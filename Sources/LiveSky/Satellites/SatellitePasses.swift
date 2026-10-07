//  Observer geometry, sunlight, passes and visibility for SGP4 satellites.
//  Port of `Tools/livefeeds/livefeeds/sats/passes.py` (same constants, same operation order).
//
//  Frames: SGP4 gives TEME; TEME is turned to Earth-fixed by GMST (IAU 1982, UT1 = UTC; polar motion ignored).
//  The observer sits on the WGS84 ellipsoid. A satellite is sunlit unless it is inside the Earth's cylindrical
//  shadow. A pass is visible where the satellite is sunlit, at least 10 degrees up, and the Sun is at least
//  6 degrees below the observer's horizon.

import Foundation

enum PassConstants {
    static let d2r: Double = Double.pi / 180
    static let reKm: Double = 6378.137
    static let fWGS84: Double = 1 / 298.257223563
    static let minPassAlt: Double = 10.0
    static let visibleMinAlt: Double = 10.0
    static let sunMaxAltForVisible: Double = -6.0
    static let stepS: Double = 20.0
    static let visStepS: Double = 5.0
    static let trackStepS: Double = 10.0
}

enum SatGeometry {
    typealias C = PassConstants

    /// Vallado's gstime (IAU 1982), the angle SGP4's TEME is defined against.
    static func gmstRad(_ posix: Double) -> Double {
        let jd = posix / 86400.0 + 2440587.5
        let tut1 = (jd - 2451545.0) / 36525.0
        let a: Double = -6.2e-6 * pow(tut1, 3) + 0.093104 * pow(tut1, 2)
        let k: Double = 876600.0 * 3600 + 8640184.812866
        let temp = a + k * tut1 + 67310.54841
        return PyMath.mod(fmod(temp * C.d2r / 240.0, 2 * Double.pi), 2 * Double.pi)
    }

    static func temeToEcef(_ r: SatVec3, _ posix: Double) -> SatVec3 {
        let g = gmstRad(posix)
        let c = cos(g)
        let s = sin(g)
        return SatVec3(c * r.x + s * r.y, -s * r.x + c * r.y, r.z)
    }

    static func observerEcef(_ lat: Double, _ lon: Double, _ elevM: Double) -> SatVec3 {
        let phi = lat * C.d2r
        let lam = lon * C.d2r
        let e2 = C.fWGS84 * (2 - C.fWGS84)
        let n = C.reKm / (1 - e2 * pow(sin(phi), 2)).squareRoot()
        let h = elevM / 1000.0
        return SatVec3((n + h) * cos(phi) * cos(lam), (n + h) * cos(phi) * sin(lam),
                       (n * (1 - e2) + h) * sin(phi))
    }

    /// (lat, lon, height km) on WGS84.
    static func geodetic(_ r: SatVec3) -> (lat: Double, lon: Double, heightKm: Double) {
        let x = r.x
        let y = r.y
        let z = r.z
        let e2 = C.fWGS84 * (2 - C.fWGS84)
        let lon = atan2(y, x)
        let p = hypot(x, y)
        var lat = atan2(z, p * (1 - e2))
        for _ in 0..<6 {
            let n = C.reKm / (1 - e2 * pow(sin(lat), 2)).squareRoot()
            let h = p / cos(lat) - n
            lat = atan2(z, p * (1 - e2 * n / (n + h)))
        }
        let n = C.reKm / (1 - e2 * pow(sin(lat), 2)).squareRoot()
        return (lat: lat / C.d2r, lon: lon / C.d2r, heightKm: p / cos(lat) - n)
    }

    /// (altitude deg, azimuth deg from north through east, range km) of an Earth-fixed offset vector.
    static func lookAngles(_ rho: SatVec3, _ lat: Double, _ lon: Double) -> (alt: Double, az: Double, range: Double) {
        let phi = lat * C.d2r
        let lam = lon * C.d2r
        let sp = sin(phi)
        let cp = cos(phi)
        let sl = sin(lam)
        let cl = cos(lam)
        let s = sp * cl * rho.x + sp * sl * rho.y - cp * rho.z
        let e = -sl * rho.x + cl * rho.y
        let z = cp * cl * rho.x + cp * sl * rho.y + sp * rho.z
        let rng = (s * s + e * e + z * z).squareRoot()
        let alt = asin(max(-1.0, min(1.0, z / rng))) / C.d2r
        let az = PyMath.mod(atan2(e, -s) / C.d2r, 360.0)
        return (alt: alt, az: az, range: rng)
    }

