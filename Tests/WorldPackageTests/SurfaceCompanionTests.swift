import Foundation
import Testing
@testable import WorldPackage
@testable import WorldMesh

@Suite("Surface companion")
struct SurfaceCompanionTests {
    @Test(.enabled(if: PackageTests.hasData), .timeLimit(.minutes(5)))
    func optInChangesNoLegacyFileAndBindsHashes() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("surface-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tmp) }
        let off = tmp.appendingPathComponent("off"), on = tmp.appendingPathComponent("on"), side = tmp.appendingPathComponent("side")
        let options = PackageTests.options()
        #expect(options.surfaceRolesTo == nil)
        try WorldPackage.export(areaDirectory: PackageTests.areaDir, to: off, options: options)
        #expect(!FileManager.default.fileExists(atPath: side.path))
        var optIn = options; optIn.surfaceRolesTo = side
        try WorldPackage.export(areaDirectory: PackageTests.areaDir, to: on, options: optIn)
        let a = try PackageTests.files(off), b = try PackageTests.files(on)
        #expect(a == b)
        let index = try JSONSerialization.jsonObject(with: Data(contentsOf: side.appendingPathComponent("index.json"))) as! [String: Any]
        let binding = index["packageHash"] as! [String: String]
        #expect(binding["sha256"] == SurfaceCompanion.sha(a["world.json"]!))
        let payload = try Data(contentsOf: side.appendingPathComponent("triangles.u16le"))
        #expect((index["payload"] as! [String: Any])["sha256"] as? String == SurfaceCompanion.sha(payload))
        let entries = index["primitives"] as! [[String: Any]]
        #expect(!entries.isEmpty)
        for e in entries {
            #expect(e["sha256"] as? String == SurfaceCompanion.sha(a[e["path"] as! String]!))
            #expect((e["byteOffset"] as! Int) % 4 == 0)
            #expect((e["byteOffset"] as! Int) + (e["triangleCount"] as! Int) * 2 <= payload.count)
        }
        optIn.surfaceRolesTo = on.appendingPathComponent("roles")
        #expect(throws: SurfaceCompanion.Error.self) { try WorldPackage.export(areaDirectory: PackageTests.areaDir, to: on, options: optIn) }
    }
}
