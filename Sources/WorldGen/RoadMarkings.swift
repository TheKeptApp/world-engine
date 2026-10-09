import Foundation
import simd
import WorldGeo
import WorldMap

/// Road paint look from infrastructure-kit-v1 (R approved, binding): roads-08 lane-marking library and
/// roads-09 crosswalk library, read by key from the bundled shared mock values (`Profiles/mock-values.json`,
/// compiled by Tools/lookloop/compile_mocks.py). Geometry (lane widths) is not taken from the kit: R's rule,
/// street-geometry-rules-v1 owns geometry (`LookSpec.MarkingTuning`). Nil when a key is missing: no paint.
public struct MarkingValues: Sendable, Equatable {
    /// roads-08: line width, dash and gap, gap between double lines, stop-bar width (m); paint colours.
    public var lineWidth: Double
    public var dashLength: Double
    public var dashGap: Double
    public var doubleLineGap: Double
    public var stopBarWidth: Double
    public var white: String
    public var yellow: String
    /// roads-09: crossing band width along the road, bar width and gap, transverse line width (m); paint.
    public var crossingWidth: Double
    public var stripeWidth: Double
    public var stripeGap: Double
    public var transverseLineWidth: Double
    public var crossingWhite: String

    static let prefix = "style-b/infrastructure/assets."
    /// Every mock key read, in `init(mock:)` order.
    public static let keys: [String] = [
        "roads-08-markings.dimensionsM.lineWidth", "roads-08-markings.dimensionsM.dashLength",
        "roads-08-markings.dimensionsM.dashGap", "roads-08-markings.dimensionsM.doubleLineGap",
        "roads-08-markings.dimensionsM.stopBarWidth",
        "roads-08-markings.palette.Base.secondaryHex", "roads-08-markings.palette.Base.accentHex",
        "roads-09-crosswalks.dimensionsM.crossingWidthAlongRoad", "roads-09-crosswalks.dimensionsM.stripeWidth",
        "roads-09-crosswalks.dimensionsM.stripeGap", "roads-09-crosswalks.dimensionsM.transverseLineWidth",
        "roads-09-crosswalks.palette.Base.secondaryHex",
    ].map { prefix + $0 }

    public init?(mock m: MockValues?) {
        guard let m else { return nil }
        func n(_ i: Int) -> Double? { m.number(Self.keys[i]) }
        func s(_ i: Int) -> String? { m.string(Self.keys[i]) }
        guard let lw = n(0), let dl = n(1), let dg = n(2), let dbl = n(3), let sb = n(4), let white = s(5), let yellow = s(6),
              let cw = n(7), let sw = n(8), let sg = n(9), let tw = n(10), let cwhite = s(11) else { return nil }
        self.init(lineWidth: lw, dashLength: dl, dashGap: dg, doubleLineGap: dbl, stopBarWidth: sb, white: white, yellow: yellow,
                  crossingWidth: cw, stripeWidth: sw, stripeGap: sg, transverseLineWidth: tw, crossingWhite: cwhite)
    }

    public init(lineWidth: Double, dashLength: Double, dashGap: Double, doubleLineGap: Double, stopBarWidth: Double,
                white: String, yellow: String, crossingWidth: Double, stripeWidth: Double, stripeGap: Double,
                transverseLineWidth: Double, crossingWhite: String) {
        self.lineWidth = lineWidth; self.dashLength = dashLength; self.dashGap = dashGap; self.doubleLineGap = doubleLineGap
        self.stopBarWidth = stopBarWidth; self.white = white; self.yellow = yellow; self.crossingWidth = crossingWidth
        self.stripeWidth = stripeWidth; self.stripeGap = stripeGap; self.transverseLineWidth = transverseLineWidth
        self.crossingWhite = crossingWhite
    }

    /// Keys missing from the mock values.
    public static func missing(in m: MockValues?) -> [String] {
        keys.filter { m?.number($0) == nil && m?.string($0) == nil }
    }

    public static let bundled: MarkingValues? = MarkingValues(mock: MockValues.bundled)
}

