import Foundation
import simd
import WorldGeo

/// A camera pose in scene metres (east +X, up +Y, north −Z). Renderer-neutral: RealityKit and
/// three.js both place their cameras from it.
public struct CameraPose: Sendable, Equatable {
    public var eye: SIMD3<Double>
    public var target: SIMD3<Double>
    public var verticalFOVDegrees: Double

    public init(eye: SIMD3<Double>, target: SIMD3<Double>, verticalFOVDegrees: Double) {
        self.eye = eye
        self.target = target
        self.verticalFOVDegrees = verticalFOVDegrees
    }

    /// Eased blend for mode transitions (eye and aim interpolate; FOV too).
    public static func blend(_ a: CameraPose, _ b: CameraPose, _ t: Double) -> CameraPose {
        let k = t * t * (3 - 2 * t)
        return CameraPose(eye: a.eye + (b.eye - a.eye) * k, target: a.target + (b.target - a.target) * k,
                          verticalFOVDegrees: a.verticalFOVDegrees + (b.verticalFOVDegrees - a.verticalFOVDegrees) * k)
    }
}

/// Unit view direction for a heading (degrees clockwise from north) and downward pitch.
func viewDirection(heading: Double, downPitch: Double) -> SIMD3<Double> {
    let h = heading * .pi / 180, p = downPitch * .pi / 180
    return SIMD3(sin(h) * cos(p), -sin(p), -cos(h) * cos(p))
}

// MARK: - Aerial diorama

/// experience-v1 §3 aerial diorama: fit the mapped bounds, pitch 45–65°, true metre scale.
/// One-finger pan moves across the ground, pinch changes distance, two-finger rotation changes
/// heading, an explicit tilt control changes pitch. The ground point stays inside the bounds.
public struct AerialRig: Sendable, Equatable {
    public var center: SIMD3<Double>
    public var distance: Double
    public var downPitchDegrees: Double
    public var headingDegrees: Double
    public var verticalFOVDegrees: Double
    public var pitchRange: ClosedRange<Double> = 45...65
    public var distanceRange: ClosedRange<Double>
    /// Ground area the center may move within (local east/north metres).
    public var bounds: Rect2D

    public init(defaults a: ExperienceDefaults.Aerial, bounds: Rect2D) {
        center = SIMD3(a.center[0], a.center[1], a.center[2])
        distance = a.distance
        downPitchDegrees = a.downPitchDegrees
        headingDegrees = a.headingDegrees
        verticalFOVDegrees = a.verticalFOVDegrees
        pitchRange = a.minPitchDegrees...a.maxPitchDegrees
        distanceRange = 120...(a.distance * 1.6)
        self.bounds = bounds
    }

    public var pose: CameraPose {
        let f = viewDirection(heading: headingDegrees, downPitch: downPitchDegrees)
        return CameraPose(eye: center - f * distance, target: center, verticalFOVDegrees: verticalFOVDegrees)
    }

    /// One-finger pan by a screen drag (points), so the ground follows the finger.
    public mutating func pan(by drag: SIMD2<Double>, viewportHeight: Double) {
        let metresPerPoint = 2 * distance * tan(verticalFOVDegrees / 2 * .pi / 180) / max(1, viewportHeight)
        let h = headingDegrees * .pi / 180
        let right = SIMD2(cos(h), sin(h))           // local (east, north) of screen right
        let forward = SIMD2(sin(h), cos(h))         // local (east, north) of screen up
        var local = LocalPoint(center.x, -center.z)
        local -= right * drag.x * metresPerPoint
        local += forward * drag.y * metresPerPoint / sin(downPitchDegrees * .pi / 180)
        local = simd_clamp(local, bounds.min, bounds.max)
        center = SIMD3(local.x, center.y, -local.y)
    }

    public mutating func zoom(by scale: Double) {
        distance = min(distanceRange.upperBound, max(distanceRange.lowerBound, distance / max(0.01, scale)))
    }

    public mutating func rotate(byDegrees d: Double) {
        headingDegrees = (headingDegrees - d + 360).truncatingRemainder(dividingBy: 360)
    }

    public mutating func tilt(toDegrees p: Double) {
        downPitchDegrees = min(pitchRange.upperBound, max(pitchRange.lowerBound, p))
    }
}

// MARK: - Free street exploring

