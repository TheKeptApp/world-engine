import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

// House details (docs/proposals/house-details-v1): covered porches with posts, railings and porch
// roofs; stoops and steps (cheek walls where the family has them); trim (relief casings, door
// heads, corner boards, frieze, shutters) in the family's contrasting trim colour; eave overhang
// and fascia per family; softened edges (one chamfer on street wall corners, street-facing fascia
// and rakes, cornice caps). All switched on per family by `details` in house-families.json and
// seeded with their own salts, so families without `details` come out exactly as before.
//
// Distance tiers (pack 10 / 25 / 50 m → BuildingLOD): the pack's 10 m and 25 m tiers are both
// inside `near` (0–50 m), so near models what the pack models at 25 m plus the coarse 10 m cues
// (post profile, bracket wedge, few rail uprights, relief casings, shutters, chamfers). `mid`
// (50–150 m) is the pack's 50 m tier: porch platform, plain posts/piers with their gaps, porch
// roof, the outer top rail, a stoop wedge instead of risers; no casings, shutters, uprights,
// brackets or chamfers. `far` and `skyline` are beyond the pack's range and unchanged.

extension HouseFamilyGrammar {
    /// Per-family house details (house-details-v1). All optional.
    public struct Details: Codable, Sendable, Equatable {
        /// The pack family this recipe follows (documentation; e.g. "queen_anne").
        public var pack: String?
        /// Trim colour endpoints (sRGB); one of three steps (interpolated in linear light) per house.
        /// Used for casings, door surround, corner boards, frieze, fascia, soffits and porch posts.
        public var trim: [String]?
        /// Eave overhang range in metres instead of the profile's.
        public var eave: [Double]?
        /// Fascia board depth at near (default 0.22 m).
        public var fascia: Double?
        /// Street wall corners: "board" (trim-coloured corner boards with a chamfered edge, siding
        /// families) or "chamfer" (a 4 cm chamfer strip in the wall colour, masonry families).
        public var corners: String?
        /// Relief casings on street-facing windows (projecting head and sill) and a door head.
        public var casings: Bool?
        /// A trim frieze board under the eave on street-facing walls.
        public var frieze: Bool?
        /// Paired plain shutters on street-facing windows of symmetric fronts.
        public var shutters: Shutters?
        /// Covered front porch recipe (used when the family's porch roll asks for a covered porch).
        public var porch: Porch?
        /// Stoop and steps at the door when there is no porch.
        public var stoop: Stoop?
        /// Foundation (raised floor) range in metres instead of the profile's.
        public var foundation: [Double]?
        /// One chamfer on the top outer edge of the cornice / parapet cap (near).
        public var copingBevel: Bool?
        /// Portico columns with a base and a capital block (near).
        public var columnCaps: Bool?
        /// Heavy stone door surround: two jambs and a head block (greystone, apartment portals; near).
        public var jambs: Bool?
    }

    public struct Shutters: Codable, Sendable, Equatable {
        public var chance: Double?
        /// Colour endpoints (sRGB), three steps.
        public var colours: [String]?
    }

    public struct Porch: Codable, Sendable, Equatable {
        /// square | turned | pier | tapered
        public var posts: String?
        /// Post (or pier) width range in metres.
        public var postWidth: [Double]?
        /// Masonry pier height under tapered posts.
        public var pierHeight: [Double]?
        /// Top rail with a few stout uprights (near); top rail only (mid).
        public var rail: Bool?
        /// One bracket wedge each side of a post head (near).
        public var brackets: Bool?
        /// hip | shed | gable | flat
        public var roof: String?
        /// Porch roof pitch in degrees.
        public var pitch: Double?
        public var depth: [Double]?
        /// Porch width as a share of the front wall.
        public var frontage: [Double]?
    }

    public struct Stoop: Codable, Sendable, Equatable {
        /// Stair width range in metres.
        public var width: [Double]?
        /// Solid cheek walls beside the steps.
        public var cheeks: Bool?
        /// Step colour: foundation (default) | trim (stone) | wall.
        public var steps: String?
        /// Cheek wall colour: foundation | trim | wall (default: the step colour).
        public var cheekColour: String?
    }
}

/// Where a covered porch went (along its wall edge).
struct PorchLayout {
    var s0: Double, s1: Double, depth: Double
    var stairS: Double, stairW: Double
}

