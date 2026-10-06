import Foundation
import WorldGeo

/// The Moon for one instant and observer (sky-seasons spec §3).
public struct MoonState: Codable, Sendable, Equatable {
    /// Geometric (airless) topocentric altitude, degrees.
    public var altitudeDeg: Double
    /// True-north clockwise azimuth, degrees.
    public var azimuthDeg: Double
    /// Topocentric distance, km.
    public var distanceKm: Double
    public var geocentricDistanceKm: Double
    /// Physical angular diameter, degrees (2·asin(1737.4 km / topocentric distance)).
    public var angularDiameterDeg: Double
    /// Topocentric phase angle (0 full … 180 new), degrees.
    public var phaseAngleDeg: Double
    /// Illuminated fraction k = (1 + cos i)/2.
    public var illuminatedFraction: Double
    /// Geocentric ecliptic longitude of the Moon minus the Sun, 0…360 (waxing < 180).
    public var phaseLongitudeDeg: Double
    public var phaseLabel: String
    /// Position angle of the bright limb from celestial north toward east, (−180, 180]; nil near
    /// new/full where it is ill-conditioned.
    public var brightLimbAngleEquatorialDeg: Double?
    /// The same angle measured from the local zenith direction (χ − parallactic angle).
    public var brightLimbAngleFromZenithDeg: Double?
    /// Unit direction in scene axes (east +X, up +Y, north −Z).
    public var direction: SIMD3<Double>
    /// Unit vector from the Moon toward the Sun, scene axes (disk lighting).
    public var sunDirectionFromMoon: SIMD3<Double>
    public var aboveGeometricHorizon: Bool
}

public struct MoonEvent: Codable, Sendable, Equatable {
    public var utc: Date
    public var kind: Kind
    public enum Kind: String, Codable, Sendable { case moonrise, moonset }
}

public struct MoonDay: Codable, Sendable, Equatable {
    public var events: [MoonEvent]
    public var status: String
    /// Whether the Moon is above the standard rise/set horizon at the civil day's start.
    public var aboveStandardRiseSetHorizonAtDayStart: Bool
}

/// Low-precision lunar ephemeris: Meeus, *Astronomical Algorithms* (2nd ed.) ch. 47 (truncated
/// ELP-2000/82, about 10″ in longitude), with nutation (ch. 22, short series), the observer's
/// WGS84 position for parallax, and ΔT from Espenak & Meeus. Geometric (no refraction).
public enum Moon {
    public static let model = "meeus47-topocentric-v1"
    public static let radiusKm = 1737.4
    static let rad = Double.pi / 180

    // MARK: Public

    public static func state(at date: Date, observer: SkyObserver) -> MoonState {
        let g = geometry(at: date, observer: observer)
        // Phase from topocentric geometry.
        let l = normalize(g.sun - g.moon)            // Moon → Sun
        let v = normalize(g.observer - g.moon)       // Moon → observer
        let i = acos(max(-1, min(1, dot(l, v)))) / rad
        let k = (1 + cos(i * rad)) / 2
        let phaseLongitude = EnvMath.wrap360(g.moonLongitude - g.sunLongitude)
        // Bright limb (topocentric RA/Dec of the Moon; geocentric Sun).
        let topo = g.moon - g.observer
        let (am, dm) = raDec(topo), (asun, dsun) = raDec(g.sun)
        var chi: Double? = atan2(cos(dsun) * sin(asun - am), sin(dsun) * cos(dm) - cos(dsun) * sin(dm) * cos(asun - am)) / rad
        let hm = g.localSiderealRad - am
        let lat = observer.latitude * rad
        let q = atan2(sin(hm), tan(lat) * cos(dm) - sin(dm) * cos(hm)) / rad
        var chiZ: Double? = chi.map { EnvMath.wrap180($0 - q) }
        if i < 1 || i > 179 { chi = nil; chiZ = nil }
        chi = chi.map(EnvMath.wrap180)
        let (alt, az) = horizontal(topo, lst: g.localSiderealRad, latitude: lat)
        let dist = length(topo)
        let dir = sceneDirection(altitude: alt, azimuth: az)
        // Sun direction from the Moon, in scene axes.
        let sunFromMoon = sceneVector(equatorial: l, lst: g.localSiderealRad, latitude: lat)
        return MoonState(altitudeDeg: alt, azimuthDeg: az, distanceKm: dist, geocentricDistanceKm: length(g.moon),
                         angularDiameterDeg: 2 * asin(radiusKm / dist) / rad, phaseAngleDeg: i, illuminatedFraction: k,
                         phaseLongitudeDeg: phaseLongitude, phaseLabel: label(k: k, phaseLongitude: phaseLongitude),
                         brightLimbAngleEquatorialDeg: chi, brightLimbAngleFromZenithDeg: chiZ, direction: dir,
                         sunDirectionFromMoon: sunFromMoon, aboveGeometricHorizon: alt > 0)
    }

