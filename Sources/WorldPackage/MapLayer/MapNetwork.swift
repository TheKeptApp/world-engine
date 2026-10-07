import Foundation
import simd
import WorldGeo
import WorldMap

/// The street and path network of the map data layer (worldengine.map/2 §5): every `highway=*`
/// way that is not an area, split at shared nodes, barriers and closed loops, with the pieces that
/// reach within `marginM` of the playable area. Raw OSM facts only; nothing is estimated.
struct MapNetwork {
    struct Segment {
        var id: String
        var way: Int64
        /// Node IDs along the piece (first = from, last = to).
        var nodeIDs: [Int64]
        /// Plan points along the piece (same count as `nodeIDs`).
        var points: [LocalPoint]
        var tags: Tags
        var lengthM: Double
        var midpoint: LocalPoint
        /// Index range of the piece in the way's full node list (the source link of its ID).
        var range: ClosedRange<Int>
    }

    struct Barrier { var node: Int64; var tags: Tags }

    struct GatedArea { var id: String; var polygon: Polygon2D; var tags: Tags }

    struct Restriction {
        var id: String
        var tags: Tags
        var from: String
        var to: String
        var viaNode: Int64?
        var viaSegments: [String]
    }

    struct Control { var kind: String; var approaches: Set<String> }

    var nodes: [Int64: (position: LocalPoint, tags: Tags)] = [:]
    var segments: [Segment] = []
    var barriers: [Barrier] = []
    var gatedAreas: [GatedArea] = []
    var restrictions: [Restriction] = []
    var controls: [Int64: Control] = [:]
    /// Segment indices by way ID, in piece order.
    var byWay: [Int64: [Int]] = [:]

    /// Ways in the network: every `highway=*` way that is not an area.
    static func isNetworkWay(_ w: OSMWay) -> Bool {
        w.tags["highway"] != nil && w.tags["area"] != "yes" && w.nodeIDs.count >= 2
    }

    /// Stop signs and give-way signs on a way apply to the junction they precede: within this many
    /// metres along the piece (traffic signals mapped beside the junction likewise).
    static let signReachM = 30.0
    static let signalReachM = 20.0

    init(doc: OSMDocument, frame: LocalFrame, playable: Rect2D, marginM: Double) {
        let reach = playable.expanded(by: marginM)
        let ways = doc.ways.values.filter(Self.isNetworkWay).sorted { $0.id < $1.id }

        // Junctions: nodes on two or more network ways, or twice on one (not as a loop's closing node).
        var uses: [Int64: Int] = [:]
        var repeated: Set<Int64> = []
        for w in ways {
            let ids = w.isClosed ? Array(w.nodeIDs.dropLast()) : w.nodeIDs
            var seen: Set<Int64> = []
            for id in ids {
                if !seen.insert(id).inserted { repeated.insert(id) } else { uses[id, default: 0] += 1 }
            }
        }
        func splits(_ id: Int64) -> Bool {
            (uses[id] ?? 0) >= 2 || repeated.contains(id) || doc.nodes[id]?.tags["barrier"] != nil
        }

        var local: [Int64: LocalPoint] = [:]
        func position(_ id: Int64) -> LocalPoint? {
            if let p = local[id] { return p }
            guard let n = doc.nodes[id] else { return nil }
            let p = frame.localPoint(of: n.coordinate)
            local[id] = p
            return p
        }

        for w in ways {
            // Piece boundaries along the full node list.
            var cuts = [0]
            for i in 1..<(w.nodeIDs.count - 1) where splits(w.nodeIDs[i]) { cuts.append(i) }
            cuts.append(w.nodeIDs.count - 1)
            var ranges: [ClosedRange<Int>] = []
            for (a, b) in zip(cuts, cuts.dropFirst()) where b > a {
                // A piece that starts and ends at the same node is split once more in its middle.
                if w.nodeIDs[a] == w.nodeIDs[b], b - a >= 2 {
                    let m = (a + b) / 2
                    ranges += [a...m, m...b]
                } else {
                    ranges.append(a...b)
                }
            }
            for (k, r) in ranges.enumerated() {
                let ids = Array(w.nodeIDs[r])
                guard ids.first != ids.last else { continue }
                let pts = ids.compactMap(position)
                guard pts.count == ids.count else { continue } // a node is missing from the extract
                let inside = pts.contains { reach.contains($0) } || !Clipping.clip(polyline: pts, to: reach).isEmpty
                guard inside else { continue }
                let rounded = pts.map { LocalPoint(MapJSON.round3($0.x), MapJSON.round3($0.y)) }
                var length = 0.0
                for (p, q) in zip(rounded, rounded.dropFirst()) { length += simd_distance(p, q) }
                // Rounded up to the mm so it never falls below the straight-line distance (§5.2).
                length = max(0.001, (length * 1000).rounded(.up) / 1000)
                let seg = Segment(id: "way/\(w.id):\(k)", way: w.id, nodeIDs: ids, points: pts, tags: Self.stripAddress(w.tags),
                                  lengthM: length, midpoint: Self.pointAlong(pts, fraction: 0.5), range: r)
                byWay[w.id, default: []].append(segments.count)
                segments.append(seg)
                for id in [ids.first!, ids.last!] where nodes[id] == nil {
                    nodes[id] = (pts[id == ids.first! ? 0 : pts.count - 1], Self.stripAddress(doc.nodes[id]?.tags ?? [:]))
                }
            }
        }

        // Barriers sit on segment ends (the network is split there).
        for id in nodes.keys.sorted() {
            if let tags = nodes[id]?.tags, tags["barrier"] != nil { barriers.append(Barrier(node: id, tags: tags)) }
        }

        controls = Self.controls(segments: segments, nodes: nodes, doc: doc)
        gatedAreas = Self.gatedAreas(doc: doc, frame: frame, reach: reach)
        restrictions = Self.restrictions(doc: doc, segments: segments, byWay: byWay)
    }

