import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// Lawn detail that reads at phone scale (look-fix §1.1): broad tonal patches, mowing bands on some
/// lots, worn edges beside walks and drives, and darker ground under trees, hedges and shrubs. All
/// of it is baked into the lawn's own vertices (shade and tone), on a low grid clipped to the lot,
/// so nothing is stacked as an overlay layer that could z-fight with the lawn.
/// How strongly the lawn detail shows (yards.json `groundContrast`). `spec` is look-fix §1.1/§2.3;
/// the owner approved stronger values (2026-10-06) because the spec contrast doesn't read at phone size.
public struct GroundContrast: Codable, Sendable, Equatable {
    /// Patch amplitude range (each patch ±), also the cap on summed patches.
    public var patchAmplitude: [Double]
    /// Value difference between neighbouring mowing bands.
    public var mowContrast: Double
    /// Darkening at the centre of a pool: under trees, under shrubs and hedges.
    public var poolDepth: [Double]
    /// Worn strip: shade lift and tone shift toward the dry endpoint at the hard edge.
    public var wornShade: Double
    public var wornTone: Double

    public static let spec = GroundContrast(patchAmplitude: [0.03, 0.06], mowContrast: 0.03, poolDepth: [0.15, 0.12], wornShade: 0.04, wornTone: 0.4)
}

struct LawnField {
    struct Patch { var c: LocalPoint; var r: Double; var amp: Double }
    struct Mow { var across: LocalPoint; var start: Double; var width: Double; var count: Int; var amp: Double; var front: (LocalPoint, LocalPoint) }
    /// A worn strip on one side of an access line: from its hard edge out to `width`, over [t0, t1] m along it.
    struct Worn { var a: LocalPoint; var u: LocalPoint; var len: Double; var halfHard: Double; var side: Double; var width: Double; var t0: Double; var t1: Double }

    var shade: Float
    var tone: Float
    var seed: Float
    /// The lawnsmooth experiment (LookExperiments): replaces the lot's own shade and tone per vertex.
    var broad: BroadLawn?
    var patches: [Patch] = []
    var mow: Mow?
    var worn: [Worn] = []

    /// Largest summed patch deviation, and the worn edges' lift in shade and tone (from `GroundContrast`).
    var patchLimit = GroundContrast.spec.patchAmplitude[1]
    var wornShade = GroundContrast.spec.wornShade, wornTone = GroundContrast.spec.wornTone

    func patchFactor(_ p: LocalPoint) -> Double {
        var s = 0.0
        for q in patches {
            let d2 = simd_distance_squared(p, q.c) / (q.r * q.r)
            if d2 < 4 { s += q.amp * exp(-d2) }
        }
        return 1 + min(patchLimit, max(-patchLimit, s))
    }

    /// Band index of a point, nil outside the mowed front lawn.
    func band(_ p: LocalPoint) -> Int? {
        guard let m = mow, simd_dot(p - m.front.0, m.front.1) > 0.5 else { return nil }
        let k = Int(((simd_dot(p, m.across) - m.start) / m.width).rounded(.down))
        return k >= 0 && k < m.count ? k : nil
    }

    func mowFactor(_ band: Int?) -> Double {
        guard let k = band, let m = mow else { return 1 }
        return 1 + (k % 2 == 0 ? m.amp : -m.amp) / 2
    }

    /// 0…1: how worn the ground is at `p` (1 at the hard edge, 0 at the strip's outer edge).
    func wear(_ p: LocalPoint) -> Double {
        var w = 0.0
        for s in worn {
            let d = p - s.a
            let t = simd_dot(d, s.u)
            guard t > s.t0 - 0.01, t < s.t1 + 0.01 else { continue }
            let off = (d.x * -s.u.y + d.y * s.u.x) * s.side - s.halfHard
            guard off > -0.6, off < s.width + 0.01 else { continue }
            let across = 1 - max(0, off) / s.width
            let ends = min(1, (t - s.t0) / 1.5, (s.t1 - t) / 1.5)
            w = max(w, max(0, across) * max(0, ends))
        }
        return w
    }

