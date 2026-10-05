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
}

/// Many copies of one prop mesh.
public struct PropSet: Sendable {
    public var kind: PropKind
    public var variant: Int
    /// Grouping cell (for culling): instances in one set share a cell.
    public var group: SIMD2<Int>
    public var transforms: [simd_float4x4] = []
}

/// An axis-aligned building box for camera collision (local footprint hull + height).
public struct Occluder: Sendable {
    public var hull: [LocalPoint]
    public var height: Double
}

public struct GeneratedScene: Sendable {
    public var palette: Palette
    public var profile: StyleProfile
    public var chunks: [GeneratedChunk] = []
    public var props: [PropSet] = []
    public var occluders: [Occluder] = []
    public var buildings: [GeneratedBuilding] = []
    public var clutter: ClutterField
    public var stats: [String: Int] = [:]
}

public struct SceneGenerator: Sendable {
    public var features: MapFeatures
    public var profile: StyleProfile
    public var baseColors: [String: String]
    /// Region that gets full street-level detail; everything else is simple context.
    public var focus: Rect2D
    public var chunkSize = 200.0

    public init(features: MapFeatures, profile: StyleProfile, baseColors: [String: String], focus: Rect2D) {
        self.features = features
        self.profile = profile
        self.baseColors = baseColors
        self.focus = focus
    }

    func chunkIndex(_ p: LocalPoint) -> SIMD2<Int> {
        SIMD2(Int(((p.x - features.bounds.min.x) / chunkSize).rounded(.down)),
              Int(((p.y - features.bounds.min.y) / chunkSize).rounded(.down)))
    }

