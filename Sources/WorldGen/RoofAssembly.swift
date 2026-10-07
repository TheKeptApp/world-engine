import Foundation
import simd
import WorldGeo
import WorldMesh

// Sealed roof assemblies (regions-chicagoland-miami §4): a roof is a few rectangular masses, each
// with a gable or hip roof. The visible roof is the upper envelope of all masses, so cross-gables,
// wings off hip ends and valleys meet without interior faces. Walls rise exactly to the envelope,
// which also produces gable-end triangles; vertical faces fill any step where one mass's roof edge
// sits above another's surface. Everything is computed once on the CPU at generation time.

/// A linear function over the ground plane: f(p) = a·p + c.
struct Linear2: Sendable, Equatable {
    var a: LocalPoint
    var c: Double

    func callAsFunction(_ p: LocalPoint) -> Double { simd_dot(a, p) + c }

    static func - (l: Linear2, r: Linear2) -> Linear2 { Linear2(a: l.a - r.a, c: l.c - r.c) }
    static prefix func - (l: Linear2) -> Linear2 { Linear2(a: -l.a, c: -l.c) }

    /// Positive on the left of the directed line p → q (the inside of a CCW polygon).
    static func leftOf(_ p: LocalPoint, _ q: LocalPoint) -> Linear2 {
        let d = q - p
        let len = max(simd_length(d), 1e-12)
        let a = LocalPoint(-d.y, d.x) / len
        return Linear2(a: a, c: -simd_dot(a, p))
    }
}

/// Convex polygon clipping in the ground plane (all polygons counter-clockwise).
enum ConvexClip {
    /// Pieces smaller than this (m²) are dropped: invisible, and they only add triangles.
    static let minArea = 1e-4

    static func area(_ poly: [LocalPoint]) -> Double { RingMath.signedArea(poly) }

    /// The part of `poly` where `f ≥ 0`.
    static func clip(_ poly: [LocalPoint], keep f: Linear2) -> [LocalPoint] {
        guard poly.count >= 3 else { return [] }
        var out: [LocalPoint] = []
        out.reserveCapacity(poly.count + 2)
        for i in 0..<poly.count {
            let p = poly[i], q = poly[(i + 1) % poly.count]
            let fp = f(p), fq = f(q)
            if fp >= 0 { out.append(p) }
            if (fp >= 0) != (fq >= 0) {
                let t = fp / (fp - fq)
                out.append(p + (q - p) * t)
            }
        }
        return cleaned(out)
    }

    /// Removes repeated points; returns [] for degenerate results.
    static func cleaned(_ pts: [LocalPoint]) -> [LocalPoint] {
        var out: [LocalPoint] = []
        for p in pts where out.last.map({ simd_distance_squared($0, p) > 1e-14 }) ?? true { out.append(p) }
        while out.count > 1, simd_distance_squared(out[0], out[out.count - 1]) <= 1e-14 { out.removeLast() }
        return out.count >= 3 ? out : []
    }

    /// Half-planes (f ≥ 0 inside) of a convex CCW polygon.
    static func halfPlanes(_ poly: [LocalPoint]) -> [Linear2] {
        (0..<poly.count).map { Linear2.leftOf(poly[$0], poly[($0 + 1) % poly.count]) }
    }

    static func intersect(_ poly: [LocalPoint], _ region: [Linear2]) -> [LocalPoint] {
        var cur = poly
        for h in region {
            cur = clip(cur, keep: h)
            if cur.isEmpty { return [] }
        }
        return cur
    }

    /// `poly` minus the convex region (intersection of half-planes), as convex pieces.
    static func subtract(_ poly: [LocalPoint], _ region: [Linear2]) -> [[LocalPoint]] {
        let overlap = intersect(poly, region)
        if overlap.isEmpty || area(overlap) < minArea { return [poly] }
        var pieces: [[LocalPoint]] = []
        var cur = poly
        for h in region {
            let outside = clip(cur, keep: -h)
            if !outside.isEmpty, area(outside) >= minArea { pieces.append(outside) }
            cur = clip(cur, keep: h)
            if cur.isEmpty { break }
        }
        return pieces
    }

