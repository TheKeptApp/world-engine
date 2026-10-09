import Foundation
import WorldGeo

/// Source diagnostics, not new geometry. A8 long-tail review rows 1–7 and R's tunnel task.
/// Counts unique OSM objects per key=value/reason; categories can overlap and must not be summed as objects.
public enum UnsupportedFeatures {
    public struct Entry: Codable, Sendable, Equatable {
        public var keyValue: String
        public var reason: String
        public var count: Int
        public var refs: [String]
    }
    public struct Report: Codable, Sendable {
        public var area: String
        public var entries: [Entry]
        public var summary: String {
            let counts = entries.map { "\($0.keyValue):\($0.reason)=\($0.count)" }.joined(separator: ",")
            return "Unsupported features [\(area)]: \(counts.isEmpty ? "none" : counts)"
        }
    }

    public static func collect(area: String, document: OSMDocument, features: MapFeatures,
                               drawnRefs: Set<String>) -> Report {
        var grouped: [String: Set<String>] = [:]
        let roadRefs = Set(features.roads.map { $0.ref.description })
        let underground = Set(features.roads.filter { $0.suppressesSurfaceRendering }.map { $0.ref.description }
            + (features.paths + features.sidewalks).filter { $0.suppressesPedestrianSurfaceRendering }.map { $0.ref.description })
        let layerOnly = Set(features.roads.filter { $0.layer < 0 && !$0.isTunnel }.map { $0.ref.description })
        let typedRefs = Set(features.buildings.map { $0.ref.description } + features.roads.map { $0.ref.description }
            + features.paths.map { $0.ref.description } + features.sidewalks.map { $0.ref.description }
            + features.areas.map { $0.ref.description } + features.points.map { $0.ref.description }
            + features.lines.map { $0.ref.description })
        func keys(_ tags: Tags) -> [String] {
            tags.keys.sorted().filter { key in
                switch key {
                case "bridge", "building:part", "man_made", "power", "aeroway": return tags[key] != "no"
                case "waterway": return ["stream", "ditch", "drain"].contains(tags[key]!)
                case "barrier": return true
                case "railway": return ["station", "platform"].contains(tags[key]!)
                default: return false
                }
            }
        }
        func visit(_ ref: OSMRef, _ tags: Tags, inBounds: Bool) {
            let id = ref.description
            guard inBounds || typedRefs.contains(id) else { return }
            for key in keys(tags) {
                let reason: String
                if underground.contains(id) { reason = "undergroundSuppressed" }
                else if key == "bridge", roadRefs.contains(id), drawnRefs.contains(id) { reason = "flatRoadFallback" }
                else if drawnRefs.contains(id) { continue }
                else { reason = "notDrawn" }
                grouped[key + "=" + tags[key]! + "\t" + reason, default: []].insert(id)
            }
            if layerOnly.contains(id) {
                grouped["layer=" + (tags["layer"] ?? "unknown") + "\tlayer-only, review", default: []].insert(id)
            }
            if underground.contains(id) {
                let key = tags["tunnel"].flatMap { $0 == "no" ? nil : "tunnel=" + $0 } ?? "layer=" + (tags["layer"] ?? "unknown")
                grouped[key + "\tundergroundSuppressed", default: []].insert(id)
            }
        }
        func intersects(_ way: OSMWay) -> Bool {
            guard let coordinates = document.coordinates(of: way) else { return false }
            let points = coordinates.map(features.frame.localPoint(of:))
            if points.contains(where: features.bounds.contains) { return true }
            if !Clipping.clip(polyline: points, to: features.bounds).isEmpty { return true }
            return way.isClosed && Polygon2D(outer: Array(points.dropLast())).contains((features.bounds.min + features.bounds.max) * 0.5)
        }
        for n in document.nodes.values { visit(OSMRef(.node,n.id),n.tags,inBounds:features.bounds.contains(features.frame.localPoint(of:n.coordinate))) }
        for w in document.ways.values { visit(OSMRef(.way,w.id),w.tags,inBounds:intersects(w)) }
        for r in document.relations.values {
            let inside = r.members.contains { m in
                if m.kind == .way, let w = document.ways[m.ref] { return intersects(w) }
                if m.kind == .node, let n = document.nodes[m.ref] { return features.bounds.contains(features.frame.localPoint(of:n.coordinate)) }
                return false
            }
            visit(OSMRef(.relation,r.id),r.tags,inBounds:inside)
        }
        let entries = grouped.keys.sorted().map { key in
            let parts = key.split(separator: "\t", maxSplits: 1).map(String.init), refs = grouped[key]!.sorted()
            return Entry(keyValue: parts[0], reason: parts[1], count: refs.count, refs: refs)
        }
        return Report(area: area, entries: entries)
    }
}
