import CryptoKit
import Foundation
import simd
import WorldGen
import WorldGeo
import WorldMap

/// The map data layer, `worldengine.map/2` (neighborhood-jobs `docs/contracts/world-map-layer-v2.md`):
/// the public, static map of a package area in plan metres of the package frame. Renderer- and
/// app-neutral: raw OSM facts plus the generator's own decisions (frontage, lots, doors), each
/// estimated value with a calibrated confidence and a named method. No house numbers, no street
/// values, no user data.
public enum MapLayer {
    public static let schema = "worldengine.map/2"
    public static let header = "map/layer.json"

    public struct Options: Sendable {
        /// How far beyond the playable area roads and paths are included (§5.4).
        public var marginM: Double
        /// Writes per-record confidence features (not part of the package) for calibration.
        public var diagnosticsURL: URL?
        /// The previous package of the same area: writes `mapmeta/migration.json` (old ID → new IDs).
        public var previousPackage: URL?

        public init(marginM: Double = 400, diagnosticsURL: URL? = nil, previousPackage: URL? = nil) {
            self.marginM = marginM
            self.diagnosticsURL = diagnosticsURL
            self.previousPackage = previousPackage
        }
    }

    public struct Output {
        /// Package-relative path → bytes (`map/*.json`, `independent/*`, `mapmeta/*.json`).
        public var files: [String: Data]
        public var snapshotID: String
        /// Sources besides the area manifest's (ZCTA boundaries, terrain), as manifest sources so
        /// credits and the licence notice name them.
        public var extraSources: [AreaManifest.Source]
        /// Licence URLs of the extra sources (by format), from their files' own headers.
        public var extraLicenseURLs: [String: String]
        public var counts: [String: Int]
    }

    /// Distance kept between a lot's lawn cells and its building's walls when measuring slope:
    /// lidar ground under and against walls is interpolated, not lawn.
    static let slopeWallClearanceM = 2.0
    /// Kinds of `amenity=*` left out of places: street furniture and parking geometry, not places.
    static let placeAmenityNoise: Set<String> = ["parking_space", "parking_entrance", "bench", "waste_basket", "waste_disposal",
                                                 "vending_machine", "bicycle_parking", "motorcycle_parking", "recycling", "grit_bin",
                                                 "hunting_stand", "clock", "letter_box", "loading_dock", "charging_station"]

