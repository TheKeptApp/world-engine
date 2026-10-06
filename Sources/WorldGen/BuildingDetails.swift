import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

// Family details on top of walls and roofs (regions-chicagoland-miami §3–§5, §12). All seeded per
// building with their own salts, so adding a detail never reshuffles another.

extension BuildingGenerator {
    // MARK: - Roof details: chimney, dormers

    /// Adds the chimney and dormers the family asks for, skipping lower-priority pieces that
    /// would exceed `budget` triangles. Returns the triangles added.
    func addRoofDetails(_ c: BuildContext, _ g: inout GeneratedBuilding, palette: inout Palette, budget: Int, into m: inout MeshBuffers) -> Int {
        guard g.role == .house, let env = c.envelope, let plan = c.plan, plan.clip == nil else { return 0 }
        let main = plan.masses[plan.main]
        let rr = c.grammar.roof
        var used = 0

        // Chimney first: one cuboid plus cap (cap only near).
        var r = c.b.ref.random("chimney")
        if r.chance(rr?.chimney ?? profile.chimneyLikelihood) {
            var piece = MeshBuffers()
            if addChimney(c, main: main, plan: plan, env: env, placement: rr?.chimneyPlacement ?? "end",
                          tall: rr?.chimneyTall == true, broad: rr?.chimneyBroad == true, rng: &r, palette: &palette, into: &piece),
               used + piece.triangleCount <= budget {
                m.append(piece)
                used += piece.triangleCount
                g.hasChimney = true
            }
        }

        // Dormers on the street-facing slope, near only.
        guard c.lod == .near, let range = rr?.dormers, range.count >= 2, main.pitch >= 24, plan.frontSign != 0 else { return used }
        var d = c.b.ref.random("dormers")
        guard d.chance(rr?.dormerChance ?? 0) else { return used }
        let count = range[0] + Int(d.next() % UInt64(max(1, range[1] - range[0] + 1)))
        let width = d.range(rr?.dormerWidth ?? [1.0, 1.4])
        let L = main.halfLength
        let spots: [Double] = count >= 2 ? [-L * 0.45, L * 0.45] : [0]
        for s in spots {
            var piece = MeshBuffers()
            guard addDormer(c, main: main, mainIndex: plan.main, env: env, sign: plan.frontSign, s: s, width: width, into: &piece),
                  used + piece.triangleCount <= budget else { continue }
            m.append(piece)
            used += piece.triangleCount
            g.dormers += 1
        }
        return used
    }

    // swiftlint:disable:next function_parameter_count
    func addChimney(_ c: BuildContext, main: RoofMass, plan: RoofPlan, env: RoofEnvelope, placement: String, tall: Bool, broad: Bool,
                    rng: inout StableRandom, palette: inout Palette, into m: inout MeshBuffers) -> Bool {
        let L = main.halfLength, W = main.halfWidth
        let side: Double = rng.chance(0.5) ? 1 : -1
        let front = plan.frontSign == 0 ? 1 : plan.frontSign
        var (s, t): (Double, Double)
        switch placement {
        case "front": (s, t) = (side * (L - 0.75), front * max(0.4, W - 1.0))
        case "central": (s, t) = (rng.range(-0.25, 0.25) * L, rng.range(0.15, 0.45) * W * side)
        case "rear": (s, t) = (side * L * rng.range(0.25, 0.55), -front * W * 0.45)
        default: (s, t) = (side * (L - 0.6), 0.3 * side)
        }
        let hl = broad ? 0.55 : 0.32, hw = broad ? 0.38 : 0.42
        let center = main.point(s, t)
        let corners = [main.point(s - hl, t - hw), main.point(s + hl, t - hw), main.point(s + hl, t + hw), main.point(s - hl, t + hw)]
        guard corners.allSatisfy({ c.b.footprint.contains($0) }) else { return false }
        let heights = corners.compactMap { env.height(at: $0) }
        guard heights.count == 4 else { return false }
        let ridge = env.topHeight
        var top = heights.max()! + (tall ? 1.5 : 0.9)
        if abs(t) < 2.5 { top = max(top, ridge + (tall ? 0.9 : 0.5)) }
        if tall { top = max(top, ridge + 0.6) }
        let base = heights.min()! - 0.3
        m.paint = Paint(slot: palette.named("chimney"))
        m.addBox(center: center, u: main.axis, halfLength: hl, halfWidth: hw, z0: base, z1: top)
        if c.lod == .near {
            m.paint = Paint(slot: palette.named("chimney"), shade: 0.82)
            m.addBox(center: center, u: main.axis, halfLength: hl + 0.07, halfWidth: hw + 0.07, z0: top, z1: top + 0.12, bottom: true)
        }
        return true
    }

