import Foundation
import Testing
import WorldGeo
@testable import WorldGen

/// The lighting bible's sun-bearing check (look-fix-v1 §2.1): the light the renderers get points
/// where the fixture's sun is, so shadows fall on bearing A + 180° with length/height = cot(e).
/// Fixtures come from the bible data (Profiles/lighting-bible.json, generated from the proposal's
/// lighting-fixtures.json; computed there from this repository's SolarPosition, no refraction).
@Suite("Sun bearing against the lighting-bible fixtures")
struct SunBearingTests {
    let bible = try! StyleLibrary.lightingBible()
    var observer: GeoCoordinate { GeoCoordinate(latitude: 39.7528379, longitude: -105.0467978) }

    func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s.replacingOccurrences(of: "+00:00", with: "Z"))! }

    @Test func solarPositionMatchesTheFixtures() {
        for (name, f) in bible.states {
            let sun = SolarPosition(date: date(f.utc), at: observer)
            #expect(abs(sun.elevation - f.elevation) < 0.1, "\(name) elevation \(sun.elevation)")
            var dA = abs(sun.azimuth - f.azimuth).truncatingRemainder(dividingBy: 360)
            dA = min(dA, 360 - dA)
            #expect(dA < 0.1, "\(name) azimuth \(sun.azimuth)")
        }
    }

    /// The renderers' light vector: shadow bearing within 1°, shadow length within 5% (e ≥ 5°).
    @Test func lightDirectionCastsTrueShadows() throws {
        let tables = try StyleLibrary.lighting()
        for (name, f) in bible.states where f.elevation >= 5 {
            let L = LightingModel.state(at: date(f.utc), location: observer, tables: tables)
            let d = L.sunDirection  // toward the sun; scene axes: east +x, up +y, north −z
            // Shadows fall away from the sun: east = −x, north = +z.
            var bearing = atan2(Double(-d.x), Double(d.z)) * 180 / .pi
            if bearing < 0 { bearing += 360 }
            var dB = abs(bearing - (f.azimuth + 180).truncatingRemainder(dividingBy: 360))
            dB = min(dB, 360 - dB)
            #expect(dB < 1, "\(name) shadow bearing \(bearing)")
            let lengthPerHeight = Double((d.x * d.x + d.z * d.z).squareRoot() / d.y)
            let expected = 1 / tan(f.elevation * .pi / 180)
            #expect(abs(lengthPerHeight / expected - 1) < 0.05, "\(name) L/H \(lengthPerHeight) vs \(expected)")
        }
    }
}