    public static func export(build: WorldBuild, areaDirectory: URL, generatorVersion: String, options: Options = .init()) throws -> Output {
        let manifest = build.manifest
        let frame = manifest.frame
        let playable = build.focus
        let doc = try AreaLoader.loadDocument(areaDirectory, manifest: manifest, layers: nil)
        let regions = try MapRegions.load(areaDirectory: areaDirectory, frame: frame)
        let terrain = try MapTerrain.load(areaDirectory: areaDirectory, frame: frame)
        let network = MapNetwork(doc: doc, frame: frame, playable: playable, marginM: options.marginM)
        let context = StreetContext(build.features)
        var diagnostics: [String: [[String: Any]]] = [:]

        func regionFields(_ rep: LocalPoint, _ geometry: [LocalPoint], closed: Bool, into r: inout [String: MapJSON]) {
            guard let regions else { return }
            if let z = regions.region(at: rep) { r["region"] = .string(z) }
            if let s = regions.spanned(geometry, closed: closed) { r["regionsSpanned"] = MapJSON.strings(s) }
        }
        func rings(_ p: Polygon2D) -> MapJSON { .array(([p.outer] + p.holes).map { .array($0.map(MapJSON.point)) }) }
        func inPlayable(_ pts: [LocalPoint]) -> Bool { pts.contains { playable.contains($0) } }

        // MARK: Network (§5)

        var segmentRecords: [[String: MapJSON]] = []
        for s in network.segments {
            var r: [String: MapJSON] = [
                "id": .string(s.id), "way": .string("way/\(s.way)"), "from": .string("node/\(s.nodeIDs.first!)"),
                "to": .string("node/\(s.nodeIDs.last!)"), "lengthM": .number(s.lengthM), "tags": MapJSON.tags(s.tags),
                "highway": .string(s.tags["highway"]!), "oneway": .string(MapNetwork.oneway(s.tags)),
            ]
            if s.points.count > 2 { r["geometry"] = .array(s.points.dropFirst().dropLast().map(MapJSON.point)) }
            // Margin pieces come from the area or context extract, both `out body`: the way's complete tags.
            if !playable.contains(s.midpoint) { r["context"] = .bool(true); r["fullTags"] = .bool(true) }
            regionFields(s.midpoint, s.points, closed: false, into: &r)
            for (key, tag) in [("service", "service"), ("footway", "footway"), ("junction", "junction"), ("name", "name"), ("surface", "surface")] {
                if let v = s.tags[tag] { r[key] = .string(v) }
            }
            let access = MapNetwork.access(s.tags)
            if !access.isEmpty { r["access"] = MapJSON.tags(access) }
            if let w = s.tags["width"].flatMap(MapNetwork.widthM) { r["widthM"] = .num(w) }
            if let v = MapNetwork.positiveInt(s.tags["lanes"], min: 1) { r["lanes"] = .number(Double(v)) }
            if let v = MapNetwork.positiveInt(s.tags["lanes:forward"], min: 0) { r["lanesForward"] = .number(Double(v)) }
            if let v = MapNetwork.positiveInt(s.tags["lanes:backward"], min: 0) { r["lanesBackward"] = .number(Double(v)) }
            if let v = s.tags["maxspeed"].flatMap(MapNetwork.maxspeedKmh) { r["maxspeedKmh"] = .num(v) }
            if let g = network.gatedAreas.first(where: { MapRegions.contains($0.polygon, s.midpoint) }) { r["gatedArea"] = .string(g.id) }
            segmentRecords.append(r)
        }
        var nodeRecords: [[String: MapJSON]] = []
        for (id, n) in network.nodes {
            var r: [String: MapJSON] = ["id": .string("node/\(id)"), "position": MapJSON.point(n.position)]
            if !playable.contains(n.position) { r["context"] = .bool(true) }
            r["region"] = .null
            if let regions {
                let hits = regions.regions.filter { reg in reg.bounds.expanded(by: 0.001).contains(n.position) && MapRegions.boundaryDistance(reg, n.position) <= 0.001 }.map(\.id)
                if let z = regions.region(at: n.position) { r["region"] = .string(z) }
                if hits.count >= 2 { r["regionsSpanned"] = MapJSON.strings(hits.sorted()) }
            }
            if !n.tags.isEmpty { r["tags"] = MapJSON.tags(n.tags) }
            if let c = network.controls[id] {
                r["control"] = .string(c.kind)
                if !c.approaches.isEmpty { r["controlApproaches"] = MapJSON.strings(c.approaches.sorted(by: MapJSON.byteOrder)) }
            }
            if n.tags["highway"] == "crossing" || n.tags["railway"] == "crossing", let v = n.tags["crossing"] { r["crossing"] = .string(v) }
            nodeRecords.append(r)
        }
        let barrierRecords: [[String: MapJSON]] = network.barriers.map { b in
            var r: [String: MapJSON] = ["id": .string("node/\(b.node)"), "node": .string("node/\(b.node)"), "barrier": .string(b.tags["barrier"]!),
                                        "tags": MapJSON.tags(b.tags)]
            let a = MapNetwork.access(b.tags)
            if !a.isEmpty { r["access"] = MapJSON.tags(a) }
            return r
        }
        let gatedRecords: [[String: MapJSON]] = network.gatedAreas.map { g in
            var r: [String: MapJSON] = ["id": .string(g.id), "polygon": rings(g.polygon), "tags": MapJSON.tags(g.tags)]
            let a = MapNetwork.access(g.tags)
            if !a.isEmpty { r["access"] = MapJSON.tags(a) }
            return r
        }
        let restrictionRecords: [[String: MapJSON]] = network.restrictions.map { t in
            var r: [String: MapJSON] = ["id": .string(t.id), "restriction": .string(t.tags["restriction"]!), "from": .string(t.from),
                                        "to": .string(t.to), "tags": MapJSON.tags(t.tags)]
            if let v = t.viaNode { r["viaNode"] = .string("node/\(v)") } else { r["viaSegments"] = MapJSON.strings(t.viaSegments) }
            if let e = t.tags["except"] { r["except"] = MapJSON.strings(e.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }) }
            return r
        }
        // Barrier records carry `id` only for sorting; the schema keys them by `node`.
        let barriersSorted = MapJSON.sortedByID(barrierRecords).map { v -> MapJSON in
            guard case .object(var o) = v else { return v }
            o["id"] = nil
            return .object(o)
        }
        let networkFile: MapJSON = .object([
            "schema": .string(schema), "file": .string("network"),
            "nodes": .array(MapJSON.sortedByID(nodeRecords)), "segments": .array(MapJSON.sortedByID(segmentRecords)),
            "barriers": .array(barriersSorted), "gatedAreas": .array(MapJSON.sortedByID(gatedRecords)),
            "turnRestrictions": .array(MapJSON.sortedByID(restrictionRecords)),
        ])

        // MARK: Buildings and frontage (§6, §7)

