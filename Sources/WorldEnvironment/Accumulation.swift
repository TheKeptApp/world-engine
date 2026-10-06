import Foundation
import WorldGeo

/// Persistent surface wetness and snow (weather spec §4): an appearance model, not hydrology.
/// Integrated on fixed source-time hours, independent of frame rate; double precision; nil means
/// unknown and is never silently replaced by zero.
public struct SurfaceState: Codable, Sendable, Equatable {
    /// Exposed-reference wetness 0…1 (nil = unknown).
    public var wetness01: Double?
    /// Modeled snow water equivalent, mm, 0…100 (nil = unknown).
    public var snowWaterEquivalentMm: Double?
    /// Melt in the last evaluated interval, mm.
    public var lastIntervalMeltMm: Double?
    /// Source-time instant the state describes.
    public var time: Date
    public var status: Status
    /// How the state was initialised (provenance).
    public var initialization: Initialization

    public enum Status: String, Codable, Sendable {
        /// No checkpoint: values are null.
        case unknownInitialState = "unknown_initial_state"
        /// Integrated from a supported checkpoint over complete inputs.
        case modeled
        /// A required input hour was missing: the precise state is invalid after the gap.
        case gapInvalidated = "gap_invalidated"
    }

    public enum Initialization: Codable, Sendable, Equatable {
        case unknown
        case checkpoint(source: String)
        /// A labeled reference initialisation for previews/tests (never "observed").
        case assumedReference(wetness: Double, snowWaterEquivalentMm: Double)
    }

    /// Eligible-surface snow coverage, 1 − exp(−S/6).
    public var snowCover01: Double? { snowWaterEquivalentMm.map { 1 - exp(-$0 / 6) } }

    public static func unknown(at time: Date) -> SurfaceState {
        SurfaceState(wetness01: nil, snowWaterEquivalentMm: nil, lastIntervalMeltMm: nil, time: time,
                     status: .unknownInitialState, initialization: .unknown)
    }

    public static func assumedReference(wetness: Double, snowWaterEquivalentMm: Double, at time: Date) -> SurfaceState {
        SurfaceState(wetness01: wetness, snowWaterEquivalentMm: snowWaterEquivalentMm, lastIntervalMeltMm: 0, time: time,
                     status: .modeled, initialization: .assumedReference(wetness: wetness, snowWaterEquivalentMm: snowWaterEquivalentMm))
    }
}

/// One accumulation interval's inputs (normalized; nil = missing).
public struct AccumulationInput: Sendable, Equatable {
    public var start: Date
    public var end: Date
    public var temperatureC: Double?
    public var windSpeedMps: Double?
    public var humidity01: Double?
    public var cloudCover01: Double?
    /// Liquid-equivalent precipitation over the interval, mm.
    public var precipitationMm: Double?
    /// Frozen fraction f of that precipitation (0…1), nil if the phase is unresolved.
    public var frozenFraction: Double?
    /// Hail does not build the snow reservoir.
    public var isHail: Bool

    public init(start: Date, end: Date, temperatureC: Double?, windSpeedMps: Double?, humidity01: Double?, cloudCover01: Double?,
                precipitationMm: Double?, frozenFraction: Double?, isHail: Bool = false) {
        self.start = start
        self.end = end
        self.temperatureC = temperatureC
        self.windSpeedMps = windSpeedMps
        self.humidity01 = humidity01
        self.cloudCover01 = cloudCover01
        self.precipitationMm = precipitationMm
        self.frozenFraction = frozenFraction
        self.isHail = isHail
    }
}

public enum Accumulation {
    public static let modelVersion = "weather-accumulation-v1"
    public static let windCapMps = 20.0
    public static let snowCapMm = 100.0

    /// Frozen fraction for mixed/unresolved cold precipitation: 1 − smoothstep(−1, 2, T).
    public static func mixedFrozenFraction(temperatureC t: Double) -> Double { 1 - EnvMath.smoothstep(-1, 2, t) }

