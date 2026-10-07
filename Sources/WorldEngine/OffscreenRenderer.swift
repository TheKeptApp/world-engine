import CoreGraphics
import Foundation
import Metal
import RealityKit
import WorldGen

// Offscreen renders of a world at an exact pixel size (postcard exports; docs/postcards.md).
//
// RealityView has no offscreen API, and an entity belongs to one scene at a time. Lending the live
// world's root entity to a second renderer would take it out of the live view's scene for the
// duration: RealityKit stops a host character's animations when its entity leaves a scene, rain and
// snow emitters restart, and the view must register every mesh again when the root comes back.
// So the live entities never move. The world is cloned instead (`World.offscreenCopy`): meshes,
// materials and textures are shared resources, so the copy costs entities, not geometry. The copy
// gets its own instance data (detail levels, tufts, stars) and its own frozen palette/globals
// texture, so later frames of the live view can't change it, and RealityKit's public
// `RealityRenderer` draws it into a Metal texture. The grade and bloom of `WorldPostProcess` run on
// that texture exactly as on screen.

@MainActor
extension World {
    /// Sets the world's camera-dependent state for a view from `eye` towards `target`, as a frame of
    /// the live view would for that camera: detail levels, near-camera tufts, the sky dome, stars and
    /// precipitation box, and the shader globals (fog distances, camera). Host motions don't advance.
    /// Without `keepContact` the character contact shadow is left out (characters aren't drawn).
    /// Nothing changes when the live view already looks from `eye` (postcard mode) and the contact
    /// shadow stays; otherwise the live view's next frame, whose update runs before it draws, puts
    /// its own state back.
    func prepareOffscreenView(eye: SIMD3<Float>, target: SIMD3<Float>, keepContact: Bool) {
        let camera = Entity()
        let aim = simd_distance(eye, target) > 1e-3 ? target : eye + SIMD3(0, 0, -1)
        camera.look(at: aim, from: eye, relativeTo: nil)
        let paused = motions.map(\.isPaused)
        for m in motions { m.isPaused = true }
        let contact = contactEntity
        if !keepContact { contactEntity = nil }
        // Every tree and bush, not just those in the live view (the picture's frame may be wider);
        // the live view culls again at its next update.
        foliageViewCulling = false
        lodCenter = nil
        update(deltaTime: 0, camera: camera, focusPoint: target, cutAwayTarget: nil)
        foliageViewCulling = true
        lodCenter = nil
        contactEntity = contact
        for (m, p) in zip(motions, paused) { m.isPaused = p }
    }

