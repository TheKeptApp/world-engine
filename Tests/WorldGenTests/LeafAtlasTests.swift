import Foundation
import Testing
@testable import WorldGen

/// The procedural leaf-card atlas: deterministic (hashed), R8 1024², clear cell borders, dense middles.
@Suite("Leaf atlas")
struct LeafAtlasTests {
    static func fnv(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in bytes { h ^= UInt64(b); h &*= 0x100_0000_01B3 }
        return h
    }

    @Test func atlasIsDeterministic() throws {
        let a = PropLibrary.leafAtlas, b = LeafAtlas.generate()
        #expect(a.width == 1024 && a.height == 1024 && a.format == "r8Unorm" && a.bytes.count == 1024 * 1024)
        #expect(Self.fnv(a.bytes) == Self.fnv(b.bytes))
        print("LEAFATLAS fnv1a \(String(Self.fnv(a.bytes), radix: 16)) coverage \(Double(a.bytes.reduce(0) { $0 + Int($1) }) / 255 / Double(a.bytes.count))")
    }

    /// Per cell: nothing in the border padding; leaf clusters mostly opaque in the middle (alpha-tested
    /// opaque cards keep overdraw useful), with a ragged edge (not a full square).
    @Test(arguments: LeafAtlas.Family.allCases)
    func cellsAreClusters(_ family: LeafAtlas.Family) throws {
        let atlas = PropLibrary.leafAtlas
        let cell = atlas.width / LeafAtlas.grid
        for variant in 0..<LeafAtlas.grid {
            let rect = LeafAtlas.cell(family, variant: variant)
            let x0 = Int(rect.min.x * Float(atlas.width)), y0 = Int(rect.min.y * Float(atlas.height))
            var border = 0, middle = 0, middleCount = 0, total = 0
            for y in 0..<cell { for x in 0..<cell {
                let a = Int(atlas.bytes[(y0 + y) * atlas.width + x0 + x])
                total += a >= 128 ? 1 : 0
                if x < LeafAtlas.padding || y < LeafAtlas.padding || x >= cell - LeafAtlas.padding || y >= cell - LeafAtlas.padding { border += a }
                let u = (Float(x) + 0.5) / Float(cell) - 0.5, v = (Float(y) + 0.5) / Float(cell) - (family == .needles ? 0.55 : 0.5)
                if u * u + v * v < 0.1 * 0.1 { middleCount += 1; middle += a >= 128 ? 1 : 0 }
            } }
            let share = Double(total) / Double(cell * cell), dense = Double(middle) / Double(max(middleCount, 1))
            print("LEAFCELL \(family) \(variant) coverage \(String(format: "%.2f", share)) middle \(String(format: "%.2f", dense))")
            #expect(border == 0, "\(family) \(variant): leaves in the border")
            #expect(share > (family == .needles ? 0.18 : 0.25) && share < 0.85, "\(family) \(variant): coverage \(share)")
            if family != .strands { #expect(dense > 0.85, "\(family) \(variant): middle coverage \(dense)") }
        }
    }
}

/// Leaf cards and puffs stay behind `PropLibrary.crownStyle` (default `.solid`): the default
/// meshes are exactly the solid crowns (no uv0, no card flag), so main renders unchanged until the
/// card material lands; with cards on, near and mid crowns are cards and far/skyline are unchanged.
@Suite("Leaf card switch")
struct LeafCardSwitchTests {
    @Test(arguments: PropKind.allCases.filter(\.isTree))
    func defaultMeshesAreTheSolidCrowns(_ kind: PropKind) throws {
        guard PropLibrary.crownStyle == .solid else { return }
        let palette = try TreeSilhouetteTests.palette()
        for lod in 0..<PropLibrary.lodCount(kind) {
            let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette)
            #expect(m == PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, leafCards: false), "\(kind) lod \(lod)")
            #expect(m.uvs.isEmpty && m.paints.allSatisfy { Int($0.z + 0.5) & 512 == 0 }, "\(kind) lod \(lod): cards in the default mesh")
            let cards = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, leafCards: true)
            let hasCards = cards.paints.contains { Int($0.z + 0.5) & 512 != 0 }
            #expect(hasCards == (lod < 2), "\(kind) lod \(lod): cards \(hasCards)")
            if lod >= 2 { #expect(cards == m, "\(kind) lod \(lod): far/skyline change with cards") }
        }
    }
}
