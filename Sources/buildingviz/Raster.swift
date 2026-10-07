import Foundation
import simd
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import WorldGen

/// Orbit camera. `yaw` is the compass direction the camera looks toward (0 = north, 90 = east),
/// `pitch` is degrees down from horizontal. Scene axes: x east, y up, z = -north.
struct Camera {
    var target: SIMD3<Float>
    var yaw: Float
    var pitch: Float
    var distance: Float
    var fovDegrees: Float

    var forward: SIMD3<Float> {
        let y = yaw * .pi / 180, p = pitch * .pi / 180
        return SIMD3(sin(y) * cos(p), -sin(p), -cos(y) * cos(p))
    }
    var position: SIMD3<Float> { target - forward * distance }
}

/// A triangle in world space with a resolved flat color (before lighting).
struct ScreenTriangle {
    var x0: Double, y0: Double, x1: Double, y1: Double, x2: Double, y2: Double
    var iz0: Double, iz1: Double, iz2: Double
    var color: SIMD3<Float>
    /// Alpha-tested (leaf card): texture coordinates per corner, divided by depth (perspective-correct).
    var cutout = false
    var uz0 = SIMD2<Double>.zero, uz1 = SIMD2<Double>.zero, uz2 = SIMD2<Double>.zero
}

/// Collects world-space triangles, then projects, clips, bins and rasterizes them.
struct Scene {
    struct Tri {
        var a: SIMD3<Float>, b: SIMD3<Float>, c: SIMD3<Float>
        /// Material: base color (sRGB 0..1), shade multiplier, ambient occlusion per tri, glass flag.
        var color: SIMD3<Float>
        var shade: Float
        var ao: Float
        var glass: Bool
        var cull: Bool
        /// Leaf card: atlas texture coordinates per corner (alpha-tested at 0.5 against `Scene.atlas`)
        /// and the card's bent normal for lighting.
        var uv: (SIMD2<Float>, SIMD2<Float>, SIMD2<Float>)? = nil
        var normal: SIMD3<Float>? = nil
    }
    var tris: [Tri] = []
    /// Coverage atlas for alpha-tested triangles.
    var atlas: LeafAtlas? = nil
}

struct SceneRenderer {
    var width: Int
    var height: Int
    var ssaa: Int
    var camera: Camera
    var sunDirection: SIMD3<Float> // toward the sun
    var sky = SIMD3<Float>(0xBF, 0xD3, 0xE3) / 255