        let generated = Dictionary(build.scene.buildings.map { ($0.ref, $0) }, uniquingKeysWith: { a, _ in a })
        let lotsByBuilding = Dictionary(build.scene.lots.map { ($0.building, $0) }, uniquingKeysWith: { a, _ in a })
        var buildingRecords: [[String: MapJSON]] = []
        var included: [OSMRef: Building] = [:]
        var frontageOf: [OSMRef: (segment: MapNetwork.Segment, offset: Double, distance: Double, side: String)] = [:]
        for b in build.features.buildings {
            let ring = b.footprint.outer
            guard playable.contains(b.footprint.centroid) || inPlayable(ring) else { continue }
            included[b.ref] = b
            let id = b.ref.description
            var r: [String: MapJSON] = [
                "id": .string(id), "source": .string(b.ref.kind == .overture ? "overture" : "osm"), "building": .string(b.type),
                "isPart": .bool(b.isPart), "footprint": rings(b.footprint), "centroid": MapJSON.point(b.footprint.centroid),
                "hasHouseNumber": .bool(["addr:housenumber", "addr:streetnumber", "addr:conscriptionnumber"].contains { b.tags[$0] != nil }),
                "hasAddrStreet": .bool(b.tags["addr:street"] != nil),
            ]
            regionFields(b.footprint.centroid, ring, closed: true, into: &r)
            if !playable.contains(b.footprint.centroid) { r["context"] = .bool(true) }
            if !b.isPart, let g = generated[b.ref], g.role == .house || g.role == .block, let fe = g.frontEdge,
               let hit = context.streetIndex.nearest(to: b.footprint.centroid, within: 60) {
                // The street the generator's StreetContext chose for the front edge, and the piece of it
                // opposite the front door.
                let way = context.streets[hit.line].ref
                let p = ring[fe], q = ring[(fe + 1) % ring.count]
                let door = g.entry?.point ?? (p + q) / 2
                let best = (network.byWay[way.id] ?? []).map { network.segments[$0] }
                    .map { s in (s, MapNetwork.project(door, onto: s.points)) }
                    .min { $0.1.distance < $1.1.distance }
                if case let (s, proj)? = best {
                    frontageOf[b.ref] = (s, min(proj.offset, s.lengthM), proj.distance, proj.side)
                    let features = MapConfidence.frontageFeatures(building: b, generated: g, context: context, distance: proj.distance, street: way)
                    let c = MapConfidence.frontage(features)
                    r["frontage"] = .object(["segment": .string(s.id), "offsetM": .num(min(proj.offset, s.lengthM)), "side": .string(proj.side),
                                             "confidence": .num(c), "method": .string(MapConfidence.frontageMethod.id)])
                    var d = features
                    d["id"] = id
                    d["segment"] = s.id
                    d["confidence"] = c
                    diagnostics["frontage", default: []].append(d)
                }
            }
            buildingRecords.append(r)
        }
        let buildingsFile: MapJSON = .object(["schema": .string(schema), "file": .string("buildings"), "buildings": .array(MapJSON.sortedByID(buildingRecords))])

        // MARK: Lots (§8)

        var lotRecords: [[String: MapJSON]] = []
        var lotSlopes: [[String: MapJSON]] = []
        var frontLotOf: [OSMRef: String] = [:]
        for (ref, lot) in lotsByBuilding.sorted(by: { $0.key < $1.key }) {
            guard let b = included[ref], !b.isPart else { continue }
            for part in lot.parts {
                let name = part.front ? "front" : "back"
                let id = "gen:lot:\(ref):\(name)"
                let outline = part.outline.map { LocalPoint(MapJSON.round3($0.x), MapJSON.round3($0.y)) }
                let area = MapJSON.round3(abs(RingMath.signedArea(outline)))
                guard area > 0 else { continue }
                let features = MapConfidence.lotFeatures(building: b, generated: generated[ref], part: part, frontage: frontageOf[ref]?.distance)
                let c = MapConfidence.lot(features)
                var r: [String: MapJSON] = [
                    "id": .string(id), "building": .string(ref.description), "part": .string(name),
                    "polygon": .array([.array(outline.map(MapJSON.point))]), "areaM2": .number(area),
                    "mowableAreaM2": .number(min(area, MapJSON.round3(part.mowableArea))),
                    "confidence": .num(c), "method": .string(MapConfidence.lotMethod.id),
                ]
                if let terrain {
                    let walls = b.footprint.outer
                    let near: (LocalPoint) -> Bool = { p in
                        RingMath.contains(walls, p) || MapConfidence.distance(p, toRing: walls) < slopeWallClearanceM
                    }
                    // D-57: slope lives in independent/lot-slope.json, joined by lot ID, never in lots.json.
                    if let s = terrain.maxSlope(lawn: part.lawn, exclude: near) {
                        var rec: [String: MapJSON] = ["id": .string(id), "lot": .string(id), "slopePercent": .num(s.percent),
                                                      "method": .string(MapConfidence.slopeMethodID), "source": .string(terrain.source.id),
                                                      "resolutionM": .num(terrain.cellM)]
                        if let c = terrain.confidence(forPercent: s.percent) { rec["slopeConfidence"] = .num(c) }
                        lotSlopes.append(rec)
                    }
                }
                if part.front { frontLotOf[ref] = id }
                lotRecords.append(r)
                var d = features
                d["id"] = id
                d["confidence"] = c
                d["polygon"] = outline.map { [$0.x, $0.y] }
                d["footprint"] = b.footprint.outer.map { [$0.x, $0.y] }
                d["building"] = ref.description
                if let fe = generated[ref]?.frontEdge {
                    let ring = b.footprint.outer, p = ring[fe], q = ring[(fe + 1) % ring.count]
                    d["frontEdge"] = [[p.x, p.y], [q.x, q.y]]
                }
                diagnostics["lots", default: []].append(d)
            }
        }
        let lotsFile: MapJSON = .object(["schema": .string(schema), "file": .string("lots"), "lots": .array(MapJSON.sortedByID(lotRecords))])

