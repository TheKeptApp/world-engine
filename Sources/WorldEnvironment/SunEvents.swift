import Foundation
import WorldGeo

/// The world's astronomical reference point (not a weather cell, never a private address).
public struct SkyObserver: Codable, Sendable, Equatable {
    public var latitude: Double
    /// East-positive longitude, degrees.
    public var longitude: Double
    public var elevationM: Double
    /// IANA timezone identifier (display/calendar context, never the clock itself).
    public var timeZoneID: String

    public init(latitude: Double, longitude: Double, elevationM: Double = 0, timeZoneID: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevationM = elevationM
        self.timeZoneID = timeZoneID
    }

    public var coordinate: GeoCoordinate { GeoCoordinate(latitude: latitude, longitude: longitude) }
    public var timeZone: TimeZone? { TimeZone(identifier: timeZoneID) }
}

public struct SunCrossing: Codable, Sendable, Equatable {
    public var utc: Date
    public var branch: Branch
    public enum Branch: String, Codable, Sendable { case rising, setting }
}

public struct SunInterval: Codable, Sendable, Equatable {
    public var branch: SunCrossing.Branch
    public var start: Date
    public var end: Date
}

/// One local civil day of sun events (sky-seasons spec §2).
public struct SunDay: Codable, Sendable, Equatable {
    public var dayStart: Date
    public var dayEnd: Date
    public var sunrise: [SunCrossing]
    public var sunset: [SunCrossing]
    public var civilDawn: [SunCrossing]
    public var civilDusk: [SunCrossing]
    public var nauticalDawn: [SunCrossing]
    public var nauticalDusk: [SunCrossing]
    /// Upper transits (hour angle 0).
    public var solarNoon: [Date]
    public var dailyMaximumElevation: Double
    public var dailyMaximumTime: Date
    public var goldenHourIntervals: [SunInterval]
    public var blueHourIntervals: [SunInterval]
    /// Total time with center elevation ≥ −0.833333° within the civil day.
    public var daylightSeconds: Double
    public var status: Status

    public enum Status: String, Codable, Sendable {
        case normal
        case alwaysAbove = "always_above"
        case alwaysBelow = "always_below"
        case grazing
        case noCrossingThisDay = "no_crossing_this_day"
        case unsupportedDate = "unsupported_date"
        case unknown
    }
}

public enum SunEvents {
    public static let sunriseElevation = -0.833333
    public static let civil = -6.0, nautical = -12.0
    public static let goldenLow = -4.0, goldenHigh = 6.0
    public static let model = "noaa-geometric-v1 (SolarPosition.swift)"
    /// Supported accuracy window.
    public static let supportedYears = 1950...2050

    public static func elevation(_ t: Date, _ c: GeoCoordinate) -> Double { SolarPosition(date: t, at: c).elevation }

    /// Civil day [start, end) containing `instant` in the observer's timezone (DST-aware).
    public static func civilDay(containing instant: Date, timeZone: TimeZone) -> (start: Date, end: Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let start = cal.startOfDay(for: instant)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return (start, end)
    }

