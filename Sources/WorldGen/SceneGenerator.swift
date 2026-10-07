import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// Ground layer heights (meters). Small steps keep coplanar layers from flickering.
public enum GroundLayer {
    public static let base = 0.0
    public static let park = 0.01
    public static let pitch = 0.02
    public static let bank = 0.025
    public static let water = 0.03
    public static let alley = 0.035
    public static let road = 0.04
    public static let crossing = 0.045
    public static let path = 0.05
    public static let sidewalk = 0.06
    public static let curbTop = 0.15
    /// Generated yards (inferred lots): ≥2 cm over the base lawn (5A: no z-fighting at 2.5x).
    public static let yard = 0.02
    public static let yardBed = 0.03
    public static let driveway = 0.045
    public static let walk = 0.05
}

/// One feature's vertex range inside a chunk mesh (stable primitive-to-feature mapping).
public struct FeatureRange: Sendable, Codable, Equatable {
    public var feature: String
    public var start: Int
    public var count: Int
}

/// One 200 m chunk's merged geometry.
public struct GeneratedChunk: Sendable {
    public var index: SIMD2<Int>
    public var rect: Rect2D
    public var detail: DetailLevel
    /// Buildings, ground, roads, curbs: the `static` material.
    public var staticMesh = MeshBuffers()
    /// Lakes and ponds: the `water` material.
    public var waterMesh = MeshBuffers()
    public var staticFeatures: [FeatureRange] = []
    public var waterFeatures: [FeatureRange] = []

    public var id: String { "\(index.x)_\(index.y)" }
}

/// One placed prop (tree, lamp, bench, bush). Trees and bushes pick their detail level at render time.
public struct PropInstance: Sendable, Codable, Equatable {
    public var kind: PropKind
    /// Shape variant (`PropLibrary.variants`; trees have one, shaped per instance by `stretch`).
    public var variant: Int
    /// The OSM feature it came from, or a generator key (e.g. "gen:lamp:way/123:4").
    public var source: String
    /// Local meters (east, north) and height.
    public var x: Double
    public var y: Double
    public var height: Double
    public var yaw: Double
    public var scale: Double
    /// Extra scale along the prop's own x and z axes (before yaw): trees get their own crown width and
    /// an oval footprint; 1 for everything else.
    public var stretch = SIMD2<Double>(1, 1)

    public var transform: simd_float4x4 {
        simd_float4x4(translation: LocalFrame.scenePosition(LocalPoint(x, y), y: height), yaw: Float(yaw), scale: Float(scale),
                      stretch: SIMD2<Float>(stretch))
    }
}

/// An oriented building hull for camera collision (local footprint hull + height).
public struct Occluder: Sendable {
    public var hull: [LocalPoint]
    public var height: Double
}

public struct GeneratedScene: Sendable {
    public var palette: Palette
    public var profile: StyleProfile
    public var season: Int
    public var chunks: [GeneratedChunk] = []
    public var instances: [PropInstance] = []
    public var occluders: [Occluder] = []
    public var buildings: [GeneratedBuilding] = []
    public var clutter: ClutterField
    /// A large plain ground under and around the area (soft world boundary), slightly below y=0.
    public var boundaryGround = MeshBuffers()
    public var stats: [String: Int] = [:]
    /// Inferred yards of residential buildings (dressing data, not parcels).
    public var lots: [GeneratedLot] = []
    /// Where leaves collect beyond crowns: curbs, hedges, walk edges.
    public var litterHints: [LitterHint] = []
    /// Fall leaf-litter patches under deciduous trees (season mask is the renderer's).
    public var litterPatches: [LitterPatch] = []
    /// Buildings by ~100 m cell at each distance LOD, when `SceneGenerator.buildingLODs` is on
    /// (then building meshes are not in the chunks' static meshes).
    public var buildingCells: [BuildingCell] = []
}