        // MARK: Entry points (§9)

        var entryRecords: [[String: MapJSON]] = []
        for (ref, b) in included.sorted(by: { $0.key < $1.key }) where !b.isPart {
            guard let g = generated[ref], g.role == .house || g.role == .block else { continue }
            if let e = g.entry {
                let features = MapConfidence.doorFeatures(building: b, generated: g, frontage: frontageOf[ref]?.distance)
                let c = MapConfidence.door(features)
                var r: [String: MapJSON] = [
                    "id": .string("gen:entry:\(ref):front_door"), "building": .string(ref.description), "kind": .string("front_door"),
                    "position": MapJSON.point(e.point), "confidence": .num(c), "method": .string(MapConfidence.entryMethod.id),
                ]
                if simd_length(e.normal) > 0.5 { r["normal"] = MapJSON.point(simd_normalize(e.normal)) }
                if let l = frontLotOf[ref] { r["lot"] = .string(l) }
                entryRecords.append(r)
                var d = features
                d["id"] = "gen:entry:\(ref):front_door"
                d["kind"] = "front_door"
                d["position"] = [e.point.x, e.point.y]
                d["confidence"] = c
                d["building"] = ref.description
                d["footprint"] = b.footprint.outer.map { [$0.x, $0.y] }
                if let fe = g.frontEdge {
                    let ring = b.footprint.outer, p = ring[fe], q = ring[(fe + 1) % ring.count]
                    d["frontEdge"] = [[p.x, p.y], [q.x, q.y]]
                }
                diagnostics["entries", default: []].append(d)
            }
            // Driveway mouths: where the generated driveway of a garage serving this house meets the
            // street or alley (keyed by the house, not the garage).
            for (n, line) in (lotsByBuilding[ref]?.driveways ?? []).enumerated() {
                guard let end = line.last, let start = line.first else { continue }
                let id = "gen:entry:\(ref):driveway_end" + (n == 0 ? "" : ":\(n)")
                let features = MapConfidence.drivewayFeatures(building: b, length: simd_distance(start, end))
                let c = MapConfidence.driveway(features)
                entryRecords.append(["id": .string(id), "building": .string(ref.description), "kind": .string("driveway_end"),
                                     "position": MapJSON.point(end), "confidence": .num(c), "method": .string(MapConfidence.entryMethod.id)])
                var d = features
                d["id"] = id
                d["kind"] = "driveway_end"
                d["position"] = [end.x, end.y]
                d["start"] = [start.x, start.y]
                d["confidence"] = c
                d["building"] = ref.description
                diagnostics["entries", default: []].append(d)
            }
        }
        let entriesFile: MapJSON = .object(["schema": .string(schema), "file": .string("entries"), "entries": .array(MapJSON.sortedByID(entryRecords))])

        // MARK: Places (§10) and transit (§11)

        let elements = Self.elements(doc, frame: frame)
        var placeRecords: [[String: MapJSON]] = []
        for el in elements {
            guard case let (kind, cls)? = Self.placeClass(el.tags) else { continue }
            let geometry = el.polygon.map { [$0.outer] } ?? [[el.position]]
            guard inPlayable(geometry.flatMap { $0 }) || playable.contains(el.position) else { continue }
            var r: [String: MapJSON] = [
                "id": .string(el.id), "kind": .string(kind), "class": .string(cls), "position": MapJSON.point(el.position),
                "hasHouseNumber": .bool(["addr:housenumber", "addr:streetnumber", "addr:conscriptionnumber"].contains { el.tags[$0] != nil }),
            ]
            if let n = el.tags["name"] { r["name"] = .string(n) }
            if let p = el.polygon { r["outline"] = rings(p) }
            if let v = el.tags["building"] { r["building"] = .string(v) }
            r["region"] = .null
            regionFields(el.position, el.polygon?.outer ?? [el.position], closed: el.polygon != nil, into: &r)
            if !playable.contains(el.position) { r["context"] = .bool(true) }
            placeRecords.append(r)
        }
        let placesFile: MapJSON = .object(["schema": .string(schema), "file": .string("places"), "places": .array(MapJSON.sortedByID(placeRecords))])

