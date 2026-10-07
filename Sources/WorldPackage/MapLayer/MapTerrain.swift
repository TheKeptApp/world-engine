import CryptoKit
import Foundation
import WorldGeo

/// Terrain slope for lots (worldengine.map/2 §8): the area's `terrain-slope.json` + `.bin`, a
/// 1 m slope grid in the area frame computed from USGS 3DEP lidar ground returns by
/// `Tools/regionkit/terrain`. Absent files = no slope (a flat package has no slope, never 0 %).
struct MapTerrain {
    struct Source {
        var id: String
        var title: String
        var attribution: String
        var license: String
        var licenseURL: String?
        var url: String?
        var dataTimestamp: String?
        var sha256: String
        var method: String
        var validation: String
    }

    /// Calibrated slope confidence (worldengine.map/2 §8, D-55): the share of validation cells whose
    /// slope agrees within 2 percentage points, per slope class (< 15 %, ≥ 15 %) and for the grid as a
    /// whole, taking the lower of the two validations (vs the USGS 1 m DEM; split-sample point noise).
    struct Confidence {
        var below15: Double
        var from15: Double
        var overall: Double
        var basis: String
    }

    static let headerFile = "terrain-slope.json"
    static let noData: UInt8 = 255
    static let capped: UInt8 = 254

    var cellM: Double
    var minX: Double
    var minY: Double
    var cols: Int
    var rows: Int
    var values: [UInt8]
    var source: Source
    var confidence: Confidence?

    static func load(areaDirectory: URL, frame: LocalFrame) throws -> MapTerrain? {
        guard let data = try? Data(contentsOf: areaDirectory.appendingPathComponent(headerFile)) else { return nil }
        let h = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard h["format"] as? String == "worldengine-slope-grid-v1", let cellM = h["cellM"] as? Double, let minX = h["minX"] as? Double,
              let minY = h["minY"] as? Double, let cols = h["cols"] as? Int, let rows = h["rows"] as? Int, let binFile = h["binFile"] as? String,
              let s = h["source"] as? [String: Any] else { throw MapLayerError.badInput("\(headerFile): unknown format") }
        if let o = (h["frame"] as? [String: Any])?["origin"] as? [String: Any], let lat = o["latitude"] as? Double, let lon = o["longitude"] as? Double,
           abs(lat - frame.origin.latitude) > 1e-9 || abs(lon - frame.origin.longitude) > 1e-9 {
            throw MapLayerError.badInput("\(headerFile): frame origin differs from the area manifest")
        }
        let compressed = try Data(contentsOf: areaDirectory.appendingPathComponent(binFile))
        let binHash = SHA256.hash(data: compressed).map { String(format: "%02x", $0) }.joined()
        if let expected = h["binSha256"] as? String, expected != binHash { throw MapLayerError.badInput("\(binFile): SHA-256 mismatch") }
        // Raw deflate (the regionkit writer uses wbits = −15, which is what Apple's zlib codec reads).
        let raw = try (compressed as NSData).decompressed(using: .zlib) as Data
        guard raw.count == cols * rows else { throw MapLayerError.badInput("\(binFile): \(raw.count) cells, expected \(cols * rows)") }
        let validation: String
        if let v = h["validation"], let d = try? JSONSerialization.data(withJSONObject: v, options: [.sortedKeys]) {
            validation = String(decoding: d, as: UTF8.self)
        } else {
            validation = "no validation recorded"
        }
        let source = Source(id: s["id"] as? String ?? "usgs-3dep", title: s["title"] as? String ?? "USGS 3DEP lidar",
                            attribution: s["attribution"] as? String ?? "USGS 3D Elevation Program", license: s["license"] as? String ?? "public-domain",
                            licenseURL: s["licenseURL"] as? String, url: s["url"] as? String, dataTimestamp: s["collected"] as? String,
                            sha256: binHash, method: h["method"] as? String ?? "", validation: validation)
        return MapTerrain(cellM: cellM, minX: minX, minY: minY, cols: cols, rows: rows, values: [UInt8](raw), source: source,
                          confidence: confidence(h["validation"] as? [String: Any]))
    }

