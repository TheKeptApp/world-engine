import Testing
@testable import WorldGen

/// look.json is loaded with `try?` by the renderer, so a bad edit would silently fall back to defaults.
@Suite("Look spec")
struct LookSpecTests {
    @Test func decodes() throws {
        let look = try StyleLibrary.look()
        #expect(look.water.overcastReflectGain > 0 && look.water.overcastReflectGain <= 1)
    }
}
