import Foundation
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
