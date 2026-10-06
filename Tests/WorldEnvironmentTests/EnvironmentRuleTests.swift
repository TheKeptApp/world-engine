import Foundation
import Testing
@testable import WorldEnvironment
import WorldGen
import WorldGeo

private let t0 = Date(timeIntervalSince1970: 1_790_000_000)

@Suite("Normalization catches unit errors")
struct NormalizationTests {
    @Test func precipitationRateThroughUnits() {
        // 0.762 mm/h expressed in m/s, km/h and mm/s all normalize to the same mm/hour.
        let mmPerHourInMps = 0.762 / 3_600_000
        #expect(abs(Normalize.millimetersPerHour(Measurement(value: mmPerHourInMps, unit: .metersPerSecond))! - 0.762) < 1e-9)
        // Foundation's km/h factor is 0.277778 (rounded), hence the looser bound.
        #expect(abs(Normalize.millimetersPerHour(Measurement(value: mmPerHourInMps * 3.6, unit: .kilometersPerHour))! - 0.762) < 1e-5)
        // The classic slip: reading "0.762" as if it were already m/s is 2.7 million mm/h → rejected.
        #expect(Normalize.millimetersPerHour(Measurement(value: 0.762, unit: .metersPerSecond)) == nil)
    }

    @Test func amountsLengthsAndFractions() {
        #expect(abs(Normalize.millimeters(Measurement(value: 0.000762, unit: .meters))! - 0.762) < 1e-9)
        #expect(Normalize.millimeters(Measurement(value: 762, unit: .meters)) == nil) // 1,000,000× too large
        #expect(abs(Normalize.visibilityMeters(Measurement(value: 0.5, unit: .miles))! - 804.672) < 1e-6)
        #expect(Normalize.visibilityMeters(Measurement(value: 804_672, unit: .kilometers)) == nil)
        #expect(abs(Normalize.celsius(Measurement(value: 65, unit: .fahrenheit))! - 18.333333) < 1e-5)
        #expect(Normalize.celsius(Measurement(value: 291, unit: .celsius)) == nil) // kelvin read as Celsius
        #expect(abs(Normalize.metersPerSecond(Measurement(value: 28, unit: .knots))! - 14.404444) < 1e-4) // Foundation knot = 0.514444 m/s
        #expect(Normalize.fraction(0.75) == 0.75 && Normalize.fraction(75) == nil)
    }
}

@Suite("Condition mapping and resolution order")
struct ConditionTests {
    func sample(_ code: WeatherConditionCode?, rate: Double? = nil, phase: PrecipitationPhase? = nil, frozen: Double? = nil,
                cloud: Double? = nil, visibility: Double? = nil) -> WeatherSample {
        WeatherSample(validTime: t0, condition: code, cloudCover01: cloud, visibilityM: visibility, precipitationRateMmPerHour: rate,
                      phase: phase, frozenFraction: frozen)
    }

    @Test func all34CodesMap() {
        #expect(WeatherConditionCode.allCases.count == 34)
        for code in WeatherConditionCode.allCases {
            let r = WeatherClassifier.classify(sample(code))
            #expect(r.dominantState != nil && (0...1).contains(r.intensity01 ?? -1), "\(code)")
        }
    }

    @Test func freezingRainNeverBecomesSnow() {
        let r = WeatherClassifier.classify(sample(.freezingRain, rate: 1, phase: .frozen, frozen: 1))
        #expect(r.dominantState == .rain && r.flags.contains("freezing"))
    }

    @Test func stormWithoutLocalRainStaysStormWithoutParticles() {
        let r = WeatherClassifier.classify(sample(.thunderstorms, rate: 0, phase: .liquid, frozen: 0))
        #expect(r.dominantState == .thunderstorm && r.intensity01 == 0.70)
        let p = ParticleBudget.resolve(state: r.dominantState, intensity: 0, liquidShare: 1, leafDropRate: 0, aerial: false)
        #expect(p.rain == 0 && p.snow == 0)
    }

