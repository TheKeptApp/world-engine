import Foundation

/// The weather appearance channels a renderer interpolates (all blendable scalars/vectors).
public struct WeatherAppearance: Codable, Sendable, Equatable {
    public var tintLinear: SIMD3<Double>
    public var tintWeight: Double
    public var directMultiplier: Double
    public var fogStartM: Double
    public var fogEndM: Double
    /// Precipitation appearance (particle/streak strength), not water input.
    public var rainIntensity: Double
    public var snowIntensity: Double
    /// Air transport vector, scene axes (blended as a vector, never as an angle).
    public var windVector: SIMD3<Double>

    public static func target(label: DominantState?, intensity: Double?, sample: WeatherSample, wind: WindState,
                              baseFogStart: Double, baseFogEnd: Double, aerial: Bool, sunFloor: Bool) -> WeatherAppearance {
        let state = label ?? .clear
        let i = intensity ?? 0
        let atm = Atmosphere.resolve(state: state, intensity: i, cloud: sample.cloudCover01, visibilityM: sample.visibilityM,
                                     visibilityReportingLimited: sample.visibilityReportingLimited, baseFogStart: baseFogStart,
                                     baseFogEnd: baseFogEnd, aerial: aerial, sunFloor: sunFloor)
        let frozen = sample.frozenFraction ?? (state == .snow ? 1 : 0)
        let precip = state.isPrecipitation ? i : 0
        return WeatherAppearance(tintLinear: atm.tintLinear, tintWeight: atm.tintWeight, directMultiplier: atm.directMultiplier,
                                 fogStartM: atm.fogStartM, fogEndM: atm.fogEndM, rainIntensity: precip * (1 - frozen),
                                 snowIntensity: precip * frozen, windVector: wind.transportVectorMps)
    }
}

/// Blend durations (seconds) for live transitions (weather spec §5).
public enum TransitionTiming {
    public static let atmosphere = 12.0
    public static let fog = 20.0
    public static let wind = 10.0
    public static let precipitationOn = 8.0
    public static let precipitationOff = 12.0
    /// Non-precipitation label changes must stay the candidate this long (live elapsed time).
    public static let labelHold = 90.0
    /// Recap: fixed source-time window centred on a changed hourly boundary.
    public static let recapWindow = 120.0
}

/// Live weather: accepts newer samples, holds label candidates, and blends displayed channels
/// from their current values toward frozen targets. Accumulation is not touched here.
public struct LiveWeatherTracker: Sendable {
    public private(set) var acceptedLabel: DominantState?
    public private(set) var acceptedIntensity: Double?
    public private(set) var lastValidTime: Date?
    private var candidate: (label: DominantState?, intensity: Double?, since: Double)?
    private var latestSample: WeatherSample?
    private var latestWind: WindState?
    private var from: WeatherAppearance?
    private var to: WeatherAppearance?
    private var transitionStart = 0.0
    private var settled = false

    public init() {}

    /// Feeds a sample at live time `now` (seconds). Older or equal valid times are ignored.
    @discardableResult
    public mutating func ingest(_ sample: WeatherSample, wind: WindState, now: Double, baseFogStart: Double, baseFogEnd: Double,
                                aerial: Bool = false) -> Bool {
        if let last = lastValidTime, sample.validTime <= last { return false }
        lastValidTime = sample.validTime
        latestSample = sample
        latestWind = wind
        let r = WeatherClassifier.classify(sample, previous: acceptedLabel)
        if !settled {
            // The opening state settles immediately behind the opening transition.
            settled = true
            accept(r, now: now, baseFogStart: baseFogStart, baseFogEnd: baseFogEnd, aerial: aerial, immediate: true)
            return true
        }
        if r.dominantState == acceptedLabel {
            candidate = nil
            accept(r, now: now, baseFogStart: baseFogStart, baseFogEnd: baseFogEnd, aerial: aerial, immediate: false)
        } else if r.dominantState?.isPrecipitation == true {
            // Precipitation and storms enter on fresh evidence (their appearance still blends).
            candidate = nil
            accept(r, now: now, baseFogStart: baseFogStart, baseFogEnd: baseFogEnd, aerial: aerial, immediate: false)
        } else if candidate?.label != r.dominantState {
            candidate = (r.dominantState, r.intensity01, now) // a replaced candidate restarts the hold
        } else {
            candidate?.intensity = r.intensity01
        }
        return true
    }

    /// Displayed channels at live time `now`; promotes a candidate held long enough.
    public mutating func display(now: Double, baseFogStart: Double, baseFogEnd: Double, aerial: Bool = false) -> WeatherAppearance? {
        if let c = candidate, now - c.since >= TransitionTiming.labelHold {
            candidate = nil
            accept(ResolvedWeather(dominantState: c.label, intensity01: c.intensity, assumedIntensity: false, flags: [], conflict: false,
                                   displayFallback: nil), now: now, baseFogStart: baseFogStart, baseFogEnd: baseFogEnd, aerial: aerial,
                   immediate: false)
        }
        guard let from, let to else { return nil }
        return Self.blend(from: from, to: to, elapsed: now - transitionStart)
    }

    private mutating func accept(_ r: ResolvedWeather, now: Double, baseFogStart: Double, baseFogEnd: Double, aerial: Bool, immediate: Bool) {
        guard let sample = latestSample, let wind = latestWind else { return }
        let current = (from != nil && to != nil) ? Self.blend(from: from!, to: to!, elapsed: now - transitionStart) : nil
        acceptedLabel = r.dominantState
        acceptedIntensity = r.intensity01
        let target = WeatherAppearance.target(label: r.dominantState, intensity: r.intensity01, sample: sample, wind: wind,
                                              baseFogStart: baseFogStart, baseFogEnd: baseFogEnd, aerial: aerial,
                                              sunFloor: r.flags.contains("sunFloor0.65"))
        from = immediate ? target : (current ?? target)
        to = target
        transitionStart = now
    }

