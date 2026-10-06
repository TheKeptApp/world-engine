import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// Polyline helpers.
enum Polyline {
    static func length(_ l: [LocalPoint]) -> Double {
        zip(l, l.dropFirst()).reduce(0) { $0 + simd_distance($1.0, $1.1) }
    }

    /// Offsets a polyline sideways by `d` meters (positive = left of travel), mitered joins.
    static func offset(_ l: [LocalPoint], by d: Double) -> [LocalPoint] {
        guard l.count >= 2 else { return l }
        func n(_ k: Int) -> LocalPoint {
            let v = simd_normalize(l[k + 1] - l[k])
            return LocalPoint(-v.y, v.x)
        }
        return l.indices.map { i in
            if i == 0 { return l[0] + n(0) * d }
            if i == l.count - 1 { return l[i] + n(i - 1) * d }
            let m = n(i - 1) + n(i)
            let len = simd_length(m)
            guard len > 1e-6 else { return l[i] + n(i) * d }
            let mu = m / len
            let scale = min(2.5, 1 / max(0.2, simd_dot(mu, n(i))))
            return l[i] + mu * (d * scale)
        }
    }

    /// Resamples a polyline at roughly `step` meters, returning points with their direction.
    static func resample(_ l: [LocalPoint], step: Double) -> [(LocalPoint, LocalPoint)] {
        var out: [(LocalPoint, LocalPoint)] = []
        for (a, b) in zip(l, l.dropFirst()) {
            let d = b - a
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            let dir = d / len
            let n = max(1, Int((len / step).rounded(.up)))
            for k in 0..<n { out.append((a + d * (Double(k) / Double(n)), dir)) }
        }
        if let last = l.last, l.count >= 2 { out.append((last, simd_normalize(last - l[l.count - 2]))) }
        return out
    }

    /// Douglas–Peucker on an open polyline: keeps the ends and every point farther than
    /// `tolerance` metres from the simplified line (bends survive, straight runs collapse).
    static func simplify(_ l: [LocalPoint], tolerance: Double) -> [LocalPoint] {
        guard l.count > 2 else { return l }
        var keep = [Bool](repeating: false, count: l.count)
        keep[0] = true
        keep[l.count - 1] = true
        var stack = [(0, l.count - 1)]
        while let (i, j) = stack.popLast() {
            guard j > i + 1 else { continue }
            let a = l[i], d = l[j] - a, len = simd_length(d)
            var worst = -1.0, at = i
            for k in (i + 1)..<j {
                let v = l[k] - a
                let dist = len > 1e-9 ? abs(d.x * v.y - d.y * v.x) / len : simd_length(v)
                if dist > worst { worst = dist; at = k }
            }
            if worst > tolerance {
                keep[at] = true
                stack.append((i, at))
                stack.append((at, j))
            }
        }
        return l.indices.filter { keep[$0] }.map { l[$0] }
    }

    /// Splits `points` into runs where `keep` is true; runs shorter than `minLength` are dropped.
    static func runs(_ points: [LocalPoint], keep: [Bool], minLength: Double) -> [[LocalPoint]] {
        var out: [[LocalPoint]] = [], cur: [LocalPoint] = []
        for (p, k) in zip(points, keep) {
            if k { cur.append(p) } else {
                if cur.count >= 2, length(cur) >= minLength { out.append(cur) }
                cur = []
            }
        }
        if cur.count >= 2, length(cur) >= minLength { out.append(cur) }
        return out
    }
}

/// Point-in-polygon lookups over many polygons (buildings, water).
public struct PolygonIndex: Sendable {
    let cell = 25.0
    var polys: [Polygon2D] = []
    var buckets: [SIMD2<Int32>: [Int]] = [:]

    public init(_ polygons: [Polygon2D]) {
        polys = polygons
        for (i, p) in polygons.enumerated() {
            let b = p.bounds
            for x in key(b.min.x)...key(b.max.x) { for y in key(b.min.y)...key(b.max.y) { buckets[SIMD2(x, y), default: []].append(i) } }
        }
    }

    func key(_ v: Double) -> Int32 { Int32((v / cell).rounded(.down)) }

    public func contains(_ p: LocalPoint, margin: Double = 0) -> Bool {
        for i in buckets[SIMD2(key(p.x), key(p.y))] ?? [] {
            let poly = polys[i]
            if margin > 0 ? poly.bounds.expanded(by: margin).contains(p) && (poly.contains(p) || Self.near(poly.outer, p, margin)) : poly.contains(p) {
                return true
            }
        }
        return false
    }

    static func near(_ ring: Ring, _ p: LocalPoint, _ r: Double) -> Bool {
        for i in 0..<ring.count {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            let d = b - a
            let t = max(0, min(1, simd_dot(p - a, d) / max(simd_length_squared(d), 1e-12)))
            if simd_distance(p, a + d * t) < r { return true }
        }
        return false
    }
}

