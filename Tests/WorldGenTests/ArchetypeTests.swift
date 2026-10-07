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
    @Test(arguments: ["chicago", "denver"])
    func everyMetroArchetypeHasAHouseType(_ metro: String) throws {
        let types = try Self.rawTypes(Self.metroProfiles[metro]!)
        let ids = HouseArchetype.bundled.keys.filter { $0.hasPrefix(metro + "-") }
        #expect(!ids.isEmpty)
        for id in ids { #expect(types.contains { $0.archetype == id }, "\(id) has no house type") }
    }

    /// The profile JSON copies (read by review tools) equal the values the engine reads by key.
    @Test(arguments: ["chicago-dense-north", "front-range"])
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
        let gen = try Self.generator("front-range")
        let out = gen.expandWeights(["@archetypes": 90, "cottage": 10]) { _ in true }
        #expect(abs(out.reduce(0) { $0 + $1.1 } - 100) < 1e-9)
        let w = Dictionary(out.map { ($0.0.id, $0.1) }, uniquingKeysWith: +)
        #expect(w["duplex"] == nil, "duplex has archetypeShare 0")
        let pct = { (id: String) in try #require(HouseArchetype.named(gen.profile.houseType(id)?.archetype)).weightPct }
        #expect(abs(w["bungalow"]! / w["ranch"]! - (try pct("bungalow")) / (try pct("ranch"))) < 1e-9)
        // Measured floor-group totals stay (Chicago unknown).
        let chi = try Self.generator("chicago-dense-north")
        let rules = try #require(chi.profile.typeRules["unknown"])
        let ex = chi.expandWeights(rules) { _ in true }
        let one = ex.filter { $0.0.archetype != nil && $0.0.floors.first == 1 }.reduce(0) { $0 + $1.1 }
        #expect(abs(one - rules["@archetypes:1"]!) < 1e-9)
    }

    @Test(arguments: ["chicago-dense-north", "front-range"])
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

    /// Split-level (denver-05-split): two-storey block plus one-storey wing on exactly the mapped footprint.
    @Test func splitLevelHasTwoHeights() throws {
        let gen = try Self.generator("front-range")
        var palette = Palette(base: try StyleLibrary.baseColors())
        let split = try #require(gen.profile.houseTypes.first { $0.archetype == "denver-05-split" })
        let a = try #require(HouseArchetype.named("denver-05-split"))
        var made = 0
        for id in Int64(1)...Int64(10) {
            let b = testBuilding(82_000 + id, Self.rect(0, 0, 14, 10))
            let shape = FootprintAnalysis(b.footprint)
            let choice = HouseChoice(type: split, situation: "test", archetype: a.id, confidence: 0.2, evidence: ["footprint"])
            guard let g = gen.splitLevel(b, shape: shape, archetype: a, choice: choice, palette: &palette, lod: .near) else { continue }
            made += 1
            #expect(g.splitLevel && g.archetype == "denver-05-split" && g.floors == 2)
            #expect(abs(g.eaveHeight - a.parts[0].eaveHeight) < 0.01, "main eave \(g.eaveHeight)")
            #expect(g.entry != nil)
            let xs = g.mesh.positions.map { Double($0.x) }, zs = g.mesh.positions.map { Double(-$0.z) }
            #expect(xs.min()! > -1.5 && xs.max()! < 15.5 && zs.min()! > -2.5 && zs.max()! < 11.5)
            // Wall tops at both eave heights.
            let ys = Set(g.mesh.positions.indices.filter { abs(g.mesh.normals[$0].y) < 0.1 }.map { (Double(g.mesh.positions[$0].y) * 100).rounded() / 100 })
            #expect(ys.contains { abs($0 - a.parts[1].eaveHeight) < 0.02 }, "wing eave")
        }
        #expect(made == 10)
    }

    /// Far tier keeps porch and entry voids for archetype houses.
    @Test func farTierKeepsEntryVoids() throws {
        let gen = try Self.generator("front-range")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var withVoid = 0
        for id in Int64(1)...Int64(30) {
            let b = testBuilding(83_000 + id, Self.rect(0, 0, 10, 12))
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
        for id in ["chicago-05-ranch", "chicago-02-flats", "denver-01-square"] {
            let a = HouseArchetype.named(id)!
            let d = a.tierDistances(frameHeightPx: t.tierFrameHeightPx, fovDegrees: t.tierFovDegrees)
            #expect(d.near > 100 && d.far > d.near * 3, "\(id) \(d)")
        }
    }

    /// Miami archetypes are data only (no Miami profile or test area): every Miami archetype has a house type whose
    /// mirrored values equal the by-key resolution.
    @Test func miamiArchetypeTypesAreDataOnly() throws {
        struct File: Decodable { var archetypeHouseTypes: [StyleProfile.HouseType] }
        let types = try JSONDecoder().decode(File.self, from: StyleLibrary.data("archetypes-miami")).archetypeHouseTypes
        let ids = HouseArchetype.bundled.keys.filter { $0.hasPrefix("miami-") }
        #expect(ids.count == 5)
        for id in ids { #expect(types.contains { $0.archetype == id }, "\(id)") }
        for t in types {
            let a = try #require(HouseArchetype.named(t.archetype))
            #expect(t == t.resolvingArchetype(a), "\(t.id): mirror differs from the by-key values")
            #expect(t.floors.contains(a.fullFloors), "\(t.id) floors")
        }
        #expect(!(try StyleLibrary.regions().regions.contains { $0.profile.contains("miami") }))
    }
}