    /// All sun events of the local civil day that contains `instant`.
    public static func day(containing instant: Date, observer: SkyObserver) -> SunDay? {
        guard let tz = observer.timeZone else { return nil }
        let (start, end) = civilDay(containing: instant, timeZone: tz)
        let c = observer.coordinate
        let year = Calendar(identifier: .gregorian).component(.year, from: instant)
        let e: (Date) -> Double = { elevation($0, c) }

        func crossings(_ threshold: Double) -> [SunCrossing] {
            Roots.crossings(of: { e($0) - threshold }, from: start, to: end, step: 600).map {
                SunCrossing(utc: $0.time, branch: $0.rising ? .rising : .setting)
            }
        }
        let rise = crossings(sunriseElevation)
        let civilX = crossings(civil), nauticalX = crossings(nautical)
        // Upper transit: hour angle crosses 0 upward (not the ±180° wrap).
        let transits = Roots.crossings(of: { t in
            let terms = SolarPosition.terms(at: t)
            return SolarPosition.hourAngle(at: t, longitude: c.longitude, equationOfTime: terms.equationOfTime)
        }, from: start, to: end, step: 600, rejectJumpsAbove: 90).filter(\.rising).map(\.time)
        // Daily maximum (optimised separately; declination changes during the day).
        let (maxTime, maxElevation) = Roots.maximum(of: e, from: start, to: end, step: 600)

        // Golden/blue intervals from all breakpoints, classified by midpoint elevation and slope.
        var breaks = [start, end]
        for th in [civil, goldenLow, goldenHigh, sunriseElevation] {
            breaks += Roots.crossings(of: { e($0) - th }, from: start, to: end, step: 600).map(\.time)
        }
        breaks += Roots.extrema(of: e, from: start, to: end, step: 600)
        breaks.sort()
        var golden: [SunInterval] = [], blue: [SunInterval] = []
        var daylight = 0.0
        for (a, b) in zip(breaks, breaks.dropFirst()) where b.timeIntervalSince(a) > 0.5 {
            let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
            let em = e(mid)
            let rising = e(mid.addingTimeInterval(1)) > e(mid.addingTimeInterval(-1))
            let branch: SunCrossing.Branch = rising ? .rising : .setting
            if em >= goldenLow, em <= goldenHigh { append(&golden, SunInterval(branch: branch, start: a, end: b)) }
            if em >= civil, em <= goldenLow { append(&blue, SunInterval(branch: branch, start: a, end: b)) }
            if em >= sunriseElevation { daylight += b.timeIntervalSince(a) }
        }

        var status: SunDay.Status = .normal
        if !supportedYears.contains(year) { status = .unsupportedDate }
        else if rise.isEmpty {
            let mid = e(start.addingTimeInterval(end.timeIntervalSince(start) / 2))
            if abs(maxElevation - sunriseElevation) < 0.05 { status = .grazing }
            else { status = mid > sunriseElevation ? .alwaysAbove : .alwaysBelow }
        } else if !rise.contains(where: { $0.branch == .rising }) || !rise.contains(where: { $0.branch == .setting }) {
            status = .noCrossingThisDay
        }
        return SunDay(dayStart: start, dayEnd: end,
                      sunrise: rise.filter { $0.branch == .rising }, sunset: rise.filter { $0.branch == .setting },
                      civilDawn: civilX.filter { $0.branch == .rising }, civilDusk: civilX.filter { $0.branch == .setting },
                      nauticalDawn: nauticalX.filter { $0.branch == .rising }, nauticalDusk: nauticalX.filter { $0.branch == .setting },
                      solarNoon: transits, dailyMaximumElevation: maxElevation, dailyMaximumTime: maxTime,
                      goldenHourIntervals: golden, blueHourIntervals: blue, daylightSeconds: daylight, status: status)
    }

    /// Merges an interval into the list when it continues the previous one on the same branch.
    static func append(_ list: inout [SunInterval], _ i: SunInterval) {
        if let last = list.last, last.branch == i.branch, abs(last.end.timeIntervalSince(i.start)) < 0.5 {
            list[list.count - 1].end = i.end
        } else {
            list.append(i)
        }
    }

    public enum NextIntervalStatus: String, Codable, Sendable {
        case active, upcoming
        case notFoundWithinHorizon = "not_found_within_horizon"
        case unknown
    }

    /// The earliest golden-hour interval ending after `after` (an active one counts unless
    /// `includeActive` is false), searching up to `searchDays` civil days.
    public static func nextGoldenHour(after: Date, observer: SkyObserver, includeActive: Bool = true,
                                      searchDays: Int = 370) -> (interval: SunInterval?, status: NextIntervalStatus, secondsUntilStart: Double?) {
        guard let tz = observer.timeZone else { return (nil, .unknown, nil) }
        var cursor = civilDay(containing: after, timeZone: tz).start
        for _ in 0..<searchDays {
            guard let day = day(containing: cursor.addingTimeInterval(3600), observer: observer) else { return (nil, .unknown, nil) }
            for g in day.goldenHourIntervals.sorted(by: { $0.start < $1.start }) {
                if g.start <= after, g.end > after {
                    if includeActive { return (g, .active, 0) }
                    continue
                }
                if g.start > after { return (g, .upcoming, g.start.timeIntervalSince(after)) }
            }
            cursor = day.dayEnd
        }
        return (nil, .notFoundWithinHorizon, nil)
    }
}

