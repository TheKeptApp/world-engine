import Foundation
import simd

/// The world's color table. Every vertex stores a slot index into it; the renderer uploads the
/// table as a small texture, so palettes can later shift (season, time, weather) without
/// rebuilding meshes.
public struct Palette: Sendable {
    public private(set) var colors: [SIMD3<Float>] = []
    private var slotsByHex: [String: Int] = [:]
    private var named: [String: Int] = [:]

    /// Maximum slots (texture width).
    public static let capacity = 256

    public init(base: [String: String]) {
        for key in base.keys.sorted() { named[key] = slot(hex: base[key]!) }
    }

    /// The slot for a named base color ("lawn", "asphalt", ...). Unknown names map to slot 0.
    public func named(_ name: String) -> Int { named[name] ?? 0 }

    /// The slot for a hex color, adding it if new.
    public mutating func slot(hex: String) -> Int {
        let key = hex.uppercased()
        if let s = slotsByHex[key] { return s }
        precondition(colors.count < Self.capacity, "palette full")
        colors.append(Self.parse(key))
        slotsByHex[key] = colors.count - 1
        return colors.count - 1
    }

    /// "#RRGGBB" → linear-free sRGB components in 0...1.
    public static func parse(_ hex: String) -> SIMD3<Float> {
        let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt32(s, radix: 16) ?? 0xFF00FF
        return SIMD3(Float((v >> 16) & 0xFF), Float((v >> 8) & 0xFF), Float(v & 0xFF)) / 255
    }
}
