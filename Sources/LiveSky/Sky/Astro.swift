import Foundation

/// Time scales, reference frames and horizon coordinates (Meeus, Astronomical Algorithms, 2nd ed.).
///
/// Swift port of the Python reference in `Tools/livefeeds/livefeeds/sky/` (astro.py, bodies.py,
/// moontables.py, stars.py, skyglow.py). The reference stays the oracle: `Tests/LiveSkyTests/SkyVectorTests.swift`
/// checks this port against `Tests/LiveSkyTests/Fixtures/live-sky-vectors.json`, exported by
/// `Tools/livefeeds/livefeeds/vectors.py`.
///
/// Conventions: instants are POSIX seconds (UTC), UT1 = UTC; TT = UTC + leap seconds + 32.184 s from 1972
/// on, Espenak-Meeus Delta T before; angles in the public API are degrees.
public enum Astro {
    public static let rad = Double.pi / 180.0
    public static let arcsec = rad / 3600.0
    public static let auKm = 149_597_870.7
    public static let cAuPerDay = 173.1446326846693
    public static let j2000 = 2_451_545.0
    public static let obliquityJ2000 = 23.4392911 * rad

    /// (POSIX second the offset starts, TAI-UTC). IERS Bulletin C; no leap second since 2017-01-01.
    public static let leapSeconds: [(start: Double, value: Int)] = [
        (63072000, 10), (78796800, 11), (94694400, 12), (126230400, 13), (157766400, 14), (189302400, 15),
        (220924800, 16), (252460800, 17), (283996800, 18), (315532800, 19), (362793600, 20), (394329600, 21),
        (425865600, 22), (489024000, 23), (567993600, 24), (631152000, 25), (662688000, 26), (709948800, 27),
        (741484800, 28), (773020800, 29), (820454400, 30), (867715200, 31), (915148800, 32), (1136073600, 33),
        (1230768000, 34), (1341100800, 35), (1435708800, 36), (1483228800, 37),
    ]

    // MARK: angles

    /// Python's `x % 360.0` (result has the sign of the divisor).
    public static func pyMod(_ x: Double, _ m: Double) -> Double {
        var r = fmod(x, m)
        if r != 0 {
            if (r < 0) != (m < 0) {
                r += m
            }
        } else {
            r = m < 0 ? -0.0 : 0.0
        }
        return r
    }

    public static func wrap360(_ x: Double) -> Double {
        pyMod(x, 360.0)
    }

    public static func wrap180(_ x: Double) -> Double {
        pyMod(x + 180.0, 360.0) - 180.0
    }

    /// Python `math.degrees`.
    public static func degrees(_ x: Double) -> Double {
        x * (180.0 / Double.pi)
    }

    /// Python `math.radians`.
    public static func radians(_ x: Double) -> Double {
        x * (Double.pi / 180.0)
    }

    public static func rotX(_ t: Double) -> Mat3 {
        let c = cos(t), s = sin(t)
        return Mat3(Vec3(1, 0, 0), Vec3(0, c, s), Vec3(0, -s, c))
    }

    public static func rotY(_ t: Double) -> Mat3 {
        let c = cos(t), s = sin(t)
        return Mat3(Vec3(c, 0, -s), Vec3(0, 1, 0), Vec3(s, 0, c))
    }

    public static func rotZ(_ t: Double) -> Mat3 {
        let c = cos(t), s = sin(t)
        return Mat3(Vec3(c, s, 0), Vec3(-s, c, 0), Vec3(0, 0, 1))
    }

    // MARK: time

    public static func jdUtc(_ posix: Double) -> Double {
        posix / 86400.0 + 2_440_587.5
    }

    public static func taiMinusUtc(_ posix: Double) -> Int {
        var off = 0
        for entry in leapSeconds where posix >= entry.start {
            off = entry.value
        }
        return off
    }

    /// TT - UT in seconds.
    public static func deltaT(_ posix: Double) -> Double {
        if posix >= leapSeconds[0].start {
            return Double(taiMinusUtc(posix)) + 32.184
        }
        let t = 1970.0 + posix / (365.25 * 86400.0) - 1975.0
        return 45.45 + 1.067 * t - t * t / 260.0 - t * t * t / 718.0
    }

    public static func jdTt(_ posix: Double) -> Double {
        jdUtc(posix) + deltaT(posix) / 86400.0
    }

