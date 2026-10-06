import Foundation
import WorldGeo

/// A place's calendar-demo phenology profile (sky-seasons spec §5.4/§6): day-of-year knots for
/// the representative deciduous cohort and grass. These are labeled art priors, not observed
/// biology; thermal (GDD) models replace them only when calibrated inputs exist.
public struct PhenologyProfile: Codable, Sendable, Equatable {
    public var id: String
    public var leafStart: Double, leafFull: Double, summerMature: Double
    public var colorStart: Double, colorPeak: Double, dropStart: Double, dropEnd: Double
    public var grassStart: Double, grassFull: Double, grassDormancyStart: Double, grassDormancyEnd: Double
    public var grassPolicy: GrassPolicy
    /// Minimum grass greenness (e.g. Seattle's mild winters), nil = none.
    public var grassFloor: Double?
    /// Southern-hemisphere season-year: days of year below this threshold add 365.
    public var seasonYearWrapBelowDay: Double?

    public enum GrassPolicy: String, Codable, Sendable {
        case coolSeason = "cool_season", warmSeason = "warm_season"
    }

    public init(id: String, knots: [Double], grassPolicy: GrassPolicy, grassFloor: Double? = nil, seasonYearWrapBelowDay: Double? = nil) {
        precondition(knots.count == 11, "11 knots: leafStart…grassDormancyEnd")
        self.id = id
        (leafStart, leafFull, summerMature, colorStart, colorPeak, dropStart, dropEnd) = (knots[0], knots[1], knots[2], knots[3], knots[4], knots[5], knots[6])
        (grassStart, grassFull, grassDormancyStart, grassDormancyEnd) = (knots[7], knots[8], knots[9], knots[10])
        self.grassPolicy = grassPolicy
        self.grassFloor = grassFloor
        self.seasonYearWrapBelowDay = seasonYearWrapBelowDay
    }

    /// The four calendar-demo profiles of the sky-seasons proposal (illustrative priors).
    public static let denverDemo = PhenologyProfile(id: "denver-calendar-demo-v1",
        knots: [100, 140, 165, 263, 288, 295, 320, 80, 120, 310, 345], grassPolicy: .coolSeason)
    public static let planoDemo = PhenologyProfile(id: "plano-calendar-demo-v1",
        knots: [65, 105, 135, 295, 320, 325, 350, 85, 120, 300, 340], grassPolicy: .warmSeason)
    public static let seattleDemo = PhenologyProfile(id: "seattle-calendar-demo-v1",
        knots: [75, 120, 150, 270, 295, 305, 330, 55, 95, 345, 380], grassPolicy: .coolSeason, grassFloor: 0.6)
    public static let sydneyDemo = PhenologyProfile(id: "sydney-calendar-demo-v1",
        knots: [245, 285, 315, 465, 490, 500, 530, 230, 275, 505, 545], grassPolicy: .warmSeason, seasonYearWrapBelowDay: 200)
}

/// v2 seasonal palette weights (spring, summer, autumn, winter); they sum to one.
public struct SeasonWeights: Codable, Sendable, Equatable {
    public var spring: Double, summer: Double, autumn: Double, winter: Double
    public var sum: Double { spring + summer + autumn + winter }
}

public struct DeciduousState: Codable, Sendable, Equatable {
    public var state: String
    public var greenUp: Double, maturity: Double, color: Double, drop: Double
    public var leafFraction: Double
    public var flowerFraction: Double
    public var autumnColorFraction: Double
    public var leafDropProgress: Double
    public var paletteWeights: SeasonWeights
}

public struct GrassState: Codable, Sendable, Equatable {
    public var greenFraction: Double
    public var policy: PhenologyProfile.GrassPolicy
    /// Unknown without evidence (never inferred from clear weather).
    public var waterStress: Double?
    public var irrigation: Double?
    public var paletteWeights: SeasonWeights
    public var dormancyCauseDisplayPrior: String
}

public struct PhenologyState: Codable, Sendable, Equatable {
    public var profileID: String
    public var dataKind: String
    public var dayOfYear: Double
    public var deciduous: DeciduousState
    public var evergreenLeafFraction: Double
    public var grass: GrassState
}

public enum Phenology {
    public static let model = "calendar-demo-v1"
    /// Per-tree timing shift ±7 days from one stable unit value per tree.
    public static let treeShiftDays = 7.0
    public static let timingSalt = "phenology-timing-v1"