    /// Returns RGBA8 pixels (width x height) and the number of triangles that survived culling.
    func render(_ scene: Scene) -> (pixels: [UInt8], drawn: Int) {
        let W = width * ssaa, H = height * ssaa
        let camPos = camera.position
        let f = camera.forward
        let right = simd_normalize(simd_cross(f, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, f)
        let tanH = tan(camera.fovDegrees * .pi / 360)
        let aspect = Float(W) / Float(H)
        let near = 0.1

        func toCam(_ p: SIMD3<Float>) -> SIMD3<Double> {
            let d = SIMD3<Double>(p) - SIMD3<Double>(camPos)
            return SIMD3(simd_dot(d, SIMD3<Double>(right)), simd_dot(d, SIMD3<Double>(up)), simd_dot(d, SIMD3<Double>(f)))
        }
        func project(_ c: SIMD3<Double>) -> (Double, Double, Double) {
            let iz = 1 / c.z
            let nx = c.x * iz / (Double(tanH) * Double(aspect))
            let ny = c.y * iz / Double(tanH)
            return ((nx * 0.5 + 0.5) * Double(W), (0.5 - ny * 0.5) * Double(H), iz)
        }

        var screen: [ScreenTriangle] = []
        screen.reserveCapacity(scene.tris.count)
        for t in scene.tris {
            let e1 = t.b - t.a, e2 = t.c - t.a
            var n = simd_cross(e1, e2)
            let len = simd_length(n)
            if len < 1e-9 { continue }
            n /= len
            // Back-face culling on the geometric (winding) normal.
            if t.cull, simd_dot(n, t.a - camPos) >= 0 { continue }
            // Flat shading.
            let diffuse = max(0, simd_dot(t.normal ?? n, sunDirection))
            var color: SIMD3<Float>
            if t.glass {
                color = SIMD3<Float>(0.16, 0.21, 0.27) * (0.6 + 0.4 * diffuse)
            } else {
                color = t.color * t.shade * (0.45 + 0.55 * diffuse) * (0.55 + 0.45 * t.ao)
            }
            color = simd_clamp(color, SIMD3(repeating: 0), SIMD3(repeating: 1))

            let ca = toCam(t.a), cb = toCam(t.b), cc = toCam(t.c)
            let uvs = t.uv.map { [SIMD2<Double>($0.0), SIMD2<Double>($0.1), SIMD2<Double>($0.2)] }
            if ca.z >= near && cb.z >= near && cc.z >= near {
                emit(ca, cb, cc, uvs?[0] ?? .zero, uvs?[1] ?? .zero, uvs?[2] ?? .zero)
            } else if ca.z < near && cb.z < near && cc.z < near {
                continue
            } else {
                // Sutherland-Hodgman against z = near.
                let poly = [ca, cb, cc], puv = uvs ?? [.zero, .zero, .zero]
                var out: [SIMD3<Double>] = [], outUV: [SIMD2<Double>] = []
                for i in 0..<3 {
                    let p = poly[i], q = poly[(i + 1) % 3]
                    let pin = p.z >= near, qin = q.z >= near
                    if pin { out.append(p); outUV.append(puv[i]) }
                    if pin != qin {
                        let s = (near - p.z) / (q.z - p.z)
                        out.append(p + (q - p) * s)
                        outUV.append(puv[i] + (puv[(i + 1) % 3] - puv[i]) * s)
                    }
                }
                if out.count >= 3 {
                    for i in 1..<(out.count - 1) { emit(out[0], out[i], out[i + 1], outUV[0], outUV[i], outUV[i + 1]) }
                }
            }

            func emit(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ c: SIMD3<Double>,
                      _ ua: SIMD2<Double>, _ ub: SIMD2<Double>, _ uc: SIMD2<Double>) {
                let (x0, y0, i0) = project(a), (x1, y1, i1) = project(b), (x2, y2, i2) = project(c)
                screen.append(ScreenTriangle(x0: x0, y0: y0, x1: x1, y1: y1, x2: x2, y2: y2,
                                             iz0: i0, iz1: i1, iz2: i2, color: color,
                                             cutout: uvs != nil && scene.atlas != nil, uz0: ua * i0, uz1: ub * i1, uz2: uc * i2))
            }
        }

        // Bin triangles into horizontal bands.
        let bandH = 16
        let bands = (H + bandH - 1) / bandH
        var counts = [Int](repeating: 0, count: bands + 1)
        func bandRange(_ t: ScreenTriangle) -> (Int, Int)? {
            let lo = min(t.y0, t.y1, t.y2), hi = max(t.y0, t.y1, t.y2)
            if hi < 0 || lo >= Double(H) || !(lo.isFinite && hi.isFinite) { return nil }
            let b0 = max(0, Int(max(lo, 0).rounded(.down)) / bandH)
            let b1 = min(bands - 1, Int(min(max(hi, 0), Double(H)).rounded(.down)) / bandH)
            return b1 >= b0 ? (b0, b1) : nil
        }
        for t in screen { if let (a, b) = bandRange(t) { for k in a...b { counts[k + 1] += 1 } } }
        for k in 0..<bands { counts[k + 1] += counts[k] }
        var fill = counts
        var binned = [Int32](repeating: 0, count: counts[bands])
        for (i, t) in screen.enumerated() {
            if let (a, b) = bandRange(t) { for k in a...b { binned[fill[k]] = Int32(i); fill[k] += 1 } }
        }

        // Rasterize bands in parallel.
        var color = [SIMD3<Float>](repeating: sky, count: W * H)
        var depth = [Float](repeating: 0, count: W * H) // stores 1/z, larger = nearer
        color.withUnsafeMutableBufferPointer { cbuf in
            depth.withUnsafeMutableBufferPointer { dbuf in
                screen.withUnsafeBufferPointer { sbuf in
                    binned.withUnsafeBufferPointer { bbuf in
                        let ctx = RasterContext(color: cbuf.baseAddress!, depth: dbuf.baseAddress!,
                                                tris: sbuf.baseAddress!, bins: bbuf.baseAddress!, counts: counts,
                                                W: W, H: H, bandH: bandH, atlas: scene.atlas)
                        DispatchQueue.concurrentPerform(iterations: bands) { band in ctx.rasterize(band: band) }
                    }
                }
            }
        }

        // Downsample.
        var out = [UInt8](repeating: 255, count: width * height * 4)
        let inv = 1 / Float(ssaa * ssaa)
        for y in 0..<height {
            for x in 0..<width {
                var acc = SIMD3<Float>(repeating: 0)
                for sy in 0..<ssaa { for sx in 0..<ssaa { acc += color[(y * ssaa + sy) * W + x * ssaa + sx] } }
                acc = simd_clamp(acc * inv, SIMD3(repeating: 0), SIMD3(repeating: 1))
                let o = (y * width + x) * 4
                out[o] = UInt8((acc.x * 255).rounded())
                out[o + 1] = UInt8((acc.y * 255).rounded())
                out[o + 2] = UInt8((acc.z * 255).rounded())
            }
        }
        return (out, screen.count)
    }
}

struct RasterContext: @unchecked Sendable {
    var color: UnsafeMutablePointer<SIMD3<Float>>
    var depth: UnsafeMutablePointer<Float>
    var tris: UnsafePointer<ScreenTriangle>
    var bins: UnsafePointer<Int32>
    var counts: [Int]
    var W: Int
    var H: Int
    var bandH: Int
    var atlas: LeafAtlas?

