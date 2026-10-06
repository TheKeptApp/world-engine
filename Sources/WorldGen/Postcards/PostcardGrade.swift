import Foundation
import simd

/// The lighting states of the look-fix lighting bible (docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md
/// §2.2 targets, §2.3 shade tints), named as the keys of `Profiles/postcard-grade.json`.
public enum PostcardLightState: String, CaseIterable, Codable, Sendable {
    case morning, midday, ordinary, golden, blue, overcast
    case lightRain = "light-rain"
    case storm, fog, snow
    case moonNight = "moon-night"
    case moonlessNight = "moonless-night"

    /// What `resolve` reads, renderer-neutral (WorldEngine fills it from the environment).
    public struct Conditions: Sendable, Equatable {
        /// Sun elevation, degrees.
        public var sunElevation: Double
        /// Sun azimuth, degrees clockwise from true north.
        public var sunAzimuth: Double
        /// The dominant weather label (clear, cloudy, rain, snow, fog, haze, smoke, dust, thunderstorm).
        public var weather: String?
        /// Weather intensity 0–1.
        public var intensity: Double
        /// Cloud cover 0–1.
        public var cloudCover: Double
        /// Moon altitude, degrees, and illuminated fraction 0–1.
        public var moonAltitude: Double
        public var moonIlluminatedFraction: Double
        /// (time − sunrise) / (sunset − sunrise) for the day, when the sun rises and sets that day.
        public var dayFraction: Double?

        public init(sunElevation: Double, sunAzimuth: Double, weather: String? = nil, intensity: Double = 0, cloudCover: Double = 0,
                    moonAltitude: Double = -90, moonIlluminatedFraction: Double = 0, dayFraction: Double? = nil) {
            self.sunElevation = sunElevation
            self.sunAzimuth = sunAzimuth
            self.weather = weather
            self.intensity = intensity
            self.cloudCover = cloudCover
            self.moonAltitude = moonAltitude
            self.moonIlluminatedFraction = moonIlluminatedFraction
            self.dayFraction = dayFraction
        }
    }

    /// The bible state for a moment. In order:
    /// 1. Night, sun below −6° (after civil dusk): `moonNight` when the Moon is above the horizon,
    ///    at least a quarter lit and the cloud cover under 0.6, else `moonlessNight`. Weather
    ///    doesn't change the night states.
    /// 2. Weather, which sets the light by day and twilight: thunderstorm, or rain of intensity
    ///    ≥ 0.6 → `storm`; rain → `lightRain`; snow falling → `snow`; fog, haze, smoke or dust →
    ///    `fog`; cloudy, or cloud cover ≥ 0.8 → `overcast`.
    /// 3. The sun: −6°…0° → `blue`; 0°…10° → `golden` (morning or evening); above 10° by the share
    ///    of the daylight gone: before 0.38 → `morning`, after 0.62 → `ordinary` (afternoon),
    ///    else `midday`. Without sunrise and sunset (polar day) the sun's side of the sky decides:
    ///    `midday` at 50° and above, else `morning` in the east, `ordinary` in the west.
    public static func resolve(_ c: Conditions) -> PostcardLightState {
        if c.sunElevation < -6 {
            return c.moonAltitude > 0 && c.moonIlluminatedFraction >= 0.25 && c.cloudCover < 0.6 ? .moonNight : .moonlessNight
        }
        switch c.weather {
        case "thunderstorm": return .storm
        case "rain": return c.intensity >= 0.6 ? .storm : .lightRain
        case "snow": return .snow
        case "fog", "haze", "smoke", "dust": return .fog
        case "cloudy": return .overcast
        default: if c.cloudCover >= 0.8 { return .overcast }
        }
        if c.sunElevation < 0 { return .blue }
        if c.sunElevation < 10 { return .golden }
        if let f = c.dayFraction {
            return f < 0.38 ? .morning : (f > 0.62 ? .ordinary : .midday)
        }
        if c.sunElevation >= 50 { return .midday }
        let azimuth = (c.sunAzimuth.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return azimuth < 180 ? .morning : .ordinary
    }
}

/// One state's final grade for quality-mode postcards, applied after `WorldPostProcess` in
/// display-referred values (0–1): lift/gamma/gain per channel, saturation around Rec. 709 luma,
/// then a push of shaded pixels toward the state's shade tint (bible §2.3). Identity by default.
public struct PostcardGrade: Codable, Sendable, Equatable {
    /// RGB lift, gamma and gain: out = (gain·(x + lift·(1 − x)))^(1/gamma).
    public var lift: [Double]
    public var gamma: [Double]
    public var gain: [Double]
    /// 1 = unchanged.
    public var saturation: Double
    /// The bible's shade tint for the state (sRGB hex).
    public var shadeTint: String
    /// How far shaded pixels move toward the shade tint's hue at their own brightness (0 = not at all).
    public var shadeTintStrength: Double

