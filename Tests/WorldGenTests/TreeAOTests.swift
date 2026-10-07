import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldMesh

/// Baked contact shading on trees (extra.x, vegetation-v1): the trunk base 10–20% darker where it meets
/// the lawn, unshaded just above; crown undersides gently shaded.
@Suite("Tree AO")
struct TreeAOTests {
    @Test(arguments: [PropKind.treeBroad, .treeOval, .treeSpreading, .conifer])
    func trunkBaseIsDarker(_ kind: PropKind) throws {
        for lod in 0..<(kind == .conifer ? 3 : 4) {
            let m = try TreeSilhouetteTests.mesh(kind, lod: lod)
            let base = (0..<m.vertexCount).filter { m.positions[$0].y < 0.005 && TreeSilhouetteTests.part(m, vertex: $0) == .trunk }
            #expect(!base.isEmpty, "\(kind) lod \(lod): no trunk base")
            for v in base { #expect(m.extras[v].x >= 0.8 && m.extras[v].x <= 0.9, "\(kind) lod \(lod): trunk base AO \(m.extras[v].x)") }
        }
        // Just above the contact band (about 0.4 m up a 15 m tree) and below the fork, the trunk is unshaded.
        if kind != .conifer {
            let m = try TreeSilhouetteTests.mesh(kind, lod: 0)
            let above = (0..<m.vertexCount).filter {
                abs(m.positions[$0].y - PropLibrary.trunkBaseAOHeight) < 0.002 && TreeSilhouetteTests.part(m, vertex: $0) == .trunk
            }
            #expect(!above.isEmpty && above.allSatisfy { m.extras[$0].x > 0.97 }, "\(kind): trunk AO above the contact \(above.map { m.extras[$0].x }.min() ?? 0)")
        }
    }

    @Test(arguments: [PropKind.treeBroad, .treeOval, .treeSpreading])
    func crownUndersidesAreShaded(_ kind: PropKind) throws {
        for lod in 0..<3 {
            let m = try TreeSilhouetteTests.mesh(kind, lod: lod)
            let under = (0..<m.vertexCount).filter { TreeSilhouetteTests.part(m, vertex: $0) == .crown && m.normals[$0].y < -0.8 }
            #expect(lod == 2 || !under.isEmpty, "\(kind) lod \(lod): no underside")
            #expect(under.allSatisfy { m.extras[$0].x <= 0.76 }, "\(kind) lod \(lod): underside AO up to \(under.map { m.extras[$0].x }.max() ?? 0)")
        }
    }
}
