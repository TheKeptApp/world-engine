// Swift port of earcut 2.2.4 (https://github.com/mapbox/earcut), without the z-order hash
// used for very large polygons.
//
// ISC License
// Copyright (c) 2016, Mapbox
//
// Permission to use, copy, modify, and/or distribute this software for any purpose
// with or without fee is hereby granted, provided that the above copyright notice
// and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH REGARD TO
// THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
// IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
// DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
// WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
// OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

import WorldGeo

/// Ear-clipping triangulation of polygons with holes.
public enum Earcut {
    /// Triangulates flat `[x0, y0, x1, y1, ...]` coordinates. `holeIndices` are the vertex
    /// indices where each hole starts. Returns vertex indices, three per triangle, wound the same
    /// way as a counter-clockwise outer ring (whatever the input winding).
    public static func triangulate(_ data: [Double], holeIndices: [Int] = []) -> [Int] {
        var list = LinkedPolygon()
        var triangles: [Int] = []
        let outerLen = holeIndices.first.map { $0 * 2 } ?? data.count
        guard var outer = list.linkedList(data, 0, outerLen, clockwise: true),
              list.next[outer] != list.prev[outer] else { return [] }
        if !holeIndices.isEmpty {
            outer = list.eliminateHoles(data, holeIndices, outer)
        }
        list.earcutLinked(outer, &triangles, pass: 0)
        return triangles
    }

    /// Triangulates a polygon. Returns its vertices (outer ring, then holes) and triangle indices.
    public static func triangulate(_ polygon: Polygon2D) -> (vertices: [LocalPoint], indices: [Int]) {
        var vertices = polygon.outer
        var holeIndices: [Int] = []
        for h in polygon.holes {
            holeIndices.append(vertices.count)
            vertices += h
        }
        var flat: [Double] = []
        flat.reserveCapacity(vertices.count * 2)
        for v in vertices { flat.append(v.x); flat.append(v.y) }
        return (vertices, triangulate(flat, holeIndices: holeIndices))
    }
}

/// The circular doubly-linked vertex list earcut works on, stored as parallel arrays.
private struct LinkedPolygon {
    var x: [Double] = []
    var y: [Double] = []
    var vertex: [Int] = []
    var prev: [Int] = []
    var next: [Int] = []
    var steiner: [Bool] = []

    // MARK: List operations

    mutating func createNode(_ i: Int, _ px: Double, _ py: Double) -> Int {
        let p = x.count
        x.append(px); y.append(py); vertex.append(i); steiner.append(false)
        prev.append(p); next.append(p)
        return p
    }

    mutating func insertNode(_ i: Int, _ px: Double, _ py: Double, after last: Int?) -> Int {
        let p = createNode(i, px, py)
        if let last {
            let ln = next[last]
            next[p] = ln
            prev[p] = last
            prev[ln] = p
            next[last] = p
        }
        return p
    }

    mutating func removeNode(_ p: Int) {
        next[prev[p]] = next[p]
        prev[next[p]] = prev[p]
    }

    /// Links a ring, reversing it if needed so its orientation matches `clockwise`
    /// (earcut's "clockwise" means counter-clockwise in a y-up frame).
    mutating func linkedList(_ data: [Double], _ start: Int, _ end: Int, clockwise: Bool) -> Int? {
        var last: Int?
        if clockwise == (signedArea(data, start, end) > 0) {
            for i in stride(from: start, to: end, by: 2) {
                last = insertNode(i / 2, data[i], data[i + 1], after: last)
            }
        } else {
            for i in stride(from: end - 2, through: start, by: -2) {
                last = insertNode(i / 2, data[i], data[i + 1], after: last)
            }
        }
        if let l = last, equals(l, next[l]) {
            removeNode(l)
            last = next[l]
        }
        return last
    }

    /// Removes duplicate and collinear points.
    mutating func filterPoints(_ start: Int, _ endIn: Int? = nil) -> Int {
        var end = endIn ?? start
        var p = start
        var again: Bool
        repeat {
            again = false
            if !steiner[p] && (equals(p, next[p]) || area(prev[p], p, next[p]) == 0) {
                removeNode(p)
                p = prev[p]
                end = p
                if p == next[p] { break }
                again = true
            } else {
                p = next[p]
            }
        } while again || p != end
        return end
    }

    // MARK: Main loop

    mutating func earcutLinked(_ start: Int?, _ triangles: inout [Int], pass: Int) {
        guard var ear = start else { return }
        var stop = ear
        while prev[ear] != next[ear] {
            let p = prev[ear], n = next[ear]
            if isEar(ear) {
                triangles.append(vertex[p])
                triangles.append(vertex[ear])
                triangles.append(vertex[n])
                removeNode(ear)
                ear = next[n]
                stop = next[n]
                continue
            }
            ear = n
            if ear == stop {
                switch pass {
                case 0:
                    earcutLinked(filterPoints(ear), &triangles, pass: 1)
                case 1:
                    let cured = cureLocalIntersections(filterPoints(ear), &triangles)
                    earcutLinked(cured, &triangles, pass: 2)
                default:
                    splitEarcut(ear, &triangles)
                }
                break
            }
        }
    }

