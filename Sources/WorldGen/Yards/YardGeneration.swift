import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// An inferred yard: the open ground nearest one residential building, never crossing a road,
/// walkway or blocked land. A dressing aid only (lawn tone, walks, planting): never a parcel
/// boundary, never for navigation (regions spec §7: inferred, tied to its parent reference).
public struct GeneratedLot: Sendable {
    public var building: OSMRef
    public var profileID: String
    /// Outline rings, local meters, counter-clockwise (the house sits inside).
    public var outline: [Ring]
    /// Open yard area in m² (house excluded).
    public var area: Double
    /// Palette shade for this lot's lawn (one of four value steps; neighbours differ by 1–2 steps).
    public var lawnShade: Float
    /// Position 0…1 between the zone's lawn endpoint pair for the season (vertex extra.y).
    public var tone: Float
    /// Stable per-lot seed 0…1 for the renderer's analytic patch field (vertex extra.w).
    public var seed: Float
    public var entry: LocalPoint?
    /// Front walk from the door to the sidewalk or street.
    public var walk: [LocalPoint]?
    public var driveways: [[LocalPoint]] = []
    public var origin = "inferred"
    /// Yard rule version (bump when placement rules change so caches and comparisons know).
    public var ruleVersion = 2
}

/// A fall leaf-litter patch near a deciduous tree (look-fix §1.3). Renderers show it only in the
/// fall phenophase (season mask is theirs). Tone picks one of three leaf colours.
public struct LitterPatch: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var radius: Double
    /// 0, 1, 2 → #AA753F, #BD914F, #8C7145.
    public var tone: Int
    /// The tree's instance source.
    public var tree: String
}

/// Where fallen leaves collect beyond tree crowns (renderers decide whether and how).
public struct LitterHint: Sendable {
    public enum Kind: String, Sendable, Codable { case curb, hedge, walkEdge }
    public var kind: Kind
    public var line: [LocalPoint]
    public var weight: Float
}

/// One building as the yard pass sees it.
struct YardSubject {
    var index: Int
    var building: Building
    var generated: GeneratedBuilding
}

extension SceneGenerator {
    static let yardBlockedAreas: Set<AreaFeature.Kind> = [.park, .pitch, .playground, .parking, .water, .pool, .cemetery, .recreation,
                                                          .pedestrianArea, .sand, .wetland, .wood, .commercial]
    static let yardBuildingTypes: Set<String> = ["house", "detached", "semidetached_house", "bungalow", "residential", "terrace",
                                                 "apartments", "yes", "cabin"]

