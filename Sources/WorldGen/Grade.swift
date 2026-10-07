import Foundation

/// The lighting bible as engine data: `Profiles/lighting-bible.json`, generated from
/// docs/proposals/look-fix-v1 by scripts/lookfix_data.py (never edited by hand). States are the
/// proposal's twelve lighting fixtures with their §2.2 targets and §2.3 lift, shade and clear-air
/// fade; `night` holds §2.4 (the file also carries §3.1 wet ground and §3.2 extinction presets).
public struct LightingBible: Codable, Sendable {
    public struct State: Codable, Sendable {
        public var fixture: String
        public var utc: String
        /// Sun elevation and azimuth at the fixture (degrees, the repository's SolarPosition).
        public var elevation: Double
        public var azimuth: Double
        public var weather: [String: Double]
        public var directTint: String?
        public var skyFillTint: String
        public var keyFill: Double
        public var ev: Double
        /// Whole-frame encoded-sRGB Y targets (0–255) and mean HSV saturation (0–255).
        public var luma: Double
        public var p5: Double
        public var p50: Double
        public var p95: Double
        public var saturationS: Double
        /// Shade-to-sun ratio range (linear luminance); nil where the bible gives no number.
        public var lift: [Double]?
        public var shadeTint: String
        public var air: GradeTable.Air
    }
    public struct Night: Codable, Sendable {
        public var ambientHorizon: String
        public var ambientUpper: String
        public var windowCore: String
        public var windowSurround: String
        public var litWindows: [Double]
        public var patchBands: [String: [String: [Double]]]
    }
    public struct Source: Codable, Sendable {
        public var path: String
        public var sha256: String
    }
    /// §3.2 extinction presets ("fog-light", "smoke-medium", "rain-light", "storm-rain", …): the
    /// scattering colour and the distances where extinction starts and where 90% of contrast is gone.
    public struct Extinction: Codable, Sendable {
        public var color: String
        public var start: Double
        public var end: Double
    }
    public var sources: [String: Source]
    public var states: [String: State]
    public var night: Night
    public var extinction: [String: Extinction]

    /// The extinction for a weather label at an intensity: fog and smoke run light → medium → dense
    /// over intensity 0 → 0.5 → 1 (distances and colour interpolated), rain uses the light-rain
    /// preset, thunderstorms storm rain; nil for labels the bible has no preset for.
    public func extinction(label: String, intensity: Double) -> (color: SIMD3<Float>, start: Double, end: Double)? {
        func ext(_ k: String) -> Extinction? { extinction[k] }
        func lin(_ e: Extinction) -> SIMD3<Float> { Color.linear(Palette.parse(e.color)) }
        switch label {
        case "fog", "smoke":
            guard var a = ext("\(label)-light"), var b = ext("\(label)-medium"), var c = ext("\(label)-dense") else { return nil }
            if label == "smoke" {
                // Owner direction (gate on ccb5f77): smoke warms the scene toward ochre/peach with
                // distance; the bible's distances stay, its grey-tan colours give way.
                (a.color, b.color, c.color) = ("#D9B48E", "#C99A6B", "#B5865A")
            }
            let i = min(1, max(0, intensity))
            let (x, y, t) = i < 0.5 ? (a, b, i / 0.5) : (b, c, (i - 0.5) / 0.5)
            let col = lin(x) + (lin(y) - lin(x)) * Float(t)
            return (col, x.start + (y.start - x.start) * t, x.end + (y.end - x.end) * t)
        case "rain":
            return ext("rain-light").map { (lin($0), $0.start, $0.end) }
        case "thunderstorm":
            return ext("storm-rain").map { (lin($0), $0.start, $0.end) }
        default:
            return nil
        }
    }
}

/// Hand-tuned renderer values on top of the bible (`Profiles/grade.json`), keyed by its states.
public struct GradeTuning: Codable, Sendable {
    public struct Tune: Codable, Sendable {
        public var saturation: Double?
        public var direct: Double?
        public var fill: Double?
        public var groundFill: Double?
    }
    public struct Other: Codable, Sendable {
        public var luma: Double
        public var saturation: Double
        public var direct: Double?
        public var air: GradeTable.Air
    }
    public struct Night: Codable, Sendable {
        public var elevation: Double
        public var moonless: String
        public var moon: String
    }
    public var tuning: [String: Tune]
    /// Weather label (DominantState raw value) → bible state.
    public var weatherStates: [String: String]
    /// Weather labels the bible has no state for, with our own targets.
    public var otherWeather: [String: Other]
    /// Bible states that are clear skies, interpolated by sun elevation.
    public var clearStates: [String]
    public var night: Night
    /// Weather weight (intensity or cover) at which a label's bible state applies in full.
    public var weatherFullAt: [String: Double]?
}

