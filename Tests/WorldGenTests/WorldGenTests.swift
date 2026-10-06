import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

private func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
    [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
}

private func way(_ id: Int64, _ kind: HighwayKind, _ line: [LocalPoint], name: String? = nil, width: Double = 6,
                 tags extra: Tags = [:]) -> WayFeature {
    var tags = extra
    tags["highway"] = kind.rawValue
    if let name { tags["name"] = name }
    return WayFeature(ref: OSMRef(.way, id), kind: kind, centerline: line, tags: tags, width: width,
                      sidewalkLeft: .unknown, sidewalkRight: .unknown, isCrossing: false, layer: 0, isBridge: false, isTunnel: false)
}

private func building(_ id: Int64, _ ring: Ring, type: String = "house", tags extra: Tags = [:]) -> Building {
    var tags = extra
    tags["building"] = type
    let ref = OSMRef(.way, id)
    let fp = Polygon2D(outer: ring).cleaned()!
    return Building(ref: ref, footprint: fp, tags: tags, type: type, isPart: false,
                    height: HeightRules().resolve(tags: tags, type: type, ref: ref))
}

/// Every triangle's winding agrees with its vertex normals (no inside-out faces).
private func windingConsistent(_ m: MeshBuffers) -> Bool {
    for t in 0..<m.triangleCount {
        let face = m.faceCross(t)
        guard simd_length(face) > 1e-7 else { continue }
        let n = m.normals[Int(m.indices[t * 3])] + m.normals[Int(m.indices[t * 3 + 1])] + m.normals[Int(m.indices[t * 3 + 2])]
        if simd_dot(simd_normalize(face), simd_normalize(n)) <= 0 { return false }
    }
    return true
}

@Suite("Style profiles")
struct ProfileTests {
    @Test func profilesLoadAndRegionSelectsByLocation() throws {
        let regions = try StyleLibrary.regions()
        #expect(regions.profileID(at: GeoCoordinate(latitude: 39.7494, longitude: -105.0445)) == "front-range")
        #expect(regions.profileID(at: GeoCoordinate(latitude: 40.7128, longitude: -74.0060)) == "default")
        let fr = try StyleLibrary.profile(id: "front-range")
        let def = try StyleLibrary.profile(id: "default")
        #expect(fr.trees.deciduousShare == 0.90)
        #expect(def.id == "default")
        #expect(try StyleLibrary.baseColors()["windowDay"] != nil)
        #expect(try StyleLibrary.seasonalPalette().surfaces["lawn"]?.count == 4)
    }

    @Test func paletteDeduplicatesColors() throws {
        var p = Palette(base: ["a": "#112233", "b": "#112233"])
        #expect(p.named("a") == p.named("b"))
        let s = p.slot(hex: "#abcdef")
        #expect(p.slot(hex: "#ABCDEF") == s)
        #expect(Palette.parse("#FF0080") == SIMD3<Float>(1, 0, 128.0 / 255))
    }
}

@Suite("Footprint analysis")
struct FootprintTests {
    @Test func rectangle() {
        let a = FootprintAnalysis(Polygon2D(outer: rect(0, 0, 12, 8)))
        #expect(a.kind == .rectangle)
        #expect(abs(a.obb.halfLength - 6) < 1e-6 && abs(a.obb.halfWidth - 4) < 1e-6)
        #expect(abs(abs(a.obb.u.x) - 1) < 1e-6) // long axis east-west
    }

    @Test func rotatedRectangleFindsItsAxis() {
        let ang = 0.5
        let u = LocalPoint(cos(ang), sin(ang)), v = LocalPoint(-sin(ang), cos(ang))
        let ring = [LocalPoint.zero, u * 14, u * 14 + v * 9, v * 9]
        let a = FootprintAnalysis(Polygon2D(outer: ring))
        #expect(a.kind == .rectangle)
        #expect(abs(abs(simd_dot(a.obb.u, u)) - 1) < 1e-6)
        #expect(abs(a.rectangularity - 1) < 1e-6)
    }

