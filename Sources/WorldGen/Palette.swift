import Foundation
import simd

/// The world's color table. Every vertex stores a slot index into it; renderers upload the table
/// as a small texture, so seasons (and later weather) change colors without rebuilding meshes.
///
/// Slots 0…n-1 are the seasonal surfaces in `SeasonalPalette.order` (always at the same
/// indices), then season-independent base colors, then colors added by generation (house
/// tuples). Changing the season rewrites only the seasonal slots.
public struct Palette: Sendable {
    public private(set) var colors: [SIMD3<Float>] = []
    private var slotsByHex: [String: Int] = [:]
    private var named: [String: Int] = [:]
    private var seasonal: SeasonalPalette?
    public private(set) var season = 1

    /// Maximum slots (texture width).
    public static let capacity = 256

    /// Seasonal surfaces first (fixed slots), then base colors.
    public init(seasonal: SeasonalPalette, season: Int, base: [String: String]) {
        self.seasonal = seasonal
        self.season = season
        for key in SeasonalPalette.order {
            let hex = seasonal.surfaces[key]?[season] ?? "#FF00FF"
            colors.append(Self.parse(hex))
            named[key] = colors.count - 1
        }
        for key in base.keys.sorted() { named[key] = slot(hex: base[key]!) }
    }

    /// Base colors only (tests, tools).
    public init(base: [String: String]) {
        for key in base.keys.sorted() { named[key] = slot(hex: base[key]!) }
    }

    /// The slot for a named color ("lawn", "road", "windowDay"…). Unknown names map to slot 0.
    public func named(_ name: String) -> Int { named[name] ?? 0 }

    /// This palette with every seasonal surface blended across the four seasons in linear light
    /// (sky-seasons §5.3 continuous palettes). `weights(key)` returns (spring, summer, autumn,
    /// winter) for a surface key, or nil to keep its current color.
    public func blendingSeasons(_ weights: (String) -> SIMD4<Double>?) -> Palette {
        guard let seasonal else { return self }
        var p = self
        for (slot, key) in SeasonalPalette.order.enumerated() {
            guard let w = weights(key), let hexes = seasonal.surfaces[key], hexes.count == 4 else { continue }
            var linear = SIMD3<Float>(repeating: 0)
            for s in 0..<4 { linear += Color.linear(Self.parse(hexes[s])) * Float(w[s]) }
            p.colors[slot] = Color.srgb(linear)
        }
        return p
    }

    /// All named slots (for export).
    public var namedSlots: [String: Int] { named }

    /// The slot for a hex color, adding it if new.
    public mutating func slot(hex: String) -> Int {
        let key = hex.uppercased()
        if let s = slotsByHex[key] { return s }
        precondition(colors.count < Self.capacity, "palette full")
        colors.append(Self.parse(key))
        slotsByHex[key] = colors.count - 1
        return colors.count - 1
    }

    /// The same palette with seasonal slots set to another season (house colors unchanged).
    public func withSeason(_ s: Int) -> Palette {
        guard let seasonal else { return self }
        var p = self
        p.season = s
        for (i, key) in SeasonalPalette.order.enumerated() {
            p.colors[i] = Self.parse(seasonal.surfaces[key]?[s] ?? "#FF00FF")
        }
        return p
    }

    /// "#RRGGBB" → sRGB components in 0...1.
    public static func parse(_ hex: String) -> SIMD3<Float> {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt32(s, radix: 16) ?? 0xFF00FF
        return SIMD3(Float((v >> 16) & 0xFF), Float((v >> 8) & 0xFF), Float(v & 0xFF)) / 255
    }

    public static func hex(_ c: SIMD3<Float>) -> String {
        let r = Int((c.x * 255).rounded()), g = Int((c.y * 255).rounded()), b = Int((c.z * 255).rounded())
        return String(format: "#%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }
}
