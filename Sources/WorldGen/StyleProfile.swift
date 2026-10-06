import Foundation
import WorldGeo

/// A regional style profile: the look of generated detail where OSM is silent.
/// Pure data (JSON in `Profiles/`). Real OSM tags always win over profile choices.
public struct StyleProfile: Codable, Sendable, Equatable {
    public struct RoofMix: Codable, Sendable, Equatable {
        public var gabled: Double
        public var hipped: Double
        public var flat: Double
    }

    public struct Seasons: Codable, Sendable, Equatable {
        public var hemisphere: String
        public var spring: [Int]
        public var summer: [Int]
        public var autumn: [Int]
        public var winter: [Int]

        /// Season index (0 spring, 1 summer, 2 autumn, 3 winter) for a month 1–12.
        public func season(month: Int) -> Int {
            if spring.contains(month) { return 0 }
            if summer.contains(month) { return 1 }
            if autumn.contains(month) { return 2 }
            if winter.contains(month) { return 3 }
            return 1 // unknown → neutral summer (v2 §3.2)
        }
    }

    public struct Trees: Codable, Sendable, Equatable {
        /// Share of trees that are deciduous when OSM has no `leaf_type`; the rest are conifers.
        public var deciduousShare: Double
        /// Crown archetype weights: broad rounded, upright oval, open spreading.
        public var crownWeights: [String: Double]
        public var heightMeters: [Double]
        public var youngShare: Double
        public var youngHeightMeters: [Double]
        /// Optional, zone level: measured share (0–1) of the ground covered by tree crowns, from leaf-on
        /// aerial imagery (e.g. a NAIP canopy mask over a sample cell). The generator calibrates
        /// generated yard trees toward it (`yards.json` `canopyFill`); absent → behaviour unchanged. Decoded with
        /// `decodeIfPresent` (synthesized `Codable` for an optional), so older JSON still decodes.
        public var canopyShare: Double?
    }

    public struct Porch: Codable, Sendable, Equatable {
        public var likelihood: Double
        public var depth: [Double]
        /// Share of the front facade the porch spans.
        public var frontage: [Double]
        /// covered | stoop | entry | canopy
        public var style: String
    }

    public struct Windows: Codable, Sendable, Equatable {
        /// One window bay per this many meters of facade.
        public var bay: [Double]
        public var width: [Double]
        public var height: [Double]
        /// Width of one broad living-room window on the front (ranch), if any.
        public var broad: [Double]?
    }

    public struct HouseType: Codable, Sendable, Equatable {
        public var id: String
        /// Eligible floor counts (first is the default when OSM has no levels).
        public var floors: [Int]
        /// Wall height per floor.
        public var perFloor: [Double]
        public var minAspect: Double?
        public var maxAspect: Double?
        public var minRectangularity: Double?
        /// Requires the long side of the footprint to face the street.
        public var broadFrontage: Bool?
        public var roof: RoofMix
        public var pitch: [Double]
        public var overhang: [Double]
        public var parapet: [Double]?
        public var porch: Porch
        public var windows: Windows
        /// Door position(s) as a share of the front facade.
        public var door: [Double]
        /// Coordinated tuples: [wall, trim, door, roof].
        public var colors: [[String]]
    }

    public struct Thresholds: Codable, Sendable, Equatable {
        /// Absolute footprint areas (m²) for the `small` / `large` situations and the huge-house limit.
        /// They are the fallback when the percentile fields below are absent or the area has too few houses.
        public var smallArea: Double
        public var largeArea: Double
        public var hugeArea: Double
        public var broadAspect: Double
        public var squareAspect: Double
        public var squareRectangularity: Double
        public var narrowAspect: Double
        /// Optional size thresholds relative to the local houses, as quantiles (0–1) of the area's house
        /// footprint areas. Generator rule (`Thresholds.resolved(houseAreas:minCandidates:)` in HouseFamilies.swift): if a percentile is present and
        /// the area has at least 30 house candidates, that threshold = this percentile of the area's house
        /// footprint areas; otherwise use the absolute m² value above. Expected order when present:
        /// small < large < huge. Absent → behaviour unchanged (absolute values). Decoded with
        /// `decodeIfPresent` (synthesized `Codable` for optionals), so older JSON still decodes.
        public var smallAreaPercentile: Double?
        /// See `smallAreaPercentile`; replaces `largeArea` under the same rule.
        public var largeAreaPercentile: Double?
        /// See `smallAreaPercentile`; replaces `hugeArea` under the same rule.
        public var hugeAreaPercentile: Double?
    }