    /// Per-channel smoothstep from frozen endpoints.
    public static func blend(from a: WeatherAppearance, to b: WeatherAppearance, elapsed: Double) -> WeatherAppearance {
        func w(_ duration: Double) -> Double { EnvMath.smoothstep(0, duration, elapsed) }
        let atm = w(TransitionTiming.atmosphere), fog = w(TransitionTiming.fog), wind = w(TransitionTiming.wind)
        let rainT = w(b.rainIntensity >= a.rainIntensity ? TransitionTiming.precipitationOn : TransitionTiming.precipitationOff)
        let snowT = w(b.snowIntensity >= a.snowIntensity ? TransitionTiming.precipitationOn : TransitionTiming.precipitationOff)
        return WeatherAppearance(
            tintLinear: a.tintLinear + (b.tintLinear - a.tintLinear) * atm,
            tintWeight: EnvMath.mix(a.tintWeight, b.tintWeight, atm),
            directMultiplier: EnvMath.mix(a.directMultiplier, b.directMultiplier, atm),
            fogStartM: EnvMath.mix(a.fogStartM, b.fogStartM, fog),
            fogEndM: EnvMath.mix(a.fogEndM, b.fogEndM, fog),
            rainIntensity: EnvMath.mix(a.rainIntensity, b.rainIntensity, rainT),
            snowIntensity: EnvMath.mix(a.snowIntensity, b.snowIntensity, snowT),
            windVector: a.windVector + (b.windVector - a.windVector) * wind)
    }
}

/// Recap: labels resolved once on the source timeline, appearance keyframes per hourly interval
/// with fixed 120 s windows centred on changed boundaries. `appearance(at:)` is a pure function
/// of source time, so seeks, pauses and playback speed give identical results.
public struct RecapTimeline: Sendable {
    public struct Keyframe: Sendable {
        public var start: Date
        public var end: Date
        public var label: DominantState?
        public var intensity: Double?
        public var appearance: WeatherAppearance
    }
    public private(set) var keyframes: [Keyframe] = []

    /// `samples` are hourly interval samples sorted by time; fog base distances are per moment.
    public init(samples: [WeatherSample], cellSeed: UInt64, aerial: Bool = false, baseFog: (Date) -> (start: Double, end: Double)) {
        var previous: DominantState?
        for s in samples {
            let r = WeatherClassifier.classify(s, previous: previous)
            previous = r.dominantState
            let wind = WindModel.resolve(speedMps: s.windSpeedMps, fromDegrees: s.windFromDegrees, gustMps: s.windGustMps, cellSeed: cellSeed)
            let start = s.intervalStart ?? s.validTime.addingTimeInterval(-3600)
            let end = s.intervalEnd ?? s.validTime
            let fog = baseFog(start.addingTimeInterval(end.timeIntervalSince(start) / 2))
            let a = WeatherAppearance.target(label: r.dominantState, intensity: r.intensity01, sample: s, wind: wind,
                                             baseFogStart: fog.start, baseFogEnd: fog.end, aerial: aerial,
                                             sunFloor: r.flags.contains("sunFloor0.65"))
            keyframes.append(Keyframe(start: start, end: end, label: r.dominantState, intensity: r.intensity01, appearance: a))
        }
    }

    public func appearance(at t: Date) -> WeatherAppearance? {
        guard let i = keyframes.lastIndex(where: { $0.start <= t }) ?? (keyframes.isEmpty ? nil : 0) else { return nil }
        let k = keyframes[i]
        let half = TransitionTiming.recapWindow / 2
        // Entering window from the previous interval.
        if i > 0, t.timeIntervalSince(k.start) < half, keyframes[i - 1].appearance != k.appearance {
            let progress = (t.timeIntervalSince(k.start) + half) / TransitionTiming.recapWindow
            return Self.lerp(keyframes[i - 1].appearance, k.appearance, EnvMath.smoothstep(0, 1, progress))
        }
        // Leaving window toward the next interval.
        if i + 1 < keyframes.count, k.end.timeIntervalSince(t) < half, keyframes[i + 1].appearance != k.appearance {
            let progress = (half - k.end.timeIntervalSince(t)) / TransitionTiming.recapWindow
            return Self.lerp(k.appearance, keyframes[i + 1].appearance, EnvMath.smoothstep(0, 1, progress))
        }
        return k.appearance
    }

    static func lerp(_ a: WeatherAppearance, _ b: WeatherAppearance, _ t: Double) -> WeatherAppearance {
        WeatherAppearance(tintLinear: a.tintLinear + (b.tintLinear - a.tintLinear) * t, tintWeight: EnvMath.mix(a.tintWeight, b.tintWeight, t),
                          directMultiplier: EnvMath.mix(a.directMultiplier, b.directMultiplier, t),
                          fogStartM: EnvMath.mix(a.fogStartM, b.fogStartM, t), fogEndM: EnvMath.mix(a.fogEndM, b.fogEndM, t),
                          rainIntensity: EnvMath.mix(a.rainIntensity, b.rainIntensity, t),
                          snowIntensity: EnvMath.mix(a.snowIntensity, b.snowIntensity, t),
                          windVector: a.windVector + (b.windVector - a.windVector) * t)
    }
}
