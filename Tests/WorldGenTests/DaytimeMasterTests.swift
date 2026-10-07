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
        #expect(master.sky.stops.count == 3)
        #expect(master.sky.stops.first!.elevation == 0 && master.sky.stops.last!.elevation == 90)
        #expect(master.sky.stops.last!.hex == (try mv.hex(p + "sky.gradient[0].hex")))
        #expect(master.sunColorHex == (try mv.hex(p + "sun.colorHex")))
        #expect(master.skyFillHex == (try mv.hex(p + "sun.skyFillColorHex")))
        #expect(abs(master.shadowStrength - (try mv.number(p + "shadows.strengthPercent")) / 100) < 1e-12)
        #expect(master.grade.exposureEV == (try mv.number(p + "exposure.relativeEV")))
        #expect(master.grade.contrast == (try mv.number(p + "exposure.contrastSlope")))
        #expect(master.grade.saturation == (try mv.number(p + "exposure.saturationFactor")))
        #expect(master.grade.warmth == (try mv.number(p + "exposure.additionalWarmthPercent")) / 100)
    }

    @Test func clearDaytimeTakesTheMasterGrade() throws {
        let table = try StyleLibrary.grade()
        let afternoon = table.resolve(sunElevation: 54.383, moonLight: 0, weather: nil, weight: 0).look
        #expect(afternoon == master.grade)
        // No mock grades night yet (night-fog-v1 comes later): neutral.
        #expect(table.resolve(sunElevation: -30, moonLight: 0, weather: nil, weight: 0).look == .neutral)
    }
}