    /// Lines that split lawn pieces so worn strips get vertices on their edges.
    func splitLines() -> [(line: Linear2, a: LocalPoint, u: LocalPoint, len: Double, reach: Double)] {
        worn.flatMap { s -> [(line: Linear2, a: LocalPoint, u: LocalPoint, len: Double, reach: Double)] in
            let n = LocalPoint(-s.u.y, s.u.x) * s.side
            return [s.halfHard, s.halfHard + s.width].map { off in
                let p = s.a + n * off
                return (Linear2.leftOf(p, p + s.u), s.a, s.u, s.len, s.halfHard + s.width + 0.5)
            }
        }
    }
}

/// Darker ground under crowns, hedges and shrubs (contact shade baked into lawn vertices).
struct GroundPools {
    struct Pool { var p: LocalPoint; var r: Double; var depth: Double }
    private var cells: [SIMD2<Int>: [Pool]] = [:]
    private let cell = 8.0
    init(_ instances: [PropInstance], treeDepth: Double = GroundContrast.spec.poolDepth[0], shrubDepth: Double = GroundContrast.spec.poolDepth[1]) {
        for inst in instances {
            let p = LocalPoint(inst.x, inst.y)
            if inst.kind.isTree {
                let crown = Double(PropLibrary.lobes(inst.kind).radii.x) * inst.scale * max(inst.stretch.x, inst.stretch.y)
                add(Pool(p: p, r: max(1.5, crown * 0.85), depth: treeDepth))
            } else if inst.kind == .bush || inst.kind == .flowerBush {
                add(Pool(p: p, r: max(1.0, 1.5 * inst.scale), depth: shrubDepth))
            }
        }
    }

    private mutating func add(_ q: Pool) { cells[key(q.p), default: []].append(q) }
    private func key(_ p: LocalPoint) -> SIMD2<Int> { SIMD2(Int((p.x / cell).rounded(.down)), Int((p.y / cell).rounded(.down))) }

    /// Multiplier ≤ 1 (deepest pool wins; pools never stack).
    func factor(_ p: LocalPoint) -> Double {
        let k = key(p)
        var f = 1.0
        for dj in -1...1 { for di in -1...1 {
            for q in cells[k &+ SIMD2(di, dj)] ?? [] {
                let d = simd_distance(p, q.p) / q.r
                guard d < 1 else { continue }
                let s = 1 - d * d
                f = min(f, 1 - q.depth * s * s)
            }
        } }
        return f
    }
}

enum GroundDetail {
    /// Lawn grid spacing along the bands (m); across them it is the band width or this.
    static let gridStep = 4.0

    /// The lot lawn on a grid clipped to its rings, every vertex shaded by the field and pools.
    static func lawnMesh(_ rings: [Ring], field: LawnField, pools: GroundPools, slot: Int, y: Double) -> MeshBuffers {
        var m = MeshBuffers()
        let across = field.mow?.across ?? LocalPoint(1, 0)
        let along = LocalPoint(-across.y, across.x)
        let wa = field.mow?.width ?? gridStep, oa = field.mow?.start ?? 0
        let splits = field.splitLines()
        // Each ring is clipped once per grid cell (Sutherland–Hodgman against the convex cell is
        // exact for a concave ring up to zero-area bridges, which the triangulation drops), so an
        // inside cell costs two triangles.
        for ring0 in rings {
            let ring = RingMath.signedArea(ring0) < 0 ? Array(ring0.reversed()) : ring0
            let pa = ring.map { simd_dot($0, across) }, pb = ring.map { simd_dot($0, along) }
            let i0 = Int(((pa.min()! - oa) / wa).rounded(.down)), i1 = Int(((pa.max()! - oa) / wa).rounded(.down))
            let j0 = Int((pb.min()! / gridStep).rounded(.down)), j1 = Int((pb.max()! / gridStep).rounded(.down))
            for i in i0...i1 { for j in j0...j1 {
                let a0 = oa + Double(i) * wa, b0 = Double(j) * gridStep
                var piece = ConvexClip.clip(ring, keep: Linear2(a: across, c: -a0))
                piece = ConvexClip.clip(piece, keep: Linear2(a: -across, c: a0 + wa))
                piece = ConvexClip.clip(piece, keep: Linear2(a: along, c: -b0))
                piece = ConvexClip.clip(piece, keep: Linear2(a: -along, c: b0 + gridStep))
                guard piece.count >= 3, abs(ConvexClip.area(piece)) > 0.05 else { continue }
                // Concave leftovers: triangulate, then treat each triangle as a convex piece.
                var convex: [[LocalPoint]] = []
                if piece.count <= 4 || isConvex(piece) {
                    convex = [piece]
                } else {
                    let tri = Earcut.triangulate(Polygon2D(outer: piece))
                    for k in stride(from: 0, to: tri.indices.count - 2, by: 3) {
                        let t = [tri.vertices[tri.indices[k]], tri.vertices[tri.indices[k + 1]], tri.vertices[tri.indices[k + 2]]]
                        if abs(RingMath.signedArea(t)) > 1e-4 { convex.append(RingMath.signedArea(t) < 0 ? t.reversed() : t) }
                    }
                }
                for pc in convex {
                    var pieces = [pc]
                    for s in splits {
                        let c = pc.reduce(LocalPoint(0, 0), +) / Double(pc.count)
                        let d = c - s.a, t = simd_dot(d, s.u)
                        guard t > -3, t < s.len + 3, abs(d.x * -s.u.y + d.y * s.u.x) < s.reach + 3 else { continue }
                        pieces = pieces.flatMap { p in
                            [ConvexClip.clip(p, keep: s.line), ConvexClip.clip(p, keep: -s.line)].filter { $0.count >= 3 && ConvexClip.area($0) > ConvexClip.minArea }
                        }
                    }
                    for p in pieces { addPiece(p, field: field, pools: pools, slot: slot, y: y, into: &m) }
                }
            } }
        }
        return m
    }

