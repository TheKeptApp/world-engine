import Foundation
import simd
import WorldGeo

/// The resolved light state for one moment and place: everything both renderers need to light
/// the world identically. Computed once here (one decision owner) and exported in the package.
public struct LightingState: Codable, Sendable, Equatable {
    /// Unit vector toward the sun (scene axes); direct light shines along its negative.
    public var sunDirection: SIMD3<Float>
    public var sunElevation: Double
    public var sunAzimuth: Double
    /// Linear RGB, already multiplied by normalized intensity (noon = 1).
    public var sunColor: SIMD3<Float>
    public var sunIntensity: Float
    /// sRGB colors (as authored).
    public var skyTop: SIMD3<Float>
    public var skyHorizon: SIMD3<Float>
    public var ambientSky: SIMD3<Float>
    public var ambientGround: SIMD3<Float>
    public var fog: SIMD3<Float>
    public var fogStart: Float
    public var fogEnd: Float
    public var litWindows: Float
    /// Exposure multiplier for all scene light (sun, fill, sky light), interpolated in log space.
    public var exposure: Float
    /// R8 fill strengths relative to the noon key.
    public var fillSky: Float
    public var fillGround: Float
    /// The two keys blended and the blend weight (for reports).
    public var keyA: String
    public var keyB: String
    public var blend: Double
}

/// v2 §3.3: street-mode fog distances come from the time-of-day key; aerial framing gets its own
/// distance policy that grows with camera height (≈900–2500 m at the aerial fixture), so a high
/// camera sees light haze instead of a fog wall. Both renderers apply this every frame.
public enum FogPolicy {
    public static let startPerHeight: Float = 0.92
    public static let endPerHeight: Float = 2.4

    public static func distances(start: Float, end: Float, cameraHeight: Float) -> (start: Float, end: Float) {
        let h = max(0, cameraHeight)
        return (max(start, h * startPerHeight), max(end, h * endPerHeight))
    }
}

public enum LightingModel {
    /// Weather v1 §5 (refining v2 §3.3): the anchors (night −12°, dawn −4° rising, morning +15°
    /// rising, noon at the day's maximum, golden hour +6° setting, dusk −4° setting) are found at
    /// their actual crossing times on the day, sorted chronologically, and keys interpolate
    /// linearly in time between neighbours (colours in linear light). Unreachable crossings are
    /// skipped (a low winter sun has no "morning"); with no crossings (polar day or night) keys
    /// interpolate by elevation. Direct sun is zero below the horizon and fades in over 0–2°.
    public static func state(at date: Date, location: GeoCoordinate, tables: LightingTables) -> LightingState {
        let sun = SolarPosition(date: date, at: location)
        let e = sun.elevation
        let (k1, k2, t) = chronologicalKeys(at: date, location: location, anchors: tables.anchors)
            ?? elevationKeys(at: date, location: location, anchors: tables.anchors)
        return blend(tables, k1, k2, t, sun: sun, elevation: e)
    }

