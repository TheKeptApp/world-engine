import Foundation
import Testing
@testable import LiveSky

/// Checks the Swift sky core against the Python reference (`Tools/livefeeds/livefeeds/sky`) through the
/// shared vectors in `Fixtures/live-sky-vectors.json` (exported by `Tools/livefeeds/livefeeds/vectors.py`).
@Suite("Live sky vectors")
struct SkyVectorTests {
    private static let circularKeys: Set<String> = [
        "azDeg", "raDeg", "lstDeg", "gmstDeg", "gastDeg", "lstDegChicago",
        "brightLimbPositionAngleDeg", "brightLimbFromZenithDeg", "elongationLongitudeDeg",
    ]

    private static func vectors() throws -> [String: Any] {
        let url = try #require(Bundle.module.url(forResource: "live-sky-vectors", withExtension: "json",
                                                 subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private static func catalog() throws -> [StarEntry] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/WorldEnvironment/Catalog/stars-bsc5-bright256.json")
        return try StarCatalog.load(data: Data(contentsOf: url)).stars
    }

    private static func num(_ x: Any?) -> Double? {
        if x == nil || x is NSNull { return nil }
        return (x as? NSNumber)?.doubleValue
    }

    private static func tolerances(_ v: [String: Any]) throws -> [String: Double] {
        let raw = try #require(v["tolerances"] as? [String: Any])
        var out: [String: Double] = [:]
        for (k, value) in raw {
            if let d = num(value) { out[k] = d }
        }
        return out
    }

    private static func check(_ actual: Double?, _ expectedAny: Any?, tol: Double, circular: Bool, _ ctx: String) {
        let expected = num(expectedAny)
        guard let e = expected else {
            #expect(actual == nil, "\(ctx): expected null, got \(String(describing: actual))")
            return
        }
        guard let a = actual else {
            Issue.record("\(ctx): missing value, expected \(e)")
            return
        }
        var diff = abs(a - e)
        if circular {
            let m = Astro.pyMod(a - e, 360.0)
            diff = min(m, 360.0 - m)
        }
        #expect(diff <= tol, "\(ctx): got \(a), expected \(e), diff \(diff), tolerance \(tol)")
    }

    private static func vec(_ v: Vec3, _ expectedAny: Any?, tol: Double, _ ctx: String) {
        guard let arr = expectedAny as? [Any], arr.count == 3 else {
            Issue.record("\(ctx): expected a 3-vector")
            return
        }
        check(v.x, arr[0], tol: tol, circular: false, ctx + "[0]")
        check(v.y, arr[1], tol: tol, circular: false, ctx + "[1]")
        check(v.z, arr[2], tol: tol, circular: false, ctx + "[2]")
    }

    private static func bodyTolerance(_ key: String, _ tol: [String: Double]) -> Double {
        switch key {
        case "distanceKm": return tol["distanceKm"] ?? 1e-4
        case "distanceAu", "heliocentricDistanceAu": return tol["distanceAu"] ?? 1e-10
        case "magnitude": return tol["magnitude"] ?? 1e-7
        case "illuminatedFraction": return tol["fraction"] ?? 1e-9
        default: return tol["angleDeg"] ?? 1e-7
        }
    }

    private static func fields(_ s: SunState) -> [String: Double] {
        ["altDeg": s.altDeg, "apparentAltDeg": s.apparentAltDeg, "azDeg": s.azDeg, "raDeg": s.raDeg,
         "decDeg": s.decDeg, "distanceAu": s.distanceAu, "angularDiameterDeg": s.angularDiameterDeg,
         "magnitude": s.magnitude]
    }

    private static func fields(_ m: MoonState) -> [String: Double] {
        ["altDeg": m.altDeg, "apparentAltDeg": m.apparentAltDeg, "azDeg": m.azDeg, "raDeg": m.raDeg,
         "decDeg": m.decDeg, "distanceKm": m.distanceKm, "angularDiameterDeg": m.angularDiameterDeg,
         "phaseAngleDeg": m.phaseAngleDeg, "illuminatedFraction": m.illuminatedFraction,
         "elongationLongitudeDeg": m.elongationLongitudeDeg, "ageDays": m.ageDays,
         "brightLimbPositionAngleDeg": m.brightLimbPositionAngleDeg,
         "brightLimbFromZenithDeg": m.brightLimbFromZenithDeg, "magnitude": m.magnitude]
    }

    private static func fields(_ p: PlanetState) -> [String: Double] {
        var out: [String: Double] = [
            "altDeg": p.altDeg, "apparentAltDeg": p.apparentAltDeg, "azDeg": p.azDeg, "raDeg": p.raDeg,
            "decDeg": p.decDeg, "distanceAu": p.distanceAu, "heliocentricDistanceAu": p.heliocentricDistanceAu,
            "phaseAngleDeg": p.phaseAngleDeg, "illuminatedFraction": p.illuminatedFraction,
            "magnitude": p.magnitude,
        ]
        if let tilt = p.ringTiltDeg { out["ringTiltDeg"] = tilt }
        return out
    }

