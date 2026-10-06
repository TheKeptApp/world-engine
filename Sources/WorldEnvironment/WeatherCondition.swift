import Foundation

/// Apple WeatherKit's `WeatherCondition` cases (34, Swift names, checked 2026-10-05). Raw values
/// are the Swift case names; a REST adapter keeps the provider's own wire string separately.
public enum WeatherConditionCode: String, CaseIterable, Codable, Sendable {
    case blowingDust, clear, cloudy, foggy, haze, mostlyClear, mostlyCloudy, partlyCloudy, smoky
    case breezy, windy
    case drizzle, heavyRain, isolatedThunderstorms, rain, sunShowers, scatteredThunderstorms, strongStorms, thunderstorms
    case frigid, hail, hot
    case flurries, sleet, snow, sunFlurries, wintryMix, blizzard, blowingSnow
    case freezingDrizzle, freezingRain, heavySnow
    case hurricane, tropicalStorm
}

/// The nine atmospheric labels of the weather proposal.
public enum DominantState: String, CaseIterable, Codable, Sendable {
    case clear, cloudy, rain, snow, fog, haze, smoke, dust, thunderstorm

    /// Labels whose particles/accumulation come from precipitation.
    public var isPrecipitation: Bool { self == .rain || self == .snow || self == .thunderstorm }
    /// Haze, smoke, dust and fog share the obscuration (fog) implementation.
    public var isObscuration: Bool { self == .fog || self == .haze || self == .smoke || self == .dust }
}

/// How a code's intensity is computed (weather spec §2). Defaults are used, with an
/// assumed-intensity flag, when the quantitative input is missing or invalid.
public enum IntensityRule: Sendable, Equatable {
    case fixed(Double)
    case cloud(default: Double)
    case rain(default: Double)
    case snow(default: Double)
    case visibility(default: Double)
}

/// Extra handling carried with a code (independent channels, never collapsed into the label).
public struct ConditionFlags: OptionSet, Sendable, Hashable, Codable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    /// Visible sun is preserved (sun showers/flurries): direct-light floor 0.65.
    public static let sunFloor = ConditionFlags(rawValue: 1 << 0)
    public static let hail = ConditionFlags(rawValue: 1 << 1)
    public static let freezing = ConditionFlags(rawValue: 1 << 2)
    public static let tropicalHazard = ConditionFlags(rawValue: 1 << 3)
    public static let hot = ConditionFlags(rawValue: 1 << 4)
    public static let frigid = ConditionFlags(rawValue: 1 << 5)
    /// Wind-only label (breezy/windy): wind is measured independently.
    public static let windLabel = ConditionFlags(rawValue: 1 << 6)
    /// Mixed or frozen phase retained (sleet, wintry mix).
    public static let mixedPhase = ConditionFlags(rawValue: 1 << 7)
    /// Blowing snow: resuspended snow, never new snowfall or accumulation.
    public static let blowingSnow = ConditionFlags(rawValue: 1 << 8)
    /// Storm or obscuration code that wins its label over quantitative overrides.
    public static let explicitLabel = ConditionFlags(rawValue: 1 << 9)
}

/// Precipitation phase reported or implied by a code.
public enum PrecipitationPhase: String, Codable, Sendable {
    case liquid, frozen, mixed
}

public struct ConditionMapping: Sendable, Equatable {
    public var state: DominantState
    public var rule: IntensityRule
    public var flags: ConditionFlags
    /// The phase the code implies (nil: none / not a precipitation code).
    public var phase: PrecipitationPhase?