    @Test func measuredPrecipitationOverridesCloudLabelAboveThreshold() {
        #expect(WeatherClassifier.classify(sample(.cloudy, rate: 0.5, phase: .liquid, frozen: 0, cloud: 1)).dominantState == .rain)
        #expect(WeatherClassifier.classify(sample(.cloudy, rate: 0.05, phase: .liquid, frozen: 0, cloud: 1)).dominantState == .cloudy)
        // Leaving needs < 0.05 once raining.
        #expect(WeatherClassifier.classify(sample(.cloudy, rate: 0.07, phase: .liquid, frozen: 0, cloud: 1), previous: .rain).dominantState == .rain)
    }

    @Test func windLabelCloudHysteresis() {
        #expect(WeatherClassifier.classify(sample(.windy, cloud: 0.7)).dominantState == .cloudy)
        #expect(WeatherClassifier.classify(sample(.windy, cloud: 0.6)).dominantState == .clear)
        #expect(WeatherClassifier.classify(sample(.windy, cloud: 0.6), previous: .cloudy).dominantState == .cloudy)
        #expect(WeatherClassifier.classify(sample(.windy, cloud: 0.5), previous: .cloudy).dominantState == .clear)
    }

    @Test func missingQuantitiesUseDefaultsWithFlag() {
        let r = WeatherClassifier.classify(sample(.rain))
        #expect(r.intensity01 == 0.50 && r.assumedIntensity && r.flags.contains("assumedIntensity"))
        let u = WeatherClassifier.classify(WeatherSample(validTime: t0))
        #expect(u.dominantState == nil && u.displayFallback == .clear) // unknown, labeled neutral fallback
    }

    @Test func codePhaseConflictIsKept() {
        let r = WeatherClassifier.classify(sample(.rain, rate: 1, phase: .frozen, frozen: 1))
        #expect(r.conflict && r.dominantState == .rain)
    }
}

@Suite("Accumulation rules")
struct AccumulationRuleTests {
    let denver = GeoCoordinate(latitude: 39.74, longitude: -104.99)
    func hour(_ k: Int, p: Double?, f: Double?, t: Double? = -3, hail: Bool = false) -> AccumulationInput {
        AccumulationInput(start: t0.addingTimeInterval(Double(k) * 3600), end: t0.addingTimeInterval(Double(k + 1) * 3600),
                          temperatureC: t, windSpeedMps: 2, humidity01: 0.8, cloudCover01: 1, precipitationMm: p, frozenFraction: f, isHail: hail)
    }

    @Test func blowingSnowAddsNoSnowfall() {
        // A blowing-snow label without an independent amount contributes zero precipitation.
        let s = WeatherSample(validTime: t0, condition: .blowingSnow, precipitationMm: 0)
        let r = WeatherClassifier.classify(s)
        #expect(r.flags.contains("blowingSnowNoNewSnowfall"))
        let out = Accumulation.integrate(from: .assumedReference(wetness: 0, snowWaterEquivalentMm: 0, at: t0), inputs: [hour(0, p: 0, f: nil)],
                                         location: denver)
        #expect(out.snowWaterEquivalentMm == 0)
    }

    @Test func hailDoesNotBuildSnow() {
        let out = Accumulation.integrate(from: .assumedReference(wetness: 0, snowWaterEquivalentMm: 0, at: t0),
                                         inputs: [hour(0, p: 5, f: 1, hail: true)], location: denver)
        #expect(out.snowWaterEquivalentMm == 0 && (out.wetness01 ?? 0) > 0.5)
    }

    @Test func gapsAndMissingInputsStayUnknown() {
        let start = SurfaceState.assumedReference(wetness: 0.3, snowWaterEquivalentMm: 2, at: t0)
        let gap = Accumulation.integrate(from: start, inputs: [hour(0, p: 0, f: 0), hour(2, p: 0, f: 0)], location: denver)
        #expect(gap.wetness01 == nil && gap.status == .gapInvalidated)
        let missingT = Accumulation.integrate(from: start, inputs: [hour(0, p: 0, f: 0, t: nil)], location: denver)
        #expect(missingT.wetness01 == nil)
        let missingPhase = Accumulation.integrate(from: start, inputs: [hour(0, p: 1, f: nil)], location: denver)
        #expect(missingPhase.snowWaterEquivalentMm == nil)
        let unknown = Accumulation.integrate(from: .unknown(at: t0), inputs: [hour(0, p: 3, f: 1)], location: denver)
        #expect(unknown.wetness01 == nil && unknown.status == .unknownInitialState)
    }

