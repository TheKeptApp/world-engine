import Foundation
import simd
import WorldGeo
import WorldMap

/// Coarse ray queries for postcard composition (CPU, no renderer): building prisms, tree crowns
/// and trunks, and a 4 m ground grid classified as water, green, road, building or other.
struct RayWorld {
    enum Ground: UInt8, Equatable { case other, water, green, road, building, outside }

    enum Kind: Equatable {
        case sky, building, tree
        case ground(Ground)
    }

    struct Hit {
        var kind: Kind
        var distance: Double
        /// Scene metres (east +X, up +Y, north −Z).
        var point: SIMD3<Double>
    }

    struct Prism { var hull: [LocalPoint]; var height: Double }
    struct Tree { var center: LocalPoint; var crownY: Double; var crownRadius: Double; var trunkTop: Double }

    let bounds: Rect2D
    let groundCell = 4.0
    let columns: Int, rows: Int
    private var grid: [UInt8]
    private(set) var prisms: [Prism] = []
    private(set) var trees: [Tree] = []
    let objectCell = 25.0
    private var objects: [SIMD2<Int>: [Int]] = [:]

    init(features: MapFeatures, scene: GeneratedScene) {
        bounds = features.bounds
        columns = max(1, Int((bounds.max.x - bounds.min.x) / groundCell) + 1)
        rows = max(1, Int((bounds.max.y - bounds.min.y) / groundCell) + 1)
        grid = [UInt8](repeating: Ground.other.rawValue, count: columns * rows)

        // Ground classes, lowest priority first.
        for a in features.areas where PostcardComposer.greenKinds.contains(a.kind) {
            fill([a.polygon.outer] + a.polygon.holes, with: .green)
        }
        for r in features.roads where r.kind.isVehicular && !r.isTunnel && !r.isBridge {
            stamp(r.centerline, halfWidth: max(2, r.width / 2), with: .road)
        }
        for a in features.areas where a.kind == .water || a.kind == .pool {
            fill([a.polygon.outer] + a.polygon.holes, with: .water)
        }
        for b in features.buildings where !b.isPart {
            fill([b.footprint.outer], with: .building)
        }

        // Objects: building hulls (camera-collision proxies) and trees.
        for o in scene.occluders where o.hull.count >= 3 { add(prism: Prism(hull: o.hull, height: o.height)) }
        for i in scene.instances where i.kind.isTree {
            let shape = PropLibrary.lobes(i.kind)
            let s = i.scale
            let r = Double((shape.radii.x + shape.radii.y + shape.radii.z) / 3) * s
            add(tree: Tree(center: LocalPoint(i.x, i.y), crownY: Double(shape.crown.y) * s + i.height, crownRadius: r,
                           trunkTop: Double(shape.trunkTop) * s + i.height))
        }
    }

    // MARK: Ground grid

    func ground(_ p: LocalPoint) -> Ground {
        guard bounds.contains(p) else { return .outside }
        let c = Int((p.x - bounds.min.x) / groundCell), r = Int((p.y - bounds.min.y) / groundCell)
        guard c >= 0, r >= 0, c < columns, r < rows else { return .outside }
        return Ground(rawValue: grid[r * columns + c]) ?? .other
    }

    func insideBuilding(_ p: LocalPoint) -> Bool {
        let key = SIMD2(Int((p.x / objectCell).rounded(.down)), Int((p.y / objectCell).rounded(.down)))
        for i in objects[key] ?? [] where i >= 0 && RingMath.contains(prisms[i].hull, p) { return true }
        return false
    }

    func nearWater(_ p: LocalPoint, within d: Double) -> Bool {
        for a in stride(from: 0.0, to: 360, by: 30) {
            let q = p + LocalPoint(cos(a * .pi / 180), sin(a * .pi / 180)) * d
            if ground(q) == .water { return true }
        }
        return false
    }

