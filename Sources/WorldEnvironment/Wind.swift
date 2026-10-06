import Foundation
import WorldGeo

/// Wind for rendering (weather spec §6). Source values stay uncapped; rendering uses capped ones.
public struct WindState: Codable, Sendable, Equatable {
    /// Source sustained speed, m/s (uncapped; nil = unknown).
    public var speedMps: Double?
    /// Direction the wind blows FROM, degrees clockwise from north (nil = variable/unknown).
    public var fromDegrees: Double?
    public var gustMps: Double?
    /// Display bearing used when the source direction is variable: stable per weather cell.
    public var displayFromDegrees: Double
    /// True when `displayFromDegrees` is an assumption (variable/missing direction).
    public var directionAssumed: Bool
    /// Air transport vector in scene axes (east +X, up +Y, north −Z), speed capped at 20 m/s.
    public var transportVectorMps: SIMD3<Double>
    /// Leafy branch-tip sway amplitude, metres: 0.03 × min(U/12, 1).
    public var treeTipAmplitudeM: Double
    /// Sway frequency, Hz: 0.10 + 0.08 × min(U/12, 1).
    public var swayFrequencyHz: Double
    /// Horizontal drift of rain (0.2 × wind, ≤ 2 m/s) and snow (0.35 × wind, ≤ 3 m/s), scene axes.
    public var rainDriftMps: SIMD3<Double>
    public var snowDriftMps: SIMD3<Double>
}

public enum WindModel {
    public static let renderCapMps = 20.0
    public static let maxTipAmplitudeM = 0.03
    /// Multipliers for bare branches and wet/cold foliage.
    public static let bareBranchFactor = 0.3
    public static let wetFoliageFactor = 0.7
    /// Sway fades out between these distances (m).
    public static let fadeStartM = 100.0, fadeEndM = 150.0

    /// Air transport for a FROM bearing: v = (−U sin θ, 0, +U cos θ). A north wind moves toward +Z.
    public static func transport(speed: Double, fromDegrees: Double) -> SIMD3<Double> {
        let t = fromDegrees * .pi / 180
        return SIMD3(-speed * sin(t), 0, speed * cos(t))
    }

    /// Resolves wind. `cellSeed` gives variable winds a stable assumed display bearing.
    public static func resolve(speedMps: Double?, fromDegrees: Double?, gustMps: Double?, cellSeed: UInt64) -> WindState {
        var rng = StableRandom(cellSeed, salt: "variable-wind-bearing")
        let assumedBearing = (rng.unit() * 360).rounded()
        let bearing = fromDegrees ?? assumedBearing
        let u = min(renderCapMps, speedMps ?? 0)
        let k = min(u / 12, 1)
        let v = transport(speed: u, fromDegrees: bearing)
        let horizontal = SIMD3(v.x, 0, v.z)
        func drift(_ factor: Double, cap: Double) -> SIMD3<Double> {
            let d = horizontal * factor
            let len = (d.x * d.x + d.z * d.z).squareRoot()
            return len > cap ? d * (cap / len) : d
        }
        return WindState(speedMps: speedMps, fromDegrees: fromDegrees, gustMps: gustMps, displayFromDegrees: bearing,
                         directionAssumed: fromDegrees == nil, transportVectorMps: v, treeTipAmplitudeM: maxTipAmplitudeM * k,
                         swayFrequencyHz: 0.10 + 0.08 * k, rainDriftMps: drift(0.2, cap: 2), snowDriftMps: drift(0.35, cap: 3))
    }

    /// Gusts may smoothly raise amplitude up to the same 3 cm cap, never above it.
    public static func gustAmplitude(gustMps: Double) -> Double { maxTipAmplitudeM * min(min(gustMps, renderCapMps) / 12, 1) }
}