    /// A render-only copy of the world as it is now: every entity under the root cloned except the
    /// camera-collision hulls and, unless asked for, the host's characters. Light receivers point
    /// at the copy's own image-based light, instanced detail gets its own instance data, and the
    /// world materials read a frozen copy of the palette/globals texture (with `quality`'s fill and
    /// occlusion settings; the live texture never has them). Returns the copy and, for each copied
    /// child of the root, live entity → copy.
    func offscreenCopy(includeCharacters: Bool, quality: PostcardQuality = .live) throws -> (root: Entity, copies: [ObjectIdentifier: Entity]) {
        let root = Entity()
        root.name = "World (offscreen copy)"
        var ibl: Entity?
        var copies: [ObjectIdentifier: Entity] = [:]
        var hostEntities: Set<ObjectIdentifier> = []
        // Tree and bush slots that quality mode refills anyway skip the instance copy.
        let refilled = quality.nearDetail ? Set(lodBatches.map { ObjectIdentifier($0.entity) }) : []
        var skipInstances: Set<ObjectIdentifier> = []
        for child in rootEntity.children {
            if child.name == "Occluders" { continue }
            let isCharacter = characters.contains { $0 === child }
            if isCharacter && !includeCharacters { continue }
            let copy = child.clone(recursive: true)
            if child === iblEntity { ibl = copy }
            if isCharacter { hostEntities.insert(ObjectIdentifier(copy)) }
            if refilled.contains(ObjectIdentifier(child)) { skipInstances.insert(ObjectIdentifier(copy)) }
            copies[ObjectIdentifier(child)] = copy
            root.addChild(copy)
        }
        let frozen = try resources.frozenTexture(fillSkyScale: Float(1 + quality.shadeLift),
                                                 fillGroundScale: Float(1 + quality.groundBounce),
                                                 ambientOcclusion: Float(quality.ambientOcclusion))
        func visit(_ e: Entity, host: Bool) {
            let host = host || hostEntities.contains(ObjectIdentifier(e))
            if !host, let ibl, e.components.has(ImageBasedLightReceiverComponent.self) {
                e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: ibl))
            }
            if !host, var model = e.components[ModelComponent.self] {
                var changed = false
                model.materials = model.materials.map { (m: any Material) -> any Material in
                    // The world's materials all read the palette/globals texture (256 × 4).
                    guard var c = m as? CustomMaterial, let t = c.custom.texture?.resource,
                          t.width == RenderResources.textureWidth, t.height == RenderResources.textureHeight else { return m }
                    c.custom.texture = .init(frozen)
                    changed = true
                    return c
                }
                if changed { e.components.set(model) }
                // Instance data is a shared buffer the live view rewrites as its camera moves.
                if !skipInstances.contains(ObjectIdentifier(e)), let part = e.components[MeshInstancesComponent.self]?[partIndex: 0] {
                    let source = part.data
                    let n = source.instanceCount
                    if let data = try? LowLevelInstanceData(instanceCount: n, instanceCapacity: max(1, n)) {
                        // Copy out, then in: nesting the two buffer closures captures `data` in a
                        // sending closure, which the strict-concurrency Release build rejects.
                        var copied: [simd_float4x4] = []
                        source.withTransforms { copied = Array($0.prefix(n)) }
                        data.withMutableTransforms { to in for i in 0..<min(copied.count, to.count) { to[i] = copied[i] } }
                        if let instances = try? MeshInstancesComponent(mesh: model.mesh, instances: data, bounds: part.bounds) {
                            e.components.set(instances)
                        }
                    }
                }
            }
            for c in e.children { visit(c, host: host) }
        }
        visit(root, host: false)
        return (root, copies)
    }
}

/// Draws an offscreen copy of a world with RealityKit's `RealityRenderer`: 4× multisampling and
/// tone mapping as on screen, optionally supersampled, then `WorldPostProcess` (grade and bloom)
/// at the rendered size, a Lanczos-2 downsample to the picture's size, the optional final grade,
/// and an sRGB read-back of exactly the requested size.
@MainActor
final class OffscreenWorldRenderer {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let event: MTLSharedEvent
    private var signalled: UInt64 = 0
    private let renderer: RealityRenderer
    private let camera = Entity()
    private let post: WorldPostProcess
    private let finisher: PostcardFinisher
    /// Metal memory the process held when the last picture's GPU work was done (bytes).
    private(set) var lastAllocatedBytes = 0

    /// Compiled once per process: the export's own post-processing (separate from the live view's
    /// instance, which runs on RealityKit's render thread) and the postcard kernels.
    private static var sharedPost: WorldPostProcess?
    private static var sharedFinisher: PostcardFinisher?

