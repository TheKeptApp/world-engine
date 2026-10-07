import Foundation

/// Mean elements as published (TLE/OMM): angles in degrees, mean motion in revolutions per day.
/// Port of `Tools/livefeeds/livefeeds/sats/elements.py` (parsing) and `Elements` in `sgp4.py`.
public struct SatelliteElements: Sendable, Equatable {
    public var noradId: Int
    public var name: String
    /// POSIX seconds (UTC).
    public var epoch: Double
    public var inclinationDeg: Double
    public var raanDeg: Double
    public var eccentricity: Double
    public var argPerigeeDeg: Double
    public var meanAnomalyDeg: Double
    public var meanMotionRevPerDay: Double
    public var bstar: Double

    public init(noradId: Int, name: String, epoch: Double, inclinationDeg: Double, raanDeg: Double,
                eccentricity: Double, argPerigeeDeg: Double, meanAnomalyDeg: Double,
                meanMotionRevPerDay: Double, bstar: Double) {
        self.noradId = noradId
        self.name = name
        self.epoch = epoch
        self.inclinationDeg = inclinationDeg
        self.raanDeg = raanDeg
        self.eccentricity = eccentricity
        self.argPerigeeDeg = argPerigeeDeg
        self.meanAnomalyDeg = meanAnomalyDeg
        self.meanMotionRevPerDay = meanMotionRevPerDay
        self.bstar = bstar
    }

    // MARK: - TLE

    static func isAsciiDigit(_ c: Character) -> Bool {
        return c >= "0" && c <= "9"
    }

    static func digitValue(_ c: Character) -> Int {
        return Int(String(c)) ?? 0
    }

    static func checksumOK(_ chars: [Character]) -> Bool {
        var s = 0
        for i in 0..<68 {
            let ch = chars[i]
            if isAsciiDigit(ch) {
                s += digitValue(ch)
            } else if ch == "-" {
                s += 1
            }
        }
        let last = chars[68]
        return isAsciiDigit(last) && s % 10 == digitValue(last)
    }

    static func slice(_ chars: [Character], _ from: Int, _ to: Int) -> String {
        let lo = min(from, chars.count)
        let hi = min(to, chars.count)
        if lo >= hi {
            return ""
        }
        return String(chars[lo..<hi])
    }

