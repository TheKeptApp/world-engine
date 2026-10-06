import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Yards on the committed areas: lots never cross streets, generated trees and shrubs stay off
/// roads and buildings, output is stable, and the in-view budget holds with trees and shrubs.
@Suite("Yards", .serialized)
struct YardTests {
    static func build(_ area: String, _ profile: String, focus: GeoBoundingBox? = nil) throws -> WorldBuild {
        try WorldBuild.generate(areaDirectory: BuildingAreaTests.dir(area),
                                recipe: WorldRecipe(profileID: profile, date: ISO8601DateFormatter().date(from: "2026-10-22T20:00:00Z")!, focus: focus))
    }

    static let cases: [(String, String)] = [("evanston-south", "evanston"), ("lakeview-sheil-park", "chicago-dense-north")]

    @Test(arguments: cases)
    func lotsStayOffStreetsAndTreesOffRoadsAndBuildings(_ area: String, _ profile: String) throws {
        guard BuildingAreaTests.has(area) else { return }
        let b = try Self.build(area, profile)
        let f = b.features
        #expect(b.scene.lots.count > 300, "\(area): \(b.scene.lots.count) lots")
        // No vehicular road centerline runs through a lot (beyond the 1 m raster tolerance).
        let lotPolys = b.scene.lots.flatMap { $0.outline.map { Polygon2D(outer: $0) } }
        let index = PolygonIndex(lotPolys)
        var crossings = 0
        for r in f.roads where r.kind.isVehicular && !r.isTunnel && !r.isBridge {
            for (p, q) in zip(r.centerline, r.centerline.dropFirst()) {
                let len = simd_distance(p, q)
                var t = 0.0
                while t < len {
                    let x = p + (q - p) * (t / len)
                    if index.contains(x), lotPolys.contains(where: { $0.bounds.contains(x) && $0.contains(x) && GeometryCheck.distanceToBoundary($0, x) > 1.5 }) {
                        crossings += 1
                    }
                    t += 2
                }
            }
        }
        #expect(crossings == 0, "\(area): \(crossings) road samples inside lots")
        // Generated trees and shrubs: not inside buildings, not on carriageways.
        let buildings = PolygonIndex(f.buildings.filter { !$0.isPart }.map(\.footprint))
        let roads = SegmentIndex(f.roads.filter { $0.kind.isVehicular }.map(\.centerline))
        let widths = f.roads.filter { $0.kind.isVehicular }.map(\.width)
        var bad: [String] = []
        for inst in b.scene.instances where inst.source.hasPrefix("gen:yardtree") || inst.source.hasPrefix("gen:streettree")
            || inst.source.hasPrefix("gen:shrub") || inst.source.hasPrefix("gen:hedge") {
            let p = LocalPoint(inst.x, inst.y)
            if buildings.contains(p, margin: inst.kind.isTree ? 1.0 : 0.2) { bad.append("\(inst.source) in building") }
            if let hit = roads.nearest(to: p, within: 12), hit.distance < widths[hit.line] / 2 + 0.3 { bad.append("\(inst.source) on road") }
        }
        #expect(bad.isEmpty, "\(area): \(bad.count) misplaced, first \(bad.prefix(3))")
        let s = b.scene.stats
        print("YARDS \(area) lots=\(b.scene.lots.count) walks=\(s["walks"] ?? 0) driveways=\(s["driveways"] ?? 0) beds=\(s["beds"] ?? 0) shrubs=\(s["shrubs"] ?? 0) hedgeBushes=\(s["hedgeBushes"] ?? 0) yardTrees=\(s["yardTrees"] ?? 0) streetTrees=\(s["streetTrees"] ?? 0) litterHints=\(b.scene.litterHints.count)")
    }

    @Test func sameAreaSameYards() throws {
        guard BuildingAreaTests.has("lakeview-sheil-park") else { return }
        let a = try Self.build("lakeview-sheil-park", "chicago-dense-north"), b = try Self.build("lakeview-sheil-park", "chicago-dense-north")
        #expect(a.scene.lots.count == b.scene.lots.count)
        #expect(zip(a.scene.lots, b.scene.lots).allSatisfy { $0.outline == $1.outline && $0.lawnShade == $1.lawnShade && $0.walk == $1.walk })
        #expect(a.scene.instances == b.scene.instances)
    }

    @Test func zonesPickProfilesPerBuilding() throws {
        guard BuildingAreaTests.has("evanston-south") else { return }
        let manifest = try AreaLoader.loadManifest(BuildingAreaTests.dir("evanston-south"))
        let features = try AreaLoader.loadFeatures(BuildingAreaTests.dir("evanston-south"))
        // A synthetic catalog splitting the area at its centre longitude.
        let c = manifest.center
        let west = RegionCatalog.Region(id: "west", profile: "evanston", bounds: GeoBoundingBox(south: c.latitude - 1, west: c.longitude - 1, north: c.latitude + 1, east: c.longitude))
        let catalog = RegionCatalog(defaultProfile: "chicago-dense-north", regions: [west])
        let zones = ZoneProfiles(catalog: catalog, profiles: ["evanston": try StyleLibrary.profile(id: "evanston"),
                                                              "chicago-dense-north": try StyleLibrary.profile(id: "chicago-dense-north")],
                                 frame: manifest.frame)
        var gen = try WorldBuild.generator(features: features, profile: try StyleLibrary.profile(id: "evanston"), season: 2, focus: features.bounds)
        gen.zones = zones
        let scene = gen.generate()
        let ids = Set(scene.buildings.compactMap(\.profileID))
        #expect(ids == ["evanston", "chicago-dense-north"])
        for (g, b) in zip(scene.buildings, features.buildings.filter { !$0.isPart }) {
            #expect(g.profileID == (b.footprint.centroid.x < 0 ? "evanston" : "chicago-dense-north"))
        }
    }