    public func generate() -> GeneratedScene {
        var palette = Palette(base: baseColors)
        let context = StreetContext(features)
        let buildingIndex = PolygonIndex(features.buildings.map(\.footprint))
        let streetscape = Streetscape(context: context, buildings: buildingIndex)
        let generator = BuildingGenerator(profile: profile, context: context)

        // Chunk grid.
        let b = features.bounds
        let nx = Int((b.width / chunkSize).rounded(.up)), ny = Int((b.height / chunkSize).rounded(.up))
        var chunks: [SIMD2<Int>: GeneratedChunk] = [:]
        for i in 0..<nx { for j in 0..<ny {
            let r = Rect2D(min: b.min + LocalPoint(Double(i), Double(j)) * chunkSize,
                           max: simd_min(b.max, b.min + LocalPoint(Double(i + 1), Double(j + 1)) * chunkSize))
            chunks[SIMD2(i, j)] = GeneratedChunk(index: SIMD2(i, j), rect: r, detail: r.intersects(focus) ? .full : .simple)
        } }
        func isFull(_ p: LocalPoint) -> Bool { chunks[chunkIndex(p)]?.detail == .full }

        var scene = GeneratedScene(palette: palette, profile: profile, clutter: ClutterField(bounds: focus))
        var props: [String: PropSet] = [:]
        func addProp(_ kind: PropKind, _ variant: Int, at p: LocalPoint, yaw: Double, scale: Float, y: Double = 0) {
            let group = isFull(p) ? SIMD2(-1, -1) : SIMD2(Int((p.x - b.min.x) / 800), Int((p.y - b.min.y) / 600))
            let key = "\(kind.rawValue)/\(variant)/\(group.x),\(group.y)"
            let t = simd_float4x4(translation: LocalFrame.scenePosition(p, y: y), yaw: Float(yaw), scale: scale)
            props[key, default: PropSet(kind: kind, variant: variant, group: group)].transforms.append(t)
        }

        // Buildings.
        for building in features.buildings where !building.isPart {
            let c = building.footprint.centroid
            guard let key = Optional(chunkIndex(c)), let detail = chunks[key]?.detail else { continue }
            var g = generator.generate(building, palette: &palette, detail: detail)
            chunks[key]!.staticMesh.append(g.mesh)
            scene.occluders.append(Occluder(hull: FootprintAnalysis.convexHull(building.footprint.outer), height: g.topHeight))
            for (spot, s) in g.bushSpots {
                var r = building.ref.random("bush-\(spot.x)")
                addProp(r.chance(0.3) ? .flowerBush : .bush, r.chance(0.5) ? 0 : 1, at: spot, yaw: r.range(0, 6.28), scale: s)
            }
            g.mesh = MeshBuffers()
            scene.buildings.append(g)
        }

        // Ground: base, areas, water.
        let n = palette.named
        for key in chunks.keys {
            let r = chunks[key]!.rect
            var m = MeshBuffers()
            m.paint = Paint(slot: n("lawn"))
            m.addFace([P(r.min, 0), P(LocalPoint(r.max.x, r.min.y), 0), P(r.max, 0), P(LocalPoint(r.min.x, r.max.y), 0)], facing: sceneUp)
            chunks[key]!.staticMesh.append(m)
        }
        for area in features.areas {
            let style: (String, Double)? = switch area.kind {
            case .park, .grass, .garden, .meadow, .recreation, .cemetery: ("parkGrass", GroundLayer.park)
            case .pitch: ("pitch", GroundLayer.pitch)
            case .playground, .sand: ("playground", GroundLayer.pitch)
            case .parking, .pedestrianArea: ("parking", GroundLayer.pitch)
            case .wood, .scrub: ("parkGrass", GroundLayer.park)
            case .water, .pool: ("water", GroundLayer.water)
            default: nil
            }
            guard let (slotName, y) = style else { continue }
            for key in chunks.keys {
                guard let clipped = Clipping.clip(area.polygon, to: chunks[key]!.rect), let clean = clipped.cleaned(minArea: 0.2),
                      var cap = Triangulator.cap(clean, y: y) else { continue }
                cap.repaint(from: 0, Paint(slot: n(slotName), shade: area.kind == .wood ? 0.9 : 1))
                if area.kind == .water || area.kind == .pool { chunks[key]!.waterMesh.append(cap) } else { chunks[key]!.staticMesh.append(cap) }
            }
            if area.kind == .water {
                // Shore band along the real water edge (not along chunk cuts).
                for ring in [area.polygon.outer] + area.polygon.holes {
                    addLines(ring + [ring[0]], width: 1.6, y: GroundLayer.bank, paint: Paint(slot: n("bank")), into: &chunks)
                }
            }
        }

        // Roads, paths, sidewalks (mapped).
        for road in features.roads {
            let service = road.kind == .service || road.kind == .track
            addLines(road.centerline, width: road.width, y: service ? GroundLayer.alley : GroundLayer.road,
                     paint: Paint(slot: n(service ? "alley" : "asphalt")), into: &chunks)
        }
        for path in features.paths {
            let gravel = ["gravel", "fine_gravel", "dirt", "compacted", "ground", "unpaved"].contains(path.tags["surface"] ?? "")
            let (slot, y, w) = path.isCrossing
                ? ("crossing", GroundLayer.crossing, 2.4)
                : (gravel ? "trailGravel" : "trailConcrete", GroundLayer.path, max(1.6, path.width))
            addLines(path.centerline, width: w, y: y, paint: Paint(slot: n(slot)), into: &chunks)
        }
        for sw in features.sidewalks {
            addLines(sw.centerline, width: 1.6, y: GroundLayer.sidewalk, paint: Paint(slot: n("concrete")), into: &chunks)
        }

        // Street detail in the focus region: curbs, generated sidewalks, generated lamps.
        var lampSpots = features.points(of: .streetLamp).map(\.position)
        var generatedSidewalkMeters = 0.0, curbMeters = 0.0, generatedLamps = 0
        for (i, road) in features.roads.enumerated() {
            for piece in Clipping.clip(polyline: road.centerline, to: focus) {
                for curb in streetscape.curbLines(roadIndex: i, piece: piece) {
                    curbMeters += Polyline.length(curb)
                    addCurb(curb, roadSide: road, paint: Paint(slot: n("curb")), into: &chunks)
                }
                for sw in streetscape.generatedSidewalks(roadIndex: i, piece: piece) {
                    generatedSidewalkMeters += Polyline.length(sw)
                    addLines(sw, width: 1.5, y: GroundLayer.sidewalk, paint: Paint(slot: n("concrete"), shade: 1.03), into: &chunks)
                    scene.clutter.blockedLines.append((sw, 1.5))
                }
                for (spot, facing) in streetscape.generatedLamps(roadIndex: i, piece: piece, existing: &lampSpots) {
                    addProp(.lamp, 0, at: spot, yaw: atan2(facing.y, facing.x), scale: 1)
                    generatedLamps += 1
                }
            }
        }
        for lamp in features.points(of: .streetLamp) { addProp(.lamp, 0, at: lamp.position, yaw: 0, scale: 1) }

        // Benches: face the water if it's close, else the nearest path.
        let waterEdges = SegmentIndex(features.areas(of: .water).flatMap { [$0.polygon.outer + [$0.polygon.outer[0]]] })
        let pathIndex = SegmentIndex((features.paths + features.sidewalks).map(\.centerline))
        for bench in features.points(of: .bench) {
            let target = waterEdges.nearest(to: bench.position, within: 40)?.point ?? pathIndex.nearest(to: bench.position, within: 30)?.point
            let d = (target ?? bench.position + LocalPoint(0, 1)) - bench.position
            // Bench front is +Z in object space; yaw rotates +Z toward d (scene: north = −Z).
            addProp(.bench, 0, at: bench.position, yaw: atan2(d.x, -d.y), scale: 1)
        }

        // Trees: species from OSM tags, else the profile's deciduous share (seeded by node ID).
        var conifers = 0, deciduous = 0
        for tree in features.points(of: .tree) {
            var r = tree.ref.random("tree")
            let leaf = tree.tags["leaf_type"]
            let isConifer = leaf == "needleleaved" ? true : leaf == "broadleaved" ? false : !r.chance(profile.trees.deciduousShare)
            let height = tree.tags["height"].flatMap(TagParsing.length) ?? (isConifer ? r.range(8, 14) : r.range(7, 12.5))
            if isConifer { conifers += 1 } else { deciduous += 1 }
            if isFull(tree.position) {
                addProp(isConifer ? .conifer : .deciduousTree, Int(r.next() % UInt64(PropLibrary.variants[isConifer ? .conifer : .deciduousTree]!)),
                        at: tree.position, yaw: r.range(0, 6.28), scale: Float(height))
            } else {
                addProp(.lowTree, isConifer ? 1 : 0, at: tree.position, yaw: r.range(0, 6.28), scale: Float(height))
            }
            scene.clutter.blockedPoints.append(tree.position)
        }

        // Lawn mask for near-camera clutter (focus region only).
        scene.clutter.rasterize(features: features, buildings: features.buildings.map(\.footprint))

        scene.palette = palette
        scene.chunks = chunks.values.sorted { ($0.index.x, $0.index.y) < ($1.index.x, $1.index.y) }
        scene.props = props.keys.sorted().map { props[$0]! }
        scene.stats = [
            "generatedSidewalkMeters": Int(generatedSidewalkMeters), "curbMeters": Int(curbMeters),
            "generatedLamps": generatedLamps, "mappedLamps": features.points(of: .streetLamp).count,
            "conifers": conifers, "deciduous": deciduous,
        ]
        return scene
    }