    static func confidence(_ v: [String: Any]?) -> Confidence? {
        guard let v else { return nil }
        func cls(_ block: String, _ c: String) -> (share: Double, cells: Double)? {
            guard let b = (v[block] as? [String: Any])?[c] as? [String: Any], let s = b["shareWithin2Pts"] as? Double else { return nil }
            return (s, (b["cells"] as? Double) ?? Double(b["cells"] as? Int ?? 0))
        }
        guard let rl = cls("vsReference1mDEM", "slopeBelow15"), let rh = cls("vsReference1mDEM", "slope15AndAbove"),
              let sl = cls("splitSample", "slopeBelow15"), let sh = cls("splitSample", "slope15AndAbove") else { return nil }
        func overall(_ l: (share: Double, cells: Double), _ h: (share: Double, cells: Double)) -> Double {
            let n = l.cells + h.cells
            return n > 0 ? (l.share * l.cells + h.share * h.cells) / n : min(l.share, h.share)
        }
        let c = Confidence(below15: MapJSON.round3(min(rl.share, sl.share)), from15: MapJSON.round3(min(rh.share, sh.share)),
                           overall: MapJSON.round3(min(overall(rl, rh), overall(sl, sh))),
                           basis: "share of validation cells whose 1 m slope agrees within 2 percentage points, the lower of (a) the USGS 3DEP 1 m DEM from the same lidar (gridding and method error) and (b) a split-sample rebuild from alternate halves of the ground points (point noise); cells within 2 m of buildings, water or no-data excluded, as the lot slope excludes the 2 m strip along walls")
        return c
    }

    /// Confidence of a slope value by its class.
    func confidence(forPercent p: Double) -> Double? {
        guard let c = confidence else { return nil }
        return p < 15 ? c.below15 : c.from15
    }

    /// The grid as worldengine.map/2 §8.2 stores it: `uint16le`, v × 0.01 %, 65535 = no data, row 0
    /// south, each row west to east. The repository grid stores 0.5 % steps (v × 50 here, exact);
    /// its "≥ 127 %" code becomes 127 % (a lower bound).
    func uint16le() -> Data {
        var out = Data(count: values.count * 2)
        out.withUnsafeMutableBytes { (p: UnsafeMutableRawBufferPointer) in
            for (i, v) in values.enumerated() {
                let u: UInt16 = v == Self.noData ? 65535 : UInt16(v == Self.capped ? 127 * 100 : Int(v) * 50)
                p[2 * i] = UInt8(u & 0xff)
                p[2 * i + 1] = UInt8(u >> 8)
            }
        }
        return out
    }

    /// Steepest slope (percent) over the cells whose centres lie in `lawn` and outside `exclude`
    /// (the building footprint grown by a margin: terrain under and against walls is not lawn).
    /// Returns nil when fewer than `minCells` lawn cells carry data, or when under `minCoverage`
    /// of the lawn cells do.
    func maxSlope(lawn: [Ring], exclude: (LocalPoint) -> Bool, minCells: Int = 4, minCoverage: Double = 0.8) -> (percent: Double, capped: Bool)? {
        var n = 0, measured = 0
        var best: UInt8 = 0
        for ring in lawn where ring.count >= 3 {
            let box = Rect2D(enclosing: ring)
            let i0 = max(0, Int(((box.min.x - minX) / cellM).rounded(.down))), i1 = min(cols - 1, Int(((box.max.x - minX) / cellM).rounded(.down)))
            let j0 = max(0, Int(((box.min.y - minY) / cellM).rounded(.down))), j1 = min(rows - 1, Int(((box.max.y - minY) / cellM).rounded(.down)))
            guard i0 <= i1, j0 <= j1 else { continue }
            for j in j0...j1 { for i in i0...i1 {
                let p = LocalPoint(minX + (Double(i) + 0.5) * cellM, minY + (Double(j) + 0.5) * cellM)
                guard RingMath.contains(ring, p), !exclude(p) else { continue }
                n += 1
                let v = values[j * cols + i]
                guard v != Self.noData else { continue }
                measured += 1
                best = max(best, v)
            } }
        }
        guard measured >= minCells, Double(measured) >= minCoverage * Double(n) else { return nil }
        return (Double(best) / 2, best == Self.capped)
    }
}