    public struct Outbuilding: Codable, Sendable, Equatable {
        public var wallHeight: [Double]
        public var roof: RoofMix?
        public var pitch: [Double]
        public var overhang: [Double]
        public var doubleDoorMinWidthMeters: Double?
        public var colors: [[String]]
    }

    public var id: String
    public var version: Int
    public var name: String
    public var seasons: Seasons
    public var trees: Trees
    public var houseTypes: [HouseType]
    /// Situation key → type weights (v2 §4.4). Keys: oneFloorBroad, oneFloor, twoFloorSquare,
    /// twoFloorNarrow, twoFloor, threeFloor, unknown, small, large, semidetached.
    public var typeRules: [String: [String: Double]]
    public var typeThresholds: Thresholds
    public var garage: Outbuilding
    public var shed: Outbuilding
    public var chimneyLikelihood: Double
    public var foundationMeters: [Double]

    /// Decoded keys. Anything else in a profile file is ignored by the decoder: a top-level `"comment"`
    /// string and a top-level `"provenance"` object (per-field status/source notes for reviewers) are
    /// documentation only.
    enum CodingKeys: String, CodingKey {
        case id, version, name, seasons, trees, houseTypes, typeRules, typeThresholds, garage, shed, chimneyLikelihood, foundationMeters
    }

    /// The optional fields of `Trees` and `Thresholds` (`canopyShare`, `*AreaPercentile`) are decoded by
    /// those types' synthesized `Codable` (`decodeIfPresent`), so this decoder needs no change for them.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        version = try c.decode(Int.self, forKey: .version)
        name = try c.decode(String.self, forKey: .name)
        seasons = try c.decode(Seasons.self, forKey: .seasons)
        trees = try c.decode(Trees.self, forKey: .trees)
        houseTypes = try c.decode([HouseType].self, forKey: .houseTypes)
        // typeRules may contain a "comment" string; keep only weight maps.
        let raw = try c.decode([String: AnyWeights].self, forKey: .typeRules)
        typeRules = raw.compactMapValues(\.weights)
        typeThresholds = try c.decode(Thresholds.self, forKey: .typeThresholds)
        garage = try c.decode(Outbuilding.self, forKey: .garage)
        shed = try c.decode(Outbuilding.self, forKey: .shed)
        chimneyLikelihood = try c.decode(Double.self, forKey: .chimneyLikelihood)
        foundationMeters = try c.decode([Double].self, forKey: .foundationMeters)
    }

    public func houseType(_ id: String) -> HouseType? { houseTypes.first { $0.id == id } }
}

/// Decodes either a weight map or a comment string.
private struct AnyWeights: Decodable {
    var weights: [String: Double]?
    init(from decoder: Decoder) throws {
        weights = try? decoder.singleValueContainer().decode([String: Double].self)
    }
}

/// Regions (in data) that select a profile by location.
public struct RegionCatalog: Codable, Sendable {
    public struct Region: Codable, Sendable {
        public var id: String
        public var profile: String
        public var bounds: GeoBoundingBox
    }

    public var defaultProfile: String
    public var regions: [Region]

    /// The profile ID for a location: the first region containing it, else the default.
    public func profileID(at c: GeoCoordinate) -> String {
        regions.first { $0.bounds.contains(c) }?.profile ?? defaultProfile
    }
}

/// v2 §3.2: seasonal surface colors.
public struct SeasonalPalette: Codable, Sendable {
    public var seasons: [String]
    /// Surface key → four hex colors (spring, summer, autumn, winter).
    public var surfaces: [String: [String]]

