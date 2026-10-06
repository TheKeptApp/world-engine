import Foundation
import simd

/// The sky as an equirectangular image: time-of-day gradient (v2 §3.3), soft clouds and a small
/// sun disk in the real sun direction. Generated once here so both renderers show the same sky.
public enum SkyImage {
    /// Which direction the image's center column faces.
    public enum Convention: String, Sendable {
        /// Center column = −Z (north), longitude increasing toward +X (east).
        case realityKit
        /// three.js `equirectUv`: u = atan2(z, x) / 2π + 0.5 (center column = −X), row 0 = up.
        case threeJS
    }

    /// RGBA8 sRGB pixels, row 0 at the zenith.
    public static func render(_ L: LightingState, width: Int = 1024, height: Int = 512, convention: Convention) -> [UInt8] {
        var out = [UInt8](repeating: 255, count: width * height * 4)
        let sun = simd_normalize(L.sunDirection)
        let top = Color.linear(L.skyTop), horizon = Color.linear(L.skyHorizon), ground = Color.linear(L.ambientGround)
        let sunColor = simd_normalize(L.sunColor + 1e-4) * 1.2
        let daylight = min(1, max(0, Float(L.sunElevation + 6) / 12))
        for y in 0..<height {
            let lat = Float.pi / 2 - (Float(y) + 0.5) / Float(height) * .pi
            for x in 0..<width {
                let lon = (Float(x) + 0.5) / Float(width) * 2 * .pi - .pi
                let dir: SIMD3<Float> = switch convention {
                case .realityKit: SIMD3(cos(lat) * sin(lon), sin(lat), -cos(lat) * cos(lon))
                case .threeJS: SIMD3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))
                }
                var c: SIMD3<Float>
                if dir.y >= 0 {
                    let t = pow(min(1, dir.y / 0.85), 0.5)
                    c = horizon + (top - horizon) * t
                    // Soft clouds: two octaves of value noise on the dome, thin near the horizon.
                    let q = SIMD2(dir.x, dir.z) / max(dir.y + 0.18, 0.18) * 1.6
                    let n = noise(q) * 0.65 + noise(q * 2.3 + 7.1) * 0.35
                    let coverage = smooth(0.52, 0.78, n) * smooth(0.02, 0.2, dir.y) * 0.55
                    let cloudLit = horizon * 1.06 + sunColor * 0.08 * daylight
                    c = c + (cloudLit - c) * coverage
                } else {
                    c = horizon + (ground - horizon) * min(1, -dir.y / 0.12)
                }
                // Sun: small soft disk (~0.6° radius) plus a gentle glow; none below the horizon.
                if L.sunElevation > -2 {
                    let cosA = simd_dot(dir, sun)
                    let disk = smooth(cos(0.75 * .pi / 180), cos(0.55 * .pi / 180), cosA)
                    let glow = pow(max(0, cosA), 60) * 0.35 + pow(max(0, cosA), 8) * 0.08
                    c += sunColor * (disk * 2.5 + glow) * daylight
                }
                let s = Color.srgb(simd_min(c, SIMD3(repeating: 1)))
                let i = (y * width + x) * 4
                out[i] = UInt8(max(0, min(255, s.x * 255))); out[i + 1] = UInt8(max(0, min(255, s.y * 255)))
                out[i + 2] = UInt8(max(0, min(255, s.z * 255))); out[i + 3] = 255
            }
        }
        return out
    }

    static func smooth(_ e0: Float, _ e1: Float, _ x: Float) -> Float {
        let t = min(1, max(0, (x - e0) / (e1 - e0)))
        return t * t * (3 - 2 * t)
    }

    static func hash(_ p: SIMD2<Float>) -> Float {
        var p3 = SIMD3(p.x, p.y, p.x) * 0.1031
        p3 = p3 - p3.rounded(.down)
        let d = simd_dot(p3, SIMD3(p3.y, p3.z, p3.x) + 33.33)
        p3 += d
        let v = (p3.x + p3.y) * p3.z
        return v - v.rounded(.down)
    }

    static func noise(_ p: SIMD2<Float>) -> Float {
        let i = p.rounded(.down), f = p - i
        let u = f * f * (3 - 2 * f)
        let a = hash(i), b = hash(i + SIMD2(1, 0)), c = hash(i + SIMD2(0, 1)), d = hash(i + SIMD2(1, 1))
        return (a + (b - a) * u.x) + ((c + (d - c) * u.x) - (a + (b - a) * u.x)) * u.y
    }
}
