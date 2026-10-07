import Foundation

// Sun, Moon and planets: apparent topocentric positions, distance, phase and magnitude.
//
// Planets and the Earth-Moon barycentre: E. M. Standish, "Keplerian Elements for Approximate Positions of
// the Major Planets" (JPL Solar System Dynamics, table 1, valid 1800-2050 AD), a fit to JPL DE405. Moon:
// Meeus chapter 47 (ELP-2000/82 truncated). Pipeline per body (Meeus chapters 23, 33, 40): light time,
// annual aberration (first order), precession and nutation to the true equator of date, topocentric
// parallax by vector subtraction, then horizon coordinates and refraction.

public enum SkyError: Error, Sendable, Equatable {
    /// The instant is outside 1800-2050, where the planetary elements are valid.
    case outOfRange
}

public struct SkyObserver: Sendable, Equatable {
    public var lat: Double
    public var lon: Double
    public var elevM: Double
    public var pressureHpa: Double
    public var tempC: Double

    public init(lat: Double, lon: Double, elevM: Double = 0.0, pressureHpa: Double = 1010.0, tempC: Double = 10.0) {
        self.lat = lat
        self.lon = lon
        self.elevM = elevM
        self.pressureHpa = pressureHpa
        self.tempC = tempC
    }
}

/// Everything that depends only on the instant and the observer.
public struct SkyFrame: Sendable, Equatable {
    public var posix: Double
    /// TT centuries since J2000.
    public var t: Double
    /// Local apparent sidereal time, degrees.
    public var lst: Double
    /// J2000 equator -> true equator of date.
    public var toDate: Mat3
    /// Heliocentric Earth, au, ecliptic J2000.
    public var earth: Vec3
    /// Earth velocity, au/day, equatorial J2000.
    public var vEarth: Vec3
    /// Observer, km, true equator of date.
    public var observerKm: Vec3

    public init(posix: Double, t: Double, lst: Double, toDate: Mat3, earth: Vec3, vEarth: Vec3, observerKm: Vec3) {
        self.posix = posix
        self.t = t
        self.lst = lst
        self.toDate = toDate
        self.earth = earth
        self.vEarth = vEarth
        self.observerKm = observerKm
    }

    public static func make(posix: Double, observer obs: SkyObserver) -> SkyFrame {
        let t = Astro.centuriesTt(posix)
        let lst = Astro.lstDeg(posix, lonDeg: obs.lon)
        return SkyFrame(posix: posix, t: t, lst: lst, toDate: Astro.j2000ToDateMatrix(t),
                        earth: SolarSystem.earthHeliocentric(t),
                        vEarth: Astro.eclipticJ2000ToEquatorialJ2000(SolarSystem.earthVelocity(t)),
                        observerKm: Astro.observerVectorKm(latDeg: obs.lat, lonDeg: obs.lon, elevM: obs.elevM, lst: lst))
    }
}

/// Horizon and equatorial coordinates of a body, degrees.
public struct HorizonPosition: Sendable, Equatable {
    public var altDeg: Double
    public var apparentAltDeg: Double
    public var azDeg: Double
    public var raDeg: Double
    public var decDeg: Double

    public init(altDeg: Double, apparentAltDeg: Double, azDeg: Double, raDeg: Double, decDeg: Double) {
        self.altDeg = altDeg
        self.apparentAltDeg = apparentAltDeg
        self.azDeg = azDeg
        self.raDeg = raDeg
        self.decDeg = decDeg
    }
}

public struct SunState: Sendable, Equatable {
    public var altDeg: Double
    public var apparentAltDeg: Double
    public var azDeg: Double
    public var raDeg: Double
    public var decDeg: Double
    public var distanceAu: Double
    public var angularDiameterDeg: Double
    public var magnitude: Double
}

public struct MoonState: Sendable, Equatable {
    public var altDeg: Double
    public var apparentAltDeg: Double
    public var azDeg: Double
    public var raDeg: Double
    public var decDeg: Double
    public var distanceKm: Double
    public var angularDiameterDeg: Double
    public var phaseAngleDeg: Double
    public var illuminatedFraction: Double
    public var elongationLongitudeDeg: Double
    /// One of new, waxingCrescent, firstQuarter, waxingGibbous, full, waningGibbous, lastQuarter, waningCrescent.
    public var phaseName: String
    public var ageDays: Double
    public var brightLimbPositionAngleDeg: Double
    public var brightLimbFromZenithDeg: Double
    public var magnitude: Double

    public var distanceAu: Double { distanceKm / Astro.auKm }
}

