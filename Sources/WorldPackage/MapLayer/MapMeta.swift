import Foundation
import WorldGeo
import WorldMap

/// Companion files of the map data layer (`mapmeta/*.json`, schema `worldengine.mapmeta/1`), kept
/// out of `map/` so the worldengine.map/2 files stay exactly as the contract defines them:
///
/// - `mapmeta/ids.json`: every exported ID's link to its source identity. Most IDs *are* their
///   source identity (`node/…`, `way/…`, `relation/…`); the file lists the ones that are not: road
///   segments (way + node range), Overture buildings (full GERS ID and dataset), lots and entry
///   points (the building they derive from).
/// - `mapmeta/provenance.json`: every exported field labelled observed, inferred or simulated,
///   with per-record exceptions (Overture footprints traced by machine learning are inferred).
/// - `mapmeta/migration.json` (when the export is given the previous package): old ID → new IDs for
///   every ID that disappeared between the two snapshots (`MapMigration`).
///
/// Rules and classes: `docs/data/map-layer.md`.
enum MapMeta {
    static let schema = "worldengine.mapmeta/1"
    static let idsPath = "mapmeta/ids.json"
    static let provenancePath = "mapmeta/provenance.json"
    static let migrationPath = "mapmeta/migration.json"

    static let idRules = """
    IDs are stable engine IDs derived from source identities (worldengine.map/2 §3). OSM nodes, ways, relations, places, \
    stops and OSM buildings use the OSM identity itself (type/id). Road segments: way/<osm way id>:<k>, k = index of the \
    piece along the way's full node list; the link gives the way and the node index range. Overture buildings: \
    overture/<the full GERS ID, 32 hex digits>; the link gives the GERS ID as Overture writes it. Lots gen:lot:<building>:<front|back> \
    and entry points gen:entry:<building>:<kind>[:<n>] derive from their building's ID. An ID changes only when its own \
    source element changes; when a source feature is split, merged or deleted, mapmeta/migration.json maps old IDs to \
    new ones for that snapshot pair.
    """

    /// `basis` text per class.
    static let classes: [String: String] = [
        "observed": "Taken from a source that mapped or measured it (OpenStreetMap, Overture from survey or authoritative data, U.S. Census ZCTA boundaries, USGS 3DEP lidar), or computed exactly from such values (lengths, centroids, containment, parsed units).",
        "inferred": "Estimated from observed data by a fixed rule, not checked against reality record by record (the street a house faces, yard outlines, driveways, the wall a door is on, machine-learned footprints). Each inferred value with a confidence carries a calibrated one.",
        "simulated": "Drawn from regional distributions with a seeded random choice: plausible, not evidence about this place (a door's position along its wall; front gardens, paved rear yards and foundation beds, which set mowable area).",
    ]

    /// Field → class for every field the layer writes.
    static let fields: [String: String] = [
        "network.nodes.position": "observed", "network.nodes.tags": "observed", "network.nodes.control": "observed",
        "network.nodes.controlApproaches": "inferred", "network.nodes.crossing": "observed", "network.nodes.context": "observed",
        "network.nodes.region": "observed", "network.nodes.regionsSpanned": "observed",
        "network.segments.from": "observed", "network.segments.to": "observed", "network.segments.way": "observed",
        "network.segments.geometry": "observed", "network.segments.lengthM": "observed", "network.segments.tags": "observed",
        "network.segments.highway": "observed", "network.segments.service": "observed", "network.segments.footway": "observed",
        "network.segments.oneway": "observed", "network.segments.junction": "observed", "network.segments.access": "observed",
        "network.segments.name": "observed", "network.segments.surface": "observed", "network.segments.widthM": "observed",
        "network.segments.lanes": "observed", "network.segments.lanesForward": "observed", "network.segments.lanesBackward": "observed",
        "network.segments.maxspeedKmh": "observed", "network.segments.gatedArea": "observed", "network.segments.context": "observed",
        "network.segments.region": "observed", "network.segments.regionsSpanned": "observed",
        "network.barriers": "observed", "network.gatedAreas": "observed", "network.turnRestrictions": "observed",
        "buildings.source": "observed", "buildings.building": "observed", "buildings.isPart": "observed", "buildings.footprint": "observed",
        "buildings.centroid": "observed", "buildings.hasHouseNumber": "observed", "buildings.hasAddrStreet": "observed",
        "buildings.region": "observed", "buildings.regionsSpanned": "observed",
        "buildings.frontage.segment": "inferred", "buildings.frontage.offsetM": "simulated", "buildings.frontage.side": "inferred",
        "buildings.frontage.confidence": "observed",
        "lots.building": "inferred", "lots.part": "inferred", "lots.polygon": "inferred", "lots.areaM2": "inferred",
        "lots.mowableAreaM2": "simulated", "lots.confidence": "observed",
        "lotSlope.slopePercent": "observed", "lotSlope.slopeConfidence": "observed", "terrainSlope": "observed",
        "buildings.context": "observed", "places.context": "observed", "network.segments.fullTags": "observed",
        "entries.front_door.position": "simulated", "entries.front_door.normal": "inferred", "entries.front_door.lot": "inferred",
        "entries.driveway_end.position": "inferred", "entries.confidence": "observed",
        "places": "observed", "transit": "observed",
    ]

