import Foundation
import Testing
@testable import WorldEnvironment
import WorldGeo

/// docs/proposals/weather-v1/weather-fixtures.json (read-only input): 10 real Denver-area cases.
enum WeatherFixtures {
    static let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("docs/proposals/weather-v1/weather-fixtures.json")
    static var json: [String: Any] { (try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]) ?? [:] }
    static var available: Bool { FileManager.default.fileExists(atPath: url.path) }

    static func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)!
    }

    static var station: GeoCoordinate {
        let l = json["location"] as! [String: Any]
        return GeoCoordinate(latitude: l["latitude"] as! Double, longitude: l["longitude"] as! Double)
    }

    /// The fixture's hourly history as normalized samples (METAR adapter).
    static func history(_ fixture: [String: Any], observations: [String: Any]) -> [WeatherSample] {
        let refs = (fixture["history"] as! [String: Any])["hourlyObservationRefs"] as! [String]
        return refs.map { ref in
            let raw = (observations[ref] as! [String: Any])["raw"] as! [String: String]
            return MetarAdapter.sample(raw, validTime: date(ref))
        }
    }

    /// The settled sample at the fixture time: its normalized values plus the WeatherKit analogue code.
    static func settledSample(_ fixture: [String: Any]) -> WeatherSample {
        let s = fixture["sourceWeatherNormalized"] as! [String: Any]
        func d(_ k: String) -> Double? { (s[k] as? NSNumber)?.doubleValue }
        let code = (fixture["weatherKitAnalogue_assumption"] as? String).flatMap(WeatherConditionCode.init(rawValue:))
        let t = date(fixture["timestampUTC"] as! String)
        let vis = d("visibilityM")
        let raw = observationRow(fixture)
        let metar = MetarAdapter.sample(raw, validTime: t)
        return WeatherSample(validTime: t, intervalStart: t.addingTimeInterval(-3600), intervalEnd: t, condition: code,
                             conditionRaw: raw["metar"], cloudCover01: d("cloudCover01"), temperatureC: d("temperatureC"),
                             humidity01: d("humidity01"), visibilityM: vis, visibilityReportingLimited: (vis ?? 0) >= 16093,
                             windSpeedMps: d("windSpeedMps"), windFromDegrees: d("windFromDegrees"), windGustMps: d("windGustMps"),
                             precipitationMm: d("hourPrecipLiquidEquivalentMm_reference"), phase: metar.phase,
                             frozenFraction: metar.frozenFraction)
    }

    static func observationRow(_ fixture: [String: Any]) -> [String: String] {
        let obs = json["hourlyObservations"] as! [String: Any]
        return (obs[fixture["sourceObservationRef"] as! String] as! [String: Any])["raw"] as! [String: String]
    }
}

