import RealityKit
import SwiftUI

/// Ready-made SwiftUI view for a world: RealityView, camera rig, gestures and the required
/// OpenStreetMap attribution.
public struct WorldView: View {
    let world: World
    let camera: WorldCamera
    var gesturesEnabled: Bool
    var onFrame: (@MainActor (Double) -> Void)?

    @State private var dragStart: (yaw: Float, pitch: Float)?
    @State private var zoomStart: Float?

    public init(world: World, camera: WorldCamera, gesturesEnabled: Bool = true,
                onFrame: (@MainActor (Double) -> Void)? = nil) {
        self.world = world
        self.camera = camera
        self.gesturesEnabled = gesturesEnabled
        self.onFrame = onFrame
    }

    public var body: some View {
        RealityView { content in
            content.add(world.rootEntity)
            let cam = Entity()
            cam.name = "Camera"
            cam.components.set(PerspectiveCameraComponent(near: 0.1, far: 4000, fieldOfViewInDegrees: 50))
            content.add(cam)
            if let sky = world.skyEnvironment { content.environment = .skybox(sky) }
            // Camera-style effects off. (Custom post-processing is not used: assigning
            // `customPostProcessing` traps inside RealityKit 26.4 in both Simulator and device.)
            var effects = content.renderingEffects
            effects.motionBlur = .disabled
            effects.depthOfField = .disabled
            effects.cameraGrain = .disabled
            content.renderingEffects = effects
            let world = world, camera = camera, onFrame = onFrame
            // Keep the subscription alive for the world's lifetime (an unretained subscription
            // can be released at any time, which silently stops all per-frame updates).
            world.frameSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
                MainActor.assumeIsolated {
                    let dt = event.deltaTime
                    let cutTarget = camera.update(camera: cam, scene: event.scene, dt: Float(dt))
                    world.update(deltaTime: dt, camera: cam, focusPoint: camera.lookTarget, cutAwayTarget: cutTarget)
                    onFrame?(dt)
                }
            }
        }
        .realityViewCameraControls(.none)
        .gesture(gesturesEnabled ? drag : nil)
        .simultaneousGesture(gesturesEnabled ? pinch : nil)
        .overlay(alignment: .bottomTrailing) {
            WorldAttributionView().padding(8)
        }
        .ignoresSafeArea()
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { v in
                if dragStart == nil { dragStart = (camera.yawOffset, camera.pitchOffset) }
                camera.yawOffset = dragStart!.yaw - Float(v.translation.width) * 0.008
                camera.pitchOffset = dragStart!.pitch + Float(v.translation.height) * 0.12
                camera.userDidInteract()
            }
            .onEnded { _ in dragStart = nil; camera.userDidInteract() }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                if zoomStart == nil { zoomStart = camera.zoom }
                camera.zoom = max(camera.street.minZoom, min(camera.street.maxZoom, zoomStart! / Float(v.magnification)))
                camera.userDidInteract()
            }
            .onEnded { _ in zoomStart = nil }
    }
}
