import Foundation
import WorldGeo

/// Identifies a map feature: an OSM element, or a feature from a second source such as Overture.
/// Used as the stable seed for generated detail and as the key for future per-building overrides.
public struct OSMRef: Hashable, Codable, Sendable, CustomStringConvertible, Comparable {
    public enum Kind: String, Codable, Sendable, Comparable {
        case node, way, relation
        /// An Overture Maps feature. `id` holds the first 16 hex digits of its GERS ID
        /// (see `OSMRef.init(overtureID:)` in OvertureSource.swift).
        case overture
        public static func < (a: Kind, b: Kind) -> Bool { a.rawValue < b.rawValue }
    }

    public var kind: Kind
    public var id: Int64

    public init(_ kind: Kind, _ id: Int64) {
        self.kind = kind
        self.id = id
    }

    /// `node/<id>`, `way/<id>`, `relation/<id>`; Overture: `overture/<16 lowercase hex digits>`, the
    /// GERS ID prefix the ref holds (the form the map data layer's ID patterns require).
    public var description: String {
        kind == .overture ? "overture/" + String(format: "%016llx", UInt64(bitPattern: id)) : "\(kind.rawValue)/\(id)"
    }

    public static func < (a: OSMRef, b: OSMRef) -> Bool { (a.kind, a.id) < (b.kind, b.id) }

    /// A deterministic generator for this element. `salt` separates independent uses.
    public func random(_ salt: String) -> StableRandom {
        let kindCode: UInt64 = switch kind { case .node: 1; case .way: 2; case .relation: 3; case .overture: 4 }
        return StableRandom(kindCode, UInt64(bitPattern: id), salt: salt)
    }
}

public typealias Tags = [String: String]

public struct OSMNode: Sendable {
    public var id: Int64
    public var coordinate: GeoCoordinate
    public var tags: Tags
}

public struct OSMWay: Sendable {
    public var id: Int64
    public var nodeIDs: [Int64]
    public var tags: Tags

    public var isClosed: Bool { nodeIDs.count >= 4 && nodeIDs.first == nodeIDs.last }
}

public struct OSMRelation: Sendable {
    public struct Member: Sendable {
        public var kind: OSMRef.Kind
        public var ref: Int64
        public var role: String
    }

    public var id: Int64
    public var members: [Member]
    public var tags: Tags
}

/// Raw OSM elements, independent of where they came from (an Overpass JSON file today,
/// hosted tiles later). Several documents can be merged; elements are de-duplicated by ID,
/// which is what lets tiles that overlap at their borders combine cleanly.
public struct OSMDocument: Sendable {
    public var nodes: [Int64: OSMNode] = [:]
    public var ways: [Int64: OSMWay] = [:]
    public var relations: [Int64: OSMRelation] = [:]
    /// The OSM data timestamp reported by the source, if any.
    public var timestamp: String?

    public init() {}

    /// Parses Overpass API JSON (`[out:json]`).
    public init(overpassJSON data: Data) throws {
        let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
        timestamp = decoded.osm3s?.timestamp_osm_base
        for e in decoded.elements {
            let tags = e.tags ?? [:]
            switch e.type {
            case "node":
                guard let lat = e.lat, let lon = e.lon else { continue }
                nodes[e.id] = OSMNode(id: e.id, coordinate: GeoCoordinate(latitude: lat, longitude: lon), tags: tags)
            case "way":
                ways[e.id] = OSMWay(id: e.id, nodeIDs: e.nodes ?? [], tags: tags)
            case "relation":
                let members = (e.members ?? []).compactMap { m -> OSMRelation.Member? in
                    guard let kind = OSMRef.Kind(rawValue: m.type), kind != .overture else { return nil }
                    return OSMRelation.Member(kind: kind, ref: m.ref, role: m.role)
                }
                relations[e.id] = OSMRelation(id: e.id, members: members, tags: tags)
            default:
                continue
            }
        }
    }

    /// Adds another document's elements. An element present in both keeps the version that has
    /// tags (Overpass "skeleton" output omits them).
    public mutating func merge(_ other: OSMDocument) {
        nodes.merge(other.nodes) { a, b in a.tags.isEmpty ? b : a }
        ways.merge(other.ways) { a, b in a.tags.isEmpty ? b : a }
        relations.merge(other.relations) { a, b in a.tags.isEmpty ? b : a }
        if timestamp == nil { timestamp = other.timestamp }
    }

    /// Coordinates of a way's nodes, or nil if any node is missing.
    public func coordinates(of way: OSMWay) -> [GeoCoordinate]? {
        var out: [GeoCoordinate] = []
        out.reserveCapacity(way.nodeIDs.count)
        for id in way.nodeIDs {
            guard let n = nodes[id] else { return nil }
            out.append(n.coordinate)
        }
        return out
    }
}

// MARK: - Overpass JSON shape

private struct OverpassResponse: Decodable {
    struct OSM3S: Decodable { var timestamp_osm_base: String? }
    struct Element: Decodable {
        struct Member: Decodable {
            var type: String
            var ref: Int64
            var role: String
        }
        var type: String
        var id: Int64
        var lat: Double?
        var lon: Double?
        var nodes: [Int64]?
        var members: [Member]?
        var tags: [String: String]?
    }
    var osm3s: OSM3S?
    var elements: [Element]
}
