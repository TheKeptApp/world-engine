import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

// Facade pass (5B gate gaps 1 and 5): family window sizes, entry kits (portico, vestibule,
// arched surround), masonry sills and lintels, mapped and inferred street bays, side-wall window
// rhythm; side walls (gap 5): chimney breasts, gangway window stacks, mapped side bays.
// Everything is switched on per family in house-families.json and seeded with its own salts, so
// buildings without these fields come out exactly as before.

/// A street bay: mapped (faces of the footprint) or inferred (a shallow volume added in front of
/// the facade). Plan points are local; `faces` are wall segments with outward normals.
struct FacadeBay {
    var edge: Int
    var s0: Double, s1: Double
    var depth: Double
    var angled: Bool
    /// Stories that carry windows on the bay faces.
    var stories: Int
    /// Wall top of the bay and the hip cap rise above it (0 = flat cap).
    var top: Double
    var capRise: Double
}

/// A chimney on a long side wall: a shallow masonry breast from the ground to just under the eave,
/// then the stack through the eave to above the roof. `s` is its center along the edge.
struct SideBreast {
    var edge: Int
    var s: Double
    var width: Double
    var depth: Double
    var tall: Bool
    var broad: Bool
}

extension BuildingGenerator {
    // MARK: - Clearance

    /// True when the ground in front of a wall segment (s0…s1, out to `depth`) is clear of this
    /// footprint, other buildings, roads (plus `roadMargin` beyond the carriageway) and mapped sidewalks.
    func frontClear(_ c: BuildContext, origin p: LocalPoint, dir: LocalPoint, n: LocalPoint, s0: Double, s1: Double,
                    depth: Double, roadMargin: Double) -> Bool {
        let ss = [s0, (s0 + s1) / 2, s1]
        var ts: [Double] = [0.3]
        var t = 0.3
        while t < depth { t = min(depth, t + 0.8); ts.append(t) }
        for s in ss {
            for t in ts {
                let q = p + dir * s + n * t
                if c.b.footprint.contains(q) { return false }
                if let obstacles, obstacles.contains(q, margin: 0.15) { return false }
                if let h = context.roadIndex.nearest(to: q, within: 25), h.distance < context.roads[h.line].width / 2 + roadMargin { return false }
                if context.sidewalkIndex.nearest(to: q, within: 1.0) != nil { return false }
            }
        }
        return true
    }

    /// Lowest point an added element in front of a wall may reach up to without touching the
    /// main roof (its overhang included): roof top minus a 0.3 m soffit allowance. Infinite when
    /// no roof overhangs the spot.
    func roofCeiling(_ c: BuildContext, origin p: LocalPoint, dir: LocalPoint, n: LocalPoint, s0: Double, s1: Double, depth: Double) -> Double {
        guard let env = c.envelope else { return .infinity }
        var best = Double.infinity
        for k in 0...4 {
            let s = s0 + (s1 - s0) * Double(k) / 4
            for t in [0.02, depth / 2, depth] {
                if let h = env.height(at: p + dir * s + n * t) { best = min(best, h - 0.3) }
            }
        }
        return best
    }

    // MARK: - Entry kits