        var stopRecords: [[String: MapJSON]] = []
        var stopIDs: Set<String> = []
        for el in elements {
            guard let kind = Self.stopKind(el.tags), playable.contains(el.position) else { continue }
            var r: [String: MapJSON] = ["id": .string(el.id), "kind": .string(kind), "position": MapJSON.point(el.position),
                                        "tags": MapJSON.tags(MapNetwork.stripAddress(el.tags))]
            if let v = el.tags["name"] { r["name"] = .string(v) }
            if let v = el.tags["ref"] { r["ref"] = .string(v) }
            if let v = el.tags["route_ref"] { r["routeRefs"] = MapJSON.strings(v.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }) }
            if let v = el.tags["gtfs:stop_id"] ?? el.tags["ref:gtfs"] { r["gtfsStopID"] = .string(v) }
            if el.id.hasPrefix("node/"), let nid = Int64(el.id.dropFirst(5)), network.nodes[nid] != nil { r["node"] = .string(el.id) }
            if let z = regions?.region(at: el.position) { r["region"] = .string(z) }
            stopIDs.insert(el.id)
            stopRecords.append(r)
        }
        var routeRecords: [[String: MapJSON]] = []
        for rel in doc.relations.values where rel.tags["type"] == "route" && rel.tags["route"] != nil {
            let stops = rel.members.map { "\($0.kind.rawValue)/\($0.ref)" }.filter { stopIDs.contains($0) }
            guard !stops.isEmpty else { continue }
            var r: [String: MapJSON] = ["id": .string("relation/\(rel.id)"), "mode": .string(rel.tags["route"]!), "stops": MapJSON.strings(stops),
                                        "tags": MapJSON.tags(MapNetwork.stripAddress(rel.tags))]
            if let v = rel.tags["ref"] { r["ref"] = .string(v) }
            if let v = rel.tags["name"] { r["name"] = .string(v) }
            routeRecords.append(r)
        }
        let transitFile: MapJSON = .object(["schema": .string(schema), "file": .string("transit"),
                                            "stops": .array(MapJSON.sortedByID(stopRecords)), "routes": .array(MapJSON.sortedByID(routeRecords))])

        // MARK: Header (§4) and snapshot (§13)

        var extraSources: [AreaManifest.Source] = []
        if let z = regions?.source {
            extraSources.append(.init(format: "census-zcta-v1", path: MapRegions.fileName, layers: ["regions"], bounds: manifest.contextBounds ?? manifest.bounds,
                                      dataTimestamp: nil, fetchedAt: nil, bytes: nil, sha256: z.sha256, license: z.license, attribution: z.attribution))
        }
        if let t = terrain?.source {
            extraSources.append(.init(format: "worldengine-slope-grid-v1", path: MapTerrain.headerFile, layers: ["terrain"], bounds: manifest.bounds,
                                      dataTimestamp: t.dataTimestamp, fetchedAt: nil, bytes: nil, sha256: t.sha256, license: t.license, attribution: t.attribution))
        }
        let catalog = try CreditsCatalog.bundled()
        let allSources = manifest.sources + extraSources
        var extraLicenseURLs: [String: String] = [:]
        if let u = regions?.source.licenseURL { extraLicenseURLs["census-zcta-v1"] = u }
        if let u = terrain?.source.licenseURL { extraLicenseURLs["worldengine-slope-grid-v1"] = u }
        let credits = catalog.merged(sources: allSources, surface: .package)
        let hasRelations = manifest.sources.contains { $0.layers.contains(MapLayer.relationsLayer) }
        var files: [String: MapJSON] = [
            "map/network.json": networkFile, "map/buildings.json": buildingsFile, "map/lots.json": lotsFile,
            "map/entries.json": entriesFile, "map/places.json": placesFile, "map/transit.json": transitFile,
        ]
        let counts = ["network": segmentRecords.count, "buildings": buildingRecords.count, "lots": lotRecords.count,
                      "entries": entryRecords.count, "places": placeRecords.count, "transit": stopRecords.count]
        // `partial` marks a known gap in the data: without the relations extract there are no turn
        // restrictions or transit routes. Lots and entry points are complete for their methods (every
        // yard and door the generator makes is exported; it makes no mailboxes or yard gates).
        let coverage = ["network": hasRelations ? "complete" : "partial", "buildings": "complete", "lots": "complete",
                        "entries": "complete", "places": "complete", "transit": hasRelations ? "complete" : "partial"]
        var layers: [String: MapJSON] = [:]
        for name in ["network", "buildings", "lots", "entries", "places", "transit"] {
            layers[name] = .object(["path": .string("map/\(name).json"), "coverage": .string(coverage[name]!), "count": .number(Double(counts[name]!))])
        }
        if let terrain {
            layers["lotSlope"] = .object(["path": .string("\(independentDirectory)/lot-slope.json"), "coverage": .string("complete"),
                                          "count": .number(Double(lotSlopes.count))])
            layers["terrainSlope"] = .object(["path": .string("\(independentDirectory)/terrain-slope.json"), "coverage": .string("complete"),
                                              "count": .number(Double(terrain.cols * terrain.rows))])
        }
        func sourceID(_ s: AreaManifest.Source) -> String {
            switch s.format {
            case "census-zcta-v1": regions?.source.id ?? "census-zcta"
            case "worldengine-slope-grid-v1": terrain?.source.id ?? "terrain"
            case OvertureBuildings.format: "overture-buildings"
            default: s.layers.contains("all") ? "osm" : "osm-\(s.layers.joined(separator: "-"))"
            }
        }
        let sourceRecords: [MapJSON] = allSources.map { s -> MapJSON in
            var r: [String: MapJSON] = ["id": .string(sourceID(s)), "format": .string(s.format), "license": .string(s.license),
                                        "attribution": .string(s.attribution), "layers": MapJSON.strings(s.layers)]
            if let u = catalog.licenseURL(for: s.license) ?? extraLicenseURLs[s.format] { r["licenseURL"] = .string(u) }
            if let t = s.dataTimestamp { r["dataTimestamp"] = .string(t) }
            if let h = s.sha256 { r["sha256"] = .string(h) }
            r["credits"] = MapJSON.strings(credits.filter { c in
                (c.sources ?? []).contains(s.format) || (c.kind == .mapData && s.license == "ODbL-1.0") || (c.kind == .dataOffer && s.license == "ODbL-1.0")
            }.map(\.id))
            return .object(r)
        }.sorted { a, b in
            guard case .object(let x) = a, case .object(let y) = b, case .string(let i)? = x["id"], case .string(let j)? = y["id"] else { return false }
            return MapJSON.byteOrder(i, j)
        }
        let usedCredits = Set(sourceRecords.flatMap { r -> [String] in
            guard case .object(let o) = r, case .array(let a)? = o["credits"] else { return [] }
            return a.compactMap { if case .string(let s) = $0 { s } else { nil } }
        })
        let creditRecords: [MapJSON] = credits.filter { usedCredits.contains($0.id) }.map { c in
            var r: [String: MapJSON] = ["id": .string(c.id), "kind": .string(c.kind.rawValue), "title": .string(c.title), "text": .string(c.text)]
            if let u = c.url { r["url"] = .string(u) }
            if let l = c.license { r["license"] = .string(l) }
            if let u = c.licenseURL { r["licenseURL"] = .string(u) }
            if c.isPlaceholder { r["placeholder"] = .bool(true) }
            return .object(r)
        }
        // Every ZCTA the playable area intersects, plus any that only margin features reach (share 0),
        // so every feature's region is declared.
        var regionRecords: [MapJSON] = []
        if let regions {
            var shares = Dictionary(regions.areaShares(of: playable).map { ($0.id, $0.share) }, uniquingKeysWith: { a, _ in a })
            for v in files.values { for id in Self.regionIDs(in: v) where shares[id] == nil { shares[id] = 0 } }
            for id in shares.keys.sorted() {
                regionRecords.append(.object(["id": .string(id), "system": .string("zcta"), "vintage": .string(regions.source.vintage),
                                              "source": .string(regions.source.id), "areaShare": .number(shares[id]!)]))
            }
        }
        var methods = [MapConfidence.frontageMethod, MapConfidence.lotMethod, MapConfidence.entryMethod]
        if let terrain { methods.append(MapConfidence.slopeMethod(terrain)) }
        let pl = [playable.min, LocalPoint(playable.max.x, playable.min.y), playable.max, LocalPoint(playable.min.x, playable.max.y)]
        var header: [String: MapJSON] = [
            "schema": .string(schema), "file": .string("layer"),
            "generator": .object(["name": .string("WorldEngine WorldGen"), "version": .string(generatorVersion)]),
            "area": .object(["id": .string(manifest.id), "name": .string(manifest.name), "playable": .array([.array(pl.map(MapJSON.point))]),
                             "marginM": .num(options.marginM)]),
            "frame": .object([
                "type": .string(WorldPackage.frameType),
                "origin": .object(["latitude": .exact(frame.origin.latitude), "longitude": .exact(frame.origin.longitude), "height": .number(0)]),
                "units": .string("meters"), "planAxes": MapJSON.strings(["east", "north"]), "vertical": .string(WorldPackage.frameVertical),
            ]),
            "attribution": .string("© OpenStreetMap contributors"), "license": .string(WorldPackage.dataLicense),
            "sources": .array(sourceRecords), "credits": .array(creditRecords),
            "methods": .array(methods.sorted { $0.id < $1.id }.map(\.json)),
            "layers": .object(layers), "containsUserData": .bool(false),
        ]
        if !regionRecords.isEmpty { header["regions"] = .array(regionRecords) }
        files[Self.header] = .object(header)

        var data: [String: Data] = [:]
        for (path, value) in files { data[path] = value.encoded() }
        if let terrain {
            let creditIDs = credits.filter { ($0.sources ?? []).contains("worldengine-slope-grid-v1") }.map(\.id)
            for (path, d) in Self.independentFiles(terrain: terrain, lotSlopes: lotSlopes, credits: creditIDs) { data[path] = d }
        }
        // §13 (D-57): over map/*.json and independent/*, so a slope change changes the ID too.
        let lines = data.keys.sorted(by: MapJSON.byteOrder).map { "\($0) \(sha256(data[$0]!))\n" }.joined()
        let snapshot = "wem2-" + String(sha256(Data(lines.utf8)).prefix(16))

        // Companion files (outside map/ and independent/, not part of the snapshot hash): source
        // links, provenance labels, and the migration from the previous package.
        let overture = included.values.filter { $0.ref.kind == .overture }.sorted { $0.ref < $1.ref }
        data[MapMeta.idsPath] = MapMeta.ids(snapshot: snapshot, segments: network.segments, overture: overture).encoded()
        data[MapMeta.provenancePath] = MapMeta.provenance(snapshot: snapshot, overture: overture).encoded()
        if let prev = options.previousPackage {
            guard let old = try MapMigration.load({ p in try? Data(contentsOf: prev.appendingPathComponent(p)) }) else {
                throw MapLayerError.badInput("previous package \(prev.path) has no map layer")
            }
            let newWorld = try JSONSerialization.data(withJSONObject: ["mapSnapshotID": snapshot])
            guard let new = try MapMigration.load({ p in p == "world.json" ? newWorld : data[p] }) else { throw MapLayerError.badInput("new layer unreadable") }
            data[MapMeta.migrationPath] = try MapMigration.compare(old: old, new: new).encoded()
        }

        if let url = options.diagnosticsURL {
            let obj: [String: Any] = ["area": manifest.id, "snapshot": snapshot, "records": diagnostics]
            try JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]).write(to: url)
        }
        return Output(files: data, snapshotID: snapshot, extraSources: extraSources, extraLicenseURLs: extraLicenseURLs, counts: counts)
    }

    // MARK: - Independent layers (public-domain non-OSM sources, kept out of the ODbL files)

    public static let independentDirectory = "independent"

    /// Licence of the independent files (owner rule 2026-10-06: proprietary pending the lawyer's review).
    public static let independentLicense = "Proprietary (WorldEngine), pending legal review"
    /// The acknowledgement USGS asks for (The National Map terms of use).
    public static let usgsAcknowledgement = "Data available from U.S. Geological Survey, National Geospatial Program."

    /// worldengine.map/2 §8.1–8.2 (D-57): `independent/lot-slope.json` (each lot's steepest lawn slope,
    /// joined by lot ID) and `independent/terrain-slope.json` + `.bin` (the lidar slope grid in the
    /// package frame, `uint16le`, no OSM input).
    static func independentFiles(terrain: MapTerrain, lotSlopes: [[String: MapJSON]], credits: [String]) -> [String: Data] {
        let provenance: [String: MapJSON] = ["license": .string(independentLicense), "attribution": .string(usgsAcknowledgement),
                                             "credits": MapJSON.strings(credits), "schema": .string(schema)]
        var lotFile = provenance
        lotFile["file"] = .string("lotSlope")
        lotFile["lots"] = .array(MapJSON.sortedByID(lotSlopes).map { v -> MapJSON in
            guard case .object(var o) = v else { return v }
            o["id"] = nil
            return .object(o)
        })
        var grid = provenance
        grid["file"] = .string("terrainSlope")
        grid["source"] = .string(terrain.source.id)
        grid["method"] = .string(MapConfidence.slopeMethodID)
        grid["resolutionM"] = .num(terrain.cellM)
        grid["origin"] = MapJSON.point(LocalPoint(terrain.minX, terrain.minY))
        grid["cellSizeM"] = .num(terrain.cellM)
        grid["width"] = .number(Double(terrain.cols))
        grid["height"] = .number(Double(terrain.rows))
        grid["rowOrder"] = .string("south-to-north")
        grid["units"] = .string("percent")
        grid["encoding"] = .string("uint16le")
        grid["scale"] = .num(0.01)
        grid["nodata"] = .number(65535)
        grid["data"] = .string("\(independentDirectory)/terrain-slope.bin")
        if let c = terrain.confidence { grid["confidence"] = .num(c.overall) }
        return ["\(independentDirectory)/lot-slope.json": MapJSON.object(lotFile).encoded(),
                "\(independentDirectory)/terrain-slope.json": MapJSON.object(grid).encoded(),
                "\(independentDirectory)/terrain-slope.bin": terrain.uint16le()]
    }

    /// Manifest layer of the network-relations extract (turn restrictions, transit routes) that
    /// `worldbake fetch --layers relations` writes.
    public static let relationsLayer = "relations"

    /// Region IDs written on records (`region`, `regionsSpanned`) anywhere in a file.
    static func regionIDs(in v: MapJSON) -> Set<String> {
        switch v {
        case .object(let o):
            var out = Set<String>()
            for (k, x) in o {
                if k == "region", case .string(let s) = x { out.insert(s) }
                else if k == "regionsSpanned", case .array(let a) = x { for case .string(let s) in a { out.insert(s) } }
                else { out.formUnion(regionIDs(in: x)) }
            }
            return out
        case .array(let a): return a.reduce(into: Set<String>()) { $0.formUnion(regionIDs(in: $1)) }
        default: return []
        }
    }

    static func sha256(_ d: Data) -> String { SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined() }

    // MARK: - OSM elements as places and stops

    struct Element {
        var id: String
        var tags: Tags
        var position: LocalPoint
        var polygon: Polygon2D?
    }

    /// Tagged nodes, closed ways and multipolygons with a position (area centroid of the outer ring).
    static func elements(_ doc: OSMDocument, frame: LocalFrame) -> [Element] {
        var out: [Element] = []
        let interesting: (Tags) -> Bool = { t in
            t["amenity"] != nil || t["shop"] != nil || t["leisure"] != nil || t["tourism"] != nil || t["public_transport"] != nil
                || t["highway"] == "bus_stop" || ["tram_stop", "station", "halt"].contains(t["railway"] ?? "")
        }
        for n in doc.nodes.values where !n.tags.isEmpty && interesting(n.tags) {
            out.append(Element(id: "node/\(n.id)", tags: n.tags, position: frame.localPoint(of: n.coordinate)))
        }
        for w in doc.ways.values where interesting(w.tags) {
            guard let coords = doc.coordinates(of: w), coords.count >= 2 else { continue }
            if w.isClosed {
                let poly = MapNetwork.oriented(Polygon2D(outer: coords.dropLast().map(frame.localPoint(of:))))
                out.append(Element(id: "way/\(w.id)", tags: w.tags, position: poly.centroid, polygon: poly))
            } else if w.tags["public_transport"] == "platform" {
                let pts = coords.map(frame.localPoint(of:))
                out.append(Element(id: "way/\(w.id)", tags: w.tags, position: MapNetwork.pointAlong(pts, fraction: 0.5)))
            }
        }
        for r in doc.relations.values where r.tags["type"] == "multipolygon" && interesting(r.tags) {
            guard case .success(let polys) = MultipolygonAssembler.assemble(r, in: doc, frame: frame),
                  let poly = polys.max(by: { abs($0.area) < abs($1.area) }) else { continue }
            let p = MapNetwork.oriented(poly)
            out.append(Element(id: "relation/\(r.id)", tags: r.tags, position: p.centroid, polygon: p))
        }
        return out.sorted { MapJSON.byteOrder($0.id, $1.id) }
    }

    /// Place kind and defining tag (§10); nil for elements that are not places.
    static func placeClass(_ t: Tags) -> (String, String)? {
        if t["leisure"] == "park" { return ("park", "leisure=park") }
        if t["amenity"] == "school" { return ("school", "amenity=school") }
        if t["amenity"] == "library" { return ("library", "amenity=library") }
        if let s = t["shop"] { return ("shop", "shop=\(s)") }
        if stopKind(t) != nil { return nil }
        if let a = t["amenity"], !placeAmenityNoise.contains(a) { return ("other", "amenity=\(a)") }
        if let l = t["leisure"] { return ("other", "leisure=\(l)") }
        if let v = t["tourism"] { return ("other", "tourism=\(v)") }
        return nil
    }

    static func stopKind(_ t: Tags) -> String? {
        if let p = t["public_transport"], ["platform", "stop_position", "station"].contains(p) { return p }
        if t["highway"] == "bus_stop" { return "bus_stop" }
        if let r = t["railway"], ["tram_stop", "station", "halt"].contains(r) { return r }
        return nil
    }
}
