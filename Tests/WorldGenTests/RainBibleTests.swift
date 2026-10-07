import CryptoKit
import Foundation
import Testing
@testable import WorldGen

@Suite("Rain pack data (rain-v1)")
struct RainBibleTests {
    let rb = try! StyleLibrary.rainBible()

    @Test func matchesTheProposal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent(rb.source.path))
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #expect(hash == rb.source.sha256, "rerun scripts/rainfix_data.py")
    }

    @Test func statesInterpolateByWetness() {
        let dry = rb.at(wetness: 0)
        #expect(dry.surfaces["concrete"]!.darken == 0 && dry.puddleCoverage == 0)
        for st in rb.states where st.id != "drying" {
            let at = rb.at(wetness: st.wetness)
            #expect(abs(at.surfaces["asphalt"]!.darken - st.surfaces["asphalt"]!.darken) < 1e-9, "\(st.id)")
            #expect(abs(at.puddleCoverage - st.puddleCoverage) < 1e-9, "\(st.id)")
        }
        // Monotonic darkening with wetness, bounded by the pack's soaked cap.
        var last = -1.0
        for w in stride(from: 0.0, through: 1.0, by: 0.05) {
            let d = rb.at(wetness: w).surfaces["concrete"]!.darken
            #expect(d >= last - 1e-12 && d <= 0.12 + 1e-9)
            last = d
        }
    }
}
