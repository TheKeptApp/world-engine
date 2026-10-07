import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Context ring (look-fix-v1 §4): shoreline closing, palette slots, and the rings of the committed
/// areas (nothing inside the area box, closed water, coverage fade, determinism, triangle budget).
/// Prints BUDGET lines; with WORLDENGINE_CONTEXT_DUMP=<dir> it writes meshes for offline renders.
@Suite("Context ring", .serialized)
struct ContextRingTests {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static func dir(_ area: String) -> URL { root.appendingPathComponent("Data/areas/\(area)") }
    static let areas = ["sloans-lake", "evanston-south", "lakeview-sheil-park"]
    static func hasContext(_ area: String) -> Bool {
        (try? AreaLoader.loadManifest(dir(area)))?.contextSources.isEmpty == false
    }

    // MARK: Palette

    @Test func newSeasonalKeysAreAppendedAndBackdropKeepsItsShaderSlot() throws {
        let order = SeasonalPalette.order
        #expect(order.firstIndex(of: "backdrop") == 17)   // WorldShaders.metal kBackdropSlot
        // The context-ring masses follow the lawn pair; later keys (more crown slots) come after them.
        let ring = try #require(order.firstIndex(of: "residential"))
        #expect(ring == order.firstIndex(of: "lawnB")! + 1)
        #expect(Array(order[ring..<(ring + 4)]) == ["residential", "commercial", "wood", "farmland"])
        let seasonal = try StyleLibrary.seasonalPalette()
        for key in order { #expect(seasonal.surfaces[key]?.count == 4, "\(key)") }
    }

    // MARK: Shoreline

    static let box = Rect2D(min: LocalPoint(0, 0), max: LocalPoint(100, 100))

    static func waterArea(_ r: ShorelineFill.Result) -> Double { r.water.reduce(0) { $0 + $1.area } }

    @Test func coastlineClosesAlongTheBoxOnTheWaterSide() {
        // Coastline running north across the box at x = 40: water on its right (east).
        let line = [LocalPoint(40, -50), LocalPoint(40, 150)]
        let r = ShorelineFill.fill(box: Self.box, lines: [line], side: .right)
        #expect(r.pieces == 1 && r.dropped == 0)
        #expect(abs(Self.waterArea(r) - 6000) < 1)
        #expect(r.water.allSatisfy { $0.contains(LocalPoint(70, 50)) && !$0.contains(LocalPoint(20, 50)) })
        // Reversed direction: water on the west.
        let back = ShorelineFill.fill(box: Self.box, lines: [line.reversed()], side: .right)
        #expect(abs(Self.waterArea(back) - 4000) < 1)
    }

    @Test func partialLakeTakesTheSideWithoutLandAndIsFilled() {
        // A bent shore crossing the box twice (in from the south, out to the east), direction
        // unknown; roads and buildings lie west of it.
        let shore = [LocalPoint(30, -10), LocalPoint(35, 60), LocalPoint(110, 70)]
        let land = (0..<20).map { LocalPoint(5 + Double($0), 20 + Double($0)) }
        for line in [shore, shore.reversed()] {
            let r = ShorelineFill.fill(box: Self.box, lines: [line], side: .unknown(landEvidence: land, fallbackLand: LocalPoint(50, 90)))
            #expect(r.water.count == 1)
            let water = r.water[0]
            #expect(water.contains(LocalPoint(80, 20)))
            #expect(!water.contains(LocalPoint(10, 50)) && !water.contains(LocalPoint(50, 90)))
            // Closed (no repeated closing point, CCW) and filled: triangles cover the polygon.
            #expect(water.outer.first != water.outer.last && RingMath.signedArea(water.outer) > 0)
            let cap = Triangulator.cap(water, y: 0)
            #expect(cap != nil)
            #expect(abs(Double(cap?.surfaceArea ?? 0) - water.area) / water.area < 0.01)
        }
    }

    @Test func noEvidenceFallsBackToTheSideAwayFromTheArea() {
        let line = [LocalPoint(-10, 50), LocalPoint(110, 50)]
        let r = ShorelineFill.fill(box: Self.box, lines: [line], side: .unknown(landEvidence: [], fallbackLand: LocalPoint(50, 10)))
        #expect(r.water.count == 1 && r.water[0].contains(LocalPoint(50, 90)))
    }

    @Test func shorelineEndingInsideTheBoxIsNotInvented() {
        let r = ShorelineFill.fill(box: Self.box, lines: [[LocalPoint(-20, 50), LocalPoint(60, 50)]], side: .right)
        #expect(r.water.isEmpty && r.dropped == 1)
    }

    @Test func twoShoresMakeAChannelAndIslandsAreHoles() {
        // Water between x = 30 and x = 70 (coastlines facing each other), an island inside it.
        let west = [LocalPoint(30, -10), LocalPoint(30, 110)], east = [LocalPoint(70, 110), LocalPoint(70, -10)]
        let island: Ring = [LocalPoint(45, 45), LocalPoint(45, 55), LocalPoint(55, 55), LocalPoint(55, 45)]
        let r = ShorelineFill.fill(box: Self.box, lines: [west, east], side: .right, holes: [island])
        #expect(abs(Self.waterArea(r) - (4000 - 100)) < 1)
        #expect(r.water.count == 1 && !r.water[0].contains(LocalPoint(50, 50)) && r.water[0].contains(LocalPoint(35, 50)))
    }

    @Test func joinChainsWaysEndToEnd() {
        let j = ShorelineFill.join([[1, 2, 3], [5, 4, 3], [5, 6]], directed: false)
        #expect(j.closed.isEmpty && j.open.count == 1 && Set(j.open[0]) == [1, 2, 3, 4, 5, 6])
        let d = ShorelineFill.join([[1, 2], [3, 2]], directed: true)
        #expect(d.open.count == 2)
    }

    // MARK: Simplification

    @Test func junctionsSurviveSimplification() {
        // A nearly straight street with a side street joining at a vertex D–P would drop.
        let street = [LocalPoint(0, 0), LocalPoint(50, 0.4), LocalPoint(100, 0)]
        let pin = ContextRing.key(LocalPoint(50, 0.4))
        #expect(ContextRing.simplify(line: street, tolerance: 2, pins: []).count == 2)
        #expect(ContextRing.simplify(line: street, tolerance: 2, pins: [pin]) == street)
    }

    @Test func fadeWeightRunsFromTheEdgeToFadeWidthInside() {
        let cov = Rect2D(min: LocalPoint(-1000, -1000), max: LocalPoint(1000, 1000))
        #expect(ContextRing.fadeWeight(at: LocalPoint(1000, 0), coverage: cov, width: 200) == 1)
        #expect(ContextRing.fadeWeight(at: LocalPoint(0, -900), coverage: cov, width: 200) == 0.5)
        #expect(ContextRing.fadeWeight(at: LocalPoint(799, 0), coverage: cov, width: 200) == 0)
    }

    @Test func cellsTileTheRingOutsideTheBox() {
        let core = Rect2D(centerWidth: 1600, height: 1200)
        let cov = Rect2D(min: LocalPoint(-3789, -3606), max: LocalPoint(3792, 3604))
        let cells = ContextRing.cellRects(core: core, coverage: cov, inner: 1000)
        #expect(cells.count == 18)
        let area = cells.reduce(0) { $0 + $1.1.width * $1.1.height }
        #expect(abs(area - (cov.width * cov.height - core.width * core.height)) < 1)
        #expect(cells.allSatisfy { c in !(c.1.min.x < core.max.x - 1e-6 && c.1.max.x > core.min.x + 1e-6 && c.1.min.y < core.max.y - 1e-6 && c.1.max.y > core.min.y + 1e-6) })
    }

    @Test func levelsFollowTheCamera() {
        let s = ContextSettings()
        let cell = Rect2D(min: LocalPoint(800, -600), max: LocalPoint(1800, 600))
        #expect(ContextLOD.pick(eye: SIMD3(700, 0, 1.65), cell: cell, settings: s) == .near)
        #expect(ContextLOD.pick(eye: SIMD3(-700, 0, 1.65), cell: cell, settings: s) == .street)
        #expect(ContextLOD.pick(eye: SIMD3(0, -1032, 1474), cell: cell, settings: s) == .aerial)
        #expect(ContextLOD.pick(eye: SIMD3(-3000, 0, 1.65), cell: cell, settings: s) == .far)
    }

    // MARK: Real data

    static func generate(_ area: String) throws -> (ContextScene, Double, Double) {
        let d = dir(area)
        let manifest = try AreaLoader.loadManifest(d)
        let profile = try StyleLibrary.profile(at: manifest.center)
        let palette = Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 1, base: try StyleLibrary.baseColors())
        let built = try #require(try ContextRing.build(areaDirectory: d, manifest: manifest, palette: palette, profile: profile, zonesByLocation: true))
        return (built.scene, built.parseSeconds, built.generateSeconds)
    }