    static func isConvex(_ p: [LocalPoint]) -> Bool {
        var sign = 0.0
        for i in p.indices {
            let a = p[i], b = p[(i + 1) % p.count], c = p[(i + 2) % p.count]
            let z = RingMath.cross(b - a, c - b)
            if abs(z) < 1e-9 { continue }
            if sign == 0 { sign = z } else if (z > 0) != (sign > 0) { return false }
        }
        return true
    }

    static func addPiece(_ poly: [LocalPoint], field: LawnField, pools: GroundPools, slot: Int, y: Double, into m: inout MeshBuffers) {
        let c = poly.reduce(LocalPoint(0, 0), +) / Double(poly.count)
        let mow = field.mowFactor(field.band(c))
        var idx: [UInt32] = []
        for p in poly {
            let w = field.wear(p)
            let base = field.broad?.shade(p) ?? Double(field.shade), tone = field.broad?.tone(p) ?? field.tone
            let shade = base * field.patchFactor(p) * mow * pools.factor(p) * (1 + field.wornShade * w)
            m.paint = Paint(slot: slot, shade: Float(shade), flags: .lawn)
            m.extra = SIMD4(1, min(1, tone + Float(field.wornTone * w)), 0, field.seed)
            idx.append(m.addVertex(P(p, y), normal: sceneUp))
        }
        for k in 1..<(poly.count - 1) {
            let a = m.positions[Int(idx[0])], b = m.positions[Int(idx[k])], cc = m.positions[Int(idx[k + 1])]
            if simd_cross(b - a, cc - a).y >= 0 { m.addTriangle(idx[0], idx[k], idx[k + 1]) } else { m.addTriangle(idx[0], idx[k + 1], idx[k]) }
        }
    }