    // MARK: - Helpers

    /// Ribbon(s) for a polyline, cut per chunk.
    func addLines(_ line: [LocalPoint], width: Double, y: Double, paint: Paint, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        let b = Rect2D(enclosing: line).expanded(by: width)
        for key in chunks.keys where chunks[key]!.rect.intersects(b) {
            for piece in Clipping.clip(polyline: line, to: chunks[key]!.rect) {
                var m = Ribbon.build(piece, width: width, y: y)
                m.repaint(from: 0, paint)
                chunks[key]!.staticMesh.append(m)
            }
        }
    }

    /// A curb: a raised strip just outside the road edge with a vertical face toward the road.
    func addCurb(_ line: [LocalPoint], roadSide road: WayFeature, paint: Paint, into chunks: inout [SIMD2<Int>: GeneratedChunk]) {
        guard let first = line.first, let key = Optional(chunkIndex(first)), chunks[key] != nil else { return }
        var m = MeshBuffers()
        m.paint = paint
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len = simd_length(d)
            guard len > 1e-6 else { continue }
            let left = LocalPoint(-d.y, d.x) / len
            let mid = (a + b) / 2
            let roadward = road.centerline.min { simd_distance($0, mid) < simd_distance($1, mid) }.map { simd_dot($0 - mid, left) > 0 ? left : -left } ?? left
            let out = -roadward * 0.18
            m.addFace([P(a, GroundLayer.curbTop), P(b, GroundLayer.curbTop), P(b + out, GroundLayer.curbTop), P(a + out, GroundLayer.curbTop)], facing: sceneUp)
            m.addFace([P(a, GroundLayer.road), P(b, GroundLayer.road), P(b, GroundLayer.curbTop), P(a, GroundLayer.curbTop)], facing: D(roadward))
        }
        chunks[key]!.staticMesh.append(m)
    }
}

extension simd_float4x4 {
    /// Translation × rotation about +Y × uniform scale.
    public init(translation t: SIMD3<Float>, yaw: Float, scale s: Float) {
        let c = cos(yaw), si = sin(yaw)
        self.init(columns: (
            SIMD4(c * s, 0, -si * s, 0),
            SIMD4(0, s, 0, 0),
            SIMD4(si * s, 0, c * s, 0),
            SIMD4(t.x, t.y, t.z, 1)
        ))
    }
}
