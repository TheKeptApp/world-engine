import Foundation
import Metal
import RealityKit
import WorldMesh

/// Copies `MeshBuffers` into a RealityKit `LowLevelMesh`.
/// Vertex layout (56 bytes): position float3, normal float3, paint float4 (uv2), extra float4 (uv3).
@MainActor
enum MeshUpload {
    static let stride = 56
    static let attributes: [LowLevelMesh.Attribute] = [
        .init(semantic: .position, format: .float3, offset: 0),
        .init(semantic: .normal, format: .float3, offset: 12),
        .init(semantic: .uv2, format: .float4, offset: 24),
        .init(semantic: .uv3, format: .float4, offset: 40),
    ]

    /// Writes the parts' vertices in this layout into `raw` (shared by uploads and the stream cache).
    static func writeVertices(of parts: [WorldMesh.MeshBuffers], into raw: UnsafeMutableRawBufferPointer) {
        var o = 0
        for m in parts {
            for i in 0..<m.vertexCount {
                let p = m.positions[i], n = m.normals[i]
                raw.storeBytes(of: p.x, toByteOffset: o, as: Float.self)
                raw.storeBytes(of: p.y, toByteOffset: o + 4, as: Float.self)
                raw.storeBytes(of: p.z, toByteOffset: o + 8, as: Float.self)
                raw.storeBytes(of: n.x, toByteOffset: o + 12, as: Float.self)
                raw.storeBytes(of: n.y, toByteOffset: o + 16, as: Float.self)
                raw.storeBytes(of: n.z, toByteOffset: o + 20, as: Float.self)
                raw.storeBytes(of: m.paints[i], toByteOffset: o + 24, as: SIMD4<Float>.self)
                raw.storeBytes(of: m.extras[i], toByteOffset: o + 40, as: SIMD4<Float>.self)
                o += stride
            }
        }
    }

    /// One mesh with one part per buffer (parts use material indices 0, 1, ...).
    static func resource(_ parts: [WorldMesh.MeshBuffers]) throws -> MeshResource? {
        let parts = parts.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        let vertexCount = parts.reduce(0) { $0 + $1.vertexCount }
        let indexCount = parts.reduce(0) { $0 + $1.indices.count }
        let desc = LowLevelMesh.Descriptor(
            vertexCapacity: vertexCount,
            vertexAttributes: [
                .init(semantic: .position, format: .float3, offset: 0),
                .init(semantic: .normal, format: .float3, offset: 12),
                .init(semantic: .uv2, format: .float4, offset: 24),
                .init(semantic: .uv3, format: .float4, offset: 40),
            ],
            vertexLayouts: [.init(bufferIndex: 0, bufferStride: stride)],
            indexCapacity: indexCount,
            indexType: .uint32
        )
        let mesh = try LowLevelMesh(descriptor: desc)
        mesh.withUnsafeMutableBytes(bufferIndex: 0) { raw in
            var o = 0
            for m in parts {
                for i in 0..<m.vertexCount {
                    let p = m.positions[i], n = m.normals[i]
                    raw.storeBytes(of: p.x, toByteOffset: o, as: Float.self)
                    raw.storeBytes(of: p.y, toByteOffset: o + 4, as: Float.self)
                    raw.storeBytes(of: p.z, toByteOffset: o + 8, as: Float.self)
                    raw.storeBytes(of: n.x, toByteOffset: o + 12, as: Float.self)
                    raw.storeBytes(of: n.y, toByteOffset: o + 16, as: Float.self)
                    raw.storeBytes(of: n.z, toByteOffset: o + 20, as: Float.self)
                    raw.storeBytes(of: m.paints[i], toByteOffset: o + 24, as: SIMD4<Float>.self)
                    raw.storeBytes(of: m.extras[i], toByteOffset: o + 40, as: SIMD4<Float>.self)
                    o += stride
                }
            }
        }
        var lowParts: [LowLevelMesh.Part] = []
        mesh.withUnsafeMutableIndices { raw in
            let dst = raw.bindMemory(to: UInt32.self)
            var vBase: UInt32 = 0, iBase = 0
            for (k, m) in parts.enumerated() {
                for (j, idx) in m.indices.enumerated() { dst[iBase + j] = idx + vBase }
                let b = m.bounds!
                lowParts.append(.init(indexOffset: iBase * 4, indexCount: m.indices.count, topology: .triangle,
                                      materialIndex: k, bounds: BoundingBox(min: b.min, max: b.max)))
                vBase += UInt32(m.vertexCount)
                iBase += m.indices.count
            }
        }
        mesh.parts.replaceAll(lowParts)
        return try MeshResource(from: mesh)
    }
}
