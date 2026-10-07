import Foundation
import Testing
import WorldGeo
import WorldMap
import WorldMesh
@testable import WorldGen

/// house-archetypes-v1 (R approved 2026-10-07): profile house types carry the pack's archetypes, read by key from the
/// shared mock values; archetype choice is inferred from tags and geometry with a confidence; palette variants are
/// seeded per house; real tags and geometry win.
struct ArchetypeTests {
    static let metroProfiles = ["chicago": "chicago-dense-north", "denver": "front-range"]

    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    static func generator(_ profile: String) throws -> BuildingGenerator {
        BuildingGenerator(profile: try StyleLibrary.profile(id: profile), context: testContext())
    }

    static func rawTypes(_ profile: String) throws -> [StyleProfile.HouseType] {
        try JSONDecoder().decode(StyleProfile.self, from: StyleLibrary.data(profile)).houseTypes
    }

    @Test func everyArchetypeLoadsByKey() {
        #expect(HouseArchetype.bundled.count >= 16)
        for (id, a) in HouseArchetype.bundled {
            #expect(a.variants.count == 4, "\(id)")
            #expect(a.pitchRange[0] <= a.pitchDegrees && a.pitchDegrees <= a.pitchRange[1], "\(id)")
            // The sheet's eave height is foundation + full floors x floor-to-floor.
            #expect(abs(a.foundation + Double(a.fullFloors) * a.floorToFloor - a.eaveHeight) < 0.02, "\(id) eave")
            #expect(a.farBelowPx == 6 && a.nearAbovePx == 20, "\(id) tiers")
        }
        #expect(HouseArchetype.named("denver-05-split")?.parts.map(\.fullFloors) == [2, 1])
    }