    /// Even-odd scanline fill of rings into the grid (holes come out naturally).
    private mutating func fill(_ rings: [Ring], with g: Ground) {
        var lo = LocalPoint(.infinity, .infinity), hi = -lo
        for ring in rings { for p in ring { lo = simd_min(lo, p); hi = simd_max(hi, p) } }
        guard lo.x.isFinite else { return }
        let r0 = max(0, Int((lo.y - bounds.min.y) / groundCell)), r1 = min(rows - 1, Int((hi.y - bounds.min.y) / groundCell))
        guard r0 <= r1 else { return }
        var xs: [Double] = []
        for r in r0...r1 {
            let y = bounds.min.y + (Double(r) + 0.5) * groundCell
            xs.removeAll(keepingCapacity: true)
            for ring in rings where ring.count >= 3 {
                var j = ring.count - 1
                for i in 0..<ring.count {
                    let a = ring[j], b = ring[i]
                    if (a.y > y) != (b.y > y) { xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x)) }
                    j = i
                }
            }
            xs.sort()
            var k = 0
            while k + 1 < xs.count {
                let c0 = max(0, Int(((xs[k] - bounds.min.x) / groundCell - 0.5).rounded(.up)))
                let c1 = min(columns - 1, Int(((xs[k + 1] - bounds.min.x) / groundCell - 0.5).rounded(.down)))
                if c0 <= c1 { for c in c0...c1 { grid[r * columns + c] = g.rawValue } }
                k += 2
            }
        }
    }

    private mutating func stamp(_ line: [LocalPoint], halfWidth: Double, with g: Ground) {
        for p in PostcardComposer.resample(line, every: groundCell / 2) {
            let reach = Int((halfWidth / groundCell).rounded(.up))
            let c = Int((p.x - bounds.min.x) / groundCell), r = Int((p.y - bounds.min.y) / groundCell)
            for dr in -reach...reach {
                for dc in -reach...reach {
                    let cc = c + dc, rr = r + dr
                    guard cc >= 0, rr >= 0, cc < columns, rr < rows else { continue }
                    let center = bounds.min + LocalPoint((Double(cc) + 0.5) * groundCell, (Double(rr) + 0.5) * groundCell)
                    if simd_distance(center, p) <= halfWidth { grid[rr * columns + cc] = g.rawValue }
                }
            }
        }
    }

    // MARK: Objects

    private mutating func add(prism: Prism) {
        prisms.append(prism)
        index(prism.hull, id: prisms.count - 1, pad: 0)
    }

    private mutating func add(tree: Tree) {
        trees.append(tree)
        index([tree.center], id: -trees.count, pad: tree.crownRadius)
    }

    private mutating func index(_ pts: [LocalPoint], id: Int, pad: Double) {
        var lo = LocalPoint(.infinity, .infinity), hi = -lo
        for p in pts { lo = simd_min(lo, p); hi = simd_max(hi, p) }
        lo -= LocalPoint(pad, pad); hi += LocalPoint(pad, pad)
        let c0 = Int((lo.x / objectCell).rounded(.down)), c1 = Int((hi.x / objectCell).rounded(.down))
        let r0 = Int((lo.y / objectCell).rounded(.down)), r1 = Int((hi.y / objectCell).rounded(.down))
        for r in r0...r1 { for c in c0...c1 { objects[SIMD2(c, r), default: []].append(id) } }
    }

    // MARK: Ray cast

    /// First hit along a ray from `eye` (scene metres) in unit direction `dir`.
    func cast(from eye: SIMD3<Double>, direction dir: SIMD3<Double>, maxDistance: Double) -> Hit {
        var best = maxDistance
        var kind: Kind = .sky
        if dir.y < -1e-6 {
            let t = -eye.y / dir.y
            if t < best { best = t; kind = .ground(.other) }
        }
        // 2D traversal of object cells in local (east, north) coordinates.
        let o = LocalPoint(eye.x, -eye.z), d = LocalPoint(dir.x, -dir.z)
        let horizontal = simd_length(d)
        var tested = Set<Int>()
        if horizontal > 1e-9 {
            var cell = SIMD2(Int((o.x / objectCell).rounded(.down)), Int((o.y / objectCell).rounded(.down)))
            let step = SIMD2(d.x >= 0 ? 1 : -1, d.y >= 0 ? 1 : -1)
            func boundary(_ i: Int, _ s: Int) -> Double { Double(s > 0 ? i + 1 : i) * objectCell }
            var tMax = SIMD2(d.x != 0 ? (boundary(cell.x, step.x) - o.x) / d.x : .infinity,
                             d.y != 0 ? (boundary(cell.y, step.y) - o.y) / d.y : .infinity)
            let tDelta = SIMD2(d.x != 0 ? objectCell / abs(d.x) : .infinity, d.y != 0 ? objectCell / abs(d.y) : .infinity)
            var tCell = 0.0
            while tCell < best {
                for id in objects[cell] ?? [] where tested.insert(id).inserted {
                    if id >= 0 {
                        if let t = hitPrism(prisms[id], o, d, eye.y, dir.y), t < best { best = t; kind = .building }
                    } else if let t = hitTree(trees[-id - 1], eye, dir), t < best {
                        best = t; kind = .tree
                    }
                }
                if tMax.x < tMax.y { tCell = tMax.x; tMax.x += tDelta.x; cell.x += step.x } else { tCell = tMax.y; tMax.y += tDelta.y; cell.y += step.y }
            }
        }
        let point = eye + dir * best
        if case .ground = kind { kind = .ground(ground(LocalPoint(point.x, -point.z))) }
        return Hit(kind: kind, distance: best, point: point)
    }

    /// Ray against a vertical convex prism (hull from y = 0 to height): Cyrus–Beck in 2D, then the
    /// height slab.
    private func hitPrism(_ p: Prism, _ o: LocalPoint, _ d: LocalPoint, _ oy: Double, _ dy: Double) -> Double? {
        var t0 = 0.0, t1 = Double.infinity
        let hull = p.hull
        let ccw = RingMath.signedArea(hull) > 0
        for i in 0..<hull.count {
            let a = hull[i], b = hull[(i + 1) % hull.count]
            let e = b - a
            let n = ccw ? LocalPoint(e.y, -e.x) : LocalPoint(-e.y, e.x) // outward normal
            let denom = simd_dot(n, d), num = simd_dot(n, a - o)
            if abs(denom) < 1e-12 {
                if num < 0 { return nil }
                continue
            }
            let t = num / denom
            if denom < 0 { t0 = max(t0, t) } else { t1 = min(t1, t) }
            if t0 > t1 { return nil }
        }
        if abs(dy) < 1e-12 {
            return oy >= 0 && oy <= p.height ? t0 : nil
        }
        let ya = (0 - oy) / dy, yb = (p.height - oy) / dy
        let lo = max(t0, min(ya, yb)), hi = min(t1, max(ya, yb))
        return lo <= hi && hi >= 0 ? max(lo, 0) : nil
    }

    private func hitTree(_ tree: Tree, _ eye: SIMD3<Double>, _ dir: SIMD3<Double>) -> Double? {
        var best: Double?
        let c = SIMD3(tree.center.x, tree.crownY, -tree.center.y)
        let oc = eye - c
        let b = simd_dot(oc, dir), cc = simd_dot(oc, oc) - tree.crownRadius * tree.crownRadius
        let disc = b * b - cc
        if disc >= 0 {
            let t = -b - sqrt(disc)
            if t >= 0 { best = t } else if -b + sqrt(disc) >= 0 { best = 0 }
        }
        // Trunk: a 0.2 m cylinder from the ground to the crown.
        let o2 = LocalPoint(eye.x, -eye.z) - tree.center, d2 = LocalPoint(dir.x, -dir.z)
        let a2 = simd_dot(d2, d2)
        if a2 > 1e-12 {
            let b2 = simd_dot(o2, d2), c2 = simd_dot(o2, o2) - 0.04
            let disc2 = b2 * b2 - a2 * c2
            if disc2 >= 0 {
                let t = (-b2 - sqrt(disc2)) / a2
                let y = eye.y + t * dir.y
                if t >= 0, y >= 0, y <= tree.trunkTop, best == nil || t < best! { best = t }
            }
        }
        return best
    }
}

/// Where free exploring may stand (experience-v1 §3): not in buildings or water, not past the
/// edge of the mapped data. Built once per world from the same ray world the composer uses.
public struct WalkMap: Sendable {
    let world: RayWorld

    public init(features: MapFeatures, scene: GeneratedScene) {
        world = RayWorld(features: features, scene: scene)
    }

    /// nil when the point is walkable, else "building", "water" or "edge".
    public func blocker(at p: LocalPoint) -> String? {
        switch world.ground(p) {
        case .outside: return "edge"
        case .water: return "water"
        case .building: return "building"
        default: return world.insideBuilding(p) ? "building" : nil
        }
    }
}