    public init(lift: [Double] = [0, 0, 0], gamma: [Double] = [1, 1, 1], gain: [Double] = [1, 1, 1], saturation: Double = 1,
                shadeTint: String = "#808080", shadeTintStrength: Double = 0) {
        self.lift = lift
        self.gamma = gamma
        self.gain = gain
        self.saturation = saturation
        self.shadeTint = shadeTint
        self.shadeTintStrength = shadeTintStrength
    }

    public static let identity = PostcardGrade()

    /// True when the grade changes nothing (the renderer then skips it).
    public var isIdentity: Bool {
        Self.triple(lift, 0) == SIMD3(0, 0, 0) && Self.triple(gamma, 1) == SIMD3(1, 1, 1) && Self.triple(gain, 1) == SIMD3(1, 1, 1)
            && saturation == 1 && shadeTintStrength == 0
    }

    public var liftRGB: SIMD3<Double> { Self.triple(lift, 0) }
    public var gammaRGB: SIMD3<Double> { Self.triple(gamma, 1) }
    public var gainRGB: SIMD3<Double> { Self.triple(gain, 1) }

    /// The shade tint as sRGB 0–1.
    public var shadeTintRGB: SIMD3<Double> {
        var hex = shadeTint.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let v = UInt32(hex, radix: 16) else { return SIMD3(0.5, 0.5, 0.5) }
        return SIMD3(Double((v >> 16) & 0xFF), Double((v >> 8) & 0xFF), Double(v & 0xFF)) / 255
    }

    static func triple(_ a: [Double], _ fallback: Double) -> SIMD3<Double> {
        SIMD3(a.count > 0 ? a[0] : fallback, a.count > 1 ? a[1] : fallback, a.count > 2 ? a[2] : fallback)
    }

    /// The grade on one display-referred colour (the reference for the GPU kernel and the tests).
    public func apply(_ c: SIMD3<Double>, shadeThreshold: Double, shadeSoftness: Double) -> SIMD3<Double> {
        let lift = liftRGB, gamma = gammaRGB, gain = gainRGB
        var x = simd_clamp(c, SIMD3(repeating: 0), SIMD3(repeating: 1))
        if lift != SIMD3(repeating: 0) || gain != SIMD3(repeating: 1) {
            x = simd_clamp(gain * (x + lift * (1 - x)), SIMD3(repeating: 0), SIMD3(repeating: 1))
        }
        if gamma != SIMD3(repeating: 1) {
            x = SIMD3(pow(x.x, 1 / gamma.x), pow(x.y, 1 / gamma.y), pow(x.z, 1 / gamma.z))
        }
        let weights = SIMD3<Double>(0.2126, 0.7152, 0.0722)
        if saturation != 1 {
            let y = simd_dot(x, weights)
            x = SIMD3(repeating: y) + (x - SIMD3(repeating: y)) * saturation
        }
        if shadeTintStrength > 0 {
            let t = shadeTintRGB
            let ty = max(simd_dot(t, weights), 1e-4)
            let shade = 1 - Self.smoothstep(shadeThreshold - shadeSoftness, shadeThreshold, simd_dot(x, weights))
            let tinted = t * (simd_dot(x, weights) / ty)
            x += (tinted - x) * (shadeTintStrength * shade)
        }
        return simd_clamp(x, SIMD3(repeating: 0), SIMD3(repeating: 1))
    }

    static func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - e0) / max(e1 - e0, 1e-6)))
        return t * t * (3 - 2 * t)
    }
}

/// `Profiles/postcard-grade.json`: one final grade per lighting state, for quality-mode postcards.
public struct PostcardGradeTable: Codable, Sendable, Equatable {
    public var schema: String
    public var comment: String?
    /// Display-referred luma below which a pixel counts as shade, fading in over `shadeSoftness`.
    public var shadeThreshold: Double
    public var shadeSoftness: Double
    public var states: [String: PostcardGrade]

    public static let resourceName = "postcard-grade"

    public static func bundled() throws -> PostcardGradeTable {
        try JSONDecoder().decode(PostcardGradeTable.self, from: StyleLibrary.data(resourceName))
    }

    /// The grade for a state (identity when the table has none).
    public func grade(for state: PostcardLightState) -> PostcardGrade {
        states[state.rawValue] ?? .identity
    }
}
