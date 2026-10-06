import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Every building of the committed test areas, at every LOD: clean geometry, sealed shells on a
/// sample, and the triangle budget (printed as BUDGET lines for docs/perf).
@Suite("Buildings on real data", .serialized)
struct BuildingAreaTests {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static func dir(_ area: String) -> URL { root.appendingPathComponent("Data/areas/\(area)") }
    static func has(_ area: String) -> Bool { FileManager.default.fileExists(atPath: dir(area).appendingPathComponent("manifest.json").path) }

    /// (area, profile): the profile is an explicit test override (spec §2 selection precedence).
    static let areas: [(String, String)] = [("evanston-south", "evanston"), ("lakeview-sheil-park", "chicago-dense-north"), ("sloans-lake", "front-range"),
                                            ("wilmette-vattmann-park", "wilmette")]

    /// Average triangles per house (near, mid, far, skyline) before the facade pass.
    static let houseBaseline: [String: [Double]] = [
        "evanston-south": [401, 142, 45, 11], "lakeview-sheil-park": [511, 167, 53, 14], "sloans-lake": [429, 191, 91, 19],
    ]

    struct Tally {
        var count = 0
        var tris: [BuildingLOD: Int] = [:]
        var maxNear = 0
    }

    @Test(arguments: areas)
    func everyBuildingIsCleanAndWithinBudget(_ area: String, _ profileID: String) throws {
        guard Self.has(area) else { return }
        let features = try AreaLoader.loadFeatures(Self.dir(area))
        let profile = try StyleLibrary.profile(id: profileID)
        var gen = BuildingGenerator(profile: profile, context: StreetContext(features))
        gen.obstacles = PolygonIndex(features.buildings.map(\.footprint))
        var palette = Palette(base: try StyleLibrary.baseColors())
        var byRole: [String: Tally] = [:]
        var byFamily: [String: Tally] = [:]
        var fallbacks = 0, crossGables = 0, dormers = 0, chimneys = 0, porches = 0, optional = 0, nearHouses = 0
        var inferredBays = 0, mappedBays = 0, kits: [String: Int] = [:]
        var bad: [String] = []
        var seconds: [BuildingLOD: Double] = [:]
        let buildings = features.buildings.filter { !$0.isPart }
        for (i, b) in buildings.enumerated() {
            var meshes: [BuildingLOD: GeneratedBuilding] = [:]
            for lod in BuildingLOD.allCases {
                let t0 = Date()
                meshes[lod] = gen.generate(b, palette: &palette, lod: lod)
                seconds[lod, default: 0] += Date().timeIntervalSince(t0)
            }
            let g = meshes[.near]!
            let role = g.role.rawValue, fam = g.family ?? role
            for lod in BuildingLOD.allCases {
                let m = meshes[lod]!.mesh
                byRole[role, default: Tally()].tris[lod, default: 0] += m.triangleCount
                byFamily[fam, default: Tally()].tris[lod, default: 0] += m.triangleCount
                let w = GeometryCheck.windingErrors(m)
                if !w.isEmpty || !GeometryCheck.finite(m) { bad.append("\(b.ref) \(lod) \(fam) \(g.footprintClass) inverted=\(w.count)") }
            }
            byRole[role, default: Tally()].count += 1
            byFamily[fam, default: Tally()].count += 1
            byRole[role]!.maxNear = max(byRole[role]!.maxNear, g.mesh.triangleCount)
            if g.roofFallback != nil { fallbacks += 1 }
            if g.crossGable { crossGables += 1 }
            dormers += g.dormers
            if g.hasChimney { chimneys += 1 }
            if g.hasRearPorch { porches += 1 }
            inferredBays += g.inferredBays.count
            mappedBays += g.mappedBays
            if let k = g.entryKit { kits[k, default: 0] += 1 }
            if g.role == .house { optional += g.optionalRoofTriangles; nearHouses += 1 }
            #expect(g.optionalRoofTriangles <= BuildingGenerator.optionalRoofCap)
            // Sealing on a deterministic sample (ray casting is slow).
            if i % 25 == 0, g.role == .house || g.role == .block {
                for lod in [BuildingLOD.near, .far] {
                    let leaks = GeometryCheck.leaks(meshes[lod]!, footprint: b.footprint, samples: 4, seed: UInt64(i))
                    if !leaks.isEmpty { bad.append("\(b.ref) \(lod) \(fam) \(g.footprintClass) leaks=\(leaks.count)") }
                }
            }
        }
        let km2 = features.bounds.width * features.bounds.height / 1e6
        func line(_ name: String, _ t: Tally) -> String {
            let per = BuildingLOD.allCases.map { "\($0)=\(t.count > 0 ? t.tris[$0, default: 0] / t.count : 0)" }.joined(separator: " ")
            return "BUDGET \(area) \(name) n=\(t.count) perBuilding[\(per)]"
        }
        for (k, t) in byRole.sorted(by: { $0.key < $1.key }) { print(line("role:" + k, t) + " maxNear=\(t.maxNear)") }
        for (k, t) in byFamily.sorted(by: { $0.key < $1.key }) { print(line("family:" + k, t)) }
        var total: [BuildingLOD: Int] = [:]
        for t in byRole.values { for (l, n) in t.tris { total[l, default: 0] += n } }
        let perKm2 = BuildingLOD.allCases.map { "\($0)=\(Int(Double(total[$0, default: 0]) / km2))" }.joined(separator: " ")
        let time = BuildingLOD.allCases.map { "\($0)=\(String(format: "%.2f", seconds[$0, default: 0] / km2))s" }.joined(separator: " ")
        print("BUDGET \(area) buildings=\(buildings.count) km2=\(String(format: "%.2f", km2)) trisPerKm2[\(perKm2)] genSecondsPerKm2[\(time)]")
        print("BUDGET \(area) fallbacks=\(fallbacks) crossGables=\(crossGables) dormers=\(dormers) chimneys=\(chimneys) rearPorches=\(porches) optionalRoofTrisPerHouse=\(nearHouses > 0 ? optional / nearHouses : 0)")
        print("BUDGET \(area) inferredBays=\(inferredBays) mappedBays=\(mappedBays) entryKits=\(kits.sorted { $0.key < $1.key })")
        for s in bad.prefix(40) { print("BAD \(area) \(s)") }
        // Budget (v2 §8.1, regions §4): optional roof detail stays far below its 12k visible cap,
        // and each LOD step at least halves the per-km² load.
        #expect(nearHouses == 0 || optional / nearHouses <= 60)
        #expect(Double(total[.mid, default: 0]) <= 0.5 * Double(total[.near, default: 0]))
        #expect(Double(total[.far, default: 0]) <= 0.6 * Double(total[.mid, default: 0]))
        #expect(Double(total[.far, default: 0]) / km2 <= 200_000)
        #expect(Double(total[.skyline, default: 0]) / km2 <= 60_000)
        for (k, t) in byRole where k == "house" { #expect(t.maxNear <= 2500, "largest house \(t.maxNear) triangles") }
        // Facade pass budget against the measurements before it (gate-5b.md): average house near
        // at most +45 %, mid at most +25 %, far and skyline unchanged.
        if let base = Self.houseBaseline[area], let t = byRole["house"], t.count > 0 {
            func avg(_ l: BuildingLOD) -> Double { Double(t.tris[l, default: 0]) / Double(t.count) }
            #expect(avg(.near) <= base[0] * 1.45, "near \(avg(.near)) vs \(base[0])")
            #expect(avg(.mid) <= base[1] * 1.25, "mid \(avg(.mid)) vs \(base[1])")
            #expect(avg(.far) < base[2] + 1 && avg(.skyline) < base[3] + 1, "far \(avg(.far)) skyline \(avg(.skyline))")
        }
        #expect(bad.isEmpty, "\(area): \(bad.count) problems, first: \(bad.first ?? "")")
    }
}

/// Triangles in view from fixed cameras with per-building LOD by distance (v2 §8.1: ≤400k main
/// triangles in total; buildings get ≤170k, the share spec §5.5 allocates to buildings/roofs).
@Suite("Building view budget")
struct BuildingViewBudgetTests {
    struct Camera { var name: String; var area: String; var profile: String; var lat: Double; var lon: Double; var heading: Double; var aerial: Bool }
    static let cameras = [
        Camera(name: "lakeview-street", area: "lakeview-sheil-park", profile: "chicago-dense-north", lat: 41.943402, lon: -87.66075, heading: 270, aerial: false),
        Camera(name: "lakeview-alley", area: "lakeview-sheil-park", profile: "chicago-dense-north", lat: 41.944063, lon: -87.666977, heading: 0, aerial: false),
        Camera(name: "lakeview-block-center", area: "lakeview-sheil-park", profile: "chicago-dense-north", lat: 41.94567, lon: -87.66361, heading: 90, aerial: false),
        Camera(name: "evanston-street", area: "evanston-south", profile: "evanston", lat: 42.0382, lon: -87.69135, heading: 180, aerial: false),
        Camera(name: "wilmette-street", area: "wilmette-vattmann-park", profile: "wilmette", lat: 42.074933, lon: -87.719996, heading: 90, aerial: false),
    ]

