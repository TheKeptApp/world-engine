import Foundation
import simd
import WorldGeo
import WorldMesh

/// Instanced prop kinds. Each (kind, variant) is one mesh drawn many times.
public enum PropKind: String, Sendable, CaseIterable {
    case deciduousTree, conifer, lowTree, lamp, bench, bush, flowerBush, tuft
}

/// Reusable prop meshes in object space (scene axes, origin on the ground, +Y up).
/// Organic props have shared vertices and smooth normals; built objects are flat-shaded.
public struct PropLibrary: Sendable {
    public static let variants: [PropKind: Int] = [
        .deciduousTree: 3, .conifer: 2, .lowTree: 2, .lamp: 1, .bench: 1, .bush: 2, .flowerBush: 1, .tuft: 2,
    ]

    /// Mesh for a prop variant. Trees and lamps are unit height (scale by instance);
    /// benches, bushes and tufts are real size.
    public static func mesh(_ kind: PropKind, variant: Int, palette: Palette) -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, UInt64(variant), salt: "prop")
        switch kind {
        case .deciduousTree:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("trunk"))
            addCylinder(&m, radius: 0.02, z0: 0, z1: 0.55, sides: 6, smooth: true)
            m.paint = Paint(slot: palette.named(variant == 1 ? "leavesAlt" : "leaves"), sway: 1)
            let lobes = variant == 2 ? 3 : 1
            for k in 0..<lobes {
                let off = lobes == 1 ? SIMD3<Float>(0, 0, 0)
                    : SIMD3(Float(cos(Double(k) * 2.1)) * 0.12, Float(rng.range(-0.04, 0.06)), Float(sin(Double(k) * 2.1)) * 0.12)
                addBlob(&m, center: SIMD3(0, 0.72, 0) + off, radius: lobes == 1 ? 0.28 : 0.21,
                        squash: 0.9, jitter: 0.1, rng: &rng)
            }
            return m
        case .conifer:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("trunk"))
            addCylinder(&m, radius: 0.022, z0: 0, z1: 0.2, sides: 6, smooth: true)
            m.paint = Paint(slot: palette.named("conifer"), sway: 0.6)
            let tiers: [(Float, Float, Float)] = variant == 0
                ? [(0.14, 0.56, 0.27), (0.36, 0.8, 0.21), (0.6, 1.0, 0.14)]
                : [(0.12, 0.62, 0.23), (0.42, 1.0, 0.17)]
            for (z0, z1, r) in tiers { addCone(&m, radius: r, z0: z0, z1: z1, sides: 9) }
            return m
        case .lowTree:
            // Context tree: 8-sided bipyramid canopy + 4-sided trunk.
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("trunk"))
            addCylinder(&m, radius: 0.04, z0: 0, z1: 0.4, sides: 4, smooth: false)
            m.paint = Paint(slot: palette.named(variant == 0 ? "leaves" : "conifer"))
            if variant == 0 {
                addBlob(&m, center: SIMD3(0, 0.64, 0), radius: 0.33, squash: 0.85, jitter: 0, rng: &rng, subdivide: false)
            } else {
                addCone(&m, radius: 0.24, z0: 0.15, z1: 1.0, sides: 6)
            }
            return m
        case .lamp:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("metal"))
            addCylinder(&m, radius: 0.16, z0: 0, z1: 0.35, sides: 8, smooth: false)
            addCylinder(&m, radius: 0.055, z0: 0.35, z1: 3.55, sides: 8, smooth: true)
            addCylinder(&m, radius: 0.12, z0: 3.55, z1: 3.62, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("lampGlow"), flags: .emissive)
            addCylinder(&m, radius: 0.17, z0: 3.62, z1: 4.05, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("metal"))
            addCone(&m, radius: 0.23, z0: 4.05, z1: 4.32, sides: 8)
            return m
        case .bench:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bench"))
            box(&m, c: SIMD3(0, 0.44, 0), half: SIMD3(0.8, 0.03, 0.22))           // seat
            box(&m, c: SIMD3(0, 0.72, -0.22), half: SIMD3(0.8, 0.16, 0.025))      // back
            m.paint = Paint(slot: palette.named("metal"))
            for x: Float in [-0.68, 0.68] {
                box(&m, c: SIMD3(x, 0.21, 0.15), half: SIMD3(0.03, 0.21, 0.03))
                box(&m, c: SIMD3(x, 0.45, -0.2), half: SIMD3(0.03, 0.45, 0.03))
            }
            return m
        case .bush, .flowerBush:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bush"), sway: 0.25)
            let start = m.positions.count
            addBlob(&m, center: SIMD3(0, 0.38, 0), radius: variant == 0 ? 0.55 : 0.48, squash: 0.72, jitter: 0.12, rng: &rng)
            if kind == .flowerBush {
                // Dot flowers on the upper vertices.
                for i in start..<m.positions.count where m.positions[i].y > 0.45 && rng.chance(0.45) {
                    m.paints[i] = Paint(slot: palette.named(rng.chance(0.5) ? "flowers" : "flowersAlt"), sway: 0.25).packed
                }
            }
            return m
        case .tuft:
            var m = MeshBuffers()
            let blades = variant == 0 ? 5 : 7
            for k in 0..<blades {
                let a = Double(k) / Double(blades) * 2 * .pi + rng.range(-0.3, 0.3)
                let lean = Float(rng.range(0.05, 0.12))
                let base = SIMD3<Float>(Float(cos(a)) * 0.04, 0, Float(sin(a)) * 0.04)
                let side = SIMD3<Float>(Float(-sin(a)) * 0.025, 0, Float(cos(a)) * 0.025)
                let tip = SIMD3<Float>(Float(cos(a)) * lean, Float(rng.range(0.22, 0.36)), Float(sin(a)) * lean)
                let n = simd_normalize(SIMD3<Float>(Float(cos(a)), 0.6, Float(sin(a))))
                m.paint = Paint(slot: palette.named("tuft"), shade: 0.85, sway: 0)
                let i0 = m.addVertex(base - side, normal: n)
                let i1 = m.addVertex(base + side, normal: n)
                m.paint = Paint(slot: palette.named("tuft"), shade: 1.15, sway: 1)
                let i2 = m.addVertex(tip, normal: n)
                m.addTriangle(i0, i1, i2)
                m.addTriangle(i0, i2, i1) // both sides
            }
            return m
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

    /// Cylinder side (no caps except top), `sides` segments; smooth or flat normals.
    static func addCylinder(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, sides: Int, smooth: Bool) {
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
        m.paint = Paint(slot: shade.slot, shade: shade.shade * 0.7, flags: shade.flags, sway: shade.sway)
        let base = (0..<sides).map { i -> SIMD3<Float> in
            let a = Float(i) / Float(sides) * 2 * .pi
            return SIMD3(cos(a) * r, z0, sin(a) * r)
        }
        m.addFace(base, facing: -sceneUp)
        m.paint = shade
    }

    /// A smooth, slightly lumpy blob (icosphere, subdivided once = 80 triangles).
    static func addBlob(_ m: inout MeshBuffers, center: SIMD3<Float>, radius: Float, squash: Float, jitter: Double,
                        rng: inout StableRandom, subdivide: Bool = true) {
        var (verts, faces) = icosahedron()
        if subdivide { (verts, faces) = subdivided(verts, faces) }
        let base = UInt32(m.positions.count)
        for v in verts {
            let k = Float(1 + rng.range(-jitter, jitter))
            let p = v * radius * k
            let pos = center + SIMD3(p.x, p.y * squash, p.z)
            // Smooth normal: ellipsoid gradient, slightly flattened for a soft, toy-like look.
            let n = simd_normalize(SIMD3(v.x, v.y / max(squash, 0.01), v.z))
            m.addVertex(pos, normal: n)
        }
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
