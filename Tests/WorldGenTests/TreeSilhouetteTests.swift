import CoreGraphics
import Foundation
import ImageIO
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Deciduous tree silhouettes (Props.swift): the bare skeleton every detail level draws, the far
/// crown and per-tree proportions. Meshes are unit height; trunk, branches and crown are told apart by
/// sway (0, 0.3, 1).
@Suite("Tree silhouettes")
struct TreeSilhouetteTests {
    static let kinds: [PropKind] = [.treeBroad, .treeOval, .treeSpreading] + speciesKinds
    /// The foliage-seasons-v1 species silhouettes.
    static let speciesKinds: [PropKind] = [.treeRounded, .treePyramidal, .treeVase, .treeOpen, .treeUpright]
    /// Branch triangles per tree at near, mid and far detail (thousands of trees are drawn; at far
    /// detail the trunk carries the leader).
    static let branchBudget = [260, 90, 15]
    /// Whole-tree triangles at mid, far and skyline detail.
    static let totalBudget = [Int.max, PropLibrary.treeTriangleBudget.mid, PropLibrary.treeTriangleBudget.far, PropLibrary.skylineTriangleBudget]

    enum Part { case trunk, branch, crown }

    struct Piece {
        var triangles: [Int]
        var lo: SIMD3<Float>, hi: SIMD3<Float>
    }

    static func palette() throws -> Palette { Palette(base: try StyleLibrary.baseColors()) }

    static func mesh(_ kind: PropKind, lod: Int) throws -> MeshBuffers {
        PropLibrary.mesh(kind, variant: 0, lod: lod, palette: try palette(), leafCards: true)
    }

    /// The solid lobe crown a level's leaf cards stand in for (same skeleton and trunk): the reference
    /// outline for branch containment and the far crown.
    static func solid(_ kind: PropKind, lod: Int) throws -> MeshBuffers {
        var rng = StableRandom(kind.rawValue.hashValueStable, 0, salt: "prop")
        return PropLibrary.deciduous(kind, lod: lod, palette: try palette(), rng: &rng, cards: false)
    }

    /// Whether vertex `v` belongs to a leaf card.
    static func isCard(_ m: MeshBuffers, vertex v: Int) -> Bool { Int(m.paints[v].z + 0.5) & Int(Paint.Flags.leafCard.rawValue) != 0 }

    static func part(_ m: MeshBuffers, vertex v: Int) -> Part {
        let sway = m.paints[v].w
        return sway > 0.9 ? .crown : (sway > 0.2 ? .branch : .trunk)
    }

    static func triangles(_ m: MeshBuffers, _ p: Part) -> [Int] {
        (0..<m.triangleCount).filter { part(m, vertex: Int(m.indices[$0 * 3])) == p }
    }

    static func corners(_ m: MeshBuffers, _ t: Int) -> (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) {
        (m.positions[Int(m.indices[t * 3])], m.positions[Int(m.indices[t * 3 + 1])], m.positions[Int(m.indices[t * 3 + 2])])
    }

    /// Triangles grouped into connected pieces by shared vertices (each crown lobe, or the far crown, is
    /// one closed piece).
    static func pieces(_ m: MeshBuffers, _ tris: [Int]) -> [Piece] {
        var root = Array(0..<m.vertexCount)
        func find(_ x: Int) -> Int {
            var x = x
            while root[x] != x { root[x] = root[root[x]]; x = root[x] }
            return x
        }
        for t in tris {
            let a = find(Int(m.indices[t * 3]))
            for k in 1..<3 { root[find(Int(m.indices[t * 3 + k]))] = a }
        }
        return Dictionary(grouping: tris) { find(Int(m.indices[$0 * 3])) }.values.sorted { $0[0] < $1[0] }.map { tris in
            var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
            for t in tris {
                let (a, b, c) = corners(m, t)
                lo = simd_min(lo, simd_min(a, simd_min(b, c)))
                hi = simd_max(hi, simd_max(a, simd_max(b, c)))
            }
            return Piece(triangles: tris, lo: lo, hi: hi)
        }
    }

