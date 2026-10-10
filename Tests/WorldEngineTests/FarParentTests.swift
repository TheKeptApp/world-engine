import Foundation
import RealityKit
import Testing
@testable import WorldEngine
import WorldGen
import WorldGeo

/// The simplified far parent and per-cell tree instancing (5A Batch 4; FarParent.swift): default
/// off, the 400 m whole-core admission, exclusive parent/children and exact restoration, and tree
/// cells holding the same instances as the whole-world batches. Runs only when the engine's shaders
/// are compiled for the Mac, like the other world tests.
@MainActor
@Suite("Far parent and tree cells", .serialized)
struct FarParentTests {
    static let date = ISO8601DateFormatter().date(from: "2026-10-15T20:30:00Z")!

    static func world(_ diagnostics: Set<String>) async throws -> World? {
        guard OffscreenPostcardTests.shadersReady,
              FileManager.default.fileExists(atPath: OffscreenPostcardTests.area.appendingPathComponent("manifest.json").path) else { return nil }
        let world = try await World.load(areaDirectory: OffscreenPostcardTests.area,
                                         options: WorldOptions(focus: OffscreenPostcardTests.focus, date: date, diagnostics: diagnostics))
        let resolver = try world.environmentResolver(timeZone: TimeZone(identifier: "America/Denver")!, phenologyProfileID: nil)
        world.apply(resolver.resolve(SyntheticWeather(label: .clear, cloudFraction: 0.1).input(at: date)))
        world.viewAspect = 16.0 / 9.0
        return world
    }

    /// A camera `height` m above `p`, looking 45° down.
    static func look(_ world: World, _ camera: Entity, from p: SIMD3<Float>) {
        camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: 50))
        camera.look(at: SIMD3(p.x - p.y, 0, p.z), from: p, relativeTo: nil)
        world.update(deltaTime: 0.5, camera: camera, focusPoint: nil, cutAwayTarget: nil)
    }

    @Test func defaultOff() async throws {
        guard let world = try await Self.world([]) else { return }
        #expect(world.farParent == nil)
        #expect(!world.treeCells)
        #expect(!world.lodBatches.contains { $0.entity.name.contains(" cell ") })
    }

    @Test func admissionIsExclusiveAndRestores() async throws {
        guard let world = try await Self.world(["farParent"]) else { return }
        let fp = try #require(world.farParent)
        #expect(!fp.tiles.isEmpty && fp.tiles.allSatisfy { $0.entities.allSatisfy { !$0.isEnabled } })
        let core = fp.core
        let mid = (core.min + core.max) / 2
        let camera = Entity()
        // Inside the area at 40 m: children only.
        Self.look(world, camera, from: SIMD3(mid.x, 40, mid.z))
        let near = world.buildingCells.map(\.active)
        #expect(!world.farParentActive)
        #expect(world.raisedTiles.allSatisfy { $0.entity.isEnabled })
        // Just under and just over 400 m above the core's top.
        Self.look(world, camera, from: SIMD3(mid.x, core.max.y + 399.9, mid.z))
        #expect(!world.farParentActive)
        Self.look(world, camera, from: SIMD3(mid.x, core.max.y + 400.1, mid.z))
        #expect(world.farParentActive)
        #expect(world.farParent!.tiles.allSatisfy { t in t.entities.allSatisfy { e in t.drawn.contains { $0.entity === e } == e.isEnabled } })
        #expect(world.farParent!.tiles.allSatisfy { $0.levels.isEmpty || $0.active != nil })
        #expect(world.buildingCells.allSatisfy { cell in cell.active == nil && cell.levels.allSatisfy { !$0.entity.isEnabled } })
        #expect(world.buildingTiles.allSatisfy { tile in tile.active == nil && tile.levels.allSatisfy { !$0.entity.isEnabled } })
        // Back near: the same children as before, the parent gone.
        Self.look(world, camera, from: SIMD3(mid.x, 40, mid.z))
        #expect(!world.farParentActive)
        #expect(world.farParent!.tiles.allSatisfy { $0.entities.allSatisfy { !$0.isEnabled } })
        #expect(world.raisedTiles.allSatisfy { $0.entity.isEnabled })
        #expect(world.buildingCells.map(\.active) == near)
    }

    @Test func treeCellsHoldTheSameInstances() async throws {
        guard let whole = try await Self.world(["shadowCells"]), let cells = try await Self.world(["shadowCells", "treeCells"]) else { return }
        #expect(cells.treeCells)
        #expect(cells.lodBatches.contains { $0.entity.name.contains(" cell ") })
        let camera = Entity()
        func counts(_ w: World) -> [String: Int] {
            var c: [String: Int] = [:]
            for b in w.lodBatches { c["\(b.kind.rawValue) \(b.slot) \(b.casts)", default: 0] += b.count }
            return c
        }
        for height: Float in [40, 150, 600] {
            Self.look(whole, camera, from: SIMD3(0, height, 0))
            Self.look(cells, camera, from: SIMD3(0, height, 0))
            #expect(counts(whole) == counts(cells))
            // Tree cells cast only from their own cell batches.
            #expect(!cells.lodBatches.contains { $0.kind.isTree && $0.casts && $0.twin != nil && $0.count > 0 })
        }
    }
}
