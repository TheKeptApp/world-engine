import Foundation

/// Yard and street-tree rules for one style profile (Profiles/yards.json). Generator data, not
/// a profile schema change: profiles choose the house families; this says how their yards are dressed.
public struct YardRules: Codable, Sendable, Equatable {
    /// How far (m) from its house a yard may reach (inferred lot cells beyond stay plain lawn).
    public var maxLotDepth: Double
    /// Spacing (m) of generated parkway trees; nil = no generated street trees.
    public var streetTreeSpacing: Double?
    /// Narrowest planting strip (m) between curb and sidewalk that gets a street tree.
    public var minParkway: Double
    /// Mean specimen trees per house lot.
    public var yardTreesPerHouse: Double
    /// Likelihood of a low hedge along the front lot line, and along a side lot line in the front yard.
    public var frontHedge: Double
    public var sideHedge: Double
    /// Extra shrubs per lot (min, max) besides foundation planting.
    public var shrubs: [Int]
    /// Likelihood of a mulched foundation bed along the front wall.
    public var beds: Double
    /// Lawn shade range per lot (palette shade multiplier).
    public var lawnShade: [Double]
    /// Likelihood of a front walk from the door to the sidewalk or street.
    public var frontWalk: Double
    /// Share of the profile's measured `trees.canopyShare` to reach by planting extra yard trees
    /// (nil = no canopy calibration).
    public var canopyFill: Double?
    /// Ceiling on mapped + generated trees per km² (render budget), applied to canopy planting.
    public var maxTreesPerKm2: Double?
    /// Regional lawn endpoint pairs per season (sRGB hex, look-fix §1.1): spring, summer, fall,
    /// winter → [low, high]. Lots carry their position between the pair (vertex extra.y); the
    /// renderer mixes the endpoints in linear light.
    public var lawnEndpoints: [String: [String]]?
    /// Foundation bed area per lot, m² (look-fix §1.2), reached with depth 0.6–1.2 m and side returns.
    public var bedArea: [Double]?
    /// Most generated trees (yard + canopy) per lot.
    public var maxYardTreesPerLot: Int?
    /// Likelihood that the front yard is a planted garden (bed + shrubs) instead of lawn (city zones).
    public var frontGarden: Double?
    /// Likelihood that the rear yard is paved (patio, parking pad) instead of lawn.
    public var rearPaving: Double?
    /// Likelihood of a low iron fence along the front lot line, and of a wooden privacy fence on the
    /// alley side (both inferred dressing, gaps at walks, drives and garages).
    public var frontFence: Double?
    public var rearFence: Double?
    /// Broad tonal patches per lot lawn (min, max; look-fix §1.1: 3–5, ±3–6 %).
    public var lawnPatches: [Int]?
    /// Share of front lawns with mowing bands (2.5–4 m, ≤ 4 bands, 3 % contrast; at most half of suburban lawns).
    public var mowShare: Double?
    /// Likelihood of a worn strip beside each walk or driveway (0.3–0.7 m, one side, part of its length).
    public var wornEdges: Double?
    /// Parkway strips between curb and sidewalk drawn as their own lawn band (drier, darker at the curb).
    public var parkwayBand: Bool?
    /// Lawn detail contrast (nil = the look-fix spec values, `GroundContrast.spec`).
    public var groundContrast: GroundContrast?
}

public struct YardLibrary: Codable, Sendable, Equatable {
    public var version: Int
    public var rules: [String: YardRules]

    public func rules(for profileID: String) -> YardRules {
        rules[profileID] ?? rules["default"] ?? YardLibrary.fallback
    }

    static let fallback = YardRules(maxLotDepth: 30, streetTreeSpacing: 20, minParkway: 1.2, yardTreesPerHouse: 0.8, frontHedge: 0.1,
                                    sideHedge: 0.1, shrubs: [1, 3], beds: 0.5, lawnShade: [0.93, 1.06], frontWalk: 0.85,
                                    canopyFill: nil, maxTreesPerKm2: nil, lawnEndpoints: nil, bedArea: nil, maxYardTreesPerLot: nil,
                                    frontGarden: nil, rearPaving: nil, frontFence: nil, rearFence: nil,
                                    lawnPatches: nil, mowShare: nil, wornEdges: nil, parkwayBand: nil, groundContrast: nil)

    /// The bundled library (fallback rules if the file is missing).
    public static let bundled: YardLibrary = {
        guard let data = try? StyleLibrary.data("yards"), let lib = try? JSONDecoder().decode(YardLibrary.self, from: data) else {
            return YardLibrary(version: 0, rules: [:])
        }
        return lib
    }()
}