    // MARK: - Traffic control

    static func controlKind(_ tags: Tags) -> String? {
        switch tags["highway"] {
        case "traffic_signals": "traffic_signals"
        case "stop": tags["stop"] == "all" ? "all_way_stop" : "stop"
        case "give_way": "give_way"
        default: nil
        }
    }

    static let controlRank = ["give_way": 0, "stop": 1, "all_way_stop": 2, "traffic_signals": 3]

    /// A node's own control tag, or a sign mapped on a piece just before its end node
    /// (`direction=forward|backward` picks the end; otherwise the nearer end within reach).
    static func controls(segments: [Segment], nodes: [Int64: (position: LocalPoint, tags: Tags)], doc: OSMDocument) -> [Int64: Control] {
        var out: [Int64: Control] = [:]
        for (id, n) in nodes { if let k = controlKind(n.tags) { out[id] = Control(kind: k, approaches: []) } }
        var attached: [Int64: Control] = [:]
        for s in segments where s.nodeIDs.count > 2 {
            var along = [0.0]
            for (p, q) in zip(s.points, s.points.dropFirst()) { along.append(along.last! + simd_distance(p, q)) }
            let total = along.last!
            for i in 1..<(s.nodeIDs.count - 1) {
                guard let tags = doc.nodes[s.nodeIDs[i]]?.tags, let kind = controlKind(tags) else { continue }
                let reachM = kind == "traffic_signals" ? signalReachM : signReachM
                let toEnd: Bool?
                switch tags["direction"] {
                case "forward": toEnd = total - along[i] <= reachM ? true : nil
                case "backward": toEnd = along[i] <= reachM ? false : nil
                default:
                    let dEnd = total - along[i], dStart = along[i]
                    toEnd = min(dEnd, dStart) <= reachM ? dEnd <= dStart : nil
                }
                guard let toEnd else { continue }
                let target = toEnd ? s.nodeIDs.last! : s.nodeIDs.first!
                var c = attached[target] ?? Control(kind: kind, approaches: [])
                if controlRank[kind]! > controlRank[c.kind]! { c.kind = kind }
                if kind != "traffic_signals" { c.approaches.insert(s.id) }
                attached[target] = c
            }
        }
        for (id, c) in attached {
            if var own = out[id] {
                if controlRank[c.kind]! > controlRank[own.kind]! { own.kind = c.kind }
                out[id] = own
            } else {
                out[id] = c
            }
        }
        return out
    }

    // MARK: - Gated areas

    /// Areas mapped as private or gated: `access=private|no` on a landuse, parking or residential
    /// area, or `gated=yes`.
    static func isGatedArea(_ t: Tags) -> Bool {
        guard t["highway"] == nil, t["building"] == nil else { return false }
        if t["gated"] == "yes" { return true }
        guard let a = t["access"], a == "private" || a == "no" else { return false }
        return t["landuse"] != nil || t["amenity"] == "parking" || t["residential"] != nil || t["place"] != nil
    }

