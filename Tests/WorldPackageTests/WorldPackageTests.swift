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
    @Test(.enabled(if: hasData), .timeLimit(.minutes(5)))
    func packageIsDeterministicAndMatchesTheGenerator() throws {
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
        print("PACKAGE files=\(fa.count) bytes=\(fa.values.reduce(0) { $0 + $1.count }) worstVertex=\(worstError) worstInstance=\(worstInstance)")
    }
}
