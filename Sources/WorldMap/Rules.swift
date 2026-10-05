import Foundation
import WorldGeo

/// How building heights are filled in when OSM has no `height` tag.
/// Data, not code: apps and future data sources (Overture, lidar) can replace any of it.
public struct HeightRules: Sendable {
    public var metersPerLevel = 3.2
    /// Height by `building=*` value when neither `height` nor `building:levels` is tagged.
    public var typeDefaults: [String: Double] = [
        "house": 7.0, "detached": 7.0, "semidetached_house": 7.0, "bungalow": 4.5,
        "residential": 8.0, "terrace": 8.0,
        "garage": 3.0, "garages": 3.0, "carport": 3.0,
        "shed": 2.5, "hut": 2.5, "cabin": 3.5,
        "roof": 3.0,
        "apartments": 12.8,
        "commercial": 5.0, "retail": 5.0, "kiosk": 3.0, "supermarket": 6.0,
        "office": 10.0,
        "church": 10.0, "chapel": 8.0,
        "school": 8.0, "university": 12.0, "civic": 8.0, "public": 8.0,
        "industrial": 7.0, "warehouse": 7.0,
        "toilets": 3.0, "service": 3.0, "boathouse": 4.0,
    ]
    public var fallbackDefault = 6.0
    /// Seeded ±fraction applied to fallback heights so identical houses don't look stamped out.
    public var jitterFraction = 0.10

    public init() {}

    public func resolve(tags: Tags, type: String, ref: OSMRef) -> BuildingHeight {
        let base = tags["min_height"].flatMap(TagParsing.length)
            ?? tags["building:min_level"].flatMap(TagParsing.number).map { $0 * metersPerLevel }
            ?? 0

        if let h = tags["height"].flatMap(TagParsing.length) {
            return BuildingHeight(base: base, top: max(h, base + 0.5), source: .heightTag)
        }
        var rng = ref.random("height-jitter")
        let jitter = 1 + rng.range(-jitterFraction, jitterFraction)
        if let levels = tags["building:levels"].flatMap(TagParsing.number), levels > 0 {
            let roofLevels = tags["roof:levels"].flatMap(TagParsing.number) ?? 0
            let h = (levels + roofLevels) * metersPerLevel * jitter
            return BuildingHeight(base: base, top: max(h, base + 0.5), source: .levels)
        }
        let h = (typeDefaults[type] ?? fallbackDefault) * jitter
        return BuildingHeight(base: base, top: max(h, base + 0.5), source: .typeDefault)
    }
}

/// How road and path widths are chosen when OSM has no `width` tag.
public struct RoadRules: Sendable {
    public var laneWidth = 3.3
    public var defaultWidths: [HighwayKind: Double] = [
        .motorway: 14, .trunk: 13, .primary: 12, .secondary: 10, .tertiary: 8,
        .residential: 6, .unclassified: 6, .livingStreet: 5, .road: 6, .busway: 6,
        .service: 4, .track: 3,
        .pedestrian: 4, .cycleway: 2.5, .footway: 2, .path: 2, .bridleway: 2.5, .steps: 2,
        .corridor: 2, .other: 3,
    ]

    public init() {}

    public func width(kind: HighwayKind, tags: Tags) -> Double {
        if let w = tags["width"].flatMap(TagParsing.length), w <= 60 { return w }
        if kind.isVehicular, let lanes = tags["lanes"].flatMap(TagParsing.integer), lanes > 0, lanes < 12 {
            return Double(lanes) * laneWidth
        }
        return defaultWidths[kind] ?? 3
    }
}
