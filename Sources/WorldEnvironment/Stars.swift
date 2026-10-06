import Foundation
import WorldGeo

/// One catalog star (J2000 unit direction, magnitude, color index).
public struct CatalogStar: Codable, Sendable, Equatable {
    public var id: Int
    public var components: [Int]
    public var hip: String?
    public var name: String?
    public var bayer: String?
    public var con: String?
    public var mag: Double
    public var ci: Double?
    public var u: [Double]
    public var distPc: Double?
    public var velPcPerYear: [Double]?
}

public struct StarCatalog: Codable, Sendable {
    public var schema: String
    public var count: Int
    public var stars: [CatalogStar]
    public var source: Source

    public struct Source: Codable, Sendable {
        public var name: String, author: String, url: String, sha256: String, license: String, licenseURL: String
    }

    /// The bundled 256-star HYG v4.1 subset (CC BY-SA 4.0; see Resources/STARS-NOTICE.md).
    public static func bundled() throws -> StarCatalog {
        guard let url = Bundle.module.url(forResource: "stars-hyg-v41-bright256", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(StarCatalog.self, from: Data(contentsOf: url))
    }

    /// Credit line required wherever the stars are shown.
    public static let attribution = "Stars: HYG Database v4.1, David Nash / Astronomy Nexus, CC BY-SA 4.0 (modified)."
}

/// A visible star for drawing: scene direction, brightness and tint.
public struct VisibleStar: Codable, Sendable, Equatable {
    public var id: Int
    public var direction: SIMD3<Double>
    public var altitudeDeg: Double
    /// Compressed, capped brightness 0.15…1 from magnitude.
    public var brightness: Double
    /// Restrained tint (linear RGB, near white) from the color index; white if unknown.
    public var tint: SIMD3<Double>
}

public struct StarField: Codable, Sendable, Equatable {
    /// Global strength 0…1 (night factor, cloud, obscuration, moon; zero in active precipitation).
    public var strength: Double
    /// Brightest eligible stars above the horizon, at most 128, stable-ID ties.
    public var visible: [VisibleStar]
    public var catalogCount: Int
}

public enum Stars {
    public static let maxVisible = 128
    public static let model = "hyg-v41-256, IAU-1976 precession, mean sidereal time"

    /// Weather/time gate: nightFactor × (1 − C)³ × (1 − O) × (1 − 0.3B), off in active precipitation.
    public static func strength(sunElevationDeg: Double, cloud: Double?, obscuration: Double, moonFill b: Double,
                                activePrecipitation: Bool) -> Double {
        if activePrecipitation { return 0 }
        let night = 1 - EnvMath.smoothstep(-12, -6, sunElevationDeg)
        let c = cloud ?? 1 // unknown cloud: no stars
        return night * pow(1 - EnvMath.clamp01(c), 3) * (1 - EnvMath.clamp01(obscuration)) * (1 - 0.3 * EnvMath.clamp01(b))
    }

    public static func field(_ catalog: StarCatalog, at date: Date, observer: SkyObserver, strength: Double) -> StarField {
        let jdUT = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let t = (jdUT - 2_451_545) / 36_525
        let years = (jdUT - 2_451_545) / 365.25
        let p = precessionMatrix(t)
        let tu = t
        let gmst = EnvMath.wrap360(280.46061837 + 360.98564736629 * (jdUT - 2_451_545) + 0.000387933 * tu * tu - tu * tu * tu / 38_710_000)
        let lst = (gmst + observer.longitude) * .pi / 180
        let lat = observer.latitude * .pi / 180
        var out: [VisibleStar] = []
        if strength > 0 {
            for s in catalog.stars {
                var v = SIMD3(s.u[0], s.u[1], s.u[2])
                if let d = s.distPc, let vel = s.velPcPerYear, vel.count == 3 {
                    let pos = v * d + SIMD3(vel[0], vel[1], vel[2]) * years
                    v = pos / (pos.x * pos.x + pos.y * pos.y + pos.z * pos.z).squareRoot()
                }
                let q = SIMD3(p.0.x * v.x + p.0.y * v.y + p.0.z * v.z, p.1.x * v.x + p.1.y * v.y + p.1.z * v.z,
                              p.2.x * v.x + p.2.y * v.y + p.2.z * v.z)
                let (alt, az) = Moon.horizontal(q, lst: lst, latitude: lat)
                guard alt > 0 else { continue }
                out.append(VisibleStar(id: s.id, direction: Moon.sceneDirection(altitude: alt, azimuth: az), altitudeDeg: alt,
                                       brightness: brightness(mag: s.mag), tint: tint(ci: s.ci)))
                if out.count == maxVisible { break } // catalog is sorted by magnitude, then ID
            }
        }
        return StarField(strength: strength, visible: out, catalogCount: catalog.stars.count)
    }

    public static func brightness(mag: Double) -> Double { min(1, max(0.15, (4.5 - mag) / 6)) }

    /// Restrained tint: 25% toward an approximate blackbody color from B−V (Ballesteros 2012).
    public static func tint(ci: Double?) -> SIMD3<Double> {
        guard let bv = ci else { return SIMD3(1, 1, 1) }
        let t = 4600 * (1 / (0.92 * bv + 1.7) + 1 / (0.92 * bv + 0.62))
        let k = min(40_000, max(1000, t)) / 100
        func c(_ x: Double) -> Double { min(1, max(0, x / 255)) }
        let r = k <= 66 ? 1 : c(329.698727446 * pow(k - 60, -0.1332047592))
        let g = k <= 66 ? c(99.4708025861 * log(k) - 161.1195681661) : c(288.1221695283 * pow(k - 60, -0.0755148492))
        let b = k >= 66 ? 1 : (k <= 19 ? 0 : c(138.5177312231 * log(k - 10) - 305.0447927307))
        let color = SIMD3(r, g, b)
        return SIMD3(1, 1, 1) * 0.75 + color * 0.25
    }

    /// J2000 → mean equator/equinox of date (IAU 1976: ζ, z, θ; Meeus ch. 21).
    static func precessionMatrix(_ t: Double) -> (SIMD3<Double>, SIMD3<Double>, SIMD3<Double>) {
        let a = Double.pi / (180 * 3600)
        let zeta = (2306.2181 * t + 0.30188 * t * t + 0.017998 * t * t * t) * a
        let z = (2306.2181 * t + 1.09468 * t * t + 0.018203 * t * t * t) * a
        let theta = (2004.3109 * t - 0.42665 * t * t - 0.041833 * t * t * t) * a
        let cz = cos(zeta), sz = sin(zeta), cZ = cos(z), sZ = sin(z), ct = cos(theta), st = sin(theta)
        return (SIMD3(cZ * ct * cz - sZ * sz, -cZ * ct * sz - sZ * cz, -cZ * st),
                SIMD3(sZ * ct * cz + cZ * sz, -sZ * ct * sz + cZ * cz, -sZ * st),
                SIMD3(st * cz, -st * sz, ct))
    }
}