/// experience-v1 §3 free exploring: eye 1.65 m over supported ground, FOV 50°, 1.4 m/s
/// (0.7–3 selectable), acceleration ≤ 1.5 m/s², turn ≤ 60°/s, pitch −45°…+60° (positive down),
/// no roll or head bob. Movement stops at buildings, water and the edge of the data.
public struct ExploreRig: Sendable, Equatable {
    public var position: LocalPoint
    public var eyeHeight: Double
    public var headingDegrees: Double
    public var downPitchDegrees: Double = 0
    public var speed: Double
    public var speedRange: ClosedRange<Double>
    public var acceleration: Double
    public var turnRate: Double
    public var pitchRange: ClosedRange<Double>
    public var verticalFOVDegrees = 50.0
    public private(set) var velocity = LocalPoint(0, 0)
    /// Set when the last step was stopped by a building, water or the data edge.
    public private(set) var blocked: String?

    public init(position: LocalPoint, headingDegrees: Double, motion m: ExperienceDefaults.Motion) {
        self.position = position
        self.headingDegrees = headingDegrees
        eyeHeight = m.exploreEyeHeight
        speed = m.exploreSpeed
        speedRange = m.exploreSpeedRange[0]...m.exploreSpeedRange[1]
        acceleration = m.exploreAcceleration
        turnRate = m.exploreTurnDegreesPerSecond
        pitchRange = m.explorePitchRange[0]...m.explorePitchRange[1]
    }

    public var pose: CameraPose {
        let eye = SIMD3(position.x, eyeHeight, -position.y)
        return CameraPose(eye: eye, target: eye + viewDirection(heading: headingDegrees, downPitch: downPitchDegrees) * 10,
                          verticalFOVDegrees: verticalFOVDegrees)
    }

    /// Direct look from a drag (degrees), pitch clamped.
    public mutating func look(headingBy dh: Double, pitchBy dp: Double) {
        headingDegrees = (headingDegrees + dh + 360).truncatingRemainder(dividingBy: 360)
        downPitchDegrees = min(pitchRange.upperBound, max(pitchRange.lowerBound, downPitchDegrees + dp))
    }

    /// One frame. `move` is the thumb pad (x right, y forward, each −1…1); `turn` is −1…1 from
    /// turn buttons or keys. `canStand` says whether a ground point is walkable.
    public mutating func step(dt: Double, move: SIMD2<Double>, turn: Double, canStand: (LocalPoint) -> String?) {
        guard dt > 0 else { return }
        headingDegrees = (headingDegrees + max(-1, min(1, turn)) * turnRate * dt + 360).truncatingRemainder(dividingBy: 360)
        let h = headingDegrees * .pi / 180
        let forward = LocalPoint(sin(h), cos(h)), right = LocalPoint(cos(h), -sin(h))
        var input = move
        if simd_length(input) > 1 { input = simd_normalize(input) }
        let wanted = (forward * input.y + right * input.x) * speed
        let dv = wanted - velocity
        let maxDV = acceleration * dt
        velocity += simd_length(dv) > maxDV ? simd_normalize(dv) * maxDV : dv
        guard simd_length(velocity) > 1e-4 else { velocity = .zero; blocked = nil; return }
        let next = position + velocity * dt
        // Probe a little ahead so the eye never ends up inside a wall.
        let probe = next + simd_normalize(velocity) * 0.35
        if let reason = canStand(probe) {
            blocked = reason
            velocity = .zero
        } else {
            blocked = nil
            position = next
        }
    }
}

// MARK: - Route flythrough

/// experience-v1 §3 route flythrough: a camera over a recorded path with no entity on it. Eye 2 m
/// above the path, aim 1.2 m at a point clamp(2 + 2v, 4, 18) m ahead, scenic speed 1.4 m/s
/// (cap 5), acceleration ≤ 1 m/s², turning ≤ 30°/s, downward pitch ≤ 20°, no banking. Corners: stay
/// on the path, slow down before sharp turns, then speed up. At a hairpin the look-ahead shortens
/// so the camera never looks across to the opposite leg.
public struct RouteRig: Sendable, Equatable {
    public let path: [LocalPoint]
    public let cumulative: [Double]
    public let loop: Bool
    public var distance = 0.0
    public var scenicSpeed: Double
    public var playing = true
    public var verticalFOVDegrees = 50.0
    public private(set) var speed = 0.0
    let motion: ExperienceDefaults.Motion
    private var heading: Double?
    private var pitch: Double?

