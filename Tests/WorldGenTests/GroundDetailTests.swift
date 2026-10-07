import Foundation
import simd
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// Phone-scale lawn detail (look-fix §1.1): in-lot patches, mowing bands, worn edges, contact pools, parkways.
struct GroundDetailTests {
    @Test func fieldStaysInsideTheSpecBounds() {
        var f = LawnField(shade: 1, tone: 0.5, seed: 0.3)
        f.patchLimit = 0.06
        for k in 0..<5 { f.patches.append(.init(c: LocalPoint(Double(k), 0), r: 2, amp: 0.06)) }
        #expect(abs(f.patchFactor(LocalPoint(2, 0)) - 1.06) < 1e-9, "summed patches clamp at +6 %")
        #expect(f.patchFactor(LocalPoint(100, 0)) == 1)
        f.mow = .init(across: LocalPoint(1, 0), start: 0, width: 3, count: 4, amp: 0.03, front: (LocalPoint(0, 0), LocalPoint(0, 1)))
        #expect(f.band(LocalPoint(1, 5)) == 0 && f.band(LocalPoint(4, 5)) == 1 && f.band(LocalPoint(13, 5)) == nil)
        #expect(f.band(LocalPoint(1, -5)) == nil, "bands only on the front lawn")
        #expect(abs(f.mowFactor(0) - f.mowFactor(1) - 0.03) < 1e-9)
        f.worn = [.init(a: LocalPoint(0, 0), u: LocalPoint(0, 1), len: 10, halfHard: 0.55, side: 1, width: 0.5, t0: 2, t1: 8)]
        // Left of a walk heading +y is −x.
        #expect(f.wear(LocalPoint(-0.55, 5)) == 1)
        #expect(f.wear(LocalPoint(-1.2, 5)) == 0 && f.wear(LocalPoint(0.8, 5)) == 0 && f.wear(LocalPoint(-0.6, 9.5)) == 0)
    }

    @Test func poolsDarkenUnderCrownsOnly() {
        let tree = PropInstance(kind: .treeBroad, variant: 0, source: "t", x: 0, y: 0, height: 0, yaw: 0, scale: 10)
        let pools = GroundPools([tree])
        #expect(abs(pools.factor(LocalPoint(0, 0)) - (1 - GroundContrast.spec.poolDepth[0])) < 1e-9)
        #expect(pools.factor(LocalPoint(40, 0)) == 1)
        #expect(pools.factor(LocalPoint(1, 0)) < pools.factor(LocalPoint(2.5, 0)))
    }

    @Test(arguments: YardTests.cases)
    func lawnsCarryDetailWithinBudget(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let b = try YardTests.build(area, profile)
        let stats = b.scene.stats
        let rules = YardLibrary.bundled.rules(for: profile)
        let lots = stats["lots"] ?? 0
        #expect((stats["lawnTriangles"] ?? 0) > 0)
        #expect((stats["mowedLots"] ?? 0) <= lots / 2 + 1, "\(area): at most half of the lawns mowed in bands")
        // Vertex shades stay inside the lot step × patch × band × pool × wear bounds, and lawns
        // under trees read darker than open lawn.
        var under: [Float] = [], open: [Float] = []
        let trees = b.scene.instances.filter { $0.kind.isTree }.map { LocalPoint($0.x, $0.y) }
        var grid: [SIMD2<Int>: [LocalPoint]] = [:]
        for t in trees { grid[SIMD2(Int((t.x / 10).rounded(.down)), Int((t.y / 10).rounded(.down))), default: []].append(t) }
        func nearTree(_ p: LocalPoint, _ d: Double) -> Bool {
            let k = SIMD2(Int((p.x / 10).rounded(.down)), Int((p.y / 10).rounded(.down)))
            for dj in -1...1 { for di in -1...1 { for t in grid[k &+ SIMD2(di, dj)] ?? [] where simd_distance(t, p) < d { return true } } }
            return false
        }
        for chunk in b.scene.chunks {
            for fr in chunk.staticFeatures where fr.feature.hasPrefix("gen:lot:") {
                for i in fr.start..<(fr.start + fr.count) {
                    let shade = chunk.staticMesh.paints[i].y
                    let c = rules.groundContrast ?? .spec
                    let lo = rules.lawnShade[0] * (1 - c.patchAmplitude[1]) * (1 - c.mowContrast / 2) * (1 - c.poolDepth[0])
                    let hi = rules.lawnShade[1] * (1 + c.patchAmplitude[1]) * (1 + c.mowContrast / 2) * (1 + c.wornShade)
                    #expect(Double(shade) > lo - 0.01 && Double(shade) < hi + 0.01)
                    let pos = chunk.staticMesh.positions[i]
                    let p = LocalPoint(Double(pos.x), -Double(pos.z))
                    if nearTree(p, 1.5) { under.append(shade) } else if !nearTree(p, 8) { open.append(shade) }
                }
            }
        }
        if under.count > 20, open.count > 20 {
            let mu = under.reduce(0, +) / Float(under.count), mo = open.reduce(0, +) / Float(open.count)
            #expect(mu < mo - 0.05, "\(area): under trees \(mu) vs open \(mo)")
        }
        // Budget: detailed lawns and parkways per km² of area.
        let km2 = b.features.bounds.width * b.features.bounds.height / 1e6
        let tris = Double((stats["lawnTriangles"] ?? 0) + (stats["parkwayTriangles"] ?? 0)) / km2
        print("ground detail \(area): lawn \(stats["lawnTriangles"] ?? 0) parkway \(stats["parkwayTriangles"] ?? 0) tris, \(Int(tris)) /km², mowed \(stats["mowedLots"] ?? 0)/\(lots), worn \(stats["wornEdges"] ?? 0)")
        #expect(tris < 150_000, "\(area): \(Int(tris)) ground-detail triangles per km²")
    }

    /// Yard shrubs stand back from public sidewalks so none fills a street-level view (P3 daily sheet:
    /// a shrub beside the walk at the camera read as a boulder).
    @Test(arguments: YardTests.cases)
    func shrubsStandBackFromSidewalks(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let b = try YardTests.build(area, profile)
        let walks = SegmentIndex(b.features.sidewalks.map(\.centerline))
        // Walkway cells are filled 0.8 m either side of the centreline; shrubs clear them by 1.0–1.5 m
        // (1 m raster: allow half a cell).
        // Yard and canopy trunks: ≥ 0.75 m from the pavement edge (look-fix §1.2).
        let trunks = b.scene.instances.filter { $0.source.hasPrefix("gen:yardtree:") || $0.source.hasPrefix("gen:canopytree:") }
            .filter { walks.nearest(to: LocalPoint($0.x, $0.y), within: 0.8 + 0.75) != nil }
        #expect(trunks.isEmpty, "\(area): \(trunks.count) yard trees at a sidewalk edge")
        let close = b.scene.instances.filter { $0.source.hasPrefix("gen:shrub:") }
            .filter { walks.nearest(to: LocalPoint($0.x, $0.y), within: 0.8 + 1.0 - 0.75) != nil }
        #expect(close.isEmpty, "\(area): \(close.count) shrubs crowd a sidewalk, e.g. \(close.first.map { "\($0.x), \($0.y)" } ?? "")")
    }
}