/// One painted mark: a flat ribbon `width` wide along `line`, at `GroundLayer.marking`.
public struct RoadMark: Sendable, Equatable {
    public enum Role: String, Sendable, CaseIterable {
        /// Double yellow between opposing flows; yellow pair around a two-way turn lane.
        case centre
        /// Broken white between same-direction lanes.
        case laneDivider
        /// Solid edge lines of a divided (one-way motorway/trunk) carriageway.
        case edge
        /// Solid white line between a tagged bike lane and the traffic lanes.
        case bikeLane
        case stopBar
        /// Longitudinal crosswalk bar (zebra/continental, ladder).
        case crosswalkBar
        /// Transverse crosswalk line (ladder boundaries, two-line crossings).
        case crosswalkLine
    }
    public enum Colour: Sendable { case white, yellow, crossingWhite }

    public var role: Role
    public var colour: Colour
    public var line: [LocalPoint]
    public var width: Double
    /// Seeded paint wear (1 = fresh).
    public var shade: Float
    /// The road, crossing way or crossing node it belongs to.
    public var source: OSMRef
    /// True where the tags were silent and a pack/class default decided (lane count, crossing style).
    public var inferred: Bool
}

/// How a road's carriageway is split for paint, from its tags and the pack's class defaults.
/// Offsets are metres to the left of the way's direction (centreline 0); `right < left`.
public struct LaneLayout: Sendable, Equatable {
    public enum RoadClass: Sendable { case highway, arterial, collector, local, service }
    public var roadClass: RoadClass
    /// Lanes with the way's direction, against it, and a two-way centre turn lane (0/1).
    public var forward: Int
    public var backward: Int
    public var centreTurn: Int
    /// Travel area (between parking and bike lanes).
    public var right: Double
    public var left: Double
    public var bikeRight: Bool
    public var bikeLeft: Bool
    /// Centre and lane lines are painted (class default or tags).
    public var longitudinal: Bool
    public var inferredLanes: Bool
    /// One-way motorway/trunk carriageway: white right edge, yellow left (median) edge.
    public var divided: Bool
    /// 0 two-way, 1 with the way, -1 against it.
    public var oneway: Int
    /// A tagged bike lane did not fit next to the traffic lanes (not painted).
    public var conflict: Bool

    public var lanes: Int { forward + backward + centreTurn }
    public var laneWidth: Double { (left - right) / Double(max(1, lanes)) }
    /// Offset of the boundary between forward lanes and the centre (turn lane or opposing flow).
    public var centreStart: Double { right + Double(forward) * laneWidth }
    public var centreEnd: Double { centreStart + Double(centreTurn) * laneWidth }
}

/// Lane markings and crosswalks from OSM tags (infrastructure-kit-v1 roads-08/09; street-geometry-rules-v1
/// US rows), only where mapped (R, 7 Oct): through roads (motorway…tertiary) with a mapped lane count;
/// local streets, alleys and service roads never unless `lane_markings=yes` (`lane_markings=no` always wins);
/// tagged bike lanes on any road. No per-class default paint on untagged roads. Crosswalks only at mapped crossings whose tags evidence paint
/// (never at every junction or signal). Deterministic: wear is seeded per feature.
public struct RoadMarkings: Sendable {
    public var features: MapFeatures
    public var values: MarkingValues
    public var tuning: LookSpec.MarkingTuning
    public var rules = RoadRules()

    public init(features: MapFeatures, values: MarkingValues, tuning: LookSpec.MarkingTuning) {
        self.features = features
        self.values = values
        self.tuning = tuning
    }

    /// A crosswalk where a mapped crossing meets a road.
    public struct Crosswalk: Sendable, Equatable {
        public enum Style: Sendable, Equatable { case bars, ladder, lines, none }
        public var road: Int
        public var point: LocalPoint
        /// Distance along the road's centreline.
        public var along: Double
        /// Unit direction of the road and of the crossing at `point`.
        public var roadDir: LocalPoint
        public var crossDir: LocalPoint
        public var style: Style
        public var styleInferred: Bool
        public var signals: Bool
        public var source: OSMRef
        /// The crossing way (index into `features.paths`) and the part of it on the carriageway.
        public var path: Int?
        public var pathSpan: ClosedRange<Double>?
    }

    public struct Output: Sendable {
        public var marks: [RoadMark] = []
        public var crosswalks: [Crosswalk] = []
        /// Crossing way index → parts on a carriageway (distance along the way), where paint replaces the ribbon.
        public var crossingSpans: [Int: [ClosedRange<Double>]] = [:]
        public var conflicts = 0
    }

    // MARK: - Classes and layout

    static func roadClass(_ kind: HighwayKind) -> LaneLayout.RoadClass {
        switch kind {
        case .motorway, .trunk: .highway
        case .primary, .secondary: .arterial
        case .tertiary: .collector
        case .residential, .unclassified, .livingStreet, .road: .local
        default: .service
        }
    }

