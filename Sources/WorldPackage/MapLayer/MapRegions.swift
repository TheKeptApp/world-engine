import CryptoKit
import Foundation
import simd
import WorldGeo

/// ZIP Code Tabulation Areas for the map data layer (worldengine.map/2 §12), from the area's
/// `zcta.json` (Census ZCTA5 boundaries, written by `Tools/regionkit/zcta`). Absent file = no
/// regions (outside the US, or not prepared).
struct MapRegions {
    struct Region {
        var id: String
        var polygons: [Polygon2D]
        var bounds: Rect2D
    }

    struct Source {
        var id: String
        var title: String
        var attribution: String
        var license: String
        var licenseURL: String?
        var url: String?
        var vintage: String
        var sha256: String
    }

    static let fileName = "zcta.json"

    var regions: [Region]
    var source: Source

    static func load(areaDirectory: URL, frame: LocalFrame) throws -> MapRegions? {
        let url = areaDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard obj["format"] as? String == "census-zcta-v1", let s = obj["source"] as? [String: Any],
              let list = obj["zctas"] as? [[String: Any]] else { throw MapLayerError.badInput("\(fileName): unknown format") }
        var regions: [Region] = []
        for z in list {
            guard let id = z["id"] as? String, let polys = z["polygons"] as? [[[[Double]]]] else { continue }
            let polygons: [Polygon2D] = polys.compactMap { rings in
                let local = rings.map { ring -> Ring in
                    var r = ring.map { frame.localPoint(of: GeoCoordinate(latitude: $0[1], longitude: $0[0])) }
                    if r.count > 1, r.first == r.last { r.removeLast() }
                    return r
                }
                guard let outer = local.first, outer.count >= 3 else { return nil }
                return Polygon2D(outer: outer, holes: Array(local.dropFirst()))
            }
            guard !polygons.isEmpty else { continue }
            let all = polygons.flatMap(\.outer)
            regions.append(Region(id: id, polygons: polygons, bounds: Rect2D(enclosing: all)))
        }
        regions.sort { $0.id < $1.id }
        let vintage = (s["vintage"] as? Int).map(String.init) ?? (s["vintage"] as? String) ?? ""
        let source = Source(id: s["id"] as? String ?? "census-zcta", title: s["title"] as? String ?? "U.S. Census Bureau ZCTA5",
                            attribution: s["attribution"] as? String ?? "U.S. Census Bureau", license: s["license"] as? String ?? "public-domain",
                            licenseURL: s["licenseURL"] as? String, url: s["url"] as? String, vintage: vintage,
                            sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
        return MapRegions(regions: regions, source: source)
    }

    static func contains(_ poly: Polygon2D, _ p: LocalPoint) -> Bool {
        RingMath.contains(poly.outer, p) && !poly.holes.contains { RingMath.contains($0, p) }
    }

    /// Distance from `p` to the region's boundary (for the exact-boundary rule).
    static func boundaryDistance(_ r: Region, _ p: LocalPoint) -> Double {
        var best = Double.infinity
        for poly in r.polygons {
            for ring in [poly.outer] + poly.holes {
                for i in ring.indices {
                    let a = ring[i], b = ring[(i + 1) % ring.count], d = b - a
                    let len2 = simd_length_squared(d)
                    let t = len2 > 0 ? min(1, max(0, simd_dot(p - a, d) / len2)) : 0
                    best = min(best, simd_distance(p, a + d * t))
                }
            }
        }
        return best
    }

    /// The ZCTA containing `p`; a point exactly on a boundary (within 1 mm) takes the lower ID.
    func region(at p: LocalPoint) -> String? {
        var hits: [String] = []
        for r in regions where r.bounds.expanded(by: 0.001).contains(p) {
            if r.polygons.contains(where: { Self.contains($0, p) }) || Self.boundaryDistance(r, p) <= 0.001 { hits.append(r.id) }
        }
        return hits.min()
    }

    /// Every ZCTA a polyline or ring touches, sorted; written only when there are two or more.
    func spanned(_ pts: [LocalPoint], closed: Bool) -> [String]? {
        guard !pts.isEmpty else { return nil }
        let box = Rect2D(enclosing: pts)
        var out: [String] = []
        for r in regions where r.bounds.intersects(box.expanded(by: 0.001)) {
            if pts.contains(where: { p in r.polygons.contains { Self.contains($0, p) } }) { out.append(r.id); continue }
            if Self.crossesBoundary(r, pts, closed: closed) { out.append(r.id); continue }
            // A ring that encloses the whole region.
            if closed, let probe = r.polygons.first?.outer.first, RingMath.contains(pts, probe) { out.append(r.id) }
        }
        return out.count >= 2 ? out.sorted() : nil
    }

    static func crossesBoundary(_ r: Region, _ pts: [LocalPoint], closed: Bool) -> Bool {
        var edges = Array(zip(pts, pts.dropFirst()))
        if closed, let f = pts.first, let l = pts.last { edges.append((l, f)) }
        for poly in r.polygons {
            for ring in [poly.outer] + poly.holes {
                for i in ring.indices {
                    let c = ring[i], d = ring[(i + 1) % ring.count]
                    for (a, b) in edges where segmentsIntersect(a, b, c, d) { return true }
                }
            }
        }
        return false
    }

    static func segmentsIntersect(_ a: LocalPoint, _ b: LocalPoint, _ c: LocalPoint, _ d: LocalPoint) -> Bool {
        func orient(_ p: LocalPoint, _ q: LocalPoint, _ r: LocalPoint) -> Double { RingMath.cross(q - p, r - p) }
        let o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b)
        return (o1 * o2 <= 0) && (o3 * o4 <= 0) && !(o1 == 0 && o2 == 0 && o3 == 0 && o4 == 0)
    }

    /// Share of the playable rectangle inside each region, for the header (§12).
    func areaShares(of playable: Rect2D) -> [(id: String, share: Double)] {
        let total = playable.width * playable.height
        var out: [(String, Double)] = []
        for r in regions where r.bounds.intersects(playable) {
            var a = 0.0
            for poly in r.polygons {
                guard let c = Clipping.clip(poly, to: playable) else { continue }
                a += abs(RingMath.signedArea(c.outer)) - c.holes.reduce(0) { $0 + abs(RingMath.signedArea($1)) }
            }
            let share = MapJSON.round3(a / total)
            if share > 0 { out.append((r.id, share)) }
        }
        return out
    }
}

enum MapLayerError: Error, CustomStringConvertible {
    case badInput(String)
    var description: String {
        switch self { case .badInput(let s): "map layer: \(s)" }
    }
}
