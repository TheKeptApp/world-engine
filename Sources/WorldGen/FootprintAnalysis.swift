import Foundation
import simd
import WorldGeo

/// A rectangle with an arbitrary orientation. `u` runs along the long side.
public struct OrientedRect: Sendable, Equatable {
    public var center: LocalPoint
    /// Unit vector along the long side.
    public var u: LocalPoint
    public var halfLength: Double
    public var halfWidth: Double

    public var v: LocalPoint { LocalPoint(-u.y, u.x) }
    public var area: Double { 4 * halfLength * halfWidth }

    public init(center: LocalPoint, u: LocalPoint, halfLength: Double, halfWidth: Double) {
        // Normalize so u is the long axis.
        if halfWidth > halfLength {
            self.center = center
            self.u = LocalPoint(-u.y, u.x) // the old short-side direction becomes the long axis
            self.halfLength = halfWidth
            self.halfWidth = halfLength
        } else {
            self.center = center
            self.u = u
            self.halfLength = halfLength
            self.halfWidth = halfWidth
        }
    }

    /// Point at local (s along u, t along v).
    public func point(_ s: Double, _ t: Double) -> LocalPoint { center + u * s + v * t }

    /// Corners counter-clockwise.
    public var corners: [LocalPoint] {
        [point(-halfLength, -halfWidth), point(halfLength, -halfWidth), point(halfLength, halfWidth), point(-halfLength, halfWidth)]
    }
}

/// What the house generator does with a footprint.
public enum FootprintClass: String, Sendable {
    /// Under `tinyArea` m²: flat slab roof, no windows.
    case tiny
    /// Close to its bounding rectangle: one pitched roof over the oriented rectangle.
    case rectangle
    /// Built from right angles (L, T, U, notched): split into rectangles, each roofed.
    case orthogonal
    /// Roughly rectangular but not orthogonal: one pitched roof over the bounding rectangle.
    case nearRectangle
    /// Anything else, and very large footprints that aren't rectangular: flat roof with parapet.
    case irregular
}

public struct FootprintAnalysis: Sendable {
    public static let tinyArea = 12.0
    public static let largeArea = 400.0

    public var obb: OrientedRect
    /// Footprint area / bounding-rectangle area (1 = perfect rectangle).
    public var rectangularity: Double
    /// Share of perimeter running parallel or perpendicular to the rectangle (within 10°).
    public var orthogonality: Double
    public var kind: FootprintClass
    /// Roof pieces: rectangles to put pitched roofs on (empty for tiny/irregular).
    public var roofRects: [OrientedRect]
    /// Leftover orthogonal pieces too small for their own pitched roof (get flat roofs).
    public var flatRects: [OrientedRect]

    public init(_ footprint: Polygon2D) {
        let area = footprint.area
        obb = Self.minimumAreaRect(footprint.outer)
        rectangularity = obb.area > 0 ? area / obb.area : 0
        orthogonality = Self.orthogonality(footprint.outer, axis: obb.u)
        roofRects = []
        flatRects = []

        if area < Self.tinyArea {
            kind = .tiny
        } else if !footprint.holes.isEmpty {
            kind = .irregular
        } else if rectangularity >= 0.9 {
            kind = .rectangle
            roofRects = [obb]
        } else if orthogonality >= 0.85, let (roofs, flats) = Self.decompose(footprint.outer, frame: obb), !roofs.isEmpty {
            kind = .orthogonal
            roofRects = roofs
            flatRects = flats
        } else if rectangularity >= 0.75, area <= Self.largeArea {
            kind = .nearRectangle
            roofRects = [obb]
        } else {
            kind = .irregular
        }
    }

    // MARK: - Minimum-area rectangle (rotating edges of the convex hull)

    public static func convexHull(_ pts: [LocalPoint]) -> [LocalPoint] {
        let p = pts.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        guard p.count >= 3 else { return p }
        var lower: [LocalPoint] = [], upper: [LocalPoint] = []
        for q in p {
            while lower.count >= 2, RingMath.cross(lower[lower.count - 1] - lower[lower.count - 2], q - lower[lower.count - 2]) <= 0 { lower.removeLast() }
            lower.append(q)
        }
        for q in p.reversed() {
            while upper.count >= 2, RingMath.cross(upper[upper.count - 1] - upper[upper.count - 2], q - upper[upper.count - 2]) <= 0 { upper.removeLast() }
            upper.append(q)
        }
        return Array(lower.dropLast() + upper.dropLast())
    }

