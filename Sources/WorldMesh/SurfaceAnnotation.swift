import Foundation

/// Export-only semantics; never encoded in native paint channels.
public enum SurfaceRole: UInt16, Sendable { case other = 0, roof, wall, trim, door }
public enum SurfaceCapture {
    @TaskLocal public static var enabled = false
    public static let materials = ["unknown", "brick", "stone", "wood", "metal", "concrete", "render", "glass", "asphalt", "clay_tile", "slate", "bituminous_shingle"]
    /// Only explicit supported source materials count; colour is independent evidence.
    public static func word(role: SurfaceRole, material: String? = nil, mappedColour: Bool = false,
                            familyColour: Bool = false) -> UInt16 {
        let normalized = material?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let id = normalized.flatMap { materials.firstIndex(of: $0) } ?? 0
        let colour: UInt16 = mappedColour ? 1 : (familyColour ? 2 : 0)
        return role.rawValue | UInt16(id << 3) | (id > 0 ? 1 << 8 : 0) | colour << 10
    }
}
