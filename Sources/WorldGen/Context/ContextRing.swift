import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

// Context ring (look-fix-v1 §4 "real ground continuation with a bounded context fade"): low-detail
// real ground around an area, from the area's "context" OSM layer (docs/data/context-rings.md),
// drawn outside the area box only. Land use as flat palette colour masses, water, roads and rail as
// flat ribbons, real buildings near the box, and a fade into the seasonal backdrop at the edge of
// coverage. Nothing is invented: ground without data is the backdrop plain under the world.

/// Detail level of one context cell, chosen per cell from the camera (`pick`).
public enum ContextLOD: Int, Sendable, CaseIterable, Comparable, Codable {
    /// Camera close to the cell: first-row buildings as skyline masses, the rest of the transition
    /// ring as roof slabs, every street.
    case near
    /// Camera looking down steeply (aerial): roof slabs and tall masses, streets within reach.
    case aerial
    /// Low camera further away (street level): tall masses, main roads and large areas only.
    case street
    /// Far from the camera: large areas, motorway to secondary roads, rail and rivers.
    case far

    public static func < (a: ContextLOD, b: ContextLOD) -> Bool { a.rawValue < b.rawValue }

    /// The level for a camera at `eye` (local east, north metres; z = height above the ground)
    /// and a cell: by the 3D distance to the cell's nearest ground point and how steeply the camera
    /// looks down on that point.
    public static func pick(eye: SIMD3<Double>, cell: Rect2D, settings s: ContextSettings) -> ContextLOD {
        let p = LocalPoint(eye.x, eye.y)
        let horizontal = simd_distance(p, simd_clamp(p, cell.min, cell.max))
        let h = max(eye.z, 0)
        let d = (horizontal * horizontal + h * h).squareRoot()
        let steep = h >= s.steepMinHeight && atan2(h, horizontal) >= s.steepAngleDegrees * .pi / 180
        if d < (steep ? s.nearDistanceSteep : s.nearDistance) { return .near }
        if steep { return d < s.aerialDistance ? .aerial : .far }
        return d < s.streetDistance ? .street : .far
    }
}

/// Context-ring rules (metres unless noted). Defaults are the shipped look; tests may vary them.
public struct ContextSettings: Sendable, Equatable {
    /// Cells: one ring of about this depth around the area box (the box span split near this size),
    /// then 4 corner cells and 4 side strips to the edge of coverage.
    public var innerCell = 1000.0
    /// Low buildings are drawn when their centroid is within this distance of the area box
    /// (look-fix-v1 §4: a 150–300 m real-data transition ring).
    public var transitionWidth = 300.0
    /// Low buildings this close to the box are skyline masses at `near` (the first row seen from
    /// the street); the rest of the transition ring is roof slabs.
    public var firstRowWidth = 100.0
    /// Buildings at least this tall (top, m) or this large (footprint, m²) are drawn anywhere in
    /// the data's building band (they rise over the near rows).
    public var tallHeight = 15.0
    public var tallFootprint = 1500.0
    /// Coverage fade into the backdrop inside the edge of coverage (look-fix-v1 §4: 150–250 m).
    public var fadeWidth = 200.0
    /// Level switching (see `ContextLOD.pick`).
    public var nearDistance = 450.0
    public var nearDistanceSteep = 700.0
    public var aerialDistance = 2500.0
    public var streetDistance = 2600.0
    public var steepAngleDegrees = 20.0
    public var steepMinHeight = 30.0

    /// Ground detail per level.
    public struct Detail: Sendable, Equatable {
        /// Douglas–Peucker tolerances for area outlines and centrelines.
        public var areaTolerance: Double
        public var roadTolerance: Double
        /// Areas smaller than this (whole feature, m²) are left out.
        public var minArea: Double
        /// Residential streets (within `minorReach`), and alleys too (4 m: a pixel from the air).
        public var minorRoads: Bool
        public var alleys: Bool
        /// Residential streets and alleys beyond this distance from the area box are dropped.
        public var minorReach: Double
        /// Tertiary roads and link roads (motorway to secondary always).
        public var tertiaryAndLinks: Bool
        /// Rail yards and sidings.
        public var railYards: Bool
    }