/// Bracketing root finders over time (refined by bisection to ≤ 10 ms).
enum Roots {
    struct Crossing { var time: Date; var rising: Bool }

    /// Sign changes of f in [a, b), sampled every `step` seconds. With `rejectJumpsAbove`, a
    /// sign change across a discontinuity (e.g. an angle wrapping ±180°) is ignored.
    static func crossings(of f: (Date) -> Double, from a: Date, to b: Date, step: Double, rejectJumpsAbove: Double? = nil) -> [Crossing] {
        var out: [Crossing] = []
        var t0 = a, f0 = f(a)
        if f0 == 0 { out.append(Crossing(time: a, rising: f(a.addingTimeInterval(1)) > 0)) }
        while t0 < b {
            let t1 = min(b, t0.addingTimeInterval(step))
            let f1 = f(t1)
            if (f0 < 0 && f1 > 0) || (f0 > 0 && f1 < 0) {
                if let limit = rejectJumpsAbove, abs(f1 - f0) > limit {
                    // discontinuity, not a root
                } else {
                    var lo = t0, hi = t1, flo = f0
                    while hi.timeIntervalSince(lo) > 0.01 {
                        let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
                        let fm = f(mid)
                        if (flo < 0) == (fm < 0) { lo = mid; flo = fm } else { hi = mid }
                    }
                    let root = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
                    if root >= a, root < b { out.append(Crossing(time: root, rising: f0 < f1)) }
                }
            }
            t0 = t1
            f0 = f1
        }
        return out
    }

    /// Times of local extrema (slope sign changes) in (a, b), refined by golden-section search.
    static func extrema(of f: (Date) -> Double, from a: Date, to b: Date, step: Double) -> [Date] {
        var out: [Date] = []
        var t = a
        var prev = f(a), cur = f(a.addingTimeInterval(step))
        while t.addingTimeInterval(2 * step) <= b {
            let next = f(t.addingTimeInterval(2 * step))
            let isMax = cur > prev && cur >= next, isMin = cur < prev && cur <= next
            if isMax || isMin {
                out.append(goldenSection(f, t, t.addingTimeInterval(2 * step), maximize: isMax).time)
            }
            t = t.addingTimeInterval(step)
            prev = cur
            cur = next
        }
        return out.filter { $0 > a && $0 < b }
    }

    static func maximum(of f: (Date) -> Double, from a: Date, to b: Date, step: Double) -> (Date, Double) {
        var bestT = a, best = f(a)
        var t = a
        while t <= b {
            let v = f(t)
            if v > best { best = v; bestT = t }
            t = t.addingTimeInterval(step)
        }
        let lo = max(a, bestT.addingTimeInterval(-step)), hi = min(b, bestT.addingTimeInterval(step))
        let r = goldenSection(f, lo, hi, maximize: true)
        return r.value >= best ? (r.time, r.value) : (bestT, best)
    }

    static func goldenSection(_ f: (Date) -> Double, _ a: Date, _ b: Date, maximize: Bool) -> (time: Date, value: Double) {
        let g = (5.0.squareRoot() - 1) / 2
        var lo = 0.0, hi = b.timeIntervalSince(a)
        let sign = maximize ? 1.0 : -1.0
        func v(_ x: Double) -> Double { sign * f(a.addingTimeInterval(x)) }
        var x1 = hi - g * (hi - lo), x2 = lo + g * (hi - lo)
        var f1 = v(x1), f2 = v(x2)
        while hi - lo > 0.5 {
            if f1 < f2 { lo = x1; x1 = x2; f1 = f2; x2 = lo + g * (hi - lo); f2 = v(x2) }
            else { hi = x2; x2 = x1; f2 = f1; x1 = hi - g * (hi - lo); f1 = v(x1) }
        }
        let x = (lo + hi) / 2
        return (a.addingTimeInterval(x), f(a.addingTimeInterval(x)))
    }
}
