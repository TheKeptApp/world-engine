import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// What a context-ring area is drawn as. Tags only (real OSM tags, no place rules); anything not
/// listed is not drawn and the backdrop plain shows instead.
enum ContextSurface: String, Sendable, CaseIterable {
    case residential, commercial, industrial, farmland, ground, park, lawn, meadow, wood, scrub, wetland
    case pitch, playground, sand, water

    static func classify(_ t: Tags) -> ContextSurface? {
        let landuse = t["landuse"] ?? "", natural = t["natural"] ?? "", leisure = t["leisure"] ?? ""
        if natural == "water" || t["water"] != nil || t["waterway"] == "riverbank" || ["reservoir", "basin"].contains(landuse) { return .water }
        if natural == "wetland" { return .wetland }
        if ["beach", "sand"].contains(natural) { return .sand }
        if ["bare_rock", "scree", "shingle"].contains(natural) { return .ground }
        if leisure == "pitch" { return .pitch }
        if leisure == "playground" { return .playground }
        if natural == "wood" || landuse == "forest" { return .wood }
        if natural == "scrub" || natural == "heath" { return .scrub }
        if ["grass", "village_green"].contains(landuse) || ["garden", "golf_course"].contains(leisure) { return .lawn }
        if landuse == "meadow" || natural == "grassland" { return .meadow }
        if landuse == "cemetery" || t["amenity"] == "grave_yard" { return .park }
        if ["park", "nature_reserve", "recreation_ground", "common"].contains(leisure) || landuse == "recreation_ground" { return .park }
        if ["farmland", "farmyard", "orchard", "vineyard", "allotments", "greenhouse_horticulture", "plant_nursery"].contains(landuse) { return .farmland }
        if landuse == "residential" { return .residential }
        if ["religious", "education", "institutional"].contains(landuse) { return .residential }
        if ["commercial", "retail"].contains(landuse) { return .commercial }
        if ["industrial", "railway", "garages", "depot", "port", "military"].contains(landuse) { return .industrial }
        if ["construction", "brownfield", "greenfield", "landfill", "quarry"].contains(landuse) { return .ground }
        return nil
    }

    /// Palette name, shade, shader flags and layer height (m). Lawn-like ground matches the core's
    /// parks ("lawn" at 0.97 with the lawn flag), so a park crossing the area edge keeps its colour.
    var style: (slot: String, shade: Float, flags: Paint.Flags, y: Double) {
        switch self {
        case .residential: ("residential", 1, [], 0.000)
        case .commercial: ("commercial", 1, [], 0.003)
        case .industrial: ("commercial", 0.93, [], 0.003)
        case .farmland: ("farmland", 1, [], 0.006)
        case .ground: ("ground", 1, [], 0.006)
        case .park: ("lawn", 0.97, .lawn, 0.010)
        case .lawn: ("lawn", 0.97, .lawn, 0.012)
        case .meadow: ("lawn", 1.03, .lawn, 0.012)
        case .wetland: ("lawn", 0.9, .lawn, 0.012)
        case .wood: ("wood", 1, [], 0.015)
        case .scrub: ("wood", 1.12, [], 0.015)
        case .pitch: ("pitch", 1, .lawn, 0.020)
        case .playground: ("playground", 1, [], 0.020)
        case .sand: ("sand", 1, [], 0.020)
        case .water: ("water", 1, [], 0.030)
        }
    }
}

/// A linear context feature (road, rail, waterway).
struct ContextLine: Sendable {
    enum Kind: Sendable { case main, mainLink, minor, alley, rail, railYard, river, stream }
    var ref: OSMRef
    var kind: Kind
    var points: [LocalPoint]
    var width: Double
}

/// The context ring's map data in local metres.
struct ContextData: Sendable {
    var areas: [(ref: OSMRef, surface: ContextSurface, polygon: Polygon2D)] = []
    var water: [Polygon2D] = []
    var roads: [ContextLine] = []
    var rails: [ContextLine] = []
    var waterways: [ContextLine] = []
    var buildings: [Building] = []
    var features: MapFeatures
    var stats: [String: Int] = [:]

    static let railWidths: [String: Double] = ["rail": 4, "light_rail": 3.5, "subway": 4, "tram": 3, "narrow_gauge": 3, "monorail": 2.5]

