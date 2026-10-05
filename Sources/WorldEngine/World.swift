import Foundation
import Metal
import RealityKit
import WorldGen
import WorldGeo
import WorldMap
import WorldMesh

/// Options for building a world from an area directory.
public struct WorldOptions: Sendable {
    /// Region that gets full street-level detail. Nil = the whole area.
    public var focus: GeoBoundingBox?
    /// Force a style profile by ID (e.g. "default" for the worst-case generalization run).
    /// Nil = selected by location from the bundled region data.
    public var profileID: String?
    /// Draw trees, bushes, grass, lamps and benches with GPU instancing (iOS 26) instead of
    /// merging copies into chunk meshes.
    public var instancing = true
    /// The time that sets the sun position.
    public var date: Date
    /// Performance experiments: "noShadows", "noProps", "noClutter", "opaqueProps".
    public var diagnostics: Set<String> = []

    public init(focus: GeoBoundingBox? = nil, profileID: String? = nil, instancing: Bool = true, date: Date = Date(),
                diagnostics: Set<String> = []) {
        self.focus = focus
        self.profileID = profileID
        self.instancing = instancing
        self.date = date
        self.diagnostics = diagnostics
    }
}

/// Counts for performance reports.
public struct WorldStats: Sendable {
    public var triangles = 0
    /// Draw calls if everything were visible (mesh parts across entities).
    public var drawCalls = 0
    public var staticTriangles = 0
    public var propTriangles = 0
    public var propInstances = 0
    public var clutterInstances = 0
    /// GPU bytes of world vertex/index data plus instance transforms.
    public var meshBytes = 0
    public var chunkCount = 0
    public var buildSeconds = 0.0
    public var profileID = ""
    public var generated: [String: Int] = [:]
}

/// A built world: entities plus the engine-side state that animates it.
@MainActor
public final class World {
    public let rootEntity = Entity()
    public let frame: LocalFrame
    public let manifest: AreaManifest
    public let sun: SolarPosition
    public private(set) var stats = WorldStats()
    public var shaderGlobals = ShaderGlobals()

    let scene: GeneratedScene
    let features: MapFeatures
    let resources: RenderResources
    let options: WorldOptions
    let skyEnvironment: EnvironmentResource?
    let iblEntity = Entity()
    var motions: [WorldMotion] = []
    /// The per-frame update subscription (owned here so it can't be released early).
    var frameSubscription: EventSubscription?
    private var clutter: (entity: Entity, data: LowLevelInstanceData, center: LocalPoint)?
    private var tuftMesh: MeshResource?
    static let clutterRadius = 45.0

    /// Loads an area directory (manifest + OSM data) and builds the world.
    public static func load(areaDirectory: URL, options: WorldOptions = .init()) async throws -> World {
        let start = Date()
        let generated = try await Task.detached(priority: .userInitiated) { () throws -> (AreaManifest, GeneratedScene, MapFeatures) in
            let manifest = try AreaLoader.loadManifest(areaDirectory)
            let features = try AreaLoader.loadFeatures(areaDirectory)
            let profile = try options.profileID.map(StyleLibrary.profile(id:)) ?? StyleLibrary.profile(at: manifest.center)
            let focus: Rect2D
            if let f = options.focus {
                let a = manifest.frame.localPoint(of: GeoCoordinate(latitude: f.south, longitude: f.west))
                let b = manifest.frame.localPoint(of: GeoCoordinate(latitude: f.north, longitude: f.east))
                focus = Rect2D(min: simd_min(a, b), max: simd_max(a, b))
            } else {
                focus = features.bounds
            }
            let gen = SceneGenerator(features: features, profile: profile, baseColors: try StyleLibrary.baseColors(), focus: focus)
            return (manifest, gen.generate(), features)
        }.value
        let world = try World(manifest: generated.0, scene: generated.1, features: generated.2, options: options)
        world.stats.buildSeconds = Date().timeIntervalSince(start)
        return world
    }

    init(manifest: AreaManifest, scene: GeneratedScene, features: MapFeatures, options: WorldOptions) throws {
        self.manifest = manifest
        self.scene = scene
        self.features = features
        self.options = options
        frame = manifest.frame
        sun = SolarPosition(date: options.date, at: manifest.center)
        resources = try RenderResources(palette: scene.palette)

        let sky = SkyKeyframe.at(elevation: sun.elevation)
        skyEnvironment = Atmosphere.skyImage(sky, sun: sun).flatMap { try? EnvironmentResource(equirectangular: $0) }
        shaderGlobals.fogColor = Atmosphere.linear(sky.horizon)
        shaderGlobals.fogDensity = 0.0016
        shaderGlobals.fogStart = 90

        rootEntity.name = "World"
        buildLights(sky)
        try buildChunks()
        try buildProps()
        buildOccluders()
        stats.profileID = scene.profile.id
        stats.generated = scene.stats
        stats.chunkCount = scene.chunks.count
        resources.update(globals: shaderGlobals)
    }

