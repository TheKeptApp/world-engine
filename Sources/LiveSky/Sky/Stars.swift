import Foundation

/// One star of a `worldengine.stars/1` catalogue (unit vector, equatorial J2000, epoch J2000).
public struct StarEntry: Sendable, Equatable, Decodable {
    public var id: Int
    public var hr: String
    public var name: String?
    public var mag: Double
    /// B-V colour index; nil when the catalogue has none.
    public var ci: Double?
    public var u: Vec3
    public var distPc: Double?
    public var velPcPerYear: Vec3?

    public init(id: Int, hr: String, name: String?, mag: Double, ci: Double?, u: Vec3,
                distPc: Double?, velPcPerYear: Vec3?) {
        self.id = id
        self.hr = hr
        self.name = name
        self.mag = mag
        self.ci = ci
        self.u = u
        self.distPc = distPc
        self.velPcPerYear = velPcPerYear
    }

    private enum CodingKeys: String, CodingKey {
        case id, hr, name, mag, ci, u, distPc, velPcPerYear
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let hrString = try c.decode(String.self, forKey: .hr)
        hr = hrString
        if let i = try c.decodeIfPresent(Int.self, forKey: .id) {
            id = i
        } else {
            id = Int(hrString) ?? 0
        }
        name = try c.decodeIfPresent(String.self, forKey: .name)
        mag = try c.decode(Double.self, forKey: .mag)
        ci = try c.decodeIfPresent(Double.self, forKey: .ci)
        u = try StarEntry.vec(try c.decode([Double].self, forKey: .u), c, .u)
        distPc = try c.decodeIfPresent(Double.self, forKey: .distPc)
        if let v = try c.decodeIfPresent([Double].self, forKey: .velPcPerYear) {
            velPcPerYear = try StarEntry.vec(v, c, .velPcPerYear)
        } else {
            velPcPerYear = nil
        }
    }

    private static func vec(_ a: [Double], _ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> Vec3 {
        guard a.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "expected 3 components")
        }
        return Vec3(a[0], a[1], a[2])
    }
}

public struct StarCatalog: Sendable, Equatable, Decodable {
    public static let schemaID = "worldengine.stars/1"

    public var schema: String
    public var stars: [StarEntry]

    public init(schema: String = StarCatalog.schemaID, stars: [StarEntry]) {
        self.schema = schema
        self.stars = stars
    }

    public enum LoadError: Error, Sendable, Equatable {
        case unsupportedSchema(String)
    }

    /// Decodes a `worldengine.stars/1` document; throws on any other schema.
    public static func load(data: Data) throws -> StarCatalog {
        let cat = try JSONDecoder().decode(StarCatalog.self, from: data)
        if cat.schema != schemaID {
            throw LoadError.unsupportedSchema(cat.schema)
        }
        return cat
    }
}

/// A star's apparent horizon position for one frame.
public struct ApparentStar: Sendable, Equatable {
    /// "hr" + HR number.
    public var id: String
    public var name: String?
    public var mag: Double
    public var colorIndexBV: Double?
    public var altDeg: Double
    public var apparentAltDeg: Double
    public var azDeg: Double
    public var raDeg: Double
    public var decDeg: Double
}

/// Bright stars: space motion to the date (when the catalogue gives it), annual aberration, precession and
/// nutation, then horizon coordinates and refraction. Stellar parallax (< 1 arcsec) is ignored.
public enum Stars {
    public static func j2000Direction(_ star: StarEntry, yearsSinceJ2000: Double) -> Vec3 {
        if let dist = star.distPc, dist != 0, let vel = star.velPcPerYear {
            let p = star.u.scaled(dist) + vel.scaled(yearsSinceJ2000)
            return p.unit
        }
        return star.u
    }

    /// Stars whose apparent altitude is at least `minAltDeg`, brightest first (ties by id).
    public static func apparent(frame fr: SkyFrame, observer obs: SkyObserver, catalog: [StarEntry],
                                minAltDeg: Double = -1.0) -> [ApparentStar] {
        let years = fr.t * 100.0
        var out: [ApparentStar] = []
        for s in catalog {
            let u = SolarSystem.aberrate(j2000Direction(s, yearsSinceJ2000: years), fr.vEarth)
            let v = fr.toDate * u
            let aa = Astro.altAz(v, latDeg: obs.lat, lst: fr.lst)
            let app = aa.alt + Astro.refractionDeg(aa.alt, pressureHpa: obs.pressureHpa, tempC: obs.tempC)
            if app < minAltDeg {
                continue
            }
            let rd = Astro.raDec(v)
            out.append(ApparentStar(id: "hr" + s.hr, name: s.name, mag: s.mag, colorIndexBV: s.ci,
                                    altDeg: aa.alt, apparentAltDeg: app, azDeg: aa.az, raDeg: rd.ra, decDeg: rd.dec))
        }
        out.sort { a, b in
            if a.mag != b.mag {
                return a.mag < b.mag
            }
            return a.id.unicodeScalars.lexicographicallyPrecedes(b.id.unicodeScalars)
        }
        return out
    }

    public static func apparent(frame fr: SkyFrame, observer obs: SkyObserver, catalog: StarCatalog,
                                minAltDeg: Double = -1.0) -> [ApparentStar] {
        apparent(frame: fr, observer: obs, catalog: catalog.stars, minAltDeg: minAltDeg)
    }

    /// Atmospheric extinction in V for a typical inland site (k = 0.25 mag per air mass, assumption).
    public static func extinctionMag(_ apparentAltDeg: Double, kV: Double = 0.25) -> Double {
        let x = Astro.airmass(apparentAltDeg)
        return x.isFinite ? kV * x : 99.0
    }
}