    /// Makes a polygon counter-clockwise.
    static func ccw(_ poly: [LocalPoint]) -> [LocalPoint] { area(poly) < 0 ? poly.reversed() : poly }
}

/// One roof mass: a wall rectangle with a gable or hip roof over it.
public struct RoofMass: Sendable, Equatable {
    public enum Form: String, Sendable, Codable { case gable, hip }

    public var center: LocalPoint
    /// Unit ridge direction.
    public var axis: LocalPoint
    /// Half the wall length along the ridge.
    public var halfLength: Double
    /// Half the wall width across the ridge.
    public var halfWidth: Double
    public var form: Form
    /// Degrees above horizontal.
    public var pitch: Double
    /// Horizontal overhang beyond the walls (eaves and rakes).
    public var overhang: Double
    /// Wall-top height where the roof meets the walls (meters above ground).
    public var eave: Double

    public init(center: LocalPoint, axis: LocalPoint, halfLength: Double, halfWidth: Double, form: Form,
                pitch: Double, overhang: Double, eave: Double) {
        self.center = center
        self.axis = simd_normalize(axis)
        self.halfLength = halfLength
        self.halfWidth = halfWidth
        self.form = form
        self.pitch = pitch
        self.overhang = overhang
        self.eave = eave
        // A hip ridge runs along the long side.
        if form == .hip, halfLength < halfWidth {
            self.axis = LocalPoint(-self.axis.y, self.axis.x)
            self.halfLength = halfWidth
            self.halfWidth = halfLength
        }
    }

    /// Unit vector across the ridge (left of the axis).
    public var across: LocalPoint { LocalPoint(-axis.y, axis.x) }
    public var slope: Double { tan(pitch * .pi / 180) }
    public var ridgeHeight: Double { eave + halfWidth * slope }
    /// Height of the outer roof edge (eave line), below the wall top by the overhang's drop.
    public var edgeHeight: Double { eave - overhang * slope }

    /// Point at (s along the ridge, t across it) from the center.
    public func point(_ s: Double, _ t: Double) -> LocalPoint { center + axis * s + across * t }

    /// Wall rectangle, counter-clockwise.
    public var wallRect: [LocalPoint] { rect(halfLength, halfWidth) }
    /// Roof outline (wall rectangle plus overhang), counter-clockwise.
    public var domain: [LocalPoint] { rect(halfLength + overhang, halfWidth + overhang) }

    func rect(_ a: Double, _ b: Double) -> [LocalPoint] { [point(-a, -b), point(a, -b), point(a, b), point(-a, b)] }

    /// The roof planes over the domain.
    func faces(mass: Int) -> [RoofFace] {
        let k = slope, L = halfLength, W = halfWidth, H = eave
        let A = L + overhang, B = W + overhang
        let n = across, u = axis, c = center
        // z = H + (W ∓ t)·k on the sides, H + (L ∓ s)·k on hip ends.
        let sidePos = Linear2(a: -n * k, c: H + W * k + k * simd_dot(n, c))
        let sideNeg = Linear2(a: n * k, c: H + W * k - k * simd_dot(n, c))
        var out: [RoofFace] = []
        func add(_ st: [(Double, Double)], _ plane: Linear2) {
            let poly = ConvexClip.ccw(st.map { point($0.0, $0.1) })
            if poly.count >= 3 { out.append(RoofFace(mass: mass, polygon: poly, plane: plane)) }
        }
        switch form {
        case .gable:
            add([(-A, 0), (A, 0), (A, B), (-A, B)], sidePos)
            add([(-A, -B), (A, -B), (A, 0), (-A, 0)], sideNeg)
        case .hip:
            let r = max(0, L - W)
            let endPos = Linear2(a: -u * k, c: H + L * k + k * simd_dot(u, c))
            let endNeg = Linear2(a: u * k, c: H + L * k - k * simd_dot(u, c))
            add(r > 1e-6 ? [(r, 0), (A, B), (-A, B), (-r, 0)] : [(0, 0), (A, B), (-A, B)], sidePos)
            add(r > 1e-6 ? [(-A, -B), (A, -B), (r, 0), (-r, 0)] : [(-A, -B), (A, -B), (0, 0)], sideNeg)
            add([(A, -B), (A, B), (r, 0)], endPos)
            add([(-A, B), (-A, -B), (-r, 0)], endNeg)
        }
        return out
    }
}