    /// Yards for residential buildings, parkway trees along streets, litter hints.
    // swiftlint:disable:next function_parameter_count
    func generateYards(_ subjects: [YardSubject], context: StreetContext, generatedWalkways: [[LocalPoint]], palette: inout Palette,
                       chunks: inout [SIMD2<Int>: GeneratedChunk], instances: inout [PropInstance], scene: inout GeneratedScene) {
        let library = YardLibrary.bundled
        let t0 = Date()
        var raster = LotRaster(bounds: features.bounds, resolution: 1)
        for a in features.areas where Self.yardBlockedAreas.contains(a.kind) { raster.fill(a.polygon, .blocked) }
        for r in features.roads { raster.fill(line: r.centerline, width: r.width, .road) }
        for p in features.paths { raster.fill(line: p.centerline, width: max(1.5, p.width), .walkway) }
        for s in features.sidewalks { raster.fill(line: s.centerline, width: 1.6, .walkway) }
        for s in generatedWalkways { raster.fill(line: s, width: 1.5, .walkway) }
        for s in subjects { raster.fill(s.building.footprint, .building, building: Int32(s.index)) }

        // Who grows a yard: houses and residential blocks; other buildings claim a narrow margin
        // so houses don't take the ground beside a church or a shop. Garages and sheds don't.
        var maxDistance: [Int32: Double] = [:]
        var eligible: Set<Int> = []
        for s in subjects {
            let g = s.generated
            switch g.role {
            case .garage, .shed: continue
            case .house, .block:
                let residential = Self.yardBuildingTypes.contains(s.building.type) && g.family != "cornerMixedUse" && s.building.tags["shop"] == nil
                if residential {
                    eligible.insert(s.index)
                    maxDistance[Int32(s.index)] = library.rules(for: g.profileID ?? profile.id).maxLotDepth
                } else {
                    maxDistance[Int32(s.index)] = 6
                }
            }
        }
        let t1 = Date()
        raster.assignYards(maxDistance: maxDistance)
        let t2 = Date()

        // Per-owner cell extents.
        var lo = [Int: SIMD2<Int>](), hi = [Int: SIMD2<Int>](), count = [Int: Int]()
        for j in 0..<raster.h { for i in 0..<raster.w {
            let k = raster.index(i, j)
            let o = Int(raster.owner[k])
            guard o >= 0, eligible.contains(o), raster.use[k] == LotRaster.Use.open.rawValue else { continue }
            lo[o] = simd_min(lo[o] ?? SIMD2(i, j), SIMD2(i, j))
            hi[o] = simd_max(hi[o] ?? SIMD2(i, j), SIMD2(i, j))
            count[o, default: 0] += 1
        } }

        let n = palette.named
        let byIndex = Dictionary(uniqueKeysWithValues: subjects.map { ($0.index, $0) })
        var trees = TreeGrid(cell: 8)
        for inst in instances where inst.kind.isTree { trees.insert(LocalPoint(inst.x, inst.y), kind: inst.kind, variant: inst.variant) }
        var stats: [String: Int] = [:]
        func addStatic(_ m: MeshBuffers, _ feature: String, at p: LocalPoint) {
            let key = chunkIndex(p)
            guard !m.isEmpty, chunks[key] != nil else { return }
            let start = chunks[key]!.staticMesh.vertexCount
            chunks[key]!.staticMesh.append(m)
            chunks[key]!.staticFeatures.append(FeatureRange(feature: feature, start: start, count: m.vertexCount))
        }
        func inFocus(_ p: LocalPoint) -> Bool { lod == 0 && focus.expanded(by: 30).contains(p) }

        // Walks and driveways first (they mark hard ground that planting avoids).
        var walks: [Int: [LocalPoint]] = [:]
        var driveways: [Int: [[LocalPoint]]] = [:]
        for idx in eligible.sorted() where count[idx, default: 0] >= 12 {
            let s = byIndex[idx]!
            let rules = library.rules(for: s.generated.profileID ?? profile.id)
            var r = s.building.ref.random("yard-walk")
            guard let entry = s.generated.entry, r.chance(rules.frontWalk) else { continue }
            // Inferred lot lines don't stop a walk (a neighbour's cell can reach the sidewalk first).
            if let end = march(raster, from: entry.point + entry.normal * 0.3, dir: entry.normal, maxLength: 35, owner: nil,
                               stopAt: [.walkway, .road]) {
                let line = [entry.point + entry.normal * 0.05, end]
                walks[idx] = line
                raster.markHard(line: line, width: 1.6)
            }
        }
        for s in subjects where s.generated.role == .garage {
            guard let e = s.generated.garageDoorEdge else { continue }
            let ring = s.building.footprint.outer
            let (p, dir, nrm, len) = BuildingGenerator.edge(ring, e)
            guard len >= 2.6 else { continue }
            let start = p + dir * (len / 2) + nrm * 0.1
            // The lot this garage serves: the yard owner just outside its door.
            let o = Int(raster.ownerAt(start + nrm * 1.0))
            guard o >= 0, eligible.contains(o),
                  let end = march(raster, from: start, dir: nrm, maxLength: s.generated.garageDoorFacesAlley ? 12 : 40, owner: nil,
                                  stopAt: [.road, .walkway]) else { continue }
            let line = [start - nrm * 0.1, end]
            driveways[o, default: []].append(line)
            var m = Ribbon.build(line, width: min(len - 0.4, 3.2), y: GroundLayer.driveway)
            m.repaint(from: 0, Paint(slot: n("driveway")))
            addStatic(m, "gen:driveway:\(s.building.ref)", at: start)
            raster.markHard(line: line, width: min(len - 0.4, 3.2) + 0.6)
            stats["driveways", default: 0] += 1
        }

        // Lawn value steps: four per zone range (5 % apart); neighbouring lots differ by one or two
        // steps where possible, never equal unless every level is taken (look-fix §1.1: 4–10 % value apart, no alternating stripes).
        var neighbours: [Int: Set<Int>] = [:]
        for j in 0..<raster.h { for i in 0..<raster.w {
            let o = Int(raster.owner[raster.index(i, j)])
            guard o >= 0, eligible.contains(o) else { continue }
            // Lots one open cell apart still read as neighbours.
            for (di, dj) in [(1, 0), (0, 1), (1, 1), (1, -1), (2, 0), (0, 2), (2, 1), (1, 2), (2, -1), (1, -2), (2, 2), (2, -2), (3, 0), (0, 3)]
                where i + di < raster.w && j + dj < raster.h && j + dj >= 0 {
                let q = Int(raster.owner[raster.index(i + di, j + dj)])
                if q >= 0, q != o, eligible.contains(q) { neighbours[o, default: []].insert(q); neighbours[q, default: []].insert(o) }
            }
        } }
        var step: [Int: Int] = [:]
        for idx in eligible.sorted() {
            guard let s = byIndex[idx] else { continue }
            var r = s.building.ref.random("lawn-step")
            let taken = (neighbours[idx] ?? []).compactMap { step[$0] }
            var allowed = (0..<4).filter { k in taken.allSatisfy { abs($0 - k) == 1 || abs($0 - k) == 2 } }
            if allowed.isEmpty { allowed = (0..<4).filter { !taken.contains($0) } }
            if allowed.isEmpty {
                // Every level is taken: the least-used one among the neighbours.
                let counts = (0..<4).map { k in taken.filter { $0 == k }.count }
                allowed = [counts.firstIndex(of: counts.min()!)!]
            }
            step[idx] = allowed[Int(r.next() % UInt64(allowed.count))]
        }
        var lotTrees: [Int: Int] = [:]
        var lawnJobs: [LawnJob] = []

        for idx in eligible.sorted() {
            guard let c = count[idx], c >= 12, let l = lo[idx], let h = hi[idx], let s = byIndex[idx] else { continue }
            let g = s.generated
            let profileID = g.profileID ?? profile.id
            let rules = library.rules(for: profileID)
            let zoneProfile = zones?.profiles[profileID] ?? profile
            var r = s.building.ref.random("yard")
            let k = Double(step[idx] ?? 1)
            let range = rules.lawnShade.count >= 2 ? rules.lawnShade : [0.92, 1.07]
            let shade = Float(range[0] + (range[1] - range[0]) * k / 3)
            let tone = Float(min(1, max(0, (k + r.range(-0.3, 0.3)) / 3)))
            let lotSeed = Float(r.unit())
            let front = g.frontEdge.map { BuildingGenerator.edge(s.building.footprint.outer, $0) }
            func isFrontYard(_ p: LocalPoint) -> Bool {
                guard let (fp, _, fn, _) = front else { return false }
                return simd_dot(p - fp, fn) > 0.5
            }
            // City lots (look-fix §1.2: Lakeview 0–20 % lawn): a planted front garden and/or a paved
            // rear yard replace parts of the lawn.
            var fr = s.building.ref.random("yard-front")
            let garden = front != nil && fr.chance(rules.frontGarden ?? 0)
            let paved = front != nil && fr.chance(rules.rearPaving ?? 0)
            let ri = max(0, l.x - 1)...min(raster.w - 1, h.x + 1), rj = max(0, l.y - 1)...min(raster.h - 1, h.y + 1)
            func cellFront(_ k: Int) -> Bool { isFrontYard(raster.center(k % raster.w, k / raster.w)) }
            func owned(_ k: Int) -> Bool { raster.owner[k] == Int32(idx) }
            let rings = raster.outlines(ri, rj, tolerance: 0.8) { k in
                if raster.buildingOf[k] == Int32(idx) { return true }
                guard owned(k) else { return false }
                let f = cellFront(k)
                return !(garden && f) && !(paved && !f)
            }
            guard !rings.isEmpty else { continue }
            let anchor = s.building.footprint.centroid
            let lot = GeneratedLot(building: s.building.ref, profileID: profileID, outline: rings, area: Double(c), lawnShade: shade, tone: tone, seed: lotSeed,
                                   entry: g.entry?.point, walk: walks[idx], driveways: driveways[idx] ?? [])

            // Lawn: emitted after every tree and shrub is placed (contact pools), with in-lot patches,
            // mowing bands on some front lawns and worn edges beside walks and drives (GroundDetail).
            var field = LawnField(shade: shade, tone: tone, seed: lotSeed)
            let detailed = inFocus(anchor)
            if detailed {
                var dr = s.building.ref.random("lawn-detail")
                let span = SIMD2<Double>(Double(h.x - l.x + 1), Double(h.y - l.y + 1)) * raster.res
                let base = raster.origin + LocalPoint(Double(l.x), Double(l.y)) * raster.res
                let want = Int(dr.range(Double(rules.lawnPatches?.first ?? 3), Double((rules.lawnPatches?.last ?? 5) + 1)).rounded(.down))
                var tries = 0
                while field.patches.count < want, tries < want * 6 {
                    tries += 1
                    let p = base + LocalPoint(dr.unit() * span.x, dr.unit() * span.y)
                    guard raster.ownerAt(p) == Int32(idx) else { continue }
                    field.patches.append(.init(c: p, r: dr.range(1.5, 3.0), amp: dr.range(0.03, 0.06) * (dr.chance(0.5) ? 1 : -1)))
                }
                if let (fp, fdir, fn, _) = front, dr.chance(rules.mowShare ?? 0) {
                    let across = fdir
                    var lo2 = Double.infinity, hi2 = -Double.infinity
                    for ring in rings { for q in ring where simd_dot(q - fp, fn) > 0.5 { lo2 = min(lo2, simd_dot(q, across)); hi2 = max(hi2, simd_dot(q, across)) } }
                    if hi2 - lo2 >= 5 {
                        let n = max(2, min(4, Int(((hi2 - lo2) / 3.2).rounded())))
                        let w = max(2.5, min(4, (hi2 - lo2) / Double(n)))
                        let start = (lo2 + hi2) / 2 - w * Double(n) / 2
                        field.mow = .init(across: across, start: start, width: w, count: n, amp: 0.03, front: (fp, fn))
                        stats["mowedLots", default: 0] += 1
                    }
                }
                var access: [([LocalPoint], Double)] = []
                if let w = walks[idx] { access.append((w, 0.55)) }
                for d in driveways[idx] ?? [] { access.append((d, 1.5)) }
                for (line, half) in access where dr.chance(rules.wornEdges ?? 0) {
                    let a = line[0], b = line[line.count - 1]
                    let len = simd_distance(a, b)
                    guard len >= 4 else { continue }
                    let u = (b - a) / len
                    let part = dr.range(0.4, 0.7) * len
                    let t0 = dr.range(0.5, max(0.6, len - part - 0.5))
                    field.worn.append(.init(a: a, u: u, len: len, halfHard: half, side: dr.chance(0.5) ? 1 : -1,
                                            width: dr.range(0.3, 0.7), t0: t0, t1: t0 + part))
                    stats["wornEdges", default: 0] += 1
                }
            }
            lawnJobs.append(LawnJob(rings: rings, field: field, detailed: detailed, anchor: anchor, feature: "gen:lot:\(s.building.ref)"))
            stats["lots", default: 0] += 1
            // Garden front (bed colour) and paved rear (concrete), traced like the lawn.
            for (on, paint, y, key) in [(garden, Paint(slot: n("yardBed"), shade: Float(fr.range(0.975, 1.025))), GroundLayer.yardBed, "garden"),
                                        (paved, Paint(slot: n("driveway"), shade: Float(fr.range(0.96, 1.02))), GroundLayer.driveway, "paving")] where on {
                let wantFront = key == "garden"
                var m = MeshBuffers()
                m.paint = paint
                for ring in raster.outlines(ri, rj, tolerance: 0.8, inside: { k in owned(k) && cellFront(k) == wantFront }) {
                    let tri = Earcut.triangulate(Polygon2D(outer: ring))
                    for t in stride(from: 0, to: tri.indices.count - 2, by: 3) {
                        m.addFace([tri.vertices[tri.indices[t]], tri.vertices[tri.indices[t + 1]], tri.vertices[tri.indices[t + 2]]].map { P($0, y) },
                                  facing: sceneUp)
                    }
                }
                addStatic(m, "gen:\(key):\(s.building.ref)", at: anchor)
                stats[key == "garden" ? "gardens" : "pavedYards", default: 0] += 1
            }

            // Front walk.
            if let walk = walks[idx] {
                var m = Ribbon.build(walk, width: 1.1, y: GroundLayer.walk)
                m.repaint(from: 0, Paint(slot: n("sidewalk"), shade: 0.97, flags: .sidewalk))
                addStatic(m, "gen:walk:\(s.building.ref)", at: anchor)
                scene.clutter.blockedLines.append((walk, 1.1))
                scene.litterHints.append(LitterHint(kind: .walkEdge, line: walk, weight: 0.5))
                stats["walks", default: 0] += 1
            }

            let near = inFocus(anchor)

            // Foundation beds: along the front wall (skipping the door), depth 0.6–1.2 m toward the
            // zone's bed area, with short returns along the side walls when the front alone is short.
            if near, let (fp, dir, fn, len) = front, len >= 4, r.chance(rules.beds), let fe = g.frontEdge {
                var m = MeshBuffers()
                m.paint = Paint(slot: n("yardBed"), shade: Float(r.range(0.975, 1.025)))
                let doorS = g.entry.map { simd_dot($0.point - fp, dir) } ?? -10
                var spans: [(Double, Double)] = doorS > 0 ? [(0.3, doorS - 0.9), (doorS + 0.9, len - 0.3)] : [(0.3, len - 0.3)]
                spans = spans.filter { $0.1 - $0.0 >= 1.0 }
                let frontLen = spans.reduce(0) { $0 + $1.1 - $1.0 }
                let target = rules.bedArea.map { r.range($0) } ?? frontLen
                let depth = min(1.2, max(0.6, target / max(frontLen, 1)))
                var area = 0.0
                for (a, b) in spans {
                    let q = [fp + dir * a, fp + dir * b, fp + dir * b + fn * depth, fp + dir * a + fn * depth]
                    if q.allSatisfy({ raster.useAt($0) != .road && raster.useAt($0) != .walkway }) {
                        m.addFace(q.map { P($0, GroundLayer.yardBed) }, facing: sceneUp)
                        area += (b - a) * depth
                    }
                }
                // Side returns at the front corners.
                let ring = s.building.footprint.outer
                for (e, fromStart) in [((fe + 1) % ring.count, true), ((fe + ring.count - 1) % ring.count, false)] where area < target - 1 {
                    let (sp, sdir, sn, slen) = BuildingGenerator.edge(ring, e)
                    guard abs(simd_dot(sdir, fn)) > 0.7, slen >= 2 else { continue }
                    let run = min(3.0, slen - 0.5, (target - area) / depth)
                    guard run >= 0.8 else { continue }
                    let a = fromStart ? 0.2 : slen - 0.2 - run, b = a + run
                    let q = [sp + sdir * a, sp + sdir * b, sp + sdir * b + sn * depth, sp + sdir * a + sn * depth]
                    guard q.allSatisfy({ raster.useAt($0) == .open || raster.useAt($0) == .building }) else { continue }
                    m.addFace(q.map { P($0, GroundLayer.yardBed) }, facing: sceneUp)
                    area += run * depth
                }
                if !m.isEmpty {
                    addStatic(m, "gen:bed:\(s.building.ref)", at: anchor)
                    stats["beds", default: 0] += 1
                    stats["bedSquareMeters", default: 0] += Int(area)
                }
            }

            // Bushes keep clear of carriageways, walkways and walls.
            func clear(_ p: LocalPoint) -> Bool {
                !raster.nearUse(p, .road, radius: 1.2) && !raster.nearUse(p, .walkway, radius: 0.4) && !raster.nearUse(p, .building, radius: 1.0)
            }
            // Shrubs: a flowering pair at the walk, a few more near the lot edges in front.
            if near {
                var placed: [LocalPoint] = []
                var shr = s.building.ref.random("yard-shrubs")
                if walks[idx] != nil, let (_, dir, _, _) = front, let entry = g.entry {
                    for sx in [-1.0, 1.0] {
                        let p = entry.point + entry.normal * 1.7 + dir * (sx * 1.05)
                        if raster.useAt(p) == .open, clear(p) { placed.append(p) }
                    }
                }
                let extra = rules.shrubs.count >= 2 ? rules.shrubs[0] + Int(shr.next() % UInt64(max(1, rules.shrubs[1] - rules.shrubs[0] + 1))) : 1
                var tries = 0
                while placed.count < extra + 2, tries < 160 {
                    tries += 1
                    let i = l.x + Int(shr.next() % UInt64(h.x - l.x + 1)), j = l.y + Int(shr.next() % UInt64(h.y - l.y + 1))
                    let k = raster.index(i, j)
                    guard raster.owner[k] == Int32(idx), raster.use[k] == LotRaster.Use.open.rawValue else { continue }
                    let p = raster.center(i, j)
                    guard isFrontYard(p), raster.isEdge(i, j, owner: Int32(idx)) || raster.nearUse(p, .building, radius: 2.5), !raster.nearUse(p, .hard, radius: 1.5),
                          !raster.nearUse(p, .building, radius: 1.2), clear(p), placed.allSatisfy({ simd_distance($0, p) > 1.8 }) else { continue }
                    placed.append(p)
                }
                for (k, p) in placed.enumerated() {
                    var rr = s.building.ref.random("yard-shrub-\(k)")
                    instances.append(PropInstance(kind: rr.chance(0.35) ? .flowerBush : .bush, variant: rr.chance(0.5) ? 0 : 1,
                                                  source: "gen:shrub:\(s.building.ref):\(k)", x: p.x, y: p.y, height: 0,
                                                  yaw: rr.range(0, 6.28), scale: rr.range(0.75, 1.15)))
                }
                stats["shrubs", default: 0] += placed.count

                // Hedges: along the front lot line (behind the sidewalk) and one side lot line in front.
                var hr = s.building.ref.random("yard-hedge")
                var rows: [[LocalPoint]] = []
                if hr.chance(rules.frontHedge) {
                    rows += raster.edgeRuns(l, h, owner: Int32(idx)) { k in raster.use[k] == LotRaster.Use.walkway.rawValue }
                }
                if hr.chance(rules.sideHedge) {
                    rows += raster.edgeRuns(l, h, owner: Int32(idx)) { k in
                        let o = raster.owner[k]
                        return o > Int32(idx) && raster.use[k] == LotRaster.Use.open.rawValue && eligible.contains(Int(o))
                    }.map { $0.filter(isFrontYard) }
                }
                var hedgeCount = 0
                let variant = hr.chance(0.5) ? 0 : 1
                for row in rows where row.count >= 3 {
                    var lastP: LocalPoint?
                    var line: [LocalPoint] = []
                    for p in row where !raster.nearUse(p, .hard, radius: 1.2) && clear(p) {
                        if let q = lastP, simd_distance(q, p) < 0.85 { continue }
                        lastP = p
                        line.append(p)
                        instances.append(PropInstance(kind: .bush, variant: variant, source: "gen:hedge:\(s.building.ref):\(hedgeCount)",
                                                      x: p.x, y: p.y, height: 0, yaw: hr.range(0, 6.28), scale: hr.range(1.0, 1.12)))
                        hedgeCount += 1
                    }
                    if line.count >= 2 { scene.litterHints.append(LitterHint(kind: .hedge, line: line, weight: 0.8)) }
                }
                stats["hedgeBushes", default: 0] += hedgeCount

                // A planted front garden: low shrubs spread through it.
                if garden {
                    var gr = s.building.ref.random("yard-garden")
                    var gardenShrubs: [LocalPoint] = []
                    for j in l.y...h.y { for i in l.x...h.x {
                        let k = raster.index(i, j)
                        guard owned(k), raster.use[k] == LotRaster.Use.open.rawValue, cellFront(k), gr.chance(0.3) else { continue }
                        let p = raster.center(i, j) + LocalPoint(gr.range(-0.3, 0.3), gr.range(-0.3, 0.3))
                        guard !raster.nearUse(p, .walkway, radius: 0.5), !raster.nearUse(p, .road, radius: 1.2), !raster.nearUse(p, .building, radius: 0.8),
                              gardenShrubs.allSatisfy({ simd_distance($0, p) > 1.5 }) else { continue }
                        gardenShrubs.append(p)
                    } }
                    for (k, p) in gardenShrubs.enumerated() {
                        var rr = s.building.ref.random("garden-shrub-\(k)")
                        instances.append(PropInstance(kind: rr.chance(0.2) ? .flowerBush : .bush, variant: rr.chance(0.5) ? 0 : 1,
                                                      source: "gen:shrub:\(s.building.ref):g\(k)", x: p.x, y: p.y, height: 0,
                                                      yaw: rr.range(0, 6.28), scale: rr.range(0.6, 0.9)))
                    }
                    stats["shrubs", default: 0] += gardenShrubs.count
                }

                // Fences: low iron along the front lot line, wooden privacy on the alley side.
                var fc = s.building.ref.random("yard-fence")
                var fence = MeshBuffers()
                if fc.chance(rules.frontFence ?? 0) {
                    let runs = raster.edgeRuns(l, h, owner: Int32(idx)) { k in raster.use[k] == LotRaster.Use.walkway.rawValue }
                    for run in runs { addFence(run.filter { !raster.nearUse($0, .hard, radius: 0.9) }, iron: true, palette: palette, into: &fence) }
                    stats["frontFences", default: 0] += 1
                }
                if fc.chance(rules.rearFence ?? 0) {
                    let runs = raster.edgeRuns(l, h, owner: Int32(idx)) { k in
                        raster.use[k] == LotRaster.Use.road.rawValue
                            && context.alleyIndex.nearest(to: raster.center(k % raster.w, k / raster.w), within: 3) != nil
                    }
                    for run in runs { addFence(run.filter { !raster.nearUse($0, .hard, radius: 0.9) && !raster.nearUse($0, .building, radius: 0.8) },
                                               iron: false, palette: palette, into: &fence) }
                    stats["rearFences", default: 0] += 1
                }
                addStatic(fence, "gen:fence:\(s.building.ref)", at: anchor)
            }

            // Specimen trees, back yard preferred, clear of walls, walks and other crowns.
            var tr = s.building.ref.random("yard-trees")
            let mean = rules.yardTreesPerHouse
            let wanted = min(Int(mean) + (tr.chance(mean - Double(Int(mean))) ? 1 : 0), rules.maxYardTreesPerLot ?? 3)
            var planted = 0, tries = 0
            while planted < wanted, tries < 60 {
                tries += 1
                let i = l.x + Int(tr.next() % UInt64(h.x - l.x + 1)), j = l.y + Int(tr.next() % UInt64(h.y - l.y + 1))
                let k = raster.index(i, j)
                guard raster.owner[k] == Int32(idx), raster.use[k] == LotRaster.Use.open.rawValue else { continue }
                let p = raster.center(i, j)
                if isFrontYard(p), tr.chance(0.55) { continue }
                guard !raster.nearUse(p, .building, radius: 3.5), !raster.nearUse(p, .hard, radius: 1.5),
                      !raster.nearUse(p, .road, radius: 2), !trees.near(p, 7) else { continue }
                let inst = treeInstance(zoneProfile, random: &tr, at: p, source: "gen:yardtree:\(s.building.ref):\(planted)", trees: trees)
                trees.insert(p, kind: inst.kind, variant: inst.variant)
                instances.append(inst)
                scene.clutter.blockedPoints.append(p)
                planted += 1
            }
            stats["yardTrees", default: 0] += planted
            lotTrees[idx] = planted
            scene.lots.append(lot)
        }

        let t3 = Date()
        // Parkway trees: between curb and sidewalk, by the zone's spacing, clear of crossings,
        // drives, walks and mapped trees (mapped trees count first).
        let roadLines = SegmentIndex(features.roads.filter { $0.kind.isVehicular && $0.kind != .service && $0.kind != .track }.map(\.centerline))
        var streetTrees = 0
        for road in features.roads where road.kind.isVehicular && road.kind != .service && road.kind != .track
            && road.kind != .motorway && road.kind != .trunk && !road.isBridge && !road.isTunnel {
            var along = 0.0
            var next = -1.0
            for (a, b) in zip(road.centerline, road.centerline.dropFirst()) {
                let d = b - a
                let len = simd_length(d)
                guard len > 0.5 else { continue }
                let u = d / len, nrm = LocalPoint(-u.y, u.x)
                let zone = zones?.profile(at: a) ?? profile
                guard let spacing = library.rules(for: zone.id).streetTreeSpacing else { along += len; continue }
                let minStrip = library.rules(for: zone.id).minParkway
                if next < 0 { next = spacing / 2 }
                while next <= along + len {
                    let t = next - along
                    next += spacing
                    let c = a + u * t
                    // Not near intersections (another street's centerline close by).
                    if let hit = roadLines.nearest(to: c, within: 10), simd_dot(hit.direction, u).magnitude < 0.9 { continue }
                    for side in [-1.0, 1.0] {
                        var rr = StableRandom(UInt64(bitPattern: road.ref.id), UInt64(Int(next * 10)) &+ (side > 0 ? 1 : 2), salt: "street-tree")
                        let edge = road.width / 2 + 0.2
                        // Find the sidewalk across the planting strip.
                        var walkAt: Double?
                        var dd = edge
                        while dd < edge + 7 {
                            let q = c + nrm * (side * dd)
                            if let use = raster.useAt(q) {
                                if use == .walkway { walkAt = dd; break }
                                if use == .building || use == .blocked { break }
                            }
                            dd += 0.25
                        }
                        let offset: Double
                        if let w = walkAt {
                            let strip = w - edge
                            guard strip >= minStrip else { continue }
                            offset = edge + strip / 2
                        } else {
                            offset = edge + 2.2
                        }
                        let p = c + nrm * (side * offset) + u * rr.range(-0.8, 0.8)
                        guard let use = raster.useAt(p), use == .open, !raster.nearUse(p, .hard, radius: 1.8), !raster.nearUse(p, .building, radius: 3),
                              !raster.nearUse(p, .road, radius: 0.8),
                              !trees.near(p, 7) else { continue }
                        let inst = treeInstance(zone, random: &rr, at: p, source: "gen:streettree:\(road.ref):\(streetTrees)", street: true, trees: trees)
                        trees.insert(p, kind: inst.kind, variant: inst.variant)
                        instances.append(inst)
                        scene.clutter.blockedPoints.append(p)
                        streetTrees += 1
                    }
                }
                along += len
            }
        }
        stats["streetTrees"] = streetTrees
        stats["canopyTrees"] = plantForCanopy(raster, eligible: eligible, lo: lo, hi: hi, count: count, byIndex: byIndex, library: library,
                                              lotTrees: &lotTrees, trees: &trees, instances: &instances, scene: &scene)
        // Lot lawns and parkways, now that every tree, hedge and shrub is placed.
        let pools = GroundPools(instances)
        var lawnTris = 0
        for job in lawnJobs {
            var lawn: MeshBuffers
            if job.detailed {
                lawn = GroundDetail.lawnMesh(job.rings, field: job.field, pools: pools, slot: n("lawn"), y: GroundLayer.yard)
            } else {
                lawn = GroundDetail.plainLawn(job.rings, field: job.field, slot: n("lawn"), y: GroundLayer.yard)
            }
            lawnTris += lawn.triangleCount
            addStatic(lawn, job.feature, at: job.anchor)
        }
        stats["lawnTriangles"] = lawnTris
        if lod == 0 {
            let park = GroundDetail.parkways(features.roads, raster: raster, roadLines: roadLines, pools: pools, slot: n("lawn"),
                                             include: { self.focus.expanded(by: 30).contains($0) })
            stats["parkwayTriangles"] = park.triangleCount
            // One feature per chunk so chunk meshes keep their ranges local.
            var byChunk: [SIMD2<Int>: MeshBuffers] = [:]
            var t = 0
            while t + 2 < park.indices.count {
                let i0 = Int(park.indices[t])
                let p = LocalPoint(Double(park.positions[i0].x), -Double(park.positions[i0].z))
                var m = byChunk[chunkIndex(p)] ?? MeshBuffers()
                let base = UInt32(m.positions.count)
                for k in 0..<3 {
                    let i = Int(park.indices[t + k])
                    m.positions.append(park.positions[i]); m.normals.append(park.normals[i])
                    m.paints.append(park.paints[i]); m.extras.append(park.extras[i])
                }
                m.indices.append(contentsOf: [base, base + 1, base + 2])
                byChunk[chunkIndex(p)] = m
                t += 3
            }
            for (key, m) in byChunk.sorted(by: { ($0.key.x, $0.key.y) < ($1.key.x, $1.key.y) }) {
                guard chunks[key] != nil else { continue }
                let start = chunks[key]!.staticMesh.vertexCount
                chunks[key]!.staticMesh.append(m)
                chunks[key]!.staticFeatures.append(FeatureRange(feature: "gen:parkway:\(key.x)_\(key.y)", start: start, count: m.vertexCount))
            }
        }
        scene.litterPatches = litterPatches(instances, raster: raster)
        stats["litterPatches"] = scene.litterPatches.count
        let t4 = Date()
        stats["yardMsRaster"] = Int(t1.timeIntervalSince(t0) * 1000)
        stats["yardMsAssign"] = Int(t2.timeIntervalSince(t1) * 1000)
        stats["yardMsLots"] = Int(t3.timeIntervalSince(t2) * 1000)
        stats["yardMsStreet"] = Int(t4.timeIntervalSince(t3) * 1000)
        // Curbs collect leaves too.
        for road in features.roads where road.kind == .residential || road.kind == .tertiary || road.kind == .unclassified {
            scene.litterHints.append(LitterHint(kind: .curb, line: road.centerline, weight: Float(road.width / 2)))
        }
        for (k, v) in stats { scene.stats[k] = v }
    }

