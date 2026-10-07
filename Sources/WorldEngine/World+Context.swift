import Foundation
import RealityKit
import WorldGen
import WorldGeo
import WorldMap
import WorldMesh

/// The context ring's entities: one static entity per cell level (one enabled per cell) and one
/// water entity for the whole ring.
struct ContextRuntime {
    struct Cell {
        var rect: Rect2D
        /// By `ContextLOD.rawValue`; nil where that level is empty.
        var levels: [(entity: Entity, triangles: Int, bounds: BoundingBox)?]
        var active: Int?
    }
    var cells: [Cell] = []
    /// Cells on the same side of the area box (one of 8 sectors), merged per level: when every
    /// cell of a sector picks the same level, the sector's entity draws them in one call.
    struct Group {
        var cells: [Int]
        var levels: [(entity: Entity, triangles: Int, bounds: BoundingBox)?]
        var active: Int?
    }
    var groups: [Group] = []
    var water: (entity: Entity, triangles: Int, bounds: BoundingBox)?
    var settings = ContextSettings()
    var task: Task<Void, Never>?
}

/// Context ring (look-fix-v1 §4): real low-detail ground around the area, read from the area
/// manifest's "context" layer (no area names in code). Built off the main thread after the
/// detailed world, so it never delays the first frame; the cells then appear at once. Opaque, no
/// shadow casting; atmosphere, fog and the clear-air fade apply as on every world surface.
@MainActor
extension World {
    func startContext(areaDirectory: URL) {
        guard !options.diagnostics.contains("noContext"), !manifest.contextSources.isEmpty else { return }
        let manifest = manifest, palette = scene.palette, profile = scene.profile
        // An explicit profile overrides every building (as in the detailed world); otherwise
        // buildings take the zone profile at their location.
        let byLocation = options.profileID == nil
        context.task = Task.detached(priority: .utility) { [weak self] in
            let built: (scene: ContextScene, parseSeconds: Double, generateSeconds: Double)?
            do {
                built = try ContextRing.build(areaDirectory: areaDirectory, manifest: manifest, palette: palette, profile: profile,
                                              zonesByLocation: byLocation)
            } catch {
                print("CONTEXT failed: \(error)")
                return
            }
            guard let built, !Task.isCancelled else { return }
            await self?.attachContext(built.scene, parseSeconds: built.parseSeconds, generateSeconds: built.generateSeconds)
        }
    }