    /// - Parameters:
    ///   - root: the world copy (`World.offscreenCopy`); this renderer owns it from now on.
    ///   - environment: the world's sky light (as `content.environment` on screen).
    ///   - background: shown only where the sky dome doesn't cover (sRGB).
    ///   - post: grade and bloom settings; nil renders without them.
    init(root: Entity, environment: EnvironmentResource?, background: SIMD3<Float>, post settings: WorldPostProcess.Settings?) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let event = device.makeSharedEvent() else { throw PostcardExportError.metalUnavailable }
        self.device = device
        self.queue = queue
        self.event = event
        if let f = Self.sharedFinisher, f.device === device {
            finisher = f
        } else {
            finisher = try PostcardFinisher(device: device)
            Self.sharedFinisher = finisher
        }
        if let p = Self.sharedPost {
            post = p
        } else {
            post = WorldPostProcess()
            post.prepare(device)
            Self.sharedPost = post
        }
        do {
            renderer = try RealityRenderer()
        } catch {
            throw PostcardExportError.rendererUnavailable("\(error)")
        }
        camera.name = "Postcard camera"
        camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: 50, fieldOfViewOrientation: .vertical))
        renderer.entities.append(root)
        renderer.entities.append(camera)
        renderer.activeCamera = camera
        renderer.cameraSettings.colorBackground = .color(CGColor(srgbRed: CGFloat(background.x), green: CGFloat(background.y),
                                                                 blue: CGFloat(background.z), alpha: 1))
        renderer.cameraSettings.antialiasing = .multisample4X
        renderer.cameraSettings.isToneMappingEnabled = true
        if let environment {
            var light = renderer.lighting
            light.resource = environment
            light.intensityExponent = 0
            renderer.lighting = light
        }
        if let settings {
            post.settings = settings
        } else {
            var off = WorldPostProcess.Settings()
            off.enabled = false
            post.settings = off
        }
    }

    /// Releases the world copy.
    func close() {
        renderer.entities.removeAll()
    }

    /// Runs the copy's simulation for `seconds` in frames drawn into a 64 × 64 target (rain and
    /// snow emitters start empty in a new scene, and `RealityRenderer.update` alone left the air
    /// empty on the Mac), at most 24 frames.
    func warmUp(seconds: Double) async throws {
        let tiny = try texture(.bgra8Unorm_srgb, 64, 64, [.renderTarget, .shaderRead])
        let output: RealityRenderer.CameraOutput
        do {
            output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: tiny))
        } catch {
            throw PostcardExportError.renderFailed("camera output: \(error)")
        }
        let step = max(0.1, seconds / 24)
        var t = 0.0
        while t < seconds {
            signalled += 1
            let value = signalled
            do {
                try renderer.updateAndRender(deltaTime: step, cameraOutput: output, actionsAfterRender: [.signal(event, value: value)])
            } catch {
                throw PostcardExportError.renderFailed("RealityRenderer: \(error)")
            }
            try await waitForGPU(value)
            t += step
        }
    }

    /// One picture of `width` × `height` pixels from `pose`, rendered at `renderWidth` ×
    /// `renderHeight` (supersampled when larger). `settleFrames` frames come first so the renderer
    /// settles (shadow maps, the new output size, resources it prepares on first use). The grade
    /// (when given) runs after the downsample. Adds settle, render and post times to `timing`.
    func render(pose: CameraPose, width: Int, height: Int, renderWidth: Int, renderHeight: Int, settleFrames: Int,
                grade: (PostcardGrade, threshold: Double, softness: Double)?, timing: inout PostcardTiming) async throws -> CGImage {
        camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: Float(pose.verticalFOVDegrees),
                                                         fieldOfViewOrientation: .vertical))
        let eye = SIMD3<Float>(pose.eye), target = SIMD3<Float>(pose.target)
        camera.look(at: simd_distance(eye, target) > 1e-3 ? target : eye + SIMD3(0, 0, -1), from: eye, relativeTo: nil)
        let color = try texture(.bgra8Unorm_srgb, renderWidth, renderHeight, [.renderTarget, .shaderRead])
        let output: RealityRenderer.CameraOutput
        do {
            output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: color))
        } catch {
            throw PostcardExportError.renderFailed("camera output: \(error)")
        }
        let frames = max(0, settleFrames) + 1
        for f in 0..<frames {
            let started = Date()
            signalled += 1
            let value = signalled
            do {
                try renderer.updateAndRender(deltaTime: 1.0 / 60, cameraOutput: output, actionsAfterRender: [.signal(event, value: value)])
            } catch {
                throw PostcardExportError.renderFailed("RealityRenderer: \(error)")
            }
            try await waitForGPU(value)
            let ms = Date().timeIntervalSince(started) * 1000
            if f == frames - 1 { timing.render += ms } else { timing.settle += ms }
        }
        let started = Date()
        let image = try await finish(color, width: width, height: height, grade: grade)
        timing.post += Date().timeIntervalSince(started) * 1000
        return image
    }

    // MARK: - GPU

    private func waitForGPU(_ value: UInt64) async throws {
        let event = self.event
        let done = await Task.detached(priority: .userInitiated) { Self.wait(event, for: value, timeoutMS: 10_000) }.value
        guard done else { throw PostcardExportError.timedOut }
    }

    nonisolated private static func wait(_ event: any MTLSharedEvent, for value: UInt64, timeoutMS: UInt64) -> Bool {
        event.wait(untilSignaledValue: value, timeoutMS: timeoutMS)
    }

    /// Grade and bloom at the rendered size (bloom measured against the picture size), Lanczos-2
    /// down to the picture size, final grade and sRGB encode, read-back.
    private func finish(_ color: MTLTexture, width w: Int, height h: Int,
                        grade: (PostcardGrade, threshold: Double, softness: Double)?) async throws -> CGImage {
        let rw = color.width, rh = color.height
        let graded = try texture(.rgba16Float, rw, rh, [.shaderRead, .shaderWrite])
        let encoded = try texture(.rgba8Unorm, w, h, [.shaderRead, .shaderWrite])
        let bytesPerRow = w * 4
        guard let buffer = device.makeBuffer(length: bytesPerRow * h, options: .storageModeShared),
              let cb = queue.makeCommandBuffer() else { throw PostcardExportError.renderFailed("read-back buffer") }
        post.resetExposureHistory()
        post.encode(cb, device: device, source: color, target: graded, bloomSize: (w, h))
        var picture = graded
        if rw != w || rh != h {
            let across = try texture(.rgba16Float, w, rh, [.shaderRead, .shaderWrite])
            let down = try texture(.rgba16Float, w, h, [.shaderRead, .shaderWrite])
            try finisher.downsample(cb, from: graded, to: across, horizontal: true)
            try finisher.downsample(cb, from: across, to: down, horizontal: false)
            picture = down
        }
        try finisher.encode(cb, from: picture, to: encoded, grade: grade)
        guard let blit = cb.makeBlitCommandEncoder() else { throw PostcardExportError.renderFailed("blit") }
        blit.copy(from: encoded, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(), sourceSize: MTLSize(width: w, height: h, depth: 1),
                  to: buffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * h)
        blit.endEncoding()
        try await PostcardFinisher.run(cb)
        lastAllocatedBytes = device.currentAllocatedSize
        return try PostcardFinisher.image(buffer, width: w, height: h)
    }

    private func texture(_ format: MTLPixelFormat, _ w: Int, _ h: Int, _ usage: MTLTextureUsage) throws -> MTLTexture {
        try PostcardFinisher.texture(device, format, w, h, usage)
    }
}

