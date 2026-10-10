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
    /// Analytic sun shadow-pass cost in view (`World.shadowEstimate`), for logs.
    public var shadowSummary = ""
    /// GPU geometry bytes by kind (chunks, building LODs, building tiles, props), for memory attribution.
    public var meshBytesByKind: [String: Int] = [:]
    /// Draw calls for the current view (same test), refreshed twice a second.
    public var viewDrawCalls = 0
    /// `viewDrawCalls` and `viewTriangles` by category (same test, same refresh).
    public var viewDraws = ViewCost()
    public var viewTriangleSplit = ViewCost()
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

/// A per-category split of what the current view draws (draw calls or triangles): chunk ground and
/// raised static geometry (with water), building cells, trees and bushes, single-detail props,
/// the context ring, and the rest (boundary ground, tufts, sky dome, stars, precipitation).
public struct ViewCost: Sendable, Equatable {
    public var chunks = 0
    public var buildings = 0
    public var foliage = 0
    public var props = 0
    public var context = 0
    public var other = 0
    public init() {}
    public var total: Int { chunks + buildings + foliage + props + context + other }
    /// "chunks=… buildings=… foliage=… props=… context=… other=…" for log lines.
    public var summary: String {
        "chunks=\(chunks) buildings=\(buildings) foliage=\(foliage) props=\(props) context=\(context) other=\(other)"
    }
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
    public internal(set) var captureSceneState: CaptureSceneState = .notRequired
    private var tuftEntity: (entity: Entity, data: LowLevelInstanceData, center: LocalPoint)?
    private var tuftMesh: MeshResource?
    /// LOD props (trees, bushes) per kind/variant over the whole world, drawn by slot: 0 = near
    /// detail inside the cut-away zone (cuttable; used only while the view has a cut-away target,
    /// otherwise those instances join slot 1), 1 = the rest of the near detail, 2 = mid, 3 = far,
    /// 4 = skyline (1–4 opaque; see `RenderResources.foliageOpaqueMaterial`). Each slot draws into
    /// an instanced `LODBatch`; at far and skyline, variants of a non-tree kind whose meshes have
    /// the same triangle count share one batch (`fits` scales the shared mesh to the variant's
    /// bounds, keeping the instance origin, so per-instance colour and season hashes are unchanged).
    struct LODGroup {
        var kind: PropKind
        var variant: Int
        var instances: [PropInstance]
        /// Per instance: a bounding sphere (scene centre, radius) of its largest mesh.
        var spheres: [SIMD4<Float>] = []
        /// Batch index per slot, and the transform from the batch's mesh to this variant's.
        var batches: [Int]
        var fits: [simd_float4x4]
        /// Tree cells: each instance's cell and, per slot, the casting batch of each cell.
        var cellOf: [SIMD2<Int>] = []
        var cellBatches: [[SIMD2<Int>: Int]] = []
    }
    /// One instanced entity: a kind's mesh at one slot (one variant, or several sharing it).
    struct LODBatch {
        var kind: PropKind
        var slot: Int
        var entity: Entity
        var data: LowLevelInstanceData
        var triangles: Int
        var buffers: WorldMesh.MeshBuffers
        var count = 0
        var bounds: BoundingBox?
        /// Draws into the sun's shadow map (false for a shadow-cells twin).
        var casts = true
        /// Shadow cells: the twin batch that takes this batch's out-of-reach instances.
        var twin: Int?
    }
    private(set) var lodBatches: [LODBatch] = []
    /// Shadow cells (`-diag shadowCells`, default off; 5A Batch 2): only objects whose shadow can
    /// reach the shadow range draw into the shadow map. Lossless by construction: a caster whose
    /// shadow cannot meet the range sphere around the camera cannot shadow anything that is drawn.
    var shadowCells: Bool { options.diagnostics.contains("shadowCells") || options.diagnostics.contains("roam") }
    /// Raised chunk tiles (shadow cells: 200 m tiles), with their bounds, cast toggled by reach.
    private(set) var raisedTiles: [(entity: Entity, bounds: BoundingBox)] = []
    /// Range used by the last caster pass, to re-run it when the applied range changes.
    private var casterRange: Float = 0
    /// Simplified far parent (FarParent.swift); nil unless enabled.
    var farParent: FarParentState?
    /// Per-cell tree instancing (`-diag treeCells`, also part of `roam`; default off; 5A Batch 4):
    /// under shadow cells, a tree's casting instances draw from one batch per `treeCellMeters`
    /// cell instead of one over the whole world, so RealityKit culls them per cell from the view
    /// and from the shadow map. The same instances and transforms; non-casting twins stay whole.
    var treeCells: Bool { shadowCells && (options.diagnostics.contains("treeCells") || options.diagnostics.contains("roam")) }
    static let treeCellMeters = 200.0

    /// Whether a caster (bounds, top height) can shadow anything within the shadow range of the
    /// camera: its footprint swept away from the sun by its shadow length comes within the range
    /// plus the re-bucket distance and the foliage sway bound (0.03 m, `worldFoliageGeometry`).
    func shadowReaches(center: SIMD3<Float>, radius: Float, height: Float, camera: SIMD3<Float>) -> Bool {
        guard let cast = shadowCast else { return false }
        // RealityKit's automatic projection draws shadows well past `maximumDistance` from a raised
        // camera (measured: shadows on ground 150–210 m away from a 150 m-high camera with a 120 m
        // range), so the reach grows with the camera's height above ground.
        let range = (appliedShadowRange > 0 ? appliedShadowRange : shadowDistance) + 1.5 * max(camera.y, 0)
            + Float(PropLibrary.lodRebucketMeters) + 0.05
        let length = min(max(height, 0) * cast.z, 300)
        let a = SIMD2(center.x, center.z), dir = SIMD2(cast.x, -cast.y), b = a + dir * length
        let c = SIMD2(camera.x, camera.z), ab = b - a
        let t = simd_length_squared(ab) > 0 ? min(1, max(0, simd_dot(c - a, ab) / simd_length_squared(ab))) : 0
        let flat = simd_distance(c, a + ab * t), dy = max(0, abs(camera.y - center.y) - height - radius)
        return (flat * flat + dy * dy).squareRoot() <= range + radius
    }

