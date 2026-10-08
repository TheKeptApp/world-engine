import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Tree species (foliage-seasons-v1, R approved and binding 2026-10-07): the vegetation.json copies of
/// the pack values, mock values first, mapped species win, inferred species follow the city mix,
/// species silhouettes (proportions, clustering, lobe counts per tier, triangle caps), summer colours.
@Suite("Tree species")
struct TreeSpeciesTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static var foliage: FoliageSeasons { VegetationLibrary.bundled.foliageSeasons! }
    static let mixProfiles = ["chicago-dense-north", "front-range"]

    /// The pack JSON (text, on main), or nil when absent.
    static func pack() throws -> [String: Any]? {
        guard let data = try? Data(contentsOf: root.appendingPathComponent("docs/proposals/foliage-seasons-v1/foliage-values.json")) else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    /// A scene with trees on a 30 m grid (tags per tree) and no buildings.
    static func scene(_ profile: String, _ trees: [[String: String]], season: Int = 1) throws -> GeneratedScene {
        let origin = profile == "front-range" ? GeoCoordinate(latitude: 39.75, longitude: -105.04) : GeoCoordinate(latitude: 41.94, longitude: -87.66)
        var f = MapFeatures(frame: LocalFrame(origin: origin), bounds: Rect2D(centerWidth: 2000, height: 2000))
        for (i, tags) in trees.enumerated() {
            f.points.append(PointFeature(ref: OSMRef(.node, Int64(10_000 + i)), kind: .tree,
                                         position: LocalPoint(Double(i % 60) * 30 - 885, Double(i / 60) * 30 - 885), tags: tags))
        }
        let gen = SceneGenerator(features: f, profile: try StyleLibrary.profile(id: profile), seasonal: try StyleLibrary.seasonalPalette(),
                                 baseColors: try StyleLibrary.baseColors(), season: season, focus: f.bounds)
        return gen.generate()
    }

    static func instance(_ scene: GeneratedScene, _ i: Int) -> PropInstance? {
        let source = OSMRef(.node, Int64(10_000 + i)).description
        return scene.instances.first { $0.source == source }
    }

    // MARK: - Values

    /// P2's mapping covers the pack: every described species (by the compiled mock-value keys) has an
    /// entry, every mix species read from the mock values resolves to a described species with a
    /// silhouette, and `nearest` covers exactly the mix species the pack names but does not describe.
    /// Pack values come from the compiled keys and equal the pack JSON.
    @Test func mappingCoversThePackKeys() throws {
        let f = Self.foliage, m = try #require(MockValues.bundled)
        #expect(f.prefix == "style-b/foliage/")
        for id in f.species.keys { #expect(f.summer(id) != nil && f.dimensions(id) != nil, "\(id): no compiled summer/dimensions") }
        for (name, mix) in f.mixes {
            let ids = f.mixSpecies(mix)
            #expect(ids.count == 6 && ids.allSatisfy { f.kind($0) != nil }, "\(name): \(ids)")
            #expect(m.string("\(f.prefix)cities.\(mix.city).id") == mix.city)
        }
        #expect(Set(f.mixes.values.flatMap(\.profiles)) == Set(Self.mixProfiles))
        for (id, s) in f.species { if let kind = s.kind { #expect(PropKind(rawValue: kind)?.isTree == true, "\(id): \(kind)") } }
        #expect(f.nearest.values.allSatisfy { f.species[$0] != nil })
        guard let pack = try Self.pack() else { return }
        let species = try #require(pack["species"] as? [[String: Any]])
        #expect(Set(species.compactMap { $0["id"] as? String }) == Set(f.species.keys))
        for p in species {
            let id = try #require(p["id"] as? String)
            #expect((p["seasonColours"] as? [String: Any])?["summer"] as? String == f.summer(id), "\(id) summer")
            let dims = try #require(p["dimensionsM"] as? [String: Any])
            #expect(dims["height"] as? [Double] == f.dimensions(id)?.height && dims["spread"] as? [Double] == f.dimensions(id)?.spread, "\(id)")
        }
        let cities = try #require(pack["cities"] as? [[String: Any]])
        let named = Set(cities.flatMap { ($0["mix"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String } })
        #expect(Set(f.nearest.keys) == named.subtracting(f.species.keys))
        print("NEAREST " + f.nearest.sorted { $0.key < $1.key }.map { "\($0.key)→\($0.value)" }.joined(separator: ", "))
    }

    /// Values are read by key (`style-b/foliage/species.<id>.…`).
    @Test func valuesAreReadByKey() throws {
        let f = Self.foliage, id = "ulmus_americana", p = "style-b/foliage/species.\(id)."
        let m = MockValues(strings: [p + "seasonColours.summer": "#123456"],
                           numbers: [p + "dimensionsM.height[0]": 10, p + "dimensionsM.height[1]": 20, p + "dimensionsM.spread[0]": 5, p + "dimensionsM.spread[1]": 7])
        #expect(f.summer(id, mock: m) == "#123456")
        #expect(f.dimensions(id, mock: m)?.height == [10, 20] && f.dimensions(id, mock: m)?.spread == [5, 7])
        #expect(f.summer(id, mock: MockValues(strings: [:], numbers: [:])) == nil)
    }

    // MARK: - Species pick

    /// A species named by OSM tags wins (exact, nearest described, or a genus resolved within the mix),
    /// marked mapped; untagged trees draw from the mix, marked inferred. Profiles without a mix are
    /// unchanged.
    @Test func mappedTagsWin() throws {
        let tagged: [([String: String], String, PropKind)] = [
            (["species": "Ulmus americana"], "ulmus_americana", .treeVase),
            (["species": "Quercus rubra"], "quercus_palustris", .treePyramidal),
            (["taxon": "Picea pungens"], "picea_pungens", .conifer),
            (["genus": "Tilia"], "tilia_cordata", .treePyramidal),
            (["species": "Gleditsia triacanthos", "leaf_type": "broadleaved"], "gleditsia_triacanthos", .treeOpen),
        ]
        var trees: [[String: String]] = tagged.flatMap { Array(repeating: $0.0, count: 10) }
        trees += Array(repeating: ["genus": "Acer"], count: 40) + Array(repeating: [:], count: 60)
        let scene = try Self.scene("chicago-dense-north", trees)
        let f = Self.foliage
        for (i, t) in tagged.enumerated() {
            for j in 0..<10 {
                let inst = try #require(Self.instance(scene, i * 10 + j))
                #expect(inst.species == t.1 && inst.kind == t.2 && inst.speciesFrom == .mapped, "\(t.0): \(inst.species ?? "-") \(inst.kind)")
            }
        }
        let acer = (50..<90).compactMap { Self.instance(scene, $0) }
        #expect(Set(acer.compactMap(\.species)) == ["acer_platanoides", "acer_saccharinum"], "genus Acer within the Chicago mix")
        #expect(acer.allSatisfy { $0.speciesFrom == .mapped && $0.kind == f.kind($0.species!) })
        let mix = try #require(f.mix(forProfile: "chicago-dense-north"))
        for inst in (90..<150).compactMap({ Self.instance(scene, $0) }) {
            if inst.kind == .conifer { #expect(inst.species == nil); continue }   // the Chicago mix has no conifer
            #expect(inst.speciesFrom == .inferred && f.mixSpecies(mix).contains(inst.species ?? "") && inst.kind == f.kind(inst.species!))
        }
        // No mix (Evanston): a tagged elm keeps the genus form, no species.
        let evanston = try Self.scene("evanston", [["species": "Ulmus americana"], [:]])
        #expect(Self.instance(evanston, 0)?.kind == .treeSpreading && evanston.instances.allSatisfy { $0.species == nil })
    }

    /// Inferred species follow the mix: the crown form is drawn from the profile's weights (unchanged),
    /// then a mix species of that colour family with equal odds; conifers from the mix's conifers. 3,600
    /// untagged trees: each species' share within 0.025 of that expectation.
    @Test(arguments: mixProfiles)
    func inferredMixProportions(_ profileID: String) throws {
        let profile = try StyleLibrary.profile(id: profileID)
        let n = 3600
        let scene = try Self.scene(profileID, Array(repeating: [:], count: n))
        let f = Self.foliage, mix = try #require(f.mix(forProfile: profileID))
        let trees = scene.instances.filter(\.kind.isTree)
        #expect(trees.count == n)
        let w = profile.trees.crownWeights, total = w.values.reduce(0, +)
        var expected: [String: Double] = [:]
        for id in f.mixSpecies(mix) {
            let kind = try #require(f.kind(id))
            if kind == .conifer {
                expected[id, default: 0] += (1 - profile.trees.deciduousShare) / Double(f.mixSpecies(mix).filter { f.kind($0) == .conifer }.count)
            } else {
                let form = PropLibrary.crownForm(kind)
                let peers = f.mixSpecies(mix).filter { f.kind($0).map { $0 != .conifer && PropLibrary.crownForm($0) == form } ?? false }.count
                expected[id, default: 0] += profile.trees.deciduousShare * (w[form] ?? 0) / total / Double(peers)
            }
        }
        var line = "MIXSHARE \(profileID)"
        for id in f.mixSpecies(mix) {
            let share = Double(trees.filter { $0.species == id }.count) / Double(n)
            line += " \(id) \(String(format: "%.3f", share)) (exp \(String(format: "%.3f", expected[id] ?? 0)))"
            #expect(abs(share - (expected[id] ?? 0)) <= 0.025, "\(profileID) \(id): \(share) vs \(expected[id] ?? 0)")
        }
        print(line)
        #expect(trees.allSatisfy { $0.species == nil || ($0.speciesFrom == .inferred && $0.kind == f.kind($0.species!)) })
        // A shared silhouette is scaled to its species' pack proportions.
        for t in trees where t.species != nil {
            let ref = OSMRef(.node, Int64(t.source.split(separator: "/").last!)!)
            let s = f.widthScale(t.species!)
            #expect(abs(t.stretch.x - SceneGenerator.treeStretch(ref).x * s) < 1e-9 && abs(t.stretch.y - SceneGenerator.treeStretch(ref).y * s) < 1e-9)
        }
    }

    /// Generated yard, parkway and canopy trees in Lakeview carry Chicago mix species (inferred).
    @Test func generatedTreesDrawFromTheMix() throws {
        guard BuildingAreaTests.has("lakeview-sheil-park") else { return }
        let b = try YardTests.build("lakeview-sheil-park", "chicago-dense-north")
        let f = Self.foliage, mix = try #require(f.mix(forProfile: "chicago-dense-north"))
        let generated = b.scene.instances.filter { $0.kind.isTree && $0.source.hasPrefix("gen:") }
        #expect(!generated.isEmpty)
        let deciduous = generated.filter { $0.kind != .conifer }
        #expect(deciduous.allSatisfy { f.mixSpecies(mix).contains($0.species ?? "") && $0.speciesFrom == .inferred && $0.kind == f.kind($0.species!) })
        let counts = Dictionary(grouping: deciduous, by: { $0.species! }).mapValues(\.count)
        print("GENSPECIES lakeview \(counts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", "))")
        #expect(Set(counts.keys) == Set(f.mixSpecies(mix)))
    }

    // MARK: - Silhouettes

    static func solid(_ kind: PropKind, lod: Int) throws -> MeshBuffers {
        PropLibrary.mesh(kind, variant: 0, lod: lod, palette: try TreeSilhouetteTests.palette(), style: .solid)
    }

    /// Every mix species: crown width (its silhouette's, times the species width scale) over tree height
    /// lies within the pack's spread/height range [spread min / height max, spread max / height min].
    @Test func silhouettesMatchThePackProportions() throws {
        let f = Self.foliage
        for id in Set(f.mixes.values.flatMap { f.mixSpecies($0) }).sorted() {
            let kind = try #require(f.kind(id)), m = try Self.solid(kind, lod: 0)
            var lo = SIMD3<Float>(repeating: .infinity), hi = -lo, top: Float = 0
            for v in 0..<m.vertexCount {
                let p = m.positions[v]
                top = max(top, p.y)
                if TreeSilhouetteTests.part(m, vertex: v) == .crown || (kind == .conifer && p.y > 0.1) { lo = simd_min(lo, p); hi = simd_max(hi, p) }
            }
            let ratio = Double((hi.x - lo.x + hi.z - lo.z) / 2 / top) * f.widthScale(id)
            let d = try #require(f.dimensions(id))
            let range = (d.spread[0] / d.height[1], d.spread[1] / d.height[0])
            print("SPECIESRATIO \(id) \(kind.rawValue) width/height \(String(format: "%.2f", ratio)) pack \(String(format: "%.2f–%.2f", range.0, range.1)) scale \(String(format: "%.2f", f.widthScale(id)))")
            #expect(ratio >= range.0 && ratio <= range.1, "\(id): \(ratio) outside \(range)")
        }
    }

    /// Each species crown is clustered, not a blob: lobe counts per tier within the pack's (near 9–18,
    /// mid 5–9, far 1–3), solid near sky holes within the pack's proposal (8–22 % of the side outline's
    /// convex hull, mean of four yaws), and a lumpy outline from above and the side.
    @Test(arguments: TreeSilhouetteTests.speciesKinds)
    func speciesCrownsAreClustered(_ kind: PropKind) throws {
        let pack = try Self.pack()
        let crown = (pack?["species"] as? [[String: Any]])?.first?["crown"] as? [String: Any]
        func range(_ key: String, _ fallback: [Double]) -> ClosedRange<Double> {
            let r = (crown?[key] as? [Double]) ?? fallback
            return r[0]...r[1]
        }
        let pieces = try (0..<3).map { lod -> Int in
            let m = try Self.solid(kind, lod: lod)
            return TreeSilhouetteTests.pieces(m, TreeSilhouetteTests.triangles(m, .crown)).count
        }
        #expect(range("nearClusterLobes", [9, 18]).contains(Double(pieces[0])) && range("midClusterLobes", [5, 9]).contains(Double(pieces[1]))
                && range("farMasses", [1, 3]).contains(Double(pieces[2])), "\(kind): lobes per tier \(pieces)")
        let m = try Self.solid(kind, lod: 0), tris = TreeSilhouetteTests.triangles(m, .crown)
        let holes = (0..<4).map { PropTreeLookTests.holeShare(TreeSilhouetteTests.mask(m, tris, yaw: Float($0) * .pi / 4), size: 160) }
        let mean = Double(holes.reduce(0, +) / 4)
        let above = PropTreeLookTests.outline(TreeSilhouetteTests.mask(m, tris, fromAbove: true), size: 160).radii
        let plan = (above.max()! - above.min()!) / above.max()!
        print("SPECIESCROWN \(kind.rawValue) lobes \(pieces) skyholes \(holes.map { String(format: "%.3f", $0) }) mean \(String(format: "%.3f", mean)) plan \(String(format: "%.3f", plan))")
        #expect(range("skyHoleFractionProposal", [0.08, 0.22]).contains(mean), "\(kind): sky holes \(mean)")
        #expect(plan >= 0.15, "\(kind): outline from above varies by only \(plan)")
    }

    /// The silhouettes differ the way the sheets do: vase and open crowns sit high on a clear trunk and
    /// limbs (crown base above half the height), the pyramidal linden's skirt reaches down to about a
    /// third; the open crown is the widest for its crown depth, upright and pyramidal crowns narrower
    /// than the rounded maple's.
    @Test func speciesSilhouettesDiffer() throws {
        var shapes: [PropKind: (base: Float, aspect: Float)] = [:]
        for kind in TreeSilhouetteTests.speciesKinds {
            let m = try Self.solid(kind, lod: 0), size = 160
            let mask = TreeSilhouetteTests.mask(m, TreeSilhouetteTests.triangles(m, .crown), yaw: 0.3, size: size)
            let rows = (0..<size).map { y in (0..<size).filter { mask[y * size + $0] }.count }
            let filled = rows.indices.filter { rows[$0] > 0 }
            let topRow = filled.first!, bottomRow = filled.last!
            // Mask rows: y = (1.1 - height) × size / 1.2.
            let base = 1.1 - Float(bottomRow) * 1.2 / Float(size)
            shapes[kind] = (base, Float(rows.max()!) / Float(bottomRow - topRow))
            print("SPECIESSHAPE \(kind.rawValue) crown base \(String(format: "%.2f", base)) width/crown depth \(String(format: "%.2f", shapes[kind]!.aspect))")
        }
        #expect(shapes[.treeVase]!.base > 0.55 && shapes[.treeOpen]!.base > 0.5 && shapes[.treePyramidal]!.base < 0.36)
        #expect(shapes[.treeVase]!.base > shapes[.treeRounded]!.base + 0.1 && shapes[.treeUpright]!.base < shapes[.treeVase]!.base)
        #expect(shapes[.treeOpen]!.aspect > shapes.filter { $0.key != .treeOpen }.map(\.value.aspect).max()!)
        #expect(shapes[.treeUpright]!.aspect < shapes[.treeRounded]!.aspect && shapes[.treePyramidal]!.aspect < shapes[.treeRounded]!.aspect)
    }

    /// Solid crowns per level within the tree caps: near 900, mid 200, far 52, skyline 12.
    @Test(arguments: TreeSilhouetteTests.speciesKinds)
    func solidLevelsStayWithinTheirCaps(_ kind: PropKind) throws {
        let caps = [PropLibrary.nearTriangleBudget, PropLibrary.treeTriangleBudget.mid, PropLibrary.treeTriangleBudget.far, PropLibrary.skylineTriangleBudget]
        let counts = try (0..<4).map { try Self.solid(kind, lod: $0).triangleCount }
        print("TREELOD solid \(kind.rawValue) \(counts)")
        for (lod, n) in counts.enumerated() { #expect(n <= caps[lod], "\(kind) lod \(lod): \(n) triangles") }
    }

    // MARK: - Colours

    /// Summer crowns in profiles with a mix take the pack species' summer albedo per crown slot (after
    /// the daytime master); spring, autumn and winter are unchanged (the Denver autumn mix holds), and
    /// profiles without a mix are unchanged. Species crowns paint with their form's colour family.
    @Test func summerColoursAreThePacks() throws {
        let lib = VegetationLibrary.bundled, f = Self.foliage
        let seasonal = try StyleLibrary.seasonalPalette(), base = try StyleLibrary.baseColors()
        let crownSlots = SeasonalPalette.order.filter { $0.hasPrefix("deciduous") || $0.hasPrefix("conifer") }
        for profile in Self.mixProfiles + ["evanston"] {
            let region = try #require(lib.region(forProfile: profile))
            let without = MockDaytime.applying(lib.applying(to: SceneGenerator.withLawnEndpoints(seasonal, profileID: profile), profileID: profile))
            for season in 0..<4 {
                let p = try Self.scene(profile, [], season: season).palette
                let reference = Palette(seasonal: without, season: season, base: base)
                for slot in crownSlots {
                    let got = Palette.hex(p.colors[p.named(slot)])
                    let pack = region.slots[slot].flatMap { lib.species[VegetationLibrary.speciesID($0)]?.packSpecies }
                    if season == 1, profile != "evanston", let pack {
                        #expect(got == f.summer(pack), "\(profile) \(slot): \(got) vs \(pack) \(f.summer(pack) ?? "-")")
                    } else {
                        #expect(got == Palette.hex(reference.colors[reference.named(slot)]), "\(profile) season \(season) \(slot) changed")
                    }
                }
            }
        }
        let denver = try Self.scene("front-range", [], season: 1).palette
        print("SUMMER front-range " + crownSlots.map { "\($0) \(Palette.hex(denver.colors[denver.named($0)]))" }.joined(separator: ", "))
        #expect(Palette.hex(denver.colors[denver.named("conifer1")]) == "#617A86" && Palette.hex(denver.colors[denver.named("deciduous5")]) == "#49664C")
        // Species crowns paint every level with their form's family.
        let palette = try TreeSilhouetteTests.palette()
        for kind in TreeSilhouetteTests.speciesKinds {
            let expected = PropLibrary.crownPaint(kind, palette: palette)
            for lod in 0..<4 {
                let m = try Self.solid(kind, lod: lod)
                let crown = (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) == .crown }
                #expect(!crown.isEmpty && crown.allSatisfy { Int(m.paints[$0].x) == expected.slot && Int(m.paints[$0].z) == Int(expected.flags.rawValue) },
                        "\(kind) lod \(lod)")
            }
        }
    }
}