    /// Extra yard trees toward the area profile's measured canopy share (P1, NAIP), until the
    /// target × `canopyFill` or the `maxTreesPerKm2` budget ceiling is reached. Back yards first,
    /// one tree per lot per round, so cover spreads instead of filling one lot.
    // swiftlint:disable:next function_parameter_count
    func plantForCanopy(_ raster: LotRaster, eligible: Set<Int>, lo: [Int: SIMD2<Int>], hi: [Int: SIMD2<Int>], count: [Int: Int],
                        byIndex: [Int: YardSubject], library: YardLibrary, lotTrees: inout [Int: Int], trees: inout TreeGrid, instances: inout [PropInstance],
                        scene: inout GeneratedScene) -> Int {
        let rules = library.rules(for: profile.id)
        guard let measured = profile.trees.canopyShare, let fill = rules.canopyFill, fill > 0 else { return 0 }
        let target = measured * fill
        let area = features.bounds.width * features.bounds.height
        let maxTrees = Int((rules.maxTreesPerKm2 ?? .infinity) * area / 1e6)
        // Crown cover on a 2 m grid.
        let res = 2.0
        let gw = Int(features.bounds.width / res) + 1, gh = Int(features.bounds.height / res) + 1
        var cover = [Bool](repeating: false, count: gw * gh)
        var coveredCells = 0
        func addCrown(_ p: LocalPoint, _ r: Double) {
            let cx = (p.x - features.bounds.min.x) / res, cy = (p.y - features.bounds.min.y) / res, rr = r / res
            for j in max(0, Int(cy - rr))...min(gh - 1, Int(cy + rr)) { for i in max(0, Int(cx - rr))...min(gw - 1, Int(cx + rr)) {
                let dx = Double(i) + 0.5 - cx, dy = Double(j) + 0.5 - cy
                if dx * dx + dy * dy <= rr * rr, !cover[j * gw + i] { cover[j * gw + i] = true; coveredCells += 1 }
            } }
        }
        func crownRadius(_ inst: PropInstance) -> Double { Double(PropLibrary.lobes(inst.kind).radii.x) * inst.scale * 1.15 }
        var total = 0
        for inst in instances where inst.kind.isTree { addCrown(LocalPoint(inst.x, inst.y), crownRadius(inst)); total += 1 }
        var share: Double { Double(coveredCells) / Double(gw * gh) }
        var added = 0
        let lots = eligible.sorted().filter { (count[$0] ?? 0) >= 40 }
        var round = 0
        while share < target, total < maxTrees, round < 6 {
            round += 1
            var plantedThisRound = 0
            for idx in lots {
                guard share < target, total < maxTrees, let l = lo[idx], let h = hi[idx], let s = byIndex[idx] else { break }
                let cap = library.rules(for: s.generated.profileID ?? profile.id).maxYardTreesPerLot ?? 3
                guard lotTrees[idx, default: 0] < cap else { continue }
                var r = s.building.ref.random("canopy-\(round)")
                let zoneProfile = zones?.profiles[s.generated.profileID ?? profile.id] ?? profile
                for _ in 0..<24 {
                    let i = l.x + Int(r.next() % UInt64(h.x - l.x + 1)), j = l.y + Int(r.next() % UInt64(h.y - l.y + 1))
                    let k = raster.index(i, j)
                    guard raster.owner[k] == Int32(idx), raster.use[k] == LotRaster.Use.open.rawValue else { continue }
                    let p = raster.center(i, j)
                    guard !raster.nearUse(p, .building, radius: 4), !raster.nearUse(p, .hard, radius: 1.5), !raster.nearUse(p, .road, radius: 2.5),
                          !trees.near(p, 8) else { continue }
                    let inst = treeInstance(zoneProfile, random: &r, at: p, source: "gen:canopytree:\(s.building.ref):\(round)", trees: trees)
                    trees.insert(p, kind: inst.kind, variant: inst.variant)
                    lotTrees[idx, default: 0] += 1
                    instances.append(inst)
                    scene.clutter.blockedPoints.append(p)
                    addCrown(p, crownRadius(inst))
                    total += 1
                    added += 1
                    plantedThisRound += 1
                    break
                }
            }
            if plantedThisRound == 0 { break }
        }
        return added
    }