    static func onewayValue(_ t: Tags, kind: HighwayKind) -> Int {
        switch t["oneway"] {
        case "yes", "true", "1": return 1
        case "-1", "reverse": return -1
        case "no", "false", "0": return 0
        default: return kind == .motorway || t["junction"] == "roundabout" ? 1 : 0
        }
    }

    public func layout(_ road: WayFeature) -> LaneLayout {
        let t = road.tags
        let cls = Self.roadClass(road.kind)
        let oneway = Self.onewayValue(t, kind: road.kind)
        func count(_ k: String) -> Int? { t[k].flatMap(TagParsing.integer).flatMap { $0 > 0 && $0 < 12 ? $0 : nil } }
        func turnCount(_ k: String) -> Int? { t[k].map { $0.split(separator: "|", omittingEmptySubsequences: false).count } }
        func bike(_ side: String) -> Bool {
            let v = t["cycleway:\(side)"] ?? t["cycleway:both"] ?? (oneway != 0 && side == "left" ? nil : t["cycleway"])
            return v == "lane" || v == "opposite_lane"
        }
        let parkingAllowed = rules.parkingKinds.contains(road.kind)
        var parkR: (parked: Bool, tagged: Bool) = parkingAllowed ? rules.parking(t, side: "right") : (false, true)
        var parkL: (parked: Bool, tagged: Bool) = parkingAllowed ? rules.parking(t, side: "left") : (false, true)
        var bikeR = bike("right"), bikeL = bike("left")
        let bw = tuning.bikeLaneWidthM, pw = rules.parkingLaneWidth
        func extents() -> (Double, Double) {
            (-road.width / 2 + (parkR.parked ? pw : 0) + (bikeR ? bw : 0), road.width / 2 - (parkL.parked ? pw : 0) - (bikeL ? bw : 0))
        }

        let total = count("lanes")
        let laneWidth = cls == .highway ? tuning.highwayLaneWidthM : tuning.arterialLaneWidthM
        func lanes(travel: Double) -> (f: Int, b: Int, c: Int, inferred: Bool) {
            if oneway != 0 {
                let n = total ?? turnCount("turn:lanes")
                let m = n ?? max(1, Int(travel / laneWidth))
                return oneway == 1 ? (m, 0, 0, n == nil) : (0, m, 0, n == nil)
            }
            let c = min(1, count("lanes:both_ways") ?? 0)
            var f = count("lanes:forward") ?? turnCount("turn:lanes:forward")
            var b = count("lanes:backward") ?? turnCount("turn:lanes:backward")
            if let total {
                let rest = max(2, total - c)
                if f == nil, let b { f = max(1, rest - b) }
                if b == nil, let f { b = max(1, rest - f) }
                if f == nil { f = (rest + 1) / 2; b = max(1, rest - f!) }
            }
            if let f, let b { return (f, b, c, false) }
            let per = max(1, Int(travel / 2 / laneWidth))
            return (f ?? per, b ?? per, c, true)
        }

        var (r, l) = extents()
        var plan = lanes(travel: l - r)
        // Unlaned streets still carry one flow per direction for the bike-lane fit.
        func slots(_ p: (f: Int, b: Int, c: Int, inferred: Bool)) -> Int {
            cls == .local || cls == .service ? (oneway != 0 ? 1 : 2) : p.f + p.b + p.c
        }
        var conflict = false
        // street-geometry-rules-v1 §5: when tagged parts don't fit, inferred (untagged) parking goes first,
        // then the optional paint; the measured envelope (road width) never changes.
        for side in ["right", "left"] where l - r < Double(slots(plan)) * tuning.minLaneWidthM {
            if side == "right", parkR.parked, !parkR.tagged { parkR.parked = false }
            if side == "left", parkL.parked, !parkL.tagged { parkL.parked = false }
            (r, l) = extents()
            plan = lanes(travel: l - r)
        }
        if (bikeR || bikeL), l - r < Double(slots(plan)) * tuning.minLaneWidthM {
            bikeR = false; bikeL = false; conflict = true
            (r, l) = extents()
            plan = lanes(travel: l - r)
        }

        var longitudinal: Bool
        switch t["lane_markings"] {
        case "no": longitudinal = false
        case "yes": longitudinal = true
        default:
            // Only where mapped (R, 7 Oct): a lane count (`lanes`, `lanes:forward/backward`, `turn:lanes*`) on a
            // through road. Local streets stay unmarked (street-geometry-rules-v1 US residential: no longitudinal
            // markings; OSM `lanes` there counts traffic flows, not paint); alleys/service roads never.
            let mapped = total != nil || ["lanes:forward", "lanes:backward", "turn:lanes", "turn:lanes:forward", "turn:lanes:backward"]
                .contains { t[$0] != nil }
            switch cls {
            case .highway, .arterial, .collector: longitudinal = mapped
            case .local, .service: longitudinal = false
            }
        }
        if t["lane_markings"] == "no" { bikeR = false; bikeL = false }
        return LaneLayout(roadClass: cls, forward: plan.f, backward: plan.b, centreTurn: plan.c, right: r, left: l,
                          bikeRight: bikeR, bikeLeft: bikeL, longitudinal: longitudinal, inferredLanes: plan.inferred && longitudinal,
                          divided: cls == .highway && oneway != 0, oneway: oneway, conflict: conflict)
    }

