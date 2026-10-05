import Foundation
import simd
import WorldGeo
import WorldMap

/// Where near-camera ground clutter (grass tufts) may grow, and the clutter itself.
///
/// A 0.5 m lawn mask over the focus region marks ground that isn't building, road, path,
/// sidewalk, water, parking or playground. v2 R3: tufts cluster at lawn edges (where grass
/// meets sidewalk, curb or wall), at most 200 clusters within 25 m of the camera. Candidates are
/// seeded per 6 m cell by the cell's coordinates (stable across devices); the cap keeps the
/// nearest, so moving the camera never rerolls a patch.
public struct ClutterField: Sendable {
    public var bounds: Rect2D
    public let resolution = 0.5
    public let cellSize = 6.0
    public var tuftsPerCell = 40
    public static let maxClusters = 200
    public static let radius = 25.0
    var mask: [UInt8] = []
    var width = 0, height = 0
    var blockedLines: [([LocalPoint], Double)] = []
    var blockedPoints: [LocalPoint] = []

    public init(bounds: Rect2D) {
        self.bounds = bounds
    }

    public func isLawn(_ p: LocalPoint) -> Bool {
        let x = Int((p.x - bounds.min.x) / resolution), y = Int((p.y - bounds.min.y) / resolution)
        guard x >= 0, y >= 0, x < width, y < height else { return false }
        return mask[y * width + x] == 0
    }

    /// True where lawn meets something else within ~0.75 m (an edge band).
    public func isLawnEdge(_ p: LocalPoint) -> Bool {
        guard isLawn(p) else { return false }
        let d = 0.75
        for o in [LocalPoint(d, 0), LocalPoint(-d, 0), LocalPoint(0, d), LocalPoint(0, -d)] where !isLawn(p + o) { return true }
        return false
    }

    /// Edge-tuft placements (local x, y, yaw, scale) within `radius` of `center`, nearest first,
    /// capped at `maxClusters`.
    public func tuftPlacements(near center: LocalPoint, radius: Double = ClutterField.radius) -> [SIMD4<Double>] {
        var out: [(Double, SIMD4<Double>)] = []
        let c0 = Int(((center.x - radius) / cellSize).rounded(.down)), c1 = Int(((center.x + radius) / cellSize).rounded(.up))
        let r0 = Int(((center.y - radius) / cellSize).rounded(.down)), r1 = Int(((center.y + radius) / cellSize).rounded(.up))
        for cx in c0...c1 { for cy in r0...r1 {
            var rng = StableRandom(UInt64(bitPattern: Int64(cx)), UInt64(bitPattern: Int64(cy)), salt: "tufts")
            for _ in 0..<tuftsPerCell {
                let p = LocalPoint((Double(cx) + rng.unit()) * cellSize, (Double(cy) + rng.unit()) * cellSize)
                let yaw = rng.range(0, 6.28), s = rng.range(0.8, 1.3)
                let dist = simd_distance(p, center)
                guard dist <= radius, isLawnEdge(p) else { continue }
                out.append((dist, SIMD4(p.x, p.y, yaw, s)))
            }
        } }
        out.sort { $0.0 < $1.0 }
        return out.prefix(Self.maxClusters).map(\.1)
    }

    /// Tuft transforms (scene space) near `center`.
    public func tufts(near center: LocalPoint, radius: Double = ClutterField.radius) -> [simd_float4x4] {
        tuftPlacements(near: center, radius: radius).map {
            simd_float4x4(translation: LocalFrame.scenePosition(LocalPoint($0.x, $0.y), y: 0), yaw: Float($0.z), scale: Float($0.w))
        }
    }

    mutating func rasterize(features f: MapFeatures, buildings: [Polygon2D]) {
        width = Int((bounds.width / resolution).rounded(.up))
        height = Int((bounds.height / resolution).rounded(.up))
        mask = [UInt8](repeating: 0, count: width * height)
        for b in buildings where Rect2D(enclosing: b.outer).intersects(bounds) { fill(b.outer) }
        for a in f.areas where [.water, .pool, .parking, .playground, .pedestrianArea, .sand].contains(a.kind) {
            fill(a.polygon.outer)
        }
        for r in f.roads { stroke(r.centerline, width: r.width + 0.8) }
        for p in f.paths { stroke(p.centerline, width: max(1.6, p.width) + 0.4) }
        for s in f.sidewalks { stroke(s.centerline, width: 2.0) }
        for (l, w) in blockedLines { stroke(l, width: w + 0.4) }
        for p in blockedPoints { stroke([p, p + LocalPoint(0.01, 0)], width: 1.2) }
    }

    /// Scanline fill (even-odd) of a ring into the mask.
    mutating func fill(_ ring: Ring) {
        let bb = Rect2D(enclosing: ring)
        guard bb.intersects(bounds) else { return }
        let y0 = max(0, Int((bb.min.y - bounds.min.y) / resolution)), y1 = min(height - 1, Int((bb.max.y - bounds.min.y) / resolution))
        guard y0 <= y1 else { return }
        for row in y0...y1 {
            let y = bounds.min.y + (Double(row) + 0.5) * resolution
            var xs: [Double] = []
            for i in 0..<ring.count {
                let a = ring[i], b = ring[(i + 1) % ring.count]
                if (a.y > y) != (b.y > y) { xs.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y)) }
            }
            xs.sort()
            var k = 0
            while k + 1 < xs.count {
                let c0 = max(0, Int(((xs[k] - bounds.min.x) / resolution).rounded()))
                let c1 = min(width - 1, Int(((xs[k + 1] - bounds.min.x) / resolution).rounded()) - 1)
                if c0 <= c1 { for c in c0...c1 { mask[row * width + c] = 1 } }
                k += 2
            }
        }
    }

    /// Marks a buffered polyline (each segment as a rectangle).
    mutating func stroke(_ line: [LocalPoint], width w: Double) {
        for (a, b) in zip(line, line.dropFirst()) {
            let d = b - a
            let len = simd_length(d)
            let dir = len > 1e-9 ? d / len : LocalPoint(1, 0)
            let n = LocalPoint(-dir.y, dir.x) * (w / 2)
            let e = dir * (w / 2)
            fill([a - e - n, b + e - n, b + e + n, a - e + n])
        }
    }
}