    /// A fence along ordered points (lot-edge cell centres), split where the run has gaps.
    /// Iron: posts, two rails and bars (1.1 m). Wood privacy: posts and solid boards (1.75 m).
    func addFence(_ pts: [LocalPoint], iron: Bool, palette: Palette, into m: inout MeshBuffers) {
        guard pts.count >= 2 else { return }
        let height = iron ? 1.1 : 1.75
        m.paint = iron ? Paint(slot: palette.named("metal")) : Paint(slot: palette.named("fenceWood"))
        var segments: [[LocalPoint]] = [[pts[0]]]
        for p in pts.dropFirst() {
            if simd_distance(segments[segments.count - 1].last!, p) > 1.6 { segments.append([p]) } else { segments[segments.count - 1].append(p) }
        }
        for seg in segments where seg.count >= 2 {
            let a = seg.first!, b = seg.last!
            let d = b - a
            let len = simd_length(d)
            guard len >= 1.5 else { continue }
            let u = d / len
            // Posts.
            let postEvery = iron ? 2.0 : 2.4
            let posts = max(1, Int((len / postEvery).rounded()))
            for k in 0...posts {
                let c = a + u * (len * Double(k) / Double(posts))
                m.addBox(center: c, u: u, halfLength: iron ? 0.04 : 0.06, halfWidth: iron ? 0.04 : 0.06, z0: 0, z1: height + (iron ? 0.05 : 0.08))
            }
            if iron {
                for z in [0.12, height - 0.08] { m.addBox(center: (a + b) / 2, u: u, halfLength: len / 2, halfWidth: 0.02, z0: z, z1: z + 0.04) }
                let bars = Int(len / 0.16)
                let nrm = LocalPoint(-u.y, u.x)
                for k in 1..<max(2, bars) {
                    let c = a + u * (len * Double(k) / Double(bars))
                    for side in [-1.0, 1.0] {
                        let o = nrm * (side * 0.008)
                        m.addFace([P(c - u * 0.012 + o, 0.12), P(c + u * 0.012 + o, 0.12), P(c + u * 0.012 + o, height), P(c - u * 0.012 + o, height)],
                                  facing: D(nrm * side))
                    }
                }
            } else {
                m.addBox(center: (a + b) / 2, u: u, halfLength: len / 2, halfWidth: 0.03, z0: 0.05, z1: height)
            }
        }
    }

