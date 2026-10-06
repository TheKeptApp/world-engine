import Foundation
import RealityKit
import WorldGen
import WorldGeo

/// Camera rigs for this world's no-character modes (experience-v1 §3), built from the
/// experience defaults composed with the world.
@MainActor
extension World {
    /// The composed postcards, best first.
    public var postcards: [Postcard] { experience?.postcards ?? [] }

    /// A postcard's camera pose.
    public func pose(of p: Postcard) -> CameraPose {
        CameraPose(eye: SIMD3(p.eye[0], p.eye[1], p.eye[2]), target: SIMD3(p.target[0], p.target[1], p.target[2]),
                   verticalFOVDegrees: p.verticalFOVDegrees)
    }

    /// A pose given in local metres around a geographic origin (e.g. the experience-v1 showcase).
    public func pose(origin: GeoCoordinate, eye: [Double], target: [Double], fieldOfViewDegrees: Double) -> CameraPose {
        let o = position(of: origin)
        let base = SIMD3<Double>(Double(o.x), 0, Double(o.z))
        return CameraPose(eye: base + SIMD3(eye[0], eye[1], eye[2]), target: base + SIMD3(target[0], target[1], target[2]),
                          verticalFOVDegrees: fieldOfViewDegrees)
    }

    /// Aerial diorama fitted to the mapped bounds.
    public func makeAerialRig() -> AerialRig? {
        experience.map { AerialRig(defaults: $0.aerial, bounds: features.bounds) }
    }

    /// Free exploring from a pose (eye on the ground, looking the same way).
    public func makeExploreRig(from pose: CameraPose) -> ExploreRig {
        let d = pose.target - pose.eye
        let heading = atan2(d.x, -d.z) * 180 / .pi
        return ExploreRig(position: LocalPoint(pose.eye.x, -pose.eye.z), headingDegrees: heading,
                          motion: experience?.motion ?? ExperienceDefaults.Motion())
    }

    /// Route flythrough along a host-provided geographic path (no entity on it).
    public func makeRouteRig(route: [GeoCoordinate], loop: Bool) -> RouteRig {
        RouteRig(path: route.map(frame.localPoint(of:)), loop: loop, motion: experience?.motion ?? ExperienceDefaults.Motion())
    }
}