    /// Colonial portico: raised platform with steps, two or four square columns, an entablature
    /// beam and a small pediment (or a flat roof where the main eave is too low). Returns its
    /// half-width along the wall, or nil when it doesn't fit (then the old entry is used).
    func addPortico(_ c: BuildContext, edge e: Int, doorS: Double, into m: inout MeshBuffers) -> Double? {
        let (p, dir, n, len) = Self.edge(c.ring, e)
        var r = c.b.ref.random("portico")
        let four = len >= 13 && r.chance(0.35)
        var hw = four ? r.range(1.6, 1.8) : r.range(1.15, 1.35)
        let depth = r.range(1.3, 1.55)
        hw = min(hw, doorS - 0.2, len - 0.2 - doorS)
        guard hw >= 1.0 else { return nil }
        let F = c.F
        let stepRun = 0.15 + 0.3 * Double(max(1, Int((F / 0.18).rounded())))
        guard frontClear(c, origin: p, dir: dir, n: n, s0: doorS - hw, s1: doorS + hw, depth: depth + stepRun, roadMargin: 0.6) else { return nil }
        let ceiling = roofCeiling(c, origin: p, dir: dir, n: n, s0: doorS - hw - 0.1, s1: doorS + hw + 0.1, depth: depth + 0.1)
        var colTop = F + 2.7
        let beam = 0.24
        let rise = (hw + 0.06) * tan(24 * Double.pi / 180)
        var pediment = colTop + beam + rise + 0.05 <= ceiling
        if !pediment {
            colTop = min(colTop, ceiling - beam - 0.08)
            guard colTop >= F + 2.3 else { return nil }
            // A pediment still fits over a lowered beam?
            pediment = colTop + beam + rise + 0.05 <= ceiling && colTop >= F + 2.55
        }
        let near = c.lod == .near
        let mid = dir * doorS
        let start = m.positions.count
        // Platform (and steps near).
        if F > 0.05 {
            m.paint = c.foundation
            m.addBox(center: p + mid + n * (depth / 2), u: dir, halfLength: hw, halfWidth: depth / 2, z0: 0, z1: F)
        }
        if near { addSteps(at: p + mid + n * depth, dir: dir, n: n, width: min(2 * hw - 0.4, 1.8), height: F, foundation: c.foundation, into: &m) }
        // Columns (near only): square posts at the front, two or four.
        m.paint = c.trim
        if near {
            let edgeS = hw - 0.17
            var cols = [-edgeS, edgeS]
            if four { cols += [-edgeS / 3, edgeS / 3] }
            for s in cols {
                let at = p + dir * (doorS + s) + n * (depth - 0.17)
                if c.grammar.details?.columnCaps == true {
                    // Slender shaft with one simplified base and capital (house-details-v1 Colonial).
                    m.addBox(center: at, u: dir, halfLength: 0.15, halfWidth: 0.15, z0: F, z1: F + 0.22)
                    addPrism(at: at, u: dir, half: 0.105, z0: F + 0.22, z1: colTop - 0.2, topHalf: 0.09, into: &m)
                    m.addBox(center: at, u: dir, halfLength: 0.15, halfWidth: 0.15, z0: colTop - 0.2, z1: colTop, bottom: true)
                } else {
                    m.addBox(center: at, u: dir, halfLength: 0.11, halfWidth: 0.11, z0: F, z1: colTop)
                }
            }
            // Pilasters where the beam meets the wall.
            for sx in [-1.0, 1.0] {
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: doorS + sx * edgeS - 0.11, s1: doorS + sx * edgeS + 0.11, z0: F, z1: colTop, offset: 0.04)
            }
        }
        // Entablature beam, closed underneath (the porch ceiling).
        m.addBox(center: p + mid + n * (depth / 2), u: dir, halfLength: hw, halfWidth: depth / 2, z0: colTop, z1: colTop + beam, bottom: true)
        if pediment {
            addPediment(at: p + mid, dir: dir, n: n, z: colTop + beam, paint: c.trim, roof: c.roof,
                        halfWidth: hw + 0.06, depth: depth + 0.06, rise: rise, into: &m)
        } else {
            Roofs.slab(OrientedRect(center: p + mid + n * (depth / 2), u: dir, halfLength: hw, halfWidth: depth / 2),
                       z: colTop + beam, thickness: 0.1, overhang: 0.06, paint: c.roof, into: &m)
        }
        m.bakeAO(from: start) { pos, nn in
            if nn.y < -0.5 { return 0.68 }
            return Float(0.8 + 0.2 * smoothstep(F, F + 0.6, Double(pos.y)))
        }
        return hw
    }

    /// Tudor entry vestibule: a small projecting steep-gabled porch with an arched door. Its
    /// ridge runs back into the main wall, or under the main roof when the gable would reach the
    /// eave. Returns its half-width, or nil when it doesn't fit.
    func addVestibule(_ c: BuildContext, edge e: Int, doorS: Double, into m: inout MeshBuffers) -> Double? {
        let (p, dir, n, len) = Self.edge(c.ring, e)
        var r = c.b.ref.random("vestibule")
        var hw = r.range(0.95, 1.15)
        let depth = r.range(1.0, 1.3)
        let k = tan(r.range(48, 54) * Double.pi / 180)
        hw = min(hw, doorS - 0.25, len - 0.25 - doorS)
        guard hw >= 0.85 else { return nil }
        let F = c.F, ov = 0.12
        let zv = F + 2.45, peak = zv + hw * k
        let stepRun = 0.15 + 0.3 * Double(max(1, Int((F / 0.18).rounded())))
        guard frontClear(c, origin: p, dir: dir, n: n, s0: doorS - hw - ov, s1: doorS + hw + ov, depth: depth + ov + stepRun, roadMargin: 0.6)
        else { return nil }
        let ceiling = roofCeiling(c, origin: p, dir: dir, n: n, s0: doorS - hw - ov, s1: doorS + hw + ov, depth: depth + ov)
        var back = -0.02
        if peak + 0.05 > ceiling {
            // Bury the ridge under the main roof, inside the footprint.
            guard let env = c.envelope else { return nil }
            var found: Double?
            for tb in stride(from: 0.4, through: 3.0, by: 0.2) {
                let qs = [doorS, doorS - hw - ov, doorS + hw + ov].map { p + dir * $0 - n * tb }
                guard qs.allSatisfy({ c.b.footprint.contains($0) }) else { break }
                if let h = env.height(at: qs[0]), h >= peak + 0.15 { found = tb; break }
            }
            guard let tb = found else { return nil }
            back = -tb
        }
        let near = c.lod == .near
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(p + dir * (doorS + s) + n * t, z) }
        let start = m.positions.count
        // Walls: foundation band (near), body, stucco gable triangle on the front.
        let z0 = near ? F : 0
        if near, F > 0.05 {
            m.paint = c.foundation
            m.addCleanFace([q(-hw, depth, 0), q(hw, depth, 0), q(hw, depth, F), q(-hw, depth, F)], facing: D(n))
            for sx in [-1.0, 1.0] {
                m.addCleanFace([q(sx * hw, 0, 0), q(sx * hw, depth, 0), q(sx * hw, depth, F), q(sx * hw, 0, F)], facing: D(dir * sx))
            }
        }
        m.paint = c.wall
        m.addCleanFace([q(-hw, depth, z0), q(hw, depth, z0), q(hw, depth, zv), q(-hw, depth, zv)], facing: D(n))
        for sx in [-1.0, 1.0] {
            m.addCleanFace([q(sx * hw, 0, z0), q(sx * hw, depth, z0), q(sx * hw, depth, zv), q(sx * hw, 0, zv)], facing: D(dir * sx))
        }
        m.paint = c.grammar.facade?.gablePanel == true || c.grammar.facade?.halfTimber == true ? Paint(slot: c.panel.slot, shade: 0.97) : c.wall
        m.addCleanFace([q(-hw, depth, zv), q(hw, depth, zv), q(0, depth, peak)], facing: D(n))
        // Roof: two steep planes from the front rake back to the wall (or under the main roof).
        m.paint = c.roof
        let ze = zv - ov * k
        for sx in [-1.0, 1.0] {
            let face = [q(sx * (hw + ov), depth + ov, ze), q(sx * (hw + ov), back, ze), q(0, back, peak), q(0, depth + ov, peak)]
            m.addCleanFace(face, facing: sceneUp + D(dir * sx))
            if near {
                // Underside (seen only through the overhang).
                m.paint = Paint(slot: c.trim.slot, shade: 0.9)
                m.addCleanFace(face, facing: -sceneUp - D(dir * sx))
                m.paint = c.roof
            }
        }
        // Arched door with a stone surround.
        let t = depth
        if near {
            m.paint = c.trim
            m.addCleanFace([q(-0.62, t + 0.025, F), q(0.62, t + 0.025, F), q(0.62, t + 0.025, F + 1.95), q(0, t + 0.025, F + 2.32),
                            q(-0.62, t + 0.025, F + 1.95)], facing: D(n))
        }
        m.paint = c.door
        m.addCleanFace([q(-0.45, t + 0.045, F), q(0.45, t + 0.045, F), q(0.45, t + 0.045, F + 1.8), q(0, t + 0.045, F + 2.12),
                        q(-0.45, t + 0.045, F + 1.8)], facing: D(n))
        if near { addSteps(at: p + dir * doorS + n * depth, dir: dir, n: n, width: 1.2, height: F, foundation: c.foundation, into: &m) }
        m.bakeAO(from: start) { pos, nn in
            if nn.y < -0.5 { return 0.7 }
            return Float(0.75 + 0.25 * smoothstep(0, F + 0.5, Double(pos.y)))
        }
        return hw
    }

    /// An arched stone door surround on the wall (Tudor fallback when no vestibule fits).
    func addArchedDoor(_ c: BuildContext, origin p: LocalPoint, dir: LocalPoint, n: LocalPoint, doorS: Double, into m: inout MeshBuffers) {
        func q(_ s: Double, _ off: Double, _ z: Double) -> SIMD3<Float> { P(p + dir * (doorS + s) + n * off, z) }
        let F = c.F
        if c.lod == .near {
            m.paint = c.trim
            m.addCleanFace([q(-0.62, 0.025, F), q(0.62, 0.025, F), q(0.62, 0.025, F + 1.95), q(0, 0.025, F + 2.32), q(-0.62, 0.025, F + 1.95)],
                           facing: D(n))
        }
        m.paint = c.door
        m.addCleanFace([q(-0.45, 0.045, F), q(0.45, 0.045, F), q(0.45, 0.045, F + 1.8), q(0, 0.045, F + 2.12), q(-0.45, 0.045, F + 1.8)],
                       facing: D(n))
    }

    // MARK: - Bays

    /// Protrusions of the mapped footprint on the street side: a street-parallel face 0.9–5 m
    /// long between two short side faces, standing 0.25–1.8 m in front of the walls beside it.
    /// The front-door edge is never a bay (an entry projection). Returns [side, front, side] edges.
    func mappedBays(_ ring: Ring, front: Int?, streetFacing: Set<Int>) -> [[Int]] {
        guard let f = front, ring.count >= 6 else { return [] }
        let fn = Self.edge(ring, f).2
        return streetFacing.sorted().filter { $0 != f }.compactMap { protrusion(ring, $0, facing: fn) }
    }

    /// A face `e` of the footprint 0.9–5 m long, facing along `fn`, between two short (≤ 2.2 m)
    /// side or 45° faces, standing 0.25–1.8 m in front of the walls beside it: [side, e, side].
    func protrusion(_ ring: Ring, _ e: Int, facing fn: LocalPoint) -> [Int]? {
        let count = ring.count
        func mid(_ i: Int) -> LocalPoint { let (p, d, _, l) = Self.edge(ring, i); return p + d * (l / 2) }
        let (_, _, ne, le) = Self.edge(ring, e)
        guard simd_dot(ne, fn) > 0.9, le >= 0.9, le <= 5 else { return nil }
        let a = (e + count - 1) % count, b = (e + 1) % count
        let a2 = (e + count - 2) % count, b2 = (e + 2) % count
        guard a != b, a2 != b, b2 != a else { return nil }
        for (side, beyond) in [(a, a2), (b, b2)] {
            let (_, _, ns, ls) = Self.edge(ring, side)
            let dot = simd_dot(ns, fn)
            let nb = Self.edge(ring, beyond).2
            let setback = simd_dot(mid(e) - mid(beyond), fn)
            if ls > 2.2 || dot > 0.85 || dot < -0.3 || simd_dot(nb, fn) < 0.9 || setback < 0.25 || setback > 1.8 { return nil }
        }
        return [a, e, b]
    }

    /// Where an inferred bay goes on the front edge: beside the entry, within the family's width
    /// and depth, under the roof, and only where the 2.5 m in front of the facade is clear of
    /// other buildings, roads and sidewalks.
    func planBay(_ c: BuildContext, _ g: GeneratedBuilding, doorSpan: (edge: Int, s0: Double, s1: Double)?, winH: Double) -> FacadeBay? {
        guard let spec = c.grammar.facade?.bay, let e = g.frontEdge, c.mappedBays.isEmpty else { return nil }
        var r = c.b.ref.random("bay")
        guard r.chance(spec.chance ?? 1) else { return nil }
        let (p, dir, n, len) = Self.edge(c.ring, e)
        let wr = spec.width ?? [2.4, 3.2]
        var width = r.range(wr)
        let depth = min(0.6, r.range(spec.depth ?? [0.45, 0.6]))
        let angled = spec.form == "box" ? false : spec.form == "angled" ? true : r.chance(0.65)
        let chosenStories: Int? = spec.stories.flatMap { $0.isEmpty ? nil : $0[Int(r.next() % UInt64($0.count))] }
        // The larger room beside the entry.
        var rooms: [(Double, Double)] = []
        if let span = doorSpan, span.edge == e {
            rooms = [(0.45, span.s0 - 0.1), (span.s1 + 0.1, len - 0.45)]
        } else {
            rooms = [(0.45, len - 0.45)]
        }
        guard let room = rooms.max(by: { $0.1 - $0.0 < $1.1 - $1.0 }) else { return nil }
        width = min(width, room.1 - room.0)
        guard width >= (wr.first ?? 2.4) - 1e-9 else { return nil }
        let sc = (room.0 + room.1) / 2
        let s0 = sc - width / 2, s1 = sc + width / 2
        guard frontClear(c, origin: p, dir: dir, n: n, s0: s0, s1: s1, depth: 2.5, roadMargin: 3.0) else { return nil }

        let stories = max(1, g.floors)
        let storyH = (c.H - c.F) / Double(stories)
        let ceiling = roofCeiling(c, origin: p, dir: dir, n: n, s0: s0, s1: s1, depth: depth + 0.1)
        let wallTop = c.H + c.parapet
        let rise = depth * tan(30 * Double.pi / 180)
        func topFor(_ k: Int) -> Double { c.F + Double(k) * storyH - 0.1 }
        if let k0 = chosenStories {
            // Partial height with a hip cap; drop to one story if the eave is in the way.
            for k in Swift.stride(from: min(k0, stories), through: 1, by: -1) {
                let top = topFor(k)
                if top + rise <= min(ceiling, wallTop - 0.1) {
                    return FacadeBay(edge: e, s0: s0, s1: s1, depth: depth, angled: angled, stories: k, top: top, capRise: rise)
                }
            }
            return nil
        }
        // Full height: up to the cornice of a flat roof, or under the main eave.
        if c.envelope == nil {
            let top = wallTop - (c.grammar.facade?.cornice == true ? 0.5 : 0)
            return FacadeBay(edge: e, s0: s0, s1: s1, depth: depth, angled: angled, stories: stories, top: top, capRise: 0)
        }
        let top = min(wallTop, ceiling) - rise
        var k = stories
        while k > 0, !(c.F + Double(k - 1) * storyH + 0.8 + 0.8 <= top - 0.3) { k -= 1 }
        guard k > 0 else { return nil }
        return FacadeBay(edge: e, s0: s0, s1: s1, depth: depth, angled: angled, stories: k, top: top, capRise: rise)
    }

    /// The bay's plan points A (wall), B, C (front), D (wall).
    func bayPlan(_ c: BuildContext, _ bay: FacadeBay) -> [LocalPoint] {
        let (p, dir, n, _) = Self.edge(c.ring, bay.edge)
        let inset = bay.angled ? bay.depth : 0
        return [p + dir * bay.s0, p + dir * (bay.s0 + inset) + n * bay.depth, p + dir * (bay.s1 - inset) + n * bay.depth, p + dir * bay.s1]
    }

    /// Bay volume (walls from the ground, flat or hip cap), its fascia, and windows on every face.
    func emitBay(_ c: BuildContext, _ bay: FacadeBay, win: (w: Double, h: Double), lit: Float, into m: inout MeshBuffers) {
        let near = c.lod == .near
        let pts = bayPlan(c, bay)
        let (p, dir, n, _) = Self.edge(c.ring, bay.edge)
        let F = c.F, top = bay.top
        let stories = max(1, bay.stories)
        let floorH = (c.H - F) / Double(max(1, c.floors))
        let start = m.positions.count
        var faces: [(LocalPoint, LocalPoint, LocalPoint, LocalPoint, Double)] = [] // start, dir, normal, end, length
        for i in 0..<3 {
            let a = pts[i], b = pts[i + 1]
            let d = b - a
            let l = simd_length(d)
            guard l > 1e-6 else { continue }
            let u = d / l
            faces.append((a, u, LocalPoint(u.y, -u.x), b, l))
        }
        // Walls.
        for f in faces {
            if near, F > 0.05 {
                m.paint = c.foundation
                m.addCleanFace([P(f.0, 0), P(f.3, 0), P(f.3, F), P(f.0, F)], facing: D(f.2))
            }
            m.paint = c.wall
            let z0 = near ? F : 0
            m.addCleanFace([P(f.0, z0), P(f.3, z0), P(f.3, top), P(f.0, top)], facing: D(f.2))
        }
        m.bakeAO(from: start) { pos, _ in Float(0.72 + 0.28 * smoothstep(0, max(F, 0.6) + 0.3, Double(pos.y))) }
        // Cap.
        let capStart = m.positions.count
        if bay.capRise <= 0 {
            m.paint = c.roof
            m.addCleanFace(pts.map { P($0, top) }, facing: sceneUp)
        } else {
            let inset = bay.angled ? bay.depth : 0
            let a2 = p + dir * (bay.s0 + inset), d2 = p + dir * (bay.s1 - inset)
            let zr = top + bay.capRise
            m.paint = c.roof
            m.addCleanFace([P(pts[1], top), P(pts[2], top), P(d2, zr), P(a2, zr)], facing: sceneUp + D(n))
            m.paint = bay.angled ? c.roof : c.wall
            m.addCleanFace([P(pts[0], top), P(pts[1], top), P(a2, zr)], facing: (bay.angled ? sceneUp : .zero) + D(faces[0].2))
            m.addCleanFace([P(pts[2], top), P(pts[3], top), P(d2, zr)], facing: (bay.angled ? sceneUp : .zero) + D(faces[faces.count - 1].2))
        }
        // Fascia band under the cap (near).
        if near {
            m.paint = Paint(slot: c.trim.slot, shade: 0.95)
            for f in faces {
                m.addWallQuad(origin: f.0, dir: f.1, normal: f.2, s0: 0, s1: f.4, z0: top - 0.24, z1: top, offset: 0.03)
            }
        }
        m.bakeAO(from: capStart) { _, _ in 0.95 }
        // Windows on each face, per story.
        let lintel = c.grammar.facade?.lintels == true && near ? c.trim : nil
        for story in 0..<stories {
            let z0 = F + Double(story) * floorH + (story == 0 ? 0.85 : 0.8)
            let z1 = min(z0 + win.h, F + Double(story + 1) * floorH - 0.35, top - 0.3)
            guard z1 - z0 > 0.6 else { continue }
            for (i, f) in faces.enumerated() {
                let front = i == 1 || faces.count == 1
                var w: Double
                var mullions = 1
                if front {
                    w = bay.angled ? min(f.4 - 0.4, max(win.w, 0.9)) : min(f.4 - 0.5, win.w * 2 + 0.12)
                    if !bay.angled, w > win.w * 1.5 { mullions = 2 }
                } else {
                    w = f.4 - 0.3
                    if w > win.w { w = win.w }
                }
                guard w > 0.42 else { continue }
                var wr = StableRandom(UInt64(bay.edge), UInt64(story * 31 + 100 + i), salt: "lit")
                m.extra = SIMD4(1, min(0.999, lit * 0.6 + Float(wr.unit()) * 0.4), 0, 0)
                addWindow(origin: f.0, dir: f.1, normal: f.2, sCenter: f.4 / 2, width: w, z0: z0, z1: z1, glass: c.glass, trim: c.trim, reveal: c.reveal,
                          frames: near, mullions: mullions, lintel: f.4 >= w + 0.38 ? lintel : nil, into: &m)
                m.extra = SIMD4(1, 0, 0, 0)
            }
        }
    }

    // MARK: - Window layouts

    /// Symmetric front (Colonial / Georgian): window bays mirrored about the centered door, the
    /// same columns on every story (clear of the entry), spread evenly to 0.6 m from the corners,
    /// and one window over the door upstairs. Returns offsets from the door (0 = over the door).
    func symmetricOffsets(len: Double, doorS: Double, minPitch: Double, width: Double, entryHalf: Double, story: Int) -> [Double] {
        let limit = min(doorS, len - doorS) - 0.6 - width / 2
        let first = max(minPitch, entryHalf + 0.05 + width / 2)
        var out: [Double] = story > 0 ? [0] : []
        guard first <= limit + 1e-9 else { return out }
        let k = 1 + Int((limit - first) / minPitch)
        let step = k > 1 ? min(3.4, (limit - first) / Double(k - 1)) : 0
        for i in 0..<k { out += [-(first + Double(i) * step), first + Double(i) * step] }
        return out.sorted()
    }

    /// Long side wall rhythm: groups of one to three windows at the same positions on every
    /// story, with blank stretches between; nothing on a wall that touches a neighbor.
    func sideRhythmCenters(_ c: BuildContext, edge e: Int, width w: Double) -> [(center: Double, width: Double, count: Int)] {
        let (p, dir, n, len) = Self.edge(c.ring, e)
        // Party wall: another building right outside the middle of the wall.
        if let obstacles {
            let probes = [0.25, 0.5, 0.75].map { p + dir * (len * $0) + n * 0.4 }
            if probes.filter({ obstacles.contains($0) && !c.b.footprint.contains($0) }).count >= 2 { return [] }
        }
        var r = c.b.ref.random("side-rhythm-\(e)")
        let usable = len - 0.9
        let groups = max(2, Int(usable / 6.5))
        let cell = usable / Double(groups)
        var out: [(center: Double, width: Double, count: Int)] = []
        let skip = groups >= 3 && r.chance(0.35) ? 1 + Int(r.next() % UInt64(groups - 2)) : -1
        for gi in 0..<groups {
            let roll = r.unit()
            let count = roll < 0.6 ? 2 : roll < 0.85 ? 1 : 3
            guard gi != skip else { continue }
            let gw = Double(count) * w + Double(count - 1) * 0.4
            guard gw <= cell - 0.7 else { continue }
            let slack = (cell - gw) / 2 - 0.35
            let center = 0.45 + cell * (Double(gi) + 0.5) + r.range(-1, 1) * max(0, slack) * 0.6
            out.append((center, gw, count))
        }
        return out
    }

    // MARK: - Side walls (gap 5)

    /// Clear distance to the neighbour that makes a side wall a gangway wall.
    static let gangwayGap = 0.9...3.1

    /// A side wall: not on the street side and roughly perpendicular to the front wall.
    func isSideWall(_ c: BuildContext, _ e: Int, front: Int?) -> Bool {
        guard let f = front, e != f, !c.streetFacing.contains(e) else { return false }
        return abs(simd_dot(Self.edge(c.ring, f).2, Self.edge(c.ring, e).2)) < 0.5
    }

    /// Clear distance from a wall straight out to the next building, probed at 20, 50 and 80 % of
    /// its length: the median of the three. Infinity when nothing stands within `reach`; 0 when the
    /// own footprint is in the way (a concave corner is never a gangway or open ground).
    func sideGap(_ c: BuildContext, edge e: Int, reach: Double = 4) -> Double {
        guard let obstacles else { return .infinity }
        let (p, dir, n, len) = Self.edge(c.ring, e)
        var gaps: [Double] = []
        for f in [0.2, 0.5, 0.8] {
            let base = p + dir * (len * f)
            var gap = Double.infinity
            var t = 0.1
            while t <= reach + 1e-9 {
                let q = base + n * t
                if c.b.footprint.contains(q) { gap = 0; break }
                if obstacles.contains(q) { gap = t; break }
                t += 0.2
            }
            gaps.append(gap)
        }
        return gaps.sorted()[1]
    }

    /// Where the gangway window stacks go along a side wall: one near the middle of the depth, or
    /// (walls ≥ 14 m, half of them) two, toward the front third (stairs) and the back (bath).
    func gangwayStackCenters(_ c: BuildContext, edge e: Int, width w: Double) -> [Double] {
        let len = Self.edge(c.ring, e).3
        var r = c.b.ref.random("gangway-\(e)")
        let fracs = len >= 14 && r.chance(0.5) ? [r.range(0.25, 0.35), r.range(0.6, 0.72)] : [r.range(0.4, 0.6)]
        return fracs.map { min(max(len * $0, w / 2 + 0.6), len - w / 2 - 0.6) }
            .filter { !breastCovers(c, edge: e, s: $0, width: w) }
    }

    /// True when a window centered at `s` (width `width`) on edge `e` would touch the chimney breast.
    func breastCovers(_ c: BuildContext, edge e: Int, s: Double, width: Double) -> Bool {
        guard let br = c.breast, br.edge == e else { return false }
        return abs(s - br.s) < br.width / 2 + width / 2 + 0.25
    }

    /// Mapped protrusions on side walls (a face parallel to its side wall between two short faces).
    func sideBayEdges(_ ring: Ring, front: Int?, streetFacing: Set<Int>) -> [[Int]] {
        guard let f = front, ring.count >= 6 else { return [] }
        let fn = Self.edge(ring, f).2
        return (0..<ring.count).filter { e in
            e != f && !streetFacing.contains(e) && abs(simd_dot(Self.edge(ring, e).2, fn)) < 0.3
        }.compactMap { protrusion(ring, $0, facing: Self.edge(ring, $0).2) }
    }

    /// The chimney as a side-wall breast: only when the family's chimney roll (the roof chimney's
    /// own draw) succeeds, the family's breast chance passes, and a long side wall (≥ 12 m) has
    /// open ground (3 m clear of buildings, roads and sidewalks) at the family's chimney position.
    func planChimneyBreast(_ c: BuildContext, front: Int?) -> SideBreast? {
        guard let chance = c.grammar.facade?.chimneyBreast, chance > 0, c.lod <= .mid, let env = c.envelope,
              let plan = c.plan, plan.clip == nil, let f = front else { return nil }
        let rr = c.grammar.roof
        var roll = c.b.ref.random("chimney")
        guard roll.chance(rr?.chimney ?? profile.chimneyLikelihood) else { return nil }
        var r = c.b.ref.random("chimney-breast")
        guard r.chance(chance) else { return nil }
        let width = r.range(1.2, 1.8), depth = r.range(0.25, 0.4)
        // Depth position from the front follows the family's chimney placement.
        let want: Double = switch rr?.chimneyPlacement {
        case "front": r.range(0.25, 0.4)
        case "rear": r.range(0.6, 0.75)
        default: r.range(0.4, 0.6)
        }
        let fn = Self.edge(c.ring, f).2
        var walls = (0..<c.ring.count).filter { isSideWall(c, $0, front: f) && Self.edge(c.ring, $0).3 >= 12 }
        if walls.count > 1, r.chance(0.5) { walls.reverse() }
        for e in walls {
            let (p, dir, n, len) = Self.edge(c.ring, e)
            var s = simd_dot(dir, fn) <= 0 ? len * want : len * (1 - want)
            s = min(max(s, width / 2 + 0.8), len - width / 2 - 0.8)
            guard env.height(at: p + dir * s - n * 0.3) != nil,
                  frontClear(c, origin: p, dir: dir, n: n, s0: s - width / 2 - 0.3, s1: s + width / 2 + 0.3, depth: 3.0, roadMargin: 0.6)
            else { continue }
            return SideBreast(edge: e, s: s, width: width, depth: depth, tall: rr?.chimneyTall == true, broad: rr?.chimneyBroad == true)
        }
        return nil
    }
}