    /// Advances `state` over one interval. Missing temperature, precipitation or phase (with
    /// precipitation) invalidates the precise state (values become nil, status gap).
    public static func step(_ state: SurfaceState, _ input: AccumulationInput, location: GeoCoordinate) -> SurfaceState {
        guard let w = state.wetness01, let s = state.snowWaterEquivalentMm else {
            var out = state
            out.time = input.end
            return out
        }
        guard let t = input.temperatureC, let p = input.precipitationMm, p == 0 || input.frozenFraction != nil || input.isHail else {
            return SurfaceState(wetness01: nil, snowWaterEquivalentMm: nil, lastIntervalMeltMm: nil, time: input.end,
                                status: .gapInvalidated, initialization: state.initialization)
        }
        let dt = input.end.timeIntervalSince(input.start) / 3600
        let u = min(windCapMps, input.windSpeedMps ?? 0)
        let h = input.humidity01 ?? 0.5
        let c = input.cloudCover01 ?? 0
        // Solar drying proxy at the interval midpoint.
        let mid = input.start.addingTimeInterval(input.end.timeIntervalSince(input.start) / 2)
        let e = SolarPosition(date: mid, at: location).elevation * .pi / 180
        let j = max(0, sin(e)) * (1 - 0.75 * c)

        let f = input.isHail ? 0 : (input.frozenFraction ?? 0)
        let ps = p * f
        let pr = p - ps
        let r = EnvMath.clamp01((2 - t) / 2)
        let sa = s + r * ps
        let mp = (0.12 * max(t, 0) + 0.25 * j) * dt
        let melt = min(sa, mp)
        let sNew = min(snowCapMm, max(0, sa - melt))

        let q = pr + (1 - r) * ps + melt
        let a = 0.8 * q / dt
        let d = (0.04 + 0.008 * max(t, 0) + 0.015 * u + 0.12 * j) * (1 - 0.5 * h)
        var wNew = w
        if a + d > 0 {
            let weq = a / (a + d)
            wNew = weq + (w - weq) * exp(-(a + d) * dt)
        }
        wNew = min(1, max(0, wNew)) // round-off only
        return SurfaceState(wetness01: wNew, snowWaterEquivalentMm: sNew, lastIntervalMeltMm: melt, time: input.end,
                            status: .modeled, initialization: state.initialization)
    }

    /// Integrates a sequence of intervals (sorted, contiguous) from a starting state.
    /// A gap between intervals invalidates the precise state.
    public static func integrate(from start: SurfaceState, inputs: [AccumulationInput], location: GeoCoordinate) -> SurfaceState {
        var state = start
        for input in inputs {
            if input.start > state.time.addingTimeInterval(1) {
                state = SurfaceState(wetness01: nil, snowWaterEquivalentMm: nil, lastIntervalMeltMm: nil, time: input.end,
                                     status: .gapInvalidated, initialization: state.initialization)
                continue
            }
            state = step(state, input, location: location)
        }
        return state
    }

    /// Seeks to any instant: integrates whole intervals from the checkpoint, then the partial
    /// interval with its share of the precipitation and the same hour-start state and midpoint
    /// solar value as the full-interval evaluation.
    public static func state(at time: Date, from checkpoint: SurfaceState, inputs: [AccumulationInput], location: GeoCoordinate) -> SurfaceState {
        var state = checkpoint
        for input in inputs where input.start >= checkpoint.time.addingTimeInterval(-1) {
            if input.end <= time {
                state = integrate(from: state, inputs: [input], location: location)
            } else if input.start < time {
                let fraction = time.timeIntervalSince(input.start) / input.end.timeIntervalSince(input.start)
                var partial = input
                partial.end = time
                partial.precipitationMm = input.precipitationMm.map { $0 * fraction }
                state = stepPartial(state, partial, full: input, location: location)
                break
            } else {
                break
            }
        }
        return state
    }

    /// Partial interval: uses the full interval's midpoint for the solar term.
    static func stepPartial(_ state: SurfaceState, _ partial: AccumulationInput, full: AccumulationInput, location: GeoCoordinate) -> SurfaceState {
        // Evaluate with the full interval's solar midpoint by shifting the partial window so its
        // midpoint coincides; durations and amounts stay those of the partial window.
        let fullMid = full.start.addingTimeInterval(full.end.timeIntervalSince(full.start) / 2)
        let half = partial.end.timeIntervalSince(partial.start) / 2
        var shifted = partial
        shifted.start = fullMid.addingTimeInterval(-half)
        shifted.end = fullMid.addingTimeInterval(half)
        var out = step(state, shifted, location: location)
        out.time = partial.end
        return out
    }
}
