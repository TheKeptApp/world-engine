import Foundation

/// Converts provider measurements to the environment contract's SI units (°C, m/s, mm, mm/hour,
/// m, fractions 0–1, degrees). Values are converted through their units, never by reading a
/// bare `.value`, and implausible results are rejected (nil) rather than clamped: a 1,000× or
/// 1,000,000× unit slip becomes "unknown", not a silent flood or drought.
public enum Normalize {
    /// Plausible ranges after conversion. Outside them the input is treated as a unit error.
    public static let temperatureRangeC = -95.0...65.0
    public static let windRangeMps = 0.0...120.0
    public static let precipitationRateRangeMmPerHour = 0.0...400.0
    public static let precipitationAmountRangeMm = 0.0...1000.0
    public static let visibilityRangeM = 0.0...200_000.0

    public static func celsius(_ m: Measurement<UnitTemperature>) -> Double? {
        checked(m.converted(to: .celsius).value, temperatureRangeC)
    }

    public static func metersPerSecond(_ m: Measurement<UnitSpeed>) -> Double? {
        checked(m.converted(to: .metersPerSecond).value, windRangeMps)
    }

    /// A precipitation *rate* expressed as a speed (WeatherKit's `precipitationIntensity`):
    /// 1 mm/hour = 2.777…e-7 m/s.
    public static func millimetersPerHour(_ m: Measurement<UnitSpeed>) -> Double? {
        checked(m.converted(to: .metersPerSecond).value * 3_600_000, precipitationRateRangeMmPerHour)
    }

    /// A liquid-equivalent precipitation *amount* over an interval.
    public static func millimeters(_ m: Measurement<UnitLength>) -> Double? {
        checked(m.converted(to: .millimeters).value, precipitationAmountRangeMm)
    }

    public static func visibilityMeters(_ m: Measurement<UnitLength>) -> Double? {
        checked(m.converted(to: .meters).value, visibilityRangeM)
    }

    public static func degrees(_ m: Measurement<UnitAngle>) -> Double? {
        let v = m.converted(to: .degrees).value
        guard v.isFinite else { return nil }
        return (v.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    /// A fraction that must already be 0…1 (WeatherKit cloud cover, humidity). A percentage
    /// (e.g. 75) is rejected instead of being read as 7500%.
    public static func fraction(_ x: Double) -> Double? {
        guard x.isFinite, x >= 0, x <= 1 else { return nil }
        return x
    }

    /// METAR/ASOS conversions used by the fixture and fallback adapters.
    public static func fahrenheitToCelsius(_ f: Double) -> Double { (f - 32) * 5 / 9 }
    public static func knotsToMetersPerSecond(_ k: Double) -> Double { k * 0.514444444444 }
    public static func statuteMilesToMeters(_ mi: Double) -> Double { mi * 1609.344 }
    public static func inchesToMillimeters(_ inches: Double) -> Double { inches * 25.4 }

    static func checked(_ v: Double, _ range: ClosedRange<Double>) -> Double? {
        guard v.isFinite, range.contains(v) else { return nil }
        return v
    }
}

/// Shared math helpers (contract definitions from the weather spec).
public enum EnvMath {
    public static func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

    /// smoothstep(a, b, x) with q = clamp((x − a)/(b − a)), q²(3 − 2q).
    public static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        guard b != a else { return x < a ? 0 : 1 }
        let q = clamp01((x - a) / (b - a))
        return q * q * (3 - 2 * q)
    }

    public static func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    static let degreesPerRadian = 180 / Double.pi

    /// Wraps to [0, 360).
    public static func wrap360(_ x: Double) -> Double {
        let r = x.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// Wraps to (−180, 180].
    public static func wrap180(_ x: Double) -> Double {
        var r = wrap360(x)
        if r > 180 { r -= 360 }
        return r
    }
}
