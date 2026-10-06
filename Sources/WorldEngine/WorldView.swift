import RealityKit
import SwiftUI

/// Ready-made SwiftUI view for a world: RealityView, camera rig, gestures, post-processing, display
/// policy (render scale by heat, pausing when hidden) and the required OpenStreetMap attribution.
public struct WorldView: View {
    let world: World
    let camera: WorldCamera
    var gesturesEnabled: Bool
    var post: WorldPostProcess?
    /// Host override: stop rendering (e.g. while the app covers the world with its own UI).
    var isPaused: Bool
    /// 4× multisampling (RealityKit's default); off only for GPU attribution.
    public var multisampling = true
    var onFrame: (@MainActor (Double) -> Void)?

    @State private var dragStart: (yaw: Float, pitch: Float)?
    @State private var zoomStart: Float?
    @State private var lastDrag: CGSize = .zero
    @State private var lastMagnification: CGFloat = 1
    @State private var lastRotation: Angle = .zero
    @State private var viewHeight: CGFloat = 800
    @State private var padOffset: CGSize = .zero
    @State private var surface: RenderSurface
    @Environment(\.scenePhase) private var scenePhase

    /// - Parameters:
    ///   - settings: render scale and pausing (default: the shared display policy).
    ///   - renderState: optional observable the view keeps current (scale, frame rate, paused).
    ///   - isPaused: stop rendering while true (the view also pauses itself when hidden).
    public init(world: World, camera: WorldCamera, gesturesEnabled: Bool = true, post: WorldPostProcess? = nil,
                settings: WorldRenderSettings = .init(), renderState: WorldRenderState? = nil, isPaused: Bool = false,
                onFrame: (@MainActor (Double) -> Void)? = nil) {
        self.world = world
        self.camera = camera
        self.gesturesEnabled = gesturesEnabled
        self.post = post
        self.isPaused = isPaused
        self.onFrame = onFrame
        _surface = State(initialValue: RenderSurface(settings: settings, state: renderState ?? WorldRenderState()))
    }

    public var body: some View {
        ZStack {
            // Paused = the RealityView leaves the hierarchy: RealityKit stops updating and drawing
            // entirely (no public pause exists). The world's entities stay alive and rejoin the
            // new view on resume.
            if surface.state.isPaused {
                Color.black
            } else {
                WorldRealityView(world: world, camera: camera, post: post, surface: surface, multisampling: multisampling, onFrame: onFrame)
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
            world.viewAspect = Float(size.width / max(1, size.height))
            viewHeight = size.height
        }
        .onAppear { if camera.walkBlocker == nil { let w = world; camera.walkBlocker = { w.walkMap.blocker(at: $0) } } }
        .onChange(of: scenePhase, initial: true) { _, phase in surface.setPhase(active: phase == .active, background: phase == .background) }
        .onChange(of: isPaused, initial: true) { _, paused in surface.setHostPaused(paused) }
        .onAppear { surface.setVisible(true) }
        .onDisappear { surface.setVisible(false) }
        .gesture(gesturesEnabled ? drag : nil)
        .simultaneousGesture(gesturesEnabled ? pinch : nil)
        .simultaneousGesture(gesturesEnabled ? rotate : nil)
        .overlay(alignment: .bottomLeading) {
            if gesturesEnabled, case .explore = camera.mode { thumbPad.padding(.leading, 24).padding(.bottom, 120) }
        }
        .overlay(alignment: .bottomTrailing) {
            WorldAttributionView().padding(8)
        }
    }

    /// One-finger drag: orbit (follow), pan (aerial), look (explore).
    private var drag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                let delta = CGSize(width: v.translation.width - lastDrag.width, height: v.translation.height - lastDrag.height)
                lastDrag = v.translation
                switch camera.mode {
                case .aerial:
                    camera.aerial?.pan(by: SIMD2(Double(delta.width), Double(delta.height)), viewportHeight: Double(viewHeight))
                case .explore:
                    // Grab the view like a panorama: drag right turns left, drag down looks up.
                    camera.explore?.look(headingBy: -Double(delta.width) * 0.2, pitchBy: -Double(delta.height) * 0.2)
                case .street:
                    if dragStart == nil { dragStart = (camera.yawOffset, camera.pitchOffset) }
                    camera.yawOffset = dragStart!.yaw - Float(v.translation.width) * 0.008
                    camera.pitchOffset = dragStart!.pitch + Float(v.translation.height) * 0.12
                default:
                    break
                }
                camera.userDidInteract()
            }
            .onEnded { _ in dragStart = nil; lastDrag = .zero; camera.userDidInteract() }
    }

    /// Pinch: zoom (follow), distance (aerial).
    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                switch camera.mode {
                case .aerial:
                    camera.aerial?.zoom(by: Double(v.magnification / lastMagnification))
                    lastMagnification = v.magnification
                case .street:
                    if zoomStart == nil { zoomStart = camera.zoom }
                    camera.zoom = max(camera.street.minZoom, min(camera.street.maxZoom, zoomStart! / Float(v.magnification)))
                default:
                    break
                }
                camera.userDidInteract()
            }
            .onEnded { _ in zoomStart = nil; lastMagnification = 1 }
    }

    /// Two-finger rotation: heading (aerial).
    private var rotate: some Gesture {
        RotateGesture()
            .onChanged { v in
                guard case .aerial = camera.mode else { return }
                camera.aerial?.rotate(byDegrees: (v.rotation - lastRotation).degrees)
                lastRotation = v.rotation
                camera.userDidInteract()
            }
            .onEnded { _ in lastRotation = .zero }
    }

    /// Free-exploring thumb pad: drag the knob to walk (up = forward).
    private var thumbPad: some View {
        ZStack {
            Circle().fill(.black.opacity(0.25)).frame(width: 120, height: 120)
            Circle().fill(.white.opacity(0.7)).frame(width: 46, height: 46).offset(padOffset)
        }
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                var o = v.translation
                let r = sqrt(o.width * o.width + o.height * o.height)
                if r > 45 { o = CGSize(width: o.width / r * 45, height: o.height / r * 45) }
                padOffset = o
                camera.moveInput = SIMD2(Double(o.width / 45), Double(-o.height / 45))
                camera.userDidInteract()
            }
            .onEnded { _ in padOffset = .zero; camera.moveInput = .zero })
        .accessibilityLabel("Move")
    }
}

