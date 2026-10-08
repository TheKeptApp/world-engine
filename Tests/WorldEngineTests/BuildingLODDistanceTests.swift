import Testing
import simd
import WorldGeo
@testable import WorldEngine

/// The aerial LOD bug: building cells took their LOD from horizontal distance, so cells below a high
/// camera picked the near level. The eye's 3D distance to the cell decides now.
@Suite("Building LOD eye distance")
@MainActor
struct BuildingLODDistanceTests {
    @Test func aerialEyeIsFarFromTheCellBelow() {
        let cell = Rect2D(min: LocalPoint(-50, -50), max: LocalPoint(50, 50))
        // Street eye inside the cell: 0 m. Aerial eye 98 m above a 9 m tall cell: 89 m.
        #expect(World.distance3D(eye: SIMD3(0, 1.65, 0), to: cell, top: 9) == 0)
        #expect(abs(World.distance3D(eye: SIMD3(0, 98, 0), to: cell, top: 9) - 89) < 1e-4)
        // Beside the cell at street height: the horizontal distance.
        #expect(abs(World.distance3D(eye: SIMD3(80, 1.65, 0), to: cell, top: 9) - 30) < 1e-4)
    }
}