    static func gatedAreas(doc: OSMDocument, frame: LocalFrame, reach: Rect2D) -> [GatedArea] {
        var out: [GatedArea] = []
        for w in doc.ways.values where w.isClosed && isGatedArea(w.tags) {
            guard let coords = doc.coordinates(of: w) else { continue }
            var ring = coords.dropLast().map(frame.localPoint(of:))
            if RingMath.signedArea(ring) < 0 { ring.reverse() }
            let poly = Polygon2D(outer: ring)
            guard poly.bounds.intersects(reach) else { continue }
            out.append(GatedArea(id: "way/\(w.id)", polygon: poly, tags: stripAddress(w.tags)))
        }
        for r in doc.relations.values where r.tags["type"] == "multipolygon" && isGatedArea(r.tags) {
            guard case .success(let polys) = MultipolygonAssembler.assemble(r, in: doc, frame: frame),
                  let poly = polys.max(by: { abs($0.area) < abs($1.area) }), poly.bounds.intersects(reach) else { continue }
            out.append(GatedArea(id: "relation/\(r.id)", polygon: oriented(poly), tags: stripAddress(r.tags)))
        }
        return out.sorted { MapJSON.byteOrder($0.id, $1.id) }
    }

    /// Outer ring counter-clockwise, holes clockwise.
    static func oriented(_ p: Polygon2D) -> Polygon2D {
        var o = p.outer
        if RingMath.signedArea(o) < 0 { o.reverse() }
        let holes = p.holes.map { RingMath.signedArea($0) > 0 ? Array($0.reversed()) : $0 }
        return Polygon2D(outer: o, holes: holes)
    }

    // MARK: - Turn restrictions

    static func restrictions(doc: OSMDocument, segments: [Segment], byWay: [Int64: [Int]]) -> [Restriction] {
        var out: [Restriction] = []
        for r in doc.relations.values.sorted(by: { $0.id < $1.id }) where r.tags["type"] == "restriction" && r.tags["restriction"] != nil {
            let fromWays = r.members.filter { $0.role == "from" && $0.kind == .way }
            let toWays = r.members.filter { $0.role == "to" && $0.kind == .way }
            let via = r.members.filter { $0.role == "via" }
            guard fromWays.count == 1, toWays.count == 1, !via.isEmpty else { continue }
            func pieces(_ way: Int64) -> [Segment] { (byWay[way] ?? []).map { segments[$0] } }
            func touching(_ way: Int64, node: Int64) -> Segment? {
                pieces(way).first { $0.nodeIDs.first == node || $0.nodeIDs.last == node }
            }
            if via.count == 1, via[0].kind == .node {
                let v = via[0].ref
                guard let f = touching(fromWays[0].ref, node: v), let t = touching(toWays[0].ref, node: v) else { continue }
                out.append(Restriction(id: "relation/\(r.id)", tags: r.tags, from: f.id, to: t.id, viaNode: v, viaSegments: []))
            } else if via.allSatisfy({ $0.kind == .way }) {
                // Via ways: walk from the from-way through the via pieces to the to-way.
                let viaPieces = via.flatMap { pieces($0.ref) }
                guard !viaPieces.isEmpty else { continue }
                let fromPieces = pieces(fromWays[0].ref)
                var chain: [Segment] = []
                var current: Int64?
                for f in fromPieces {
                    for end in [f.nodeIDs.first!, f.nodeIDs.last!] where viaPieces.contains(where: { $0.nodeIDs.first == end || $0.nodeIDs.last == end }) {
                        current = end
                    }
                    if current != nil { chain = [f]; break }
                }
                guard var node = current, let from = chain.first else { continue }
                var used: Set<String> = []
                var viaChain: [String] = []
                while let next = viaPieces.first(where: { !used.contains($0.id) && ($0.nodeIDs.first == node || $0.nodeIDs.last == node) }) {
                    used.insert(next.id)
                    viaChain.append(next.id)
                    node = next.nodeIDs.first == node ? next.nodeIDs.last! : next.nodeIDs.first!
                }
                guard viaChain.count == viaPieces.count, let t = touching(toWays[0].ref, node: node) else { continue }
                out.append(Restriction(id: "relation/\(r.id)", tags: r.tags, from: from.id, to: t.id, viaNode: nil, viaSegments: viaChain))
            }
        }
        return out
    }

    // MARK: - Helpers

    /// `addr:*` keys are never exported (§6, §13).
    static func stripAddress(_ t: Tags) -> Tags { t.filter { !$0.key.hasPrefix("addr:") } }