    @Test func lShapeSplitsIntoTwoRoofs() {
        let l = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(14, 0), LocalPoint(14, 6), LocalPoint(6, 6), LocalPoint(6, 12), LocalPoint(0, 12)])
        let a = FootprintAnalysis(l)
        #expect(a.kind == .orthogonal)
        #expect(a.roofRects.count == 2)
        let covered = a.roofRects.reduce(0) { $0 + $1.area } + a.flatRects.reduce(0) { $0 + $1.area }
        #expect(abs(covered - l.area) < 1e-6)
    }

    @Test func notchedRectangle() {
        // 12 × 9 with a 2 × 1.5 notch at a corner (rectangularity 0.97 → still one roof).
        let small = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 1.5), LocalPoint(12, 1.5),
                                      LocalPoint(12, 9), LocalPoint(0, 9)])
        #expect(FootprintAnalysis(small).kind == .rectangle)
        // A deep notch (4 × 4 out of 12 × 9) becomes an orthogonal split.
        let deep = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(8, 0), LocalPoint(8, 4), LocalPoint(12, 4),
                                     LocalPoint(12, 9), LocalPoint(0, 9)])
        let a = FootprintAnalysis(deep)
        #expect(a.kind == .orthogonal)
        #expect(a.roofRects.count >= 2)
    }

    @Test func tinyAndIrregular() {
        #expect(FootprintAnalysis(Polygon2D(outer: rect(0, 0, 3, 3))).kind == .tiny)
        // A 7-sided blob: not rectangular, not orthogonal.
        let blob = Polygon2D(outer: (0..<7).map { k in
            let a = Double(k) / 7 * 2 * .pi
            return LocalPoint(cos(a) * 9, sin(a) * 6)
        })
        #expect(FootprintAnalysis(blob).kind == .irregular)
    }
}