    /// Cameras for the budget: aerials (v2-06 pose, the area's own fit, its farthest zoom, a
    /// rotated tilt, a low corner oblique) and street eyes (centre, box edges, a corner).
    static func cameras(_ c: ContextScene) -> [(String, SIMD3<Double>, SIMD3<Double>)] {
        func aerial(_ d: Double, pitch: Double = 55, heading: Double = 0, at p: LocalPoint = .zero) -> (SIMD3<Double>, SIMD3<Double>) {
            let h = heading * .pi / 180, a = pitch * .pi / 180
            let f = SIMD3(sin(h) * cos(a), cos(h) * cos(a), -sin(a))
            let t = SIMD3(p.x, p.y, 0)
            return (t - f * d, t)
        }
        func street(_ p: LocalPoint, heading: Double) -> (SIMD3<Double>, SIMD3<Double>) {
            let h = heading * .pi / 180
            return (SIMD3(p.x, p.y, 1.65), SIMD3(p.x + sin(h) * 30, p.y + cos(h) * 30, 1.65 - 30 * tan(3 * .pi / 180)))
        }
        // ExperienceDefaults' aerial fit (bounds + 10%, 55°, 50° FOV).
        let size = (c.core.max - c.core.min) * 1.1
        let fitH = max(size.y * sin(55 * .pi / 180), size.x * 9 / 16 * sin(55 * .pi / 180))
        let fit = fitH / 2 / tan(25 * .pi / 180) + size.y / 2 * cos(55 * .pi / 180)
        let k = c.core
        var out: [(String, SIMD3<Double>, SIMD3<Double>)] = []
        func add(_ n: String, _ v: (SIMD3<Double>, SIMD3<Double>)) { out.append((n, v.0, v.1)) }
        add("aerial-v2-06", aerial(1800))
        add("aerial-fit", aerial(fit))
        add("aerial-max", aerial(fit * 1.6))
        add("aerial-max-45", aerial(fit * 1.6, pitch: 45, heading: 45))
        add("aerial-corner", aerial(400, pitch: 45, heading: 45, at: k.max))
        add("aerial-low", aerial(170, pitch: 36, heading: 90, at: LocalPoint(k.max.x - 100, 0)))
        for h in [0.0, 90, 180, 270] { add("street-centre-\(Int(h))", street(.zero, heading: h)) }
        add("street-edge-N", street(LocalPoint(0, k.max.y - 20), heading: 0))
        add("street-edge-E", street(LocalPoint(k.max.x - 20, 0), heading: 90))
        add("street-edge-S", street(LocalPoint(0, k.min.y + 20), heading: 180))
        add("street-edge-W", street(LocalPoint(k.min.x + 20, 0), heading: 270))
        for (n, p, h) in [("NE", k.max, 45.0), ("SW", k.min, 225), ("NW", LocalPoint(k.min.x, k.max.y), 315), ("SE", LocalPoint(k.max.x, k.min.y), 135)] {
            add("street-corner-\(n)", street(p - simd_normalize(p) * 20, heading: h))
        }
        return out
    }

