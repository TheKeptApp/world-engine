import Foundation
import Testing
import WorldGeo
import WorldMesh
@testable import WorldMap
@testable import WorldGen

/// Lake shore band (lake-winter-v1): water-mesh vertices carry the distance to the shore (extra.z) and the
/// lake profile (extra.w); the band is the profile's shallowBlendWidthM wide.
struct ShoreBandTests {
    func water(_ id: Int64, _ tags: Tags, kind: AreaFeature.Kind = .water) -> AreaFeature {
        AreaFeature(ref: OSMRef(.relation,id), kind:kind,
                    polygon:Polygon2D(outer:[LocalPoint(0,0),LocalPoint(20,0),LocalPoint(20,20),LocalPoint(0,20)]), tags:tags)
    }
    @Test func profilesFollowWaterIdentityRatherThanSurroundingRegion() {
        let sloans = ShoreBand.profile(for:water(4049789,["water":"lake","wikidata":"Q7352210"]))
        let michigan = ShoreBand.profile(for:water(999,["water":"lake","wikidata":"Q1169"]))
        #expect(sloans.id == "sloans_lake" && sloans.blendWidth == 2 && sloans.index == 1)
        #expect(michigan.id == "lake_michigan" && michigan.blendWidth == 4 && michigan.index == 0)
        // The same clipped Michigan feature works at Soldier Field and every other region.
        #expect(ShoreBand.profile(for:water(1205149,["water":"lake"])).id == "lake_michigan")
        #expect(ShoreBand.profile(for:water(4049789,["water":"lake"])).id == "sloans_lake")
        for tags in [["water":"lake"],["water":"lake","name":"Sloan’s Lake"],
                     ["water":"river"],["water":"pond"],["water":"basin"]] {
            let p = ShoreBand.profile(for:water(999,tags))
            #expect(p.index == -1 && p.id == nil && p.blendWidth == nil)
        }
        #expect(ShoreBand.profile(for:water(1205149,["water":"lake"],kind:.pool)).index == -1)
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