    // MARK: - Crossing style

    /// The paint a crossing's tags evidence: `crossing:markings` first, then the older `crossing=*` /
    /// `crossing_ref` values. Untagged crossings stay unpainted (unknown is not evidence). `inferred`
    /// when a marked crossing's style is not given (the pack's US default, continental bars).
    public static func style(_ t: Tags) -> (style: Crosswalk.Style, inferred: Bool)? {
        switch t["crossing:markings"] {
        case "zebra", "zebra:double", "zebra:paired", "zebra:bicolour": return (.bars, false)
        case "ladder", "ladder:skewed", "ladder:paired": return (.ladder, false)
        case "lines", "lines:paired", "dashes", "dots": return (.lines, false)
        case "no", "surface", "pictograms": return (.none, false)
        case "yes": return (.bars, true)
        default: break
        }
        if t["crossing_ref"] == "zebra" { return (.bars, false) }
        switch t["crossing"] {
        case "zebra": return (.bars, false)
        case "marked", "uncontrolled", "traffic_signals": return (.bars, true)
        case "unmarked", "no": return (.none, false)
        default: return nil
        }
    }

    static func signals(_ t: Tags) -> Bool { t["crossing"] == "traffic_signals" || t["crossing:signals"] == "yes" }

    // MARK: - Build