    /// Ray–triangle crossings (Möller–Trumbore) from `o` along `dir` with a piece.
    static func crossings(_ m: MeshBuffers, _ piece: Piece, from o: SIMD3<Float>, along dir: SIMD3<Float>) -> Int {
        let d = simd_normalize(dir)
        var n = 0
        for t in piece.triangles {
            let (a, b, c) = corners(m, t)
            let e1 = b - a, e2 = c - a
            let p = simd_cross(d, e2), det = simd_dot(e1, p)
            guard abs(det) > 1e-12 else { continue }
            let s = o - a, u = simd_dot(s, p) / det
            guard u >= 0, u <= 1 else { continue }
            let q = simd_cross(s, e1), v = simd_dot(d, q) / det
            if v >= 0, u + v <= 1, simd_dot(e2, q) / det > 0 { n += 1 }
        }
        return n
    }

    static func inside(_ m: MeshBuffers, _ piece: Piece, _ p: SIMD3<Float>) -> Bool {
        guard all(p .>= piece.lo), all(p .<= piece.hi) else { return false }
        return crossings(m, piece, from: p, along: SIMD3(0.31, -0.2, 0.93)) % 2 == 1
    }

    /// Under the crown: a (nearly) vertical ray up from `p` meets it.
    static func under(_ m: MeshBuffers, _ piece: Piece, _ p: SIMD3<Float>) -> Bool {
        guard p.y <= piece.hi.y, p.x >= piece.lo.x - 0.05, p.x <= piece.hi.x + 0.05, p.z >= piece.lo.z - 0.05, p.z <= piece.hi.z + 0.05
        else { return false }
        return crossings(m, piece, from: p, along: SIMD3(0.012, 1, -0.007)) > 0
    }

    // MARK: - Tests