/// The per-state grade: the whole-frame brightness a renderer's exposure aims for, its saturation,
/// the clear-air fade and the light multipliers, for clear skies by sun elevation, night by moon
/// light, and weather states over them by intensity. Built from the bible and the tuning.
public struct GradeTable: Sendable {
    public struct Grade: Sendable, Equatable {
        /// Target whole-frame mean display brightness (Y8 on 0–255).
        public var luma: Double
        /// Post-process saturation multiplier.
        public var saturation: Double
        /// §2.3 clear-air fade; a cap of 0 leaves the distance to weather extinction (rain, fog).
        public var air: Air?
        /// Renderer multiplier on the environment's direct sun (default 1). Weather states use it to
        /// reach the bible's key:fill (overcast 0.15, rain 0.10, storm 0.05, fog 0: "no legible hard
        /// sun shadow"), which the weather model's direct factors leave several times too high.
        public var direct: Double?
        /// Renderer multipliers on the R8 sky fill and ground bounce (default 1), tuned toward the
        /// bible's lift (§2.3 shade-to-sun ratio) and night floor (§2.4 trunk, roof and wall bands).
        public var fill: Double?
        public var groundFill: Double?
        /// The paint-over colour grade (paintover-grade.json), relative to the engine's own output;
        /// neutral for states no paint-over shows.
        public var look: Look = .neutral

        public init(luma: Double, saturation: Double, air: Air? = nil, direct: Double? = nil, fill: Double? = nil,
                    groundFill: Double? = nil, look: Look = .neutral) {
            self.luma = luma
            self.saturation = saturation
            self.air = air
            self.direct = direct
            self.fill = fill
            self.groundFill = groundFill
            self.look = look
        }

        func mixed(_ b: Grade, _ t: Double) -> Grade {
            let t = min(1, max(0, t))
            let air: Air? = switch (self.air, b.air) {
            case let (x?, y?): x.mixed(y, t)
            case let (x?, nil): x
            case let (nil, y?): y
            default: nil
            }
            // Direct: missing means 1 (no cut). Fill: missing means "as the other state", so weather
            // without its own fill keeps the clear state's lift.
            func one(_ x: Double?, _ y: Double?) -> Double { (x ?? 1) + ((y ?? 1) - (x ?? 1)) * t }
            func inherit(_ x: Double?, _ y: Double?) -> Double? {
                guard let a = x ?? y, let c = y ?? x else { return nil }
                return a + (c - a) * t
            }
            return Grade(luma: luma + (b.luma - luma) * t, saturation: saturation + (b.saturation - saturation) * t, air: air,
                         direct: one(direct, b.direct), fill: inherit(fill, b.fill), groundFill: inherit(groundFill, b.groundFill),
                         look: look.mixed(b.look, t))
        }
    }

    /// paintover-v1's grade, applied after lighting in its order: exposure (EV over the solved auto
    /// exposure), contrast (linear luminance slope about 0.18), saturation (linear, luminance kept),
    /// warmth (red 1 + w/2, blue 1 − w/2), then the tone mapper.
    public struct Look: Codable, Sendable, Equatable {
        public var exposureEV: Double
        public var contrast: Double
        public var saturation: Double
        public var warmth: Double
        public static let neutral = Look(exposureEV: 0, contrast: 1, saturation: 1, warmth: 0)

        public init(exposureEV: Double, contrast: Double, saturation: Double, warmth: Double) {
            self.exposureEV = exposureEV
            self.contrast = contrast
            self.saturation = saturation
            self.warmth = warmth
        }

        func mixed(_ b: Look, _ t: Double) -> Look {
            Look(exposureEV: exposureEV + (b.exposureEV - exposureEV) * t, contrast: contrast + (b.contrast - contrast) * t,
                 saturation: saturation + (b.saturation - saturation) * t, warmth: warmth + (b.warmth - warmth) * t)
        }
    }

    /// Profiles/paintover-grade.json (generated by scripts/paintover_data.py).
    public struct PaintoverGrade: Codable, Sendable {
        public struct Source: Codable, Sendable { public var path: String; public var sha256: String }
        public var source: Source
        public var states: [String: Look]
    }

    /// The clear-air fade a = cap·(1 − exp(−ln 2·max(0, d − start)/(d50 − start))): half the cap at
    /// `d50` metres, blended in linear colour.
    public struct Air: Codable, Sendable, Equatable {
        public var start: Double
        public var d50: Double
        public var cap: Double
        /// sRGB hex as authored; `linear` for rendering.
        public var color: String
        var mixedLinear: SIMD3<Float>?

        public var linear: SIMD3<Float> { mixedLinear ?? Color.linear(Palette.parse(color)) }

        enum CodingKeys: String, CodingKey { case start, d50, cap, color }