    func rasterize(band: Int) {
        let yMin = band * bandH, yMax = min(H, yMin + bandH)
        for k in counts[band]..<counts[band + 1] {
            let t = tris[Int(bins[k])]
            // Edge functions and depth as affine functions of the pixel, evaluated in Double so huge
            // (near-plane clipped) ground triangles stay accurate.
            let x0 = t.x0, y0 = t.y0, x1 = t.x1, y1 = t.y1, x2 = t.x2, y2 = t.y2
            let area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
            if abs(area) < 1e-9 { continue }
            let invArea = 1 / area
            let minXd = max(0, (min(x0, x1, x2) - 0.5).rounded(.up))
            let maxXd = min(Double(W - 1), (max(x0, x1, x2) - 0.5).rounded(.down))
            let minYd = max(Double(yMin), (min(y0, y1, y2) - 0.5).rounded(.up))
            let maxYd = min(Double(yMax - 1), (max(y0, y1, y2) - 0.5).rounded(.down))
            if minXd > maxXd || minYd > maxYd { continue }
            let minX = Int(minXd), maxX = Int(maxXd), minY = Int(minYd), maxY = Int(maxYd)
            // w0 = a0*px + b0*py + c0, etc.
            let a0 = (y1 - y2) * invArea, b0 = (x2 - x1) * invArea
            let c0 = (x1 * y2 - x2 * y1) * invArea
            let a1 = (y2 - y0) * invArea, b1 = (x0 - x2) * invArea
            let c1 = (x2 * y0 - x0 * y2) * invArea
            let iz0 = t.iz0, iz1 = t.iz1, iz2 = t.iz2
            let eps = -1e-9
            for y in minY...maxY {
                let py = Double(y) + 0.5
                for x in minX...maxX {
                    let px = Double(x) + 0.5
                    let w0 = a0 * px + b0 * py + c0
                    let w1 = a1 * px + b1 * py + c1
                    let w2 = 1 - w0 - w1
                    if w0 < eps || w1 < eps || w2 < eps { continue }
                    let iz = Float(w0 * iz0 + w1 * iz1 + w2 * iz2)
                    let idx = y * W + x
                    if t.cutout, iz > depth[idx], let atlas {
                        let uv = (t.uz0 * w0 + t.uz1 * w1 + t.uz2 * w2) / Double(iz)
                        if atlas.coverage(SIMD2<Float>(uv)) < 0.5 { continue }
                    }
                    if iz > depth[idx] {
                        depth[idx] = iz
                        color[idx] = t.color
                    }
                }
            }
        }
    }
}

func writePNG(_ pixels: [UInt8], width: Int, height: Int, to url: URL) throws {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                              space: cs, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
    else { throw NSError(domain: "buildingviz", code: 1, userInfo: [NSLocalizedDescriptionKey: "cannot create PNG"]) }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "buildingviz", code: 2, userInfo: [NSLocalizedDescriptionKey: "cannot write \(url.path)"])
    }
}
