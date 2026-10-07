import Foundation

/// The rain pack as engine data: `Profiles/rain-bible.json`, generated from docs/proposals/rain-v1 by
/// scripts/rainfix_data.py (never edited by hand). Wetness states with per-surface darkening,
/// roughness and sheen; puddles; rain and lamp streaks.
public struct RainBible: Codable, Sendable {
    public struct Surface: Codable, Sendable, Equatable {
        public var darken: Double
        public var roughness: Double
        public var sheen: Double
        public init(darken: Double, roughness: Double, sheen: Double) {
            self.darken = darken
            self.roughness = roughness
            self.sheen = sheen
        }
        func mixed(_ b: Surface, _ t: Double) -> Surface {
            Surface(darken: darken + (b.darken - darken) * t, roughness: roughness + (b.roughness - roughness) * t,
                    sheen: sheen + (b.sheen - sheen) * t)
        }
    }
    public struct State: Codable, Sendable {
        public var id: String
        public var wetness: Double
        public var rainIntensity: Double
        public var rainCountStreet: Int
        public var rainCountAerial: Int
        public var puddleCoverage: Double
        public var surfaces: [String: Surface]
    }
    public struct Puddles: Codable, Sendable {
        public var roughness: Double
        public var skyMixNormal: Double
        public var skyMixGrazing: Double
        public var maxCoverage: Double
    }
    public struct Rain: Codable, Sendable {
        public var speedMps: Double
        public var streakLengthM: [Double]
        public var opacityLight: Double
        public var opacitySteady: Double
        public var opacityHeavy: Double
        public var nightOpacity: Double
        public var distanceFadeM: [Double]
        public var maxRainStreaks: Int
    }
    public struct Lamps: Codable, Sendable {
        public var maxFieldsGlobal: Int
        public var lengthM: [Double]
        public var widthM: [Double]
        public var opacityDusk: Double
        public var opacityNight: Double
        public var fadeDistanceM: [Double]
        public var color: String
    }
    public struct Source: Codable, Sendable { public var path: String; public var sha256: String }
    public var source: Source
    public var states: [State]
    public var puddles: Puddles
    public var rain: Rain
    public var lampStreaks: Lamps

    public static let surfaceNames = ["concrete", "asphalt", "brick", "lawn", "roof"]

    /// Surface values and puddle cover at a wetness: rising states (dry → damp → light rain →
    /// steady → soaked) interpolated in wetness; "drying" is a falling-wetness preview, not used here.
    public func at(wetness w: Double) -> (surfaces: [String: Surface], puddleCoverage: Double) {
        let rising = states.filter { $0.id != "drying" }.sorted { $0.wetness < $1.wetness }
        let dry = Surface(darken: 0, roughness: 1, sheen: 0)
        var lo = (w: 0.0, s: Dictionary(uniqueKeysWithValues: Self.surfaceNames.map { ($0, dry) }), p: 0.0)
        for st in rising {
            if w <= st.wetness {
                let t = st.wetness > lo.w ? (w - lo.w) / (st.wetness - lo.w) : 1
                var out: [String: Surface] = [:]
                for n in Self.surfaceNames {
                    let a = lo.s[n] ?? dry, b = st.surfaces[n] ?? dry
                    // Roughness of "dry" means unchanged: use the wet row's from the first state.
                    let a2 = lo.w == 0 ? Surface(darken: 0, roughness: b.roughness, sheen: 0) : a
                    out[n] = a2.mixed(b, t)
                }
                return (out, lo.p + (st.puddleCoverage - lo.p) * t)
            }
            lo = (st.wetness, st.surfaces, st.puddleCoverage)
        }
        return (lo.s, lo.p)
    }
}

extension StyleLibrary {
    public static func rainBible() throws -> RainBible {
        try JSONDecoder().decode(RainBible.self, from: data("rain-bible"))
    }
}