    public static func centuriesTt(_ posix: Double) -> Double {
        (jdTt(posix) - j2000) / 36525.0
    }

    /// Greenwich mean sidereal time, degrees (Meeus 12.4, UT1 = UTC).
    public static func gmstDeg(_ posix: Double) -> Double {
        let jd = jdUtc(posix)
        let t = (jd - j2000) / 36525.0
        return wrap360(280.46061837 + 360.98564736629 * (jd - j2000) + 0.000387933 * t * t - t * t * t / 38_710_000.0)
    }

    /// Greenwich apparent sidereal time, degrees (GMST + equation of the equinoxes).
    public static func gastDeg(_ posix: Double) -> Double {
        let t = centuriesTt(posix)
        let n = nutation(t)
        return wrap360(gmstDeg(posix) + n.dpsi / 3600.0 * cos(trueObliquity(t)))
    }

    /// Local apparent sidereal time, degrees (east longitude positive).
    public static func lstDeg(_ posix: Double, lonDeg: Double) -> Double {
        wrap360(gastDeg(posix) + lonDeg)
    }

    // MARK: precession and nutation

    /// IAU 1980 nutation, the 13 largest terms (Meeus table 22.A):
    /// D, M, M', F, Omega, psi (1e-4"), psi T, eps, eps T.
    static let nutationTerms: [Double] = [
        0, 0, 0, 0, 1, -171996, -174.2, 92025, 8.9,
        -2, 0, 0, 2, 2, -13187, -1.6, 5736, -3.1,
        0, 0, 0, 2, 2, -2274, -0.2, 977, -0.5,
        0, 0, 0, 0, 2, 2062, 0.2, -895, 0.5,
        0, 1, 0, 0, 0, 1426, -3.4, 54, -0.1,
        0, 0, 1, 0, 0, 712, 0.1, -7, 0,
        -2, 1, 0, 2, 2, -517, 1.2, 224, -0.6,
        0, 0, 0, 2, 1, -386, -0.4, 200, 0,
        0, 0, 1, 2, 2, -301, 0, 129, -0.1,
        -2, -1, 0, 2, 2, 217, -0.5, -95, 0.3,
        -2, 0, 1, 0, 0, -158, 0, 0, 0,
        -2, 0, 0, 2, 1, 129, 0.1, -70, 0,
        0, 0, -1, 2, 2, 123, 0, -53, 0,
    ]

    /// (delta psi, delta epsilon) in arcseconds for TT centuries since J2000.
    public static func nutation(_ t: Double) -> (dpsi: Double, deps: Double) {
        let t3 = t * t * t
        let d = (297.85036 + 445267.111480 * t - 0.0019142 * t * t + t3 / 189474.0) * rad
        let m = (357.52772 + 35999.050340 * t - 0.0001603 * t * t - t3 / 300000.0) * rad
        let mp = (134.96298 + 477198.867398 * t + 0.0086972 * t * t + t3 / 56250.0) * rad
        let f = (93.27191 + 483202.017538 * t - 0.0036825 * t * t + t3 / 327270.0) * rad
        let om = (125.04452 - 1934.136261 * t + 0.0020708 * t * t + t3 / 450000.0) * rad
        var dpsi = 0.0
        var deps = 0.0
        let terms = nutationTerms
        var i = 0
        while i < terms.count {
            let arg = terms[i] * d + terms[i + 1] * m + terms[i + 2] * mp + terms[i + 3] * f + terms[i + 4] * om
            dpsi += (terms[i + 5] + terms[i + 6] * t) * sin(arg)
            deps += (terms[i + 7] + terms[i + 8] * t) * cos(arg)
            i += 9
        }
        return (dpsi * 1e-4, deps * 1e-4)
    }

