import Testing
@testable import WorldGen

@Suite("Lighting-bible grade (look-fix-v1 §2.2)")
struct GradeTests {
    let table = try! StyleLibrary.grade()

    @Test func clearStatesHitTheBibleTargets() {
        for (e, luma) in [(-6.0, 88.0), (6.5, 130), (23.6, 135), (54.4, 140), (71.7, 145), (85, 145)] {
            #expect(abs(table.resolve(sunElevation: e, moonLight: 0, weather: nil, weight: 0).luma - luma) < 0.01, "elevation \(e)")
        }
        // Between points: linear in elevation.
        let mid = table.resolve(sunElevation: (54.4 + 71.7) / 2, moonLight: 0, weather: nil, weight: 0).luma
        #expect(abs(mid - 142.5) < 0.01)
    }

    @Test func nightFollowsTheMoon() {
        #expect(table.resolve(sunElevation: -20, moonLight: 0, weather: nil, weight: 0).luma == 43)
        #expect(table.resolve(sunElevation: -20, moonLight: 1, weather: nil, weight: 0).luma == 57)
        // Twilight between full night (−12°) and blue hour (−6°).
        let dusk = table.resolve(sunElevation: -9, moonLight: 0, weather: nil, weight: 0).luma
        #expect(dusk > 43 && dusk < 88)
    }

    @Test func weatherLeadsByDayOnly() {
        let noon = 71.7
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "thunderstorm", weight: 1).luma == 96)
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "fog", weight: 1).luma == 147)
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "snow", weight: 1).luma == 166)
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "fog", weight: 0.5).luma == (145 + 147) / 2)
        // At night the weather does not move the target.
        #expect(table.resolve(sunElevation: -20, moonLight: 0, weather: "fog", weight: 1).luma == 43)
        // Unknown labels leave the clear grade.
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "clear", weight: 1).luma == 145)
    }

    @Test func everyWeatherLabelHasAGrade() {
        for label in ["cloudy", "rain", "thunderstorm", "fog", "snow", "smoke", "haze", "dust"] {
            #expect(table.weather[label] != nil, "\(label)")
        }
        for g in table.weather.values { #expect(g.saturation > 0.3 && g.saturation <= 1.2) }
    }
}