    func isEar(_ ear: Int) -> Bool {
        let a = prev[ear], b = ear, c = next[ear]
        if area(a, b, c) >= 0 { return false } // reflex
        let ax = x[a], bx = x[b], cx = x[c], ay = y[a], by = y[b], cy = y[c]
        let x0 = min(ax, bx, cx), y0 = min(ay, by, cy), x1 = max(ax, bx, cx), y1 = max(ay, by, cy)
        var p = next[c]
        while p != a {
            if x[p] >= x0, x[p] <= x1, y[p] >= y0, y[p] <= y1,
               pointInTriangle(ax, ay, bx, by, cx, cy, x[p], y[p]),
               area(prev[p], p, next[p]) >= 0 {
                return false
            }
            p = next[p]
        }
        return true
    }

    /// Clips small local self-intersections.
    mutating func cureLocalIntersections(_ startIn: Int, _ triangles: inout [Int]) -> Int {
        var start = startIn
        var p = start
        repeat {
            let a = prev[p], b = next[next[p]]
            if !equals(a, b), intersects(a, p, next[p], b), locallyInside(a, b), locallyInside(b, a) {
                triangles.append(vertex[a])
                triangles.append(vertex[p])
                triangles.append(vertex[b])
                removeNode(p)
                removeNode(next[p])
                p = b
                start = b
            }
            p = next[p]
        } while p != start
        return filterPoints(p)
    }

    /// Last resort: split the polygon along a valid diagonal and triangulate both halves.
    mutating func splitEarcut(_ start: Int, _ triangles: inout [Int]) {
        var a = start
        repeat {
            var b = next[next[a]]
            while b != prev[a] {
                if vertex[a] != vertex[b], isValidDiagonal(a, b) {
                    let c = splitPolygon(a, b)
                    let a2 = filterPoints(a, next[a])
                    let c2 = filterPoints(c, next[c])
                    earcutLinked(a2, &triangles, pass: 0)
                    earcutLinked(c2, &triangles, pass: 0)
                    return
                }
                b = next[b]
            }
            a = next[a]
        } while a != start
    }

    // MARK: Holes

    mutating func eliminateHoles(_ data: [Double], _ holeIndices: [Int], _ outerIn: Int) -> Int {
        var outer = outerIn
        var queue: [Int] = []
        for (k, h) in holeIndices.enumerated() {
            let start = h * 2
            let end = k < holeIndices.count - 1 ? holeIndices[k + 1] * 2 : data.count
            guard let list = linkedList(data, start, end, clockwise: false) else { continue }
            if list == next[list] { steiner[list] = true }
            queue.append(leftmost(list))
        }
        queue.sort { x[$0] < x[$1] }
        for hole in queue {
            outer = eliminateHole(hole, outer)
        }
        return outer
    }

    mutating func eliminateHole(_ hole: Int, _ outer: Int) -> Int {
        guard let bridge = findHoleBridge(hole, outer) else { return outer }
        let bridgeReverse = splitPolygon(bridge, hole)
        _ = filterPoints(bridgeReverse, next[bridgeReverse])
        return filterPoints(bridge, next[bridge])
    }

    /// David Eberly's algorithm for finding a bridge between a hole and the outer polygon.
    func findHoleBridge(_ hole: Int, _ outer: Int) -> Int? {
        var p = outer
        let hx = x[hole], hy = y[hole]
        var qx = -Double.infinity
        var m: Int?
        // Find the segment hit by a ray from the hole's leftmost point to the left.
        repeat {
            let n = next[p]
            if hy <= y[p], hy >= y[n], y[n] != y[p] {
                let ix = x[p] + (hy - y[p]) * (x[n] - x[p]) / (y[n] - y[p])
                if ix <= hx, ix > qx {
                    qx = ix
                    m = x[p] < x[n] ? p : n
                    if ix == hx { return m } // hole touches the outer segment
                }
            }
            p = n
        } while p != outer
        guard var best = m else { return nil }

        // Look for points inside the triangle (hole point, intersection, endpoint); pick the one
        // with the smallest angle to the ray so the bridge doesn't cross other edges.
        let stop = best
        let mx = x[best], my = y[best]
        var tanMin = Double.infinity
        p = best
        repeat {
            if hx >= x[p], x[p] >= mx, hx != x[p],
               pointInTriangle(hy < my ? hx : qx, hy, mx, my, hy < my ? qx : hx, hy, x[p], y[p]) {
                let tan = abs(hy - y[p]) / (hx - x[p])
                if locallyInside(p, hole),
                   tan < tanMin || (tan == tanMin && (x[p] > x[best] || (x[p] == x[best] && sectorContainsSector(best, p)))) {
                    best = p
                    tanMin = tan
                }
            }
            p = next[p]
        } while p != stop
        return best
    }