    // MARK: - Coordinates

    /// Lat/lon → world position at ground level (meters; east = +X, north = −Z).
    public func position(of c: GeoCoordinate) -> SIMD3<Float> {
        frame.scenePosition(of: c, y: GroundLayer.sidewalk)
    }

    /// World position → lat/lon.
    public func coordinate(at p: SIMD3<Float>) -> GeoCoordinate {
        frame.coordinate(at: LocalPoint(Double(p.x), Double(-p.z)))
    }

    // MARK: - Entities from the host app

    /// Adds an app-provided entity at a lat/lon, standing on the ground (its origin = its feet).
    public func place(_ entity: Entity, at c: GeoCoordinate, heading: Float? = nil) {
        if entity.parent !== rootEntity { rootEntity.addChild(entity) }
        entity.position = position(of: c)
        if let heading { entity.orientation = simd_quatf(angle: -heading, axis: [0, 1, 0]) }
    }

    /// Removes an entity the app placed (and stops its motion).
    public func remove(_ entity: Entity) {
        motions.removeAll { $0.entity === entity }
        entity.removeFromParent()
    }

    /// Walks an entity along a route at `speed` m/s, facing the direction of travel.
    @discardableResult
    public func move(_ entity: Entity, along route: [GeoCoordinate], speed: Double, loop: Bool = true) -> WorldMotion {
        if entity.parent !== rootEntity { rootEntity.addChild(entity) }
        motions.removeAll { $0.entity === entity }
        let m = WorldMotion(entity: entity, route: route.map(frame.localPoint(of:)), speed: speed, loop: loop)
        motions.append(m)
        m.apply()
        return m
    }

    /// Per-frame update: motions, near-camera clutter, shader globals.
    func update(deltaTime dt: Double, camera: Entity, focusPoint: SIMD3<Float>?, cutAwayTarget: SIMD3<Float>?) {
        for m in motions { m.advance(dt) }
        if let p = focusPoint { updateClutter(around: LocalPoint(Double(p.x), Double(-p.z))) }
        var g = shaderGlobals
        g.camera = camera.position(relativeTo: nil)
        if let target = cutAwayTarget {
            // Character relative to the camera, in world axes (small numbers: fine in half floats).
            g.characterView = target - camera.position(relativeTo: nil)
        } else {
            g.characterView = nil
        }
        resources.update(globals: g)
    }

    // MARK: - Building

