import Foundation
import Testing
import WorldGeo
@testable import WorldGen

/// Archetype colour variants follow look.json archetypes.variantWeights (chicago-02-flats variant 1 rare).
struct VariantWeightTests {
    @Test func flatsVariantOneIsRare() throws {
        let w = try #require(BuildingGenerator.variantWeights["chicago-02-flats"])
        #expect(w == [1, 0.25, 1, 1])
        let gen = try HouseDetailTests.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var counts = [Int](repeating: 0, count: 4)
        for id in Int64(1)...Int64(1500) {
            let g = gen.generate(testBuilding(71_000 + id, HouseDetailTests.rect(0, 0, 7.5, 18)), palette: &palette, lod: .far)
            guard g.archetype == "chicago-02-flats", g.colorSet < 4 else { continue }
            counts[g.colorSet] += 1
        }
        let n = counts.reduce(0, +)
        try #require(n > 200, "flats drawn \(n)")
        let share1 = Double(counts[1]) / Double(n)
        #expect(abs(share1 - 0.25 / 3.25) < 0.04, "variant 1 share \(share1), counts \(counts)")
    }
}