public struct PlanetState: Sendable, Equatable {
    public var altDeg: Double
    public var apparentAltDeg: Double
    public var azDeg: Double
    public var raDeg: Double
    public var decDeg: Double
    public var distanceAu: Double
    public var heliocentricDistanceAu: Double
    public var phaseAngleDeg: Double
    public var illuminatedFraction: Double
    public var magnitude: Double
    /// Saturn only.
    public var ringTiltDeg: Double?
}

public struct SolarSystemState: Sendable, Equatable {
    public var sun: SunState
    public var moon: MoonState
    /// Keyed by `SolarSystem.planets` names.
    public var planets: [String: PlanetState]
}

public enum SolarSystem {
    public static let validFrom: Double = -5364662400  // 1800-01-01
    public static let validUntil: Double = 2556143999  // 2050-12-31 23:59:59

    /// a (au), e, I, L, long. perihelion, long. node (deg), each followed by its rate per Julian century.
    static let standish: [String: [Double]] = [
        "mercury": [0.38709927, 0.00000037, 0.20563593, 0.00001906, 7.00497902, -0.00594749,
                    252.25032350, 149472.67411175, 77.45779628, 0.16047689, 48.33076593, -0.12534081],
        "venus": [0.72333566, 0.00000390, 0.00677672, -0.00004107, 3.39467605, -0.00078890,
                  181.97909950, 58517.81538729, 131.60246718, 0.00268329, 76.67984255, -0.27769418],
        "emb": [1.00000261, 0.00000562, 0.01671123, -0.00004392, -0.00001531, -0.01294668,
                100.46457166, 35999.37244981, 102.93768193, 0.32327364, 0.0, 0.0],
        "mars": [1.52371034, 0.00001847, 0.09339410, 0.00007882, 1.84969142, -0.00813131,
                 -4.55343205, 19140.30268499, -23.94362959, 0.44441088, 49.55953891, -0.29257343],
        "jupiter": [5.20288700, -0.00011607, 0.04838624, -0.00013253, 1.30439695, -0.00183714,
                    34.39644051, 3034.74612775, 14.72847983, 0.21252668, 100.47390909, 0.20469106],
        "saturn": [9.53667594, -0.00125060, 0.05386179, -0.00050991, 2.48599187, 0.00193609,
                   49.95424423, 1222.49362201, 92.59887831, -0.41897216, 113.66242448, -0.28867794],
        "uranus": [19.18916464, -0.00196176, 0.04725744, -0.00004397, 0.77263783, -0.00242939,
                   313.23810451, 428.48202785, 170.95427630, 0.40805281, 74.01692503, 0.04240589],
        "neptune": [30.06992276, 0.00026291, 0.00859048, 0.00005105, 1.77004347, 0.00035372,
                    -55.12002969, 218.45945325, 44.96476227, -0.32241464, 131.78422574, -0.00508664],
    ]
    public static let planets: [String] = ["mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune"]
    public static let earthMoonMassRatio = 81.30056
    public static let moonRadiusKm = 1737.4
    public static let sunRadiusKm = 696_000.0
    /// Saturn's north ring-plane pole, J2000 equatorial (IAU WGCCRE 2015: RA 40.589, Dec 83.537 deg).
    public static let saturnPole = Astro.fromRaDec(40.589, 83.537)

    static func check(_ posix: Double) throws {
        if !(validFrom <= posix && posix <= validUntil) {
            throw SkyError.outOfRange
        }
    }

    /// Heliocentric ecliptic-and-equinox-J2000 position (au), t in TT centuries since J2000.
    public static func heliocentricEcliptic(_ body: String, _ t: Double) -> Vec3 {
        guard let el = standish[body] else {
            preconditionFailure("unknown body \(body)")
        }
        let rad = Astro.rad
        let a = el[0] + el[1] * t
        let e = el[2] + el[3] * t
        let i = (el[4] + el[5] * t) * rad
        let l = (el[6] + el[7] * t) * rad
        let w = (el[8] + el[9] * t) * rad
        let o = (el[10] + el[11] * t) * rad
        let argPeri = w - o
        let m = (l - w).remainder(dividingBy: 2 * Double.pi)
        var bigE = m + e * sin(m)
        for _ in 0..<15 {
            let d = (bigE - e * sin(bigE) - m) / (1 - e * cos(bigE))
            bigE -= d
            if abs(d) < 1e-14 {
                break
            }
        }
        let xp = a * (cos(bigE) - e)
        let yp = a * (1 - e * e).squareRoot() * sin(bigE)
        let cw = cos(argPeri), sw = sin(argPeri), co = cos(o), so = sin(o), ci = cos(i), si = sin(i)
        return Vec3((cw * co - sw * so * ci) * xp + (-sw * co - cw * so * ci) * yp,
                    (cw * so + sw * co * ci) * xp + (-sw * so + cw * co * ci) * yp,
                    (sw * si) * xp + (cw * si) * yp)
    }

