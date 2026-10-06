import Foundation
import WorldGeo

/// How building heights are filled in when OSM has no `height` tag.
/// Data, not code: apps and future data sources (Overture, lidar) can replace any of it.
public struct HeightRules: Sendable {
    public var metersPerLevel = 3.2
    /// Height by `building=*` value when neither `height` nor `building:levels` is tagged.
    public var typeDefaults: [String: Double] = [
        "house": 7.0, "detached": 7.0, "semidetached_house": 7.0, "bungalow": 4.5,
        "residential": 8.0, "terrace": 8.0,
        "garage": 3.0, "garages": 3.0, "carport": 3.0,
        "shed": 2.5, "hut": 2.5, "cabin": 3.5,
        "roof": 3.0,
        "apartments": 12.8,
        "commercial": 5.0, "retail": 5.0, "kiosk": 3.0, "supermarket": 6.0,
        "office": 10.0,
        "church": 10.0, "chapel": 8.0,
        "school": 8.0, "university": 12.0, "civic": 8.0, "public": 8.0,
        "industrial": 7.0, "warehouse": 7.0,
        "toilets": 3.0, "service": 3.0, "boathouse": 4.0,
    ]
    public var fallbackDefault = 6.0
    /// Seeded ±fraction applied to fallback heights so identical houses don't look stamped out.
    public var jitterFraction = 0.10

    public init() {}

    public func resolve(tags: Tags, type: String, ref: OSMRef) -> BuildingHeight {
        let base = tags["min_height"].flatMap(TagParsing.length)
            ?? tags["building:min_level"].flatMap(TagParsing.number).map { $0 * metersPerLevel }
            ?? 0

        if let h = tags["height"].flatMap(TagParsing.length) {
            return BuildingHeight(base: base, top: max(h, base + 0.5), source: .heightTag)
        }
        var rng = ref.random("height-jitter")
        let jitter = 1 + rng.range(-jitterFraction, jitterFraction)
        if let levels = tags["building:levels"].flatMap(TagParsing.number), levels > 0 {
            let roofLevels = tags["roof:levels"].flatMap(TagParsing.number) ?? 0
            let h = (levels + roofLevels) * metersPerLevel * jitter
            return BuildingHeight(base: base, top: max(h, base + 0.5), source: .levels)
        }
        let h = (typeDefaults[type] ?? fallbackDefault) * jitter
        return BuildingHeight(base: base, top: max(h, base + 0.5), source: .typeDefault)
    }
}

/// How road and path widths are chosen when OSM has no `width` tag.
///
/// Carriageway (curb-to-curb) width, in order:
/// 1. A tagged `width` (≤ 60 m) wins and is never changed.
/// 2. `lanes` × `laneWidth` (for `parkingKinds` at least `minTravelWidth`), plus
///    `parkingLaneWidth` per side with on-street parking, for the kinds in `parkingKinds`.
///    Untagged sides are assumed to have parking; `parking:*` / `parking:lane:*` tags remove sides.
/// 3. Otherwise `defaultWidths[kind]`, which for `parkingKinds` already includes parking on both
///    sides; each side tagged without parking takes `parkingLaneWidth` off.
/// `MapFeatureBuilder` then clamps untagged roads so the curb stays `sidewalkClearance` clear of a
/// mapped sidewalk running alongside.
public struct RoadRules: Sendable {
    public var laneWidth = 3.3
    public var defaultWidths: [HighwayKind: Double] = [
        .motorway: 14, .trunk: 13, .primary: 12, .secondary: 10, .tertiary: 8,
        .residential: 8, .unclassified: 6, .livingStreet: 5, .road: 6, .busway: 6,
        .service: 4, .track: 3,
        .pedestrian: 4, .cycleway: 2.5, .footway: 2, .path: 2, .bridleway: 2.5, .steps: 2,
        .corridor: 2, .other: 3,
    ]
    /// Kinds that get a parking allowance on each side unless tags say otherwise.
    public var parkingKinds: Set<HighwayKind> = [.residential, .tertiary, .unclassified, .secondary]
    /// Width of one parallel parking lane.
    public var parkingLaneWidth = 2.3
    /// Narrowest travel width (between parked cars) of a `parkingKinds` street: a `lanes=1` street
    /// still has room to pass parked cars, open doors and oncoming or emergency traffic.
    public var minTravelWidth = 4.5
    /// Narrowest carriageway the sidewalk clamp may leave.
    public var minCarriagewayWidth = 3.0
    /// Gap kept between the curb and the near edge of a mapped sidewalk.
    public var sidewalkClearance = 0.3
    /// How far from a road centreline a sidewalk line is looked for, and how far off parallel it may be.
    public var sidewalkSearchRadius = 15.0
    public var sidewalkMaxAngleDegrees = 25.0

    public init() {}

