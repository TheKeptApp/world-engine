import Foundation
import simd
import WorldGeo

/// `mapmeta/migration.json`: how the IDs of a previous package's map layer map onto this one's.
/// Only IDs that disappeared are listed (an ID that still exists still means the same object, §3
/// "Stability"); new IDs are listed as added. Matching is geometric, in the shared area frame:
///
/// - segments: an old piece's points sampled every 2 m; new segments within 1.5 m of at least 20 %
///   of the samples replace it (`renumbered` when the way is the same and one piece replaces it,
///   `split` for several pieces, `merged` when several old pieces map to one new, `replaced` when
///   the way changed), else `deleted`;
/// - nodes: the new node within 1 m, else `deleted`;
/// - buildings: new footprints overlapping the old one at IoU ≥ 0.5 (`replaced`), or covering ≥ 50 %
///   of it (`merged` when several old map to one new, `split` when one old maps to several), else
///   `deleted`;
/// - lots and entry points follow their building (same part or kind), else `deleted`;
/// - places: the same `class` within 15 m (`replaced`), else `deleted`.
enum MapMigration {
    struct Snapshot {
        var id: String
        var origin: [Double]
        var segments: [String: [LocalPoint]] = [:]
        var segmentWay: [String: String] = [:]
        var nodes: [String: LocalPoint] = [:]
        var buildings: [String: Ring] = [:]
        var lots: Set<String> = []
        var entries: Set<String> = []
        var places: [String: (cls: String, position: LocalPoint)] = [:]
    }

    static func load(_ read: (String) throws -> Data?) throws -> Snapshot? {
        func obj(_ path: String) throws -> [String: Any]? {
            guard let d = try read(path) else { return nil }
            return try JSONSerialization.jsonObject(with: d) as? [String: Any]
        }
        guard let world = try obj("world.json"), let snap = world["mapSnapshotID"] as? String,
              let header = try obj("map/layer.json"), let net = try obj("map/network.json") else { return nil }
        let o = ((header["frame"] as? [String: Any])?["origin"] as? [String: Any]) ?? [:]
        var s = Snapshot(id: snap, origin: [o["latitude"] as? Double ?? 0, o["longitude"] as? Double ?? 0])
        func pt(_ a: Any?) -> LocalPoint? {
            guard let v = a as? [Double], v.count == 2 else { return nil }
            return LocalPoint(v[0], v[1])
        }
        for n in net["nodes"] as? [[String: Any]] ?? [] {
            if let id = n["id"] as? String, let p = pt(n["position"]) { s.nodes[id] = p }
        }
        for seg in net["segments"] as? [[String: Any]] ?? [] {
            guard let id = seg["id"] as? String, let f = seg["from"] as? String, let t = seg["to"] as? String,
                  let a = s.nodes[f], let b = s.nodes[t] else { continue }
            let mid = (seg["geometry"] as? [[Double]] ?? []).compactMap { pt($0) }
            s.segments[id] = [a] + mid + [b]
            s.segmentWay[id] = seg["way"] as? String
        }
        for b in try obj("map/buildings.json")?["buildings"] as? [[String: Any]] ?? [] {
            if let id = b["id"] as? String, let rings = b["footprint"] as? [[[Double]]], let outer = rings.first {
                s.buildings[id] = outer.compactMap { pt($0) }
            }
        }
        for l in try obj("map/lots.json")?["lots"] as? [[String: Any]] ?? [] { if let id = l["id"] as? String { s.lots.insert(id) } }
        for e in try obj("map/entries.json")?["entries"] as? [[String: Any]] ?? [] { if let id = e["id"] as? String { s.entries.insert(id) } }
        for p in try obj("map/places.json")?["places"] as? [[String: Any]] ?? [] {
            if let id = p["id"] as? String, let c = p["class"] as? String, let q = pt(p["position"]) { s.places[id] = (c, q) }
        }
        return s
    }