    public var detail: [Detail] = [
        Detail(areaTolerance: 3, roadTolerance: 1.5, minArea: 3000, minorRoads: true, alleys: true, minorReach: 1500, tertiaryAndLinks: true, railYards: true),      // near
        Detail(areaTolerance: 6, roadTolerance: 5, minArea: 8000, minorRoads: true, alleys: false, minorReach: 400, tertiaryAndLinks: true, railYards: false),      // aerial
        Detail(areaTolerance: 6, roadTolerance: 4, minArea: 6000, minorRoads: false, alleys: false, minorReach: 0, tertiaryAndLinks: true, railYards: false),   // street
        Detail(areaTolerance: 10, roadTolerance: 8, minArea: 20000, minorRoads: false, alleys: false, minorReach: 0, tertiaryAndLinks: false, railYards: false), // far
    ]
    /// Low buildings smaller than this (m², garages and sheds) are left out of roof slabs.
    public var minSlabFootprint = 40.0
    /// At the aerial level, low buildings get roof slabs only this close to the area box; beyond it
    /// the land-use colour shows (from the air a field of grey roof quads flattened the ring). The
    /// near level keeps them across the transition ring.
    public var aerialSlabWidth = 100.0
    /// Water (one mesh for the ring, no levels).
    public var waterTolerance = 3.0
    public var minWaterArea = 200.0

    public init() {}
}

/// One context cell: a rectangle outside the area box with one mesh per `ContextLOD`.
public struct ContextCell: Sendable {
    public var index: SIMD2<Int>
    public var rect: Rect2D
    /// Indexed by `ContextLOD.rawValue` (static material; may be empty).
    public var meshes: [MeshBuffers]
    public var id: String { "\(index.x)_\(index.y)" }
    public func mesh(_ lod: ContextLOD) -> MeshBuffers { meshes[lod.rawValue] }
}

/// A generated context ring.
public struct ContextScene: Sendable {
    /// The edge of coverage (local metres) and the area box it surrounds.
    public var coverage: Rect2D
    public var core: Rect2D
    public var settings: ContextSettings
    public var cells: [ContextCell] = []
    /// Lakes, rivers and waterways of the whole ring (water material, no levels).
    public var water = MeshBuffers()
    /// The input palette plus any colours the ring's buildings added (existing slots unchanged).
    public var palette: Palette
    public var stats: [String: Int] = [:]
}

public struct ContextRingInput: Sendable {
    public var frame: LocalFrame
    public var core: Rect2D
    public var coverage: Rect2D
    /// The detailed world's palette (seasonal slots first; buildings may add colours).
    public var palette: Palette
    public var profile: StyleProfile
    /// Per-building zone profiles; nil = `profile` for every building (an explicit profile override).
    public var zones: ZoneProfiles?
    public var settings = ContextSettings()

    public init(frame: LocalFrame, core: Rect2D, coverage: Rect2D, palette: Palette, profile: StyleProfile, zones: ZoneProfiles?) {
        self.frame = frame
        self.core = core
        self.coverage = coverage
        self.palette = palette
        self.profile = profile
        self.zones = zones
    }
}

public enum ContextRing {
    /// The context sources' box in local metres (the inner rectangle of its projected corners), or
    /// nil when the area has no context layer.
    public static func coverage(of manifest: AreaManifest) -> Rect2D? {
        guard let b = manifest.contextBounds else { return nil }
        let f = manifest.frame
        let sw = f.localPoint(of: GeoCoordinate(latitude: b.south, longitude: b.west))
        let se = f.localPoint(of: GeoCoordinate(latitude: b.south, longitude: b.east))
        let nw = f.localPoint(of: GeoCoordinate(latitude: b.north, longitude: b.west))
        let ne = f.localPoint(of: GeoCoordinate(latitude: b.north, longitude: b.east))
        let r = Rect2D(min: LocalPoint(max(sw.x, nw.x), max(sw.y, se.y)), max: LocalPoint(min(se.x, ne.x), min(nw.y, ne.y)))
        return r.width > 0 && r.height > 0 ? r : nil
    }

