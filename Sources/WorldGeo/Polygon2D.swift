import Foundation
import simd

/// A closed ring of local points. The closing point is NOT repeated.
public typealias Ring = [LocalPoint]

/// A polygon in local meters: one outer ring plus zero or more holes (courtyards, islands).
///
/// After `cleaned()`, the outer ring is counter-clockwise and holes are clockwise, viewed from
/// above (east = +x, north = +y). Triangles with that winding face up in scene space.
public struct Polygon2D: Hashable, Sendable {
    public var outer: Ring
    public var holes: [Ring]

    public init(outer: Ring, holes: [Ring] = []) {
        self.outer = outer
        self.holes = holes
    }

    /// Area of the outer ring minus the holes, in m².
    public var area: Double {
        abs(RingMath.signedArea(outer)) - holes.reduce(0) { $0 + abs(RingMath.signedArea($1)) }
    }

    public var bounds: Rect2D { Rect2D(enclosing: outer) }

    /// Area-weighted centroid of the outer ring.
    public var centroid: LocalPoint { RingMath.centroid(outer) }

    public func contains(_ p: LocalPoint) -> Bool {
        RingMath.contains(outer, p) && !holes.contains { RingMath.contains($0, p) }
    }

    /// Clean-up before triangulation:
    /// - drops a repeated closing point
    /// - merges points closer than `mergeDistance`
    /// - removes collinear points
    /// - orients the outer ring CCW and holes CW
    /// - drops rings with an area under `minArea`
    ///
    /// Returns nil if the outer ring doesn't survive.
    public func cleaned(mergeDistance: Double = 0.01, minArea: Double = 0.5) -> Polygon2D? {
        guard let o = RingMath.clean(outer, mergeDistance: mergeDistance),
              abs(RingMath.signedArea(o)) >= minArea else { return nil }
        let outerCCW = RingMath.signedArea(o) > 0 ? o : o.reversed()
        let cleanedHoles: [Ring] = holes.compactMap { h in
            guard let c = RingMath.clean(h, mergeDistance: mergeDistance),
                  abs(RingMath.signedArea(c)) >= minArea else { return nil }
            return RingMath.signedArea(c) < 0 ? c : c.reversed()
        }
        return Polygon2D(outer: outerCCW, holes: cleanedHoles)
    }
}

/// An axis-aligned rectangle in local meters.
public struct Rect2D: Hashable, Codable, Sendable {
    public var min: LocalPoint
    public var max: LocalPoint

    public init(min: LocalPoint, max: LocalPoint) {
        self.min = min
        self.max = max
    }

    public init(centerWidth width: Double, height: Double) {
        self.init(min: LocalPoint(-width / 2, -height / 2), max: LocalPoint(width / 2, height / 2))
    }

    public init(enclosing points: [LocalPoint]) {
        var lo = LocalPoint(Double.infinity, Double.infinity)
        var hi = -lo
        for p in points {
            lo = simd_min(lo, p)
            hi = simd_max(hi, p)
        }
        self.init(min: lo, max: hi)
    }

    public var width: Double { max.x - min.x }
    public var height: Double { max.y - min.y }

    public func contains(_ p: LocalPoint) -> Bool {
        p.x >= min.x && p.x <= max.x && p.y >= min.y && p.y <= max.y
    }

    public func intersects(_ other: Rect2D) -> Bool {
        min.x <= other.max.x && max.x >= other.min.x && min.y <= other.max.y && max.y >= other.min.y
    }

    public func expanded(by d: Double) -> Rect2D {
        Rect2D(min: min - LocalPoint(d, d), max: max + LocalPoint(d, d))
    }
}

/// Ring utilities shared by the map and mesh modules.
public enum RingMath {
    /// Shoelace signed area: positive for counter-clockwise rings.
    public static func signedArea(_ r: Ring) -> Double {
        guard r.count >= 3 else { return 0 }
        var sum = 0.0
        var j = r.count - 1
        for i in 0..<r.count {
            sum += (r[j].x - r[i].x) * (r[j].y + r[i].y)
            j = i
        }
        return sum / 2
    }

    public static func centroid(_ r: Ring) -> LocalPoint {
        let a = signedArea(r)
        guard abs(a) > 1e-9 else {
            return r.isEmpty ? .zero : r.reduce(.zero, +) / Double(r.count)
        }
        var c = LocalPoint.zero
        var j = r.count - 1
        for i in 0..<r.count {
            let cross = r[j].x * r[i].y - r[i].x * r[j].y
            c += (r[j] + r[i]) * cross
            j = i
        }
        return c / (6 * a)
    }

    /// Even-odd point-in-ring test.
    public static func contains(_ r: Ring, _ p: LocalPoint) -> Bool {
        var inside = false
        var j = r.count - 1
        for i in 0..<r.count {
            let a = r[i], b = r[j]
            if (a.y > p.y) != (b.y > p.y),
               p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    /// Drops a repeated closing point, merges near-duplicate points and removes collinear points.
    /// Returns nil if fewer than 3 points remain.
    public static func clean(_ ring: Ring, mergeDistance: Double = 0.01, collinearTolerance: Double = 0.001) -> Ring? {
        var pts: [LocalPoint] = []
        pts.reserveCapacity(ring.count)
        for p in ring {
            if let last = pts.last, simd_distance(last, p) < mergeDistance { continue }
            pts.append(p)
        }
        while pts.count > 1, simd_distance(pts[0], pts[pts.count - 1]) < mergeDistance {
            pts.removeLast()
        }
        // Remove collinear points (distance from the neighbor line below tolerance) until stable.
        var changed = true
        while changed, pts.count >= 3 {
            changed = false
            var i = 0
            while i < pts.count, pts.count >= 3 {
                let a = pts[(i + pts.count - 1) % pts.count]
                let b = pts[i]
                let c = pts[(i + 1) % pts.count]
                let ac = c - a
                let len = simd_length(ac)
                let dist = len > 1e-12 ? abs(cross(ac, b - a)) / len : simd_distance(a, b)
                if dist < collinearTolerance {
                    pts.remove(at: i)
                    changed = true
                } else {
                    i += 1
                }
            }
        }
        return pts.count >= 3 ? pts : nil
    }

    @inline(__always)
    public static func cross(_ a: LocalPoint, _ b: LocalPoint) -> Double {
        a.x * b.y - a.y * b.x
    }
}