    /// Rise/set of the civil day containing `instant`: h + 34′ + asin(1737.4/d) = 0 (topocentric,
    /// geometric altitude; the 34′ is the conventional refraction; no second parallax term).
    public static func day(containing instant: Date, observer: SkyObserver) -> MoonDay? {
        guard let tz = observer.timeZone else { return nil }
        let (start, end) = SunEvents.civilDay(containing: instant, timeZone: tz)
        let f: (Date) -> Double = { t in
            let s = state(at: t, observer: observer)
            return s.altitudeDeg + 34.0 / 60 + asin(radiusKm / s.distanceKm) / rad
        }
        let x = Roots.crossings(of: f, from: start, to: end, step: 600)
        let events = x.map { MoonEvent(utc: $0.time, kind: $0.rising ? .moonrise : .moonset) }
        let status: String
        switch (events.contains { $0.kind == .moonrise }, events.contains { $0.kind == .moonset }) {
        case (true, true): status = "normal"
        case (false, false): status = "no_crossing_this_civil_day"
        default: status = "missing_one_crossing_this_civil_day"
        }
        return MoonDay(events: events, status: status, aboveStandardRiseSetHorizonAtDayStart: f(start) > 0)
    }

    /// Approximate label from k and the waxing/waning phase longitude (not phase-event times).
    public static func label(k: Double, phaseLongitude: Double) -> String {
        if k >= 0.98 { return "near_full" }
        if k <= 0.02 { return "near_new" }
        let waxing = phaseLongitude < 180
        return (waxing ? "waxing_" : "waning_") + (k > 0.5 ? "gibbous" : "crescent")
    }

    // MARK: Geometry

    struct Geometry {
        var moon: SIMD3<Double>      // geocentric equatorial of date, km
        var sun: SIMD3<Double>       // geocentric equatorial of date, km
        var observer: SIMD3<Double>  // geocentric equatorial of date, km
        var localSiderealRad: Double
        var moonLongitude: Double    // apparent ecliptic longitude, degrees
        var sunLongitude: Double
    }

    static func geometry(at date: Date, observer obs: SkyObserver) -> Geometry {
        let jdUT = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let jdTT = jdUT + deltaT(jdUT) / 86_400
        let t = (jdTT - 2_451_545) / 36_525
        let (lon, lat, distance) = lunarEcliptic(t)
        let (dpsi, deps) = nutation(t)
        let eps0 = 23.439291111 - 0.013004167 * t - 1.6389e-7 * t * t + 5.0361e-7 * t * t * t
        let eps = (eps0 + deps) * rad
        let lambda = (lon + dpsi) * rad, beta = lat * rad
        let moon = SIMD3(distance * cos(beta) * cos(lambda),
                         distance * (cos(beta) * sin(lambda) * cos(eps) - sin(beta) * sin(eps)),
                         distance * (cos(beta) * sin(lambda) * sin(eps) + sin(beta) * cos(eps)))
        // Sun: the engine's solar terms (apparent longitude, distance), latitude ≈ 0.
        let terms = SolarPosition.terms(at: date)
        let ls = terms.apparentLongitude * rad
        let rs = terms.distanceAU * 149_597_870.7
        let sun = SIMD3(rs * cos(ls), rs * sin(ls) * cos(eps), rs * sin(ls) * sin(eps))
        // Sidereal time (GMST + equation of the equinoxes) and the observer.
        let tu = (jdUT - 2_451_545) / 36_525
        var gmst = 280.46061837 + 360.98564736629 * (jdUT - 2_451_545) + 0.000387933 * tu * tu - tu * tu * tu / 38_710_000
        gmst = EnvMath.wrap360(gmst)
        let gast = gmst + dpsi * cos(eps)
        let lst = (gast + obs.longitude) * rad
        let a = 6378.137, f = 1 / 298.257223563
        let phi = obs.latitude * rad, h = obs.elevationM / 1000
        let c = 1 / (cos(phi) * cos(phi) + (1 - f) * (1 - f) * sin(phi) * sin(phi)).squareRoot()
        let s = (1 - f) * (1 - f) * c
        let rxy = (a * c + h) * cos(phi), rz = (a * s + h) * sin(phi)
        let observer = SIMD3(rxy * cos(lst), rxy * sin(lst), rz)
        return Geometry(moon: moon, sun: sun, observer: observer, localSiderealRad: lst,
                        moonLongitude: EnvMath.wrap360(lon + dpsi), sunLongitude: EnvMath.wrap360(terms.apparentLongitude))
    }

