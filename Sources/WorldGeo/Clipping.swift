import Foundation
import simd

/// Clipping of rings and polylines to an axis-aligned rectangle.
public enum Clipping {
    /// Sutherland–Hodgman clip of a ring against `rect`. Works for concave rings because the clip
    /// region is convex. Where a concave ring leaves and re-enters the box, the result can include
    /// zero-width edges along the box border; triangulation tolerates these.
    public static func clip(_ ring: Ring, to rect: Rect2D) -> Ring {
        var output = ring
        // Each edge: (inside test, intersection along that edge).
        let edges: [(LocalPoint) -> Bool] = [
            { $0.x >= rect.min.x }, { $0.x <= rect.max.x },
            { $0.y >= rect.min.y }, { $0.y <= rect.max.y },
        ]
        for (k, inside) in edges.enumerated() {
            guard !output.isEmpty else { break }
            let input = output
            output = []
            output.reserveCapacity(input.count + 4)
            var prev = input[input.count - 1]
            for cur in input {
                let curIn = inside(cur)
                let prevIn = inside(prev)
                if curIn {
                    if !prevIn { output.append(intersect(prev, cur, edge: k, rect: rect)) }
                    output.append(cur)
                } else if prevIn {
                    output.append(intersect(prev, cur, edge: k, rect: rect))
                }
                prev = cur
            }
        }
        return output
    }

    /// Clips a polygon (outer + holes). Returns nil if nothing remains inside.
    public static func clip(_ polygon: Polygon2D, to rect: Rect2D) -> Polygon2D? {
        if rect.contains(polygon.bounds.min) && rect.contains(polygon.bounds.max) { return polygon }
        guard rect.intersects(polygon.bounds) else { return nil }
        let outer = clip(polygon.outer, to: rect)
        guard outer.count >= 3 else { return nil }
        let holes = polygon.holes.map { clip($0, to: rect) }.filter { $0.count >= 3 }
        return Polygon2D(outer: outer, holes: holes)
    }

    /// Liang–Barsky clip of a polyline. Returns the pieces inside `rect` (a line that leaves and
    /// re-enters becomes several polylines).
    public static func clip(polyline: [LocalPoint], to rect: Rect2D) -> [[LocalPoint]] {
        var pieces: [[LocalPoint]] = []
        var current: [LocalPoint] = []
        for i in 0..<max(0, polyline.count - 1) {
            guard let (a, b) = clipSegment(polyline[i], polyline[i + 1], to: rect) else {
                if current.count >= 2 { pieces.append(current) }
                current = []
                continue
            }
            if let last = current.last, last == a {
                current.append(b)
            } else {
                if current.count >= 2 { pieces.append(current) }
                current = [a, b]
            }
        }
        if current.count >= 2 { pieces.append(current) }
        return pieces
    }

    static func clipSegment(_ p0: LocalPoint, _ p1: LocalPoint, to r: Rect2D) -> (LocalPoint, LocalPoint)? {
        let d = p1 - p0
        var t0 = 0.0, t1 = 1.0
        let checks: [(Double, Double)] = [
            (-d.x, p0.x - r.min.x), (d.x, r.max.x - p0.x),
            (-d.y, p0.y - r.min.y), (d.y, r.max.y - p0.y),
        ]
        for (p, q) in checks {
            if p == 0 {
                if q < 0 { return nil }
            } else {
                let t = q / p
                if p < 0 { if t > t1 { return nil }; if t > t0 { t0 = t } }
                else { if t < t0 { return nil }; if t < t1 { t1 = t } }
            }
        }
        // Keep exact endpoints when unclipped so consecutive pieces join by equality.
        let a = t0 == 0 ? p0 : p0 + d * t0
        let b = t1 == 1 ? p1 : p0 + d * t1
        return (a, b)
    }

    private static func intersect(_ a: LocalPoint, _ b: LocalPoint, edge: Int, rect: Rect2D) -> LocalPoint {
        let d = b - a
        switch edge {
        case 0: let t = (rect.min.x - a.x) / d.x; return LocalPoint(rect.min.x, a.y + d.y * t)
        case 1: let t = (rect.max.x - a.x) / d.x; return LocalPoint(rect.max.x, a.y + d.y * t)
        case 2: let t = (rect.min.y - a.y) / d.y; return LocalPoint(a.x + d.x * t, rect.min.y)
        default: let t = (rect.max.y - a.y) / d.y; return LocalPoint(a.x + d.x * t, rect.max.y)
        }
    }
}