@Suite("Building generation")
struct BuildingGenerationTests {
    /// A street to the south (named) and an alley to the north of a lot.
    static func context() -> StreetContext {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)),
                            bounds: Rect2D(centerWidth: 400, height: 400))
        f.roads = [
            way(1, .residential, [LocalPoint(-100, -10), LocalPoint(100, -10)], name: "Test Street"),
            way(2, .service, [LocalPoint(-100, 40), LocalPoint(100, 40)], width: 4, tags: ["service": "alley"]),
        ]
        return StreetContext(f)
    }

    static func generator() throws -> BuildingGenerator {
        BuildingGenerator(profile: try StyleLibrary.profile(id: "front-range"), context: context())
    }

    @Test func frontDoorFacesTheNamedStreetNotTheAlley() throws {
        var palette = Palette(base: try StyleLibrary.baseColors())
        let house = building(10, rect(-5, 0, 5, 12))
        let g = try Self.generator().generate(house, palette: &palette, detail: .full)
        let e = try #require(g.frontEdge)
        let ring = house.footprint.outer
        let mid = (ring[e] + ring[(e + 1) % ring.count]) / 2
        #expect(abs(mid.y - 0) < 1e-6) // the south edge, toward Test Street
        #expect(windingConsistent(g.mesh))
    }

    @Test func detachedGarageDoorFacesTheAlley() throws {
        var palette = Palette(base: try StyleLibrary.baseColors())
        let garage = building(11, rect(-3, 30, 3, 36), type: "garage")
        let g = try Self.generator().generate(garage, palette: &palette, detail: .full)
        #expect(g.garageDoorFacesAlley)
        let e = try #require(g.garageDoorEdge)
        let ring = garage.footprint.outer
        let mid = (ring[e] + ring[(e + 1) % ring.count]) / 2
        #expect(abs(mid.y - 36) < 1e-6) // the north edge, toward the alley at y = 40
        #expect(windingConsistent(g.mesh))
    }

    @Test func sameIDSameHouseDifferentIDDifferentHouse() throws {
        var p1 = Palette(base: try StyleLibrary.baseColors()), p2 = p1, p3 = p1
        let gen = try Self.generator()
        let a = gen.generate(building(20, rect(-5, 0, 5, 12)), palette: &p1, detail: .full)
        let b = gen.generate(building(20, rect(-5, 0, 5, 12)), palette: &p2, detail: .full)
        #expect(a.mesh == b.mesh)
        let others = (21...30).map { gen.generate(building(Int64($0), rect(-5, 0, 5, 12)), palette: &p3, detail: .full).mesh }
        #expect(Set(others.map(\.positions.count)).count > 1 || Set(others.map { $0.paints.first }).count > 1)
    }

    @Test(arguments: ["gabled", "hipped", "flat"])
    func osmRoofShapeOverridesProfile(_ shape: String) throws {
        var palette = Palette(base: try StyleLibrary.baseColors())
        let b = building(40, rect(-5, 0, 5, 12), tags: ["roof:shape": shape])
        let g = try Self.generator().generate(b, palette: &palette, detail: .full)
        #expect(g.roofShape.rawValue == shape)
        #expect(windingConsistent(g.mesh))
    }

    @Test func levelsSetWallHeight() throws {
        var palette = Palette(base: try StyleLibrary.baseColors())
        let b = building(41, rect(-5, 0, 5, 12), tags: ["building:levels": "2"])
        let g = try Self.generator().generate(b, palette: &palette, detail: .full)
        // Two floors of the chosen house type (2.6–3.3 m each) plus a foundation up to 0.9 m.
        #expect(g.eaveHeight > 2 * 2.6 && g.eaveHeight < 2 * 3.3 + 0.9)
        #expect(g.roofShape == .flat || g.topHeight > g.eaveHeight)
    }

    static let oddFootprints: [(String, Ring)] = {
        let l: Ring = [LocalPoint(0, 0), LocalPoint(14, 0), LocalPoint(14, 6), LocalPoint(6, 6), LocalPoint(6, 12), LocalPoint(0, 12)]
        let blob: Ring = (0..<9).map { (k: Int) -> LocalPoint in
            let a = Double(k) / 9 * 2 * Double.pi
            return LocalPoint(cos(a) * 9, sin(a) * 7)
        }
        return [("L-shape", l), ("tiny", rect(0, 0, 2.5, 3)), ("large", rect(0, 0, 30, 20)), ("blob", blob)]
    }()

    @Test(arguments: oddFootprints)
    func irregularFootprintsProduceCleanMeshes(_ name: String, _ ring: Ring) throws {
        var palette = Palette(base: try StyleLibrary.baseColors())
        let g = try Self.generator().generate(building(50, ring.map { $0 + LocalPoint(-5, 0) }), palette: &palette, detail: .full)
        #expect(!g.mesh.isEmpty, "\(name)")
        #expect(windingConsistent(g.mesh), "\(name)")
        #expect(g.mesh.positions.allSatisfy { !$0.x.isNaN && !$0.y.isNaN && !$0.z.isNaN }, "\(name)")
    }
}

