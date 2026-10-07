import Foundation
import WorldGeo

/// Turns raw OSM elements into typed `MapFeatures` for one area.
///
/// Classification keys off OSM tags only. There are no place-specific rules. The area (frame and
/// bounds) is input data.
public struct MapFeatureBuilder: Sendable {
    public var frame: LocalFrame
    public var bounds: Rect2D
    public var heightRules = HeightRules()
    public var roadRules = RoadRules()

    public init(frame: LocalFrame, bounds: Rect2D) {
        self.frame = frame
        self.bounds = bounds
    }

    /// Convenience: an area of `width` × `height` meters centered on the frame origin.
    public init(center: GeoCoordinate, widthMeters: Double, heightMeters: Double) {
        self.init(frame: LocalFrame(origin: center), bounds: Rect2D(centerWidth: widthMeters, height: heightMeters))
    }

    public func build(_ doc: OSMDocument) -> MapFeatures {
        var out = MapFeatures(frame: frame, bounds: bounds)
        out.report.nodeCount = doc.nodes.count
        out.report.wayCount = doc.ways.count
        out.report.relationCount = doc.relations.count

        // Relations are looked at first, so ways that a relation already covers are not
        // turned into a second building.
        var assembled: [Int64: Result<[Polygon2D], MultipolygonAssembler.Failure>] = [:]
        // Closed building ways that are outers of a multipolygon building: the relation's
        // polygon (which carries the holes) is kept, the way is not emitted on its own.
        // Value: the way's tags, which fill gaps in the relation's tags.
        var coveredWays: [Int64: Tags] = [:]
        // `type=building` outline ways whose own tags lack `building`: the relation's building tags apply.
        var outlineTags: [Int64: Tags] = [:]

        let relations = doc.relations.values.sorted(by: { $0.id < $1.id })
        for rel in relations {
            switch rel.tags["type"] {
            case "multipolygon":
                guard Self.buildingType(rel.tags) != nil || Self.areaKind(rel.tags) != nil else { continue }
                let result = MultipolygonAssembler.assemble(rel, in: doc, frame: frame)
                assembled[rel.id] = result
                guard case .success = result, Self.buildingType(rel.tags) != nil else { continue }
                for m in rel.members where m.kind == .way && m.role != "inner" {
                    guard let way = doc.ways[m.ref], way.isClosed, Self.isBuildingWay(way.tags) else { continue }
                    coveredWays[way.id] = way.tags
                }
            case "building":
                guard Self.isBuildingWay(rel.tags) else { continue }
                let inherited = rel.tags.filter { Self.isBuildingTagKey($0.key) }
                for m in rel.members where m.kind == .way && m.role == "outline" {
                    guard let way = doc.ways[m.ref], way.tags["building"] == nil, way.tags["building:part"] == nil else { continue }
                    outlineTags[way.id] = way.tags.merging(inherited) { own, _ in own }
                }
            default:
                continue
            }
        }

        // Ways (sorted by ID so output order is deterministic).
        for way in doc.ways.values.sorted(by: { $0.id < $1.id }) {
            let tags = outlineTags[way.id] ?? way.tags
            guard !tags.isEmpty, coveredWays[way.id] == nil else { continue }
            let ref = OSMRef(.way, way.id)
            guard let coords = doc.coordinates(of: way) else {
                out.report.skipped.append(.init(ref: ref, reason: "missing nodes"))
                continue
            }
            let pts = coords.map(frame.localPoint(of:))
            if !classifyWay(ref: ref, tags: tags, points: pts, closed: way.isClosed, into: &out) {
                out.report.unclassifiedCount += 1
            }
        }

        out.roads = roadRules.clampedToSidewalks(out.roads, sidewalks: out.sidewalks)

        // Multipolygon relations. A `type=building` relation only groups an outline and parts, which
        // are ordinary ways: it never makes a building from its members.
        for rel in relations {
            guard rel.tags["type"] == "multipolygon" || rel.tags["type"] == "building" else { continue }
            let ref = OSMRef(.relation, rel.id)
            guard Self.buildingType(rel.tags) != nil || Self.areaKind(rel.tags) != nil else {
                out.report.unclassifiedCount += 1
                continue
            }
            guard rel.tags["type"] == "multipolygon", let result = assembled[rel.id] else { continue }
            switch result {
            case .success(let polygons):
                for poly in polygons {
                    var tags = rel.tags
                    // A closed way that is this polygon's outer fills in tags the relation lacks.
                    if let wayTags = coveredTags(matching: poly, covered: coveredWays, in: doc) {
                        tags = wayTags.merging(rel.tags) { _, relation in relation }
                    }
                    classifyPolygon(ref: ref, tags: tags, polygon: poly, into: &out)
                }
            case .failure(let error):
                out.report.skipped.append(.init(ref: ref, reason: error.description))
            }
        }

        // Tagged nodes.
        for node in doc.nodes.values.sorted(by: { $0.id < $1.id }) where !node.tags.isEmpty {
            guard let kind = Self.pointKind(node.tags) else { continue }
            let p = frame.localPoint(of: node.coordinate)
            guard bounds.contains(p) else { continue }
            out.points.append(PointFeature(ref: OSMRef(.node, node.id), kind: kind, position: p, tags: node.tags))
        }
        return out
    }

