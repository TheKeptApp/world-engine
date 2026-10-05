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
    public var indices: [UInt32] = []
    /// Paint applied to vertices added from now on.
    public var paint = Paint(slot: 0)

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
        indices.append(contentsOf: other.indices.map { $0 + base })
    }

    /// Sets the paint of every vertex from `start` on.
    public mutating func repaint(from start: Int, _ p: Paint) {
        for i in start..<paints.count { paints[i] = p.packed }
    }

    /// Bytes used by this mesh's vertex and index data in the engine's GPU layout
    /// (position 12 + normal 12 + paint 16 bytes per vertex, 4 bytes per index).
    public var gpuBytes: Int { positions.count * 40 + indices.count * 4 }

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