    /// Reads the context OSM document. `coverage` clips nothing here (cells do), it only bounds
    /// the buildings (by centroid) and the shoreline fill.
    init(document doc: OSMDocument, frame: LocalFrame, coverage: Rect2D, core: Rect2D) {
        func points(_ ids: [Int64]) -> [LocalPoint]? {
            var out: [LocalPoint] = []
            out.reserveCapacity(ids.count)
            for id in ids {
                guard let n = doc.nodes[id] else { return nil }
                out.append(frame.localPoint(of: n.coordinate))
            }
            return out
        }
        func underground(_ t: Tags) -> Bool {
            if let tunnel = t["tunnel"], tunnel != "no" { return true }
            if let layer = t["layer"].flatMap(TagParsing.integer), layer < 0, t["bridge"] == nil { return true }
            return false
        }

        // Buildings and roads through the shared builder (heights, widths, multipolygon buildings),
        // on a copy that keeps only what it needs.
        // Only the nodes those ways use: no tagged points (benches, trees) are wanted.
        var slim = OSMDocument()
        slim.ways = doc.ways.filter { $0.value.tags["building"] != nil || $0.value.tags["highway"] != nil }
        slim.relations = doc.relations.filter { $0.value.tags["building"] != nil }
        for r in slim.relations.values { for m in r.members where m.kind == .way { if let w = doc.ways[m.ref] { slim.ways[w.id] = w } } }
        slim.timestamp = doc.timestamp
        for w in slim.ways.values {
            for id in w.nodeIDs where slim.nodes[id] == nil {
                if var n = doc.nodes[id] { n.tags = [:]; slim.nodes[id] = n }
            }
        }
        features = MapFeatureBuilder(frame: frame, bounds: coverage).build(slim)
        buildings = features.buildings.filter { !$0.isPart }

        for r in features.roads where !r.isTunnel && (r.layer >= 0 || r.isBridge) {
            let kind: ContextLine.Kind
            switch r.kind {
            case .motorway, .trunk, .primary, .secondary, .tertiary:
                // `mainLink`: tertiary roads and link roads (left out at the far level).
                kind = r.kind == .tertiary || (r.tags["highway"] ?? "").hasSuffix("_link") ? .mainLink : .main
            case .unclassified, .residential, .livingStreet, .road, .busway: kind = .minor
            case .service: kind = .alley
            default: continue
            }
            roads.append(ContextLine(ref: r.ref, kind: kind, points: r.centerline, width: r.width))
        }

        // Areas, rails, waterways, water, shorelines from the raw document.
        var coast: [[Int64]] = []
        var evidence: [LocalPoint] = []
        for r in roads where r.points.count >= 2 { evidence.append(r.points[r.points.count / 2]) }
        for b in buildings { evidence.append(b.footprint.centroid) }
        for way in doc.ways.values.sorted(by: { $0.id < $1.id }) {
            let t = way.tags
            guard !t.isEmpty else { continue }
            let ref = OSMRef(.way, way.id)
            if t["natural"] == "coastline" { coast.append(way.nodeIDs); continue }
            if let rail = t["railway"], let w = Self.railWidths[rail] {
                guard !underground(t), let pts = points(way.nodeIDs) else { continue }
                let yard = ["yard", "siding", "spur"].contains(t["service"] ?? "")
                rails.append(ContextLine(ref: ref, kind: yard ? .railYard : .rail, points: pts, width: w))
                continue
            }
            if let ww = t["waterway"], ["river", "canal", "stream"].contains(ww) {
                guard !underground(t), let pts = points(way.nodeIDs) else { continue }
                let width = t["width"].flatMap(TagParsing.length).map { min($0, 80) } ?? (ww == "river" ? 14 : ww == "canal" ? 10 : 3)
                waterways.append(ContextLine(ref: ref, kind: ww == "stream" ? .stream : .river, points: pts, width: width))
                continue
            }
            guard way.isClosed, t["building"] == nil, t["highway"] == nil || t["area"] == "yes",
                  let surface = ContextSurface.classify(t), let pts = points(way.nodeIDs),
                  let poly = Polygon2D(outer: Array(pts.dropLast())).cleaned(minArea: 1) else { continue }
            if surface == .water { water.append(poly) } else { areas.append((ref, surface, poly)) }
        }
        var partialWater = 0
        for rel in doc.relations.values.sorted(by: { $0.id < $1.id }) where rel.tags["type"] == "multipolygon" {
            guard rel.tags["building"] == nil, let surface = ContextSurface.classify(rel.tags) else { continue }
            let ref = OSMRef(.relation, rel.id)
            switch MultipolygonAssembler.assemble(rel, in: doc, frame: frame) {
            case .success(let polys):
                for p in polys {
                    guard let c = p.cleaned(minArea: 1) else { continue }
                    if surface == .water { water.append(c) } else { areas.append((ref, surface, c)) }
                }
            case .failure:
                // A water relation too large to fetch whole: only the members touching the ring are
                // present. Close them along the coverage box on the water side (ShorelineFill).
                guard surface == .water else { continue }
                partialWater += 1
                var outer: [[Int64]] = [], inner: [[Int64]] = []
                for m in rel.members where m.kind == .way {
                    guard let w = doc.ways[m.ref] else { continue }
                    if m.role == "inner" { inner.append(w.nodeIDs) } else { outer.append(w.nodeIDs) }
                }
                let o = ShorelineFill.join(outer, directed: false)
                let holes = ShorelineFill.join(inner, directed: false).closed.compactMap { points($0).map { Array($0.dropLast()) } }
                for ring in o.closed { if let pts = points(ring), let c = Polygon2D(outer: Array(pts.dropLast()), holes: holes).cleaned(minArea: 1) { water.append(c) } }
                let lines = o.open.compactMap(points)
                let fill = ShorelineFill.fill(box: coverage, lines: lines,
                                              side: .unknown(landEvidence: evidence, fallbackLand: (core.min + core.max) / 2), holes: holes)
                water += fill.water
                stats["shorelinePieces", default: 0] += fill.pieces
                stats["shorelineDropped", default: 0] += fill.dropped
            }
        }
        if !coast.isEmpty {
            // OSM coastline: land on the left. Closed rings: counter-clockwise = island (a hole in the
            // sea), clockwise = water.
            let j = ShorelineFill.join(coast, directed: true)
            var islands: [Ring] = []
            for ring in j.closed {
                guard let pts = points(ring) else { continue }
                let r = Array(pts.dropLast())
                if RingMath.signedArea(r) > 0 { islands.append(r) } else if let c = Polygon2D(outer: r).cleaned(minArea: 1) { water.append(c) }
            }
            let fill = ShorelineFill.fill(box: coverage, lines: j.open.compactMap(points), side: .right, holes: islands)
            water += fill.water
            stats["shorelinePieces", default: 0] += fill.pieces
            stats["shorelineDropped", default: 0] += fill.dropped
        }
        stats["partialWaterRelations"] = partialWater
        stats["areas"] = areas.count
        stats["waterPolygons"] = water.count
        stats["roads"] = roads.count
        stats["rails"] = rails.count
        stats["waterways"] = waterways.count
        stats["buildingsInData"] = buildings.count
    }
}
