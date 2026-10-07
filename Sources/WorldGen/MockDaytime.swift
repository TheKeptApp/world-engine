import Foundation
import simd

/// The daytime master colours (house-contrast-v1 `sharedLighting`, R 2026-10-07: the daytime lighting master)
/// applied to a scene's seasonal palette, read by key from the bundled shared mock values
/// (`Profiles/mock-values.json`). No multipliers: the mock hex values replace the palette's.
/// - Paving (asphalt road, concrete sidewalk, curb): spring, summer and autumn (winter keeps its salted look,
///   which the master does not cover).
/// - Lawn (base lawn and the lot endpoint pair): summer.
/// - Deciduous crowns: spring and summer take the master's three crown greens, dark/mid/light, given to the
///   region's crown slots by their current summer lightness (darkest third → dark green); autumn and winter
///   (species colours, the Denver mix) are unchanged.
/// - Bark: every season.
enum MockDaytime {
    static let prefix = "house-contrast-v1/sharedLighting."

    static func applying(_ seasonal: SeasonalPalette, mock: MockValues? = .bundled) -> SeasonalPalette {
        guard let m = mock else { return seasonal }
        var out = seasonal
        func set(_ key: String, seasons: [Int], _ hex: String?) {
            guard let hex, var row = out.surfaces[key], row.count == 4 else { return }
            for s in seasons { row[s] = hex }
            out.surfaces[key] = row
        }
        set("road", seasons: [0, 1, 2], m.string(prefix + "ground.asphalt.hex"))
        set("sidewalk", seasons: [0, 1, 2], m.string(prefix + "ground.concrete.hex"))
        set("curb", seasons: [0, 1, 2], m.string(prefix + "ground.curbHex"))
        for key in ["lawn", "lawnA", "lawnB"] { set(key, seasons: [1], m.string(prefix + "ground.lawn.hex")) }
        set("bark", seasons: [0, 1, 2, 3], m.string(prefix + "postcard.trees.barkHex"))

        let greens = (0..<3).compactMap { m.string(prefix + "postcard.trees.crownGreensHex[\($0)]") }
        guard greens.count == 3 else { return out }
        // Dark, mid, light by luminance (the mock lists them in that order; sorted to be safe).
        let ranked = greens.sorted { luminance($0) < luminance($1) }
        let crowns = SeasonalPalette.order.filter { $0.hasPrefix("deciduous") }.filter { (out.surfaces[$0]?.count ?? 0) == 4 }
        let byLightness = crowns.sorted { (luminance(out.surfaces[$0]![1]), $0) < (luminance(out.surfaces[$1]![1]), $1) }
        for (i, key) in byLightness.enumerated() {
            let green = ranked[min(2, i * 3 / max(1, byLightness.count))]
            set(key, seasons: [0, 1], green)
        }
        return out
    }

    static func luminance(_ hex: String) -> Float {
        simd_dot(Color.linear(Palette.parse(hex)), SIMD3(0.2126, 0.7152, 0.0722))
    }
}
