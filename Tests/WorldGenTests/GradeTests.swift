import CryptoKit
import Foundation
import Testing
@testable import WorldGen

@Suite("Lighting-bible grade (look-fix-v1 §2.2-2.4)")
struct GradeTests {
    let bible = try! StyleLibrary.lightingBible()
    let table = try! StyleLibrary.grade()

    @Test func clearStatesHitTheBibleTargets() {
        for p in table.clear {
            let g = table.resolve(sunElevation: p.elevation, moonLight: 0, weather: nil, weight: 0)
            #expect(g.luma == bible.states[p.state]!.luma, "\(p.state)")
            #expect(g.air?.cap == bible.states[p.state]!.air.cap, "\(p.state)")
        }
        // Between points: linear in elevation; above the highest point: that point.
        let (a, b) = (table.clear[table.clear.count - 2], table.clear[table.clear.count - 1])
        let mid = table.resolve(sunElevation: (a.elevation + b.elevation) / 2, moonLight: 0, weather: nil, weight: 0).luma
        #expect(abs(mid - (a.grade.luma + b.grade.luma) / 2) < 1e-9)
        #expect(table.resolve(sunElevation: 89, moonLight: 0, weather: nil, weight: 0).luma == b.grade.luma)
    }

    @Test func nightFollowsTheMoon() {
        #expect(table.resolve(sunElevation: -20, moonLight: 0, weather: nil, weight: 0).luma == bible.states["moonless-night"]!.luma)
        #expect(table.resolve(sunElevation: -20, moonLight: 1, weather: nil, weight: 0).luma == bible.states["moon-night"]!.luma)
        let dusk = table.resolve(sunElevation: -9, moonLight: 0, weather: nil, weight: 0).luma
        #expect(dusk > bible.states["moonless-night"]!.luma && dusk < bible.states["blue-hour"]!.luma)
    }

    @Test func weatherLeadsByDayOnly() {
        let noon = table.clear.last!.elevation
        for (label, state) in [("thunderstorm", "storm"), ("fog", "fog"), ("snow", "snow"), ("cloudy", "overcast"), ("rain", "light-rain")] {
            #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: label, weight: 1).luma == bible.states[state]!.luma, "\(label)")
        }
        let half = table.resolve(sunElevation: noon, moonLight: 0, weather: "fog", weight: 0.5).luma
        #expect(abs(half - (table.clear.last!.grade.luma + bible.states["fog"]!.luma) / 2) < 1e-9)
        #expect(table.resolve(sunElevation: -20, moonLight: 0, weather: "fog", weight: 1).luma == bible.states["moonless-night"]!.luma)
        #expect(table.resolve(sunElevation: noon, moonLight: 0, weather: "clear", weight: 1).luma == table.clear.last!.grade.luma)
    }

    @Test func everyWeatherLabelHasAGrade() {
        for label in ["cloudy", "rain", "thunderstorm", "fog", "snow", "smoke", "haze", "dust"] {
            #expect(table.weather[label] != nil, "\(label)")
        }
        for g in table.weather.values { #expect(g.saturation > 0.3 && g.saturation <= 1.2) }
    }

    /// Profiles/lighting-bible.json is generated from the proposal (scripts/lookfix_data.py): it must
    /// match the files it names, and the bible-owned time-of-day fields must match it.
    @Test func bibleDataMatchesTheProposal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for (name, source) in bible.sources {
            let data = try Data(contentsOf: root.appendingPathComponent(source.path))
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            #expect(hash == source.sha256, "\(name): \(source.path) changed; rerun scripts/lookfix_data.py")
        }
        let tables = try StyleLibrary.lighting()
        for (key, state) in ["morning": "morning", "noon": "midday", "golden": "golden-hour", "dawn": "blue-hour",
                             "dusk": "blue-hour", "night": "moon-night"] {
            let k = try #require(tables.keys[key]), s = try #require(bible.states[state])
            #expect(k.ambientSky.uppercased() == s.skyFillTint.uppercased(), "\(key) sky fill")
            #expect(k.shadowTint.uppercased() == s.shadeTint.uppercased(), "\(key) shade tint")
            if let sun = s.directTint { #expect(k.sun.uppercased() == sun.uppercased(), "\(key) sun") }
        }
    }
}
