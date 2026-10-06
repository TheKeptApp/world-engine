import Foundation
import WorldGeo

/// A provider-facing weather cell (weather spec §9): 0.05° × 0.05°, centred at
/// −90 + (i + 0.5)·0.05 latitude and −180 + (j + 0.5)·0.05 longitude. Only the centre is ever
/// sent to a provider — never a home point, route or user ID.
public struct WeatherCell: Codable, Sendable, Hashable {
    public var i: Int
    public var j: Int
    public static let stepDegrees = 0.05

    public init(i: Int, j: Int) { self.i = i; self.j = j }

    public init(containing c: GeoCoordinate) {
        let lon = (c.longitude + 180).truncatingRemainder(dividingBy: 360)
        let wrapped = lon < 0 ? lon + 360 : lon
        let rows = Int((180 / Self.stepDegrees).rounded())
        i = min(rows - 1, max(0, Int(((c.latitude + 90) / Self.stepDegrees).rounded(.down))))
        j = Int((wrapped / Self.stepDegrees).rounded(.down)) % Int((360 / Self.stepDegrees).rounded())
    }

    public var center: GeoCoordinate {
        GeoCoordinate(latitude: -90 + (Double(i) + 0.5) * Self.stepDegrees, longitude: -180 + (Double(j) + 0.5) * Self.stepDegrees)
    }

    public var id: String { "c005-\(i)-\(j)" }

    /// A stable seed for cell-scoped assumptions (e.g. a variable wind's display bearing).
    public var seed: UInt64 { UInt64(i) << 32 | UInt64(j) }

    /// Distance (m) from `c` to the nearest edge of this cell (positive inside).
    public func insideDistanceMeters(_ c: GeoCoordinate) -> Double {
        let south = -90 + Double(i) * Self.stepDegrees, west = -180 + Double(j) * Self.stepDegrees
        let mPerDegLat = 111_320.0, mPerDegLon = 111_320.0 * cos(c.latitude * .pi / 180)
        let dLat = min(c.latitude - south, south + Self.stepDegrees - c.latitude) * mPerDegLat
        var lon = c.longitude - west
        if lon < -180 { lon += 360 } else if lon > 180 { lon -= 360 }
        let dLon = min(lon, Self.stepDegrees - lon) * mPerDegLon
        return min(dLat, dLon)
    }
}

/// Cell changes take effect 500 m inside the new cell or after 60 s of continued presence,
/// so the exact path never reaches the provider and borders don't flap.
public struct CellSwitchPolicy: Sendable {
    public static let insideMeters = 500.0
    public static let dwellSeconds = 60.0
    public private(set) var current: WeatherCell?
    private var pending: (cell: WeatherCell, since: Date)?

    public init() {}

    public mutating func update(position: GeoCoordinate, at time: Date) -> WeatherCell {
        let here = WeatherCell(containing: position)
        guard let cur = current else { current = here; return here }
        if here == cur { pending = nil; return cur }
        if pending?.cell != here { pending = (here, time) }
        if here.insideDistanceMeters(position) >= Self.insideMeters || time.timeIntervalSince(pending!.since) >= Self.dwellSeconds {
            current = here
            pending = nil
        }
        return current!
    }
}

/// Refresh cadence while active: 30 min, or 15 min during changing precipitation/storms.
/// No polling while inactive.
public enum RefreshPolicy {
    public static let normal: TimeInterval = 30 * 60
    public static let changing: TimeInterval = 15 * 60
    /// Historical requests are split into windows of at most 240 hours.
    public static let maxHistoryHours = 240.0
    /// Warm-up before a recap so accumulation starts from a modeled state.
    public static let recapWarmupHours = 7.0 * 24

    public static func interval(changingPrecipitation: Bool) -> TimeInterval { changingPrecipitation ? changing : normal }

    public static func nextRefresh(after last: Date, active: Bool, changingPrecipitation: Bool) -> Date? {
        active ? last.addingTimeInterval(interval(changingPrecipitation: changingPrecipitation)) : nil
    }

    /// ⌈hours/240⌉ request windows covering [start, end), merged on interval timestamps.
    public static func historyWindows(from start: Date, to end: Date) -> [DateInterval] {
        guard end > start else { return [] }
        var out: [DateInterval] = []
        var cursor = start
        while cursor < end {
            let next = min(end, cursor.addingTimeInterval(maxHistoryHours * 3600))
            out.append(DateInterval(start: cursor, end: next))
            cursor = next
        }
        return out
    }
}