    private static func compareBody(_ actual: [String: Double], _ expected: [String: Any], tol: [String: Double],
                                    _ ctx: String) {
        for (key, value) in expected where key != "phaseName" {
            check(actual[key], value, tol: bodyTolerance(key, tol), circular: circularKeys.contains(key), "\(ctx).\(key)")
        }
        for key in actual.keys where expected[key] == nil {
            Issue.record("\(ctx).\(key): not in the reference output")
        }
    }

    @Test func timeScalesAndFrames() throws {
        let v = try Self.vectors()
        let tol = try Self.tolerances(v)
        let rows = try #require(v["time"] as? [[String: Any]])
        #expect(rows.count == 5)
        let angle = tol["angleDeg"] ?? 1e-7
        let days = tol["timeDays"] ?? 1e-10
        for row in rows {
            let posix = try #require(Self.num(row["posix"]))
            let ctx = "time[\(Int(posix))]"
            let t = Astro.centuriesTt(posix)
            let n = Astro.nutation(t)
            let actual: [String: (Double, Double)] = [
                "jdUtc": (Astro.jdUtc(posix), days),
                "deltaTSeconds": (Astro.deltaT(posix), tol["deltaTSeconds"] ?? 1e-6),
                "jdTt": (Astro.jdTt(posix), days),
                "centuriesTt": (t, days / 36525.0),
                "gmstDeg": (Astro.gmstDeg(posix), angle),
                "gastDeg": (Astro.gastDeg(posix), angle),
                "lstDegChicago": (Astro.lstDeg(posix, lonDeg: -87.6298), angle),
                "nutationLonArcsec": (n.dpsi, angle * 3600.0),
                "nutationOblArcsec": (n.deps, angle * 3600.0),
                "meanObliquityRad": (Astro.meanObliquity(t), angle * Astro.rad),
                "trueObliquityRad": (Astro.trueObliquity(t), angle * Astro.rad),
                "refractionDegAt10": (Astro.refractionDeg(10.0), angle),
                "airmassAt30": (Astro.airmass(30.0), tol["fraction"] ?? 1e-9),
            ]
            for (key, value) in row where key != "posix" {
                guard let a = actual[key] else {
                    Issue.record("\(ctx).\(key): not computed by the port")
                    continue
                }
                Self.check(a.0, value, tol: a.1, circular: Self.circularKeys.contains(key), "\(ctx).\(key)")
            }
        }
    }

    @Test func solarSystemFramesAndStars() throws {
        let v = try Self.vectors()
        let tol = try Self.tolerances(v)
        let stars = Array(try Self.catalog().prefix(40))
        #expect(stars.count == 40)
        let cases = try #require(v["sky"] as? [[String: Any]])
        #expect(cases.count == 9)
        let angle = tol["angleDeg"] ?? 1e-7
        for c in cases {
            let place = (c["place"] as? String) ?? "?"
            let lat = try #require(Self.num(c["lat"]))
            let lon = try #require(Self.num(c["lon"]))
            let elev = try #require(Self.num(c["elevM"]))
            let posix = try #require(Self.num(c["posix"]))
            let ctx = "\(place)@\(Int(posix))"
            let obs = SkyObserver(lat: lat, lon: lon, elevM: elev)

            let frame = SkyFrame.make(posix: posix, observer: obs)
            let ef = try #require(c["frame"] as? [String: Any])
            Self.check(frame.lst, ef["lstDeg"], tol: angle, circular: true, "\(ctx).frame.lstDeg")
            Self.vec(frame.earth, ef["earthAu"], tol: tol["distanceAu"] ?? 1e-10, "\(ctx).frame.earthAu")
            Self.vec(frame.vEarth, ef["vEarthAuPerDay"], tol: tol["distanceAu"] ?? 1e-10, "\(ctx).frame.vEarthAuPerDay")
            Self.vec(frame.observerKm, ef["observerKm"], tol: tol["distanceKm"] ?? 1e-4, "\(ctx).frame.observerKm")

            let ss = try SolarSystem.compute(posix: posix, observer: obs)
            let eb = try #require(c["bodies"] as? [String: Any])
            let es = try #require(eb["sun"] as? [String: Any])
            Self.compareBody(Self.fields(ss.sun), es, tol: tol, "\(ctx).sun")
            let em = try #require(eb["moon"] as? [String: Any])
            Self.compareBody(Self.fields(ss.moon), em, tol: tol, "\(ctx).moon")
            #expect(ss.moon.phaseName == (em["phaseName"] as? String), "\(ctx).moon.phaseName")
            #expect(ss.planets.count == SolarSystem.planets.count, "\(ctx): planet count")
            for name in SolarSystem.planets {
                let ep = try #require(eb[name] as? [String: Any], "\(ctx).\(name) missing in vectors")
                let p = try #require(ss.planets[name], "\(ctx).\(name) missing in port")
                Self.compareBody(Self.fields(p), ep, tol: tol, "\(ctx).\(name)")
            }

            let apparent = Stars.apparent(frame: frame, observer: obs, catalog: stars, minAltDeg: -90.0)
            let expectedStars = try #require(c["stars"] as? [[String: Any]])
            #expect(apparent.map(\.id) == expectedStars.compactMap { $0["id"] as? String }, "\(ctx): star order")
            var byID: [String: ApparentStar] = [:]
            for s in apparent { byID[s.id] = s }
            for es in expectedStars {
                let id = (es["id"] as? String) ?? "?"
                guard let s = byID[id] else {
                    Issue.record("\(ctx).\(id): star missing in port")
                    continue
                }
                let actual: [String: Double] = ["altDeg": s.altDeg, "apparentAltDeg": s.apparentAltDeg,
                                                "azDeg": s.azDeg, "raDeg": s.raDeg, "decDeg": s.decDeg]
                for (key, value) in es where key != "id" {
                    Self.check(actual[key], value, tol: angle, circular: Self.circularKeys.contains(key),
                               "\(ctx).\(id).\(key)")
                }
            }
        }
    }