    private static func eccPower(_ ecc: Double, _ cm: Int) -> Double {
        switch abs(cm) {
        case 0: return 1.0
        case 1: return ecc
        default: return pow(ecc, Double(abs(cm)))
        }
    }

    /// Geometric geocentric ecliptic longitude, latitude (deg, mean equinox of date) and distance (km).
    public static func moonEclipticOfDate(_ t: Double) -> (lon: Double, lat: Double, distKm: Double) {
        let rad = Astro.rad
        let t2 = t * t, t3 = t * t * t, t4 = t * t * t * t
        let lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841.0 - t4 / 65194000.0
        let d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868.0 - t4 / 113065000.0
        let m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000.0
        let mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699.0 - t4 / 14712000.0
        let f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000.0 + t4 / 863310000.0
        let a1 = 119.75 + 131.849 * t, a2 = 53.09 + 479264.290 * t, a3 = 313.45 + 481266.484 * t
        let ecc = 1 - 0.002516 * t - 0.0000074 * t2
        var sl = 0.0, sr = 0.0, sb = 0.0
        let lr = MoonTables.lrTerms
        var i = 0
        while i < lr.count {
            let arg = (Double(lr[i]) * d + Double(lr[i + 1]) * m + Double(lr[i + 2]) * mp + Double(lr[i + 3]) * f) * rad
            let k = eccPower(ecc, lr[i + 1])
            sl += Double(lr[i + 4]) * k * sin(arg)
            sr += Double(lr[i + 5]) * k * cos(arg)
            i += 6
        }
        let bt = MoonTables.bTerms
        i = 0
        while i < bt.count {
            let arg = (Double(bt[i]) * d + Double(bt[i + 1]) * m + Double(bt[i + 2]) * mp + Double(bt[i + 3]) * f) * rad
            sb += Double(bt[i + 4]) * eccPower(ecc, bt[i + 1]) * sin(arg)
            i += 5
        }
        var addL: Double = 3958.0 * sin(a1 * rad)
        addL += 1962.0 * sin((lp - f) * rad)
        addL += 318.0 * sin(a2 * rad)
        sl += addL
        var addB: Double = -2235.0 * sin(lp * rad)
        addB += 382.0 * sin(a3 * rad)
        addB += 175.0 * sin((a1 - f) * rad)
        addB += 175.0 * sin((a1 + f) * rad)
        addB += 127.0 * sin((lp - mp) * rad)
        addB -= 115.0 * sin((lp + mp) * rad)
        sb += addB
        return (Astro.wrap360(lp + sl / 1e6), sb / 1e6, 385000.56 + sr / 1000.0)
    }

    /// Apparent geocentric Moon, true equator and equinox of date, km.
    public static func moonGeocentricDateKm(_ t: Double) -> Vec3 {
        let ecl = moonEclipticOfDate(t)
        let dpsi = Astro.nutation(t).dpsi
        let lam = (ecl.lon + dpsi / 3600.0) * Astro.rad
        let beta = ecl.lat * Astro.rad
        let eps = Astro.trueObliquity(t)
        let dist = ecl.distKm
        let v = Vec3(dist * cos(beta) * cos(lam), dist * cos(beta) * sin(lam), dist * sin(beta))
        return Astro.rotX(-eps) * v
    }

    /// Heliocentric Earth (au, ecliptic J2000): barycentre minus the Moon's share.
    public static func earthHeliocentric(_ t: Double) -> Vec3 {
        let emb = heliocentricEcliptic("emb", t)
        let ecl = moonEclipticOfDate(t)
        let lam = ecl.lon * Astro.rad, beta = ecl.lat * Astro.rad
        let r = ecl.distKm / Astro.auKm / (1 + earthMoonMassRatio)
        return Vec3(emb.x - r * cos(beta) * cos(lam), emb.y - r * cos(beta) * sin(lam), emb.z - r * sin(beta))
    }

    /// Earth heliocentric velocity, au/day (ecliptic J2000), by central difference over +-0.05 day.
    public static func earthVelocity(_ t: Double) -> Vec3 {
        let h = 0.05 / 36525.0
        let a = heliocentricEcliptic("emb", t + h), b = heliocentricEcliptic("emb", t - h)
        return (a - b).scaled(1 / 0.1)
    }