/// The GPU steps after the renderer: Lanczos-2 downsampling and the final grade with sRGB
/// encoding (separate from `WorldPostProcess` so the live view's post-processing is untouched).
@MainActor
final class PostcardFinisher {
    let device: MTLDevice
    private let downsampleX: MTLComputePipelineState
    private let downsampleY: MTLComputePipelineState
    private let encodePipeline: MTLComputePipelineState

    init(device: MTLDevice) throws {
        self.device = device
        do {
            let library = try device.makeLibrary(source: Self.source, options: nil)
            func pipeline(_ name: String) throws -> MTLComputePipelineState {
                guard let f = library.makeFunction(name: name) else { throw PostcardExportError.renderFailed("kernel \(name) missing") }
                return try device.makeComputePipelineState(function: f)
            }
            downsampleX = try pipeline("worldPostcardDownsampleX")
            downsampleY = try pipeline("worldPostcardDownsampleY")
            encodePipeline = try pipeline("worldPostcardEncode")
        } catch let e as PostcardExportError {
            throw e
        } catch {
            throw PostcardExportError.renderFailed("postcard kernels: \(error)")
        }
    }

    /// One separable Lanczos-2 pass (the scale is the source/target size ratio along the axis).
    func downsample(_ cb: MTLCommandBuffer, from source: MTLTexture, to target: MTLTexture, horizontal: Bool) throws {
        var scale = Float(horizontal ? Double(source.width) / Double(target.width) : Double(source.height) / Double(target.height))
        try dispatch(cb, horizontal ? downsampleX : downsampleY, [source, target], bytes: &scale, length: MemoryLayout<Float>.size,
                     width: target.width, height: target.height)
    }