    // MARK: - Ways

    /// Returns false if the way matched no rule.
    private func classifyWay(ref: OSMRef, tags: Tags, points: [LocalPoint], closed: Bool, into out: inout MapFeatures) -> Bool {
        let isArea = tags["area"] == "yes"

        // Closed ways that describe areas (buildings, parks, water, plazas).
        if closed, !(tags["highway"] != nil && !isArea), tags["area"] != "no" {
            if Self.buildingType(tags) != nil || Self.areaKind(tags) != nil {
                classifyPolygon(ref: ref, tags: tags, polygon: Polygon2D(outer: Array(points.dropLast())), into: &out)
                return true
            }
            if let kind = Self.pointKind(tags) {
                // Benches, picnic tables etc. mapped as small areas become points.
                let c = RingMath.centroid(Array(points.dropLast()))
                if bounds.contains(c) {
                    out.points.append(PointFeature(ref: ref, kind: kind, position: c, tags: tags, fromWay: true))
                }
                return true
            }
        }

        if let hw = tags["highway"], !isArea {
            let kind = HighwayKind(tag: hw)
            for piece in Clipping.clip(polyline: points, to: bounds) {
                let f = makeWayFeature(ref: ref, kind: kind, tags: tags, line: piece)
                if kind.isVehicular {
                    out.roads.append(f)
                } else if tags["footway"] == "sidewalk" || tags["path"] == "sidewalk" {
                    out.sidewalks.append(f)
                } else {
                    out.paths.append(f)
                }
            }
            return true
        }

        if let kind = Self.lineKind(tags) {
            for piece in Clipping.clip(polyline: points, to: bounds) {
                out.lines.append(LineFeature(ref: ref, kind: kind, line: piece, tags: tags))
            }
            return true
        }

        if let kind = Self.pointKind(tags) {
            // Linear benches etc.: use the midpoint vertex.
            let mid = points[points.count / 2]
            if bounds.contains(mid) {
                out.points.append(PointFeature(ref: ref, kind: kind, position: mid, tags: tags, fromWay: true))
            }
            return true
        }
        return false
    }

    private func makeWayFeature(ref: OSMRef, kind: HighwayKind, tags: Tags, line: [LocalPoint]) -> WayFeature {
        let (left, right) = Self.sidewalks(tags)
        return WayFeature(
            ref: ref, kind: kind, centerline: line, tags: tags,
            width: roadRules.width(kind: kind, tags: tags),
            sidewalkLeft: left, sidewalkRight: right,
            isCrossing: tags["footway"] == "crossing" || tags["crossing"] != nil && !kind.isVehicular,
            layer: tags["layer"].flatMap(TagParsing.integer) ?? 0,
            isBridge: tags["bridge"].map { $0 != "no" } ?? false,
            isTunnel: tags["tunnel"].map { $0 != "no" } ?? false
        )
    }

    // MARK: - Polygons

    /// Tags of the covered way whose ring is exactly this polygon's outer ring, if any.
    private func coveredTags(matching poly: Polygon2D, covered: [Int64: Tags], in doc: OSMDocument) -> Tags? {
        for id in covered.keys.sorted() {
            guard let way = doc.ways[id], way.nodeIDs.count - 1 == poly.outer.count,
                  let coords = doc.coordinates(of: way) else { continue }
            if coords.dropLast().map(frame.localPoint(of:)) == poly.outer { return covered[id] }
        }
        return nil
    }

    /// True if the tags carry a real `building=*` (not `no`). `building:part` alone does not count.
    static func isBuildingWay(_ t: Tags) -> Bool {
        if let b = t["building"], b != "no" { return true }
        return false
    }

    /// Keys a `type=building` relation passes down to an outline way that has no building tag.
    static func isBuildingTagKey(_ key: String) -> Bool {
        key == "building" || key.hasPrefix("building:") || key.hasPrefix("roof:")
            || key == "height" || key == "min_height"
    }

    private func classifyPolygon(ref: OSMRef, tags: Tags, polygon: Polygon2D, into out: inout MapFeatures) {
        if let type = Self.buildingType(tags) {
            // Buildings are kept whole if their centroid is inside the area (no half-houses).
            guard bounds.contains(polygon.centroid) else { return }
            guard let clean = polygon.cleaned(minArea: 1.0) else {
                out.report.skipped.append(.init(ref: ref, reason: "degenerate footprint"))
                return
            }
            let isPart = tags["building"] == nil
            out.buildings.append(Building(
                ref: ref, footprint: clean, tags: tags, type: type, isPart: isPart,
                height: heightRules.resolve(tags: tags, type: type, ref: ref)
            ))
            return
        }
        if let kind = Self.areaKind(tags) {
            guard let clipped = Clipping.clip(polygon, to: bounds) else { return }
            guard let clean = clipped.cleaned() else {
                out.report.skipped.append(.init(ref: ref, reason: "degenerate area"))
                return
            }
            out.areas.append(AreaFeature(ref: ref, kind: kind, polygon: clean, tags: tags))
        }
    }