    /// Triangles in view from the street cameras, now including the yard ground and the generated
    /// trees and shrubs at their render LODs. Buildings + yards + trees must fit the 400k main ceiling
    /// minus the existing scene (roads, mapped props) with margin: ≤ 250k here.
    @Test(arguments: BuildingViewBudgetTests.cameras.map(\.name))
    func viewBudgetWithYards(_ name: String) throws {
        let cam = BuildingViewBudgetTests.cameras.first { $0.name == name }!
        guard BuildingAreaTests.has(cam.area) else { return }
        // As in the app: full street detail in a 400 m box around the camera.
        let d = 200.0 / 111_000, dl = d / cos(cam.lat * .pi / 180)
        let b = try Self.build(cam.area, cam.profile, focus: GeoBoundingBox(south: cam.lat - d, west: cam.lon - dl, north: cam.lat + d, east: cam.lon + dl))
        let eye = b.manifest.frame.localPoint(of: GeoCoordinate(latitude: cam.lat, longitude: cam.lon))
        let h = cam.heading * .pi / 180
        let forward = LocalPoint(sin(h), cos(h))
        let halfFOV = 2 * atan(tan(25 * Double.pi / 180) * 16 / 9) / 2 + 10 * .pi / 180
        func visible(_ p: LocalPoint, _ r: Double) -> Bool {
            let d = p - eye
            let dist = simd_length(d)
            return dist < r + 1 || acos(max(-1, min(1, simd_dot(d / dist, forward)))) <= halfFOV + atan(r / max(dist, 1))
        }
        var propTris: [String: Int] = [:]
        var trees = 0, shrubs = 0, yardGround = 0
        for inst in b.scene.instances where inst.source.hasPrefix("gen:") {
            let p = LocalPoint(inst.x, inst.y)
            guard visible(p, 4) else { continue }
            let dist = simd_distance(p, eye)
            let lod = PropLibrary.lodCount(inst.kind) == 3 ? (dist < PropLibrary.lodDistances[0] ? 0 : dist < PropLibrary.lodDistances[1] ? 1 : 2) : 0
            let key = "\(inst.kind.rawValue)-\(inst.variant)-\(lod)"
            if propTris[key] == nil { propTris[key] = PropLibrary.mesh(inst.kind, variant: inst.variant, lod: lod, palette: b.scene.palette).triangleCount }
            if inst.kind.isTree { trees += propTris[key]! } else { shrubs += propTris[key]! }
        }
        for chunk in b.scene.chunks {
            for fr in chunk.staticFeatures where fr.feature.hasPrefix("gen:lot") || fr.feature.hasPrefix("gen:walk") || fr.feature.hasPrefix("gen:driveway") || fr.feature.hasPrefix("gen:bed") {
                let p = chunk.staticMesh.positions[fr.start]
                if visible(LocalPoint(Double(p.x), Double(-p.z)), 20) { yardGround += fr.count / 3 }
            }
        }
        let lodTris = (0..<3).map { PropLibrary.mesh(.treeBroad, variant: 0, lod: $0, palette: b.scene.palette).triangleCount }
        let bushTris = (0..<3).map { PropLibrary.mesh(.bush, variant: 0, lod: $0, palette: b.scene.palette).triangleCount }
        print("VIEWYARDS \(name) generatedTreeTris=\(trees) shrubTris=\(shrubs) yardGroundTris≈\(yardGround) treeLOD=\(lodTris) bushLOD=\(bushTris)")
        #expect(trees + shrubs + yardGround <= 200_000, "\(name)")
    }
}

@Suite("Relative size thresholds")
struct RelativeThresholdTests {
    @Test func percentilesNeedThirtyHouses() throws {
        let t = try StyleLibrary.profile(id: "evanston").typeThresholds
        let few = (0..<29).map { Double(50 + $0 * 5) }
        #expect(t.resolved(houseAreas: few) == t)
        let many = (0..<200).map { Double(40 + $0) } // 40…239 m²
        let r = t.resolved(houseAreas: many)
        if let q = t.smallAreaPercentile { #expect(abs(r.smallArea - (40 + q * 199)) < 1e-6) }
        if let q = t.largeAreaPercentile { #expect(abs(r.largeArea - (40 + q * 199)) < 1e-6) }
        #expect(r.hugeArea >= r.largeArea)
        #expect(r.broadAspect == t.broadAspect)
    }
}
