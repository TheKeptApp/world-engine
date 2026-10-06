import Foundation

/// One provider sample, already normalized to SI units. `nil` always means unknown; `0` means a
/// known absence. Source values are kept uncapped; rendering caps happen later.
public struct WeatherSample: Codable, Sendable, Equatable {
    /// The time the values describe (UTC). For interval quantities, the interval end.
    public var validTime: Date
    /// Interval for accumulated quantities (precipitation amount); nil for instantaneous samples.
    public var intervalStart: Date?
    public var intervalEnd: Date?
    public var condition: WeatherConditionCode?
    /// The provider's original condition string, preserved (REST wire spelling, METAR codes…).
    public var conditionRaw: String?
    public var cloudCover01: Double?
    public var temperatureC: Double?
    public var humidity01: Double?
    public var visibilityM: Double?
    /// The reported visibility is a reporting limit (e.g. METAR 10SM), not a measured value.
    public var visibilityReportingLimited: Bool
    public var windSpeedMps: Double?
    /// Direction the wind blows FROM, degrees clockwise from true north; nil = variable/unknown.
    public var windFromDegrees: Double?
    public var windGustMps: Double?
    /// Liquid-equivalent precipitation over [intervalStart, intervalEnd], mm.
    public var precipitationMm: Double?
    /// Instantaneous liquid-equivalent rate, mm/hour.
    public var precipitationRateMmPerHour: Double?
    /// Separately reported snowfall liquid equivalent over the interval, mm.
    public var snowfallLiquidEquivalentMm: Double?
    /// Measured/reported phase of the precipitation, when known.
    public var phase: PrecipitationPhase?
    /// Frozen fraction of the interval's precipitation when the source fixes it (0…1).
    public var frozenFraction: Double?
    /// Provenance and assumption flags (e.g. "traceAssumed", "phaseInferred", "humidityAssumed").
    public var flags: [String]

    public init(validTime: Date, intervalStart: Date? = nil, intervalEnd: Date? = nil, condition: WeatherConditionCode? = nil,
                conditionRaw: String? = nil, cloudCover01: Double? = nil, temperatureC: Double? = nil, humidity01: Double? = nil,
                visibilityM: Double? = nil, visibilityReportingLimited: Bool = false, windSpeedMps: Double? = nil,
                windFromDegrees: Double? = nil, windGustMps: Double? = nil, precipitationMm: Double? = nil,
                precipitationRateMmPerHour: Double? = nil, snowfallLiquidEquivalentMm: Double? = nil,
                phase: PrecipitationPhase? = nil, frozenFraction: Double? = nil, flags: [String] = []) {
        self.validTime = validTime
        self.intervalStart = intervalStart
        self.intervalEnd = intervalEnd
        self.condition = condition
        self.conditionRaw = conditionRaw
        self.cloudCover01 = cloudCover01
        self.temperatureC = temperatureC
        self.humidity01 = humidity01
        self.visibilityM = visibilityM
        self.visibilityReportingLimited = visibilityReportingLimited
        self.windSpeedMps = windSpeedMps
        self.windFromDegrees = windFromDegrees
        self.windGustMps = windGustMps
        self.precipitationMm = precipitationMm
        self.precipitationRateMmPerHour = precipitationRateMmPerHour
        self.snowfallLiquidEquivalentMm = snowfallLiquidEquivalentMm
        self.phase = phase
        self.frozenFraction = frozenFraction
        self.flags = flags
    }

    /// Interval length in hours (nil for instantaneous samples).
    public var intervalHours: Double? {
        guard let a = intervalStart, let b = intervalEnd, b > a else { return nil }
        return b.timeIntervalSince(a) / 3600
    }

    /// The best available liquid-equivalent rate (mm/hour): the instantaneous rate, else the
    /// interval amount divided by its length. Nil when neither is known.
    public var effectiveRateMmPerHour: Double? {
        if let r = precipitationRateMmPerHour { return r }
        if let p = precipitationMm, let h = intervalHours { return p / h }
        return nil
    }
}