    /// Low-precision apparent Sun direction (Meeus 25, about 0.01 deg), true equator of date.
    static func sunEciUnit(_ posix: Double) -> SatVec3 {
        let jd = posix / 86400.0 + 2440587.5 + 69.184 / 86400.0
        let t = (jd - 2451545.0) / 36525.0
        let l0 = 280.46646 + 36000.76983 * t
        let m = (357.52911 + 35999.05029 * t) * C.d2r
        let c1: Double = (1.914602 - 0.004817 * t) * sin(m)
        let c = c1 + 0.019993 * sin(2 * m) + 0.000289 * sin(3 * m)
        let om = (125.04 - 1934.136 * t) * C.d2r
        let lam = (l0 + c - 0.00569 - 0.00478 * sin(om)) * C.d2r
        let eps = (23.439291 - 0.0130042 * t + 0.00256 * cos(om)) * C.d2r
        return SatVec3(cos(lam), cos(eps) * sin(lam), sin(eps) * sin(lam))
    }

    static func sunlit(_ r: SatVec3, _ sunU: SatVec3) -> Bool {
        let d = r.x * sunU.x + r.y * sunU.y + r.z * sunU.z
        if d >= 0 {
            return true
        }
        let px = r.x - d * sunU.x
        let py = r.y - d * sunU.y
        let pz = r.z - d * sunU.z
        return (pow(px, 2) + pow(py, 2) + pow(pz, 2)).squareRoot() > C.reKm
    }
}

public enum SatelliteMagnitude {
    /// Diffuse-sphere estimate from a standard magnitude (at 1000 km, phase angle 90 deg).
    public static func estimate(stdMag: Double?, rangeKm: Double, phaseRad: Double) -> Double? {
        guard let stdMag = stdMag else {
            return nil
        }
        let f = (Double.pi - phaseRad) * cos(phaseRad) + sin(phaseRad)
        if f <= 1e-6 {
            return nil
        }
        return stdMag + 5 * log10(rangeKm / 1000.0) - 2.5 * log10(f)
    }
}

/// One look at a satellite from an observer.
public struct SatelliteObservation: Sendable, Equatable {
    public var t: Double
    public var altDeg: Double
    public var azDeg: Double
    public var rangeKm: Double
    public var sunlit: Bool
    public var sunAltDeg: Double
    public var phaseRad: Double
    /// Sub-satellite point and height on WGS84.
    public var latDeg: Double
    public var lonDeg: Double
    public var heightKm: Double
}

/// A rounded pass point (t 0.1 s, angles 0.001 deg, range 0.1 km, magnitude 0.01), as the reference emits it.
public struct PassPoint: Sendable, Equatable {
    public var t: Double
    public var altDeg: Double
    public var azDeg: Double
    public var rangeKm: Double
    public var sunlit: Bool
    public var magnitude: Double?
}

public struct VisibleWindow: Sendable, Equatable {
    public var start: PassPoint
    public var end: PassPoint
    public var maxAltDeg: Double
    public var brightestMagnitude: Double?
    public var endsInShadow: Bool
    public var track: [PassPoint]
}

public struct SatellitePass: Sendable, Equatable {
    public var rise: PassPoint
    public var culmination: PassPoint
    public var set: PassPoint
    public var startsBeforeWindow: Bool
    public var endsAfterWindow: Bool
    public var visible: Bool
    public var basis: String
    public var visibleWindow: VisibleWindow?
}

/// An observer on the WGS84 ellipsoid.
public struct PassObserver: Sendable, Equatable {
    public let latDeg: Double
    public let lonDeg: Double
    public let elevM: Double
    let ecef: SatVec3