    /// Notes on fields whose class needs a word.
    static let notes: [String: String] = [
        "network.nodes.controlApproaches": "A stop or give-way sign mapped on a way within 30 m of a junction is assigned to that junction and approach.",
        "buildings.frontage.offsetM": "Measured to the front door, whose position along its wall is simulated.",
        "buildings.frontage.confidence": "Calibrated against a validation sample (methods[].confidence in map/layer.json).",
        "lotSlope.slopePercent": "Measured by lidar (independent/lot-slope.json), over an inferred lawn outline.",
        "lotSlope.slopeConfidence": "Calibrated against the slope grid's validation (methods[].confidence in map/layer.json).",
        "lots.confidence": "Calibrated against a validation sample (methods[].confidence in map/layer.json).",
        "entries.confidence": "Calibrated against a validation sample (methods[].confidence in map/layer.json).",
        "entries.front_door.position": "The wall (front edge) is inferred; the position along it is a seeded draw from the regional house type.",
    ]

    /// Overture footprint datasets traced by machine learning (their footprints are inferred).
    static func isMachineLearned(_ dataset: String?) -> Bool {
        guard let d = dataset?.lowercased() else { return false }
        return d.contains("ml buildings") || d.contains("open buildings") || d.contains("machine")
    }

    static func ids(snapshot: String, segments: [MapNetwork.Segment], overture: [Building]) -> MapJSON {
        let seg: [[String: MapJSON]] = segments.map { s in
            ["id": .string(s.id), "osm": .string("way/\(s.way)"), "nodeRange": .array([.number(Double(s.range.lowerBound)), .number(Double(s.range.upperBound))]),
             "fromNode": .string("node/\(s.nodeIDs.first!)"), "toNode": .string("node/\(s.nodeIDs.last!)")]
        }
        let ov: [[String: MapJSON]] = overture.map { b in
            var r: [String: MapJSON] = ["id": .string(b.ref.description), "gers": .string(b.tags["overture:id"] ?? "")]
            if let d = b.tags["overture:geometry_source"] { r["geometryDataset"] = .string(d) }
            return r
        }
        return .object([
            "schema": .string(schema), "file": .string("ids"), "mapSnapshotID": .string(snapshot), "rules": .string(idRules),
            "identity": MapJSON.strings(["network.nodes", "network.barriers", "network.gatedAreas", "network.turnRestrictions",
                                         "buildings (source osm)", "places", "transit.stops", "transit.routes"]),
            "derived": .object(["lots": .string("gen:lot:<building id>:<part>"), "entries": .string("gen:entry:<building id>:<kind>[:<n>]")]),
            "segments": .array(MapJSON.sortedByID(seg)), "overtureBuildings": .array(MapJSON.sortedByID(ov)),
        ])
    }

    static func provenance(snapshot: String, overture: [Building]) -> MapJSON {
        let records: [[String: MapJSON]] = overture.compactMap { b in
            let d = b.tags["overture:geometry_source"]
            guard isMachineLearned(d) else { return nil }
            return ["id": .string(b.ref.description), "collection": .string("buildings"), "field": .string("footprint"),
                    "class": .string("inferred"), "basis": .string("Footprint traced by machine learning from imagery (\(d ?? "")); centroid and region follow it.")]
        }
        return .object([
            "schema": .string(schema), "file": .string("provenance"), "mapSnapshotID": .string(snapshot),
            "classes": .object(classes.mapValues { .string($0) }),
            "fields": .object(fields.mapValues { .string($0) }),
            "notes": .object(notes.mapValues { .string($0) }),
            "records": .array(MapJSON.sortedByID(records)),
        ])
    }
}