    private func buildLights(_ sky: SkyKeyframe) {
        let sunEntity = Entity()
        sunEntity.name = "Sun"
        var light = DirectionalLightComponent(color: .init(red: CGFloat(sky.sunColor.x), green: CGFloat(sky.sunColor.y),
                                                            blue: CGFloat(sky.sunColor.z), alpha: 1),
                                              intensity: sky.sunIntensity)
        light.isRealWorldProxy = false
        sunEntity.components.set(light)
        if !options.diagnostics.contains("noShadows") {
            var shadow = DirectionalLightComponent.Shadow()
            shadow.shadowProjection = .automatic(maximumDistance: 90)
            shadow.depthBias = 1.5
            sunEntity.components.set(shadow)
        }
        // Light shines along −Z of the entity: point it from the sun toward the ground.
        let dir = sun.sceneDirection
        sunEntity.look(at: .zero, from: max(dir.y, 0.05) > 0 ? dir * 100 : [0, 100, 0], relativeTo: nil)
        rootEntity.addChild(sunEntity)

        if let env = skyEnvironment {
            iblEntity.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: sky.ambientExponent))
        }
        rootEntity.addChild(iblEntity)
    }

    private func receiveIBL(_ e: Entity) {
        e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
    }

    private func buildChunks() throws {
        for chunk in scene.chunks {
            var parts: [WorldMesh.MeshBuffers] = [], materials: [any Material] = []
            if !chunk.staticMesh.isEmpty { parts.append(chunk.staticMesh); materials.append(resources.staticMaterial) }
            if !chunk.waterMesh.isEmpty { parts.append(chunk.waterMesh); materials.append(resources.waterMaterial) }
            guard let mesh = try MeshUpload.resource(parts) else { continue }
            let e = Entity()
            e.name = "Chunk \(chunk.index.x),\(chunk.index.y)"
            e.components.set(ModelComponent(mesh: mesh, materials: materials))
            receiveIBL(e)
            rootEntity.addChild(e)
            let tris = parts.reduce(0) { $0 + $1.triangleCount }
            stats.staticTriangles += tris
            stats.drawCalls += parts.count
            stats.meshBytes += parts.reduce(0) { $0 + $1.gpuBytes }
        }
    }

    static func isFoliage(_ k: PropKind) -> Bool { ![PropKind.lamp, .bench].contains(k) }

    private func propMesh(_ kind: PropKind, _ variant: Int) -> WorldMesh.MeshBuffers {
        PropLibrary.mesh(kind, variant: variant, palette: scene.palette)
    }

    private func buildProps() throws {
        if options.diagnostics.contains("noProps") { stats.triangles = stats.staticTriangles; return }
        let propMat = options.diagnostics.contains("opaqueProps") ? resources.staticMaterial : resources.propMaterial
        let foliageMat = options.diagnostics.contains("opaqueProps") ? resources.foliageOpaqueMaterial : resources.foliageMaterial
        var meshCache: [String: (MeshResource, WorldMesh.MeshBuffers)] = [:]
        func cached(_ k: PropKind, _ v: Int) throws -> (MeshResource, WorldMesh.MeshBuffers)? {
            let key = "\(k.rawValue)/\(v)"
            if let c = meshCache[key] { return c }
            let buffers = propMesh(k, v)
            guard let r = try MeshUpload.resource([buffers]) else { return nil }
            meshCache[key] = (r, buffers)
            stats.meshBytes += buffers.gpuBytes
            return (r, buffers)
        }

        if options.instancing {
            for set in scene.props {
                guard let (mesh, buffers) = try cached(set.kind, set.variant) else { continue }
                let e = try instancedEntity(mesh: mesh, buffers: buffers, transforms: set.transforms,
                                            material: Self.isFoliage(set.kind) ? foliageMat : propMat)
                e.name = "Props \(set.kind.rawValue)/\(set.variant) @\(set.group.x),\(set.group.y)"
                rootEntity.addChild(e)
                stats.propInstances += set.transforms.count
                stats.propTriangles += buffers.triangleCount * set.transforms.count
                stats.drawCalls += 1
                stats.meshBytes += set.transforms.count * 64
            }
        } else {
            // Comparison path: merge every copy into per-group meshes.
            var groups: [String: (WorldMesh.MeshBuffers, Bool)] = [:]
            for set in scene.props {
                let buffers = propMesh(set.kind, set.variant)
                let foliage = Self.isFoliage(set.kind)
                let key = "\(set.group.x),\(set.group.y)/\(foliage)"
                var g = groups[key] ?? (WorldMesh.MeshBuffers(), foliage)
                for t in set.transforms { g.0.append(buffers, transform: t) }
                groups[key] = g
                stats.propInstances += set.transforms.count
            }
            for (key, g) in groups.sorted(by: { $0.key < $1.key }) {
                guard let mesh = try MeshUpload.resource([g.0]) else { continue }
                let e = Entity()
                e.name = "Merged props \(key)"
                e.components.set(ModelComponent(mesh: mesh, materials: [g.1 ? foliageMat : propMat]))
                receiveIBL(e)
                rootEntity.addChild(e)
                stats.propTriangles += g.0.triangleCount
                stats.drawCalls += 1
                stats.meshBytes += g.0.gpuBytes
            }
        }
        // Near-camera grass tufts are always instanced and rebuilt as the camera moves.
        if let (mesh, _) = try cached(.tuft, 0) { tuftMesh = mesh }
        stats.triangles = stats.staticTriangles + stats.propTriangles
    }

    private func instancedEntity(mesh: MeshResource, buffers: WorldMesh.MeshBuffers, transforms: [simd_float4x4], material: CustomMaterial) throws -> Entity {
        let data = try LowLevelInstanceData(instanceCount: transforms.count)
        data.withMutableTransforms { dst in for (i, t) in transforms.enumerated() { dst[i] = t } }
        let e = Entity()
        e.components.set(ModelComponent(mesh: mesh, materials: [material]))
        e.components.set(try MeshInstancesComponent(mesh: mesh, instances: data, bounds: Self.bounds(of: buffers, transforms)))
        receiveIBL(e)
        return e
    }

    static func bounds(of buffers: WorldMesh.MeshBuffers, _ transforms: [simd_float4x4]) -> BoundingBox? {
        guard let b = buffers.bounds, !transforms.isEmpty else { return nil }
        var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
        for t in transforms {
            let s = simd_length(SIMD3(t.columns.0.x, t.columns.0.y, t.columns.0.z))
            let c = SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            let r = simd_max(simd_abs(b.min), simd_abs(b.max)) * s
            lo = simd_min(lo, c - r); hi = simd_max(hi, c + r)
        }
        return BoundingBox(min: lo, max: hi)
    }

    private func updateClutter(around p: LocalPoint) {
        if options.diagnostics.contains("noClutter") || options.diagnostics.contains("noProps") { return }
        if let c = clutter, simd_distance(c.center, p) < 6 { return }
        let transforms = scene.clutter.tufts(near: p, radius: Self.clutterRadius)
        guard let mesh = tuftMesh, !transforms.isEmpty else { return }
        do {
            if let c = clutter, c.data.instanceCapacity >= transforms.count {
                c.data.instanceCount = transforms.count
                c.data.replaceMutableTransforms { dst in for (i, t) in transforms.enumerated() { dst[i] = t } }
                c.entity.components.set(try MeshInstancesComponent(mesh: mesh, instances: c.data,
                                                                    bounds: Self.bounds(of: propMesh(.tuft, 0), transforms)))
                clutter = (c.entity, c.data, p)
            } else {
                clutter?.entity.removeFromParent()
                let data = try LowLevelInstanceData(instanceCount: transforms.count, instanceCapacity: max(transforms.count * 2, 512))
                data.withMutableTransforms { dst in for (i, t) in transforms.enumerated() { dst[i] = t } }
                let e = Entity()
                e.name = "Clutter tufts"
                e.components.set(ModelComponent(mesh: mesh, materials: [resources.foliageMaterial]))
                e.components.set(try MeshInstancesComponent(mesh: mesh, instances: data))
                receiveIBL(e)
                rootEntity.addChild(e)
                clutter = (e, data, p)
            }
            stats.clutterInstances = transforms.count
        } catch {
            // Clutter is decoration; skip on failure.
        }
    }

    // MARK: - Camera collision

    public static let occluderGroup = CollisionGroup(rawValue: 1 << 20)

    private func buildOccluders() {
        let e = Entity()
        e.name = "Occluders"
        var shapes: [ShapeResource] = []
        for o in scene.occluders where o.hull.count >= 3 {
            let pts = o.hull.flatMap { [LocalFrame.scenePosition($0, y: 0), LocalFrame.scenePosition($0, y: o.height)] }
            shapes.append(ShapeResource.generateConvex(from: pts))
        }
        e.components.set(CollisionComponent(shapes: shapes, isStatic: true,
                                            filter: CollisionFilter(group: Self.occluderGroup, mask: .all)))
        rootEntity.addChild(e)
    }
}

