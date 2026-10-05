import Foundation
import Testing
@testable import WorldGeo

@Suite("Sun position")
struct SolarTests {
    let denver = GeoCoordinate(latitude: 39.7494, longitude: -105.0445)

    func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    @Test func juneSolsticeNoonElevation() {
        // Solar noon in Denver on 21 June ≈ 13:01 MDT (19:01 UTC): elevation ≈ 90 − 39.75 + 23.44 = 73.7°.
        let s = SolarPosition(date: date("2026-06-21T19:01:00Z"), at: denver)
        #expect(abs(s.elevation - 73.7) < 0.5)
        #expect(abs(s.azimuth - 180) < 3)
    }

    @Test func equinoxNoonAtEquator() {
        let s = SolarPosition(date: date("2026-03-20T12:07:00Z"), at: GeoCoordinate(latitude: 0, longitude: 0))
        #expect(s.elevation > 88)
    }

    @Test func sunsetIsInTheWestAndNightIsBelowTheHorizon() {
        let evening = SolarPosition(date: date("2026-09-23T00:30:00Z"), at: denver) // 18:30 MDT
        #expect(evening.elevation > 0 && evening.elevation < 10)
        #expect(evening.azimuth > 250 && evening.azimuth < 280)
        let night = SolarPosition(date: date("2026-09-23T06:00:00Z"), at: denver)
        #expect(night.elevation < -20)
    }

    @Test func sceneDirectionPointsTowardTheSun() {
        let s = SolarPosition(azimuth: 90, elevation: 0) // due east on the horizon
        let d = s.sceneDirection
        #expect(abs(d.x - 1) < 1e-5 && abs(d.y) < 1e-5 && abs(d.z) < 1e-5)
    }
}
