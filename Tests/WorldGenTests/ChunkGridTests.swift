import Foundation
import simd
import Testing
import WorldGeo
import WorldMap
@testable import WorldGen

@Suite("Geographic chunk grid alignment")
struct ChunkGridTests {
    @Test func expansionKeepsPhaseAndCoversClippedEdges() {
        let b = Rect2D(min: LocalPoint(-1133, -992), max: LocalPoint(1063, 763))
        let grid = ChunkGrid(bounds: b, size: 200, anchor: .zero)
        #expect(grid.count == SIMD2(12, 9))
        #expect(grid.start == LocalPoint(-1200, -1000))
        var area = 0.0
        for x in 0..<grid.count.x { for y in 0..<grid.count.y {
            let key = SIMD2(x, y), r = grid.rect(key)
            #expect(r.width > 0 && r.width <= 200 && r.height > 0 && r.height <= 200)
            #expect(b.contains(r.min) && b.contains(r.max))
            #expect(grid.index((r.min + r.max) / 2) == key)
            if x + 1 < grid.count.x { #expect(r.max.x == grid.rect(SIMD2(x + 1, y)).min.x) }
            if y + 1 < grid.count.y { #expect(r.max.y == grid.rect(SIMD2(x, y + 1)).min.y) }
            area += r.width * r.height
        } }
        #expect(area == b.width * b.height)
    }

    @Test func legacyLayoutsAreExactlyUnchanged() {
        for (w, h) in [(1000.0, 1000.0), (1600.0, 1200.0), (2199.556, 1750.884)] {
            let b = Rect2D(centerWidth: w, height: h), grid = ChunkGrid(bounds: b, size: 200)
            #expect(grid.start == b.min)
            #expect(grid.count == SIMD2(Int(ceil(w / 200)), Int(ceil(h / 200))))
            for x in 0..<grid.count.x { for y in 0..<grid.count.y {
                let old = Rect2D(min: b.min + LocalPoint(Double(x), Double(y)) * 200,
                                 max: simd_min(b.max, b.min + LocalPoint(Double(x + 1), Double(y + 1)) * 200))
                #expect(grid.rect(SIMD2(x, y)) == old)
            } }
        }
    }

    @Test func translatedGridUsesTheSameCoverageRule() {
        let a = Rect2D(min: LocalPoint(-327, -145), max: LocalPoint(631, 809))
        let delta = LocalPoint(1234.5, -875.25)
        let x = ChunkGrid(bounds: a, size: 200, anchor: LocalPoint(17, 29))
        let y = ChunkGrid(bounds: Rect2D(min: a.min + delta, max: a.max + delta), size: 200, anchor: LocalPoint(17, 29) + delta)
        #expect(x.count == y.count)
        #expect(x.start + delta == y.start)
        for i in 0..<x.count.x { for j in 0..<x.count.y {
            let key = SIMD2(i, j)
            #expect(x.rect(key).min + delta == y.rect(key).min)
            #expect(x.rect(key).max + delta == y.rect(key).max)
        } }
    }

    @Test func anchorIsOptionalInExistingManifests() throws {
        var m = AreaManifest(id: "test", name: "test", center: GeoCoordinate(latitude: 42, longitude: -87), widthMeters: 1000, heightMeters: 1000)
        let legacy = try JSONEncoder().encode(m)
        #expect(try JSONDecoder().decode(AreaManifest.self, from: legacy).gridAnchor == nil)
        #expect((try JSONSerialization.jsonObject(with: legacy) as! [String: Any])["gridAnchor"] == nil)
        m.gridAnchor = GeoCoordinate(latitude: 41.9, longitude: -87.1)
        #expect(try JSONDecoder().decode(AreaManifest.self, from: JSONEncoder().encode(m)) == m)
    }
}