    /// ΔT = TT − UT, seconds (Espenak & Meeus polynomials, 1986–2150 segments).
    static func deltaT(_ jdUT: Double) -> Double {
        let y = 2000 + (jdUT - 2_451_544.5) / 365.25
        switch y {
        case ..<2005:
            let u = y - 2000
            return 63.86 + 0.3345 * u - 0.060374 * u * u + 0.0017275 * pow(u, 3) + 0.000651814 * pow(u, 4) + 0.00002373599 * pow(u, 5)
        case ..<2050:
            let u = y - 2000
            return 62.92 + 0.32217 * u + 0.005589 * u * u
        case ..<2150:
            return -20 + 32 * pow((y - 1820) / 100, 2) - 0.5628 * (2150 - y)
        default:
            return -20 + 32 * pow((y - 1820) / 100, 2)
        }
    }

    /// Nutation in longitude and obliquity, degrees (Meeus ch. 22, short series, ≈0.5″).
    static func nutation(_ t: Double) -> (Double, Double) {
        let omega = (125.04452 - 1934.136261 * t) * rad
        let l = (280.4665 + 36_000.7698 * t) * rad
        let lp = (218.3165 + 481_267.8813 * t) * rad
        let dpsi = (-17.20 * sin(omega) - 1.32 * sin(2 * l) - 0.23 * sin(2 * lp) + 0.21 * sin(2 * omega)) / 3600
        let deps = (9.20 * cos(omega) + 0.57 * cos(2 * l) + 0.10 * cos(2 * lp) - 0.09 * cos(2 * omega)) / 3600
        return (dpsi, deps)
    }

    /// Geocentric ecliptic longitude/latitude (degrees, mean equinox of date) and distance (km).
    static func lunarEcliptic(_ t: Double) -> (Double, Double, Double) {
        let t2 = t * t, t3 = t2 * t, t4 = t3 * t
        let lp = 218.3164477 + 481_267.88123421 * t - 0.0015786 * t2 + t3 / 538_841 - t4 / 65_194_000
        let d = 297.8501921 + 445_267.1114034 * t - 0.0018819 * t2 + t3 / 545_868 - t4 / 113_065_000
        let m = 357.5291092 + 35_999.0502909 * t - 0.0001536 * t2 + t3 / 24_490_000
        let mp = 134.9633964 + 477_198.8675055 * t + 0.0087414 * t2 + t3 / 69_699 - t4 / 14_712_000
        let f = 93.2720950 + 483_202.0175233 * t - 0.0036539 * t2 - t3 / 3_526_000 + t4 / 863_310_000
        let a1 = 119.75 + 131.849 * t, a2 = 53.09 + 479_264.290 * t, a3 = 313.45 + 481_266.484 * t
        let e = 1 - 0.002516 * t - 0.0000074 * t2

        var sl = 0.0, sr = 0.0, sb = 0.0
        for term in lrTerms {
            let arg = (Double(term.0) * d + Double(term.1) * m + Double(term.2) * mp + Double(term.3) * f) * rad
            let ef = abs(term.1) == 1 ? e : (abs(term.1) == 2 ? e * e : 1)
            sl += Double(term.4) * ef * sin(arg)
            sr += Double(term.5) * ef * cos(arg)
        }
        for term in bTerms {
            let arg = (Double(term.0) * d + Double(term.1) * m + Double(term.2) * mp + Double(term.3) * f) * rad
            let ef = abs(term.1) == 1 ? e : (abs(term.1) == 2 ? e * e : 1)
            sb += Double(term.4) * ef * sin(arg)
        }
        sl += 3958 * sin(a1 * rad) + 1962 * sin((lp - f) * rad) + 318 * sin(a2 * rad)
        sb += -2235 * sin(lp * rad) + 382 * sin(a3 * rad) + 175 * sin((a1 - f) * rad) + 175 * sin((a1 + f) * rad)
            + 127 * sin((lp - mp) * rad) - 115 * sin((lp + mp) * rad)
        return (EnvMath.wrap360(lp + sl / 1_000_000), sb / 1_000_000, 385_000.56 + sr / 1000)
    }

