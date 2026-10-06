import Foundation
import Metal
import RealityKit

/// R9: gentle grade + restrained emissive bloom, plus GPU timing of the post-processing command
/// buffer. Must be assigned after the RealityView is on screen (see docs/feedback/).
public final class WorldPostProcess: @unchecked Sendable {
    public struct Settings: Sendable {
        public var enabled = true
        public var saturation: Float = 0.99
        public var contrast: Float = 1.03
        /// Bloom applies to pixels brighter than this (display-referred), contributing `bloomStrength`.
        public var bloomThreshold: Float = 0.9
        public var bloomStrength: Float = 0.04
        /// Auto exposure, like a camera metering the view: the frame's mean display brightness is
        /// eased toward `exposureTarget` (0–1), within `exposureMin`…`exposureMax` (display-space
        /// gain), over about half a second. A soft curve keeps white at white. The same light then
        /// reads alike facing the sun or away from it (P3's look loop: backlit golden streets
        /// rendered ~40 luma below their targets). The world sets the target by time of day.
        public var autoExposure = true
        public var exposureTarget: Float = 0.54
        public var exposureMin: Float = 0.85
        public var exposureMax: Float = 1.5
        public var exposureRate: Float = 0.06
        public init() {}
    }

    public var settings = Settings()
    private let lock = NSLock()
    private var gpuSamples: [Double] = []
    private var pipelines: [String: MTLComputePipelineState] = [:]
    private var half: [MTLTexture] = []
    private var size = (0, 0)
    /// The eased mean display brightness, carried from frame to frame (one float).
    private var meanBuffer: MTLBuffer?

    public init() {}

    /// Recent GPU durations (ms) of the command buffer that carries post-processing.
    public func recentGPUms(_ n: Int = 120) -> [Double] {
        lock.lock(); defer { lock.unlock() }
        return Array(gpuSamples.suffix(n))
    }

    func record(_ ms: Double) {
        lock.lock(); defer { lock.unlock() }
        gpuSamples.append(ms)
        if gpuSamples.count > 900 { gpuSamples.removeFirst(gpuSamples.count - 900) }
    }

    static let source = """
    #include <metal_stdlib>
    using namespace metal;
    struct P { float threshold; float strength; float saturation; float contrast;
               float target; float minGain; float maxGain; float rate; float autoExposure; };
    kernel void prefilter(texture2d<half, access::sample> src [[texture(0)]], texture2d<half, access::write> dst [[texture(1)]],
                          constant P& p [[buffer(0)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        constexpr sampler s(filter::linear, address::clamp_to_edge);
        float2 uv = (float2(gid) + 0.5) / float2(dst.get_width(), dst.get_height());
        half3 c = src.sample(s, uv).rgb;
        half l = max(c.r, max(c.g, c.b));
        half k = max(l - half(p.threshold), 0.0h) / max(l, 1e-3h);
        dst.write(half4(c * k, 1), gid);
    }
    kernel void blur(texture2d<half, access::read> src [[texture(0)]], texture2d<half, access::write> dst [[texture(1)]],
                     constant int2& dir [[buffer(0)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        const float w[5] = {0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216};
        half3 acc = src.read(gid).rgb * half(w[0]);
        int2 size = int2(src.get_width(), src.get_height());
        for (int i = 1; i < 5; i++) {
            int2 a = clamp(int2(gid) + dir * i * 2, int2(0), size - 1), b = clamp(int2(gid) - dir * i * 2, int2(0), size - 1);
            acc += (src.read(uint2(a)).rgb + src.read(uint2(b)).rgb) * half(w[i]);
        }
        dst.write(half4(acc, 1), gid);
    }
    // Mean display brightness of the frame (16 × 16 samples), eased into mean[0].
    kernel void meanLuminance(texture2d<half, access::sample> src [[texture(0)]], constant P& p [[buffer(0)]],
                              device float* mean [[buffer(1)]], uint2 tid [[thread_position_in_threadgroup]],
                              uint index [[thread_index_in_threadgroup]]) {
        threadgroup float sums[256];
        constexpr sampler s(filter::linear, address::clamp_to_edge);
        float3 c = float3(src.sample(s, (float2(tid) + 0.5) / 16.0).rgb);
        sums[index] = pow(max(dot(c, float3(0.2126, 0.7152, 0.0722)), 0.0), 1.0 / 2.2);
        threadgroup_barrier(mem_flags::mem_threadgroup);
        for (uint stride = 128; stride > 0; stride >>= 1) {
            if (index < stride) { sums[index] += sums[index + stride]; }
            threadgroup_barrier(mem_flags::mem_threadgroup);
        }
        if (index == 0) {
            float m = sums[0] / 256.0;
            mean[0] = mean[0] <= 0.0 ? m : mix(mean[0], m, p.rate);
        }
    }
    kernel void composite(texture2d<half, access::read> src [[texture(0)]], texture2d<half, access::sample> bloom [[texture(1)]],
                          texture2d<half, access::write> dst [[texture(2)]], constant P& p [[buffer(0)]],
                          device const float* mean [[buffer(1)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        constexpr sampler s(filter::linear, address::clamp_to_edge);
        float2 uv = (float2(gid) + 0.5) / float2(dst.get_width(), dst.get_height());
        half4 c = src.read(gid);
        half3 col = c.rgb + bloom.sample(s, uv).rgb * half(p.strength);
        if (p.autoExposure > 0.5 && mean[0] > 0.0) {
            // Display-space gain toward the target, applied in linear light with a soft curve
            // (g·x / (1 + (g − 1)·x)) so that white stays white.
            float g = pow(clamp(p.target / mean[0], p.minGain, p.maxGain), 2.2);
            float3 x = float3(col);
            col = half3(g * x / (1.0 + (g - 1.0) * x));
        }
        half luma = dot(col, half3(0.2126h, 0.7152h, 0.0722h));
        col = mix(half3(luma), col, half(p.saturation));
        col = (col - 0.5h) * half(p.contrast) + 0.5h;
        dst.write(half4(clamp(col, 0.0h, 1.0h), c.a), gid);
    }
    kernel void copy(texture2d<half, access::read> src [[texture(0)]], texture2d<half, access::write> dst [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        dst.write(src.read(gid), gid);
    }
    """

