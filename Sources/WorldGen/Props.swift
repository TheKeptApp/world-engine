import Foundation
import simd
import WorldGeo
import WorldMesh

/// Instanced prop kinds. Each (kind, variant) is one mesh per detail level, drawn many times.
public enum PropKind: String, Sendable, CaseIterable, Codable {
    case treeBroad, treeOval, treeSpreading, conifer, lamp, bench, bush, flowerBush, tuft

    public var isTree: Bool { [.treeBroad, .treeOval, .treeSpreading, .conifer].contains(self) }
    public var isFoliage: Bool { ![.lamp, .bench].contains(self) }
}

/// Reusable prop meshes in object space (scene axes, origin on the ground, +Y up).
/// Organic props have shared vertices and smooth normals; built objects are flat-shaded.
public struct PropLibrary: Sendable {
    /// Shape variants per kind (instances pick one at generation time). Each variant is its own instanced
    /// draw per cell and detail level, so trees vary per instance instead (yaw, `PropInstance.stretch`).
    public static let variants: [PropKind: Int] = [
        .treeBroad: 1, .treeOval: 1, .treeSpreading: 1, .conifer: 1, .lamp: 1, .bench: 1, .bush: 2, .flowerBush: 2, .tuft: 2,
    ]

    /// Detail levels per kind, chosen at render time: trees and bushes have near (0), mid (1), far (2) and
    /// skyline (3) meshes; everything else one.
    public static func lodCount(_ kind: PropKind) -> Int { kind.isTree || kind == .bush || kind == .flowerBush ? 4 : 1 }

    /// Distances (m) where LOD props switch from near to mid, mid to far and far to skyline detail
    /// (detail level `k` is used from `lodDistances[k - 1]` on).
    public static let lodDistances: [Double] = [45, 160, 400]
    /// Renderers re-bucket LOD props when the camera has moved this far (m).
    public static let lodRebucketMeters: Double = 8
    /// Instanced props are grouped into square cells of this size (m) so renderers can cull them.
    public static let cellMeters: Double = 400

    /// The cell a prop belongs to (local meters east/north → integer cell coordinates).
    public static func cell(x: Double, y: Double) -> SIMD2<Int> {
        SIMD2(Int((x / cellMeters).rounded(.down)), Int((y / cellMeters).rounded(.down)))
    }

