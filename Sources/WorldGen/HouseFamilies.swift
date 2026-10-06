import Foundation
import simd
import WorldGeo
import WorldMap

/// Per-family building grammar (Profiles/house-families.json): what a house family's roof and
/// facade look like beyond the profile's ranges and colors. Keyed by the profile's house type IDs,
/// so regions stay data: a profile chooses families and weights; this file says how each family
/// is built. Unknown IDs get the plain default grammar. Nothing here names a place.
public struct HouseFamilyGrammar: Codable, Sendable, Equatable {
    public struct Roof: Codable, Sendable, Equatable {
        /// gable | hip; nil = the profile's roof mix (or the OSM tag).
        public var wingForm: RoofMass.Form?
        public var ridge: RoofRecipe.Ridge?
        public var crossGable: Double?
        public var crossGableWidth: [Double]?
        public var crossGableCentered: Bool?
        public var crossGablePitchBoost: Double?
        /// Chance of a flush crossing gable on a side wall of a front-gabled house.
        public var sideCrossGable: Double?
        /// Dormer count range on the street-facing slope, the chance of having any, and front width.
        public var dormers: [Int]?
        public var dormerChance: Double?
        public var dormerWidth: [Double]?
        /// Chimney likelihood (nil = the profile's) and placement: end | front | central | rear.
        public var chimney: Double?
        public var chimneyPlacement: String?
        /// Chimney top well above the ridge.
        public var chimneyTall: Bool?
        /// Broad (Prairie) chimney.
        public var chimneyBroad: Bool?
    }

    public struct Facade: Codable, Sendable, Equatable {
        /// Up to two broad dark strips on a street-facing gable, with a trim-colored panel above the eave.
        public var halfTimber: Bool?
        /// Gable walls above the eave line use the trim color.
        public var gablePanel: Bool?
        /// Centered door and mirrored window bays.
        public var symmetric: Bool?
        /// Horizontal trim bands at floor and sill lines.
        public var bands: Bool?
        /// Windows grouped in ribbons of 2–3.
        public var groupedWindows: Bool?
        /// Projecting band at the top of the street wall (flat roofs).
        public var cornice: Bool?
        /// Wall colors for the non-street walls (e.g. stone fronts on brick masses), chosen stably.
        public var sideWall: [String]?
        /// A small gable over the door.
        public var entryPediment: Bool?
        /// Raised entry with steps (uses the profile's foundation height).
        public var stoop: Bool?
        /// Likelihood of a stacked wooden rear porch where the rear faces a mapped alley with room.
        public var rearPorch: Double?
        /// Ground-floor shopfront band with larger openings and a plain sign panel.
        public var storefront: Bool?
        /// A small window high in street-facing gable ends.
        public var attic: Bool?
        /// Taller window proportion (stacked city facades).
        public var tallWindows: Bool?
        /// Porch style and likelihood instead of the profile's (e.g. a covered porch for Queen Anne).
        public var porchStyle: String?
        public var porchLikelihood: Double?

        // Facade pass (gaps 1 and 5 of the 5B gate). All optional: unset means the old behavior.

        /// Window width / height ranges in meters instead of the profile's (tallWindows is then ignored).
        public var windowWidth: [Double]?
        public var windowHeight: [Double]?
        /// Windows per street-facing group when `groupedWindows` (default 2; Prairie ribbons use 3).
        public var windowGroup: Int?
        /// Entry kit instead of the plain stoop/canopy: portico | vestibule | surround.
        public var entry: String?
        /// Likelihood of the entry kit (default 1); otherwise the old entry (pediment/canopy).
        public var entryChance: Double?
        /// Masonry openings (near only): a projecting sill under and a lintel over each window
        /// on street-facing walls and bay faces, in the trim (stone) color.
        public var lintels: Bool?
        /// Dress protrusions of the mapped footprint on the street side as bays (windows on every
        /// face, cornice around flat-roofed ones).
        public var mappedBays: Bool?
        /// An inferred shallow bay on the street facade where the mapped footprint has none.
        public var bay: Bay?
        /// Long side walls (≥ 12 m, not street-facing): grouped, smaller windows aligned per
        /// story with blank stretches between; no openings on walls that touch a neighbor.
        public var sideRhythm: Bool?
        /// Side-wall window size relative to the front windows (default 0.85).
        public var sideWindowScale: Double?
    }