    public init(latDeg: Double, lonDeg: Double, elevM: Double = 0.0) {
        self.latDeg = latDeg
        self.lonDeg = lonDeg
        self.elevM = elevM
        self.ecef = SatGeometry.observerEcef(latDeg, lonDeg, elevM)
    }

    public func observe(_ sat: SGP4Propagator, at t: Double) throws -> SatelliteObservation {
        let r = try sat.propagate(posix: t).r
        let re = SatGeometry.temeToEcef(r, t)
        let rho = SatVec3(re.x - ecef.x, re.y - ecef.y, re.z - ecef.z)
        let look = SatGeometry.lookAngles(rho, latDeg, lonDeg)
        let rng = look.range
        let su = SatGeometry.sunEciUnit(t)
        let suE = SatGeometry.temeToEcef(su, t)
        let sunAlt = SatGeometry.lookAngles(suE, latDeg, lonDeg).alt
        // Phase angle Sun-satellite-observer (Sun at infinity).
        let toObs = SatVec3(-rho.x / rng, -rho.y / rng, -rho.z / rng)
        let cosph = suE.x * toObs.x + suE.y * toObs.y + suE.z * toObs.z
        let geo = SatGeometry.geodetic(re)
        return SatelliteObservation(
            t: t, altDeg: look.alt, azDeg: look.az, rangeKm: rng, sunlit: SatGeometry.sunlit(r, su),
            sunAltDeg: sunAlt, phaseRad: acos(max(-1.0, min(1.0, cosph))),
            latDeg: geo.lat, lonDeg: geo.lon, heightKm: geo.heightKm)
    }

    func altitude(_ sat: SGP4Propagator, _ t: Double) throws -> Double {
        let r = try sat.propagate(posix: t).r
        let re = SatGeometry.temeToEcef(r, t)
        return SatGeometry.lookAngles(SatVec3(re.x - ecef.x, re.y - ecef.y, re.z - ecef.z), latDeg, lonDeg).alt
    }

    static func bisect(_ f: (Double) throws -> Double, _ a0: Double, _ b0: Double, rising: Bool,
                       tol: Double = 0.5) rethrows -> Double {
        var a = a0
        var b = b0
        while b - a > tol {
            let m = (a + b) / 2
            if (try f(m) > 0) == rising {
                b = m
            } else {
                a = m
            }
        }
        return (a + b) / 2
    }

    static func maximize(_ f: (Double) throws -> Double, _ a0: Double, _ b0: Double,
                         tol: Double = 0.5) rethrows -> Double {
        var a = a0
        var b = b0
        let g = (5.0.squareRoot() - 1) / 2
        var c = b - g * (b - a)
        var d = a + g * (b - a)
        var fc = try f(c)
        var fd = try f(d)
        while b - a > tol {
            if fc > fd {
                let oldC = c
                let oldFc = fc
                b = d
                d = oldC
                fd = oldFc
                c = b - g * (b - a)
                fc = try f(c)
            } else {
                let oldD = d
                let oldFd = fd
                a = c
                c = oldD
                fc = oldFd
                d = a + g * (b - a)
                fd = try f(d)
            }
        }
        return (a + b) / 2
    }

    static func point(_ o: SatelliteObservation, _ stdMag: Double?) -> PassPoint {
        var mag: Double? = nil
        if o.sunlit {
            if let m = SatelliteMagnitude.estimate(stdMag: stdMag, rangeKm: o.rangeKm, phaseRad: o.phaseRad) {
                mag = PyMath.round(m, 2)
            }
        }
        return PassPoint(t: PyMath.round(o.t, 1), altDeg: PyMath.round(o.altDeg, 3),
                         azDeg: PyMath.round(o.azDeg, 3), rangeKm: PyMath.round(o.rangeKm, 1),
                         sunlit: o.sunlit, magnitude: mag)
    }

