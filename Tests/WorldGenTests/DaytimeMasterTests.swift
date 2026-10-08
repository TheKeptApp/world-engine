import Foundation
import Testing
@testable import WorldGen

/// The daytime lighting master (house-contrast-v1 sharedLighting) as the engine reads it from
/// mock-values.json: values by key, not copied numbers.
@Suite("Daytime lighting master")
struct DaytimeMasterTests {
    let mv = try! StyleLibrary.mockValues()
    let master = try! StyleLibrary.daytimeMaster()

    @Test func readsThePackKeys() throws {
        let p = "house-contrast-v1/sharedLighting."
        // Stops by elevation (P3 may sample more from the heroes): horizon at 0°, zenith at 90°.
        #expect(master.sky.stops.count >= 3)
        #expect(master.sky.stops.first!.elevation == 0 && master.sky.stops.last!.elevation == 90)
        // style-b-calibration-v2 owns look where it has a value (owner, 7 Oct).
        #expect(master.sky.stops.last!.hex == (try mv.requireHex("style-b/look/lighting.sky.zenithHex")))
        #expect(master.sky.stops.first!.hex == (try mv.requireHex("style-b/look/lighting.sky.horizonHex")))
        #expect(master.sunColorHex == (try mv.requireHex(p + "sun.colorHex")))
        #expect(master.skyFillHex == (try mv.requireHex("style-b/look/lighting.sky.fillHex")))
        #expect(abs(master.shadowStrength - (try mv.requireNumber(p + "shadows.strengthPercent")) / 100) < 1e-12)
        #expect(master.grade.exposureEV == (try mv.requireNumber(p + "exposure.relativeEV")))
        #expect(master.grade.contrast == (try mv.requireNumber(p + "exposure.contrastSlope")))
        #expect(master.grade.saturation == (try mv.requireNumber(p + "exposure.saturationFactor")))
        #expect(master.grade.warmth == (try mv.requireNumber(p + "exposure.additionalWarmthPercent")) / 100)
    }

    @Test func clearDaytimeTakesTheMasterGrade() throws {
        let table = try StyleLibrary.grade()
        let afternoon = table.resolve(sunElevation: 54.383, moonLight: 0, weather: nil, weight: 0).look
        #expect(afternoon == master.grade)
        // No mock grades night yet (night-fog-v1 comes later): neutral.
        #expect(table.resolve(sunElevation: -30, moonLight: 0, weather: nil, weight: 0).look == .neutral)
    }
}