    /// Walks from `start` along `dir` until a cell of a stopping use; nil if it hits a building,
    /// blocked land or another lot first.
    func march(_ raster: LotRaster, from start: LocalPoint, dir: LocalPoint, maxLength: Double, owner: Int32?,
               stopAt: Set<LotRaster.Use>) -> LocalPoint? {
        var t = 0.0
        while t <= maxLength {
            let p = start + dir * t
            guard let use = raster.useAt(p) else { return nil }
            if stopAt.contains(use) { return t >= 1.0 ? p : nil }
            if use == .building || use == .blocked || use == .hard { if t > 0.6 { return nil } }
            if let owner, use == .open {
                let o = raster.ownerAt(p)
                if o >= 0, o != owner { return nil }
            }
            t += 0.25
        }
        return nil
    }

    /// A tree from a profile's species and size rules (like mapped trees without tags).
    func treeInstance(_ p: StyleProfile, random r: inout StableRandom, at pos: LocalPoint, source: String, street: Bool = false,
                      trees: TreeGrid? = nil) -> PropInstance {
        let isConifer = !street && !r.chance(p.trees.deciduousShare)
        let young = r.chance(street ? p.trees.youngShare * 1.5 : p.trees.youngShare)
        let height = young ? r.range(p.trees.youngHeightMeters) : r.range(p.trees.heightMeters)
        let kind: PropKind
        if isConifer {
            kind = .conifer
        } else {
            let w = p.trees.crownWeights
            let pick = r.pick(w.keys.sorted()) { w[$0] ?? 0 }
            kind = pick == "oval" ? .treeOval : pick == "spreading" ? .treeSpreading : .treeBroad
        }
        // Look-fix §5: no repeated silhouette among the nearest three trees of the same form.
        let count = PropLibrary.variants[kind] ?? 1
        var variant = 0
        if count > 1 {
            let avoid = Set(trees?.nearestVariants(pos, kind: kind, count: 3) ?? [])
            let options = (0..<count).filter { !avoid.contains($0) }
            let pool = options.isEmpty ? Array(0..<count) : options
            variant = pool[Int(r.next() % UInt64(pool.count))]
        }
        return PropInstance(kind: kind, variant: variant, source: source, x: pos.x, y: pos.y, height: 0, yaw: r.range(0, 6.28), scale: height)
    }