    /// Parkway strips between curb and sidewalk (look-fix §1.4: curb/parkway definition at postcard
    /// range): drier lawn tone, darker toward the curb, pools under street trees.
    static func parkways(_ roads: [WayFeature], raster: LotRaster, roadLines: SegmentIndex, pools: GroundPools,
                         slot: Int, include: (LocalPoint) -> Bool) -> MeshBuffers {
        var m = MeshBuffers()
        let step = 3.0
        for road in roads where road.kind.isVehicular && road.kind != .service && road.kind != .track
            && road.kind != .motorway && road.kind != .trunk && !road.isBridge && !road.isTunnel {
            var sr = StableRandom(UInt64(bitPattern: road.ref.id), 0, salt: "parkway")
            let seed = Float(sr.unit())
            for (a, b) in zip(road.centerline, road.centerline.dropFirst()) {
                let d = b - a
                let len = simd_length(d)
                guard len > step else { continue }
                let u = d / len, nrm = LocalPoint(-u.y, u.x)
                let edge = road.width / 2 + 0.2
                for side in [-1.0, 1.0] {
                    var prev: (LocalPoint, Double)?
                    var t = 0.0
                    while t <= len {
                        let c = a + u * t
                        var strip: Double?
                        if include(c), roadLines.nearest(to: c, within: 9).map({ simd_dot($0.direction, u).magnitude > 0.9 }) ?? true {
                            var dd = edge
                            while dd < edge + 6 {
                                guard let use = raster.useAt(c + nrm * (side * dd)) else { break }
                                if use == .walkway { strip = dd - edge; break }
                                if use != LotRaster.Use.open && use != LotRaster.Use.hard { break }
                                dd += 0.25
                            }
                        }
                        if let s = strip, s >= 0.6, raster.ownerAt(c + nrm * (side * (edge + s / 2))) < 0 {
                            if let (pc, ps) = prev {
                                let ring = [pc + nrm * (side * edge), c + nrm * (side * edge), c + nrm * (side * (edge + s)), pc + nrm * (side * (edge + ps))]
                                let curb = [true, true, false, false]
                                var idx: [UInt32] = []
                                for (p, atCurb) in zip(ring, curb) {
                                    m.paint = Paint(slot: slot, shade: Float((atCurb ? 0.88 : 0.98) * pools.factor(p)), flags: .lawn)
                                    m.extra = SIMD4(1, atCurb ? 0.8 : 0.6, 0, max(seed, 0.001))
                                    idx.append(m.addVertex(P(p, GroundLayer.yard), normal: sceneUp))
                                }
                                let p0 = m.positions[Int(idx[0])], p1 = m.positions[Int(idx[1])], p2 = m.positions[Int(idx[2])]
                                if simd_cross(p1 - p0, p2 - p0).y >= 0 {
                                    m.addTriangle(idx[0], idx[1], idx[2]); m.addTriangle(idx[0], idx[2], idx[3])
                                } else {
                                    m.addTriangle(idx[0], idx[2], idx[1]); m.addTriangle(idx[0], idx[3], idx[2])
                                }
                            }
                            prev = (c, s)
                        } else {
                            prev = nil
                        }
                        t += step
                    }
                }
            }
        }
        return m
    }
}

/// A lot lawn waiting for the contact pools (emitted after all planting).
struct LawnJob {
    var rings: [Ring]
    var field: LawnField
    var detailed: Bool
    var anchor: LocalPoint
    var feature: String
}

extension GroundDetail {
    /// Outside the detailed region: the lot's own shade and tone on its plain triangulation.
    static func plainLawn(_ rings: [Ring], field: LawnField, slot: Int, y: Double) -> MeshBuffers {
        var m = MeshBuffers()
        m.paint = Paint(slot: slot, shade: field.shade, flags: .lawn)
        m.extra = SIMD4(1, field.tone, 0, field.seed)
        for ring in rings {
            let tri = Earcut.triangulate(Polygon2D(outer: ring))
            for k in stride(from: 0, to: tri.indices.count - 2, by: 3) {
                let a = P(tri.vertices[tri.indices[k]], y), b = P(tri.vertices[tri.indices[k + 1]], y), c = P(tri.vertices[tri.indices[k + 2]], y)
                func add(_ q: SIMD3<Float>, _ v: LocalPoint) -> UInt32 {
                    if let broad = field.broad {
                        m.paint = Paint(slot: slot, shade: Float(broad.shade(v)), flags: .lawn)
                        m.extra = SIMD4(1, broad.tone(v), 0, field.seed)
                    }
                    return m.addVertex(q, normal: sceneUp)
                }
                let i0 = add(a, tri.vertices[tri.indices[k]]), i1 = add(b, tri.vertices[tri.indices[k + 1]]), i2 = add(c, tri.vertices[tri.indices[k + 2]])
                if simd_cross(b - a, c - a).y >= 0 { m.addTriangle(i0, i1, i2) } else { m.addTriangle(i0, i2, i1) }
            }
        }
        return m
    }
}
