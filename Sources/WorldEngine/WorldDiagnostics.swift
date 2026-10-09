import Foundation
import Metal
import RealityKit
import WorldGen
import WorldGeo
import WorldMap
import WorldMesh

/// Tools for screenshots and reports. Not needed by apps.
@MainActor
extension World {
    /// Positions (scene space) of trees within `radius` of `point`.
    public func treePositions(near point: SIMD3<Float>, radius: Float) -> [SIMD3<Float>] {
        scene.instances.filter(\.kind.isTree)
            .map { LocalFrame.scenePosition(LocalPoint($0.x, $0.y), y: 0) }
            .filter { simd_distance(SIMD2($0.x, $0.z), SIMD2(point.x, point.z)) <= radius }
    }

    /// One entry in the footprint lineup.
    public struct LineupEntry: Sendable {
        public var label: String
        public var osmRef: String
        public var footprintClass: String
        public var roofShape: String
        public var houseType: String
        public var area: Double
        public var rectangularity: Double
    }

    /// Six real house footprints chosen by shape: a typical rectangle, an L-shape, a complex
    /// orthogonal shape, the smallest, the largest, and the least rectangular (worst) one.
    /// Built with full detail in a 2-column grid, `spacing` meters apart, centered on `origin`.
    public func footprintLineup(origin: SIMD3<Float>, spacing: Float = 42) -> (Entity, [LineupEntry]) {
        let context = StreetContext(features)
        let generator = BuildingGenerator(profile: scene.profile, context: context)
        let houses = features.buildings.filter { !$0.isPart && BuildingGenerator.role(of: $0) == .house }
        let analyzed = houses.map { ($0, FootprintAnalysis($0.footprint)) }

        var picks: [(String, Building)] = []
        func take(_ label: String, _ b: Building?) {
            if let b, !picks.contains(where: { $0.1.ref == b.ref }) { picks.append((label, b)) }
        }
        let rects = analyzed.filter { $0.1.kind == .rectangle }.sorted { $0.0.footprint.area < $1.0.footprint.area }
        take("Rectangle (typical)", rects.isEmpty ? nil : rects[rects.count / 2].0)
        take("L-shape", analyzed.filter { $0.1.kind == .orthogonal && $0.1.roofRects.count == 2 }
            .max { $0.0.footprint.area < $1.0.footprint.area }?.0)
        take("Complex orthogonal", analyzed.filter { $0.1.kind == .orthogonal && $0.1.roofRects.count >= 3 }
            .max { $0.1.roofRects.count < $1.1.roofRects.count }?.0)
        take("Smallest house", houses.min { $0.footprint.area < $1.footprint.area })
        take("Largest house", houses.max { $0.footprint.area < $1.footprint.area })
        take("Least rectangular (worst)", analyzed.min { $0.1.rectangularity < $1.1.rectangularity }?.0)

        let root = Entity()
        root.name = "Footprint lineup"
        var entries: [LineupEntry] = []
        var palette = scene.palette
        for (k, (label, b)) in picks.enumerated() {
            let c = b.footprint.centroid
            let g = generator.generate(b, palette: &palette, detail: .full)
            var mesh = g.mesh
            let shift = SIMD3<Float>(Float(-c.x), 0, Float(c.y))
            mesh.positions = mesh.positions.map { $0 + shift }
            let col = Float(k % 2), row = Float(k / 2)
            let slot = origin + SIMD3(col - 0.5, 0, row - 1) * spacing
            if let resource = try? MeshUpload.resource([mesh]) {
                let e = Entity()
                e.components.set(ModelComponent(mesh: resource, materials: [resources.staticMaterial]))
                e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
                e.position = slot
                root.addChild(e)
            }
            let a = FootprintAnalysis(b.footprint)
            entries.append(LineupEntry(label: label, osmRef: b.ref.description, footprintClass: a.kind.rawValue,
                                       roofShape: g.roofShape.rawValue, houseType: g.houseType ?? "-", area: b.footprint.area,
                                       rectangularity: a.rectangularity))
            let text = MeshResource.generateText("\(k + 1). \(label)\n\(g.houseType ?? "-"), \(g.roofShape.rawValue) roof\n\(Int(b.footprint.area)) m², fill \(Int(a.rectangularity * 100))%",
                                                 extrusionDepth: 0.02, font: .systemFont(ofSize: 1.6, weight: .semibold), alignment: .center)
            let labelEntity = ModelEntity(mesh: text, materials: [UnlitMaterial(color: .black)])
            let w = text.bounds.extents.x
            labelEntity.position = slot + SIMD3(-w / 2, 0.05, 17)
            labelEntity.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
            root.addChild(labelEntity)
        }
        var ground = WorldMesh.MeshBuffers()
        ground.paint = Paint(slot: scene.palette.named("lawn"), flags: .lawn)
        let half: Float = 400
        let o = origin
        ground.addVertex(o + [-half, 0, -half], normal: [0, 1, 0]); ground.addVertex(o + [half, 0, -half], normal: [0, 1, 0])
        ground.addVertex(o + [half, 0, half], normal: [0, 1, 0]); ground.addVertex(o + [-half, 0, half], normal: [0, 1, 0])
        ground.addTriangle(0, 3, 2); ground.addTriangle(0, 2, 1)
        if let r = try? MeshUpload.resource([ground]) {
            let e = Entity()
            e.components.set(ModelComponent(mesh: r, materials: [resources.staticMaterial]))
            e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
            root.addChild(e)
        }
        rootEntity.addChild(root)
        return (root, entries)
    }
}