/// The RealityView itself. Recreated after a pause, so its post-process install state starts over.
private struct WorldRealityView: View {
    let world: World
    let camera: WorldCamera
    let post: WorldPostProcess?
    let surface: RenderSurface
    let multisampling: Bool
    let onFrame: (@MainActor (Double) -> Void)?

    /// Post-processing can only be installed once the view is on screen (RealityKit traps
    /// otherwise; see docs/feedback/realitykit-postprocess-trap.md).
    @State private var onScreen = false
    @State private var installed = Installed()

    final class Installed { var post = false }

    var body: some View {
        RealityView { content in
            content.add(world.rootEntity)
            let cam = Entity()
            cam.name = "Camera"
            cam.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: 50))
            content.add(cam)
            if let sky = world.skyEnvironment { content.environment = .skybox(sky) }
            var effects = content.renderingEffects
            effects.motionBlur = .disabled
            effects.depthOfField = .disabled
            effects.cameraGrain = .disabled
            content.renderingEffects = effects
            let world = world, camera = camera, onFrame = onFrame, surface = surface, post = post
            // Keep the subscription alive for the world's lifetime (an unretained subscription can
            // be released at any time, which silently stops all per-frame updates). A view rebuilt
            // after a pause cancels its predecessor's: a RealityView torn down while the app was in
            // the background keeps ticking for a while and would run every update twice.
            world.frameSubscription?.cancel()
            world.frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                MainActor.assumeIsolated {
                    let dt = event.deltaTime
                    let cutTarget = camera.update(camera: cam, scene: event.scene, dt: Float(dt))
                    world.update(deltaTime: dt, camera: cam, focusPoint: camera.lookTarget, cutAwayTarget: cutTarget)
                    surface.frame(camera: cam)
                    if let post {
                        post.settings.exposureTarget = world.exposureTarget
                        post.settings.saturation = WorldPostProcess.Settings.default.saturation * world.gradeSaturation * world.lookTuning.saturation
                        post.settings.contrast = WorldPostProcess.Settings.default.contrast * world.lookTuning.contrast
                    }
                    onFrame?(dt)
                }
            }
        } update: { content in
            let aa: AntialiasingMode = multisampling ? .multisample4X : .none
            if content.renderingEffects.antialiasing != aa { content.renderingEffects.antialiasing = aa }
            if onScreen, let post, !installed.post {
                installed.post = true
                content.renderingEffects.customPostProcessing = .effect(WorldPostEffect(post: post))
            }
        }
        .realityViewCameraControls(.none)
        #if os(iOS)
        .background(RenderSurfaceProbe(surface: surface))
        #endif
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            onScreen = true
        }
    }
}
