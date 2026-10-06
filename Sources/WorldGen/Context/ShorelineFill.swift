import Foundation
import simd
import WorldGeo

/// Water bounded by open shorelines inside a box (context rings, look-fix-v1 §4: real shoreline only).
///
/// A large lake or sea arrives as open shoreline pieces: `natural=coastline` ways (land on the left
/// of the way, water on the right) or the member ways of a water relation too large to fetch whole
/// (only the members touching the box are present, and their direction is not guaranteed). Each
/// piece that crosses the box splits it; walking the box edge between pieces closes the regions
/// they bound (regions alternate water and land across every piece). The water regions follow the
/// mapped shoreline exactly and the box edge on the water side: no shoreline is invented, and a
/// piece that ends inside the box (incomplete data) is dropped rather than closed by guessing.
enum ShorelineFill {
    /// Which side of the pieces is water.
    enum Side: Sendable {
        /// Water on the right of the piece's direction (OSM `natural=coastline`).
        case right
        /// Unknown (multipolygon member ways): decided by `landEvidence`, the side with fewer land
        /// features (roads, buildings) is water; on a tie, the side without `fallbackLand`.
        case unknown(landEvidence: [LocalPoint], fallbackLand: LocalPoint)
    }

    struct Result {
        var water: [Polygon2D] = []
        /// Pieces crossing the box that were used.
        var pieces = 0
        /// Pieces that end inside the box (open data), not used.
        var dropped = 0
    }