/// Moves an entity along a route at a speed, facing the direction of travel.
@MainActor
public final class WorldMotion {
    public let entity: Entity
    let route: [LocalPoint]
    let cumulative: [Double]
    public var speed: Double
    public var loop: Bool
    public var isPaused = false
    /// Meters traveled along the route.
    public var distance: Double = 0
    public var length: Double { cumulative.last ?? 0 }
    private var heading: Float?

    init(entity: Entity, route: [LocalPoint], speed: Double, loop: Bool) {
        self.entity = entity
        var r = route
        if loop, let f = route.first, let l = route.last, simd_distance(f, l) > 0.01 { r.append(f) }
        self.route = r
        var c: [Double] = [0]
        for (a, b) in zip(r, r.dropFirst()) { c.append(c.last! + simd_distance(a, b)) }
        cumulative = c
        self.speed = speed
        self.loop = loop
    }

    /// Jumps to a point `meters` along the route.
    public func seek(to meters: Double) {
        distance = meters
        heading = nil
        apply()
    }

    func advance(_ dt: Double) {
        guard !isPaused, length > 0 else { return }
        distance += speed * dt
        if loop { distance = distance.truncatingRemainder(dividingBy: length) } else { distance = min(distance, length) }
        apply()
    }

    /// Current position and direction of travel (local meters).
    public var state: (position: LocalPoint, direction: LocalPoint) {
        guard route.count >= 2 else { return (route.first ?? .zero, LocalPoint(0, 1)) }
        let d = max(0, min(distance, length))
        var i = 0
        while i < cumulative.count - 2, cumulative[i + 1] < d { i += 1 }
        let a = route[i], b = route[i + 1]
        let seg = cumulative[i + 1] - cumulative[i]
        let t = seg > 0 ? (d - cumulative[i]) / seg : 0
        let dir = seg > 0 ? (b - a) / seg : LocalPoint(0, 1)
        return (a + (b - a) * t, dir)
    }

    func apply() {
        let (p, dir) = state
        entity.position = LocalFrame.scenePosition(p, y: GroundLayer.sidewalk)
        // Heading: rotate +Z (entity front) to the travel direction; ease turns.
        let target = atan2(Float(dir.x), Float(-dir.y))
        if let h = heading {
            var delta = target - h
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            heading = h + delta * 0.15
        } else {
            heading = target
        }
        entity.orientation = simd_quatf(angle: heading!, axis: [0, 1, 0])
    }

    /// The direction the entity faces, in scene space.
    public var facing: SIMD3<Float> {
        let h = heading ?? 0
        return SIMD3(sin(h), 0, cos(h))
    }
}
