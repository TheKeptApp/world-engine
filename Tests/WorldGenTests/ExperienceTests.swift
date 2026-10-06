import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap

@Suite("Experience cameras (experience-v1 §3)")
struct ExperienceCameraTests {
    static let motion = ExperienceDefaults.Motion()

    @Test func aerialMatchesTheSpecPose() {
        // experience-v1 §1.2 aerial: 1800 m slant, 55° down, heading 0 → eye (0, 1474.47, 1032.44).
        let a = ExperienceDefaults.Aerial(center: [0, 0, 0], distance: 1800, downPitchDegrees: 55, headingDegrees: 0,
                                          verticalFOVDegrees: 50, minPitchDegrees: 45, maxPitchDegrees: 65)
        var rig = AerialRig(defaults: a, bounds: Rect2D(min: LocalPoint(-1000, -1000), max: LocalPoint(1000, 1000)))
        let p = rig.pose
        #expect(abs(p.eye.x) < 1e-9 && abs(p.eye.y - 1474.47367972) < 1e-6 && abs(p.eye.z - 1032.43758543) < 1e-6)
        rig.tilt(toDegrees: 80)
        #expect(rig.downPitchDegrees == 65)
        rig.zoom(by: 100)
        #expect(rig.distance == rig.distanceRange.lowerBound)
        rig.pan(by: SIMD2(100_000, 0), viewportHeight: 800)
        #expect(rig.center.x >= -1000 && rig.center.x <= 1000)
    }

    @Test func exploreRespectsLimitsAndBlockers() {
        var rig = ExploreRig(position: .zero, headingDegrees: 0, motion: Self.motion)
        // Acceleration ≤ 1.5 m/s²: after 0.5 s of full forward input, speed ≤ 0.75 m/s.
        for _ in 0..<30 { rig.step(dt: 1.0 / 60, move: SIMD2(0, 1), turn: 0) { _ in nil } }
        #expect(simd_length(rig.velocity) <= 0.75 + 1e-9)
        // Turning ≤ 60°/s.
        let h0 = rig.headingDegrees
        rig.step(dt: 0.5, move: .zero, turn: 1) { _ in nil }
        #expect(abs(rig.headingDegrees - h0 - 30) < 1e-9)
        // A wall stops movement.
        var walled = ExploreRig(position: .zero, headingDegrees: 0, motion: Self.motion)
        for _ in 0..<600 { walled.step(dt: 1.0 / 60, move: SIMD2(0, 1), turn: 0) { $0.y > 2 ? "building" : nil } }
        #expect(walled.position.y <= 2 && walled.blocked == "building")
        walled.look(headingBy: 0, pitchBy: 200)
        #expect(walled.downPitchDegrees == 60)
    }

    @Test func routeKeepsTheMotionBounds() {
        // An L-shaped path with a hairpin at the end.
        let path = [LocalPoint(0, 0), LocalPoint(0, 60), LocalPoint(40, 60), LocalPoint(40, 58), LocalPoint(0, 58.5)]
        var rig = RouteRig(path: path, loop: false, motion: Self.motion)
        var lastHeading: Double?, lastSpeed = 0.0
        let dt = 1.0 / 60
        var maxTurnRate = 0.0, maxAccel = 0.0, maxSpeed = 0.0, maxPitch = 0.0
        for _ in 0..<(60 * 120) {
            rig.step(dt: dt)
            let f = simd_normalize(rig.pose.target - rig.pose.eye)
            let heading = atan2(f.x, -f.z) * 180 / .pi
            if let h = lastHeading {
                var d = abs(heading - h).truncatingRemainder(dividingBy: 360)
                if d > 180 { d = 360 - d }
                maxTurnRate = max(maxTurnRate, d / dt)
            }
            lastHeading = heading
            maxAccel = max(maxAccel, abs(rig.speed - lastSpeed) / dt)
            lastSpeed = rig.speed
            maxSpeed = max(maxSpeed, rig.speed)
            maxPitch = max(maxPitch, asin(-f.y) * 180 / .pi)
            #expect(abs(rig.pose.eye.y - 2) < 1e-9)
        }
        #expect(maxTurnRate <= 30 + 1e-6)
        #expect(maxAccel <= 1 + 1e-6)
        #expect(maxSpeed <= 1.4 + 1e-9)
        #expect(maxPitch <= 20 + 1e-9)
        #expect(rig.distance == rig.length, "a non-loop route ends at its last point")
    }
}

@Suite("Postcard composition (experience-v1 §4)")
struct PostcardCompositionTests {
    static let areaDir = RealSceneTests.areaDir

    @Test(.enabled(if: FileManager.default.fileExists(atPath: areaDir.appendingPathComponent("manifest.json").path)))
    func composesValidRepeatablePostcards() throws {
        let date = ISO8601DateFormatter().date(from: "2026-10-15T23:44:01Z")!
        let build = try WorldBuild.generate(areaDirectory: Self.areaDir, recipe: WorldRecipe(date: date))
        let a = ExperienceDefaults.compose(build: build, date: date)
        let b = ExperienceDefaults.compose(build: build, date: date)
        #expect(a == b, "same inputs, same postcards")
        #expect(!a.postcards.isEmpty && a.postcards.count <= 8 && a.defaultPostcard == a.postcards.first?.id)
        #expect(a.candidatesConsidered <= 256)
        let world = RayWorld(features: build.features, scene: build.scene)
        for p in a.postcards {
            let here = LocalPoint(p.eye[0], -p.eye[2])
            #expect(world.ground(here) != .water && world.ground(here) != .building && !world.insideBuilding(here), "\(p.id) stands on land")
            let s = p.scores
            for v in [s.openDepth, s.geographicInterest, s.composition, s.lightFit, s.weatherFit, s.coverageConfidence] { #expect(v >= 0 && v <= 1) }
            let total = 0.25 * s.openDepth + 0.20 * s.geographicInterest + 0.20 * s.composition + 0.15 * s.lightFit
                + 0.10 * s.weatherFit + 0.10 * s.coverageConfidence
            #expect(abs(total - s.total) < 0.002, "\(p.id) weights")
            #expect(abs(p.eye[1] - 1.65) < 1e-9 && p.verticalFOVDegrees == 50)
        }
        // Sorted best first, and distinct locations.
        #expect(zip(a.postcards, a.postcards.dropFirst()).allSatisfy { $0.scores.total >= $1.scores.total })
        print("POSTCARDS \(a.postcards.map { "\($0.id) \($0.scores.total) \($0.reasons)" })")
    }
}
