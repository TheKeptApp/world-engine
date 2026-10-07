import Foundation

/// A JSON value written deterministically for the map data layer (worldengine.map/2 §3, §15):
/// sorted keys, two-space indentation, a final newline, numbers rounded half away from zero to at
/// most 3 decimals, integral values without a fraction, never `-0`, NaN or infinities.
enum MapJSON {
    case object([String: MapJSON])
    case array([MapJSON])
    case string(String)
    case number(Double)
    /// A number written exactly (shortest round-trip form), for geographic coordinates.
    case exact(Double)
    case bool(Bool)
    /// JSON `null` (only where the contract asks for it, e.g. a node in no ZCTA).
    case null

    /// Rounds to 3 decimals, half away from zero (`.rounded()` is `.toNearestOrAwayFromZero`).
    static func round3(_ v: Double) -> Double {
        let r = (v * 1000).rounded() / 1000
        return r == 0 ? 0 : r
    }

    static func num(_ v: Double) -> MapJSON { .number(round3(v)) }
    static func point(_ p: SIMD2<Double>) -> MapJSON { .array([num(p.x), num(p.y)]) }
    static func strings(_ s: [String]) -> MapJSON { .array(s.map { .string($0) }) }
    static func tags(_ t: [String: String]) -> MapJSON { .object(t.mapValues { .string($0) }) }

    /// UTF-8 text with a final newline.
    func encoded() -> Data {
        var s = ""
        write(into: &s, indent: 0)
        s += "\n"
        return Data(s.utf8)
    }

    func write(into s: inout String, indent: Int) {
        switch self {
        case .object(let o):
            if o.isEmpty { s += "{}"; return }
            s += "{\n"
            // Byte order of the UTF-8 keys (§3).
            let keys = o.keys.sorted { Array($0.utf8).lexicographicallyPrecedes(Array($1.utf8)) }
            for (i, k) in keys.enumerated() {
                s += String(repeating: " ", count: indent + 2)
                Self.writeString(k, into: &s)
                s += ": "
                o[k]!.write(into: &s, indent: indent + 2)
                s += i == keys.count - 1 ? "\n" : ",\n"
            }
            s += String(repeating: " ", count: indent) + "}"
        case .array(let a):
            if a.isEmpty { s += "[]"; return }
            s += "[\n"
            for (i, v) in a.enumerated() {
                s += String(repeating: " ", count: indent + 2)
                v.write(into: &s, indent: indent + 2)
                s += i == a.count - 1 ? "\n" : ",\n"
            }
            s += String(repeating: " ", count: indent) + "]"
        case .string(let v):
            Self.writeString(v, into: &s)
        case .number(let v):
            s += Self.format(v)
        case .exact(let v):
            precondition(v.isFinite)
            s += v == v.rounded() && abs(v) < 1e15 ? String(Int64(v)) : "\(v)"
        case .bool(let v):
            s += v ? "true" : "false"
        case .null:
            s += "null"
        }
    }

    static func format(_ v: Double) -> String {
        precondition(v.isFinite, "map layer numbers must be finite")
        let r = round3(v)
        if r == r.rounded(), abs(r) < 1e15 { return String(Int64(r)) }
        return "\(r)"
    }

    static func writeString(_ v: String, into s: inout String) {
        s += "\""
        for u in v.unicodeScalars {
            switch u {
            case "\"": s += "\\\""
            case "\\": s += "\\\\"
            case "\n": s += "\\n"
            case "\r": s += "\\r"
            case "\t": s += "\\t"
            case _ where u.value < 0x20: s += String(format: "\\u%04x", u.value)
            default: s.unicodeScalars.append(u)
            }
        }
        s += "\""
    }

    /// Sorts records by their `id` (byte order of the UTF-8 string, §3).
    static func sortedByID(_ records: [[String: MapJSON]]) -> [MapJSON] {
        records.sorted { idBytes($0).lexicographicallyPrecedes(idBytes($1)) }.map { .object($0) }
    }

    static func idBytes(_ r: [String: MapJSON]) -> [UInt8] {
        if case .string(let s)? = r["id"] { return Array(s.utf8) }
        return []
    }

    static func byteOrder(_ a: String, _ b: String) -> Bool { Array(a.utf8).lexicographicallyPrecedes(Array(b.utf8)) }
}
