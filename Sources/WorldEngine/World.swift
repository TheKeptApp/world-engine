import CoreGraphics
import Foundation
import Metal
import RealityKit
import WorldEnvironment
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
    /// The moment that sets the sun, light keys and season.
    public var date: Date
    /// Force a season (0 spring … 3 winter); nil = from the date and the profile.
    public var season: Int?
    /// Performance experiments: "noShadows", "noProps", "noClutter", "noPost".
    public var diagnostics: Set<String> = []

    public init(focus: GeoBoundingBox? = nil, profileID: String? = nil, date: Date = Date(), season: Int? = nil,
                diagnostics: Set<String> = []) {
        self.focus = focus
        self.profileID = profileID
        self.date = date
        self.season = season
        self.diagnostics = diagnostics
    }
}

/// Counts for performance reports.
public struct WorldStats: Sendable {
    /// Triangles submitted per frame right now (static + current tree detail levels + props + tufts).
    public var triangles = 0
    /// Draw calls if everything were visible (mesh parts across entities).
    public var drawCalls = 0
    public var staticTriangles = 0
    public var propTriangles = 0
    public var treeTriangles = 0
    public var propInstances = 0
    public var clutterInstances = 0
    /// Triangles submitted for the current view (entities whose bounds meet the camera frustum).
    public var viewTriangles = 0
    /// Draw calls for the current view (same test), refreshed twice a second.
    public var viewDrawCalls = 0
    /// GPU bytes of world vertex/index data plus instance transforms.
    public var meshBytes = 0
    public var chunkCount = 0
    public var buildSeconds = 0.0
    public var profileID = ""
    public var season = 1
    public var lightKeys = ""
    public var generated: [String: Int] = [:]
    /// Context ring (look-fix-v1 §4), 0 until it has loaded in the background: triangles of the
    /// cell levels in use plus the ring's water, its cells, and seconds spent parsing the context
    /// layer and generating the ring (off the main thread).
    public var contextTriangles = 0
    public var contextCells = 0
    public var contextParseSeconds = 0.0
    public var contextGenerateSeconds = 0.0
}

/// A built world: entities plus the engine-side state that animates it.
@MainActor
public final class World {
    public let rootEntity = Entity()
    public let frame: LocalFrame
    public let manifest: AreaManifest
    public let lighting: LightingState
    /// No-character experience defaults (composed postcards, aerial fit, motion bounds).
    public let experience: ExperienceDefaults?
    public internal(set) var stats = WorldStats()
    public var shaderGlobals = ShaderGlobals()

    /// Mutable only for the palette: the context ring's buildings may add colours (`attachContext`).
    var scene: GeneratedScene
    let features: MapFeatures
    let resources: RenderResources
    let options: WorldOptions
    var skyEnvironment: EnvironmentResource?
    let iblEntity = Entity()
    /// Runtime environment (time, weather, sky, season): see Environment.swift.
    let sunEntity = Entity()
    var skyDome: Entity?
    var starField: (entity: Entity, data: LowLevelInstanceData)?
    var precipitation: Entity?
    var environment: EnvironmentDocument?
    var environmentState = EnvironmentRuntime()
    var motions: [WorldMotion] = []
    /// The per-frame update subscription (owned here so it can't be released early).
    var frameSubscription: EventSubscription?
    /// The entity whose ground footprint gets the contact shadow (usually the followed character).
    public weak var contactEntity: Entity?