    /// First-order annual aberration of a J2000 unit direction (about 20 arcsec).
    public static func aberrate(_ u: Vec3, _ vEarth: Vec3) -> Vec3 {
        let k = 1 / Astro.cAuPerDay
        return (u + vEarth.scaled(k)).unit
    }

    /// (astrometric geocentric equatorial J2000 au, heliocentric ecliptic J2000 au, light time days).
    static func geocentricBodyJ2000Au(_ body: String, _ fr: SkyFrame) -> (geo: Vec3, helio: Vec3, tau: Double) {
        var tau = 0.0
        var p = Vec3.zero
        var g = Vec3.zero
        for _ in 0..<3 {
            let tb = fr.t - tau / 36525.0
            p = body == "sun" ? Vec3.zero : heliocentricEcliptic(body, tb)
            g = p - fr.earth
            tau = g.norm / Astro.cAuPerDay
        }
        return (Astro.eclipticJ2000ToEquatorialJ2000(g), p, tau)
    }

    /// Topocentric apparent position (km, true equator of date) and, for planets, the heliocentric
    /// position (au, ecliptic J2000) used for phase and magnitude.
    public static func apparentTopocentricKm(_ body: String, _ fr: SkyFrame) -> (position: Vec3, helio: Vec3?) {
        if body == "moon" {
            return (moonGeocentricDateKm(fr.t) - fr.observerKm, nil)
        }
        let gb = geocentricBodyJ2000Au(body, fr)
        let distKm = gb.geo.norm * Astro.auKm
        let u = aberrate(gb.geo.unit, fr.vEarth)
        let geo = (fr.toDate * u).scaled(distKm)
        return (geo - fr.observerKm, body == "sun" ? nil : gb.helio)
    }

    public static func horizon(_ vDate: Vec3, _ fr: SkyFrame, _ obs: SkyObserver) -> HorizonPosition {
        let aa = Astro.altAz(vDate, latDeg: obs.lat, lst: fr.lst)
        let rd = Astro.raDec(vDate)
        return HorizonPosition(altDeg: aa.alt,
                               apparentAltDeg: aa.alt + Astro.refractionDeg(aa.alt, pressureHpa: obs.pressureHpa, tempC: obs.tempC),
                               azDeg: aa.az, raDeg: rd.ra, decDeg: rd.dec)
    }

    /// Visual magnitude, Meeus chapter 41 (G. Muller / Astronomical Almanac 1984 expressions).
    /// Saturn omits the small Sun-Earth ring-longitude term (<= 0.1 mag).
    public static func planetMagnitude(_ body: String, rAu: Double, deltaAu: Double, phaseDeg: Double,
                                       ringTiltDeg: Double = 0.0) -> Double {
        let base = 5 * log10(rAu * deltaAu)
        let i = phaseDeg
        switch body {
        case "mercury":
            return -0.42 + base + 0.0380 * i - 0.000273 * i * i + 0.000002 * (i * i * i)
        case "venus":
            return -4.40 + base + 0.0009 * i + 0.000239 * i * i - 0.00000065 * (i * i * i)
        case "mars":
            return -1.52 + base + 0.016 * i
        case "jupiter":
            return -9.40 + base + 0.005 * i
        case "saturn":
            let sb = sin(abs(ringTiltDeg) * Astro.rad)
            return -8.88 + base - 2.60 * sb + 1.25 * sb * sb
        case "uranus":
            return -7.19 + base
        case "neptune":
            return -6.87 + base
        default:
            preconditionFailure("unknown planet \(body)")
        }
    }