    public init(path: [LocalPoint], loop: Bool, motion m: ExperienceDefaults.Motion) {
        var p = path
        if loop, let f = path.first, let l = path.last, simd_distance(f, l) > 0.01 { p.append(f) }
        self.path = p
        var c = [0.0]
        for (a, b) in zip(p, p.dropFirst()) { c.append(c.last! + simd_distance(a, b)) }
        cumulative = c
        self.loop = loop
        motion = m
        scenicSpeed = m.routeScenicSpeed
    }

    public var length: Double { cumulative.last ?? 0 }

    public func point(at s: Double) -> LocalPoint {
        guard path.count >= 2 else { return path.first ?? .zero }
        var d = s
        if loop { d = (d.truncatingRemainder(dividingBy: length) + length).truncatingRemainder(dividingBy: length) }
        d = max(0, min(length, d))
        var lo = 0, hi = cumulative.count - 1
        while hi - lo > 1 { let mid = (lo + hi) / 2; if cumulative[mid] <= d { lo = mid } else { hi = mid } }
        let seg = cumulative[hi] - cumulative[lo]
        return seg > 0 ? path[lo] + (path[hi] - path[lo]) * ((d - cumulative[lo]) / seg) : path[lo]
    }

    /// Change of direction (degrees) between here and `ahead` metres further along.
    func turn(at s: Double, ahead: Double) -> Double {
        let a = point(at: s), b = point(at: s + 1.5), c = point(at: s + ahead), e = point(at: s + ahead + 1.5)
        guard simd_distance(a, b) > 1e-6, simd_distance(c, e) > 1e-6 else { return 0 }
        let d1 = simd_normalize(b - a), d2 = simd_normalize(e - c)
        return acos(max(-1, min(1, simd_dot(d1, d2)))) * 180 / .pi
    }

    public mutating func seek(to s: Double) {
        distance = loop ? s : max(0, min(length, s))
        heading = nil
        pitch = nil
    }

    public mutating func step(dt: Double) {
        guard dt > 0, length > 0 else { return }
        // Target speed: scenic, reduced ahead of sharp turns so the 30°/s turn limit can keep up.
        var target = playing ? min(motion.routeMaxSpeed, scenicSpeed) : 0
        for ahead in stride(from: 2.0, through: 12.0, by: 2.0) {
            let t = turn(at: distance, ahead: ahead)
            if t > 25 { target = min(target, max(0.5, motion.routeTurnDegreesPerSecond / t * ahead / 2)) }
        }
        let dv = max(-motion.routeAcceleration * dt, min(motion.routeAcceleration * dt, target - speed))
        speed = max(0, speed + dv)
        distance += speed * dt
        if loop { distance = distance.truncatingRemainder(dividingBy: length) } else { distance = min(distance, length) }

        // Aim: look-ahead point; shorten it at hairpins.
        var ahead = min(motion.routeLookAhead[3], max(motion.routeLookAhead[2], motion.routeLookAhead[0] + motion.routeLookAhead[1] * speed))
        let here = point(at: distance), tangentAhead = point(at: distance + 1.5)
        let tangent = simd_length(tangentAhead - here) > 1e-6 ? simd_normalize(tangentAhead - here) : LocalPoint(0, 1)
        while ahead > 2, simd_dot(simd_normalize(point(at: distance + ahead) - here + 1e-9), tangent) < 0.2 { ahead *= 0.7 }
        let aim = point(at: distance + ahead)
        let d = aim - here
        let wantHeading = atan2(d.x, d.y) * 180 / .pi
        let eyeY = motion.routeEyeHeight, aimY = motion.routeAimHeight
        let wantPitch = min(motion.routeMaxDownPitchDegrees, atan2(eyeY - aimY, max(0.1, simd_length(d))) * 180 / .pi)
        if let h = heading {
            var delta = (wantHeading - h).truncatingRemainder(dividingBy: 360)
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            let maxTurn = motion.routeTurnDegreesPerSecond * dt
            heading = h + max(-maxTurn, min(maxTurn, delta))
        } else {
            heading = wantHeading
        }
        pitch = pitch.map { $0 + (wantPitch - $0) * min(1, dt * 2) } ?? wantPitch
    }

    public var pose: CameraPose {
        let here = point(at: distance)
        let eye = SIMD3(here.x, motion.routeEyeHeight, -here.y)
        let f = viewDirection(heading: heading ?? 0, downPitch: pitch ?? 0)
        return CameraPose(eye: eye, target: eye + f * 10, verticalFOVDegrees: verticalFOVDegrees)
    }
}
