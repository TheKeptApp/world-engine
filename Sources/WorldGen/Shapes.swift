import Foundation
import simd
import WorldGeo
import WorldMesh

/// Local point + height → scene position.
@inline(__always)
func P(_ p: LocalPoint, _ z: Double) -> SIMD3<Float> { LocalFrame.scenePosition(p, y: z) }

/// Local direction → scene direction (horizontal).
@inline(__always)
func D(_ d: LocalPoint) -> SIMD3<Float> { SIMD3(Float(d.x), 0, Float(-d.y)) }

extension MeshBuffers {
    /// Adds a planar convex polygon (fan), flat-shaded, wound to face `hint`.
    mutating func addFace(_ pts: [SIMD3<Float>], facing hint: SIMD3<Float>) {
        guard pts.count >= 3 else { return }
        // Newell normal.
        var n = SIMD3<Float>.zero
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            n += SIMD3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
        }
        let len = simd_length(n)
        guard len > 1e-8 else { return }
        n /= len
        var ordered = pts
        if simd_dot(n, hint) < 0 { ordered.reverse(); n = -n }
        let base = UInt32(positions.count)
        for p in ordered { addVertex(p, normal: n) }
        for i in 1..<(UInt32(ordered.count) - 1) { addTriangle(base, base + i, base + i + 1) }
    }

    /// An oriented box: footprint rectangle (center, axis u, half sizes) from z0 to z1.
    /// Bottom face omitted unless `bottom`.
    mutating func addBox(center c: LocalPoint, u: LocalPoint, halfLength a: Double, halfWidth b: Double,
                         z0: Double, z1: Double, bottom: Bool = false) {
        let v = LocalPoint(-u.y, u.x)
        let k = [c - u * a - v * b, c + u * a - v * b, c + u * a + v * b, c - u * a + v * b]
        addFace(k.map { P($0, z1) }, facing: sceneUp)
        if bottom { addFace(k.map { P($0, z0) }, facing: -sceneUp) }
        for i in 0..<4 {
            let p = k[i], q = k[(i + 1) % 4]
            let mid = (p + q) / 2 - c
            addFace([P(p, z0), P(q, z0), P(q, z1), P(p, z1)], facing: D(mid))
        }
    }

    /// A quad flat against a wall: along the wall from `s0` to `s1` (meters from `origin` along
    /// `dir`), from height `z0` to `z1`, pushed `offset` meters out along `normal`.
    mutating func addWallQuad(origin: LocalPoint, dir: LocalPoint, normal: LocalPoint,
                              s0: Double, s1: Double, z0: Double, z1: Double, offset: Double) {
        let a = origin + dir * s0 + normal * offset, b = origin + dir * s1 + normal * offset
        addFace([P(a, z0), P(b, z0), P(b, z1), P(a, z1)], facing: D(normal))
    }
}

/// Roof geometry on oriented rectangles. Heights in meters above ground.
enum Roofs {
    struct Style {
        var pitchDegrees: Double
        var overhang: Double
        var roof: Paint
        var gableWall: Paint
        var trim: Paint
        /// Fascia board thickness.
        var fascia = 0.14
    }

    /// Height the roof rises above the eave line for a rectangle of half-width `b`.
    static func rise(_ rect: OrientedRect, pitch: Double) -> Double {
        rect.halfWidth * tan(pitch * .pi / 180)
    }

    /// Gabled roof: ridge along the rectangle's long axis, gable walls at both ends.
    static func gabled(_ r: OrientedRect, eave h: Double, style s: Style, into m: inout MeshBuffers) {
        let t = tan(s.pitchDegrees * .pi / 180)
        let a = r.halfLength, b = r.halfWidth, o = s.overhang
        let ridgeZ = h + b * t, eaveZ = h - o * t
        let up = sceneUp

        // Gable end walls (siding), flush with the walls.
        m.paint = s.gableWall
        for sgn in [-1.0, 1.0] {
            let pts = [P(r.point(sgn * a, -b), h), P(r.point(sgn * a, b), h), P(r.point(sgn * a, 0), ridgeZ)]
            m.addFace(pts, facing: D(r.u * sgn))
        }
        // Slopes.
        m.paint = s.roof
        for side in [-1.0, 1.0] {
            let e0 = P(r.point(-(a + o), side * (b + o)), eaveZ), e1 = P(r.point(a + o, side * (b + o)), eaveZ)
            let r0 = P(r.point(-(a + o), 0), ridgeZ), r1 = P(r.point(a + o, 0), ridgeZ)
            m.addFace([e0, e1, r1, r0], facing: up + D(r.v * side))
            // Underside of the overhang (soffit), facing down.
            let w0 = P(r.point(-(a + o), side * b), h), w1 = P(r.point(a + o, side * b), h)
            m.paint = s.trim
            m.addFace([e0, e1, w1, w0], facing: -up)
            // Fascia board along the eave.
            m.addFace([e0, e1, e1 - SIMD3(0, Float(s.fascia), 0), e0 - SIMD3(0, Float(s.fascia), 0)], facing: D(r.v * side))
            m.paint = s.roof
        }
        // Rake boards (roof thickness) at the gable ends.
        m.paint = s.trim
        for sgn in [-1.0, 1.0] {
            for side in [-1.0, 1.0] {
                let e = P(r.point(sgn * (a + o), side * (b + o)), eaveZ), q = P(r.point(sgn * (a + o), 0), ridgeZ)
                let dz = SIMD3<Float>(0, Float(s.fascia), 0)
                m.addFace([e, q, q - dz, e - dz], facing: D(r.u * sgn))
                // Rake soffit (underside between gable wall and roof edge).
                let ew = P(r.point(sgn * a, side * (b + o)), eaveZ), qw = P(r.point(sgn * a, 0), ridgeZ)
                m.addFace([e, q, qw, ew], facing: -up)
            }
        }
    }