    /// Sun, Moon and seven planets for one instant and place (all angles degrees).
    public static func compute(posix: Double, observer obs: SkyObserver) throws -> SolarSystemState {
        try check(posix)
        let fr = SkyFrame.make(posix: posix, observer: obs)
        let deg = Astro.degrees, rads = Astro.radians

        let sunV = apparentTopocentricKm("sun", fr).position
        let sh = horizon(sunV, fr, obs)
        let sun = SunState(altDeg: sh.altDeg, apparentAltDeg: sh.apparentAltDeg, azDeg: sh.azDeg, raDeg: sh.raDeg,
                           decDeg: sh.decDeg, distanceAu: sunV.norm / Astro.auKm,
                           angularDiameterDeg: 2 * deg(asin(sunRadiusKm / sunV.norm)), magnitude: -26.74)

        let moonV = apparentTopocentricKm("moon", fr).position
        // Phase angle: the angle Sun-Moon-observer.
        let i = Astro.angularSeparationDeg(sunV - moonV, moonV.scaled(-1))
        let k = (1 + cos(i * Astro.rad)) / 2
        let lonM = moonEclipticOfDate(fr.t).lon
        let sunLon = eclipticLongitudeOfDate(sunV, fr.t)
        let elong = Astro.wrap360(lonM - sunLon)
        let sunRD = Astro.raDec(sunV)
        let moonRD = Astro.raDec(moonV)
        let sunRa = sunRD.ra, sunDec = sunRD.dec, mRa = moonRD.ra, mDec = moonRD.dec
        let chi = deg(atan2(
            cos(rads(sunDec)) * sin(rads(sunRa - mRa)),
            sin(rads(sunDec)) * cos(rads(mDec))
                - cos(rads(sunDec)) * sin(rads(mDec)) * cos(rads(sunRa - mRa))))
        let ha = rads(fr.lst - mRa)
        let q = deg(atan2(sin(ha), tan(rads(obs.lat)) * cos(rads(mDec)) - sin(rads(mDec)) * cos(ha)))
        let dist = moonV.norm
        let mh = horizon(moonV, fr, obs)
        let moon = MoonState(altDeg: mh.altDeg, apparentAltDeg: mh.apparentAltDeg, azDeg: mh.azDeg, raDeg: mh.raDeg,
                             decDeg: mh.decDeg, distanceKm: dist,
                             angularDiameterDeg: 2 * deg(asin(moonRadiusKm / dist)),
                             phaseAngleDeg: i, illuminatedFraction: k, elongationLongitudeDeg: elong,
                             phaseName: moonPhaseName(k, elong),
                             ageDays: elong / 360.0 * 29.530589,
                             brightLimbPositionAngleDeg: Astro.wrap360(chi),
                             brightLimbFromZenithDeg: Astro.wrap180(chi - q),
                             magnitude: moonMagnitude(i, dist))

        var planetStates: [String: PlanetState] = [:]
        let earthNorm = fr.earth.norm
        for body in planets {
            let ap = apparentTopocentricKm(body, fr)
            let v = ap.position
            guard let helio = ap.helio else { continue }
            let delta = v.norm / Astro.auKm
            let r = helio.norm
            let phase = deg(acos(max(-1.0, min(1.0, (r * r + delta * delta - earthNorm * earthNorm) / (2 * r * delta)))))
            var tilt = 0.0
            if body == "saturn" {
                let g = geocentricBodyJ2000Au(body, fr).geo
                tilt = deg(asin(g.unit.dot(saturnPole)))
            }
            let ph = horizon(v, fr, obs)
            planetStates[body] = PlanetState(
                altDeg: ph.altDeg, apparentAltDeg: ph.apparentAltDeg, azDeg: ph.azDeg, raDeg: ph.raDeg,
                decDeg: ph.decDeg, distanceAu: delta, heliocentricDistanceAu: r, phaseAngleDeg: phase,
                illuminatedFraction: (1 + cos(phase * Astro.rad)) / 2,
                magnitude: planetMagnitude(body, rAu: r, deltaAu: delta, phaseDeg: phase, ringTiltDeg: tilt),
                ringTiltDeg: body == "saturn" ? -tilt : nil)
        }
        return SolarSystemState(sun: sun, moon: moon, planets: planetStates)
    }

    static func eclipticLongitudeOfDate(_ vDate: Vec3, _ t: Double) -> Double {
        let eps = Astro.trueObliquity(t)
        let e = Astro.rotX(eps) * vDate
        return Astro.wrap360(Astro.degrees(atan2(e.y, e.x)))
    }

    /// Name from the illuminated fraction and the Sun-Moon longitude difference (0 new, 180 full).
    public static func moonPhaseName(_ k: Double, _ elong: Double) -> String {
        if k >= 0.98 {
            return "full"
        }
        if k <= 0.02 {
            return "new"
        }
        if abs(k - 0.5) < 0.03 {
            return elong < 180 ? "firstQuarter" : "lastQuarter"
        }
        return (elong < 180 ? "waxing" : "waning") + (k > 0.5 ? "Gibbous" : "Crescent")
    }

    /// Allen (1976) style approximation: -12.73 at full, plus the phase law 0.026|i| + 4e-9 i^4
    /// (Krisciunas & Schaefer 1991), scaled for distance.
    public static func moonMagnitude(_ phaseDeg: Double, _ distKm: Double) -> Double {
        let i = abs(phaseDeg)
        return -12.73 + 0.026 * i + 4e-9 * (i * i * i * i) + 5 * log10(distKm / 384400.0)
    }
}
