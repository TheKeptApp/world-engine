import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Weeping willow (vegetation-v1 addendum): curtain crown within the LOD budgets, pale-gold autumn,
/// chosen by Salix tags or the Chicago/North Shore prior near water and in parks.
@Suite("Weeping willow")
struct TreeWillowTests {
    /// Near ≤ 900 (pack 600–900), mid ≤ 250 (pack 200–450), far ≤ 80 (pack 80–180; the curtains on the
    /// far crown), skyline ≤ 12 (pack 8–16).
    @Test func levelsStayWithinBudget() throws {
        let counts = try (0..<4).map { try TreeSilhouetteTests.mesh(.treeWeeping, lod: $0).triangleCount }
        print("TREELOD treeWeeping \(counts)")
        for (n, cap) in zip(counts, [PropLibrary.nearTriangleBudget, 250, 80, PropLibrary.skylineTriangleBudget]) { #expect(n <= cap, "\(counts)") }
    }

    /// Strand cards hang below the dome (6–10 near, 2–4 mid) reaching well under the upper lobes, with
    /// sky between them (15–22% target; at least 60% of 18% here, alpha-tested).
    @Test func curtainsHangWithGaps() throws {
        let shape = PropLibrary.lobes(.treeWeeping)
        let domeBottom = shape.lobes.map { $0.0.y - $0.1 * 0.92 }.min()!
        for (lod, range) in [(0, 6...10), (1, 2...4)] {
            let m = try TreeSilhouetteTests.mesh(.treeWeeping, lod: lod)
            let crown = TreeSilhouetteTests.triangles(m, .crown)
            // Strand cards (atlas row 3) hanging below the dome.
            let strands = TreeSilhouetteTests.pieces(m, crown).filter { p in
                m.uvs[Int(m.indices[p.triangles[0] * 3])].y >= 0.75 && p.lo.y < domeBottom - 0.1
            }
            #expect(range.contains(strands.count), "lod \(lod): \(strands.count) strand cards")
        }
        let m = try TreeSilhouetteTests.mesh(.treeWeeping, lod: 0)
        let crown = TreeSilhouetteTests.triangles(m, .crown)
        let shares = (0..<4).map { PropTreeLookTests.holeShare(TreeSilhouetteTests.mask(m, crown, yaw: Float($0) * .pi / 4, size: 160, atlas: PropLibrary.leafAtlas), size: 160) }
        let mean = shares.reduce(0, +) / 4
        print("SKYHOLES treeWeeping \(shares.map { String(format: "%.3f", $0) }) mean \(String(format: "%.3f", mean)) target 0.18")
        #expect(mean >= 0.6 * 0.18, "sky holes \(mean)")
    }

    /// Willow autumn is greenish-yellow to pale gold, never orange; winter is bare (branch colour).
    @Test func willowColours() throws {
        let autumn = try TreeColourTests.palette(profile: "evanston", season: 2)
        let slot = PropLibrary.crownPaint(.treeWeeping, palette: autumn).slot
        #expect(Palette.hex(autumn.colors[slot]) == "#B3AD5C")
        let c = autumn.colors[slot]
        #expect(abs(c.x - c.y) < 0.05, "willow autumn \(Palette.hex(c)) reads orange")
        let winter = try TreeColourTests.palette(profile: "evanston", season: 3)
        #expect(Palette.hex(winter.colors[slot]) == "#7A7159")
    }

    /// Salix tags pick the willow anywhere; untagged trees near water become willows only where the
    /// profile has the prior (Chicago/North Shore), and only some of them.
    @Test func salixTagsAndThePrior() throws {
        #expect(VegetationLibrary.bundled.form(tags: ["genus": "Salix"]) == "weeping")
        #expect(VegetationLibrary.bundled.form(tags: ["species": "Salix babylonica"]) == "weeping")
        for profile in ["evanston", "front-range"] {
            var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 42.04, longitude: -87.69)), bounds: Rect2D(centerWidth: 600, height: 600))
            let pond = Polygon2D(outer: [LocalPoint(-100, -10), LocalPoint(100, -10), LocalPoint(100, 10), LocalPoint(-100, 10)])
            f.areas.append(AreaFeature(ref: OSMRef(.way, 1), kind: .water, polygon: pond, tags: [:]))
            for i in 0..<80 {
                f.points.append(PointFeature(ref: OSMRef(.node, Int64(2000 + i)), kind: .tree,
                                             position: LocalPoint(Double(i % 40) * 5 - 100, i < 40 ? 20 : 200), tags: ["leaf_type": "broadleaved"]))
            }
            f.points.append(PointFeature(ref: OSMRef(.node, 3000), kind: .tree, position: LocalPoint(150, -200), tags: ["genus": "Salix"]))
            let gen = SceneGenerator(features: f, profile: try StyleLibrary.profile(id: profile), seasonal: try StyleLibrary.seasonalPalette(),
                                     baseColors: try StyleLibrary.baseColors(), season: 1, focus: f.bounds)
            let trees = gen.generate().instances.filter { $0.source.hasPrefix("node/") }
            let near = trees.filter { $0.y > 0 && $0.y < 50 && $0.kind == .treeWeeping }.count, far = trees.filter { $0.y > 100 && $0.y < 300 && $0.kind == .treeWeeping }.count
            #expect(trees.contains { $0.source == OSMRef(.node, 3000).description && $0.kind == .treeWeeping }, "\(profile): tagged Salix")
            print("WILLOWPRIOR \(profile) near water \(near)/40 away \(far)/40")
            if profile == "evanston" { #expect(near >= 4 && near <= 20 && far == 0) } else { #expect(near == 0) }
        }
    }
}