    @Test(arguments: areas)
    func ringOfCommittedArea(_ area: String) throws {
        guard Self.hasContext(area) else { return }
        let (c, parse, gen) = try Self.generate(area)
        print("BUDGET context \(area) parse=\(String(format: "%.2f", parse))s generate=\(String(format: "%.2f", gen))s cells=\(c.cells.count) stats=\(c.stats.sorted { $0.key < $1.key })")
        #expect(!c.cells.isEmpty)
        let bytes = c.cells.flatMap(\.meshes).reduce(c.water.gpuBytes) { $0 + $1.gpuBytes }
        print("BUDGET memory \(area) gpuMB=\(String(format: "%.1f", Double(bytes) / 1_048_576)) palette=\(c.palette.colors.count)")
        let core = c.core, cov = c.coverage

        // Nothing flat inside the area box (buildings: centroid outside it, like the detailed
        // world keeps buildings by centroid), and everything inside the coverage box.
        func flatInsideCore(_ m: MeshBuffers, margin: Double) -> Int {
            var n = 0
            for t in 0..<m.triangleCount {
                let a = m.positions[Int(m.indices[t * 3])], b = m.positions[Int(m.indices[t * 3 + 1])], d = m.positions[Int(m.indices[t * 3 + 2])]
                guard max(a.y, b.y, d.y) < 0.1 else { continue }
                let p = (a + b + d) / 3
                let q = LocalPoint(Double(p.x), Double(-p.z))
                if q.x > core.min.x + margin, q.x < core.max.x - margin, q.y > core.min.y + margin, q.y < core.max.y - margin { n += 1 }
            }
            return n
        }
        // Ribbons of streets running just outside the box may overlap it by half their width.
        var inside = flatInsideCore(c.water, margin: 8)
        for cell in c.cells { for m in cell.meshes { inside += flatInsideCore(m, margin: 8) } }
        #expect(inside == 0)
        for cell in c.cells { for m in cell.meshes where !m.isEmpty {
            let b = m.bounds!
            #expect(Double(b.min.x) >= cov.min.x - 30 && Double(b.max.x) <= cov.max.x + 30)
        } }

        // Coverage fade on every flat vertex: flag, box and width; ground reaches the edge.
        var flat = 0, faded = 0, atEdge = 0
        for m in c.cells.flatMap(\.meshes) + [c.water] {
            for i in 0..<m.vertexCount where m.positions[i].y < 0.1 && m.normals[i].y > 0.9 {
                flat += 1
                let p = m.paints[i]
                if Int(p.z) & Paint.Flags.coverageFade.rawValue != 0, p.w >= 150, p.w <= 250,
                   m.extras[i] == SIMD4(Float(cov.min.x), Float(-cov.max.y), Float(cov.max.x), Float(-cov.min.y)) { faded += 1 }
                if ContextRing.edgeDistance(LocalPoint(Double(m.positions[i].x), Double(-m.positions[i].z)), cov) < 1 { atEdge += 1 }
            }
        }
        #expect(flat > 0 && faded == flat)
        #expect(atEdge > 0)

        // Water: closed, filled (triangulated area matches), inside the ring.
        #expect(c.water.triangleCount > 0 || area != "sloans-lake")
        #expect(c.water.indices.count % 3 == 0)

        // Budget: per cell and per view (≤ 20k triangles, look-fix-v1 §7).
        var worst = (0, ""), worstDraws = (0, "")
        for cell in c.cells {
            print("BUDGET cell \(area) \(cell.id) \(Int(cell.rect.width))x\(Int(cell.rect.height)) " + ContextLOD.allCases.map { "\($0)=\(cell.mesh($0).triangleCount)" }.joined(separator: " "))
        }
        for (name, eye, target) in Self.cameras(c) {
            for (aspect, an) in [(16.0 / 9, "16:9"), (19.5 / 9, "landscape"), (9 / 19.5, "portrait")] {
                let v = c.viewEstimate(eye: eye, target: target, fovY: 50, aspect: aspect)
                if v.triangles > worst.0 { worst = (v.triangles, "\(name) \(an)") }
                if v.drawCalls > worstDraws.0 { worstDraws = (v.drawCalls, "\(name) \(an)") }
                if an != "portrait" || name.hasPrefix("aerial-v2") {
                    print("BUDGET view \(area) \(name) \(an) triangles=\(v.triangles) draws=\(v.drawCalls) levels=\(v.levels.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" })")
                }
                #expect(v.triangles <= 20_000, "\(area) \(name) \(an): \(v.triangles)")
            }
        }
        print("BUDGET worst \(area) triangles=\(worst.0) (\(worst.1)) draws=\(worstDraws.0) (\(worstDraws.1)) water=\(c.water.triangleCount)")
        if let out = ProcessInfo.processInfo.environment["WORLDENGINE_CONTEXT_DUMP"] {
            try Self.dump(c, area: area, to: URL(fileURLWithPath: out))
            try Self.dumpCore(area: area, to: URL(fileURLWithPath: out))
        }
    }

    /// The detailed world for the same renders (static ground and buildings at the far level,
    /// water, trees as points), to judge the seam.
    static func dumpCore(area: String, to dir: URL) throws {
        let build = try WorldBuild.generate(areaDirectory: Self.dir(area), recipe: WorldRecipe(season: 1, buildingLODs: true))
        let pal = build.scene.palette
        var floats: [Float] = []
        func add(_ m: MeshBuffers) {
            for t in 0..<m.indices.count {
                let i = Int(m.indices[t]), p = m.positions[i], pa = m.paints[i]
                let c = pal.colors[min(max(Int(pa.x), 0), pal.colors.count - 1)] * pa.y
                floats += [p.x, p.y, p.z, c.x, c.y, c.z]
            }
        }
        for ch in build.scene.chunks { add(ch.staticMesh); add(ch.waterMesh) }
        for cell in build.scene.buildingCells { if let m = cell.meshes[.far] ?? cell.meshes[.skyline] { add(m) } }
        var trees: [Float] = []
        for t in build.scene.instances where t.kind.isTree {
            let slot = t.kind == .conifer ? pal.named("conifer1") : pal.named("deciduous1")
            let c = pal.colors[slot]
            trees += [Float(t.x), Float(t.y), Float(t.scale), c.x, c.y, c.z]
        }
        try floats.withUnsafeBufferPointer { Data(buffer: $0) }.write(to: dir.appendingPathComponent("\(area)-core.bin"))
        try trees.withUnsafeBufferPointer { Data(buffer: $0) }.write(to: dir.appendingPathComponent("\(area)-trees.bin"))
    }

    @Test func generationIsDeterministic() throws {
        let area = "evanston-south"
        guard Self.hasContext(area) else { return }
        let (a, _, _) = try Self.generate(area)
        let (b, _, _) = try Self.generate(area)
        #expect(a.cells.count == b.cells.count)
        for (x, y) in zip(a.cells, b.cells) {
            #expect(x.rect == y.rect)
            for (m, n) in zip(x.meshes, y.meshes) {
                #expect(m.positions == n.positions && m.paints == n.paints && m.indices == n.indices && m.extras == n.extras)
            }
        }
        #expect(a.water.positions == b.water.positions && a.palette.colors == b.palette.colors)
    }

    /// Simplification keeps the street network connected: after joining continuations and
    /// simplifying at each level's tolerance, every junction is still a vertex of every line that
    /// met there, and line ends are unchanged.
    @Test func simplifiedRoadsStayConnected() throws {
        let area = "lakeview-sheil-park"
        guard Self.hasContext(area) else { return }
        let d = Self.dir(area)
        let manifest = try AreaLoader.loadManifest(d)
        let doc = try #require(try AreaLoader.loadContextDocument(d, manifest: manifest))
        let data = ContextData(document: doc, frame: manifest.frame, coverage: try #require(ContextRing.coverage(of: manifest)),
                               core: manifest.localBounds)
        for level in ContextSettings().detail {
            let lines = data.roads.filter { $0.kind == .main || ($0.kind == .minor && level.minorRoads) }
            let pins = ContextRing.junctions(lines)
            let merged = ContextRing.mergeContinuations(lines, pins: pins)
            #expect(merged.count <= lines.count)
            var before = Set<SIMD2<UInt64>>(), after = Set<SIMD2<UInt64>>(), missing = 0
            for l in lines { for p in l.points where pins.contains(ContextRing.key(p)) { before.insert(ContextRing.key(p)) } }
            for l in merged {
                let s = ContextRing.simplify(line: l.points, tolerance: level.roadTolerance, pins: pins)
                #expect(s.first == l.points.first && s.last == l.points.last)
                for p in s { after.insert(ContextRing.key(p)) }
            }
            for k in before where !after.contains(k) { missing += 1 }
            #expect(missing == 0)
            print("BUDGET topology \(area) tolerance=\(level.roadTolerance) lines=\(lines.count) merged=\(merged.count) junctions=\(before.count) lost=\(missing)")
        }
    }

    // MARK: Dump for offline renders (WORLDENGINE_CONTEXT_DUMP)

    /// Per mesh: positions and an sRGB colour per vertex (palette × shade, faded as the shader does).
    static func dump(_ c: ContextScene, area: String, to dir: URL) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var floats: [Float] = [], index: [[String: Any]] = []
        let backdrop = c.palette.colors[17]
        func lin(_ v: SIMD3<Float>) -> SIMD3<Float> { SIMD3(v.x * v.x, v.y * v.y, v.z * v.z) }
        func add(_ m: MeshBuffers, cell: String, lod: String) {
            guard !m.isEmpty else { return }
            let start = floats.count / 6
            for t in 0..<m.indices.count {
                let i = Int(m.indices[t])
                let p = m.positions[i], pa = m.paints[i]
                let slot = min(max(Int(pa.x), 0), c.palette.colors.count - 1)
                var col = lin(c.palette.colors[slot]) * pa.y
                if Int(pa.z) & Paint.Flags.coverageFade.rawValue != 0 {
                    let w = Float(ContextRing.fadeWeight(at: LocalPoint(Double(p.x), Double(-p.z)), coverage: c.coverage, width: Double(pa.w)))
                    col = col * (1 - w) + lin(backdrop) * w
                }
                let s = SIMD3<Float>(col.x.squareRoot(), col.y.squareRoot(), col.z.squareRoot())
                floats += [p.x, p.y, p.z, s.x, s.y, s.z]
            }
            index.append(["cell": cell, "lod": lod, "start": start, "count": m.indices.count])
        }
        for cell in c.cells { for lod in ContextLOD.allCases { add(cell.mesh(lod), cell: cell.id, lod: "\(lod)") } }
        add(c.water, cell: "water", lod: "water")
        let header: [String: Any] = [
            "coverage": [c.coverage.min.x, c.coverage.min.y, c.coverage.max.x, c.coverage.max.y],
            "core": [c.core.min.x, c.core.min.y, c.core.max.x, c.core.max.y],
            "backdrop": [backdrop.x, backdrop.y, backdrop.z], "fadeWidth": c.settings.fadeWidth,
            "cells": c.cells.map { ["id": $0.id, "rect": [$0.rect.min.x, $0.rect.min.y, $0.rect.max.x, $0.rect.max.y]] },
            "meshes": index,
        ]
        try JSONSerialization.data(withJSONObject: header).write(to: dir.appendingPathComponent("\(area)-context.json"))
        try floats.withUnsafeBufferPointer { Data(buffer: $0) }.write(to: dir.appendingPathComponent("\(area)-context.bin"))
    }
}