    /// The context ring's entities and level state (World+Context.swift).
    var context = ContextRuntime()
    private var tuftEntity: (entity: Entity, data: LowLevelInstanceData, center: LocalPoint)?
    private var tuftMesh: MeshResource?
    /// LOD props (trees, bushes) per kind/variant/cell, with one entity per slot: 0 = near detail
    /// inside the cut-away zone (cuttable), 1 = the rest of the near detail, 2 = mid, 3 = far,
    /// 4 = skyline (1–4 opaque; see `RenderResources.foliageOpaqueMaterial`).
    private struct LODGroup {
        var kind: PropKind
        var variant: Int
        var instances: [PropInstance]
        var levels: [(entity: Entity, data: LowLevelInstanceData, triangles: Int, buffers: WorldMesh.MeshBuffers)]
        var counts = [0, 0, 0, 0, 0]
        var bounds: [BoundingBox?] = [nil, nil, nil, nil, nil]
    }
    /// Buildings of one cell, one entity per distance LOD (P2's `BuildingLOD`); one is enabled.
    private struct BuildingCellState {
        var rect: Rect2D
        var bounds: BoundingBox?
        var levels: [(lod: BuildingLOD, entity: Entity, triangles: Int)]
        var active: Int?
    }
    private var buildingCells: [BuildingCellState] = []
    /// Triangles of the enabled building LODs.
    private var buildingTriangles = 0
    /// Trees and bushes this close to the camera keep the cut-away (transparent) material. The
    /// character is at most ~8 m from the follow camera and detail is re-bucketed every 8 m, so a
    /// blocker always falls inside.
    static let cutZoneMeters: Float = 20
    private var lodGroups: [LODGroup] = []
    var lodCenter: SIMD3<Float>?
    /// Fixed geometry for the view-triangle estimate: chunk and static-prop bounds.
    private var cullables: [(bounds: BoundingBox, triangles: Int, draws: Int)] = []
    private var tuftBounds: BoundingBox?
    private var viewClock = 0.0
    private var staticPropTriangles = 0
    /// Lamps and benches (fixed detail) and the fixed draw calls (chunks, boundary, single-LOD props).
    private var staticPropBase = 0
    private var baseDrawCalls = 0

    /// Loads an area directory (manifest + OSM data) and builds the world.
    public static func load(areaDirectory: URL, options: WorldOptions = .init()) async throws -> World {
        let start = Date()
        let recipe = WorldRecipe(profileID: options.profileID, date: options.date, season: options.season, focus: options.focus,
                                 buildingLODs: true)
        let build = try await Task.detached(priority: .userInitiated) {
            try WorldBuild.generate(areaDirectory: areaDirectory, recipe: recipe)
        }.value
        let generated = (build.manifest, build.scene, build.features, build.lighting, build.experience)
        let world = try World(manifest: generated.0, scene: generated.1, features: generated.2, lighting: generated.3,
                              experience: generated.4, options: options)
        world.stats.buildSeconds = Date().timeIntervalSince(start)
        // The context ring builds in the background and appears when ready (World+Context.swift).
        world.startContext(areaDirectory: areaDirectory)
        return world
    }

    init(manifest: AreaManifest, scene: GeneratedScene, features: MapFeatures, lighting: LightingState, experience: ExperienceDefaults?,
         options: WorldOptions) throws {
        self.manifest = manifest
        self.experience = experience
        self.scene = scene
        self.features = features
        self.lighting = lighting
        self.options = options
        frame = manifest.frame
        resources = try RenderResources(palette: scene.palette)

        let pixels = SkyImage.render(lighting, convention: .realityKit)
        skyEnvironment = Self.cgImage(pixels, width: 1024, height: 512).flatMap { try? EnvironmentResource(equirectangular: $0) }

        // Shader globals from the resolved light state.
        shaderGlobals.fogColor = WorldGen.Color.linear(lighting.fog)
        shaderGlobals.fogStart = lighting.fogStart
        shaderGlobals.fogEnd = lighting.fogEnd
        shaderGlobals.fillSky = WorldGen.Color.linear(lighting.ambientSky) * lighting.fillSky * Self.fillScale * lighting.exposure
        shaderGlobals.fillGround = WorldGen.Color.linear(lighting.ambientGround) * lighting.fillGround * Self.fillScale * lighting.exposure
        shaderGlobals.litFraction = lighting.litWindows
        shaderGlobals.litWindow = Palette.parse(lighting.sunElevation < -6 ? "#DCA967" : "#E9BE7C")

        rootEntity.name = "World"
        buildLights()
        buildCanopyMap()
        try buildChunks()
        try buildBuildingCells()
        try buildProps()
        buildOccluders()
        stats.profileID = scene.profile.id
        stats.season = scene.season
        stats.lightKeys = "\(lighting.keyA)→\(lighting.keyB) \(String(format: "%.2f", lighting.blend)), sun \(String(format: "%.1f° az %.1f°", lighting.sunElevation, lighting.sunAzimuth))"
        stats.generated = scene.stats
        stats.chunkCount = scene.chunks.count
        resources.update(globals: shaderGlobals)
    }

