import Foundation
import simd
import WorldGeo
import WorldMesh

/// Instanced prop kinds. Each (kind, variant) is one mesh per detail level, drawn many times.
public enum PropKind: String, Sendable, CaseIterable, Codable {
    case treeBroad, treeOval, treeSpreading, conifer, lamp, bench, bush, flowerBush, tuft
    /// Weeping willow (vegetation-v1 addendum): joined upper lobes over hanging curtains.
    case treeWeeping
    /// Species crown silhouettes (foliage-seasons-v1 species sheets; regions with a city mix,
    /// `vegetation.json` `foliageSeasons`): dense rounded (Norway maple), pyramidal oval (linden), tall
    /// vase (American elm, cottonwood), open wide and airy (honeylocust, silver maple), upright oval
    /// (green ash, aspen). Ten near lobes, five at mid, one shrink-wrapped far mass.
    case treeRounded, treePyramidal, treeVase, treeOpen, treeUpright

    public var isTree: Bool { [.treeBroad, .treeOval, .treeSpreading, .conifer, .treeWeeping].contains(self) || isSpeciesCrown }
    /// One of the species silhouettes (foliage-seasons-v1).
    public var isSpeciesCrown: Bool { [.treeRounded, .treePyramidal, .treeVase, .treeOpen, .treeUpright].contains(self) }
    public var isFoliage: Bool { ![.lamp, .bench].contains(self) }
}