enum HouseDetailColours {
    /// Steps per colour range (palette slots stay few: 3 per family range).
    static let steps = 3

    /// Step `k` of `n` between two sRGB endpoints, interpolated in linear light (pack: decode to
    /// linear before interpolation).
    static func step(_ a: String, _ b: String, _ k: Int, of n: Int = steps) -> String {
        let t = n > 1 ? Float(max(0, min(k, n - 1))) / Float(n - 1) : 0
        let la = Color.linear(Palette.parse(a)), lb = Color.linear(Palette.parse(b))
        return Palette.hex(Color.srgb(la + (lb - la) * t))
    }

    /// The house's step for a seeded salt.
    static func pick(_ range: [String], ref: OSMRef, salt: String) -> String? {
        guard range.count >= 2 else { return range.first }
        var r = ref.random(salt)
        return step(range[0], range[1], Int(r.next() % UInt64(steps)))
    }
}

extension BuildingGenerator {
    // MARK: - Stairs

    /// Steps from `height` down to the ground, starting at `top` (the platform edge) and going out
    /// along `n`, centred on `top`. Near: one block per riser (0.3 m treads, no hidden back faces)
    /// and optional solid cheek walls; mid: one stair wedge when there are three or more risers.
    /// Returns the run (metres out from `top`).
    @discardableResult
    // swiftlint:disable:next function_parameter_count
    func addStair(_ c: BuildContext, top: LocalPoint, dir: LocalPoint, n: LocalPoint, width: Double, height: Double,
                  cheeks: Bool, paint: Paint, cheekPaint: Paint? = nil, into m: inout MeshBuffers) -> Double {
        guard height > 0.12 else { return 0 }
        let count = max(1, Int((height / 0.18).rounded()))
        let rise = height / Double(count + 1)
        let tread = 0.3
        let run = tread * Double(count)
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(top + dir * s + n * t, z) }
        let hw = width / 2
        let start = m.positions.count
        m.paint = paint
        if c.lod == .near {
            for k in 0..<count {
                let z1 = height - rise * Double(k + 1)
                let t0 = tread * Double(k), t1 = t0 + tread
                m.addCleanFace([q(-hw, t0, z1), q(hw, t0, z1), q(hw, t1, z1), q(-hw, t1, z1)], facing: sceneUp)
                m.addCleanFace([q(-hw, t1, 0), q(hw, t1, 0), q(hw, t1, z1), q(-hw, t1, z1)], facing: D(n))
                for sx in [-1.0, 1.0] {
                    m.addCleanFace([q(sx * hw, t0, 0), q(sx * hw, t1, 0), q(sx * hw, t1, z1), q(sx * hw, t0, z1)], facing: D(dir * sx))
                }
            }
            if cheeks {
                m.paint = cheekPaint ?? paint
                // Solid cheek walls: top sloping from just over the stoop to knee height at the foot.
                let th = 0.24, zTop = height + 0.12, zEnd = min(zTop, max(0.4, rise * 2))
                let tEnd = run + 0.05
                for sx in [-1.0, 1.0] {
                    let si = sx * hw, so = sx * (hw + th)
                    m.addCleanFace([q(so, 0, 0), q(so, tEnd, 0), q(so, tEnd, zEnd), q(so, 0, zTop)], facing: D(dir * sx))
                    m.addCleanFace([q(si, 0, height), q(si, tEnd, 0), q(si, tEnd, zEnd), q(si, 0, zTop)], facing: D(dir * -sx))
                    m.addCleanFace([q(si, 0, zTop), q(si, tEnd, zEnd), q(so, tEnd, zEnd), q(so, 0, zTop)], facing: sceneUp + D(n))
                    m.addCleanFace([q(si, tEnd, 0), q(so, tEnd, 0), q(so, tEnd, zEnd), q(si, tEnd, zEnd)], facing: D(n))
                }
            }
        } else if c.lod == .mid, count >= 3 {
            // Stair envelope: one sloped wedge from the top tread to the ground (pack 50 m tier).
            let z0 = height - rise
            m.addCleanFace([q(-hw, 0, z0), q(hw, 0, z0), q(hw, run, rise), q(-hw, run, rise)], facing: sceneUp + D(n))
            m.addCleanFace([q(-hw, run, 0), q(hw, run, 0), q(hw, run, rise), q(-hw, run, rise)], facing: D(n))
            for sx in [-1.0, 1.0] {
                m.addCleanFace([q(sx * hw, 0, 0), q(sx * hw, run, 0), q(sx * hw, run, rise), q(sx * hw, 0, z0)], facing: D(dir * sx))
            }
        }
        m.bakeAO(from: start) { pos, _ in Float(0.8 + 0.2 * smoothstep(0, 0.5, Double(pos.y))) }
        return run
    }

    // MARK: - Covered porch

    /// Covered front porch from family data: platform at floor height, posts at the front corners
    /// (and either side of the steps on wide porches), optional rails and bracket wedges, a beam
    /// with the porch ceiling and a hip / shed / gable / flat roof kept under the main roof, steps
    /// centred on the door. Only where the ground in front is clear of buildings, roads and
    /// sidewalks. Nil when it doesn't fit (the caller then builds the plain stoop).
    func addPorch(_ c: BuildContext, _ spec: HouseFamilyGrammar.Porch, profilePorch: StyleProfile.Porch?, edge e: Int, doorS: Double,
                  into m: inout MeshBuffers) -> PorchLayout? {
        let (p, dir, n, len) = Self.edge(c.ring, e)
        var r = c.b.ref.random("porch-detail")
        let F = c.F
        let near = c.lod == .near
        var depth = r.range(spec.depth ?? profilePorch?.depth ?? [1.6, 2.2])
        let width = min(len - 0.4, max(2.4, len * r.range(spec.frontage ?? profilePorch?.frontage ?? [0.5, 0.8])))
        let postW = r.range(spec.postWidth ?? [0.16, 0.2])
        let pierH = r.range(spec.pierHeight ?? [0.7, 0.9])
        // Footprint of a post on the porch floor (a tapered post stands on a wider pier).
        let postSpan = spec.posts == "tapered" ? 2 * max(0.13, postW / 2 * 1.45) : postW
        guard width >= 2.4 else { return nil }
        let s0 = max(0.2, min(len - 0.2 - width, doorS - width / 2)), s1 = s0 + width
        // Steps centred on the door, clear of the corner posts.
        let room = min(doorS - s0, s1 - doorS) - postSpan - 0.2
        let stairW = min(1.5, 2 * room)
        guard stairW >= 1.0 else { return nil }
        let risers = F > 0.12 ? max(1, Int((F / 0.18).rounded())) : 0
        let run = 0.3 * Double(risers) + 0.1
        var fits = false
        for d in [depth, max(1.4, depth - 0.6)] where !fits {
            if frontClear(c, origin: p, dir: dir, n: n, s0: s0, s1: s1, depth: d + 0.15, roadMargin: 0.6),
               frontClear(c, origin: p, dir: dir, n: n, s0: doorS - stairW / 2, s1: doorS + stairW / 2, depth: d + run, roadMargin: 0.6) {
                depth = d
                fits = true
            }
        }
        guard fits else { return nil }

        // Heights: beam top under the main eave, roof kept under the main roof everywhere.
        let ov = 0.15, beamH = 0.24
        let eaveZ = c.H - c.overhang * tan(c.pitch * .pi / 180)
        var beamTop = max(F + 2.55, min(F + 2.85, eaveZ - 0.1))
        var kind = spec.roof ?? "hip"
        var k = tan((spec.pitch ?? (kind == "gable" ? 32 : 18)) * .pi / 180)
        let W = width + 2 * ov, DP = depth + ov
        let mid = (s0 + s1) / 2
        /// Porch roof height at (s, t) above `z0` per unit slope.
        func dist(_ s: Double, _ t: Double, _ kind: String) -> Double {
            switch kind {
            case "flat": return 0
            case "shed": return DP - t
            case "gable": return min(s - (s0 - ov), (s1 + ov) - s)
            default: return min(DP - t, s - (s0 - ov), (s1 + ov) - s)
            }
        }
        func clearance(_ kind: String, _ k: Double, _ beamTop: Double) -> Bool {
            guard let env = c.envelope else { return true }
            let z0 = beamTop - ov * k
            for i in 0...8 {
                let s = s0 - ov + W * Double(i) / 8
                for t in [0.02, 0.3, DP / 2, DP] {
                    guard let h = env.height(at: p + dir * s + n * t) else { continue }
                    let top = kind == "flat" ? beamTop + 0.12 : z0 + dist(s, t, kind) * k
                    if top > h - 0.25 { return false }
                }
            }
            return true
        }
        if !clearance(kind, k, beamTop) {
            // Lower the beam (≥ 2.3 m clear), then flatten the pitch, then a flat roof.
            beamTop = max(F + 2.3, beamTop - 0.3)
            var tries = 0
            while !clearance(kind, k, beamTop), tries < 4 { k *= 0.6; tries += 1 }
            if !clearance(kind, k, beamTop) { kind = "flat" }
            guard clearance(kind, k, beamTop) else { return nil }
        }
        let ceilZ = beamTop - beamH
        let start = m.positions.count
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(p + dir * s + n * t, z) }

        // Platform.
        if F > 0.05 {
            m.paint = c.foundation
            m.addBox(center: p + dir * mid + n * (depth / 2), u: dir, halfLength: width / 2, halfWidth: depth / 2, z0: 0, z1: F)
        }
        // Posts: front corners, and either side of the steps on wide porches.
        let inset = postSpan / 2 + 0.06
        let tp = depth - inset
        var posts = [s0 + inset, s1 - inset]
        if width > 4.4 {
            for sx in [-1.0, 1.0] {
                let s = doorS + sx * (stairW / 2 + 0.2 + postSpan / 2)
                if s - posts[0] >= 1.1, posts[1] - s >= 1.1 { posts.append(s) }
            }
        }
        posts.sort()
        let style = spec.posts ?? "square"
        for s in posts { addPorchPost(c, style: style, at: p + dir * s + n * tp, dir: dir, n: n, width: postW, pierH: pierH,
                                      top: ceilZ, brackets: near && spec.brackets == true, into: &m) }
        // Rails: top rail along the open front (both sides of the steps) and the porch ends; a few
        // stout uprights near. Mid keeps the front top rail only (outer rail outline).
        if spec.rail == true, F > 0.15 || near {
            let zr = F + 0.86
            let gapL = doorS - stairW / 2 - 0.05, gapR = doorS + stairW / 2 + 0.05
            var runs: [(LocalPoint, LocalPoint)] = []
            if gapL - posts[0] > 0.4 { runs.append((p + dir * posts[0] + n * tp, p + dir * gapL + n * tp)) }
            if posts.last! - gapR > 0.4 { runs.append((p + dir * gapR + n * tp, p + dir * posts.last! + n * tp)) }
            if near {
                for s in [posts[0], posts.last!] { runs.append((p + dir * s + n * 0.12, p + dir * s + n * tp)) }
            }
            m.paint = c.trim
            for (a, b) in runs {
                let v = b - a
                let l = simd_length(v)
                guard l > 0.3 else { continue }
                let u = v / l
                m.addBox(center: (a + b) / 2, u: u, halfLength: l / 2, halfWidth: 0.045, z0: zr, z1: zr + 0.08, bottom: near)
                guard near else { continue }
                let uprights = max(1, Int(l / 0.8))
                for j in 1...uprights {
                    let at = a + u * (l * Double(j) / Double(uprights + 1))
                    addPrism(at: at, u: u, half: 0.03, z0: F, z1: zr, into: &m)
                }
            }
        }
        // Beam with the porch ceiling under it (top hidden by the roof).
        m.paint = c.trim
        m.addCleanFace([q(s0, depth, ceilZ), q(s1, depth, ceilZ), q(s1, depth, beamTop), q(s0, depth, beamTop)], facing: D(n))
        for (s, sx) in [(s0, -1.0), (s1, 1.0)] {
            m.addCleanFace([q(s, 0, ceilZ), q(s, depth, ceilZ), q(s, depth, beamTop), q(s, 0, beamTop)], facing: D(dir * sx))
        }
        m.paint = Paint(slot: c.trim.slot, shade: 0.9)
        m.addCleanFace([q(s0, 0, ceilZ), q(s1, 0, ceilZ), q(s1, depth, ceilZ), q(s0, depth, ceilZ)], facing: -sceneUp)
        // Roof planes (top in the roof colour, underside in trim) and the closing faces.
        let z0 = beamTop - ov * k
        var planes: [[(Double, Double)]] = []
        let L = s0 - ov, R = s1 + ov
        switch kind {
        case "flat":
            Roofs.slab(OrientedRect(center: p + dir * mid + n * (depth / 2), u: dir, halfLength: width / 2, halfWidth: depth / 2),
                       z: beamTop, thickness: 0.12, overhang: ov, paint: c.roof, into: &m)
        case "shed":
            planes = [[(L, DP), (R, DP), (R, 0), (L, 0)]]
        case "gable":
            planes = [[(L, DP), (mid, DP), (mid, 0), (L, 0)], [(mid, DP), (R, DP), (R, 0), (mid, 0)]]
        default:
            if W >= 2 * DP {
                planes = [[(L, DP), (R, DP), (R - DP, 0), (L + DP, 0)], [(L, DP), (L + DP, 0), (L, 0)], [(R, DP), (R, 0), (R - DP, 0)]]
            } else {
                let pk = (mid, DP - W / 2)
                planes = [[(L, DP), (R, DP), pk], [(L, DP), pk, (mid, 0), (L, 0)], [(R, DP), (R, 0), (mid, 0), pk]]
            }
        }
        for poly in planes {
            let pts = poly.map { q($0.0, $0.1, z0 + dist($0.0, $0.1, kind) * k) }
            m.paint = c.roof
            m.addCleanFace(pts, facing: sceneUp)
            m.paint = Paint(slot: c.trim.slot, shade: 0.9)
            m.addCleanFace(pts, facing: -sceneUp)
        }
        m.paint = c.trim
        if kind == "gable" {
            // Gable triangle over the front beam.
            m.addCleanFace([q(s0, depth, beamTop), q(s1, depth, beamTop), q(mid, depth, z0 + (mid - L) * k)], facing: D(n))
        } else if kind == "shed" {
            for (s, sx) in [(s0, -1.0), (s1, 1.0)] {
                m.addCleanFace([q(s, depth, beamTop), q(s, 0, beamTop), q(s, 0, z0 + DP * k)], facing: D(dir * sx))
            }
        }
        // Porch floor darker near the wall, ceiling in shade, post bases grounded.
        m.bakeAO(from: start) { pos, nn in
            let lp = LocalPoint(Double(pos.x), Double(-pos.z))
            let out = simd_dot(lp - p, n)
            if nn.y < -0.5 { return 0.68 }
            if nn.y > 0.5, Double(pos.y) <= F + 0.01 { return Float(0.74 + 0.26 * smoothstep(0, depth, out)) }
            return Float(0.8 + 0.2 * smoothstep(F, F + 0.6, Double(pos.y)))
        }
        if risers > 0 {
            let stoop = c.grammar.details?.stoop
            addStair(c, top: p + dir * doorS + n * depth, dir: dir, n: n, width: stairW, height: F, cheeks: stoop?.cheeks == true,
                     paint: detailPaint(c, stoop?.steps), cheekPaint: detailPaint(c, stoop?.cheekColour ?? stoop?.steps), into: &m)
        }
        return PorchLayout(s0: s0, s1: s1, depth: depth, stairS: doorS, stairW: stairW)
    }

    /// Cornice along a street wall with one chamfer on its top outer edge (house-details-v1:
    /// parapet cap 1 chamfer): bottom, front, chamfer, top and the two ends.
    // swiftlint:disable:next function_parameter_count
    func addChamferedCornice(origin p: LocalPoint, dir: LocalPoint, n: LocalPoint, s0: Double, s1: Double, z0: Double, z1: Double,
                             depth: Double, chamfer ch: Double, into m: inout MeshBuffers) {
        func q(_ s: Double, _ t: Double, _ z: Double) -> SIMD3<Float> { P(p + dir * s + n * t, z) }
        m.addCleanFace([q(s0, 0, z0), q(s1, 0, z0), q(s1, depth, z0), q(s0, depth, z0)], facing: -sceneUp)
        m.addCleanFace([q(s0, depth, z0), q(s1, depth, z0), q(s1, depth, z1 - ch), q(s0, depth, z1 - ch)], facing: D(n))
        m.addCleanFace([q(s0, depth, z1 - ch), q(s1, depth, z1 - ch), q(s1, depth - ch, z1), q(s0, depth - ch, z1)], facing: D(n) + sceneUp)
        m.addCleanFace([q(s0, depth - ch, z1), q(s1, depth - ch, z1), q(s1, 0, z1), q(s0, 0, z1)], facing: sceneUp)
        for (s, sx) in [(s0, -1.0), (s1, 1.0)] {
            m.addCleanFace([q(s, 0, z0), q(s, depth, z0), q(s, depth, z1 - ch), q(s, depth - ch, z1), q(s, 0, z1)], facing: D(dir * sx))
        }
    }

    /// A named detail colour: trim | wall | foundation (default).
    func detailPaint(_ c: BuildContext, _ name: String?) -> Paint {
        switch name {
        case "trim": c.trim
        case "wall": c.wall
        default: c.foundation
        }
    }

    /// A vertical four-sided prism (no caps) centred at `at`.
    func addPrism(at: LocalPoint, u: LocalPoint, half: Double, z0: Double, z1: Double, topHalf: Double? = nil, into m: inout MeshBuffers) {
        let v = LocalPoint(-u.y, u.x)
        let th = topHalf ?? half
        let b = [at - u * half - v * half, at + u * half - v * half, at + u * half + v * half, at - u * half + v * half]
        let t = [at - u * th - v * th, at + u * th - v * th, at + u * th + v * th, at - u * th + v * th]
        for i in 0..<4 {
            let j = (i + 1) % 4
            let mid = (b[i] + b[j]) / 2 - at
            m.addCleanFace([P(b[i], z0), P(b[j], z0), P(t[j], z1), P(t[i], z1)], facing: D(mid))
        }
    }

    /// One porch post by family style. near: profile changes (turned: rail-height block, slim
    /// shaft, capital; pier: masonry pier with a cap; tapered: brick pier and a tapered post),
    /// optional bracket wedges; mid: one plain prism of the post's main width (pier: the pier).
    // swiftlint:disable:next function_parameter_count
    func addPorchPost(_ c: BuildContext, style: String, at: LocalPoint, dir: LocalPoint, n: LocalPoint, width: Double, pierH: Double,
                      top: Double, brackets: Bool, into m: inout MeshBuffers) {
        let F = c.F, near = c.lod == .near
        let h = width / 2
        switch style {
        case "pier":
            // Broad square masonry pier (Prairie), wall coloured, with a projecting cap.
            m.paint = c.wall
            addPrism(at: at, u: dir, half: h, z0: F, z1: top - (near ? 0.2 : 0), into: &m)
            if near {
                m.paint = c.trim
                m.addBox(center: at, u: dir, halfLength: h + 0.05, halfWidth: h + 0.05, z0: top - 0.2, z1: top, bottom: true)
            }
        case "tapered":
            // Brick pier, then a post tapering from 0.65 to 0.42 of the pier width (Craftsman).
            let ph = max(0.13, h * 1.45)
            m.paint = c.wall
            if near {
                m.addBox(center: at, u: dir, halfLength: ph, halfWidth: ph, z0: F, z1: F + pierH)
                m.paint = c.trim
                addPrism(at: at, u: dir, half: ph * 0.65, z0: F + pierH, z1: top, topHalf: ph * 0.42, into: &m)
            } else {
                addPrism(at: at, u: dir, half: ph, z0: F, z1: F + pierH, into: &m)
                m.paint = c.trim
                addPrism(at: at, u: dir, half: ph * 0.55, z0: F + pierH, z1: top, into: &m)
            }
        case "turned":
            m.paint = c.trim
            if near {
                // Rail-height block, slim shaft, capital block: two or three coarse profile changes.
                m.addBox(center: at, u: dir, halfLength: h, halfWidth: h, z0: F, z1: F + 0.9)
                addPrism(at: at, u: dir, half: h * 0.62, z0: F + 0.9, z1: top - 0.28, into: &m)
                m.addBox(center: at, u: dir, halfLength: h * 0.9, halfWidth: h * 0.9, z0: top - 0.28, z1: top, bottom: true)
            } else {
                addPrism(at: at, u: dir, half: h * 0.75, z0: F, z1: top, into: &m)
            }
        default:
            m.paint = c.trim
            addPrism(at: at, u: dir, half: h, z0: F, z1: top, into: &m)
        }
        guard brackets else { return }
        // Bracket wedges in the beam plane, one each side of the post head.
        m.paint = c.trim
        let hw = style == "tapered" ? max(0.13, h * 1.45) * 0.42 : h * 0.62
        for sx in [-1.0, 1.0] {
            let a = at + dir * (sx * hw), b = at + dir * (sx * (hw + 0.32))
            m.addCleanFace([P(a, top - 0.34), P(b, top), P(a, top)], facing: D(n))
        }
    }

    // MARK: - Trim, corners, frieze

    /// Near only: corner boards or chamfer strips on the convex street corners of the outer ring,
    /// and a frieze board under the eave of street-facing walls of pitched roofs.
    func addCornersAndFrieze(_ c: BuildContext, into m: inout MeshBuffers) {
        guard c.lod == .near, let d = c.grammar.details else { return }
        let ring = c.ring
        let count = ring.count
        let start = m.positions.count
        if let mode = d.corners {
            let board = mode == "board"
            // Board: 0.14 m wide each face, 3 cm proud, 2 cm edge chamfer. Masonry: 7 cm strips,
            // 2.5 cm proud, 4 cm chamfer (the pack's preferred wall-corner bevel); 2t ≥ c keeps
            // the chamfer face in front of the wall corner.
            let w = board ? 0.14 : 0.07, t = board ? 0.03 : 0.025, ch = board ? 0.02 : 0.04
            m.paint = board ? c.trim : Paint(slot: c.wall.slot, shade: c.wall.shade)
            for i in 0..<count {
                let ip = (i + count - 1) % count
                let (_, a, na, la) = Self.edge(ring, ip)
                let (C, b, nb, lb) = Self.edge(ring, i)
                guard c.streetFacing.contains(ip) || c.streetFacing.contains(i), la >= 1.0, lb >= 1.0 else { continue }
                // Convex (left turn on a CCW ring), roughly square.
                guard a.x * b.y - a.y * b.x > 0.9 else { continue }
                let zTop: Double
                if let env = c.envelope {
                    zTop = (env.height(at: C) ?? c.H) - 0.03
                } else {
                    zTop = c.H + c.parapet - (c.grammar.facade?.cornice == true ? 0.45 : 0.03)
                }
                let z0 = c.F
                guard zTop - z0 > 0.5 else { continue }
                let a0 = C - a * w + na * t, a1 = C + na * t + a * (t - ch)
                let b1 = C + nb * t - b * (t - ch), b0 = C + nb * t + b * w
                m.addCleanFace([P(a0, z0), P(a1, z0), P(a1, zTop), P(a0, zTop)], facing: D(na))
                m.addCleanFace([P(a1, z0), P(b1, z0), P(b1, zTop), P(a1, zTop)], facing: D(simd_normalize(na + nb)))
                m.addCleanFace([P(b1, z0), P(b0, z0), P(b0, zTop), P(b1, zTop)], facing: D(nb))
            }
        }
        if d.frieze == true, c.envelope != nil {
            m.paint = c.trim
            for e in c.streetFacing.sorted() {
                let (p, dir, n, len) = Self.edge(ring, e)
                guard len >= 1.5 else { continue }
                m.addWallQuad(origin: p, dir: dir, normal: n, s0: 0, s1: len, z0: c.H - 0.3, z1: c.H - 0.02, offset: 0.022)
            }
        }
        m.bakeAO(from: start) { pos, _ in
            let y = Double(pos.y)
            return Float((0.72 + 0.28 * smoothstep(0, max(c.F, 0.6) + 0.3, y)) * (1 - 0.2 * smoothstep(c.H - 0.7, c.H, y)))
        }
    }

    /// Paired plain shutters beside a window (slab colour, 4 cm proud).
    // swiftlint:disable:next function_parameter_count
    func addShutters(origin: LocalPoint, dir: LocalPoint, normal: LocalPoint, sCenter: Double, width: Double, z0: Double, z1: Double,
                     shutterWidth sw: Double, paint: Paint, into m: inout MeshBuffers) {
        guard sw >= 0.25 else { return }
        m.paint = paint
        let f = 0.1
        for (a, b) in [(sCenter - width / 2 - f - sw, sCenter - width / 2 - f), (sCenter + width / 2 + f, sCenter + width / 2 + f + sw)] {
            m.addWallQuad(origin: origin, dir: dir, normal: normal, s0: a, s1: b, z0: z0, z1: z1, offset: 0.04)
        }
    }
}