    /// Shadow cells: sets casting on building cells/tiles and raised chunk tiles by reach.
    private func updateCasters(camera: SIMD3<Float>) {
        guard shadowCells else { return }
        casterRange = appliedShadowRange
        func set(_ e: Entity, _ on: Bool) {
            let cur = e.components[DynamicLightShadowComponent.self]?.castsShadow ?? true
            if cur != on { e.components.set(DynamicLightShadowComponent(castsShadow: on)) }
        }
        func reaches(_ b: BoundingBox) -> Bool {
            let c = (b.min + b.max) / 2, ext = (b.max - b.min) / 2
            return shadowReaches(center: SIMD3(c.x, b.min.y, c.z), radius: simd_length(SIMD2(ext.x, ext.z)), height: b.max.y - b.min.y, camera: camera)
        }
        for cell in buildingCells { if let b = cell.bounds { let on = reaches(b); for l in cell.levels { set(l.entity, on) } } }
        for tile in buildingTiles { for l in tile.levels { set(l.entity, reaches(l.bounds)) } }
        for t in raisedTiles { set(t.entity, reaches(t.bounds)) }
        for t in farParent?.tiles ?? [] { for d in t.drawn { set(d.entity, reaches(d.bounds)) } }
    }
    /// Buildings of one cell, one entity per distance LOD (P2's `BuildingLOD`); one is enabled.
    struct BuildingCellState {
        var rect: Rect2D
        var bounds: BoundingBox?
        var levels: [(lod: BuildingLOD, entity: Entity, triangles: Int)]
        var active: Int?
    }
    var buildingCells: [BuildingCellState] = []
    /// Neighbouring building cells (`buildingTileSizes` × as many) merged at the mid, far and
    /// skyline LODs: when every cell of a tile picks the same level by its own distance, one tile
    /// entity at that level replaces its cells' entities (the same triangles, fewer draw calls);
    /// also when some want a coarser level, if drawing them at the finest one adds at most
    /// `buildingTileAllowance` triangles. Larger tiles are tried first.
    struct BuildingTileState {
        var cells: [Int]
        var levels: [(lod: BuildingLOD, entity: Entity, triangles: Int, bounds: BoundingBox)]
        var active: Int?
    }
    var buildingTiles: [BuildingTileState] = []
    /// Tile sides in cells (100 m cells → 400 m and 200 m tiles), largest first.
    static let buildingTileSizes = [4, 2]
    /// Triangles a tile may add by drawing some cells finer than they want.
    static let buildingTileAllowance = 2000
    /// Triangles of the enabled building LODs.
    private var buildingTriangles = 0
    /// Trees and bushes this close to the camera keep the cut-away (transparent) material. The
    /// character is at most ~8 m from the follow camera and detail is re-bucketed every 8 m, so a
    /// blocker always falls inside.
    static let cutZoneMeters: Float = 20
    /// Whether the view has a cut-away target (slot 0 is used only then).
    private(set) var cutAwayActive = false
    private(set) var lodGroups: [LODGroup] = []
    var lodCenter: SIMD3<Float>?
    /// Forward direction and vertical field of view (degrees) at the last re-bucket, and the aspect.
    private var lodView: SIMD4<Float>?
    private var lodAspect: Float = 0
    /// Leave trees and bushes outside the (widened) view out of the instance data (on by default;
    /// off while an offscreen copy is made for another camera).
    var foliageViewCulling = true
    /// Re-bucket after turning this far; the culled view is this much wider on every side.
    static let cullTurnDegrees: Float = 20
    static let cullMarginDegrees: Float = 30
    /// Shadows of trees and bushes, for culling (set by `apply`): x, z = horizontal direction away
    /// from the sun (scene), y = shadow length per metre of height; nil without sun shadows.
    var shadowCast: SIMD3<Float>?
    /// Fixed geometry for the view-triangle estimate: chunk and static-prop bounds.
    private(set) var cullables: [(bounds: BoundingBox, triangles: Int, draws: Int, category: WritableKeyPath<ViewCost, Int>, name: String)] = []
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
        try buildFarParent()
        try buildProps()
        buildOccluders()
        stats.profileID = scene.profile.id
        stats.season = scene.season
        stats.lightKeys = "\(lighting.keyA)→\(lighting.keyB) \(String(format: "%.2f", lighting.blend)), sun \(String(format: "%.1f° az %.1f°", lighting.sunElevation, lighting.sunAzimuth))"
        stats.generated = scene.stats
        stats.chunkCount = scene.chunks.count
        if !options.diagnostics.contains("keepLoadGeometry") { releaseLoadOnlyGeometry() }
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
        // Without a cut-away target nothing is cut, so the cut-away zone joins the opaque near slot.
        if (cutAwayTarget != nil) != cutAwayActive {
            cutAwayActive = cutAwayTarget != nil
            lodCenter = nil
        }
        if updateFarParent(camera: camPos) { lodCenter = nil }
        updateLODs(camera: camera)
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
        tickStreaming(camera: camPos)
        viewClock += dt
        if viewClock >= 0.5 {
            viewClock = 0
            (stats.viewTriangleSplit, stats.viewDraws) = estimateView(camera: camera)
            stats.viewTriangles = stats.viewTriangleSplit.total
            stats.viewDrawCalls = stats.viewDraws.total
            let sh = shadowEstimate(camera: camera)
            stats.shadowSummary = "shadowTriangles=\(sh.triangles) shadowDraws=\(sh.draws) shadowRange=\(Int(sh.range)) shadowsplit[\(sh.casters)]"
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
            shadow.depthBias = Self.shadowBias(range: shadowDistance)
            sunEntity.components.set(shadow)
            let sun = SIMD2(lighting.sunDirection.x, lighting.sunDirection.z)
            let away = simd_length(sun) > 1e-4 ? -simd_normalize(sun) : SIMD2<Float>(0, 0)
            shadowCast = SIMD3(away.x, away.y, Float(1 / tan(max(Double(lighting.sunElevation), 3) * .pi / 180)))
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
            if let b = boundary.bounds {
                cullables.append((BoundingBox(min: b.min, max: b.max), boundary.triangleCount, 1, \.other, e.name))
            }
        }
        // Chunks are merged into square tiles, flat ground and raised geometry separately: the
        // largest tile (`chunkTileSize`, in chunks, halving) whose merged mesh stays within
        // `chunkTileTriangles`, so sparse ground costs few draw calls and dense ground still
        // culls; all water is one entity.
        var flatBy: [SIMD2<Int>: WorldMesh.MeshBuffers] = [:], raisedBy: [SIMD2<Int>: WorldMesh.MeshBuffers] = [:]
        var water = WorldMesh.MeshBuffers()
        for chunk in scene.chunks {
            // Flat ground (lawns, streets, paths, curbs, water) can't shadow anything, so it stays
            // out of the sun's shadow map; buildings and other raised geometry cast.
            (flatBy[chunk.index], raisedBy[chunk.index]) = Self.splitFlatGround(chunk.staticMesh)
            water.append(chunk.waterMesh)
        }
        func add(_ part: WorldMesh.MeshBuffers, name: String, material: CustomMaterial, casts: Bool) throws {
            guard let mesh = try MeshUpload.resource([part]), let b = part.bounds else { return }
            let e = Entity()
            e.name = name
            e.components.set(ModelComponent(mesh: mesh, materials: [material]))
            if !casts { e.components.set(DynamicLightShadowComponent(castsShadow: false)) }
            receiveIBL(e)
            rootEntity.addChild(e)
            if casts { raisedTiles.append((e, BoundingBox(min: b.min, max: b.max))) }
            stats.staticTriangles += part.triangleCount
            cullables.append((BoundingBox(min: b.min, max: b.max), part.triangleCount, 1, \.chunks, name))
            baseDrawCalls += 1
            stats.meshBytes += part.gpuBytes
            stats.meshBytesByKind["chunks", default: 0] += part.gpuBytes
        }
        for (parts, suffix, casts) in [(flatBy, " ground", false), (raisedBy, "", true)] {
            func tile(_ key: SIMD2<Int>, size: Int) throws {
                var merged = WorldMesh.MeshBuffers()
                for dx in 0..<size { for dy in 0..<size { if let m = parts[key &* size &+ SIMD2(dx, dy)] { merged.append(m) } } }
                guard !merged.isEmpty else { return }
                if merged.triangleCount > Self.chunkTileTriangles, size > 1 {
                    for dx in 0..<2 { for dy in 0..<2 { try tile(key &* 2 &+ SIMD2(dx, dy), size: size / 2) } }
                    return
                }
                try add(merged, name: "Chunk tile \(size) \(key.x)_\(key.y)\(suffix)", material: resources.staticMaterial, casts: casts)
            }
            // Shadow cells: casting (raised) geometry in single-chunk tiles, so casting follows reach.
            let top = shadowCells && casts ? 1 : Self.chunkTileSize
            let keys = Set(parts.keys.map { SIMD2(Self.floorDiv($0.x, top), Self.floorDiv($0.y, top)) })
            for key in keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) { try tile(key, size: top) }
        }
        try add(water, name: "Chunk water", material: resources.waterMaterial, casts: false)
    }

    /// Largest chunk tile side in chunks (`SceneGenerator.chunkSize` 200 m → 800 m), halved while a
    /// tile's mesh has more than `chunkTileTriangles` triangles.
    static let chunkTileSize = 4
    static let chunkTileTriangles = 40_000

    static func floorDiv(_ a: Int, _ b: Int) -> Int { Int((Double(a) / Double(b)).rounded(.down)) }

    /// Building cells: one entity per distance LOD (near, mid, far, skyline), all disabled until
    /// `updateLODs` picks one per cell by camera distance; then tiles of cells at the mid, far and
    /// skyline LODs (`BuildingTileState`).
    private func buildBuildingCells() throws {
        var sources: [Int] = []
        if options.diagnostics.contains("streamCells") || options.diagnostics.contains("roam") { streamer = try CellStreamer() }
        for (source, cell) in scene.buildingCells.enumerated() {
            var state = BuildingCellState(rect: cell.rect, bounds: nil, levels: [], active: nil)
            var streamedNear: WorldMesh.MeshBuffers?
            for lod in BuildingLOD.allCases {
                guard let m = cell.meshes[lod], !m.isEmpty else { continue }
                // Streaming: the near level stays on disk until the camera comes close; the cell
                // draws its next level until then (only when a coarser level exists).
                let streamed = streamer != nil && lod == .near && cell.meshes.keys.contains { $0 > .near }
                let mesh: MeshResource? = streamed ? nil : try MeshUpload.resource([m])
                guard streamed || mesh != nil else { continue }
                let e = Entity()
                e.name = "Buildings \(cell.id) \(lod)"
                e.isEnabled = false
                if let mesh { e.components.set(ModelComponent(mesh: mesh, materials: [resources.staticMaterial])) } else { streamedNear = m }
                receiveIBL(e)
                rootEntity.addChild(e)
                state.levels.append((lod, e, m.triangleCount))
                if let b = m.bounds {
                    let box = BoundingBox(min: b.min, max: b.max)
                    state.bounds = state.bounds.map { $0.union(box) } ?? box
                }
                if !streamed {
                    stats.meshBytes += m.gpuBytes
                    stats.meshBytesByKind["building-\(lod)", default: 0] += m.gpuBytes
                }
            }
            guard !state.levels.isEmpty else { continue }
            buildingCells.append(state)
            sources.append(source)
            if let near = streamedNear { try streamer?.store(cell: buildingCells.count - 1, mesh: near) }
        }
        try streamer?.finishStoring()
        for size in Self.buildingTileSizes {
            var tileCells: [SIMD2<Int>: [Int]] = [:]
            for (i, source) in sources.enumerated() {
                let index = scene.buildingCells[source].index
                tileCells[SIMD2(Self.floorDiv(index.x, size), Self.floorDiv(index.y, size)), default: []].append(i)
            }
            for key in tileCells.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
                let members = tileCells[key]!
                // A tile of one cell gains nothing.
                guard members.count > 1 else { continue }
                var tile = BuildingTileState(cells: members, levels: [], active: nil)
                for lod in [BuildingLOD.mid, .far, .skyline] {
                    // Each cell's level for a camera wanting `lod` (as `updateBuildingLODs` picks it).
                    var merged = WorldMesh.MeshBuffers()
                    for i in members {
                        let levels = buildingCells[i].levels
                        let pick = levels.firstIndex { $0.lod >= lod } ?? (levels.count - 1)
                        if let m = scene.buildingCells[sources[i]].meshes[levels[pick].lod] { merged.append(m) }
                    }
                    guard let b = merged.bounds, let mesh = try MeshUpload.resource([merged]) else { continue }
                    let e = Entity()
                    e.name = "Buildings tile \(size) \(key.x)_\(key.y) \(lod)"
                    e.isEnabled = false
                    e.components.set(ModelComponent(mesh: mesh, materials: [resources.staticMaterial]))
                    receiveIBL(e)
                    rootEntity.addChild(e)
                    tile.levels.append((lod, e, merged.triangleCount, BoundingBox(min: b.min, max: b.max)))
                    stats.meshBytes += merged.gpuBytes
                    stats.meshBytesByKind["building-tile-\(lod)", default: 0] += merged.gpuBytes
                }
                if !tile.levels.isEmpty { buildingTiles.append(tile) }
            }
        }
    }

    /// Diagnostics: hide or show every building cell and tile (the current LODs come back).
    func setBuildingsVisible(_ on: Bool) {
        for cell in buildingCells {
            for (j, l) in cell.levels.enumerated() { l.entity.isEnabled = on && j == cell.active }
        }
        for tile in buildingTiles {
            for (j, l) in tile.levels.enumerated() { l.entity.isEnabled = on && j == tile.active }
        }
    }

    /// Distance (m) from a camera point to a rectangle's nearest point (0 inside).
    static func distance(_ p: LocalPoint, to r: Rect2D) -> Double {
        simd_distance(p, LocalPoint(min(max(p.x, r.min.x), r.max.x), min(max(p.y, r.min.y), r.max.y)))
    }

    /// Enables one LOD per building cell: `BuildingLOD.forDistance` of the camera's distance to the
    /// cell, or the nearest coarser level the cell has (context cells have far and skyline only).
    /// Where every cell of a tile wants the same mid, far or skyline level, the tile's merged entity
    /// draws them instead (the same meshes; larger tiles first).
    private func updateBuildingLODs(camera c: SIMD2<Float>) {
        // The far parent draws every building while it is admitted.
        if farParentActive { buildingTriangles = 0; return }
        var tris = 0
        let p = LocalPoint(Double(c.x), Double(-c.y))
        let want = buildingCells.map { BuildingLOD.forDistance(Self.distance(p, to: $0.rect)) }
        var tiled = [Bool](repeating: false, count: buildingCells.count)
        for t in buildingTiles.indices {
            let tile = buildingTiles[t]
            // The finest level any cell wants; cells wanting a coarser one are drawn at it too when
            // that adds at most `buildingTileAllowance` triangles.
            let w = tile.cells.map { want[$0] }.min()!
            var pick: Int?
            if !tile.cells.contains(where: { tiled[$0] }), let k = tile.levels.firstIndex(where: { $0.lod == w }) {
                if tile.cells.allSatisfy({ want[$0] == w }) {
                    pick = k
                } else {
                    let own = tile.cells.reduce(0) { sum, i in
                        let levels = buildingCells[i].levels
                        return sum + levels[levels.firstIndex { $0.lod >= want[i] } ?? (levels.count - 1)].triangles
                    }
                    if tile.levels[k].triangles <= own + Self.buildingTileAllowance { pick = k }
                }
            }
            if tile.active != pick {
                for (j, l) in tile.levels.enumerated() { l.entity.isEnabled = j == pick }
                buildingTiles[t].active = pick
            }
            if let pick {
                for i in tile.cells { tiled[i] = true }
                tris += tile.levels[pick].triangles
            }
        }
        for i in buildingCells.indices {
            let levels = buildingCells[i].levels
            let pick: Int? = tiled[i] ? nil : (levels.firstIndex { $0.lod >= want[i] && nearReady(i, $0.lod) } ?? (levels.count - 1))
            if buildingCells[i].active != pick {
                for (j, l) in levels.enumerated() { l.entity.isEnabled = j == pick }
                buildingCells[i].active = pick
            }
            if let pick { tris += levels[pick].triangles }
        }
        buildingTriangles = tris
    }

    /// A streamed near level counts only once its mesh is resident.
    private func nearReady(_ cell: Int, _ lod: BuildingLOD) -> Bool {
        lod != .near || streamer == nil || streamer!.packed[cell] == nil || streamer!.isResident(cell)
    }

    /// Streaming tick (every frame, stream on): loads/releases near levels by camera distance and
    /// re-picks LODs when residency changes. A released cell switches to its next level first.
    private func tickStreaming(camera c: SIMD3<Float>) {
        guard let streamer else { return }
        // Prefetch: also measure from where the camera will be in 1.5 s (velocity smoothed over ~0.5 s),
        // so a cell's near mesh is resident before it comes within the near range.
        let now = CFAbsoluteTimeGetCurrent()
        if let (q, t) = streamLast, now > t {
            let v = (c - q) / Float(now - t)
            streamVelocity += (v - streamVelocity) * min(1, Float(now - t) * 2)
        }
        streamLast = (c, now)
        let ahead = c + streamVelocity * 1.5
        let p = LocalPoint(Double(c.x), Double(-c.z)), pa = LocalPoint(Double(ahead.x), Double(-ahead.z))
        // While the far parent is admitted no near level is drawn, so none is wanted.
        let far = farParentActive
        let changed = streamer.tick(distances: { far ? .infinity : min(Self.distance(p, to: self.buildingCells[$0].rect), Self.distance(pa, to: self.buildingCells[$0].rect)) },
            attach: { cell, resource in
                guard let k = self.buildingCells[cell].levels.firstIndex(where: { $0.lod == .near }) else { return }
                self.buildingCells[cell].levels[k].entity.components.set(ModelComponent(mesh: resource, materials: [self.resources.staticMaterial]))
            },
            detach: { cell in
                let levels = self.buildingCells[cell].levels
                guard let k = levels.firstIndex(where: { $0.lod == .near }) else { return }
                if self.buildingCells[cell].active == k, k + 1 < levels.count {
                    levels[k + 1].entity.isEnabled = true
                    self.buildingCells[cell].active = k + 1
                }
                levels[k].entity.isEnabled = false
                levels[k].entity.components.remove(ModelComponent.self)
            })
        if changed { updateBuildingLODs(camera: SIMD2(c.x, c.z)) }
    }

    /// Splits static geometry into flat ground (every corner within 0.3 m of the ground plane:
    /// lawns, streets, paths, curbs) and the rest. The ground is flat at y = 0 today; with terrain
    /// this must compare against the ground height instead.
    static func splitFlatGround(_ m: WorldMesh.MeshBuffers) -> (flat: WorldMesh.MeshBuffers, raised: WorldMesh.MeshBuffers) {
        m.partitioned { $0.y < 0.3 && $1.y < 0.3 && $2.y < 0.3 }
    }

    private var meshCache: [String: (MeshResource, WorldMesh.MeshBuffers)] = [:]
    var meshCacheCPUBytes: Int { meshCache.values.reduce(0) { $0 + $1.1.cpuBytes } }
    /// Whether the CPU copies of chunk, building-cell and boundary meshes were freed after upload.
    private(set) var loadOnlyGeometryReleased = false
    /// Streaming slice 1 (`-diag streamCells`, default off): building-cell near levels from a disk cache.
    private(set) var streamer: CellStreamer?
    private var streamLast: (SIMD3<Float>, Double)?
    private var streamVelocity = SIMD3<Float>(repeating: 0)
    /// Streaming has nothing in flight or wanted (true when streaming is off).
    var streamingIdle: Bool { streamer?.idle ?? true }
    /// Stream counters for logs (resident bytes/cells, loads, evictions, worst upload frame).
    public var streamSummary: String {
        guard let st = streamer?.stats else { return "" }
        return String(format: "pool=%.1fMiB slots=%d/%d ", Double(streamer?.poolBytes ?? 0) / 1_048_576, streamer?.slotCounts.free ?? 0, streamer?.slotCounts.total ?? 0) + "packed=\(streamer?.packed.count ?? 0) wanted=\(st.wanted) nearest=\(Int(st.nearest)) reads=\(st.reads) readFail=\(st.readFailures) " + String(format: "allocMaxMs=%.3f copyMaxMs=%.3f finishMaxMs=%.3f replaceMaxMs=%.3f partsMaxMs=%.3f attachMaxMs=%.3f finishesOver=%d ", st.allocMax * 1000, st.copyMax * 1000, st.finishMax * 1000, st.replaceMax * 1000, st.partsMax * 1000, st.attachMax * 1000, st.finishesOver) + String(format: "STREAM resident=%.1fMiB cells=%d loads=%d evictions=%d cancelled=%d uploadFrames=%d overBudget=%d", Double(st.residentBytes) / 1_048_576,
                      st.residentCells, st.loads, st.evictions, st.cancelled, st.uploadFrames, st.framesOverBudget)
    }
    /// The worst single-frame upload time (ms) since the last call (stream on).
    public func takeStreamFrameMaxMs() -> Double { (streamer?.takeFrameMax().frameMax ?? 0) * 1000 }

    /// Frees the CPU copies of geometry that only the load path reads (chunk, building-cell and
    /// boundary meshes): once uploaded, nothing reads them again, so rendering is unchanged.
    /// Counts, palette, instances, clutter and occluders stay.
    func releaseLoadOnlyGeometry() {
        for i in scene.chunks.indices { scene.chunks[i].staticMesh = .init(); scene.chunks[i].waterMesh = .init() }
        for i in scene.buildingCells.indices { scene.buildingCells[i].meshes = [:] }
        scene.boundaryGround = .init()
        loadOnlyGeometryReleased = true
    }
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
    /// The approved mock's colour grade for the current light and weather (daytime master, mock-values.json).
    public internal(set) var gradeLook: GradeTable.Look = .neutral
    /// The lighting bible (generated from look-fix-v1) and its per-state grade with our tuning.
    static let lightingBible = try? StyleLibrary.lightingBible()
    static let gradeTable = try? StyleLibrary.grade()
    /// Renderer-neutral look values beyond the bible (`Profiles/look.json`).
    static let lookSpec = try? StyleLibrary.look()
    /// The daytime lighting master (house-contrast-v1 sharedLighting, from mock-values.json).
    static let daytimeMaster = try? StyleLibrary.daytimeMaster()
    /// Lake water values (lake-winter-v1, water-surfaces-v1 mechanics).
    static let lakeWater = try? StyleLibrary.lakeWater()
    /// The rain pack (generated from docs/proposals/rain-v1).
    static let rainBible = try? StyleLibrary.rainBible()

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

    /// How far from the camera the sun casts shadows (m): look.json `shadows.rangeM` (owner, 7 Oct:
    /// crown shadows must reach the lawns, 120 m; was 60 m under the earlier 8 ms GPU rule).
    /// GPU attribution measures other ranges with `setShadowDistance(_:)`.
    var shadowDistance = Float(World.lookSpec?.shadows.rangeM ?? 60)
    /// Shadow depth bias: 1.5 was tuned at 60 m; a longer range has coarser texels, so the bias grows
    /// with it (linearly, as postcards always did) to keep acne off lawns and walls.
    static func shadowBias(range: Float) -> Float { 1.5 * max(1, range / 60) }
    /// The shadow range last given to the sun (`apply` widens it at low sun).
    var appliedShadowRange: Float = 0

    /// Opaque materials for trees and bushes outside the cut-away zone (on by default; switched off
    /// only to measure what it saves, `World.Feature.opaqueDetail`).
    var opaqueDetail = true {
        didSet {
            guard opaqueDetail != oldValue else { return }
            for b in lodBatches {
                b.entity.components[ModelComponent.self]?.materials = [material(for: b.kind, cuttable: b.slot == 0)]
            }
        }
    }

    private func buildProps() throws {
        if options.diagnostics.contains("noProps") { recount(); return }
        // Lamps and benches (one detail level, fixed): merged into one static mesh, or one per
        // `propTileMeters` tile when there are many (their shader reads no per-instance value, so
        // a merged copy draws the same); trees and bushes: instanced per kind/variant (below).
        var fixed: [SIMD2<Int>: WorldMesh.MeshBuffers] = [:]
        var groups: [String: [PropInstance]] = [:]
        for inst in scene.instances {
            stats.propInstances += 1
            if PropLibrary.lodCount(inst.kind) == 1, !inst.kind.isFoliage {
                guard let (_, buffers) = try cached(inst.kind, inst.variant) else { continue }
                let k = SIMD2(Int((inst.x / Self.propTileMeters).rounded(.down)), Int((inst.y / Self.propTileMeters).rounded(.down)))
                fixed[k, default: WorldMesh.MeshBuffers()].append(buffers, transform: inst.transform)
            } else {
                groups["\(inst.kind.rawValue)/\(inst.variant)", default: []].append(inst)
            }
        }
        // A small set is one entity; a large one stays split by tile, so it still culls.
        if fixed.values.reduce(0, { $0 + $1.triangleCount }) <= Self.chunkTileTriangles {
            var all = WorldMesh.MeshBuffers()
            for key in fixed.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) { all.append(fixed[key]!) }
            fixed = all.isEmpty ? [:] : [SIMD2(0, 0): all]
        }
        for key in fixed.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            let m = fixed[key]!
            guard let b = m.bounds, let mesh = try MeshUpload.resource([m]) else { continue }
            let e = Entity()
            e.name = "Props \(key.x)_\(key.y)"
            e.components.set(ModelComponent(mesh: mesh, materials: [material(for: .lamp)]))
            receiveIBL(e)
            rootEntity.addChild(e)
            staticPropBase += m.triangleCount
            cullables.append((BoundingBox(min: b.min, max: b.max), m.triangleCount, 1, \.props, e.name))
            baseDrawCalls += 1
            stats.meshBytes += m.gpuBytes
        }
        // Trees, bushes: one batch per kind/variant and slot (cut-away zone, near, mid, far,
        // skyline), refilled as the camera moves; at far and skyline, variants of a non-tree kind
        // with equally many triangles share the first one's batch, scaled to their own bounds.
        var shared: [String: Int] = [:]
        for key in groups.keys.sorted() {
            let list = groups[key]!
            let kind = list[0].kind, variant = list[0].variant
            var group = LODGroup(kind: kind, variant: variant, instances: list, batches: [], fits: [])
            let slots = PropLibrary.lodCount(kind) + 1
            let perCell = treeCells && kind.isTree
            if perCell {
                group.cellOf = list.map { SIMD2(Int(($0.x / Self.treeCellMeters).rounded(.down)), Int(($0.y / Self.treeCellMeters).rounded(.down))) }
            }
            let cells = Set(group.cellOf).sorted { ($0.x, $0.y) < ($1.x, $1.y) }
            for slot in 0..<slots {
                guard let (mesh, buffers) = try cached(kind, variant, lod: max(0, slot - 1)) else { break }
                let shareKey = !kind.isTree && slot >= 3 ? "\(kind.rawValue)/\(slot)/\(buffers.triangleCount)" : nil
                if let shareKey, let b = shared[shareKey] {
                    group.batches.append(b)
                    group.fits.append(Self.fit(lodBatches[b].buffers, to: buffers))
                    continue
                }
                let data = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: 1)
                let e = Entity()
                e.name = shareKey.map { "LOD \(kind.rawValue) shared \(slot) \($0.split(separator: "/").last!)" } ?? "LOD \(key) \(slot)"
                e.isEnabled = false
                e.components.set(ModelComponent(mesh: mesh, materials: [material(for: kind, cuttable: slot == 0)]))
                receiveIBL(e)
                rootEntity.addChild(e)
                if let shareKey { shared[shareKey] = lodBatches.count }
                group.batches.append(lodBatches.count)
                group.fits.append(matrix_identity_float4x4)
                lodBatches.append(LODBatch(kind: kind, slot: slot, entity: e, data: data, triangles: buffers.triangleCount, buffers: buffers))
                if shadowCells, shareKey == nil {
                    // Twin: the same mesh and material, never in the shadow map.
                    let te = Entity()
                    te.name = e.name + " no-shadow"
                    te.isEnabled = false
                    te.components.set(ModelComponent(mesh: mesh, materials: [material(for: kind, cuttable: slot == 0)]))
                    te.components.set(DynamicLightShadowComponent(castsShadow: false))
                    receiveIBL(te)
                    rootEntity.addChild(te)
                    let twinData = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: 1)
                    lodBatches[lodBatches.count - 1].twin = lodBatches.count
                    lodBatches.append(LODBatch(kind: kind, slot: slot, entity: te, data: twinData, triangles: buffers.triangleCount, buffers: buffers, casts: false))
                }
                if perCell, shareKey == nil {
                    var byCell: [SIMD2<Int>: Int] = [:]
                    for c in cells {
                        let ce = Entity()
                        ce.name = e.name + " cell \(c.x)_\(c.y)"
                        ce.isEnabled = false
                        ce.components.set(ModelComponent(mesh: mesh, materials: [material(for: kind, cuttable: slot == 0)]))
                        receiveIBL(ce)
                        rootEntity.addChild(ce)
                        byCell[c] = lodBatches.count
                        lodBatches.append(LODBatch(kind: kind, slot: slot, entity: ce, data: try LowLevelInstanceData(instanceCount: 0, instanceCapacity: 1),
                                                   triangles: buffers.triangleCount, buffers: buffers))
                    }
                    group.cellBatches.append(byCell)
                }
            }
            guard group.batches.count == slots else { continue }
            if let b = lodBatches[group.batches[1]].buffers.bounds {
                let extent = simd_max(simd_abs(b.min), simd_abs(b.max))
                group.spheres = list.map { inst in
                    let t = inst.transform
                    let s = max(simd_length(SIMD3(t.columns.0.x, t.columns.0.y, t.columns.0.z)),
                                simd_length(SIMD3(t.columns.1.x, t.columns.1.y, t.columns.1.z)),
                                simd_length(SIMD3(t.columns.2.x, t.columns.2.y, t.columns.2.z)))
                    return SIMD4(t.columns.3.x, t.columns.3.y, t.columns.3.z, simd_length(extent) * s)
                }
            } else {
                group.spheres = list.map { SIMD4($0.transform.columns.3.x, $0.transform.columns.3.y, $0.transform.columns.3.z, 50) }
            }
            lodGroups.append(group)
            stats.meshBytes += list.count * 64 * slots
        }
        // Instance capacity: every instance that can draw into the batch.
        var capacity = [Int](repeating: 0, count: lodBatches.count)
        for g in lodGroups { for b in Set(g.batches) { capacity[b] += g.instances.count } }
        for g in lodGroups where !g.cellBatches.isEmpty {
            var counts: [SIMD2<Int>: Int] = [:]
            for c in g.cellOf { counts[c, default: 0] += 1 }
            for slot in g.cellBatches { for (c, b) in slot { capacity[b] += counts[c]! } }
        }
        // A shadow-cells twin can take every instance its batch can.
        for b in lodBatches.indices { if let t = lodBatches[b].twin { capacity[t] = capacity[b] } }
        for b in lodBatches.indices { lodBatches[b].data = try LowLevelInstanceData(instanceCount: 0, instanceCapacity: max(1, capacity[b])) }
        if let (mesh, _) = try cached(.tuft, 0) { tuftMesh = mesh }
        staticPropTriangles = staticPropBase
        recount()
    }

    func recount() {
        stats.propTriangles = staticPropTriangles
        stats.triangles = stats.staticTriangles + buildingTriangles + staticPropTriangles + stats.treeTriangles + stats.clutterInstances * 17
        if farParentActive, let fp = farParent {
            stats.triangles += fp.tiles.reduce(0) { $0 + $1.drawn.reduce(0) { $0 + $1.triangles } }
        }
        // Draw calls: chunks + static props (counted at build) + building cells + enabled LOD entities + tufts.
        stats.drawCalls = baseDrawCalls + buildingCells.filter { $0.active != nil }.count + buildingTiles.filter { $0.active != nil }.count
            + (farParentActive ? farParent!.tiles.reduce(0) { $0 + $1.drawn.count } : 0)
            + lodBatches.filter { $0.count > 0 }.count
            + (stats.clutterInstances > 0 ? 1 : 0) + contextDrawCalls
        stats.triangles += stats.contextTriangles
    }

    /// Side of the tiles lamps and benches are merged into (m) when they are more than
    /// `chunkTileTriangles` in all.
    static let propTileMeters = 800.0

    /// Scale (about the origin, so the instance origin stays put) taking `shared`'s bounds to
    /// `own`'s: width and depth by extent, height by top.
    static func fit(_ shared: WorldMesh.MeshBuffers, to own: WorldMesh.MeshBuffers) -> simd_float4x4 {
        guard let a = shared.bounds, let b = own.bounds else { return matrix_identity_float4x4 }
        func ratio(_ x: Float, _ y: Float) -> Float { y > 1e-4 ? x / y : 1 }
        let ea = a.max - a.min, eb = b.max - b.min
        return simd_float4x4(diagonal: SIMD4(ratio(eb.x, ea.x), ratio(b.max.y, a.max.y), ratio(eb.z, ea.z), 1))
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
    /// than 8 m, or (with `foliageViewCulling`) turned more than `cullTurnDegrees` or widened its
    /// view. Distance is from the eye (3D), so from the aerial camera every tree is far away.
    /// Instances (beyond the cut-away zone) that neither meet the view widened by
    /// `cullMarginDegrees` on every side nor throw a shadow into it are left out: they can't be
    /// seen before the next re-bucket.
    private func updateLODs(camera cameraEntity: Entity) {
        let camera = cameraEntity.position(relativeTo: nil)
        let m = cameraEntity.transformMatrix(relativeTo: nil)
        let forward = simd_normalize(-SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z))
        let fov = cameraEntity.components[PerspectiveCameraComponent.self]?.fieldOfViewInDegrees ?? 50
        let view = SIMD4(forward, fov)
        if shadowCells, casterRange != appliedShadowRange { lodCenter = nil }
        if let last = lodCenter, simd_distance(last, camera) < Float(PropLibrary.lodRebucketMeters) {
            guard foliageViewCulling, let v = lodView else { return }
            let turned = acos(min(1, max(-1, simd_dot(SIMD3(v.x, v.y, v.z), forward)))) * 180 / .pi
            guard turned > Self.cullTurnDegrees || fov > v.w + 0.5 || abs(viewAspect - lodAspect) > 0.01 else { return }
        }
        lodCenter = camera
        lodView = view
        lodAspect = viewAspect
        updateBuildingLODs(camera: SIMD2(camera.x, camera.z))
        updateContextLODs(camera: camera)
        updateCasters(camera: camera)
        let cut = Self.cutZoneMeters
        let edges = PropLibrary.lodDistances.map(Float.init)  // near→mid, mid→far, far→skyline
        // The view widened by the margin (normalised planes for a sphere test).
        let margin = Self.cullMarginDegrees * .pi / 180
        let vHalf = fov * .pi / 360, hHalf = atan(tan(vHalf) * viewAspect)
        let vWide = min(vHalf + margin, 85 * .pi / 180), hWide = min(hHalf + margin, 85 * .pi / 180)
        let planes = Self.frustumPlanes(view: m.inverse, fovY: 2 * vWide, aspect: tan(hWide) / tan(vWide), near: 0.1, far: 20000)
            .map { $0 / simd_length(SIMD3($0.x, $0.y, $0.z)) }
        let cast = shadowCast
        /// Whether an instance (bounding sphere) or its shadow can meet the widened view.
        func visible(_ c: SIMD4<Float>) -> Bool {
            func meets(_ p: SIMD3<Float>, _ r: Float) -> Bool {
                !planes.contains { simd_dot(SIMD3($0.x, $0.y, $0.z), p) + $0.w < -r }
            }
            let p = SIMD3(c.x, c.y, c.z)
            if meets(p, c.w) { return true }
            guard let cast else { return false }
            // The shadow: from the instance along the ground away from the sun, as long as a crown of
            // the sphere's diameter casts at this sun (capped), bounded by one sphere.
            let length = min(2 * c.w * cast.z, 300)
            return meets(SIMD3(p.x + cast.x * length / 2, 0, p.z + cast.y * length / 2), c.w + length / 2)
        }
        var trees = 0, others = 0
        var buckets = [[simd_float4x4]](repeating: [], count: lodBatches.count)
        for g in lodGroups {
            let slots = g.batches.count
            for (k, inst) in g.instances.enumerated() {
                let d = simd_distance(SIMD3(Float(inst.x), Float(inst.height), Float(-inst.y)), camera)
                if foliageViewCulling, d >= cut, !visible(g.spheres[k]) { continue }
                var slot = cutAwayActive && d < cut ? 0 : 1
                if slot == 1 { for e in edges where d >= e { slot += 1 } }
                slot = min(slot, slots - 1)
                var target = g.batches[slot]
                if let twin = lodBatches[target].twin {
                    let c = g.spheres[k]
                    // Bounding sphere about the tree's origin: its top is at most c.w above it.
                    if !shadowReaches(center: SIMD3(c.x, c.y, c.z), radius: c.w + 0.03, height: c.w, camera: camera) {
                        target = twin
                    } else if !g.cellBatches.isEmpty, !farParentActive, let cb = g.cellBatches[slot][g.cellOf[k]] {
                        target = cb
                    }
                }
                buckets[target].append(slot >= 3 ? inst.transform * g.fits[slot] : inst.transform)
            }
        }
        for b in lodBatches.indices {
            let batch = lodBatches[b], ts = buckets[b]
            batch.data.instanceCount = ts.count
            lodBatches[b].count = ts.count
            lodBatches[b].bounds = Self.bounds(of: batch.buffers, ts)
            if ts.isEmpty {
                batch.entity.isEnabled = false
            } else {
                batch.data.replaceMutableTransforms { dst in for (i, t) in ts.enumerated() { dst[i] = t } }
                batch.entity.isEnabled = true
                if let mesh = batch.entity.components[ModelComponent.self]?.mesh,
                   let comp = try? MeshInstancesComponent(mesh: mesh, instances: batch.data, bounds: lodBatches[b].bounds) {
                    batch.entity.components.set(comp)
                }
            }
            if batch.kind.isTree { trees += ts.count * batch.triangles } else { others += ts.count * batch.triangles }
        }
        stats.treeTriangles = trees
        staticPropTriangles = staticPropBase + others
        recount()
    }

    /// Triangles and draw calls in entities whose bounds meet the camera frustum (what the GPU is
    /// asked to draw), by category. The sky dome, stars and precipitation count as one draw each
    /// when enabled (their triangles are left out); host characters are not counted.
    func estimateView(camera: Entity) -> (triangles: ViewCost, draws: ViewCost) {
        let fov = (camera.components[PerspectiveCameraComponent.self]?.fieldOfViewInDegrees ?? 50) * .pi / 180
        let planes = Self.frustumPlanes(view: camera.transformMatrix(relativeTo: nil).inverse, fovY: fov, aspect: viewAspect, near: 0.1, far: 5000)
        var tris = ViewCost(), draws = ViewCost()
        for c in cullables where Self.intersects(c.bounds, planes) {
            tris[keyPath: c.category] += c.triangles; draws[keyPath: c.category] += c.draws
        }
        if farParentActive {
            for t in farParent!.tiles {
                for d in t.drawn where Self.intersects(d.bounds, planes) { tris.buildings += d.triangles; draws.buildings += 1 }
            }
        }
        for cell in buildingCells {
            if let b = cell.bounds, let a = cell.active, Self.intersects(b, planes) { tris.buildings += cell.levels[a].triangles; draws.buildings += 1 }
        }
        for tile in buildingTiles {
            if let a = tile.active, Self.intersects(tile.levels[a].bounds, planes) { tris.buildings += tile.levels[a].triangles; draws.buildings += 1 }
        }
        for batch in lodBatches where batch.count > 0 {
            if let b = batch.bounds, Self.intersects(b, planes) {
                let t = batch.count * batch.triangles
                if batch.kind.isFoliage { tris.foliage += t; draws.foliage += 1 } else { tris.props += t; draws.props += 1 }
            }
        }
        if let b = tuftBounds, stats.clutterInstances > 0, Self.intersects(b, planes) { tris.other += stats.clutterInstances * 17; draws.other += 1 }
        for e in [skyDome, starField?.entity, precipitation] { if let e, e.isEnabled { draws.other += 1 } }
        let ring = contextView(planes)
        tris.context = ring.triangles
        draws.context = ring.drawCalls
        return (tris, draws)
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
