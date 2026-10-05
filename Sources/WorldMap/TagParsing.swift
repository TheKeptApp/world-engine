import Foundation

/// Parsing helpers for OSM tag values.
public enum TagParsing {
    /// Parses an OSM length into meters. Accepts `12`, `12.5`, `12 m`, `12m`, `12 ft`, `40'`,
    /// `40'6"` and `12,5`. Takes the first value of a `;` list. Returns nil for anything else,
    /// and for values that aren't positive or are implausibly large (over 1 km).
    public static func length(_ raw: String) -> Double? {
        var s = firstValue(raw).lowercased()
        if !s.contains("."), s.filter({ $0 == "," }).count == 1 { s = s.replacingOccurrences(of: ",", with: ".") }

        let meters: Double?
        if let quote = s.firstIndex(of: "'") {
            let feet = Double(s[..<quote].trimmingCharacters(in: .whitespaces))
            var rest = s[s.index(after: quote)...].trimmingCharacters(in: .whitespaces)
            if rest.hasSuffix("\"") { rest.removeLast() }
            rest = rest.trimmingCharacters(in: .whitespaces)
            let inches = rest.isEmpty ? 0 : Double(rest)
            if let feet, let inches { meters = feet * 0.3048 + inches * 0.0254 } else { meters = nil }
        } else {
            let numberEnd = s.firstIndex { !("0"..."9").contains($0) && $0 != "." } ?? s.endIndex
            let number = Double(s[..<numberEnd])
            let unit = s[numberEnd...].trimmingCharacters(in: .whitespaces)
            switch (number, unit) {
            case let (n?, ""), let (n?, "m"), let (n?, "meter"), let (n?, "meters"), let (n?, "metre"), let (n?, "metres"):
                meters = n
            case let (n?, "ft"), let (n?, "feet"), let (n?, "foot"):
                meters = n * 0.3048
            default:
                meters = nil
            }
        }
        guard let m = meters, m > 0, m <= 1000 else { return nil }
        return m
    }

    /// Parses a plain non-negative number (e.g. `building:levels`). Takes the first `;` value.
    public static func number(_ raw: String) -> Double? {
        let s = firstValue(raw).replacingOccurrences(of: ",", with: ".")
        guard let n = Double(s), n >= 0, n <= 500 else { return nil }
        return n
    }

    public static func integer(_ raw: String) -> Int? {
        Int(firstValue(raw))
    }

    static func firstValue(_ raw: String) -> String {
        (raw.split(separator: ";").first.map(String.init) ?? raw).trimmingCharacters(in: .whitespaces)
    }
}
