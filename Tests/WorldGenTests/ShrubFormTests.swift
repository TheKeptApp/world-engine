import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMesh

// Shrub forms (look-fix-v1 §1.2): every bush and flowering-bush variant and detail level builds
// within its triangle cap, winds consistently, has the size of its form class, and the original
// variants 0 and 1 are unchanged.

/// FNV-1a over every buffer of a mesh (bit patterns, so any change at all shows).
func meshChecksum(_ m: MeshBuffers) -> UInt64 {
    var h: UInt64 = 0xCBF2_9CE4_8422_2325
    func eat(_ x: UInt32) { for k in 0..<4 { h ^= UInt64((x >> (8 * UInt32(k))) & 0xFF); h &*= 0x100_0000_01B3 } }
    for p in m.positions { eat(p.x.bitPattern); eat(p.y.bitPattern); eat(p.z.bitPattern) }
    for n in m.normals { eat(n.x.bitPattern); eat(n.y.bitPattern); eat(n.z.bitPattern) }
    for v in m.paints + m.extras { eat(v.x.bitPattern); eat(v.y.bitPattern); eat(v.z.bitPattern); eat(v.w.bitPattern) }
    for i in m.indices { eat(i) }
    return h
}

@Suite("Shrub forms")
struct ShrubFormTests {
    static func palette() throws -> Palette {
        Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 1, base: try StyleLibrary.baseColors())
    }

    /// Bush variants 0 and 1 exactly as they were built before shrub forms (origin/main 81a8c52).
    static func referenceBush(_ kind: PropKind, variant: Int, lod: Int, palette: Palette) -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, UInt64(variant), salt: "prop")
        var m = MeshBuffers()
        m.paint = Paint(slot: palette.named("bushes"), shade: kind == .flowerBush ? 1.08 : 1, sway: 0.2)
        let start = m.positions.count
        let radius: Float = variant == 0 ? 0.55 : 0.47
        if lod < 2 {
            PropLibrary.addBlob(&m, center: SIMD3(0, 0.36, 0), radius: radius, squash: 0.72, jitter: lod == 0 ? 0.08 : 0.04, rng: &rng, subdivide: lod == 0)
        } else {
            PropLibrary.addEllipsoid(&m, center: SIMD3(0, 0.36, 0), radii: SIMD3(radius, radius * 0.72, radius), octahedron: true)
        }
        m.bakeAO(from: start) { p, _ in Float(0.62 + 0.38 * smoothstep(0.0, 0.55, Double(p.y))) }
        return m
    }

    /// Triangle counts and checksums of variants 0 and 1 on origin/main (season-1 palette).
    static let originalBushes: [String: (Int, UInt64)] = [
        "bush/0/0": (80, 0x4746667f9a1c636a),
        "bush/0/1": (20, 0xd24c963ce1de12cd),
        "bush/0/2": (8, 0xfae8129fa5b02d7a),
        "bush/1/0": (80, 0x3f8322279e480452),
        "bush/1/1": (20, 0x8fea82cebabe55ca),
        "bush/1/2": (8, 0xff919f4b1d6acf48),
        "flowerBush/0/0": (80, 0x5bb50261601f15e2),
        "flowerBush/0/1": (20, 0x950d1a4ea3c9eda0),
        "flowerBush/0/2": (8, 0xf0096b0bdc5e0b8e),
        "flowerBush/1/0": (80, 0xb43dfbb386ae59f0),
        "flowerBush/1/1": (20, 0x2cc8ddf60ef5eae6),
        "flowerBush/1/2": (8, 0x4b9a4fb683c7c1fc),
    ]

    @Test func originalVariantsUnchanged() throws {
        let palette = try Self.palette()
        var line = "SHRUBBASE"
        for kind in [PropKind.bush, .flowerBush] { for v in 0..<2 { for lod in 0..<3 {
            let m = PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette)
            let ref = Self.referenceBush(kind, variant: v, lod: lod, palette: palette)
            #expect(meshChecksum(m) == meshChecksum(ref), "\(kind) \(v) \(lod)")
            #expect(m.triangleCount == ref.triangleCount)
            let key = "\(kind.rawValue)/\(v)/\(lod)"
            if let (tris, sum) = Self.originalBushes[key] {
                #expect(m.triangleCount == tris, "\(key)")
                #expect(meshChecksum(m) == sum, "\(key)")
            }
            line += " \(key)=\(m.triangleCount):0x\(String(meshChecksum(m), radix: 16))"
        } } }
        print(line)
    }

    @Test func everyVariantAndLevelBuildsWithinCaps() throws {
        let palette = try Self.palette()
        let caps = [80, 24, 8, 4] // near, mid, far, skyline
        #expect(PropLibrary.variants[.bush] == 8)
        #expect(PropLibrary.variants[.flowerBush] == 8)
        var line = "SHRUBTRIS"
        for kind in [PropKind.bush, .flowerBush] {
            #expect(PropLibrary.lodCount(kind) >= 3)
            for v in 0..<PropLibrary.variants[kind]! { for lod in 0..<PropLibrary.lodCount(kind) {
                let m = PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette)
                #expect(!m.isEmpty)
                // Variants 0 and 1 keep their own (unchanged) meshes; the caps hold for the new forms.
                if v >= 2 { #expect(m.triangleCount <= caps[lod], "\(kind) \(v) \(lod): \(m.triangleCount)") }
                #expect(GeometryCheck.windingErrors(m).isEmpty, "\(kind) \(v) \(lod)")
                #expect(GeometryCheck.finite(m))
                #expect(m.paints.count == m.positions.count && m.extras.count == m.positions.count)
                #expect(m.normals.allSatisfy { abs(simd_length($0) - 1) < 1e-3 })
                // Darker underneath (baked AO), never brighter than unoccluded.
                #expect(m.extras.allSatisfy { $0.x > 0.5 && $0.x <= 1 })
                line += " \(kind.rawValue)/\(v)/\(lod)=\(m.triangleCount)"
            } }
        }
        print(line)
    }

    /// Nominal (height, width) per variant from the §1.2 table; hedges also length along +X.
    static let nominal: [Int: (h: Float, w: Float)] = [
        2: (0.45, 0.7), 3: (0.85, 1.15), 4: (1.35, 0.75), 5: (0.95, 0.7), 6: (0.36, 0.75), 7: (0.52, 0.55),
    ]

    @Test func boundsMatchFormClass() throws {
        let palette = try Self.palette()
        var line = "SHRUBBOUNDS"
        for kind in [PropKind.bush, .flowerBush] { for v in 2..<8 {
            let near = PropLibrary.mesh(kind, variant: v, lod: 0, palette: palette)
            let b = try #require(near.bounds)
            let size = b.max - b.min
            let height = b.max.y, width = v == 5 ? size.z : (size.x + size.z) / 2
            let (h, w) = Self.nominal[v]!
            #expect(abs(height / h - 1) <= 0.25, "\(kind) \(v) height \(height)")
            #expect(abs(width / w - 1) <= 0.25, "\(kind) \(v) width \(width)")
            // Sits on the ground: a flat-ish bottom a few centimetres below y = 0.
            #expect(b.min.y < 0 && b.min.y > -0.06, "\(kind) \(v) bottom \(b.min.y)")
            if v == 5 {
                #expect(abs(size.x - 1.0) <= 0.05, "hedge length \(size.x)")
            }
            if [2, 6, 7].contains(v) {
                // Low perennial/cushion: 0.25–0.55 × 0.4–0.9 m.
                #expect(height >= 0.25 && height <= 0.55 && width >= 0.4 && width <= 0.9, "cushion \(v) \(height) × \(width)")
            }
            // Mid and far detail keep the outline.
            for lod in 1..<3 {
                let lb = try #require(PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette).bounds)
                let ls = lb.max - lb.min
                #expect(abs(lb.max.y / height - 1) <= 0.2, "\(kind) \(v) lod \(lod) height \(lb.max.y)")
                #expect(abs(max(ls.x, ls.z) / max(size.x, size.z) - 1) <= 0.25, "\(kind) \(v) lod \(lod) width")
            }
            // Skyline detail (when renderers have it) stays about as tall.
            if PropLibrary.lodCount(kind) > 3 {
                let sb = try #require(PropLibrary.mesh(kind, variant: v, lod: 3, palette: palette).bounds)
                #expect(abs(sb.max.y / height - 1) <= 0.2, "\(kind) \(v) skyline height \(sb.max.y)")
            }
            line += String(format: " %@/%d=%.2fx%.2fx%.2f", kind.rawValue, v, size.x, height, size.z)
        } }
        print(line)
    }

    /// Forms differ from each other (no identical spheres) and the cushion silhouettes are distinct.
    @Test func formsAreDistinct() throws {
        let palette = try Self.palette()
        let sums = (0..<8).map { meshChecksum(PropLibrary.mesh(.bush, variant: $0, lod: 0, palette: palette)) }
        #expect(Set(sums).count == 8)
        // Bodies are shared between kinds; flowering bushes add accents only at near detail.
        for v in 2..<8 {
            let bush = PropLibrary.mesh(.bush, variant: v, lod: 0, palette: palette)
            let flower = PropLibrary.mesh(.flowerBush, variant: v, lod: 0, palette: palette)
            #expect(flower.positions.prefix(bush.positions.count).elementsEqual(bush.positions))
            #expect(flower.triangleCount > bush.triangleCount)
            for lod in 1..<PropLibrary.lodCount(.flowerBush) {
                #expect(PropLibrary.mesh(.flowerBush, variant: v, lod: lod, palette: palette).positions
                    == PropLibrary.mesh(.bush, variant: v, lod: lod, palette: palette).positions)
            }
        }
    }

    /// Flower accents: a small share of the surface, in the flower colours, gated by the leaf threshold.
    @Test func flowerAccentsAreSmall() throws {
        let palette = try Self.palette()
        let flowers = Set([palette.named("flowers"), palette.named("flowersAlt")].map(Float.init))
        for v in 2..<8 {
            let m = PropLibrary.mesh(.flowerBush, variant: v, lod: 0, palette: palette)
            var flowerArea: Float = 0
            for t in 0..<m.triangleCount where flowers.contains(m.paints[Int(m.indices[t * 3])].x) {
                flowerArea += simd_length(m.faceCross(t)) / 2
                #expect(m.extras[Int(m.indices[t * 3])].y > 0)
            }
            #expect(flowerArea > 0)
            #expect(flowerArea / m.surfaceArea < 0.04, "variant \(v) flower share \(flowerArea / m.surfaceArea)")
        }
    }

    /// The hedge segment's ends are flat-ish and full width, so segments every 0.9–1 m read as one row;
    /// its top is uneven by up to about ±0.08 m along the long sides.
    @Test func hedgeSegmentJoins() throws {
        let palette = try Self.palette()
        let m = PropLibrary.mesh(.bush, variant: 5, lod: 0, palette: palette)
        let endPoints = m.positions.filter { $0.x > 0.42 && $0.y > 0.05 }
        let endWidth = (endPoints.map(\.z).max() ?? 0) - (endPoints.map(\.z).min() ?? 0)
        #expect(endWidth > 0.45, "end width \(endWidth)")
        let sideTop = m.positions.filter { abs($0.z) > 0.2 && $0.y > 0.6 }.map(\.y)
        let spread = (sideTop.max() ?? 0) - (sideTop.min() ?? 0)
        #expect(spread > 0.08 && spread < 0.2, "top spread \(spread)")
    }
}
