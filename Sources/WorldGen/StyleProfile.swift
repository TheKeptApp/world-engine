import Foundation
import WorldGeo

/// A regional style profile: the look of generated detail where OSM is silent.
/// Pure data (JSON in `Profiles/`). Real OSM tags always win over profile choices.
public struct StyleProfile: Codable, Sendable, Equatable {
    public struct WeightedColor: Codable, Sendable, Equatable {
        public var color: String
        public var weight: Double
    }

    public struct RoofMix: Codable, Sendable, Equatable {
        public var gabled: Double
        public var hipped: Double
        public var flat: Double
    }

    public struct Trees: Codable, Sendable, Equatable {
        /// Share of trees that are deciduous when OSM has no `leaf_type`; the rest are conifers.
        public var deciduousShare: Double
    }

    public struct Houses: Codable, Sendable, Equatable {
        public var roofMix: RoofMix
        public var roofPitchDegrees: [Double]
        public var overhangMeters: [Double]
        public var porchLikelihood: Double
        public var chimneyLikelihood: Double
        public var foundationMeters: [Double]
        public var windowSpacingMeters: [Double]
        public var sidingPalette: [WeightedColor]
        public var trimPalette: [WeightedColor]
        public var roofPalette: [WeightedColor]
        public var doorPalette: [WeightedColor]
    }

    public struct Garages: Codable, Sendable, Equatable {
        /// "alleyThenStreet": garage doors face the nearest alley/service road, else the street.
        public var doorFacing: String
        public var doubleDoorMinWidthMeters: Double
        public var roofMix: RoofMix
        public var wallHeightMeters: [Double]
    }

    public var id: String
    public var name: String
    public var trees: Trees
    public var houses: Houses
    public var garages: Garages
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

/// Loads the bundled profile data.
public enum StyleLibrary {
    public enum LoadError: Error { case missing(String) }

    static func data(_ name: String) throws -> Data {
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

    /// Named base colors shared by all regions.
    public static func baseColors() throws -> [String: String] {
        struct File: Codable { var colors: [String: String] }
        return try JSONDecoder().decode(File.self, from: data("base-palette")).colors
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
