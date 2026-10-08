import Testing
@testable import WorldGen

/// Lake water as the engine reads it (lake-winter-v1 colour, shore, reflection; water-surfaces-v1 wave weights).
@Suite("Lake water values")
struct LakeWaterTests {
    let lake = try! StyleLibrary.lakeWater()

    @Test func readsBothProfilesAndTheShore() {
        #expect(lake.profiles.count == 2)
        #expect(lake.profiles.allSatisfy { $0.shallowHex.hasPrefix("#") && $0.shallowBlendWidthM > 0 && $0.waves.count >= 2 })
        #expect(abs(lake.shoreDarkenMultiplier - 0.88) < 1e-9)
        #expect(lake.waveWeights.count == 4)
        #expect(lake.grazingStrength > lake.f0)
    }

    @Test func wavesAndRoughnessGrowWithWind() {
        for p in lake.profiles {
            #expect(p.wave(windKmh: 0).amplitudeM == 0)
            #expect(p.wave(windKmh: 18).amplitudeM > p.wave(windKmh: 10).amplitudeM)
        }
        #expect(lake.roughness(windKmh: 0) < lake.roughness(windKmh: 25))
        #expect(lake.normalAmplitude(windKmh: 0) == 0 && lake.normalAmplitude(windKmh: 25) > lake.normalAmplitude(windKmh: 10))
        #expect(lake.normalStrength < lake.grazingStrength)
    }
}
