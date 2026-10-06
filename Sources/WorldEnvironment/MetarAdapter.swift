import Foundation

/// Normalizes routine hourly ASOS/METAR rows (Iowa Environmental Mesonet CSV fields) into
/// samples, following the weather fixtures' documented conventions. Used for the fixtures and
/// as a non-Apple fallback source; samples keep the original METAR as `conditionRaw`.
public enum MetarAdapter {
    /// Cloud categories → fraction (assumed midpoints): CLR/SKC 0, FEW .1875, SCT .4375, BKN .75, OVC/VV 1.
    public static let cloudCategories: [String: Double] = ["CLR": 0, "SKC": 0, "FEW": 0.1875, "SCT": 0.4375, "BKN": 0.75, "OVC": 1, "VV": 1]
    /// Trace precipitation reference amount (mm), inside a conservative [0, 0.254] interval.
    public static let traceMm = 0.127

    /// `row` uses the IEM field names: valid, tmpf, relh, drct, sknt, gust, vsby, p01i, skyc1…4, wxcodes, metar.
    public static func sample(_ row: [String: String], validTime: Date) -> WeatherSample {
        func num(_ k: String) -> Double? { row[k].flatMap { $0 == "M" ? nil : Double($0) } }
        var flags: [String] = []
        let t = num("tmpf").map(Normalize.fahrenheitToCelsius)
        let h = num("relh").map { $0 / 100 }
        let wind = num("sknt").map(Normalize.knotsToMetersPerSecond)
        let gust = num("gust").map(Normalize.knotsToMetersPerSecond)
        let dir = num("drct")
        let vis = num("vsby").map(Normalize.statuteMilesToMeters)
        let skies = (1...4).compactMap { row["skyc\($0)"]?.trimmingCharacters(in: .whitespaces) }.compactMap { cloudCategories[$0] }
        let cloud = skies.max()
        var precip: Double?
        switch row["p01i"] {
        case "T"?: precip = traceMm; flags.append("traceAssumed")
        case "M"?, nil: precip = nil
        case let v?: precip = Double(v).map(Normalize.inchesToMillimeters)
        }
        let wx = row["wxcodes"] ?? "M"
        let tokens = wx == "M" ? [] : wx.split(separator: " ").map(String.init)
        let hasSN = tokens.contains { $0.contains("SN") }, hasRA = tokens.contains { $0.contains("RA") }
        var frozen: Double?
        var phase: PrecipitationPhase?
        if hasSN && !hasRA { frozen = 1; phase = .frozen }
        else if hasRA && !hasSN { frozen = 0; phase = .liquid }
        else if hasRA && hasSN, let tc = t { frozen = Accumulation.mixedFrozenFraction(temperatureC: tc); phase = .mixed; flags.append("phaseInferred") }
        else if let p = precip, p > 0, wx == "M", let tc = t {
            // Positive precipitation with no reported weather code: phase reconstructed from temperature.
            frozen = tc <= 2 ? Accumulation.mixedFrozenFraction(temperatureC: tc) : 0
            phase = tc <= 2 ? .mixed : .liquid
            flags.append("phaseInferred")
        } else if precip != nil { frozen = 0 }
        return WeatherSample(validTime: validTime, intervalStart: validTime.addingTimeInterval(-3600), intervalEnd: validTime,
                             condition: nil, conditionRaw: row["metar"], cloudCover01: cloud, temperatureC: t, humidity01: h,
                             visibilityM: vis, visibilityReportingLimited: (num("vsby") ?? 0) >= 10, windSpeedMps: wind,
                             windFromDegrees: (dir == nil || (wind ?? 0) == 0) ? nil : dir, windGustMps: gust,
                             precipitationMm: precip, precipitationRateMmPerHour: nil, snowfallLiquidEquivalentMm: nil,
                             phase: phase, frozenFraction: frozen, flags: flags)
    }

    /// The accumulation interval a routine report supplies (the preceding hour).
    public static func accumulationInput(_ s: WeatherSample) -> AccumulationInput {
        AccumulationInput(start: s.intervalStart ?? s.validTime.addingTimeInterval(-3600), end: s.intervalEnd ?? s.validTime,
                          temperatureC: s.temperatureC, windSpeedMps: s.windSpeedMps, humidity01: s.humidity01,
                          cloudCover01: s.cloudCover01, precipitationMm: s.precipitationMm, frozenFraction: s.frozenFraction,
                          isHail: (s.conditionRaw ?? "").contains("GR"))
    }
}
