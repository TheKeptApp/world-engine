import Foundation
import simd
import WorldGeo
import WorldMesh

/// Instanced prop kinds. Each (kind, variant) is one mesh drawn many times.
/// For trees the variant is the detail level: 0 near, 1 mid, 2 far.
public enum PropKind: String, Sendable, CaseIterable, Codable {
    case treeBroad, treeOval, treeSpreading, conifer, lamp, bench, bush, flowerBush, tuft

    public var isTree: Bool { [.treeBroad, .treeOval, .treeSpreading, .conifer].contains(self) }
    public var isFoliage: Bool { ![.lamp, .bench].contains(self) }
}

/// Reusable prop meshes in object space (scene axes, origin on the ground, +Y up).
/// Organic props have shared vertices and smooth normals; built objects are flat-shaded.
public struct PropLibrary: Sendable {
    /// Shape variants per kind (instances pick one at generation time).
    public static let variants: [PropKind: Int] = [
        .treeBroad: 1, .treeOval: 1, .treeSpreading: 1, .conifer: 1, .lamp: 1, .bench: 1, .bush: 2, .flowerBush: 2, .tuft: 2,
    ]

    /// Detail levels per kind: trees and bushes have near/mid/far meshes, chosen at render time.
    public static func lodCount(_ kind: PropKind) -> Int { kind.isTree || kind == .bush || kind == .flowerBush ? 3 : 1 }

    /// Distances (m) where LOD props switch from near to mid and mid to far detail.
    public static let lodDistances: [Double] = [45, 160]
    /// Renderers re-bucket LOD props when the camera has moved this far (m).
    public static let lodRebucketMeters: Double = 8
    /// Instanced props are grouped into square cells of this size (m) so renderers can cull them.
    public static let cellMeters: Double = 400

    /// The cell a prop belongs to (local meters east/north → integer cell coordinates).
    public static func cell(x: Double, y: Double) -> SIMD2<Int> {
        SIMD2(Int((x / cellMeters).rounded(.down)), Int((y / cellMeters).rounded(.down)))
    }