    /// Zone profiles for every region touching `box` (local metres) plus the catalog default.
    public static func zones(frame: LocalFrame, box: Rect2D) throws -> ZoneProfiles {
        let catalog = try StyleLibrary.regions()
        let sw = frame.coordinate(at: box.min), ne = frame.coordinate(at: box.max)
        var ids: Set<String> = [catalog.defaultProfile]
        for r in catalog.regions where r.bounds.south <= ne.latitude && r.bounds.north >= sw.latitude
            && r.bounds.west <= ne.longitude && r.bounds.east >= sw.longitude { ids.insert(r.profile) }
        var profiles: [String: StyleProfile] = [:]
        for id in ids.sorted() { profiles[id] = try StyleLibrary.profile(id: id) }
        return ZoneProfiles(catalog: catalog, profiles: profiles, frame: frame)
    }

    /// Loads the area's context layer and generates the ring (nil without a context layer).
    /// Returns the seconds spent parsing and generating.
    public static func build(areaDirectory: URL, manifest: AreaManifest, palette: Palette, profile: StyleProfile,
                             zonesByLocation: Bool, settings: ContextSettings = .init()) throws
        -> (scene: ContextScene, parseSeconds: Double, generateSeconds: Double)? {
        guard let coverage = coverage(of: manifest) else { return nil }
        let t0 = Date()
        guard let doc = try AreaLoader.loadContextDocument(areaDirectory, manifest: manifest) else { return nil }
        let t1 = Date()
        var input = ContextRingInput(frame: manifest.frame, core: manifest.localBounds, coverage: coverage, palette: palette,
                                     profile: profile, zones: zonesByLocation ? try zones(frame: manifest.frame, box: coverage) : nil)
        input.settings = settings
        let scene = generate(doc, input: input)
        return (scene, t1.timeIntervalSince(t0), Date().timeIntervalSince(t1))
    }

    /// Cells: a ring about `innerCell` deep around the area box (its span split near that size),
    /// then corner cells and side strips to the edge of coverage. None overlaps the box.
    public static func cellRects(core: Rect2D, coverage: Rect2D, inner: Double) -> [(SIMD2<Int>, Rect2D)] {
        func axis(_ lo: Double, _ hi: Double, _ clo: Double, _ chi: Double) -> [Double] {
            var e = [lo]
            let i0 = max(lo, clo - inner), i1 = min(hi, chi + inner)
            if i0 > lo + 1 { e.append(i0) }
            if clo > e.last! + 1 { e.append(clo) }
            let n = max(1, Int(((chi - clo) / inner).rounded()))
            for k in 1..<n { e.append(clo + (chi - clo) * Double(k) / Double(n)) }
            e.append(chi)
            if i1 > chi + 1 { e.append(i1) }
            if hi > e.last! + 1 { e.append(hi) }
            return e
        }
        let xs = axis(coverage.min.x, coverage.max.x, core.min.x, core.max.x)
        let ys = axis(coverage.min.y, coverage.max.y, core.min.y, core.max.y)
        let ix0 = max(coverage.min.x, core.min.x - inner), ix1 = min(coverage.max.x, core.max.x + inner)
        let iy0 = max(coverage.min.y, core.min.y - inner), iy1 = min(coverage.max.y, core.max.y + inner)
        var out: [(SIMD2<Int>, Rect2D)] = []
        // Inner ring: grid cells between ix0…ix1 and iy0…iy1, outside the box.
        for i in 0..<(xs.count - 1) where xs[i] >= ix0 - 1e-6 && xs[i + 1] <= ix1 + 1e-6 {
            for j in 0..<(ys.count - 1) where ys[j] >= iy0 - 1e-6 && ys[j + 1] <= iy1 + 1e-6 {
                let r = Rect2D(min: LocalPoint(xs[i], ys[j]), max: LocalPoint(xs[i + 1], ys[j + 1]))
                let c = (r.min + r.max) / 2
                if core.contains(c) { continue }
                out.append((SIMD2(i, j), r))
            }
        }
        // Outer ring: corners and side strips.
        let xb = [coverage.min.x, ix0, ix1, coverage.max.x], yb = [coverage.min.y, iy0, iy1, coverage.max.y]
        for i in 0..<3 {
            for j in 0..<3 where !(i == 1 && j == 1) {
                let r = Rect2D(min: LocalPoint(xb[i], yb[j]), max: LocalPoint(xb[i + 1], yb[j + 1]))
                guard r.width > 1, r.height > 1 else { continue }
                out.append((SIMD2(100 + i, 100 + j), r))
            }
        }
        return out
    }

