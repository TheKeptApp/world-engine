import Foundation
import WorldGeo

/// Describes one area's data on disk: `manifest.json` next to one or more source files.
///
/// Designed to grow into on-demand loading: today an area has one raw Overpass file; later it
/// can list many tiles (each with its own bounds) from a server. Loaders merge all sources and
/// de-duplicate elements by OSM ID, so tile borders need no special handling.
public struct AreaManifest: Codable, Sendable, Equatable {
    public struct Source: Codable, Sendable, Equatable {
        /// Payload format: "osm-overpass-json", or "overture-buildings-v1" (a second building
        /// footprint source, merged after OSM; see `OvertureBuildings`). Later: e.g. "osm-tile-v1".
        public var format: String
        /// File path relative to the manifest.
        public var path: String
        /// What the source contains: ["all"] for every mapped feature, or e.g. ["buildings"].
        public var layers: [String]
        public var bounds: GeoBoundingBox
        /// The OSM data timestamp reported by the server.
        public var dataTimestamp: String?
        public var fetchedAt: String?
        public var bytes: Int?
        public var sha256: String?
        public var license: String
        public var attribution: String

        public init(format: String, path: String, layers: [String], bounds: GeoBoundingBox,
                    dataTimestamp: String?, fetchedAt: String?, bytes: Int?, sha256: String?,
                    license: String, attribution: String) {
            self.format = format
            self.path = path
            self.layers = layers
            self.bounds = bounds
            self.dataTimestamp = dataTimestamp
            self.fetchedAt = fetchedAt
            self.bytes = bytes
            self.sha256 = sha256
            self.license = license
            self.attribution = attribution
        }
    }

    public var formatVersion = 1
    public var id: String
    public var name: String
    /// Origin of the local frame: (0, 0) in world meters.
    public var center: GeoCoordinate
    /// Optional IANA civil timezone, supplied by the area data owner. Never inferred from longitude.
    public var timezone: String? = nil
    public var widthMeters: Double
    public var heightMeters: Double
    public var sources: [Source] = []

    public init(id: String, name: String, center: GeoCoordinate, widthMeters: Double, heightMeters: Double) {
        self.id = id
        self.name = name
        self.center = center
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
    }

    public var bounds: GeoBoundingBox {
        GeoBoundingBox(center: center, widthMeters: widthMeters, heightMeters: heightMeters)
    }

    public var frame: LocalFrame { LocalFrame(origin: center) }
    public var localBounds: Rect2D { Rect2D(centerWidth: widthMeters, height: heightMeters) }

    public static let fileName = "manifest.json"
}

/// Loads an area directory (manifest + sources) into raw OSM elements.
public enum AreaLoader {
    public static func loadManifest(_ directory: URL) throws -> AreaManifest {
        let data = try Data(contentsOf: directory.appendingPathComponent(AreaManifest.fileName))
        return try JSONDecoder().decode(AreaManifest.self, from: data)
    }

    /// Reads and merges every OSM source whose layers intersect `layers` (nil = all). Overture
    /// sources are not OSM elements; `loadFeatures` merges them after building.
    public static func loadDocument(_ directory: URL, manifest: AreaManifest, layers: Set<String>? = nil) throws -> OSMDocument {
        var doc = OSMDocument()
        for s in manifest.sources {
            if let layers, Set(s.layers).isDisjoint(with: layers), !s.layers.contains("all") { continue }
            if s.format == OvertureBuildings.format { continue }
            guard s.format == "osm-overpass-json" else { throw LoadError.unsupportedFormat(s.format) }
            let data = try Data(contentsOf: directory.appendingPathComponent(s.path))
            doc.merge(try OSMDocument(overpassJSON: data))
        }
        return doc
    }

    /// Manifest → features, using the manifest's own frame and bounds. Overture building
    /// sources, if any, then fill footprints OSM lacks.
    public static func loadFeatures(_ directory: URL, heightRules: HeightRules = .init(), roadRules: RoadRules = .init()) throws -> MapFeatures {
        let manifest = try loadManifest(directory)
        let doc = try loadDocument(directory, manifest: manifest, layers: ["all"])
        var builder = MapFeatureBuilder(frame: manifest.frame, bounds: manifest.localBounds)
        builder.heightRules = heightRules
        builder.roadRules = roadRules
        var features = builder.build(doc)
        try OvertureBuildings.merge(directory: directory, manifest: manifest, osm: doc, heightRules: heightRules, into: &features)
        return features
    }

    /// The context ring's OSM extract alone (sources whose layers are `AreaManifest.contextLayer`),
    /// or nil when the area has none. `loadDocument(_:manifest:layers:)` would merge the detailed
    /// sources too (sources tagged "all" always load).
    public static func loadContextDocument(_ directory: URL, manifest: AreaManifest) throws -> OSMDocument? {
        let sources = manifest.contextSources
        guard !sources.isEmpty else { return nil }
        var only = manifest
        only.sources = sources
        return try loadDocument(directory, manifest: only, layers: [AreaManifest.contextLayer])
    }

    public enum LoadError: Error {
        case unsupportedFormat(String)
    }
}

extension AreaManifest {
    /// Layer of the low-detail context ring around an area (docs/data/context-rings.md): real
    /// ground beyond the area box, drawn outside it only and never part of the detailed world.
    public static let contextLayer = "context"

    /// OSM sources of the context ring (their layers name `contextLayer` and not "all").
    public var contextSources: [Source] {
        sources.filter { $0.layers.contains(Self.contextLayer) && !$0.layers.contains("all") && $0.format == "osm-overpass-json" }
    }

    /// The box the context sources cover (their bounds together), or nil without any.
    public var contextBounds: GeoBoundingBox? {
        let b = contextSources.map(\.bounds)
        guard let first = b.first else { return nil }
        return b.dropFirst().reduce(first) { a, x in
            GeoBoundingBox(south: min(a.south, x.south), west: min(a.west, x.west), north: max(a.north, x.north), east: max(a.east, x.east))
        }
    }
}
