import Foundation

/// Night-sky brightness and naked-eye limiting magnitude.
///
/// Zenith sky light is the linear-flux sum of artificial skyglow (inferred from NASA Black Marble upward
/// radiance around the observer), twilight (coarse table from the Sun's altitude, assumption) and moonlight
/// (Krisciunas & Schaefer 1991, PASP 103, 1033). Natural moonless dark-site zenith brightness: 22.0 V mag/arcsec^2.
/// The radiance-to-skyglow step is an uncalibrated assumption (confidence low).
public enum SkyGlow {
    public static let naturalSkyMag = 22.0
    public static let kernelRadiusKm = 50.0
    public static let kernelCoreKm = 1.0
    /// Ratio of artificial to natural zenith brightness per nW/cm^2/sr of kernel-weighted radiance (assumption).
    public static let calibration = 1.0
    /// Zenith sky brightness against solar altitude (deg, V mag/arcsec^2), coarse shape (assumption).
    public static let twilightTable: [(alt: Double, mag: Double)] = [
        (5.0, 3.5), (0.0, 5.5), (-6.0, 12.5), (-12.0, 18.0), (-18.0, 22.0),
    ]
    /// V-band extinction coefficient used by Krisciunas & Schaefer.
    public static let extinctionK = 0.172

    public static func magToFlux(_ m: Double) -> Double {
        pow(10.0, -0.4 * m)
    }

    public static func fluxToMag(_ f: Double) -> Double {
        -2.5 * log10(f)
    }

    /// Naked-eye limiting magnitude at the zenith from sky brightness (V mag/arcsec^2), as used by the Unihedron
    /// SQM documentation and Clear Sky Chart: NELM = 7.93 - 5 log10(10^(4.316 - B/5) + 1).
    public static func limitingMagnitude(_ skyMag: Double) -> Double {
        7.93 - 5 * log10(pow(10.0, 4.316 - skyMag / 5) + 1)
    }

    // MARK: artificial skyglow

    /// Regular lat/lon grid of upward radiance, nW/cm^2/sr (row 0 is the northernmost row).
    public struct RadianceGrid: Sendable, Equatable {
        public var north: Double
        public var west: Double
        public var dlat: Double
        public var dlon: Double
        public var rows: Int
        public var cols: Int
        public var values: [Double?]

        public init(north: Double, west: Double, dlat: Double, dlon: Double, rows: Int, cols: Int, values: [Double?]) {
            self.north = north
            self.west = west
            self.dlat = dlat
            self.dlon = dlon
            self.rows = rows
            self.cols = cols
            self.values = values
        }

        public func contains(lat: Double, lon: Double) -> Bool {
            north - Double(rows) * dlat <= lat && lat <= north
                && west <= lon && lon <= west + Double(cols) * dlon
        }
    }

    static func kernel(_ dKm: Double) -> Double {
        pow(dKm + kernelCoreKm, -2.5)
    }

    /// Integral of 2 pi r (r + core)^-2.5 dr from 0 to R, closed form.
    static func uniformKernelIntegral() -> Double {
        let c = kernelCoreKm, r = kernelRadiusKm
        func prim(_ x: Double) -> Double {
            -2 * pow(x + c, -0.5) + (2.0 / 3.0) * c * pow(x + c, -1.5)
        }
        return 2 * Double.pi * (prim(r) - prim(0))
    }

    /// Kernel-weighted mean radiance around the point; nil when the point or most of the kernel is outside
    /// the grid (fewer than 70 percent of the kernel weight covered).
    public static func weightedRadiance(_ grid: RadianceGrid, lat: Double, lon: Double) -> Double? {
        if !grid.contains(lat: lat, lon: lon) {
            return nil
        }
        let kx = 111.32 * cos(Astro.radians(lat))
        let ky = 110.57
        let cellArea = (grid.dlat * ky) * (grid.dlon * kx)
        var total = 0.0
        var covered = 0.0
        let r0 = Int(max(0.0, floor((grid.north - lat - kernelRadiusKm / ky) / grid.dlat)))
        let r1 = Int(min(Double(grid.rows), ceil((grid.north - lat + kernelRadiusKm / ky) / grid.dlat)))
        let c0 = Int(max(0.0, floor((lon - grid.west - kernelRadiusKm / kx) / grid.dlon)))
        let c1 = Int(min(Double(grid.cols), ceil((lon - grid.west + kernelRadiusKm / kx) / grid.dlon)))
        if r0 < r1 && c0 < c1 {
            for r in r0..<r1 {
                let clat = grid.north - (Double(r) + 0.5) * grid.dlat
                for c in c0..<c1 {
                    let clon = grid.west + (Double(c) + 0.5) * grid.dlon
                    let d = hypot((clat - lat) * ky, (clon - lon) * kx)
                    if d > kernelRadiusKm {
                        continue
                    }
                    let w = kernel(d) * cellArea
                    covered += w
                    let idx = r * grid.cols + c
                    var value = 0.0
                    if idx < grid.values.count, let v = grid.values[idx], v > 0 {
                        value = v
                    }
                    total += w * value
                }
            }
        }
        let full = uniformKernelIntegral()
        if covered < 0.7 * full {
            return nil
        }
        return total / covered
    }