    @Test func snowRetentionAndCoverage() {
        // All snow retained at ≤ 0 °C; S = 6 mm covers ≈ 63% of eligible surface.
        let out = Accumulation.integrate(from: .assumedReference(wetness: 0, snowWaterEquivalentMm: 0, at: t0),
                                         inputs: [hour(0, p: 6, f: 1, t: -5)], location: denver)
        #expect(abs(out.snowWaterEquivalentMm! - 6) < 0.3)
        #expect(abs(SurfaceState(wetness01: 0, snowWaterEquivalentMm: 6, lastIntervalMeltMm: 0, time: t0, status: .modeled,
                                 initialization: .unknown).snowCover01! - (1 - exp(-1))) < 1e-12)
    }

    @Test func dryingHalfLifeExample() {
        // Spec example: T = 10 °C, U = 3, J = 0.5, H = 0.5 → d = 0.16875 / h (half-life ≈ 4.11 h).
        let d = (0.04 + 0.008 * 10 + 0.015 * 3 + 0.12 * 0.5) * (1 - 0.5 * 0.5)
        #expect(abs(d - 0.16875) < 1e-12 && abs(log(2) / d - 4.1075) < 1e-3)
    }
}

@Suite("Wind and transitions")
struct WindTransitionTests {
    @Test func northWindTravelsTowardPlusZ() {
        let v = WindModel.transport(speed: 5, fromDegrees: 0)
        #expect(abs(v.x) < 1e-12 && abs(v.z - 5) < 1e-12)
    }

    @Test func wrapAroundBlendsAsVectors() {
        // 359° → 1°: the blended vector stays short-path (no swing through south).
        let a = WindModel.resolve(speedMps: 5, fromDegrees: 359, gustMps: nil, cellSeed: 1)
        let b = WindModel.resolve(speedMps: 5, fromDegrees: 1, gustMps: nil, cellSeed: 1)
        let mid = a.transportVectorMps + (b.transportVectorMps - a.transportVectorMps) * 0.5
        #expect(mid.z > 4.99 && abs(mid.x) < 1e-9)
    }

    @Test func variableDirectionIsStableAndFlagged() {
        let a = WindModel.resolve(speedMps: 3, fromDegrees: nil, gustMps: nil, cellSeed: 42)
        let b = WindModel.resolve(speedMps: 3, fromDegrees: nil, gustMps: nil, cellSeed: 42)
        #expect(a.directionAssumed && a.displayFromDegrees == b.displayFromDegrees)
        #expect(WindModel.resolve(speedMps: 30, fromDegrees: 90, gustMps: 40, cellSeed: 1).treeTipAmplitudeM == 0.03)
    }

    func s(_ code: WeatherConditionCode, _ minutes: Double, cloud: Double = 0.2, rate: Double? = nil) -> WeatherSample {
        WeatherSample(validTime: t0.addingTimeInterval(minutes * 60), condition: code, cloudCover01: cloud, windSpeedMps: 3,
                      windFromDegrees: 90, precipitationRateMmPerHour: rate, phase: rate == nil ? nil : .liquid, frozenFraction: rate == nil ? nil : 0)
    }

    @Test func liveHoldAndImmediatePrecipitation() {
        var live = LiveWeatherTracker()
        let wind = WindModel.resolve(speedMps: 3, fromDegrees: 90, gustMps: nil, cellSeed: 1)
        live.ingest(s(.clear, 0), wind: wind, now: 0, baseFogStart: 350, baseFogEnd: 1100)
        #expect(live.acceptedLabel == .clear)
        live.ingest(s(.cloudy, 30, cloud: 1), wind: wind, now: 10, baseFogStart: 350, baseFogEnd: 1100)
        _ = live.display(now: 60, baseFogStart: 350, baseFogEnd: 1100)
        #expect(live.acceptedLabel == .clear) // still a candidate (< 90 s)
        _ = live.display(now: 101, baseFogStart: 350, baseFogEnd: 1100)
        #expect(live.acceptedLabel == .cloudy)
        // Stale (older) samples are ignored; precipitation enters at once.
        let acceptedStale = live.ingest(s(.clear, 10), wind: wind, now: 110, baseFogStart: 350, baseFogEnd: 1100)
        #expect(!acceptedStale)
        live.ingest(s(.rain, 60, cloud: 1, rate: 2), wind: wind, now: 120, baseFogStart: 350, baseFogEnd: 1100)
        #expect(live.acceptedLabel == .rain)
        let start = live.display(now: 120, baseFogStart: 350, baseFogEnd: 1100)!
        let settled = live.display(now: 140, baseFogStart: 350, baseFogEnd: 1100)!
        #expect(start.rainIntensity < settled.rainIntensity && settled.rainIntensity > 0.4)
    }