/// A planar roof polygon: its outline in the ground plane and its height function.
struct RoofFace: Sendable {
    var mass: Int
    var polygon: [LocalPoint]
    var plane: Linear2
    var halfPlanes: [Linear2]

    init(mass: Int, polygon: [LocalPoint], plane: Linear2) {
        self.mass = mass
        self.polygon = polygon
        self.plane = plane
        halfPlanes = ConvexClip.halfPlanes(polygon)
    }

    func contains(_ p: LocalPoint, tolerance: Double = 1e-6) -> Bool { halfPlanes.allSatisfy { $0(p) >= -tolerance } }
}

/// A covered stretch of a height profile along a segment: parameters in 0…1, heights at both ends.
struct ProfileSpan: Sendable, Equatable {
    var t0: Double
    var t1: Double
    var z0: Double
    var z1: Double
    /// The mass whose roof is on top here.
    var mass: Int

    func z(at t: Double) -> Double { t1 - t0 > 1e-12 ? z0 + (z1 - z0) * (t - t0) / (t1 - t0) : z0 }
}

/// Visible roof: the upper envelope of a set of masses.
public struct RoofEnvelope: Sendable {
    public struct Fragment: Sendable {
        public var polygon: [LocalPoint]
        var plane: Linear2
        public var mass: Int
        /// Outside the mass's walls (gets a soffit underneath).
        public var overhang: Bool
        public func height(_ p: LocalPoint) -> Double { plane(p) }
    }

    public let masses: [RoofMass]
    /// Footprint ring the roof is cut to (conservative envelope over a non-orthogonal footprint).
    public let clip: Ring?
    let faces: [RoofFace]
    public private(set) var fragments: [Fragment] = []

    public init(masses: [RoofMass], clip: Ring? = nil) {
        self.masses = masses
        self.clip = clip.map { Self.offset($0, by: masses.map(\.overhang).min() ?? 0) }
        faces = masses.enumerated().flatMap { $0.element.faces(mass: $0.offset) }
        fragments = computeFragments()
    }

    /// Splits each face at its mass's walls, then removes every part lying below another mass's roof.
    func computeFragments() -> [Fragment] {
        var out: [Fragment] = []
        let eps = 1e-5
        for face in faces {
            let wall = ConvexClip.halfPlanes(masses[face.mass].wallRect)
            var pieces: [(poly: [LocalPoint], overhang: Bool)] = []
            let inside = ConvexClip.intersect(face.polygon, wall)
            if !inside.isEmpty, ConvexClip.area(inside) >= ConvexClip.minArea { pieces.append((inside, false)) }
            for p in ConvexClip.subtract(face.polygon, wall) where !p.isEmpty { pieces.append((p, true)) }
            if masses[face.mass].overhang <= 1e-6 { pieces = pieces.map { ($0.poly, false) } }

            for piece in pieces {
                var frags = [piece.poly]
                for other in faces where other.mass != face.mass {
                    let d = other.plane - face.plane
                    var region = other.halfPlanes
                    if simd_length(d.a) < 1e-9 {
                        // Parallel planes: higher wins everywhere; exact ties go to the lower mass index.
                        if d.c > eps || (abs(d.c) <= eps && other.mass < face.mass) {} else { continue }
                    } else {
                        region.append(Linear2(a: d.a, c: d.c - eps))
                    }
                    frags = frags.flatMap { ConvexClip.subtract($0, region) }
                    if frags.isEmpty { break }
                }
                for f in frags where ConvexClip.area(f) >= ConvexClip.minArea {
                    out.append(Fragment(polygon: f, plane: face.plane, mass: face.mass, overhang: piece.overhang))
                }
            }
        }
        return out
    }

