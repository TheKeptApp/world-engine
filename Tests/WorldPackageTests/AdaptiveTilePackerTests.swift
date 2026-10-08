import Foundation
import Testing
@testable import WorldPackage

@Suite("Adaptive byte-budget tile packing")
struct AdaptiveTilePackerTests {
    func fixture(triangles: Int, collapsed: Bool = false) throws -> Data {
        let b = GLBBuilder(), m = b.material(name: "worldStatic")
        var pos: [Float] = [], nrm: [Float] = [], paint: [Float] = [], extra: [Float] = [], features: [UInt32] = []
        for i in 0..<triangles { for corner in 0..<3 {
            let x = collapsed ? Float(0) : Float(i)
            pos += [x + Float(corner == 1 ? 1 : 0), Float(i % 5), Float(corner == 2 ? 1 : 0)]
            nrm += [0, 1, 0]; paint += [Float(i % 7), 0.9, 32, 0]; extra += [1, Float(i) / 1000, 2, 3]
            features.append(UInt32(i % 4))
        } }
        let attrs = ["POSITION": b.floats(pos, components: 3, minMax: true), "NORMAL": b.floats(nrm, components: 3),
                     "_PAINT": b.floats(paint, components: 4), "_EXTRA": b.floats(extra, components: 4), "_FEATURE": b.uints(features)]
        let primitive = b.primitive(attributes: attrs, indices: b.indices((0..<triangles * 3).map(UInt32.init)), material: m)
        _ = b.node(name: "fixture", mesh: b.mesh(name: "fixture", primitives: [primitive]), translation: [100, 0, -200])
        return try b.encoded()
    }
    func triangleSignatures(_ data: Data) throws -> [String] {
        let m = try AdaptiveTilePacker.Mesh(data)
        return m.primitives.flatMap { p in
            (0..<p.indices.count / 3).map { t in
                var bytes = Data(p.material.utf8)
                for vertex in p.indices[(t * 3)..<(t * 3 + 3)] { for key in p.attributes.keys.sorted() {
                    let a = p.attributes[key]!, start = Int(vertex) * a.width
                    bytes.append(a.bytes.subdata(in: start..<(start + a.width)))
                } }
                return AdaptiveTilePacker.digest(bytes)
            }
        }.sorted()
    }
    @Test func budgetAndExactTrianglesAndDeterminism() throws {
        let a = try fixture(triangles: 150), b = try fixture(triangles: 40)
        let meshes = try [a, b].map(AdaptiveTilePacker.Mesh.init)
        var budget = AdaptiveTilePacker.Budget(); budget.uploadBytes = 8000; budget.queueBytes = 12000
        let leaves = try AdaptiveTilePacker.split(meshes, budget: budget)
        #expect(leaves.count > 1)
        let again = try AdaptiveTilePacker.split(meshes, budget: budget)
        #expect(leaves.map(\.suffix) == again.map(\.suffix))
        for (left, right) in zip(leaves, again) { for (x, y) in zip(left.lods, right.lods) {
            #expect(x.data == y.data); #expect(x.data.count <= budget.uploadBytes); #expect(x.decoded <= budget.queueBytes / 2)
        } }
        for lod in 0..<2 {
            let before = try triangleSignatures([a, b][lod])
            let after = try leaves.flatMap { try triangleSignatures($0.lods[lod].data) }.sorted()
            #expect(before == after)
            for leaf in leaves {
                let file = try GLBFile(data: leaf.lods[lod].data)
                #expect(file.nodes[0]["translation"] as? [Double] == [100, 0, -200])
                #expect(try WorldPackage.json(file.json["materials"]!) == WorldPackage.json(meshes[lod].template["materials"]!))
                for ranges in leaf.lods[lod].ranges.values {
                    #expect(ranges.values.flatMap { $0 }.reduce(0) { $0 + $1[1] } == leaf.lods[lod].vertices)
                }
            }
        }
    }
    @Test func coincidentTrianglesTerminateAndAllowExplicitEmptyLOD() throws {
        let meshes = try [fixture(triangles: 80, collapsed: true), fixture(triangles: 1)].map(AdaptiveTilePacker.Mesh.init)
        var budget = AdaptiveTilePacker.Budget(); budget.uploadBytes = 5000
        let leaves = try AdaptiveTilePacker.split(meshes, budget: budget)
        #expect(leaves.count > 1)
        #expect(leaves.contains { $0.lods[1].triangles == 0 })
        #expect(leaves.reduce(0) { $0 + $1.lods[0].triangles } == 80)
        #expect(leaves.reduce(0) { $0 + $1.lods[1].triangles } == 1)
    }
    @Test func impossibleBudgetFailsRatherThanDroppingGeometry() throws {
        let mesh = try AdaptiveTilePacker.Mesh(fixture(triangles: 1))
        var budget = AdaptiveTilePacker.Budget(); budget.uploadBytes = 1
        #expect(throws: (any Error).self) { try AdaptiveTilePacker.split([mesh], budget: budget) }
    }
}
