import simd
import WorldGeo

/// Per-vertex paint: which palette color a vertex uses and how the shader treats it.
/// Stored as a float4: x = palette slot, y = shade multiplier, z = flags, w = sway weight.
public struct Paint: Hashable, Sendable {
    public struct Flags: OptionSet, Hashable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        /// Window glass: glossy by day, may light up at night.
        public static let glass = Flags(rawValue: 1)
        /// Self-lit (lamp heads).
        public static let emissive = Flags(rawValue: 2)
        /// Lawn/grass surface (low-frequency mottling).
        public static let lawn = Flags(rawValue: 4)
        /// Sidewalk surface (procedural joints along `extra.z`).
        public static let sidewalk = Flags(rawValue: 8)
        /// Road surface (wetness response).
        public static let road = Flags(rawValue: 16)
        /// Per-instance color variant among 4 consecutive slots (deciduous crowns).
        public static let variant4 = Flags(rawValue: 32)
        /// Per-instance color variant among 2 consecutive slots (conifers).
        public static let variant2 = Flags(rawValue: 64)
        /// Near-camera clutter that shrinks away with distance (tufts).
        public static let distanceFade = Flags(rawValue: 128)
        /// Context-ring ground (look-fix-v1 §4 coverage fade): the colour blends into the seasonal
        /// backdrop over the last `sway` metres inside a coverage box carried in `extra` (scene
        /// x min, z min, x max, z max), so the data ends without a cut. AO is 1 on these vertices.
        public static let coverageFade = Flags(rawValue: 256)
        /// Leaf card (tree crowns): an alpha-tested quad textured from the leaf atlas
        /// (`PropLibrary.leafAtlas`) through `MeshBuffers.uvs`; opaque, clipped at alpha 0.5.
        /// extra.x = AO, extra.y = leaf-drop threshold, extra.z = 0, extra.w = per-card random value.
        public static let leafCard = Flags(rawValue: 512)
    }

    public var slot: Int
    public var shade: Float
    public var flags: Flags
    public var sway: Float

    public init(slot: Int, shade: Float = 1, flags: Flags = [], sway: Float = 0) {
        self.slot = slot
        self.shade = shade
        self.flags = flags
        self.sway = sway
    }

    public var packed: SIMD4<Float> { SIMD4(Float(slot), shade, Float(flags.rawValue), sway) }
}

/// Plain triangle-mesh data, independent of any renderer. RealityKit upload happens elsewhere.
/// Triangles are counter-clockwise when seen from the side their normal points to.
public struct MeshBuffers: Sendable, Equatable {
    public var positions: [SIMD3<Float>] = []
    public var normals: [SIMD3<Float>] = []
    /// Packed `Paint` per vertex (see `Paint.packed`).
    public var paints: [SIMD4<Float>] = []
    /// Per-vertex extra channel: x = baked ambient occlusion (1 open … 0 closed),
    /// y = stable seed 0…1 (e.g. lit-window choice), z = meters along a path (sidewalk joints),
    /// w = meters across a path.
    public var extras: [SIMD4<Float>] = []
    public var indices: [UInt32] = []
    /// Texture coordinates (uv0), empty for meshes without them; once any vertex has one, every
    /// vertex does (earlier ones get (0, 0)). Only leaf cards use them so far.
    public var uvs: [SIMD2<Float>] = []
    /// Paint applied to vertices added from now on.
    public var paint = Paint(slot: 0)
    /// Extra channel applied to vertices added from now on (AO defaults to 1).
    public var extra = SIMD4<Float>(1, 0, 0, 0)

    public init() {}

    public var vertexCount: Int { positions.count }
    public var triangleCount: Int { indices.count / 3 }
    public var isEmpty: Bool { indices.isEmpty }

    /// Axis-aligned bounds (min, max), or nil if empty.
    public var bounds: (min: SIMD3<Float>, max: SIMD3<Float>)? {
        guard var lo = positions.first else { return nil }
        var hi = lo
        for p in positions {
            lo = simd_min(lo, p)
            hi = simd_max(hi, p)
        }
        return (lo, hi)
    }

    /// Adds a vertex and returns its index.
    @discardableResult
    public mutating func addVertex(_ p: SIMD3<Float>, normal n: SIMD3<Float>) -> UInt32 {
        positions.append(p)
        normals.append(n)
        paints.append(paint.packed)
        extras.append(extra)
        if !uvs.isEmpty { uvs.append(.zero) }
        return UInt32(positions.count - 1)
    }

    /// Adds a vertex with texture coordinates and returns its index.
    @discardableResult
    public mutating func addVertex(_ p: SIMD3<Float>, normal n: SIMD3<Float>, uv: SIMD2<Float>) -> UInt32 {
        if uvs.count < positions.count { uvs.append(contentsOf: repeatElement(.zero, count: positions.count - uvs.count)) }
        positions.append(p)
        normals.append(n)
        paints.append(paint.packed)
        extras.append(extra)
        uvs.append(uv)
        return UInt32(positions.count - 1)
    }

