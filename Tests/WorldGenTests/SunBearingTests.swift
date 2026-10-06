import Foundation
import Testing
import WorldGeo
@testable import WorldGen

/// The lighting bible's sun-bearing check (look-fix-v1 §2.1): the light the renderers get points
/// where the fixture's sun is, so shadows fall on bearing A + 180° with length/height = cot(e).
/// Fixture values are copied from docs/proposals/look-fix-v1/lighting-fixtures.json (computed
/// there from this repository's SolarPosition formula, geometric, no refraction).
@Suite("Sun bearing against the lighting-bible fixtures")
struct SunBearingTests {
    static let observer = GeoCoordinate(latitude: 39.7528379, longitude: -105.0467978)
    static let fixtures: [(id: String, utc: String, elevation: Double, azimuth: Double)] = [
        ("lighting-01-morning", "2026-07-15T14:00:00Z", 23.5991, 81.0314),
        ("lighting-02-midday", "2026-07-15T19:06:00Z", 71.6718, 179.8282),
        ("lighting-03-ordinary-1530", "2026-07-15T21:30:00Z", 54.3830, 249.7682),
        ("lighting-04-golden-hour", "2026-07-16T01:45:00Z", 6.4698, 292.5126),
        ("lighting-05-blue-hour", "2026-07-16T03:00:00Z", -6.1922, 304.5426),
        ("lighting-10-snow", "2026-01-15T19:00:00Z", 29.1917, 177.4080),
        ("lighting-11-moon-night", "2026-01-04T02:00:00Z", -24.5701, 260.0739),
        ("lighting-12-moonless-night", "2026-01-19T02:00:00Z", -22.0919, 261.3284),
    ]

    static func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }

    @Test func solarPositionMatchesTheFixtures() {
        for f in Self.fixtures {
            let sun = SolarPosition(date: Self.date(f.utc), at: Self.observer)
            #expect(abs(sun.elevation - f.elevation) < 0.1, "\(f.id) elevation \(sun.elevation)")
            var dA = abs(sun.azimuth - f.azimuth).truncatingRemainder(dividingBy: 360)
            dA = min(dA, 360 - dA)
            #expect(dA < 0.1, "\(f.id) azimuth \(sun.azimuth)")
        }
    }

    /// The renderers' light vector: shadow bearing within 1°, shadow length within 5% (e ≥ 5°).
    @Test func lightDirectionCastsTrueShadows() throws {
        let tables = try StyleLibrary.lighting()
        for f in Self.fixtures where f.elevation >= 5 {
            let L = LightingModel.state(at: Self.date(f.utc), location: Self.observer, tables: tables)
            let d = L.sunDirection  // toward the sun; scene axes: east +x, up +y, north −z
            // Shadows fall away from the sun: east = −x, north = +z.
            var bearing = atan2(Double(-d.x), Double(d.z)) * 180 / .pi
            if bearing < 0 { bearing += 360 }
            var dB = abs(bearing - (f.azimuth + 180).truncatingRemainder(dividingBy: 360))
            dB = min(dB, 360 - dB)
            #expect(dB < 1, "\(f.id) shadow bearing \(bearing)")
            let lengthPerHeight = Double((d.x * d.x + d.z * d.z).squareRoot() / d.y)
            let expected = 1 / tan(f.elevation * .pi / 180)
            #expect(abs(lengthPerHeight / expected - 1) < 0.05, "\(f.id) L/H \(lengthPerHeight) vs \(expected)")
        }
    }
}