    /// Roof height at a ground point (top of the envelope), or nil outside every mass.
    public func height(at p: LocalPoint, excluding: Int? = nil) -> Double? {
        var best: Double?
        for f in faces where f.mass != excluding && f.contains(p) {
            let z = f.plane(p)
            if z > (best ?? -.infinity) { best = z }
        }
        return best
    }

    /// Highest point of the roof.
    public var topHeight: Double { masses.map(\.ridgeHeight).max() ?? 0 }

    /// The envelope's height along the segment a → b, as covered spans. `include` filters masses.
    func profile(_ a: LocalPoint, _ b: LocalPoint, include: (Int) -> Bool = { _ in true }) -> [ProfileSpan] {
        let fs = faces.filter { include($0.mass) }
        guard !fs.isEmpty else { return [] }
        let dir = b - a
        var ts: [Double] = [0, 1]
        for f in fs {
            // Where the segment crosses the face outline.
            for i in 0..<f.polygon.count {
                let p = f.polygon[i], q = f.polygon[(i + 1) % f.polygon.count]
                let e = q - p
                let den = RingMath.cross(dir, e)
                guard abs(den) > 1e-12 else { continue }
                let t = RingMath.cross(p - a, e) / den
                let u = RingMath.cross(p - a, dir) / den
                if t > 0, t < 1, u >= -1e-9, u <= 1 + 1e-9 { ts.append(t) }
            }
        }
        // Where two planes cross along the segment.
        for i in 0..<fs.count { for j in (i + 1)..<fs.count {
            let d = fs[i].plane - fs[j].plane
            let den = simd_dot(d.a, dir)
            guard abs(den) > 1e-12 else { continue }
            let t = -d(a) / den
            if t > 0, t < 1 { ts.append(t) }
        } }
        ts.sort()
        var spans: [ProfileSpan] = []
        var prev = ts[0]
        for t in ts.dropFirst() where t - prev > 1e-9 {
            let mid = a + dir * ((prev + t) / 2)
            var best: RoofFace?
            var bestZ = -Double.infinity
            for f in fs where f.contains(mid, tolerance: 1e-7) {
                let z = f.plane(mid)
                if z > bestZ { bestZ = z; best = f }
            }
            if let f = best {
                let span = ProfileSpan(t0: prev, t1: t, z0: f.plane(a + dir * prev), z1: f.plane(a + dir * t), mass: f.mass)
                // Merge with the previous span when it continues the same straight line.
                if let last = spans.last, abs(last.t1 - span.t0) < 1e-9, abs(last.z1 - span.z0) < 1e-6,
                   abs(last.z(at: span.t1) - span.z1) < 1e-6 * max(1, span.t1 - last.t0) * 100 {
                    spans[spans.count - 1].t1 = span.t1
                    spans[spans.count - 1].z1 = span.z1
                } else {
                    spans.append(span)
                }
            }
            prev = t
        }
        return spans
    }
}

extension RoofEnvelope {
    /// The ring pushed outward by `d` (mitered corners); the ring itself if that would fold.
    static func offset(_ ring: Ring, by d: Double) -> Ring {
        guard d > 1e-6, ring.count >= 3 else { return ring }
        let n = ring.count
        func normal(_ i: Int) -> LocalPoint {
            let e = ring[(i + 1) % n] - ring[i]
            let len = simd_length(e)
            return len > 1e-9 ? LocalPoint(e.y, -e.x) / len : .zero
        }
        var out: Ring = []
        for i in 0..<n {
            let n1 = normal((i + n - 1) % n), n2 = normal(i)
            let denom = max(1 + simd_dot(n1, n2), 0.25)
            out.append(ring[i] + (n1 + n2) * (d / denom))
        }
        // Reject folds: every offset edge must keep its direction.
        for i in 0..<n {
            let a = ring[(i + 1) % n] - ring[i], b = out[(i + 1) % n] - out[i]
            if simd_dot(a, b) <= 0 { return ring }
        }
        return RingMath.signedArea(out) > RingMath.signedArea(ring) ? out : ring
    }
}