/// GPU attribution switches (WorldLab `-attribution`): turn one feature off at runtime so a GPU
/// trace can be split by feature. Not for apps.
@MainActor
extension World {
    public enum Feature: String, CaseIterable, Sendable {
        case shadows, sky, foliage, surfaceDetail, particles, buildings
        /// Opaque trees and bushes outside the cut-away zone (off = every level cuttable, as before).
        case opaqueDetail
    }

    public func set(_ feature: Feature, enabled on: Bool) {
        switch feature {
        case .shadows:
            if on, let env = environment { apply(env) } else { sunEntity.components.remove(DirectionalLightComponent.Shadow.self) }
        case .sky:
            skyDome?.isEnabled = on
            starField?.entity.isEnabled = on && (environment?.light.starStrength ?? 0) > 0.001
        case .foliage:
            for e in rootEntity.children where e.name.hasPrefix("LOD ") || e.name == "Clutter tufts" { e.isEnabled = on && featureWasEnabled(e) }
            if on { lodCenter = nil }
        case .surfaceDetail:
            shaderGlobals.debug = on ? 0 : 5
            resources.update(globals: shaderGlobals)
        case .particles:
            particlesAllowed = on
            precipitation?.isEnabled = on && !environmentState.precipitation.isEmpty
        case .buildings:
            for e in rootEntity.children where e.name.hasPrefix("Chunk ") { e.isEnabled = on }
            setBuildingsVisible(on)
        case .opaqueDetail:
            opaqueDetail = on
        }
    }

    private func featureWasEnabled(_ e: Entity) -> Bool { true }

    /// The live sun shadow range in metres (look.json `shadows.rangeM`; low sun widens it).
    public var shadowRange: Float { shadowDistance }

    /// Sun shadow range in metres (diagnostics: GPU cost of other shadow ranges).
    public func setShadowDistance(_ meters: Float) {
        shadowDistance = meters
        guard var shadow = sunEntity.components[DirectionalLightComponent.Shadow.self] else { return }
        shadow.shadowProjection = .automatic(maximumDistance: meters)
        shadow.depthBias = Self.shadowBias(range: meters)
        sunEntity.components.set(shadow)
    }
}

// MARK: - Memory attribution (5A Batch 1)

extension WorldMesh.MeshBuffers {
    /// CPU bytes held by these buffers (Swift arrays; SIMD3<Float> is 16-byte aligned).
    var cpuBytes: Int {
        positions.count * 16 + normals.count * 16 + paints.count * 16 + extras.count * 16
            + uvs.count * 8 + surfaceWords.count * 2 + indices.count * 4
    }
}

@MainActor
extension World {
    /// The app process's physical footprint (what iOS counts against its limit), in bytes.
    nonisolated static func physicalFootprint() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return kr == KERN_SUCCESS ? Int(info.phys_footprint) : 0
    }

    /// One `MEMORY` line attributing the process footprint (MiB): GPU allocations (Metal device total),
    /// of which world geometry (vertex/index buffers we upload) and the rest (RealityKit render targets,
    /// shadow maps, IBL, textures); CPU copies of generated geometry still held; and everything else
    /// (RealityKit/CPU heap, code, OSM-derived data). Shadow maps are not separable from RealityKit's
    /// own allocations without a GPU capture.
    public func memoryReport() -> String {
        func mib(_ b: Int) -> String { String(format: "%.1f", Double(b) / 1_048_576) }
        let footprint = Self.physicalFootprint()
        let gpu = Int(MTLCreateSystemDefaultDevice()?.currentAllocatedSize ?? 0)
        var sceneCPU = scene.boundaryGround.cpuBytes
        for c in scene.chunks { sceneCPU += c.staticMesh.cpuBytes + c.waterMesh.cpuBytes }
        for c in scene.buildingCells { for m in c.meshes.values { sceneCPU += m.cpuBytes } }
        let propCPU = meshCacheCPUBytes
        let geometry = stats.meshBytes
        let other = max(0, footprint - gpu - sceneCPU - propCPU)
        return "MEMORY footprint=\(mib(footprint)) gpuAllocated=\(mib(gpu)) geometryGPU=\(mib(geometry)) gpuOther=\(mib(max(0, gpu - geometry))) "
            + "sceneCPU=\(mib(sceneCPU)) propCacheCPU=\(mib(propCPU)) other=\(mib(other)) loadOnlyReleased=\(loadOnlyGeometryReleased) "
            + "geometry[" + stats.meshBytesByKind.sorted { $0.key < $1.key }.map { "\($0.key)=\(mib($0.value))" }.joined(separator: " ") + "]"
    }
}