    /// Fall leaf-litter patches: 1–3 per deciduous tree within its crown, radius 0.4–1.2 m, on open
    /// ground or paving, never on carriageways or in buildings (look-fix §1.3).
    func litterPatches(_ instances: [PropInstance], raster: LotRaster) -> [LitterPatch] {
        var out: [LitterPatch] = []
        for inst in instances where inst.kind.isTree && inst.kind != .conifer {
            var r = StableRandom(UInt64(bitPattern: Int64((inst.x * 100).rounded())), UInt64(bitPattern: Int64((inst.y * 100).rounded())), salt: "litter")
            let crown = Double(PropLibrary.lobes(inst.kind).radii.x) * inst.scale
            let n = 1 + Int(r.next() % 3)
            for _ in 0..<n {
                let a = r.range(0, 2 * .pi), d = r.range(0.2, 0.7) * crown
                let c = LocalPoint(inst.x + cos(a) * d, inst.y + sin(a) * d)
                let radius = r.range(0.4, 1.2), tone = Int(r.next() % 3)
                guard let use = raster.useAt(c), use != .road, use != .building, use != .blocked,
                      !raster.nearUse(c, .road, radius: radius) else { continue }
                out.append(LitterPatch(x: c.x, y: c.y, radius: radius, tone: tone, tree: inst.source))
            }
        }
        return out
    }
}