    /// Keys and blend from the day's anchor crossing times; nil when the day has no crossings.
    static func chronologicalKeys(at date: Date, location: GeoCoordinate, anchors a: [String: Double]) -> (String, String, Double)? {
        func elevation(_ t: Date) -> Double { SolarPosition(date: t, at: location).elevation }
        // Solar noon: the maximum within ±12 h, refined to a few seconds.
        var noon = date, best = -90.0
        for m in stride(from: -720, through: 720, by: 10) {
            let t = date.addingTimeInterval(Double(m) * 60)
            let v = elevation(t)
            if v > best { best = v; noon = t }
        }
        var lo = noon.addingTimeInterval(-600), hi = noon.addingTimeInterval(600)
        for _ in 0..<40 {
            let m1 = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 3), m2 = hi.addingTimeInterval(-hi.timeIntervalSince(lo) / 3)
            if elevation(m1) < elevation(m2) { lo = m1 } else { hi = m2 }
        }
        noon = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
        let maxElevation = elevation(noon)
        // A crossing of `level` on the rising (before noon) or setting (after noon) branch.
        func crossing(_ level: Double, rising: Bool) -> Date? {
            var a = rising ? noon.addingTimeInterval(-12 * 3600) : noon
            var b = rising ? noon : noon.addingTimeInterval(12 * 3600)
            var fa = elevation(a) - level, fb = elevation(b) - level
            guard fa * fb < 0 else { return nil }
            for _ in 0..<40 {
                let m = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
                let fm = elevation(m) - level
                if fa * fm <= 0 { b = m; fb = fm } else { a = m; fa = fm }
            }
            return a.addingTimeInterval(b.timeIntervalSince(a) / 2)
        }
        let night = a["night"] ?? -12
        var list: [(String, Date)] = []
        if let t = crossing(night, rising: true) { list.append(("night", t)) }
        if let t = crossing(a["dawn"] ?? -4, rising: true) { list.append(("dawn", t)) }
        // Morning and golden hour merge into noon when they coincide with it (noon wins).
        if let t = crossing(a["morning"] ?? 15, rising: true), noon.timeIntervalSince(t) > 600 { list.append(("morning", t)) }
        list.append(("noon", noon))
        if let t = crossing(a["golden"] ?? 6, rising: false), t.timeIntervalSince(noon) > 600 { list.append(("golden", t)) }
        if let t = crossing(a["dusk"] ?? -4, rising: false) { list.append(("dusk", t)) }
        if let t = crossing(night, rising: false) { list.append(("night", t)) }
        guard list.count >= 3, maxElevation > night else { return nil }
        if date <= list[0].1 || date >= list[list.count - 1].1 {
            // Outside the reachable anchors: night if the sun is that low, else let elevation decide.
            return elevation(date) <= night ? ("night", "night", 0) : nil
        }
        for i in 0..<(list.count - 1) where date >= list[i].1 && date < list[i + 1].1 {
            let span = list[i + 1].1.timeIntervalSince(list[i].1)
            return (list[i].0, list[i + 1].0, span > 0 ? date.timeIntervalSince(list[i].1) / span : 0)
        }
        return nil
    }

    /// v2 §3.3 elevation interpolation: the fallback when a day has no anchor crossings.
    static func elevationKeys(at date: Date, location: GeoCoordinate, anchors a: [String: Double]) -> (String, String, Double) {
        let sun = SolarPosition(date: date, at: location)
        let later = SolarPosition(date: date.addingTimeInterval(600), at: location)
        let rising = later.elevation > sun.elevation
        var maxElevation = -90.0
        for m in stride(from: -720, through: 720, by: 15) {
            maxElevation = max(maxElevation, SolarPosition(date: date.addingTimeInterval(Double(m) * 60), at: location).elevation)
        }
        let e = sun.elevation
        let night = a["night"] ?? -12
        let (k1, k2, t): (String, String, Double)
        if e <= night {
            (k1, k2, t) = ("night", "night", 0)
        } else if rising {
            let dawn = a["dawn"] ?? -4, morning = min(a["morning"] ?? 15, maxElevation - 1)
            if e < dawn { (k1, k2, t) = ("night", "dawn", inv(night, dawn, e)) }
            else if e < morning { (k1, k2, t) = ("dawn", "morning", inv(dawn, morning, e)) }
            else { (k1, k2, t) = ("morning", "noon", inv(morning, max(morning + 1, maxElevation), e)) }
        } else {
            let dusk = a["dusk"] ?? -4, golden = min(a["golden"] ?? 6, maxElevation - 1)
            if e > golden { (k1, k2, t) = ("golden", "noon", inv(golden, max(golden + 1, maxElevation), e)) }
            else if e > dusk { (k1, k2, t) = ("dusk", "golden", inv(dusk, golden, e)) }
            else { (k1, k2, t) = ("night", "dusk", inv(night, dusk, e)) }
        }
        return (k1, k2, t)
    }

    static func blend(_ tables: LightingTables, _ k1: String, _ k2: String, _ t: Double, sun: SolarPosition, elevation e: Double) -> LightingState {
        let A = tables.keys[k1]!, B = tables.keys[k2]!
        func mix(_ x: String, _ y: String) -> SIMD3<Float> {
            // Interpolate in linear light, return sRGB (v2 §3.1).
            let lx = Color.linear(Palette.parse(x)), ly = Color.linear(Palette.parse(y))
            return Color.srgb(lx + (ly - lx) * Float(t))
        }
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t }
        // Direct sun is zero below the geometric horizon and fades in over 0–2° (weather v1 §5,
        // decision 5): no fake sun at night, no light through the ground.
        let horizonFade = Float(smoothstep(0, 2, e))
        let intensity = Float(lerp(A.sunIntensity, B.sunIntensity)) * horizonFade
        return LightingState(
            sunDirection: sun.sceneDirection, sunElevation: e, sunAzimuth: sun.azimuth,
            sunColor: Color.linear(mix(A.sun, B.sun)) * intensity, sunIntensity: intensity,
            skyTop: mix(A.skyTop, B.skyTop), skyHorizon: mix(A.skyHorizon, B.skyHorizon),
            ambientSky: mix(A.ambientSky, B.ambientSky), ambientGround: mix(A.ambientGround, B.ambientGround),
            fog: mix(A.fog, B.fog), fogStart: Float(lerp(A.fogStart, B.fogStart)), fogEnd: Float(lerp(A.fogEnd, B.fogEnd)),
            litWindows: Float(lerp(A.litWindows, B.litWindows)),
            exposure: Float(exp(lerp(log(A.exposure ?? 1), log(B.exposure ?? 1)))),
            fillSky: Float(tables.fill.sky), fillGround: Float(tables.fill.ground),
            keyA: k1, keyB: k2, blend: t
        )
    }

    static func inv(_ a: Double, _ b: Double, _ v: Double) -> Double {
        guard b != a else { return 0 }
        return min(1, max(0, (v - a) / (b - a)))
    }
}

/// sRGB ↔ linear helpers.
public enum Color {
    public static func linear(_ c: SIMD3<Float>) -> SIMD3<Float> {
        func f(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return SIMD3(f(c.x), f(c.y), f(c.z))
    }

    public static func srgb(_ c: SIMD3<Float>) -> SIMD3<Float> {
        func f(_ v: Float) -> Float { v <= 0.0031308 ? v * 12.92 : 1.055 * pow(max(v, 0), 1 / 2.4) - 0.055 }
        return SIMD3(f(c.x), f(c.y), f(c.z))
    }
}

extension StyleProfile.Seasons {
    /// Season index for a moment at a longitude, using local mean time (no timezone database
    /// needed; ±1 day at month boundaries at most).
    public func season(at date: Date, longitude: Double) -> Int {
        let local = date.addingTimeInterval(longitude / 15 * 3600)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let month = cal.component(.month, from: local)
        let s = season(month: month)
        // Southern hemisphere profiles list their own months; nothing to flip here.
        return s
    }
}