/// Curbs, generated sidewalks and generated street lamps.
public struct Streetscape: Sendable {
    public var context: StreetContext
    public var buildings: PolygonIndex

    public static let sidewalkSearchRadius = 15.0
    public static let lampSpacing = 38.0

    /// Roads that get curbs and sidewalks (not alleys, driveways or tracks).
    static func isStreet(_ r: WayFeature) -> Bool {
        [.residential, .livingStreet, .unclassified, .tertiary, .secondary, .primary, .trunk].contains(r.kind)
    }

    func blockedByOtherRoad(_ p: LocalPoint, own: Int, extra: Double) -> Bool {
        guard let hit = context.roadIndex.nearest(to: p, within: 12 + extra, where: { $0 != own }) else { return false }
        return hit.distance < context.roads[hit.line].width / 2 + extra
    }

    /// Curb lines (both edges of each street), cut at intersections and driveways.
    public func curbLines(roadIndex i: Int, piece: [LocalPoint]) -> [[LocalPoint]] {
        let road = context.roads[i]
        guard Self.isStreet(road) else { return [] }
        var out: [[LocalPoint]] = []
        for side in [-1.0, 1.0] {
            let edge = Polyline.offset(piece, by: side * road.width / 2)
            let samples = Polyline.resample(edge, step: 1.0).map(\.0)
            let keep = samples.map { !blockedByOtherRoad($0, own: i, extra: 0.6) }
            // The 1 m samples find the cuts at intersections; the curb itself only needs points at
            // bends (P1's budget audit: curbs cost 12 triangles per street metre at 1 m).
            out += Polyline.runs(samples, keep: keep, minLength: 2).map { Polyline.simplify($0, tolerance: 0.03) }
        }
        return out
    }

    /// Generated sidewalk centerlines for one street piece, using the 15 m rule: generate only
    /// where no mapped sidewalk runs parallel within 15 m (or where the road is tagged with a
    /// sidewalk), never where tags say none or separate.
    public func generatedSidewalks(roadIndex i: Int, piece: [LocalPoint]) -> [[LocalPoint]] {
        let road = context.roads[i]
        guard Self.isStreet(road), road.kind != .primary, road.kind != .trunk else { return [] }
        var out: [[LocalPoint]] = []
        for (side, state) in [(1.0, road.sidewalkLeft), (-1.0, road.sidewalkRight)] {
            if state == .none || state == .separate { continue }
            let line = Polyline.offset(piece, by: side * (road.width / 2 + 2.2))
            let samples = Polyline.resample(line, step: 2.0)
            let keep = samples.map { (p, dir) -> Bool in
                if blockedByOtherRoad(p, own: i, extra: 2.0) { return false }
                if buildings.contains(p, margin: 0.5) { return false }
                if state == .tagged { return true }
                // A mapped sidewalk counts only if it's parallel and on this side of the street.
                guard let roadPoint = context.roadIndex.nearest(to: p, within: road.width + 10, where: { $0 == i })?.point else { return true }
                if let hit = context.sidewalkIndex.nearest(to: p, within: Self.sidewalkSearchRadius),
                   abs(simd_dot(hit.direction, dir)) > 0.7,
                   simd_dot(hit.point - roadPoint, p - roadPoint) > 0 {
                    return false
                }
                return true
            }
            out += Polyline.runs(samples.map(\.0), keep: keep, minLength: 8)
        }
        return out
    }

    /// Generated lamp positions (with the direction the lamp faces the road) along one street,
    /// skipping places near mapped or already-placed lamps, intersections, driveways and buildings.
    public func generatedLamps(roadIndex i: Int, piece: [LocalPoint], existing: inout [LocalPoint]) -> [(LocalPoint, LocalPoint)] {
        let road = context.roads[i]
        guard [.residential, .livingStreet, .unclassified, .tertiary].contains(road.kind), road.tags["name"] != nil else { return [] }
        var rng = road.ref.random("lamps")
        var out: [(LocalPoint, LocalPoint)] = []
        var along = rng.range(0, Self.lampSpacing / 2)
        var side = rng.chance(0.5) ? 1.0 : -1.0
        let samples = Polyline.resample(piece, step: 1.0)
        var traveled = 0.0
        for k in 1..<max(1, samples.count) {
            traveled += simd_distance(samples[k - 1].0, samples[k].0)
            guard traveled >= along else { continue }
            let (p, dir) = samples[k]
            let normal = LocalPoint(-dir.y, dir.x) * side
            let spot = p + normal * (road.width / 2 + 0.7)
            let ok = !blockedByOtherRoad(p, own: i, extra: 9)
                && !buildings.contains(spot, margin: 1.0)
                && !existing.contains { simd_distance($0, spot) < 20 }
            if ok {
                out.append((spot, -normal))
                existing.append(spot)
                along = traveled + Self.lampSpacing
                side = -side
            } else {
                along = traveled + 4
            }
        }
        return out
    }
}