    public static func minimumAreaRect(_ ring: Ring) -> OrientedRect {
        let hull = convexHull(ring)
        var best: OrientedRect?
        var bestArea = Double.infinity
        for i in 0..<hull.count {
            let d = hull[(i + 1) % hull.count] - hull[i]
            let len = simd_length(d)
            guard len > 1e-9 else { continue }
            let u = d / len, v = LocalPoint(-u.y, u.x)
            var sMin = Double.infinity, sMax = -Double.infinity, tMin = Double.infinity, tMax = -Double.infinity
            for p in hull {
                let s = simd_dot(p, u), t = simd_dot(p, v)
                sMin = min(sMin, s); sMax = max(sMax, s); tMin = min(tMin, t); tMax = max(tMax, t)
            }
            let a = (sMax - sMin) * (tMax - tMin)
            if a < bestArea - 1e-9 {
                bestArea = a
                let c = u * ((sMin + sMax) / 2) + v * ((tMin + tMax) / 2)
                best = OrientedRect(center: c, u: u, halfLength: (sMax - sMin) / 2, halfWidth: (tMax - tMin) / 2)
            }
        }
        return best ?? OrientedRect(center: ring.first ?? .zero, u: LocalPoint(1, 0), halfLength: 0, halfWidth: 0)
    }

    static func orthogonality(_ ring: Ring, axis u: LocalPoint) -> Double {
        var total = 0.0, aligned = 0.0
        let tol = sin(10 * Double.pi / 180)
        for i in 0..<ring.count {
            let d = ring[(i + 1) % ring.count] - ring[i]
            let len = simd_length(d)
            guard len > 1e-9 else { continue }
            let c = abs(RingMath.cross(u, d / len))   // sin of angle to u
            let s = abs(simd_dot(u, d / len))          // cos of angle to u
            if c < tol || s < tol { aligned += len }
            total += len
        }
        return total > 0 ? aligned / total : 0
    }

    // MARK: - Orthogonal decomposition

    /// Splits an orthogonal ring into rectangles in `frame`'s axes: snaps vertices to a grid of
    /// distinct coordinates, marks grid cells inside the ring, then repeatedly takes the
    /// largest all-inside rectangle. Pieces under 6 m² (or past the sixth) become flat pieces.
    static func decompose(_ ring: Ring, frame: OrientedRect) -> (roofs: [OrientedRect], flats: [OrientedRect])? {
        let local = ring.map { p -> LocalPoint in
            let d = p - frame.center
            return LocalPoint(simd_dot(d, frame.u), simd_dot(d, frame.v))
        }
        func clusters(_ values: [Double]) -> [Double] {
            var out: [Double] = []
            for v in values.sorted() {
                if let last = out.last, v - last < 0.35 { continue }
                out.append(v)
            }
            return out
        }
        let xs = clusters(local.map(\.x)), ys = clusters(local.map(\.y))
        guard xs.count >= 2, ys.count >= 2, xs.count <= 24, ys.count <= 24 else { return nil }
        let nx = xs.count - 1, ny = ys.count - 1
        var inside = [[Bool]](repeating: [Bool](repeating: false, count: ny), count: nx)
        for i in 0..<nx { for j in 0..<ny {
            inside[i][j] = RingMath.contains(local, LocalPoint((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2))
        } }

        var roofs: [OrientedRect] = [], flats: [OrientedRect] = []
        while true {
            // Largest all-inside rectangle by area (grids are small: brute force).
            var best: (i0: Int, i1: Int, j0: Int, j1: Int, area: Double)?
            for i0 in 0..<nx { for j0 in 0..<ny where inside[i0][j0] {
                var maxJ = ny - 1
                for i1 in i0..<nx {
                    guard inside[i1][j0] else { break }
                    var j1 = j0
                    while j1 + 1 <= maxJ, inside[i1][j1 + 1] { j1 += 1 }
                    maxJ = j1
                    let a = (xs[i1 + 1] - xs[i0]) * (ys[j1 + 1] - ys[j0])
                    if a > (best?.area ?? 0) { best = (i0, i1, j0, j1, a) }
                }
            } }
            guard let b = best else { break }
            for i in b.i0...b.i1 { for j in b.j0...b.j1 { inside[i][j] = false } }
            let cx = (xs[b.i0] + xs[b.i1 + 1]) / 2, cy = (ys[b.j0] + ys[b.j1 + 1]) / 2
            let rect = OrientedRect(
                center: frame.point(cx, cy), u: frame.u,
                halfLength: (xs[b.i1 + 1] - xs[b.i0]) / 2, halfWidth: (ys[b.j1 + 1] - ys[b.j0]) / 2
            )
            if b.area >= 6, roofs.count < 6 { roofs.append(rect) } else if b.area >= 0.5 { flats.append(rect) }
        }
        return (roofs, flats)
    }
}