    @Test(arguments: kinds + [.conifer, .bush, .flowerBush])
    func meshesAreDeterministic(_ kind: PropKind) throws {
        #expect(PropLibrary.lodCount(kind) == 4 && PropLibrary.lodDistances.count == 3)
        for lod in 0..<4 { #expect(try Self.mesh(kind, lod: lod) == Self.mesh(kind, lod: lod), "\(kind) lod \(lod)") }
    }

    /// Budgets per tree: branches per level, whole tree at mid (≤ 200), far (`treeTriangleBudget.far`)
    /// and skyline (≤ 12: a crown and a two-triangle trunk card, no branches); conifers and bushes stay
    /// within the skyline budget there too.
    @Test(arguments: kinds)
    func trianglesStayWithinBudget(_ kind: PropKind) throws {
        var line = "TREETRIS \(kind.rawValue)"
        for lod in 0..<4 {
            let m = try Self.mesh(kind, lod: lod)
            let trunk = Self.triangles(m, .trunk).count, branches = Self.triangles(m, .branch).count, crown = Self.triangles(m, .crown).count
            line += " | lod\(lod) trunk \(trunk) branches \(branches) crown \(crown) total \(m.triangleCount)"
            #expect(m.triangleCount <= Self.totalBudget[lod], "\(kind) lod \(lod): \(m.triangleCount) triangles")
            if lod < 3 {
                #expect(branches <= Self.branchBudget[lod], "\(kind) lod \(lod): \(branches) branch triangles")
                #expect(trunk > 0 && branches > 0 && crown > 0, "\(kind) lod \(lod): a part is missing")
            } else {
                #expect(trunk <= 2 && branches == 0 && crown > 0, "\(kind): the skyline level is a crown on a trunk card")
            }
        }
        for other in [PropKind.conifer, .bush, .flowerBush] {
            let m = try Self.mesh(other, lod: 3)
            line += " | \(other.rawValue) lod3 \(m.triangleCount)"
            #expect(m.triangleCount <= PropLibrary.skylineTriangleBudget, "\(other): \(m.triangleCount) skyline triangles")
        }
        print(line)
    }

    /// Nothing pokes out of a leafy crown: every branch vertex lies inside that level's crown (its closed
    /// lobes) or right under it, checked against the crown mesh itself; so does the far trunk where it
    /// carries on as the leader, and the skyline trunk card's top.
    @Test(arguments: kinds)
    func branchesStayInsideTheLeafyCrown(_ kind: PropKind) throws {
        let trunkTop = PropLibrary.lobes(kind).trunkTop + 0.08
        for lod in 0..<4 {
            let m = try Self.mesh(kind, lod: lod)
            let ref = lod < 2 ? try Self.solid(kind, lod: lod) : m
            let crown = Self.pieces(ref, Self.triangles(ref, .crown))
            let shape = PropLibrary.lobes(kind)
            #expect(crown.count == [shape.lobes.count, shape.midCount, shape.shellFar ? 1 : 2, 1][lod], "\(kind) lod \(lod): \(crown.count) crown pieces")
            var outside: [SIMD3<Float>] = []
            for v in 0..<m.vertexCount {
                let p = m.positions[v]
                guard Self.part(m, vertex: v) == .branch || (Self.part(m, vertex: v) == .trunk && p.y > trunkTop) else { continue }
                if !crown.contains(where: { Self.inside(ref, $0, p) }) && !crown.contains(where: { Self.under(ref, $0, p) }) { outside.append(p) }
            }
            #expect(outside.isEmpty, "\(kind) lod \(lod): \(outside.count) branch vertices outside the crown, first \(String(describing: outside.first))")
        }
    }

    /// The near rule in lobe terms: branch points stay within 0.85 of a lobe's radius from its centre
    /// (0.05 tolerance for jitter and tube radius), inside the crown ellipsoid, or below the lobes.
    @Test(arguments: kinds)
    func nearBranchesKeepToTheLobes(_ kind: PropKind) throws {
        let shape = PropLibrary.lobes(kind)
        let m = try Self.mesh(kind, lod: 0)
        let lowest = shape.lobes.map(\.0.y).min()!
        let stray = (0..<m.vertexCount).filter { v in
            guard Self.part(m, vertex: v) == .branch else { return false }
            let p = m.positions[v]
            let inLobe = shape.lobes.contains { c, r in simd_length((p - c) / SIMD3(r, r * 0.92, r)) <= 0.9 }
            return !inLobe && simd_length((p - shape.crown) / shape.radii) > 1 && p.y > lowest
        }
        #expect(stray.isEmpty, "\(kind): \(stray.count) branch vertices beyond the lobes, first \(String(describing: stray.first.map { m.positions[$0] }))")
    }

    /// Paint and leaf-drop data stay as the shaders expect: bark trunk (sway 0) and branches (sway 0.3,
    /// AO 0.75) with no leaf threshold; crown lobes sway 1 with thresholds in (0.1, 1], the skyline crown
    /// 0.5 (with the skyline shade).
    @Test(arguments: kinds)
    func paintsAndLeafThresholds(_ kind: PropKind) throws {
        let palette = try Self.palette()
        let bark = Float(palette.named("bark")), crownPaint = PropLibrary.crownPaint(kind, palette: palette), leaves = Float(crownPaint.slot)
        for lod in 0..<4 {
            let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette, leafCards: true)
            var wrong = 0
            for v in 0..<m.vertexCount {
                let paint = m.paints[v], extra = m.extras[v]
                switch Self.part(m, vertex: v) {
                case .trunk: if paint.x != bark || paint.z != 0 || paint.w != 0 || extra.y != 0 { wrong += 1 }
                case .branch: if paint.x != bark || paint.z != 0 || paint.w != Float(0.3) || extra.y != 0 || abs(extra.x - 0.75) > 1e-6 { wrong += 1 }
                case .crown:
                    let card = lod < 2
                    let flags = Float(crownPaint.flags.union(card ? .leafCard : []).rawValue)
                    let shade = lod == 3 ? PropLibrary.skylineShade : 1
                    let shadeOK = card ? paint.y >= 0.94 && paint.y <= 1.05 : paint.y == shade
                    if paint.x != leaves || paint.z != flags || !shadeOK || (lod == 3 ? extra.y != 0.5 : !(extra.y > 0.1 && extra.y <= 1))
                        || (card && (extra.z != 0 || m.uvs.count != m.vertexCount)) { wrong += 1 }
                }
            }
            #expect(wrong == 0, "\(kind) lod \(lod): \(wrong) vertices with unexpected paint or leaf threshold")
            #expect(Self.triangles(m, .crown).count > 0 && (lod == 3 || Self.triangles(m, .branch).count > 0))
        }
    }