/// Reusable prop meshes in object space (scene axes, origin on the ground, +Y up).
/// Organic props have shared vertices and smooth normals; built objects are flat-shaded.
public struct PropLibrary: Sendable {
    /// Shape variants per kind (instances pick one at generation time). Each variant is its own instanced
    /// draw per cell and detail level, so trees vary per instance instead (yaw, `PropInstance.stretch`).
    /// Bushes and flowering bushes share their numbering (look-fix-v1 §1.2): 0, 1 = the original rounded
    /// bushes; 2, 6, 7 = low cushions; 3 = medium loose shrub; 4 = upright shrub; 5 = hedge segment
    /// (1 m along local +X).
    public static let variants: [PropKind: Int] = [
        .treeBroad: 1, .treeOval: 1, .treeSpreading: 1, .conifer: 1, .lamp: 1, .bench: 1, .bush: 8, .flowerBush: 8, .tuft: 2,
        .treeWeeping: 1, .treeRounded: 1, .treePyramidal: 1, .treeVase: 1, .treeOpen: 1, .treeUpright: 1,
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

    /// Crown lobes (center, radius) in unit-height tree space for each archetype: a clustered, lopsided
    /// crown of unequal, intersecting lobes (look-fix-v1 §5, vegetation-v1 crown construction: merged
    /// masses with sky holes, not a pile of balls). Side-view sky holes inside the crown's convex outline
    /// (vegetation-v1 targets): broad/maple ≈ 6%, oval/linden ≈ 5%, spreading/oak ≈ 10%.
    /// Lobe 0 is the top lobe; lobes 1…`BranchStyle.limbs` are the major side lobes (each gets a limb, and lobes
    /// 0 and 1 make the mid crown); later lobes are smaller shoulders that break the outline into an
    /// asymmetric top and notches between lobes (they drop their leaves first).
    public static func lobes(_ kind: PropKind) -> TreeShape {
        switch kind {
        case .treeWeeping:
            // Weeping willow (vegetation-v1 addendum: 7–10 joined upper lobes, 15–22% sky holes): a
            // broad, low dome of unequal lobes, as wide as the tree is tall; curtains hang from its rim
            // (`willowCurtains`).
            return TreeShape(0.42, [0, 0.76, 0], [0.42, 0.18, 0.42], [
                ([0.04, 0.84, 0.02], 0.16), ([-0.21, 0.76, 0.06], 0.14), ([0.23, 0.75, -0.05], 0.13),
                ([0.02, 0.74, 0.25], 0.12), ([-0.05, 0.73, -0.25], 0.12),
                ([0.2, 0.81, 0.19], 0.09), ([-0.2, 0.82, -0.18], 0.09),
            ])
        // Species silhouettes (foliage-seasons-v1 species sheets, detail tiers: near 9–18 clustered
        // lobes, mid 5–9, far 1–3 masses). Ten lobes each: the top lobe, four major side lobes (one limb
        // each), then shoulders and rim lobes; the first five (×1.1) are the mid crown. Crown width to
        // tree height is set near the main species' pack spread/height; other species in the family
        // scale their width (`VegetationLibrary.FoliageSpecies.widthScale`).
        case .treeRounded:
            // Norway maple (trees-02 row 1: "dense rounded wide crown"): a full dome, lobes overlapping,
            // shallow notches, crown down to about 40 % of the height. Width/height ≈ 0.8.
            return TreeShape(0.36, [0, 0.66, 0], [0.4, 0.3, 0.4], [
                ([0.03, 0.8, 0.02], 0.19), ([-0.22, 0.64, 0.09], 0.18), ([0.23, 0.62, -0.07], 0.17), ([0.03, 0.61, -0.24], 0.16),
                ([-0.05, 0.63, 0.25], 0.16), ([-0.17, 0.83, -0.11], 0.12), ([0.18, 0.82, 0.13], 0.12),
                ([0.29, 0.49, 0.15], 0.1), ([-0.28, 0.49, -0.13], 0.1), ([0.09, 0.91, -0.09], 0.085),
            ], mid: 5, midScale: 1.1)
        case .treePyramidal:
            // Littleleaf linden (trees-03 row 2: "dense heartlike oval/pyramidal crown, single trunk"):
            // broadest in the lower third, tapering to a narrow pointed top over a central upper mass.
            return TreeShape(0.3, [0, 0.62, 0], [0.32, 0.3, 0.32], [
                ([0, 0.72, 0.01], 0.19), ([-0.18, 0.5, 0.07], 0.17), ([0.19, 0.48, -0.06], 0.165), ([0.04, 0.49, 0.2], 0.16),
                ([-0.05, 0.51, -0.19], 0.16), ([0.01, 0.89, -0.02], 0.095), ([0.12, 0.75, 0.1], 0.11),
                ([-0.12, 0.74, -0.09], 0.11), ([0.24, 0.38, 0.12], 0.09), ([-0.22, 0.38, -0.14], 0.09),
            ], mid: 5, midScale: 1.1)
        case .treeVase:
            // American elm (trees-03 row 3: "tall broad vase, arching upward/outward main limbs"; cottonwood
            // "large high open vase crown" shares it, narrower): limbs rise from a low fork to an umbrella
            // of lobes widest near the top, open underneath down to the fork.
            return TreeShape(0.3, [0, 0.8, 0], [0.34, 0.17, 0.34], [
                ([0, 0.86, 0], 0.14), ([0.21, 0.79, 0.06], 0.13), ([-0.21, 0.8, -0.05], 0.13), ([0.04, 0.78, 0.21], 0.125),
                ([-0.06, 0.79, -0.21], 0.125), ([0.16, 0.9, -0.14], 0.09), ([-0.15, 0.9, 0.14], 0.09),
                ([0.29, 0.76, -0.12], 0.07), ([-0.28, 0.77, 0.13], 0.07), ([-0.07, 0.94, -0.06], 0.055),
            ], mid: 5, midScale: 1.1, column: 0.2)
        case .treeOpen:
            // Honeylocust (trees-01 row 1: "open wide oval, airy fine canopy, 7 uneven lobes, visible
            // branching gaps"; silver maple shares it, narrower): small separated lobes spread wide and
            // flat, sky between them and the scaffold showing.
            return TreeShape(0.37, [0, 0.71, 0], [0.46, 0.2, 0.46], [
                ([0.02, 0.81, 0], 0.15), ([0.29, 0.7, 0.05], 0.13), ([-0.3, 0.72, -0.06], 0.125), ([0.03, 0.68, 0.3], 0.125),
                ([-0.07, 0.69, -0.29], 0.125), ([0.21, 0.84, -0.21], 0.09), ([-0.2, 0.85, 0.21], 0.09),
                ([0.4, 0.69, -0.13], 0.07), ([-0.39, 0.68, 0.15], 0.07), ([0.13, 0.9, 0.13], 0.075),
            ], mid: 5, midScale: 1.1, column: 0.24)
        case .treeUpright:
            // Green ash (trees-03 row 1: "upright oval open crown with clear opposing branch rhythm"; aspen
            // shares it, narrower): a tall oval of paired lobes up a leader, a small top lobe.
            return TreeShape(0.33, [0, 0.68, 0], [0.29, 0.26, 0.29], [
                ([0.02, 0.82, 0.01], 0.16), ([-0.17, 0.64, 0.06], 0.15), ([0.17, 0.61, -0.05], 0.14), ([0.02, 0.55, 0.18], 0.13),
                ([-0.03, 0.57, -0.18], 0.13), ([0.12, 0.76, 0.12], 0.105), ([-0.13, 0.78, -0.11], 0.105),
                ([0.22, 0.46, 0.07], 0.085), ([-0.2, 0.45, -0.09], 0.085), ([-0.03, 0.93, -0.04], 0.07),
            ], mid: 5, midScale: 1.1)
        case .treeOval:
            // Upright oval (linden: tapered oval, 5–8 lobes): a column of offset lobes, a high shoulder
            // on each side, a narrower waist and a low lobe over the fork.
            return TreeShape(0.40, [0, 0.68, 0], [0.19, 0.30, 0.19], [
                ([0.02, 0.83, 0.01], 0.15), ([-0.04, 0.64, 0.03], 0.18), ([0.1, 0.55, -0.06], 0.12), ([0.04, 0.47, 0.11], 0.1),
                ([-0.13, 0.8, -0.04], 0.09), ([0.14, 0.72, 0.05], 0.09),
            ])
        case .treeSpreading:
            // Open spreading (oak: unequal spreading shoulders, 7–10 lobes; elm and honey locust share it):
            // wide and flat-topped, separated rim lobes at different heights with gaps between them.
            return TreeShape(0.46, [0, 0.66, 0], [0.37, 0.2, 0.37], [
                ([0, 0.74, 0], 0.18), ([0.22, 0.64, 0.05], 0.15), ([-0.23, 0.67, -0.08], 0.13),
                ([0.05, 0.61, 0.22], 0.115), ([-0.09, 0.6, -0.22], 0.115),
                ([0.23, 0.75, -0.2], 0.09), ([-0.22, 0.76, 0.19], 0.09),
            ])
        default:
            // Broad rounded (maple: upright rounded, uneven height, 6–9 lobes): an off-centre top lobe with
            // two smaller crests beside it (notches between them), three side lobes and a low shoulder.
            return TreeShape(0.44, [0, 0.67, 0], [0.32, 0.26, 0.32], [
                ([0.05, 0.78, 0.02], 0.19), ([-0.15, 0.64, 0.07], 0.18), ([0.2, 0.61, -0.06], 0.14), ([-0.02, 0.58, -0.2], 0.13),
                ([-0.18, 0.82, -0.06], 0.11), ([0.22, 0.54, 0.14], 0.1), ([0.14, 0.86, -0.12], 0.09),
            ])
        }
    }

    /// Crown width of a tree kind at unit height (mean of the lobes' x and z extents; conifers their
    /// lowest tier's span).
    public static func crownWidth(_ kind: PropKind) -> Float {
        if kind == .conifer { return 0.54 }
        var lo = SIMD2<Float>(repeating: .infinity), hi = -lo
        for (c, r) in lobes(kind).lobes {
            lo = simd_min(lo, SIMD2(c.x - r, c.z - r))
            hi = simd_max(hi, SIMD2(c.x + r, c.z + r))
        }
        return ((hi.x - lo.x) + (hi.y - lo.y)) / 2
    }

    /// Mesh for a prop variant. Trees and lamps are unit height (scale by instance); benches,
    /// bushes and tufts are real size.
    /// How deciduous (and willow) crowns are built at near and mid detail; far and skyline are the same
    /// in every style. Prototypes for the owner's style check, default `.solid` (main renders
    /// unchanged): `.leafCards` = alpha-tested leaf cards (`Paint.Flags.leafCard`, needs the card
    /// material), `.puffs` = clusters of smooth rounded puffs on a flared trunk with scaffold limbs.
    public enum CrownStyle: String, Sendable, CaseIterable {
        case solid, leafCards, puffs
    }

    /// The default crown style: `WORLDENGINE_CROWN_STYLE=solid|leafCards|puffs` (or the older
    /// `WORLDENGINE_LEAF_CARDS=1`), else `.solid`. Per call: `mesh(…, style:)`; buildingviz `--crown-style`.
    public static let crownStyle: CrownStyle = {
        let env = ProcessInfo.processInfo.environment
        if let s = env["WORLDENGINE_CROWN_STYLE"].flatMap(CrownStyle.init(rawValue:)) { return s }
        return env["WORLDENGINE_LEAF_CARDS"] == "1" ? .leafCards : .solid
    }()

    /// Whether the default crown style is leaf cards.
    public static var leafCards: Bool { crownStyle == .leafCards }

    public static func mesh(_ kind: PropKind, variant: Int, lod: Int = 0, palette: Palette, leafCards: Bool) -> MeshBuffers {
        mesh(kind, variant: variant, lod: lod, palette: palette, style: leafCards ? .leafCards : .solid)
    }

    public static func mesh(_ kind: PropKind, variant: Int, lod: Int = 0, palette: Palette, style: CrownStyle = PropLibrary.crownStyle) -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, UInt64(variant), salt: "prop")
        switch kind {
        case .treeBroad, .treeOval, .treeSpreading, .treeWeeping, .treeRounded, .treePyramidal, .treeVase, .treeOpen, .treeUpright:
            return deciduous(kind, lod: lod, palette: palette, rng: &rng, style: style)
        case .conifer:
            return conifer(lod: lod, palette: palette, rng: &rng, cards: style == .leafCards, smooth: style == .puffs)
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
            if variant >= 2 { return shrub(kind, variant: variant, lod: lod, palette: palette) }
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

    // MARK: - Shrub forms

    /// A shrub silhouette (look-fix-v1 §1.2), real size in metres: a closed lathe around +Y whose rings
    /// carry soft lobes, so they merge into one irregular mass (no separate spheres) with a flat-ish
    /// bottom sunk 3 cm into the ground. Hedge segments use a rounded-rectangle section, 1 m long
    /// along local +X with flat-ish ends, so segments yawed to the row and placed every 0.9–1 m read
    /// as one hedge.
    struct ShrubForm {
        /// Height of the top pole and half widths (x, z) of the profile.
        var height: Float, halfX: Float, halfZ: Float
        /// Near profile rings, bottom → top: (height share, radius share). A negative height share is the
        /// ground ring, at −sink.
        var rings: [SIMD2<Float>]
        /// Lobes: azimuth (rad), radial amplitude (share of the radius), angular width (rad), height share.
        var lobes: [SIMD4<Float>]
        /// Uneven top: azimuth (rad), height (m), angular width (rad); grows toward the top.
        var tops: [SIMD3<Float>] = []
        /// Lean: horizontal shift (x, z) per metre of height.
        var lean = SIMD2<Float>(0, 0)
        /// Rounded-rectangle section (hedge segments).
        var boxy = false
        /// Height shares of the mid level's upper ring and the far level's equator.
        var midRing: Float = 0.58, farRing: Float = 0.42

        static let sink: Float = 0.03
        static let cushion: [SIMD2<Float>] = [[-1, 0.86], [0.32, 1.0], [0.66, 0.88], [0.9, 0.52]]

        /// One detail level of the lathe: 2 × sides × rings triangles (near 72, mid 20 (hedge 16), far 8).
        struct Level {
            /// Ring vertex azimuths (rad, in order around +Y from +X toward +Z) and profile rings.
            var azimuths: [Float], rings: [SIMD2<Float>]
            /// Explicit unit section points (one per azimuth) instead of the superellipse.
            var section: [SIMD2<Float>]? = nil
            /// Lobe and uneven-top scales, radial jitter, section squareness (superellipse exponent).
            var lobes: Float, tops: Float, jitter: Float, square: Float
            var sides: Int { azimuths.count }

            init(sides: Int, phase: Float = 0, rings: [SIMD2<Float>], lobes: Float, tops: Float, jitter: Float, square: Float) {
                self.init(azimuths: (0..<sides).map { phase + Float($0) / Float(sides) * 2 * .pi }, rings: rings,
                          lobes: lobes, tops: tops, jitter: jitter, square: square)
            }

            init(azimuths: [Float], rings: [SIMD2<Float>], lobes: Float, tops: Float, jitter: Float, square: Float) {
                (self.azimuths, self.rings, self.lobes, self.tops, self.jitter, self.square) = (azimuths, rings, lobes, tops, jitter, square)
            }
        }

        /// Hedge section (unit half-length × half-width): square-ish ends that keep 82% of the width,
        /// so sections in a row join without a waist; five points along each long side.
        static let hedgeSection: [SIMD2<Float>] = [[1, 0], [0.97, 0.82], [0.75, 1], [0.4, 1], [0, 1.02], [-0.4, 1], [-0.75, 1], [-0.97, 0.82],
                                                   [-1, 0], [-0.97, -0.82], [-0.75, -1], [-0.4, -1], [0, -1.02], [0.4, -1], [0.75, -1], [0.97, -0.82]]

        func level(_ lod: Int) -> Level {
            switch (lod, boxy) {
            case (0, true):
                var near = Level(azimuths: Self.hedgeSection.map { atan2($0.y, $0.x) }, rings: rings, lobes: 1, tops: 1, jitter: 0.015, square: 2)
                near.section = Self.hedgeSection
                return near
            case (0, false): return Level(sides: 9, rings: rings, lobes: 1, tops: 1, jitter: 0.03, square: 2)
            case (1, true): return Level(sides: 4, phase: .pi / 4, rings: [rings[0], [0.9, 0.97]], lobes: 0, tops: 0, jitter: 0, square: 12)
            case (1, false): return Level(sides: 5, rings: [rings[0], [midRing, 0.97]], lobes: 0.7, tops: 1, jitter: 0.015, square: 2)
            default: return Level(sides: 4, rings: [[farRing, 1.0]], lobes: 0, tops: 0.5, jitter: 0, square: 2)
            }
        }

        /// Bush variants 2…7 (0 and 1 are the original rounded bushes).
        static func of(_ variant: Int) -> ShrubForm {
            switch variant {
            case 3:
                // Medium loose shrub: narrow base, wide irregular middle, top higher on one side, leaning ~7°.
                ShrubForm(height: 0.85, halfX: 0.53, halfZ: 0.47, rings: [[-1, 0.72], [0.3, 0.95], [0.62, 1.0], [0.86, 0.66]],
                          lobes: [[0.4, 0.16, 0.6, 0.6], [1.9, 0.12, 0.55, 0.45], [3.3, 0.15, 0.6, 0.7], [4.9, 0.11, 0.5, 0.5]],
                          tops: [[0.7, 0.1, 0.9], [3.9, -0.07, 0.9]], lean: [0.12, 0.03], midRing: 0.62, farRing: 0.48)
            case 4:
                // Upright shrub: narrow and tall, an open crown of stacked lobes.
                ShrubForm(height: 1.35, halfX: 0.34, halfZ: 0.31, rings: [[-1, 0.62], [0.3, 0.92], [0.6, 1.0], [0.88, 0.82]],
                          lobes: [[0.5, 0.2, 0.7, 0.3], [2.7, 0.2, 0.7, 0.55], [4.6, 0.18, 0.7, 0.85], [1.6, 0.14, 0.5, 0.88]],
                          tops: [[1.2, 0.08, 0.7], [4.2, -0.05, 0.8]], lean: [0.03, -0.02], midRing: 0.72, farRing: 0.55)
            case 5:
                // Hedge section (vegetation-v1: one continuous envelope with an irregular crest, broken
                // into 1.5–3 m cullable sections): 2 m along +X, 0.7 m wide, 0.95 m high; the crest rises
                // and dips ±0.06–0.1 m along both long sides, ends left plain so sections join.
                ShrubForm(height: 0.95, halfX: 1.0, halfZ: 0.35, rings: [[-1, 0.94], [0.45, 1.0], [0.95, 0.95]],
                          lobes: [[1.19, 0.04, 0.2, 0.6], [1.951, 0.05, 0.2, 0.5], [4.332, 0.05, 0.2, 0.55], [5.093, 0.04, 0.2, 0.6]],
                          tops: [[0.927, 0.09, 0.15], [1.19, -0.07, 0.15], [1.571, 0.1, 0.15], [1.951, -0.06, 0.15], [2.214, 0.08, 0.15],
                                 [4.069, -0.08, 0.15], [4.332, 0.07, 0.15], [4.712, -0.09, 0.15], [5.093, 0.06, 0.15], [5.356, -0.07, 0.15]],
                          boxy: true)
            case 6:
                // Second cushion: wide and flat, two merged mounds with a shallow saddle.
                ShrubForm(height: 0.36, halfX: 0.42, halfZ: 0.31, rings: cushion,
                          lobes: [[0.0, 0.18, 0.6, 0.5], [3.14, 0.16, 0.6, 0.45], [1.7, 0.07, 0.5, 0.5]],
                          tops: [[0.1, 0.035, 0.7], [3.1, 0.025, 0.7], [1.6, -0.03, 0.5], [4.7, -0.025, 0.5]])
            case 7:
                // Third cushion: compact, taller mound of four soft lobes.
                ShrubForm(height: 0.52, halfX: 0.28, halfZ: 0.26, rings: cushion,
                          lobes: [[0.3, 0.12, 0.6, 0.5], [1.9, 0.13, 0.6, 0.45], [3.5, 0.11, 0.6, 0.55], [5.0, 0.13, 0.6, 0.5]],
                          tops: [[4.0, 0.04, 0.8]])
            default:
                // Low cushion: rounded and irregular, three merged lobes.
                ShrubForm(height: 0.45, halfX: 0.35, halfZ: 0.31, rings: cushion,
                          lobes: [[0.3, 0.16, 0.75, 0.5], [2.4, 0.16, 0.75, 0.45], [4.4, 0.13, 0.75, 0.55]],
                          tops: [[0.3, 0.03, 0.8], [3.2, -0.02, 0.8]])
            }
        }
    }

    /// Bush and flowering-bush variants 2…7. The body depends only on variant and detail level (kind
    /// is colour, variant is form); flowering bushes add small flower accents at near detail.
    static func shrub(_ kind: PropKind, variant: Int, lod: Int, palette: Palette) -> MeshBuffers {
        let form = ShrubForm.of(variant)
        var m = MeshBuffers()
        m.paint = Paint(slot: palette.named("bushes"), shade: kind == .flowerBush ? 1.08 : 1, sway: 0.2)
        if lod >= 3 {
            addShrubSkyline(&m, form)
            return m
        }
        if lod == 2, form.boxy {
            addHedgeTent(&m, form)
            return m
        }
        var rng = StableRandom(UInt64(variant), UInt64(lod), salt: "shrub-form")
        addShrubBody(&m, form, form.level(lod), rng: &rng)
        if kind == .flowerBush, lod == 0 {
            var fr = StableRandom(UInt64(variant), salt: "shrub-flowers")
            addFlowerAccents(&m, count: 8, height: form.height, slot: palette.named(variant % 2 == 0 ? "flowers" : "flowersAlt"), rng: &fr)
        }
        return m
    }

    /// The lathe body: bottom centre, rings, top pole (leaning toward the high side of an uneven top).
    /// Normals: smooth face averages softened toward the form's ellipsoid. AO darker underneath (like
    /// bush variants 0 and 1) and slightly darker in the creases between lobes.
    static func addShrubBody(_ m: inout MeshBuffers, _ f: ShrubForm, _ level: ShrubForm.Level, rng: inout StableRandom) {
        let h = f.height, n = level.sides
        func bump(_ a: Float, _ at: Float, _ width: Float) -> Float {
            var d = (a - at).truncatingRemainder(dividingBy: 2 * .pi)
            if d > .pi { d -= 2 * .pi } else if d < -.pi { d += 2 * .pi }
            return exp(-(d / width) * (d / width))
        }
        func lobe(_ a: Float, _ t: Float) -> Float {
            f.lobes.reduce(0) { s, l in s + l.y * bump(a, l.x, l.z) * exp(-((t - l.w) / 0.32) * ((t - l.w) / 0.32)) }
        }
        func top(_ a: Float) -> Float { f.tops.reduce(0) { $0 + $1.y * bump(a, $1.x, $1.z) } }
        func section(_ a: Float) -> SIMD2<Float> {
            let c = cos(a), s = sin(a)
            guard f.boxy else { return [c, s] }
            let k = pow(pow(abs(c), level.square) + pow(abs(s), level.square), -1 / level.square)
            return [c * k, s * k]
        }
        func lean(_ p: SIMD3<Float>) -> SIMD3<Float> { p + SIMD3(f.lean.x, 0, f.lean.y) * max(p.y, 0) }
        let maxLobe = max(f.lobes.map(\.y).max() ?? 0, 1e-3)

        var points: [SIMD3<Float>] = [lean([0, -ShrubForm.sink - 0.01, 0])]
        var crease: [Float] = [1]
        for ring in level.rings {
            let t = max(ring.x, 0)
            for j in 0..<n {
                let a = level.azimuths[j]
                let l = lobe(a, ring.x < 0 ? 0.15 : t) * level.lobes
                let r = ring.y * (1 + l) * Float(1 + rng.range(-Double(level.jitter), Double(level.jitter)))
                let d = level.section?[j] ?? section(a)
                let y = (ring.x < 0 ? -ShrubForm.sink : ring.x * h) + top(a) * level.tops * t * t
                points.append(lean([d.x * r * f.halfX, y, d.y * r * f.halfZ]))
                crease.append(level.lobes > 0 && ring.x >= 0 ? min(1, max(0, l / (maxLobe * level.lobes))) : 1)
            }
        }
        var shift = SIMD2<Float>(0, 0)
        if !f.boxy { for tp in f.tops { shift += SIMD2(cos(tp.x), sin(tp.x)) * (tp.y * 1.2 * level.tops) } }
        points.append(lean([shift.x, h, shift.y]))
        crease.append(1)

        let rings = level.rings.count, pole = UInt32(1 + rings * n)
        func v(_ i: Int, _ j: Int) -> UInt32 { UInt32(1 + i * n + j % n) }
        var tris: [SIMD3<UInt32>] = []
        for j in 0..<n { tris.append([v(0, j), v(0, j + 1), 0]) }
        for i in 0..<(rings - 1) {
            for j in 0..<n {
                tris.append([v(i, j), v(i + 1, j), v(i + 1, j + 1)])
                tris.append([v(i, j), v(i + 1, j + 1), v(i, j + 1)])
            }
        }
        for j in 0..<n { tris.append([v(rings - 1, j), pole, v(rings - 1, j + 1)]) }

        var normals = [SIMD3<Float>](repeating: .zero, count: points.count)
        for t in tris {
            let c = simd_cross(points[Int(t.y)] - points[Int(t.x)], points[Int(t.z)] - points[Int(t.x)])
            for i in [t.x, t.y, t.z] { normals[Int(i)] += c }
        }
        let center = lean([0, 0.42 * h, 0]), radii = SIMD3<Float>(f.halfX, 0.62 * h, f.halfZ)
        let base = UInt32(m.positions.count)
        for (i, p) in points.enumerated() {
            let shape = simd_normalize((p - center) / (radii * radii))
            var normal = simd_normalize(simd_normalize(normals[i]) * 0.7 + shape * 0.3)
            // Hedge segments shade as one row: normals barely turn toward the ends, so joins don't show.
            if f.boxy { normal = simd_normalize(SIMD3(normal.x * 0.2, normal.y, normal.z)) }
            m.addVertex(p, normal: normal)
            let ao = Float(0.62 + 0.38 * smoothstep(0.0, Double(0.72 * h), Double(p.y))) * (0.92 + 0.08 * crease[i])
            m.extras[Int(base) + i].x = min(m.extras[Int(base) + i].x, ao)
        }
        for t in tris { m.addTriangle(base + t.x, base + t.y, base + t.z) }
    }

    /// Far hedge section: a tent over the full length × width footprint with its ridge along +X at
    /// full length (6 triangles, open underneath), so a row of sections reads as one continuous hedge.
    static func addHedgeTent(_ m: inout MeshBuffers, _ f: ShrubForm) {
        let h = f.height, w = f.halfZ, l = f.halfX, start = m.positions.count
        let up = SIMD3<Float>(0, 1, 0)
        let ridge = [m.addVertex([-l, h, 0], normal: up), m.addVertex([l, h, 0], normal: up)]
        var base: [[UInt32]] = []
        for s: Float in [-1, 1] {
            let n = simd_normalize(SIMD3<Float>(0, w, s * (h + ShrubForm.sink)))
            base.append([m.addVertex([-l, -ShrubForm.sink, s * w], normal: n), m.addVertex([l, -ShrubForm.sink, s * w], normal: n)])
        }
        // Long sides (−z, +z), then the two end triangles.
        m.addTriangle(base[0][1], base[0][0], ridge[0]); m.addTriangle(base[0][1], ridge[0], ridge[1])
        m.addTriangle(base[1][0], base[1][1], ridge[1]); m.addTriangle(base[1][0], ridge[1], ridge[0])
        let ends: [(Float, UInt32, UInt32, UInt32)] = [(1, base[0][1], ridge[1], base[1][1]), (-1, base[1][0], ridge[0], base[0][0])]
        for (s, a, b, c) in ends {
            let n = SIMD3<Float>(s, 0, 0)
            let ids = [a, b, c].map { m.addVertex(m.positions[Int($0)], normal: simd_normalize(n * 0.6 + up * 0.8)) }
            m.addTriangle(ids[0], ids[1], ids[2])
        }
        m.bakeAO(from: start) { p, _ in Float(0.62 + 0.38 * smoothstep(0.0, Double(0.72 * h), Double(p.y))) }
    }

    /// Skyline detail (level 3, if renderers ask for it): open underneath, like the trees' skyline
    /// spires. Round forms: a three-sided pyramid over the footprint (3 triangles), apex leaning with
    /// the form; hedge segments: a two-sided tent along +X (4 triangles), full length so rows join.
    static func addShrubSkyline(_ m: inout MeshBuffers, _ f: ShrubForm) {
        let h = f.height, start = m.positions.count
        if f.boxy {
            let ridge = [m.addVertex([-0.94 * f.halfX, 0.9 * h, 0], normal: [0, 1, 0]), m.addVertex([0.94 * f.halfX, 0.9 * h, 0], normal: [0, 1, 0])]
            for s: Float in [-1, 1] {
                let n = simd_normalize(SIMD3<Float>(0, f.halfZ, s * 0.9 * h))
                let a = m.addVertex([-f.halfX, 0.05, s * f.halfZ], normal: n), b = m.addVertex([f.halfX, 0.05, s * f.halfZ], normal: n)
                if s > 0 { m.addTriangle(a, b, ridge[1]); m.addTriangle(a, ridge[1], ridge[0]) }
                else { m.addTriangle(b, a, ridge[0]); m.addTriangle(b, ridge[0], ridge[1]) }
            }
        } else {
            var shift = SIMD2<Float>(0, 0)
            for tp in f.tops { shift += SIMD2(cos(tp.x), sin(tp.x)) * (tp.y * 1.2) }
            shift += f.lean * h
            let apex = m.addVertex([shift.x, h, shift.y], normal: [0, 1, 0])
            let ring = (0..<3).map { i -> UInt32 in
                let a = Float(i) / 3 * 2 * .pi
                let p = SIMD3<Float>(cos(a) * f.halfX, 0.05, sin(a) * f.halfZ)
                return m.addVertex(p, normal: simd_normalize(SIMD3(cos(a) / f.halfX, 1 / (h - 0.05), sin(a) / f.halfZ)))
            }
            for i in 0..<3 { m.addTriangle(apex, ring[(i + 1) % 3], ring[i]) }
        }
        m.bakeAO(from: start) { p, _ in Float(0.62 + 0.38 * smoothstep(0.0, Double(0.72 * h), Double(p.y))) }
    }

    /// Flower accents on the upper body: single triangles about 8 cm across, lifted 1.2 cm off faces in
    /// the upper half and spread around the shrub (about 2% of a cushion's surface). They carry a leaf
    /// threshold (extras.y = 0.9), so they show only while the season is in full leaf.
    static func addFlowerAccents(_ m: inout MeshBuffers, count: Int, height: Float, slot: Int, rng: inout StableRandom) {
        var spots: [(center: SIMD3<Float>, face: SIMD3<Float>, normal: SIMD3<Float>, azimuth: Float)] = []
        for t in 0..<m.triangleCount {
            let ids = (0..<3).map { Int(m.indices[t * 3 + $0]) }
            let c = ids.reduce(SIMD3<Float>.zero) { $0 + m.positions[$1] } / 3
            let face = simd_normalize(m.faceCross(t))
            guard c.y > 0.45 * height, face.y > -0.1 else { continue }
            let normal = simd_normalize(ids.reduce(SIMD3<Float>.zero) { $0 + m.normals[$1] })
            spots.append((c, face, normal, atan2(c.z, c.x)))
        }
        guard !spots.isEmpty else { return }
        let paint = m.paint, extra = m.extra
        m.paint = Paint(slot: slot, shade: 1, sway: 0.2)
        m.extra = SIMD4(1, 0.9, 0, 0)
        var used = Set<Int>()
        for k in 0..<count {
            let want = -Float.pi + (Float(k) + Float(rng.range(0.2, 0.8))) / Float(count) * 2 * .pi
            let wantY = Float(rng.range(0.55, 0.95)) * height
            var best = -1, score = Float.infinity
            for (i, s) in spots.enumerated() where !used.contains(i) {
                var d = abs(s.azimuth - want)
                if d > .pi { d = 2 * .pi - d }
                let e = d + abs(s.center.y - wantY) / height
                if e < score { score = e; best = i }
            }
            guard best >= 0 else { break }
            used.insert(best)
            let s = spots[best]
            let u = simd_normalize(simd_cross(s.normal, abs(s.normal.y) < 0.9 ? SIMD3(0, 1, 0) : SIMD3(1, 0, 0)))
            let w = simd_cross(s.normal, u)
            let r = Float(rng.range(0.04, 0.055)), spin = Float(rng.range(0, 2 * .pi))
            let c = s.center + s.face * 0.012
            let ids = (0..<3).map { q -> UInt32 in
                let a = spin + Float(q) * 2 * .pi / 3
                return m.addVertex(c + (u * cos(a) + w * sin(a)) * r, normal: s.normal)
            }
            m.addTriangle(ids[0], ids[1], ids[2])
        }
        m.paint = paint
        m.extra = extra
    }

    // MARK: - Trees

    /// Triangle ceilings per deciduous tree at mid and far detail (beyond `lodDistances[2]` the skyline
    /// level takes over, `skylineTriangleBudget`). At 40 the far crown's smaller lobe has to be an
    /// octahedron, which reads as a diamond at the mid→far switch; 52 lets both lobes be icosahedra
    /// with the same trunk and three winter spikes (`farSmallLobe` follows this value).
    public static let treeTriangleBudget = (mid: 200, far: 52)

    /// A deciduous tree in a crown style (near and mid; far and skyline are the same in every style).
    static func deciduous(_ kind: PropKind, lod: Int, palette: Palette, rng: inout StableRandom, cards: Bool = false) -> MeshBuffers {
        deciduous(kind, lod: lod, palette: palette, rng: &rng, style: cards ? .leafCards : .solid)
    }

    static func deciduous(_ kind: PropKind, lod: Int, palette: Palette, rng: inout StableRandom, style: CrownStyle) -> MeshBuffers {
        let cards = style == .leafCards
        let shape = lobes(kind)
        // Trunk radius (unit height): stout enough that a crown doesn't read as a lollipop on a pole
        // (vegetation-v1: thick oak fork, stout trunks); about a tenth of the crown's width across.
        let trunkR: Float = [.treeSpreading, .treeWeeping, .treeVase].contains(kind) ? 0.03 : [.treeOval, .treePyramidal, .treeUpright].contains(kind) ? 0.024 : kind == .treeOpen ? 0.028 : 0.026
        if lod == 3 { return skylineTree(shape, palette: palette, trunkRadius: trunkR, kind: kind) }
        // Branches: hidden inside the leafy crown, they carry the bare winter silhouette (sky-seasons
        // §5.3: foliage is removed lobe by lobe while branches remain; visual v2: meaningful winter
        // silhouettes). Every detail level draws from one skeleton, so the bare outline holds across
        // LOD switches, and each level keeps it inside its own leafy crown so nothing pokes through.
        // Bare branches sway at 0.3 (R10). Branch draws come from a generator split off a copy of
        // `rng`, so the crown jitter below keeps its sequence.
        var split = rng
        var branchRng = StableRandom(seed: split.next())
        let skeleton = bareSkeleton(shape, style: BranchStyle.of(kind), trunkRadius: trunkR, rng: &branchRng)
        if lod == 2 {
            return shape.shellFar ? farShellTree(shape, skeleton: skeleton, trunkRadius: trunkR, palette: palette, kind: kind)
                : farTree(shape, skeleton: skeleton, trunkRadius: trunkR, palette: palette, kind: kind)
        }
        if style == .puffs { return puffTree(kind, shape: shape, lod: lod, trunkRadius: trunkR, palette: palette, rng: &rng) }

        var m = MeshBuffers()
        // Trunk: thin, bark-colored; AO darker at the ground and where it enters the crown.
        m.paint = Paint(slot: palette.named("bark"))
        let trunkSides = lod == 0 ? 7 : 5
        // Near: rings where trunk AO changes (the ground contact and the fork); mid keeps one segment
        // (its triangle budget), the AO then shading along it from contact to fork.
        let rings: [Float] = lod == 0 ? [0, trunkBaseAOHeight, shape.trunkTop - 0.12, shape.trunkTop + 0.08] : [0, shape.trunkTop + 0.08]
        for (z0, z1) in zip(rings, rings.dropFirst()) {
            addCylinder(&m, radius: trunkR, z0: z0, z1: z1, sides: trunkSides, smooth: true, cap: false)
        }
        m.bakeAO(from: 0) { p, _ in trunkAO(p, shape) }
        m.paint = Paint(slot: palette.named("bark"), sway: 0.3)
        let branchStart = m.positions.count
        addBareBranches(&m, skeleton, lod: lod, trunkSides: trunkSides, within: crownEnvelope(shape, lod: lod))
        m.bakeAO(from: branchStart) { _, _ in 0.8 }
        if lod == 0 { addBranchStubs(&m, shape, trunkRadius: trunkR, rng: &rng) }
        // Crown: one colour per tree, from its form's family (`crownPaint`, picked per instance by the
        // shader); lobes
        // share a softened ellipsoid normal so the crown reads as one sculpted mass. Each lobe's
        // vertices carry a stable leaf threshold in extra.y: the lobe shows while the tree's leaf
        // fraction is at or above it, so autumn thins crowns lobe by lobe. Near lobes are lumpy
        // geodesic spheres (the largest ones finer while the near budget allows); mid detail keeps
        // the top lobe and the first side lobe at 1.25×, its side lobe a 48-triangle cube sphere.
        let leaves = crownPaint(kind, palette: palette)
        if cards {
            addLeafCrown(&m, kind: kind, shape: shape, lod: lod, leaves: leaves, rng: &rng)
            return m
        }
        m.paint = Paint(slot: leaves.slot, flags: leaves.flags, sway: 1)
        let lobes = lod == 0 ? shape.lobes : midLobes(shape)
        let curtains = kind == .treeWeeping ? willowCurtains(lod: lod) : []
        let room = nearTriangleBudget - m.triangleCount - curtains.reduce(0) { $0 + $1.triangles }
        let fine = lod == 0 && !shape.shellFar ? fineLobes(lobes, room: room) : []
        // Species crowns (ten near lobes): cube spheres, the largest lumpy geodesic spheres while the
        // near budget allows; mid: the top lobe a cube sphere, the four side lobes icosahedra.
        let lumpy = lod == 0 && shape.shellFar ? speciesLumpyLobes(lobes, room: room) : []
        let start = m.positions.count
        for (k, (c, r)) in lobes.enumerated() {
            let lobeStart = m.positions.count
            if shape.shellFar {
                if lod == 0 && lumpy.contains(k) {
                    addLumpyLobe(&m, center: c, radius: r, frequency: 2, rng: &rng)
                } else if lod == 0 {
                    addCubeSphere(&m, center: c, radii: SIMD3(r, r * 0.92, r))
                } else {
                    // Mid: radii raised so each low-poly lobe covers its sphere's silhouette (the far
                    // and skyline shells are wrapped onto the spheres).
                    let s = k == 0 ? midLobeScales.cube : midLobeScales.icosahedron
                    if k == 0 { addCubeSphere(&m, center: c, radii: SIMD3(r, r * 0.92, r) * s) }
                    else { addEllipsoid(&m, center: c, radii: SIMD3(r, r * 0.92, r) * s, octahedron: false) }
                }
            } else if lod == 1 && k > 0 {
                addCubeSphere(&m, center: c, radii: SIMD3(r, r * 0.92, r))
            } else if lod == 0 {
                addLumpyLobe(&m, center: c, radius: r, frequency: fine.contains(k) ? 3 : 2, rng: &rng)
            } else {
                addBlob(&m, center: c, radius: r, squash: 0.92, jitter: 0, rng: &rng, subdivide: true)
            }
            let threshold = lobeThreshold(k, of: lobes.count)
            for i in lobeStart..<m.positions.count {
                m.extras[i].y = threshold
                let q = (m.positions[i] - shape.crown) / shape.radii
                m.normals[i] = blendedCrownNormal(m.normals[i], crown: simd_normalize(q / shape.radii))
            }
        }
        addCurtains(&m, curtains)
        // Overlap AO against the modelled lobe radii (mid lobes are drawn 1.25× larger).
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: Array(shape.lobes.prefix(lobes.count)))
        return m
    }

