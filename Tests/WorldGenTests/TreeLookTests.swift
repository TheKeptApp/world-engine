import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldMesh

/// Tree look (look-fix-v1 §5): per-level triangle caps, clustered irregular crown outlines.
@Suite("Tree look")
struct PropTreeLookTests {
    static let kinds: [PropKind] = [.treeBroad, .treeOval, .treeSpreading, .conifer]
    /// Whole-tree triangle caps at near, mid, far and skyline detail.
    static let caps = [PropLibrary.nearTriangleBudget, 250, PropLibrary.treeTriangleBudget.far, PropLibrary.skylineTriangleBudget]

    @Test(arguments: kinds)
    func everyLevelStaysWithinItsCap(_ kind: PropKind) throws {
        let counts = try (0..<PropLibrary.lodCount(kind)).map { try TreeSilhouetteTests.mesh(kind, lod: $0).triangleCount }
        print("TREELOD \(kind.rawValue) \(counts)")
        for (lod, n) in counts.enumerated() { #expect(n <= Self.caps[lod], "\(kind) lod \(lod): \(n) triangles") }
    }

    /// Outline radius of a mask (size × size) from its centroid at `angles` directions, in pixels.
    static func outline(_ mask: [Bool], size: Int, angles: Int = 72, upperHalfOnly: Bool = false) -> (radii: [Float], center: SIMD2<Float>) {
        var sum = SIMD2<Float>.zero, n: Float = 0
        for y in 0..<size { for x in 0..<size where mask[y * size + x] { sum += SIMD2(Float(x), Float(y)); n += 1 } }
        let c = sum / max(n, 1)
        var radii: [Float] = []
        for k in 0..<angles {
            let a = (upperHalfOnly ? Float.pi : 2 * Float.pi) * Float(k) / Float(angles) + (upperHalfOnly ? Float.pi : 0)
            let d = SIMD2<Float>(cos(a), sin(a))
            var r: Float = 0, t: Float = 0
            while t < Float(size) {
                let p = c + d * t
                let x = Int(p.x), y = Int(p.y)
                guard x >= 0, y >= 0, x < size, y < size else { break }
                if mask[y * size + x] { r = t }
                t += 0.5
            }
            radii.append(r)
        }
        return (radii, c)
    }

    /// The crown's outline is clustered, not a ball: from above, the outline radius around the crown
    /// varies by at least 15% (notches between lobes); from the side, the upper outline departs from
    /// the crown's bounding ellipse by at least 15% somewhere (an asymmetric top with a notch).
    @Test(arguments: [PropKind.treeBroad, .treeOval, .treeSpreading])
    func crownOutlineIsIrregular(_ kind: PropKind) throws {
        let m = try TreeSilhouetteTests.mesh(kind, lod: 0)
        let crown = TreeSilhouetteTests.triangles(m, .crown)
        let size = 160
        let above = Self.outline(TreeSilhouetteTests.mask(m, crown, fromAbove: true, size: size, atlas: PropLibrary.leafAtlas), size: size).radii
        let plan = (above.max()! - above.min()!) / above.max()!
        var side: [Float] = []
        for k in 0..<4 {
            let mask = TreeSilhouetteTests.mask(m, crown, yaw: Float(k) * .pi / 4, size: size, atlas: PropLibrary.leafAtlas)
            var lo = SIMD2<Int>(size, size), hi = SIMD2<Int>(0, 0)
            for y in 0..<size { for x in 0..<size where mask[y * size + x] { lo = simd_min(lo, SIMD2(x, y)); hi = simd_max(hi, SIMD2(x, y)) } }
            let half = SIMD2<Float>(Float(hi.x - lo.x), Float(hi.y - lo.y)) / 2
            let (radii, _) = Self.outline(mask, size: size, angles: 36, upperHalfOnly: true)
            let rel = radii.enumerated().map { i, r -> Float in
                let a = Float.pi * Float(i) / 36 + .pi
                let e = 1 / ((cos(a) / half.x) * (cos(a) / half.x) + (sin(a) / half.y) * (sin(a) / half.y)).squareRoot()
                return r / e
            }
            side.append(rel.max()! - rel.min()!)
        }
        print("IRREG \(kind.rawValue) plan \(String(format: "%.3f", plan)) side \(side.map { String(format: "%.3f", $0) })")
        #expect(plan >= 0.15, "\(kind): outline from above varies by only \(plan)")
        #expect(side.max()! >= 0.15, "\(kind): side outline departs from its ellipse by only \(side)")
    }

    /// Share of a mask's convex hull it leaves uncovered (sky holes and notches inside the outline).
    static func holeShare(_ mask: [Bool], size: Int) -> Float {
        var pts: [SIMD2<Int>] = []
        for y in 0..<size { for x in 0..<size where mask[y * size + x] { pts.append(SIMD2(x, y)) } }
        pts.sort { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        func cross(_ o: SIMD2<Int>, _ a: SIMD2<Int>, _ b: SIMD2<Int>) -> Int { (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) }
        var lower: [SIMD2<Int>] = [], upper: [SIMD2<Int>] = []
        for p in pts {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        for p in pts.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        let hull = Array(lower.dropLast()) + Array(upper.dropLast())
        var inside = 0, open = 0
        for y in 0..<size { for x in 0..<size {
            let p = SIMD2(x, y)
            guard (0..<hull.count).allSatisfy({ cross(hull[$0], hull[($0 + 1) % hull.count], p) >= 0 }) else { continue }
            inside += 1
            if !mask[y * size + x] { open += 1 }
        } }
        return Float(open) / Float(max(inside, 1))
    }

    /// Sky holes (vegetation-v1 crown construction): from the side, at four yaws, the near crown leaves
    /// open about its family's target share of its convex outline (maple 6%, linden 5%, oak 10%; at least
    /// 60% of it here, the lumps fill a little).
    @Test(arguments: [(PropKind.treeBroad, Float(0.06)), (.treeOval, 0.05), (.treeSpreading, 0.1)])
    func crownHasSkyHoles(_ kind: PropKind, _ target: Float) throws {
        let m = try TreeSilhouetteTests.mesh(kind, lod: 0)
        let crown = TreeSilhouetteTests.triangles(m, .crown)
        let shares = (0..<4).map { Self.holeShare(TreeSilhouetteTests.mask(m, crown, yaw: Float($0) * .pi / 4, size: 160, atlas: PropLibrary.leafAtlas), size: 160) }
        let mean = shares.reduce(0, +) / 4
        print("SKYHOLES \(kind.rawValue) \(shares.map { String(format: "%.3f", $0) }) mean \(String(format: "%.3f", mean)) target \(target)")
        #expect(mean >= 0.6 * target, "\(kind): sky holes \(mean) of the outline, target \(target)")
    }

    /// Each archetype has its own silhouette family: crown width to height differs between kinds.
    @Test func archetypesHaveDistinctProportions() throws {
        var ratios: [Float] = []
        for kind in [PropKind.treeBroad, .treeOval, .treeSpreading] {
            let m = try TreeSilhouetteTests.mesh(kind, lod: 0)
            var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
            for v in 0..<m.vertexCount where TreeSilhouetteTests.part(m, vertex: v) == .crown {
                lo = simd_min(lo, m.positions[v]); hi = simd_max(hi, m.positions[v])
            }
            ratios.append((hi.x - lo.x + hi.z - lo.z) / 2 / (hi.y - lo.y))
        }
        print("CROWNRATIO broad/oval/spreading \(ratios)")
        #expect(ratios[1] < ratios[0] - 0.2 && ratios[2] > ratios[0] + 0.2, "\(ratios)")
    }

    /// Near trunks carry branch stubs where they enter the crown (bark, below the fork).
    @Test(arguments: [PropKind.treeBroad, .treeOval, .treeSpreading])
    func nearTrunkHasBranchStubs(_ kind: PropKind) throws {
        let m = try TreeSilhouetteTests.mesh(kind, lod: 0)
        let top = PropLibrary.lobes(kind).trunkTop
        let low = (0..<m.vertexCount).filter { v in
            TreeSilhouetteTests.part(m, vertex: v) == .branch && m.positions[v].y < top - 0.015
                && simd_length(SIMD2(m.positions[v].x, m.positions[v].z)) > 0.05
        }
        #expect(!low.isEmpty, "\(kind): no branch stubs below the fork")
    }
}

/// Crown style `.puffs` (style-check prototype): within the near/mid budgets, a flared trunk with
/// scaffold limbs, smooth puff normals, darker inside; far and skyline as the solid style.
@Suite("Puff crowns")
struct PuffCrownTests {
    @Test(arguments: [PropKind.treeBroad, .treeOval, .treeSpreading, .treeWeeping])
    func puffTreesFitAndShadeInside(_ kind: PropKind) throws {
        let palette = try TreeSilhouetteTests.palette()
        let meshes = (0..<4).map { PropLibrary.mesh(kind, variant: 0, lod: $0, palette: palette, style: .puffs) }
        print("TREELOD puffs \(kind.rawValue) \(meshes.map(\.triangleCount))")
        #expect(meshes[0].triangleCount <= PropLibrary.nearTriangleBudget && meshes[1].triangleCount <= 250, "\(meshes.map(\.triangleCount))")
        for lod in 2..<4 { #expect(meshes[lod] == PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, style: .solid)) }
        let m = meshes[0]
        // Root flare: the trunk is wider at the ground than a little way up.
        func trunkRadius(near y: Float) -> Float {
            (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) == .trunk && abs(m.positions[$0].y - y) < 0.002 }
                .map { simd_length(SIMD2(m.positions[$0].x, m.positions[$0].z)) }.max() ?? 0
        }
        #expect(trunkRadius(near: 0) >= 1.1 * trunkRadius(near: 0.008), "\(kind): no root flare")
        // Scaffold limbs (bark, sway 0.3) reach into the crown.
        #expect((0..<m.vertexCount).contains { TreeSilhouetteTests.part(m, vertex: $0) == .branch && m.positions[$0].y > PropLibrary.lobes(kind).trunkTop + 0.1 })
        // Darker inside: crown faces turned toward the crown centre have lower AO than those facing out.
        let shape = PropLibrary.lobes(kind)
        var inward: [Float] = [], outward: [Float] = []
        for v in 0..<m.vertexCount where TreeSilhouetteTests.part(m, vertex: v) == .crown && !(kind == .treeWeeping && m.extras[v].y == 0.95) {
            let d = simd_dot(m.normals[v], simd_normalize(m.positions[v] - shape.crown))
            if d < -0.3 { inward.append(m.extras[v].x) } else if d > 0.3 { outward.append(m.extras[v].x) }
        }
        let mean = { (a: [Float]) in a.reduce(0, +) / Float(max(a.count, 1)) }
        print("PUFFAO \(kind.rawValue) inward \(mean(inward)) outward \(mean(outward))")
        #expect(mean(inward) + 0.1 < mean(outward), "\(kind): inside not darker")
    }
}