/// Trees on a coarse grid: "is there a tree within d", and the variants of the nearest ones.
struct TreeGrid {
    struct Item { var p: LocalPoint; var kind: PropKind?; var variant: Int }
    let cell: Double
    var cells: [SIMD2<Int>: [Item]] = [:]
    init(cell: Double) { self.cell = cell }
    func key(_ p: LocalPoint) -> SIMD2<Int> { SIMD2(Int((p.x / cell).rounded(.down)), Int((p.y / cell).rounded(.down))) }
    mutating func insert(_ p: LocalPoint, kind: PropKind? = nil, variant: Int = 0) { cells[key(p), default: []].append(Item(p: p, kind: kind, variant: variant)) }
    func near(_ p: LocalPoint, _ d: Double) -> Bool {
        let k = key(p)
        for dx in -1...1 { for dy in -1...1 {
            for q in cells[k &+ SIMD2(dx, dy)] ?? [] where simd_distance(p, q.p) < d { return true }
        } }
        return false
    }
    /// Variants of the nearest `count` trees of the same kind within two cells.
    func nearestVariants(_ p: LocalPoint, kind: PropKind, count: Int) -> [Int] {
        let k = key(p)
        var items: [Item] = []
        for dx in -2...2 { for dy in -2...2 { items += (cells[k &+ SIMD2(dx, dy)] ?? []).filter { $0.kind == kind } } }
        return items.sorted { simd_distance($0.p, p) < simd_distance($1.p, p) }.prefix(count).map(\.variant)
    }
}

