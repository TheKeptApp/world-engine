import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh
@testable import WorldPackage

@Suite("GLB")
struct GLBTests {
    @Test func roundTrip() throws {
        let b = GLBBuilder()
        let mat = b.material(name: "worldStatic")
        let pos: [Float] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
        let prim = b.primitive(attributes: ["POSITION": b.floats(pos, components: 3, minMax: true), "_FEATURE": b.uints([0, 1, 70000])],
                               indices: b.indices([0, 1, 2]), material: mat)
        _ = b.node(name: "n", mesh: b.mesh(name: "m", primitives: [prim]), translation: [1, 2, 3])
        let data = try b.encoded()
        #expect(data.count % 4 == 0)
        let f = try GLBFile(data: data)
        let p = f.primitive(mesh: 0, 0)
        #expect(f.floats(p.attributes["POSITION"]!) == pos)
        #expect(f.uints(p.attributes["_FEATURE"]!) == [0, 1, 70000])
        #expect(f.uints(p.indices) == [0, 1, 2])
        #expect(f.materialNames == ["worldStatic"])
        #expect(f.nodes[0]["translation"] as? [Double] == [1, 2, 3])
    }
}

@Suite("Package licence notice (decision 6a)")
struct DataNoticeTests {
    static func source(_ format: String, _ license: String, _ attribution: String, sha: String?) -> AreaManifest.Source {
        .init(format: format, path: "\(format).json", layers: ["buildings"], bounds: GeoBoundingBox(south: 0, west: 0, north: 0.01, east: 0.01),
              dataTimestamp: "2026-10-06T00:00:00Z", fetchedAt: nil, bytes: nil, sha256: sha, license: license, attribution: attribution)
    }

    /// Generic over sources: OSM, an Overture source with its own attribution, a CC BY source and
    /// an unknown licence all appear with licence, attribution and hash.
    @Test func noticeNamesEverySource() throws {
        var manifest = AreaManifest(id: "test-area", name: "Test area", center: GeoCoordinate(latitude: 0, longitude: 0),
                                    widthMeters: 100, heightMeters: 100)
        manifest.sources = [
            Self.source("osm-overpass-json", "ODbL-1.0", "© OpenStreetMap contributors", sha: "aaa111"),
            Self.source("overture-buildings-v1", "ODbL-1.0", "© OpenStreetMap contributors, Overture Maps Foundation", sha: "bbb222"),
            Self.source("cc-by-extra", "CC-BY-4.0", "Esri Community Maps contributors", sha: nil),
            Self.source("odd", "Custom-1", "Someone else", sha: nil),
        ]
        let catalog = try CreditsCatalog.bundled()
        let credits = catalog.merged(sources: manifest.sources, surface: .package)
        let notice = WorldPackage.dataNotice(manifest: manifest, credits: credits, catalog: catalog, generatorVersion: "test")
        #expect(notice.contains("Derivative Database of OpenStreetMap"))
        #expect(notice.contains("https://opendatacommons.org/licenses/odbl/1-0/"))
        #expect(notice.contains("© OpenStreetMap contributors"))
        for s in manifest.sources {
            #expect(notice.contains("**\(s.attribution)**. Licence: \(s.license)"), "\(s.format)")
            #expect(notice.contains("`\(s.format)`"))
        }
        #expect(notice.contains("aaa111") && notice.contains("bbb222"))
        #expect(notice.contains("https://creativecommons.org/licenses/by/4.0/"))
        #expect(notice.contains("Custom-1 (licence URL not on record)"))
        #expect(notice.contains("## How to obtain the data") && notice.contains("## Separately licensed content"))
        for f in WorldPackage.derivativeDatabaseFiles + WorldPackage.separatelyLicensedFiles { #expect(notice.contains("`\(f.pattern)`")) }
        // Every distinct source credit is listed in the credits section too.
        #expect(credits.contains { $0.text == "© OpenStreetMap contributors, Overture Maps Foundation" })
        #expect(credits.contains { $0.text == "Esri Community Maps contributors" })
        // Deterministic.
        #expect(notice == WorldPackage.dataNotice(manifest: manifest, credits: credits, catalog: catalog, generatorVersion: "test"))
    }

    @Test func everyKnownPackagePathIsClassified() {
        #expect(WorldPackage.licenseClass(of: "world.json") == "ODbL-1.0")
        #expect(WorldPackage.licenseClass(of: "chunks/0_1/scene.json") == "ODbL-1.0")
        #expect(WorldPackage.licenseClass(of: "chunks/0_1/lod0.glb") == "ODbL-1.0")
        #expect(WorldPackage.licenseClass(of: "prototypes/tree-0-lod0.glb") == "separate")
        #expect(WorldPackage.licenseClass(of: "profiles/default.json") == "separate")
        #expect(WorldPackage.licenseClass(of: "sky-golden.png") == "separate")
        #expect(WorldPackage.licenseClass(of: "LICENSE-DATA.md") == "notice")
        #expect(WorldPackage.licenseClass(of: "something-new.bin") == nil)
    }
}

@Suite("World package on real data")
struct PackageTests {
    static let areaDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/areas/sloans-lake")
    static let hasData = FileManager.default.fileExists(atPath: areaDir.appendingPathComponent("manifest.json").path)

