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
        update(deltaTime: 0, camera: camera, focusPoint: target, cutAwayTarget: nil)
        contactEntity = contact
        for (m, p) in zip(motions, paused) { m.isPaused = p }
    }

    /// A render-only copy of the world as it is now: every entity under the root cloned except the
    /// camera-collision hulls and, unless asked for, the host's characters. Light receivers point
    /// at the copy's own image-based light, instanced detail gets its own instance data, and the
    /// world materials read a frozen copy of the palette/globals texture.
    func offscreenCopy(includeCharacters: Bool) throws -> Entity {
        let root = Entity()
        root.name = "World (offscreen copy)"
        var ibl: Entity?
        for child in rootEntity.children {
            if child.name == "Occluders" { continue }
            if !includeCharacters, characters.contains(where: { $0 === child }) { continue }
            let copy = child.clone(recursive: true)
            if child === iblEntity { ibl = copy }
            root.addChild(copy)
        }
        let frozen = try resources.frozenTexture()
        let live = resources.textureResource
        func visit(_ e: Entity) {
            if let ibl, e.components.has(ImageBasedLightReceiverComponent.self) {
                e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: ibl))
            }
            if var model = e.components[ModelComponent.self] {
                var changed = false
                model.materials = model.materials.map { (m: any Material) -> any Material in
                    guard var c = m as? CustomMaterial, c.custom.texture?.resource === live else { return m }
                    c.custom.texture = .init(frozen)
                    changed = true
                    return c
                }
                if changed { e.components.set(model) }
                // Instance data is a shared buffer the live view rewrites as its camera moves.
                if let part = e.components[MeshInstancesComponent.self]?[partIndex: 0] {
                    let source = part.data
                    let n = source.instanceCount
                    if let data = try? LowLevelInstanceData(instanceCount: n, instanceCapacity: max(1, n)) {
                        source.withTransforms { from in
                            data.withMutableTransforms { to in for i in 0..<min(n, from.count, to.count) { to[i] = from[i] } }
                        }
                        if let instances = try? MeshInstancesComponent(mesh: model.mesh, instances: data, bounds: part.bounds) {
                            e.components.set(instances)
                        }
                    }
                }
            }
            for c in e.children { visit(c) }
        }
        visit(root)
        return root
    }
}