    // MARK: - Puff crowns

    /// Crown style `.puffs` (owner's mock and paintover-v1: clusters of smooth rounded puffs,
    /// soft-shaded and darker inside, on a thick trunk with a modest root flare that splits into
    /// scaffold limbs). Near: a lumpy
    /// geodesic puff (80 triangles) per lobe plus smaller rim puffs (20) filling the rest of
    /// `nearTriangleBudget`, so the outline scallops; mid (≤ 250): the top lobe's puff and small puffs
    /// for the others. Puff normals are each puff's own sphere normals (shared vertices, no facets in
    /// shading); AO (extra.x) darkens faces toward the crown centre, inner puffs and undersides. Each
    /// puff keeps its lobe's leaf threshold. Willows keep their curtains.
    static func puffTree(_ kind: PropKind, shape: TreeShape, lod: Int, trunkRadius trunkR: Float, palette: Palette,
                         rng: inout StableRandom) -> MeshBuffers {
        var m = MeshBuffers()
        // Trunk with a root flare, up to the fork.
        m.paint = Paint(slot: palette.named("bark"))
        let fork = shape.trunkTop - 0.02
        // Root flare (paintover-v1: radius up to 1.15 × the trunk over about 0.12 m, 0.008 of a 15 m tree).
        let heights: [Float] = lod == 0 ? [0, 0.004, 0.008, fork * 0.55, fork] : [0, 0.008, fork]
        let flare: [Float] = lod == 0 ? [1.15, 1.06, 1.0, 0.97, 0.92] : [1.15, 1.0, 0.92]
        addBranch(&m, heights.map { SIMD3<Float>(0, $0, 0) }, radii: flare.map { trunkR * $0 }, sides: lod == 0 ? 8 : 4)
        for i in 0..<m.positions.count { m.extras[i].x = trunkAO(m.positions[i], shape) }
        // Scaffold limbs from the fork into the top lobe and the major side lobes (2–4 visible).
        m.paint = Paint(slot: palette.named("bark"), sway: 0.3)
        let limbs = Array(([0] + Array(1...min(BranchStyle.of(kind).limbs, shape.lobes.count - 1))).prefix(lod == 0 ? 5 : 3))
        let base = SIMD3<Float>(0, fork - 0.01, 0)
        for k in limbs {
            let (c, r) = shape.lobes[k]
            let end = c - SIMD3(0, r * 0.25, 0)
            let side = SIMD3<Float>(Float(rng.range(-0.02, 0.02)), 0, Float(rng.range(-0.02, 0.02)))
            let bend = base + (end - base) * 0.5 + SIMD3(0, k == 0 ? 0 : -0.03, 0) + side
            let w: Float = k == 0 ? 0.8 : 0.7
            addBranch(&m, [base, bend, end], radii: [trunkR * w, trunkR * w * 0.72, trunkR * w * 0.45], sides: lod == 0 ? 6 : 3)
        }
        // Puffs.
        let leaves = crownPaint(kind, palette: palette)
        m.paint = Paint(slot: leaves.slot, flags: leaves.flags, sway: 1)
        let curtains = kind == .treeWeeping ? willowCurtains(lod: lod) : []
        var puffs: [(center: SIMD3<Float>, radius: Float, lobe: Int, fine: Bool)] = []
        // Mid keeps the five main lobes (its 250 budget).
        // Species crowns (ten lobes): the five mid lobes fine, the shoulders plain, to fit the near budget.
        for (k, (c, r)) in shape.lobes.enumerated() where lod == 0 || k < 5 {
            puffs.append((c, r * (lod == 0 ? 0.88 : 1.0), k, lod == 0 ? (k < 5 || !shape.shellFar) : k == 0))
        }
        let big = puffs.reduce(0) { $0 + ($1.fine ? 80 : 20) }
        let room = (lod == 0 ? nearTriangleBudget : 250) - m.triangleCount - big - curtains.reduce(0) { $0 + $1.triangles }
        let small = max(0, min(lod == 0 ? 12 : 3, room / 20))
        for j in 0..<small {
            // A rim puff on a lobe's upper or outer side, half the lobe's size.
            let k = j % shape.lobes.count
            let (c, r) = shape.lobes[k]
            var u = SIMD3<Float>(Float(rng.range(-1, 1)), Float(rng.range(-0.2, 1)), Float(rng.range(-1, 1)))
            let away = c - shape.crown
            if simd_length(away) > 1e-3 { u += simd_normalize(SIMD3(away.x, 0, away.z)) * 0.7 }
            u = simd_length(u) > 1e-4 ? simd_normalize(u) : SIMD3(0, 1, 0)
            puffs.append((c + SIMD3(u.x, u.y * 0.92, u.z) * (r * 0.72), r * Float(rng.range(0.42, 0.55)), k, false))
        }
        let spread = max(shape.radii.x, shape.radii.z)
        for p in puffs {
            let start = m.positions.count
            if p.fine {
                addLumpyLobe(&m, center: p.center, radius: p.radius, frequency: 2, rng: &rng)
            } else {
                addEllipsoid(&m, center: p.center, radii: SIMD3(p.radius, p.radius * 0.92, p.radius), octahedron: false)
            }
            let threshold = lobeThreshold(p.lobe, of: shape.lobes.count)
            let inner = simd_length(SIMD2(p.center.x - shape.crown.x, p.center.z - shape.crown.z)) / spread
            for i in start..<m.positions.count {
                let n = m.normals[i]
                let out = simd_normalize(m.positions[i] - shape.crown)
                let facing = Float(smoothstep(-0.7, 0.6, Double(simd_dot(n, out))))
                // paintover-v1: interior ambient reduction 25 %, the rest of the light/mid/dark range
                // from the sun and fill (no painted stripes).
                var ao = (0.75 + 0.25 * facing) * (0.9 + 0.1 * min(1, inner * 1.6))
                ao = min(ao, 1 - 0.25 * Float(smoothstep(0.2, 0.9, Double(-n.y))))
                m.extras[i].x = ao
                m.extras[i].y = threshold
            }
        }
        addCurtains(&m, curtains)
        return m
    }