    @Test func recapIsAPureFunctionOfSourceTime() {
        var hourly: [WeatherSample] = []
        for k in 0..<4 {
            let dry = k < 2
            let start = t0.addingTimeInterval(Double(k) * 3600), end = t0.addingTimeInterval(Double(k + 1) * 3600)
            let code: WeatherConditionCode = dry ? .clear : .rain
            let cloud: Double = dry ? 0.1 : 1
            let amount: Double = dry ? 0 : 2
            hourly.append(WeatherSample(validTime: end, intervalStart: start, intervalEnd: end, condition: code, cloudCover01: cloud,
                                        precipitationMm: amount, phase: .liquid, frozenFraction: 0))
        }
        let recap = RecapTimeline(samples: hourly, cellSeed: 1) { _ in (350, 1100) }
        let boundary = t0.addingTimeInterval(2 * 3600)
        let before = recap.appearance(at: boundary.addingTimeInterval(-61))!
        let middle = recap.appearance(at: boundary)!
        let after = recap.appearance(at: boundary.addingTimeInterval(61))!
        #expect(before.rainIntensity == 0 && after.rainIntensity > 0)
        #expect(middle.rainIntensity > 0 && middle.rainIntensity < after.rainIntensity) // centred 120 s window
        #expect(recap.appearance(at: boundary) == middle) // seeks repeat exactly
    }
}

@Suite("Sky boundaries")
struct SkyBoundaryTests {
    @Test func polarDayAndNight() throws {
        let tromso = SkyObserver(latitude: 69.65, longitude: 18.96, timeZoneID: "Europe/Oslo")
        let summer = try #require(SunEvents.day(containing: Date(timeIntervalSince1970: 1_782_043_200), observer: tromso)) // 2026-06-21
        #expect(summer.status == .alwaysAbove && summer.sunrise.isEmpty && summer.daylightSeconds > 86_000)
        let winter = try #require(SunEvents.day(containing: Date(timeIntervalSince1970: 1_797_854_400), observer: tromso)) // 2026-12-21
        #expect(winter.status == .alwaysBelow && winter.daylightSeconds == 0)
        // Never a fabricated golden hour in polar summer's continuous day.
        let next = SunEvents.nextGoldenHour(after: Date(timeIntervalSince1970: 1_782_043_200), observer: tromso, searchDays: 3)
        #expect(next.status == .notFoundWithinHorizon || next.interval != nil)
    }

    @Test func timezoneDaysAndLeapDay() throws {
        let denver = SkyObserver(latitude: 39.7392, longitude: -104.9903, timeZoneID: "America/Denver")
        let f = ISO8601DateFormatter()
        for (s, hours) in [("2026-03-08T18:00:00Z", 23.0), ("2026-11-01T18:00:00Z", 25.0), ("2028-02-29T18:00:00Z", 24.0)] {
            let day = try #require(SunEvents.day(containing: f.date(from: s)!, observer: denver))
            #expect(day.dayEnd.timeIntervalSince(day.dayStart) == hours * 3600, "\(s)")
            #expect(day.sunrise.count == 1 && day.sunset.count == 1)
        }
    }

    @Test func nextGoldenHourActiveAndUpcoming() throws {
        let denver = SkyObserver(latitude: 39.7392, longitude: -104.9903, timeZoneID: "America/Denver")
        let fixture = ISO8601DateFormatter().date(from: "2026-10-15T23:44:01Z")! // sun 6.0° setting: start of the evening interval
        let active = SunEvents.nextGoldenHour(after: fixture.addingTimeInterval(600), observer: denver)
        #expect(active.status == .active && active.secondsUntilStart == 0)
        let upcoming = SunEvents.nextGoldenHour(after: fixture.addingTimeInterval(600), observer: denver, includeActive: false)
        #expect(upcoming.status == .upcoming && (upcoming.secondsUntilStart ?? 0) > 3600)
    }
}

