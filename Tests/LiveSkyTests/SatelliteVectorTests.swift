import Foundation
import Testing
@testable import LiveSky

/// Checks the Swift satellite port against the Python reference vectors
/// (`Tests/LiveSkyTests/Fixtures/live-sky-vectors.json`, from `Tools/livefeeds/livefeeds/vectors.py`).
@Suite("Satellite vectors")
struct SatelliteVectorTests {
    struct Fixture {
        let root: [String: Any]
        let sats: [String: Any]
        let tol: [String: Any]

        func tolerance(_ key: String) -> Double {
            return SatelliteVectorTests.num(tol[key]) ?? 0
        }
    }

    static func loadFixture() throws -> Fixture {
        let url = try #require(Bundle.module.url(forResource: "live-sky-vectors", withExtension: "json",
                                                 subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let sats = try #require(root["satellites"] as? [String: Any])
        let tol = try #require(root["tolerances"] as? [String: Any])
        return Fixture(root: root, sats: sats, tol: tol)
    }

    static func num(_ v: Any?) -> Double? {
        if v == nil || v is NSNull {
            return nil
        }
        if let n = v as? NSNumber {
            return n.doubleValue
        }
        if let d = v as? Double {
            return d
        }
        return nil
    }

    static func bool(_ v: Any?) -> Bool? {
        if let b = v as? Bool {
            return b
        }
        if let n = v as? NSNumber {
            return n.boolValue
        }
        return nil
    }

    static func checkClose(_ actual: Double, _ expected: Any?, _ tol: Double, _ label: String) {
        guard let e = num(expected) else {
            Issue.record("\(label): expected value missing")
            return
        }
        let diff = abs(actual - e)
        #expect(diff <= tol, "\(label): got \(actual), expected \(e) (diff \(diff), tol \(tol))")
    }