// MARK: - Mesh emission

/// Paints and sizes for one roof assembly.
struct RoofPaints {
    var roof: Paint
    var trim: Paint
    var wall: Paint
    /// Wall color above the eave line on gable ends (stucco panel), nil = wall.
    var gable: Paint?
    /// Roof edge thickness (fascia board).
    var fascia: Double = 0.22
    /// Chamfer on the fascia's lower outer edge (0 = none), only on edges facing `bevelToward`.
    var bevel: Double = 0
    var bevelToward = LocalPoint(0, 0)
}

extension RoofEnvelope {
    /// Roof planes; soffits under overhangs; fascia on free edges; vertical faces where one roof
    /// edge stands above a lower roof.
    func emitRoof(paints: RoofPaints, soffits: Bool, fascia: Bool, into m: inout MeshBuffers) {
        if let clip {
            emitClipped(clip, paints: paints, soffits: soffits, fascia: fascia, into: &m)
            return
        }
        m.paint = paints.roof
        for f in fragments {
            m.addCleanFace(f.polygon.map { P($0, f.plane($0)) }, facing: sceneUp)
        }
        if soffits {
            m.paint = paints.trim
            for f in fragments where f.overhang {
                m.addCleanFace(f.polygon.map { P($0, f.plane($0)) }, facing: -sceneUp)
            }
        }
        for (i, mass) in masses.enumerated() {
            let d = mass.domain
            for k in 0..<4 {
                let a = d[k], b = d[(k + 1) % 4]
                let e = b - a
                let outward = simd_normalize(LocalPoint(e.y, -e.x))
                let own = profile(a, b) { $0 == i }
                let others = profile(a, b) { $0 != i }
                for piece in Self.compare(own, others) {
                    let p0 = a + e * piece.t0, p1 = a + e * piece.t1
                    if let lo0 = piece.other0, let lo1 = piece.other1 {
                        // Step: this roof edge stands above another roof surface.
                        guard piece.own0 > lo0 + 0.005 || piece.own1 > lo1 + 0.005 else { continue }
                        m.paint = paints.gable ?? paints.wall
                        m.addCleanFace([P(p0, lo0), P(p1, lo1), P(p1, piece.own1), P(p0, piece.own0)], facing: D(outward))
                    } else if fascia, mass.overhang > 0.01 {
                        let f = paints.fascia
                        m.paint = paints.trim
                        let c = paints.bevel
                        if c > 0, simd_dot(outward, paints.bevelToward) > 0.3 {
                            // Fascia face down to the chamfer, then one 45° face back under the soffit.
                            m.addCleanFace([P(p0, piece.own0 - f + c), P(p1, piece.own1 - f + c), P(p1, piece.own1), P(p0, piece.own0)],
                                           facing: D(outward))
                            let i0 = p0 - outward * c, i1 = p1 - outward * c
                            m.addCleanFace([P(i0, piece.own0 - f), P(i1, piece.own1 - f), P(p1, piece.own1 - f + c), P(p0, piece.own0 - f + c)],
                                           facing: D(outward) - sceneUp)
                        } else {
                            m.addCleanFace([P(p0, piece.own0 - f), P(p1, piece.own1 - f), P(p1, piece.own1), P(p0, piece.own0)],
                                           facing: D(outward))
                        }
                    }
                }
            }
        }
    }