    /// Appends another mesh, transformed by `transform` (normals by its rotation part).
    public mutating func append(_ other: MeshBuffers, transform: simd_float4x4 = matrix_identity_float4x4) {
        let base = UInt32(positions.count)
        let rot = simd_float3x3(
            SIMD3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z),
            SIMD3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z),
            SIMD3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
        )
        let normalMatrix = rot.inverse.transpose
        positions.reserveCapacity(positions.count + other.positions.count)
        for p in other.positions {
            let q = transform * SIMD4(p, 1)
            positions.append(SIMD3(q.x, q.y, q.z))
        }
        for n in other.normals { normals.append(simd_normalize(normalMatrix * n)) }
        paints.append(contentsOf: other.paints)
        extras.append(contentsOf: other.extras)
        if !uvs.isEmpty || !other.uvs.isEmpty {
            if uvs.count < Int(base) { uvs.append(contentsOf: repeatElement(.zero, count: Int(base) - uvs.count)) }
            uvs.append(contentsOf: other.uvs.isEmpty ? Array(repeating: .zero, count: other.positions.count) : other.uvs)
        }
        indices.append(contentsOf: other.indices.map { $0 + base })
    }

    /// Splits the triangles into two meshes by a test on each triangle's corners: those passing
    /// go to the first mesh, the rest to the second. Vertices are copied as needed (shared ones
    /// end up in both); triangle order and every vertex attribute are kept.
    public func partitioned(_ isFirst: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) -> Bool) -> (MeshBuffers, MeshBuffers) {
        var out = (MeshBuffers(), MeshBuffers())
        var maps = ([Int32](repeating: -1, count: positions.count), [Int32](repeating: -1, count: positions.count))
        func take(_ i: Int, _ mesh: inout MeshBuffers, _ map: inout [Int32]) -> UInt32 {
            if map[i] < 0 {
                mesh.positions.append(positions[i])
                mesh.normals.append(normals[i])
                mesh.paints.append(paints[i])
                mesh.extras.append(extras[i])
                if !uvs.isEmpty { mesh.uvs.append(uvs[i]) }
                map[i] = Int32(mesh.positions.count - 1)
            }
            return UInt32(map[i])
        }
        var t = 0
        while t + 2 < indices.count {
            let a = Int(indices[t]), b = Int(indices[t + 1]), c = Int(indices[t + 2])
            if isFirst(positions[a], positions[b], positions[c]) {
                out.0.indices.append(contentsOf: [take(a, &out.0, &maps.0), take(b, &out.0, &maps.0), take(c, &out.0, &maps.0)])
            } else {
                out.1.indices.append(contentsOf: [take(a, &out.1, &maps.1), take(b, &out.1, &maps.1), take(c, &out.1, &maps.1)])
            }
            t += 3
        }
        return out
    }

    /// Sets the paint of every vertex from `start` on.
    public mutating func repaint(from start: Int, _ p: Paint) {
        for i in start..<paints.count { paints[i] = p.packed }
    }

    /// Sets the AO of every vertex from `start` on with a function of its position.
    public mutating func bakeAO(from start: Int, _ f: (SIMD3<Float>, SIMD3<Float>) -> Float) {
        for i in start..<positions.count { extras[i].x = min(extras[i].x, f(positions[i], normals[i])) }
    }

    /// Bytes used by this mesh's vertex and index data in the engine's GPU layout
    /// (position 12 + normal 12 + paint 16 + extra 16 bytes per vertex, 4 bytes per index).
    public var gpuBytes: Int { positions.count * 56 + indices.count * 4 }

    public mutating func addTriangle(_ a: UInt32, _ b: UInt32, _ c: UInt32) {
        indices.append(contentsOf: [a, b, c])
    }

    /// Adds a flat quad (a, b, c, d in counter-clockwise order seen from the normal side).
    public mutating func addQuad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>, normal: SIMD3<Float>) {
        let i = addVertex(a, normal: normal)
        addVertex(b, normal: normal)
        addVertex(c, normal: normal)
        addVertex(d, normal: normal)
        addTriangle(i, i + 1, i + 2)
        addTriangle(i, i + 2, i + 3)
    }

    /// The geometric (face) normal of triangle `t`, not normalized; its length is twice the area.
    public func faceCross(_ t: Int) -> SIMD3<Float> {
        let a = positions[Int(indices[t * 3])]
        let b = positions[Int(indices[t * 3 + 1])]
        let c = positions[Int(indices[t * 3 + 2])]
        return simd_cross(b - a, c - a)
    }

    /// Total surface area in m².
    public var surfaceArea: Float {
        (0..<triangleCount).reduce(0) { $0 + simd_length(faceCross($1)) / 2 }
    }
}

/// Scene-space up.
public let sceneUp = SIMD3<Float>(0, 1, 0)

/// Local east/north point at height `y` → scene position (east = +X, north = −Z).
@inline(__always)
func scene(_ p: LocalPoint, _ y: Double) -> SIMD3<Float> {
    LocalFrame.scenePosition(p, y: y)
}
