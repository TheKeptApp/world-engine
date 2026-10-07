import Foundation
import simd
import WorldGen
import WorldGeo
import WorldMap

/// Confidence numbers of the map data layer (worldengine.map/2 §3 "Confidence"). Each estimated
/// value gets a score from a few features of the record, looked up in a calibration table: the
/// share of a validation sample in that feature bin whose generated value was right (yards:
/// outline IoU ≥ 0.6 with the yard cut from the real parcel; doors within 2 m and driveway ends
/// within 3 m of the point seen in 0.3 m aerial imagery; frontage: the addressed street). The
/// tables, their samples and the scripts that fit them: `docs/research/map-confidence.md`,
/// `Tools/regionkit/mapconf/`.
enum MapConfidence {
    struct Method {
        var id: String
        var field: String
        var version: Int
        var description: String
        var confidence: String
        /// Slope methods only (worldengine.map/2 §4, D-55): the method's calibrated confidence as a whole.
        var defaultConfidence: Double?

        var json: MapJSON {
            var o: [String: MapJSON] = ["id": .string(id), "field": .string(field), "version": .number(Double(version)),
                                        "description": .string(description), "confidence": .string(confidence)]
            if let d = defaultConfidence { o["defaultConfidence"] = .num(d) }
            return .object(o)
        }
    }

    // MARK: - Features

    static func frontageFeatures(building b: Building, generated g: GeneratedBuilding, context: StreetContext, distance: Double, street: OSMRef) -> [String: Any] {
        let name = context.streets.first { $0.ref == street }?.tags["name"]
        // A second, differently named street close by: a corner house, whose address may be on either.
        let other = context.streetIndex.nearest(to: b.footprint.centroid, within: 40) { context.streets[$0].tags["name"] != name }
        return ["source": b.ref.kind == .overture ? "overture" : "osm", "building": b.type, "role": g.role.rawValue,
                "distanceM": distance, "corner": other != nil, "otherStreetM": other?.distance ?? -1]
    }

    static func lotFeatures(building b: Building, generated g: GeneratedBuilding?, part: LotPart, frontage: Double?) -> [String: Any] {
        let area = abs(RingMath.signedArea(part.outline))
        return ["source": b.ref.kind == .overture ? "overture" : "osm", "building": b.type, "part": part.front ? "front" : "back",
                "areaM2": area, "droppedShare": part.droppedArea / max(1, area + part.droppedArea), "frontageM": frontage ?? -1,
                "footprintM2": abs(b.footprint.area), "family": g?.family ?? ""]
    }

    static func doorFeatures(building b: Building, generated g: GeneratedBuilding, frontage: Double?) -> [String: Any] {
        let ring = b.footprint.outer
        let edge = g.frontEdge.map { simd_distance(ring[$0], ring[($0 + 1) % ring.count]) } ?? 0
        return ["source": b.ref.kind == .overture ? "overture" : "osm", "building": b.type, "role": g.role.rawValue,
                "footprintM2": abs(b.footprint.area), "frontEdgeM": edge, "frontageM": frontage ?? -1, "family": g.family ?? ""]
    }

    static func drivewayFeatures(building b: Building, length: Double) -> [String: Any] {
        ["source": b.ref.kind == .overture ? "overture" : "osm", "building": b.type, "lengthM": length]
    }

    // MARK: - Scores (calibration tables)

    static func frontage(_ f: [String: Any]) -> Double { Calibration.frontage(f) }
    static func lot(_ f: [String: Any]) -> Double { Calibration.lot(f) }
    static func door(_ f: [String: Any]) -> Double { Calibration.door(f) }
    static func driveway(_ f: [String: Any]) -> Double { Calibration.driveway(f) }

    // MARK: - Methods

    static let frontageMethod = Method(
        id: "frontage/street-context-v1", field: "frontage", version: 1,
        description: "The named street the generator's StreetContext chose for the building's front edge (the nearest named vehicle street within 60 m of the footprint centroid); the segment is that street's network piece nearest the front door, offsetM and side measured at the door's projection onto it.",
        confidence: Calibration.frontageDefinition)
    static let lotMethod = Method(
        id: "lots/yard-v1", field: "lots", version: 1,
        description: "WorldGen's inferred yard (GeneratedLot, yard rules version 2): open ground nearest the building on a 1 m raster, never crossing roads, walkways or blocked land, up to the zone's maximum lot depth; split at the line of the building's front edge into front and back; the largest connected piece of each part. Mowable area: open lawn cells minus walks, driveways, planted front gardens, paved rear yards and foundation beds (tree trunks, about 0.07 m² each, are not subtracted).",
        confidence: Calibration.lotDefinition)
    static let entryMethod = Method(
        id: "entries/entry-v1", field: "entries", version: 1,
        description: "front_door: WorldGen's front door (GeneratedBuilding.entry) on the front edge. driveway_end: the end of WorldGen's generated driveway from a garage door to the street, alley or sidewalk, keyed by the house whose yard it crosses. No mailboxes or yard gates are generated.",
        confidence: Calibration.entryDefinition)
    static let slopeMethodID = "slope/lidar-dtm-v1"

    static func slopeMethod(_ t: MapTerrain) -> Method {
        var m = Method(id: slopeMethodID, field: "slope", version: 1, description: "", confidence: "")
        m.description = "Steepest 1 m cell slope over the lot's mowable lawn, at least 2 m from the building's walls (lot file); the grid holds every cell's slope. \(t.source.method) Lot records only where lidar ground returns cover at least 80 % of the lawn cells. Grid values are stored in 0.5 % steps; 127 % means at least 127 %."
        if let c = t.confidence {
            m.confidence = "slopeConfidence, the grid's confidence and defaultConfidence are the \(c.basis). Per lot: the share for the class of its slope (< 15 %: \(c.below15); ≥ 15 %: \(c.from15)); grid and default: over all validated cells (\(c.overall)). The lot value is the steepest of its cells, which this per-cell agreement does not fully cover (a maximum also picks up noise). Validation detail: \(t.source.validation)"
            m.defaultConfidence = c.overall
        } else {
            m.confidence = "No validation recorded for this grid: no confidence number is given."
        }
        return m
    }

    static func distance(_ p: LocalPoint, toRing r: Ring) -> Double {
        var best = Double.infinity
        for i in r.indices {
            let a = r[i], b = r[(i + 1) % r.count], d = b - a
            let len2 = simd_length_squared(d)
            let t = len2 > 0 ? min(1, max(0, simd_dot(p - a, d) / len2)) : 0
            best = min(best, simd_distance(p, a + d * t))
        }
        return best
    }
}