    /// A gable dormer on the main roof's street-facing slope: front wall with one window, two cheek
    /// walls and a small gable roof, all running back into the main roof (no interior faces shown).
    func addDormer(_ c: BuildContext, main: RoofMass, mainIndex: Int, env: RoofEnvelope, sign σ: Double, s: Double, width w: Double,
                   into m: inout MeshBuffers) -> Bool {
        let H = main.eave, W = main.halfWidth, L = main.halfLength, k = main.slope
        let setback = 0.6
        let tf = W - setback                     // |t| of the front wall
        let zb = H + setback * k                 // main roof height at the front wall
        var ed = zb + 1.25
        let od = 0.12
        var rd = ed + (w / 2) * max(k, tan(35 * .pi / 180))
        let maxRidge = main.ridgeHeight - 0.35
        if rd > maxRidge {
            ed -= rd - maxRidge
            rd = maxRidge
        }
        guard ed - zb >= 0.9 else { return false }
        let tr = W - (rd - H) / k                // where the dormer ridge meets the main roof
        let te = W - (ed - H) / k
        guard tr > 0.2 else { return false }
        // Stay on the plain slope: inside the gable ends / hip lines and clear of other masses.
        let reach = main.form == .hip ? (L - W) + tr : L
        guard abs(s) + w / 2 + 0.3 <= reach else { return false }
        let plan = [main.point(s - w / 2 - od, σ * (tf + od)), main.point(s + w / 2 + od, σ * (tf + od)),
                    main.point(s + w / 2 + od, σ * tr), main.point(s - w / 2 - od, σ * tr)]
        for (j, other) in env.masses.enumerated() where j != mainIndex {
            let hp = ConvexClip.halfPlanes(other.domain)
            if !ConvexClip.intersect(ConvexClip.ccw(plan), hp).isEmpty { return false }
        }
        func pt(_ ss: Double, _ tt: Double, _ z: Double) -> SIMD3<Float> { P(main.point(ss, σ * tt), z) }
        let out = D(main.across * σ)
        let kd = (rd - ed) / (w / 2)
        // Front wall.
        m.paint = c.wall
        m.addCleanFace([pt(s - w / 2, tf, zb - 0.15), pt(s + w / 2, tf, zb - 0.15), pt(s + w / 2, tf, ed), pt(s, tf, rd), pt(s - w / 2, tf, ed)],
                       facing: out)
        // Cheeks: their sloped lower edge runs 0.15 m under the main roof.
        let te2 = te - 0.15 / k
        for sx in [-1.0, 1.0] {
            let x = s + sx * w / 2
            m.addCleanFace([pt(x, tf, zb - 0.15), pt(x, tf, ed), pt(x, te2, ed)], facing: D(main.axis * sx))
        }
        // Roof planes, ridge buried into the main roof at the back.
        m.paint = c.roof
        let back = max(0.05, tr - 0.25)
        for sx in [-1.0, 1.0] {
            let xe = s + sx * (w / 2 + od), ze = ed - od * kd
            m.addCleanFace([pt(xe, tf + od, ze), pt(xe, back, ze), pt(s, back, rd), pt(s, tf + od, rd)],
                           facing: sceneUp + D(main.axis * sx))
        }
        // Window.
        let origin = main.point(s - w / 2, σ * tf)
        let dir = main.axis * (σ > 0 ? -1.0 : 1.0)
        let n = main.across * σ
        let s0 = σ > 0 ? w : 0.0
        func along(_ x: Double) -> Double { σ > 0 ? s0 - x : x }
        m.paint = c.trim
        m.addWallQuad(origin: origin, dir: dir, normal: n, s0: min(along(0.12), along(w - 0.12)), s1: max(along(0.12), along(w - 0.12)),
                      z0: zb + 0.08, z1: ed - 0.06, offset: 0.02)
        m.paint = c.glass
        m.addWallQuad(origin: origin, dir: dir, normal: n, s0: min(along(0.24), along(w - 0.24)), s1: max(along(0.24), along(w - 0.24)),
                      z0: zb + 0.2, z1: ed - 0.16, offset: 0.04)
        return true
    }