    /// Distance from a point to the area box (0 inside).
    static func distance(_ p: LocalPoint, to r: Rect2D) -> Double {
        simd_distance(p, simd_clamp(p, r.min, r.max))
    }

    /// Distance from a point inside the coverage box to its edge.
    static func edgeDistance(_ p: LocalPoint, _ r: Rect2D) -> Double {
        min(p.x - r.min.x, r.max.x - p.x, p.y - r.min.y, r.max.y - p.y)
    }

    /// The coverage fade the shader applies (WorldShaders.metal, context ring block), for tests and
    /// offline renders: 1 = backdrop colour at the edge of coverage, 0 from `width` inside it.
    public static func fadeWeight(at p: LocalPoint, coverage r: Rect2D, width: Double) -> Double {
        let d = edgeDistance(p, r)
        let t = min(1, max(0, d / max(width, 1)))
        return 1 - t * t * (3 - 2 * t)
    }

    /// Douglas–Peucker on a closed ring (split at the point farthest from the first).
    static func simplify(ring r: Ring, tolerance: Double) -> Ring {
        guard r.count > 4, tolerance > 0 else { return r }
        let far = r.indices.max { simd_distance(r[0], r[$0]) < simd_distance(r[0], r[$1]) }!
        guard far > 0 else { return r }
        let a = Polyline.simplify(Array(r[0...far]), tolerance: tolerance)
        let b = Polyline.simplify(Array(r[far...]) + [r[0]], tolerance: tolerance)
        let out = a + b.dropFirst().dropLast()
        return out.count >= 3 ? out : r
    }

    /// Douglas–Peucker that keeps every vertex in `pins` (road junctions), so streets that met
    /// still meet after simplification.
    static func simplify(line l: [LocalPoint], tolerance: Double, pins: Set<SIMD2<UInt64>>) -> [LocalPoint] {
        guard l.count > 2 else { return l }
        var out: [LocalPoint] = [l[0]]
        var start = 0
        for k in 1..<l.count where k == l.count - 1 || pins.contains(key(l[k])) {
            out += Polyline.simplify(Array(l[start...k]), tolerance: tolerance).dropFirst()
            start = k
        }
        return out
    }

    static func key(_ p: LocalPoint) -> SIMD2<UInt64> { SIMD2(p.x.bitPattern, p.y.bitPattern) }

    /// Real junctions among `lines`: a vertex used three or more times, or by two lines where it
    /// is inside at least one of them. (Two lines merely continuing each other are not pinned.)
    static func junctions(_ lines: [ContextLine]) -> Set<SIMD2<UInt64>> {
        var count: [SIMD2<UInt64>: Int] = [:], interior = Set<SIMD2<UInt64>>()
        for l in lines {
            for (i, p) in l.points.enumerated() {
                let k = key(p)
                count[k, default: 0] += 1
                if i > 0 && i < l.points.count - 1 { interior.insert(k) }
            }
        }
        return Set(count.filter { $0.value >= 3 || ($0.value == 2 && interior.contains($0.key)) }.map(\.key))
    }