    /// Crown lobes (center, radius) in unit-height tree space for each archetype.
    static func lobes(_ kind: PropKind) -> (trunkTop: Float, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)]) {
        switch kind {
        case .treeOval:
            // Upright oval: narrow, tall crown of stacked lobes.
            return (0.40, [0, 0.68, 0], [0.19, 0.30, 0.19], [
                ([0, 0.84, 0], 0.15), ([0.05, 0.66, 0.04], 0.18), ([-0.06, 0.58, -0.03], 0.16), ([0.02, 0.50, -0.07], 0.13),
            ])
        case .treeSpreading:
            // Open spreading: wide, flatter crown of five lobes.
            return (0.46, [0, 0.66, 0], [0.36, 0.19, 0.34], [
                ([0, 0.74, 0], 0.18), ([0.22, 0.64, 0.05], 0.15), ([-0.2, 0.65, -0.08], 0.16),
                ([0.04, 0.63, 0.22], 0.14), ([-0.06, 0.62, -0.23], 0.14),
            ])
        default:
            // Broad rounded: one top lobe over three around it.
            return (0.44, [0, 0.66, 0], [0.29, 0.24, 0.29], [
                ([0, 0.78, 0], 0.2), ([0.15, 0.62, 0.06], 0.17), ([-0.13, 0.63, 0.1], 0.16), ([0.0, 0.6, -0.16], 0.17),
            ])
        }
    }

    /// Mesh for a prop variant. Trees and lamps are unit height (scale by instance); benches,
    /// bushes and tufts are real size.
    public static func mesh(_ kind: PropKind, variant: Int, lod: Int = 0, palette: Palette) -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, UInt64(variant), salt: "prop")
        switch kind {
        case .treeBroad, .treeOval, .treeSpreading:
            return deciduous(kind, lod: lod, palette: palette, rng: &rng)
        case .conifer:
            return conifer(lod: lod, palette: palette)
        case .lamp:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("metal"))
            addCylinder(&m, radius: 0.15, z0: 0, z1: 0.32, sides: 8, smooth: false)
            m.bakeAO(from: 0) { p, _ in p.y < 0.05 ? 0.75 : 1 }
            addCylinder(&m, radius: 0.05, z0: 0.32, z1: 3.55, sides: 8, smooth: true)
            addCylinder(&m, radius: 0.12, z0: 3.55, z1: 3.62, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("lampGlow"), flags: .emissive)
            addCylinder(&m, radius: 0.16, z0: 3.62, z1: 4.0, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("metal"))
            addCone(&m, radius: 0.22, z0: 4.0, z1: 4.28, sides: 8)
            return m
        case .bench:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bench"))
            box(&m, c: SIMD3(0, 0.45, 0), half: SIMD3(0.85, 0.03, 0.22))           // seat 1.7 m wide, 0.45 m high
            box(&m, c: SIMD3(0, 0.73, -0.22), half: SIMD3(0.85, 0.15, 0.025))      // back
            m.bakeAO(from: 0) { _, n in n.y < -0.5 ? 0.7 : 1 }
            m.paint = Paint(slot: palette.named("metal"))
            let legs = m.positions.count
            for x: Float in [-0.72, 0.72] {
                box(&m, c: SIMD3(x, 0.21, 0.15), half: SIMD3(0.03, 0.21, 0.03))
                box(&m, c: SIMD3(x, 0.45, -0.2), half: SIMD3(0.03, 0.45, 0.03))
            }
            m.bakeAO(from: legs) { p, _ in p.y < 0.05 ? 0.75 : 1 }
            return m
        case .bush, .flowerBush:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bushes"), shade: kind == .flowerBush ? 1.08 : 1, sway: 0.2)
            let start = m.positions.count
            let radius: Float = variant == 0 ? 0.55 : 0.47
            if lod < 2 {
                // Near: subdivided icosahedron (80 triangles); mid: plain icosahedron (20).
                addBlob(&m, center: SIMD3(0, 0.36, 0), radius: radius, squash: 0.72, jitter: lod == 0 ? 0.08 : 0.04, rng: &rng, subdivide: lod == 0)
            } else {
                addEllipsoid(&m, center: SIMD3(0, 0.36, 0), radii: SIMD3(radius, radius * 0.72, radius), octahedron: true)
            }
            m.bakeAO(from: start) { p, _ in Float(0.62 + 0.38 * smoothstep(0.0, 0.55, Double(p.y))) }
            return m
        case .tuft:
            // R3 stylized tuft: 4–5 chunky tapered blades, partly double-sided: 15–21 triangles.
            var m = MeshBuffers()
            let blades = variant == 0 ? 4 : 5
            for k in 0..<blades {
                let a = Float(k) / Float(blades) * 2 * .pi + Float(rng.range(-0.35, 0.35))
                let dirOut = SIMD3<Float>(cos(a), 0, sin(a))
                let side = SIMD3<Float>(-sin(a), 0, cos(a)) * Float(rng.range(0.028, 0.04))
                let base = dirOut * 0.02
                let height = Float(rng.range(0.16, 0.27))
                let lean = Float(rng.range(0.05, 0.1))
                let mid = base + dirOut * (lean * 0.45) + SIMD3(0, height * 0.55, 0)
                let tip = base + dirOut * lean + SIMD3(0, height, 0)
                let n = simd_normalize(dirOut * 0.6 + SIMD3(0, 0.8, 0))
                func blade(_ flip: Bool) {
                    m.paint = Paint(slot: palette.named("tufts"), shade: 0.88, flags: .distanceFade, sway: 0)
                    m.extra = SIMD4(0.8, 0, 0, 0)
                    let i0 = m.addVertex(base - side, normal: n)
                    let i1 = m.addVertex(base + side, normal: n)
                    m.paint = Paint(slot: palette.named("tufts"), shade: 1.0, flags: .distanceFade, sway: 0.6)
                    m.extra = SIMD4(0.95, 0, 0, 0)
                    let i2 = m.addVertex(mid + side * 0.75, normal: n)
                    let i3 = m.addVertex(mid - side * 0.75, normal: n)
                    m.paint = Paint(slot: palette.named("tufts"), shade: 1.1, flags: .distanceFade, sway: 1)
                    m.extra = SIMD4(1, 0, 0, 0)
                    let i4 = m.addVertex(tip, normal: n)
                    if flip {
                        m.addTriangle(i0, i2, i1); m.addTriangle(i0, i3, i2); m.addTriangle(i3, i4, i2)
                    } else {
                        m.addTriangle(i0, i1, i2); m.addTriangle(i0, i2, i3); m.addTriangle(i3, i2, i4)
                    }
                }
                blade(false)
                if k % 2 == 0 { blade(true) }
            }
            m.extra = SIMD4(1, 0, 0, 0)
            return m
        }
    }

    // MARK: - Trees

    static func deciduous(_ kind: PropKind, lod: Int, palette: Palette, rng: inout StableRandom) -> MeshBuffers {
        var m = MeshBuffers()
        let shape = lobes(kind)
        // Trunk: thin, bark-colored; AO darker where it enters the crown.
        m.paint = Paint(slot: palette.named("bark"))
        let trunkStart = m.positions.count
        let trunkR: Float = kind == .treeSpreading ? 0.022 : 0.018
        addCylinder(&m, radius: trunkR, z0: 0, z1: shape.trunkTop + 0.08, sides: lod == 0 ? 7 : (lod == 1 ? 5 : 3), smooth: true, cap: false)
        m.bakeAO(from: trunkStart) { p, _ in Float(0.85 - 0.3 * smoothstep(Double(shape.trunkTop) - 0.12, Double(shape.trunkTop), Double(p.y))) }
        if kind == .treeSpreading, lod < 2 {
            for (target, _) in shape.lobes.dropFirst().prefix(2) {
                addBranch(&m, from: SIMD3(0, shape.trunkTop - 0.04, 0), to: target * SIMD3(0.7, 1, 0.7), radius: 0.012, sides: lod == 0 ? 5 : 4)
            }
        }
        // Crown: one color family per tree (the shader picks deciduous1…4 per instance); lobes
        // share a softened ellipsoid normal so the crown reads as one sculpted mass.
        m.paint = Paint(slot: palette.named("deciduous1"), flags: .variant4, sway: 1)
        if lod == 2 {
            let start = m.positions.count
            addEllipsoid(&m, center: shape.crown, radii: shape.radii * 0.95, octahedron: true)
            bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: [])
            return m
        }
        let lobes = lod == 0 ? shape.lobes : Array(shape.lobes.prefix(2))
        let start = m.positions.count
        for (c, r) in lobes {
            let lobeStart = m.positions.count
            addBlob(&m, center: c, radius: r * (lod == 0 ? 1 : 1.25), squash: 0.92, jitter: lod == 0 ? 0.05 : 0, rng: &rng, subdivide: true)
            for i in lobeStart..<m.positions.count {
                let q = (m.positions[i] - shape.crown) / shape.radii
                let crownN = simd_normalize(q / shape.radii)
                m.normals[i] = simd_normalize(m.normals[i] * 0.5 + crownN * 0.5)
            }
        }
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: lobes)
        return m
    }

    /// Crown AO: lower and interior parts darker, lobe overlaps darker (R1).
    static func bakeCrownAO(_ m: inout MeshBuffers, from start: Int, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)]) {
        for i in start..<m.positions.count {
            let p = m.positions[i]
            let rel = (p.y - crown.y) / radii.y
            var ao = 0.66 + 0.34 * Float(smoothstep(-1.0, 0.7, Double(rel)))
            for (c, r) in lobes where simd_distance(p, c) < r * 0.98 { ao *= 0.86 }
            m.extras[i].x = min(m.extras[i].x, ao)
        }
    }

    static func conifer(lod: Int, palette: Palette) -> MeshBuffers {
        var m = MeshBuffers()
        m.paint = Paint(slot: palette.named("bark"))
        addCylinder(&m, radius: 0.018, z0: 0, z1: 0.22, sides: lod == 0 ? 6 : 3, smooth: true, cap: false)
        m.bakeAO(from: 0) { p, _ in p.y > 0.15 ? 0.6 : 0.85 }
        m.paint = Paint(slot: palette.named("conifer1"), flags: .variant2, sway: 0.5)
        let start = m.positions.count
        let tiers: [(Float, Float, Float)] = lod == 2 ? [(0.14, 1.0, 0.24)]
            : [(0.14, 0.58, 0.26), (0.38, 0.8, 0.2), (0.6, 1.0, 0.13)]
        for (z0, z1, r) in tiers { addCone(&m, radius: r, z0: z0, z1: z1, sides: lod == 0 ? 10 : (lod == 1 ? 7 : 5)) }
        m.bakeAO(from: start) { p, n in n.y < -0.5 ? 0.6 : Float(0.7 + 0.3 * smoothstep(0.1, 0.9, Double(p.y))) }
        return m
    }

    static func addBranch(_ m: inout MeshBuffers, from a: SIMD3<Float>, to b: SIMD3<Float>, radius: Float, sides: Int) {
        let axis = simd_normalize(b - a)
        let helper: SIMD3<Float> = abs(axis.y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
        let u = simd_normalize(simd_cross(axis, helper)), v = simd_cross(axis, u)
        let base = UInt32(m.positions.count)
        for i in 0..<sides {
            let t = Float(i) / Float(sides) * 2 * .pi
            let n = u * cos(t) + v * sin(t)
            m.extra = SIMD4(0.75, 0, 0, 0)
            m.addVertex(a + n * radius, normal: n)
            m.addVertex(b + n * radius * 0.6, normal: n)
        }
        m.extra = SIMD4(1, 0, 0, 0)
        for i in 0..<UInt32(sides) {
            let j = (i + 1) % UInt32(sides)
            m.addTriangle(base + i * 2, base + j * 2, base + j * 2 + 1)
            m.addTriangle(base + i * 2, base + j * 2 + 1, base + i * 2 + 1)
        }
    }

    // MARK: - Builders

    static func box(_ m: inout MeshBuffers, c: SIMD3<Float>, half h: SIMD3<Float>) {
        let x = SIMD3<Float>(h.x, 0, 0), y = SIMD3<Float>(0, h.y, 0), z = SIMD3<Float>(0, 0, h.z)
        let faces: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = [(y, x, z), (-y, x, z), (x, y, z), (-x, y, z), (z, x, y), (-z, x, y)]
        for (n, a, b) in faces {
            let o = c + n
            m.addFace([o - a - b, o + a - b, o + a + b, o - a + b], facing: simd_normalize(n))
        }
    }

    /// Cylinder side (+ optional top cap), `sides` segments; smooth or flat normals.
    static func addCylinder(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, sides: Int, smooth: Bool, cap: Bool = true) {
        for i in 0..<sides {
            let a0 = Float(i) / Float(sides) * 2 * .pi, a1 = Float(i + 1) / Float(sides) * 2 * .pi
            let p0 = SIMD3(cos(a0) * r, 0, sin(a0) * r), p1 = SIMD3(cos(a1) * r, 0, sin(a1) * r)
            if smooth {
                let n0 = simd_normalize(p0), n1 = simd_normalize(p1)
                let b = m.addVertex(p0 + SIMD3(0, z0, 0), normal: n0)
                m.addVertex(p1 + SIMD3(0, z0, 0), normal: n1)
                m.addVertex(p1 + SIMD3(0, z1, 0), normal: n1)
                m.addVertex(p0 + SIMD3(0, z1, 0), normal: n0)
                m.addTriangle(b, b + 2, b + 1)
                m.addTriangle(b, b + 3, b + 2)
            } else {
                m.addFace([p0 + SIMD3(0, z0, 0), p1 + SIMD3(0, z0, 0), p1 + SIMD3(0, z1, 0), p0 + SIMD3(0, z1, 0)],
                          facing: simd_normalize(p0 + p1))
            }
        }
        guard cap else { return }
        let top = (0..<sides).map { i -> SIMD3<Float> in
            let a = Float(i) / Float(sides) * 2 * .pi
            return SIMD3(cos(a) * r, z1, sin(a) * r)
        }
        m.addFace(top, facing: sceneUp)
    }

    /// Smooth cone with a flat underside.
    static func addCone(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, sides: Int) {
        let h = z1 - z0
        let slope = r / h
        let apex = m.addVertex(SIMD3(0, z1, 0), normal: SIMD3(0, 1, 0))
        var ring: [UInt32] = []
        for i in 0..<sides {
            let a = Float(i) / Float(sides) * 2 * .pi
            let n = simd_normalize(SIMD3(cos(a), slope, sin(a)))
            ring.append(m.addVertex(SIMD3(cos(a) * r, z0, sin(a) * r), normal: n))
        }
        for i in 0..<sides { m.addTriangle(apex, ring[(i + 1) % sides], ring[i]) }
        let shade = m.paint
        m.paint = Paint(slot: shade.slot, shade: shade.shade * 0.8, flags: shade.flags, sway: shade.sway)
        let base = (0..<sides).map { i -> SIMD3<Float> in
            let a = Float(i) / Float(sides) * 2 * .pi
            return SIMD3(cos(a) * r, z0, sin(a) * r)
        }
        m.addFace(base, facing: -sceneUp)
        m.paint = shade
    }

    /// A smooth, slightly lumpy blob (icosphere: 80 triangles subdivided, 20 not).
    static func addBlob(_ m: inout MeshBuffers, center: SIMD3<Float>, radius: Float, squash: Float, jitter: Double,
                        rng: inout StableRandom, subdivide: Bool = true) {
        var (verts, faces) = icosahedron()
        if subdivide { (verts, faces) = subdivided(verts, faces) }
        let base = UInt32(m.positions.count)
        for v in verts {
            let k = Float(1 + rng.range(-jitter, jitter))
            let p = v * radius * k
            let pos = center + SIMD3(p.x, p.y * squash, p.z)
            let n = simd_normalize(SIMD3(v.x, v.y / max(squash, 0.01), v.z))
            m.addVertex(pos, normal: n)
        }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    /// A smooth ellipsoid (octahedron, 8 triangles; or icosahedron, 20).
    static func addEllipsoid(_ m: inout MeshBuffers, center: SIMD3<Float>, radii: SIMD3<Float>, octahedron: Bool) {
        let (verts, faces): ([SIMD3<Float>], [SIMD3<UInt32>]) = octahedron
            ? ([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]],
               [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]])
            : icosahedron()
        let base = UInt32(m.positions.count)
        for v in verts { m.addVertex(center + v * radii, normal: simd_normalize(v / radii)) }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    static func icosahedron() -> ([SIMD3<Float>], [SIMD3<UInt32>]) {
        let t: Float = (1 + 5.0.squareRoot().float) / 2
        let v: [SIMD3<Float>] = [
            [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t],
            [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
        ].map { simd_normalize($0) }
        let f: [SIMD3<UInt32>] = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
        ]
        return (v, f)
    }

    static func subdivided(_ v: [SIMD3<Float>], _ f: [SIMD3<UInt32>]) -> ([SIMD3<Float>], [SIMD3<UInt32>]) {
        var verts = v
        var cache: [UInt64: UInt32] = [:]
        func mid(_ a: UInt32, _ b: UInt32) -> UInt32 {
            let key = UInt64(min(a, b)) << 32 | UInt64(max(a, b))
            if let i = cache[key] { return i }
            verts.append(simd_normalize((verts[Int(a)] + verts[Int(b)]) / 2))
            cache[key] = UInt32(verts.count - 1)
            return UInt32(verts.count - 1)
        }
        var faces: [SIMD3<UInt32>] = []
        for t in f {
            let a = mid(t.x, t.y), b = mid(t.y, t.z), c = mid(t.z, t.x)
            faces += [[t.x, a, c], [t.y, b, a], [t.z, c, b], [a, b, c]]
        }
        return (verts, faces)
    }
}

extension Double {
    var float: Float { Float(self) }
}

extension String {
    /// FNV-1a hash, stable across runs (unlike `hashValue`).
    var hashValueStable: UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in utf8 { h ^= UInt64(b); h &*= 0x100_0000_01B3 }
        return h
    }
}
