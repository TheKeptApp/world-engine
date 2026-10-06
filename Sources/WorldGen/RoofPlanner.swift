import Foundation
import simd
import WorldGeo

/// What a house family asks of its roof (from house-families.json plus the profile's ranges).
public struct RoofRecipe: Sendable, Equatable {
    public enum Ridge: String, Sendable, Codable {
        /// Along the footprint's long side.
        case long
        /// Parallel to the street (side gable), when the main mass is close to square.
        case alongFront
        /// Toward the street (front gable), when the main mass is close to square.
        case towardFront
    }

    public var mainForm: RoofMass.Form
    /// Form of wings over footprint arms (nil = same as the main roof).
    public var wingForm: RoofMass.Form?
    public var pitch: Double
    public var overhang: Double
    public var ridge: Ridge = .long
    /// Chance of one flush crossing gable on the street side when the footprint has no arm.
    public var crossGable: Double = 0
    /// Crossing gable width as a share of the facade length.
    public var crossGableWidth: [Double] = [0.35, 0.6]
    public var crossGableCentered = false
    /// Extra pitch for the crossing gable (steeper accent), still kept below the main ridge.
    public var crossGablePitchBoost: Double = 0
}

/// The masses of one house roof.
public struct RoofPlan: Sendable {
    public var masses: [RoofMass]
    public var main: Int
    /// Index of the flush crossing gable, if one was added.
    public var crossGable: Int?
    /// Clip the roof to this ring (conservative envelope over a non-orthogonal footprint).
    public var clip: Ring?
    /// Why a conservative envelope was used instead of a decomposed roof (flagged for review).
    public var fallback: String?
    /// +1 if the street side of the main mass is +across, −1 if −across, 0 if unknown.
    public var frontSign: Double
}

enum RoofPlanner {
    /// True if every point along the ring lies inside some mass's roof outline (eaves included).
    static func covers(_ ring: Ring, _ masses: [RoofMass]) -> Bool {
        let outlines = masses.map { m -> [Linear2] in
            let shrink = max(0, m.overhang - 0.03)
            return ConvexClip.halfPlanes(m.rect(m.halfLength + shrink, m.halfWidth + shrink))
        }
        for i in 0..<ring.count {
            let a = ring[i], b = ring[(i + 1) % ring.count]
            let n = max(1, Int(simd_distance(a, b) / 0.5))
            for k in 0...n {
                let p = a + (b - a) * (Double(k) / Double(n))
                if !outlines.contains(where: { hp in hp.allSatisfy { $0(p) >= -1e-6 } }) { return false }
            }
        }
        return true
    }

    struct Box { var s0, s1, t0, t1: Double
        var area: Double { (s1 - s0) * (t1 - t0) }
        var center: LocalPoint { LocalPoint((s0 + s1) / 2, (t0 + t1) / 2) }
        func extent(_ axis: Int) -> Double { axis == 0 ? s1 - s0 : t1 - t0 }
    }