    @Test func outOfRangeDatesThrow() {
        let obs = SkyObserver(lat: 0, lon: 0)
        #expect(throws: SkyError.outOfRange) { _ = try SolarSystem.compute(posix: 2_556_144_000, observer: obs) }
        #expect(throws: SkyError.outOfRange) { _ = try SolarSystem.compute(posix: -5_364_662_401, observer: obs) }
    }

    @Test func skyGlowTables() throws {
        let v = try Self.vectors()
        let tol = try Self.tolerances(v)
        let skyMag = tol["skyMag"] ?? 1e-7
        let glow = try #require(v["skyglow"] as? [String: Any])

        let rows = try #require(glow["skyBrightness"] as? [[String: Any]])
        #expect(rows.count == 120)
        for (n, row) in rows.enumerated() {
            let art = Self.num(row["artificial"])
            let sun = try #require(Self.num(row["sunAltDeg"]))
            let moon = try #require(Self.num(row["moonAltDeg"]))
            let phase = try #require(Self.num(row["moonPhaseDeg"]))
            let b = SkyGlow.skyBrightness(artificial: art, sunAlt: sun, moonAlt: moon, moonPhase: phase)
            let ctx = "skyBrightness[\(n)] art=\(String(describing: art)) sun=\(sun) moon=\(moon)/\(phase)"
            Self.check(b.zenithSkyMagDark, row["zenithSkyMagDark"], tol: skyMag, circular: false, ctx + ".zenithSkyMagDark")
            Self.check(b.zenithSkyMagNow, row["zenithSkyMagNow"], tol: skyMag, circular: false, ctx + ".zenithSkyMagNow")
            Self.check(b.limitingMagnitudeDark, row["limitingMagnitudeDark"], tol: skyMag, circular: false,
                       ctx + ".limitingMagnitudeDark")
            Self.check(b.limitingMagnitudeNow, row["limitingMagnitudeNow"], tol: skyMag, circular: false,
                       ctx + ".limitingMagnitudeNow")
        }

        let lm = try #require(glow["limitingMagnitude"] as? [[String: Any]])
        for row in lm {
            let m = try #require(Self.num(row["skyMag"]))
            Self.check(SkyGlow.limitingMagnitude(m), row["limitingMagnitude"], tol: skyMag, circular: false,
                       "limitingMagnitude(\(m))")
        }

        let ext = try #require(glow["extinction"] as? [[String: Any]])
        for row in ext {
            let a = try #require(Self.num(row["apparentAltDeg"]))
            Self.check(Stars.extinctionMag(a), row["extinctionMag"], tol: tol["magnitude"] ?? 1e-7, circular: false,
                       "extinctionMag(\(a))")
        }

        let g = try #require(glow["radianceGrid"] as? [String: Any])
        let rawValues = try #require(g["values"] as? [Any])
        let north = try #require(Self.num(g["north"]))
        let west = try #require(Self.num(g["west"]))
        let dlat = try #require(Self.num(g["dlat"]))
        let dlon = try #require(Self.num(g["dlon"]))
        let gridRows = try #require(Self.num(g["rows"]))
        let gridCols = try #require(Self.num(g["cols"]))
        let grid = SkyGlow.RadianceGrid(north: north, west: west, dlat: dlat, dlon: dlon,
                                        rows: Int(gridRows), cols: Int(gridCols),
                                        values: rawValues.map { Self.num($0) })
        #expect(grid.values.count == grid.rows * grid.cols)
        let wr = try #require(glow["weightedRadiance"] as? [[String: Any]])
        for row in wr {
            let lat = try #require(Self.num(row["lat"]))
            let lon = try #require(Self.num(row["lon"]))
            Self.check(SkyGlow.weightedRadiance(grid, lat: lat, lon: lon), row["weightedRadiance"],
                       tol: tol["radiance"] ?? 1e-9, circular: false, "weightedRadiance(\(lat), \(lon))")
        }
    }
}
