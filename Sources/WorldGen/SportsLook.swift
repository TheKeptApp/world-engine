import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh

/// The sportsfields experiment (LookExperiments, default off; P2 Batch 3): pitches drawn by `sport`, with existing palette
/// keys only — hard courts in `parking`, grass fields in `pitch` with `laneMarking` lines, baseball/softball infields in
/// `playground` (dirt), and `leisure=track` running tracks in `pavingBrick`. Region-independent; no new palette key.
enum SportsLook {
    enum Kind: Equatable { case court, field, diamond(side: Double), track, plain }

    static let courts: Set<String> = ["tennis", "basketball", "volleyball", "netball", "padel", "pickleball", "multi", "handball", "badminton"]
    static let fields: Set<String> = ["soccer", "american_football", "rugby", "rugby_union", "rugby_league", "field_hockey", "lacrosse",
                                      "gaelic_games", "australian_football", "canadian_football"]

    /// The first listed sport decides (`sport=soccer;baseball` → soccer).
    static func kind(_ t: Tags) -> Kind {
        let sport = (t["sport"] ?? "").split(separator: ";").first.map(String.init) ?? ""
        if courts.contains(sport) { return .court }
        if fields.contains(sport) { return .field }
        if sport == "baseball" { return .diamond(side: 27.43) }  // 90 ft base paths
        if sport == "softball" { return .diamond(side: 18.29) }  // 60 ft
        if ["athletics", "running"].contains(sport) { return .track }
        return .plain
    }

    /// Slot name for the pitch surface.
    static func surface(_ k: Kind) -> String {
        switch k {
        case .court: "parking"
        case .track: "pavingBrick"
        default: "pitch"
        }
    }

    /// Boundary lines 0.5 m inside the pitch's oriented rectangle plus the halfway / net line across it.
    static func lines(_ poly: Polygon2D) -> [[LocalPoint]] {
        let r = FootprintAnalysis(poly).obb
        let hl = r.halfLength - 0.5, hw = r.halfWidth - 0.5
        guard hl > 2, hw > 1 else { return [] }
        let c = r.center, u = r.u, v = r.v
        let corners = [c + u * hl + v * hw, c - u * hl + v * hw, c - u * hl - v * hw, c + u * hl - v * hw]
        return [corners + [corners[0]], [c + v * hw, c - v * hw]]
    }

    /// Infield square for a diamond: home plate at the polygon's sharpest corner (the fan's apex), second base toward the
    /// centroid. Nil when the field is too small to hold it.
    static func infield(_ poly: Polygon2D, side: Double) -> [LocalPoint]? {
        let ring = poly.outer.count > 1 && poly.outer.first == poly.outer.last ? Array(poly.outer.dropLast()) : poly.outer
        guard ring.count >= 3 else { return nil }
        var best = 0, bestCos = -2.0
        for i in ring.indices {
            let a = ring[(i + ring.count - 1) % ring.count] - ring[i], b = ring[(i + 1) % ring.count] - ring[i]
            guard simd_length(a) > 0.01, simd_length(b) > 0.01 else { continue }
            let cosine = simd_dot(simd_normalize(a), simd_normalize(b))
            if cosine > bestCos { bestCos = cosine; best = i }
        }
        let home = ring[best], centroid = poly.centroid
        guard simd_distance(home, centroid) > side * 0.75 else { return nil }
        let d = simd_normalize(centroid - home), n = LocalPoint(-d.y, d.x)
        let s = side / 2.0.squareRoot()
        let diamond = [home, home + d * s + n * s, home + d * (2 * s), home + d * s - n * s]
        return diamond.allSatisfy { poly.contains($0) || simd_distance($0, home) < 0.01 } ? diamond : nil
    }
}
