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
        let above = Self.outline(TreeSilhouetteTests.mask(m, crown, fromAbove: true, size: size), size: size).radii
        let plan = (above.max()! - above.min()!) / above.max()!
        var side: [Float] = []
        for k in 0..<4 {
            let mask = TreeSilhouetteTests.mask(m, crown, yaw: Float(k) * .pi / 4, size: size)
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

/// Autumn colour per crown form (look-fix-v1 §5, regions-chicagoland-miami §6): maples (broad) red or
/// orange, linden/upright (oval) yellow or orange, oak/elm/locust (spreading) yellow, orange, russet or
/// late green; no olive slot anywhere, and late-green crowns stay a minority of the Evanston mix.
@Suite("Tree autumn colour")
struct TreeAutumnColourTests {
    static func autumn() throws -> Palette {
        Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 2, base: try StyleLibrary.baseColors())
    }

    /// The slots a crown form's trees pick from.
    static func slots(_ kind: PropKind, _ palette: Palette) -> [Int] {
        let paint = PropLibrary.crownPaint(kind, palette: palette)
        let count = paint.flags.contains(.variant4) ? 4 : paint.flags.contains(.variant2) ? 2 : 1
        return (0..<count).map { paint.slot + $0 }
    }

    @Test func formsPickTheirAutumnFamilies() throws {
        let p = try Self.autumn()
        let d = (1...4).map { p.named("deciduous\($0)") }
        #expect(Self.slots(.treeBroad, p) == [d[1], d[2]])
        #expect(Self.slots(.treeOval, p) == [d[0], d[1]])
        #expect(Self.slots(.treeSpreading, p) == d)
        for kind in [PropKind.treeBroad, .treeOval, .treeSpreading] {
            for lod in 0..<4 {
                let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: p)
                let crown = (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) == .crown }
                let expected = PropLibrary.crownPaint(kind, palette: p)
                #expect(crown.allSatisfy { Int(m.paints[$0].x) == expected.slot && Int(m.paints[$0].z) == Int(expected.flags.rawValue) },
                        "\(kind) lod \(lod): crown paint is not its form's family")
            }
        }
    }

    @Test func noCrownReadsOliveInAutumn() throws {
        let p = try Self.autumn()
        let weights = try StyleLibrary.profile(id: "evanston").trees.crownWeights
        var green = 0.0
        for (kind, form) in [(PropKind.treeBroad, "broad"), (.treeOval, "oval"), (.treeSpreading, "spreading")] {
            let slots = Self.slots(kind, p)
            for s in slots {
                let c = p.colors[s]
                let warm = c.x > c.y + 0.03
                // Late green: clearly green (green over red by 0.08+), not a khaki/olive in between.
                let lateGreen = c.y > c.x + 0.08
                print("AUTUMNSLOT \(form) slot \(s) \(Palette.hex(c)) \(warm ? "warm" : lateGreen ? "late-green" : "OLIVE")")
                #expect(warm || lateGreen, "\(form): slot \(s) \(Palette.hex(c)) reads olive")
                if lateGreen { green += (weights[form] ?? 0) / Double(slots.count) }
            }
            #expect(slots.filter { p.colors[$0].y > p.colors[$0].x }.count * 2 < slots.count,
                    "\(form): most of its trees stay green")
        }
        let total = weights.values.reduce(0, +)
        print("AUTUMNSLOT late-green share \(green / total)")
        #expect(green / total > 0 && green / total <= 0.15, "late-green share \(green / total)")
    }
}
