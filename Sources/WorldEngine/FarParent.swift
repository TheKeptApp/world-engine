import Foundation
import RealityKit
import WorldGen
import WorldGeo
import WorldMesh

/// Simplified far parent (`-diag farParent`, also part of `roam`; default off; 5A Batch 4), the
/// native port of A4's web trial (docs/execution/simplified-far-parent.md). When the camera's
/// nearest 3D distance to the whole core (every chunk's and building level's bounds, padded
/// 0.5 m) is at least `farParentMeters`, one parent replaces every building cell and tile: per
/// `farParentTileMeters` tile, the tile's buildings merged at `.far` (the web trial's
/// LOD1 masses: the generator's simple detail is `.far`) and at `.skyline`, one drawn by the
/// camera's 3D distance to the tile (`BuildingLOD.forDistance`; native cells beyond 600 m already
/// draw `.skyline`, so `.far` alone would add triangles). Ground (LOD0, as in the web trial) and
/// water stay their unchanged chunk tiles: merging raised ground into 800 m tiles was measured
/// (Batch 4) to add 30k triangles in view and 100k shadow triangles at 600 m for 27 fewer draws.
/// Exclusive with its children; below the distance the children come back exactly.
///
/// RealityKit has no shadow-only draw, so unlike the web trial the parent casts the shadows
/// (its own geometry, reach-toggled like the children under shadow cells); originals do not.
struct FarParentState {
    struct Tile {
        /// Buildings at `.far` and `.skyline`; `active` is drawn while the parent is admitted.
        var levels: [(lod: BuildingLOD, entity: Entity, bounds: BoundingBox, triangles: Int)] = []
        var active: Int?
        var entities: [Entity] { levels.map(\.entity) }
        /// The drawn level while admitted.
        var drawn: [(entity: Entity, bounds: BoundingBox, triangles: Int)] {
            active.map { [(levels[$0].entity, levels[$0].bounds, levels[$0].triangles)] } ?? []
        }
    }
    var tiles: [Tile] = []
    /// The whole core's bounds (padded), for admission.
    var core: BoundingBox
    var active = false
}

extension World {
    /// Nearest camera distance (m, 3D) to the core at which the parent is admitted (A4 trial).
    static let farParentMeters: Float = 400
    /// Parent tile side (m): the largest chunk tile (`chunkTileSize` × 200 m).
    static let farParentTileMeters = 800.0

    var farParentEnabled: Bool { options.diagnostics.contains("farParent") || options.diagnostics.contains("roam") }

    /// Builds the (disabled) parent from the load geometry; call before it is released.
    func buildFarParent() throws {
        guard farParentEnabled else { return }
        var by: [SIMD2<Int>: (far: WorldMesh.MeshBuffers, skyline: WorldMesh.MeshBuffers)] = [:]
        var core: BoundingBox?
        func grow(_ m: WorldMesh.MeshBuffers) {
            guard let b = m.bounds else { return }
            let box = BoundingBox(min: b.min, max: b.max)
            core = core.map { $0.union(box) } ?? box
        }
        func key(_ r: Rect2D) -> SIMD2<Int> {
            let c = (r.min + r.max) / 2
            return SIMD2(Int((c.x / Self.farParentTileMeters).rounded(.down)), Int((c.y / Self.farParentTileMeters).rounded(.down)))
        }
        for chunk in scene.chunks {
            grow(chunk.staticMesh)
        }
        for cell in scene.buildingCells {
            for m in cell.meshes.values { grow(m) }
            guard let far = cell.meshes[.far] ?? cell.meshes[.skyline], !far.isEmpty else { continue }
            by[key(cell.rect), default: (.init(), .init())].far.append(far)
            by[key(cell.rect), default: (.init(), .init())].skyline.append(cell.meshes[.skyline] ?? far)
        }
        guard var box = core else { return }
        box.min -= SIMD3(repeating: 0.5)
        box.max += SIMD3(repeating: 0.5)
        var state = FarParentState(core: box)
        for k in by.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            let parts = by[k]!
            func part(_ m: WorldMesh.MeshBuffers, _ name: String) throws -> (Entity, BoundingBox, Int)? {
                guard let b = m.bounds, let mesh = try MeshUpload.resource([m]) else { return nil }
                let e = Entity()
                e.name = "Far parent \(k.x)_\(k.y) \(name)"
                e.isEnabled = false
                e.components.set(ModelComponent(mesh: mesh, materials: [resources.staticMaterial]))
                receiveIBL(e)
                rootEntity.addChild(e)
                stats.meshBytes += m.gpuBytes
                stats.meshBytesByKind["far-parent-\(name)", default: 0] += m.gpuBytes
                return (e, BoundingBox(min: b.min, max: b.max), m.triangleCount)
            }
            var tile = FarParentState.Tile()
            for (lod, m) in [(BuildingLOD.far, parts.far), (.skyline, parts.skyline)] {
                if let r = try part(m, "\(lod)") { tile.levels.append((lod, r.0, r.1, r.2)) }
            }
            if !tile.levels.isEmpty { state.tiles.append(tile) }
        }
        farParent = state
    }

    /// Distance from a point to a box (0 inside).
    static func distance(_ p: SIMD3<Float>, to b: BoundingBox) -> Float {
        simd_distance(p, simd_clamp(p, b.min, b.max))
    }

    /// Admits or releases the parent for this camera and picks each tile's building level; true
    /// when admission switched.
    func updateFarParent(camera: SIMD3<Float>) -> Bool {
        guard let fp = farParent else { return false }
        let want = Self.distance(camera, to: fp.core) >= Self.farParentMeters
        if want {
            for i in fp.tiles.indices {
                let t = fp.tiles[i]
                let lod = BuildingLOD.forDistance(Double(t.levels.map { Self.distance(camera, to: $0.bounds) }.min() ?? 0))
                let pick = t.levels.firstIndex { $0.lod >= lod } ?? (t.levels.isEmpty ? nil : t.levels.count - 1)
                if pick != t.active || !fp.active {
                    for (j, l) in t.levels.enumerated() { l.entity.isEnabled = j == pick }
                    farParent!.tiles[i].active = pick
                }
            }
        }
        guard want != fp.active else { return false }
        farParent!.active = want
        if !want {
            for t in fp.tiles { for e in t.entities { e.isEnabled = false } }
            for i in fp.tiles.indices { farParent!.tiles[i].active = nil }
        }
        if want {
            // The children go; `updateBuildingLODs` re-picks them when the parent is released.
            for i in buildingCells.indices {
                for l in buildingCells[i].levels { l.entity.isEnabled = false }
                buildingCells[i].active = nil
            }
            for i in buildingTiles.indices {
                for l in buildingTiles[i].levels { l.entity.isEnabled = false }
                buildingTiles[i].active = nil
            }
        }
        return true
    }

    var farParentActive: Bool { farParent?.active == true }
}