    public func width(kind: HighwayKind, tags: Tags) -> Double {
        if let w = taggedWidth(tags) { return w }
        let sides = parkingKinds.contains(kind) ? parkingSides(tags) : 0
        if kind.isVehicular, let lanes = tags["lanes"].flatMap(TagParsing.integer), lanes > 0, lanes < 12 {
            var travel = Double(lanes) * laneWidth
            if parkingKinds.contains(kind) { travel = max(travel, minTravelWidth) }
            return travel + Double(sides) * parkingLaneWidth
        }
        let base = defaultWidths[kind] ?? 3
        guard parkingKinds.contains(kind), sides < 2 else { return base }
        return max(min(base, minTravelWidth), base - Double(2 - sides) * parkingLaneWidth)
    }

    /// The `width` tag, if usable. Tagged widths are real data and are never adjusted.
    public func taggedWidth(_ tags: Tags) -> Double? {
        guard let w = tags["width"].flatMap(TagParsing.length), w > 0, w <= 60 else { return nil }
        return w
    }

    /// Number of sides (0–2) with on-street parking in the carriageway. Untagged sides count as parked.
    /// Reads `parking:{both,left,right}` (current scheme) and `parking:lane[:{both,left,right}]` (old).
    public func parkingSides(_ t: Tags) -> Int {
        func side(_ s: String) -> Bool {
            let v = t["parking:\(s)"] ?? t["parking:both"]
                ?? t["parking:lane:\(s)"] ?? t["parking:lane:both"] ?? t["parking:lane"]
            guard let v else { return true }
            return !Self.noCarriagewayParking.contains(v)
        }
        return (side("left") ? 1 : 0) + (side("right") ? 1 : 0)
    }

    /// Parking values that leave no parked cars in the carriageway (bays, kerb parking and bans).
    static let noCarriagewayParking: Set<String> = [
        "no", "none", "no_parking", "no_stopping", "no_standing", "fire_lane",
        "separate", "street_side", "on_kerb", "shoulder",
    ]
}

extension RoadRules {
    /// Narrows roads whose width was not tagged so the curb stays `sidewalkClearance` clear of the
    /// near edge of any mapped sidewalk (`footway=sidewalk` lines) running alongside.
    ///
    /// The road centreline is sampled every few metres; at each sample the nearest sidewalk segment
    /// that is roughly parallel (within `sidewalkMaxAngleDegrees`), within `sidewalkSearchRadius` and
    /// that the sample projects onto (not past its ends, so corners at junctions are ignored) limits
    /// the half-width. Deterministic: no randomness, inputs in feature order.
    public func clampedToSidewalks(_ roads: [WayFeature], sidewalks: [WayFeature]) -> [WayFeature] {
        guard !sidewalks.isEmpty else { return roads }
        struct Seg { var a: LocalPoint; var b: LocalPoint; var halfWidth: Double; var minP: LocalPoint; var maxP: LocalPoint }
        var segs: [Seg] = []
        for sw in sidewalks {
            for (a, b) in zip(sw.centerline, sw.centerline.dropFirst()) where a != b {
                segs.append(Seg(a: a, b: b, halfWidth: sw.width / 2,
                                minP: pointwiseMin(a, b), maxP: pointwiseMax(a, b)))
            }
        }
        let cosLimit = cos(sidewalkMaxAngleDegrees * .pi / 180)
        let r = sidewalkSearchRadius
        return roads.map { road in
            guard taggedWidth(road.tags) == nil, road.centerline.count >= 2 else { return road }
            var limit = Double.infinity
            for (p, q) in zip(road.centerline, road.centerline.dropFirst()) {
                let d = q - p
                let len = (d.x * d.x + d.y * d.y).squareRoot()
                guard len > 1e-6 else { continue }
                let dir = d / len
                let lo = pointwiseMin(p, q) - LocalPoint(r, r), hi = pointwiseMax(p, q) + LocalPoint(r, r)
                let near = segs.filter { $0.maxP.x >= lo.x && $0.minP.x <= hi.x && $0.maxP.y >= lo.y && $0.minP.y <= hi.y }
                guard !near.isEmpty else { continue }
                let steps = max(1, Int((len / 2).rounded(.up)))
                for i in 0...steps {
                    let s = p + d * (Double(i) / Double(steps))
                    for seg in near {
                        let e = seg.b - seg.a
                        let el = (e.x * e.x + e.y * e.y).squareRoot()
                        guard abs((e.x * dir.x + e.y * dir.y) / el) >= cosLimit else { continue }
                        let t = ((s.x - seg.a.x) * e.x + (s.y - seg.a.y) * e.y) / (el * el)
                        guard t >= 0, t <= 1 else { continue }
                        let foot = seg.a + e * t
                        let dist = ((s.x - foot.x) * (s.x - foot.x) + (s.y - foot.y) * (s.y - foot.y)).squareRoot()
                        guard dist <= r else { continue }
                        limit = min(limit, dist - seg.halfWidth - sidewalkClearance)
                    }
                }
            }
            guard limit.isFinite, road.width / 2 > limit else { return road }
            var out = road
            out.width = min(road.width, max(minCarriagewayWidth, 2 * limit))
            return out
        }
    }
}

