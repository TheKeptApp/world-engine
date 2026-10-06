#if os(iOS)
@preconcurrency import Metal
import QuartzCore
import RealityKit
import SwiftUI
import UIKit

/// EXPERIMENT (Phase 5A, off by default): draws the world with `RealityRenderer` (public RealityKit
/// API, iOS 18+) into a Metal layer this view owns, instead of `RealityView`. The frame loop is
/// ours, so frame rate (calm mode), pausing, resolution and full-frame GPU timing are under our
/// control. Selected with `WorldRenderSettings.host = .realityRenderer`.
@MainActor
final class RendererHostView: UIView {
    override class var layerClass: AnyClass { CAMetalLayer.self }
    private var metalLayer: CAMetalLayer { layer as! CAMetalLayer }

    var world: World?
    var cameraRig: WorldCamera?
    var post: WorldPostProcess?
    var surface: RenderSurface?
    var onFrame: (@MainActor (Double) -> Void)?

    private var renderer: RealityRenderer?
    private var camera = Entity()
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var device: MTLDevice?
    private var queue: MTLCommandQueue?
    private var colorTexture: MTLTexture?
    private var event: MTLSharedEvent?
    private var eventValue: UInt64 = 0
    private var inFlight = DispatchSemaphore(value: 2)
    private(set) var framesPerSecond = 60

    /// Full-frame GPU time (RealityKit's render + our post), from GPU timestamps of the command
    /// buffers that bracket RealityKit's work.
    nonisolated(unsafe) static var lastGPUms: Double?
    nonisolated(unsafe) static var lastPostMs: Double?

    override init(frame: CGRect) {
        super.init(frame: frame)
        metalLayer.pixelFormat = .bgra8Unorm_srgb
        metalLayer.framebufferOnly = false
        metalLayer.maximumDrawableCount = 3
        isOpaque = true
        backgroundColor = .black
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { start() } else { stop() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyScale(surface?.state.scale ?? Double(window?.screen.scale ?? 3))
    }

    func applyScale(_ scale: Double) {
        guard scale > 0 else { return }
        contentScaleFactor = CGFloat(scale)
        metalLayer.contentsScale = CGFloat(scale)
        metalLayer.drawableSize = CGSize(width: (bounds.width * CGFloat(scale)).rounded(), height: (bounds.height * CGFloat(scale)).rounded())
    }

    var drawableSize: CGSize { metalLayer.drawableSize }

    func setFramesPerSecond(_ fps: Int) {
        framesPerSecond = fps
        guard let link else { return }
        if fps <= 0 {
            link.isPaused = true
        } else {
            link.isPaused = false
            let f = Float(fps)
            link.preferredFrameRateRange = CAFrameRateRange(minimum: f, maximum: f, preferred: f)
        }
    }

    private func start() {
        guard renderer == nil, let world else { return }
        do {
            let r = try RealityRenderer()
            r.entities.append(world.rootEntity)
            camera.name = "Camera"
            camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: 50))
            r.entities.append(camera)
            r.activeCamera = camera
            r.cameraSettings.colorBackground = .color(UIColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 1).cgColor)
            r.cameraSettings.antialiasing = .multisample4X
            r.cameraSettings.isToneMappingEnabled = true
            if let sky = world.skyEnvironment {
                var light = r.lighting
                light.resource = sky
                light.intensityExponent = 0
                r.lighting = light
            }
            renderer = r
        } catch {
            print("RENDERERHOST failed: \(error)")
            return
        }
        device = MTLCreateSystemDefaultDevice()
        metalLayer.device = device
        queue = device?.makeCommandQueue()
        event = device?.makeSharedEvent()
        post?.prepare(device!)
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        setFramesPerSecond(framesPerSecond)
        surface?.attachHost(self)
    }

    private func stop() {
        link?.invalidate()
        link = nil
        lastTimestamp = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard let renderer, let world, let cameraRig, let queue, let event else { return }
        let now = link.timestamp
        let dt = min(0.1, lastTimestamp.map { now - $0 } ?? 1.0 / 60)
        lastTimestamp = now

        let cutTarget = cameraRig.update(camera: camera, scene: world.rootEntity.scene, dt: Float(dt))
        world.update(deltaTime: dt, camera: camera, focusPoint: cameraRig.lookTarget, cutAwayTarget: cutTarget)
        surface?.frame(camera: camera, sceneMoving: world.hasActiveMotion || cameraRig.recentlyInteracted)
        onFrame?(dt)

        let size = metalLayer.drawableSize
        guard size.width > 0, size.height > 0 else { return }
        if colorTexture?.width != Int(size.width) || colorTexture?.height != Int(size.height) {
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: Int(size.width), height: Int(size.height), mipmapped: false)
            d.usage = [.renderTarget, .shaderRead]
            d.storageMode = .private
            colorTexture = device?.makeTexture(descriptor: d)
        }
        guard let colorTexture, inFlight.wait(timeout: .now()) == .success else { return }
        guard let drawable = metalLayer.nextDrawable() else { inFlight.signal(); return }

        // GPU timing: RealityKit's work waits for event `start`, which command buffer A signals
        // once the previous frame is done and RealityKit's commands are already queued, so A's end
        // marks the GPU starting this frame (CPU encoding time excluded). B waits for RealityKit's
        // `end` signal, runs the post-process and presents; its end closes the frame.
        let previousEnd = eventValue, start = eventValue + 1, end = eventValue + 2
        eventValue = end
        do {
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: colorTexture))
            try renderer.updateAndRender(deltaTime: dt, cameraOutput: output,
                                         actionsBeforeRender: [.wait(for: event, value: start)],
                                         actionsAfterRender: [.signal(event, value: end)])
        } catch {
            print("RENDERERHOST render failed: \(error)")
        }
        guard let a = queue.makeCommandBuffer() else { inFlight.signal(); return }
        if previousEnd > 0 { a.encodeWaitForEvent(event, value: previousEnd) }
        a.encodeSignalEvent(event, value: start)
        a.commit()
        guard let b = queue.makeCommandBuffer() else { inFlight.signal(); return }
        b.encodeWaitForEvent(event, value: end)
        if let post, let device {
            post.encode(b, device: device, source: colorTexture, target: drawable.texture)
        } else if let blit = b.makeBlitCommandEncoder() {
            blit.copy(from: colorTexture, to: drawable.texture)
            blit.endEncoding()
        }
        b.present(drawable)
        let semaphore = inFlight
        b.addCompletedHandler { [a] b in
            let total = (b.gpuEndTime - a.gpuEndTime) * 1000
            if total > 0, total < 1000 {
                RendererHostView.lastGPUms = total
                RendererHostView.lastPostMs = (b.gpuEndTime - b.gpuStartTime) * 1000
            }
            semaphore.signal()
        }
        b.commit()
    }
}

/// SwiftUI wrapper for `RendererHostView`.
struct RendererHost: UIViewRepresentable {
    let world: World
    let camera: WorldCamera
    let post: WorldPostProcess?
    let surface: RenderSurface
    let onFrame: (@MainActor (Double) -> Void)?

    func makeUIView(context: Context) -> RendererHostView {
        let v = RendererHostView(frame: .zero)
        v.world = world
        v.cameraRig = camera
        v.post = post
        v.surface = surface
        v.onFrame = onFrame
        return v
    }

    func updateUIView(_ view: RendererHostView, context: Context) {}
}
#endif
