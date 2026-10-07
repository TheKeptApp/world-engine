import Foundation

/// Renderer-neutral look values beyond the lighting bible (`Profiles/look.json`): wet ground,
/// puddles and rain streaks. Both renderers read them; see docs/look-spec-changes.md.
public struct LookSpec: Codable, Sendable {
    public struct Surface: Codable, Sendable {
        /// Diffuse darkening when soaked, wet roughness, puddle share of flat paving when soaked.
        public var darken: Double
        public var roughness: Double
        public var puddles: Double
    }
    public struct Wet: Codable, Sendable {
        public var asphalt: Surface
        public var walk: Surface
        public var lawnDarken: Double
        /// Sky sheen floor on wet paving (reads when looking down at it).
        public var pavingGloss: Double
        /// Share of the soaked response that light rain (wetness ~0.65) already shows.
        public var lightRainResponse: Double
        /// Wetness at which puddles start.
        public var puddleStart: Double
        /// Puddle base relative to the wet ground under it (puddles read as water, not holes).
        public var puddleBase: Double
        /// Sky reflection in puddles: [floor, cap].
        public var puddleReflect: [Double]
        /// Ripple ring strength in puddles while it rains.
        public var ripples: Double
    }
    public struct Rain: Codable, Sendable {
        public var drops: Int
        /// Streak width (m) and length as a multiple of it.
        public var width: Double
        public var stretch: Double
        public var color: String
        public var opacity: Double
    }
    public struct Water: Codable, Sendable {
        /// How much of the water's colour is the reflected sky, clear and overcast (blended by cover).
        public var skyReflectClear: Double
        public var skyReflectOvercast: Double
        /// Saturation left in the water under full overcast.
        public var overcastSaturation: Double
        /// Ripple ring strength on open water while it rains.
        public var rainRipples: Double
    }
    public var wet: Wet
    public var rain: Rain
    public var water: Water
}

extension StyleLibrary {
    /// `Profiles/look.json`.
    public static func look() throws -> LookSpec {
        try JSONDecoder().decode(LookSpec.self, from: data("look"))
    }
}