    /// Weather spec §2 table, all 34 codes.
    public static func of(_ code: WeatherConditionCode) -> ConditionMapping {
        switch code {
        case .blowingDust: .init(state: .dust, rule: .visibility(default: 0.65), flags: .explicitLabel, phase: nil)
        case .clear: .init(state: .clear, rule: .fixed(1), flags: [], phase: nil)
        case .cloudy: .init(state: .cloudy, rule: .cloud(default: 1.00), flags: [], phase: nil)
        case .foggy: .init(state: .fog, rule: .visibility(default: 0.70), flags: .explicitLabel, phase: nil)
        case .haze: .init(state: .haze, rule: .visibility(default: 0.35), flags: .explicitLabel, phase: nil)
        case .mostlyClear: .init(state: .clear, rule: .fixed(1), flags: [], phase: nil)
        case .mostlyCloudy: .init(state: .cloudy, rule: .cloud(default: 0.75), flags: [], phase: nil)
        case .partlyCloudy: .init(state: .cloudy, rule: .cloud(default: 0.50), flags: [], phase: nil)
        case .smoky: .init(state: .smoke, rule: .visibility(default: 0.60), flags: .explicitLabel, phase: nil)
        case .breezy: .init(state: .clear, rule: .fixed(1), flags: .windLabel, phase: nil)
        case .windy: .init(state: .clear, rule: .fixed(1), flags: .windLabel, phase: nil)
        case .drizzle: .init(state: .rain, rule: .rain(default: 0.15), flags: [], phase: .liquid)
        case .heavyRain: .init(state: .rain, rule: .rain(default: 0.90), flags: [], phase: .liquid)
        case .isolatedThunderstorms: .init(state: .thunderstorm, rule: .fixed(0.45), flags: .explicitLabel, phase: nil)
        case .rain: .init(state: .rain, rule: .rain(default: 0.50), flags: [], phase: .liquid)
        case .sunShowers: .init(state: .rain, rule: .rain(default: 0.30), flags: .sunFloor, phase: .liquid)
        case .scatteredThunderstorms: .init(state: .thunderstorm, rule: .fixed(0.60), flags: .explicitLabel, phase: nil)
        case .strongStorms: .init(state: .thunderstorm, rule: .fixed(0.90), flags: .explicitLabel, phase: nil)
        case .thunderstorms: .init(state: .thunderstorm, rule: .fixed(0.70), flags: .explicitLabel, phase: nil)
        case .frigid: .init(state: .clear, rule: .fixed(1), flags: .frigid, phase: nil)
        case .hail: .init(state: .rain, rule: .rain(default: 0.60), flags: .hail, phase: .liquid)
        case .hot: .init(state: .clear, rule: .fixed(1), flags: .hot, phase: nil)
        case .flurries: .init(state: .snow, rule: .snow(default: 0.15), flags: [], phase: .frozen)
        case .sleet: .init(state: .snow, rule: .snow(default: 0.45), flags: .mixedPhase, phase: .frozen)
        case .snow: .init(state: .snow, rule: .snow(default: 0.50), flags: [], phase: .frozen)
        case .sunFlurries: .init(state: .snow, rule: .snow(default: 0.20), flags: .sunFloor, phase: .frozen)
        case .wintryMix: .init(state: .snow, rule: .snow(default: 0.45), flags: .mixedPhase, phase: .mixed)
        case .blizzard: .init(state: .snow, rule: .fixed(1.00), flags: .explicitLabel, phase: .frozen)
        case .blowingSnow: .init(state: .snow, rule: .visibility(default: 0.45), flags: [.blowingSnow, .explicitLabel], phase: nil)
        case .freezingDrizzle: .init(state: .rain, rule: .rain(default: 0.15), flags: .freezing, phase: .liquid)
        case .freezingRain: .init(state: .rain, rule: .rain(default: 0.50), flags: .freezing, phase: .liquid)
        case .heavySnow: .init(state: .snow, rule: .snow(default: 0.90), flags: [], phase: .frozen)
        case .hurricane: .init(state: .rain, rule: .fixed(1.00), flags: [.tropicalHazard, .explicitLabel], phase: .liquid)
        case .tropicalStorm: .init(state: .rain, rule: .fixed(0.85), flags: [.tropicalHazard, .explicitLabel], phase: .liquid)
        }
    }
}

/// Quantitative intensity functions (weather spec §2).
public enum Intensity {
    /// Rain, P in liquid-equivalent mm/hour: 0 when known zero, else max(0.10, clamp(ln(1+P)/ln 11)).
    public static func rain(_ p: Double) -> Double {
        p <= 0 ? 0 : max(0.10, EnvMath.clamp01(log(1 + p) / log(11)))
    }

    /// Snow, Ps in liquid-equivalent mm/hour: 0 when known zero, else max(0.10, clamp(√(Ps/2))).
    public static func snow(_ ps: Double) -> Double {
        ps <= 0 ? 0 : max(0.10, EnvMath.clamp01((ps / 2).squareRoot()))
    }

    /// Visibility V in metres: clamp(ln(20000/max(V,200))/ln(100)).
    public static func visibility(_ v: Double) -> Double {
        EnvMath.clamp01(log(20_000 / max(v, 200)) / log(100))
    }
}