    @Test(arguments: cameras.map(\.name))
    func viewFitsTheBuildingShare(_ name: String) throws {
        let cam = Self.cameras.first { $0.name == name }!
        guard BuildingAreaTests.has(cam.area) else { return }
        let manifest = try AreaLoader.loadManifest(BuildingAreaTests.dir(cam.area))
        let features = try AreaLoader.loadFeatures(BuildingAreaTests.dir(cam.area))
        var gen = BuildingGenerator(profile: try StyleLibrary.profile(id: cam.profile), context: StreetContext(features))
        gen.obstacles = PolygonIndex(features.buildings.map(\.footprint))
        var palette = Palette(base: try StyleLibrary.baseColors())
        let eye = manifest.frame.localPoint(of: GeoCoordinate(latitude: cam.lat, longitude: cam.lon))
        let h = cam.heading * .pi / 180
        let forward = LocalPoint(sin(h), cos(h))
        // 16:9 at 50° vertical → about 79° horizontal; widen 10° for buildings straddling the edge.
        let halfFOV = (2 * atan(tan(25 * Double.pi / 180) * 16 / 9) / 2) + 10 * .pi / 180
        var byLOD: [BuildingLOD: (n: Int, tris: Int)] = [:]
        var optional = 0
        for b in features.buildings where !b.isPart {
            let c = b.footprint.centroid
            let d = c - eye
            let dist = simd_length(d)
            let r = sqrt(b.footprint.area / .pi)
            guard dist < r + 1 || acos(max(-1, min(1, simd_dot(d / dist, forward)))) <= halfFOV + atan(r / max(dist, 1)) else { continue }
            let lod = BuildingLOD.forDistance(max(0, dist - r))
            let g = gen.generate(b, palette: &palette, lod: lod)
            byLOD[lod, default: (0, 0)].n += 1
            byLOD[lod, default: (0, 0)].tris += g.mesh.triangleCount
            if lod == .near { optional += g.optionalRoofTriangles }
        }
        let total = byLOD.values.reduce(0) { $0 + $1.tris }
        let parts = BuildingLOD.allCases.map { "\($0)=\(byLOD[$0]?.n ?? 0)/\(byLOD[$0]?.tris ?? 0)" }.joined(separator: " ")
        print("VIEW \(name) buildings/tris [\(parts)] total=\(total) nearOptionalRoof=\(optional)")
        #expect(total <= 170_000, "\(name): \(total) building triangles in view")
        #expect(optional <= 12_000)
    }
}
