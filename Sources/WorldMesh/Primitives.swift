import simd
import WorldGeo

/// Polygon triangulation with a correctness check.
public enum Triangulator {
    /// Triangulates `polygon` (cleaned: outer CCW, holes CW). Returns nil if the result's area is
    /// off from the polygon's by more than `tolerance` (a sign of self-intersecting input), so the
    /// caller can skip and log the feature instead of drawing garbage.
    public static func triangulate(_ polygon: Polygon2D, tolerance: Double = 0.01) -> (vertices: [LocalPoint], indices: [Int])? {
        let result = Earcut.triangulate(polygon)
        guard !result.indices.isEmpty else { return nil }
        var sum = 0.0
        for t in stride(from: 0, to: result.indices.count, by: 3) {
            let a = result.vertices[result.indices[t]]
            let b = result.vertices[result.indices[t + 1]]
            let c = result.vertices[result.indices[t + 2]]
            sum += RingMath.cross(b - a, c - a) / 2
        }
        let expected = polygon.area
        guard expected > 0, abs(sum - expected) / expected <= tolerance else { return nil }
        return result
    }

    /// A flat, up-facing cap at height `y` (roofs, ground polygons).
    public static func cap(_ polygon: Polygon2D, y: Double) -> MeshBuffers? {
        guard let t = triangulate(polygon) else { return nil }
        var mesh = MeshBuffers()
        for v in t.vertices { mesh.addVertex(scene(v, y), normal: sceneUp) }
        for i in stride(from: 0, to: t.indices.count, by: 3) {
            mesh.addTriangle(UInt32(t.indices[i]), UInt32(t.indices[i + 1]), UInt32(t.indices[i + 2]))
        }
        return mesh
    }
}

/// Footprint extrusion: flat-shaded walls plus a flat roof. No floor (never visible).
public enum Extrusion {
    /// Extrudes `footprint` from `base` to `top` meters. Each wall quad gets its own outward
    /// normal; courtyard walls face into the courtyard. Returns nil if the roof can't be
    /// triangulated.
    public static func extrude(_ footprint: Polygon2D, base: Double, top: Double) -> MeshBuffers? {
        let fp = oriented(footprint)
        guard top > base, var mesh = Triangulator.cap(fp, y: top) else { return nil }
        for ring in [fp.outer] + fp.holes {
            addWalls(ring, base: base, top: top, into: &mesh)
        }
        return mesh
    }

    /// One quad per ring edge. For a CCW ring the outside is on the right of each edge; for a CW
    /// hole that same rule points into the courtyard, which is the outside of the building.
    public static func addWalls(_ ring: Ring, base: Double, top: Double, into mesh: inout MeshBuffers) {
        for i in 0..<ring.count {
            let p = ring[i], q = ring[(i + 1) % ring.count]
            let d = q - p
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            let outwardLocal = LocalPoint(d.y, -d.x) / len
            let normal = SIMD3<Float>(Float(outwardLocal.x), 0, Float(-outwardLocal.y))
            mesh.addQuad(scene(p, base), scene(q, base), scene(q, top), scene(p, top), normal: normal)
        }
    }

    /// Outer ring CCW, holes CW (no other cleaning).
    static func oriented(_ p: Polygon2D) -> Polygon2D {
        Polygon2D(
            outer: RingMath.signedArea(p.outer) >= 0 ? p.outer : p.outer.reversed(),
            holes: p.holes.map { RingMath.signedArea($0) <= 0 ? $0 : $0.reversed() }
        )
    }
}

/// Flat ribbons along a polyline (roads, paths, sidewalks), facing up.
public enum Ribbon {
    /// Builds a ribbon of `width` meters at height `y`. Joins are mitered; when the miter would
    /// be longer than `miterLimit` × half-width (sharp turns), the join is beveled instead.
    public static func build(_ line: [LocalPoint], width: Double, y: Double, miterLimit: Double = 2) -> MeshBuffers {
        var mesh = MeshBuffers()
        var pts: [LocalPoint] = []
        for p in line where pts.last.map({ simd_distance($0, p) > 0.001 }) ?? true { pts.append(p) }
        guard pts.count >= 2, width > 0 else { return mesh }
        let h = width / 2
        let n = pts.count

        func leftNormal(_ k: Int) -> LocalPoint {
            let d = simd_normalize(pts[k + 1] - pts[k])
            return LocalPoint(-d.y, d.x)
        }

        // Per vertex: left/right edge points where the incoming segment ends and the outgoing begins.
        var inL = [LocalPoint](repeating: .zero, count: n), inR = inL, outL = inL, outR = inL
        for i in 0..<n {
            let p = pts[i]
            if i == 0 || i == n - 1 {
                let nm = leftNormal(i == 0 ? 0 : n - 2)
                inL[i] = p + nm * h; outL[i] = inL[i]
                inR[i] = p - nm * h; outR[i] = inR[i]
                continue
            }
            let n0 = leftNormal(i - 1), n1 = leftNormal(i)
            let sum = n0 + n1
            let sumLen = simd_length(sum)
            var miter: LocalPoint?
            if sumLen > 1e-6 {
                let m = sum / sumLen
                let scale = h / simd_dot(m, n0)
                if scale <= miterLimit * h { miter = m * scale }
            }
            if let m = miter {
                inL[i] = p + m; outL[i] = inL[i]
                inR[i] = p - m; outR[i] = inR[i]
            } else {
                inL[i] = p + n0 * h; inR[i] = p - n0 * h
                outL[i] = p + n1 * h; outR[i] = p - n1 * h
                // Fill the gap on the outer side of the turn.
                let d0 = pts[i] - pts[i - 1], d1 = pts[i + 1] - pts[i]
                if RingMath.cross(d0, d1) > 0 {
                    addUpTriangle(p, inR[i], outR[i], y: y, into: &mesh)
                } else {
                    addUpTriangle(p, outL[i], inL[i], y: y, into: &mesh)
                }
            }
        }
        for k in 0..<(n - 1) {
            let l0 = outL[k], r0 = outR[k], l1 = inL[k + 1], r1 = inR[k + 1]
            addUpTriangle(r0, r1, l1, y: y, into: &mesh)
            addUpTriangle(r0, l1, l0, y: y, into: &mesh)
        }
        return mesh
    }

    /// Adds a triangle wound counter-clockwise from above (so it faces up), whatever the input
    /// order. Degenerate triangles are dropped.
    static func addUpTriangle(_ a: LocalPoint, _ b: LocalPoint, _ c: LocalPoint, y: Double, into mesh: inout MeshBuffers) {
        let cr = RingMath.cross(b - a, c - a)
        guard abs(cr) > 1e-9 else { return }
        let (p, q) = cr > 0 ? (b, c) : (c, b)
        let i = mesh.addVertex(scene(a, y), normal: sceneUp)
        mesh.addVertex(scene(p, y), normal: sceneUp)
        mesh.addVertex(scene(q, y), normal: sceneUp)
        mesh.addTriangle(i, i + 1, i + 2)
    }
}