    /// Day of year in the observer's timezone (whole local days, 1 = Jan 1) on the profile's
    /// season-year: days before the wrap day count from the previous year (+365), so the calendar
    /// is cyclic and nothing resets on January 1.
    public static func dayOfYear(_ date: Date, timeZone: TimeZone, profile: PhenologyProfile) -> Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var d = Double(cal.ordinality(of: .day, in: .year, for: date) ?? 1)
        if d < seasonYearStart(profile) { d += 365 }
        return d
    }

    /// First day of the profile's season-year: the explicit wrap (southern profiles), else the
    /// middle of the quiet stretch between the last knot (taken modulo 365) and the first, where
    /// every stage is flat. Seattle's grass dormancy ends on day 380 (Jan 15), so its season-year
    /// starts on day 35, not January 1.
    public static func seasonYearStart(_ p: PhenologyProfile) -> Double {
        if let wrap = p.seasonYearWrapBelowDay { return wrap }
        let knots = [p.leafStart, p.leafFull, p.summerMature, p.colorStart, p.colorPeak, p.dropStart, p.dropEnd,
                     p.grassStart, p.grassFull, p.grassDormancyStart, p.grassDormancyEnd]
        let first = knots.min()!, last = knots.max()! - 365
        return max(1, ((last + first) / 2).rounded(.down))
    }

    /// Resolves the representative cohorts for a (shifted) day of year.
    public static func resolve(dayOfYear doy: Double, profile p: PhenologyProfile) -> PhenologyState {
        let s = EnvMath.smoothstep
        let g = s(p.leafStart, p.leafFull, doy)
        let m = s(p.leafFull, p.summerMature, doy)
        let c = s(p.colorStart, p.colorPeak, doy)
        let d = s(p.dropStart, p.dropEnd, doy)
        let weights = SeasonWeights(spring: g * (1 - m) * (1 - c) * (1 - d), summer: g * m * (1 - c) * (1 - d),
                                    autumn: g * c * (1 - d), winter: 1 - g + g * d)
        // Flowering: an independent pulse rising around leaf start, fading after (offsets −5, +5, +15, +30 days).
        let flower = s(p.leafStart - 5, p.leafStart + 5, doy) * (1 - s(p.leafStart + 15, p.leafStart + 30, doy))
        let leaf = g * (1 - d)
        let label: String
        if leaf <= 1e-9 { label = "bare_winter" }
        else if d > 0 { label = "leaf_drop" }
        else if c >= 1 { label = "autumn_peak" }
        else if c > 0 { label = "autumn_onset" }
        else if g < 1 || m < 1 { label = "spring_green_up" }
        else { label = "full_summer" }
        let deciduous = DeciduousState(state: label, greenUp: g, maturity: m, color: c, drop: d, leafFraction: leaf,
                                       flowerFraction: flower, autumnColorFraction: c, leafDropProgress: d, paletteWeights: weights)

        // Grass: greenness, its own spring-to-mature progress, D = 0 (dormancy cause unknown).
        var green = s(p.grassStart, p.grassFull, doy) * (1 - s(p.grassDormancyStart, p.grassDormancyEnd, doy))
        if let floor = p.grassFloor { green = max(floor, green) }
        let maturity = s(p.grassFull, p.grassFull + 30, doy)
        let dormantWarmDry = 0.0
        let gw = SeasonWeights(spring: green * (1 - maturity), summer: green * maturity, autumn: (1 - green) * dormantWarmDry,
                               winter: (1 - green) * (1 - dormantWarmDry))
        let grass = GrassState(greenFraction: green, policy: p.grassPolicy, waterStress: nil, irrigation: nil, paletteWeights: gw,
                               dormancyCauseDisplayPrior: "cold_palette_only; cause not observed")
        return PhenologyState(profileID: p.id, dataKind: "climatological_art_prior", dayOfYear: doy, deciduous: deciduous,
                              evergreenLeafFraction: 1, grass: grass)
    }

    public static func resolve(at date: Date, timeZone: TimeZone, profile: PhenologyProfile) -> PhenologyState {
        resolve(dayOfYear: dayOfYear(date, timeZone: timeZone, profile: profile), profile: profile)
    }

    /// Stable per-tree timing shift in days, (2u − 1) × 7, from the tree's own generator
    /// (`OSMRef.random(Phenology.timingSalt)` or the stable placement identity). Not rerolled by year.
    public static func treeShiftDays(_ rng: inout StableRandom) -> Double {
        (2 * rng.unit() - 1) * treeShiftDays
    }

    /// A tree's own state: the shared shift applied to every ordered stage (day-of-year offset).
    public static func resolve(dayOfYear doy: Double, profile: PhenologyProfile, treeShiftDays shift: Double) -> DeciduousState {
        resolve(dayOfYear: doy - shift, profile: profile).deciduous
    }
}