    public func build() -> Output {
        var out = Output()
        let roads = features.roads.filter { !$0.suppressesSurfaceRendering }
        let layouts = roads.map(layout)
        let cums = roads.map { Self.cumulative($0.centerline) }
        let boxes = roads.map { Rect2D(enclosing: $0.centerline).expanded(by: $0.width / 2 + 1) }
        out.conflicts = layouts.filter(\.conflict).count

        // Junctions: centreline vertices shared by three or more arms of non-service roads.
        func key(_ p: LocalPoint) -> SIMD2<Int64> { SIMD2(Int64((p.x * 100).rounded()), Int64((p.y * 100).rounded())) }
        var at: [SIMD2<Int64>: [(road: Int, vertex: Int)]] = [:]
        for (i, r) in roads.enumerated() where Self.roadClass(r.kind) != .service {
            for (k, p) in r.centerline.enumerated() { at[key(p), default: []].append((i, k)) }
        }
        var junctions: [[(along: Double, radius: Double)]] = Array(repeating: [], count: roads.count)
        for k in at.keys.sorted(by: { ($0.x, $0.y) < ($1.x, $1.y) }) {
            let list = at[k]!
            let arms = list.reduce(0) { $0 + ($1.vertex == 0 || $1.vertex == roads[$1.road].centerline.count - 1 ? 1 : 2) }
            guard arms >= 3 else { continue }
            for (i, v) in list {
                let radius = list.filter { $0.road != i }.map { roads[$0.road].width / 2 }.max() ?? 0
                junctions[i].append((cums[i][v], radius))
            }
        }

        // Crosswalks at mapped crossing ways.
        var extraCuts: [(road: Int, along: Double, signals: Bool)] = []
        let crossingNodes = features.points(of: .crossing)
        for (pi, path) in features.paths.enumerated() where path.isCrossing && path.centerline.count >= 2 {
            let pbox = Rect2D(enclosing: path.centerline)
            let pcum = Self.cumulative(path.centerline)
            for (ri, road) in roads.enumerated() where boxes[ri].intersects(pbox) && road.layer == path.layer {
                for a in 0..<(path.centerline.count - 1) {
                    for b in 0..<(road.centerline.count - 1) {
                        let p0 = path.centerline[a], p1 = path.centerline[a + 1], q0 = road.centerline[b], q1 = road.centerline[b + 1]
                        guard let (u, v) = Self.intersect(p0, p1, q0, q1) else { continue }
                        let x = q0 + (q1 - q0) * v
                        let alongRoad = cums[ri][b] + simd_distance(q0, q1) * v
                        // One crosswalk per place: a road split at the crossing node (or a second hit at a
                        // shared vertex) only gets its lines cut.
                        if let other = out.crosswalks.first(where: { simd_distance($0.point, x) < 1 }) {
                            if other.road != ri { extraCuts.append((ri, alongRoad, other.signals)) }
                            continue
                        }
                        let rd = simd_normalize(q1 - q0), cd = simd_normalize(p1 - p0)
                        let sinA = max(0.25, abs(rd.x * cd.y - rd.y * cd.x))
                        let sPath = pcum[a] + simd_distance(p0, p1) * u
                        let half = road.width / 2 / sinA
                        var tags = path.tags
                        let node = crossingNodes.first { simd_distance($0.position, x) < 1 }
                        if Self.style(tags) == nil || tags["crossing:markings"] == nil, let node {
                            for (k, val) in node.tags where tags[k] == nil { tags[k] = val }
                        }
                        let st = Self.style(tags)
                        out.crosswalks.append(Crosswalk(road: ri, point: x, along: alongRoad,
                                                        roadDir: rd, crossDir: cd, style: st?.style ?? .none, styleInferred: st?.inferred ?? false,
                                                        signals: Self.signals(tags), source: path.ref, path: pi,
                                                        pathSpan: (sPath - half)...(sPath + half)))
                        out.crossingSpans[pi, default: []].append((sPath - half)...(sPath + half))
                    }
                }
            }
        }
        // Crossing nodes without a crossing way: across the road at the node.
        for node in crossingNodes {
            guard let st = Self.style(node.tags), st.style != .none else { continue }
            guard !out.crosswalks.contains(where: { simd_distance($0.point, node.position) < 2 }) else { continue }
            var best: (road: Int, along: Double, point: LocalPoint, dir: LocalPoint, dist: Double)?
            for (ri, road) in roads.enumerated() where boxes[ri].contains(node.position) {
                for b in 0..<(road.centerline.count - 1) {
                    let q0 = road.centerline[b], q1 = road.centerline[b + 1], d = q1 - q0
                    let len2 = simd_length_squared(d)
                    guard len2 > 1e-9 else { continue }
                    let v = min(1, max(0, simd_dot(node.position - q0, d) / len2))
                    let foot = q0 + d * v, dist = simd_distance(foot, node.position)
                    if dist < 1, dist < (best?.dist ?? .infinity) {
                        best = (ri, cums[ri][b] + len2.squareRoot() * v, foot, d / len2.squareRoot(), dist)
                    }
                }
            }
            guard let best else { continue }
            out.crosswalks.append(Crosswalk(road: best.road, point: best.point, along: best.along, roadDir: best.dir,
                                            crossDir: LocalPoint(-best.dir.y, best.dir.x), style: st.style, styleInferred: st.inferred,
                                            signals: Self.signals(node.tags), source: node.ref, path: nil, pathSpan: nil))
        }

        // Crosswalk paint and stop bars.
        for cw in out.crosswalks {
            let road = roads[cw.road], lay = layouts[cw.road]
            var rng = cw.source.random("crosswalk")
            let sinA = max(0.25, abs(cw.roadDir.x * cw.crossDir.y - cw.roadDir.y * cw.crossDir.x))
            let halfBand = values.crossingWidth / 2
            func across(_ n: Double) -> LocalPoint { cw.point + cw.crossDir * (n / sinA) }
            func mark(_ role: RoadMark.Role, _ line: [LocalPoint], _ width: Double) {
                out.marks.append(RoadMark(role: role, colour: .crossingWhite, line: line, width: width,
                                          shade: wear(&rng), source: cw.source, inferred: cw.styleInferred))
            }
            if cw.style == .bars || cw.style == .ladder {
                let pitch = values.stripeWidth + values.stripeGap
                let k = max(1, Int((road.width - values.stripeWidth) / pitch) + 1)
                for j in 0..<k {
                    let c = across((Double(j) - Double(k - 1) / 2) * pitch)
                    mark(.crosswalkBar, [c - cw.roadDir * halfBand, c + cw.roadDir * halfBand], values.stripeWidth)
                }
            }
            if cw.style == .ladder || cw.style == .lines {
                for side in [-1.0, 1.0] {
                    let o = cw.roadDir * (side * (halfBand - values.transverseLineWidth / 2))
                    mark(.crosswalkLine, [across(-road.width / 2) + o, across(road.width / 2) + o], values.transverseLineWidth)
                }
            }
            guard cw.signals, cw.style != .none || lay.longitudinal else { continue }
            // Stop bars ahead of a signalised crossing, on the approach lanes: from the side away from an
            // adjacent junction, or both sides mid-block; one-way roads only on their legal approach.
            let near = junctions[cw.road].filter { abs($0.along - cw.along) <= $0.radius + 2 * values.crossingWidth }
                .min { abs($0.along - cw.along) < abs($1.along - cw.along) }
            var sides: [Double] = near.map { [$0.along > cw.along ? -1 : 1] } ?? [-1, 1]
            sides = sides.filter { s in lay.oneway == 0 || (s < 0 ? lay.oneway == 1 : lay.oneway == -1) }
            let centre = lay.longitudinal ? (lay.centreStart + lay.centreEnd) / 2 : (lay.right + lay.left) / 2
            for s in sides {
                let along = cw.along + s * (halfBand + tuning.stopBarSetbackM + values.stopBarWidth / 2)
                guard along > 0, along < cums[cw.road].last!, let (p, d) = Self.point(road.centerline, cums[cw.road], at: along) else { continue }
                let n = LocalPoint(-d.y, d.x)
                let (a, b) = lay.oneway != 0 ? (lay.right, lay.left) : s < 0 ? (lay.right, centre) : (centre, lay.left)
                out.marks.append(RoadMark(role: .stopBar, colour: .white, line: [p + n * a, p + n * b], width: values.stopBarWidth,
                                          shade: wear(&rng), source: road.ref, inferred: false))
            }
        }

        // Longitudinal lines, cut at junction boxes and crosswalks.
        for (i, road) in roads.enumerated() where road.centerline.count >= 2 {
            let lay = layouts[i]
            guard lay.longitudinal || lay.bikeLeft || lay.bikeRight else { continue }
            let cum = cums[i], length = cum.last!
            var cuts = junctions[i].map { ($0.along - $0.radius)...($0.along + $0.radius) }
            for c in out.crosswalks.map({ ($0.road, $0.along, $0.signals) }) + extraCuts.map({ ($0.road, $0.along, $0.signals) }) where c.0 == i {
                let e = values.crossingWidth / 2 + (c.2 ? tuning.stopBarSetbackM + values.stopBarWidth : 0)
                cuts.append((c.1 - e)...(c.1 + e))
            }
            let spans = Self.subtract(cuts, from: 0...length).filter { $0.upperBound - $0.lowerBound >= values.dashLength }
            var rng = road.ref.random("markings")
            let w = values.lineWidth, pair = values.doubleLineGap / 2 + w / 2
            var lines: [(offset: Double, colour: RoadMark.Colour, dashed: Bool, role: RoadMark.Role)] = []
            if lay.longitudinal {
                let lw = lay.laneWidth
                for k in 1..<max(1, lay.forward) { lines.append((lay.right + Double(k) * lw, .white, true, .laneDivider)) }
                for k in 1..<max(1, lay.backward) { lines.append((lay.centreEnd + Double(k) * lw, .white, true, .laneDivider)) }
                if lay.forward > 0, lay.backward > 0 {
                    if lay.centreTurn == 0 {
                        lines += [(lay.centreStart - pair, .yellow, false, .centre), (lay.centreStart + pair, .yellow, false, .centre)]
                    } else {
                        lines += [(lay.centreStart - pair, .yellow, false, .centre), (lay.centreStart + pair, .yellow, true, .centre),
                                  (lay.centreEnd - pair, .yellow, true, .centre), (lay.centreEnd + pair, .yellow, false, .centre)]
                    }
                }
                if lay.divided {
                    // The median (left of travel) edge is yellow, the outer edge white (roads-01 correction).
                    let leftOfTravelIsLeft = lay.oneway >= 0
                    lines.append((lay.left - w, leftOfTravelIsLeft ? .yellow : .white, false, .edge))
                    lines.append((lay.right + w, leftOfTravelIsLeft ? .white : .yellow, false, .edge))
                }
            }
            if lay.bikeRight { lines.append((lay.right, .white, false, .bikeLane)) }
            if lay.bikeLeft { lines.append((lay.left, .white, false, .bikeLane)) }
            for line in lines {
                for span in spans {
                    if line.dashed {
                        var s = span.lowerBound
                        while s + values.dashLength <= span.upperBound {
                            let sub = Self.subline(road.centerline, cum, from: s, to: s + values.dashLength)
                            out.marks.append(RoadMark(role: line.role, colour: line.colour, line: Polyline.offset(sub, by: line.offset),
                                                      width: w, shade: wear(&rng), source: road.ref, inferred: lay.inferredLanes))
                            s += values.dashLength + values.dashGap
                        }
                    } else {
                        let sub = Self.subline(road.centerline, cum, from: span.lowerBound, to: span.upperBound)
                        out.marks.append(RoadMark(role: line.role, colour: line.colour, line: Polyline.offset(sub, by: line.offset),
                                                  width: w, shade: wear(&rng), source: road.ref,
                                                  inferred: line.role == .bikeLane ? false : lay.inferredLanes))
                    }
                }
            }
        }
        return out
    }