    static func distance(_ p: LocalPoint, _ line: [LocalPoint]) -> Double {
        var best = Double.infinity
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a, len2 = simd_length_squared(d)
            let t = len2 > 0 ? min(1, max(0, simd_dot(p - a, d) / len2)) : 0
            best = min(best, simd_distance(p, a + d * t))
        }
        return best
    }

    static func samples(_ line: [LocalPoint], step: Double = 2) -> [LocalPoint] {
        var out: [LocalPoint] = []
        for (a, b) in zip(line, line.dropFirst()) {
            let n = max(1, Int((simd_distance(a, b) / step).rounded(.up)))
            for i in 0..<n { out.append(a + (b - a) * (Double(i) / Double(n))) }
        }
        if let l = line.last { out.append(l) }
        return out
    }

    /// Overlap of two rings by 0.5 m point sampling: (intersection / old area, IoU).
    static func overlap(_ a: Ring, _ b: Ring) -> (ofOld: Double, iou: Double) {
        let ba = Rect2D(enclosing: a), bb = Rect2D(enclosing: b)
        guard ba.intersects(bb) else { return (0, 0) }
        let box = Rect2D(min: simd_min(ba.min, bb.min), max: simd_max(ba.max, bb.max))
        var ina = 0, inb = 0, both = 0
        var y = box.min.y + 0.25
        while y < box.max.y {
            var x = box.min.x + 0.25
            while x < box.max.x {
                let p = LocalPoint(x, y)
                let ia = RingMath.contains(a, p), ib = RingMath.contains(b, p)
                if ia { ina += 1 }
                if ib { inb += 1 }
                if ia && ib { both += 1 }
                x += 0.5
            }
            y += 0.5
        }
        let union = ina + inb - both
        return (ina > 0 ? Double(both) / Double(ina) : 0, union > 0 ? Double(both) / Double(union) : 0)
    }

    static func compare(old: Snapshot, new: Snapshot) throws -> MapJSON {
        guard old.origin.count == 2, new.origin.count == 2, abs(old.origin[0] - new.origin[0]) < 1e-9, abs(old.origin[1] - new.origin[1]) < 1e-9 else {
            throw MapLayerError.badInput("previous package has a different frame origin; IDs cannot be matched geometrically")
        }
        var out: [String: MapJSON] = [:]
        func entry(_ old: String, _ new: [String], _ change: String) -> MapJSON {
            .object(["old": .string(old), "new": MapJSON.strings(new.sorted(by: MapJSON.byteOrder)), "change": .string(change)])
        }

        // Segments.
        var segMap: [String: [String]] = [:]
        let newSegs = Array(new.segments)
        for (id, line) in old.segments where new.segments[id] == nil {
            let pts = samples(line)
            let box = Rect2D(enclosing: line).expanded(by: 2)
            var hits: [String: Int] = [:]
            let near = newSegs.filter { Rect2D(enclosing: $0.value).intersects(box) }
            for p in pts { if let best = near.map({ ($0.key, distance(p, $0.value)) }).min(by: { $0.1 < $1.1 }), best.1 <= 1.5 { hits[best.0, default: 0] += 1 } }
            segMap[id] = hits.filter { Double($0.value) >= 0.2 * Double(pts.count) }.map(\.key)
        }
        out["segments"] = .array(classify(segMap, sameSource: { o, n in old.segmentWay[o] == new.segmentWay[n] }, entry: entry))

        // Nodes.
        var nodeRecs: [MapJSON] = []
        for (id, p) in old.nodes where new.nodes[id] == nil {
            let best = new.nodes.min { simd_distance($0.value, p) < simd_distance($1.value, p) }
            if let b = best, simd_distance(b.value, p) <= 1 { nodeRecs.append(entry(id, [b.key], "replaced")) } else { nodeRecs.append(entry(id, [], "deleted")) }
        }
        out["nodes"] = .array(sortRecords(nodeRecs))

        // Buildings.
        var bMap: [String: [String]] = [:]
        for (id, ring) in old.buildings where new.buildings[id] == nil {
            let box = Rect2D(enclosing: ring)
            var m: [String] = []
            for (nid, nring) in new.buildings where Rect2D(enclosing: nring).intersects(box) {
                let o = overlap(ring, nring)
                if o.iou >= 0.5 || o.ofOld >= 0.5 || overlap(nring, ring).ofOld >= 0.5 { m.append(nid) }
            }
            bMap[id] = m
        }
        out["buildings"] = .array(classify(bMap, sameSource: { _, _ in false }, entry: entry))

        // Lots and entry points follow their building.
        func follow(_ oldIDs: Set<String>, _ newIDs: Set<String>, prefix: String) -> [MapJSON] {
            var recs: [MapJSON] = []
            for id in oldIDs where !newIDs.contains(id) {
                let rest = id.dropFirst(prefix.count)
                // gen:lot:<building>:<part> / gen:entry:<building>:<kind>[:n]: the building is everything up to the part/kind.
                let parts = rest.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 3 else { recs.append(entry(id, [], "deleted")); continue }
                let kindIndex = prefix == "gen:lot:" ? parts.count - 1 : (Int(parts.last!) != nil ? parts.count - 2 : parts.count - 1)
                let building = parts[..<kindIndex].joined(separator: ":")
                let suffix = parts[kindIndex...].joined(separator: ":")
                let targets = (bMap[building] ?? []).map { "\(prefix)\($0):\(suffix)" }.filter { newIDs.contains($0) }
                recs.append(entry(id, targets, targets.isEmpty ? "deleted" : "replaced"))
            }
            return sortRecords(recs)
        }
        out["lots"] = .array(follow(old.lots, new.lots, prefix: "gen:lot:"))
        out["entries"] = .array(follow(old.entries, new.entries, prefix: "gen:entry:"))

        // Places.
        var placeRecs: [MapJSON] = []
        for (id, p) in old.places where new.places[id] == nil {
            let best = new.places.filter { $0.value.cls == p.cls }.min { simd_distance($0.value.position, p.position) < simd_distance($1.value.position, p.position) }
            if let b = best, simd_distance(b.value.position, p.position) <= 15 { placeRecs.append(entry(id, [b.key], "replaced")) } else { placeRecs.append(entry(id, [], "deleted")) }
        }
        out["places"] = .array(sortRecords(placeRecs))

        var added: [String: MapJSON] = [:]
        added["segments"] = MapJSON.strings(new.segments.keys.filter { old.segments[$0] == nil }.sorted(by: MapJSON.byteOrder))
        added["nodes"] = MapJSON.strings(new.nodes.keys.filter { old.nodes[$0] == nil }.sorted(by: MapJSON.byteOrder))
        added["buildings"] = MapJSON.strings(new.buildings.keys.filter { old.buildings[$0] == nil }.sorted(by: MapJSON.byteOrder))
        added["lots"] = MapJSON.strings(new.lots.subtracting(old.lots).sorted(by: MapJSON.byteOrder))
        added["entries"] = MapJSON.strings(new.entries.subtracting(old.entries).sorted(by: MapJSON.byteOrder))
        added["places"] = MapJSON.strings(new.places.keys.filter { old.places[$0] == nil }.sorted(by: MapJSON.byteOrder))

        return .object([
            "schema": .string(MapMeta.schema), "file": .string("migration"),
            "fromSnapshot": .string(old.id), "toSnapshot": .string(new.id),
            "rules": .string("Old IDs that no longer exist, each with the new IDs that now carry its object (empty when deleted). Matching is geometric in the shared frame; see docs/data/map-layer.md."),
            "changed": .object(out), "added": .object(added),
        ])
    }

    /// split / merged / renumbered / replaced / deleted from an old → new map.
    static func classify(_ map: [String: [String]], sameSource: (String, String) -> Bool, entry: (String, [String], String) -> MapJSON) -> [MapJSON] {
        var inverse: [String: Int] = [:]
        for (_, ns) in map { for n in ns { inverse[n, default: 0] += 1 } }
        var recs: [MapJSON] = []
        for (o, ns) in map {
            let change: String
            if ns.isEmpty { change = "deleted" }
            else if ns.count > 1 { change = "split" }
            else if inverse[ns[0], default: 0] > 1 { change = "merged" }
            else if sameSource(o, ns[0]) { change = "renumbered" }
            else { change = "replaced" }
            recs.append(entry(o, ns, change))
        }
        return sortRecords(recs)
    }

    static func sortRecords(_ r: [MapJSON]) -> [MapJSON] {
        r.sorted { a, b in
            guard case .object(let x) = a, case .object(let y) = b, case .string(let i)? = x["old"], case .string(let j)? = y["old"] else { return false }
            return MapJSON.byteOrder(i, j)
        }
    }
}