    // Table 47.A: D, M, M′, F, Σl (1e-6°), Σr (1e-3 km).
    static let lrTerms: [(Int, Int, Int, Int, Int, Int)] = [
        (0, 0, 1, 0, 6288774, -20905355), (2, 0, -1, 0, 1274027, -3699111), (2, 0, 0, 0, 658314, -2955968),
        (0, 0, 2, 0, 213618, -569925), (0, 1, 0, 0, -185116, 48888), (0, 0, 0, 2, -114332, -3149),
        (2, 0, -2, 0, 58793, 246158), (2, -1, -1, 0, 57066, -152138), (2, 0, 1, 0, 53322, -170733),
        (2, -1, 0, 0, 45758, -204586), (0, 1, -1, 0, -40923, -129620), (1, 0, 0, 0, -34720, 108743),
        (0, 1, 1, 0, -30383, 104755), (2, 0, 0, -2, 15327, 10321), (0, 0, 1, 2, -12528, 0),
        (0, 0, 1, -2, 10980, 79661), (4, 0, -1, 0, 10675, -34782), (0, 0, 3, 0, 10034, -23210),
        (4, 0, -2, 0, 8548, -21636), (2, 1, -1, 0, -7888, 24208), (2, 1, 0, 0, -6766, 30824),
        (1, 0, -1, 0, -5163, -8379), (1, 1, 0, 0, 4987, -16675), (2, -1, 1, 0, 4036, -12831),
        (2, 0, 2, 0, 3994, -10445), (4, 0, 0, 0, 3861, -11650), (2, 0, -3, 0, 3665, 14403),
        (0, 1, -2, 0, -2689, -7003), (2, 0, -1, 2, -2602, 0), (2, -1, -2, 0, 2390, 10056),
        (1, 0, 1, 0, -2348, 6322), (2, -2, 0, 0, 2236, -9884), (0, 1, 2, 0, -2120, 5751),
        (0, 2, 0, 0, -2069, 0), (2, -2, -1, 0, 2048, -4950), (2, 0, 1, -2, -1773, 4130),
        (2, 0, 0, 2, -1595, 0), (4, -1, -1, 0, 1215, -3958), (0, 0, 2, 2, -1110, 0),
        (3, 0, -1, 0, -892, 3258), (2, 1, 1, 0, -810, 2616), (4, -1, -2, 0, 759, -1897),
        (0, 2, -1, 0, -713, -2117), (2, 2, -1, 0, -700, 2354), (2, 1, -2, 0, 691, 0),
        (2, -1, 0, -2, 596, 0), (4, 0, 1, 0, 549, -1423), (0, 0, 4, 0, 537, -1117),
        (4, -1, 0, 0, 520, -1571), (1, 0, -2, 0, -487, -1739), (2, 1, 0, -2, -399, 0),
        (0, 0, 2, -2, -381, -4421), (1, 1, 1, 0, 351, 0), (3, 0, -2, 0, -340, 0),
        (4, 0, -3, 0, 330, 0), (2, -1, 2, 0, 327, 0), (0, 2, 1, 0, -323, 1165),
        (1, 1, -1, 0, 299, 0), (2, 0, 3, 0, 294, 0), (2, 0, -1, -2, 0, 8752),
    ]