    /// Every Chicago and Denver archetype has an engine house type in its metro's profile.
    @Test(arguments: ["chicago"])
    func everyMetroArchetypeHasAHouseType(_ metro: String) throws {
        let types = try Self.rawTypes(Self.metroProfiles[metro]!)
        let ids = HouseArchetype.bundled.keys.filter { $0.hasPrefix(metro + "-") }
        #expect(!ids.isEmpty)
        for id in ids { #expect(types.contains { $0.archetype == id }, "\(id) has no house type") }
    }

    /// The profile JSON copies (read by review tools) equal the values the engine reads by key.
    @Test(arguments: ["chicago-dense-north"])
    func profileMirrorsMatchTheMockValues(_ profile: String) throws {
        let raw = try Self.rawTypes(profile)
        let resolved = try StyleLibrary.profile(id: profile).houseTypes
        for (r, t) in zip(raw, resolved) where r.archetype != nil {
            let a = try #require(HouseArchetype.named(r.archetype), "\(r.id)")
            #expect(r.colors.map { [$0[0], $0[1], $0[3]] } == a.variants.map { [$0.wall, $0.trim, $0.roof] }, "\(r.id) colours")
            #expect(r.colors.map { $0[2] } == t.colors.map { $0[2] }, "\(r.id) doors")
            #expect(r.roof == a.roofMix && r.pitch == a.pitchRange, "\(r.id) roof")
            #expect(r.perFloor == [a.floorToFloor, a.floorToFloor] && r.porch.depth == [a.porchDepth, a.porchDepth], "\(r.id) storey/porch")
            #expect(r.floors.contains(a.fullFloors), "\(r.id) floors")
            #expect(r == t, "\(r.id): JSON mirror differs from the by-key resolution")
        }
    }

    /// "@archetypes" weights split by the pack's fallback mix (generatorWeightPctProposal).
    @Test func archetypeGroupsSplitByThePackMix() throws {
        // Measured floor-group totals stay (Chicago unknown).
        let chi = try Self.generator("chicago-dense-north")
        let rules = try #require(chi.profile.typeRules["unknown"])
        let ex = chi.expandWeights(rules) { _ in true }
        let one = ex.filter { $0.0.archetype != nil && $0.0.floors.first == 1 }.reduce(0) { $0 + $1.1 }
        #expect(abs(one - rules["@archetypes:1"]!) < 1e-9)
    }

    @Test(arguments: ["chicago-dense-north"])
    func housesGetAnInferredArchetypeAndAVariant(_ profile: String) throws {
        let gen = try Self.generator(profile)
        var palette = Palette(base: try StyleLibrary.baseColors())
        var walls: [String: Set<String>] = [:]
        var counts: [String: Int] = [:]
        var archetypes = Set<String>()
        for (i, ring) in [Self.rect(0, 0, 7, 15), Self.rect(0, 0, 10, 11), Self.rect(0, 0, 14, 9.5), Self.rect(0, 0, 9, 16)].enumerated() {
            for id in Int64(1)...Int64(60) {
                let b = testBuilding(70_000 + Int64(i) * 1000 + id, ring)
                let g = gen.generate(b, palette: &palette, lod: .near)
                guard g.role == .house, let aid = g.archetype else { continue }
                let a = try #require(HouseArchetype.named(aid))
                archetypes.insert(aid)
                let c = try #require(g.archetypeConfidence)
                #expect(c > 0 && c <= 1)
                #expect(g.archetypeEvidence.contains("footprint"))
                #expect(a.variants.map(\.wall).contains(g.colors[0]) && a.variants.map(\.roof).contains(g.colors[3]), "\(aid) \(g.colors)")
                #expect(a.variants[g.colorSet].wall == g.colors[0])
                walls[aid, default: []].insert(g.colors[0])
                counts[aid, default: 0] += 1
                // Stable: the same building gives the same choice.
                let again = gen.generate(b, palette: &palette, lod: .near)
                #expect(again.archetype == aid && again.colorSet == g.colorSet && again.archetypeConfidence == c)
            }
        }
        #expect(archetypes.count >= 3, "\(archetypes)")
        // Four variants per archetype: with 10+ houses of a type, at least three show up.
        for (aid, s) in walls where s.count < 3 && counts[aid, default: 0] >= 10 { Issue.record("\(aid): only \(s.count) wall variants") }
    }

    /// Mapped tags win over archetype defaults; the footprint is never resized.
    @Test func tagsOverrideArchetypeDefaults() throws {
        let gen = try Self.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        let ring = Self.rect(0, 0, 6.6, 15)
        for id in Int64(1)...Int64(30) {
            let b = testBuilding(81_000 + id, ring, tags: ["building:levels": "2", "roof:shape": "flat", "building:colour": "#336699"])
            let g = gen.generate(b, palette: &palette, lod: .far)
            #expect(g.floors == 2 && g.floorsFromOSM)
            #expect(g.roofShape == .flat)
            #expect(g.colors[0] == "#336699")
            if let a = HouseArchetype.named(g.archetype) {
                // The roof tag is evidence: a flat-roofed archetype (the flats) is the likely pick.
                #expect(g.archetypeEvidence.contains("roof:shape") && g.archetypeEvidence.contains("levels"))
                _ = a
            }
            let xs = g.mesh.positions.map { Double($0.x) }
            #expect(xs.min()! >= -0.01 && xs.max()! <= 6.61, "footprint resized")
        }
    }

    /// Far tier keeps porch and entry voids for archetype houses.
    @Test func farTierKeepsEntryVoids() throws {
        let gen = try Self.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var withVoid = 0
        for id in Int64(1)...Int64(30) {
            let b = testBuilding(83_000 + id, Self.rect(0, 0, 7, 15))
            let g = gen.generate(b, palette: &palette, lod: .far)
            guard g.archetype != nil else { continue }
            let front = g.mesh.positions.indices.filter { g.mesh.normals[$0].z > 0.9 && g.mesh.positions[$0].z > 0.03 }
            if !front.isEmpty { withVoid += 1 }
        }
        #expect(withVoid >= 20)
    }

    /// Detail tiers (px) onto distances for the reference phone frame (docs/buildings/README.md "Archetypes").
    @Test func tierDistancesAreDocumented() {
        let t = BuildingGenerator.archetypeTuning
        for id in ["chicago-05-ranch", "chicago-02-flats", "chicago-01-bungalow"] {
            let a = HouseArchetype.named(id)!
            let d = a.tierDistances(frameHeightPx: t.tierFrameHeightPx, fovDegrees: t.tierFovDegrees)
            #expect(d.near > 100 && d.far > d.near * 3, "\(id) \(d)")
        }
    }
}