    /// Direct-light scale: normalized sun intensity 1 (noon) → this many lux in RealityKit.
    static let sunLux: Float = 14000
    /// Fill scale: emissive units per normalized fill (tuned so shade faces keep ~35–45% of sun).
    static let fillScale: Float = 2.4

    static func cgImage(_ rgba: [UInt8], width: Int, height: Int) -> CGImage? {
        let data = Data(rgba) as CFData
        guard let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
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

    /// Host entities in the world right now (characters, props): zero, one or many. The engine
    /// treats them as plain entities; the first is the default contact-shadow target.
    public private(set) var characters: [Entity] = []

    /// Adds an app-provided entity at a lat/lon, standing on the ground (its origin = its feet).
    public func place(_ entity: Entity, at c: GeoCoordinate, heading: Float? = nil) {
        if entity.parent !== rootEntity { adopt(entity) }
        entity.position = position(of: c)
        if let heading { entity.orientation = simd_quatf(angle: -heading, axis: [0, 1, 0]) }
    }

    /// Adds a host entity to the world and lets its models receive the world's sky light.
    private func adopt(_ entity: Entity) {
        rootEntity.addChild(entity)
        if !characters.contains(where: { $0 === entity }) { characters.append(entity) }
        if contactEntity == nil { contactEntity = entity }
        func visit(_ e: Entity) {
            if e.components.has(ModelComponent.self) { receiveIBL(e) }
            for c in e.children { visit(c) }
        }
        visit(entity)
    }

    /// Walkable ground for free exploring (built on first use).
    public lazy var walkMap = WalkMap(features: features, scene: scene)

    /// Whether any entity is walking a route right now.
    var hasActiveMotion: Bool { motions.contains { !$0.isPaused && $0.speed != 0 } }

    /// Removes an entity the app placed (and stops its motion).
    public func remove(_ entity: Entity) {
        motions.removeAll { $0.entity === entity }
        characters.removeAll { $0 === entity }
        if contactEntity === entity { contactEntity = characters.first }
        entity.removeFromParent()
    }

    /// Walks an entity along a route at `speed` m/s, facing the direction of travel.
    @discardableResult
    public func move(_ entity: Entity, along route: [GeoCoordinate], speed: Double, loop: Bool = true) -> WorldMotion {
        if entity.parent !== rootEntity { adopt(entity) }
        motions.removeAll { $0.entity === entity }
        let m = WorldMotion(entity: entity, route: route.map(frame.localPoint(of:)), speed: speed, loop: loop)
        motions.append(m)
        m.apply()
        return m
    }

    /// Per-frame update: motions, tree detail levels, near-camera clutter, shader globals.
    func update(deltaTime dt: Double, camera: Entity, focusPoint: SIMD3<Float>?, cutAwayTarget: SIMD3<Float>?) {
        for m in motions { m.advance(dt) }
        let camPos = camera.position(relativeTo: nil)
        updateLODs(camera: camPos)
        if let p = focusPoint { updateClutter(around: LocalPoint(Double(p.x), Double(-p.z)), camera: camPos) }
        var g = shaderGlobals
        g.camera = camPos
        // v2 §3.3 aerial distance policy (shared with the web renderer).
        (g.fogStart, g.fogEnd) = FogPolicy.distances(start: shaderGlobals.fogStart, end: shaderGlobals.fogEnd, cameraHeight: camPos.y)
        g.characterRel = cutAwayTarget.map { $0 - camPos }
        if let e = contactEntity {
            let b = e.visualBounds(relativeTo: e)
            g.contactRel = e.position(relativeTo: nil) + SIMD3(0, 0.0, 0) - camPos
            g.contactHalf = SIMD2(max(b.extents.x, 0.2) * 0.575, max(b.extents.z, 0.2) * 0.575)
            let fwd = e.convert(direction: [0, 0, 1], to: nil)
            g.contactHeading = atan2(fwd.x, fwd.z)
        } else {
            g.contactRel = nil
        }
        let m = camera.transformMatrix(relativeTo: nil)
        followCamera(camPos, forward: -SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z), dt: dt)
        resources.update(globals: g)
        viewClock += dt
        if viewClock >= 0.5 {
            viewClock = 0
            (stats.viewTriangles, stats.viewDrawCalls) = estimateView(camera: camera)
        }
    }

    // MARK: - Building