@Suite("Stars")
struct StarTests {
    @Test func catalogIsTheLicensedSubset() throws {
        let c = try StarCatalog.bundled()
        #expect(c.stars.count == 256 && c.count == 256)
        #expect(c.source.license == "CC BY-SA 4.0" && c.source.author.contains("David Nash"))
        // Sorted by unrounded magnitude, then ID; stored magnitudes are rounded to 0.001.
        #expect(zip(c.stars, c.stars.dropFirst()).allSatisfy { $0.mag <= $1.mag + 0.001 })
        let names = Set(c.stars.compactMap(\.name))
        for star in ["Betelgeuse", "Rigel", "Bellatrix", "Mintaka", "Alnilam", "Alnitak", "Saiph",
                     "Dubhe", "Merak", "Phecda", "Megrez", "Alioth", "Mizar", "Alkaid", "Acrux", "Mimosa", "Gacrux"] {
            #expect(names.contains(star), "\(star)")
        }
    }

    @Test func nightFieldIsCappedAndGated() throws {
        let c = try StarCatalog.bundled()
        let denver = SkyObserver(latitude: 39.7392, longitude: -104.9903, timeZoneID: "America/Denver")
        let night = ISO8601DateFormatter().date(from: "2026-01-04T05:00:00Z")! // 22:00 MST, Orion high
        let strength = Stars.strength(sunElevationDeg: -40, cloud: 0, obscuration: 0, moonFill: 0, activePrecipitation: false)
        let field = Stars.field(c, at: night, observer: denver, strength: strength)
        #expect(strength == 1 && field.visible.count <= Stars.maxVisible && field.visible.count > 80)
        #expect(field.visible.contains { $0.id == c.stars.first { $0.name == "Rigel" }!.id })
        #expect(Stars.strength(sunElevationDeg: -40, cloud: 0, obscuration: 0, moonFill: 0, activePrecipitation: true) == 0)
        #expect(Stars.strength(sunElevationDeg: -3, cloud: 0, obscuration: 0, moonFill: 0, activePrecipitation: false) == 0)
        #expect(Stars.strength(sunElevationDeg: -40, cloud: nil, obscuration: 0, moonFill: 0, activePrecipitation: false) == 0)
    }
}

@Suite("Weather cells, refresh and cache")
struct ProviderPolicyTests {
    @Test func cellCentersAndSize() {
        let cell = WeatherCell(containing: GeoCoordinate(latitude: 39.7494, longitude: -105.0445))
        #expect(abs(cell.center.latitude - 39.725) < 1e-9 && abs(cell.center.longitude - (-105.025)) < 1e-9)
        #expect(cell == WeatherCell(containing: cell.center))
        // ≈ 5.6 km north–south × 4.3 km east–west at Denver.
        let ns = WeatherCell.stepDegrees * 111_320, ew = WeatherCell.stepDegrees * 111_320 * cos(39.73 * .pi / 180)
        #expect(abs(ns - 5566) < 10 && abs(ew - 4280) < 20)
        #expect(WeatherCell(containing: GeoCoordinate(latitude: 0, longitude: 180)).j == WeatherCell(containing: GeoCoordinate(latitude: 0, longitude: -180)).j)
    }

    @Test func cellSwitchWaitsForDepthOrDwell() {
        var policy = CellSwitchPolicy()
        let a = GeoCoordinate(latitude: 39.7499, longitude: -105.0001)
        let start = policy.update(position: a, at: t0)
        let justAcross = GeoCoordinate(latitude: 39.7501, longitude: -105.0001)
        #expect(policy.update(position: justAcross, at: t0.addingTimeInterval(10)) == start)
        #expect(policy.update(position: justAcross, at: t0.addingTimeInterval(71)) != start)
    }

