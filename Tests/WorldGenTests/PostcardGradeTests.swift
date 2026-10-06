import Foundation
import simd
import Testing
@testable import WorldGen

/// Quality-mode final grade (Profiles/postcard-grade.json) and the lighting-bible state mapping
/// (docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md §2.2–2.3).
@Suite("Postcard grade")
struct PostcardGradeTests {
    @Test func bundledTableCoversEveryBibleStateAndIsIdentity() throws {
        let table = try PostcardGradeTable.bundled()
        #expect(Set(table.states.keys) == Set(PostcardLightState.allCases.map(\.rawValue)))
        // Shade tints as in §2.3, values identity until tuned.
        let tints: [PostcardLightState: String] = [.morning: "#697DAB", .midday: "#7184AC", .ordinary: "#6E7FAC", .golden: "#7777AA",
                                                   .blue: "#626C9E", .overcast: "#8993AD", .lightRain: "#7786A5", .storm: "#606F94",
                                                   .fog: "#9CAABD", .snow: "#A0AFCB", .moonNight: "#465582", .moonlessNight: "#3E4974"]
        for state in PostcardLightState.allCases {
            let g = table.grade(for: state)
            #expect(g.isIdentity, "\(state)")
            #expect(g.shadeTint == tints[state])
        }
        #expect(table.shadeThreshold > table.shadeSoftness && table.shadeSoftness > 0)
    }

    @Test func identityChangesNothingAndAGradeDoesWhatItSays() {
        let colors: [SIMD3<Double>] = [SIMD3(0, 0, 0), SIMD3(1, 1, 1), SIMD3(0.2, 0.5, 0.8), SIMD3(0.9, 0.3, 0.1)]
        for c in colors {
            #expect(PostcardGrade.identity.apply(c, shadeThreshold: 0.35, shadeSoftness: 0.2) == c)
        }
        // Gain halves, lift raises black, saturation 0 leaves luma only.
        let half = PostcardGrade(gain: [0.5, 0.5, 0.5])
        #expect(simd_length(half.apply(SIMD3(0.8, 0.4, 0.2), shadeThreshold: 0, shadeSoftness: 0.1) - SIMD3(0.4, 0.2, 0.1)) < 1e-12)
        let lifted = PostcardGrade(lift: [0.1, 0.1, 0.1])
        #expect(abs(lifted.apply(SIMD3(0, 0, 0), shadeThreshold: 0, shadeSoftness: 0.1).x - 0.1) < 1e-12)
        let grey = PostcardGrade(saturation: 0).apply(SIMD3(0.9, 0.3, 0.1), shadeThreshold: 0, shadeSoftness: 0.1)
        #expect(abs(grey.x - grey.y) < 1e-12 && abs(grey.y - grey.z) < 1e-12)
        // The shade push moves dark pixels toward the tint's hue at their own brightness, leaves light ones.
        let push = PostcardGrade(shadeTint: "#3E4974", shadeTintStrength: 1)
        let dark = push.apply(SIMD3(0.1, 0.1, 0.1), shadeThreshold: 0.35, shadeSoftness: 0.2)
        #expect(dark.z > dark.x)
        #expect(abs(simd_dot(dark, SIMD3(0.2126, 0.7152, 0.0722)) - 0.1) < 1e-9)
        #expect(push.apply(SIMD3(0.8, 0.8, 0.8), shadeThreshold: 0.35, shadeSoftness: 0.2) == SIMD3(0.8, 0.8, 0.8))
        #expect(!push.isIdentity && PostcardGrade(shadeTint: "#3E4974").isIdentity)
    }

    @Test func lightAndWeatherMapToBibleStates() {
        typealias C = PostcardLightState.Conditions
        func state(_ c: C) -> PostcardLightState { PostcardLightState.resolve(c) }
        // The bible's own fixtures (Sloan's Lake, 15 July 2026; lighting-fixtures.json).
        #expect(state(C(sunElevation: 23.6, sunAzimuth: 81.0, weather: "clear", cloudCover: 0.15, dayFraction: 0.15)) == .morning)
        #expect(state(C(sunElevation: 71.7, sunAzimuth: 179.8, weather: "clear", cloudCover: 0.1, dayFraction: 0.5)) == .midday)
        #expect(state(C(sunElevation: 54.4, sunAzimuth: 249.8, weather: "clear", cloudCover: 0.15, dayFraction: 0.66)) == .ordinary)
        #expect(state(C(sunElevation: 7, sunAzimuth: 295, weather: "clear", dayFraction: 0.95)) == .golden)
        #expect(state(C(sunElevation: -3, sunAzimuth: 300, weather: "clear")) == .blue)
        // Weather sets the light by day.
        #expect(state(C(sunElevation: 40, sunAzimuth: 200, weather: "cloudy", cloudCover: 1)) == .overcast)
        #expect(state(C(sunElevation: 40, sunAzimuth: 200, weather: "clear", cloudCover: 0.9)) == .overcast)
        #expect(state(C(sunElevation: 40, sunAzimuth: 200, weather: "rain", intensity: 0.3)) == .lightRain)
        #expect(state(C(sunElevation: 40, sunAzimuth: 200, weather: "rain", intensity: 0.8)) == .storm)
        #expect(state(C(sunElevation: 40, sunAzimuth: 200, weather: "thunderstorm", intensity: 0.2)) == .storm)
        #expect(state(C(sunElevation: 20, sunAzimuth: 200, weather: "snow", intensity: 1)) == .snow)
        for obscurant in ["fog", "haze", "smoke", "dust"] {
            #expect(state(C(sunElevation: 20, sunAzimuth: 200, weather: obscurant)) == .fog)
        }
        // Night: the Moon decides, weather doesn't.
        #expect(state(C(sunElevation: -20, sunAzimuth: 0, weather: "clear", moonAltitude: 30, moonIlluminatedFraction: 0.6)) == .moonNight)
        #expect(state(C(sunElevation: -20, sunAzimuth: 0, weather: "clear", moonAltitude: -5, moonIlluminatedFraction: 0.9)) == .moonlessNight)
        #expect(state(C(sunElevation: -20, sunAzimuth: 0, weather: "clear", moonAltitude: 30, moonIlluminatedFraction: 0.1)) == .moonlessNight)
        #expect(state(C(sunElevation: -20, sunAzimuth: 0, weather: "rain", cloudCover: 1, moonAltitude: 30, moonIlluminatedFraction: 1)) == .moonlessNight)
        // Without sunrise and sunset: the sun's side of the sky.
        #expect(state(C(sunElevation: 30, sunAzimuth: 120)) == .morning)
        #expect(state(C(sunElevation: 30, sunAzimuth: 240)) == .ordinary)
        #expect(state(C(sunElevation: 55, sunAzimuth: 240)) == .midday)
    }
}