    /// Joins lines of the same kind and width end to end where exactly two of them meet at an
    /// unpinned vertex.
    static func mergeContinuations(_ lines: [ContextLine], pins: Set<SIMD2<UInt64>>) -> [ContextLine] {
        var ends: [SIMD2<UInt64>: [Int]] = [:]
        for (i, l) in lines.enumerated() where l.points.count >= 2 {
            ends[key(l.points[0]), default: []].append(i)
            ends[key(l.points[l.points.count - 1]), default: []].append(i)
        }
        var used = [Bool](repeating: false, count: lines.count)
        var out: [ContextLine] = []
        func partner(_ k: SIMD2<UInt64>, of i: Int) -> Int? {
            guard !pins.contains(k), let e = ends[k], e.count == 2 else { return nil }
            let j = e[0] == i ? e[1] : e[0]
            guard j != i, !used[j], lines[j].kind == lines[i].kind, lines[j].width == lines[i].width else { return nil }
            return j
        }
        for i in lines.indices where !used[i] {
            used[i] = true
            var line = lines[i]
            guard line.points.count >= 2 else { out.append(line); continue }
            var cur = i
            while let j = partner(key(line.points.last!), of: cur) {
                used[j] = true
                cur = j
                let q = lines[j].points
                line.points += (key(q[0]) == key(line.points.last!) ? q : q.reversed()).dropFirst()
            }
            cur = i
            while let j = partner(key(line.points[0]), of: cur) {
                used[j] = true
                cur = j
                let q = lines[j].points
                line.points = (key(q[q.count - 1]) == key(line.points[0]) ? q : q.reversed()) + line.points.dropFirst()
            }
            out.append(line)
        }
        return out
    }

    // MARK: - Generation