    private func buildLights() {
        sunEntity.name = "Sun"
        let c = WorldGen.Color.srgb(simd_normalize(lighting.sunColor + 1e-6) * min(1, simd_length(lighting.sunColor) > 0 ? 1 : 0))
        var light = DirectionalLightComponent(color: .init(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: 1),
                                              intensity: lighting.sunIntensity * lighting.exposure * Self.sunLux)
        light.isRealWorldProxy = false
        sunEntity.components.set(light)
        if !options.diagnostics.contains("noShadows"), lighting.sunIntensity > 0.01 {
            var shadow = DirectionalLightComponent.Shadow()
            shadow.shadowProjection = .automatic(maximumDistance: shadowDistance)
            shadow.depthBias = 1.5
            sunEntity.components.set(shadow)
        }
        let dir = lighting.sunDirection
        sunEntity.look(at: .zero, from: dir.y > 0.02 ? dir * 100 : [dir.x * 100, 2, dir.z * 100], relativeTo: nil)
        rootEntity.addChild(sunEntity)

        // IBL only for speculars and a touch of sky color; diffuse fill comes from the shader (R8).
        if let env = skyEnvironment {
            iblEntity.components.set(ImageBasedLightComponent(source: .single(env), intensityExponent: -1.2 + log2(lighting.exposure)))
        }
        rootEntity.addChild(iblEntity)
    }