extension LotRaster {
    /// Marks open cells within `width / 2` of a polyline as hard ground (walks, drives).
    mutating func markHard(line: [LocalPoint], width: Double) {
        let hw = width / 2
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len2 = max(simd_length_squared(d), 1e-12)
            guard let (ri, rj) = range(Rect2D(enclosing: [a, b]).expanded(by: hw + res)) else { continue }
            for j in rj { for i in ri {
                let p = center(i, j)
                let t = min(1, max(0, simd_dot(p - a, d) / len2))
                guard simd_distance(p, a + d * t) <= hw else { continue }
                let k = index(i, j)
                if use[k] == Use.open.rawValue { use[k] = Use.hard.rawValue }
            } }
        }
    }

    /// True if any cell of `u` lies within `radius` of `p`.
    func nearUse(_ p: LocalPoint, _ u: Use, radius: Double) -> Bool {
        guard let (ri, rj) = range(Rect2D(min: p - LocalPoint(radius, radius), max: p + LocalPoint(radius, radius))) else { return false }
        for j in rj { for i in ri where use[index(i, j)] == u.rawValue && simd_distance(center(i, j), p) <= radius + res * 0.5 { return true } }
        return false
    }

    /// True if an owned cell has a 4-neighbor outside the lot.
    func isEdge(_ i: Int, _ j: Int, owner o: Int32) -> Bool {
        for (di, dj) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
            let ni = i + di, nj = j + dj
            guard ni >= 0, nj >= 0, ni < w, nj < h else { return true }
            if owner[index(ni, nj)] != o { return true }
        }
        return false
    }

    /// Owned cells next to cells matching `other`, grouped into straight-ish runs of centers.
    func edgeRuns(_ lo: SIMD2<Int>, _ hi: SIMD2<Int>, owner o: Int32, other: (Int) -> Bool) -> [[LocalPoint]] {
        var pts: [LocalPoint] = []
        for j in lo.y...hi.y { for i in lo.x...hi.x {
            let k = index(i, j)
            guard owner[k] == o, use[k] == Use.open.rawValue else { continue }
            var touches = false
            for (di, dj) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let ni = i + di, nj = j + dj
                if ni >= 0, nj >= 0, ni < w, nj < h, other(index(ni, nj)) { touches = true; break }
            }
            if touches { pts.append(center(i, j)) }
        } }
        guard pts.count >= 2 else { return [] }
        // Order along the main direction of the points, split at gaps.
        let c = pts.reduce(LocalPoint.zero, +) / Double(pts.count)
        var sxx = 0.0, sxy = 0.0, syy = 0.0
        for p in pts { let d = p - c; sxx += d.x * d.x; sxy += d.x * d.y; syy += d.y * d.y }
        let angle = 0.5 * atan2(2 * sxy, sxx - syy)
        let axis = LocalPoint(cos(angle), sin(angle))
        let sorted = pts.sorted { simd_dot($0 - c, axis) < simd_dot($1 - c, axis) }
        var runs: [[LocalPoint]] = [[sorted[0]]]
        for p in sorted.dropFirst() {
            if simd_distance(runs[runs.count - 1].last!, p) > 1.6 { runs.append([p]) } else { runs[runs.count - 1].append(p) }
        }
        return runs
    }
}