    /// Roof cut to a footprint ring (no overhang): each fragment ∩ ring, triangulated; a thin
    /// fascia along the ring marks the roof edge.
    func emitClipped(_ ring: Ring, paints: RoofPaints, soffits: Bool, fascia: Bool, into m: inout MeshBuffers) {
        for f in fragments {
            let piece = ConvexClip.intersect(ring, ConvexClip.halfPlanes(f.polygon))
            guard piece.count >= 3, abs(ConvexClip.area(piece)) >= ConvexClip.minArea else { continue }
            let tri = Earcut.triangulate(Polygon2D(outer: ConvexClip.ccw(piece)))
            for k in stride(from: 0, to: tri.indices.count - 2, by: 3) {
                let pts = [tri.vertices[tri.indices[k]], tri.vertices[tri.indices[k + 1]], tri.vertices[tri.indices[k + 2]]]
                guard abs(RingMath.signedArea(pts)) > 1e-6 else { continue }
                m.paint = paints.roof
                m.addCleanFace(pts.map { P($0, f.plane($0)) }, facing: sceneUp)
                // Underside (hidden inside the building; the soffit under the eaves).
                if soffits {
                    m.paint = paints.trim
                    m.addCleanFace(pts.map { P($0, f.plane($0)) }, facing: -sceneUp)
                }
            }
        }
        guard fascia else { return }
        m.paint = paints.trim
        for i in 0..<ring.count {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            let e = b - a
            let len = simd_length(e)
            guard len > 1e-6 else { continue }
            let out = LocalPoint(e.y, -e.x) / len
            for s in profile(a, b) {
                let p0 = a + e * s.t0 + out * 0.02, p1 = a + e * s.t1 + out * 0.02
                m.addCleanFace([P(p0, s.z0 - paints.fascia), P(p1, s.z1 - paints.fascia), P(p1, s.z1 + 0.02), P(p0, s.z0 + 0.02)], facing: D(out))
            }
        }
    }

    /// Walls along a footprint ring, from `base` up to the roof. Heights below `bandTop` are
    /// plain quads; above it the wall follows the roof (gable triangles, wing junctions).
    /// Above `gableFrom`, the wall uses `gablePaint` if given.
    func emitWalls(_ ring: Ring, base: Double, bandTop: Double, fallbackTop: Double, wall: (Int) -> Paint,
                   gableFrom: Double, gablePaint: Paint?, into m: inout MeshBuffers) {
        for i in 0..<ring.count {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            let e = b - a
            let len = simd_length(e)
            guard len > 1e-6 else { continue }
            let outward = D(LocalPoint(e.y, -e.x) / len)
            var spans = profile(a, b)
            // Gaps (outside every mass) get the fallback height.
            var filled: [ProfileSpan] = []
            var t = 0.0
            for s in spans {
                if s.t0 > t + 1e-9 { filled.append(ProfileSpan(t0: t, t1: s.t0, z0: fallbackTop, z1: fallbackTop, mass: -1)) }
                filled.append(s)
                t = s.t1
            }
            if t < 1 - 1e-9 { filled.append(ProfileSpan(t0: t, t1: 1, z0: fallbackTop, z1: fallbackTop, mass: -1)) }
            spans = filled
            let lowest = spans.map { min($0.z0, $0.z1) }.min() ?? fallbackTop
            let band = min(bandTop, lowest)
            m.paint = wall(i)
            if band > base + 1e-3 { m.addCleanFace([P(a, base), P(b, base), P(b, band), P(a, band)], facing: outward) }
            let split = max(band, gableFrom)
            for s in spans {
                let p0 = a + e * s.t0, p1 = a + e * s.t1
                // Wall paint up to `split`, then the gable panel.
                let mid0 = min(s.z0, split), mid1 = min(s.z1, split)
                m.paint = wall(i)
                m.addCleanFace([P(p0, band), P(p1, band), P(p1, mid1), P(p0, mid0)], facing: outward)
                if s.z0 > split + 1e-3 || s.z1 > split + 1e-3 {
                    m.paint = gablePaint ?? wall(i)
                    m.addCleanFace([P(p0, mid0), P(p1, mid1), P(p1, s.z1), P(p0, s.z0)], facing: outward)
                }
            }
        }
    }

