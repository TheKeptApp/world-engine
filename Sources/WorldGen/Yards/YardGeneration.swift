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
    /// Palette shade for this lot's lawn.
    public var lawnShade: Float
    /// Lawn care 0 (dry, patchy) … 1 (lush); renderers may bias lawn colour with it (vertex extra.y).
    public var care: Float
    public var entry: LocalPoint?
    /// Front walk from the door to the sidewalk or street.
    public var walk: [LocalPoint]?
    public var driveways: [[LocalPoint]] = []
    public var origin = "inferred"
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
        raster.assignYards(maxDistance: maxDistance)

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
        for t in features.points(of: .tree) { trees.insert(t.position) }
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

        for idx in eligible.sorted() {
            guard let c = count[idx], c >= 12, let l = lo[idx], let h = hi[idx], let s = byIndex[idx] else { continue }
            let g = s.generated
            let profileID = g.profileID ?? profile.id
            let rules = library.rules(for: profileID)
            let zoneProfile = zones?.profiles[profileID] ?? profile
            var r = s.building.ref.random("yard")
            let shade = Float(r.range(rules.lawnShade))
            let care = Float(r.range(0.25, 1.0))
            let rings = raster.outlines(max(0, l.x - 1)...min(raster.w - 1, h.x + 1), max(0, l.y - 1)...min(raster.h - 1, h.y + 1),
                                        tolerance: 0.8) { k in raster.owner[k] == Int32(idx) || raster.buildingOf[k] == Int32(idx) }
            guard !rings.isEmpty else { continue }
            let anchor = s.building.footprint.centroid
            let lot = GeneratedLot(building: s.building.ref, profileID: profileID, outline: rings, area: Double(c), lawnShade: shade, care: care,
                                   entry: g.entry?.point, walk: walks[idx], driveways: driveways[idx] ?? [])

            // Lawn.
            var lawn = MeshBuffers()
            lawn.paint = Paint(slot: n("lawn"), shade: shade, flags: .lawn)
            lawn.extra = SIMD4(1, care, 0, 0)
            for ring in rings {
                let tri = Earcut.triangulate(Polygon2D(outer: ring))
                for k in stride(from: 0, to: tri.indices.count - 2, by: 3) {
                    let a = P(tri.vertices[tri.indices[k]], GroundLayer.yard), b = P(tri.vertices[tri.indices[k + 1]], GroundLayer.yard)
                    let cc = P(tri.vertices[tri.indices[k + 2]], GroundLayer.yard)
                    let i0 = lawn.addVertex(a, normal: sceneUp), i1 = lawn.addVertex(b, normal: sceneUp), i2 = lawn.addVertex(cc, normal: sceneUp)
                    if simd_cross(b - a, cc - a).y >= 0 { lawn.addTriangle(i0, i1, i2) } else { lawn.addTriangle(i0, i2, i1) }
                }
            }
            addStatic(lawn, "gen:lot:\(s.building.ref)", at: anchor)
            stats["lots", default: 0] += 1

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
            let front = g.frontEdge.map { BuildingGenerator.edge(s.building.footprint.outer, $0) }
            func isFrontYard(_ p: LocalPoint) -> Bool {
                guard let (fp, _, fn, _) = front else { return false }
                return simd_dot(p - fp, fn) > 0.5
            }

            // Foundation bed along the front wall (near only).
            if near, let (fp, dir, fn, len) = front, len >= 4, r.chance(rules.beds) {
                var m = MeshBuffers()
                m.paint = Paint(slot: n("yardBed"))
                let doorS = g.entry.map { simd_dot($0.point - fp, dir) } ?? -10
                var spans: [(Double, Double)] = []
                if doorS > 0 { spans = [(0.3, doorS - 0.9), (doorS + 0.9, len - 0.3)] } else { spans = [(0.3, len - 0.3)] }
                for (a, b) in spans where b - a >= 1.0 {
                    let q = [fp + dir * a, fp + dir * b, fp + dir * b + fn * 1.0, fp + dir * a + fn * 1.0]
                    m.addFace(q.map { P($0, GroundLayer.yardBed) }, facing: sceneUp)
                }
                addStatic(m, "gen:bed:\(s.building.ref)", at: anchor)
                stats["beds", default: 0] += 1
            }

            // Shrubs: a flowering pair at the walk, a few more near the lot edges in front.
            if near {
                var placed: [LocalPoint] = []
                var shr = s.building.ref.random("yard-shrubs")
                if walks[idx] != nil, let (_, dir, _, _) = front, let entry = g.entry {
                    for sx in [-1.0, 1.0] {
                        let p = entry.point + entry.normal * 1.7 + dir * (sx * 1.05)
                        if raster.useAt(p) == .open { placed.append(p) }
                    }
                }
                let extra = rules.shrubs.count >= 2 ? rules.shrubs[0] + Int(shr.next() % UInt64(max(1, rules.shrubs[1] - rules.shrubs[0] + 1))) : 1
                var tries = 0
                while placed.count < extra + 2, tries < 40 {
                    tries += 1
                    let i = l.x + Int(shr.next() % UInt64(h.x - l.x + 1)), j = l.y + Int(shr.next() % UInt64(h.y - l.y + 1))
                    let k = raster.index(i, j)
                    guard raster.owner[k] == Int32(idx), raster.use[k] == LotRaster.Use.open.rawValue else { continue }
                    let p = raster.center(i, j)
                    guard isFrontYard(p), raster.isEdge(i, j, owner: Int32(idx)), !raster.nearUse(p, .hard, radius: 1.5),
                          !raster.nearUse(p, .building, radius: 1.2), placed.allSatisfy({ simd_distance($0, p) > 1.8 }) else { continue }
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
                    for p in row where !raster.nearUse(p, .hard, radius: 1.2) {
                        if let q = lastP, simd_distance(q, p) < 0.85 { continue }
                        lastP = p
                        line.append(p)
                        instances.append(PropInstance(kind: .bush, variant: variant, source: "gen:hedge:\(s.building.ref):\(hedgeCount)",
                                                      x: p.x, y: p.y, height: 0, yaw: hr.range(0, 6.28), scale: hr.range(0.78, 0.92)))
                        hedgeCount += 1
                    }
                    if line.count >= 2 { scene.litterHints.append(LitterHint(kind: .hedge, line: line, weight: 0.8)) }
                }
                stats["hedgeBushes", default: 0] += hedgeCount
            }

            // Specimen trees, back yard preferred, clear of walls, walks and other crowns.
            var tr = s.building.ref.random("yard-trees")
            let mean = rules.yardTreesPerHouse
            let wanted = Int(mean) + (tr.chance(mean - Double(Int(mean))) ? 1 : 0)
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
                trees.insert(p)
                instances.append(treeInstance(zoneProfile, random: &tr, at: p, source: "gen:yardtree:\(s.building.ref):\(planted)"))
                scene.clutter.blockedPoints.append(p)
                planted += 1
            }
            stats["yardTrees", default: 0] += planted
            scene.lots.append(lot)
        }

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
                              !trees.near(p, 7) else { continue }
                        trees.insert(p)
                        instances.append(treeInstance(zone, random: &rr, at: p, source: "gen:streettree:\(road.ref):\(streetTrees)", street: true))
                        scene.clutter.blockedPoints.append(p)
                        streetTrees += 1
                    }
                }
                along += len
            }
        }
        stats["streetTrees"] = streetTrees
        // Curbs collect leaves too.
        for road in features.roads where road.kind == .residential || road.kind == .tertiary || road.kind == .unclassified {
            scene.litterHints.append(LitterHint(kind: .curb, line: road.centerline, weight: Float(road.width / 2)))
        }
        for (k, v) in stats { scene.stats[k] = v }
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
    func treeInstance(_ p: StyleProfile, random r: inout StableRandom, at pos: LocalPoint, source: String, street: Bool = false) -> PropInstance {
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
        return PropInstance(kind: kind, variant: 0, source: source, x: pos.x, y: pos.y, height: 0, yaw: r.range(0, 6.28), scale: height)
    }
}

/// Points on a coarse grid for "is there a tree within d" checks.
struct TreeGrid {
    let cell: Double
    var cells: [SIMD2<Int>: [LocalPoint]] = [:]
    init(cell: Double) { self.cell = cell }
    func key(_ p: LocalPoint) -> SIMD2<Int> { SIMD2(Int((p.x / cell).rounded(.down)), Int((p.y / cell).rounded(.down))) }
    mutating func insert(_ p: LocalPoint) { cells[key(p), default: []].append(p) }
    func near(_ p: LocalPoint, _ d: Double) -> Bool {
        let k = key(p)
        for dx in -1...1 { for dy in -1...1 {
            for q in cells[k &+ SIMD2(dx, dy)] ?? [] where simd_distance(p, q) < d { return true }
        } }
        return false
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
