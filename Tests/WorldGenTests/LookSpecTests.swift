import Testing
@testable import WorldGen

/// look.json is loaded with `try?` by the renderer, so a bad edit would silently fall back to defaults.
@Suite("Look spec")
struct LookSpecTests {
    @Test func decodes() throws {
        let look = try StyleLibrary.look()
        #expect(look.water.overcastReflectGain > 0 && look.water.overcastReflectGain <= 1)
        #expect(look.sky.cloudEdgeOvercast >= look.sky.cloudEdgeClear)
        // Wet darkening is the rain pack's alone (12% or less, once); patchy sheen keeps the pack's mean.
        let ws = try #require(look.wetSheen)
        #expect(abs((ws.low + ws.high) / 2 - 1) < 0.05 && ws.glossRoughness > 0 && ws.glossRoughness <= 1)
        // Owner: real sun shadows reach the lawns, 120–150 m.
        #expect(look.shadows.rangeM >= 120 && look.shadows.rangeM <= 150)
        #expect(look.shadows.lowSunRangeM >= look.shadows.rangeM)
    }
}