    static func angleDiff(_ a: Double, _ b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360.0)
        if d < 0 {
            d += 360.0
        }
        return min(d, 360.0 - d)
    }

    static func elements(_ fx: Fixture, _ name: String) throws -> SatelliteElements {
        let tle = try #require(fx.sats["tle"] as? [String: Any])
        let lines = try #require(tle[name] as? [String])
        try #require(lines.count == 3)
        return try SatelliteElements.parseTLE(name: lines[0], line1: lines[1], line2: lines[2], verifyChecksum: true)
    }

    static func checkElements(_ el: SatelliteElements, _ expected: [String: Any], _ label: String) {
        #expect(el.name == (expected["name"] as? String), "\(label): name")
        #expect(Double(el.noradId) == num(expected["noradId"]), "\(label): noradId")
        checkClose(el.epoch, expected["epoch"], 1e-3, "\(label) epoch")
        let pairs: [(Double, String)] = [
            (el.inclinationDeg, "inclinationDeg"), (el.raanDeg, "raanDeg"), (el.eccentricity, "eccentricity"),
            (el.argPerigeeDeg, "argPerigeeDeg"), (el.meanAnomalyDeg, "meanAnomalyDeg"),
            (el.meanMotionRevPerDay, "meanMotionRevPerDay"), (el.bstar, "bstar"),
        ]
        for (value, key) in pairs {
            checkClose(value, expected[key], 1e-12, "\(label) \(key)")
        }
    }

    @Test func parsedElements() throws {
        let fx = try Self.loadFixture()
        let expected = try #require(fx.sats["elements"] as? [String: Any])
        for name in ["ISS_2008", "V5"] {
            let el = try Self.elements(fx, name)
            Self.checkElements(el, try #require(expected[name] as? [String: Any]), name)
        }
        let omm = try #require(fx.sats["omm"] as? [[String: Any]])
        let parsed = try SatelliteElements.parseOMM(records: omm)
        try #require(parsed.count == 1)
        Self.checkElements(parsed[0], try #require(expected["OMM"] as? [String: Any]), "OMM")
        let data = try JSONSerialization.data(withJSONObject: omm)
        let fromData = try SatelliteElements.parseOMM(jsonData: data)
        // Field by field with the vector tolerances: a JSON round trip may move a Double by one ulp
        // (eccentricity 0.0006703000000000001 vs 0.0006703), so exact struct equality is too strict.
        try #require(fromData.count == 1, "OMM via Data")
        Self.checkElements(fromData[0], try #require(expected["OMM"] as? [String: Any]), "OMM via Data")
    }

    @Test func tleTextAndChecksum() throws {
        let fx = try Self.loadFixture()
        let tle = try #require(fx.sats["tle"] as? [String: Any])
        let iss = try #require(tle["ISS_2008"] as? [String])
        let text = iss.joined(separator: "\n") + "\n\n" + iss[1] + "\n" + iss[2] + "\n"
        let parsed = try SatelliteElements.parseTLEText(text)
        #expect(parsed.count == 2)
        #expect(parsed.count == 2 && parsed[1].name == "25544")
        var bad = Array(iss[1])
        bad[68] = bad[68] == "0" ? "1" : "0"
        #expect(throws: SatelliteError.self) {
            _ = try SatelliteElements.parseTLE(name: "x", line1: String(bad), line2: iss[2])
        }
    }

    @Test func states() throws {
        let fx = try Self.loadFixture()
        let rows = try #require(fx.sats["states"] as? [[String: Any]])
        #expect(!rows.isEmpty)
        let posTol = fx.tolerance("sgp4PositionKm")
        let velTol = fx.tolerance("sgp4VelocityKmS")
        var props: [String: SGP4Propagator] = [:]
        for name in ["ISS_2008", "V5"] {
            props[name] = try SGP4Propagator(elements: try Self.elements(fx, name))
        }
        for row in rows {
            let name = try #require(row["sat"] as? String)
            let minutes = try #require(Self.num(row["minutes"]))
            let prop = try #require(props[name])
            let state = try prop.propagate(minutesSinceEpoch: minutes)
            let r = try #require(row["rKm"] as? [Any])
            let v = try #require(row["vKmS"] as? [Any])
            try #require(r.count == 3 && v.count == 3)
            let label = "\(name) t=\(minutes)min"
            Self.checkClose(state.r.x, r[0], posTol, "\(label) r.x")
            Self.checkClose(state.r.y, r[1], posTol, "\(label) r.y")
            Self.checkClose(state.r.z, r[2], posTol, "\(label) r.z")
            Self.checkClose(state.v.x, v[0], velTol, "\(label) v.x")
            Self.checkClose(state.v.y, v[1], velTol, "\(label) v.y")
            Self.checkClose(state.v.z, v[2], velTol, "\(label) v.z")
        }
    }

    static func place(_ fx: Fixture, _ name: String) -> PassObserver? {
        guard let rows = fx.sats["passes"] as? [[String: Any]] else {
            return nil
        }
        for row in rows where (row["place"] as? String) == name {
            if let lat = num(row["lat"]), let lon = num(row["lon"]), let elev = num(row["elevM"]) {
                return PassObserver(latDeg: lat, lonDeg: lon, elevM: elev)
            }
        }
        return nil
    }

    @Test func observations() throws {
        let fx = try Self.loadFixture()
        let rows = try #require(fx.sats["observations"] as? [[String: Any]])
        #expect(!rows.isEmpty)
        let ang = fx.tolerance("angleDeg")
        let dist = fx.tolerance("distanceKm")
        let sat = try SGP4Propagator(elements: try Self.elements(fx, "ISS_2008"))
        for row in rows {
            let placeName = try #require(row["place"] as? String)
            let observer = try #require(Self.place(fx, placeName))
            let posix = try #require(Self.num(row["posix"]))
            let o = try observer.observe(sat, at: posix)
            let label = "ISS_2008 \(placeName) t=\(posix)"
            Self.checkClose(o.altDeg, row["altDeg"], ang, "\(label) altDeg")
            let az = try #require(Self.num(row["azDeg"]))
            #expect(Self.angleDiff(o.azDeg, az) <= ang, "\(label) azDeg: got \(o.azDeg), expected \(az)")
            Self.checkClose(o.rangeKm, row["rangeKm"], dist, "\(label) rangeKm")
            #expect(o.sunlit == Self.bool(row["sunlit"]), "\(label) sunlit")
            Self.checkClose(o.sunAltDeg, row["sunAltDeg"], ang, "\(label) sunAltDeg")
            Self.checkClose(o.phaseRad, row["phaseRad"], ang * Double.pi / 180, "\(label) phaseRad")
            Self.checkClose(o.latDeg, row["latDeg"], ang, "\(label) latDeg")
            let lon = try #require(Self.num(row["lonDeg"]))
            #expect(Self.angleDiff(o.lonDeg, lon) <= ang, "\(label) lonDeg: got \(o.lonDeg), expected \(lon)")
            Self.checkClose(o.heightKm, row["heightKm"], dist, "\(label) heightKm")
        }
    }

    struct PassTolerances {
        let time: Double
        let angle: Double
        let range: Double
        let mag: Double
    }

    static func checkOptionalMag(_ actual: Double?, _ expected: Any?, _ tol: Double, _ label: String) {
        let e = num(expected)
        switch (actual, e) {
        case (nil, nil):
            break
        case let (a?, e?):
            #expect(abs(a - e) <= tol, "\(label): got \(a), expected \(e)")
        default:
            Issue.record("\(label): got \(String(describing: actual)), expected \(String(describing: e))")
        }
    }

    static func checkPoint(_ p: PassPoint, _ expected: Any?, _ tol: PassTolerances, _ label: String) {
        guard let e = expected as? [String: Any] else {
            Issue.record("\(label): expected point missing")
            return
        }
        checkClose(p.t, e["t"], tol.time, "\(label) t")
        checkClose(p.altDeg, e["altDeg"], tol.angle, "\(label) altDeg")
        if let az = num(e["azDeg"]) {
            #expect(angleDiff(p.azDeg, az) <= tol.angle, "\(label) azDeg: got \(p.azDeg), expected \(az)")
        } else {
            Issue.record("\(label) azDeg missing")
        }
        checkClose(p.rangeKm, e["rangeKm"], tol.range, "\(label) rangeKm")
        #expect(p.sunlit == bool(e["sunlit"]), "\(label) sunlit")
        checkOptionalMag(p.magnitude, e["magnitude"], tol.mag, "\(label) magnitude")
    }

    @Test func passes() throws {
        let fx = try Self.loadFixture()
        let rows = try #require(fx.sats["passes"] as? [[String: Any]])
        #expect(!rows.isEmpty)
        let tol = PassTolerances(time: fx.tolerance("passTimeSeconds"), angle: fx.tolerance("passAngleDeg"),
                                 range: fx.tolerance("passRangeKm"), mag: fx.tolerance("passMagnitude"))
        let sat = try SGP4Propagator(elements: try Self.elements(fx, "ISS_2008"))
        for row in rows {
            let placeName = try #require(row["place"] as? String)
            let observer = PassObserver(latDeg: try #require(Self.num(row["lat"])),
                                        lonDeg: try #require(Self.num(row["lon"])),
                                        elevM: try #require(Self.num(row["elevM"])))
            let start = try #require(Self.num(row["start"]))
            let end = try #require(Self.num(row["end"]))
            let stdMag = Self.num(row["stdMag"])
            let expected = try #require(row["passes"] as? [[String: Any]])
            let got = try observer.findPasses(sat, start: start, end: end, stdMag: stdMag)
            #expect(got.count == expected.count, "\(placeName): pass count \(got.count) vs \(expected.count)")
            if got.count != expected.count {
                continue
            }
            for (i, pair) in zip(got, expected).enumerated() {
                let (p, e) = pair
                let label = "ISS_2008 \(placeName) pass \(i)"
                Self.checkPoint(p.rise, e["rise"], tol, "\(label) rise")
                Self.checkPoint(p.culmination, e["culmination"], tol, "\(label) culmination")
                Self.checkPoint(p.set, e["set"], tol, "\(label) set")
                #expect(p.startsBeforeWindow == Self.bool(e["startsBeforeWindow"]), "\(label) startsBeforeWindow")
                #expect(p.endsAfterWindow == Self.bool(e["endsAfterWindow"]), "\(label) endsAfterWindow")
                #expect(p.visible == Self.bool(e["visible"]), "\(label) visible")
                #expect(p.basis == (e["basis"] as? String), "\(label) basis")
                let ew = e["visibleWindow"] as? [String: Any]
                #expect((p.visibleWindow == nil) == (ew == nil), "\(label) visibleWindow presence")
                if let w = p.visibleWindow, let ew = ew {
                    Self.checkPoint(w.start, ew["start"], tol, "\(label) window start")
                    Self.checkPoint(w.end, ew["end"], tol, "\(label) window end")
                    Self.checkClose(w.maxAltDeg, ew["maxAltDeg"], tol.angle, "\(label) window maxAltDeg")
                    Self.checkOptionalMag(w.brightestMagnitude, ew["brightestMagnitude"], tol.mag,
                                     "\(label) window brightestMagnitude")
                    #expect(w.endsInShadow == Self.bool(ew["endsInShadow"]), "\(label) window endsInShadow")
                    let et = ew["track"] as? [Any] ?? []
                    #expect(w.track.count == et.count, "\(label) track length \(w.track.count) vs \(et.count)")
                    if w.track.count == et.count {
                        for (k, tp) in w.track.enumerated() {
                            Self.checkPoint(tp, et[k], tol, "\(label) track \(k)")
                        }
                    }
                }
            }
        }
    }

    @Test func magnitudeTable() throws {
        let fx = try Self.loadFixture()
        let rows = try #require(fx.sats["magnitude"] as? [[String: Any]])
        #expect(!rows.isEmpty)
        let tol = fx.tolerance("magnitude")
        for row in rows {
            let std = Self.num(row["stdMag"])
            let r = try #require(Self.num(row["rangeKm"]))
            let ph = try #require(Self.num(row["phaseRad"]))
            let got = SatelliteMagnitude.estimate(stdMag: std, rangeKm: r, phaseRad: ph)
            Self.checkOptionalMag(got, row["magnitude"], tol, "magnitude std=\(String(describing: std)) r=\(r) ph=\(ph)")
        }
        #expect(SatelliteMagnitude.estimate(stdMag: nil, rangeKm: 500, phaseRad: 1) == nil)
    }
}