    func prepare(_ device: MTLDevice) {
        guard pipelines.isEmpty, let lib = try? device.makeLibrary(source: Self.source, options: nil) else { return }
        for name in ["prefilter", "blur", "meanLuminance", "composite", "copy"] {
            if let f = lib.makeFunction(name: name), let p = try? device.makeComputePipelineState(function: f) { pipelines[name] = p }
        }
    }

    func encode(_ cb: MTLCommandBuffer, device: MTLDevice, source: MTLTexture, target: MTLTexture) {
        let w = source.width, h = source.height
        if size != (w, h) || half.isEmpty {
            size = (w, h)
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: max(1, w / 2), height: max(1, h / 2), mipmapped: false)
            d.usage = [.shaderRead, .shaderWrite]
            d.storageMode = .private
            half = (0..<2).compactMap { _ in device.makeTexture(descriptor: d) }
        }
        if meanBuffer == nil {
            meanBuffer = device.makeBuffer(length: 16, options: .storageModeShared)
            meanBuffer?.contents().storeBytes(of: Float(0), as: Float.self)
        }
        var p = (settings.bloomThreshold, settings.bloomStrength, settings.saturation, settings.contrast,
                 settings.exposureTarget, settings.exposureMin, settings.exposureMax, settings.exposureRate,
                 Float(settings.autoExposure ? 1 : 0))
        func dispatch(_ name: String, _ textures: [MTLTexture], bytes: (UnsafeRawPointer, Int)?, grid: (Int, Int)) {
            guard let pipe = pipelines[name], let enc = cb.makeComputeCommandEncoder() else { return }
            enc.setComputePipelineState(pipe)
            for (i, t) in textures.enumerated() { enc.setTexture(t, index: i) }
            if let (ptr, len) = bytes { enc.setBytes(ptr, length: len, index: 0) }
            if let meanBuffer { enc.setBuffer(meanBuffer, offset: 0, index: 1) }
            if name == "meanLuminance" {
                enc.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
            } else {
                let tw = pipe.threadExecutionWidth, th = max(1, pipe.maxTotalThreadsPerThreadgroup / tw)
                enc.dispatchThreads(MTLSize(width: grid.0, height: grid.1, depth: 1), threadsPerThreadgroup: MTLSize(width: tw, height: th, depth: 1))
            }
            enc.endEncoding()
        }
        guard settings.enabled, half.count == 2 else {
            dispatch("copy", [source, target], bytes: nil, grid: (w, h))
            return
        }
        let hw = half[0].width, hh = half[0].height
        withUnsafeBytes(of: &p) { raw in
            dispatch("prefilter", [source, half[0]], bytes: (raw.baseAddress!, raw.count), grid: (hw, hh))
        }
        var dx = SIMD2<Int32>(1, 0), dy = SIMD2<Int32>(0, 1)
        withUnsafeBytes(of: &dx) { dispatch("blur", [half[0], half[1]], bytes: ($0.baseAddress!, $0.count), grid: (hw, hh)) }
        withUnsafeBytes(of: &dy) { dispatch("blur", [half[1], half[0]], bytes: ($0.baseAddress!, $0.count), grid: (hw, hh)) }
        withUnsafeBytes(of: &p) { raw in
            if settings.autoExposure { dispatch("meanLuminance", [source], bytes: (raw.baseAddress!, raw.count), grid: (16, 16)) }
            dispatch("composite", [source, half[0], target], bytes: (raw.baseAddress!, raw.count), grid: (w, h))
        }
    }
}

struct WorldPostEffect: PostProcessEffect {
    let post: WorldPostProcess
    nonisolated(unsafe) static var loggedFormats = false

    mutating func prepare(for device: MTLDevice) { post.prepare(device) }

    mutating func postProcess(context: borrowing PostProcessEffectContext<any MTLCommandBuffer>) {
        if !WorldPostEffect.loggedFormats {
            WorldPostEffect.loggedFormats = true
            print("POSTFORMAT source=\(context.sourceColorTexture.pixelFormat.rawValue) \(context.sourceColorTexture.width)x\(context.sourceColorTexture.height) target=\(context.targetColorTexture.pixelFormat.rawValue)")
        }
        post.encode(context.commandBuffer, device: context.device, source: context.sourceColorTexture, target: context.targetColorTexture)
        let post = post
        context.commandBuffer.addCompletedHandler { cb in
            post.record((cb.gpuEndTime - cb.gpuStartTime) * 1000)
        }
    }
}
