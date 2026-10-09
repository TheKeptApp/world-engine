import Testing
@testable import WorldGen
@testable import WorldMesh

@Suite("Export-only surface roles")
struct SurfaceRoleTests {
    @Test func sameHexMappedRoofAndDoorRemainDistinct() throws {
        var gen = try HouseDetailTests.generator("front-range")
        gen.obstacles = nil
        let b = testBuilding(31001, HouseDetailTests.rings[0].1, tags: ["roof:colour": "#123456"])
        var palette = Palette(base: try StyleLibrary.baseColors())
        let native = gen.generate(b, palette: &palette, lod: .near)
        let door = native.colors[2]
        let same = testBuilding(31001, HouseDetailTests.rings[0].1, tags: ["roof:colour": door])
        var offPalette = Palette(base: try StyleLibrary.baseColors())
        let off = gen.generate(same, palette: &offPalette, lod: .near)
        var onPalette = Palette(base: try StyleLibrary.baseColors())
        let on = SurfaceCapture.$enabled.withValue(true) { gen.generate(same, palette: &onPalette, lod: .near) }
        #expect(off.mesh == on.mesh)
        #expect(offPalette.colors == onPalette.colors)
        #expect(off.mesh.surfaceWords.isEmpty)
        #expect(on.mesh.surfaceWords.count == on.mesh.vertexCount)
        #expect(on.colors[2].uppercased() == on.colors[3].uppercased())
        let roof = on.mesh.surfaceWords.filter { $0 & 7 == SurfaceRole.roof.rawValue }
        #expect(!roof.isEmpty)
        #expect(on.mesh.surfaceWords.contains { $0 & 7 == SurfaceRole.door.rawValue })
        #expect(roof.allSatisfy { ($0 >> 10) & 3 == 1 }) // mapped roof:colour
        #expect(roof.allSatisfy { ($0 >> 3) & 31 == 0 && ($0 >> 8) & 3 == 0 }) // colour is not material
    }

    @Test func sourceMaterialsOnlyAndPartitionPreservesWords() {
        #expect(SurfaceCapture.word(role: .roof, material: "slate") >> 8 & 3 == 1)
        #expect(SurfaceCapture.word(role: .roof, material: "red") >> 3 & 31 == 0)
        let mesh = SurfaceCapture.$enabled.withValue(true) {
            var m = MeshBuffers()
            m.paint = Paint(slot: 1).annotated(.roof, material: "slate")
            m.addQuad(.init(0,0,0), .init(1,0,0), .init(1,0,1), .init(0,0,1), normal: .init(0,1,0))
            return m
        }
        let (first, second) = mesh.partitioned { _,_,_ in true }
        #expect(first.surfaceWords == mesh.surfaceWords)
        #expect(second.surfaceWords.isEmpty)
        var joined = MeshBuffers(); joined.append(mesh); joined.append(first)
        #expect(joined.surfaceWords == mesh.surfaceWords + first.surfaceWords)
        SurfaceCapture.$enabled.withValue(true) {
            joined.repaint(from: 0, Paint(slot: 1).annotated(.roof, mappedColour: true))
        }
        #expect(joined.surfaceWords.allSatisfy { $0 & 7 == 1 && $0 >> 10 & 3 == 1 })
        #expect(!SurfaceCapture.enabled)
    }
}