    public static func generate(_ doc: OSMDocument, input: ContextRingInput) -> ContextScene {
        let s = input.settings
        let data = ContextData(document: doc, frame: input.frame, coverage: input.coverage, core: input.core)
        var scene = ContextScene(coverage: input.coverage, core: input.core, settings: s, palette: input.palette, stats: data.stats)
        var palette = input.palette
        let cov = input.coverage, core = input.core
        let box = SIMD4<Float>(Float(cov.min.x), Float(-cov.max.y), Float(cov.max.x), Float(-cov.min.y))
        func paint(_ slot: String, _ shade: Float, _ flags: Paint.Flags) -> Paint {
            Paint(slot: palette.named(slot), shade: shade, flags: flags.union(.coverageFade), sway: Float(s.fadeWidth))
        }
        /// Marks vertices from `start` on as coverage-faded context ground.
        func fade(_ m: inout MeshBuffers, from start: Int, _ p: Paint) {
            for i in start..<m.vertexCount { m.paints[i] = p.packed; m.extras[i] = box }
        }

        let layout = cellRects(core: core, coverage: cov, inner: s.innerCell)
        var cells = layout.map { ContextCell(index: $0.0, rect: $0.1, meshes: Array(repeating: MeshBuffers(), count: ContextLOD.allCases.count)) }

        // Areas: simplified once per tolerance, then clipped to cells (cells meet exactly).
        var skipped = 0
        let detail = s.detail
        var tally: [String: Int] = [:]
        /// Appends to a cell level and tallies triangles by kind (`tri.<level>.<kind>` stats).
        func put(_ m: MeshBuffers, _ c: Int, _ lod: ContextLOD, _ kind: String) {
            cells[c].meshes[lod.rawValue].append(m)
            tally["tri.\(lod).\(kind)", default: 0] += m.triangleCount
        }
        for area in data.areas {
            let style = area.surface.style
            let p = paint(style.slot, style.shade, style.flags)
            let wholeArea = area.polygon.area
            var simplified: [Double: Polygon2D] = [:]
            for lod in ContextLOD.allCases {
                let d = detail[lod.rawValue]
                guard wholeArea >= d.minArea else { continue }
                let poly: Polygon2D
                if let cached = simplified[d.areaTolerance] {
                    poly = cached
                } else {
                    poly = Polygon2D(outer: simplify(ring: area.polygon.outer, tolerance: d.areaTolerance),
                                     holes: area.polygon.holes.map { simplify(ring: $0, tolerance: d.areaTolerance) })
                    simplified[d.areaTolerance] = poly
                }
                let bounds = poly.bounds
                for c in cells.indices where cells[c].rect.intersects(bounds) {
                    guard let clipped = Clipping.clip(poly, to: cells[c].rect), let clean = clipped.cleaned(minArea: 0.5) else { continue }
                    var cap = Triangulator.cap(clean, y: style.y)
                    if cap == nil, let raw = Clipping.clip(area.polygon, to: cells[c].rect)?.cleaned(minArea: 0.5) { cap = Triangulator.cap(raw, y: style.y) }
                    guard var m = cap else { skipped += 1; continue }
                    fade(&m, from: 0, p)
                    put(m, c, lod, "area")
                }
            }
        }

        // Roads and rail, per level: the lines drawn at that level, joined where one way simply
        // continues another (so Douglas–Peucker can straighten across), with real junctions pinned
        // (streets that met still meet), simplified, clipped per cell.
        let roadPaint = paint("road", 1, .road), alleyPaint = paint("road", 1.06, .road), railPaint = paint("ground", 0.78, [])
        for lod in ContextLOD.allCases {
            let d = detail[lod.rawValue]
            let roads = data.roads.filter { r in
                switch r.kind {
                case .main: true
                case .mainLink: d.tertiaryAndLinks
                case .minor: d.minorRoads
                case .alley: d.alleys
                default: false
                }
            }
            let rails = data.rails.filter { $0.kind == .rail || d.railYards }
            for (group, lines) in [("road", roads), ("rail", rails)] {
                let pins = junctions(lines)
                for line in mergeContinuations(lines, pins: pins) {
                    let minor = line.kind == .minor || line.kind == .alley
                    let simple = simplify(line: line.points, tolerance: d.roadTolerance, pins: pins)
                    let b = Rect2D(enclosing: simple).expanded(by: line.width)
                    let y = group == "rail" ? 0.032 : line.kind == .alley ? 0.035 : 0.04
                    let p = group == "rail" ? railPaint : line.kind == .alley ? alleyPaint : roadPaint
                    let kind = group == "rail" ? "rail" : minor ? "minor" : "main"
                    for c in cells.indices where cells[c].rect.intersects(b) {
                        for piece in Clipping.clip(polyline: simple, to: cells[c].rect) {
                            if minor, distance(piece[piece.count / 2], to: core) > d.minorReach { continue }
                            var m = Ribbon.build(piece, width: line.width, y: y)
                            guard !m.isEmpty else { continue }
                            fade(&m, from: 0, p)
                            put(m, c, lod, kind)
                        }
                    }
                }
            }
        }

        // Water: one mesh for the ring, outside the area box (four strips).
        let strips = [
            Rect2D(min: cov.min, max: LocalPoint(cov.max.x, core.min.y)),
            Rect2D(min: LocalPoint(cov.min.x, core.max.y), max: cov.max),
            Rect2D(min: LocalPoint(cov.min.x, core.min.y), max: LocalPoint(core.min.x, core.max.y)),
            Rect2D(min: LocalPoint(core.max.x, core.min.y), max: LocalPoint(cov.max.x, core.max.y)),
        ].filter { $0.width > 0.5 && $0.height > 0.5 }
        let waterPaint = paint("water", 1, [])
        for poly in data.water where poly.area >= s.minWaterArea {
            let simple = Polygon2D(outer: simplify(ring: poly.outer, tolerance: s.waterTolerance),
                                   holes: poly.holes.map { simplify(ring: $0, tolerance: s.waterTolerance) })
            for r in strips where r.intersects(simple.bounds) {
                guard let clean = Clipping.clip(simple, to: r)?.cleaned(minArea: 0.5) else { continue }
                var cap = Triangulator.cap(clean, y: ContextSurface.water.style.y)
                if cap == nil, let raw = Clipping.clip(poly, to: r)?.cleaned(minArea: 0.5) { cap = Triangulator.cap(raw, y: ContextSurface.water.style.y) }
                guard var m = cap else { skipped += 1; continue }
                fade(&m, from: 0, waterPaint)
                scene.water.append(m)
            }
        }
        for w in data.waterways {
            let simple = Polyline.simplify(w.points, tolerance: s.waterTolerance)
            for r in strips {
                for piece in Clipping.clip(polyline: simple, to: r) {
                    var m = Ribbon.build(piece, width: w.width, y: 0.028)
                    guard !m.isEmpty else { continue }
                    fade(&m, from: 0, waterPaint)
                    scene.water.append(m)
                }
            }
        }

        // Buildings: P2's generator at the skyline level (public API). Low buildings in the
        // transition ring; tall ones anywhere in the data's band; none in the fade zone.
        let houses = Dictionary(grouping: data.buildings.filter { b in
            !core.contains(b.footprint.centroid) && distance(b.footprint.centroid, to: core) <= s.transitionWidth
                && BuildingGenerator.role(of: b) == .house
        }) { input.zones?.profileID(at: $0.footprint.centroid) ?? input.profile.id }.mapValues { $0.map(\.footprint.area) }
        let streets = StreetContext(data.features)
        var generators: [String: BuildingGenerator] = [:]
        func generator(at p: LocalPoint) -> BuildingGenerator {
            let profile = input.zones?.profile(at: p) ?? input.profile
            if let g = generators[profile.id] { return g }
            var g = BuildingGenerator(profile: profile, context: streets)
            let t = profile.typeThresholds.resolved(houseAreas: houses[profile.id] ?? [])
            if t != profile.typeThresholds { g.areaThresholds = t }
            generators[profile.id] = g
            return g
        }
        var nLow = 0, nTall = 0, nFirst = 0
        for b in data.buildings {
            let c = b.footprint.centroid
            guard cov.contains(c), !core.contains(c), edgeDistance(c, cov) >= s.fadeWidth else { continue }
            let dc = distance(c, to: core)
            let area = b.footprint.area
            let maybeTall = b.height.top >= s.tallHeight * 0.8 || area >= s.tallFootprint
            guard dc <= s.transitionWidth || maybeTall else { continue }
            guard let ci = cells.firstIndex(where: { $0.rect.contains(c) }) else { continue }
            let gen = generator(at: c)
            var g: GeneratedBuilding
            if palette.colors.count <= Palette.capacity - 8 {
                g = gen.generate(b, palette: &palette, lod: .skyline)
            } else {
                // Palette nearly full: draw with the nearest existing colours.
                var scratch = palette
                g = gen.generate(b, palette: &scratch, lod: .skyline)
                remap(&g.mesh, to: palette, from: scratch)
            }
            let tall = g.topHeight >= s.tallHeight || area >= s.tallFootprint
            guard tall || dc <= s.transitionWidth, !g.mesh.isEmpty else { continue }
            let mass = g.mesh
            if tall {
                nTall += 1
                for lod in [ContextLOD.near, .aerial, .street] { put(mass, ci, lod, "tall") }
                continue
            }
            nLow += 1
            let slab = area >= s.minSlabFootprint ? roofSlab(b, mass: mass) : MeshBuffers()
            if dc <= s.firstRowWidth {
                nFirst += 1
                put(mass, ci, .near, "firstRow")
            } else {
                put(slab, ci, .near, "slab")
            }
            if dc <= s.aerialSlabWidth { put(slab, ci, .aerial, "slab") }
        }

        scene.cells = cells.filter { c in c.meshes.contains { !$0.isEmpty } }
        scene.palette = palette
        scene.stats["buildingsLow"] = nLow
        scene.stats["buildingsFirstRow"] = nFirst
        scene.stats["buildingsTall"] = nTall
        scene.stats["skippedPieces"] = skipped
        scene.stats["cells"] = scene.cells.count
        for lod in ContextLOD.allCases {
            scene.stats["triangles.\(lod)"] = scene.cells.reduce(0) { $0 + $1.mesh(lod).triangleCount }
        }
        scene.stats["triangles.water"] = scene.water.triangleCount
        scene.stats.merge(tally) { _, b in b }
        return scene
    }

