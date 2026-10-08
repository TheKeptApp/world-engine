import Foundation
import Testing
@testable import WorldEnvironment
import WorldGeo

/// Sky and season fixtures from docs/proposals/sky-seasons-v1 (read-only input).
enum SkyFixtures {
    static let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("docs/proposals/sky-seasons-v1/sky-seasons-fixtures.json")
    static var json: [String: Any] { (try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]) ?? [:] }
    static var fixtures: [[String: Any]] { json["fixtures"] as? [[String: Any]] ?? [] }
    static func observer(_ id: String) -> SkyObserver {
        let l = (json["locations"] as! [[String: Any]]).first { $0["id"] as? String == id }!
        return SkyObserver(latitude: l["latitudeDeg"] as! Double, longitude: l["longitudeDeg"] as! Double,
                           elevationM: (l["elevationM"] as! NSNumber).doubleValue, timeZoneID: l["timeZone"] as! String)
    }
    static func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)!
    }
    static var available: Bool { !fixtures.isEmpty }
}

@Suite("Sky and season fixtures (docs/proposals/sky-seasons-v1)")
struct SkyFixtureTests {
    static let ids: [String] = {
        guard let data = try? Data(contentsOf: SkyFixtures.url),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        return (j["fixtures"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
    }()
    static func fixture(_ id: String) -> [String: Any] { SkyFixtures.fixtures.first { $0["id"] as? String == id }! }
    static func utc(_ d: Any?) -> Date? { (d as? [String: Any])?["utc"].map { SkyFixtures.date($0 as! String) } }

    /// Angle between two (altitude, azimuth) directions, degrees.
    static func separation(_ alt1: Double, _ az1: Double, _ alt2: Double, _ az2: Double) -> Double {
        let r = Double.pi / 180
        let c = sin(alt1 * r) * sin(alt2 * r) + cos(alt1 * r) * cos(alt2 * r) * cos((az1 - az2) * r)
        return acos(max(-1, min(1, c))) / r
    }

    @Test(arguments: ids)
    func sunEventsMatch(_ id: String) throws {
        guard SkyFixtures.available else { Issue.record("missing test prerequisite: SkyFixtures.available"); return }
        let f = Self.fixture(id)
        let obs = SkyFixtures.observer(f["locationId"] as! String)
        let at = SkyFixtures.date((f["at"] as! [String: Any])["utc"] as! String)
        let sun = f["sun"] as! [String: Any]
        let tol = 120.0 // seconds (fixture tolerance)
        let day = try #require(SunEvents.day(containing: at, observer: obs))
        #expect(abs(day.dayEnd.timeIntervalSince(day.dayStart) - (f["localDayDurationSeconds"] as! NSNumber).doubleValue) < 1, "\(id) day length")
        func check(_ got: Date?, _ key: String) {
            guard let want = Self.utc(sun[key]) else { #expect(got == nil, "\(id) \(key) unexpected"); return }
            #expect(got.map { abs($0.timeIntervalSince(want)) <= tol } == true, "\(id) \(key) \(String(describing: got)) vs \(want)")
        }
        check(day.sunrise.first?.utc, "sunrise")
        check(day.sunset.first?.utc, "sunset")
        check(day.solarNoon.first, "solarNoon")
        check(day.civilDawn.first?.utc, "civilDawn")
        check(day.civilDusk.first?.utc, "civilDusk")
        check(day.nauticalDawn.first?.utc, "nauticalDawn")
        check(day.nauticalDusk.first?.utc, "nauticalDusk")
        for (key, got) in [("goldenHourIntervals", day.goldenHourIntervals), ("blueHourIntervals", day.blueHourIntervals)] {
            let want = sun[key] as! [[String: Any]]
            #expect(got.count == want.count, "\(id) \(key) count")
            for (g, w) in zip(got, want) {
                #expect(g.branch.rawValue == w["branch"] as? String)
                #expect(abs(g.start.timeIntervalSince(Self.utc(w["start"])!)) <= tol && abs(g.end.timeIntervalSince(Self.utc(w["end"])!)) <= tol,
                        "\(id) \(key)")
            }
        }
        #expect(abs(day.daylightSeconds - (sun["daylightSeconds"] as! NSNumber).doubleValue) <= 2 * tol, "\(id) daylight")
        #expect(day.status.rawValue == sun["status"] as? String)
        let p = SolarPosition(date: at, at: obs.coordinate)
        #expect(Self.separation(p.elevation, p.azimuth, sun["elevationDeg"] as! Double, sun["azimuthDeg"] as! Double) <= 0.1, "\(id) sun direction")
    }

    @Test(arguments: ids)
    func moonMatches(_ id: String) throws {
        guard SkyFixtures.available else { Issue.record("missing test prerequisite: SkyFixtures.available"); return }
        let f = Self.fixture(id)
        let obs = SkyFixtures.observer(f["locationId"] as! String)
        let at = SkyFixtures.date((f["at"] as! [String: Any])["utc"] as! String)
        let m = f["moon"] as! [String: Any]
        func v(_ k: String) -> Double { (m[k] as! NSNumber).doubleValue }
        let s = Moon.state(at: at, observer: obs)
        #expect(Self.separation(s.altitudeDeg, s.azimuthDeg, v("altitudeGeometricTopocentricDeg"), v("azimuthDeg")) <= 0.15, "\(id) direction")
        #expect(abs(s.illuminatedFraction - v("illuminatedFractionTopocentric")) <= 0.01, "\(id) k")
        #expect(abs(s.illuminatedFraction - (1 + cos(s.phaseAngleDeg * .pi / 180)) / 2) < 1e-12, "phase identity")
        #expect(abs(EnvMath.wrap180(s.phaseLongitudeDeg - v("phaseLongitudeGeocentricDeg"))) <= 0.1, "\(id) phase longitude")
        if let chi = s.brightLimbAngleEquatorialDeg, v("phaseAngleTopocentricDeg") > 5, v("phaseAngleTopocentricDeg") < 175 {
            #expect(abs(EnvMath.wrap180(chi - v("brightLimbAngleEquatorialDeg"))) <= 1, "\(id) bright limb")
            #expect(abs(EnvMath.wrap180(s.brightLimbAngleFromZenithDeg! - v("brightLimbAngleFromZenithDeg"))) <= 1, "\(id) limb from zenith")
        }
        #expect(abs(s.angularDiameterDeg - v("angularDiameterDeg")) <= 0.001, "\(id) diameter")
        #expect(s.phaseLabel == m["phaseLabel"] as? String)
        #expect(s.aboveGeometricHorizon == m["aboveGeometricHorizon"] as? Bool)
        let day = try #require(Moon.day(containing: at, observer: obs))
        let want = m["events"] as! [[String: Any]]
        #expect(day.events.count == want.count, "\(id) moon event count")
        for (g, w) in zip(day.events, want) {
            #expect(g.kind.rawValue == w["kind"] as? String)
            #expect(abs(g.utc.timeIntervalSince(SkyFixtures.date(w["utc"] as! String))) <= 300, "\(id) \(g.kind)")
        }
        #expect(day.status == m["eventStatus"] as? String)
        #expect(day.aboveStandardRiseSetHorizonAtDayStart == m["aboveStandardRiseSetHorizonAtDayStart"] as? Bool)
    }

    @Test(arguments: ids)
    func seasonMatches(_ id: String) throws {
        guard SkyFixtures.available else { Issue.record("missing test prerequisite: SkyFixtures.available"); return }
        let f = Self.fixture(id)
        let obs = SkyFixtures.observer(f["locationId"] as! String)
        let at = SkyFixtures.date((f["at"] as! [String: Any])["utc"] as! String)
        let season = f["season"] as! [String: Any]
        let profile = [PhenologyProfile.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo].first { $0.id == season["profileId"] as? String }!
        let p = Phenology.resolve(at: at, timeZone: obs.timeZone!, profile: profile)
        let d = season["representativeDeciduous"] as! [String: Any]
        func n(_ x: Any?) -> Double { (x as! NSNumber).doubleValue }
        let tol = 0.0006 // fixture values are rounded to 3–4 decimals
        #expect(p.deciduous.state == d["state"] as? String, "\(id) state")
        #expect(abs(p.deciduous.leafFraction - n(d["leafFraction"])) <= tol)
        #expect(abs(p.deciduous.flowerFraction - n(d["flowerFraction"])) <= tol)
        // Decision 5 (Prompt 5) wraps the calendar: before the season-year start, colour and drop
        // carry on from December (1, 1) instead of the fixture's New Year reset (0, 0). What the
        // trees show (state, leaf fraction, palette weights) is unchanged.
        let rawDay = p.dayOfYear > 365 ? p.dayOfYear - 365 : p.dayOfYear
        let wrapped = profile.seasonYearWrapBelowDay == nil && rawDay < Phenology.seasonYearStart(profile) && p.dayOfYear > 365
        let colour = wrapped ? 1.0 : n(d["autumnColorFraction"]), drop = wrapped ? 1.0 : n(d["leafDropProgress"])
        #expect(abs(p.deciduous.autumnColorFraction - colour) <= tol)
        #expect(abs(p.deciduous.leafDropProgress - drop) <= tol)
        let w = d["paletteWeights"] as! [String: Any]
        #expect(abs(p.deciduous.paletteWeights.spring - n(w["spring"])) <= tol && abs(p.deciduous.paletteWeights.summer - n(w["summer"])) <= tol
                && abs(p.deciduous.paletteWeights.autumn - n(w["autumn"])) <= tol && abs(p.deciduous.paletteWeights.winter - n(w["winter"])) <= tol,
                "\(id) deciduous weights")
        #expect(abs(p.deciduous.paletteWeights.sum - 1) < 1e-12)
        let g = season["grass"] as! [String: Any]
        let gw = g["paletteWeights"] as! [String: Any]
        #expect(abs(p.grass.greenFraction - n(g["greenFraction"])) <= tol, "\(id) grass")
        #expect(p.grass.policy.rawValue == g["policy"] as? String)
        #expect(abs(p.grass.paletteWeights.spring - n(gw["spring"])) <= tol && abs(p.grass.paletteWeights.summer - n(gw["summer"])) <= tol
                && abs(p.grass.paletteWeights.winter - n(gw["winter"])) <= tol, "\(id) grass weights")
        #expect(abs(p.grass.paletteWeights.sum - 1) < 1e-12)
        #expect(p.evergreenLeafFraction == 1)
    }
}
