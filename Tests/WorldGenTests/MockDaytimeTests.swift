import Foundation
import simd
import Testing
@testable import WorldGen

/// Daytime master colours (house-contrast-v1 sharedLighting) reach the scene palette unchanged.
struct MockDaytimeTests {
    @Test(arguments: ["evanston", "chicago-dense-north", "front-range"])
    func paletteTakesTheDaytimeMaster(_ profile: String) throws {
        let m = try #require(MockValues.bundled)
        let base = try StyleLibrary.seasonalPalette()
        let s = MockDaytime.applying(VegetationLibrary.bundled.applying(to: SceneGenerator.withLawnEndpoints(base, profileID: profile), profileID: profile))
        let p = MockDaytime.prefix
        #expect(s.surfaces["road"]?[1] == m.string(p + "ground.asphalt.hex"))
        #expect(s.surfaces["sidewalk"]?[1] == m.string(p + "ground.concrete.hex"))
        #expect(s.surfaces["curb"]?[1] == m.string(p + "ground.curbHex"))
        #expect(s.surfaces["lawn"]?[1] == m.string(p + "ground.lawn.hex"))
        // Lot endpoints: mean at the master lawn, spread kept (lot-to-lot variation).
        let a = Color.linear(Palette.parse(s.surfaces["lawnA"]![1])), b = Color.linear(Palette.parse(s.surfaces["lawnB"]![1]))
        let master = Color.linear(Palette.parse(m.string(p + "ground.lawn.hex")!))
        #expect(simd_length((a + b) / 2 - master) < 0.01, "lot lawn mean off the master")
        #expect(s.surfaces["lawnA"]![1] != s.surfaces["lawnB"]![1], "lot lawn spread lost")
        #expect(s.surfaces["water"]?[1] == m.string("lake-winter-v1/water.shoreline.exampleSurfaceValues[0].baseColourHex"))
        #expect(s.surfaces["bark"]?.allSatisfy { $0 == m.string(p + "postcard.trees.barkHex") } == true)
        let greens = Set((0..<3).compactMap { m.string(p + "postcard.trees.crownGreensHex[\($0)]") })
        let crowns = SeasonalPalette.order.filter { $0.hasPrefix("deciduous") }
        for key in crowns { #expect(greens.contains(s.surfaces[key]?[1] ?? ""), "\(profile) \(key) summer") }
        // All three greens are used; autumn keeps the species colours (Denver fix intact).
        #expect(Set(crowns.compactMap { s.surfaces[$0]?[1] }) == greens)
        let undressedAutumn = VegetationLibrary.bundled.applying(to: base, profileID: profile)
        for key in crowns { #expect(s.surfaces[key]?[2] == undressedAutumn.surfaces[key]?[2], "\(key) autumn changed") }
    }
}