    static func options(season: Int? = nil) -> WorldPackage.Options {
        let iso = ISO8601DateFormatter()
        let golden = iso.date(from: "2026-10-15T23:44:01Z")!, noon = iso.date(from: "2026-07-15T19:07:00Z")!
        let focus = GeoBoundingBox(south: 39.747058, west: -105.04345, north: 39.752462, east: -105.037966)
        return .init(recipe: WorldRecipe(date: golden, season: season, focus: focus), lightStates: [("golden", golden), ("noon", noon)])
    }

    static func files(_ dir: URL) throws -> [String: Data] {
        var out: [String: Data] = [:]
        let base = dir.resolvingSymlinksInPath().path
        let e = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey])!
        for case let url as URL in e where (try url.resourceValues(forKeys: [.isRegularFileKey])).isRegularFile == true {
            out[String(url.resolvingSymlinksInPath().path.dropFirst(base.count + 1))] = try Data(contentsOf: url)
        }
        return out
    }

    /// Three exports: two identical (determinism) and one in another season (a palette-only edit).
    /// The package must match the generator: same chunks, features, instances, positions ≤ 1 cm.
    @Test(.timeLimit(.minutes(5)))
    func packageIsDeterministicAndMatchesTheGenerator() throws {
        guard hasData else { Issue.record("missing test prerequisite: hasData"); return }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wp-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        let a = tmp.appendingPathComponent("a"), b = tmp.appendingPathComponent("b"), c = tmp.appendingPathComponent("c")
        try WorldPackage.export(areaDirectory: Self.areaDir, to: a, options: Self.options())
        try WorldPackage.export(areaDirectory: Self.areaDir, to: b, options: Self.options())
        try WorldPackage.export(areaDirectory: Self.areaDir, to: c, options: Self.options(season: 1))
        let fa = try Self.files(a), fb = try Self.files(b), fc = try Self.files(c)

        // Determinism: byte-identical packages.
        #expect(fa.keys.sorted() == fb.keys.sorted())
        #expect(fa.allSatisfy { fb[$0.key] == $0.value })

        // A palette change (season) reaches renderers through palettes.json only.
        let geometry = fa.keys.filter { $0.hasSuffix(".glb") || $0 == "instances.json" || $0 == "clutter-tufts.bin" || $0.hasSuffix("scene.json") }
        #expect(geometry.allSatisfy { fc[$0] == fa[$0] })
        #expect(fc["palettes.json"] != fa["palettes.json"])

        // Against the generator.
        let build = try WorldBuild.generate(areaDirectory: Self.areaDir, recipe: Self.options().recipe)
        let world = try JSONSerialization.jsonObject(with: fa["world.json"]!) as! [String: Any]
        let chunks = world["chunks"] as! [[String: Any]]
        #expect(chunks.count == build.scene.chunks.count)
        var worstError: Float = 0
        for (entry, chunk) in zip(chunks, build.scene.chunks) {
            #expect(entry["id"] as? String == chunk.id)
            let glb = try GLBFile(data: fa["chunks/\(chunk.id)/lod0.glb"]!)
            let t = (glb.nodes[0]["translation"] as! [Double]).map(Float.init)
            let origin = SIMD3(t[0], t[1], t[2])
            let scene = try JSONSerialization.jsonObject(with: fa["chunks/\(chunk.id)/scene.json"]!) as! [String: Any]
            let featureIDs = (scene["features"] as! [[String: Any]]).map { $0["id"] as! String }
            var prim = 0
            for (mesh, ranges) in [(chunk.staticMesh, chunk.staticFeatures), (chunk.waterMesh, chunk.waterFeatures)] where !mesh.isEmpty {
                let p = glb.primitive(mesh: 0, prim)
                prim += 1
                let pos = glb.floats(p.attributes["POSITION"]!)
                #expect(pos.count == mesh.vertexCount * 3)
                for (i, q) in mesh.positions.enumerated() {
                    let r = origin + SIMD3(pos[i * 3], pos[i * 3 + 1], pos[i * 3 + 2])
                    worstError = max(worstError, simd_distance(r, q))
                }
                #expect(glb.uints(p.indices) == mesh.indices)
                let paint = glb.floats(p.attributes["_PAINT"]!)
                #expect(paint == mesh.paints.flatMap { [$0.x, $0.y, $0.z, $0.w] })
                // Every generator feature range maps to the same feature identity.
                let ids = glb.uints(p.attributes["_FEATURE"]!)
                for r in ranges { #expect(featureIDs[Int(ids[r.start])] == r.feature) }
            }
        }
        #expect(worstError <= 0.01, "worst chunk vertex error \(worstError) m")

        let inst = try JSONSerialization.jsonObject(with: fa["instances.json"]!) as! [String: Any]
        let list = inst["instances"] as! [[String: Any]]
        #expect(list.count == build.scene.instances.count)
        var worstInstance = 0.0
        for (e, i) in zip(list, build.scene.instances) {
            #expect(e["id"] as? String == i.source)
            #expect(e["kind"] as? String == i.kind.rawValue)
            let stretch = e["stretch"] as? [Double] ?? [1, 1]
            #expect(abs(stretch[0] - i.stretch.x) < 1e-5 && abs(stretch[1] - i.stretch.y) < 1e-5, "\(i.source) stretch")
            let p = e["position"] as! [Double]
            worstInstance = max(worstInstance, simd_distance(SIMD3(p[0], p[1], p[2]), SIMD3(i.x, i.height, -i.y)))
        }
        #expect(worstInstance <= 0.01, "worst instance error \(worstInstance) m")

        // Every placed instance has a prototype.
        let protos = Set((world["prototypes"] as! [[String: Any]]).map { "\($0["kind"] as! String)/\($0["variant"] as! Int)" })
        #expect(build.scene.instances.allSatisfy { protos.contains("\($0.kind.rawValue)/\($0.variant)") })

        // LOD1 is lighter and keeps every LOD0 building's identity.
        let tris = chunks.map { $0["triangles"] as! [Int] }
        #expect(tris.reduce(0) { $0 + $1[1] } < tris.reduce(0) { $0 + $1[0] })

        // The manifest's hashes cover every other file.
        let hashes = world["files"] as! [String: Any]
        #expect(Set(hashes.keys) == Set(fa.keys).subtracting(["world.json"]))

        // Licence notice (decision 6a): present, hashed, names every source; every file is classified.
        let notice = String(decoding: try #require(fa[WorldPackage.dataNoticeFile]), as: UTF8.self)
        #expect(hashes[WorldPackage.dataNoticeFile] != nil)
        #expect(notice.contains("Derivative Database of OpenStreetMap") && notice.contains("https://opendatacommons.org/licenses/odbl/1-0/"))
        for s in build.manifest.sources {
            #expect(notice.contains(s.attribution) && notice.contains(s.license) && notice.contains(s.format))
            if let h = s.sha256 { #expect(notice.contains(h)) }
        }
        #expect(fa.keys.filter { WorldPackage.licenseClass(of: $0) == nil }.sorted() == [], "unclassified package files")
        let sources = world["sources"] as! [[String: Any]]
        // The area manifest's sources plus the map layer's ZCTA boundaries and lidar slope grid, when the area has them.
        let extras = [("zcta.json", "census-zcta-v1"), ("terrain-slope.json", "worldengine-slope-grid-v1")]
            .filter { FileManager.default.fileExists(atPath: Self.areaDir.appendingPathComponent($0.0).path) }.map(\.1)
        #expect(sources.map { $0["format"] as? String ?? "" } == build.manifest.sources.map(\.format) + extras)
        #expect(sources.allSatisfy { ($0["licenseURL"] as? String)?.hasPrefix("https://") == true })
        let dataLicense = world["dataLicense"] as! [String: Any]
        #expect(dataLicense["license"] as? String == "ODbL-1.0" && dataLicense["notice"] as? String == WorldPackage.dataNoticeFile)
        let credits = world["credits"] as! [[String: Any]]
        #expect(credits.first?["id"] as? String == "openstreetmap")
        #expect(build.manifest.sources.allSatisfy { s in credits.contains { ($0["text"] as? String) == s.attribution } })
        print("PACKAGE files=\(fa.count) bytes=\(fa.values.reduce(0) { $0 + $1.count }) worstVertex=\(worstError) worstInstance=\(worstInstance)")
    }
}