    /// A bare tree, not a fork: near detail grows dozens of branches and twigs whose tips fill most of the
    /// leafy crown's width and height, and the mid and far levels keep the limbs and outline branches.
    @Test(arguments: kinds)
    func bareCrownFillsTheLeafyOutline(_ kind: PropKind) throws {
        let shape = PropLibrary.lobes(kind)
        var rng = StableRandom(seed: 1)
        let skeleton = PropLibrary.bareSkeleton(shape, style: .of(kind), trunkRadius: 0.02, rng: &rng)
        #expect(skeleton.count >= 40, "\(kind): \(skeleton.count) boughs")
        #expect(skeleton.filter { $0.order == 2 }.count >= 24, "\(kind): too few twigs")
        let m = try Self.mesh(kind, lod: 0)
        func extent(_ p: Part) -> (lo: SIMD3<Float>, hi: SIMD3<Float>) {
            var lo = SIMD3<Float>(repeating: .infinity), hi = -lo
            for v in 0..<m.vertexCount where Self.part(m, vertex: v) == p { lo = simd_min(lo, m.positions[v]); hi = simd_max(hi, m.positions[v]) }
            return (lo, hi)
        }
        let ref = try Self.solid(kind, lod: 0)
        var leafy = (lo: SIMD3<Float>(repeating: .infinity), hi: SIMD3<Float>(repeating: -.infinity))
        for v in 0..<ref.vertexCount where Self.part(ref, vertex: v) == .crown { leafy.lo = simd_min(leafy.lo, ref.positions[v]); leafy.hi = simd_max(leafy.hi, ref.positions[v]) }
        let bare = extent(.branch)
        let width = (bare.hi - bare.lo) / (leafy.hi - leafy.lo)
        #expect(width.x >= 0.65 && width.z >= 0.65, "\(kind): bare crown spans \(width.x) × \(width.z) of the leafy one")
        #expect(bare.hi.y >= 0.85 * leafy.hi.y, "\(kind): bare crown reaches \(bare.hi.y / leafy.hi.y) of the leafy top")
    }

    /// The far crown is the mid crown's two lobes, cheaper: the larger lobe stays round (an icosahedron,
    /// its faces at 75% or more of its corners' reach; an octahedron's sink to 58%), each lobe keeps its
    /// mid leaf threshold, and from the side at eight yaws and from above the far crown covers about what
    /// the mid crown covers, so the switch keeps the outline.
    /// Species crowns: one shrink-wrapped mass (20 triangles, leaf threshold 0.5) that covers about what
    /// the five-lobe mid crown covers from the side (mean within 10 %, each yaw within 20 %) and above.
    @Test(arguments: speciesKinds)
    func farSpeciesCrownKeepsTheMidOutline(_ kind: PropKind) throws {
        let far = try Self.mesh(kind, lod: 2), mid = try Self.solid(kind, lod: 1)
        let farCrown = Self.triangles(far, .crown), midCrown = Self.triangles(mid, .crown)
        #expect(Self.pieces(far, farCrown).count == 1 && farCrown.count == 20)
        #expect(farCrown.allSatisfy { far.extras[Int(far.indices[$0 * 3])].y == 0.5 })
        let side = (0..<8).map { k -> Double in
            let yaw = Float(k) * .pi / 4
            return Double(Self.coverage(far, farCrown, yaw: yaw)) / Double(Self.coverage(mid, midCrown, yaw: yaw))
        }
        let above = Double(Self.coverage(far, farCrown, fromAbove: true)) / Double(Self.coverage(mid, midCrown, fromAbove: true))
        let mean = side.reduce(0, +) / 8
        print("FARCOVER \(kind.rawValue) side \(side.map { String(format: "%.3f", $0) }) mean \(String(format: "%.3f", mean)) above \(String(format: "%.3f", above))")
        #expect(abs(mean - 1) < 0.1 && side.allSatisfy { $0 > 0.8 && $0 < 1.2 }, "\(kind): far crown covers \(side) of the mid crown from the side")
        #expect(above > 0.9 && above < 1.2, "\(kind): far crown covers \(above) of the mid crown from above")
    }

