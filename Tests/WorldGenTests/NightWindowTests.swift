import Foundation
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// night-fog-v1: each window's warm (extra.z = 1) or cool (0) light follows the area's windowWarmShare.
struct NightWindowTests {
    @Test func warmShareComesFromTheArea() {
        #expect(LookSpec.windowWarmShare(profile: "chicago-dense-north") == 0.85)
        #expect(LookSpec.windowWarmShare(profile: "wilmette") == 0.9)
        #expect(LookSpec.windowWarmShare(profile: "front-range") == 0.85)
    }

    @Test func windowsSplitWarmAndCool() throws {
        let gen = try HouseDetailTests.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var warm = 0, total = 0
        for (_, ring) in HouseDetailTests.rings {
            for id in Int64(1)...Int64(80) {
                let m = gen.generate(testBuilding(61_000 + id, ring), palette: &palette, lod: .near).mesh
                for i in 0..<m.vertexCount where (Int(m.paints[i].z) & Paint.Flags.glass.rawValue) != 0 && m.extras[i].y > 0 {
                    total += 1
                    if m.extras[i].z == 1 { warm += 1 }
                }
            }
        }
        try #require(total > 500)
        let share = Double(warm) / Double(total)
        #expect(abs(share - 0.85) < 0.08, "warm share \(share) of \(total) glass vertices")
    }
}
