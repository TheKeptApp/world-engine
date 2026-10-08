import Testing
import simd
import WorldGeo
import WorldGen
@testable import WorldLabCamera

@Suite("WorldLab inspection camera")
struct InspectionCameraTests {
    let bounds = Rect2D(min: [-2000, -2000], max: [2000, 2000])
    let ground: (SIMD2<Double>) -> Double = { _ in 0.2 }
    var hero: CameraPose { CameraPose(eye: [0, 100.2, 100], target: [0, 0.2, 0], verticalFOVDegrees: 50) }
    func rig() -> InspectionCamera { InspectionCamera(pose: hero, defaultPose: hero, bounds: bounds, ground: ground) }

    @Test func defaultHeroPoseIsPreservedOutsideMappedBounds() {
        let small = Rect2D(min: [-10, -10], max: [10, 10])
        var r = InspectionCamera(pose: hero, defaultPose: hero, bounds: small, ground: ground)
        #expect(r.pose == hero)
        r.zoom(by: 2, ground: ground)
        r.reset(ground: ground)
        #expect(r.pose == hero)
    }
    @Test func altitudeLimitsAndReset() {
        var r = rig()
        r.zoom(by: 10000, ground: ground)
        #expect(abs(r.altitude(ground: ground) - 8) < 1e-9)
        r.zoom(by: 0.00001, ground: ground)
        #expect(abs(r.altitude(ground: ground) - 1500) < 1e-9)
        r.reset(ground: ground)
        #expect(r.pose == hero)
    }
    @Test func orbitChangesAnglesAndKeepsClearance() {
        var r = rig()
        let old = r.pose
        r.orbit(by: [100, 5000], ground: ground)
        #expect(r.pose != old)
        #expect(abs(r.pitch - 85) < 1e-8)
        #expect(abs(r.altitude(ground: ground) - 100) < 1e-8)
    }
    @Test func panMaintainsAnglesAndGroundClearance() {
        var r = rig()
        let h = r.heading, p = r.pitch
        let sloped: (SIMD2<Double>) -> Double = { point in 0.2 + abs(point.x) * 0.1 }
        r.pan(by: [100, 40], viewportHeight: 800, ground: sloped)
        #expect(abs(r.altitude(ground: sloped) - 100) < 1e-8)
        #expect(abs(r.heading - h) < 1e-8 && abs(r.pitch - p) < 1e-8)
        r.pan(by: [1e9, 1e9], viewportHeight: 800, ground: sloped)
        #expect(bounds.contains(SIMD2(r.pose.eye.x, -r.pose.eye.z)))
        #expect(InspectionCamera.altitudeRange.contains(r.altitude(ground: sloped)))
    }
    @Test func launchPoseRoundTrip() throws {
        let frame = LocalFrame(origin: GeoCoordinate(latitude: 39.7494, longitude: -105.0445))
        let input = try #require(InspectionCamera.Input("39.7500,-105.0435,40,270,45"))
        var r = rig(); r.set(input, frame: frame, ground: ground)
        let text = r.launchArgument(frame: frame, ground: ground)
        var second = rig(); second.set(try #require(InspectionCamera.Input(text)), frame: frame, ground: ground)
        #expect(simd_distance(r.pose.eye, second.pose.eye) < 0.0002)
        #expect(simd_distance(r.pose.target, second.pose.target) < 0.0002)
        #expect(abs(r.altitude(ground: ground) - 40) < 1e-8)
        #expect(abs(r.heading - 270) < 1e-8 && abs(r.pitch - 45) < 1e-8)
        r.set(try #require(InspectionCamera.Input("39.7500,-105.0435,1e308,270,5")), frame: frame, ground: ground)
        #expect(abs(r.altitude(ground: ground) - 1500) < 1e-8)
        #expect(r.pose.target.x.isFinite && r.pose.target.y.isFinite && r.pose.target.z.isFinite)
    }
    @Test(arguments: ["1,2,3,4", "1,2,3,4,5,6", "nan,2,8,0,45", "91,2,8,0,45", "1,181,8,0,45", "1,2,8,0,-30", "1,,8,0,45"])
    func rejectsMalformedPose(_ text: String) { #expect(InspectionCamera.Input(text) == nil) }
    @Test func pinchPreservesHeadingPitchAndRejectsInvalidScale() {
        var r = rig()
        let h = r.heading, p = r.pitch
        r.zoom(by: 2, ground: ground)
        #expect(abs(r.heading - h) < 1e-8 && abs(r.pitch - p) < 1e-8)
        let pose = r.pose
        r.zoom(by: .nan, ground: ground); r.zoom(by: 0, ground: ground)
        #expect(r.pose == pose)
    }
}
