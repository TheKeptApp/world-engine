import Foundation
import Metal
import Testing
@testable import WorldEngine
import WorldGen

/// The postcard GPU steps after the renderer (Lanczos-2 downsample, final grade and sRGB encode),
/// on the Mac's GPU against CPU references.
@MainActor
@Suite("Postcard GPU steps")
struct PostcardKernelTests {
    nonisolated static var hasGPU: Bool { MTLCreateSystemDefaultDevice() != nil }

    let device = MTLCreateSystemDefaultDevice()!

    /// A shared texture with `pixels` (row-major, top row first).
    func texture(_ format: MTLPixelFormat, _ w: Int, _ h: Int, _ pixels: [SIMD4<Float>]? = nil) -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: w, height: h, mipmapped: false)
        d.usage = [.shaderRead, .shaderWrite]
        d.storageMode = .shared
        let t = device.makeTexture(descriptor: d)!
        if let pixels {
            let halves = pixels.map { SIMD4<Float16>($0) }
            halves.withUnsafeBytes { t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: $0.baseAddress!, bytesPerRow: w * 8) }
        }
        return t
    }

    func floats(_ t: MTLTexture) -> [SIMD4<Float>] {
        var halves = [SIMD4<Float16>](repeating: .zero, count: t.width * t.height)
        halves.withUnsafeMutableBytes { t.getBytes($0.baseAddress!, bytesPerRow: t.width * 8, from: MTLRegionMake2D(0, 0, t.width, t.height), mipmapLevel: 0) }
        return halves.map { SIMD4<Float>($0) }
    }

    func bytes(_ t: MTLTexture) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: t.width * t.height * 4)
        out.withUnsafeMutableBytes { t.getBytes($0.baseAddress!, bytesPerRow: t.width * 4, from: MTLRegionMake2D(0, 0, t.width, t.height), mipmapLevel: 0) }
        return out
    }

    /// Two-pass downsample on the GPU.
    func downsample(_ source: MTLTexture, to w: Int, _ h: Int) async throws -> MTLTexture {
        let finisher = try PostcardFinisher(device: device)
        let across = texture(.rgba16Float, w, source.height), down = texture(.rgba16Float, w, h)
        let cb = device.makeCommandQueue()!.makeCommandBuffer()!
        try finisher.downsample(cb, from: source, to: across, horizontal: true)
        try finisher.downsample(cb, from: across, to: down, horizontal: false)
        try await PostcardFinisher.run(cb)
        return down
    }

    /// CPU reference: separable Lanczos-2 with the kernel's edge clamp and zero floor.
    static func reference(_ src: [Float], _ w: Int, _ h: Int, to ow: Int, _ oh: Int) -> [Float] {
        func lanczos(_ t: Double) -> Double {
            let t = abs(t)
            if t < 1e-4 { return 1 }
            if t >= 2 { return 0 }
            let a = Double.pi * t
            return 2 * sin(a) * sin(a / 2) / (a * a)
        }
        func pass(_ data: [Double], _ w: Int, _ h: Int, _ ow: Int, horizontal: Bool) -> [Double] {
            let n = horizontal ? w : h
            let scale = horizontal ? Double(w) / Double(ow) : Double(h) / Double(oh)
            let outW = horizontal ? ow : w, outH = horizontal ? h : oh
            var out = [Double](repeating: 0, count: outW * outH)
            for y in 0..<outH {
                for x in 0..<outW {
                    let i = horizontal ? x : y
                    let center = (Double(i) + 0.5) * scale
                    var acc = 0.0, sum = 0.0
                    for k in Int((center - 2 * scale).rounded(.down))...Int((center + 2 * scale).rounded(.up)) {
                        let wgt = lanczos((Double(k) + 0.5 - center) / scale)
                        let kk = min(max(k, 0), n - 1)
                        acc += (horizontal ? data[y * w + kk] : data[kk * w + x]) * wgt
                        sum += wgt
                    }
                    out[y * outW + x] = max(acc / sum, 0)
                }
            }
            return out
        }
        let across = pass(src.map(Double.init), w, h, ow, horizontal: true)
        return pass(across, ow, h, ow, horizontal: false).map(Float.init)
    }

    @Test func downsampleKeepsFlatColourAndMatchesTheReference() async throws {
        guard hasGPU else { Issue.record("missing test prerequisite: hasGPU"); return }
        // A flat colour stays itself (weights are normalised).
        let flat = texture(.rgba16Float, 64, 48, [SIMD4<Float>](repeating: SIMD4(0.3, 0.6, 0.9, 1), count: 64 * 48))
        for p in floats(try await downsample(flat, to: 32, 24)) {
            #expect(abs(p.x - 0.3) < 2e-3 && abs(p.y - 0.6) < 2e-3 && abs(p.z - 0.9) < 2e-3)
        }
        // Pixel-wide stripes at 2× average to grey: no aliasing into the result.
        var stripes: [SIMD4<Float>] = []
        for _ in 0..<40 { for x in 0..<60 { stripes.append(x % 2 == 0 ? SIMD4(1, 1, 1, 1) : SIMD4(0, 0, 0, 1)) } }
        let grey = floats(try await downsample(texture(.rgba16Float, 60, 40, stripes), to: 30, 20))
        for y in 0..<20 { for x in 2..<28 { #expect(abs(grey[y * 30 + x].x - 0.5) < 0.02, "\(x),\(y) \(grey[y * 30 + x].x)") } }
        // A sharp edge and a gradient at 1.5× and 2× match the CPU reference.
        for (w, h, ow, oh) in [(48, 36, 32, 24), (64, 48, 32, 24)] {
            var src: [Float] = []
            for y in 0..<h { for x in 0..<w { src.append(x < w / 2 ? 0.05 : 0.95 * Float(y) / Float(h)) } }
            let gpu = floats(try await downsample(texture(.rgba16Float, w, h, src.map { SIMD4($0, $0, $0, 1) }), to: ow, oh)).map(\.x)
            let cpu = Self.reference(src, w, h, to: ow, oh)
            let worst = zip(gpu, cpu).map { abs($0 - $1) }.max() ?? 0
            #expect(worst < 4e-3, "\(w)x\(h) → \(ow)x\(oh): max error \(worst)")
        }
    }

    @Test func encodeIsPlainSRGBWithoutAGradeAndFollowsTheGradeWithOne() async throws {
        guard hasGPU else { Issue.record("missing test prerequisite: hasGPU"); return }
        let finisher = try PostcardFinisher(device: device)
        let linear: [SIMD4<Float>] = [SIMD4(0, 0, 0, 1), SIMD4(0.5, 0.5, 0.5, 1), SIMD4(1, 1, 1, 1), SIMD4(0.02, 0.2, 0.7, 1),
                                      SIMD4(0.8, 0.3, 0.05, 1), SIMD4(0.001, 0.002, 0.003, 1), SIMD4(0.25, 0.25, 0.25, 1), SIMD4(0.6, 0.6, 0.1, 1)]
        let source = texture(.rgba16Float, 8, 1, linear)
        func run(_ grade: (PostcardGrade, threshold: Double, softness: Double)?) async throws -> [UInt8] {
            let target = texture(.rgba8Unorm, 8, 1)
            let cb = device.makeCommandQueue()!.makeCommandBuffer()!
            try finisher.encode(cb, from: source, to: target, grade: grade)
            try await PostcardFinisher.run(cb)
            return bytes(target)
        }
        func srgb(_ v: Float) -> Double {
            let c = Double(Float(Float16(v)))
            return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055
        }
        let plain = try await run(nil)
        for (i, c) in linear.enumerated() {
            for ch in 0..<3 { #expect(abs(Double(plain[i * 4 + ch]) - srgb(c[ch]) * 255) <= 1, "\(i).\(ch)") }
        }
        // Identity grade = no grade, byte for byte.
        #expect(try await run((.identity, 0.35, 0.2)) == plain)
        // A real grade follows `PostcardGrade.apply` (the reference) within a level.
        let grade = PostcardGrade(lift: [0.02, 0.01, 0.0], gamma: [1.1, 1.0, 0.95], gain: [0.95, 1.0, 1.05], saturation: 0.9,
                                  shadeTint: "#465582", shadeTintStrength: 0.4)
        let graded = try await run((grade, 0.35, 0.2))
        for (i, c) in linear.enumerated() {
            let display = SIMD3(srgb(c.x), srgb(c.y), srgb(c.z))
            let want = grade.apply(display, shadeThreshold: 0.35, shadeSoftness: 0.2)
            for ch in 0..<3 { #expect(abs(Double(graded[i * 4 + ch]) - want[ch] * 255) <= 1.5, "\(i).\(ch): \(graded[i * 4 + ch]) vs \(want[ch] * 255)") }
        }
        #expect(graded != plain)
    }

    @Test func qualitySettingsDefaults() {
        let live = PostcardQuality.live, max = PostcardQuality.max
        #expect(live.supersample == 1 && live.maxShadowDistance == 0 && !live.nearDetail && live.tuftRange == 0)
        #expect(live.ambientOcclusion == 0 && live.groundBounce == 0 && live.shadeLift == 0 && !live.finalGrade)
        #expect(max.supersample == 2 && max.nearDetail && max.tuftRange > 0 && max.maxShadowDistance > 80 && max.finalGrade)
        #expect(max.ambientOcclusion > 0 && max.ambientOcclusion <= 0.2) // bible §2.3: another 10–20% at contacts
        // Supersampling: 2× where it fits, less for big pictures, never below 1.
        #expect(max.factor(width: 1016, height: 765) == 2)
        let story = max.renderSize(width: 1016, height: 1220)
        #expect(story.width * story.height <= max.maxRenderPixels + 4000 && story.width >= 1016)
        #expect(PostcardQuality.live.renderSize(width: 970, height: 1220) == (970, 1220))
        var tight = max
        tight.maxRenderPixels = 100
        #expect(tight.factor(width: 1016, height: 765) == 1)
        // Live post-processing defaults are unchanged by the export path.
        #expect(WorldPostProcess.Settings().enabled && WorldPostProcess.Settings().autoExposure)
    }
}
