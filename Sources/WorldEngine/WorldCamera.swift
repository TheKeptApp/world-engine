import Foundation
import Observation
import RealityKit
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

/// Drives the RealityKit camera: street follow mode or a fixed overview.
@MainActor
@Observable
public final class WorldCamera {
    public enum Mode {
        /// Third-person follow behind and above an entity.
        case street(following: Entity)
        /// Orbit view looking at a ground point.
        case overview(center: SIMD3<Float>, distance: Float, pitchDegrees: Float, yawDegrees: Float, fieldOfViewDegrees: Float)
    }

    public var mode: Mode
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
    @ObservationIgnored var characterHeight: Float?
    /// Where the camera looks (for clutter and cut-away).
    @ObservationIgnored public private(set) var lookTarget: SIMD3<Float> = .zero

    public init(mode: Mode) {
        self.mode = mode
    }

    public func userDidInteract() { lastInteraction = Date() }

    /// Places `camera` for this frame. Returns the follow target (for the cut-away), if any.
    func update(camera: Entity, scene: RealityKit.Scene?, dt: Float) -> SIMD3<Float>? {
        switch mode {
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
            if characterHeight == nil {
                let b = entity.visualBounds(relativeTo: entity)
                characterHeight = max(0.2, b.extents.y)
            }
            let h = characterHeight!
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
            // Distance so the character fills `screenFraction` of the screen height.
            let fov = s.fieldOfViewDegrees * .pi / 180
            let base = h / (2 * tan(fov / 2) * s.screenFraction)
            let wanted = base * max(s.minZoom, min(s.maxZoom, zoom))
            let yaw = smoothedYaw!
            let dir = SIMD3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))

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

    private func setFOV(_ camera: Entity, _ fov: Float) {
        if var c = camera.components[PerspectiveCameraComponent.self], c.fieldOfViewInDegrees != fov {
            c.fieldOfViewInDegrees = fov
            camera.components.set(c)
        }
    }
}
