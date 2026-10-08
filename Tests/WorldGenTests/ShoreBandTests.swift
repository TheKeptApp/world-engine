import Foundation
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// Lake shore band (lake-winter-v1): water-mesh vertices carry the distance to the shore (extra.z) and the
/// lake profile (extra.w); the band is the profile's shallowBlendWidthM wide.
struct ShoreBandTests {
    @Test func profileFollowsWaterBodySize() {
        let pond = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(800, 0), LocalPoint(800, 600), LocalPoint(0, 600)])
        let lake = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(20_000, 0), LocalPoint(20_000, 3_000), LocalPoint(0, 3_000)])
        let narrowLong = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(6_000, 0), LocalPoint(6_000, 200), LocalPoint(0, 200)])
        #expect(ShoreBand.profile(for: pond).id == "sloans_lake" && ShoreBand.profile(for: pond).blendWidth == 2)
        #expect(ShoreBand.profile(for: lake).id == "lake_michigan" && ShoreBand.profile(for: lake).blendWidth == 4)
        #expect(ShoreBand.profile(for: narrowLong).id == "lake_michigan", "long fetch counts as open water")
    }

    @Test func squarePondBandIsMitredAndInward() {
        let square = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(20, 0), LocalPoint(20, 20), LocalPoint(0, 20)])
        let m = ShoreBand.mesh(square, width: 2, y: 0.034, slot: 1, profile: 1)
        #expect(m.triangleCount == 8)
        for i in 0..<m.vertexCount {
            let p = LocalPoint(Double(m.positions[i].x), -Double(m.positions[i].z))
            let d = min(p.x, p.y, 20 - p.x, 20 - p.y)
            #expect(abs(d - Double(m.extras[i].z)) < 1e-6, "vertex \(p) distance \(d) vs \(m.extras[i].z)")
            #expect(m.extras[i].w == 1)
        }
    }

    @Test func sloansLakeWaterCarriesShoreDistance() throws {
        guard BuildingAreaTests.has("sloans-lake") else { return }
        let b = try YardTests.build("sloans-lake", "front-range")
        var shore = 0, inner = 0, open = 0
        for chunk in b.scene.chunks {
            for e in chunk.waterMesh.extras {
                if e.z == 0 { shore += 1 } else if abs(e.z - 2) < 1e-6 { inner += 1 } else if e.z == Float(ShoreBand.openWater) { open += 1 }
            }
        }
        #expect(shore > 20 && inner > 20 && open > 0, "shore \(shore) inner \(inner) open \(open)")
    }
}
