import Foundation

/// Renderer-neutral look values beyond the lighting bible and the rain pack (`Profiles/look.json`):
/// water, sky, wet paving and shadow range. Both renderers read them; see docs/look-spec-changes.md.
public struct LookSpec: Codable, Sendable {
    public struct Water: Codable, Sendable {
        /// How much of the water's colour is the reflected sky, clear and overcast (blended by cover).
        public var skyReflectClear: Double
        public var skyReflectOvercast: Double
        /// Saturation left in the water under full overcast.
        public var overcastSaturation: Double
        /// Ripple ring strength on open water while it rains.
        public var rainRipples: Double
        /// Brightness of the reflected sky under full overcast (a storm lake reads dark slate, not light grey).
        public var overcastReflectGain: Double
    }
    public struct Sky: Codable, Sendable {
        /// Width of a cloud edge in noise units, clear sky and full overcast (soft edges as the deck closes,
        /// so a gap never reads as a cut-out shape).
        public var cloudEdgeClear: Double
        public var cloudEdgeOvercast: Double
    }
    /// Departure from the rain pack (owner, 7 Oct): its ≤12% paving darkening read dry on the phone, so
    /// the pack's concrete and asphalt darkening is scaled by `darkenScale` (capped at `darkenMax`).
    public struct WetPaving: Codable, Sendable {
        public var darkenScale: Double
        public var darkenMax: Double
        public var surfaces: [String]
    }
    /// Sun shadow coverage from the camera (RealityKit fits its cascades inside it): normal and
    /// below `lowSunBelowDeg` of sun elevation, when shadows grow long.
    public struct Shadows: Codable, Sendable {
        public var rangeM: Double
        public var lowSunRangeM: Double
        public var lowSunBelowDeg: Double
        /// Beyond the range, lawns and paths darken under the canopy map shifted along the sun by a
        /// typical crown's shadow (`blobCrownHeightM`), by `blobStrength` in full direct sun.
        public var blobStrength: Double
        public var blobCrownHeightM: Double
    }
    /// Engine calibration for the daytime master (not look values: those come from mock-values.json):
    /// key and fill multipliers that bring a neutral patch's shadow/lit ratio to the master's.
    public struct DaytimeMasterCalibration: Codable, Sendable {
        public var key: Double
        public var fill: Double
        /// The master's "+0.35 EV once" realised as the auto-exposure target: the four approved heroes'
        /// measured mean display brightness (Y8, 16:9 picture area). A gain on top of our auto exposure
        /// overshot the heroes by ~15 Y8 (they brighten far less than 0.35 EV over the captures).
        public var exposureTargetY8: Double
    }
    public var daytimeMaster: DaytimeMasterCalibration
    public var water: Water
    public var sky: Sky
    public var shadows: Shadows
    public var wetPaving: WetPaving
}

extension StyleLibrary {
    /// `Profiles/look.json`.
    public static func look() throws -> LookSpec {
        try JSONDecoder().decode(LookSpec.self, from: data("look"))
    }
}