    @Test(arguments: kinds.filter { !PropLibrary.lobes($0).shellFar })
    func farCrownKeepsTheMidOutline(_ kind: PropKind) throws {
        let far = try Self.mesh(kind, lod: 2), mid = try Self.solid(kind, lod: 1)
        let farCrown = Self.triangles(far, .crown), midCrown = Self.triangles(mid, .crown)
        let farLobes = Self.pieces(far, farCrown), midLobes = Self.pieces(mid, midCrown)
        #expect(farLobes.count == 2 && midLobes.count == 2)
        for (f, md) in zip(farLobes, midLobes) {
            let a = far.extras[Int(far.indices[f.triangles[0] * 3])].y, b = mid.extras[Int(mid.indices[md.triangles[0] * 3])].y
            #expect(a == b, "\(kind): far lobe threshold \(a), mid \(b)")
        }
        // An icosahedron draws the larger mid lobe (the smaller one too from a 52-triangle budget).
        func middle(_ p: Piece) -> SIMD3<Float> { (p.lo + p.hi) / 2 }
        let largerMid = midLobes.max { simd_length($0.hi - $0.lo) < simd_length($1.hi - $1.lo) }!
        let large = farLobes.min { simd_distance(middle($0), middle(largerMid)) < simd_distance(middle($1), middle(largerMid)) }!
        #expect(large.triangles.count == 20, "\(kind): the far lobes have \(farLobes.map(\.triangles.count)) triangles")
        for lobe in farLobes where lobe.triangles.count == 20 {
            let center = middle(lobe)
            let sunk = lobe.triangles.filter { t in
                let (a, b, c) = Self.corners(far, t)
                let reach = (simd_distance(a, center) + simd_distance(b, center) + simd_distance(c, center)) / 3
                return simd_distance((a + b + c) / 3, center) < 0.75 * reach
            }
            #expect(sunk.isEmpty, "\(kind): \(sunk.count) faces of a far lobe sink toward its centre")
        }
        let side = (0..<8).map { k -> Double in
            let yaw = Float(k) * .pi / 4
            return Double(Self.coverage(far, farCrown, yaw: yaw)) / Double(Self.coverage(mid, midCrown, yaw: yaw))
        }
        let above = Double(Self.coverage(far, farCrown, fromAbove: true)) / Double(Self.coverage(mid, midCrown, fromAbove: true))
        print("FARCOVER \(kind.rawValue) side \(side.map { String(format: "%.3f", $0) }) above \(String(format: "%.3f", above))")
        #expect(side.allSatisfy { $0 > 0.9 && $0 < 1.1 }, "\(kind): far crown covers \(side) of the mid crown from the side")
        #expect(above > 0.9 && above < 1.1, "\(kind): far crown covers \(above) of the mid crown from above")
    }

    /// The skyline crown (one 10-triangle dome) keeps about the far crown's outline at the switch, from
    /// the side at eight yaws, and from above (the whole aerial view is drawn at this level) it is at most
    /// 10% wider than the far crown.
    @Test(arguments: kinds)
    func skylineCrownKeepsTheFarOutline(_ kind: PropKind) throws {
        let sky = try Self.mesh(kind, lod: 3), far = try Self.mesh(kind, lod: 2)
        let skyCrown = Self.triangles(sky, .crown), farCrown = Self.triangles(far, .crown)
        #expect(Self.pieces(sky, skyCrown).count == 1)
        let side = (0..<8).map { k -> Double in
            let yaw = Float(k) * .pi / 4
            return Double(Self.coverage(sky, skyCrown, yaw: yaw)) / Double(Self.coverage(far, farCrown, yaw: yaw))
        }
        let above = Double(Self.coverage(sky, skyCrown, fromAbove: true)) / Double(Self.coverage(far, farCrown, fromAbove: true))
        print("SKYCOVER \(kind.rawValue) side \(side.map { String(format: "%.3f", $0) }) mean \(String(format: "%.3f", side.reduce(0, +) / 8)) above \(String(format: "%.3f", above))")
        #expect(side.allSatisfy { $0 > 0.8 && $0 < 1.25 }, "\(kind): skyline crown covers \(side) of the far crown from the side")
        #expect(abs(side.reduce(0, +) / 8 - 1) < 0.1, "\(kind): skyline crown covers \(side) of the far crown from the side")
        #expect(above > 0.95 && above < 1.21, "\(kind): skyline crown covers \(above) of the far crown from above")
    }

    /// A row of one archetype doesn't repeat at far detail: the far crown is lopsided like the mid crown,
    /// so turning a tree (instances have their own yaw) changes its outline; some pair of yaws overlaps
    /// by 85% or less.
    @Test(arguments: kinds)
    func farOutlineChangesWithYaw(_ kind: PropKind) throws {
        let far = try Self.mesh(kind, lod: 2)
        let crown = Self.triangles(far, .crown)
        let masks = (0..<8).map { Self.mask(far, crown, yaw: Float($0) * .pi / 4) }
        var lowest = 1.0
        for a in 0..<8 { for b in (a + 1)..<8 {
            let both = zip(masks[a], masks[b]).filter { $0 && $1 }.count, either = zip(masks[a], masks[b]).filter { $0 || $1 }.count
            lowest = min(lowest, Double(both) / Double(max(1, either)))
        } }
        #expect(lowest <= 0.85, "\(kind): far outlines at all yaws overlap by at least \(lowest)")
    }

