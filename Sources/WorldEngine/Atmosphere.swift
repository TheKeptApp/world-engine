import CoreGraphics
import Foundation
import RealityKit
import WorldGeo

/// Sky, sun and fog colors keyed by sun elevation (not clock time), so dawn, golden hour and
/// night look right at any latitude and season.
public struct SkyKeyframe: Sendable {
    public var elevation: Double
    public var zenith: SIMD3<Float>
    public var horizon: SIMD3<Float>
    public var ground: SIMD3<Float>
    public var sunColor: SIMD3<Float>
    /// Directional light intensity (lux, RealityKit scale).
    public var sunIntensity: Float
    /// Image-based (ambient) light exponent.
    public var ambientExponent: Float

    static func srgb(_ hex: UInt32) -> SIMD3<Float> {
        SIMD3(Float((hex >> 16) & 0xFF), Float((hex >> 8) & 0xFF), Float(hex & 0xFF)) / 255
    }

    /// Default keyframes (stylized). Later milestones move these to data with weather variants.
    public static let defaults: [SkyKeyframe] = [
        .init(elevation: -6, zenith: srgb(0x1E2A4A), horizon: srgb(0x5A5470), ground: srgb(0x2A2830),
              sunColor: srgb(0xFF9A6A), sunIntensity: 200, ambientExponent: -0.5),
        .init(elevation: 2, zenith: srgb(0x6E8DB8), horizon: srgb(0xF4B488), ground: srgb(0x6A5E58),
              sunColor: srgb(0xFFB070), sunIntensity: 1800, ambientExponent: 0.2),
        .init(elevation: 10, zenith: srgb(0x7FA6D2), horizon: srgb(0xF6CFA2), ground: srgb(0x7A7066),
              sunColor: srgb(0xFFC788), sunIntensity: 5200, ambientExponent: -0.2),
        .init(elevation: 30, zenith: srgb(0x6FA3D8), horizon: srgb(0xD6E4EE), ground: srgb(0x7E7A70),
              sunColor: srgb(0xFFF2DE), sunIntensity: 6500, ambientExponent: 0.2),
        .init(elevation: 70, zenith: srgb(0x5E9AD6), horizon: srgb(0xCFE2F0), ground: srgb(0x807C72),
              sunColor: srgb(0xFFFFFF), sunIntensity: 7500, ambientExponent: 0.3),
    ]

    public static func at(elevation e: Double) -> SkyKeyframe {
        let k = defaults
        if e <= k[0].elevation { return k[0] }
        for i in 1..<k.count where e <= k[i].elevation {
            let t = Float((e - k[i - 1].elevation) / (k[i].elevation - k[i - 1].elevation))
            let a = k[i - 1], b = k[i]
            func mix(_ x: SIMD3<Float>, _ y: SIMD3<Float>) -> SIMD3<Float> { x + (y - x) * t }
            return .init(elevation: e, zenith: mix(a.zenith, b.zenith), horizon: mix(a.horizon, b.horizon),
                         ground: mix(a.ground, b.ground), sunColor: mix(a.sunColor, b.sunColor),
                         sunIntensity: a.sunIntensity + (b.sunIntensity - a.sunIntensity) * t,
                         ambientExponent: a.ambientExponent + (b.ambientExponent - a.ambientExponent) * t)
        }
        return k[k.count - 1]
    }
}

enum Atmosphere {
    static func linear(_ c: SIMD3<Float>) -> SIMD3<Float> {
        func f(_ v: Float) -> Float { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return SIMD3(f(c.x), f(c.y), f(c.z))
    }

    /// Equirectangular sky gradient with a soft sun glow (sRGB), for the skybox and ambient light.
    static func skyImage(_ k: SkyKeyframe, sun: SolarPosition, width: Int = 512, height: Int = 256) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let data = ctx.data!.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let sunDir = sun.sceneDirection
        for y in 0..<height {
            // Row 0 = top (zenith) in CGContext memory order.
            let lat = Float.pi / 2 - Float(y) / Float(height - 1) * .pi
            for x in 0..<width {
                // Longitude; −Z is north at the image center column convention used by RealityKit.
                let lon = Float(x) / Float(width) * 2 * .pi - .pi
                let dir = SIMD3(cos(lat) * sin(lon), sin(lat), -cos(lat) * cos(lon))
                var c: SIMD3<Float>
                if lat >= 0 {
                    let t = pow(min(1, lat / (.pi / 2)), 0.55)
                    c = k.horizon + (k.zenith - k.horizon) * t
                } else {
                    let t = min(1, -lat / 0.25)
                    c = k.horizon + (k.ground - k.horizon) * t
                }
                let glow = pow(max(0, simd_dot(dir, sunDir)), 24) * 0.55 + pow(max(0, simd_dot(dir, sunDir)), 400) * 0.6
                c += k.sunColor * glow
                let i = (y * width + x) * 4
                data[i] = UInt8(min(255, c.x * 255)); data[i + 1] = UInt8(min(255, c.y * 255))
                data[i + 2] = UInt8(min(255, c.z * 255)); data[i + 3] = 255
            }
        }
        return ctx.makeImage()
    }
}
