import Foundation

/// The per-state grade of the lighting bible (look-fix-v1 §2.2, `Profiles/grade.json`): the
/// whole-frame brightness a renderer's exposure aims for and its saturation, for clear skies by sun
/// elevation, night by moon light, and weather states over them by intensity.
public struct GradeTable: Codable, Sendable {
    public struct Grade: Codable, Sendable, Equatable {
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

        public init(luma: Double, saturation: Double, air: Air? = nil, direct: Double? = nil, fill: Double? = nil,
                    groundFill: Double? = nil) {
            self.luma = luma
            self.saturation = saturation
            self.air = air
            self.direct = direct
            self.fill = fill
            self.groundFill = groundFill
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
                         direct: one(direct, b.direct), fill: inherit(fill, b.fill), groundFill: inherit(groundFill, b.groundFill))
        }
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

    public struct ClearPoint: Codable, Sendable {
        public var state: String
        public var elevation: Double
        public var luma: Double
        public var saturation: Double
        public var air: Air?
        public var fill: Double?
        public var groundFill: Double?
        var grade: Grade { Grade(luma: luma, saturation: saturation, air: air, fill: fill, groundFill: groundFill) }
    }

    public struct Night: Codable, Sendable {
        /// Sun elevation at and below which it is full night.
        public var elevation: Double
        public var moonless: Grade
        public var moon: Grade
    }

    /// Clear-sky states by sun elevation, ascending.
    public var clear: [ClearPoint]
    public var night: Night
    /// Weather states by `DominantState` raw value.
    public var weather: [String: Grade]

    /// The grade for a moment.
    /// - Parameters:
    ///   - moonLight: 0 (no moon) … 1 (full moon high in a clear sky), the bible's §2.4 moon boost
    ///     shape: illuminatedFraction^1.5 · sin(altitude) · (1 − cloud)².
    ///   - weather: the dominant weather label's raw value, if any.
    ///   - weight: how strongly that weather applies (its intensity, 0–1).
    public func resolve(sunElevation e: Double, moonLight: Double, weather: String?, weight: Double) -> Grade {
        let points = clear.sorted { $0.elevation < $1.elevation }
        let nightGrade = night.moonless.mixed(night.moon, moonLight)
        var g: Grade
        if let first = points.first, e < first.elevation {
            // Night to the first clear point (blue hour).
            let span = first.elevation - night.elevation
            g = span > 0 ? nightGrade.mixed(first.grade, (e - night.elevation) / span) : first.grade
        } else if let last = points.last, e >= last.elevation {
            g = last.grade
        } else {
            g = points.first?.grade ?? nightGrade
            for (a, b) in zip(points, points.dropFirst()) where e >= a.elevation && e < b.elevation {
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
    /// The lighting bible's per-state grade (`Profiles/grade.json`).
    public static func grade() throws -> GradeTable {
        try JSONDecoder().decode(GradeTable.self, from: data("grade"))
    }
}
