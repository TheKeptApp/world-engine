import CryptoKit
import Foundation
import Testing
@testable import WorldGen

@Suite("Paint-over grade data (paintover-v1)")
struct PaintoverGradeTests {
    let pg = try! StyleLibrary.paintoverGrade()

    @Test func matchesTheProposal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent(pg.source.path))
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        #expect(hash == pg.source.sha256, "rerun scripts/paintover_data.py")
    }

    @Test func statesTakeTheirLook() throws {
        let table = try StyleLibrary.grade()
        // A clear afternoon carries the ordinary/Evanston paint-overs' lift (deeper darks, more colour).
        let afternoon = table.resolve(sunElevation: 54.383, moonLight: 0, weather: nil, weight: 0).look
        #expect(afternoon == pg.states["ordinary-1530"])
        #expect(afternoon.exposureEV > 0 && afternoon.contrast > 1 && afternoon.saturation > 1 && afternoon.warmth > 0)
        // Full rain takes the rain paint-over's flatter, cooler grade.
        let rain = table.resolve(sunElevation: 54.383, moonLight: 0, weather: "rain", weight: 1).look
        #expect(rain == pg.states["light-rain"])
        #expect(rain.contrast < 1 && rain.warmth < 0)
        // States no paint-over shows stay neutral (night until night-v1).
        let night = table.resolve(sunElevation: -30, moonLight: 0, weather: nil, weight: 0).look
        #expect(night == .neutral)
    }
}