    static func pointAlong(_ pts: [LocalPoint], fraction: Double) -> LocalPoint {
        var total = 0.0
        for (p, q) in zip(pts, pts.dropFirst()) { total += simd_distance(p, q) }
        var target = total * fraction
        for (p, q) in zip(pts, pts.dropFirst()) {
            let d = simd_distance(p, q)
            if target <= d, d > 0 { return p + (q - p) * (target / d) }
            target -= d
        }
        return pts.last!
    }

    /// Nearest point on a piece: distance along it from its first point, and which side
    /// (`left` / `right` looking along it) `p` lies on.
    static func project(_ p: LocalPoint, onto pts: [LocalPoint]) -> (offset: Double, distance: Double, side: String) {
        var best = (offset: 0.0, distance: Double.infinity, side: "right")
        var along = 0.0
        for (a, b) in zip(pts, pts.dropFirst()) {
            let d = b - a
            let len2 = simd_length_squared(d)
            let t = len2 > 0 ? min(1, max(0, simd_dot(p - a, d) / len2)) : 0
            let q = a + d * t
            let dist = simd_distance(p, q)
            if dist < best.distance {
                let cross = d.x * (p.y - a.y) - d.y * (p.x - a.x)
                best = (along + len2.squareRoot() * t, dist, cross > 0 ? "left" : "right")
            }
            along += len2.squareRoot()
        }
        return best
    }

    // MARK: - Normalized fields (§5.2, §5.3)

    static func oneway(_ t: Tags) -> String {
        switch t["oneway"] {
        case "yes", "true", "1": return "forward"
        case "-1", "reverse": return "backward"
        case "reversible", "alternating": return "reversible"
        case "no", "false", "0": return "no"
        default:
            if t["oneway"] == nil, let j = t["junction"], j == "roundabout" || j == "circular" { return "forward" }
            return "no"
        }
    }

    /// Access by mode from the element's own tags along the OSM hierarchy; untagged modes absent.
    static func access(_ t: Tags) -> [String: String] {
        var a: [String: String] = [:]
        if let v = t["access"] { a["all"] = v }
        if let v = t["foot"] ?? t["access"] { a["foot"] = v }
        if let v = t["bicycle"] ?? t["vehicle"] ?? t["access"] { a["bicycle"] = v }
        if let v = t["motor_vehicle"] ?? t["vehicle"] ?? t["access"] { a["motorVehicle"] = v }
        return a
    }

    /// `width=*` in metres: plain numbers are metres; `m`, `ft`, `'`/`"` converted.
    static func widthM(_ raw: String) -> Double? {
        let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !s.contains(";") else { return nil }
        let v: Double?
        if s.contains("'") || s.contains("\"") {
            let feet = s.split(separator: "'", omittingEmptySubsequences: false)
            let f = Double(feet[0].trimmingCharacters(in: .whitespaces))
            var inch = 0.0
            if feet.count > 1 {
                let rest = feet[1].replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty { guard let i = Double(rest) else { return nil }; inch = i }
            }
            v = f.map { $0 * 0.3048 + inch * 0.0254 }
        } else if s.hasSuffix("ft") {
            v = Double(s.dropLast(2).trimmingCharacters(in: .whitespaces)).map { $0 * 0.3048 }
        } else if s.hasSuffix("m") {
            v = Double(s.dropLast(1).trimmingCharacters(in: .whitespaces))
        } else {
            v = Double(s)
        }
        guard let v, v > 0, v.isFinite else { return nil }
        return v
    }

    /// `maxspeed=*` in km/h (`35 mph` → 56.327); absent when symbolic (`US:urban`) or unparsable.
    static func maxspeedKmh(_ raw: String) -> Double? {
        let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !s.contains(";") else { return nil }
        let v: Double?
        if s.hasSuffix("mph") {
            v = Double(s.dropLast(3).trimmingCharacters(in: .whitespaces)).map { $0 * 1.609344 }
        } else if s.hasSuffix("km/h") {
            v = Double(s.dropLast(4).trimmingCharacters(in: .whitespaces))
        } else if s.hasSuffix("knots") {
            v = Double(s.dropLast(5).trimmingCharacters(in: .whitespaces)).map { $0 * 1.852 }
        } else {
            v = Double(s)
        }
        guard let v, v > 0, v.isFinite else { return nil }
        return v
    }

    static func positiveInt(_ raw: String?, min lo: Int) -> Int? {
        guard let raw, let v = Int(raw.trimmingCharacters(in: .whitespaces)), v >= lo else { return nil }
        return v
    }
}