/// The buildings of one cell at each distance LOD (regions §4, `BuildingLOD`): the renderer draws
/// one LOD per cell by camera distance. Context cells (outside the focus) have far and skyline only.
public struct BuildingCell: Sendable {
    public var index: SIMD2<Int>
    /// Local bounds of the cell (east, north metres).
    public var rect: Rect2D
    public var meshes: [BuildingLOD: MeshBuffers] = [:]
    public var id: String { "\(index.x)_\(index.y)" }
}

public struct SceneGenerator: Sendable {
    public var features: MapFeatures
    public var profile: StyleProfile
    public var seasonal: SeasonalPalette
    public var baseColors: [String: String]
    public var season: Int
    /// Region that gets full street-level detail; everything else is simple context.
    public var focus: Rect2D
    public var chunkSize = 200.0
    /// 0 = full detail; 1 = reduced (every building simple, no curbs or sidewalk edges).
    public var lod = 0
    /// Palette to continue from (keeps slot numbers equal across detail levels).
    public var startPalette: Palette?
    /// Per-building zone profiles; nil = `profile` for every building.
    public var zones: ZoneProfiles?
    /// Distance LODs for buildings: each building at every LOD into `GeneratedScene.buildingCells`
    /// instead of the chunk meshes (RealityKit; the package keeps one detail level per chunk).
    public var buildingLODs = false
    public var buildingCellSize = 100.0

    public init(features: MapFeatures, profile: StyleProfile, seasonal: SeasonalPalette, baseColors: [String: String],
                season: Int, focus: Rect2D) {
        self.features = features
        self.profile = profile
        self.seasonal = seasonal
        self.baseColors = baseColors
        self.season = season
        self.focus = focus
    }

    /// Small single-storey `building=yes` outbuildings (14–75 m²) with a principal building
    /// (≥ 70 m²) within 30 m that stands at least 4 m closer to the nearest street: detached
    /// garages behind houses (footprint and position evidence; tagged buildings are never changed).
    static func detachedGarages(_ features: MapFeatures, context: StreetContext) -> Set<OSMRef> {
        var principals: [SIMD2<Int>: [(LocalPoint, Double)]] = [:]
        func key(_ p: LocalPoint) -> SIMD2<Int> { SIMD2(Int((p.x / 30).rounded(.down)), Int((p.y / 30).rounded(.down))) }
        func streetDistance(_ p: LocalPoint) -> Double { context.streetIndex.nearest(to: p, within: 80)?.distance ?? 80 }
        for b in features.buildings where !b.isPart && b.footprint.area >= 70 {
            let c = b.footprint.centroid
            principals[key(c), default: []].append((c, streetDistance(c)))
        }
        var out: Set<OSMRef> = []
        for b in features.buildings where !b.isPart && b.type == "yes" {
            let area = b.footprint.area
            guard area >= 14, area <= 75, b.levels.map({ $0 <= 1.5 }) ?? true, !(b.hasHeightTag && b.height.top > 6.5) else { continue }
            let c = b.footprint.centroid
            let d = streetDistance(c)
            let k = key(c)
            var found = false
            for dx in -1...1 { for dy in -1...1 where !found {
                for (pc, pd) in principals[k &+ SIMD2(dx, dy)] ?? [] where simd_distance(pc, c) <= 30 && pd + 4 <= d {
                    found = true
                    break
                }
            } }
            if found { out.insert(b.ref) }
        }
        return out
    }

    /// The seasonal palette with the area profile's lawn endpoint pair as `lawnA` / `lawnB`.
    static func withLawnEndpoints(_ seasonal: SeasonalPalette, profileID: String) -> SeasonalPalette {
        guard let ends = YardLibrary.bundled.rules(for: profileID).lawnEndpoints else { return seasonal }
        var out = seasonal
        var a: [String] = [], b: [String] = []
        for season in seasonal.seasons {
            let key = season == "autumn" ? "fall" : season
            guard let pair = ends[key] ?? ends[season], pair.count == 2 else { return seasonal }
            a.append(pair[0])
            b.append(pair[1])
        }
        out.surfaces["lawnA"] = a
        out.surfaces["lawnB"] = b
        return out
    }

