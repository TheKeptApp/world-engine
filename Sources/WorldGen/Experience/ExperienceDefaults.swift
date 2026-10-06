import Foundation
import simd
import WorldGeo

/// experience-v1 §3 "experience defaults": what a renderer needs to open on a no-character view
/// (composed postcards, the aerial diorama fit, motion bounds). Plain numbers and strings, written
/// into the package's environment.json and used in-process by RealityKit.
public struct ExperienceDefaults: Codable, Sendable, Equatable {
    public struct Aerial: Codable, Sendable, Equatable {
        /// Ground point the diorama orbits (scene metres).
        public var center: [Double]
        public var distance: Double
        public var downPitchDegrees: Double
        public var headingDegrees: Double
        public var verticalFOVDegrees: Double
        public var minPitchDegrees: Double
        public var maxPitchDegrees: Double
    }

    public struct Motion: Codable, Sendable, Equatable {
        public var exploreEyeHeight = 1.65
        public var exploreSpeed = 1.4
        public var exploreSpeedRange = [0.7, 3.0]
        public var exploreAcceleration = 1.5
        public var exploreTurnDegreesPerSecond = 60.0
        public var explorePitchRange = [-45.0, 60.0]
        public var routeEyeHeight = 2.0
        public var routeAimHeight = 1.2
        public var routeScenicSpeed = 1.4
        public var routeMaxSpeed = 5.0
        public var routeAcceleration = 1.0
        public var routeTurnDegreesPerSecond = 30.0
        public var routeMaxDownPitchDegrees = 20.0
        /// Look-ahead = clamp(2 + 2v, 4, 18) metres along the path.
        public var routeLookAhead = [2.0, 2.0, 4.0, 18.0]

        public init() {}
    }

    public var version = 1
    public var model = "experience-v1 §4 bounded heuristic"
    public var composedAt: String
    public var lightTimes: [String]
    public var postcards: [PostcardComposer.Postcard]
    public var defaultPostcard: String?
    public var candidatesConsidered: Int
    public var posesScored: Int
    public var rejected: [String: Int]
    public var fallback: String?
    public var aerial: Aerial
    public var motion = Motion()

    /// Composes the defaults for a built world. Light fit averages golden hour, noon and mid-morning
    /// of the build date (real sun directions), so the winner reads at more than one time.
    public static func compose(build: WorldBuild, date: Date) -> ExperienceDefaults {
        let times = representativeTimes(around: date, at: build.manifest.center)
        let composer = PostcardComposer(features: build.features, scene: build.scene, focus: build.focus, lightTimes: times)
        let r = composer.compose()
        let b = build.features.bounds
        // Aerial diorama: fit the mapped bounds plus 10% at 55° pitch, 50° FOV, north up.
        let size = (b.max - b.min) * 1.1
        let pitch = 55.0, fov = 50.0
        let fitHeight = max(size.y * sin(pitch * .pi / 180), size.x * 9 / 16 * sin(pitch * .pi / 180))
        let distance = (fitHeight / 2) / tan(fov / 2 * .pi / 180) + size.y / 2 * cos(pitch * .pi / 180)
        let c = (b.min + b.max) / 2
        let iso = ISO8601DateFormatter()
        return ExperienceDefaults(composedAt: iso.string(from: date), lightTimes: times.map(iso.string(from:)),
                                  postcards: r.postcards, defaultPostcard: r.postcards.first?.id,
                                  candidatesConsidered: r.candidatesConsidered, posesScored: r.posesScored, rejected: r.rejected,
                                  fallback: r.fallback,
                                  aerial: Aerial(center: [c.x, 0, -c.y], distance: (distance * 10).rounded() / 10, downPitchDegrees: pitch,
                                                 headingDegrees: 0, verticalFOVDegrees: fov, minPitchDegrees: 45, maxPitchDegrees: 65))
    }

    /// Golden hour (sun 6° and setting), solar noon and mid-morning (sun 25° and rising) on the date.
    static func representativeTimes(around date: Date, at c: GeoCoordinate) -> [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let day = cal.startOfDay(for: date)
        var noon = day, best = -90.0
        var golden: Date?, morning: Date?
        var prev = SolarPosition(date: day, at: c).elevation
        for m in stride(from: 10, through: 2880, by: 10) {
            let t = day.addingTimeInterval(Double(m) * 60)
            let e = SolarPosition(date: t, at: c).elevation
            if e > best && m <= 1440 + 720 { best = e; noon = t }
            if golden == nil, prev > 6, e <= 6, t > noon { golden = t }
            if morning == nil, prev < 25, e >= 25 { morning = t }
            prev = e
        }
        return [golden, noon, morning].compactMap { $0 }
    }
}
