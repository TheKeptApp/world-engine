import Foundation
import Testing
import WorldGeo
import WorldMesh
@testable import WorldGen

/// Historic paving (ground-v1 brick addendum): only mapped `surface` tags select brick, setts or cobble;
/// everything else keeps the ordinary road and sidewalk look.
struct PavingTests {
    @Test func surfaceTagsMapToPatterns() {
        #expect(SceneGenerator.paving("bricks")?.pattern == 1)
        #expect(SceneGenerator.paving("sett")?.pattern == 2)
        #expect(SceneGenerator.paving("unhewn_cobblestone")?.pattern == 3)
        for other in [nil, "asphalt", "paving_stones", "concrete", "gravel"] { #expect(SceneGenerator.paving(other) == nil) }
    }

    /// Wilmette has one mapped sett street: its road mesh carries the setts slot, the paving flag and
    /// pattern 2; untagged roads don't.
    @Test func mappedSettStreetIsPaved() throws {
        guard BuildingAreaTests.has("wilmette-vattmann-park") else { Issue.record("missing test prerequisite: BuildingAreaTests.has('wilmette-vattmann-park')"); return }
        let b = try YardTests.build("wilmette-vattmann-park", "wilmette")
        let sett = b.features.roads.filter { $0.tags["surface"] == "sett" }.map(\.ref.description)
        try #require(!sett.isEmpty)
        let settSlot = Float(b.scene.palette.named("pavingSetts"))
        var paved = 0, wrong = 0
        for chunk in b.scene.chunks {
            for fr in chunk.staticFeatures {
                let isSett = sett.contains(fr.feature)
                for i in fr.start..<(fr.start + fr.count) {
                    let p = chunk.staticMesh.paints[i]
                    let flagged = (Int(p.z) & Paint.Flags.paving.rawValue) != 0
                    if isSett, flagged, p.x == settSlot, p.w == 2 { paved += 1 } else if !isSett && flagged { wrong += 1 }
                }
            }
        }
        #expect(paved > 0, "sett street not paved")
        #expect(wrong == 0, "\(wrong) paving vertices outside tagged ways")
    }
}
