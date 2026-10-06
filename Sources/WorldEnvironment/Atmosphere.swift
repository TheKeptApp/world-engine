import Foundation
import WorldGen

/// Per-label atmosphere at full intensity (weather spec §5): tint and weight in linear light,
/// direct-light multiplier and fog distance policy. Interpolated once from clear by intensity.
public struct AtmospherePreset: Codable, Sendable, Equatable {
    /// sRGB hex of the tint (applied in linear light).
    public var tint: String?
    public var tintWeight: Double
    public var directMultiplier: Double
    public var fogStartFactor: Double
    public var fogEndFactor: Double
    /// Absolute fog distances (fog label): street and aerial start/end, metres.
    public var absoluteFog: AbsoluteFog?

    public struct AbsoluteFog: Codable, Sendable, Equatable {
        public var streetStart: Double, streetEnd: Double, aerialStart: Double, aerialEnd: Double
    }

    /// The preset for a label, from WorldGen's weather.json (data, not code).
    public static func of(_ s: DominantState) -> AtmospherePreset {
        guard let st = table?.states[s.rawValue] else {
            return .init(tint: nil, tintWeight: 0, directMultiplier: 1, fogStartFactor: 1, fogEndFactor: 1, absoluteFog: nil)
        }
        var absolute: AbsoluteFog?
        if let f = st.fog, f.count == 2, let a = st.aerialFog, a.count == 2 {
            absolute = AbsoluteFog(streetStart: f[0], streetEnd: f[1], aerialStart: a[0], aerialEnd: a[1])
        }
        return .init(tint: st.tint, tintWeight: st.tintWeight, directMultiplier: st.sunMultiplier, fogStartFactor: st.fogStartScale,
                     fogEndFactor: st.fogEndScale, absoluteFog: absolute)
    }

    static let table: WeatherTable? = try? StyleLibrary.weather()
}

/// Weather's effect on the time-of-day light, as scalar endpoints (blendable).
public struct AtmosphereResult: Codable, Sendable, Equatable {
    /// Linear-light tint and its weight.
    public var tintLinear: SIMD3<Double>
    public var tintWeight: Double
    /// Multiplier on the time key's direct sun: min(1 − 0.6C, preset factor), with sun floors.
    public var directMultiplier: Double
    public var fogStartM: Double
    public var fogEndM: Double
}

public enum Atmosphere {
    /// Combines the time key's fog with the label (interpolated by intensity), cloud and
    /// visibility caps. `aerial` selects the aerial distance policy.
    public static func resolve(state: DominantState, intensity: Double, cloud: Double?, visibilityM: Double?,
                               visibilityReportingLimited: Bool, baseFogStart: Double, baseFogEnd: Double,
                               aerial: Bool, sunFloor: Bool) -> AtmosphereResult {
        let p = AtmospherePreset.of(state)
        let i = EnvMath.clamp01(intensity)
        let tint = p.tint.map(linear) ?? SIMD3(1, 1, 1)
        let presetDirect = EnvMath.mix(1, p.directMultiplier, i)
        let cloudFactor = 1 - 0.6 * (cloud ?? 0)
        var direct = min(cloudFactor, presetDirect)
        if sunFloor { direct = max(direct, 0.65) }

        var start: Double, end: Double
        if let abs = p.absoluteFog {
            let s = aerial ? abs.aerialStart : abs.streetStart, e = aerial ? abs.aerialEnd : abs.streetEnd
            start = EnvMath.mix(baseFogStart, s, i)
            end = EnvMath.mix(baseFogEnd, e, i)
        } else {
            start = baseFogStart * EnvMath.mix(1, p.fogStartFactor, i)
            end = baseFogEnd * EnvMath.mix(1, p.fogEndFactor, i)
        }
        // Visibility may cap fog (end at V, start at 0.1V; floors 60/10 m); a reporting-limited
        // value never shortens a longer justified view.
        if let v = visibilityM, !visibilityReportingLimited {
            end = min(end, max(60, v))
            start = min(start, max(10, 0.1 * v))
        }
        end = max(end, start + 20)
        return AtmosphereResult(tintLinear: tint, tintWeight: p.tintWeight * i, directMultiplier: direct, fogStartM: start, fogEndM: end)
    }

    static func linear(_ hex: String) -> SIMD3<Double> {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt32(s, radix: 16) ?? 0xFFFFFF
        func l(_ c: UInt32) -> Double {
            let x = Double(c) / 255
            return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
        }
        return SIMD3(l((v >> 16) & 0xFF), l((v >> 8) & 0xFF), l(v & 0xFF))
    }

    /// Direct sun ramps in above the geometric horizon: smoothstep(0°, 2°, e).
    public static func directSunGate(elevationDegrees e: Double) -> Double { EnvMath.smoothstep(0, 2, e) }
}

/// Precipitation particle budget (weather spec §6): counts scale with intensity; never feeds
/// the accumulation model.
public struct ParticleBudget: Codable, Sendable, Equatable {
    public var rain: Int
    public var snow: Int
    public var airborneLeaves: Int

    public static let rainCap = 600, snowCap = 300, leafCap = 12, totalCap = 600

    public static func resolve(state: DominantState?, intensity: Double, liquidShare: Double, leafDropRate: Double,
                               aerial: Bool) -> ParticleBudget {
        var rain = 0, snow = 0
        let i = EnvMath.clamp01(intensity)
        switch state {
        case .rain?, .thunderstorm?:
            rain = Int((Double(rainCap) * i * liquidShare).rounded())
            snow = Int((Double(snowCap) * i * (1 - liquidShare)).rounded())
        case .snow?:
            snow = Int((Double(snowCap) * i * (1 - liquidShare)).rounded())
            rain = Int((Double(rainCap) * i * liquidShare).rounded())
        default: break
        }
        var leaves = Int((Double(leafCap) * EnvMath.clamp01(leafDropRate)).rounded())
        // Leaves take slots inside the shared cap rather than adding overhead.
        let total = rain + snow + leaves
        if total > totalCap {
            let scale = Double(totalCap - leaves) / Double(max(1, rain + snow))
            rain = Int((Double(rain) * scale).rounded(.down))
            snow = Int((Double(snow) * scale).rounded(.down))
        }
        if aerial { rain /= 2; snow /= 2; leaves = 0 }
        return ParticleBudget(rain: rain, snow: snow, airborneLeaves: leaves)
    }
}
