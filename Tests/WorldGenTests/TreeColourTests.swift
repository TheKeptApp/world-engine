import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Tree species colours and regions (vegetation.json, from vegetation-v1): exact pack colours, region
/// mapping per profile, crown colour families per form, autumn per species, OSM genus tags.
@Suite("Tree colours")
struct TreeColourTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static var library: VegetationLibrary { VegetationLibrary.bundled }

    static func palette(profile: String, season: Int) throws -> Palette {
        let seasonal = library.applying(to: try StyleLibrary.seasonalPalette(), profileID: profile)
        return Palette(seasonal: seasonal, season: season, base: try StyleLibrary.baseColors())
    }

    /// The slots a crown form's trees pick from.
    static func slots(_ kind: PropKind, _ palette: Palette) -> [Int] {
        let paint = PropLibrary.crownPaint(kind, palette: palette)
        let count = paint.flags.contains(.variant4) ? 4 : paint.flags.contains(.variant2) ? 2 : 1
        return (0..<count).map { paint.slot + $0 }
    }

    /// Every species colour is the pack's neutral crown albedo for that season (peak-fall as autumn),
    /// bare winter crowns the family's branch body colour.
    @Test func speciesColoursAreThePacks() throws {
        let url = Self.root.appendingPathComponent("docs/proposals/vegetation-v1/vegetation-colours.json")
        guard let data = try? Data(contentsOf: url) else { return }
        let pack = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let trees = try #require(pack["trees"] as? [[String: Any]])
        #expect(!Self.library.species.isEmpty)
        for (id, species) in Self.library.species {
            let tree = try #require(trees.first { $0["id"] as? String == id }, "\(id) not in the pack")
            let seasons = try #require(tree["seasons"] as? [String: [String: Any]])
            for (k, key) in ["spring", "summer", "peak-fall", "winter"].enumerated() {
                let season = try #require(seasons[key])
                let branches = ((season["midday"] as? [String: Any])?["branches"] as? [String: Any])?["body"] as? String
                let expected = (season["neutralCrownAlbedo"] as? String) ?? branches
                #expect(species.colours[k].uppercased() == expected?.uppercased(), "\(id) \(key): \(species.colours[k]) vs \(String(describing: expected))")
            }
        }
    }

    /// Regions per profile; every slot names a known species, and every crown family is deciduous
    /// species with at least one of the family's own form (a family may borrow another form's
    /// colours, e.g. Denver ash in the broad family).
    @Test func regionsMapProfilesAndForms() throws {
        let lib = Self.library
        for id in ["evanston", "wilmette", "chicago-dense-north", "default"] { #expect(lib.region(forProfile: id) == lib.regions["chicago"], "\(id)") }
        #expect(lib.region(forProfile: "front-range") == lib.regions["denver"])
        for (name, region) in lib.regions {
            #expect(lib.species[region.bark] != nil, "\(name): bark species")
            for (slot, id) in region.slots {
                #expect(SeasonalPalette.order.contains(slot) && lib.species[VegetationLibrary.speciesID(id)] != nil, "\(name): \(slot) → \(id)")
            }
            for (form, family) in region.crownColors {
                let first = try #require(SeasonalPalette.order.firstIndex(of: family.first))
                var forms: [String] = []
                for key in SeasonalPalette.order[first..<(first + family.count)] {
                    let species = try #require(region.slots[key].flatMap { lib.species[VegetationLibrary.speciesID($0)] }, "\(name) \(form): \(key) unset")
                    #expect(species.form != "conifer", "\(name) \(form): \(key) is a conifer")
                    forms.append(species.form)
                }
                #expect(forms.contains(form), "\(name) \(form): family forms \(forms)")
            }
            #expect(region.slots["conifer1"].flatMap { lib.species[$0]?.form } == "conifer")
        }
    }

    /// The seasonal palette's defaults are the chicago region (so tools without a profile agree).
    @Test func paletteDefaultsAreChicago() throws {
        let seasonal = try StyleLibrary.seasonalPalette()
        let chicago = try #require(Self.library.regions["chicago"])
        #expect(Self.library.applying(to: seasonal, profileID: "evanston").surfaces == seasonal.surfaces)
        #expect(seasonal.crownColors == chicago.crownColors)
    }

    /// Autumn reads as autumn per species: Chicago maples orange-red, lindens yellow, the spreading
    /// family oak russet / elm and honey locust yellow; Denver cottonwood gold. No crown slot of a
    /// deciduous form is green, olive or grey at peak colour.
    @Test(arguments: ["evanston", "front-range"])
    func autumnReadsPerSpecies(_ profile: String) throws {
        let p = try Self.palette(profile: profile, season: 2)
        let region = try #require(Self.library.region(forProfile: profile))
        for (kind, form) in [(PropKind.treeBroad, "broad"), (.treeOval, "oval"), (.treeSpreading, "spreading")] {
            for s in Self.slots(kind, p) {
                let c = p.colors[s]
                let key = SeasonalPalette.order[s]
                print("AUTUMNSLOT \(profile) \(form) \(key) \(region.slots[key] ?? "?") \(Palette.hex(c))")
                // Denver keeps later-turning (still green) slots on purpose (owner 2026-10-07).
                if profile != "front-range" {
                    #expect(c.x > c.y + 0.03 && c.x > c.z + 0.15, "\(profile) \(form): \(key) \(Palette.hex(c)) is not an autumn colour")
                }
            }
        }
        if profile == "front-range" {
            // A Denver street mixes orange/russet, gold and still-green crowns (Sloan's Lake read as one
            // lemon yellow with the pack's Denver list alone).
            let all = [PropKind.treeBroad, .treeOval, .treeSpreading].flatMap { Self.slots($0, p) }.map { p.colors[$0] }
            let orange = all.filter { $0.x > $0.y + 0.15 }.count
            let gold = all.filter { $0.x > $0.y + 0.03 && $0.x <= $0.y + 0.15 }.count
            let green = all.filter { $0.y >= $0.x }.count
            #expect(orange >= 2 && gold >= 2 && green >= 1, "Denver autumn: orange \(orange), gold \(gold), green \(green)")
        }
        if profile == "evanston" {
            #expect(Self.slots(.treeBroad, p).map { Palette.hex(p.colors[$0]) } == ["#CE763C"])     // maple
            #expect(Self.slots(.treeOval, p).map { Palette.hex(p.colors[$0]) } == ["#C6B24E"])      // linden
            #expect(Set(Self.slots(.treeSpreading, p).map { Palette.hex(p.colors[$0]) }) == ["#A55835", "#BCAE4D", "#D2B95C"])
        } else {
            // Denver (owner 2026-10-07): cottonwood gold, oak russet, later honey locust and elm.
            #expect(Self.slots(.treeSpreading, p).map { Palette.hex(p.colors[$0]) } == ["#C8AC46", "#A55835", "#ACA556", "#839049"])
        }
        // Every level of every deciduous archetype paints its crown with its form's family.
        for kind in [PropKind.treeBroad, .treeOval, .treeSpreading] {
            let expected = PropLibrary.crownPaint(kind, palette: p)
            for lod in 0..<4 {
                let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: p)
                let crown = (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) == .crown }
                #expect(!crown.isEmpty && crown.allSatisfy { Int(m.paints[$0].x) == expected.slot && Int(m.paints[$0].z) & ~512 == Int(expected.flags.rawValue) },
                        "\(kind) lod \(lod): crown paint is not its form's family")
            }
        }
    }

    /// Spruce stays green all year; deciduous winter slots are bare-branch colour, never grey foliage.
    @Test func evergreenStaysGreenAndWinterIsBare() throws {
        let p = try Self.palette(profile: "evanston", season: 3)
        let spruce = p.colors[p.named("conifer1")]
        #expect(spruce.y > spruce.x && spruce.y > spruce.z)
        let bark = p.colors[p.named("bark")]
        for k in 1...8 { #expect(p.colors[p.named("deciduous\(k)")] == bark, "deciduous\(k) winter") }
    }

    /// Trunks and branches are bark, plain: the bark slot (the region's branch neutral, never a golden-hour
    /// swatch), shade ≤ 1, no emissive or colour-variant flag, and a grey-brown base colour (hue 20–45°,
    /// HSV saturation below 0.3) in every season and region ("orange trunks" are lighting, not albedo).
    @Test(arguments: ["evanston", "chicago-dense-north", "front-range"])
    func trunksAreGreyBrownBark(_ profile: String) throws {
        for season in 0..<4 {
            let p = try Self.palette(profile: profile, season: season)
            let bark = p.named("bark")
            let c = p.colors[bark]
            let hi = c.max(), lo = c.min()
            let hue: Float = hi == lo ? 0 : 60 * (hi == c.x ? (c.y - c.z) / (hi - lo) : hi == c.y ? 2 + (c.z - c.x) / (hi - lo) : 4 + (c.x - c.y) / (hi - lo))
            let saturation = hi > 0 ? (hi - lo) / hi : 0
            #expect(hue >= 20 && hue <= 45 && saturation < 0.3, "\(profile) season \(season): bark \(Palette.hex(c)) hue \(hue) saturation \(saturation)")
            for kind in PropKind.allCases where kind.isTree {
                for lod in 0..<PropLibrary.lodCount(kind) {
                    let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: p)
                    let wood = (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) != .crown && !(kind == .conifer && m.paints[$0].w > 0) }
                    #expect(!wood.isEmpty || (kind == .conifer && lod == 3), "\(kind) lod \(lod): no trunk")
                    for v in wood {
                        let paint = m.paints[v]
                        #expect(Int(paint.x) == bark && paint.y <= 1 && paint.z == 0, "\(profile) \(kind) lod \(lod): trunk paint \(paint)")
                    }
                }
            }
        }
    }

    /// OSM genus/species tags pick the crown form and win over the profile's weights.
    @Test func genusTagsPickTheForm() throws {
        let lib = Self.library
        #expect(lib.form(tags: ["genus": "Acer"]) == "broad")
        #expect(lib.form(tags: ["species": "Quercus rubra"]) == "spreading")
        #expect(lib.form(tags: ["species": "Populus tremuloides"]) == "oval")
        #expect(lib.form(tags: ["taxon": "Picea pungens"]) == "conifer")
        #expect(lib.form(tags: ["leaf_type": "broadleaved"]) == nil)
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 42.04, longitude: -87.69)), bounds: Rect2D(centerWidth: 400, height: 400))
        let tagged: [(String, String, PropKind)] = [("genus", "Tilia", .treeOval), ("genus", "Acer", .treeBroad),
                                                    ("species", "Gleditsia triacanthos", .treeSpreading), ("genus", "Picea", .conifer)]
        for (i, t) in tagged.enumerated() {
            for j in 0..<10 {
                f.points.append(PointFeature(ref: OSMRef(.node, Int64(1000 + i * 10 + j)), kind: .tree,
                                             position: LocalPoint(Double(j) * 12 - 60, Double(i) * 12 - 24), tags: [t.0: t.1]))
            }
        }
        let gen = SceneGenerator(features: f, profile: try StyleLibrary.profile(id: "evanston"), seasonal: try StyleLibrary.seasonalPalette(),
                                 baseColors: try StyleLibrary.baseColors(), season: 2, focus: f.bounds)
        let scene = gen.generate()
        for (i, t) in tagged.enumerated() {
            let ids = Set((0..<10).map { OSMRef(.node, Int64(1000 + i * 10 + $0)).description })
            let kinds = Set(scene.instances.filter { ids.contains($0.source) }.map(\.kind))
            #expect(kinds == [t.2], "\(t.1): \(kinds)")
        }
    }

    /// A Denver scene's palette carries the Denver families (the scene dresses its profile's region).
    @Test func sceneDressesItsRegion() throws {
        let f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)), bounds: Rect2D(centerWidth: 200, height: 200))
        let gen = SceneGenerator(features: f, profile: try StyleLibrary.profile(id: "front-range"), seasonal: try StyleLibrary.seasonalPalette(),
                                 baseColors: try StyleLibrary.baseColors(), season: 2, focus: f.bounds)
        let p = gen.generate().palette
        #expect(Palette.hex(p.colors[p.named("deciduous5")]) == "#C8AC46")
        #expect(Palette.hex(p.colors[p.named("conifer1")]) == "#678B83")
    }
}