    /// Per-tree proportions: every generated tree gets its own crown width and oval footprint (stable,
    /// from its own seed, so kinds, heights and yaws keep their draws); other props stay unstretched.
    @Test func generatedTreesGetTheirOwnProportions() throws {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 39.75, longitude: -105.04)), bounds: Rect2D(centerWidth: 400, height: 400))
        for i in 0..<60 {
            let position = LocalPoint(Double(i % 10) * 12 - 60, Double(i / 10) * 12 - 36)
            f.points.append(PointFeature(ref: OSMRef(.node, Int64(500 + i)), kind: .tree, position: position, tags: [:]))
        }
        f.points.append(PointFeature(ref: OSMRef(.node, 9), kind: .bench, position: LocalPoint(80, 80), tags: [:]))
        let gen = SceneGenerator(features: f, profile: try StyleLibrary.profile(id: "front-range"), seasonal: try StyleLibrary.seasonalPalette(),
                                 baseColors: try StyleLibrary.baseColors(), season: 1, focus: f.bounds)
        let scene = gen.generate()
        let trees = scene.instances.filter(\.kind.isTree)
        #expect(trees.count == 60)
        #expect(scene.instances.filter { !$0.kind.isTree }.allSatisfy { $0.stretch == SIMD2(1, 1) })
        #expect(scene.instances == gen.generate().instances)
        #expect(Set(trees.map { "\($0.stretch)" }).count == trees.count, "neighbouring trees share proportions")
        for t in trees {
            let ref = OSMRef(.node, Int64(t.source.split(separator: "/").last!)!)
            #expect(t.stretch == SceneGenerator.treeStretch(ref))
            let width = (t.stretch.x + t.stretch.y) / 2, oval = t.stretch.x / t.stretch.y
            #expect(width >= 0.88 && width < 1.14 && oval > 0.85 && oval < 1.18, "\(t.source): \(t.stretch)")
            // Stretch scales the prop's own x and z before its yaw; height stays the instance scale.
            let m = t.transform
            #expect(abs(simd_length(SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.z)) - Float(t.scale * t.stretch.x)) < 1e-3)
            #expect(abs(simd_length(SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.z)) - Float(t.scale)) < 1e-4)
            #expect(abs(simd_length(SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z)) - Float(t.scale * t.stretch.y)) < 1e-3)
        }
        let widths = trees.map { ($0.stretch.x + $0.stretch.y) / 2 }
        #expect(widths.max()! - widths.min()! > 0.15, "crown widths span only \(widths.min()!)–\(widths.max()!)")
    }

    // MARK: - Silhouettes

    /// Pixels a side view at `yaw` (orthographic, 1.2 tree heights across; or the view from above)
    /// shows of `tris`; `paint` also colours them into `pixels`.
    static func coverage(_ m: MeshBuffers, _ tris: [Int], yaw: Float = 0, fromAbove: Bool = false, size: Int = 160, atlas: LeafAtlas? = nil,
                         paint: (color: SIMD3<UInt8>, pixels: UnsafeMutableBufferPointer<SIMD3<UInt8>>)? = nil) -> Int {
        mask(m, tris, yaw: yaw, fromAbove: fromAbove, size: size, atlas: atlas, paint: paint).filter { $0 }.count
    }

    static func mask(_ m: MeshBuffers, _ tris: [Int], yaw: Float = 0, fromAbove: Bool = false, size: Int = 160, atlas: LeafAtlas? = nil,
                     paint: (color: SIMD3<UInt8>, pixels: UnsafeMutableBufferPointer<SIMD3<UInt8>>)? = nil) -> [Bool] {
        var covered = [Bool](repeating: false, count: size * size)
        let scale = Float(size) / 1.2
        func screen(_ p: SIMD3<Float>) -> SIMD2<Float> {
            fromAbove ? SIMD2((p.x + 0.6) * scale, (p.z + 0.6) * scale) : SIMD2((cos(yaw) * p.x - sin(yaw) * p.z + 0.6) * scale, (1.1 - p.y) * scale)
        }
        for t in tris {
            let (pa, pb, pc) = corners(m, t)
            let a = screen(pa), b = screen(pb), c = screen(pc)
            let area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
            guard abs(area) > 1e-9 else { continue }
            let x0 = max(0, Int(min(a.x, b.x, c.x))), x1 = min(size - 1, Int(max(a.x, b.x, c.x)))
            let y0 = max(0, Int(min(a.y, b.y, c.y))), y1 = min(size - 1, Int(max(a.y, b.y, c.y)))
            guard x0 <= x1, y0 <= y1 else { continue }
            for y in y0...y1 {
                for x in x0...x1 {
                    let p = SIMD2<Float>(Float(x) + 0.5, Float(y) + 0.5)
                    let w0 = ((b.x - p.x) * (c.y - p.y) - (b.y - p.y) * (c.x - p.x)) / area
                    let w1 = ((c.x - p.x) * (a.y - p.y) - (c.y - p.y) * (a.x - p.x)) / area
                    guard w0 >= 0, w1 >= 0, w0 + w1 <= 1 else { continue }
                    if let atlas, m.uvs.count == m.vertexCount, isCard(m, vertex: Int(m.indices[t * 3])) {
                        let ua: SIMD2<Float> = m.uvs[Int(m.indices[t * 3])], ub: SIMD2<Float> = m.uvs[Int(m.indices[t * 3 + 1])]
                        let uc: SIMD2<Float> = m.uvs[Int(m.indices[t * 3 + 2])]
                        let w2: Float = 1 - w0 - w1
                        let uv: SIMD2<Float> = ua * w0 + ub * w1 + uc * w2
                        guard atlas.coverage(uv) >= 0.5 else { continue }
                    }
                    covered[y * size + x] = true
                    if let paint { paint.pixels[y * size + x] = paint.color }
                }
            }
        }
        return covered
    }

    /// Visual check, off by default: `TREE_SILHOUETTES=<dir> swift test --filter TreeSilhouetteTests`
    /// writes tree-silhouettes.png there. Rows: broad, oval, spreading. Columns: near summer, near / mid /
    /// far winter (bare), far summer, then near winter from a quarter turn.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["TREE_SILHOUETTES"] != nil))
    func writesSilhouetteSheet() throws {
        let dir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TREE_SILHOUETTES"]!)
        let cell = 240, columns = 6, ss = 3, sky = SIMD3<UInt8>(196, 214, 236)
        let cells: [(lod: Int, bare: Bool, yaw: Float)] = [(0, false, 0.35), (0, true, 0.35), (1, true, 0.35), (2, true, 0.35), (2, false, 0.35), (0, true, 1.9)]
        var sheet = [SIMD3<UInt8>](repeating: sky, count: cell * columns * cell * Self.kinds.count)
        for (row, kind) in Self.kinds.enumerated() {
            for (column, c) in cells.enumerated() {
                let m = try Self.mesh(kind, lod: c.lod)
                var pixels = [SIMD3<UInt8>](repeating: sky, count: cell * ss * cell * ss)
                pixels.withUnsafeMutableBufferPointer { buffer in
                    for part in [Part.trunk, .branch] + (c.bare ? [] : [.crown]) {
                        let color: SIMD3<UInt8> = part == .crown ? SIMD3(96, 140, 80) : SIMD3(92, 70, 52)
                        _ = Self.coverage(m, Self.triangles(m, part), yaw: c.yaw, size: cell * ss, atlas: PropLibrary.leafAtlas, paint: (color, buffer))
                    }
                }
                // Box-filter the supersampled cell into the sheet.
                for y in 0..<cell { for x in 0..<cell {
                    var sum = SIMD3<Int>.zero
                    for dy in 0..<ss { for dx in 0..<ss { sum &+= SIMD3<Int>(truncatingIfNeeded: pixels[(y * ss + dy) * cell * ss + x * ss + dx]) } }
                    sheet[(row * cell + y) * cell * columns + column * cell + x] = SIMD3<UInt8>(truncatingIfNeeded: sum / (ss * ss))
                } }
            }
        }
        let width = cell * columns, height = cell * Self.kinds.count
        var bytes: [UInt8] = []
        bytes.reserveCapacity(width * height * 4)
        for p in sheet { bytes += [p.x, p.y, p.z, 255] }
        let provider = try #require(CGDataProvider(data: Data(bytes) as CFData))
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let image = try #require(CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                                         space: space, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                         provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let url = dir.appendingPathComponent("tree-silhouettes.png")
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        print("TREESILHOUETTES \(url.path)")
    }
}
