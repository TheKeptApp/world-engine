import Testing
@testable import WorldGen

/// House detail by on-screen size (house-archetypes-v1 tiers: windows above 20 px, voids from 6 px).
@Suite("Building LOD by projected size")
struct BuildingLODProjectionTests {
    func lod(_ d: Double, _ h: Double) -> BuildingLOD {
        BuildingLOD.forProjection(distance: d, heightM: h, verticalFOVDegrees: 50, frameHeightPx: 565,
                                  nearDistance: 50, midMinPx: 20, farMinPx: 6)
    }

    @Test func tiersFollowProjectedHeight() {
        #expect(lod(30, 8) == .near)
        // A 10 m flat is ~20 px at ~303 m on a 565 px frame at 50°: mid out past the old 150 m switch.
        #expect(lod(250, 10) == .mid)
        #expect(lod(350, 10) == .far)
        // ...and far (outline) until ~6 px, ~1010 m, past the old 600 m skyline switch.
        #expect(lod(900, 10) == .far)
        #expect(lod(1100, 10) == .skyline)
    }

    @Test func aWiderLensShrinksBuildings() {
        let narrow = BuildingLOD.forProjection(distance: 280, heightM: 10, verticalFOVDegrees: 40, frameHeightPx: 565,
                                               nearDistance: 50, midMinPx: 20, farMinPx: 6)
        let wide = BuildingLOD.forProjection(distance: 280, heightM: 10, verticalFOVDegrees: 70, frameHeightPx: 565,
                                             nearDistance: 50, midMinPx: 20, farMinPx: 6)
        #expect(narrow == .mid && wide == .far)
    }
}