    static func trimmed(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Python `float(str)` for the plain decimal forms element sets use.
    static func pyFloat(_ raw: String) throws -> Double {
        var s = trimmed(raw)
        var sign = ""
        if s.hasPrefix("-") || s.hasPrefix("+") {
            sign = String(s.prefix(1))
            s = String(s.dropFirst())
        }
        if s.hasPrefix(".") {
            s = "0" + s
        }
        if s.hasSuffix(".") {
            s += "0"
        }
        if s.isEmpty {
            throw SatelliteError.element("malformed TLE field: could not convert string to float: '\(raw)'")
        }
        guard let v = Double(sign + s) else {
            throw SatelliteError.element("malformed TLE field: could not convert string to float: '\(raw)'")
        }
        return v
    }

    /// Python `int(str)`.
    static func pyInt(_ raw: String) throws -> Int {
        let s = trimmed(raw)
        let body = (s.hasPrefix("+")) ? String(s.dropFirst()) : s
        guard let v = Int(body) else {
            throw SatelliteError.element("malformed TLE field: invalid literal for int(): '\(raw)'")
        }
        return v
    }

    /// TLE "assumed decimal point" exponent field, e.g. '-11606-4' -> -0.11606e-4.
    static func impliedDecimal(_ field: String) throws -> Double {
        var f = trimmed(field)
        let stripped = f.replacingOccurrences(of: "0", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "-", with: "")
        if f.isEmpty || stripped.isEmpty {
            return 0.0
        }
        let sign: Double = f.hasPrefix("-") ? -1.0 : 1.0
        while f.hasPrefix("+") || f.hasPrefix("-") {
            f = String(f.dropFirst())
        }
        let chars = Array(f)
        let mant = chars.count >= 2 ? String(chars[0..<(chars.count - 2)]) : ""
        let exp = chars.count >= 2 ? String(chars[(chars.count - 2)...]) : f
        let m = try pyFloat("0." + mant)
        let e = try pyInt(exp)
        return sign * m * pow(10.0, Double(e))
    }

    /// Days since 1970-01-01 of a proleptic Gregorian date (H. Hinnant's days_from_civil).
    static func daysFromCivil(_ year: Int, _ month: Int, _ day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }

    static func tleEpochPosix(year2: Int, day: Double) -> Double {
        let year = year2 >= 57 ? 1900 + year2 : 2000 + year2
        let jan1 = daysFromCivil(year, 1, 1) * 86400
        return Double(jan1) + (day - 1.0) * 86400.0
    }

    static func rstrip(_ s: String) -> String {
        var chars = Array(s)
        while let last = chars.last, last.isWhitespace {
            chars.removeLast()
        }
        return String(chars)
    }

    public static func parseTLE(name: String, line1: String, line2: String,
                                verifyChecksum: Bool = true) throws -> SatelliteElements {
        let l1 = Array(rstrip(line1))
        let l2 = Array(rstrip(line2))
        if l1.count < 69 || l2.count < 69 || l1[0] != "1" || l2[0] != "2" {
            throw SatelliteError.element("not a two-line element set")
        }
        if verifyChecksum && !(checksumOK(l1) && checksumOK(l2)) {
            throw SatelliteError.element("TLE checksum mismatch")
        }
        let norad = try pyInt(slice(l1, 2, 7))
        if try pyInt(slice(l2, 2, 7)) != norad {
            throw SatelliteError.element("line numbers disagree")
        }
        let trimmedName = trimmed(name)
        let epoch = tleEpochPosix(year2: try pyInt(slice(l1, 18, 20)), day: try pyFloat(slice(l1, 20, 32)))
        return SatelliteElements(
            noradId: norad, name: trimmedName.isEmpty ? String(norad) : trimmedName,
            epoch: epoch,
            inclinationDeg: try pyFloat(slice(l2, 8, 16)), raanDeg: try pyFloat(slice(l2, 17, 25)),
            eccentricity: try pyFloat("0." + trimmed(slice(l2, 26, 33))),
            argPerigeeDeg: try pyFloat(slice(l2, 34, 42)),
            meanAnomalyDeg: try pyFloat(slice(l2, 43, 51)),
            meanMotionRevPerDay: try pyFloat(slice(l2, 52, 63)),
            bstar: try impliedDecimal(slice(l1, 53, 61)))
    }

    /// Three-line (name + two lines) or bare two-line sets, as CelesTrak FORMAT=tle returns them.
    public static func parseTLEText(_ text: String) throws -> [SatelliteElements] {
        var lines: [String] = []
        for raw in text.components(separatedBy: .newlines) {
            if !trimmed(raw).isEmpty {
                lines.append(rstrip(raw))
            }
        }
        var out: [SatelliteElements] = []
        var i = 0
        while i < lines.count {
            if lines[i].hasPrefix("1 ") && i + 1 < lines.count && lines[i + 1].hasPrefix("2 ") {
                out.append(try parseTLE(name: "", line1: lines[i], line2: lines[i + 1]))
                i += 2
            } else if i + 2 < lines.count && lines[i + 1].hasPrefix("1 ") && lines[i + 2].hasPrefix("2 ") {
                out.append(try parseTLE(name: lines[i], line1: lines[i + 1], line2: lines[i + 2]))
                i += 3
            } else {
                throw SatelliteError.element("unparseable TLE text near line \(i + 1)")
            }
        }
        return out
    }

    // MARK: - OMM

    static func anyDouble(_ v: Any?, key: String) throws -> Double {
        if let d = v as? Double {
            return d
        }
        if let n = v as? Int {
            return Double(n)
        }
        if let n = v as? NSNumber {
            return n.doubleValue
        }
        if let s = v as? String {
            return try pyFloat(s)
        }
        throw SatelliteError.element("malformed OMM record: '\(key)'")
    }

    static func anyInt(_ v: Any?, key: String) throws -> Int {
        if let n = v as? Int {
            return n
        }
        if let d = v as? Double, d.isFinite {
            return Int(d)
        }
        if let n = v as? NSNumber {
            return n.intValue
        }
        if let s = v as? String {
            return try pyInt(s)
        }
        throw SatelliteError.element("malformed OMM record: '\(key)'")
    }

    /// ISO 8601 without zone (UTC assumed, a trailing Z is ignored), as Python's `fromisoformat`.
    static func isoToPosix(_ raw: String) throws -> Double {
        let s = trimmed(raw).replacingOccurrences(of: "Z", with: "")
        let bad = SatelliteError.element("malformed OMM record: bad EPOCH '\(raw)'")
        let parts = s.split(separator: "T", maxSplits: 1, omittingEmptySubsequences: false)
        let dateParts = parts[0].split(separator: "-", omittingEmptySubsequences: false)
        guard dateParts.count == 3, let y = Int(dateParts[0]), let mo = Int(dateParts[1]),
              let d = Int(dateParts[2]) else { throw bad }
        var hh = 0
        var mm = 0
        var ss = 0
        var micro = 0
        if parts.count == 2 {
            let timeParts = parts[1].split(separator: ":", omittingEmptySubsequences: false)
            guard timeParts.count >= 2, let h = Int(timeParts[0]), let mi = Int(timeParts[1]) else { throw bad }
            hh = h
            mm = mi
            if timeParts.count >= 3 {
                let secParts = timeParts[2].split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                guard let sec = Int(secParts[0]) else { throw bad }
                ss = sec
                if secParts.count == 2 {
                    var frac = String(secParts[1])
                    if frac.isEmpty || frac.count > 9 { throw bad }
                    while frac.count < 6 { frac += "0" }
                    // Python keeps microseconds.
                    guard let us = Int(String(frac.prefix(6))) else { throw bad }
                    micro = us
                }
            }
        }
        let days = daysFromCivil(y, mo, d)
        let whole = days * 86400 + hh * 3600 + mm * 60 + ss
        return Double(whole) + Double(micro) / 1_000_000.0
    }

    /// CCSDS OMM keys as CelesTrak's GP API returns them with FORMAT=json.
    public static func parseOMM(records: [[String: Any]]) throws -> [SatelliteElements] {
        var out: [SatelliteElements] = []
        for r in records {
            guard let noradAny = r["NORAD_CAT_ID"] else {
                throw SatelliteError.element("malformed OMM record: 'NORAD_CAT_ID'")
            }
            let norad = try anyInt(noradAny, key: "NORAD_CAT_ID")
            let name: String
            if let n = r["OBJECT_NAME"], !(n is NSNull) {
                name = trimmed("\(n)")
            } else {
                name = "\(noradAny)"
            }
            guard let epochStr = r["EPOCH"] as? String else {
                throw SatelliteError.element("malformed OMM record: 'EPOCH'")
            }
            var bstar = 0.0
            if let b = r["BSTAR"] {
                bstar = try anyDouble(b, key: "BSTAR")
            }
            out.append(SatelliteElements(
                noradId: norad, name: name, epoch: try isoToPosix(epochStr),
                inclinationDeg: try anyDouble(r["INCLINATION"], key: "INCLINATION"),
                raanDeg: try anyDouble(r["RA_OF_ASC_NODE"], key: "RA_OF_ASC_NODE"),
                eccentricity: try anyDouble(r["ECCENTRICITY"], key: "ECCENTRICITY"),
                argPerigeeDeg: try anyDouble(r["ARG_OF_PERICENTER"], key: "ARG_OF_PERICENTER"),
                meanAnomalyDeg: try anyDouble(r["MEAN_ANOMALY"], key: "MEAN_ANOMALY"),
                meanMotionRevPerDay: try anyDouble(r["MEAN_MOTION"], key: "MEAN_MOTION"),
                bstar: bstar))
        }
        return out
    }

    /// OMM JSON as bytes: an array of records (or a single record object).
    public static func parseOMM(jsonData: Data) throws -> [SatelliteElements] {
        let obj: Any
        do {
            obj = try JSONSerialization.jsonObject(with: jsonData, options: [])
        } catch {
            throw SatelliteError.element("malformed OMM JSON: \(error)")
        }
        if let arr = obj as? [[String: Any]] {
            return try parseOMM(records: arr)
        }
        if let one = obj as? [String: Any] {
            return try parseOMM(records: [one])
        }
        throw SatelliteError.element("malformed OMM JSON: expected an array of records")
    }
}