    /// The building's roof as one flat quad (its minimum-area rectangle) at the top of its
    /// skyline mass, in the roof's colour: what a steep aerial view resolves of a low building.
    static func roofSlab(_ b: Building, mass: MeshBuffers) -> MeshBuffers {
        var top: Float = 0, roof: SIMD4<Float>?
        for i in 0..<mass.vertexCount {
            top = max(top, mass.positions[i].y)
            if roof == nil, mass.normals[i].y > 0.9 { roof = mass.paints[i] }
        }
        var m = MeshBuffers()
        let p = roof ?? mass.paints.first ?? SIMD4(0, 1, 0, 0)
        m.paint = Paint(slot: Int(p.x), shade: p.y, flags: Paint.Flags(rawValue: Int(p.z)), sway: p.w)
        let rect = FootprintAnalysis.minimumAreaRect(b.footprint.outer)
        m.addFace(rect.corners.map { P($0, Double(top)) }, facing: sceneUp)
        return m
    }

    /// Paints any slot `scratch` added beyond `palette` with the nearest existing colour.
    static func remap(_ m: inout MeshBuffers, to palette: Palette, from scratch: Palette) {
        let n = palette.colors.count
        for i in 0..<m.paints.count {
            let slot = Int(m.paints[i].x)
            guard slot >= n, slot < scratch.colors.count else { continue }
            let c = scratch.colors[slot]
            let best = (0..<n).min { simd_distance_squared(palette.colors[$0], c) < simd_distance_squared(palette.colors[$1], c) } ?? 0
            m.paints[i].x = Float(best)
        }
    }
}

