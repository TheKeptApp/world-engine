import Foundation
import simd

/// The warmwalls / roofslate experiments (LookExperiments, default off; R-approved 10 Oct 2026 for the Front Range profile
/// only): unmapped house walls rotate toward the region's mock hue band (`-lookexp warmwalls`) and roofs clamp to the mock
/// roof lightness/chroma (`-lookexp roofslate`), from the median of the region's approved mocks as measured by P2. Values
/// live in the profile (`lookExperiments.warmwalls`); a profile without the block is unchanged. Mapped
/// `building:colour` / `roof:colour` always win.
public struct WarmWalls: Codable, Sendable, Equatable {
    public var source: String?
    /// Constant hue rotation for walls (degrees), then clamped into `wallHueDeg`.
    public var wallHueShiftDeg: Double
    public var wallHueDeg: [Double]
    public var wallLightness: [Double]
    public var wallChroma: [Double]
    /// Roof hue; nil keeps each roof's own hue.
    public var roofHueDeg: Double?
    public var roofLightness: [Double]
    public var roofChroma: [Double]

    public func wall(_ hex: String) -> String {
        var c = Self.lch(hex)
        c.h = Self.clamp(c.h + wallHueShiftDeg, wallHueDeg)
        c.l = Self.clamp(c.l, wallLightness)
        c.c = Self.clamp(c.c, wallChroma)
        return Self.hex(c)
    }

    public func roof(_ hex: String) -> String {
        var c = Self.lch(hex)
        if let h = roofHueDeg { c.h = h }
        c.l = Self.clamp(c.l, roofLightness)
        c.c = Self.clamp(c.c, roofChroma)
        return Self.hex(c)
    }

    static func clamp(_ v: Double, _ r: [Double]) -> Double { r.count == 2 ? min(max(v, r[0]), r[1]) : v }

    // MARK: CIELAB D65 (sRGB in, sRGB out)

    struct LCh { var l: Double; var c: Double; var h: Double }

    static func lch(_ hex: String) -> LCh {
        let s = Palette.parse(hex)
        let lin = SIMD3<Double>(Color.linear(s))
        let x = (0.4124 * lin.x + 0.3576 * lin.y + 0.1805 * lin.z) / 0.95047
        let y = 0.2126 * lin.x + 0.7152 * lin.y + 0.0722 * lin.z
        let z = (0.0193 * lin.x + 0.1192 * lin.y + 0.9505 * lin.z) / 1.08883
        func f(_ t: Double) -> Double { t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116 }
        let l = 116 * f(y) - 16, a = 500 * (f(x) - f(y)), b = 200 * (f(y) - f(z))
        var h = atan2(b, a) * 180 / .pi
        if h < 0 { h += 360 }
        return LCh(l: l, c: (a * a + b * b).squareRoot(), h: h)
    }

    static func hex(_ c: LCh) -> String {
        let a = c.c * cos(c.h * .pi / 180), b = c.c * sin(c.h * .pi / 180)
        let fy = (c.l + 16) / 116, fx = fy + a / 500, fz = fy - b / 200
        func inv(_ t: Double) -> Double { t * t * t > 0.008856 ? t * t * t : (t - 16.0 / 116) / 7.787 }
        let x = inv(fx) * 0.95047, y = inv(fy), z = inv(fz) * 1.08883
        let r = 3.2406 * x - 1.5372 * y - 0.4986 * z
        let g = -0.9689 * x + 1.8758 * y + 0.0415 * z
        let bl = 0.0557 * x - 0.2040 * y + 1.0570 * z
        let lin = simd_clamp(SIMD3<Float>(Float(r), Float(g), Float(bl)), SIMD3(repeating: 0), SIMD3(repeating: 1))
        return Palette.hex(Color.srgb(lin))
    }
}

/// Profile-scoped look-experiment values (each default off behind `-lookexp`).
public struct ProfileLookExperiments: Codable, Sendable, Equatable {
    public var warmwalls: WarmWalls?
}