    func wear(_ r: inout StableRandom) -> Float { Float(1 - tuning.wearShadeMax * r.unit()) }

    // MARK: - Polyline helpers

    static func cumulative(_ l: [LocalPoint]) -> [Double] {
        var out = [0.0]
        for (a, b) in zip(l, l.dropFirst()) { out.append(out.last! + simd_distance(a, b)) }
        return out
    }

    /// Point and unit direction at distance `s` along a polyline.
    static func point(_ l: [LocalPoint], _ cum: [Double], at s: Double) -> (LocalPoint, LocalPoint)? {
        guard l.count >= 2 else { return nil }
        var k = 0
        while k < l.count - 2 && cum[k + 1] < s { k += 1 }
        let len = cum[k + 1] - cum[k]
        guard len > 1e-9 else { return nil }
        let t = min(1, max(0, (s - cum[k]) / len))
        return (l[k] + (l[k + 1] - l[k]) * t, (l[k + 1] - l[k]) / len)
    }

    /// The part of a polyline between distances `a` and `b`.
    static func subline(_ l: [LocalPoint], _ cum: [Double], from a: Double, to b: Double) -> [LocalPoint] {
        func at(_ s: Double) -> LocalPoint {
            var k = 0
            while k < l.count - 2 && cum[k + 1] < s { k += 1 }
            let len = cum[k + 1] - cum[k]
            return len > 1e-9 ? l[k] + (l[k + 1] - l[k]) * min(1, max(0, (s - cum[k]) / len)) : l[k]
        }
        var out = [at(a)]
        for k in l.indices where cum[k] > a && cum[k] < b { out.append(l[k]) }
        out.append(at(b))
        return out
    }

