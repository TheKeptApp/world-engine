import Testing
@testable import WorldGen

/// look.json is loaded with `try?` by the renderer, so a bad edit would silently fall back to defaults.
@Suite("Look spec")
struct LookSpecTests {
    @Test func decodes() throws {
        let look = try StyleLibrary.look()
        #expect(look.water.overcastReflectGain > 0 && look.water.overcastReflectGain <= 1)
        #expect(look.sky.cloudEdgeOvercast >= look.sky.cloudEdgeClear)
        // Owner: steady rain darkens paving 35–40% (concrete; asphalt may reach the cap).
        let steady = try StyleLibrary.rainBible().at(wetness: 0.7).surfaces["concrete"]!.darken
        let d = min(look.wetPaving.darkenMax, steady * look.wetPaving.darkenScale)
        #expect(d >= 0.35 && d <= 0.4)
    }
}
