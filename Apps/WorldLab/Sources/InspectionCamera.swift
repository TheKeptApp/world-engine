import Foundation
import simd
import WorldGeo
import WorldGen

/// WorldLab inspection controls (R, A10 zoom/camera request, 8 Oct 2026).
/// Altitude is metres above the supplied rendered-ground clearance surface, never sea level.
struct InspectionCamera {
    static let altitudeRange = 8.0...1500.0
    static let pitchRange = 5.0...85.0
    var pose: CameraPose
    let defaultPose: CameraPose
    let bounds: Rect2D

    struct Input: Equatable {
        var latitude: Double
        var longitude: Double
        var altitude: Double
        var heading: Double
        var pitch: Double

        init?(_ text: String) {
            let fields = text.split(separator: ",", omittingEmptySubsequences: false)
            let values = fields.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard fields.count == 5, values.count == 5, values.allSatisfy(\.isFinite),
                  (-90...90).contains(values[0]), (-180...180).contains(values[1]),
                  InspectionCamera.pitchRange.contains(values[4]) else { return nil }
            latitude = values[0]; longitude = values[1]; altitude = values[2]
            heading = InspectionCamera.bearing(values[3]); pitch = values[4]
        }
    }

    init(pose: CameraPose, defaultPose: CameraPose, bounds: Rect2D, ground: (SIMD2<Double>) -> Double) {
        self.pose = pose; self.defaultPose = defaultPose
        let heroPoint = SIMD2(defaultPose.eye.x, -defaultPose.eye.z)
        self.bounds = Rect2D(min: simd_min(bounds.min, heroPoint), max: simd_max(bounds.max, heroPoint))
        constrain(ground: ground)
        // A street postcard starts below the new inspection floor; aim at supported ground.
        if !Self.pitchRange.contains(pitch) {
            let h = heading * .pi / 180
            let v = min(Self.pitchRange.upperBound, max(Self.pitchRange.lowerBound, pitch)) * .pi / 180
            self.pose.target = self.pose.eye + SIMD3(sin(h) * cos(v), -sin(v), -cos(h) * cos(v)) * max(10, altitude(ground: ground) / sin(v))
        }
    }

    static func bearing(_ value: Double) -> Double { (value.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) }
    var heading: Double {
        let f = pose.target - pose.eye
        return Self.bearing(atan2(f.x, -f.z) * 180 / .pi)
    }
    var pitch: Double {
        let f = simd_normalize(pose.target - pose.eye)
        return asin(-f.y) * 180 / .pi
    }
    func altitude(ground: (SIMD2<Double>) -> Double) -> Double { pose.eye.y - ground(SIMD2(pose.eye.x, -pose.eye.z)) }

    private mutating func constrain(ground: (SIMD2<Double>) -> Double) {
        let old = pose.eye
        let p = simd_clamp(SIMD2(old.x, -old.z), bounds.min, bounds.max)
        pose.eye.x = p.x; pose.eye.z = -p.y
        let floor = ground(p)
        pose.eye.y = floor + min(Self.altitudeRange.upperBound, max(Self.altitudeRange.lowerBound, old.y - floor))
        pose.target += pose.eye - old
    }

    mutating func set(_ input: Input, frame: LocalFrame, ground: (SIMD2<Double>) -> Double) {
        let p = frame.localPoint(of: GeoCoordinate(latitude: input.latitude, longitude: input.longitude))
        let h = input.heading * .pi / 180, v = input.pitch * .pi / 180
        let f = SIMD3(sin(h) * cos(v), -sin(v), -cos(h) * cos(v))
        let altitude = min(Self.altitudeRange.upperBound, max(Self.altitudeRange.lowerBound, input.altitude))
        pose.eye = SIMD3(p.x, ground(p) + altitude, -p.y)
        pose.target = pose.eye + f * max(10, altitude / sin(v))
        constrain(ground: ground)
    }

    /// One finger orbits the ground-facing target. Heading clockwise from north, pitch positive down.
    mutating func orbit(by delta: SIMD2<Double>, ground: (SIMD2<Double>) -> Double) {
        let altitude = altitude(ground: ground)
        let h = Self.bearing(heading - delta.x * 0.25) * .pi / 180
        let p = min(Self.pitchRange.upperBound, max(Self.pitchRange.lowerBound, pitch + delta.y * 0.2)) * .pi / 180
        let distance = max(10, altitude / sin(p))
        let f = SIMD3(sin(h) * cos(p), -sin(p), -cos(h) * cos(p))
        pose.eye = pose.target - f * distance
        constrain(ground: ground)
    }

    /// Incremental pinch scale: spreading fingers approaches the target.
    mutating func zoom(by scale: Double, ground: (SIMD2<Double>) -> Double) {
        guard scale.isFinite, scale > 0 else { return }
        let oldHeading = heading, oldPitch = pitch
        let old = altitude(ground: ground)
        let wanted = min(Self.altitudeRange.upperBound, max(Self.altitudeRange.lowerBound, old / scale))
        pose.eye = pose.target + (pose.eye - pose.target) * (wanted / max(0.001, old))
        pose.eye.y = ground(SIMD2(pose.eye.x, -pose.eye.z)) + wanted
        // Keep the viewing angles when the ground clearance changes.
        let h = oldHeading * .pi / 180, v = min(Self.pitchRange.upperBound, max(Self.pitchRange.lowerBound, oldPitch)) * .pi / 180
        pose.target = pose.eye + SIMD3(sin(h) * cos(v), -sin(v), -cos(h) * cos(v)) * max(10, wanted / sin(v))
        constrain(ground: ground)
    }

    /// Two fingers translate both eye and target in screen-relative ground metres.
    mutating func pan(by delta: SIMD2<Double>, viewportHeight: Double, ground: (SIMD2<Double>) -> Double) {
        let distance = simd_length(pose.target - pose.eye)
        let metres = 2 * distance * tan(pose.verticalFOVDegrees * .pi / 360) / max(1, viewportHeight)
        let h = heading * .pi / 180
        let right = SIMD3(cos(h), 0, sin(h))
        let forward = SIMD3(sin(h), 0, -cos(h))
        let shift = -right * delta.x * metres + forward * delta.y * metres / max(0.1, sin(pitch * .pi / 180))
        let oldAltitude = altitude(ground: ground)
        pose.eye += shift; pose.target += shift
        let dy = ground(SIMD2(pose.eye.x, -pose.eye.z)) + oldAltitude - pose.eye.y
        pose.eye.y += dy; pose.target.y += dy
        constrain(ground: ground)
    }

    mutating func reset(ground: (SIMD2<Double>) -> Double) {
        pose = defaultPose; constrain(ground: ground)
    }

    func launchArgument(frame: LocalFrame, ground: (SIMD2<Double>) -> Double) -> String {
        let c = frame.coordinate(at: SIMD2(pose.eye.x, -pose.eye.z))
        return String(format: "%.9f,%.9f,%.6f,%.6f,%.6f", c.latitude, c.longitude, altitude(ground: ground), heading, pitch)
    }
}
