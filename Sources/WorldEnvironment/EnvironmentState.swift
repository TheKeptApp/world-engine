import Foundation
import WorldGen
import WorldGeo

/// Encodes nil as JSON `null` (unknown), never omitting the key: the contract distinguishes
/// unknown (null) from known absence (0).
@propertyWrapper
public struct Nullable<T: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    public var wrappedValue: T?
    public init(wrappedValue: T?) { self.wrappedValue = wrappedValue }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        wrappedValue = c.decodeNil() ? nil : try c.decode(T.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if let v = wrappedValue { try c.encode(v) } else { try c.encodeNil() }
    }
}

extension KeyedDecodingContainer {
    public func decode<T>(_ type: Nullable<T>.Type, forKey key: Key) throws -> Nullable<T> {
        try decodeIfPresent(type, forKey: key) ?? Nullable(wrappedValue: nil)
    }
}

/// The versioned, renderer-neutral environment for one moment (weather spec §1 + sky-seasons §1).
/// One resolver produces it; RealityKit and three.js both consume it; neither calls a service.
public struct EnvironmentDocument: Codable, Sendable, Equatable {
    public static let schemaVersion = "worldengine.environment/1"

    public var schemaVersion: String
    public var identity: Identity
    public var location: Location
    public var time: Time
    public var provenance: Provenance
    public var inputs: WeatherSample?
    public var state: State
    public var light: Light
    public var presentation: Presentation
    public var continuity: Continuity
    public var sky: Sky
    public var phenology: PhenologyState?

    public struct Identity: Codable, Sendable, Equatable {
        public var environmentModel: String
        public var weatherModel: String
        public var solarModel: String
        public var lunarModel: String
        public var starModel: String
        public var phenologyModel: String
        public var timezoneDataVersion: String
        public var starCatalogSHA256: String?
        public var seed: UInt64
        public var qualityTier: String
    }

    public struct Location: Codable, Sendable, Equatable {
        /// Provider-facing coarse cell (never a home point).
        public var cellID: String?
        public var cellCenter: GeoCoordinate?
        /// The world's astronomical reference point (package reference, independent of the cell).
        public var observer: SkyObserver
    }

    public struct Time: Codable, Sendable, Equatable {
        /// Source (recorded-world) time, UTC — not playback wall-clock time.
        public var validTime: Date
        @Nullable public var intervalStart: Date?
        @Nullable public var intervalEnd: Date?
        @Nullable public var fetchedAt: Date?
        @Nullable public var expiresAt: Date?
        public var mode: Mode
        public enum Mode: String, Codable, Sendable { case live, recap, demo }
    }

    public struct Provenance: Codable, Sendable, Equatable {
        public var provider: String
        public var dataKind: String
        public var flags: [String]
        @Nullable public var attribution: WeatherAttributionInfo?
    }

    public struct State: Codable, Sendable, Equatable {
        @Nullable public var dominantState: DominantState?
        @Nullable public var intensity01: Double?
        public var assumedIntensity: Bool
        @Nullable public var displayFallback: DominantState?
        @Nullable public var cloudCover01: Double?
        @Nullable public var visibilityM: Double?
        public var wind: WindState
        @Nullable public var wetness01: Double?
        @Nullable public var snowCover01: Double?
        @Nullable public var snowWaterEquivalentMm: Double?
        public var accumulationStatus: String
        public var initialState: String
        public var conflict: Bool
    }

    public struct Light: Codable, Sendable, Equatable {
        public var sunElevationDeg: Double
        public var sunAzimuthDeg: Double
        public var sunDirection: SIMD3<Double>
        public var branch: String
        /// The time-of-day light (v2 keys, linear light inside), before weather.
        public var timeOfDay: LightingState
        /// Weather and cloud multiplier on the time-of-day key's sun (whose intensity already carries
        /// the 0–2° horizon fade): direct sun = timeOfDay.sunIntensity × directStrength.
        public var directStrength: Double
        public var weather: WeatherAppearance
        /// R8 fill strengths after the moon term (sky 0.20–0.35, ground 0.06–0.12).
        public var fillSky: Double
        public var fillGround: Double
        /// Lunar contribution B = k² (1 − C)² G and the moon disk opacity gate.
        public var moonFill: Double
        public var moonDiskOpacity: Double
        public var starStrength: Double
    }

    public struct Presentation: Codable, Sendable, Equatable {
        public var particles: ParticleBudget
        public var transitionSeconds: [String: Double]
        public var wetDarkeningMax: Double
        public var wetRoughness: Double
        public var lightning: Bool
        public var sound: Bool
    }

    public struct Continuity: Codable, Sendable, Equatable {
        @Nullable public var checkpointTime: Date?
        public var accumulationModelVersion: String
        public var uncertainty: [String]
    }

    public struct Sky: Codable, Sendable, Equatable {
        @Nullable public var sunDay: SunDay?
        public var moon: MoonState
        @Nullable public var moonDay: MoonDay?
        public var stars: StarField
        public var starAttribution: String
    }

    /// Serialized JSON (sorted keys, ISO 8601 dates, no NaN/infinity).
    public func json() throws -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        e.nonConformingFloatEncodingStrategy = .throw
        return try e.encode(self)
    }

    public static func decode(_ data: Data) throws -> EnvironmentDocument {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let doc = try d.decode(EnvironmentDocument.self, from: data)
        guard doc.schemaVersion.hasPrefix("worldengine.environment/1") else { throw DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "unsupported environment schema \(doc.schemaVersion)")) }
        return doc
    }
}

/// Moon light on the night scene (sky-seasons §3.2): B = k² × (1 − C)² × G, G = smoothstep(0°, 3°, h).
public enum MoonLight {
    public static func fill(illuminatedFraction k: Double, cloud: Double?, altitudeDeg: Double) -> Double {
        guard let c = cloud else { return 0 } // unknown cloud: labeled zero fallback
        return k * k * pow(1 - EnvMath.clamp01(c), 2) * EnvMath.smoothstep(0, 3, altitudeDeg)
    }

    /// Disk opacity: G × [1 − smoothstep(0.35, 0.75, C)] × (1 − O); zero in active precipitation.
    public static func diskOpacity(altitudeDeg: Double, cloud: Double?, obscuration: Double, activePrecipitation: Bool) -> Double {
        guard let c = cloud, !activePrecipitation, altitudeDeg > 0 else { return 0 }
        return EnvMath.smoothstep(0, 3, altitudeDeg) * (1 - EnvMath.smoothstep(0.35, 0.75, c)) * (1 - EnvMath.clamp01(obscuration))
    }
}