/// Draws an offscreen copy of a world with RealityKit's `RealityRenderer`: 4× multisampling and
/// tone mapping as on screen, then `WorldPostProcess` (grade and bloom), read back as an sRGB
/// image of exactly the requested size.
@MainActor
final class OffscreenWorldRenderer {
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let event: MTLSharedEvent
    private var signalled: UInt64 = 0
    private let renderer: RealityRenderer
    private let camera = Entity()
    private let post = WorldPostProcess()
    private let encodePipeline: MTLComputePipelineState

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
        do {
            let library = try device.makeLibrary(source: Self.encodeSource, options: nil)
            guard let function = library.makeFunction(name: "worldPostcardEncodeSRGB") else {
                throw PostcardExportError.renderFailed("sRGB encode kernel missing")
            }
            encodePipeline = try device.makeComputePipelineState(function: function)
        } catch let e as PostcardExportError {
            throw e
        } catch {
            throw PostcardExportError.renderFailed("sRGB encode kernel: \(error)")
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
            post.settings.enabled = false
        }
        post.prepare(device)
    }

    /// Releases the world copy.
    func close() {
        renderer.entities.removeAll()
    }

    /// Advances the copy's simulation without drawing (rain and snow emitters start empty in a new
    /// scene; this fills the air before the first frame).
    func simulate(seconds: Double, step: Double = 1.0 / 30) async throws {
        var t = 0.0, n = 0
        while t < seconds {
            do { try renderer.update(step) } catch { throw PostcardExportError.renderFailed("RealityRenderer update: \(error)") }
            t += step
            n += 1
            if n % 10 == 0 { await Task.yield() }
        }
    }

    /// One picture of `width` × `height` pixels from `pose`. The first `frames - 1` frames only
    /// settle the renderer (shadow maps, the new output size, resources it prepares on first use).
    func render(pose: CameraPose, width: Int, height: Int, frames: Int = 3) async throws -> CGImage {
        camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: Float(pose.verticalFOVDegrees),
                                                         fieldOfViewOrientation: .vertical))
        let eye = SIMD3<Float>(pose.eye), target = SIMD3<Float>(pose.target)
        camera.look(at: simd_distance(eye, target) > 1e-3 ? target : eye + SIMD3(0, 0, -1), from: eye, relativeTo: nil)
        let color = try texture(.bgra8Unorm_srgb, width, height, [.renderTarget, .shaderRead])
        let output: RealityRenderer.CameraOutput
        do {
            output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: color))
        } catch {
            throw PostcardExportError.renderFailed("camera output: \(error)")
        }
        for _ in 0..<max(1, frames) {
            signalled += 1
            let value = signalled
            do {
                try renderer.updateAndRender(deltaTime: 1.0 / 60, cameraOutput: output, actionsAfterRender: [.signal(event, value: value)])
            } catch {
                throw PostcardExportError.renderFailed("RealityRenderer: \(error)")
            }
            try await waitForGPU(value)
        }
        return try await finish(color, width: width, height: height)
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

    /// Grade and bloom into a float texture, sRGB-encode into 8 bits, read back.
    private func finish(_ color: MTLTexture, width w: Int, height h: Int) async throws -> CGImage {
        let graded = try texture(.rgba16Float, w, h, [.shaderRead, .shaderWrite])
        let encoded = try texture(.rgba8Unorm, w, h, [.shaderRead, .shaderWrite])
        let bytesPerRow = w * 4
        guard let buffer = device.makeBuffer(length: bytesPerRow * h, options: .storageModeShared),
              let cb = queue.makeCommandBuffer() else { throw PostcardExportError.renderFailed("read-back buffer") }
        post.encode(cb, device: device, source: color, target: graded)
        guard let compute = cb.makeComputeCommandEncoder() else { throw PostcardExportError.renderFailed("encoder") }
        compute.setComputePipelineState(encodePipeline)
        compute.setTexture(graded, index: 0)
        compute.setTexture(encoded, index: 1)
        let tw = encodePipeline.threadExecutionWidth, th = max(1, encodePipeline.maxTotalThreadsPerThreadgroup / tw)
        compute.dispatchThreads(MTLSize(width: w, height: h, depth: 1), threadsPerThreadgroup: MTLSize(width: tw, height: th, depth: 1))
        compute.endEncoding()
        guard let blit = cb.makeBlitCommandEncoder() else { throw PostcardExportError.renderFailed("blit") }
        blit.copy(from: encoded, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(), sourceSize: MTLSize(width: w, height: h, depth: 1),
                  to: buffer, destinationOffset: 0, destinationBytesPerRow: bytesPerRow, destinationBytesPerImage: bytesPerRow * h)
        blit.endEncoding()
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            cb.addCompletedHandler { _ in done.resume() }
            cb.commit()
        }
        if cb.status == .error { throw PostcardExportError.renderFailed("GPU: \(cb.error.map { "\($0)" } ?? "unknown error")") }
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

    private func texture(_ format: MTLPixelFormat, _ w: Int, _ h: Int, _ usage: MTLTextureUsage) throws -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: w, height: h, mipmapped: false)
        d.usage = usage
        d.storageMode = .private
        guard w > 0, h > 0, let t = device.makeTexture(descriptor: d) else {
            throw PostcardExportError.renderFailed("texture \(w)x\(h)")
        }
        return t
    }

    /// Linear (graded) → 8-bit sRGB: the encoding the screen applies to the view's sRGB drawable.
    static let encodeSource = """
    #include <metal_stdlib>
    using namespace metal;
    kernel void worldPostcardEncodeSRGB(texture2d<float, access::read> src [[texture(0)]],
                                        texture2d<float, access::write> dst [[texture(1)]],
                                        uint2 gid [[thread_position_in_grid]]) {
        if (gid.x >= dst.get_width() || gid.y >= dst.get_height()) return;
        float3 c = clamp(src.read(gid).rgb, 0.0, 1.0);
        float3 s = select(1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, c * 12.92, c <= 0.0031308);
        dst.write(float4(s, 1.0), gid);
    }
    """
}
