import simd
import WorldGeo

/// Plain triangle-mesh data, independent of any renderer. RealityKit upload happens elsewhere.
/// Triangles are counter-clockwise when seen from the side their normal points to.
public struct MeshBuffers: Sendable, Equatable {
    public var positions: [SIMD3<Float>] = []
    public var normals: [SIMD3<Float>] = []
    public var indices: [UInt32] = []

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
        return UInt32(positions.count - 1)
    }

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