    // MARK: - Tag rules

    /// The building type, or nil if not a building. `building:part` counts, with its part value.
    public static func buildingType(_ t: Tags) -> String? {
        if let b = t["building"], b != "no" { return b }
        if let p = t["building:part"], p != "no" { return p == "yes" ? "yes" : p }
        return nil
    }

    /// Area kind by tag, in priority order (water beats park, etc.).
    public static func areaKind(_ t: Tags) -> AreaFeature.Kind? {
        if t["natural"] == "water" || t["waterway"] == "riverbank" || t["water"] != nil
            || ["reservoir", "basin"].contains(t["landuse"] ?? "") { return .water }
        if t["leisure"] == "swimming_pool" { return .pool }
        if t["man_made"] == "pier" { return .pier }
        if t["natural"] == "wetland" { return .wetland }
        if ["sand", "beach"].contains(t["natural"] ?? "") { return .sand }
        if t["leisure"] == "pitch" { return .pitch }
        if t["leisure"] == "playground" { return .playground }
        if t["amenity"] == "parking" { return .parking }
        if t["highway"] == "pedestrian" || (t["highway"] != nil && t["area"] == "yes") { return .pedestrianArea }
        if t["natural"] == "wood" || t["landuse"] == "forest" { return .wood }
        if t["natural"] == "scrub" { return .scrub }
        if t["leisure"] == "garden" { return .garden }
        if ["grass", "village_green"].contains(t["landuse"] ?? "") { return .grass }
        if t["landuse"] == "meadow" || t["natural"] == "grassland" { return .meadow }
        if t["landuse"] == "cemetery" || t["amenity"] == "grave_yard" { return .cemetery }
        if t["leisure"] == "park" { return .park }
        if ["sports_centre", "recreation_ground", "common"].contains(t["leisure"] ?? "")
            || t["landuse"] == "recreation_ground" { return .recreation }
        if t["landuse"] == "residential" { return .residential }
        if ["commercial", "retail"].contains(t["landuse"] ?? "") { return .commercial }
        return nil
    }

    public static func pointKind(_ t: Tags) -> PointFeature.Kind? {
        if t["natural"] == "tree" { return .tree }
        if t["amenity"] == "bench" || t["leisure"] == "bench" { return .bench }
        if t["highway"] == "street_lamp" || t["man_made"] == "street_lamp" { return .streetLamp }
        if t["amenity"] == "waste_basket" { return .wasteBasket }
        if t["leisure"] == "picnic_table" || t["tourism"] == "picnic_site" && t["leisure"] == nil { return .picnicTable }
        if t["amenity"] == "drinking_water" { return .drinkingWater }
        if t["emergency"] == "fire_hydrant" { return .fireHydrant }
        if t["amenity"] == "bicycle_parking" { return .bicycleParking }
        if t["amenity"] == "toilets" && t["building"] == nil { return .toilets }
        if t["amenity"] == "post_box" { return .postBox }
        if t["barrier"] == "bollard" { return .bollard }
        if t["man_made"] == "flagpole" { return .flagpole }
        if t["playground"] != nil { return .playgroundEquipment }
        return nil
    }

    public static func lineKind(_ t: Tags) -> LineFeature.Kind? {
        if t["natural"] == "tree_row" { return .treeRow }
        switch t["barrier"] {
        case "hedge": return .hedge
        case "fence", "guard_rail", "railing": return .fence
        case "wall": return .wall
        case "retaining_wall": return .retainingWall
        case "kerb": return .kerb
        default: break
        }
        if ["stream", "ditch", "drain", "canal", "river"].contains(t["waterway"] ?? "") { return .stream }
        return nil
    }

    /// Reads `sidewalk`, `sidewalk:both`, `sidewalk:left`, `sidewalk:right`.
    /// Left/right are relative to the way's direction.
    static func sidewalks(_ t: Tags) -> (SidewalkState, SidewalkState) {
        func state(_ v: String?) -> SidewalkState? {
            switch v {
            case nil: return nil
            case "no", "none": return SidewalkState.none
            case "separate": return .separate
            default: return .tagged
            }
        }
        var left = SidewalkState.unknown, right = SidewalkState.unknown
        switch t["sidewalk"] {
        case "both", "yes": left = .tagged; right = .tagged
        case "left": left = .tagged; right = .none
        case "right": left = .none; right = .tagged
        case "no", "none": left = .none; right = .none
        case "separate": left = .separate; right = .separate
        default: break
        }
        if let both = state(t["sidewalk:both"]) { left = both; right = both }
        if let l = state(t["sidewalk:left"]) { left = l }
        if let r = state(t["sidewalk:right"]) { right = r }
        return (left, right)
    }
}
