import Foundation
import simd

/// A point in a local frame, in meters: `x` = east, `y` = north.
public typealias LocalPoint = SIMD2<Double>

/// A local tangent plane (east/north/up) anchored at `origin`, using exact WGS84 math.
///
/// The world is flat in M1: `localPoint(of:)` drops the up component (curvature drop is
/// about 8 cm at 1 km), and `coordinate(at:)` returns the point on the ellipsoid surface.
///
/// Scene axes (RealityKit, right-handed, Y up): east = +X, north = −Z, up = +Y.
public struct LocalFrame: Hashable, Codable, Sendable {
    public let origin: GeoCoordinate

    // WGS84 ellipsoid.
    static let a = 6_378_137.0
    static let f = 1.0 / 298.257223563
    static let e2 = f * (2 - f)

    public init(origin: GeoCoordinate) {
        self.origin = origin
    }

    // MARK: Geodetic → local

    /// East/north/up in meters for a coordinate at ellipsoid height `height`.
    public func enu(of c: GeoCoordinate, height: Double = 0) -> SIMD3<Double> {
        let p = Self.ecef(c, height: height)
        let p0 = Self.ecef(origin, height: 0)
        let d = p - p0
        let (sinLat, cosLat, sinLon, cosLon) = originTrig
        let e = -sinLon * d.x + cosLon * d.y
        let n = -sinLat * cosLon * d.x - sinLat * sinLon * d.y + cosLat * d.z
        let u = cosLat * cosLon * d.x + cosLat * sinLon * d.y + sinLat * d.z
        return SIMD3(e, n, u)
    }

    /// East/north in meters (flat-world projection).
    public func localPoint(of c: GeoCoordinate) -> LocalPoint {
        let v = enu(of: c)
        return LocalPoint(v.x, v.y)
    }

    // MARK: Local → geodetic

    /// The coordinate on the ellipsoid surface whose east/north matches `p`.
    public func coordinate(at p: LocalPoint) -> GeoCoordinate {
        // Start with the spherical estimate of the curvature drop, then correct so height = 0.
        let r2 = p.x * p.x + p.y * p.y
        var up = -r2 / (2 * Self.a)
        var result = origin
        for _ in 0..<3 {
            let (c, h) = geodetic(enu: SIMD3(p.x, p.y, up))
            result = c
            up -= h
        }
        return result
    }

    /// Geodetic coordinate and ellipsoid height for a full east/north/up vector.
    public func geodetic(enu v: SIMD3<Double>) -> (GeoCoordinate, height: Double) {
        let (sinLat, cosLat, sinLon, cosLon) = originTrig
        let dx = -sinLon * v.x - sinLat * cosLon * v.y + cosLat * cosLon * v.z
        let dy = cosLon * v.x - sinLat * sinLon * v.y + cosLat * sinLon * v.z
        let dz = cosLat * v.y + sinLat * v.z
        return Self.geodetic(ecef: Self.ecef(origin, height: 0) + SIMD3(dx, dy, dz))
    }

    // MARK: Scene axes

    /// Converts a local point to a RealityKit position (east = +X, north = −Z) at height `y`.
    public static func scenePosition(_ p: LocalPoint, y: Double = 0) -> SIMD3<Float> {
        SIMD3(Float(p.x), Float(y), Float(-p.y))
    }

    public func scenePosition(of c: GeoCoordinate, y: Double = 0) -> SIMD3<Float> {
        Self.scenePosition(localPoint(of: c), y: y)
    }

    // MARK: Internals

    private var originTrig: (Double, Double, Double, Double) {
        let lat = origin.latitude * .pi / 180
        let lon = origin.longitude * .pi / 180
        return (sin(lat), cos(lat), sin(lon), cos(lon))
    }

    static func ecef(_ c: GeoCoordinate, height h: Double) -> SIMD3<Double> {
        let lat = c.latitude * .pi / 180
        let lon = c.longitude * .pi / 180
        let n = a / (1 - e2 * sin(lat) * sin(lat)).squareRoot()
        return SIMD3(
            (n + h) * cos(lat) * cos(lon),
            (n + h) * cos(lat) * sin(lon),
            (n * (1 - e2) + h) * sin(lat)
        )
    }

    static func geodetic(ecef p: SIMD3<Double>) -> (GeoCoordinate, height: Double) {
        let lon = atan2(p.y, p.x)
        let rho = (p.x * p.x + p.y * p.y).squareRoot()
        var lat = atan2(p.z, rho * (1 - e2))
        var h = 0.0
        for _ in 0..<6 {
            let n = a / (1 - e2 * sin(lat) * sin(lat)).squareRoot()
            h = rho / cos(lat) - n
            lat = atan2(p.z, rho * (1 - e2 * n / (n + h)))
        }
        return (GeoCoordinate(latitude: lat * 180 / .pi, longitude: lon * 180 / .pi), h)
    }
}