    /// An inferred street bay (a user-requested exception to "no unmapped volume": kept shallow,
    /// only where the space in front of the facade is clear).
    public struct Bay: Codable, Sendable, Equatable {
        public var chance: Double?
        /// Story counts to choose from (e.g. [1, 2]); nil = full wall height.
        public var stories: [Int]?
        /// angled (three-sided, 45°) | box | nil (either).
        public var form: String?
        /// Overall width along the wall and projection, in meters.
        public var width: [Double]?
        public var depth: [Double]?
    }

    /// Preferred frontage width / depth (soft eligibility).
    public var aspect: [Double]?
    /// Preferred footprint area in m² (soft eligibility).
    public var area: [Double]?
    /// house (default) or block: block families never enter the detached-house lottery.
    public var role: String?
    /// Block families: the evidence that selects them (tall | court | commercial | apartments).
    public var evidence: String?
    public var roof: Roof?
    public var facade: Facade?

    public init() {}

    /// Soft fit of a value to a preferred range: 1 inside, falling to 0.2 well outside.
    /// Families without a preference get a neutral 0.6, so they neither win nor vanish.
    static func fit(_ x: Double, _ range: [Double]?) -> Double {
        guard let r = range, r.count >= 2 else { return 0.6 }
        if x >= r[0], x <= r[1] { return 1 }
        let d = x < r[0] ? (r[0] - x) / max(r[0], 1e-6) : (x - r[1]) / max(r[1], 1e-6)
        return max(0.2, 1 - 2.5 * d)
    }
}

public struct HouseFamilyLibrary: Codable, Sendable, Equatable {
    public var version: Int
    public var families: [String: HouseFamilyGrammar]

    public init(version: Int = 1, families: [String: HouseFamilyGrammar] = [:]) {
        self.version = version
        self.families = families
    }

    public func grammar(_ id: String?) -> HouseFamilyGrammar { id.flatMap { families[$0] } ?? HouseFamilyGrammar() }

    /// The bundled library (empty if the file is missing, so generation never fails on it).
    public static let bundled: HouseFamilyLibrary = {
        guard let data = try? StyleLibrary.data("house-families"),
              let lib = try? JSONDecoder().decode(HouseFamilyLibrary.self, from: data) else { return HouseFamilyLibrary() }
        return lib
    }()
}

// MARK: - Family assignment

/// Frontage width / depth of a footprint: extent along the street-facing edge over extent across it.
func frontageAspect(_ ring: Ring, shape: FootprintAnalysis, frontEdge: Int?) -> Double {
    guard let e = frontEdge else { return 1 }
    let (_, dir, n, _) = BuildingGenerator.edge(ring, e)
    func extent(_ axis: LocalPoint) -> Double {
        let v = shape.obb.corners.map { simd_dot($0, axis) }
        return v.max()! - v.min()!
    }
    return extent(dir) / max(extent(n), 0.01)
}

extension BuildingGenerator {
    /// Evidence for a block (non-house) building's role, strongest first. Tags only, never
    /// a regional expectation: an unresolved block stays a plain mass.
    static func blockEvidence(_ b: Building, shape: FootprintAnalysis) -> [String] {
        var out: [String] = []
        let levels = b.levels.map { Int($0.rounded()) }
        if (levels ?? 0) >= 5 || (b.hasHeightTag && b.height.top >= 16) { out.append("tall") }
        if !b.footprint.holes.isEmpty { out.append("court") }
        let commercialTypes: Set<String> = ["commercial", "retail", "mixed_use", "mixed-use"]
        if commercialTypes.contains(b.type) || b.tags["shop"] != nil || b.tags["building:use"].map(commercialTypes.contains) == true
            || ["restaurant", "cafe", "bar", "pub", "fast_food", "bank", "pharmacy"].contains(b.tags["amenity"] ?? "") {
            out.append("commercial")
        }
        let residentialTypes: Set<String> = ["apartments", "residential", "dormitory"]
        if residentialTypes.contains(b.type) || (b.type == "yes" && (2...4).contains(levels ?? 0) && b.footprint.area >= 220) {
            out.append("apartments")
        }
        return out
    }

