import Foundation
import simd
import WorldGeo
import WorldMap

/// Grid-bucketed line segments for nearest-line queries.
public struct SegmentIndex: Sendable {
    public struct Hit: Sendable {
        public var point: LocalPoint
        public var distance: Double
        /// Index of the source polyline in the array passed to `init`.
        public var line: Int
        /// Unit direction of the segment hit.
        public var direction: LocalPoint
    }

    let cell: Double
    var buckets: [SIMD2<Int32>: [(line: Int, a: LocalPoint, b: LocalPoint)]] = [:]

    public init(_ lines: [[LocalPoint]], cell: Double = 40) {
        self.cell = cell
        for (li, line) in lines.enumerated() {
            for (a, b) in zip(line, line.dropFirst()) where a != b {
                let lo = simd_min(a, b), hi = simd_max(a, b)
                for x in key(lo.x)...key(hi.x) { for y in key(lo.y)...key(hi.y) {
                    buckets[SIMD2(x, y), default: []].append((li, a, b))
                } }
            }
        }
    }

    func key(_ v: Double) -> Int32 { Int32((v / cell).rounded(.down)) }

    /// Nearest segment point within `radius`, optionally filtered by line index.
    public func nearest(to p: LocalPoint, within radius: Double, where include: (Int) -> Bool = { _ in true }) -> Hit? {
        var best: Hit?
        let r = Int32((radius / cell).rounded(.up))
        let kx = key(p.x), ky = key(p.y)
        for x in (kx - r)...(kx + r) { for y in (ky - r)...(ky + r) {
            for s in buckets[SIMD2(x, y)] ?? [] where include(s.line) {
                let d = s.b - s.a
                let len2 = simd_length_squared(d)
                let t = len2 > 0 ? min(1, max(0, simd_dot(p - s.a, d) / len2)) : 0
                let q = s.a + d * t
                let dist = simd_distance(p, q)
                if dist <= radius, dist < (best?.distance ?? .infinity) {
                    best = Hit(point: q, distance: dist, line: s.line, direction: d / len2.squareRoot())
                }
            }
        } }
        return best
    }
}

/// Streets, alleys and sidewalks around buildings, for orientation and street furniture.
public struct StreetContext: Sendable {
    /// Named vehicle streets (not service roads): where front doors face.
    public let streets: [WayFeature]
    /// Alleys and other service roads: where detached garage doors face.
    public let alleys: [WayFeature]
    /// All vehicle roads (for curbs and intersections).
    public let roads: [WayFeature]
    public let sidewalks: [WayFeature]
    public let streetIndex: SegmentIndex
    public let alleyIndex: SegmentIndex
    public let roadIndex: SegmentIndex
    public let sidewalkIndex: SegmentIndex

    public init(_ f: MapFeatures) {
        roads = f.roads
        streets = f.roads.filter { $0.kind != .service && $0.kind != .track && $0.tags["name"] != nil }
        alleys = f.roads.filter { $0.kind == .service || ($0.tags["name"] == nil && $0.kind != .track) }
        sidewalks = f.sidewalks
        streetIndex = SegmentIndex(streets.map(\.centerline))
        alleyIndex = SegmentIndex(alleys.map(\.centerline))
        roadIndex = SegmentIndex(roads.map(\.centerline))
        sidewalkIndex = SegmentIndex(sidewalks.map(\.centerline))
    }

    /// Which footprint edge faces the nearest named street (front door side), or nil if no street
    /// is within `radius`. Edges shorter than 2.5 m are ignored.
    public func frontEdge(of ring: Ring, radius: Double = 60) -> Int? {
        bestEdge(of: ring, index: streetIndex, radius: radius)
    }

    /// Which edge faces the nearest alley/service road within `radius`.
    public func alleyEdge(of ring: Ring, radius: Double = 30) -> Int? {
        bestEdge(of: ring, index: alleyIndex, radius: radius)
    }

    func bestEdge(of ring: Ring, index: SegmentIndex, radius: Double) -> Int? {
        let c = RingMath.centroid(ring)
        guard let target = index.nearest(to: c, within: radius) else { return nil }
        var best: (i: Int, score: Double)?
        for i in 0..<ring.count {
            let p = ring[i], q = ring[(i + 1) % ring.count]
            let d = q - p
            let len = simd_length(d)
            guard len >= 2.5 else { continue }
            let normal = LocalPoint(d.y, -d.x) / len // outward for a CCW ring
            let mid = (p + q) / 2
            // Nearest point on the *same* road line from this edge.
            guard let hit = index.nearest(to: mid, within: radius + 20, where: { $0 == target.line }) else { continue }
            let toRoad = hit.point - mid
            let dist = simd_length(toRoad)
            let facing = dist > 1e-6 ? simd_dot(normal, toRoad / dist) : 0
            let score = facing * min(len, 8) / 8 / (1 + dist / 30)
            if score > (best?.score ?? 0.05) { best = (i, score) }
        }
        return best?.i
    }
}
