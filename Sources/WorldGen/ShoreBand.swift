import Foundation
import simd
import WorldGeo
import WorldMesh

/// Lake shore band (lake-winter-v1 water.profiles / water.shoreline): geometry and a distance-to-shore
/// channel for the water shader (5A), which blends the profile's shallow colour over `shallowBlendWidthM`
/// and darkens the shoreline. P2 owns the geometry and mask; colours and shading stay in the shader.
/// Water-mesh vertex extra: z = metres from the shore (open water `openWater`), w = profile index.
enum ShoreBand {
    static let openWater = 1000.0

    struct Profile { var index: Int; var id: String?; var blendWidth: Double? }

    /// The lake-winter-v1 water profile for a style profile (look.json water.shoreProfiles).
    static func profile(for styleProfile: String) -> Profile {
        guard let sp = LookSpec.bundled?.water.shoreProfiles,
              let id = sp.profiles[styleProfile] ?? sp.profiles["default"], let index = sp.order.firstIndex(of: id) else {
            return Profile(index: 0, id: nil, blendWidth: nil)
        }
        let w = MockValues.bundled?.number("lake-winter-v1/water.profiles.\(id).shallowBlendWidthM")
        return Profile(index: index, id: id, blendWidth: w)
    }

    /// A strip from every ring of `polygon` inward by `width` (mitred, the miter capped at 2 × width), the
    /// shore edge at distance 0 and the inner edge at `width`.
    static func mesh(_ polygon: Polygon2D, width: Double, y: Double, slot: Int, profile: Int) -> MeshBuffers {
        var m = MeshBuffers()
        m.paint = Paint(slot: slot)
        for (k, ring0) in ([polygon.outer] + polygon.holes).enumerated() {
            // Water lies left of a CCW outer ring and right of a hole's CW ring; orient so it is on the left.
            var ring = ring0
            let ccw = RingMath.signedArea(ring) > 0
            if (k == 0) != ccw { ring.reverse() }
            let n = ring.count
            guard n >= 3 else { continue }
            var inner: [LocalPoint] = []
            for i in 0..<n {
                let a = ring[(i + n - 1) % n], b = ring[i], c = ring[(i + 1) % n]
                func left(_ d: LocalPoint) -> LocalPoint { let u = simd_normalize(d); return LocalPoint(-u.y, u.x) }
                let n1 = left(b - a), n2 = left(c - b)
                var bis = n1 + n2
                if simd_length(bis) < 1e-6 { bis = n1 }
                bis = simd_normalize(bis)
                let cosHalf = max(0.5, simd_dot(bis, n1))
                inner.append(b + bis * (width / cosHalf))
            }
            for i in 0..<n {
                let j = (i + 1) % n
                let q: [(LocalPoint, Double)] = [(ring[i], 0), (ring[j], 0), (inner[j], width), (inner[i], width)]
                var idx: [UInt32] = []
                for (p, d) in q {
                    m.extra = SIMD4(1, 0, Float(d), Float(profile))
                    idx.append(m.addVertex(P(p, y), normal: sceneUp))
                }
                let p0 = m.positions[Int(idx[0])], p1 = m.positions[Int(idx[1])], p2 = m.positions[Int(idx[2])]
                if simd_cross(p1 - p0, p2 - p0).y >= 0 {
                    m.addTriangle(idx[0], idx[1], idx[2]); m.addTriangle(idx[0], idx[2], idx[3])
                } else {
                    m.addTriangle(idx[0], idx[2], idx[1]); m.addTriangle(idx[0], idx[3], idx[2])
                }
            }
        }
        return m
    }
}

extension SceneGenerator {
    /// Splits a mesh into chunks by each triangle's first vertex and appends it as one feature per chunk,
    /// to the water mesh (`water`) or the static mesh.
    func distribute(_ mesh: MeshBuffers, feature: String, water: Bool, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        var byChunk: [SIMD2<Int>: MeshBuffers] = [:]
        var t = 0
        while t + 2 < mesh.indices.count {
            let i0 = Int(mesh.indices[t])
            let key = chunkIndex(LocalPoint(Double(mesh.positions[i0].x), -Double(mesh.positions[i0].z)))
            var m = byChunk[key] ?? MeshBuffers()
            let base = UInt32(m.positions.count)
            for k in 0..<3 {
                let i = Int(mesh.indices[t + k])
                m.positions.append(mesh.positions[i]); m.normals.append(mesh.normals[i])
                m.paints.append(mesh.paints[i]); m.extras.append(mesh.extras[i])
            }
            m.indices.append(contentsOf: [base, base + 1, base + 2])
            byChunk[key] = m
            t += 3
        }
        for (key, m) in byChunk.sorted(by: { ($0.key.x, $0.key.y) < ($1.key.x, $1.key.y) }) where chunks[key] != nil {
            if water {
                chunks[key]!.waterFeatures.append(FeatureRange(feature: feature, start: chunks[key]!.waterMesh.vertexCount, count: m.vertexCount))
                chunks[key]!.waterMesh.append(m)
            } else {
                let start = chunks[key]!.staticMesh.vertexCount
                chunks[key]!.staticMesh.append(m)
                chunks[key]!.staticFeatures.append(FeatureRange(feature: feature, start: start, count: m.vertexCount))
            }
        }
    }
}