    /// The family for a block building: the first evidence kind the profile has a family for,
    /// else the profile's plain flat-roofed type.
    func blockFamily(for b: Building, shape: FootprintAnalysis) -> StyleProfile.HouseType? {
        for ev in Self.blockEvidence(b, shape: shape) {
            let matches = profile.houseTypes.filter { families.grammar($0.id).evidence == ev }
            if !matches.isEmpty {
                var r = b.ref.random("block-family")
                return r.pick(matches) { _ in 1 }
            }
        }
        return profile.houseTypes.first { $0.roof.flat >= 1 && families.grammar($0.id).evidence == nil }
            ?? profile.houseTypes.first { $0.roof.flat >= 1 } ?? profile.houseTypes.last
    }

    /// House family: the profile's situation weights, its eligibility rules, then the grammar's
    /// soft fit to frontage aspect and area. Stable per building.
    public func houseFamily(for b: Building, shape: FootprintAnalysis, frontEdge: Int?) -> (StyleProfile.HouseType, String) {
        let ring = b.footprint.outer
        var broadFront = false
        if let e = frontEdge {
            let (_, dir, _, _) = Self.edge(ring, e)
            broadFront = abs(simd_dot(dir, shape.obb.u)) > 0.85
        }
        let key = situation(b, shape: shape, broadFront: broadFront)
        let weights = profile.typeRules[key] ?? profile.typeRules["unknown"] ?? [:]
        let aspect = shape.obb.halfWidth > 0 ? shape.obb.halfLength / shape.obb.halfWidth : 1
        let frontage = frontageAspect(ring, shape: shape, frontEdge: frontEdge)
        let levels = b.levels.map { Int($0.rounded()) }
        func eligible(_ t: StyleProfile.HouseType) -> Bool {
            if families.grammar(t.id).role == "block" { return false }
            if let l = levels, l > 0, !t.floors.contains(l) { return false }
            if let m = t.minAspect, aspect < m { return false }
            if let m = t.maxAspect, aspect > m { return false }
            if let q = t.minRectangularity, shape.rectangularity < q { return false }
            if t.broadFrontage == true, !broadFront { return false }
            return true
        }
        let all = weights.keys.sorted().compactMap { id in profile.houseType(id).map { ($0, weights[id]!) } }
        let candidates = all.filter { eligible($0.0) }
        let pool = candidates.isEmpty ? all : candidates
        var r = b.ref.random("house-type")
        let chosen = r.pick(pool) { item in
            let g = families.grammar(item.0.id)
            return item.1 * HouseFamilyGrammar.fit(frontage, g.aspect) * HouseFamilyGrammar.fit(b.footprint.area, g.area)
        }.0
        return (chosen, key)
    }
}

extension StyleProfile.Thresholds {
    /// Area thresholds relative to the local houses (P1 / owner decision): with percentile fields
    /// and at least `minCandidates` house footprints, small/large/huge are those percentiles of the
    /// local areas; otherwise the absolute values stay.
    public func resolved(houseAreas: [Double], minCandidates: Int = 30) -> StyleProfile.Thresholds {
        guard houseAreas.count >= minCandidates else { return self }
        let sorted = houseAreas.sorted()
        func pct(_ q: Double) -> Double {
            let x = max(0, min(1, q)) * Double(sorted.count - 1)
            let lo = Int(x.rounded(.down)), hi = min(sorted.count - 1, lo + 1)
            return sorted[lo] + (sorted[hi] - sorted[lo]) * (x - Double(lo))
        }
        var t = self
        if let q = smallAreaPercentile { t.smallArea = pct(q) }
        if let q = largeAreaPercentile { t.largeArea = pct(q) }
        if let q = hugeAreaPercentile { t.hugeArea = max(pct(q), t.largeArea) }
        return t
    }
}