// MARK: - View estimate

extension ContextScene {
    /// Triangles and draw calls of the ring in a view (cells whose active level's bounds meet the
    /// frustum, plus the water), the way the engine counts them. `eye`/`target` in local metres
    /// (east, north, up); `fovY` in degrees; `aspect` = width / height.
    public func viewEstimate(eye: SIMD3<Double>, target: SIMD3<Double>, fovY: Double, aspect: Double, far: Double = 5000)
        -> (triangles: Int, drawCalls: Int, levels: [ContextLOD: Int]) {
        let f = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(f, SIMD3(0, 0, 1)))
        let up = simd_cross(right, f)
        let ty = tan(fovY * .pi / 360), tx = ty * aspect
        // Inward plane normals through the eye, plus near/far.
        let sides = [f * tx - right, f * tx + right, f * ty - up, f * ty + up]
        func visible(_ lo: SIMD3<Double>, _ hi: SIMD3<Double>) -> Bool {
            for n in sides {
                let v = SIMD3(n.x > 0 ? hi.x : lo.x, n.y > 0 ? hi.y : lo.y, n.z > 0 ? hi.z : lo.z)
                if simd_dot(n, v - eye) < 0 { return false }
            }
            let vNear = SIMD3(f.x > 0 ? hi.x : lo.x, f.y > 0 ? hi.y : lo.y, f.z > 0 ? hi.z : lo.z)
            if simd_dot(f, vNear - eye) < 1 { return false }
            let vFar = SIMD3(f.x < 0 ? hi.x : lo.x, f.y < 0 ? hi.y : lo.y, f.z < 0 ? hi.z : lo.z)
            return simd_dot(f, vFar - eye) <= far
        }
        func box(_ m: MeshBuffers) -> (SIMD3<Double>, SIMD3<Double>)? {
            guard let b = m.bounds else { return nil }
            // Scene (x, y up, −north) → local (east, north, up).
            return (SIMD3(Double(b.min.x), Double(-b.max.z), Double(b.min.y)), SIMD3(Double(b.max.x), Double(-b.min.z), Double(b.max.y)))
        }
        var tris = 0, draws = 0, levels: [ContextLOD: Int] = [:]
        for c in cells {
            let lod = ContextLOD.pick(eye: eye, cell: c.rect, settings: settings)
            let m = c.mesh(lod)
            guard let (lo, hi) = box(m), visible(lo, hi) else { continue }
            tris += m.triangleCount
            draws += 1
            levels[lod, default: 0] += 1
        }
        if let (lo, hi) = box(water), visible(lo, hi) { tris += water.triangleCount; draws += 1 }
        return (tris, draws, levels)
    }
}