    /// Pairs two profiles over common breakpoints: own heights plus the other roof's (nil = open).
    struct Comparison { var t0, t1, own0, own1: Double; var other0, other1: Double? }

    static func compare(_ own: [ProfileSpan], _ other: [ProfileSpan]) -> [Comparison] {
        var ts = Set<Double>()
        for s in own { ts.insert(s.t0); ts.insert(s.t1) }
        for s in other { ts.insert(s.t0); ts.insert(s.t1) }
        let sorted = ts.sorted()
        var out: [Comparison] = []
        func at(_ spans: [ProfileSpan], _ t: Double) -> ProfileSpan? { spans.first { t >= $0.t0 - 1e-12 && t <= $0.t1 + 1e-12 } }
        for (t0, t1) in zip(sorted, sorted.dropFirst()) where t1 - t0 > 1e-9 {
            let mid = (t0 + t1) / 2
            guard let o = at(own, mid) else { continue }
            if let x = at(other, mid) {
                // Split where the two lines cross so each piece has a consistent order.
                let d0 = o.z(at: t0) - x.z(at: t0), d1 = o.z(at: t1) - x.z(at: t1)
                if d0 * d1 < 0 {
                    let tc = t0 + (t1 - t0) * d0 / (d0 - d1)
                    out.append(Comparison(t0: t0, t1: tc, own0: o.z(at: t0), own1: o.z(at: tc), other0: x.z(at: t0), other1: x.z(at: tc)))
                    out.append(Comparison(t0: tc, t1: t1, own0: o.z(at: tc), own1: o.z(at: t1), other0: x.z(at: tc), other1: x.z(at: t1)))
                } else {
                    out.append(Comparison(t0: t0, t1: t1, own0: o.z(at: t0), own1: o.z(at: t1), other0: x.z(at: t0), other1: x.z(at: t1)))
                }
            } else {
                out.append(Comparison(t0: t0, t1: t1, own0: o.z(at: t0), own1: o.z(at: t1), other0: nil, other1: nil))
            }
        }
        return out
    }
}

extension MeshBuffers {
    /// `addFace` after dropping repeated points (degenerate corners of wall/roof pieces).
    mutating func addCleanFace(_ pts: [SIMD3<Float>], facing hint: SIMD3<Float>) {
        var out: [SIMD3<Float>] = []
        for p in pts where out.last.map({ simd_distance_squared($0, p) > 1e-10 }) ?? true { out.append(p) }
        while out.count > 1, simd_distance_squared(out[0], out[out.count - 1]) <= 1e-10 { out.removeLast() }
        // Drop nearly collinear corners (clipping leftovers): their fan triangles have no area
        // and float rounding can flip them.
        var changed = true
        while changed, out.count > 3 {
            changed = false
            for i in 0..<out.count {
                let a = out[(i + out.count - 1) % out.count], p = out[i], b = out[(i + 1) % out.count]
                // Within 1 mm of the line through its neighbors.
                if simd_length(simd_cross(a - p, b - p)) < 1e-3 * max(simd_distance(a, b), 1e-3) {
                    out.remove(at: i)
                    changed = true
                    break
                }
            }
        }
        guard out.count >= 3 else { return }
        // Area vector from coordinates relative to the first point (precise for slivers).
        var n = SIMD3<Float>.zero
        for i in 1..<(out.count - 1) { n += simd_cross(out[i] - out[0], out[i + 1] - out[0]) }
        let len = simd_length(n)
        guard len > 2e-5 else { return }
        n /= len
        if simd_dot(n, hint) < 0 { out.reverse(); n = -n }
        let base = UInt32(positions.count)
        for p in out { addVertex(p, normal: n) }
        for i in 1..<(UInt32(out.count) - 1) { addTriangle(base, base + i, base + i + 1) }
    }
}
