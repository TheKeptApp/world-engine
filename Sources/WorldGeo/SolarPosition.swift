import Foundation

/// Sun position from date and location (NOAA solar calculator equations, without refraction).
/// Accurate to well under 0.5° for 1950–2050, plenty for lighting.
public struct SolarPosition: Sendable, Equatable {
    /// Degrees clockwise from true north (90 = east, 270 = west).
    public var azimuth: Double
    /// Degrees above the horizon (negative = below).
    public var elevation: Double

    public init(azimuth: Double, elevation: Double) {
        self.azimuth = azimuth
        self.elevation = elevation
    }

    public init(date: Date, at c: GeoCoordinate) {
        let rad = Double.pi / 180
        let jd = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let t = (jd - 2_451_545) / 36_525

        let l0 = (280.46646 + t * (36_000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + t * (35_999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let center = sin(m * rad) * (1.914602 - t * (0.004817 + 0.000014 * t))
            + sin(2 * m * rad) * (0.019993 - 0.000101 * t)
            + sin(3 * m * rad) * 0.000289
        let omega = 125.04 - 1934.136 * t
        let lambda = l0 + center - 0.00569 - 0.00478 * sin(omega * rad)
        let eps0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let eps = eps0 + 0.00256 * cos(omega * rad)
        let decl = asin(sin(eps * rad) * sin(lambda * rad))

        let y = pow(tan(eps * rad / 2), 2)
        let eqTime = 4 / rad * (y * sin(2 * l0 * rad) - 2 * e * sin(m * rad)
            + 4 * e * y * sin(m * rad) * cos(2 * l0 * rad)
            - 0.5 * y * y * sin(4 * l0 * rad) - 1.25 * e * e * sin(2 * m * rad))

        let secondsUTC = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 86_400)
        let trueSolarMinutes = (secondsUTC / 60 + eqTime + 4 * c.longitude)
            .truncatingRemainder(dividingBy: 1440)
        var hourAngle = trueSolarMinutes / 4 - 180
        if hourAngle < -180 { hourAngle += 360 }

        let lat = c.latitude * rad
        let ha = hourAngle * rad
        let cosZenith = min(1, max(-1, sin(lat) * sin(decl) + cos(lat) * cos(decl) * cos(ha)))
        elevation = 90 - acos(cosZenith) / rad
        let az = atan2(sin(ha), cos(ha) * sin(lat) - tan(decl) * cos(lat)) / rad + 180
        azimuth = (az.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Unit vector toward the sun in scene axes (east = +X, up = +Y, north = −Z).
    public var sceneDirection: SIMD3<Float> {
        let a = azimuth * .pi / 180, e = elevation * .pi / 180
        return SIMD3(Float(sin(a) * cos(e)), Float(sin(e)), Float(-cos(a) * cos(e)))
    }
}
