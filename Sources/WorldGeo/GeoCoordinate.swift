import Foundation

/// A WGS84 latitude/longitude in degrees. The only geographic type host apps use.
public struct GeoCoordinate: Hashable, Codable, Sendable, CustomStringConvertible {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public var description: String {
        String(format: "(%.6f, %.6f)", latitude, longitude)
    }
}

/// A latitude/longitude box. Uses south/west/north/east, the order Overpass expects.
public struct GeoBoundingBox: Hashable, Codable, Sendable {
    public var south: Double
    public var west: Double
    public var north: Double
    public var east: Double

    public init(south: Double, west: Double, north: Double, east: Double) {
        self.south = south
        self.west = west
        self.north = north
        self.east = east
    }

    /// The box covering `widthMeters` (east–west) × `heightMeters` (north–south) around `center`,
    /// measured exactly in the local frame at `center`.
    public init(center: GeoCoordinate, widthMeters: Double, heightMeters: Double) {
        let frame = LocalFrame(origin: center)
        let sw = frame.coordinate(at: LocalPoint(-widthMeters / 2, -heightMeters / 2))
        let ne = frame.coordinate(at: LocalPoint(widthMeters / 2, heightMeters / 2))
        self.init(south: sw.latitude, west: sw.longitude, north: ne.latitude, east: ne.longitude)
    }

    public var center: GeoCoordinate {
        GeoCoordinate(latitude: (south + north) / 2, longitude: (west + east) / 2)
    }

    public func contains(_ c: GeoCoordinate) -> Bool {
        c.latitude >= south && c.latitude <= north && c.longitude >= west && c.longitude <= east
    }

    /// "south,west,north,east" as used in Overpass QL.
    public var overpassString: String {
        String(format: "%.7f,%.7f,%.7f,%.7f", south, west, north, east)
    }
}