    /// Linear → 8-bit sRGB, with the final grade applied in display values when `grade` is given
    /// and not identity.
    func encode(_ cb: MTLCommandBuffer, from source: MTLTexture, to target: MTLTexture,
                grade: (PostcardGrade, threshold: Double, softness: Double)?) throws {
        var p = GradeParameters(grade)
        try dispatch(cb, encodePipeline, [source, target], bytes: &p, length: MemoryLayout<GradeParameters>.stride, width: target.width,
                     height: target.height)
    }

    private func dispatch<T>(_ cb: MTLCommandBuffer, _ pipe: MTLComputePipelineState, _ textures: [MTLTexture], bytes: inout T, length: Int,
                             width: Int, height: Int) throws {
        guard let enc = cb.makeComputeCommandEncoder() else { throw PostcardExportError.renderFailed("encoder") }
        enc.setComputePipelineState(pipe)
        for (i, t) in textures.enumerated() { enc.setTexture(t, index: i) }
        withUnsafeBytes(of: &bytes) { enc.setBytes($0.baseAddress!, length: length, index: 0) }
        let tw = pipe.threadExecutionWidth, th = max(1, pipe.maxTotalThreadsPerThreadgroup / tw)
        enc.dispatchThreads(MTLSize(width: width, height: height, depth: 1), threadsPerThreadgroup: MTLSize(width: tw, height: th, depth: 1))
        enc.endEncoding()
    }

    /// The kernel's parameter block (16-byte rows, as Metal lays out float4).
    struct GradeParameters {
        var lift = SIMD4<Float>(0, 0, 0, 0)
        var gamma = SIMD4<Float>(1, 1, 1, 0)
        var gain = SIMD4<Float>(1, 1, 1, 0)
        /// Shade tint scaled to luma 1.
        var tint = SIMD4<Float>(1, 1, 1, 0)
        /// saturation, tint strength, shade threshold, shade softness.
        var shape = SIMD4<Float>(1, 0, 0.35, 0.2)
        /// x = 1 when the grade is on.
        var flags = SIMD4<Float>(0, 0, 0, 0)

        init(_ grade: (PostcardGrade, threshold: Double, softness: Double)?) {
            guard let grade, !grade.0.isIdentity else { return }
            let (g, threshold, softness) = grade
            lift = SIMD4(SIMD3<Float>(g.liftRGB), 0)
            gamma = SIMD4(SIMD3<Float>(g.gammaRGB), 0)
            gain = SIMD4(SIMD3<Float>(g.gainRGB), 0)
            let t = g.shadeTintRGB
            let ty = max(0.2126 * t.x + 0.7152 * t.y + 0.0722 * t.z, 1e-4)
            tint = SIMD4(SIMD3<Float>(t / ty), 0)
            shape = SIMD4(Float(g.saturation), Float(g.shadeTintStrength), Float(threshold), Float(softness))
            flags = SIMD4(1, 0, 0, 0)
        }
    }

    // MARK: Helpers shared with the renderer