    /// `whole` minus the union of `cuts`, in order.
    static func subtract(_ cuts: [ClosedRange<Double>], from whole: ClosedRange<Double>) -> [ClosedRange<Double>] {
        var out: [ClosedRange<Double>] = []
        var start = whole.lowerBound
        for c in cuts.sorted(by: { $0.lowerBound < $1.lowerBound }) where c.upperBound > start {
            if c.lowerBound > start { out.append(start...min(c.lowerBound, whole.upperBound)) }
            start = max(start, c.upperBound)
            if start >= whole.upperBound { break }
        }
        if start < whole.upperBound { out.append(start...whole.upperBound) }
        return out
    }

    /// Parameters (u on p0→p1, v on q0→q1) where two segments meet, ends included.
    static func intersect(_ p0: LocalPoint, _ p1: LocalPoint, _ q0: LocalPoint, _ q1: LocalPoint) -> (Double, Double)? {
        let r = p1 - p0, s = q1 - q0
        let den = r.x * s.y - r.y * s.x
        guard abs(den) > 1e-9 else { return nil }
        let d = q0 - p0
        let u = (d.x * s.y - d.y * s.x) / den, v = (d.x * r.y - d.y * r.x) / den
        let eps = 1e-6
        guard u >= -eps, u <= 1 + eps, v >= -eps, v <= 1 + eps else { return nil }
        return (min(1, max(0, u)), min(1, max(0, v)))
    }
}