@Suite("Weather fixtures (docs/proposals/weather-v1)")
struct WeatherFixtureTests {
    static var fixtures: [[String: Any]] { WeatherFixtures.available ? (WeatherFixtures.json["fixtures"] as! [[String: Any]]) : [] }
    static let ids: [String] = {
        guard let data = try? Data(contentsOf: WeatherFixtures.url),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        return (j["fixtures"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
    }()

    static func fixture(_ id: String) -> [String: Any] { fixtures.first { $0["id"] as? String == id }! }

    @Test(.enabled(if: WeatherFixtures.available), arguments: ids)
    func settledStateMatches(_ id: String) {
        let f = Self.fixture(id)
        let expected = f["expectedEngineState"] as! [String: Any]
        let r = WeatherClassifier.classify(WeatherFixtures.settledSample(f))
        #expect(r.dominantState?.rawValue == expected["dominantState"] as? String, "\(id) label")
        #expect(abs((r.intensity01 ?? -1) - (expected["intensity01"] as! NSNumber).doubleValue) <= 1e-5, "\(id) intensity \(r.intensity01 ?? -1)")
        // Primary accumulation is unknown without a checkpoint: null, never zero.
        #expect(expected["wetness01"] is NSNull && expected["snowCover01"] is NSNull)
        let unknown = SurfaceState.unknown(at: WeatherFixtures.date(f["timestampUTC"] as! String))
        let obs = WeatherFixtures.json["hourlyObservations"] as! [String: Any]
        let inputs = WeatherFixtures.history(f, observations: obs).map(MetarAdapter.accumulationInput)
        let primary = Accumulation.integrate(from: unknown, inputs: inputs, location: WeatherFixtures.station)
        #expect(primary.wetness01 == nil && primary.snowCover01 == nil && primary.status == .unknownInitialState)
    }

    @Test(.enabled(if: WeatherFixtures.available), arguments: ids)
    func windAndSunMatch(_ id: String) {
        let f = Self.fixture(id)
        let expected = f["expectedEngineState"] as! [String: Any]
        let w = expected["wind"] as! [String: Any]
        let s = WeatherFixtures.settledSample(f)
        let wind = WindModel.resolve(speedMps: s.windSpeedMps, fromDegrees: s.windFromDegrees, gustMps: s.windGustMps, cellSeed: 1)
        let v = (w["cappedTransportVectorMps"] as! [NSNumber]).map(\.doubleValue)
        #expect(abs(wind.transportVectorMps.x - v[0]) <= 1e-4 && abs(wind.transportVectorMps.z - v[2]) <= 1e-4, "\(id) wind vector")
        #expect(abs(wind.treeTipAmplitudeM - (w["treeTipBaseAmplitudeM"] as! NSNumber).doubleValue) <= 1e-5, "\(id) tip amplitude")
        let sun = expected["sun"] as! [String: Any]
        let p = SolarPosition(date: WeatherFixtures.date(f["timestampUTC"] as! String), at: WeatherFixtures.station)
        #expect(abs(p.elevation - (sun["elevationDegrees"] as! Double)) <= 0.05 && abs(p.azimuth - (sun["azimuthDegrees"] as! Double)) <= 0.05,
                "\(id) sun")
    }

    /// The controlled-model reference runs (W=0/S=0 and W=1/S=100) over the 48–72 h histories.
    @Test(.enabled(if: WeatherFixtures.available), arguments: ids)
    func accumulationReferenceRunsMatch(_ id: String) {
        let f = Self.fixture(id)
        let ref = f["controlledModelReference_assumption"] as! [String: Any]
        let alt = ref["alternativeInitialStateRun"] as! [String: Any]
        let obs = WeatherFixtures.json["hourlyObservations"] as! [String: Any]
        let samples = WeatherFixtures.history(f, observations: obs)
        let inputs = samples.map(MetarAdapter.accumulationInput)
        let start = inputs.first!.start
        let a = Accumulation.integrate(from: .assumedReference(wetness: 0, snowWaterEquivalentMm: 0, at: start), inputs: inputs,
                                       location: WeatherFixtures.station)
        let b = Accumulation.integrate(from: .assumedReference(wetness: 1, snowWaterEquivalentMm: 100, at: start), inputs: inputs,
                                       location: WeatherFixtures.station)
        func v(_ d: [String: Any], _ k: String) -> Double { (d[k] as! NSNumber).doubleValue }
        let tol = 1e-4
        #expect(abs(a.wetness01! - v(ref, "wetness01")) <= tol, "\(id) W ref")
        #expect(abs(a.snowWaterEquivalentMm! - v(ref, "snowWaterEquivalentMm")) <= tol, "\(id) S ref")
        #expect(abs(a.snowCover01! - v(ref, "snowCover01")) <= tol, "\(id) cover ref")
        #expect(abs(a.lastIntervalMeltMm! - v(ref, "lastHourMeltMm")) <= tol, "\(id) melt ref")
        #expect(abs(b.wetness01! - v(alt, "wetness01")) <= tol, "\(id) W alt")
        #expect(abs(b.snowWaterEquivalentMm! - v(alt, "snowWaterEquivalentMm")) <= tol, "\(id) S alt")
        #expect(abs(b.snowCover01! - v(alt, "snowCover01")) <= tol, "\(id) cover alt")
        // History metadata: trace hours and hours whose phase was reconstructed (no weather code).
        let h = f["history"] as! [String: Any]
        #expect(samples.filter { $0.flags.contains("traceAssumed") }.count == (h["traceHours"] as! Int))
        let inferred = zip(samples, (h["hourlyObservationRefs"] as! [String])).filter { s, ref in
            let raw = (obs[ref] as! [String: Any])["raw"] as! [String: String]
            return (s.precipitationMm ?? 0) > 0 && raw["wxcodes"] == "M"
        }.count
        #expect(inferred == (h["hoursWithInferredPrecipPhase"] as! Int))
    }

    /// Seeking to an hour boundary reproduces the full integration; a mid-hour seek uses the hour's
    /// share of precipitation and stays between the neighbouring hourly states.
    @Test(.enabled(if: WeatherFixtures.available))
    func seekingIsDeterministic() {
        let f = Self.fixture("first-snow")
        let obs = WeatherFixtures.json["hourlyObservations"] as! [String: Any]
        let inputs = WeatherFixtures.history(f, observations: obs).map(MetarAdapter.accumulationInput)
        let start = SurfaceState.assumedReference(wetness: 0, snowWaterEquivalentMm: 0, at: inputs.first!.start)
        let full = Accumulation.integrate(from: start, inputs: inputs, location: WeatherFixtures.station)
        let seek = Accumulation.state(at: inputs.last!.end, from: start, inputs: inputs, location: WeatherFixtures.station)
        #expect(seek == full)
        let mid = inputs[40].start.addingTimeInterval(1800)
        let s1 = Accumulation.state(at: mid, from: start, inputs: inputs, location: WeatherFixtures.station)
        let s2 = Accumulation.state(at: mid, from: start, inputs: inputs, location: WeatherFixtures.station)
        #expect(s1 == s2 && s1.time == mid)
    }
}