    func sectorContainsSector(_ m: Int, _ p: Int) -> Bool {
        area(prev[m], m, prev[p]) < 0 && area(next[p], m, next[m]) < 0
    }

    func leftmost(_ start: Int) -> Int {
        var p = start, best = start
        repeat {
            if x[p] < x[best] || (x[p] == x[best] && y[p] < y[best]) { best = p }
            p = next[p]
        } while p != start
        return best
    }

    /// Links a to b with a bridge, duplicating both; returns the new b.
    mutating func splitPolygon(_ a: Int, _ b: Int) -> Int {
        let a2 = createNode(vertex[a], x[a], y[a])
        let b2 = createNode(vertex[b], x[b], y[b])
        let an = next[a], bp = prev[b]
        next[a] = b; prev[b] = a
        next[a2] = an; prev[an] = a2
        next[b2] = a2; prev[a2] = b2
        next[bp] = b2; prev[b2] = bp
        return b2
    }

    // MARK: Geometry predicates

    func signedArea(_ data: [Double], _ start: Int, _ end: Int) -> Double {
        var sum = 0.0
        var j = end - 2
        for i in stride(from: start, to: end, by: 2) {
            sum += (data[j] - data[i]) * (data[i + 1] + data[j + 1])
            j = i
        }
        return sum
    }

    func area(_ p: Int, _ q: Int, _ r: Int) -> Double {
        (y[q] - y[p]) * (x[r] - x[q]) - (x[q] - x[p]) * (y[r] - y[q])
    }

    func equals(_ a: Int, _ b: Int) -> Bool { x[a] == x[b] && y[a] == y[b] }

    func pointInTriangle(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double, _ cx: Double, _ cy: Double, _ px: Double, _ py: Double) -> Bool {
        (cx - px) * (ay - py) >= (ax - px) * (cy - py)
            && (ax - px) * (by - py) >= (bx - px) * (ay - py)
            && (bx - px) * (cy - py) >= (cx - px) * (by - py)
    }

    func isValidDiagonal(_ a: Int, _ b: Int) -> Bool {
        vertex[next[a]] != vertex[b] && vertex[prev[a]] != vertex[b] && !intersectsPolygon(a, b)
            && ((locallyInside(a, b) && locallyInside(b, a) && middleInside(a, b)
                && (area(prev[a], a, prev[b]) != 0 || area(a, prev[b], b) != 0))
                || (equals(a, b) && area(prev[a], a, next[a]) > 0 && area(prev[b], b, next[b]) > 0))
    }

    func sign(_ v: Double) -> Int { v > 0 ? 1 : (v < 0 ? -1 : 0) }

    func intersects(_ p1: Int, _ q1: Int, _ p2: Int, _ q2: Int) -> Bool {
        let o1 = sign(area(p1, q1, p2))
        let o2 = sign(area(p1, q1, q2))
        let o3 = sign(area(p2, q2, p1))
        let o4 = sign(area(p2, q2, q1))
        if o1 != o2 && o3 != o4 { return true }
        if o1 == 0 && onSegment(p1, p2, q1) { return true }
        if o2 == 0 && onSegment(p1, q2, q1) { return true }
        if o3 == 0 && onSegment(p2, p1, q2) { return true }
        if o4 == 0 && onSegment(p2, q1, q2) { return true }
        return false
    }

    /// Whether q lies on segment pr (given collinear).
    func onSegment(_ p: Int, _ q: Int, _ r: Int) -> Bool {
        x[q] <= max(x[p], x[r]) && x[q] >= min(x[p], x[r]) && y[q] <= max(y[p], y[r]) && y[q] >= min(y[p], y[r])
    }

    func intersectsPolygon(_ a: Int, _ b: Int) -> Bool {
        var p = a
        repeat {
            let n = next[p]
            if vertex[p] != vertex[a], vertex[n] != vertex[a], vertex[p] != vertex[b], vertex[n] != vertex[b],
               intersects(p, n, a, b) {
                return true
            }
            p = n
        } while p != a
        return false
    }

    func locallyInside(_ a: Int, _ b: Int) -> Bool {
        area(prev[a], a, next[a]) < 0
            ? area(a, b, next[a]) >= 0 && area(a, prev[a], b) >= 0
            : area(a, b, prev[a]) < 0 || area(a, next[a], b) < 0
    }

    func middleInside(_ a: Int, _ b: Int) -> Bool {
        var p = a
        var inside = false
        let px = (x[a] + x[b]) / 2, py = (y[a] + y[b]) / 2
        repeat {
            let n = next[p]
            if (y[p] > py) != (y[n] > py), y[n] != y[p],
               px < (x[n] - x[p]) * (py - y[p]) / (y[n] - y[p]) + x[p] {
                inside.toggle()
            }
            p = n
        } while p != a
        return inside
    }
}