    // Table 47.B: D, M, M′, F, Σb (1e-6°).
    static let bTerms: [(Int, Int, Int, Int, Int)] = [
        (0, 0, 0, 1, 5128122), (0, 0, 1, 1, 280602), (0, 0, 1, -1, 277693), (2, 0, 0, -1, 173237),
        (2, 0, -1, 1, 55413), (2, 0, -1, -1, 46271), (2, 0, 0, 1, 32573), (0, 0, 2, 1, 17198),
        (2, 0, 1, -1, 9266), (0, 0, 2, -1, 8822), (2, -1, 0, -1, 8216), (2, 0, -2, -1, 4324),
        (2, 0, 1, 1, 4200), (2, 1, 0, -1, -3359), (2, -1, -1, 1, 2463), (2, -1, 0, 1, 2211),
        (2, -1, -1, -1, 2065), (0, 1, -1, -1, -1870), (4, 0, -1, -1, 1828), (0, 1, 0, 1, -1794),
        (0, 0, 0, 3, -1749), (0, 1, -1, 1, -1565), (1, 0, 0, 1, -1491), (0, 1, 1, 1, -1475),
        (0, 1, 1, -1, -1410), (0, 1, 0, -1, -1344), (1, 0, 0, -1, -1335), (0, 0, 3, 1, 1107),
        (4, 0, 0, -1, 1021), (4, 0, -1, 1, 833), (0, 0, 1, -3, 777), (4, 0, -2, 1, 671),
        (2, 0, 0, -3, 607), (2, 0, 2, -1, 596), (2, -1, 1, -1, 491), (2, 0, -2, 1, -451),
        (0, 0, 3, -1, 439), (2, 0, 2, 1, 422), (2, 0, -3, -1, 421), (2, 1, -1, 1, -366),
        (2, 1, 0, 1, -351), (4, 0, 0, 1, 331), (2, -1, 1, 1, 315), (2, -2, 0, -1, 302),
        (0, 0, 1, 3, -283), (2, 1, 1, -1, -229), (1, 1, 0, -1, 223), (1, 1, 0, 1, 223),
        (0, 1, -2, -1, -220), (2, 1, -1, -1, -220), (1, 0, 1, 1, -185), (2, -1, -2, -1, 181),
        (0, 1, 2, 1, -177), (4, -2, -1, -1, 176), (4, -1, -1, -1, 166), (1, 0, 1, -1, -164),
        (4, 0, 1, -1, 132), (1, 0, -1, -1, -119), (4, -1, 0, -1, 115), (2, -2, 0, 1, 107),
    ]

    // MARK: Vector helpers

    static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double { a.x * b.x + a.y * b.y + a.z * b.z }
    static func length(_ a: SIMD3<Double>) -> Double { dot(a, a).squareRoot() }
    static func normalize(_ a: SIMD3<Double>) -> SIMD3<Double> { a / length(a) }

    static func raDec(_ v: SIMD3<Double>) -> (Double, Double) {
        (atan2(v.y, v.x), asin(max(-1, min(1, v.z / length(v)))))
    }

    /// Altitude/azimuth (degrees) of an equatorial-of-date vector for a local sidereal angle.
    static func horizontal(_ v: SIMD3<Double>, lst: Double, latitude: Double) -> (Double, Double) {
        let (ra, dec) = raDec(v)
        let h = lst - ra
        let alt = asin(max(-1, min(1, sin(latitude) * sin(dec) + cos(latitude) * cos(dec) * cos(h)))) / rad
        let az = EnvMath.wrap360(atan2(sin(h), cos(h) * sin(latitude) - tan(dec) * cos(latitude)) / rad + 180)
        return (alt, az)
    }

    /// (cos e sin A, sin e, −cos e cos A): the same convention as the Sun's scene vector.
    static func sceneDirection(altitude: Double, azimuth: Double) -> SIMD3<Double> {
        let e = altitude * rad, a = azimuth * rad
        return SIMD3(cos(e) * sin(a), sin(e), -cos(e) * cos(a))
    }

    /// Rotates an equatorial-of-date direction into scene axes for the observer.
    static func sceneVector(equatorial v: SIMD3<Double>, lst: Double, latitude: Double) -> SIMD3<Double> {
        let (alt, az) = horizontal(v, lst: lst, latitude: latitude)
        return sceneDirection(altitude: alt, azimuth: az)
    }
}
