import Foundation
import simd
import WorldGeo
import WorldMap

/// The roadclip experiment (LookExperiments, default off; P2 Batch 2): mapped sidewalks and paths are drawn over the
/// road (GroundLayer.sidewalk/path above GroundLayer.road), so where one crosses a street it painted concrete across
/// the asphalt. This cuts those parts out, as crossings already are (RoadMarkings.crossingSpans). Only where the line
/// crosses the carriageway at more than 30°: a sidewalk lying along an over-wide carriageway is kept (counted apart).
struct RoadClip: Sendable {
    let streets: [WayFeature]
    let index: SegmentIndex
    /// |cos| of the smallest angle that counts as crossing.
    static let crossingCos = cos(30 * Double.pi / 180)
    static let step = 0.25

    init(_ roads: [WayFeature]) {
        streets = roads.filter { !$0.suppressesSurfaceRendering && Streetscape.isStreet($0) }
        index = SegmentIndex(streets.map(\.centerline))
    }

    /// Inside a street carriageway at `p`: whether the line (direction `dir`) crosses it there.
    func onCarriageway(_ p: LocalPoint, _ dir: LocalPoint) -> (crossing: Bool, parallel: Bool) {
        guard let hit = index.nearest(to: p, within: 20), hit.distance < streets[hit.line].width / 2 else { return (false, false) }
        let crossing = abs(simd_dot(hit.direction, dir)) < Self.crossingCos
        return (crossing, !crossing)
    }

    /// Samples along the line: (distance along, point, unit direction).
    static func samples(_ line: [LocalPoint]) -> [(Double, LocalPoint, LocalPoint)] {
        var out: [(Double, LocalPoint, LocalPoint)] = []
        var s0 = 0.0
        for (a, b) in zip(line, line.dropFirst()) where a != b {
            let len = simd_distance(a, b), dir = (b - a) / len
            var t = 0.0
            while t < len { out.append((s0 + t, a + dir * t, dir)); t += step }
            s0 += len
        }
        if let a = line.last, line.count > 1 { out.append((s0, a, out.last?.2 ?? LocalPoint(1, 0))) }
        return out
    }

    /// Spans (metres along the line) that cross a carriageway.
    func crossingSpans(_ line: [LocalPoint]) -> [ClosedRange<Double>] {
        var out: [ClosedRange<Double>] = []
        var start: Double?
        var last = 0.0
        for (s, p, d) in Self.samples(line) {
            if onCarriageway(p, d).crossing { if start == nil { start = s } } else if let a = start { out.append(a...s); start = nil }
            last = s
        }
        if let a = start { out.append(a...last) }
        // One sample step either side: the cut reaches the carriageway edge rather than the first sample inside it.
        return out.map { max(0, $0.lowerBound - Self.step)...min(last, $0.upperBound + Self.step) }
    }

    /// The line without its carriageway crossings.
    func pieces(_ line: [LocalPoint]) -> [[LocalPoint]] {
        let spans = crossingSpans(line)
        guard !spans.isEmpty, line.count >= 2 else { return [line] }
        let cum = RoadMarkings.cumulative(line)
        return RoadMarkings.subtract(spans, from: 0...cum.last!).filter { $0.upperBound - $0.lowerBound > 0.05 }
            .map { RoadMarkings.subline(line, cum, from: $0.lowerBound, to: $0.upperBound) }
    }

    /// Measurement: runs and metres of the line's centre on a carriageway (crossing / lying along).
    func overlap(_ line: [LocalPoint]) -> (crossingRuns: Int, crossingM: Double, parallelRuns: Int, parallelM: Double) {
        var r = (0, 0.0, 0, 0.0)
        var prev = (false, false)
        for (_, p, d) in Self.samples(line) {
            let o = onCarriageway(p, d)
            if o.crossing { r.1 += Self.step; if !prev.0 { r.0 += 1 } }
            if o.parallel { r.3 += Self.step; if !prev.1 { r.2 += 1 } }
            prev = o
        }
        return r
    }

    // MARK: - sidewalkendshort (P2 Batch 3)

    /// Whether an end at `p`, heading out along `dir`, has its ribbon (half-width `halfWidth`) on a street carriageway it
    /// approaches at more than 30° (a curb end, not a sidewalk lying along the street).
    func endReaches(_ p: LocalPoint, _ dir: LocalPoint, halfWidth: Double) -> Bool {
        guard let hit = index.nearest(to: p, within: 20 + halfWidth) else { return false }
        return hit.distance < streets[hit.line].width / 2 + halfWidth && abs(simd_dot(hit.direction, dir)) < Self.crossingCos
    }

    /// The line with each such end pulled back (0.1 m steps, at most `maxTrim` m) until its ribbon stays off the carriageway.
    /// Nil when nothing usable remains.
    func endShort(_ line: [LocalPoint], halfWidth: Double, maxTrim: Double = 4) -> [LocalPoint]? {
        func trimStart(_ l: [LocalPoint]) -> [LocalPoint]? {
            guard l.count >= 2 else { return nil }
            let cum = RoadMarkings.cumulative(l), total = cum.last!
            var s = 0.0
            while s <= min(maxTrim, total - 0.3) {
                let p = RoadMarkings.subline(l, cum, from: s, to: min(total, s + 0.1))
                guard p.count >= 2, p[0] != p[1] else { break }
                let dir = simd_normalize(p[0] - p[1])  // outward at the start
                if !endReaches(p[0], dir, halfWidth: halfWidth) { break }
                s += 0.1
            }
            if s == 0 { return l }
            return s >= total - 0.3 ? nil : RoadMarkings.subline(l, cum, from: s, to: total)
        }
        guard let a = trimStart(line), let b = trimStart(Array(a.reversed())) else { return nil }
        return Array(b.reversed())
    }

    /// Measurement: how many of the line's two ends reach a carriageway (see `endReaches`).
    func curbEnds(_ line: [LocalPoint], halfWidth: Double) -> Int {
        guard line.count >= 2, line.first != line.last else { return 0 }
        var n = 0
        if endReaches(line[0], simd_normalize(line[0] - line[1]), halfWidth: halfWidth) { n += 1 }
        let k = line.count - 1
        if endReaches(line[k], simd_normalize(line[k] - line[k - 1]), halfWidth: halfWidth) { n += 1 }
        return n
    }
}