    func receiveIBL(_ e: Entity) {
        e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: iblEntity))
    }

    private func buildChunks() throws {
        // Soft world boundary: a plain ground under and around the area (v2 §3.3), fogged with
        // distance like everything else.
        // The plain beyond the data reads as a neutral distant land, not as lawn (from the aerial a
        // bright green field dominated the frame): the lighting bible's coverage backdrop, #A9B4A0
        // in summer and #BDC8D4 in winter (look-fix-v1 §4; a seasonal palette slot). A real
        // context ring (P1) replaces it where data exists.
        var boundary = scene.boundaryGround
        boundary.repaint(from: 0, Paint(slot: scene.palette.named("backdrop")))
        if let ground = try MeshUpload.resource([boundary]) {
            let e = Entity()
            e.name = "Boundary ground"
            e.components.set(ModelComponent(mesh: ground, materials: [resources.staticMaterial]))
            e.components.set(DynamicLightShadowComponent(castsShadow: false))
            receiveIBL(e)
            rootEntity.addChild(e)
            stats.staticTriangles += scene.boundaryGround.triangleCount
            baseDrawCalls += 1
        }
        for chunk in scene.chunks {
            // Flat ground (lawns, streets, paths, curbs, water) can't shadow anything, so it stays
            // out of the sun's shadow map; buildings and other raised geometry cast.
            let (flat, raised) = Self.splitFlatGround(chunk.staticMesh)
            for (suffix, staticPart, casts) in [("ground", flat, false), ("", raised, true)] {
                var parts: [WorldMesh.MeshBuffers] = [], materials: [any Material] = []
                if !staticPart.isEmpty { parts.append(staticPart); materials.append(resources.staticMaterial) }
                if !casts, !chunk.waterMesh.isEmpty { parts.append(chunk.waterMesh); materials.append(resources.waterMaterial) }
                guard let mesh = try MeshUpload.resource(parts) else { continue }
                let e = Entity()
                e.name = suffix.isEmpty ? "Chunk \(chunk.id)" : "Chunk \(chunk.id) \(suffix)"
                e.components.set(ModelComponent(mesh: mesh, materials: materials))
                if !casts { e.components.set(DynamicLightShadowComponent(castsShadow: false)) }
                receiveIBL(e)
                rootEntity.addChild(e)
                stats.staticTriangles += parts.reduce(0) { $0 + $1.triangleCount }
                if let b = parts.compactMap(\.bounds).reduce(nil, { (acc: BoundingBox?, x) in acc.map { $0.union(BoundingBox(min: x.min, max: x.max)) } ?? BoundingBox(min: x.min, max: x.max) }) {
                    cullables.append((b, parts.reduce(0) { $0 + $1.triangleCount }, parts.count))
                }
                baseDrawCalls += parts.count
                stats.meshBytes += parts.reduce(0) { $0 + $1.gpuBytes }
            }
        }
    }

    /// Building cells: one entity per distance LOD (near, mid, far, skyline), all disabled until
    /// `updateLODs` picks one per cell by camera distance.
    private func buildBuildingCells() throws {
        for cell in scene.buildingCells {
            var state = BuildingCellState(rect: cell.rect, bounds: nil, levels: [], active: nil)
            for lod in BuildingLOD.allCases {
                guard let m = cell.meshes[lod], !m.isEmpty, let mesh = try MeshUpload.resource([m]) else { continue }
                let e = Entity()
                e.name = "Buildings \(cell.id) \(lod)"
                e.isEnabled = false
                e.components.set(ModelComponent(mesh: mesh, materials: [resources.staticMaterial]))
                receiveIBL(e)
                rootEntity.addChild(e)
                state.levels.append((lod, e, m.triangleCount))
                if let b = m.bounds {
                    let box = BoundingBox(min: b.min, max: b.max)
                    state.bounds = state.bounds.map { $0.union(box) } ?? box
                }
                stats.meshBytes += m.gpuBytes
            }
            if !state.levels.isEmpty { buildingCells.append(state) }
        }
    }

    /// Diagnostics: hide or show every building cell (its current LOD comes back).
    func setBuildingsVisible(_ on: Bool) {
        for cell in buildingCells {
            for (j, l) in cell.levels.enumerated() { l.entity.isEnabled = on && j == cell.active }
        }
    }

    /// Enables one LOD per building cell: `BuildingLOD.forDistance` of the camera's distance to the
    /// cell, or the nearest coarser level the cell has (context cells have far and skyline only).
    private func updateBuildingLODs(camera c: SIMD2<Float>) {
        var tris = 0
        let p = LocalPoint(Double(c.x), Double(-c.y))
        for i in buildingCells.indices {
            let r = buildingCells[i].rect
            let q = LocalPoint(min(max(p.x, r.min.x), r.max.x), min(max(p.y, r.min.y), r.max.y))
            let want = BuildingLOD.forDistance(simd_distance(p, q))
            let levels = buildingCells[i].levels
            let pick = levels.firstIndex { $0.lod >= want } ?? (levels.count - 1)
            if buildingCells[i].active != pick {
                for (j, l) in levels.enumerated() { l.entity.isEnabled = j == pick }
                buildingCells[i].active = pick
            }
            tris += levels[pick].triangles
        }
        buildingTriangles = tris
    }

    /// Splits static geometry into flat ground (every corner within 0.3 m of the ground plane:
    /// lawns, streets, paths, curbs) and the rest. The ground is flat at y = 0 today; with terrain
    /// this must compare against the ground height instead.
    static func splitFlatGround(_ m: WorldMesh.MeshBuffers) -> (flat: WorldMesh.MeshBuffers, raised: WorldMesh.MeshBuffers) {
        m.partitioned { $0.y < 0.3 && $1.y < 0.3 && $2.y < 0.3 }
    }

    private var meshCache: [String: (MeshResource, WorldMesh.MeshBuffers)] = [:]
    private func cached(_ k: PropKind, _ v: Int, lod: Int = 0) throws -> (MeshResource, WorldMesh.MeshBuffers)? {
        let key = "\(k.rawValue)/\(v)/\(lod)"
        if let c = meshCache[key] { return c }
        let buffers = PropLibrary.mesh(k, variant: v, lod: lod, palette: scene.palette)
        guard let r = try MeshUpload.resource([buffers]) else { return nil }
        meshCache[key] = (r, buffers)
        stats.meshBytes += buffers.gpuBytes
        return (r, buffers)
    }

    private func material(for k: PropKind, cuttable: Bool = true) -> CustomMaterial {
        if cuttable || !opaqueDetail { return k.isFoliage ? resources.foliageMaterial : resources.propMaterial }
        return k.isFoliage ? resources.foliageOpaqueMaterial : resources.propOpaqueMaterial
    }

    /// Rain and snow particles allowed (`World.Feature.particles`; diagnostics only).
    var particlesAllowed = true

    /// Mean display brightness the post-process auto exposure aims for (set by `apply`).
    public internal(set) var exposureTarget: Float = 0.54
    /// Post-process saturation multiplier for the current light and weather (set by `apply`).
    public internal(set) var gradeSaturation: Float = 1
    /// The lighting bible (generated from look-fix-v1) and its per-state grade with our tuning.
    static let lightingBible = try? StyleLibrary.lightingBible()
    static let gradeTable = try? StyleLibrary.grade()

    /// Runtime multipliers on the resolved light and grade, for tuning the look on a device
    /// (WorldLab `-tune`). Identity by default: the shipped look lives in the profiles.
    public struct LookTuning: Sendable, Equatable {
        /// Sun (key) light.
        public var key: Float = 1
        /// R8 fill, sky and ground together; `groundFill` scales the ground bounce on top.
        public var fill: Float = 1
        public var groundFill: Float = 1
        /// Image-based (sky) light, in EV.
        public var iblEV: Float = 0
        /// Added to the auto-exposure target (display brightness, 0–1).
        public var exposureTarget: Float = 0
        /// Post-process saturation and contrast multipliers.
        public var saturation: Float = 1
        public var contrast: Float = 1
        public init() {}
    }

    /// See `LookTuning`. Setting it re-applies the current environment.
    public var lookTuning = LookTuning() {
        didSet {
            guard lookTuning != oldValue, let e = environment else { return }
            environmentState.lastIBL = nil
            apply(e)
        }
    }

    /// How far from the camera the sun casts shadows (m). 60 m: the lighting bible keeps 60–80 m of
    /// local coverage (look-fix-v1 §2.3), and the owner's decision 2 shortens the range first when
    /// the phone's GPU time is above 8 ms (street view ~9.1 ms at full clock). The shadow map's
    /// texels then cover 25% less ground, which also sharpens the jagged wall-base shadows.
    /// GPU attribution measures other ranges with `setShadowDistance(_:)`.
    var shadowDistance: Float = 60

    /// Opaque materials for trees and bushes outside the cut-away zone (on by default; switched off
    /// only to measure what it saves, `World.Feature.opaqueDetail`).
    var opaqueDetail = true {
        didSet {
            guard opaqueDetail != oldValue else { return }
            for g in lodGroups {
                for (slot, level) in g.levels.enumerated() {
                    level.entity.components[ModelComponent.self]?.materials = [material(for: g.kind, cuttable: slot == 0)]
                }
            }
        }
    }

    private func buildProps() throws {
        if options.diagnostics.contains("noProps") { recount(); return }
        // Props are instanced per kind/variant per 400 m cell so off-screen cells are culled.
        var groups: [String: [PropInstance]] = [:]
        for inst in scene.instances {
            let c = PropLibrary.cell(x: inst.x, y: inst.y)
            groups["\(inst.kind.rawValue)/\(inst.variant)/\(c.x),\(c.y)", default: []].append(inst)
        }
        for key in groups.keys.sorted() {
            let list = groups[key]!
            let kind = list[0].kind, variant = list[0].variant
            stats.propInstances += list.count
            if PropLibrary.lodCount(kind) == 1 {
                // Lamps, benches: one detail level.
                guard let (mesh, buffers) = try cached(kind, variant) else { continue }
                let e = try instancedEntity(mesh: mesh, buffers: buffers, transforms: list.map(\.transform), material: material(for: kind))
                e.name = "Props \(key)"
                rootEntity.addChild(e)
                staticPropBase += buffers.triangleCount * list.count
                if let b = Self.bounds(of: buffers, list.map(\.transform)) { cullables.append((b, buffers.triangleCount * list.count, 1)) }
                baseDrawCalls += 1
                stats.meshBytes += list.count * 64
                continue
            }
            // Trees, bushes: one entity per slot (cut-away zone, near, mid, far, skyline), refilled
            // as the camera moves.
            var group = LODGroup(kind: kind, variant: variant, instances: list, levels: [])
            let slots = PropLibrary.lodCount(kind) + 1
            for slot in 0..<slots {
                guard let (mesh, buffers) = try cached(kind, variant, lod: max(0, slot - 1)) else { continue }
                let data = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: list.count)
                let e = Entity()
                e.name = "LOD \(key) \(slot)"
                e.isEnabled = false
                e.components.set(ModelComponent(mesh: mesh, materials: [material(for: kind, cuttable: slot == 0)]))
                receiveIBL(e)
                rootEntity.addChild(e)
                group.levels.append((e, data, buffers.triangleCount, buffers))
            }
            guard group.levels.count == slots else { continue }
            lodGroups.append(group)
            stats.meshBytes += list.count * 64 * slots
        }
        if let (mesh, _) = try cached(.tuft, 0) { tuftMesh = mesh }
        staticPropTriangles = staticPropBase
        recount()
    }

    func recount() {
        stats.propTriangles = staticPropTriangles
        stats.triangles = stats.staticTriangles + buildingTriangles + staticPropTriangles + stats.treeTriangles + stats.clutterInstances * 17
        // Draw calls: chunks + static props (counted at build) + building cells + enabled LOD entities + tufts.
        stats.drawCalls = baseDrawCalls + buildingCells.count + lodGroups.reduce(0) { $0 + $1.counts.filter { $0 > 0 }.count }
            + (stats.clutterInstances > 0 ? 1 : 0) + contextDrawCalls
        stats.triangles += stats.contextTriangles
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
            // Largest axis scale: trees carry a per-tree crown stretch on x and z.
            let s = max(simd_length(SIMD3(t.columns.0.x, t.columns.0.y, t.columns.0.z)),
                        simd_length(SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z)),
                        simd_length(SIMD3(t.columns.2.x, t.columns.2.y, t.columns.2.z)))
            let c = SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
            let r = simd_max(simd_abs(b.min), simd_abs(b.max)) * s
            lo = simd_min(lo, c - r); hi = simd_max(hi, c + r)
        }
        return BoundingBox(min: lo, max: hi)
    }

    /// Re-buckets trees and bushes into near/mid/far/skyline detail when the camera has moved more
    /// than 8 m. Distance is from the eye (3D), so from the aerial camera every tree is far away.
    private func updateLODs(camera: SIMD3<Float>) {
        if let last = lodCenter, simd_distance(last, camera) < Float(PropLibrary.lodRebucketMeters) { return }
        lodCenter = camera
        updateBuildingLODs(camera: SIMD2(camera.x, camera.z))
        updateContextLODs(camera: camera)
        let cut = Self.cutZoneMeters
        let edges = PropLibrary.lodDistances.map(Float.init)  // near→mid, mid→far, far→skyline
        var trees = 0, others = 0
        for gi in lodGroups.indices {
            let slots = lodGroups[gi].levels.count
            var buckets = [[simd_float4x4]](repeating: [], count: slots)
            for inst in lodGroups[gi].instances {
                let d = simd_distance(SIMD3(Float(inst.x), Float(inst.height), Float(-inst.y)), camera)
                var slot = d < cut ? 0 : 1
                if slot == 1 { for e in edges where d >= e { slot += 1 } }
                buckets[min(slot, slots - 1)].append(inst.transform)
            }
            for lod in 0..<slots {
                let (entity, data, tris, buffers) = lodGroups[gi].levels[lod]
                let ts = buckets[lod]
                data.instanceCount = ts.count
                lodGroups[gi].counts[lod] = ts.count
                lodGroups[gi].bounds[lod] = Self.bounds(of: buffers, ts)
                if ts.isEmpty {
                    entity.isEnabled = false
                } else {
                    data.replaceMutableTransforms { dst in for (i, t) in ts.enumerated() { dst[i] = t } }
                    entity.isEnabled = true
                    if let mesh = entity.components[ModelComponent.self]?.mesh,
                       let comp = try? MeshInstancesComponent(mesh: mesh, instances: data, bounds: lodGroups[gi].bounds[lod]) {
                        entity.components.set(comp)
                    }
                }
                if lodGroups[gi].kind.isTree { trees += ts.count * tris } else { others += ts.count * tris }
            }
        }
        stats.treeTriangles = trees
        staticPropTriangles = staticPropBase + others
        recount()
    }

    /// Triangles and draw calls in entities whose bounds meet the camera frustum (what the GPU is
    /// asked to draw; the sky dome, stars, rain and characters are not counted).
    private func estimateView(camera: Entity) -> (triangles: Int, drawCalls: Int) {
        let fov = (camera.components[PerspectiveCameraComponent.self]?.fieldOfViewInDegrees ?? 50) * .pi / 180
        let planes = Self.frustumPlanes(view: camera.transformMatrix(relativeTo: nil).inverse, fovY: fov, aspect: viewAspect, near: 0.1, far: 5000)
        var total = 0, draws = 0
        for c in cullables where Self.intersects(c.bounds, planes) { total += c.triangles; draws += c.draws }
        for cell in buildingCells {
            if let b = cell.bounds, let a = cell.active, Self.intersects(b, planes) { total += cell.levels[a].triangles; draws += 1 }
        }
        for g in lodGroups {
            for lod in g.levels.indices where g.counts[lod] > 0 {
                if let b = g.bounds[lod], Self.intersects(b, planes) { total += g.counts[lod] * g.levels[lod].triangles; draws += 1 }
            }
        }
        if let b = tuftBounds, Self.intersects(b, planes) { total += stats.clutterInstances * 17; draws += 1 }
        let ring = contextView(planes)
        return (total + ring.triangles, draws + ring.drawCalls)
    }

    /// Width / height of the view, for the triangle estimate (set by WorldView).
    var viewAspect: Float = 9.0 / 19.5

    static func frustumPlanes(view: simd_float4x4, fovY: Float, aspect: Float, near: Float, far: Float) -> [SIMD4<Float>] {
        let y = 1 / tan(fovY / 2), x = y / aspect
        let proj = simd_float4x4(columns: (SIMD4(x, 0, 0, 0), SIMD4(0, y, 0, 0),
                                           SIMD4(0, 0, (far + near) / (near - far), -1), SIMD4(0, 0, 2 * far * near / (near - far), 0)))
        let m = proj * view
        func row(_ i: Int) -> SIMD4<Float> { SIMD4(m.columns.0[i], m.columns.1[i], m.columns.2[i], m.columns.3[i]) }
        let r0 = row(0), r1 = row(1), r2 = row(2), r3 = row(3)
        return [r3 + r0, r3 - r0, r3 + r1, r3 - r1, r3 + r2, r3 - r2]
    }

    static func intersects(_ b: BoundingBox, _ planes: [SIMD4<Float>]) -> Bool {
        for p in planes {
            let v = SIMD3(p.x > 0 ? b.max.x : b.min.x, p.y > 0 ? b.max.y : b.min.y, p.z > 0 ? b.max.z : b.min.z)
            if p.x * v.x + p.y * v.y + p.z * v.z + p.w < 0 { return false }
        }
        return true
    }

    /// R3 edge tufts near the camera (≤200), shrinking away between 20 and 30 m.
    private func updateClutter(around p: LocalPoint, camera: SIMD3<Float>) {
        if options.diagnostics.contains("noClutter") || options.diagnostics.contains("noProps") { return }
        if let c = tuftEntity, simd_distance(c.center, p) < 3 { return }
        let cam = LocalPoint(Double(camera.x), Double(-camera.z))
        let placements = scene.clutter.tuftPlacements(near: p)
        let transforms: [simd_float4x4] = placements.compactMap { q in
            let d = simd_distance(LocalPoint(q.x, q.y), cam)
            let fade = Float(1 - smoothstepD(20, 30, d))
            guard fade > 0.02 else { return nil }
            return simd_float4x4(translation: LocalFrame.scenePosition(LocalPoint(q.x, q.y), y: 0), yaw: Float(q.z), scale: Float(q.w) * fade)
        }
        guard let mesh = tuftMesh else { return }
        do {
            if tuftEntity == nil {
                let data = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: ClutterField.maxClusters)
                let e = Entity()
                e.name = "Clutter tufts"
                e.isEnabled = false
                e.components.set(ModelComponent(mesh: mesh, materials: [resources.foliageMaterial]))
                // Ankle-high tufts: their shadows don't read, but drawing them into the sun's
                // shadow map costs every frame.
                e.components.set(DynamicLightShadowComponent(castsShadow: false))
                receiveIBL(e)
                rootEntity.addChild(e)
                tuftEntity = (e, data, p)
            }
            guard let t = tuftEntity else { return }
            t.data.instanceCount = transforms.count
            if !transforms.isEmpty {
                t.data.replaceMutableTransforms { dst in for (i, m) in transforms.enumerated() { dst[i] = m } }
                tuftBounds = Self.bounds(of: PropLibrary.mesh(.tuft, variant: 0, palette: scene.palette), transforms)
                t.entity.components.set(try MeshInstancesComponent(mesh: mesh, instances: t.data, bounds: tuftBounds))
            }
            t.entity.isEnabled = !transforms.isEmpty
            tuftEntity = (t.entity, t.data, p)
            stats.clutterInstances = transforms.count
            recount()
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

func smoothstepD(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
    let t = min(1, max(0, (x - e0) / (e1 - e0)))
    return t * t * (3 - 2 * t)
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