    // MARK: - Leaf cards

    /// The leaf-card atlas (R8 coverage, 4 × 4 cells), generated once.
    public static let leafAtlas = LeafAtlas.generate()

    /// Leaf cards per tree at near and mid detail (vegetation-v1 crown construction; overdraw kept
    /// low: near 40–60, mid 12–20). Willows add hanging strand cards.
    public static let leafCardCounts = (near: 56, mid: 20)
    static let willowStrandCards = (near: 10, mid: 4)

    /// Atlas row for a crown form: lindens and willows small-leaf, the rest broadleaf clusters.
    static func leafFamily(_ kind: PropKind) -> LeafAtlas.Family {
        kind == .treeOval || kind == .treeWeeping ? .smallLeaf : kind == .conifer ? .needles : .broadleaf
    }

    /// One leaf card: a quad (two triangles; the card material draws both faces) facing `facing`,
    /// `half` its half size, turned `roll` in its plane; textured with an atlas cell; normals bent out
    /// from the crown centre (`bent`) so the card shades with the crown's volume from either side.
    static func addCard(_ m: inout MeshBuffers, center: SIMD3<Float>, facing: SIMD3<Float>, half: SIMD2<Float>, roll: Float,
                        cell: (min: SIMD2<Float>, max: SIMD2<Float>), bent: SIMD3<Float>) {
        let helper: SIMD3<Float> = abs(facing.y) > 0.9 ? [1, 0, 0] : [0, 1, 0]
        let a0 = simd_normalize(simd_cross(helper, facing)), b0 = simd_cross(facing, a0)
        let a = a0 * cos(roll) + b0 * sin(roll), b = simd_cross(facing, a)
        // Corners counter-clockwise seen from the front; v grows downward in the atlas, so the top
        // edge (+b) takes the cell's min v.
        let corners: [(SIMD3<Float>, SIMD2<Float>)] = [
            (center - a * half.x - b * half.y, SIMD2(cell.min.x, cell.max.y)),
            (center + a * half.x - b * half.y, SIMD2(cell.max.x, cell.max.y)),
            (center + a * half.x + b * half.y, SIMD2(cell.max.x, cell.min.y)),
            (center - a * half.x + b * half.y, SIMD2(cell.min.x, cell.min.y)),
        ]
        let front = corners.map { m.addVertex($0.0, normal: bent, uv: $0.1) }
        m.addTriangle(front[0], front[1], front[2])
        m.addTriangle(front[0], front[2], front[3])
    }