    func attachContext(_ ring: ContextScene, parseSeconds: Double, generateSeconds: Double) async {
        // The ring's buildings may have added colours; slots of the detailed world are unchanged.
        if ring.palette.colors.count > scene.palette.colors.count {
            scene.palette = ring.palette
            if let env = environment { apply(env) } else { resources.setPalette(scene.palette) }
        }
        context.settings = ring.settings
        func entity(_ m: WorldMesh.MeshBuffers, name: String, material: CustomMaterial) -> (Entity, Int, BoundingBox)? {
            guard !m.isEmpty, let b = m.bounds, let mesh = try? MeshUpload.resource([m]) else { return nil }
            let e = Entity()
            e.name = name
            e.components.set(ModelComponent(mesh: mesh, materials: [material]))
            e.components.set(DynamicLightShadowComponent(castsShadow: false))
            receiveIBL(e)
            stats.meshBytes += m.gpuBytes
            return (e, m.triangleCount, BoundingBox(min: b.min, max: b.max))
        }
        var cells: [ContextRuntime.Cell] = []
        for c in ring.cells {
            var cell = ContextRuntime.Cell(rect: c.rect, levels: [], active: nil)
            for lod in ContextLOD.allCases {
                let made = entity(c.mesh(lod), name: "Context \(c.id) \(lod)", material: resources.staticMaterial)
                made?.0.isEnabled = false
                cell.levels.append(made.map { (entity: $0.0, triangles: $0.1, bounds: $0.2) })
            }
            cells.append(cell)
            // Spread the uploads over a few main-actor turns.
            await Task.yield()
        }
        for c in cells { for l in c.levels { if let l { rootEntity.addChild(l.entity) } } }
        // Sectors around the area box (3 × 3 minus the box): merged meshes per level.
        var sectors: [SIMD2<Int>: [Int]] = [:]
        for (i, c) in ring.cells.enumerated() {
            let m = (c.rect.min + c.rect.max) / 2
            let sx = m.x < ring.core.min.x ? 0 : m.x > ring.core.max.x ? 2 : 1
            let sy = m.y < ring.core.min.y ? 0 : m.y > ring.core.max.y ? 2 : 1
            sectors[SIMD2(sx, sy), default: []].append(i)
        }
        var groups: [ContextRuntime.Group] = []
        for key in sectors.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            let members = sectors[key]!
            guard members.count > 1 else { continue }
            var g = ContextRuntime.Group(cells: members, levels: [], active: nil)
            for lod in ContextLOD.allCases {
                var merged = WorldMesh.MeshBuffers()
                for i in members { merged.append(ring.cells[i].mesh(lod)) }
                let made = entity(merged, name: "Context sector \(key.x)_\(key.y) \(lod)", material: resources.staticMaterial)
                made?.0.isEnabled = false
                if let made { rootEntity.addChild(made.0) }
                g.levels.append(made.map { (entity: $0.0, triangles: $0.1, bounds: $0.2) })
                await Task.yield()
            }
            groups.append(g)
        }
        context.groups = groups
        if let w = entity(ring.water, name: "Context water", material: resources.waterMaterial) {
            rootEntity.addChild(w.0)
            context.water = (w.0, w.1, w.2)
        }
        context.cells = cells
        stats.contextCells = cells.count
        stats.contextParseSeconds = parseSeconds
        stats.contextGenerateSeconds = generateSeconds
        let cam = lodCenter ?? SIMD3(0, 1.65, 0)
        updateContextLODs(camera: cam)
        recount()
        print(String(format: "CONTEXT cells=%d parse=%.2fs generate=%.2fs triangles=%@", cells.count, parseSeconds, generateSeconds,
                     ContextLOD.allCases.map { "\($0)=\(ring.stats["triangles.\($0)"] ?? 0)" }.joined(separator: ",")
                         + ",water=\(ring.water.triangleCount)"))
    }

    /// Picks each cell's level for a camera position (scene space). A sector whose cells all want
    /// the same level draws them as its merged entity; so does one whose cells want one level or
    /// `far`, at that level, when that adds at most `contextGroupAllowance` triangles.
    func updateContextLODs(camera: SIMD3<Float>) {
        guard !context.cells.isEmpty else { return }
        let eye = SIMD3<Double>(Double(camera.x), Double(-camera.z), Double(camera.y))
        var tris = context.water?.triangles ?? 0
        let wants = context.cells.map { ContextLOD.pick(eye: eye, cell: $0.rect, settings: context.settings).rawValue }
        var picks: [Int?] = context.cells.indices.map { context.cells[$0].levels[wants[$0]] == nil ? nil : wants[$0] }
        let far = ContextLOD.far.rawValue
        for gi in context.groups.indices {
            let g = context.groups[gi]
            let levels = Set(g.cells.map { wants[$0] })
            var pick: Int? = nil
            if levels.count == 1 {
                pick = levels.first
            } else if levels.count == 2, levels.contains(far), let l = levels.first(where: { $0 != far }), let merged = g.levels[l] {
                let own = g.cells.reduce(0) { sum, i in sum + (picks[i].flatMap { context.cells[i].levels[$0]?.triangles } ?? 0) }
                if merged.triangles <= own + Self.contextGroupAllowance { pick = l }
            }
            if let p = pick, g.levels[p] == nil { pick = nil }
            if g.active != pick {
                for (k, l) in g.levels.enumerated() { l?.entity.isEnabled = k == pick }
                context.groups[gi].active = pick
            }
            if let p = pick, let l = g.levels[p] {
                tris += l.triangles
                for i in g.cells { picks[i] = nil }
            }
        }
        for i in context.cells.indices {
            let pick = picks[i]
            if context.cells[i].active != pick {
                for (k, l) in context.cells[i].levels.enumerated() { l?.entity.isEnabled = k == pick }
                context.cells[i].active = pick
            }
            if let p = pick, let l = context.cells[i].levels[p] { tris += l.triangles }
        }
        stats.contextTriangles = tris
    }

    /// Triangles a context sector may add by drawing far cells at its nearer level.
    static let contextGroupAllowance = 3000

    /// Draw calls of the ring with every enabled entity counted.
    var contextDrawCalls: Int {
        context.cells.filter { $0.active != nil }.count + context.groups.filter { $0.active != nil }.count + (context.water == nil ? 0 : 1)
    }

    /// The ring's share of `estimateView`: enabled entities whose bounds meet the frustum.
    func contextView(_ planes: [SIMD4<Float>]) -> (triangles: Int, drawCalls: Int) {
        var t = 0, d = 0
        for c in context.cells {
            guard let a = c.active, let l = c.levels[a], Self.intersects(l.bounds, planes) else { continue }
            t += l.triangles
            d += 1
        }
        for g in context.groups {
            guard let a = g.active, let l = g.levels[a], Self.intersects(l.bounds, planes) else { continue }
            t += l.triangles
            d += 1
        }
        if let w = context.water, Self.intersects(w.bounds, planes) { t += w.triangles; d += 1 }
        return (t, d)
    }
}