    /// Water regions inside `box` bounded by `lines` (open polylines in local metres, any extent;
    /// clipped here) and the box edge. `holes` (closed rings inside water: islands) are cut out of
    /// the water region that contains them.
    static func fill(box: Rect2D, lines: [[LocalPoint]], side: Side, holes: [Ring] = []) -> Result {
        var result = Result()
        let eps = max(box.width, box.height) * 1e-9 + 1e-6
        func onEdge(_ p: LocalPoint) -> Bool {
            abs(p.x - box.min.x) <= eps || abs(p.x - box.max.x) <= eps || abs(p.y - box.min.y) <= eps || abs(p.y - box.max.y) <= eps
        }
        var chords: [[LocalPoint]] = []
        for line in lines {
            for piece in Clipping.clip(polyline: line, to: box) {
                guard let a = piece.first, let b = piece.last else { continue }
                if !onEdge(a) || !onEdge(b) { result.dropped += 1; continue }
                if simd_distance(a, b) < 1e-6 && piece.count < 3 { continue }
                chords.append(piece)
            }
        }
        result.pieces = chords.count
        guard !chords.isEmpty else { return result }

        // Box perimeter, counter-clockwise from the minimum corner.
        let w = box.width, h = box.height, perimeter = 2 * (w + h)
        func param(_ p: LocalPoint) -> Double {
            let d = [abs(p.y - box.min.y), abs(p.x - box.max.x), abs(p.y - box.max.y), abs(p.x - box.min.x)]
            let edge = d.indices.min { d[$0] < d[$1] }!
            switch edge {
            case 0: return min(max(p.x - box.min.x, 0), w)
            case 1: return w + min(max(p.y - box.min.y, 0), h)
            case 2: return w + h + min(max(box.max.x - p.x, 0), w)
            default: return (2 * w + h + min(max(box.max.y - p.y, 0), h)).truncatingRemainder(dividingBy: perimeter)
            }
        }
        let corners: [(Double, LocalPoint)] = [(0, box.min), (w, LocalPoint(box.max.x, box.min.y)), (w + h, box.max),
                                               (2 * w + h, LocalPoint(box.min.x, box.max.y))]
        // Endpoints sorted counter-clockwise: (position, chord, isStart).
        var ends: [(s: Double, chord: Int, start: Bool)] = []
        for (i, c) in chords.enumerated() {
            ends.append((param(c[0]), i, true))
            ends.append((param(c[c.count - 1]), i, false))
        }
        ends.sort { ($0.s, $0.chord, $0.start ? 0 : 1) < ($1.s, $1.chord, $1.start ? 0 : 1) }
        var slot: [Int: Int] = [:]   // chord * 2 + (start ? 0 : 1) → index in `ends`
        for (k, e) in ends.enumerated() { slot[e.chord * 2 + (e.start ? 0 : 1)] = k }

        // Regions: follow a chord (start→end = forward), then the perimeter counter-clockwise to the
        // next endpoint, then that chord away from it, until back at the start. Each region lies on
        // the left of every chord traversal that bounds it.
        var used = Set<Int>()            // half-edges: chord * 2 + (forward ? 0 : 1)
        var regions: [(ring: Ring, halfEdges: [Int])] = []
        for first in 0..<(chords.count * 2) where !used.contains(first) {
            var ring: Ring = [], edges: [Int] = []
            var he = first
            var guardCount = 0
            while !used.contains(he), guardCount <= chords.count * 2 {
                guardCount += 1
                used.insert(he)
                edges.append(he)
                let chord = he / 2, forward = he % 2 == 0
                let pts = forward ? chords[chord] : chords[chord].reversed()
                ring.append(contentsOf: pts)
                // Arrived at this endpoint of the chord: its end if forward, its start if backward.
                let k = slot[chord * 2 + (forward ? 1 : 0)]!
                let next = ends[(k + 1) % ends.count]
                // Box corners passed on the way (counter-clockwise from s0 to s1).
                let s0 = ends[k].s, s1 = next.s
                var span = s1 - s0
                if span < 0 || (span == 0 && (k + 1) % ends.count <= k) { span += perimeter }
                let passed = corners.map { (cs, c) -> (Double, LocalPoint) in
                    var d = cs - s0
                    if d < 0 { d += perimeter }
                    return (d, c)
                }.filter { $0.0 > 0 && $0.0 < span }.sorted { $0.0 < $1.0 }
                ring.append(contentsOf: passed.map(\.1))
                // Continue along the next chord away from the endpoint reached.
                he = next.chord * 2 + (next.start ? 0 : 1)
            }
            if ring.count >= 3 { regions.append((ring, edges)) }
        }

        // Label: regions on either side of a chord differ.
        var regionOf: [Int: Int] = [:]
        for (r, region) in regions.enumerated() { for he in region.halfEdges { regionOf[he] = r } }
        var water = [Bool?](repeating: nil, count: regions.count)
        switch side {
        case .right:
            // The backward traversal of a coastline piece has the water on its left.
            for (r, region) in regions.enumerated() { water[r] = region.halfEdges.first.map { $0 % 2 == 1 } }
        case .unknown(let evidence, let fallback):
            // Two-colour the regions (the chords form a tree of regions), then pick the colouring
            // with fewer land features inside the water.
            guard !regions.isEmpty else { break }
            var colour = [Bool?](repeating: nil, count: regions.count)
            for seed in regions.indices where colour[seed] == nil {
                colour[seed] = true
                var queue = [seed]
                while let r = queue.popLast() {
                    for he in regions[r].halfEdges {
                        guard let other = regionOf[he ^ 1], colour[other] == nil else { continue }
                        colour[other] = !colour[r]!
                        queue.append(other)
                    }
                }
            }
            let polys = regions.map { Polygon2D(outer: $0.ring) }
            let bounds = polys.map(\.bounds)
            func region(of p: LocalPoint) -> Int? {
                polys.indices.first { bounds[$0].contains(p) && RingMath.contains(polys[$0].outer, p) }
            }
            var landInTrue = 0, landInFalse = 0
            for p in evidence where box.contains(p) {
                guard let r = region(of: p) else { continue }
                if colour[r] == true { landInTrue += 1 } else { landInFalse += 1 }
            }
            // `true` regions are water if fewer land features fall in them.
            var trueIsWater = landInTrue < landInFalse
            if landInTrue == landInFalse, let r = region(of: fallback) { trueIsWater = colour[r] == false }
            for r in regions.indices { water[r] = colour[r].map { $0 == trueIsWater } }
        }

        for (r, region) in regions.enumerated() where water[r] == true {
            var poly = Polygon2D(outer: region.ring)
            for hole in holes where hole.count >= 3 && RingMath.contains(region.ring, hole[0]) { poly.holes.append(hole) }
            if let clean = poly.cleaned(minArea: 1) { result.water.append(clean) }
        }
        return result
    }

    /// Joins open way chains (node IDs) end to end. `directed`: only end-to-start (coastline);
    /// otherwise either way round (multipolygon members). Returns closed rings (first == last)
    /// and open chains.
    static func join(_ chains: [[Int64]], directed: Bool) -> (closed: [[Int64]], open: [[Int64]]) {
        var remaining = chains.filter { $0.count >= 2 }
        var closed: [[Int64]] = [], open: [[Int64]] = []
        while var current = remaining.popLast() {
            var grew = true
            while current.first != current.last, grew {
                grew = false
                let tail = current.last!, head = current.first!
                if let i = remaining.firstIndex(where: { $0.first == tail || (!directed && $0.last == tail) }) {
                    let next = remaining.remove(at: i)
                    current += (next.first == tail ? next : next.reversed()).dropFirst()
                    grew = true
                } else if let i = remaining.firstIndex(where: { $0.last == head || (!directed && $0.first == head) }) {
                    let prev = remaining.remove(at: i)
                    current = (prev.last == head ? prev : prev.reversed()) + current.dropFirst()
                    grew = true
                }
            }
            if current.first == current.last, current.count >= 4 { closed.append(current) } else { open.append(current) }
        }
        return (closed, open)
    }
}