    /// A crown of leaf cards over the archetype's lobes (near: all lobes, `leafCardCounts.near` cards of
    /// 0.8–1.1 × the lobe radius (half size); mid: `leafCardCounts.mid` larger cards): cards per lobe in proportion to
    /// its surface, mostly in the lobe's outer shell and facing out from the crown, so lobes read as
    /// clustered masses with sky gaps between them and branches showing through. Per card: the lobe's
    /// leaf threshold (extra.y), AO darker inside the crown (extra.x), a random value (extra.w), a
    /// little shade jitter. Willows add hanging strand cards around the rim.
    static func addLeafCrown(_ m: inout MeshBuffers, kind: PropKind, shape: TreeShape, lod: Int, leaves: (slot: Int, flags: Paint.Flags),
                             rng: inout StableRandom) {
        let start = m.positions.count
        let total = lod == 0 ? leafCardCounts.near : leafCardCounts.mid
        let area = shape.lobes.reduce(Float(0)) { $0 + $1.1 * $1.1 }
        let family = leafFamily(kind)
        var placed = 0
        for (k, (c, r)) in shape.lobes.enumerated() {
            let n = k == shape.lobes.count - 1 ? total - placed : max(1, Int((Float(total) * r * r / area).rounded()))
            placed += n
            let threshold = lobeThreshold(k, of: shape.lobes.count)
            for _ in 0..<max(0, n) {
                // A direction on the lobe, biased away from the crown centre and up.
                var u = SIMD3<Float>(Float(rng.range(-1, 1)), Float(rng.range(-0.8, 1)), Float(rng.range(-1, 1)))
                let away = c - shape.crown
                if simd_length(away) > 1e-3 { u += simd_normalize(away) * 0.6 }
                u = simd_length(u) > 1e-4 ? simd_normalize(u) : SIMD3(0, 1, 0)
                let depth = Float(rng.range(0.5, 0.95))
                let p = c + SIMD3(u.x, u.y * 0.92, u.z) * (r * depth)
                let out = simd_normalize((p - shape.crown) / (shape.radii * shape.radii))
                // Facing out from the crown with a broad random tilt, so cards near the outline still
                // show some face (edge-on cards at the rim read as a thin, see-through crown).
                let tilt = SIMD3<Float>(Float(rng.range(-0.5, 0.5)), Float(rng.range(-0.3, 0.5)), Float(rng.range(-0.5, 0.5)))
                let facing = simd_normalize(u * 0.5 + out * 0.4 + tilt)
                let size = r * Float(lod == 0 ? rng.range(0.8, 1.1) : rng.range(1.05, 1.4))
                m.paint = Paint(slot: leaves.slot, shade: Float(rng.range(0.94, 1.05)), flags: leaves.flags.union(.leafCard), sway: 1)
                m.extra = SIMD4(0.72 + 0.28 * Float(smoothstep(0.5, 0.95, Double(depth))), threshold, 0, Float(rng.unit()))
                addCard(&m, center: p, facing: facing, half: SIMD2(repeating: size), roll: Float(rng.range(0, 2 * .pi)),
                        cell: LeafAtlas.cell(family, variant: Int(rng.next() % 4)), bent: out)
            }
        }
        if kind == .treeWeeping { addStrandCards(&m, lod: lod, leaves: leaves, rng: &rng) }
        m.extra = SIMD4(1, 0, 0, 0)
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: [])
    }

    /// Willow strand cards (vegetation-v1 addendum: 6–10 tapered hanging groups, 2–4 at medium
    /// distance): vertical cards hanging from the dome's rim, facing out, uneven lengths and gaps;
    /// leaf threshold 0.95 (they thin first in autumn).
    static func addStrandCards(_ m: inout MeshBuffers, lod: Int, leaves: (slot: Int, flags: Paint.Flags), rng: inout StableRandom) {
        let count = lod == 0 ? willowStrandCards.near : willowStrandCards.mid
        let phase = Float(rng.range(0, 2 * .pi))
        for k in 0..<count {
            let a = phase + Float(k) / Float(count) * 2 * .pi + Float(rng.range(-0.2, 0.2))
            let out = SIMD3<Float>(cos(a), 0, sin(a))
            let length = Float(rng.range(0.3, 0.42)), width = Float(rng.range(0.09, 0.12)) * (lod == 0 ? 1 : 1.4)
            let top = Float(rng.range(0.74, 0.79)), reach = Float(rng.range(0.28, 0.34))
            let center = out * (reach + 0.03) + SIMD3(0, top - length / 2, 0)
            let facing = simd_normalize(out + SIMD3(0, 0.1, 0))
            m.paint = Paint(slot: leaves.slot, shade: Float(rng.range(0.94, 1.05)), flags: leaves.flags.union(.leafCard), sway: 1)
            m.extra = SIMD4(0.9, 0.95, 0, Float(rng.unit()))
            addCard(&m, center: center, facing: facing, half: SIMD2(width, length / 2), roll: 0,
                    cell: LeafAtlas.cell(.strands, variant: Int(rng.next() % 4)), bent: simd_normalize(out + SIMD3(0, -0.2, 0)))
        }
    }

    /// One hanging willow curtain: a tapered, slightly flattened cone hanging from the crown's rim.
    struct Curtain {
        /// Direction around the trunk (radians), distance of the curtain's axis from the trunk at the
        /// top, top height, length, tangential half-width and radial half-depth at the top.
        var angle: Float, reach: Float, top: Float, length: Float, width: Float, depth: Float
        /// Sides around, and rings counting the tip (2 = a plain hanging cone).
        var sides: Int, rings: Int
        var triangles: Int { sides * 2 * (rings - 2) + sides }
    }

    /// Willow curtains per detail level (vegetation-v1 addendum: 6–10 tapered hanging groups, 2–4 at
    /// medium distance, uneven lengths and gaps): near 6 five-sided curtains with a bend ring, mid 3
    /// four-sided, far 4 three-sided spikes; their tops sit inside the rim lobes. Fixed per archetype
    /// (instances vary by yaw and stretch), so no season or distance switch rerolls them.
    static func willowCurtains(lod: Int) -> [Curtain] {
        var r = StableRandom(PropKind.treeWeeping.rawValue.hashValueStable, 7, salt: "curtains")
        let count = [6, 3, 4, 0][min(lod, 3)]
        let sides = [5, 4, 3, 3][min(lod, 3)], rings = lod == 0 ? 3 : 2
        let phase = Float(r.range(0, 2 * .pi))
        return (0..<count).map { k in
            let a = phase + Float(k) / Float(count) * 2 * .pi + Float(r.range(-0.25, 0.25))
            let grow: Float = lod == 0 ? 1 : 1.25
            return Curtain(angle: a, reach: Float(r.range(0.27, 0.33)), top: Float(r.range(0.72, 0.76)), length: Float(r.range(0.3, 0.42)),
                           width: Float(r.range(0.14, 0.17)) * grow, depth: 0.05 * grow, sides: sides, rings: rings)
        }
    }

    /// Adds curtains with the crown's paint: thresholds 0.95 (their leaves go first in autumn), normals
    /// out from each curtain's own axis (so they shade as hanging folds).
    static func addCurtains(_ m: inout MeshBuffers, _ curtains: [Curtain]) {
        for c in curtains {
            let start = m.positions.count
            let out = SIMD3<Float>(cos(c.angle), 0, sin(c.angle)), side = SIMD3<Float>(-sin(c.angle), 0, cos(c.angle))
            func axis(_ t: Float) -> SIMD3<Float> {
                // Hangs a little outward as it falls, like drooping branchlets.
                out * (c.reach + 0.06 * t * t) + SIMD3(0, c.top - c.length * t, 0)
            }
            var rings: [[UInt32]] = []
            for j in 0..<(c.rings - 1) {
                let t = Float(j) / Float(c.rings - 1)
                let taper = 1 - 0.55 * t
                rings.append((0..<c.sides).map { s in
                    let u = Float(s) / Float(c.sides) * 2 * .pi
                    let d = side * (cos(u) * c.width * taper) + out * (sin(u) * c.depth * taper)
                    let n = simd_normalize(side * (cos(u) / c.width) + out * (sin(u) / c.depth) + SIMD3(0, -0.15, 0))
                    return m.addVertex(axis(t) + d, normal: n)
                })
            }
            for j in 1..<rings.count {
                let a = rings[j - 1], b = rings[j]
                for s in 0..<c.sides {
                    let s1 = (s + 1) % c.sides
                    m.addTriangle(a[s], b[s1], a[s1])
                    m.addTriangle(a[s], b[s], b[s1])
                }
            }
            // Tapered tip: one vertex per side, each keeping its side's normal.
            let last = rings[rings.count - 1], tip = axis(1)
            for s in 0..<c.sides {
                let s1 = (s + 1) % c.sides
                let n = simd_normalize(m.normals[Int(last[s])] + m.normals[Int(last[s1])] + SIMD3(0, -0.6, 0))
                let t = m.addVertex(tip, normal: n)
                m.addTriangle(last[s], t, last[s1])
            }
            for i in start..<m.positions.count { m.extras[i].y = 0.95 }
        }
    }

    /// A crown vertex normal: the lobe's own normal softened toward the crown ellipsoid's, so lobes
    /// shade as one mass; where the two disagree (a lobe's inner side) the lobe's own normal wins, so
    /// the normal never turns away from its face.
    static func blendedCrownNormal(_ lobe: SIMD3<Float>, crown: SIMD3<Float>) -> SIMD3<Float> {
        simd_normalize(lobe + crown * max(0, simd_dot(lobe, crown)))
    }

    /// The crown form key of a deciduous archetype (profile `crownWeights`, `SeasonalPalette.crownColors`).
    /// Species silhouettes keep the colour family of the form their species were drawn with before
    /// (vegetation.json genusForms: Acer broad; Tilia, Fraxinus, aspen oval; Ulmus, Populus, Gleditsia
    /// spreading), so the autumn mix per family is unchanged; silver maple shares the honeylocust's open
    /// crown and with it the spreading family.
    static func crownForm(_ kind: PropKind) -> String {
        switch kind {
        case .treeOval, .treePyramidal, .treeUpright: "oval"
        case .treeSpreading, .treeVase, .treeOpen: "spreading"
        case .treeWeeping: "weeping"
        default: "broad"
        }
    }

    /// The deciduous kind a crown form is drawn with without a species (profile `crownWeights` keys).
    public static func formKind(_ form: String) -> PropKind {
        form == "oval" ? .treeOval : form == "spreading" ? .treeSpreading : form == "weeping" ? .treeWeeping : .treeBroad
    }

    /// Crown slot and colour-variant flag for a deciduous archetype: its form's colour family from the
    /// seasonal palette (first slot + 1, 2 or 4 consecutive slots picked per instance by the shader),
    /// else deciduous1…4. A family that leaves the deciduous slots falls back too.
    public static func crownPaint(_ kind: PropKind, palette: Palette) -> (slot: Int, flags: Paint.Flags) {
        let fallback = (palette.named("deciduous1"), Paint.Flags.variant4)
        guard let family = palette.crownColors[crownForm(kind)], let first = SeasonalPalette.order.firstIndex(of: family.first),
              [1, 2, 4].contains(family.count), first + family.count <= SeasonalPalette.order.count,
              SeasonalPalette.order[first..<(first + family.count)].allSatisfy({ $0.hasPrefix("deciduous") })
        else { return fallback }
        return (palette.named(family.first), family.count == 4 ? .variant4 : family.count == 2 ? .variant2 : [])
    }

    /// Triangle ceiling per deciduous tree at near detail (within `lodDistances[0]`, a few dozen trees).
    public static let nearTriangleBudget = 900

    /// Near lobes drawn as finer geodesic spheres (frequency 3, 180 triangles, instead of 80): the
    /// largest first, while the crown still fits in `room` triangles.
    static func fineLobes(_ lobes: [(SIMD3<Float>, Float)], room: Int) -> Set<Int> {
        var left = room - lobes.count * geodesic(2).faces.count
        let extra = geodesic(3).faces.count - geodesic(2).faces.count
        var fine: Set<Int> = []
        for k in lobes.indices.sorted(by: { lobes[$0].1 > lobes[$1].1 }) where left >= extra {
            fine.insert(k)
            left -= extra
        }
        return fine
    }

    /// Radius factors for species mid lobes (cube sphere, icosahedron): the square root of how much
    /// less of a sphere's silhouette each covers.
    static let midLobeScales: (cube: Float, icosahedron: Float) = (
        (1 / silhouetteShare(cubeSphere())).squareRoot(), (1 / silhouetteShare(icosahedron())).squareRoot())

    /// Species crowns' near lobes drawn as lumpy geodesic spheres (80 triangles) instead of cube spheres
    /// (48): the largest first, while the crown still fits in `room` triangles.
    static func speciesLumpyLobes(_ lobes: [(SIMD3<Float>, Float)], room: Int) -> Set<Int> {
        let cube = cubeSphere().1.count
        var left = room - lobes.count * cube
        let extra = geodesic2.faces.count - cube
        var lumpy: Set<Int> = []
        for k in lobes.indices.sorted(by: { lobes[$0].1 > lobes[$1].1 }) where left >= extra {
            lumpy.insert(k)
            left -= extra
        }
        return lumpy
    }

    /// A near crown lobe: a geodesic sphere (squashed to 0.92 in height) with two or three broad,
    /// seeded lumps and dents (+5–8% / −6% of the radius), so lobes merge into a clustered mass instead
    /// of reading as balls. Normals stay the sphere's (soft), blended with the crown's by the caller.
    static func addLumpyLobe(_ m: inout MeshBuffers, center: SIMD3<Float>, radius: Float, frequency: Int, rng: inout StableRandom) {
        let (units, faces) = frequency == 3 ? geodesic3 : geodesic2
        var lumps: [(SIMD3<Float>, Float)] = []
        for i in 0..<3 {
            let z = Float(rng.range(-0.6, 1)), a = Float(rng.range(0, 2 * .pi)), rho = (1 - z * z).squareRoot()
            lumps.append((SIMD3(rho * cos(a), z, rho * sin(a)), i == 2 ? -0.06 : Float(rng.range(0.05, 0.08))))
        }
        let base = UInt32(m.positions.count)
        for v in units {
            var k: Float = 1
            for (d, amount) in lumps { k += amount * exp(-(1 - simd_dot(v, d)) / 0.18) }
            m.addVertex(center + SIMD3(v.x, v.y * 0.92, v.z) * (radius * k), normal: simd_normalize(SIMD3(v.x, v.y / 0.92, v.z)))
        }
        for f in faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
    }

    /// Unit geodesic spheres of frequency 2 (80 triangles) and 3 (180), counter-clockwise outside.
    static let geodesic2 = geodesic(2), geodesic3 = geodesic(3)

    /// The icosahedron with each face split into `n` × `n` triangles, corners pushed onto the unit sphere.
    static func geodesic(_ n: Int) -> Polyhedron {
        let (ico, icoFaces) = icosahedron()
        var units: [SIMD3<Float>] = []
        var index: [SIMD3<Int32>: UInt32] = [:]
        func corner(_ p: SIMD3<Float>) -> UInt32 {
            let u = simd_normalize(p), key = SIMD3<Int32>((u * 4096).rounded(.toNearestOrEven))
            if let i = index[key] { return i }
            units.append(u)
            index[key] = UInt32(units.count - 1)
            return UInt32(units.count - 1)
        }
        var faces: [SIMD3<UInt32>] = []
        for f in icoFaces {
            let a = ico[Int(f.x)], b = ico[Int(f.y)], c = ico[Int(f.z)]
            func at(_ i: Int, _ j: Int) -> UInt32 { corner(a + (b - a) * (Float(i) / Float(n)) + (c - a) * (Float(j) / Float(n))) }
            for i in 0..<n { for j in 0..<(n - i) {
                faces.append(SIMD3(at(i, j), at(i + 1, j), at(i, j + 1)))
                if i + j < n - 1 { faces.append(SIMD3(at(i + 1, j), at(i + 1, j + 1), at(i, j + 1))) }
            } }
        }
        return (units, oriented(faces, units))
    }

    /// Branch stubs where the trunk enters the crown (near detail): two or three short, pointed bark
    /// stubs leaving the trunk below the fork, angled up and out, ending under the crown, so the trunk
    /// doesn't read as a stick pushed into a ball. Bark, sway 0.3, AO 0.75 like the branches.
    static func addBranchStubs(_ m: inout MeshBuffers, _ shape: TreeShape, trunkRadius: Float, rng: inout StableRandom) {
        let paint = m.paint
        m.paint = Paint(slot: paint.slot, sway: 0.3)
        let count = rng.chance(0.5) ? 2 : 3, phase = Float(rng.range(0, 2 * .pi))
        for i in 0..<count {
            let a = phase + Float(i) * 2 * .pi / Float(count) + Float(rng.range(-0.4, 0.4))
            let y = shape.trunkTop - Float(rng.range(0.08, 0.13))
            let out = SIMD3<Float>(cos(a), 0, sin(a))
            let base = SIMD3<Float>(0, y, 0) + out * (trunkRadius * 0.5)
            let tip = base + simd_normalize(out + SIMD3(0, Float(rng.range(0.4, 0.65)), 0)) * Float(rng.range(0.08, 0.11))
            addBranch(&m, [base, tip], radii: [trunkRadius * 0.45, 0], sides: 3)
        }
        m.paint = paint
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
                            shell: CrownShell? = nil, kind: PropKind = .treeBroad) -> MeshBuffers {
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
        let leaves = crownPaint(kind, palette: palette)
        m.paint = Paint(slot: leaves.slot, shade: skylineShade, flags: leaves.flags, sway: 1)
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

    /// Trunk AO: ground contact `trunkBaseAO` at the base rising to 1 by `trunkBaseAOHeight`
    /// (vegetation-v1: a restrained 10–20% ambient reduction within about 0.15–0.4 m of the trunk base, no
    /// black ring; the renderer adds its own darkening near the ground), and darker where the trunk
    /// enters the crown (×0.55 at the fork).
    static func trunkAO(_ p: SIMD3<Float>, _ shape: TreeShape) -> Float {
        let base = Double(trunkBaseAO) + (1 - Double(trunkBaseAO)) * smoothstep(0, Double(trunkBaseAOHeight), Double(p.y))
        return Float(base * (1 - 0.45 * smoothstep(Double(shape.trunkTop) - 0.12, Double(shape.trunkTop), Double(p.y))))
    }

    /// Trunk AO at the ground: 0.65, the renderer's ambient floor (owner 2026-10-07: the 16 % of
    /// vegetation-v1 did not read at phone size, "floating trunks").
    static let trunkBaseAO: Float = 0.65
    /// Height (share of the unit-height tree) over which trunk AO rises to 1: 0.06 ≈ 0.9 m on a 15 m
    /// tree (Evanston median), 0.25–0.35 m on young 4–6 m trees.
    static let trunkBaseAOHeight: Float = 0.06

    /// The mid crown's lobes: the top lobe and the first side lobe, 1.25× larger (species crowns: the
    /// top lobe and the four major side lobes, 1.1×, so the mid level keeps the silhouette).
    static func midLobes(_ shape: TreeShape) -> [(SIMD3<Float>, Float)] {
        shape.lobes.prefix(shape.midCount).map { ($0.0, $0.1 * shape.midScale) }
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
                        large: Polyhedron? = nil, small: Polyhedron? = nil, budget: Int = treeTriangleBudget.far,
                        kind: PropKind = .treeBroad) -> MeshBuffers {
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
        let leaves = crownPaint(kind, palette: palette)
        m.paint = Paint(slot: leaves.slot, flags: leaves.flags, sway: 1)
        let start = m.positions.count
        for (k, lobe) in lobes.enumerated() {
            let lobeStart = m.positions.count, base = UInt32(lobeStart)
            for v in lobe.polyhedron.units {
                let p = lobe.center + SIMD3(v.x, v.y * 0.92, v.z) * lobe.radius
                let crownN = simd_normalize((p - shape.crown) / (shape.radii * shape.radii))
                m.addVertex(p, normal: blendedCrownNormal(simd_normalize(SIMD3(v.x, v.y / 0.92, v.z)), crown: crownN))
            }
            for f in lobe.polyhedron.faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
            for i in lobeStart..<m.positions.count { m.extras[i].y = lobeThreshold(k, of: lobes.count) }
        }
        if kind == .treeWeeping { addCurtains(&m, willowCurtains(lod: 2)) }
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: Array(shape.lobes.prefix(lobes.count)))
        return m
    }

    /// Far detail of a species crown (foliage-seasons-v1 far tier: one to three opaque masses): one
    /// icosahedron (20 triangles) shrink-wrapped onto the mid crown's five lobes, so its outline and
    /// lopsided mass carry over from mid detail (instance yaw varies it); leaf threshold 0.5. Trunk and
    /// leader as one 3-sided spike and spikes toward the limbs' forks as the budget allows, inside
    /// `farShellEnvelope`.
    static func farShellTree(_ shape: TreeShape, skeleton: [Bough], trunkRadius: Float, palette: Palette, kind: PropKind,
                             budget: Int = treeTriangleBudget.far) -> MeshBuffers {
        var m = MeshBuffers()
        let shell = farCrownShell(shape)
        let crown = farShellEnvelope(shape)
        m.paint = Paint(slot: palette.named("bark"))
        let top = skeleton[0].points[skeleton[0].points.count - 1]
        addBranch(&m, [.zero, crown.clamp(.zero, toward: top)], radii: [trunkRadius * 1.3, 0], sides: 3)
        for i in 0..<m.positions.count { m.extras[i].x = trunkAO(m.positions[i], shape) }
        m.paint = Paint(slot: palette.named("bark"), sway: 0.3)
        addBareBranches(&m, skeleton, lod: 2, trunkSides: 3, within: crown, farSpikes: min(5, max(0, (budget - shell.faces.count - 3) / 3)))
        let leaves = crownPaint(kind, palette: palette)
        m.paint = Paint(slot: leaves.slot, flags: leaves.flags, sway: 1)
        let start = m.positions.count, base = UInt32(start)
        for (p, n) in zip(shell.corners, shell.normals) { m.addVertex(p, normal: n) }
        for f in shell.faces { m.addTriangle(base + f.x, base + f.y, base + f.z) }
        for i in start..<m.positions.count { m.extras[i].y = 0.5 }
        bakeCrownAO(&m, from: start, crown: shape.crown, radii: shape.radii, lobes: [])
        return m
    }

    /// The far species crown: an icosahedron shrink-wrapped onto the mid lobes (see `shrinkWrap`).
    static func farCrownShell(_ shape: TreeShape) -> CrownShell {
        shrinkWrap(shape, icosahedron(), smooth: 0.3)
    }

    /// Where far branches of a species crown may go: well inside the mid lobes the far shell wraps.
    static func farShellEnvelope(_ shape: TreeShape) -> CrownEnvelope {
        CrownEnvelope(blobs: midLobes(shape).map { ($0.0, SIMD3(1, 0.92, 1) * ($0.1 * 0.4)) }, margin: 0.97, column: shape.underColumn)
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

    /// Crown AO: lower and interior parts darker, lobe overlaps darker (R1), and each lobe's underside
    /// (faces turned down) at most `crownUndersideAO`, so lobes read as sitting over shade
    /// (vegetation-v1: gentle vertex AO in intersections and under the crown, no dark outlines).
    static func bakeCrownAO(_ m: inout MeshBuffers, from start: Int, crown: SIMD3<Float>, radii: SIMD3<Float>, lobes: [(SIMD3<Float>, Float)]) {
        for i in start..<m.positions.count {
            let p = m.positions[i]
            let rel = (p.y - crown.y) / radii.y
            var ao = 0.66 + 0.34 * Float(smoothstep(-1.0, 0.7, Double(rel)))
            ao = min(ao, 1 - (1 - crownUndersideAO) * Float(smoothstep(0.2, 0.8, Double(-m.normals[i].y))))
            for (c, r) in lobes where simd_distance(p, c) < r * 0.98 { ao *= 0.86 }
            m.extras[i].x = min(m.extras[i].x, ao)
        }
    }

    /// AO on crown lobes' lower faces (normals turned down by more than about 50°).
    static let crownUndersideAO: Float = 0.75

    // MARK: - Bare branches

    /// A crown archetype in unit-height tree space: fork height, crown ellipsoid, lobes (centre, radius;
    /// lobe 0 the top lobe), and how many of the first lobes the mid crown draws, at what scale. Two-lobe
    /// mids (the original archetypes) keep the two-lobe far crown; species crowns (`midCount` 5) draw a
    /// shrink-wrapped far mass.
    public struct TreeShape: Sendable {
        public var trunkTop: Float
        public var crown: SIMD3<Float>
        public var radii: SIMD3<Float>
        public var lobes: [(SIMD3<Float>, Float)]
        public var midCount: Int
        public var midScale: Float
        /// High crowns (vase, open): radius of the column under the crown, up to `crown.y − 0.3 × radii.y`,
        /// where limbs may run from the fork up to the lobes (0 = none).
        public var column: Float

        init(_ trunkTop: Float, _ crown: SIMD3<Float>, _ radii: SIMD3<Float>, _ lobes: [(SIMD3<Float>, Float)], mid: Int = 2, midScale: Float = 1.25,
             column: Float = 0) {
            (self.trunkTop, self.crown, self.radii, self.lobes, self.midCount, self.midScale, self.column) = (trunkTop, crown, radii, lobes, mid, midScale, column)
        }

        /// The limb column for envelopes, if any.
        var underColumn: (top: Float, radius: Float)? { column > 0 ? (crown.y - 0.3 * radii.y, column) : nil }

        /// Whether the far crown is one shrink-wrapped mass (species crowns) instead of the mid crown's
        /// two lobes as low-poly spheres.
        var shellFar: Bool { midCount > 2 }
    }

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
        /// Side lobes that get a limb (lobes 1…limbs; the smaller shoulders after them get none).
        var limbs = 3

        static func of(_ kind: PropKind) -> BranchStyle {
            switch kind {
            case .treeOval:
                // Upright: limbs leave a tall leader at staggered heights and climb steeply.
                BranchStyle(leaderReach: 0.6, topBranches: 3, topFan: 0.42, topAt: 0.5,
                            stagger: 0.35, outward: 0.3, limbReach: 0.55, limb: 0.6, bow: -0.04,
                            fork: 0.42, tilt: 0.5, rise: 0.4, inner: 0.45, branchReach: 0.88,
                            innerTwigs: 3, endTwigs: 4, spray: 0.55, twigRise: 0.35)
            case .treeWeeping:
                // Willow: a broad, uneven scaffold; limbs rise from a low fork and arch out under the
                // dome; few twigs (the curtains hide the interior).
                BranchStyle(leaderReach: 0.5, topBranches: 2, topFan: 0.7, topAt: 0.5,
                            stagger: 0, outward: 0.45, limbReach: 0.62, limb: 0.66, bow: 0.05,
                            fork: 0.5, tilt: 0.6, rise: 0.1, inner: 0.7, branchReach: 0.88,
                            innerTwigs: 1, endTwigs: 1, spray: 0.6, twigRise: 0.1, limbs: 4)
            case .treeSpreading:
                // Vase: limbs from one low fork rise, then flare wide; a short leader.
                BranchStyle(leaderReach: 0.45, topBranches: 2, topFan: 0.75, topAt: 0.5,
                            stagger: 0, outward: 0.6, limbReach: 0.68, limb: 0.66, bow: -0.05,
                            fork: 0.5, tilt: 0.6, rise: 0.15, inner: 0.7, branchReach: 0.93,
                            innerTwigs: 2, endTwigs: 3, spray: 0.6, twigRise: 0.2, limbs: 4)
            case .treeVase:
                // Elm vase (foliage-seasons-v1: arching upward/outward main limbs): no leader to speak
                // of; limbs leave one low fork steeply, rising first, then arching out under the umbrella.
                BranchStyle(leaderReach: 0.35, topBranches: 2, topFan: 0.55, topAt: 0.5,
                            stagger: 0, outward: 0.6, limbReach: 0.8, limb: 0.62, bow: -0.1,
                            fork: 0.55, tilt: 0.6, rise: 0.2, inner: 0.55, branchReach: 0.95,
                            innerTwigs: 2, endTwigs: 3, spray: 0.6, twigRise: 0.25, limbs: 4)
            case .treeOpen:
                // Honeylocust: an open scaffold reaching wide and low-angled, fine twigs at the ends.
                BranchStyle(leaderReach: 0.65, topBranches: 2, topFan: 0.55, topAt: 0.5,
                            stagger: 0.05, outward: 0.6, limbReach: 0.8, limb: 0.6, bow: 0.04,
                            fork: 0.55, tilt: 0.6, rise: 0.15, inner: 0.65, branchReach: 0.95,
                            innerTwigs: 2, endTwigs: 3, spray: 0.65, twigRise: 0.2, limbs: 4)
            case .treePyramidal, .treeUpright:
                // Linden and ash: a leader up the crown, paired limbs leaving it at staggered heights.
                BranchStyle(leaderReach: 0.7, topBranches: 3, topFan: 0.45, topAt: 0.5,
                            stagger: 0.3, outward: 0.3, limbReach: 0.58, limb: 0.6, bow: -0.02,
                            fork: 0.42, tilt: 0.5, rise: 0.35, inner: 0.5, branchReach: 0.9,
                            innerTwigs: 2, endTwigs: 2, spray: 0.55, twigRise: 0.3, limbs: 4)
            case .treeRounded:
                // Norway maple: limbs out from the fork, curving up around a leader into a dense dome.
                BranchStyle(leaderReach: 0.55, topBranches: 3, topFan: 0.6, topAt: 0.5,
                            stagger: 0.1, outward: 0.35, limbReach: 0.55, limb: 0.62, bow: 0.06,
                            fork: 0.45, tilt: 0.6, rise: 0.25, inner: 0.6, branchReach: 0.88,
                            innerTwigs: 2, endTwigs: 2, spray: 0.6, twigRise: 0.25, limbs: 4)
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
        for (k, (c, r)) in shape.lobes.enumerated() where k > 0 && k <= style.limbs {
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
        /// A column under a high crown (`TreeShape.underColumn`).
        var column: (top: Float, radius: Float)? = nil

        func contains(_ p: SIMD3<Float>) -> Bool {
            if let c = column, p.y <= c.top, simd_length(SIMD2(p.x, p.z)) <= c.radius { return true }
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
        case 0: return CrownEnvelope(blobs: shape.lobes.map { lobe($0.0, $0.1) }, column: shape.underColumn)
        // Species mid lobes past the top one are icosahedra (faces at 0.79 of the corners' reach).
        case 1: return CrownEnvelope(blobs: midLobes(shape).map { lobe($0.0, $0.1) }, margin: shape.shellFar ? 0.74 : 0.85, column: shape.underColumn)
        default: return shape.shellFar ? farShellEnvelope(shape) : farEnvelope(farLobes(shape))
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

    static func conifer(lod: Int, palette: Palette, rng: inout StableRandom, cards: Bool = false, smooth: Bool = false) -> MeshBuffers {
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
        m.bakeAO(from: 0) { p, _ in p.y > 0.15 ? 0.6 : trunkBaseAO }
        m.paint = Paint(slot: palette.named("conifer1"), flags: .variant2, sway: 0.5)
        let start = m.positions.count
        if smooth && lod < 2 {
            // Puff style: more, smoother tiers (12 or 8 sides, smooth normals), staggered and a little
            // irregular in radius, so the near spire has no big flat polygons.
            let count = lod == 0 ? 9 : 5
            for k in 0..<count {
                let t = Float(k) / Float(count - 1)
                let z0 = 0.12 + 0.66 * t + Float(rng.range(-0.01, 0.01))
                let r = (0.27 - 0.21 * t) * Float(rng.range(0.9, 1.06))
                addCone(&m, radius: r, z0: z0, z1: k == count - 1 ? 1.0 : z0 + 0.24 - 0.08 * t, sides: lod == 0 ? 12 : 8)
            }
        } else if lod == 0 {
            // Near: staggered tiers with ragged, drooping rims (branch tips) and apexes a little off the
            // axis, so the spire reads as layered boughs rather than stacked cones.
            // Spruce (vegetation-v1): irregular taper of 7 drooping, staggered tiers with broken lengths.
            for k in 0..<7 {
                let t = Float(k) / 6
                let z0 = 0.12 + 0.62 * t + Float(rng.range(-0.015, 0.015))
                let r = (0.27 - 0.2 * t) * Float(rng.range(0.88, 1.08))
                let lean = SIMD2<Float>(Float(rng.range(-0.012, 0.012)), Float(rng.range(-0.012, 0.012)))
                addRaggedCone(&m, radius: r, z0: z0, z1: k == 6 ? 1.0 : z0 + 0.26 - 0.06 * t, tips: 5, apex: lean, rng: &rng)
            }
        } else {
            let tiers: [(Float, Float, Float)] = lod == 2 ? [(0.14, 1.0, 0.24)]
                : [(0.14, 0.58, 0.26), (0.38, 0.8, 0.2), (0.6, 1.0, 0.13)]
            for (z0, z1, r) in tiers { addCone(&m, radius: r, z0: z0, z1: z1, sides: lod == 1 ? 7 : 5) }
        }
        if cards && lod < 2 { addNeedleCards(&m, lod: lod, palette: palette, rng: &rng) }
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

    /// Needle-spray cards on a spruce (vegetation-v1: irregular drooping tiers): near 32, mid 10, in
    /// rings down the spire, each card hanging out and a little down from the axis at the tiers'
    /// edge, so the outline breaks into needle sprays over the solid tiers. Evergreen: leaf
    /// threshold 0 (never dropped), sway 0.5 like the tiers.
    static func addNeedleCards(_ m: inout MeshBuffers, lod: Int, palette: Palette, rng: inout StableRandom) {
        let count = lod == 0 ? 32 : 10
        let slot = palette.named("conifer1")
        for k in 0..<count {
            let t = (Float(k) + 0.5) / Float(count)
            let y = 0.16 + 0.74 * t + Float(rng.range(-0.02, 0.02))
            let radius = 0.26 * (1 - 0.82 * t) * Float(rng.range(0.85, 1.05))
            let a = Float(k) * 2.4 + Float(rng.range(-0.3, 0.3))
            let out = SIMD3<Float>(cos(a), 0, sin(a))
            let center = out * (radius * 0.95) + SIMD3(0, y, 0)
            let facing = simd_normalize(out + SIMD3(0, 0.35, 0) + SIMD3(Float(rng.range(-0.3, 0.3)), 0, Float(rng.range(-0.3, 0.3))))
            let half = max(0.04, radius * Float(lod == 0 ? rng.range(0.7, 0.9) : rng.range(0.9, 1.1)))
            m.paint = Paint(slot: slot, shade: Float(rng.range(0.94, 1.05)), flags: [.variant2, .leafCard], sway: 0.5)
            m.extra = SIMD4(Float(0.7 + 0.3 * smoothstep(0.1, 0.9, Double(y))), 0, 0, Float(rng.unit()))
            addCard(&m, center: center, facing: facing, half: SIMD2(half, half * 0.8), roll: .pi + Float(rng.range(-0.4, 0.4)),
                    cell: LeafAtlas.cell(.needles, variant: Int(rng.next() % 4)), bent: simd_normalize(out + SIMD3(0, 0.3, 0)))
        }
        m.extra = SIMD4(1, 0, 0, 0)
    }

    /// A conifer tier: a cone whose rim alternates `tips` outer branch tips (full radius ±8%, drooping
    /// 0.02 below `z0`) with notches (78% radius, 0.03 above it), the apex offset by `apex`; a flat
    /// underside at 0.8 shade like `addCone`.
    static func addRaggedCone(_ m: inout MeshBuffers, radius r: Float, z0: Float, z1: Float, tips: Int, apex: SIMD2<Float>,
                              rng: inout StableRandom) {
        let top = SIMD3<Float>(apex.x, z1, apex.y)
        let phase = Float(rng.range(0, 2 * .pi))
        var rim: [SIMD3<Float>] = []
        for i in 0..<(tips * 2) {
            let a = phase + Float(i) / Float(tips * 2) * 2 * .pi
            let tip = i % 2 == 0
            let rr = tip ? r * Float(rng.range(0.92, 1.08)) : r * 0.78
            rim.append(SIMD3(cos(a) * rr, tip ? z0 - 0.02 : z0 + 0.03, sin(a) * rr))
        }
        let slope = r / (z1 - z0)
        let apexID = m.addVertex(top, normal: SIMD3(0, 1, 0))
        let ids = rim.map { p -> UInt32 in
            let out = simd_normalize(SIMD3(p.x, 0, p.z))
            return m.addVertex(p, normal: simd_normalize(SIMD3(out.x, slope, out.z)))
        }
        for i in 0..<ids.count { m.addTriangle(apexID, ids[(i + 1) % ids.count], ids[i]) }
        let shade = m.paint
        m.paint = Paint(slot: shade.slot, shade: shade.shade * 0.8, flags: shade.flags, sway: shade.sway)
        // Underside: a fan from the axis (the ragged rim is star-shaped around it, not convex).
        let hub = m.addVertex(SIMD3(0, z0, 0), normal: -sceneUp)
        let down = rim.map { m.addVertex($0, normal: -sceneUp) }
        for i in 0..<down.count { m.addTriangle(hub, down[i], down[(i + 1) % down.count]) }
        m.paint = shade
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