    public static func artificialRatio(_ weightedRadianceNw: Double) -> Double {
        calibration * max(0.0, weightedRadianceNw)
    }

    // MARK: twilight and moonlight

    /// Extra zenith flux above the natural dark sky, in magToFlux units.
    public static func twilightFlux(_ sunAltDeg: Double) -> Double {
        let t = twilightTable
        var m = t[0].mag
        if sunAltDeg >= t[0].alt {
            m = t[0].mag
        } else if sunAltDeg <= t[t.count - 1].alt {
            return 0.0
        } else {
            for j in 0..<(t.count - 1) {
                let a0 = t[j].alt, m0 = t[j].mag, a1 = t[j + 1].alt, m1 = t[j + 1].mag
                if a1 <= sunAltDeg && sunAltDeg <= a0 {
                    m = m1 + (m0 - m1) * (sunAltDeg - a1) / (a0 - a1)
                    break
                }
            }
        }
        return max(0.0, magToFlux(m) - magToFlux(naturalSkyMag))
    }

    /// Zenith moonlight (Krisciunas & Schaefer 1991, eq. 15-21) in magToFlux units; 0 when the Moon is down.
    public static func moonlightFlux(moonAltDeg: Double, moonPhaseAngleDeg: Double) -> Double {
        if moonAltDeg <= 0 {
            return 0.0
        }
        let alpha = abs(moonPhaseAngleDeg)
        let iStar = pow(10.0, -0.4 * (3.84 + 0.026 * alpha + 4e-9 * pow(alpha, 4.0)))
        let rho = 90.0 - moonAltDeg
        let cr = cos(Astro.radians(rho))
        let sr = sin(Astro.radians(rho))
        let fRho = pow(10.0, 5.36) * (1.06 + cr * cr) + pow(10.0, 6.15 - rho / 40.0)
        let xMoon = pow(1 - 0.96 * (sr * sr), -0.5)
        let xZen = 1.0
        let bNl = fRho * iStar * pow(10.0, -0.4 * extinctionK * xMoon) * (1 - pow(10.0, -0.4 * extinctionK * xZen))
        if bNl <= 0 {
            return 0.0
        }
        let mag = (20.7233 - log(bNl / 34.08)) / 0.92104
        return magToFlux(mag)
    }

    public struct Brightness: Sendable, Equatable {
        public var zenithSkyMagDark: Double
        public var zenithSkyMagNow: Double
        public var limitingMagnitudeDark: Double
        public var limitingMagnitudeNow: Double
    }

    /// Zenith sky brightness (V mag/arcsec^2) and limiting magnitudes. `artificial` is the artificial-to-natural
    /// ratio, or nil when unknown (then the dark-site value is used).
    public static func skyBrightness(artificial: Double?, sunAlt: Double, moonAlt: Double, moonPhase: Double) -> Brightness {
        let nat = magToFlux(naturalSkyMag)
        let art = (artificial ?? 0.0) * nat
        let dark = fluxToMag(nat + art)
        let now = fluxToMag(nat + art + twilightFlux(sunAlt) + moonlightFlux(moonAltDeg: moonAlt, moonPhaseAngleDeg: moonPhase))
        return Brightness(zenithSkyMagDark: dark, zenithSkyMagNow: now,
                          limitingMagnitudeDark: limitingMagnitude(dark), limitingMagnitudeNow: limitingMagnitude(now))
    }
}
