import Foundation
import Observation
import RealityKit
import WorldGen
import WorldGeo

/// Tunables for the street (third-person follow) camera.
public struct StreetCameraSettings: Sendable {
    /// Share of screen height the character fills at default zoom.
    public var screenFraction: Float = 0.22
    public var fieldOfViewDegrees: Float = 50
    /// Default downward angle (degrees).
    public var pitchDegrees: Float = 14
    public var minPitchDegrees: Float = 4
    public var maxPitchDegrees: Float = 60
    /// Look-at point as a share of the character's height.
    public var targetHeightFactor: Float = 0.8
    /// Zoom limits as multiples of the default distance.
    public var minZoom: Float = 0.5
    public var maxZoom: Float = 2.5
    /// Seconds after the user lets go before the camera swings back behind the character.
    public var recenterDelay: Double = 5
    /// Minimum camera distance when pushed in by a blocker.
    public var minDistance: Float = 0.8
    public init() {}
}

/// Drives the RealityKit camera. No-character modes (experience-v1 §3): postcard, aerial diorama,
/// free exploring and route flythrough, from the renderer-neutral rigs in WorldGen; plus character
/// follow, overview and fixed comparison poses. Changing mode eases from the current view.
@MainActor
@Observable
public final class WorldCamera {
    public enum Mode {
        /// Third-person follow behind and above an entity (optional; needs a character).
        case street(following: Entity)
        /// Orbit view looking at a ground point.
        case overview(center: SIMD3<Float>, distance: Float, pitchDegrees: Float, yawDegrees: Float, fieldOfViewDegrees: Float)
        /// Exact camera position and look-at point (reproducible comparison presets).
        case fixed(position: SIMD3<Float>, target: SIMD3<Float>, fieldOfViewDegrees: Float)
        /// A saved geographic pose; static (weather and light may change).
        case postcard(CameraPose)
        /// Aerial diorama (`aerial` rig).
        case aerial
        /// Free street exploring (`explore` rig, driven by `moveInput` / `turnInput` and drags).
        case explore
        /// Route flythrough (`route` rig).
        case route

        public var name: String {
            switch self {
            case .street: "follow"
            case .overview: "overview"
            case .fixed: "fixed"
            case .postcard: "postcard"
            case .aerial: "aerial"
            case .explore: "explore"
            case .route: "route"
            }
        }
    }

    public var mode: Mode {
        didSet {
            transitionFrom = lastPose
            transitionTime = 0
        }
    }
    public var aerial: AerialRig?
    public var explore: ExploreRig?
    public var route: RouteRig?
    /// Free-exploring input: thumb pad (x right, y forward, −1…1) and turn (−1…1).
    @ObservationIgnored public var moveInput = SIMD2<Double>(0, 0)
    @ObservationIgnored public var turnInput = 0.0
    /// Why exploring may not go somewhere (building, water, edge of data); set by the world.
    @ObservationIgnored public var walkBlocker: ((LocalPoint) -> String?)?
    /// Seconds to ease between modes (0 = cut; Reduce Motion).
    public var transitionSeconds = 1.2
    @ObservationIgnored private var transitionFrom: CameraPose?
    @ObservationIgnored private var transitionTime = 0.0
    @ObservationIgnored private var lastPose: CameraPose?
    public var street = StreetCameraSettings()
    /// User orbit offsets (from drag) and zoom (from pinch).
    public var yawOffset: Float = 0
    public var pitchOffset: Float = 0
    public var zoom: Float = 1
    /// When false, `yawOffset` never decays (screenshot presets).
    public var autoRecenter = true
    /// Fixed camera bearing around the character (radians; 0 = camera south of it, π/2 = east).
    /// Overrides "behind the character" when set (screenshot presets).
    public var absoluteYaw: Float?

    @ObservationIgnored var lastInteraction = Date.distantPast
    @ObservationIgnored var smoothedYaw: Float?
    @ObservationIgnored var smoothedDistance: Float?
    @ObservationIgnored var characterBounds: BoundingBox?
    /// Where the camera looks (for clutter and cut-away).
    @ObservationIgnored public private(set) var lookTarget: SIMD3<Float> = .zero