    static func texture(_ device: MTLDevice, _ format: MTLPixelFormat, _ w: Int, _ h: Int, _ usage: MTLTextureUsage) throws -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: max(1, w), height: max(1, h), mipmapped: false)
        d.usage = usage
        d.storageMode = .private
        guard w > 0, h > 0, let t = device.makeTexture(descriptor: d) else { throw PostcardExportError.renderFailed("texture \(w)x\(h)") }
        return t
    }

    /// Commits and waits for completion without blocking the main thread.
    static func run(_ cb: MTLCommandBuffer) async throws {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            cb.addCompletedHandler { _ in done.resume() }
            cb.commit()
        }
        if cb.status == .error { throw PostcardExportError.renderFailed("GPU: \(cb.error.map { "\($0)" } ?? "unknown error")") }
    }

    /// An sRGB image from tightly packed RGBA8 bytes.
    static func image(_ buffer: MTLBuffer, width w: Int, height h: Int) throws -> CGImage {
        let bytesPerRow = w * 4
        let data = Data(bytes: buffer.contents(), count: bytesPerRow * h)
        guard let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            throw PostcardExportError.renderFailed("image")
        }
        return image
    }

    /// Lanczos-2 (a = 2) downsampling, separable; and linear → sRGB with the final grade in
    /// display values (lift/gamma/gain, saturation, shade-tint push; `PostcardGrade.apply` is the
    /// reference). Kernels clamp negative lobes to zero.
    static let source = """
    #include <metal_stdlib>
    using namespace metal;

    static float lanczos2(float t) {
        t = fabs(t);
        if (t < 1e-4) return 1.0;
        if (t >= 2.0) return 0.0;
        float a = M_PI_F * t;
        return 2.0 * sin(a) * sin(0.5 * a) / (a * a);
    }

    kernel void worldPostcardDownsampleX(texture2d<float, access::read> src [[texture(0)]],
                                         texture2d<float, access::write> dst [[texture(1)]],
                                         constant float& scale [[buffer(0)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        float center = (float(gid.x) + 0.5) * scale;
        int lo = int(floor(center - 2.0 * scale)), hi = int(ceil(center + 2.0 * scale));
        int last = int(src.get_width()) - 1;
        float4 acc = 0.0;
        float sum = 0.0;
        for (int x = lo; x <= hi; x++) {
            float w = lanczos2((float(x) + 0.5 - center) / scale);
            acc += src.read(uint2(clamp(x, 0, last), gid.y)) * w;
            sum += w;
        }
        dst.write(max(acc / sum, 0.0), gid);
    }

    kernel void worldPostcardDownsampleY(texture2d<float, access::read> src [[texture(0)]],
                                         texture2d<float, access::write> dst [[texture(1)]],
                                         constant float& scale [[buffer(0)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        float center = (float(gid.y) + 0.5) * scale;
        int lo = int(floor(center - 2.0 * scale)), hi = int(ceil(center + 2.0 * scale));
        int last = int(src.get_height()) - 1;
        float4 acc = 0.0;
        float sum = 0.0;
        for (int y = lo; y <= hi; y++) {
            float w = lanczos2((float(y) + 0.5 - center) / scale);
            acc += src.read(uint2(gid.x, clamp(y, 0, last))) * w;
            sum += w;
        }
        dst.write(max(acc / sum, 0.0), gid);
    }

    struct Grade { float4 lift; float4 gamma; float4 gain; float4 tint; float4 shape; float4 flags; };

    kernel void worldPostcardEncode(texture2d<float, access::read> src [[texture(0)]],
                                    texture2d<float, access::write> dst [[texture(1)]],
                                    constant Grade& g [[buffer(0)]], uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        float3 c = clamp(src.read(gid).rgb, 0.0, 1.0);
        float3 x = select(1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, c * 12.92, c <= 0.0031308);
        if (g.flags.x > 0.5) {
            x = clamp(g.gain.rgb * (x + g.lift.rgb * (1.0 - x)), 0.0, 1.0);
            x = pow(x, 1.0 / g.gamma.rgb);
            const float3 w = float3(0.2126, 0.7152, 0.0722);
            float y = dot(x, w);
            x = float3(y) + (x - float3(y)) * g.shape.x;
            if (g.shape.y > 0.0) {
                float yx = dot(x, w);
                float shade = 1.0 - smoothstep(g.shape.z - g.shape.w, g.shape.z, yx);
                x += (g.tint.rgb * yx - x) * (g.shape.y * shade);
            }
            x = clamp(x, 0.0, 1.0);
        }
        dst.write(float4(x, 1.0), gid);
    }
    """
}