    /// Surface keys in a fixed order. Variant families stay contiguous so shaders can offset
    /// from the first slot (deciduous1…4, conifer1…2).
    public static let order = [
        "ground", "lawn", "tufts", "deciduous1", "deciduous2", "deciduous3", "deciduous4",
        "conifer1", "conifer2", "bushes", "road", "sidewalk", "curb", "water", "sand", "bark", "snow",
        "backdrop",
        // Lot lawn endpoint pair (look-fix §1.1); scenes override them per area profile.
        "lawnA", "lawnB",
    ]
}

/// Weather atmosphere presets (weather.json, weather v1 §5 / v2 §3.4).
public struct WeatherTable: Codable, Sendable {
    public struct State: Codable, Sendable, Equatable {
        public var tint: String?
        public var tintWeight: Double
        public var sunMultiplier: Double
        public var fogStartScale: Double
        public var fogEndScale: Double
        /// Absolute street / aerial fog distances (fog label), metres.
        public var fog: [Double]?
        public var aerialFog: [Double]?
    }
    public struct WetResponse: Codable, Sendable, Equatable {
        public var albedoDarkening: Double, roughnessDry: Double, roughnessWet: Double, roadRoughnessWet: Double, sidewalkRoughnessWet: Double
    }
    public var version: Int
    public var states: [String: State]
    public var wetResponse: WetResponse
}

/// v2 §3.3 time-of-day keys and §3.4 weather states.
public struct LightingTables: Codable, Sendable {
    public struct Key: Codable, Sendable, Equatable {
        public var sun: String
        public var sunIntensity: Double
        public var skyTop: String
        public var skyHorizon: String
        public var ambientSky: String
        public var ambientGround: String
        public var fog: String
        public var fogStart: Double
        public var fogEnd: Double
        public var shadowTint: String
        public var litWindows: Double
        /// Exposure multiplier applied to all scene light before tone mapping (v2 R9 "exposure
        /// anchored before grade"; sunIntensity is not an exposure). Golden hour = 1.
        public var exposure: Double?
    }

    public struct Fill: Codable, Sendable, Equatable {
        public var sky: Double
        public var ground: Double
    }

    public var keys: [String: Key]
    public var anchors: [String: Double]
    public var fill: Fill
}

/// Loads the bundled profile data.
public enum StyleLibrary {
    public enum LoadError: Error { case missing(String) }

    public static func data(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Profiles") else {
            throw LoadError.missing(name)
        }
        return try Data(contentsOf: url)
    }

    public static func regions() throws -> RegionCatalog {
        try JSONDecoder().decode(RegionCatalog.self, from: data("regions"))
    }

    public static func profile(id: String) throws -> StyleProfile {
        try JSONDecoder().decode(StyleProfile.self, from: data(id))
    }

    /// The profile selected for a location by the region catalog.
    public static func profile(at c: GeoCoordinate) throws -> StyleProfile {
        try profile(id: regions().profileID(at: c))
    }

    /// Named season-independent colors shared by all regions.
    public static func baseColors() throws -> [String: String] {
        struct File: Codable { var colors: [String: String] }
        return try JSONDecoder().decode(File.self, from: data("base-palette")).colors
    }

    public static func seasonalPalette() throws -> SeasonalPalette {
        try JSONDecoder().decode(SeasonalPalette.self, from: data("seasonal-palette"))
    }

    /// Weather atmosphere presets.
    public static func weather() throws -> WeatherTable {
        try JSONDecoder().decode(WeatherTable.self, from: data("weather"))
    }

    public static func lighting() throws -> LightingTables {
        try JSONDecoder().decode(LightingTables.self, from: data("time-of-day"))
    }

    /// Display policy (render scale, pausing).
    public static func display() throws -> DisplayPolicy {
        try JSONDecoder().decode(DisplayPolicy.self, from: data("display"))
    }
}

extension StableRandom {
    /// Picks from weighted items.
    public mutating func pick<T>(_ items: [T], weight: (T) -> Double) -> T {
        let total = items.reduce(0) { $0 + max(0, weight($1)) }
        var r = unit() * total
        for item in items {
            r -= max(0, weight(item))
            if r < 0 { return item }
        }
        return items[items.count - 1]
    }

    public mutating func range(_ r: [Double]) -> Double {
        r.count >= 2 ? range(r[0], r[1]) : (r.first ?? 0)
    }

    public mutating func chance(_ p: Double) -> Bool { unit() < p }
}