/// A short-lived, memory-only cache within the proposal's limits: fresh for 30 min (15 min while
/// precipitation is changing), usable as stale for up to 2 h during a fetch failure, then
/// discarded. Nothing is written to disk; there is no archive.
public struct TemporaryWeatherCache: Sendable {
    public static let freshFor: TimeInterval = 30 * 60
    public static let freshForChanging: TimeInterval = 15 * 60
    public static let staleLimit: TimeInterval = 2 * 3600

    struct Entry: Sendable { var sample: WeatherSample; var fetchedAt: Date; var changing: Bool }
    private var entries: [WeatherCell: Entry] = [:]

    public init() {}

    public enum Lookup: Sendable, Equatable {
        case fresh(WeatherSample)
        case stale(WeatherSample)
        case none
    }

    public mutating func store(_ sample: WeatherSample, for cell: WeatherCell, fetchedAt: Date, changing: Bool) {
        entries[cell] = Entry(sample: sample, fetchedAt: fetchedAt, changing: changing)
    }

    /// Fresh within its TTL; stale (only for fetch failures) up to two hours; then discarded.
    public mutating func lookup(_ cell: WeatherCell, now: Date) -> Lookup {
        guard let e = entries[cell] else { return .none }
        let age = now.timeIntervalSince(e.fetchedAt)
        if age <= (e.changing ? Self.freshForChanging : Self.freshFor) { return .fresh(e.sample) }
        if age <= Self.staleLimit { return .stale(e.sample) }
        entries[cell] = nil
        return .none
    }

    /// Drops everything past the stale limit (call when the app goes inactive).
    public mutating func purge(now: Date) {
        entries = entries.filter { now.timeIntervalSince($0.value.fetchedAt) <= Self.staleLimit }
    }

    public var count: Int { entries.count }
}

/// Attribution the host must show with provider data (e.g. Apple Weather mark + legal link).
public struct WeatherAttributionInfo: Codable, Sendable, Equatable {
    public var serviceName: String
    public var legalPageURL: String?
    public var markLightURL: String?
    public var markDarkURL: String?
    /// "Weather visualization modified from <provider> data."
    public var modifiedNotice: String
}

/// The host's weather source. WorldEngine never calls a weather service itself; a host adapter
/// (WeatherKit, NOAA, a mock) produces normalized samples for the resolver.
public protocol WeatherProvider: Sendable {
    var providerID: String { get }
    /// The current conditions for a cell (sent: the cell centre only).
    func current(for cell: WeatherCell) async throws -> WeatherSample
    /// Hourly samples in [start, end), at most 240 hours per call.
    func hourly(for cell: WeatherCell, from start: Date, to end: Date) async throws -> [WeatherSample]
    func attribution() async throws -> WeatherAttributionInfo?
}

public enum WeatherProviderError: Error, Sendable {
    case windowTooLong
    case noData
}

/// A provider that replays a fixed sample list (tests, demos, the weather fixtures). Samples are
/// returned by valid time; `current` is the latest sample at or before `now`.
public struct MockWeatherProvider: WeatherProvider {
    public let providerID: String
    public let samples: [WeatherSample]
    public let now: Date

    public init(providerID: String = "mock", samples: [WeatherSample], now: Date) {
        self.providerID = providerID
        self.samples = samples.sorted { $0.validTime < $1.validTime }
        self.now = now
    }

    public func current(for cell: WeatherCell) async throws -> WeatherSample {
        guard let s = samples.last(where: { $0.validTime <= now }) else { throw WeatherProviderError.noData }
        return s
    }

    public func hourly(for cell: WeatherCell, from start: Date, to end: Date) async throws -> [WeatherSample] {
        guard end.timeIntervalSince(start) <= RefreshPolicy.maxHistoryHours * 3600 else { throw WeatherProviderError.windowTooLong }
        return samples.filter { $0.validTime > start && $0.validTime <= end }
    }

    public func attribution() async throws -> WeatherAttributionInfo? {
        WeatherAttributionInfo(serviceName: providerID, legalPageURL: nil, markLightURL: nil, markDarkURL: nil,
                               modifiedNotice: "Weather visualization modified from \(providerID) data.")
    }
}