        public init(start: Double, d50: Double, cap: Double, color: String) {
            self.start = start
            self.d50 = d50
            self.cap = cap
            self.color = color
        }

        func mixed(_ b: Air, _ t: Double) -> Air {
            var m = Air(start: start + (b.start - start) * t, d50: d50 + (b.d50 - d50) * t, cap: cap + (b.cap - cap) * t,
                        color: t < 0.5 ? color : b.color)
            m.mixedLinear = linear + (b.linear - linear) * Float(t)
            return m
        }
    }

    public struct ClearPoint: Sendable {
        public var state: String
        public var elevation: Double
        public var grade: Grade
    }

    /// Clear-sky states by sun elevation, ascending.
    public var clear: [ClearPoint]
    /// Sun elevation at and below which it is full night, and the two night grades.
    public var nightElevation: Double
    public var moonless: Grade
    public var moon: Grade
    /// Weather grades by `DominantState` raw value, and the weight at which each applies in full.
    public var weather: [String: Grade]
    public var fullAt: [String: Double]

    public init(bible: LightingBible, tuning: GradeTuning, paintover: PaintoverGrade? = nil) throws {
        let looks = paintover?.states ?? [:]
        func grade(_ name: String) throws -> Grade {
            guard let s = bible.states[name] else { throw StyleLibrary.LoadError.missing("lighting bible state \(name)") }
            let t = tuning.tuning[name]
            return Grade(luma: s.luma, saturation: t?.saturation ?? 1, air: s.air, direct: t?.direct, fill: t?.fill,
                         groundFill: t?.groundFill, look: looks[name] ?? .neutral)
        }
        clear = try tuning.clearStates.map { name in
            ClearPoint(state: name, elevation: bible.states[name]?.elevation ?? 0, grade: try grade(name))
        }.sorted { $0.elevation < $1.elevation }
        nightElevation = tuning.night.elevation
        moonless = try grade(tuning.night.moonless)
        moon = try grade(tuning.night.moon)
        var w: [String: Grade] = [:]
        for (label, state) in tuning.weatherStates { w[label] = try grade(state) }
        for (label, o) in tuning.otherWeather {
            w[label] = Grade(luma: o.luma, saturation: o.saturation, air: o.air, direct: o.direct, look: looks[label] ?? .neutral)
        }
        weather = w
        fullAt = tuning.weatherFullAt ?? [:]
    }

    /// The grade for a moment.
    /// - Parameters:
    ///   - moonLight: 0 (no moon) … 1 (full moon high in a clear sky), the bible's §2.4 moon boost
    ///     shape: illuminatedFraction^1.5 · sin(altitude) · (1 − cloud)².
    ///   - weather: the dominant weather label's raw value, if any.
    ///   - weight: how strongly that weather applies (its intensity, 0–1).
    public func resolve(sunElevation e: Double, moonLight: Double, weather: String?, weight: Double) -> Grade {
        let nightGrade = moonless.mixed(moon, moonLight)
        var g: Grade
        if let first = clear.first, e < first.elevation {
            // Night to the first clear point (blue hour).
            let span = first.elevation - nightElevation
            g = span > 0 ? nightGrade.mixed(first.grade, (e - nightElevation) / span) : first.grade
        } else if let last = clear.last, e >= last.elevation {
            g = last.grade
        } else {
            g = clear.first?.grade ?? nightGrade
            for (a, b) in zip(clear, clear.dropFirst()) where e >= a.elevation && e < b.elevation {
                g = a.grade.mixed(b.grade, (e - a.elevation) / (b.elevation - a.elevation))
            }
        }
        // Weather leads in daylight only: the bible has no weather-at-night targets.
        if let w = weather, let wg = self.weather[w] {
            let day = Self.smoothstep(-6, 6, e)
            g = g.mixed(wg, weight * day)
        }
        return g
    }

    static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }
}

extension StyleLibrary {
    /// The lighting bible (`Profiles/lighting-bible.json`, generated from the look-fix proposal).
    public static func lightingBible() throws -> LightingBible {
        try JSONDecoder().decode(LightingBible.self, from: data("lighting-bible"))
    }

    /// The bible's per-state grade with the hand-tuned renderer values (`Profiles/grade.json`).
    public static func grade() throws -> GradeTable {
        try GradeTable(bible: lightingBible(), tuning: JSONDecoder().decode(GradeTuning.self, from: data("grade")),
                       paintover: paintoverGrade())
    }

    /// paintover-v1's per-state colour grade (`Profiles/paintover-grade.json`, generated).
    public static func paintoverGrade() throws -> GradeTable.PaintoverGrade {
        try JSONDecoder().decode(GradeTable.PaintoverGrade.self, from: data("paintover-grade"))
    }
}