    /// Radians (Meeus 22.2).
    public static func meanObliquity(_ t: Double) -> Double {
        (23.439291111 - (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0) * rad
    }

    public static func trueObliquity(_ t: Double) -> Double {
        meanObliquity(t) + nutation(t).deps * arcsec
    }

    /// J2000 mean equator -> mean equator of date (Meeus 21.2/21.3 rigorous angles).
    public static func precessionMatrix(_ t: Double) -> Mat3 {
        let t3 = t * t * t
        let zeta = (2306.2181 * t + 0.30188 * t * t + 0.017998 * t3) * arcsec
        let z = (2306.2181 * t + 1.09468 * t * t + 0.018203 * t3) * arcsec
        let theta = (2004.3109 * t - 0.42665 * t * t - 0.041833 * t3) * arcsec
        return rotZ(-z) * (rotY(theta) * rotZ(-zeta))
    }

    /// Mean equator of date -> true equator of date.
    public static func nutationMatrix(_ t: Double) -> Mat3 {
        let n = nutation(t)
        let eps0 = meanObliquity(t)
        let eps = eps0 + n.deps * arcsec
        return rotX(-eps) * (rotZ(-n.dpsi * arcsec) * rotX(eps0))
    }

    public static func j2000ToDateMatrix(_ t: Double) -> Mat3 {
        nutationMatrix(t) * precessionMatrix(t)
    }

    public static func eclipticJ2000ToEquatorialJ2000(_ v: Vec3) -> Vec3 {
        rotX(-obliquityJ2000) * v
    }

    // MARK: spherical and horizon coordinates

    /// Degrees: right ascension in [0, 360), declination.
    public static func raDec(_ v: Vec3) -> (ra: Double, dec: Double) {
        let r = v.norm
        return (wrap360(atan2(v.y, v.x) / rad), asin(max(-1.0, min(1.0, v.z / r))) / rad)
    }

    public static func fromRaDec(_ raDeg: Double, _ decDeg: Double, r: Double = 1.0) -> Vec3 {
        let a = raDeg * rad, d = decDeg * rad
        return Vec3(r * cos(d) * cos(a), r * cos(d) * sin(a), r * sin(d))
    }

    /// Observer in the true equator-of-date frame, km (WGS84 ellipsoid); `lst` in degrees.
    public static func observerVectorKm(latDeg: Double, lonDeg: Double, elevM: Double, lst: Double) -> Vec3 {
        let a = 6378.137, f = 1 / 298.257223563
        let phi = latDeg * rad
        let cphi = cos(phi), sphi = sin(phi)
        let c = 1 / (cphi * cphi + (1 - f) * (1 - f) * (sphi * sphi)).squareRoot()
        let s = (1 - f) * (1 - f) * c
        let h = elevM / 1000.0
        let rxy = (a * c + h) * cos(phi)
        let th = lst * rad
        return Vec3(rxy * cos(th), rxy * sin(th), (a * s + h) * sin(phi))
    }

    /// Geometric altitude and azimuth (degrees, azimuth from north through east) of a topocentric
    /// true-equator-of-date vector.
    public static func altAz(_ vDate: Vec3, latDeg: Double, lst: Double) -> (alt: Double, az: Double) {
        let rd = raDec(vDate)
        let h = (lst - rd.ra) * rad
        let d = rd.dec * rad, phi = latDeg * rad
        let alt = asin(max(-1.0, min(1.0, sin(phi) * sin(d) + cos(phi) * cos(d) * cos(h))))
        let az = atan2(-cos(d) * sin(h), sin(d) * cos(phi) - cos(d) * cos(h) * sin(phi))
        return (alt / rad, wrap360(az / rad))
    }

    /// Atmospheric refraction to add to a geometric altitude (Saemundsson, Meeus 16.4), degrees.
    /// Returns 0 well below the horizon, where the formula is meaningless.
    public static func refractionDeg(_ altGeometric: Double, pressureHpa: Double = 1010.0, tempC: Double = 10.0) -> Double {
        if altGeometric < -1.9 {
            return 0.0
        }
        let h = max(altGeometric, -1.9)
        let r = 1.02 / tan((h + 10.3 / (h + 5.11)) * rad)
        return max(r, 0.0) * (pressureHpa / 1010.0) * (283.0 / (273.0 + tempC)) / 60.0
    }

    /// Kasten & Young (1989) relative air mass; large but finite at the horizon, infinite below -1 deg.
    public static func airmass(_ altApparent: Double) -> Double {
        if altApparent <= -1.0 {
            return Double.infinity
        }
        let z = 90.0 - max(altApparent, 0.0)
        return 1.0 / (cos(z * rad) + 0.50572 * pow(96.07995 - z, -1.6364))
    }

    public static func angularSeparationDeg(_ a: Vec3, _ b: Vec3) -> Double {
        let c = a.unit.dot(b.unit)
        return acos(max(-1.0, min(1.0, c))) / rad
    }
}