    /// Hipped roof: slopes on all four sides; a ridge if the rectangle is longer than wide.
    static func hipped(_ r: OrientedRect, eave h: Double, style s: Style, into m: inout MeshBuffers) {
        let t = tan(s.pitchDegrees * .pi / 180)
        let a = r.halfLength, b = r.halfWidth, o = s.overhang
        let ridgeZ = h + b * t, eaveZ = h - o * t
        let ridgeHalf = max(0, a - b)
        let A = a + o, B = b + o
        let p0 = P(r.point(-ridgeHalf, 0), ridgeZ), p1 = P(r.point(ridgeHalf, 0), ridgeZ)
        let c00 = P(r.point(-A, -B), eaveZ), c10 = P(r.point(A, -B), eaveZ)
        let c11 = P(r.point(A, B), eaveZ), c01 = P(r.point(-A, B), eaveZ)
        let up = sceneUp
        m.paint = s.roof
        m.addFace(ridgeHalf > 0.01 ? [c00, c10, p1, p0] : [c00, c10, p0], facing: up + D(-r.v))
        m.addFace(ridgeHalf > 0.01 ? [c11, c01, p0, p1] : [c11, c01, p0], facing: up + D(r.v))
        m.addFace([c10, c11, p1], facing: up + D(r.u))
        m.addFace([c01, c00, p0], facing: up + D(-r.u))
        // Soffits and fascia all around.
        m.paint = s.trim
        let eaves = [c00, c10, c11, c01]
        let walls = [P(r.point(-a, -b), h), P(r.point(a, -b), h), P(r.point(a, b), h), P(r.point(-a, b), h)]
        let dz = SIMD3<Float>(0, Float(s.fascia), 0)
        let outward = [D(-r.v), D(r.u), D(r.v), D(-r.u)]
        for i in 0..<4 {
            let j = (i + 1) % 4
            m.addFace([eaves[i], eaves[j], walls[j], walls[i]], facing: -up)
            m.addFace([eaves[i], eaves[j], eaves[j] - dz, eaves[i] - dz], facing: outward[i])
        }
    }

    /// A flat slab with overhang (sheds, porch roofs).
    static func slab(_ r: OrientedRect, z: Double, thickness: Double, overhang o: Double, paint: Paint, into m: inout MeshBuffers) {
        m.paint = paint
        m.addBox(center: r.center, u: r.u, halfLength: r.halfLength + o, halfWidth: r.halfWidth + o,
                 z0: z, z1: z + thickness, bottom: true)
    }

    /// Flat roof cap at `z` with a parapet of `parapet` meters (inner faces; the outer faces are
    /// the walls extended by the caller).
    static func flatWithParapet(_ footprint: Polygon2D, z: Double, parapet: Double, roof: Paint, wall: Paint, into m: inout MeshBuffers) {
        m.paint = roof
        if let cap = Triangulator.cap(footprint, y: z) {
            let start = m.positions.count
            m.append(cap)
            m.repaint(from: start, roof)
        }
        guard parapet > 0 else { return }
        m.paint = wall
        for ring in [footprint.outer] + footprint.holes {
            for i in 0..<ring.count {
                let p = ring[i], q = ring[(i + 1) % ring.count]
                let d = q - p
                guard simd_length(d) > 1e-6 else { continue }
                let inward = LocalPoint(-d.y, d.x) // left of edge = inside for CCW outer
                m.addFace([P(p, z), P(q, z), P(q, z + parapet), P(p, z + parapet)], facing: D(inward))
            }
        }
    }
}