    func chunkIndex(_ p: LocalPoint) -> SIMD2<Int> {
        SIMD2(Int(((p.x - features.bounds.min.x) / chunkSize).rounded(.down)),
              Int(((p.y - features.bounds.min.y) / chunkSize).rounded(.down)))
    }

    public func generate() -> GeneratedScene {
        let dressed = VegetationLibrary.bundled.applying(to: Self.withLawnEndpoints(seasonal, profileID: profile.id), profileID: profile.id)
        var palette = startPalette ?? Palette(seasonal: dressed, season: season, base: baseColors)
        let context = StreetContext(features)
        let buildingIndex = PolygonIndex(features.buildings.map(\.footprint))
        let streetscape = Streetscape(context: context, buildings: buildingIndex)
        // House candidates per zone profile, for thresholds relative to the local houses.
        var houseAreas: [String: [Double]] = [:]
        for b in features.buildings where !b.isPart && BuildingGenerator.role(of: b) == .house {
            let id = zones?.profile(at: b.footprint.centroid)?.id ?? profile.id
            houseAreas[id, default: []].append(b.footprint.area)
        }
        let detachedGarages = Self.detachedGarages(features, context: context)
        func makeGenerator(_ p: StyleProfile) -> BuildingGenerator {
            var g = BuildingGenerator(profile: p, context: context)
            g.obstacles = buildingIndex
            g.detachedGarages = detachedGarages
            let t = p.typeThresholds.resolved(houseAreas: houseAreas[p.id] ?? [])
            if t != p.typeThresholds { g.areaThresholds = t }
            return g
        }
        let generator = makeGenerator(profile)
        // One generator per zone profile, made on first use.
        var zoneGenerators: [String: BuildingGenerator] = [profile.id: generator]
        func generatorFor(_ p: LocalPoint) -> BuildingGenerator {
            guard let zones, let zp = zones.profile(at: p) else { return generator }
            if let g = zoneGenerators[zp.id] { return g }
            let g = makeGenerator(zp)
            zoneGenerators[zp.id] = g
            return g
        }

        // Chunk grid.
        let b = features.bounds
        let nx = Int((b.width / chunkSize).rounded(.up)), ny = Int((b.height / chunkSize).rounded(.up))
        var chunks: [SIMD2<Int>: GeneratedChunk] = [:]
        for i in 0..<nx { for j in 0..<ny {
            let r = Rect2D(min: b.min + LocalPoint(Double(i), Double(j)) * chunkSize,
                           max: simd_min(b.max, b.min + LocalPoint(Double(i + 1), Double(j + 1)) * chunkSize))
            chunks[SIMD2(i, j)] = GeneratedChunk(index: SIMD2(i, j), rect: r, detail: lod == 0 && r.intersects(focus) ? .full : .simple)
        } }
        func append(_ m: MeshBuffers, feature: String, to key: SIMD2<Int>) {
            guard !m.isEmpty, chunks[key] != nil else { return }
            let start = chunks[key]!.staticMesh.vertexCount
            chunks[key]!.staticMesh.append(m)
            chunks[key]!.staticFeatures.append(FeatureRange(feature: feature, start: start, count: m.vertexCount))
        }

        var scene = GeneratedScene(palette: palette, profile: profile, season: season, clutter: ClutterField(bounds: focus))
        var instances: [PropInstance] = []

        // Buildings.
        var yardSubjects: [YardSubject] = []
        var cells: [SIMD2<Int>: BuildingCell] = [:]
        for (buildingIndex, building) in features.buildings.enumerated() where !building.isPart {
            let key = chunkIndex(building.footprint.centroid)
            guard let detail = chunks[key]?.detail else { continue }
            let buildingGenerator = generatorFor(building.footprint.centroid)
            var g = buildingGenerator.generate(building, palette: &palette, detail: detail)
            if buildingLODs {
                // Every distance LOD of this building into its cell; the detail-level result is
                // reused (near in the focus, far outside, as before) and drives yards and occluders.
                let c = b.min
                let ci = SIMD2(Int(((building.footprint.centroid.x - c.x) / buildingCellSize).rounded(.down)),
                               Int(((building.footprint.centroid.y - c.y) / buildingCellSize).rounded(.down)))
                if cells[ci] == nil {
                    let lo = c + LocalPoint(Double(ci.x), Double(ci.y)) * buildingCellSize
                    cells[ci] = BuildingCell(index: ci, rect: Rect2D(min: lo, max: lo + LocalPoint(buildingCellSize, buildingCellSize)))
                }
                let base: BuildingLOD = detail == .full ? .near : .far
                let lods: [BuildingLOD] = detail == .full ? [.near, .mid, .far, .skyline] : [.far, .skyline]
                for lod in lods {
                    let m = lod == base ? g.mesh : buildingGenerator.generate(building, palette: &palette, lod: lod).mesh
                    cells[ci]!.meshes[lod, default: MeshBuffers()].append(m)
                }
            } else {
                append(g.mesh, feature: building.ref.description, to: key)
            }
            scene.occluders.append(Occluder(hull: FootprintAnalysis.convexHull(building.footprint.outer), height: g.topHeight))
            for (k, (spot, s)) in g.bushSpots.enumerated() {
                var r = building.ref.random("bush-\(k)")
                instances.append(PropInstance(kind: r.chance(0.3) ? .flowerBush : .bush, variant: r.chance(0.5) ? 0 : 1,
                                              source: "gen:bush:\(building.ref):\(k)", x: spot.x, y: spot.y, height: 0,
                                              yaw: r.range(0, 6.28), scale: Double(s)))
            }
            g.mesh = MeshBuffers()
            yardSubjects.append(YardSubject(index: buildingIndex, building: building, generated: g))
            scene.buildings.append(g)
        }
        scene.buildingCells = cells.keys.sorted { ($0.x, $0.y) < ($1.x, $1.y) }.map { cells[$0]! }

        // Ground: base lawn per chunk.
        let n = palette.named
        for key in chunks.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            let r = chunks[key]!.rect
            var m = MeshBuffers()
            m.paint = Paint(slot: n("lawn"), flags: .lawn)
            m.addFace([P(r.min, 0), P(LocalPoint(r.max.x, r.min.y), 0), P(r.max, 0), P(LocalPoint(r.min.x, r.max.y), 0)], facing: sceneUp)
            append(m, feature: "gen:ground:\(chunks[key]!.id)", to: key)
        }
        // Areas: parks, pitches, parking, water.
        for area in features.areas {
            let style: (String, Double, Paint.Flags, Float)? = switch area.kind {
            case .park, .grass, .garden, .meadow, .recreation, .cemetery, .wood, .scrub: ("lawn", GroundLayer.park, .lawn, 0.97)
            case .pitch: ("pitch", GroundLayer.pitch, .lawn, 1)
            case .playground, .sand: ("playground", GroundLayer.pitch, [], 1)
            case .parking, .pedestrianArea: ("parking", GroundLayer.pitch, .road, 1)
            case .water, .pool: ("water", GroundLayer.water, [], 1)
            default: nil
            }
            guard let (slotName, y, flags, shade) = style else { continue }
            for key in chunks.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
                guard let clipped = Clipping.clip(area.polygon, to: chunks[key]!.rect), let clean = clipped.cleaned(minArea: 0.2),
                      var cap = Triangulator.cap(clean, y: y) else { continue }
                cap.repaint(from: 0, Paint(slot: n(slotName), shade: shade, flags: flags))
                if area.kind == .water || area.kind == .pool {
                    chunks[key]!.waterFeatures.append(FeatureRange(feature: area.ref.description, start: chunks[key]!.waterMesh.vertexCount, count: cap.vertexCount))
                    chunks[key]!.waterMesh.append(cap)
                } else {
                    append(cap, feature: area.ref.description, to: key)
                }
            }
            if area.kind == .water {
                // Shore band along the real water edge (not along chunk cuts).
                for ring in [area.polygon.outer] + area.polygon.holes {
                    addLines(ring + [ring[0]], width: 1.6, y: GroundLayer.bank, paint: Paint(slot: n("sand"), shade: 0.95),
                             feature: area.ref.description, into: &chunks)
                }
            }
        }

        // Roads, paths, sidewalks (mapped).
        for road in features.roads {
            let service = road.kind == .service || road.kind == .track
            var paint = Paint(slot: n("road"), shade: service ? 1.06 : 1, flags: .road)
            if let (slot, pattern) = Self.paving(road.tags["surface"]) {
                paint = Paint(slot: n(slot), flags: [.road, .paving], sway: pattern)
            }
            addLines(road.centerline, width: road.width, y: service ? GroundLayer.alley : GroundLayer.road,
                     paint: paint, feature: road.ref.description, into: &chunks)
        }
        for path in features.paths {
            let gravel = ["gravel", "fine_gravel", "dirt", "compacted", "ground", "unpaved"].contains(path.tags["surface"] ?? "")
            let (paint, y, w): (Paint, Double, Double) = path.isCrossing
                ? (Paint(slot: n("crossing")), GroundLayer.crossing, 2.4)
                : (gravel ? Paint(slot: n("sand")) : Self.paving(path.tags["surface"]).map { Paint(slot: n($0.slot), flags: .paving, sway: $0.pattern) }
                    ?? Paint(slot: n("sidewalk"), shade: 1.02, flags: .sidewalk), GroundLayer.path, max(1.6, path.width))
            addLines(path.centerline, width: w, y: y, paint: paint, feature: path.ref.description, into: &chunks)
        }
        for sw in features.sidewalks {
            addLines(sw.centerline, width: 1.6, y: GroundLayer.sidewalk, paint: Paint(slot: n("sidewalk"), flags: .sidewalk),
                     feature: sw.ref.description, into: &chunks)
            if lod == 0, Rect2D(enclosing: sw.centerline).intersects(focus) {
                addSidewalkEdges(sw.centerline, width: 1.6, paint: Paint(slot: n("curb")), feature: sw.ref.description, into: &chunks)
            }
        }

        // Street detail in the focus region: curbs, generated sidewalks, generated lamps.
        var lampSpots = features.points(of: .streetLamp).map(\.position)
        var generatedSidewalkMeters = 0.0, curbMeters = 0.0, generatedLamps = 0
        var generatedWalkways: [[LocalPoint]] = []
        for (i, road) in features.roads.enumerated() {
            for piece in Clipping.clip(polyline: road.centerline, to: focus) {
                for curb in streetscape.curbLines(roadIndex: i, piece: piece) where lod == 0 {
                    curbMeters += Polyline.length(curb)
                    addCurb(curb, road: road, paint: Paint(slot: n("curb")), into: &chunks)
                }
                for sw in streetscape.generatedSidewalks(roadIndex: i, piece: piece) {
                    generatedSidewalkMeters += Polyline.length(sw)
                    generatedWalkways.append(sw)
                    addLines(sw, width: 1.5, y: GroundLayer.sidewalk, paint: Paint(slot: n("sidewalk"), shade: 1.01, flags: .sidewalk),
                             feature: "gen:sidewalk:\(road.ref)", into: &chunks)
                    if lod == 0 {
                        addSidewalkEdges(sw, width: 1.5, paint: Paint(slot: n("curb")), feature: "gen:sidewalk:\(road.ref)", into: &chunks)
                    }
                    scene.clutter.blockedLines.append((sw, 1.5))
                }
                for (spot, facing) in streetscape.generatedLamps(roadIndex: i, piece: piece, existing: &lampSpots) {
                    // v2 §5: residential fixtures 5–7 m (the unit lamp is 4.3 m).
                    instances.append(PropInstance(kind: .lamp, variant: 0, source: "gen:lamp:\(road.ref):\(generatedLamps)",
                                                  x: spot.x, y: spot.y, height: 0, yaw: Double(atan2(facing.y, facing.x)), scale: 1.3))
                    generatedLamps += 1
                }
            }
        }
        for lamp in features.points(of: .streetLamp) {
            instances.append(PropInstance(kind: .lamp, variant: 0, source: lamp.ref.description, x: lamp.position.x, y: lamp.position.y,
                                          height: 0, yaw: 0, scale: 1))
        }

        // Benches: face the water if it's close, else the nearest path.
        let waterEdges = SegmentIndex(features.areas(of: .water).flatMap { [$0.polygon.outer + [$0.polygon.outer[0]]] })
        let pathIndex = SegmentIndex((features.paths + features.sidewalks).map(\.centerline))
        for bench in features.points(of: .bench) {
            let target = waterEdges.nearest(to: bench.position, within: 40)?.point ?? pathIndex.nearest(to: bench.position, within: 30)?.point
            let d = (target ?? bench.position + LocalPoint(0, 1)) - bench.position
            instances.append(PropInstance(kind: .bench, variant: 0, source: bench.ref.description, x: bench.position.x, y: bench.position.y,
                                          height: 0, yaw: atan2(d.x, -d.y), scale: 1))
        }

        // Trees: species from OSM tags, else the profile's deciduous share; crown archetype from the
        // tagged genus/species (vegetation.json genusForms), else the profile's weights; size from OSM
        // height, else the profile's ranges. Seeded by node ID.
        var conifers = 0, deciduous = 0
        let crownWeights = profile.trees.crownWeights
        let parks = features.areas(of: .park).map(\.polygon)
        for tree in features.points(of: .tree) {
            var r = tree.ref.random("tree")
            let leaf = tree.tags["leaf_type"]
            let tagged = VegetationLibrary.bundled.form(tags: tree.tags)
            let leafConifer = leaf == "needleleaved" ? true : leaf == "broadleaved" ? false : !r.chance(profile.trees.deciduousShare)
            let isConifer = tagged.map { $0 == "conifer" } ?? leafConifer
            let young = r.chance(profile.trees.youngShare)
            let height = tree.tags["height"].flatMap(TagParsing.length)
                ?? (young ? r.range(profile.trees.youngHeightMeters) : r.range(profile.trees.heightMeters))
            let kind: PropKind
            if isConifer {
                kind = .conifer
                conifers += 1
            } else {
                deciduous += 1
                let drawn = r.pick(crownWeights.keys.sorted()) { crownWeights[$0] ?? 0 }
                let pick = tagged ?? (Self.inferredWeeping(tree, profile: profile, waterEdges: waterEdges, parks: parks) ? "weeping" : drawn)
                kind = pick == "oval" ? .treeOval : pick == "spreading" ? .treeSpreading : pick == "weeping" ? .treeWeeping : .treeBroad
            }
            instances.append(PropInstance(kind: kind, variant: 0, source: tree.ref.description, x: tree.position.x, y: tree.position.y,
                                          height: 0, yaw: r.range(0, 6.28), scale: height, stretch: Self.treeStretch(tree.ref)))
            scene.clutter.blockedPoints.append(tree.position)
        }

        // Yards (inferred lots), parkway trees, litter hints.
        let yardStart = Date()
        generateYards(yardSubjects, context: context, generatedWalkways: generatedWalkways, palette: &palette, chunks: &chunks,
                      instances: &instances, scene: &scene)
        scene.stats["yardMillis"] = Int(Date().timeIntervalSince(yardStart) * 1000)

        // Soft world boundary: 12 km ground under everything, 2 cm below the chunk ground.
        var boundary = MeshBuffers()
        boundary.paint = Paint(slot: n("lawn"), shade: 0.96, flags: .lawn)
        let half = 6000.0
        boundary.addFace([P(LocalPoint(-half, -half), -0.02), P(LocalPoint(half, -half), -0.02), P(LocalPoint(half, half), -0.02),
                          P(LocalPoint(-half, half), -0.02)], facing: sceneUp)
        scene.boundaryGround = boundary

        // Lawn mask for near-camera clutter (focus region only).
        scene.clutter.rasterize(features: features, buildings: features.buildings.map(\.footprint))

        scene.palette = palette
        scene.chunks = chunks.values.sorted { ($0.index.x, $0.index.y) < ($1.index.x, $1.index.y) }
        scene.instances = instances
        scene.stats.merge([
            "generatedSidewalkMeters": Int(generatedSidewalkMeters), "curbMeters": Int(curbMeters),
            "generatedLamps": generatedLamps, "mappedLamps": features.points(of: .streetLamp).count,
            "conifers": conifers, "deciduous": deciduous,
        ]) { _, new in new }
        return scene
    }

    // MARK: - Helpers

    /// Per-tree crown proportions, so neighbouring trees of one archetype differ in outline (with the
    /// instance yaw turning their lopsided crowns): crown width ×0.88–1.14 and an oval footprint (up to
    /// 8% longer on one horizontal axis than the other). Height stays as mapped or drawn. Its own seed,
    /// so kinds, heights and yaws are unchanged.
    /// Whether an untagged mapped deciduous tree is drawn as a weeping willow: the profile's prior
    /// (`trees.weeping`; Chicago/North Shore only) near a water edge, else inside a park. Its own salt,
    /// so the tree's other draws are unchanged.
    static func inferredWeeping(_ tree: PointFeature, profile: StyleProfile, waterEdges: SegmentIndex, parks: [Polygon2D]) -> Bool {
        guard let w = profile.trees.weeping else { return false }
        var r = tree.ref.random("weeping")
        let roll = r.unit()
        if waterEdges.nearest(to: tree.position, within: w.nearWaterMeters) != nil { return roll < w.nearWaterShare }
        return parks.contains { $0.contains(tree.position) } && roll < w.parkShare
    }

    static func treeStretch(_ ref: OSMRef) -> SIMD2<Double> {
        var r = ref.random("tree-shape")
        let width = r.range(0.88, 1.14), oval = r.range(-0.08, 0.08)
        return SIMD2(width * (1 + oval), width * (1 - oval))
    }

    /// Ribbon(s) for a polyline, cut per chunk. Distance along the path continues across chunk cuts.
    func addLines(_ line: [LocalPoint], width: Double, y: Double, paint: Paint, feature: String, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        let b = Rect2D(enclosing: line).expanded(by: width)
        for key in chunks.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) where chunks[key]!.rect.intersects(b) {
            for piece in Clipping.clip(polyline: line, to: chunks[key]!.rect) {
                var m = Ribbon.build(piece, width: width, y: y)
                m.repaint(from: 0, paint)
                if let first = piece.first {
                    let offset = Float(Self.distanceAlong(line, to: first))
                    for i in m.extras.indices { m.extras[i].z += offset }
                }
                let start = chunks[key]!.staticMesh.vertexCount
                chunks[key]!.staticMesh.append(m)
                chunks[key]!.staticFeatures.append(FeatureRange(feature: feature, start: start, count: m.vertexCount))
            }
        }
    }

    /// Distance along a polyline to the point nearest `p`.
    static func distanceAlong(_ line: [LocalPoint], to p: LocalPoint) -> Double {
        var best = (dist: Double.infinity, along: 0.0)
        var acc = 0.0
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len2 = simd_length_squared(d)
            let t = len2 > 0 ? min(1, max(0, simd_dot(p - a, d) / len2)) : 0
            let q = a + d * t
            let dist = simd_distance(p, q)
            if dist < best.dist { best = (dist, acc + len2.squareRoot() * t) }
            acc += len2.squareRoot()
        }
        return best.along
    }

    /// R2: a small chamfer and side face along both edges of a raised sidewalk.
    func addSidewalkEdges(_ line: [LocalPoint], width: Double, paint: Paint, feature: String, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        guard line.count >= 2, let first = line.first, chunks[chunkIndex(first)] != nil else { return }
        var m = MeshBuffers()
        m.paint = paint
        let top = GroundLayer.sidewalk, bevel = 0.012
        for side in [-1.0, 1.0] {
            let edge = Polyline.offset(line, by: side * width / 2)
            let inner = Polyline.offset(line, by: side * (width / 2 - bevel))
            for k in 0..<(edge.count - 1) {
                let outward = D((edge[k] - inner[k]) / bevel)
                m.extra = SIMD4(1, 0, 0, 0)
                m.addFace([P(inner[k], top), P(inner[k + 1], top), P(edge[k + 1], top - bevel), P(edge[k], top - bevel)], facing: sceneUp + outward)
                m.extra = SIMD4(0.85, 0, 0, 0)
                m.addFace([P(edge[k], top - bevel), P(edge[k + 1], top - bevel), P(edge[k + 1], 0), P(edge[k], 0)], facing: outward)
            }
        }
        m.extra = SIMD4(1, 0, 0, 0)
        let key = chunkIndex(first)
        let start = chunks[key]!.staticMesh.vertexCount
        chunks[key]!.staticMesh.append(m)
        chunks[key]!.staticFeatures.append(FeatureRange(feature: feature, start: start, count: m.vertexCount))
    }

    /// A curb: a raised strip just outside the road edge, a vertical face toward the road and a
    /// small chamfer between them (R2), with contact AO at the road.
    func addCurb(_ line: [LocalPoint], road: WayFeature, paint: Paint, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        guard let first = line.first, chunks[chunkIndex(first)] != nil else { return }
        var m = MeshBuffers()
        m.paint = paint
        let top = GroundLayer.curbTop, bevel = 0.012
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            let left = LocalPoint(-d.y, d.x) / len
            let mid = (a + b) / 2
            let roadward = road.centerline.min { simd_distance($0, mid) < simd_distance($1, mid) }.map { simd_dot($0 - mid, left) > 0 ? left : -left } ?? left
            let out = -roadward * 0.18
            let inset = roadward * -bevel
            m.extra = SIMD4(1, 0, 0, 0)
            m.addFace([P(a + inset, top), P(b + inset, top), P(b + out, top), P(a + out, top)], facing: sceneUp)
            m.addFace([P(a, top - bevel), P(b, top - bevel), P(b + inset, top), P(a + inset, top)], facing: sceneUp + D(roadward))
            let i = m.positions.count
            m.addFace([P(a, GroundLayer.road), P(b, GroundLayer.road), P(b, top - bevel), P(a, top - bevel)], facing: D(roadward))
            m.bakeAO(from: i) { p, _ in p.y < 0.06 ? 0.82 : 1 }
        }
        m.extra = SIMD4(1, 0, 0, 0)
        let key = chunkIndex(first)
        let start = chunks[key]!.staticMesh.vertexCount
        chunks[key]!.staticMesh.append(m)
        chunks[key]!.staticFeatures.append(FeatureRange(feature: "gen:curb:\(road.ref)", start: start, count: m.vertexCount))
    }
}

