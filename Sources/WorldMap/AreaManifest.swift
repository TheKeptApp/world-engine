import Foundation
import WorldGeo

/// Describes one area's data on disk: `manifest.json` next to one or more source files.
///
/// Designed to grow into on-demand loading: today an area has one raw Overpass file; later it
/// can list many tiles (each with its own bounds) from a server. Loaders merge all sources and
/// de-duplicate elements by OSM ID, so tile borders need no special handling.
public struct AreaManifest: Codable, Sendable, Equatable {
    public struct Source: Codable, Sendable, Equatable {
        /// Payload format. Today only "osm-overpass-json". Later: e.g. "osm-tile-v1".
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

    /// Reads and merges every source whose layers intersect `layers` (nil = all).
    public static func loadDocument(_ directory: URL, manifest: AreaManifest, layers: Set<String>? = nil) throws -> OSMDocument {
        var doc = OSMDocument()
        for s in manifest.sources {
            if let layers, Set(s.layers).isDisjoint(with: layers), !s.layers.contains("all") { continue }
            guard s.format == "osm-overpass-json" else { throw LoadError.unsupportedFormat(s.format) }
            let data = try Data(contentsOf: directory.appendingPathComponent(s.path))
            doc.merge(try OSMDocument(overpassJSON: data))
        }
        return doc
    }

    /// Manifest → features, using the manifest's own frame and bounds.
    public static func loadFeatures(_ directory: URL, heightRules: HeightRules = .init(), roadRules: RoadRules = .init()) throws -> MapFeatures {
        let manifest = try loadManifest(directory)
        let doc = try loadDocument(directory, manifest: manifest, layers: ["all"])
        var builder = MapFeatureBuilder(frame: manifest.frame, bounds: manifest.localBounds)
        builder.heightRules = heightRules
        builder.roadRules = roadRules
        return builder.build(doc)
    }

    public enum LoadError: Error {
        case unsupportedFormat(String)
    }
}
