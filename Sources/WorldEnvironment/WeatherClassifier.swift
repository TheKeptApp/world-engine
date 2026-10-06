import Foundation

/// The settled atmospheric label for one sample (weather spec §2, resolution order).
public struct ResolvedWeather: Codable, Sendable, Equatable {
    public var dominantState: DominantState?
    public var intensity01: Double?
    /// The intensity is the code's default, not a measurement.
    public var assumedIntensity: Bool
    public var flags: [String]
    /// Code and measured phase disagree; both are kept and measured phase drives particles.
    public var conflict: Bool
    /// No code and no usable quantitative channel: show a labeled neutral fallback.
    public var displayFallback: DominantState?
}

public enum WeatherClassifier {
    /// Quantitative precipitation enters at this rate and leaves below `precipitationLeaveRate`.
    public static let precipitationEnterRate = 0.10
    public static let precipitationLeaveRate = 0.05
    /// Wind-only/hot/frigid codes switch to cloudy at C ≥ 0.65 and back to clear at C ≤ 0.55.
    public static let cloudEnter = 0.65
    public static let cloudLeave = 0.55

    /// Classifies a sample. `previous` (the displayed label) enables the hysteresis bands.
    public static func classify(_ s: WeatherSample, previous: DominantState? = nil) -> ResolvedWeather {
        var flags: [String] = []
        let rate = s.effectiveRateMmPerHour
        let measuredPhase = s.phase
        // Frozen fraction of the measured precipitation (for intensity of mixed phases).
        let frozen: Double? = s.frozenFraction ?? measuredPhase.map { $0 == .frozen ? 1 : ($0 == .liquid ? 0 : 0.5) }

        guard let code = s.condition else {
            return classifyWithoutCode(s, rate: rate, frozen: frozen, previous: previous)
        }
        let map = ConditionMapping.of(code)
        var state = map.state
        var conflict = false
        if map.flags.contains(.sunFloor) { flags.append("sunFloor0.65") }
        if map.flags.contains(.hail) { flags.append("hail") }
        if map.flags.contains(.freezing) { flags.append("freezing") }
        if map.flags.contains(.tropicalHazard) { flags.append("tropicalHazard") }
        if map.flags.contains(.hot) { flags.append("hot") }
        if map.flags.contains(.frigid) { flags.append("frigid") }
        if map.flags.contains(.blowingSnow) { flags.append("blowingSnowNoNewSnowfall") }

        // A valid measured precipitation may override a non-precipitating cloud/temperature/wind
        // label (explicit storm/obscuration codes keep theirs).
        let threshold = previous?.isPrecipitation == true ? precipitationLeaveRate : precipitationEnterRate
        if !map.flags.contains(.explicitLabel), !state.isPrecipitation, let r = rate, r >= threshold, let f = frozen {
            state = f >= 0.5 ? .snow : .rain
            flags.append("precipitationOverride")
        }
        // Wind-only/hot/frigid labels become cloudy under heavy cloud (with hysteresis).
        if state == .clear, map.flags.contains(.windLabel) || map.flags.contains(.hot) || map.flags.contains(.frigid),
           let c = s.cloudCover01 {
            let wasCloudy = previous == .cloudy
            if c >= cloudEnter || (wasCloudy && c > cloudLeave) { state = .cloudy; flags.append("cloudOverride") }
        }
        // Code vs measured phase.
        if let mp = measuredPhase, let cp = map.phase, mp != cp, cp != .mixed {
            conflict = true
            flags.append("phaseConflict")
        }
        if map.flags.contains(.freezing), state == .snow { state = .rain } // freezing rain never becomes snow

        // Intensity.
        var intensity: Double
        var assumed = false
        switch (state, map.rule) {
        case (.cloudy, _) where state != map.state:
            // Overridden to cloudy: intensity is the cloud fraction.
            intensity = s.cloudCover01 ?? 1
        case (.rain, _) where state != map.state, (.snow, _) where state != map.state:
            intensity = precipitationIntensity(state: state, rate: rate, frozen: frozen) ?? 0.5
        case (_, .fixed(let v)):
            intensity = v
        case (_, .cloud(let d)):
            if let c = s.cloudCover01 { intensity = c } else { intensity = d; assumed = true }
        case (_, .rain(let d)):
            if let v = precipitationIntensity(state: .rain, rate: rate, frozen: frozen) { intensity = v } else { intensity = d; assumed = true }
        case (_, .snow(let d)):
            if let v = precipitationIntensity(state: .snow, rate: rate, frozen: frozen) { intensity = v } else { intensity = d; assumed = true }
        case (_, .visibility(let d)):
            if let v = s.visibilityM, !s.visibilityReportingLimited { intensity = Intensity.visibility(v) } else { intensity = d; assumed = true }
        }
        if assumed { flags.append("assumedIntensity") }
        return ResolvedWeather(dominantState: state, intensity01: EnvMath.clamp01(intensity), assumedIntensity: assumed,
                               flags: flags, conflict: conflict, displayFallback: nil)
    }

    /// Intensity from measured precipitation: IR on the liquid part, IS on the frozen part.
    static func precipitationIntensity(state: DominantState, rate: Double?, frozen: Double?) -> Double? {
        guard let r = rate else { return nil }
        let f = frozen ?? (state == .snow ? 1 : 0)
        return state == .snow ? Intensity.snow(r * f) : Intensity.rain(r * (1 - f))
    }

    /// Missing/future codes: use valid quantitative channels, else unknown with a fallback.
    static func classifyWithoutCode(_ s: WeatherSample, rate: Double?, frozen: Double?, previous: DominantState?) -> ResolvedWeather {
        var flags = ["noConditionCode"]
        let threshold = previous?.isPrecipitation == true ? precipitationLeaveRate : precipitationEnterRate
        if let r = rate, r >= threshold, let f = frozen {
            let state: DominantState = f >= 0.5 ? .snow : .rain
            let i = precipitationIntensity(state: state, rate: r, frozen: f) ?? 0.5
            return ResolvedWeather(dominantState: state, intensity01: i, assumedIntensity: false, flags: flags, conflict: false, displayFallback: nil)
        }
        if let v = s.visibilityM, !s.visibilityReportingLimited, v < 1000 {
            return ResolvedWeather(dominantState: .fog, intensity01: Intensity.visibility(v), assumedIntensity: false, flags: flags,
                                   conflict: false, displayFallback: nil)
        }
        if let c = s.cloudCover01 {
            let cloudy = c >= cloudEnter || (previous == .cloudy && c > cloudLeave)
            return ResolvedWeather(dominantState: cloudy ? .cloudy : .clear, intensity01: cloudy ? c : 1, assumedIntensity: false,
                                   flags: flags, conflict: false, displayFallback: nil)
        }
        flags.append("unknown")
        return ResolvedWeather(dominantState: nil, intensity01: nil, assumedIntensity: false, flags: flags, conflict: false,
                               displayFallback: .clear)
    }
}
