import Foundation
import Testing
@testable import LiveSky

@Suite("Naked-eye star binary")
struct StarBinaryTests {
    @Test func binaryMatchesJSONSource() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Tools/livefeeds/data/sky/stars-bsc5-v65.json")
        let json = try StarCatalog.load(data: Data(contentsOf: url)).stars
        let bin = try StarCatalog.nakedEye().stars
        #expect(bin.count == json.count)
        #expect(bin.count > 8000)
        for (b, j) in zip(bin, json) {
            #expect(b.id == j.id && b.hr == j.hr && b.name == j.name)
            #expect(abs(b.mag - j.mag) < 1e-9)
            #expect((b.ci == nil) == (j.ci == nil))
            if let bc = b.ci, let jc = j.ci { #expect(abs(bc - jc) < 1e-9) }
            // Float32 directions: about 0.01 arcsec.
            #expect((b.u - j.u).norm < 1e-7)
            #expect((b.distPc == nil) == (j.distPc == nil))
            #expect((b.velPcPerYear == nil) == (j.velPcPerYear == nil))
        }
        #expect(bin.first?.name == "Sirius")
        #expect((bin.last?.mag ?? 0) <= 6.5)
    }

    @Test func rejectsBadInput() {
        #expect(throws: StarCatalog.LoadError.self) { try StarCatalog.load(binary: Data("nope".utf8)) }
    }
}
