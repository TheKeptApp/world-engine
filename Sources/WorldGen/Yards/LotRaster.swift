import Foundation
import simd
import WorldGeo

/// A grid of what the ground is used for, and which building's yard each open cell belongs to.
///
/// Yards are inferred: every open cell goes to the nearest yard-owning building by a walk that
/// never crosses roads, walkways or blocked land and stops at that building's maximum lot depth.
/// The result is a dressing aid (lawn tone, walks, planting), never a parcel boundary.
struct LotRaster {
    enum Use: UInt8 {
        case open = 0
        /// Carriageway, alley.
        case road = 1
        /// Sidewalk, footway, path, crossing.
        case walkway = 2
        /// Parks, water, pitches, parking: not yard.
        case blocked = 3
        case building = 4
        /// Generated walk, driveway or bed (no trees or shrubs).
        case hard = 5
    }

    let origin: LocalPoint
    let res: Double
    let w: Int
    let h: Int
    var use: [UInt8]
    /// Building index for building cells, -1 elsewhere.
    var buildingOf: [Int32]
    /// Yard owner (building index) for open cells, -1 if none.
    var owner: [Int32]

    init(bounds: Rect2D, resolution: Double = 1) {
        origin = bounds.min
        res = resolution
        w = max(1, Int((bounds.width / resolution).rounded(.up)))
        h = max(1, Int((bounds.height / resolution).rounded(.up)))
        use = [UInt8](repeating: Use.open.rawValue, count: w * h)
        buildingOf = [Int32](repeating: -1, count: w * h)
        owner = [Int32](repeating: -1, count: w * h)
    }

    @inline(__always) func index(_ i: Int, _ j: Int) -> Int { j * w + i }
    @inline(__always) func center(_ i: Int, _ j: Int) -> LocalPoint { origin + LocalPoint((Double(i) + 0.5) * res, (Double(j) + 0.5) * res) }

    func cell(_ p: LocalPoint) -> (Int, Int)? {
        let i = Int(((p.x - origin.x) / res).rounded(.down)), j = Int(((p.y - origin.y) / res).rounded(.down))
        return i >= 0 && j >= 0 && i < w && j < h ? (i, j) : nil
    }

    func useAt(_ p: LocalPoint) -> Use? { cell(p).map { Use(rawValue: use[index($0.0, $0.1)])! } }
    func ownerAt(_ p: LocalPoint) -> Int32 { cell(p).map { owner[index($0.0, $0.1)] } ?? -1 }

    /// Cell index range covering a rectangle (clamped).
    func range(_ r: Rect2D) -> (ClosedRange<Int>, ClosedRange<Int>)? {
        let i0 = max(0, Int(((r.min.x - origin.x) / res).rounded(.down))), i1 = min(w - 1, Int(((r.max.x - origin.x) / res).rounded(.down)))
        let j0 = max(0, Int(((r.min.y - origin.y) / res).rounded(.down))), j1 = min(h - 1, Int(((r.max.y - origin.y) / res).rounded(.down)))
        return i0 <= i1 && j0 <= j1 ? (i0...i1, j0...j1) : nil
    }

    mutating func fill(_ polygon: Polygon2D, _ u: Use, building: Int32 = -1) {
        guard let (ri, rj) = range(polygon.bounds) else { return }
        for j in rj { for i in ri where polygon.contains(center(i, j)) {
            let k = index(i, j)
            use[k] = u.rawValue
            buildingOf[k] = building
        } }
    }