extension simd_float4x4 {
    /// Translation × rotation about +Y × scale (`scale` on every axis, times `stretch` on x and z).
    public init(translation t: SIMD3<Float>, yaw: Float, scale s: Float, stretch: SIMD2<Float> = SIMD2(1, 1)) {
        let c = cos(yaw), si = sin(yaw)
        self.init(columns: (
            SIMD4(c * s * stretch.x, 0, -si * s * stretch.x, 0),
            SIMD4(0, s, 0, 0),
            SIMD4(si * s * stretch.y, 0, c * s * stretch.y, 0),
            SIMD4(t.x, t.y, t.z, 1)
        ))
    }
}

extension SceneGenerator {
    /// Historic paving from a mapped `surface` tag only (ground-v1 brick addendum: never inferred from a
    /// district, unknown paving keeps the regional fallback): palette slot and shader pattern ID
    /// (1 brick, 2 stone setts, 3 rounded cobble). Modern `paving_stones` keep the ordinary look.
    static func paving(_ surface: String?) -> (slot: String, pattern: Float)? {
        switch surface {
        case "bricks", "brick": return ("pavingBrick", 1)
        case "sett", "cobblestone:flattened", "stone": return ("pavingSetts", 2)
        case "cobblestone", "unhewn_cobblestone": return ("pavingCobble", 3)
        default: return nil
        }
    }
}