@Suite("Streetscape")
struct StreetscapeTests {
    @Test func sidewalkOnlyWhereNoneIsMappedWithin15m() throws {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)),
                            bounds: Rect2D(centerWidth: 400, height: 400))
        let street = way(1, .residential, [LocalPoint(-100, 0), LocalPoint(100, 0)], name: "Test Street")
        f.roads = [street]
        // A mapped sidewalk 6 m north of the street, parallel.
        f.sidewalks = [way(2, .footway, [LocalPoint(-100, 6), LocalPoint(100, 6)], width: 1.6, tags: ["footway": "sidewalk"])]
        let s = Streetscape(context: StreetContext(f), buildings: PolygonIndex([]))
        let gen = s.generatedSidewalks(roadIndex: 0, piece: street.centerline)
        #expect(gen.count == 1)
        #expect(try #require(gen.first).allSatisfy { $0.y < 0 }) // only the south side
    }

    @Test func taggedNoneOrSeparateGetsNoSidewalk() {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)),
                            bounds: Rect2D(centerWidth: 400, height: 400))
        var street = way(1, .residential, [LocalPoint(-100, 0), LocalPoint(100, 0)], name: "Test Street")
        street.sidewalkLeft = .none
        street.sidewalkRight = .separate
        f.roads = [street]
        let s = Streetscape(context: StreetContext(f), buildings: PolygonIndex([]))
        #expect(s.generatedSidewalks(roadIndex: 0, piece: street.centerline).isEmpty)
    }

    @Test func lampsAreSpacedAndAvoidBuildingsAndMappedLamps() {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)),
                            bounds: Rect2D(centerWidth: 400, height: 400))
        let street = way(1, .residential, [LocalPoint(-150, 0), LocalPoint(150, 0)], name: "Test Street")
        f.roads = [street]
        let blocker = Polygon2D(outer: rect(-20, 2, 20, 12))
        let s = Streetscape(context: StreetContext(f), buildings: PolygonIndex([blocker]))
        var existing = [LocalPoint(100, 4)]
        let lamps = s.generatedLamps(roadIndex: 0, piece: street.centerline, existing: &existing)
        #expect(lamps.count >= 4)
        for (i, a) in lamps.enumerated() {
            #expect(!blocker.contains(a.0))
            #expect(simd_distance(a.0, LocalPoint(100, 4)) >= 20)
            for b in lamps[(i + 1)...] { #expect(simd_distance(a.0, b.0) >= 20) }
        }
    }
}

@Suite("Props")
struct PropTests {
    @Test(arguments: PropKind.allCases)
    func propMeshesAreWellFormed(_ kind: PropKind) throws {
        let palette = Palette(base: try StyleLibrary.baseColors())
        for v in 0..<PropLibrary.variants[kind]! { for lod in 0..<PropLibrary.lodCount(kind) {
            let m = PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette)
            #expect(!m.isEmpty)
            #expect(m.paints.count == m.positions.count)
            if kind != .tuft { #expect(windingConsistent(m), "\(kind) \(v) \(lod)") }
        } }
    }
}

@Suite("Prop budgets")
struct PropBudgetTests {
    @Test func printTriangleCounts() throws {
        let palette = Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 2, base: try StyleLibrary.baseColors())
        var line = "PROPTRIS"
        for kind in PropKind.allCases {
            for v in 0..<(PropLibrary.variants[kind] ?? 1) { for lod in 0..<PropLibrary.lodCount(kind) {
                line += " \(kind.rawValue)/\(v)/\(lod)=\(PropLibrary.mesh(kind, variant: v, lod: lod, palette: palette).triangleCount)"
            } }
        }
        print(line)
    }
}

@Suite("Scene generation on real data")
struct RealSceneTests {
    static let areaDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/areas/sloans-lake")

    @Test(.enabled(if: FileManager.default.fileExists(atPath: areaDir.appendingPathComponent("manifest.json").path)))
    func generatesTheSloansLakeScene() throws {
        let manifest = try AreaLoader.loadManifest(Self.areaDir)
        let features = try AreaLoader.loadFeatures(Self.areaDir)
        let profile = try StyleLibrary.profile(at: manifest.center)
        #expect(profile.id == "front-range")
        let start = Date()
        let scene = try Self.generator(features: features, profile: profile).generate()
        let seconds = Date().timeIntervalSince(start)
        let tris = scene.chunks.reduce(0) { $0 + $1.staticMesh.triangleCount + $1.waterMesh.triangleCount }
        print("SCENE chunks=\(scene.chunks.count) staticTris=\(tris) instances=\(scene.instances.count) seconds=\(seconds) stats=\(scene.stats)")
        #expect(scene.chunks.count == 48)
        #expect(scene.buildings.count > 1300)
        #expect(scene.chunks.allSatisfy { windingConsistent($0.staticMesh) })
        #expect(scene.stats["generatedLamps"]! > 0)
        // Every house gets a type from the profile's catalog.
        let types = Set(profile.houseTypes.map(\.id))
        #expect(scene.buildings.allSatisfy { $0.houseType == nil || types.contains($0.houseType!) })
    }