    // MARK: - Facade details

    func addFacadeDetails(_ c: BuildContext, _ g: inout GeneratedBuilding, into m: inout MeshBuffers) {
        let facade = c.grammar.facade ?? HouseFamilyGrammar.Facade()
        let ring = c.ring, near = c.lod == .near
        let stories = max(1, g.floors)
        let storyH = (c.H - c.F) / Double(stories)

        // Cornice along the street wall of flat-roofed masses.
        if facade.cornice == true, c.envelope == nil, g.roofShape == .flat {
            let top = c.H + c.parapet
            m.paint = Paint(slot: c.trim.slot, shade: 0.95)
            let start = m.positions.count
            // Around mapped street bays too, so the cornice wraps their faces.
            let bayFaces = Set(c.mappedBays.flatMap { $0 })
            for e in c.streetFacing.union(bayFaces).sorted() {
                let (p, dir, n, len) = Self.edge(ring, e)
                guard len >= 1.5 || (bayFaces.contains(e) && len >= 0.3) else { continue }
                m.addBox(center: p + dir * (len / 2) + n * 0.16, u: dir, halfLength: len / 2 + 0.16, halfWidth: 0.16,
                         z0: top - 0.5, z1: top + 0.06, bottom: true)
                if near, stories >= 2 {
                    // A quieter belt course over the ground floor.
                    m.addBox(center: p + dir * (len / 2) + n * 0.06, u: dir, halfLength: len / 2, halfWidth: 0.06,
                             z0: c.F + storyH - 0.12, z1: c.F + storyH + 0.06)
                }
            }
            m.bakeAO(from: start) { _, nn in nn.y < -0.5 ? 0.72 : 1 }
        }

        // Prairie: horizontal trim bands at floor lines and under the eaves, all the way round.
        if facade.bands == true, near {
            m.paint = c.trim
            var lines = (1..<stories).map { c.F + Double($0) * storyH - 0.06 }
            lines.append(c.H - 0.32)
            for e in 0..<ring.count {
                let (p, dir, n, len) = Self.edge(ring, e)
                guard len >= 1 else { continue }
                for z in lines { m.addWallQuad(origin: p, dir: dir, normal: n, s0: 0, s1: len, z0: z, z1: z + 0.16, offset: 0.035) }
            }
        }

        // Street-facing gables: half-timber strips and an attic window.
        if let env = c.envelope, facade.halfTimber == true || facade.attic == true {
            for e in c.streetFacing.sorted() {
                let (p, dir, n, len) = Self.edge(ring, e)
                guard len >= 2.5, let gable = Self.gable(env.profile(p, p + dir * len), length: len, eave: c.H), gable.peak - c.H >= 1.6 else { continue }
                if facade.halfTimber == true, near {
                    m.paint = Paint(slot: c.door.slot, shade: 0.8)
                    let half = (gable.s1 - gable.s0) / 2
                    m.addWallQuad(origin: p, dir: dir, normal: n, s0: gable.s0 + 0.25, s1: gable.s1 - 0.25, z0: c.H, z1: c.H + 0.2, offset: 0.04)
                    for sx in [-1.0, 1.0] {
                        let sc = gable.peakS + sx * half * 0.38
                        let zTop = gable.height(at: sc) - 0.18
                        if zTop > c.H + 0.6 {
                            m.addWallQuad(origin: p, dir: dir, normal: n, s0: sc - 0.11, s1: sc + 0.11, z0: c.H + 0.2, z1: zTop, offset: 0.04)
                        }
                    }
                }
                if facade.attic == true {
                    let z0 = c.H + 0.55, z1 = min(gable.peak - 0.9, c.H + 1.7)
                    if z1 - z0 >= 0.6 {
                        addWindow(origin: p, dir: dir, normal: n, sCenter: gable.peakS, width: 0.75, z0: z0, z1: z1,
                                  glass: c.glass, trim: c.trim, frames: near, into: &m)
                    }
                }
            }
        }

        // Shopfront: larger ground-floor openings between piers, a plain sign band above.
        if facade.storefront == true {
            for e in c.streetFacing.sorted() {
                let (p, dir, n, len) = Self.edge(ring, e)
                guard len >= 3 else { continue }
                let bays = max(1, Int(len / 3.4))
                let step = len / Double(bays)
                for k in 0..<bays {
                    let s0 = Double(k) * step + 0.35, s1 = Double(k + 1) * step - 0.35
                    m.paint = c.glass
                    m.addWallQuad(origin: p, dir: dir, normal: n, s0: s0, s1: s1, z0: c.F + 0.35, z1: c.F + 2.75, offset: 0.03)
                }
                m.paint = Paint(slot: c.door.slot, shade: 0.9)
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: 0.2, s1: len - 0.2, z0: c.F + 2.95, z1: c.F + 3.45, offset: 0.05)
            }
        }