    @Test func cacheIsShortLivedAndMemoryOnly() {
        var cache = TemporaryWeatherCache()
        let cell = WeatherCell(i: 1, j: 2)
        let s = WeatherSample(validTime: t0)
        cache.store(s, for: cell, fetchedAt: t0, changing: false)
        let fresh = cache.lookup(cell, now: t0.addingTimeInterval(29 * 60))
        let stale = cache.lookup(cell, now: t0.addingTimeInterval(90 * 60))
        let gone = cache.lookup(cell, now: t0.addingTimeInterval(121 * 60))
        #expect(fresh == .fresh(s) && stale == .stale(s) && gone == .none)
        #expect(cache.count == 0)
        cache.store(s, for: cell, fetchedAt: t0, changing: true)
        let changing = cache.lookup(cell, now: t0.addingTimeInterval(16 * 60))
        #expect(changing == .stale(s))
    }

    @Test func historyWindowsAreAtMost240Hours() {
        let w = RefreshPolicy.historyWindows(from: t0, to: t0.addingTimeInterval(500 * 3600))
        #expect(w.count == 3 && w.allSatisfy { $0.duration <= 240 * 3600 })
        #expect(RefreshPolicy.nextRefresh(after: t0, active: false, changingPrecipitation: false) == nil)
        #expect(RefreshPolicy.nextRefresh(after: t0, active: true, changingPrecipitation: true) == t0.addingTimeInterval(900))
    }

    @Test func mockProviderReplaysAndRefusesLongWindows() async throws {
        let samples = (0..<5).map { WeatherSample(validTime: t0.addingTimeInterval(Double($0) * 3600)) }
        let mock = MockWeatherProvider(samples: samples, now: t0.addingTimeInterval(2.5 * 3600))
        let cell = WeatherCell(i: 0, j: 0)
        #expect(try await mock.current(for: cell).validTime == t0.addingTimeInterval(2 * 3600))
        #expect(try await mock.hourly(for: cell, from: t0, to: t0.addingTimeInterval(4 * 3600)).count == 4)
        await #expect(throws: WeatherProviderError.self) {
            _ = try await mock.hourly(for: cell, from: t0, to: t0.addingTimeInterval(241 * 3600))
        }
    }
}