    /// Builds the roof masses. `front` is the street-facing outward normal, if known.
    static func plan(footprint: Polygon2D, shape: FootprintAnalysis, front: LocalPoint?, recipe: RoofRecipe,
                     eave H: Double, rng: inout StableRandom) -> RoofPlan? {
        let frame = shape.obb
        let rects: [OrientedRect]
        var clip: Ring?
        var fallback: String?
        switch shape.kind {
        case .rectangle: rects = [frame]
        case .orthogonal: rects = shape.roofRects + shape.flatRects
        case .nearRectangle:
            rects = [frame]
            clip = footprint.outer
        case .irregular:
            guard footprint.holes.isEmpty, shape.rectangularity >= 0.6 else { return nil }
            rects = [frame]
            clip = footprint.outer
            fallback = "irregular footprint: conservative envelope"
        case .tiny: return nil
        }
        guard !rects.isEmpty else { return nil }

        // Boxes in the frame's (u, v) coordinates.
        func toFrame(_ p: LocalPoint) -> LocalPoint { LocalPoint(simd_dot(p - frame.center, frame.u), simd_dot(p - frame.center, frame.v)) }
        var boxes = rects.map { r -> Box in
            let c = r.corners.map(toFrame)
            return Box(s0: c.map(\.x).min()!, s1: c.map(\.x).max()!, t0: c.map(\.y).min()!, t1: c.map(\.y).max()!)
        }.filter { $0.area > 0.05 }
        boxes.sort { $0.area > $1.area }
        guard !boxes.isEmpty else { return nil }

        // Adjacency (shared sides), then a tree rooted at the largest box.
        let tol = 0.05
        func overlap(_ a0: Double, _ a1: Double, _ b0: Double, _ b1: Double) -> Double { min(a1, b1) - max(a0, b0) }
        /// Side of `p` on which `c` lies: (axis, sign), or nil if they don't share a side.
        func side(_ p: Box, _ c: Box) -> (axis: Int, sign: Double)? {
            if overlap(p.t0, p.t1, c.t0, c.t1) > 0.3 {
                if abs(c.s0 - p.s1) < tol { return (0, 1) }
                if abs(c.s1 - p.s0) < tol { return (0, -1) }
            }
            if overlap(p.s0, p.s1, c.s0, c.s1) > 0.3 {
                if abs(c.t0 - p.t1) < tol { return (1, 1) }
                if abs(c.t1 - p.t0) < tol { return (1, -1) }
            }
            return nil
        }
        var parent = [Int?](repeating: nil, count: boxes.count)
        var attach = [(axis: Int, sign: Double)?](repeating: nil, count: boxes.count)
        var order = [0]
        var seen: Set<Int> = [0]
        var head = 0
        while head < order.count {
            let p = order[head]; head += 1
            for c in boxes.indices where !seen.contains(c) {
                if let s = side(boxes[p], boxes[c]) {
                    parent[c] = p; attach[c] = s; seen.insert(c); order.append(c)
                }
            }
        }
        // Disconnected pieces (rare snapping leftovers) hang off the main box as plain hips.
        for c in boxes.indices where !seen.contains(c) { order.append(c) }

        let k0 = tan(recipe.pitch * .pi / 180)
        let drop = recipe.overhang * k0
        func overhangFor(_ pitch: Double) -> Double {
            min(max(drop / max(tan(pitch * .pi / 180), 0.05), 0.05), max(1.0, recipe.overhang))
        }
        let axisVec = [frame.u, frame.v]
        func world(_ st: LocalPoint) -> LocalPoint { frame.center + frame.u * st.x + frame.v * st.y }

        // Main box ridge axis.
        let mainBox = boxes[0]
        var mainAxis = mainBox.extent(0) >= mainBox.extent(1) ? 0 : 1
        let aspect = max(mainBox.extent(0), mainBox.extent(1)) / max(min(mainBox.extent(0), mainBox.extent(1)), 0.01)
        if let front, aspect < 1.3, recipe.mainForm == .gable {
            let frontAlongU = abs(simd_dot(front, frame.u)) > abs(simd_dot(front, frame.v)) // street lies along ±u
            switch recipe.ridge {
            case .alongFront: mainAxis = frontAlongU ? 1 : 0
            case .towardFront: mainAxis = frontAlongU ? 0 : 1
            case .long: break
            }
        }

        var axes = [Int](repeating: 0, count: boxes.count)
        var extended = boxes
        var masses = [RoofMass?](repeating: nil, count: boxes.count)
        func mass(_ i: Int, axis: Int, form: RoofMass.Form, pitch: Double) -> RoofMass {
            let b = extended[i]
            let along = axis, across = 1 - axis
            return RoofMass(center: world(b.center), axis: axisVec[along], halfLength: b.extent(along) / 2,
                            halfWidth: b.extent(across) / 2, form: form, pitch: pitch, overhang: overhangFor(pitch), eave: H)
        }
        axes[0] = mainAxis
        var main = mass(0, axis: mainAxis, form: recipe.mainForm, pitch: recipe.pitch)
        main.overhang = recipe.overhang
        masses[0] = main
        let mainRidge = main.ridgeHeight

        for c in order.dropFirst() {
            let small = boxes[c].area < 6
            let form: RoofMass.Form = small ? .hip : (recipe.wingForm ?? recipe.mainForm)
            guard let p = parent[c], let att = attach[c], let pm = masses[p] else {
                masses[c] = mass(c, axis: boxes[c].extent(0) >= boxes[c].extent(1) ? 0 : 1, form: .hip, pitch: recipe.pitch)
                continue
            }
            // Ridge of a wing runs away from its parent; it reaches back toward the parent's ridge.
            let a = att.axis
            axes[c] = a
            let pb = boxes[p]
            var b = boxes[c]
            let childWidth = b.extent(1 - a)
            let oc = overhangFor(recipe.pitch)
            let reach: Double
            if axes[p] != a {
                // Parent ridge runs along the shared side: stop just short of it.
                let mid = a == 0 ? (pb.s0 + pb.s1) / 2 : (pb.t0 + pb.t1) / 2
                reach = max(0, abs((att.sign > 0 ? (a == 0 ? b.s0 : b.t0) : (a == 0 ? b.s1 : b.t1)) - mid) - oc)
            } else {
                reach = min(childWidth / 2, pb.extent(a) / 2)
            }
            if att.sign > 0 {
                if a == 0 { b.s0 -= reach } else { b.t0 -= reach }
            } else {
                if a == 0 { b.s1 += reach } else { b.t1 += reach }
            }
            extended[c] = b
            // Subordinate ridge stays below its parent's and the main ridge.
            let halfW = childWidth / 2
            let limit = min(pm.ridgeHeight, mainRidge) - 0.25
            var pitch = recipe.pitch
            if H + halfW * tan(pitch * .pi / 180) > limit {
                pitch = max(12, atan(max(limit - H, 0.01) / max(halfW, 0.01)) * 180 / .pi)
            }
            masses[c] = mass(c, axis: a, form: form, pitch: pitch)
        }

        var out = masses.compactMap { $0 }
        // Every wall must sit under some roof mass; snapped decompositions of slightly slanted
        // footprints can miss slivers. Then use one conservative mass cut to the footprint.
        if clip == nil, !covers(footprint.outer, out) {
            let m = RoofMass(center: frame.center, axis: frame.u, halfLength: frame.halfLength, halfWidth: frame.halfWidth,
                             form: recipe.mainForm, pitch: recipe.pitch, overhang: recipe.overhang, eave: H)
            out = [m]
            clip = footprint.outer
            fallback = "roof decomposition missed part of the footprint: conservative envelope"
        }
        var frontSign = 0.0
        if let front {
            let d = simd_dot(front, out[0].across)
            frontSign = abs(d) > 0.5 ? (d > 0 ? 1 : -1) : 0
        }

        // Flush crossing gable on a single-mass roof whose long side faces the street.
        var cross: Int?
        if out.count == 1, clip == nil, recipe.mainForm == .gable || recipe.mainForm == .hip, frontSign != 0,
           recipe.crossGable > 0, rng.chance(recipe.crossGable) {
            let m = out[0]
            let L = m.halfLength, W = m.halfWidth
            let w = min(rng.range(recipe.crossGableWidth) * 2 * L, 2 * L - 1.2)
            if w >= 2.6, W >= 2.4 {
                var sc = 0.0
                if !recipe.crossGableCentered {
                    let room = L - w / 2 - 0.3
                    let margin = rng.range(0.4, 1.0)
                    sc = max(0, room - margin) * (rng.chance(0.5) ? 1 : -1)
                }
                var pitch = recipe.pitch + recipe.crossGablePitchBoost
                let limit = m.ridgeHeight - 0.3
                if H + (w / 2) * tan(pitch * .pi / 180) > limit { pitch = atan(max(limit - H, 0.01) / (w / 2)) * 180 / .pi }
                if pitch >= 20 {
                    let oc = overhangFor(pitch)
                    // From the front wall back to just short of the ridge (the rake stays under it).
                    let back = min(oc, W * 0.4)
                    let len = W - back
                    let center = m.point(sc, frontSign * (W + back) / 2)
                    var g = RoofMass(center: center, axis: m.across, halfLength: len / 2, halfWidth: w / 2, form: .gable,
                                     pitch: pitch, overhang: oc, eave: H)
                    g.overhang = oc
                    out.append(g)
                    cross = out.count - 1
                }
            }
        }
        return RoofPlan(masses: out, main: 0, crossGable: cross, clip: clip, fallback: fallback, frontSign: frontSign)
    }
}