        if let r = facade.rearPorch, r > 0 { addRearPorch(c, &g, likelihood: r, into: &m) }
    }

    /// Where an edge's wall rises above the eave into a gable: its span and peak.
    struct Gable {
        var s0: Double, s1: Double, peakS: Double, peak: Double
        var points: [(Double, Double)]
        func height(at s: Double) -> Double {
            for (a, b) in zip(points, points.dropFirst()) where s >= a.0 && s <= b.0 {
                return b.0 - a.0 > 1e-9 ? a.1 + (b.1 - a.1) * (s - a.0) / (b.0 - a.0) : a.1
            }
            return points.last?.1 ?? 0
        }
    }

    static func gable(_ spans: [ProfileSpan], length: Double, eave: Double) -> Gable? {
        var pts: [(Double, Double)] = []
        for s in spans {
            if pts.last.map({ abs($0.0 - s.t0 * length) > 1e-6 }) ?? true { pts.append((s.t0 * length, s.z0)) }
            pts.append((s.t1 * length, s.z1))
        }
        guard let top = pts.max(by: { $0.1 < $1.1 }), top.1 > eave + 0.3 else { return nil }
        // Walk out from the peak while the wall stays above the eave line.
        let i = pts.firstIndex { $0.0 == top.0 && $0.1 == top.1 }!
        var a = i, b = i
        while a > 0, pts[a - 1].1 > eave + 0.05 { a -= 1 }
        while b < pts.count - 1, pts[b + 1].1 > eave + 0.05 { b += 1 }
        return Gable(s0: pts[a].0, s1: pts[b].0, peakS: top.0, peak: top.1, points: pts)
    }

    // MARK: - Rear porch (city stacked wooden porch and stairs)

    /// Two- or three-level wooden porch on the rear wall, only where the rear faces a mapped alley
    /// and the space is clear of other buildings and the alley itself. Decks, posts, one stair
    /// run per level and solid rail bands; no balusters.
    func addRearPorch(_ c: BuildContext, _ g: inout GeneratedBuilding, likelihood: Double, into m: inout MeshBuffers) {
        guard c.lod <= .mid, g.role == .house || g.role == .block, let obstacles, let f = g.frontEdge, g.floors >= 2 else { return }
        var r = c.b.ref.random("rear-porch")
        guard r.chance(likelihood) else { return }
        let ring = c.ring
        let (_, _, fn, _) = Self.edge(ring, f)
        var rear: Int?
        for e in 0..<ring.count {
            let (_, _, n, len) = Self.edge(ring, e)
            if simd_dot(n, fn) < -0.85, len >= 4.5, len > (rear.map { Self.edge(ring, $0).3 } ?? 0) { rear = e }
        }
        guard let e = rear else { return }
        let (p, dir, n, len) = Self.edge(ring, e)
        // The rear must face a mapped alley.
        guard let alley = context.alleyEdge(of: ring, radius: 45), simd_dot(Self.edge(ring, alley).2, n) > 0.8 else { return }
        let deckW = min(len - 0.4, r.range(3.6, 4.6)), depth = r.range(2.0, 2.5), stairW = 1.0
        let total = deckW + stairW
        guard total <= len - 0.2 else { return }
        let atStart = r.chance(0.5)
        let s0 = atStart ? 0.2 : len - 0.2 - total
        // Deck first along the wall, then the stair strip.
        let deckS = atStart ? s0 : s0 + stairW
        let stairS = atStart ? s0 + deckW : s0
        // Clearance: no other building, alley or street inside the porch rectangle (+0.3 m).
        var probes: [LocalPoint] = []
        for u in [0.0, 0.5, 1.0] {
            let along: LocalPoint = p + dir * (s0 + total * u)
            probes.append(along + n * (depth * 0.3))
            probes.append(along + n * (depth + 0.3))
        }
        for q in probes {
            if obstacles.contains(q, margin: 0.3), !c.b.footprint.contains(q) { return }
            if context.alleyIndex.nearest(to: q, within: 1.5) != nil || context.roadIndex.nearest(to: q, within: 3) != nil { return }
        }
        let levels = min(3, max(2, g.floors))
        let storyH = (c.H - c.F) / Double(max(1, g.floors))
        let deckZ = (0..<levels).map { c.F + Double($0) * storyH }
        let roofZ = min(c.H - 0.2, deckZ.last! + storyH - 0.15)
        let wood = Paint(slot: c.trim.slot, shade: 0.78)
        let start = m.positions.count
        m.paint = wood
        let deckC = p + dir * (deckS + deckW / 2) + n * (depth / 2)
        for z in deckZ where z > 0.3 {
            m.addBox(center: deckC, u: dir, halfLength: deckW / 2, halfWidth: depth / 2, z0: z - 0.18, z1: z, bottom: c.lod == .near)
        }
        // Posts at the outer corners (and the middle of a wide deck).
        var postS = [deckS + 0.12, deckS + deckW - 0.12]
        if deckW > 4.2 { postS.append(deckS + deckW / 2) }
        for s in postS {
            m.addBox(center: p + dir * s + n * (depth - 0.12), u: dir, halfLength: 0.09, halfWidth: 0.09, z0: 0, z1: roofZ)
        }
        Roofs.slab(OrientedRect(center: p + dir * (s0 + total / 2) + n * (depth / 2), u: dir, halfLength: total / 2, halfWidth: depth / 2),
                   z: roofZ, thickness: 0.14, overhang: 0.1, paint: c.roof, into: &m)
        g.hasRearPorch = true
        guard c.lod == .near else { return }
        // Rail bands on the open deck edges (outer and the side away from the stairs).
        m.paint = wood
        let sideS = atStart ? deckS + 0.04 : deckS + deckW - 0.04
        for z in deckZ.dropFirst() {
            m.addBox(center: p + dir * (deckS + deckW / 2) + n * (depth - 0.04), u: dir, halfLength: deckW / 2, halfWidth: 0.04, z0: z, z1: z + 0.95)
            m.addBox(center: p + dir * sideS + n * (depth / 2), u: dir, halfLength: 0.04, halfWidth: depth / 2, z0: z, z1: z + 0.95)
        }
        // One stair run per level, switching back along the wall in the stair strip.
        let stairT0 = 0.2, stairT1 = depth - 0.2
        var fromZ = 0.0
        for (k, z) in deckZ.enumerated() where z > 0.3 {
            let lowAtWall = k % 2 == 0
            let tLow = lowAtWall ? stairT1 : stairT0, tHigh = lowAtWall ? stairT0 : stairT1
            let a = stairS + 0.05, b = stairS + stairW - 0.05
            func q(_ s: Double, _ t: Double, _ zz: Double) -> SIMD3<Float> { P(p + dir * s + n * t, zz) }
            let th = 0.2
            // Sloped slab: top, underside and two stringer sides.
            m.addCleanFace([q(a, tLow, fromZ), q(b, tLow, fromZ), q(b, tHigh, z), q(a, tHigh, z)], facing: sceneUp)
            m.addCleanFace([q(a, tLow, fromZ - th), q(b, tLow, fromZ - th), q(b, tHigh, z - th), q(a, tHigh, z - th)], facing: -sceneUp)
            for (s, sx) in [(a, -1.0), (b, 1.0)] {
                m.addCleanFace([q(s, tLow, fromZ - th), q(s, tHigh, z - th), q(s, tHigh, z + 0.1), q(s, tLow, fromZ + 0.1)], facing: D(dir * sx))
            }
            fromZ = z
        }
        m.bakeAO(from: start) { _, nn in nn.y < -0.5 ? 0.72 : 1 }
    }

    // MARK: - Small kits

    /// A small gable over a door (Colonial entry pediment).
    // swiftlint:disable:next function_parameter_count
    func addPediment(at p: LocalPoint, dir: LocalPoint, n: LocalPoint, z: Double, paint: Paint, roof: Paint,
                     halfWidth hw: Double = 0.8, depth d: Double = 0.5, rise: Double = 0.42, into m: inout MeshBuffers) {
        func q(_ s: Double, _ t: Double, _ zz: Double) -> SIMD3<Float> { P(p + dir * s + n * t, zz) }
        m.paint = paint
        m.addCleanFace([q(-hw, d, z), q(hw, d, z), q(0, d, z + rise)], facing: D(n))
        m.addCleanFace([q(-hw, 0, z), q(hw, 0, z), q(hw, d, z), q(-hw, d, z)], facing: -sceneUp)
        m.paint = roof
        m.addCleanFace([q(-hw - 0.06, d + 0.06, z - 0.03), q(0, d + 0.06, z + rise + 0.04), q(0, 0, z + rise + 0.04), q(-hw - 0.06, 0, z - 0.03)],
                       facing: sceneUp + D(-dir))
        m.addCleanFace([q(hw + 0.06, d + 0.06, z - 0.03), q(hw + 0.06, 0, z - 0.03), q(0, 0, z + rise + 0.04), q(0, d + 0.06, z + rise + 0.04)],
                       facing: sceneUp + D(dir))
    }

    /// Skyline LOD: the footprint (or its rectangle when nearly rectangular) extruded to `top`.
    func skylineMass(_ fp: Polygon2D, shape: FootprintAnalysis, top: Double, wall: Paint, roof: Paint) -> MeshBuffers {
        var m = MeshBuffers()
        let ring = shape.rectangularity >= 0.85 ? shape.obb.corners : fp.outer
        m.paint = wall
        addWalls(ring, z0: 0, z1: top, into: &m)
        m.paint = roof
        let tri = Earcut.triangulate(Polygon2D(outer: ring))
        for k in stride(from: 0, to: tri.indices.count - 2, by: 3) {
            m.addCleanFace([tri.indices[k], tri.indices[k + 1], tri.indices[k + 2]].map { P(tri.vertices[$0], top) }, facing: sceneUp)
        }
        return m
    }
}