    public init(mode: Mode) {
        self.mode = mode
    }

    public func userDidInteract() { lastInteraction = Date() }

    /// A touch moved the camera within the last half second.
    var recentlyInteracted: Bool { Date().timeIntervalSince(lastInteraction) < 0.5 }

    /// Places `camera` for this frame. Returns the follow target (for the cut-away), if any.
    func update(camera: Entity, scene: RealityKit.Scene?, dt: Float) -> SIMD3<Float>? {
        let cut = place(camera: camera, scene: scene, dt: dt)
        // Ease from the pose the previous mode left off.
        let m = camera.transformMatrix(relativeTo: nil)
        let eye = SIMD3<Double>(Double(m.columns.3.x), Double(m.columns.3.y), Double(m.columns.3.z))
        let forward = -SIMD3<Double>(Double(m.columns.2.x), Double(m.columns.2.y), Double(m.columns.2.z))
        let fov = Double(camera.components[PerspectiveCameraComponent.self]?.fieldOfViewInDegrees ?? 50)
        var pose = CameraPose(eye: eye, target: eye + forward * 10, verticalFOVDegrees: fov)
        if let from = transitionFrom, transitionSeconds > 0, transitionTime < transitionSeconds {
            transitionTime += Double(dt)
            pose = CameraPose.blend(from, pose, min(1, transitionTime / transitionSeconds))
            apply(pose, to: camera)
        } else {
            transitionFrom = nil
        }
        lastPose = pose
        return transitionFrom == nil ? cut : nil
    }

    private func apply(_ p: CameraPose, to camera: Entity) {
        setFOV(camera, Float(p.verticalFOVDegrees))
        camera.look(at: SIMD3<Float>(p.target), from: SIMD3<Float>(p.eye), relativeTo: nil)
        lookTarget = SIMD3<Float>(p.target)
    }