    /// Passes above the horizon in [start, end] whose maximum altitude reaches 10 degrees.
    public func findPasses(_ sat: SGP4Propagator, start: Double, end: Double,
                           stdMag: Double? = nil) throws -> [SatellitePass] {
        typealias C = PassConstants
        let f: (Double) throws -> Double = { x in try self.altitude(sat, x) }

        var raw: [(rise: Double, setT: Double, cutStart: Bool, cutEnd: Bool)] = []
        var t = start
        var prev = try f(t)
        var rise: Double? = prev > 0 ? start : nil
        while t < end {
            let t2 = min(t + C.stepS, end)
            let cur = try f(t2)
            if prev <= 0 && 0 < cur {
                rise = try PassObserver.bisect(f, t, t2, rising: true)
            } else if prev > 0 && 0 >= cur, let r = rise {
                let s = try PassObserver.bisect(f, t, t2, rising: false)
                raw.append((rise: r, setT: s, cutStart: r == start, cutEnd: false))
                rise = nil
            }
            prev = cur
            t = t2
        }
        if let r = rise {
            raw.append((rise: r, setT: end, cutStart: r == start, cutEnd: true))
        }

        var out: [SatellitePass] = []
        for p in raw {
            let riseT = p.rise
            let setT = p.setT
            let tc = try PassObserver.maximize(f, riseT, setT)
            let top = try observe(sat, at: tc)
            if top.altDeg < C.minPassAlt {
                continue
            }
            var samples: [SatelliteObservation] = []
            let n = max(2, Int(ceil((setT - riseT) / C.visStepS)) + 1)
            for i in 0..<n {
                let ti = riseT + (setT - riseT) * Double(i) / Double(n - 1)
                samples.append(try observe(sat, at: ti))
            }
            var visIdx: [Int] = []
            for (i, o) in samples.enumerated() {
                if o.sunlit && o.altDeg >= C.visibleMinAlt && o.sunAltDeg <= C.sunMaxAltForVisible {
                    visIdx.append(i)
                }
            }
            var rec = SatellitePass(
                rise: PassObserver.point(try observe(sat, at: riseT), stdMag),
                culmination: PassObserver.point(top, stdMag),
                set: PassObserver.point(try observe(sat, at: setT), stdMag),
                startsBeforeWindow: p.cutStart, endsAfterWindow: p.cutEnd,
                visible: !visIdx.isEmpty, basis: "forecast", visibleWindow: nil)
            if let firstIdx = visIdx.first, let lastIdx = visIdx.last {
                let vis = visIdx.map { samples[$0] }
                let v0 = samples[firstIdx].t
                let v1 = samples[lastIdx].t
                let count = Int(PyMath.floorDiv(v1 - v0, C.trackStepS)) + 1
                var track: [SatelliteObservation] = []
                for k in 0..<max(0, count) {
                    track.append(try observe(sat, at: v0 + Double(k) * C.trackStepS))
                }
                if let lastTrack = track.last, lastTrack.t < v1 {
                    track.append(try observe(sat, at: v1))
                }
                var brightest: Double? = nil
                for o in vis {
                    if let m = SatelliteMagnitude.estimate(stdMag: stdMag, rangeKm: o.rangeKm, phaseRad: o.phaseRad) {
                        if let b = brightest {
                            if m < b {
                                brightest = m
                            }
                        } else {
                            brightest = m
                        }
                    }
                }
                var maxAlt = vis[0].altDeg
                for o in vis where o.altDeg > maxAlt {
                    maxAlt = o.altDeg
                }
                let after = samples[min(samples.count - 1, lastIdx + 1)]
                var brightestRounded: Double? = nil
                if let b = brightest {
                    brightestRounded = PyMath.round(b, 2)
                }
                rec.visibleWindow = VisibleWindow(
                    start: PassObserver.point(samples[firstIdx], stdMag),
                    end: PassObserver.point(samples[lastIdx], stdMag),
                    maxAltDeg: PyMath.round(maxAlt, 3),
                    brightestMagnitude: brightestRounded,
                    endsInShadow: !after.sunlit,
                    track: track.map { PassObserver.point($0, stdMag) })
            }
            out.append(rec)
        }
        return out
    }
}