    /// Crown lobes (center, radius) in unit-height tree space for each archetype.
    public static func lobes(_ kind: PropKind) -> (trunkTop: Float, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)]) {
        switch kind {
        case .treeOval:
            // Upright oval: narrow, tall crown of stacked lobes.
            return (0.40, [0, 0.68, 0], [0.19, 0.30, 0.19], [
                ([0, 0.84, 0], 0.15), ([0.05, 0.66, 0.04], 0.18), ([-0.06, 0.58, -0.03], 0.16), ([0.02, 0.50, -0.07], 0.13),
            ])
        case .treeSpreading:
            // Open spreading: wide, flatter crown of five lobes.
            return (0.46, [0, 0.66, 0], [0.36, 0.19, 0.34], [
                ([0, 0.74, 0], 0.18), ([0.22, 0.64, 0.05], 0.15), ([-0.2, 0.65, -0.08], 0.16),
                ([0.04, 0.63, 0.22], 0.14), ([-0.06, 0.62, -0.23], 0.14),
            ])
        default:
            // Broad rounded: one top lobe over three around it.
            return (0.44, [0, 0.66, 0], [0.29, 0.24, 0.29], [
                ([0, 0.78, 0], 0.2), ([0.15, 0.62, 0.06], 0.17), ([-0.13, 0.63, 0.1], 0.16), ([0.0, 0.6, -0.16], 0.17),
            ])
        }
    }

    /// Mesh for a prop variant. Trees and lamps are unit height (scale by instance); benches,
    /// bushes and tufts are real size.
    public static func mesh(_ kind: PropKind, variant: Int, lod: Int = 0, palette: Palette) -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, UInt64(variant), salt: "prop")
        switch kind {
        case .treeBroad, .treeOval, .treeSpreading:
            return deciduous(kind, lod: lod, palette: palette, rng: &rng)
        case .conifer:
            return conifer(lod: lod, palette: palette)
        case .lamp:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("metal"))
            addCylinder(&m, radius: 0.15, z0: 0, z1: 0.32, sides: 8, smooth: false)
            m.bakeAO(from: 0) { p, _ in p.y < 0.05 ? 0.75 : 1 }
            addCylinder(&m, radius: 0.05, z0: 0.32, z1: 3.55, sides: 8, smooth: true)
            addCylinder(&m, radius: 0.12, z0: 3.55, z1: 3.62, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("lampGlow"), flags: .emissive)
            addCylinder(&m, radius: 0.16, z0: 3.62, z1: 4.0, sides: 8, smooth: false)
            m.paint = Paint(slot: palette.named("metal"))
            addCone(&m, radius: 0.22, z0: 4.0, z1: 4.28, sides: 8)
            return m
        case .bench:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bench"))
            box(&m, c: SIMD3(0, 0.45, 0), half: SIMD3(0.85, 0.03, 0.22))           // seat 1.7 m wide, 0.45 m high
            box(&m, c: SIMD3(0, 0.73, -0.22), half: SIMD3(0.85, 0.15, 0.025))      // back
            m.bakeAO(from: 0) { _, n in n.y < -0.5 ? 0.7 : 1 }
            m.paint = Paint(slot: palette.named("metal"))
            let legs = m.positions.count
            for x: Float in [-0.72, 0.72] {
                box(&m, c: SIMD3(x, 0.21, 0.15), half: SIMD3(0.03, 0.21, 0.03))
                box(&m, c: SIMD3(x, 0.45, -0.2), half: SIMD3(0.03, 0.45, 0.03))
            }
            m.bakeAO(from: legs) { p, _ in p.y < 0.05 ? 0.75 : 1 }
            return m
        case .bush, .flowerBush:
            var m = MeshBuffers()
            m.paint = Paint(slot: palette.named("bushes"), shade: kind == .flowerBush ? 1.08 : 1, sway: 0.2)
            let start = m.positions.count
            let radius: Float = variant == 0 ? 0.55 : 0.47
            if lod < 2 {
                // Near: subdivided icosahedron (80 triangles); mid: plain icosahedron (20).
                addBlob(&m, center: SIMD3(0, 0.36, 0), radius: radius, squash: 0.72, jitter: lod == 0 ? 0.08 : 0.04, rng: &rng, subdivide: lod == 0)
            } else if lod == 2 {
                addEllipsoid(&m, center: SIMD3(0, 0.36, 0), radii: SIMD3(radius, radius * 0.72, radius), octahedron: true)
            } else {
                // Skyline: a three-sided pyramid, open underneath (3 triangles).
                addSpire(&m, base: 0.05, top: 0.36 + radius * 0.72, radius: radius, sides: 3)
            }
            m.bakeAO(from: start) { p, _ in Float(0.62 + 0.38 * smoothstep(0.0, 0.55, Double(p.y))) }
            return m
        case .tuft:
            // R3 stylized tuft: 4–5 chunky tapered blades, partly double-sided: 15–21 triangles.
            var m = MeshBuffers()
            let blades = variant == 0 ? 4 : 5
            for k in 0..<blades {
                let a = Float(k) / Float(blades) * 2 * .pi + Float(rng.range(-0.35, 0.35))
                let dirOut = SIMD3<Float>(cos(a), 0, sin(a))
                let side = SIMD3<Float>(-sin(a), 0, cos(a)) * Float(rng.range(0.028, 0.04))
                let base = dirOut * 0.02
                let height = Float(rng.range(0.16, 0.27))
                let lean = Float(rng.range(0.05, 0.1))
                let mid = base + dirOut * (lean * 0.45) + SIMD3(0, height * 0.55, 0)
                let tip = base + dirOut * lean + SIMD3(0, height, 0)
                let n = simd_normalize(dirOut * 0.6 + SIMD3(0, 0.8, 0))
                func blade(_ flip: Bool) {
                    m.paint = Paint(slot: palette.named("tufts"), shade: 0.88, flags: .distanceFade, sway: 0)
                    m.extra = SIMD4(0.8, 0, 0, 0)
                    let i0 = m.addVertex(base - side, normal: n)
                    let i1 = m.addVertex(base + side, normal: n)
                    m.paint = Paint(slot: palette.named("tufts"), shade: 1.0, flags: .distanceFade, sway: 0.6)
                    m.extra = SIMD4(0.95, 0, 0, 0)
                    let i2 = m.addVertex(mid + side * 0.75, normal: n)
                    let i3 = m.addVertex(mid - side * 0.75, normal: n)
                    m.paint = Paint(slot: palette.named("tufts"), shade: 1.1, flags: .distanceFade, sway: 1)
                    m.extra = SIMD4(1, 0, 0, 0)
                    let i4 = m.addVertex(tip, normal: n)
                    if flip {
                        m.addTriangle(i0, i2, i1); m.addTriangle(i0, i3, i2); m.addTriangle(i3, i4, i2)
                    } else {
                        m.addTriangle(i0, i1, i2); m.addTriangle(i0, i2, i3); m.addTriangle(i3, i2, i4)
                    }
                }
                blade(false)
                if k % 2 == 0 { blade(true) }
            }
            m.extra = SIMD4(1, 0, 0, 0)
            return m
        }
    }

    // MARK: - Trees

    /// Triangle ceilings per deciduous tree at mid and far detail (beyond `lodDistances[2]` the skyline
    /// level takes over, `skylineTriangleBudget`). At 40 the far crown's smaller lobe has to be an
    /// octahedron, which reads as a diamond at the mid→far switch; 52 lets both lobes be icosahedra
    /// with the same trunk and three winter spikes (`farSmallLobe` follows this value).
    public static let treeTriangleBudget = (mid: 200, far: 52)

    static func deciduous(_ kind: PropKind, lod: Int, palette: Palette, rng: inout StableRandom) -> MeshBuffers {
        let shape = lobes(kind)
        let trunkR: Float = kind == .treeSpreading ? 0.022 : 0.018
        if lod == 3 { return skylineTree(shape, palette: palette, trunkRadius: trunkR) }
        // Branches: hidden inside the leafy crown, they carry the bare winter silhouette (sky-seasons
        // §5.3: foliage is removed lobe by lobe while branches remain; visual v2: meaningful winter
        // silhouettes). Every detail level draws from one skeleton, so the bare outline holds across
        // LOD switches, and each level keeps it inside its own leafy crown so nothing pokes through.
        // Bare branches sway at 0.3 (R10). Branch draws come from a generator split off a copy of
        // `rng`, so the crown jitter below keeps its sequence.
        var split = rng
        var branchRng = StableRandom(seed: split.next())
        let skeleton = bareSkeleton(shape, style: BranchStyle.of(kind), trunkRadius: trunkR, rng: &branchRng)
        if lod == 2 { return farTree(shape, skeleton: skeleton, trunkRadius: trunkR, palette: palette) }

        var m = MeshBuffers()
        // Trunk: thin, bark-colored; AO darker where it enters the crown.
        m.paint = Paint(slot: palette.named("bark"))
        let trunkSides = lod == 0 ? 7 : 5
        addCylinder(&m, radius: trunkR, z0: 0, z1: shape.trunkTop + 0.08, sides: trunkSides, smooth: true, cap: false)
        m.bakeAO(from: 0) { p, _ in trunkAO(p, shape) }
        m.paint = Paint(slot: palette.named("bark"), sway: 0.3)
        let branchStart = m.positions.count
        addBareBranches(&m, skeleton, lod: lod, trunkSides: trunkSides, within: crownEnvelope(shape, lod: lod))
        m.bakeAO(from: branchStart) { _, _ in 0.8 }
        // Crown: one color family per tree (the shader picks deciduous1…4 per instance); lobes
        // share a softened ellipsoid normal so the crown reads as one sculpted mass. Each lobe's
        // vertices carry a stable leaf threshold in extra.y: the lobe shows while the tree's leaf
        // fraction is at or above it, so autumn thins crowns lobe by lobe. Mid detail keeps the top
        // lobe and the first side lobe at 1.25×; its side lobe is a 48-triangle cube sphere.
        m.paint = Paint(slot: palette.named("deciduous1"), flags: .variant4, sway: 1)
        let lobes = lod == 0 ? shape.lobes : midLobes(shape)
        let start = m.positions.count
        for (k, (c, r)) in lobes.enumerated() {
            let lobeStart = m.positions.count
            if lod == 1 && k > 0 {
                addCubeSphere(&m, center: c, radii: SIMD3(r, r * 0.92, r))
            } else {
                addBlob(&m, center: c, radius: r, squash: 0.92, jitter: lod == 0 ? 0.05 : 0, rng: &rng, subdivide: true)
            }
            let threshold = lobeThreshold(k, of: lobes.count)
            for i in lobeStart..<m.positions.count {
                m.extras[i].y = threshold
                let q = (m.positions[i] - shape.crown) / shape.radii
                let crownN = simd_normalize(q / shape.radii)
                m.normals[i] = simd_normalize(m.normals[i] * 0.5 + crownN * 0.5)
            }
        }
        // Overlap AO against the modelled lobe radii (mid lobes are drawn 1.25× larger).
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: Array(shape.lobes.prefix(lobes.count)))
        return m
    }

    /// Triangle ceiling per tree at skyline detail (beyond `lodDistances[2]`: the distant tree band and
    /// whole aerial views, thousands of trees).
    public static let skylineTriangleBudget = 12

    /// Shade of skyline crowns. From the aerial camera (1.8 km slant) a crown is 2–8 px across, and the
    /// summer crown colours sit at lawn value, so canopy vanished into the lawn; a quarter darker it
    /// reads as tree canopy (offline renders), much as real canopy, full of self-shadow, is darker than
    /// mown grass seen from above. Street views meet this level only beyond `lodDistances[2]`, where
    /// crowns are small and in the haze. Conifers (already dark) and the nearer levels keep 1.
    static let skylineShade: Float = 0.75

    /// Skyline detail: a 10-triangle dome shrink-wrapped onto the same lobes as the far crown (leaf
    /// threshold 0.5) and, with `trunk`, the trunk as one vertical card (two triangles back to back, from
    /// the ground into the crown) so distant crowns don't float above the ground; no branches.
    static func skylineTree(_ shape: TreeShape, palette: Palette, trunkRadius: Float, trunk: Bool = skylineTrunk,
                            shell: CrownShell? = nil) -> MeshBuffers {
        var m = MeshBuffers()
        let shell = shell ?? skylineCrownShell(shape)
        if trunk {
            m.paint = Paint(slot: palette.named("bark"))
            let w = trunkRadius * 1.3, top = SIMD3<Float>(0, shell.center.y, 0)
            for side: Float in [1, -1] {
                let n = SIMD3<Float>(0, 0, side)
                let a = m.addVertex(SIMD3(-w * side, 0, 0), normal: n), b = m.addVertex(SIMD3(w * side, 0, 0), normal: n)
                m.addTriangle(a, b, m.addVertex(top, normal: n))
            }
            m.bakeAO(from: 0) { p, _ in trunkAO(p, shape) }
        }
        m.paint = Paint(slot: palette.named("deciduous1"), shade: skylineShade, flags: .variant4, sway: 1)
        let start = m.positions.count, base = UInt32(start)
        for (p, n) in zip(shell.corners, shell.normals) { m.addVertex(p, normal: n) }
        for f in shell.faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
        // Leaf threshold 0.5; z = 1 marks the skyline crown, which bare seasons keep as a twig mass
        // (lighting bible §5: beyond 600 m retain aggregate height and colour) instead of dropping it.
        for i in start..<m.positions.count { m.extras[i].y = 0.5; m.extras[i].z = 1 }
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: [])
        return m
    }

    /// Skyline trees keep a two-triangle trunk card (without it crowns visibly float above the ground
    /// in the distant band, about 28 px at 400 m on a portrait phone).
    static let skylineTrunk = true

    /// Trunk AO: 0.85, darker where the trunk enters the crown.
    static func trunkAO(_ p: SIMD3<Float>, _ shape: TreeShape) -> Float {
        Float(0.85 - 0.3 * smoothstep(Double(shape.trunkTop) - 0.12, Double(shape.trunkTop), Double(p.y)))
    }

    /// The mid crown's lobes: the top lobe and the first side lobe, 1.25× larger.
    static func midLobes(_ shape: TreeShape) -> [(SIMD3<Float>, Float)] {
        shape.lobes.prefix(2).map { ($0.0, $0.1 * 1.25) }
    }

    /// Leaf threshold of lobe `k` of `count` (spread over (0.1, 1]; the top lobe, the first, keeps its
    /// leaves longest).
    static func lobeThreshold(_ k: Int, of count: Int) -> Float { Float(0.1 + 0.9 * (Double(k) + 0.5) / Double(count)) }

    /// Unit corner directions and faces (counter-clockwise outside) of a low-poly sphere.
    typealias Polyhedron = (units: [SIMD3<Float>], faces: [SIMD3<UInt32>])

    /// The far crown's lobes: the mid crown's two lobes as low-poly spheres, the larger one an icosahedron
    /// and the smaller one `farSmallLobe` (others can be passed to compare), each radius set so its
    /// silhouette covers what the mid crown's sphere for that lobe covers.
    static func farLobes(_ shape: TreeShape, large: Polyhedron? = nil, small: Polyhedron? = nil) -> [(center: SIMD3<Float>, radius: Float, polyhedron: Polyhedron)] {
        let mid = midLobes(shape)
        let topIsLarger = mid[0].1 >= mid[1].1
        let largeLobe = large ?? icosahedron(), smallLobe = small ?? farSmallLobe
        let polyhedra = topIsLarger ? [largeLobe, smallLobe] : [smallLobe, largeLobe]
        let scales = large == nil && small == nil ? (topIsLarger ? farLobeScales.topLarger : farLobeScales.sideLarger) : lobeScales(polyhedra)
        return zip(mid, zip(polyhedra, scales)).map { lobe, p in (lobe.0, lobe.1 * p.1, p.0) }
    }

    /// Radius factors for far lobes drawn with `polyhedra` (top lobe, side lobe): the square root of how
    /// much more of a sphere's silhouette the mid crown's spheres cover (an 80-triangle icosphere, a
    /// 48-triangle cube sphere) than each polyhedron.
    static func lobeScales(_ polyhedra: [Polyhedron]) -> [Float] {
        let drawnAtMid: [Polyhedron] = [subdivided(icosahedron().0, icosahedron().1), cubeSphere()]
        return zip(polyhedra, drawnAtMid).map { (silhouetteShare($1) / silhouetteShare($0)).squareRoot() }
    }

    /// The shipped far lobes' radius factors (the larger lobe on top, or at the side), computed once.
    static let farLobeScales = (topLarger: lobeScales([icosahedron(), farSmallLobe]), sideLarger: lobeScales([farSmallLobe, icosahedron()]))

    /// The far crown's smaller lobe: the roundest low-poly sphere that leaves the far budget room for
    /// the larger lobe (an icosahedron, 20), the trunk (3) and three winter spikes (9): an octahedron at
    /// 40 triangles, an icosahedron from 52.
    static let farSmallLobe: Polyhedron = {
        let room = treeTriangleBudget.far - icosahedron().1.count - 3 - 9
        return room >= icosahedron().1.count ? icosahedron() : octahedron()
    }()

    /// Far detail (from `lodDistances[1]` to `lodDistances[2]`), within `budget`: the mid crown's two
    /// lobes as low-poly spheres with their mid leaf thresholds (`farLobes`), so the switch from mid
    /// detail keeps the outline in every season; trunk and leader as one 3-sided spike; spikes toward
    /// the limbs' end forks, then the top branches, as the budget allows (the bare winter outline), each
    /// kept inside a lobe's inscribed sphere.
    static func farTree(_ shape: TreeShape, skeleton: [Bough], trunkRadius: Float, palette: Palette,
                        large: Polyhedron? = nil, small: Polyhedron? = nil, budget: Int = treeTriangleBudget.far) -> MeshBuffers {
        var m = MeshBuffers()
        let lobes = farLobes(shape, large: large, small: small)
        let crown = farEnvelope(lobes)
        // Trunk and leader: 1.3× the trunk radius at the ground, tapering to a point in the crown, so
        // the visible trunk keeps about the mid trunk's width.
        m.paint = Paint(slot: palette.named("bark"))
        let top = skeleton[0].points[skeleton[0].points.count - 1]
        addBranch(&m, [.zero, crown.clamp(.zero, toward: top)], radii: [trunkRadius * 1.3, 0], sides: 3)
        for i in 0..<m.positions.count { m.extras[i].x = trunkAO(m.positions[i], shape) }
        m.paint = Paint(slot: palette.named("bark"), sway: 0.3)
        let crownTriangles = lobes.reduce(0) { $0 + $1.polyhedron.faces.count }
        addBareBranches(&m, skeleton, lod: 2, trunkSides: 3, within: crown, farSpikes: max(0, (budget - crownTriangles - 3) / 3))
        m.paint = Paint(slot: palette.named("deciduous1"), flags: .variant4, sway: 1)
        let start = m.positions.count
        for (k, lobe) in lobes.enumerated() {
            let lobeStart = m.positions.count, base = UInt32(lobeStart)
            for v in lobe.polyhedron.units {
                let p = lobe.center + SIMD3(v.x, v.y * 0.92, v.z) * lobe.radius
                let crownN = simd_normalize((p - shape.crown) / (shape.radii * shape.radii))
                m.addVertex(p, normal: simd_normalize(simd_normalize(SIMD3(v.x, v.y / 0.92, v.z)) * 0.5 + crownN * 0.5))
            }
            for f in lobe.polyhedron.faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
            for i in lobeStart..<m.positions.count { m.extras[i].y = lobeThreshold(k, of: lobes.count) }
        }
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: Array(shape.lobes.prefix(lobes.count)))
        return m
    }

    /// Where far branches may go: inside each far lobe's inscribed sphere (or under the crown).
    static func farEnvelope(_ lobes: [(center: SIMD3<Float>, radius: Float, polyhedron: Polyhedron)]) -> CrownEnvelope {
        CrownEnvelope(blobs: lobes.map { lobe in (lobe.center, SIMD3(1, 0.92, 1) * (lobe.radius * inradius(lobe.polyhedron))) }, margin: 0.97)
    }

    /// Distance from the centre to the nearest face plane of a polyhedron with unit corners.
    static func inradius(_ p: Polyhedron) -> Float {
        p.faces.map { f in
            let a = p.units[Int(f.x)], n = simd_normalize(simd_cross(p.units[Int(f.y)] - a, p.units[Int(f.z)] - a))
            return abs(simd_dot(n, a))
        }.min() ?? 1
    }

    /// Four side views and the view from above, for silhouette areas.
    static let silhouetteViews: [SIMD3<Float>] = {
        let d = Float(0.5).squareRoot()
        return [[1, 0, 0], [d, 0, d], [0, 0, 1], [-d, 0, d], [0, -1, 0]]
    }()

    /// How much of a unit sphere's silhouette a polyhedron with unit corners covers, averaged over
    /// `silhouetteViews` (parallel rays on a 48 × 48 grid each).
    static func silhouetteShare(_ p: Polyhedron) -> Float {
        var covered = 0, disc = 0
        for v in silhouetteViews {
            let helper: SIMD3<Float> = abs(v.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
            let u1 = simd_normalize(simd_cross(v, helper)), u2 = simd_cross(v, u1)
            for i in 0..<48 { for j in 0..<48 {
                let x = (Float(i) + 0.5) / 24 - 1, y = (Float(j) + 0.5) / 24 - 1
                if x * x + y * y <= 1 { disc += 1 }
                let o = u1 * x + u2 * y - v * 2
                if p.faces.contains(where: { f in rayMeetsTriangle(o, v, p.units[Int(f.x)], p.units[Int(f.y)], p.units[Int(f.z)]) }) { covered += 1 }
            } }
        }
        return Float(covered) / Float(max(disc, 1))
    }

    /// Whether the line through `o` along `v` meets triangle `a b c` (Möller–Trumbore, either side).
    static func rayMeetsTriangle(_ o: SIMD3<Float>, _ v: SIMD3<Float>, _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> Bool {
        let e1 = b - a, e2 = c - a, p = simd_cross(v, e2), det = simd_dot(e1, p)
        guard abs(det) > 1e-9 else { return false }
        let s = o - a, q = simd_cross(s, e1)
        let u = simd_dot(s, p) / det, w = simd_dot(v, q) / det
        return u >= 0 && w >= 0 && u + w <= 1
    }

    /// The octahedron (6 corners, 8 faces).
    static func octahedron() -> Polyhedron {
        let units: [SIMD3<Float>] = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]]
        let faces: [SIMD3<UInt32>] = [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
        return (units, oriented(faces, units))
    }

    /// Crown AO: lower and interior parts darker, lobe overlaps darker (R1).
    static func bakeCrownAO(_ m: inout MeshBuffers, from start: Int, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)]) {
        for i in start..<m.positions.count {
            let p = m.positions[i]
            let rel = (p.y - crown.y) / radii.y
            var ao = 0.66 + 0.34 * Float(smoothstep(-1.0, 0.7, Double(rel)))
            for (c, r) in lobes where simd_distance(p, c) < r * 0.98 { ao *= 0.86 }
            m.extras[i].x = min(m.extras[i].x, ao)
        }
    }

    // MARK: - Bare branches

    typealias TreeShape = (trunkTop: Float, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)])

    /// One piece of a deciduous tree's bare skeleton: a tapered polyline, base first (a last radius of 0
    /// ends in a point).
    struct Bough {
        var points: [SIMD3<Float>]
        var radii: [Float]
        /// 0 = leader or limb, 1 = branch, 2 = twig.
        var order: Int
        /// The bough this one leaves, at fraction `at` of that bough's length.
        var parent: Int? = nil
        var at: Float = 0
        /// The leader: the trunk carrying on, drawn with the trunk's sides and ring.
        var stem = false
        /// Closed end (limbs, which fork there).
        var cap = false
        /// Shapes the outline: kept at mid detail, and at far detail as one spike from its limb's base.
        var far = false

        /// Position and radius at fraction `t` of the length.
        func along(_ t: Float) -> (p: SIMD3<Float>, r: Float) {
            var rest = max(0, min(1, t)) * zip(points, points.dropFirst()).reduce(Float(0)) { $0 + simd_distance($1.0, $1.1) }
            for i in 1..<points.count {
                let length = simd_distance(points[i - 1], points[i])
                if rest <= length || i == points.count - 1 {
                    let f = length > 0 ? min(1, rest / length) : 0
                    return (points[i - 1] + (points[i] - points[i - 1]) * f, radii[i - 1] + (radii[i] - radii[i - 1]) * f)
                }
                rest -= length
            }
            return (points[points.count - 1], radii[radii.count - 1])
        }
    }

    /// Branching character of a crown archetype. Angles in radians; reaches are shares of the free run
    /// to the crown's edge.
    struct BranchStyle {
        /// Leader: reach up the crown; branches leaving it, their angle from vertical and where along the
        /// leader they leave.
        var leaderReach: Float, topBranches: Int, topFan: Float, topAt: Float
        /// Side limbs: how far up toward their lobe they leave the stem (0 = all at the fork), how far past
        /// their lobe's centre they aim (× lobe radius), reach, base radius (× trunk) and bow (+ out first,
        /// then curving up; − up first, then flaring out).
        var stagger: Float, outward: Float, limbReach: Float, limb: Float, bow: Float
        /// Branches: end-fork half-angle, tilt of the fork plane (one branch rises, one reaches out low),
        /// upward pull, angle of the inner branch rising from the limb's bend, reach.
        var fork: Float, tilt: Float, rise: Float, inner: Float, branchReach: Float
        /// Twigs per inner and per end branch, their angle off the branch and upward pull.
        var innerTwigs: Int, endTwigs: Int, spray: Float, twigRise: Float

        static func of(_ kind: PropKind) -> BranchStyle {
            switch kind {
            case .treeOval:
                // Upright: limbs leave a tall leader at staggered heights and climb steeply.
                BranchStyle(leaderReach: 0.6, topBranches: 3, topFan: 0.42, topAt: 0.5,
                            stagger: 0.35, outward: 0.3, limbReach: 0.55, limb: 0.6, bow: -0.04,
                            fork: 0.42, tilt: 0.5, rise: 0.4, inner: 0.45, branchReach: 0.88,
                            innerTwigs: 3, endTwigs: 4, spray: 0.55, twigRise: 0.35)
            case .treeSpreading:
                // Vase: limbs from one low fork rise, then flare wide; a short leader.
                BranchStyle(leaderReach: 0.45, topBranches: 2, topFan: 0.75, topAt: 0.5,
                            stagger: 0, outward: 0.4, limbReach: 0.58, limb: 0.66, bow: -0.05,
                            fork: 0.5, tilt: 0.6, rise: 0.15, inner: 0.7, branchReach: 0.88,
                            innerTwigs: 2, endTwigs: 3, spray: 0.6, twigRise: 0.2)
            default:
                // Rounded: limbs from about the fork go out, then curve up around a leader.
                BranchStyle(leaderReach: 0.55, topBranches: 3, topFan: 0.6, topAt: 0.5,
                            stagger: 0.1, outward: 0.35, limbReach: 0.52, limb: 0.64, bow: 0.06,
                            fork: 0.45, tilt: 0.6, rise: 0.25, inner: 0.6, branchReach: 0.88,
                            innerTwigs: 3, endTwigs: 4, spray: 0.6, twigRise: 0.25)
            }
        }
    }

    /// The bare skeleton of a crown, grown inside its lobes. The trunk carries on as a tapering leader
    /// with branches into the top lobe; one limb leaves toward each side lobe, with an inner branch
    /// rising from its bend and a fork of two at its end. Branches taper to a point near the crown's edge,
    /// with twigs along their outer part. Lengths follow the free run to the crown's edge (0.85 of each
    /// lobe's radius), so tips fill the leafy outline without crossing it.
    static func bareSkeleton(_ shape: TreeShape, style: BranchStyle, trunkRadius: Float, rng: inout StableRandom) -> [Bough] {
        let crown = crownEnvelope(shape, lod: 0)
        let up = SIMD3<Float>(0, 1, 0)
        func jitter(_ a: Float) -> Float { Float(rng.range(Double(-a), Double(a))) }
        func unit(_ v: SIMD3<Float>, or fallback: SIMD3<Float>) -> SIMD3<Float> { simd_length(v) > 1e-5 ? simd_normalize(v) : fallback }
        func grow(_ p: SIMD3<Float>, _ d: SIMD3<Float>, _ reach: Float) -> SIMD3<Float> { p + d * (crown.run(from: p, along: d) * reach) }
        /// Unit vector `polar` off `axis`, turned `azimuth` around it (π/2 = its upper side).
        func around(_ axis: SIMD3<Float>, _ polar: Float, _ azimuth: Float) -> SIMD3<Float> {
            let s1 = simd_normalize(simd_cross(axis, abs(axis.y) > 0.95 ? SIMD3(1, 0, 0) : up)), s2 = simd_cross(s1, axis)
            return simd_normalize(axis * cos(polar) + (s1 * cos(azimuth) + s2 * sin(azimuth)) * sin(polar))
        }
        var boughs: [Bough] = []
        /// A branch leaving bough `parent` at fraction `at`, tapering to a point near the crown's edge,
        /// with `twigs` twigs along its outer part (each thinner than the branch where it leaves).
        func branch(_ parent: Int, at: Float, along d: SIMD3<Float>, radius: Float, twigs: Int, far: Bool) {
            let a = boughs[parent].along(at).p
            let b = grow(a, d, style.branchReach * (1 + jitter(0.06)))
            guard simd_distance(a, b) > 0.02 else { return }
            let index = boughs.count
            boughs.append(Bough(points: [a, b], radii: [radius, 0], order: 1, parent: parent, at: at, far: far))
            let phase = jitter(.pi)
            for i in 0..<twigs {
                let s = 0.28 + 0.4 * (Float(i) + 0.5) / Float(twigs) + jitter(0.04)
                let (p, r) = boughs[index].along(s)
                let e = simd_normalize(around(d, style.spray * (1 + jitter(0.25)), phase + Float(i) * 2.4) + up * style.twigRise)
                let length = min(crown.run(from: p, along: e) * 0.95, 0.11)
                guard length > 0.02 else { continue }
                boughs.append(Bough(points: [p, p + e * length], radii: [r * 0.85, 0], order: 2, parent: index, at: s))
            }
        }
        // Leader: the trunk carries on (its ring and radius) and tapers out up the crown.
        let stemBase = SIMD3<Float>(0, shape.trunkTop + 0.065, 0)
        let stemTop = grow(stemBase, up, style.leaderReach)
        boughs.append(Bough(points: [stemBase, stemBase + (stemTop - stemBase) * 0.45, stemTop],
                            radii: [trunkRadius * 0.97, trunkRadius * 0.62, 0], order: 0, stem: true))
        let phase = jitter(.pi)
        for j in 0..<style.topBranches {
            let at = style.topAt + Float(j) * 0.06 + jitter(0.03)
            let d = around(up, style.topFan + jitter(0.1), phase + Float(j) / Float(style.topBranches) * 2 * .pi + jitter(0.3))
            branch(0, at: at, along: d, radius: boughs[0].along(at).r * 0.85, twigs: 3, far: true)
        }
        // Side limbs: one toward each side lobe's outer side.
        let forkY = shape.trunkTop - 0.04
        for (k, (c, r)) in shape.lobes.enumerated() where k > 0 {
            let out = unit(SIMD3(c.x, 0, c.z), or: SIMD3(cos(Float(k) * 2.4), 0, sin(Float(k) * 2.4)))
            let a = SIMD3<Float>(0, forkY + style.stagger * max(0, c.y - r * 0.6 - forkY), 0)
            let d = rotate(simd_normalize(c + out * (style.outward * r) - a), around: up, by: jitter(0.12))
            let end = grow(a, d, style.limbReach * (1 + jitter(0.06)))
            let length = simd_distance(a, end)
            let lift = unit(up - d * simd_dot(up, d), or: out)
            let side = simd_normalize(simd_cross(d, lift))
            let bend = (a + end) / 2 - lift * (style.bow * length) + side * (jitter(0.05) * length)
            guard length > 0.02 else { continue }
            let baseR = trunkRadius * style.limb
            let limb = boughs.count
            boughs.append(Bough(points: [a, bend, end], radii: [baseR, baseR * 0.75, baseR * 0.55], order: 0, cap: true))
            branch(limb, at: 0.5, along: around(d, style.inner * (1 + jitter(0.15)), .pi / 2 + jitter(0.5)),
                   radius: baseR * 0.6, twigs: style.innerTwigs, far: false)
            // The end fork's plane tilts (alternating per limb), so one branch rises and one reaches out low.
            let dEnd = simd_normalize(end - bend)
            let tangent = rotate(unit(simd_cross(up, dEnd), or: side), around: dEnd,
                                 by: (style.tilt + jitter(0.25)) * (k % 2 == 0 ? 1 : -1))
            for s: Float in [-1, 1] {
                let angle = style.fork * (1 + jitter(0.15))
                branch(limb, at: 1, along: simd_normalize(dEnd * cos(angle) + tangent * (s * sin(angle)) + up * style.rise),
                       radius: baseR * 0.5, twigs: style.endTwigs, far: true)
            }
        }
        return boughs
    }

    /// `v` turned by `angle` around `axis` (Rodrigues).
    static func rotate(_ v: SIMD3<Float>, around axis: SIMD3<Float>, by angle: Float) -> SIMD3<Float> {
        let k = simd_normalize(axis)
        return v * cos(angle) + simd_cross(k, v) * sin(angle) + k * simd_dot(k, v) * (1 - cos(angle))
    }

    /// The leafy volume of one detail level as squashed spheres, for keeping branches inside. A point is
    /// inside within `margin` of a blob's radii, or under a blob (below its centre, within its
    /// footprint), where the canopy hides it from the side.
    struct CrownEnvelope {
        var blobs: [(center: SIMD3<Float>, radii: SIMD3<Float>)]
        var margin: Float = 0.85

        func contains(_ p: SIMD3<Float>) -> Bool {
            for b in blobs where simd_length((p - b.center) / b.radii) <= margin { return true }
            for b in blobs where p.y <= b.center.y && simd_length(SIMD2(p.x - b.center.x, p.z - b.center.z)) <= b.radii.x * margin * 0.9 {
                return true
            }
            return false
        }

        /// How far from `p` (inside) along unit `d` before leaving: steps of 1% of the tree's height, then bisection.
        func run(from p: SIMD3<Float>, along d: SIMD3<Float>) -> Float {
            var t: Float = 0
            while t < 1.5 {
                if !contains(p + d * (t + 0.01)) {
                    var lo = t, hi = t + 0.01
                    for _ in 0..<10 {
                        let mid = (lo + hi) / 2
                        if contains(p + d * mid) { lo = mid } else { hi = mid }
                    }
                    return lo
                }
                t += 0.01
            }
            return t
        }

        /// The farthest point from `a` (inside) toward `b` before leaving.
        func clamp(_ a: SIMD3<Float>, toward b: SIMD3<Float>) -> SIMD3<Float> {
            let length = simd_distance(a, b)
            guard length > 1e-6 else { return b }
            let d = (b - a) / length
            return a + d * min(length, run(from: a, along: d))
        }
    }

    /// The leafy volume each detail level draws (mirrors the crowns built in `deciduous`): all lobes
    /// near, the first two at 1.25× mid, the far lobes' inscribed spheres far.
    static func crownEnvelope(_ shape: TreeShape, lod: Int) -> CrownEnvelope {
        func lobe(_ c: SIMD3<Float>, _ r: Float) -> (center: SIMD3<Float>, radii: SIMD3<Float>) { (c, SIMD3(r, r * 0.92, r)) }
        switch lod {
        case 0: return CrownEnvelope(blobs: shape.lobes.map { lobe($0.0, $0.1) })
        case 1: return CrownEnvelope(blobs: midLobes(shape).map { lobe($0.0, $0.1) })
        default: return farEnvelope(farLobes(shape))
        }
    }

    /// Draws the skeleton at one detail level, kept inside that level's crown. Near: everything (limbs
    /// 4-sided, branches and twigs 3-sided, the leader with the trunk's sides). Mid: the leader, the limbs
    /// (straight) and the branches that shape the outline, no twigs. Far (the trunk carries the leader):
    /// `farSpikes` 3-sided spikes, one per limb from its base toward the middle of its end fork, then
    /// from the leader toward its top branches.
    static func addBareBranches(_ m: inout MeshBuffers, _ skeleton: [Bough], lod: Int, trunkSides: Int, within crown: CrownEnvelope,
                                farSpikes: Int = 0) {
        let trunkRing = SIMD3<Float>(1, 0, 0)
        switch lod {
        case 0:
            for b in skeleton {
                addBranch(&m, b.points, radii: b.radii, sides: b.stem ? trunkSides : (b.order == 0 ? 4 : 3),
                          cap: b.cap, ring: b.stem ? trunkRing : nil)
            }
        case 1:
            var fitted: [Int: Bough] = [:]
            for (i, b) in skeleton.enumerated() where b.order == 0 || (b.order == 1 && b.far) {
                // The leader and limbs need no middle ring at this distance. Branches start on their
                // (possibly shortened) parent; anything cut down to a stub is left out with its branches.
                var f = b
                if b.order == 0 { f.points = [b.points[0], b.points[b.points.count - 1]]; f.radii = [b.radii[0], b.radii[b.radii.count - 1]] }
                var points = [f.points[0]]
                if let parent = b.parent {
                    guard let p = fitted[parent] else { continue }
                    points = [p.along(b.at).p]
                }
                for p in f.points.dropFirst() { points.append(crown.clamp(points[points.count - 1], toward: p)) }
                guard zip(points, points.dropFirst()).reduce(Float(0), { $0 + simd_distance($1.0, $1.1) }) > 0.02 else { continue }
                f.points = points
                fitted[i] = f
                addBranch(&m, points, radii: f.radii.map { $0 * (b.stem ? 1 : 1.15) }, sides: b.stem ? trunkSides : 3,
                          ring: b.stem ? trunkRing : nil)
            }
        default:
            var spikes: [(base: SIMD3<Float>, toward: SIMD3<Float>, radius: Float)] = []
            for (i, limb) in skeleton.enumerated() where limb.order == 0 && !limb.stem {
                let fork = skeleton.filter { $0.parent == i && $0.far }.map { $0.points[$0.points.count - 1] }
                guard !fork.isEmpty else { continue }
                spikes.append((limb.points[0], fork.reduce(SIMD3<Float>(repeating: 0), +) / Float(fork.count), limb.radii[0]))
            }
            for b in skeleton where b.parent == 0 && b.far {
                spikes.append((skeleton[0].along(b.at).p, b.points[b.points.count - 1], b.radii[0]))
            }
            for s in spikes.prefix(farSpikes) {
                let tip = crown.clamp(s.base, toward: s.toward)
                guard simd_distance(s.base, tip) > 0.02 else { continue }
                addBranch(&m, [s.base, tip], radii: [min(s.radius, 0.016), 0], sides: 3)
            }
        }
    }

    // MARK: - Skyline crown

    /// A closed crown shell (skyline detail), star-shaped around `center`.
    struct CrownShell {
        var center: SIMD3<Float>
        var corners: [SIMD3<Float>]
        var normals: [SIMD3<Float>]
        var faces: [SIMD3<UInt32>]
    }

    /// The skyline crown (10 triangles): a dome (apex, two staggered rings of three, a flat triangle
    /// underneath) shrink-wrapped onto the far crown's lobes, partway toward their bounding ellipsoid
    /// (with so few corners the lobes alone give wedges): a rounded top and a flat base like a crown from
    /// the side, a hexagon from above.
    static func skylineCrownShell(_ shape: TreeShape) -> CrownShell {
        shrinkWrap(shape, domeDirections(up: 0.5, down: 0.35), smooth: 0.6)
    }

    /// Unit directions of a dome: an apex, a ring of three at elevation `up`, a ring of three at −`down`
    /// (radians) turned half a step, closed by a flat triangle underneath (7 corners, 10 faces).
    static func domeDirections(up: Float, down: Float) -> Polyhedron {
        var units = [SIMD3<Float>(0, 1, 0)]
        for (e, turn) in [(up, Float(0)), (-down, 0.5)] {
            for k in 0..<3 {
                let a = (Float(k) + turn) * 2 * .pi / 3
                units.append(SIMD3(cos(e) * cos(a), sin(e), cos(e) * sin(a)))
            }
        }
        var faces: [SIMD3<UInt32>] = [[4, 5, 6]]
        for k in 0..<3 {
            let a0 = UInt32(1 + k), a1 = UInt32(1 + (k + 1) % 3), b0 = UInt32(4 + k), b1 = UInt32(4 + (k + 1) % 3)
            faces += [[0, a0, a1], [a0, b0, a1], [a1, b0, b1]]
        }
        return (units, oriented(faces, units))
    }

    /// Faces turned to face outward (each normal along its corners' mean direction).
    static func oriented(_ faces: [SIMD3<UInt32>], _ dirs: [SIMD3<Float>]) -> [SIMD3<UInt32>] {
        faces.map { f in
            let a = dirs[Int(f.x)], b = dirs[Int(f.y)], c = dirs[Int(f.z)]
            return simd_dot(simd_cross(b - a, c - a), a + b + c) > 0 ? f : SIMD3(f.x, f.z, f.y)
        }
    }

    /// Shrink-wraps a unit polyhedron onto the mid crown's lobes, so the crown keeps their outline and
    /// lopsided mass (instance yaw then varies the silhouette). Corner directions are spread over the
    /// lobes' bounding ellipsoid (flat crowns get them nearer the horizon, tall ones nearer the top). Each
    /// corner sits where a ray from the lobes' centre last leaves a lobe (`smooth` moves it toward the
    /// bounding ellipsoid); then all corners move out together until the shell's silhouette covers what
    /// the lobes cover, from the side and from above (its flat faces cut inside between corners).
    /// Normals blend the lobe's with the crown ellipsoid's, like the near lobes.
    static func shrinkWrap(_ shape: TreeShape, _ polyhedron: Polyhedron, smooth: Float = 0) -> CrownShell {
        let lobes = midLobes(shape).map { (center: $0.0, radii: SIMD3($0.1, $0.1 * 0.92, $0.1)) }
        var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
        for l in lobes { lo = simd_min(lo, l.center - l.radii); hi = simd_max(hi, l.center + l.radii) }
        let center = (lo + hi) / 2, half = (hi - lo) / 2
        /// The ray's last exit from a lobe (larger root of |(center + t·d − c) / radii| = 1) and that lobe.
        func exit(_ d: SIMD3<Float>) -> (t: Float, lobe: Int) {
            var best: (t: Float, lobe: Int) = (0, 0)
            for (k, l) in lobes.enumerated() {
                let o = (center - l.center) / l.radii, v = d / l.radii
                let a = simd_dot(v, v), b = 2 * simd_dot(o, v), c = simd_dot(o, o) - 1
                let disc = b * b - 4 * a * c
                guard disc >= 0 else { continue }
                let t = (-b + disc.squareRoot()) / (2 * a)
                if t > best.t { best = (t, k) }
            }
            return best
        }
        let dirs = polyhedron.units.map { simd_normalize($0 * half) }
        let hits = dirs.map { d -> (t: Float, lobe: Int) in
            let h = exit(d)
            return (h.t + (1 / simd_length(d / half) - h.t) * smooth, h.lobe)
        }
        let corners = zip(dirs, hits).map { center + $0 * $1.t }
        // Silhouette areas, sampled with parallel rays on a 40 × 40 grid per view. Scaling the shell about
        // its centre scales its silhouettes by the square.
        let reach = simd_length(half) * 1.5, step = 2 * reach / 40
        // Areas from the side (four views) and from above, the view from above weighing a little more
        // (it is the aerial view's, and the dome is wider from above than from the side).
        var lobeArea: SIMD2<Float> = .zero, shellArea: SIMD2<Float> = .zero
        for v in silhouetteViews {
            let helper: SIMD3<Float> = abs(v.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
            let u1 = simd_normalize(simd_cross(v, helper)), u2 = simd_cross(v, u1)
            let corner = center - (u1 + u2 + v) * reach
            let slot = abs(v.y) > 0.9 ? 1 : 0
            for i in 0..<40 { for j in 0..<40 {
                let o = corner + u1 * ((Float(i) + 0.5) * step) + u2 * ((Float(j) + 0.5) * step)
                if lobes.contains(where: { l in
                    let a = (o - l.center) / l.radii, b = v / l.radii
                    let p = simd_dot(a, b), c = simd_dot(a, a) - 1
                    return p * p - simd_dot(b, b) * c >= 0
                }) { lobeArea[slot] += 1 }
                if polyhedron.faces.contains(where: { f in
                    rayMeetsTriangle(o, v, corners[Int(f.x)], corners[Int(f.y)], corners[Int(f.z)])
                }) { shellArea[slot] += 1 }
            } }
        }
        let ratio = lobeArea / simd_max(shellArea, SIMD2(repeating: 1))
        let inflate = (pow(ratio.x, 0.4) * pow(ratio.y, 0.6)).squareRoot()
        let normals = zip(dirs, hits).map { d, hit in
            let l = lobes[hit.lobe], p = center + d * (hit.t * inflate), onLobe = center + d * exit(d).t
            let lobeN = simd_normalize((onLobe - l.center) / (l.radii * l.radii))
            let ellipsoidN = simd_normalize(d / (half * half))
            let crownN = simd_normalize((p - shape.crown) / (shape.radii * shape.radii))
            return simd_normalize((lobeN + (ellipsoidN - lobeN) * smooth) * 0.5 + crownN * 0.5)
        }
        return CrownShell(center: center, corners: zip(dirs, hits).map { center + $0 * ($1.t * inflate) }, normals: normals, faces: polyhedron.faces)
    }

    /// A smooth cube-sphere ellipsoid (48 triangles).
    static func addCubeSphere(_ m: inout MeshBuffers, center: SIMD3<Float>, radii: SIMD3<Float>) {
        let (verts, faces) = cubeSphere()
        let base = UInt32(m.positions.count)
        for v in verts { m.addVertex(center + v * radii, normal: simd_normalize(v / radii)) }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    /// A cube sphere with each face split 2×2: 26 unit directions, 48 triangles, counter-clockwise outside.
    static func cubeSphere() -> ([SIMD3<Float>], [SIMD3<UInt32>]) {
        var verts: [SIMD3<Float>] = []
        var index: [SIMD3<Int32>: UInt32] = [:]
        var faces: [SIMD3<UInt32>] = []
        for axis in 0..<3 {
            for s: Int32 in [-1, 1] {
                func corner(_ u: Int32, _ v: Int32) -> UInt32 {
                    var p = SIMD3<Int32>(0, 0, 0)
                    p[axis] = s
                    p[(axis + 1) % 3] = u
                    p[(axis + 2) % 3] = v
                    if let i = index[p] { return i }
                    verts.append(simd_normalize(SIMD3<Float>(Float(p.x), Float(p.y), Float(p.z))))
                    index[p] = UInt32(verts.count - 1)
                    return UInt32(verts.count - 1)
                }
                for u: Int32 in [-1, 0] { for v: Int32 in [-1, 0] {
                    let a = corner(u, v), b = corner(u + 1, v), c = corner(u + 1, v + 1), d = corner(u, v + 1)
                    faces += s > 0 ? [[a, b, c], [a, c, d]] : [[a, c, b], [a, d, c]]
                } }
            }
        }
        return (verts, faces)
    }

    static func conifer(lod: Int, palette: Palette) -> MeshBuffers {
        var m = MeshBuffers()
        if lod == 3 {
            // Skyline: the far cone alone, no trunk and open underneath (5 triangles).
            m.paint = Paint(slot: palette.named("conifer1"), flags: .variant2, sway: 0.5)
            addSpire(&m, base: 0.14, top: 1.0, radius: 0.24, sides: 5)
            m.bakeAO(from: 0) { p, _ in Float(0.7 + 0.3 * smoothstep(0.1, 0.9, Double(p.y))) }
            return m
        }
        m.paint = Paint(slot: palette.named("bark"))
        addCylinder(&m, radius: 0.018, z0: 0, z1: 0.22, sides: lod == 0 ? 6 : 3, smooth: true, cap: false)
        m.bakeAO(from: 0) { p, _ in p.y > 0.15 ? 0.6 : 0.85 }
        m.paint = Paint(slot: palette.named("conifer1"), flags: .variant2, sway: 0.5)
        let start = m.positions.count
        let tiers: [(Float, Float, Float)] = lod == 2 ? [(0.14, 1.0, 0.24)]
            : [(0.14, 0.58, 0.26), (0.38, 0.8, 0.2), (0.6, 1.0, 0.13)]
        for (z0, z1, r) in tiers { addCone(&m, radius: r, z0: z0, z1: z1, sides: lod == 0 ? 10 : (lod == 1 ? 7 : 5)) }
        m.bakeAO(from: start) { p, n in n.y < -0.5 ? 0.6 : Float(0.7 + 0.3 * smoothstep(0.1, 0.9, Double(p.y))) }
        return m
    }

    /// A branch: a smooth tube along `path` with a radius per point. Rings turn to the averaged
    /// direction at each joint and are carried along without twisting; a last radius of 0 ends in a
    /// point, `cap` closes an open end, and `ring` sets where the first ring starts (the leader matches
    /// the trunk's). Bark AO 0.75.
    static func addBranch(_ m: inout MeshBuffers, _ path: [SIMD3<Float>], radii widths: [Float], sides: Int, cap: Bool = false,
                          ring: SIMD3<Float>? = nil) {
        guard !path.isEmpty, widths.count == path.count else { return }
        // A joint shortened to nothing would leave a flat ring: drop points that coincide with the last kept one.
        var keep = [0]
        for i in path.indices.dropFirst() where simd_distance(path[i], path[keep[keep.count - 1]]) > 1e-4 { keep.append(i) }
        let points = keep.map { path[$0] }, radii = keep.map { widths[$0] }
        guard points.count >= 2 else { return }
        var dirs: [SIMD3<Float>] = []
        for i in 0..<points.count {
            let d = points[min(points.count - 1, i + 1)] - points[max(0, i - 1)]
            dirs.append(simd_length(d) > 1e-6 ? simd_normalize(d) : SIMD3(0, 1, 0))
        }
        let helper: SIMD3<Float> = abs(dirs[0].y) < 0.9 ? [0, 1, 0] : [1, 0, 0]
        var u = ring.map { simd_normalize($0 - dirs[0] * simd_dot($0, dirs[0])) } ?? simd_normalize(simd_cross(dirs[0], helper))
        m.extra = SIMD4(0.75, 0, 0, 0)
        var rings: [[UInt32]] = []
        for (i, p) in points.enumerated() {
            if i > 0 { u = simd_normalize(u - dirs[i] * simd_dot(u, dirs[i])) }
            let v = simd_cross(dirs[i], u)
            var ids: [UInt32] = []
            for s in 0..<sides {
                if radii[i] > 0 {
                    let t = Float(s) / Float(sides) * 2 * .pi
                    let n = u * cos(t) + v * sin(t)
                    ids.append(m.addVertex(p + n * radii[i], normal: n))
                } else {
                    // Pointed end: one vertex per side, so each side keeps its own normal.
                    let t = (Float(s) + 0.5) / Float(sides) * 2 * .pi
                    ids.append(m.addVertex(p, normal: u * cos(t) + v * sin(t)))
                }
            }
            rings.append(ids)
        }
        for i in 1..<rings.count {
            let a = rings[i - 1], b = rings[i]
            for s in 0..<sides {
                let s1 = (s + 1) % sides
                if radii[i] > 0 {
                    m.addTriangle(a[s], a[s1], b[s1])
                    m.addTriangle(a[s], b[s1], b[s])
                } else {
                    m.addTriangle(a[s], a[s1], b[s])
                }
            }
        }
        if cap, let r = radii.last, r > 0 {
            let d = dirs[dirs.count - 1], v = simd_cross(d, u)
            let first = UInt32(m.positions.count)
            for s in 0..<sides {
                let t = Float(s) / Float(sides) * 2 * .pi
                m.addVertex(points[points.count - 1] + (u * cos(t) + v * sin(t)) * r, normal: d)
            }
            for s in 1..<UInt32(sides - 1) { m.addTriangle(first, first + s, first + s + 1) }
        }
        m.extra = SIMD4(1, 0, 0, 0)
    }

    // MARK: - Builders

    static func box(_ m: inout MeshBuffers, c: SIMD3<Float>, half h: SIMD3<Float>) {
        let x = SIMD3<Float>(h.x, 0, 0), y = SIMD3<Float>(0, h.y, 0), z = SIMD3<Float>(0, 0, h.z)
        let faces: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = [(y, x, z), (-y, x, z), (x, y, z), (-x, y, z), (z, x, y), (-z, x, y)]
        for (n, a, b) in faces {
            let o = c + n
            m.addFace([o - a - b, o + a - b, o + a + b, o - a + b], facing: simd_normalize(n))
        }
    }

    /// Cylinder side (+ optional top cap), `sides` segments; smooth or flat normals.
    static func addCylinder(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, sides: Int, smooth: Bool, cap: Bool = true) {
        for i in 0..<sides {
            let a0 = Float(i) / Float(sides) * 2 * .pi, a1 = Float(i + 1) / Float(sides) * 2 * .pi
            let p0 = SIMD3(cos(a0) * r, 0, sin(a0) * r), p1 = SIMD3(cos(a1) * r, 0, sin(a1) * r)
            if smooth {
                let n0 = simd_normalize(p0), n1 = simd_normalize(p1)
                let b = m.addVertex(p0 + SIMD3(0, z0, 0), normal: n0)
                m.addVertex(p1 + SIMD3(0, z0, 0), normal: n1)
                m.addVertex(p1 + SIMD3(0, z1, 0), normal: n1)
                m.addVertex(p0 + SIMD3(0, z1, 0), normal: n0)
                m.addTriangle(b, b + 2, b + 1)
                m.addTriangle(b, b + 3, b + 2)
            } else {
                m.addFace([p0 + SIMD3(0, z0, 0), p1 + SIMD3(0, z0, 0), p1 + SIMD3(0, z1, 0), p0 + SIMD3(0, z1, 0)],
                          facing: simd_normalize(p0 + p1))
            }
        }
        guard cap else { return }
        let top = (0..<sides).map { i -> SIMD3<Float> in
            let a = Float(i) / Float(sides) * 2 * .pi
            return SIMD3(cos(a) * r, z1, sin(a) * r)
        }
        m.addFace(top, facing: sceneUp)
    }

    /// Smooth cone, apex up, without an underside (`sides` triangles): skyline detail, seen from the side
    /// or above.
    static func addSpire(_ m: inout MeshBuffers, base y0: Float, top y1: Float, radius r: Float, sides: Int) {
        let slope = r / (y1 - y0)
        let apex = m.addVertex(SIMD3(0, y1, 0), normal: SIMD3(0, 1, 0))
        let ring = (0..<sides).map { i -> UInt32 in
            let a = Float(i) / Float(sides) * 2 * .pi
            return m.addVertex(SIMD3(cos(a) * r, y0, sin(a) * r), normal: simd_normalize(SIMD3(cos(a), slope, sin(a))))
        }
        for i in 0..<sides { m.addTriangle(apex, ring[(i + 1) % sides], ring[i]) }
    }

    /// Smooth cone with a flat underside.
    static func addCone(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, sides: Int) {
        let h = z1 - z0
        let slope = r / h
        let apex = m.addVertex(SIMD3(0, z1, 0), normal: SIMD3(0, 1, 0))
        var ring: [UInt32] = []
        for i in 0..<sides {
            let a = Float(i) / Float(sides) * 2 * .pi
            let n = simd_normalize(SIMD3(cos(a), slope, sin(a)))
            ring.append(m.addVertex(SIMD3(cos(a) * r, z0, sin(a) * r), normal: n))
        }
        for i in 0..<sides { m.addTriangle(apex, ring[(i + 1) % sides], ring[i]) }
        let shade = m.paint
        m.paint = Paint(slot: shade.slot, shade: shade.shade * 0.8, flags: shade.flags, sway: shade.sway)
        let base = (0..<sides).map { i -> SIMD3<Float> in
            let a = Float(i) / Float(sides) * 2 * .pi
            return SIMD3(cos(a) * r, z0, sin(a) * r)
        }
        m.addFace(base, facing: -sceneUp)
        m.paint = shade
    }

    /// A smooth, slightly lumpy blob (icosphere: 80 triangles subdivided, 20 not).
    static func addBlob(_ m: inout MeshBuffers, center: SIMD3<Float>, radius: Float, squash: Float, jitter: Double,
                        rng: inout StableRandom, subdivide: Bool = true) {
        var (verts, faces) = icosahedron()
        if subdivide { (verts, faces) = subdivided(verts, faces) }
        let base = UInt32(m.positions.count)
        for v in verts {
            let k = Float(1 + rng.range(-jitter, jitter))
            let p = v * radius * k
            let pos = center + SIMD3(p.x, p.y * squash, p.z)
            let n = simd_normalize(SIMD3(v.x, v.y / max(squash, 0.01), v.z))
            m.addVertex(pos, normal: n)
        }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    /// A smooth ellipsoid (octahedron, 8 triangles; or icosahedron, 20).
    static func addEllipsoid(_ m: inout MeshBuffers, center: SIMD3<Float>, radii: SIMD3<Float>, octahedron: Bool) {
        let (verts, faces): ([SIMD3<Float>], [SIMD3<UInt32>]) = octahedron
            ? ([[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]],
               [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]])
            : icosahedron()
        let base = UInt32(m.positions.count)
        for v in verts { m.addVertex(center + v * radii, normal: simd_normalize(v / radii)) }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    static func icosahedron() -> ([SIMD3<Float>], [SIMD3<UInt32>]) {
        let t: Float = (1 + 5.0.squareRoot().float) / 2
        let v: [SIMD3<Float>] = [
            [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t],
            [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
        ].map { simd_normalize($0) }
        let f: [SIMD3<UInt32>] = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
        ]
        return (v, f)
    }

    static func subdivided(_ v: [SIMD3<Float>], _ f: [SIMD3<UInt32>]) -> ([SIMD3<Float>], [SIMD3<UInt32>]) {
        var verts = v
        var cache: [UInt64: UInt32] = [:]
        func mid(_ a: UInt32, _ b: UInt32) -> UInt32 {
            let key = UInt64(min(a, b)) << 32 | UInt64(max(a, b))
            if let i = cache[key] { return i }
            verts.append(simd_normalize((verts[Int(a)] + verts[Int(b)]) / 2))
            cache[key] = UInt32(verts.count - 1)
            return UInt32(verts.count - 1)
        }
        var faces: [SIMD3<UInt32>] = []
        for t in f {
            let a = mid(t.x, t.y), b = mid(t.y, t.z), c = mid(t.z, t.x)
            faces += [[t.x, a, c], [t.y, b, a], [t.z, c, b], [a, b, c]]
        }
        return (verts, faces)
    }
}

extension Double {
    var float: Float { Float(self) }
}

extension String {
    /// FNV-1a hash, stable across runs (unlike `hashValue`).
    var hashValueStable: UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in utf8 { h ^= UInt64(b); h &*= 0x100_0000_01B3 }
        return h
    }
}