    private func place(camera: Entity, scene: RealityKit.Scene?, dt: Float) -> SIMD3<Float>? {
        switch mode {
        case let .postcard(pose):
            apply(pose, to: camera)
            return nil
        case .aerial:
            guard let a = aerial else { return nil }
            apply(a.pose, to: camera)
            return nil
        case .explore:
            guard var e = explore else { return nil }
            let blocker = walkBlocker
            e.step(dt: Double(dt), move: moveInput, turn: turnInput) { blocker?($0) }
            explore = e
            apply(e.pose, to: camera)
            // Look target: a few metres ahead on the ground, for clutter and fog.
            let f = simd_normalize(e.pose.target - e.pose.eye)
            lookTarget = SIMD3<Float>(e.pose.eye + SIMD3(f.x, 0, f.z) * 6) * SIMD3(1, 0, 1)
            // First-person cut-away: foliage within ~2.5 m ahead of the eye dithers away.
            return SIMD3<Float>(e.pose.eye + f * 2.5)
        case .route:
            guard var r = route else { return nil }
            r.step(dt: Double(dt))
            route = r
            apply(r.pose, to: camera)
            let f = simd_normalize(r.pose.target - r.pose.eye)
            lookTarget = SIMD3<Float>(r.pose.eye + SIMD3(f.x, 0, f.z) * 6) * SIMD3(1, 0, 1)
            return SIMD3<Float>(r.pose.eye + f * 2.5)
        case let .fixed(position, target, fov):
            setFOV(camera, fov)
            camera.look(at: target, from: position, relativeTo: nil)
            lookTarget = target
            return nil
        case let .overview(center, distance, pitch, yaw, fov):
            setFOV(camera, fov)
            let p = pitch * .pi / 180, y = yaw * .pi / 180
            let offset = SIMD3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * distance
            camera.look(at: center, from: center + offset, relativeTo: nil)
            lookTarget = center
            return nil

        case let .street(entity):
            let s = street
            setFOV(camera, s.fieldOfViewDegrees)
            if characterBounds == nil {
                let b = entity.visualBounds(relativeTo: entity)
                characterBounds = b.isEmpty ? BoundingBox(min: [-0.1, 0, -0.1], max: [0.1, 0.65, 0.1]) : b
            }
            let bounds = characterBounds!
            let h = max(0.2, bounds.extents.y)
            let target = entity.position(relativeTo: nil) + SIMD3(0, h * s.targetHeightFactor, 0)
            lookTarget = target

            // Recenter: decay the user's yaw offset after the delay.
            if autoRecenter, Date().timeIntervalSince(lastInteraction) > s.recenterDelay {
                yawOffset *= max(0, 1 - dt * 1.5)
                pitchOffset *= max(0, 1 - dt * 1.5)
            }
            // Behind the character: opposite its facing (+Z of the entity).
            let fwd = entity.convert(direction: [0, 0, 1], to: nil)
            let behindYaw = atan2(-fwd.x, -fwd.z)
            let targetYaw = (absoluteYaw ?? behindYaw) + yawOffset
            if let y = smoothedYaw {
                var d = targetYaw - y
                while d > .pi { d -= 2 * .pi }
                while d < -.pi { d += 2 * .pi }
                smoothedYaw = y + d * min(1, dt * 4)
            } else {
                smoothedYaw = targetYaw
            }
            let pitch = max(s.minPitchDegrees, min(s.maxPitchDegrees, s.pitchDegrees + pitchOffset)) * .pi / 180
            let yaw = smoothedYaw!
            let dir = SIMD3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
            // Distance so the character's projected bounds fill `screenFraction` of the screen height.
            let base = Self.fittedDistance(bounds: bounds, orientation: entity.orientation(relativeTo: nil), viewDirection: -dir,
                                           fieldOfViewDegrees: s.fieldOfViewDegrees, fraction: s.screenFraction)
            let wanted = base * max(s.minZoom, min(s.maxZoom, zoom))

            // Occlusion: sphere-cast toward the desired spot; pull in if a building is in the way.
            var allowed = wanted
            if let scene {
                let hits = scene.convexCast(convexShape: .generateSphere(radius: 0.3),
                                            fromPosition: target, fromOrientation: .init(),
                                            toPosition: target + dir * wanted, toOrientation: .init(),
                                            query: .nearest, mask: World.occluderGroup)
                if let hit = hits.first {
                    allowed = max(s.minDistance, hit.distance - 0.15)
                }
            }
            // Pull in fast, ease back out slowly.
            let current = smoothedDistance ?? allowed
            smoothedDistance = allowed < current ? allowed : current + (allowed - current) * min(1, dt * 1.2)
            let eye = target + dir * smoothedDistance!
            camera.look(at: target, from: eye, relativeTo: nil)
            return entity.position(relativeTo: nil) + SIMD3(0, h * 0.5, 0)
        }
    }

    /// Camera distance at which a character's bounds (local box, rotated into the world) span
    /// `fraction` of the screen height, looking along `viewDirection` (v2: projected bounds, not
    /// the upright height alone; a long dog seen from above projects taller than it stands).
    public static func fittedDistance(bounds: BoundingBox, orientation: simd_quatf, viewDirection: SIMD3<Float>,
                                      fieldOfViewDegrees: Float, fraction: Float) -> Float {
        let f = simd_normalize(viewDirection)
        let right = simd_normalize(simd_cross(f, [0, 1, 0]))
        let up = simd_cross(right, f)
        var lo = Float.infinity, hi = -Float.infinity
        for i in 0..<8 {
            let c = SIMD3(i & 1 == 0 ? bounds.min.x : bounds.max.x, i & 2 == 0 ? bounds.min.y : bounds.max.y, i & 4 == 0 ? bounds.min.z : bounds.max.z)
            let v = simd_dot(orientation.act(c), up)
            lo = min(lo, v); hi = max(hi, v)
        }
        return max(0.1, hi - lo) / (2 * tan(fieldOfViewDegrees * .pi / 360) * fraction)
    }

    private func setFOV(_ camera: Entity, _ fov: Float) {
        if var c = camera.components[PerspectiveCameraComponent.self], c.fieldOfViewInDegrees != fov {
            c.fieldOfViewInDegrees = fov
            camera.components.set(c)
        }
    }
}