    /// Marks cells within `width / 2` of a polyline, without overwriting buildings.
    mutating func fill(line: [LocalPoint], width: Double, _ u: Use) {
        let hw = width / 2
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len2 = max(simd_length_squared(d), 1e-12)
            guard let (ri, rj) = range(Rect2D(enclosing: [a, b]).expanded(by: hw + res)) else { continue }
            for j in rj { for i in ri {
                let p = center(i, j)
                let t = min(1, max(0, simd_dot(p - a, d) / len2))
                guard simd_distance(p, a + d * t) <= hw else { continue }
                let k = index(i, j)
                if use[k] != Use.building.rawValue { use[k] = u.rawValue }
            } }
        }
    }

    /// Grows yards from the cells of the seed buildings over open ground (8-neighbor shortest
    /// paths), each up to its own maximum distance. Ties go to the lower building index.
    mutating func assignYards(maxDistance: [Int32: Double]) {
        var dist = [Float](repeating: .infinity, count: w * h)
        var heap = CellHeap()
        for k in 0..<(w * h) where use[k] == Use.building.rawValue && maxDistance[buildingOf[k]] != nil {
            dist[k] = 0
            owner[k] = buildingOf[k]
            heap.push(0, Int32(k), owner: buildingOf[k])
        }
        let steps: [(Int, Int, Float)] = [(1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1), (1, 1, 1.4142), (1, -1, 1.4142), (-1, 1, 1.4142), (-1, -1, 1.4142)]
        let r = Float(res)
        while let (d, k, o) = heap.pop() {
            guard d <= dist[Int(k)], owner[Int(k)] == o else { continue }
            let limit = Float(maxDistance[o] ?? 0)
            let i = Int(k) % w, j = Int(k) / w
            for (di, dj, c) in steps {
                let ni = i + di, nj = j + dj
                guard ni >= 0, nj >= 0, ni < w, nj < h else { continue }
                let nk = index(ni, nj)
                guard use[nk] == Use.open.rawValue else { continue }
                // Diagonal moves may not slip between two non-open cells.
                if di != 0, dj != 0, use[index(i + di, j)] != Use.open.rawValue && use[index(i + di, j)] != Use.building.rawValue,
                   use[index(i, j + dj)] != Use.open.rawValue && use[index(i, j + dj)] != Use.building.rawValue { continue }
                let nd = d + c * r
                guard nd <= limit else { continue }
                if nd < dist[nk] || (nd == dist[nk] && o < owner[nk]) {
                    dist[nk] = nd
                    owner[nk] = o
                    heap.push(nd, Int32(nk), owner: o)
                }
            }
        }
        // Building cells keep their owner only if they seeded a yard.
        for k in 0..<(w * h) where use[k] == Use.building.rawValue && maxDistance[buildingOf[k]] == nil { owner[k] = -1 }
    }

    /// Outer outlines of the cells where `inside` holds within a cell range, as CCW rings on cell
    /// borders, simplified to `tolerance` (staircases become straight lines).
    func outlines(_ ri: ClosedRange<Int>, _ rj: ClosedRange<Int>, tolerance: Double, inside: (Int) -> Bool) -> [Ring] {
        func isIn(_ i: Int, _ j: Int) -> Bool { i >= ri.lowerBound && i <= ri.upperBound && j >= rj.lowerBound && j <= rj.upperBound && inside(index(i, j)) }
        // Directed border edges with the inside on the left, keyed by start corner.
        var edges: [SIMD2<Int32>: [SIMD2<Int32>]] = [:]
        func add(_ a: SIMD2<Int32>, _ b: SIMD2<Int32>) { edges[a, default: []].append(b) }
        for j in rj { for i in ri where isIn(i, j) {
            let x = Int32(i), y = Int32(j)
            if !isIn(i, j - 1) { add(SIMD2(x, y), SIMD2(x + 1, y)) }
            if !isIn(i + 1, j) { add(SIMD2(x + 1, y), SIMD2(x + 1, y + 1)) }
            if !isIn(i, j + 1) { add(SIMD2(x + 1, y + 1), SIMD2(x, y + 1)) }
            if !isIn(i - 1, j) { add(SIMD2(x, y + 1), SIMD2(x, y)) }
        } }
        var rings: [Ring] = []
        while let start = edges.keys.min(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
            var corners: [SIMD2<Int32>] = [start]
            var prev = start
            var cur = edges[start]!.removeFirst()
            if edges[start]!.isEmpty { edges[start] = nil }
            var guardSteps = 0
            while cur != start, guardSteps < 1_000_000 {
                guardSteps += 1
                corners.append(cur)
                guard var outs = edges[cur], !outs.isEmpty else { break }
                // At a pinch (regions touching at a corner) take the leftmost turn.
                let din = cur &- prev
                var best = 0
                if outs.count > 1 {
                    func turn(_ o: SIMD2<Int32>) -> Int32 {
                        let dout = o &- cur
                        return din.x * dout.y - din.y * dout.x
                    }
                    best = outs.indices.max { turn(outs[$0]) < turn(outs[$1]) }!
                }
                let next = outs.remove(at: best)
                edges[cur] = outs.isEmpty ? nil : outs
                prev = cur
                cur = next
            }
            var ring = corners.map { origin + LocalPoint(Double($0.x), Double($0.y)) * res }
            ring = Self.simplify(ring, tolerance: tolerance)
            if ring.count >= 3, RingMath.signedArea(ring) > 0 { rings.append(ring) }
        }
        return rings
    }

    /// Douglas-Peucker on a closed ring (anchored at its two farthest-apart corners).
    static func simplify(_ ring: Ring, tolerance: Double) -> Ring {
        guard ring.count > 4 else { return ring }
        var a = 0, b = 0, far = 0.0
        for i in ring.indices { let d = simd_distance_squared(ring[0], ring[i]); if d > far { far = d; b = i } }
        far = 0
        for i in ring.indices { let d = simd_distance_squared(ring[b], ring[i]); if d > far { far = d; a = i } }
        let (lo, hi) = (min(a, b), max(a, b))
        func dp(_ pts: [LocalPoint]) -> [LocalPoint] {
            guard pts.count > 2 else { return pts }
            let s = pts[0], e = pts[pts.count - 1]
            let d = e - s
            let len = max(simd_length(d), 1e-12)
            var idx = 0, maxD = 0.0
            for i in 1..<(pts.count - 1) {
                let dist = abs(RingMath.cross(d, pts[i] - s)) / len
                if dist > maxD { maxD = dist; idx = i }
            }
            if maxD <= tolerance { return [s, e] }
            return Array(dp(Array(pts[0...idx])).dropLast()) + dp(Array(pts[idx...]))
        }
        let first = dp(Array(ring[lo...hi]))
        let second = dp(Array(ring[hi...]) + Array(ring[...lo]))
        return Array(first.dropLast()) + Array(second.dropLast())
    }
}

/// Min-heap of (distance, cell, owner) for the yard growth.
struct CellHeap {
    private var items: [(Float, Int32, Int32)] = []
    mutating func push(_ d: Float, _ k: Int32, owner: Int32) {
        items.append((d, k, owner))
        var c = items.count - 1
        while c > 0 {
            let p = (c - 1) / 2
            if items[p].0 <= items[c].0 { break }
            items.swapAt(p, c)
            c = p
        }
    }
    mutating func pop() -> (Float, Int32, Int32)? {
        guard !items.isEmpty else { return nil }
        let top = items[0]
        let last = items.removeLast()
        if !items.isEmpty {
            items[0] = last
            var p = 0
            while true {
                let l = 2 * p + 1, r = l + 1
                var m = p
                if l < items.count, items[l].0 < items[m].0 { m = l }
                if r < items.count, items[r].0 < items[m].0 { m = r }
                if m == p { break }
                items.swapAt(p, m)
                p = m
            }
        }
        return top
    }
}