// MARK: - Shadow-pass estimate (5A Batch 1)

@MainActor
extension World {
    /// Analytic sun shadow-pass cost for a camera, from the scene graph (RealityKit exposes no
    /// shadow counters): the shadow map covers the view frustum from the near plane out to the
    /// applied shadow range, seen along the sun. A caster is drawn when its bounds, projected
    /// across the light, overlap that region and it is not wholly beyond the receivers. Casters:
    /// raised chunk geometry, building cells/tiles at their active level, instanced trees/bushes/props.
    /// Flat ground, water, context ring, tufts and sky do not cast. One map; RealityKit's cascade
    /// split (not exposed) redraws casters per cascade, so the per-pass total is this × the casters
    /// shared between cascades (at most × cascade count).
    public func shadowEstimate(camera: Entity) -> (triangles: Int, draws: Int, range: Float, casters: String) {
        guard sunEntity.components.has(DirectionalLightComponent.Shadow.self) else { return (0, 0, 0, "no sun shadow") }
        let range = appliedShadowRange > 0 ? appliedShadowRange : shadowDistance
        let fov = (camera.components[PerspectiveCameraComponent.self]?.fieldOfViewInDegrees ?? 50) * .pi / 180
        let m = camera.transformMatrix(relativeTo: nil)
        let eye = SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        let fwd = -SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z), right = SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.z),
            up = SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.z)
        let ty = tan(fov / 2), tx = ty * viewAspect
        var corners: [SIMD3<Float>] = []
        for d: Float in [0.1, range] { for sx: Float in [-1, 1] { for sy: Float in [-1, 1] { corners.append(eye + fwd * d + right * (sx * tx * d) + up * (sy * ty * d)) } } }
        // Light frame: travel = direction the light shines (sun entity −Z); u, v across it.
        let sm = sunEntity.transformMatrix(relativeTo: nil)
        let travel = simd_normalize(-SIMD3(sm.columns.2.x, sm.columns.2.y, sm.columns.2.z))
        let u = simd_normalize(simd_cross(travel, abs(travel.y) > 0.99 ? SIMD3(1, 0, 0) : SIMD3(0, 1, 0))), v = simd_cross(travel, u)
        func proj(_ p: SIMD3<Float>) -> SIMD3<Float> { SIMD3(simd_dot(p, u), simd_dot(p, v), simd_dot(p, travel)) }
        let pc = corners.map(proj)
        let lo = pc.reduce(SIMD3(repeating: .infinity)) { simd_min($0, $1) }, hi = pc.reduce(SIMD3(repeating: -.infinity)) { simd_max($0, $1) }
        func casts(_ b: BoundingBox) -> Bool {
            var bl = SIMD3<Float>(repeating: .infinity), bh = SIMD3<Float>(repeating: -.infinity)
            for i in 0..<8 {
                let p = proj(SIMD3(i & 1 == 0 ? b.min.x : b.max.x, i & 2 == 0 ? b.min.y : b.max.y, i & 4 == 0 ? b.min.z : b.max.z))
                bl = simd_min(bl, p); bh = simd_max(bh, p)
            }
            return bh.x >= lo.x && bl.x <= hi.x && bh.y >= lo.y && bl.y <= hi.y && bl.z <= hi.z
        }
        var tris = 0, draws = 0
        var split: [String: (Int, Int)] = [:]
        func add(_ k: String, _ t: Int, _ d: Int) { tris += t; draws += d; split[k, default: (0, 0)].0 += t; split[k, default: (0, 0)].1 += d }
        for c in cullables where c.category == \ViewCost.chunks && !c.name.hasSuffix("ground") && !c.name.contains("water") && casts(c.bounds) {
            add("chunks", c.triangles, c.draws)
        }
        for cell in buildingCells { if let b = cell.bounds, let a = cell.active, casts(b) { add("buildings", cell.levels[a].triangles, 1) } }
        for tile in buildingTiles { if let a = tile.active, casts(tile.levels[a].bounds) { add("buildings", tile.levels[a].triangles, 1) } }
        for batch in lodBatches where batch.count > 0 {
            if let b = batch.bounds, casts(b) { add(batch.kind.isFoliage ? "foliage" : "props", batch.count * batch.triangles, 1) }
        }
        let s = split.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value.0)/\($0.value.1)" }.joined(separator: " ")
        return (tris, draws, range, s)
    }
}
