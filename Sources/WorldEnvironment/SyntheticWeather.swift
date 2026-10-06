import Foundation
import WorldGeo

/// Explicit synthetic weather (demo/showcase overrides, experience-v1 §1.3): a label with its
/// rate, cloud and visibility, and an explicit surface checkpoint. Labeled "Demo" on screen; never
/// presented as observed or forecast weather.
public struct SyntheticWeather: Sendable, Equatable, Codable {
    public var label: DominantState
    /// The scenario's explicit intensity 0–1 (nil = derived from rate/visibility like provider data).
    public var intensity: Double?
    public var cloudFraction: Double
    /// Liquid-equivalent precipitation rate, mm/h.
    public var precipitationMmPerHour: Double
    public var visibilityM: Double?
    public var temperatureC: Double?
    public var windSpeedMps: Double?
    public var windFromDegrees: Double?
    /// Surface checkpoint: wetness 0–1, snow water equivalent mm.
    public var wetness: Double
    public var snowWaterEquivalentMm: Double

    public init(label: DominantState, intensity: Double? = nil, cloudFraction: Double, precipitationMmPerHour: Double = 0, visibilityM: Double? = nil,
                temperatureC: Double? = nil, windSpeedMps: Double? = 3, windFromDegrees: Double? = 300, wetness: Double = 0,
                snowWaterEquivalentMm: Double = 0) {
        self.label = label
        self.intensity = intensity
        self.cloudFraction = cloudFraction
        self.precipitationMmPerHour = precipitationMmPerHour
        self.visibilityM = visibilityM
        self.temperatureC = temperatureC
        self.windSpeedMps = windSpeedMps
        self.windFromDegrees = windFromDegrees
        self.wetness = wetness
        self.snowWaterEquivalentMm = snowWaterEquivalentMm
    }

    /// The provider-style condition for each label.
    static func condition(_ label: DominantState) -> WeatherConditionCode {
        switch label {
        case .clear: .clear
        case .cloudy: .cloudy
        case .rain: .rain
        case .snow: .snow
        case .fog: .foggy
        case .haze: .haze
        case .smoke: .smoky
        case .dust: .blowingDust
        case .thunderstorm: .thunderstorms
        }
    }

    public func sample(at time: Date) -> WeatherSample {
        let frozen = label == .snow ? 1.0 : 0.0
        return WeatherSample(validTime: time, condition: Self.condition(label), cloudCover01: cloudFraction,
                             temperatureC: temperatureC ?? (label == .snow ? -3 : 12), visibilityM: visibilityM,
                             windSpeedMps: windSpeedMps, windFromDegrees: windFromDegrees,
                             precipitationRateMmPerHour: precipitationMmPerHour,
                             snowfallLiquidEquivalentMm: label == .snow ? precipitationMmPerHour : nil,
                             phase: label == .snow ? .frozen : (label.isPrecipitation ? .liquid : nil), frozenFraction: frozen,
                             flags: ["synthetic_override"])
    }

    public func surface(at time: Date) -> SurfaceState {
        .assumedReference(wetness: wetness, snowWaterEquivalentMm: snowWaterEquivalentMm, at: time)
    }

    /// Resolver input for a demo moment (mode demo, provider "demo", data kind "synthetic_override").
    public func input(at time: Date, aerial: Bool = false) -> EnvironmentResolver.Input {
        var i = EnvironmentResolver.Input(time: time, mode: .demo, sample: sample(at: time), cell: nil, surface: surface(at: time),
                                          provider: "demo", dataKind: "synthetic_override", aerial: aerial)
        i.intensityOverride = intensity
        return i
    }
}