@Suite("Environment document")
struct EnvironmentDocumentTests {
    @Test func unknownsSerializeAsNullAndRoundTrip() throws {
        let observer = SkyObserver(latitude: 39.7494, longitude: -105.0445, elevationM: 1600, timeZoneID: "America/Denver")
        let resolver = EnvironmentResolver(observer: observer, tables: try StyleLibrary.lighting(), stars: try StarCatalog.bundled(),
                                           phenologyProfile: .denverDemo)
        let at = ISO8601DateFormatter().date(from: "2026-10-15T23:44:01Z")!
        let sample = WeatherSample(validTime: at, condition: .mostlyClear, cloudCover01: 0.2, temperatureC: 12, humidity01: 0.4,
                                   visibilityM: 16_000, visibilityReportingLimited: true, windSpeedMps: 3, windFromDegrees: 250)
        let cell = WeatherCell(containing: observer.coordinate)
        let doc = resolver.resolve(.init(time: at, mode: .demo, sample: sample, cell: cell, surface: .unknown(at: at), provider: "fixture"))
        let data = try doc.json()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"wetness01\" : null") && text.contains("\"snowCover01\" : null"))
        #expect(doc.state.dominantState == .clear && doc.state.accumulationStatus == "unknown_initial_state")
        #expect(abs(doc.light.sunElevationDeg - 6.0011) < 0.01 && doc.light.branch == "setting")
        #expect(doc.phenology?.deciduous.state == "autumn_peak")
        #expect(doc.sky.starAttribution.contains("CC BY-SA"))
        let back = try EnvironmentDocument.decode(data)
        #expect(try back.json() == data) // ISO 8601 keeps whole seconds; the re-encoded document is identical
        var bad = doc
        bad.schemaVersion = "worldengine.environment/2"
        #expect(throws: (any Error).self) { _ = try EnvironmentDocument.decode(try bad.json()) }
    }

    @Test func blowingSnowNeedsGroundSnowForParticles() throws {
        let observer = SkyObserver(latitude: 39.74, longitude: -104.99, timeZoneID: "America/Denver")
        let resolver = EnvironmentResolver(observer: observer, tables: try StyleLibrary.lighting())
        let at = ISO8601DateFormatter().date(from: "2026-01-10T18:00:00Z")!
        let sample = WeatherSample(validTime: at, condition: .blowingSnow, cloudCover01: 0.5, temperatureC: -8, visibilityM: 1500, windSpeedMps: 12)
        let bare = resolver.resolve(.init(time: at, mode: .demo, sample: sample, cell: nil, surface: .unknown(at: at), includeEvents: false))
        #expect(bare.presentation.particles.snow == 0 && bare.state.dominantState == .snow)
        let snowy = resolver.resolve(.init(time: at, mode: .demo, sample: sample, cell: nil,
                                           surface: .assumedReference(wetness: 0, snowWaterEquivalentMm: 10, at: at), includeEvents: false))
        #expect(snowy.presentation.particles.snow > 0)
    }

    @Test func perTreeOffsetsAreStable() {
        var a = StableRandom(2, 123_456, salt: Phenology.timingSalt)
        var b = StableRandom(2, 123_456, salt: Phenology.timingSalt)
        let sa = Phenology.treeShiftDays(&a), sb = Phenology.treeShiftDays(&b)
        #expect(sa == sb && abs(sa) <= 7)
        let late = Phenology.resolve(dayOfYear: 290, profile: .denverDemo, treeShiftDays: 7)
        let early = Phenology.resolve(dayOfYear: 290, profile: .denverDemo, treeShiftDays: -7)
        #expect(late.autumnColorFraction < early.leafDropProgress + 1 && late.drop <= early.drop)
    }

    /// Decision 5: the calendar wraps; nothing resets on January 1 (Seattle's grass dormancy runs
    /// to day 380 = Jan 15 and used to snap back to its floor on New Year's Day).
    @Test(arguments: [PhenologyProfile.denverDemo, .planoDemo, .seattleDemo, .sydneyDemo])
    func newYearIsContinuous(profile: PhenologyProfile) {
        let tz = TimeZone(identifier: "America/Denver")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let dec31 = cal.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 12))!
        let jan1 = cal.date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 12))!
        let a = Phenology.resolve(at: dec31, timeZone: tz, profile: profile)
        let b = Phenology.resolve(at: jan1, timeZone: tz, profile: profile)
        #expect(abs(b.dayOfYear - a.dayOfYear - 1) < 1e-9, "Jan 1 follows Dec 31 on the season-year")
        for (x, y) in [(a.deciduous.paletteWeights, b.deciduous.paletteWeights), (a.grass.paletteWeights, b.grass.paletteWeights)] {
            #expect(abs(x.spring - y.spring) < 0.05 && abs(x.summer - y.summer) < 0.05 && abs(x.autumn - y.autumn) < 0.05 && abs(x.winter - y.winter) < 0.05)
        }
        #expect(abs(a.grass.greenFraction - b.grass.greenFraction) < 0.05)
    }
}

@Suite("Weather data")
struct WeatherDataTests {
    @Test func presetsComeFromWeatherJSON() throws {
        let table = try StyleLibrary.weather()
        #expect(table.version == 2 && Set(table.states.keys) == Set(DominantState.allCases.map(\.rawValue)))
        let rain = AtmospherePreset.of(.rain)
        #expect(rain.tint == "#8F9FAA" && rain.tintWeight == 0.22 && rain.directMultiplier == 0.18)
        #expect(AtmospherePreset.of(.fog).absoluteFog?.aerialEnd == 600)
        // Direct light uses the minimum of the cloud factor and the label factor, never their product.
        let r = Atmosphere.resolve(state: .rain, intensity: 1, cloud: 1, visibilityM: nil, visibilityReportingLimited: false,
                                   baseFogStart: 350, baseFogEnd: 1100, aerial: false, sunFloor: false)
        #expect(abs(r.directMultiplier - 0.18) < 1e-12 && abs(r.fogStartM - 140) < 1e-9 && abs(r.fogEndM - 550) < 1e-9)
        // Visibility caps the fog (end ≤ V, start ≤ 0.1 V) with readability floors.
        let v = Atmosphere.resolve(state: .haze, intensity: 0.5, cloud: 0.2, visibilityM: 300, visibilityReportingLimited: false,
                                   baseFogStart: 350, baseFogEnd: 1100, aerial: false, sunFloor: false)
        #expect(v.fogEndM == 300 && v.fogStartM == 30)
    }
}
