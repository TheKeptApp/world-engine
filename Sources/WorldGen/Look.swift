import Foundation

/// Renderer-neutral look values beyond the lighting bible and the rain pack (`Profiles/look.json`):
/// water, sky and wet paving. Both renderers read them; see docs/look-spec-changes.md.
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
    /// Phone-size house contrast (generator; owner 7 Oct): house-contrast-v1 swatches per house type, baked
    /// into the base colour of house-details families, because ambient AO alone doesn't show in sun.
    public struct HouseContrast: Codable, Sendable, Equatable {
        public struct HouseType: Codable, Sendable, Equatable {
            /// Trim, roof, soffit and porch-underside colours (sRGB, the pack's swatches).
            public var trim: String
            public var roof: String
            public var soffit: String
            public var porchShadow: String
            /// Daytime window glass (dark, so openings read at phone size; night lighting keys off the glass flag).
            public var glass: String
            /// Eave/cornice shadow brightness relative to the wall (wall = 1).
            public var eaveShadow: Double
        }
        public var source: String?
        /// Height (m) of the wall band under eaves and cornices that fades to `eaveShadow`.
        public var eaveBandHeight: Double
        public var types: [String: HouseType]
        /// Family ID → type ID; "flat" = chicago_two_flat below three storeys, chicago_three_flat from three.
        public var families: [String: String]

        public func type(family: String?, floors: Int) -> HouseType? {
            guard let f = family, let id = families[f] else { return nil }
            if id == "flat" { return types[floors >= 3 ? "chicago_three_flat" : "chicago_two_flat"] }
            return types[id]
        }
    }
    public var water: Water
    public var sky: Sky
    public var wetPaving: WetPaving
    public var houseContrast: HouseContrast?

    /// The bundled look values (nil if the file is missing).
    public static let bundled: LookSpec? = try? StyleLibrary.look()
}

extension StyleLibrary {
    /// `Profiles/look.json`.
    public static func look() throws -> LookSpec {
        try JSONDecoder().decode(LookSpec.self, from: data("look"))
    }
}