    static func generator(features: MapFeatures, profile: StyleProfile) throws -> SceneGenerator {
        SceneGenerator(features: features, profile: profile, seasonal: try StyleLibrary.seasonalPalette(),
                       baseColors: try StyleLibrary.baseColors(), season: 2,
                       focus: Rect2D(min: LocalPoint(90, -260), max: LocalPoint(378, 340)))
    }

    /// Same inputs → byte-identical geometry and identical placements (one decision owner).
    @Test(.enabled(if: FileManager.default.fileExists(atPath: areaDir.appendingPathComponent("manifest.json").path)))
    func generationIsDeterministic() throws {
        let manifest = try AreaLoader.loadManifest(Self.areaDir)
        let features = try AreaLoader.loadFeatures(Self.areaDir)
        let profile = try StyleLibrary.profile(at: manifest.center)
        let a = try Self.generator(features: features, profile: profile).generate()
        let b = try Self.generator(features: features, profile: profile).generate()
        #expect(a.instances == b.instances)
        #expect(a.chunks.count == b.chunks.count)
        for (x, y) in zip(a.chunks, b.chunks) {
            #expect(x.staticMesh.positions == y.staticMesh.positions)
            #expect(x.staticMesh.paints == y.staticMesh.paints)
            #expect(x.staticMesh.extras == y.staticMesh.extras)
            #expect(x.staticFeatures == y.staticFeatures)
        }
        #expect(a.palette.colors == b.palette.colors)
    }
}

@Suite("Light and palette data")
struct LightTests {
    static let sloans = GeoCoordinate(latitude: 39.7494, longitude: -105.0445)

    @Test func goldenAndNoonFixturesResolveToTheirKeys() throws {
        let tables = try StyleLibrary.lighting()
        let iso = ISO8601DateFormatter()
        let golden = LightingModel.state(at: iso.date(from: "2026-10-15T23:44:01Z")!, location: Self.sloans, tables: tables)
        #expect(abs(golden.sunElevation - 6.0011) < 0.05)
        #expect(abs(golden.sunAzimuth - 253.2843) < 0.05)
        // Keys blend chronologically (weather v1 §5): at the golden crossing the state is the golden
        // key, reached as the end of noon→golden or the start of golden→dusk.
        func at(_ s: LightingState, _ key: String) -> Bool { (s.keyA == key && s.blend < 0.01) || (s.keyB == key && s.blend > 0.99) }
        #expect(at(golden, "golden"))
        #expect(abs(golden.exposure - 1.45) < 0.01)
        let noon = LightingModel.state(at: iso.date(from: "2026-07-15T19:07:00Z")!, location: Self.sloans, tables: tables)
        #expect(abs(noon.sunElevation - 71.6745) < 0.05)
        #expect(at(noon, "noon"))
        #expect(abs(noon.sunIntensity - 1) < 0.01)
        // Night: no direct sun, windows lit.
        let night = LightingModel.state(at: iso.date(from: "2026-10-16T04:00:00Z")!, location: Self.sloans, tables: tables)
        #expect(night.sunIntensity == 0 && night.litWindows > 0.2)
    }

    @Test func fogPolicyLeavesStreetValuesAndOpensAerial() {
        let street = FogPolicy.distances(start: 350, end: 1100, cameraHeight: 1.25)
        #expect(street.start == 350 && street.end == 1100)
        let aerial = FogPolicy.distances(start: 350, end: 1100, cameraHeight: 1474)
        #expect(aerial.start > 900 && aerial.end > 2500)
    }

    @Test func seasonalSlotsComeFirstInFixedOrder() throws {
        let seasonal = try StyleLibrary.seasonalPalette()
        let base = try StyleLibrary.baseColors()
        let summer = Palette(seasonal: seasonal, season: 1, base: base)
        let autumn = Palette(seasonal: seasonal, season: 2, base: base)
        // Same slot numbers in every season, different colors: renderers can swap one row.
        for name in SeasonalPalette.order { #expect(summer.named(name) == autumn.named(name)) }
        #expect(summer.colors[Int(summer.named("deciduous1"))] != autumn.colors[Int(autumn.named("deciduous1"))])
    }
}
