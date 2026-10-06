import CoreGraphics
import Foundation
import ImageIO
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMesh

/// Deciduous tree silhouettes (Props.swift): the bare skeleton every detail level draws, and the far
/// crown. Meshes are unit height; trunk, branches and crown are told apart by sway (0, 0.3, 1).
@Suite("Tree silhouettes")
struct TreeSilhouetteTests {
    static let kinds: [PropKind] = [.treeBroad, .treeOval, .treeSpreading]
    /// Branch triangles per tree at near, mid and far detail (thousands of trees are drawn).
    static let branchBudget = [260, 90, 30]
    /// The far crown may add 40 triangles to the old 8-triangle octahedron.
    static let farCrownBudget = 48

    enum Part { case trunk, branch, crown }

    struct Piece {
        var triangles: [Int]
        var lo: SIMD3<Float>, hi: SIMD3<Float>
    }

    static func palette() throws -> Palette { Palette(base: try StyleLibrary.baseColors()) }

    static func mesh(_ kind: PropKind, lod: Int) throws -> MeshBuffers {
        PropLibrary.mesh(kind, variant: 0, lod: lod, palette: try palette())
    }

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

    @Test(arguments: kinds)
    func meshesAreDeterministic(_ kind: PropKind) throws {
        for lod in 0..<3 { #expect(try Self.mesh(kind, lod: lod) == Self.mesh(kind, lod: lod), "\(kind) lod \(lod)") }
    }

    @Test(arguments: kinds)
    func trianglesStayWithinBudget(_ kind: PropKind) throws {
        var line = "TREETRIS \(kind.rawValue)"
        for lod in 0..<3 {
            let m = try Self.mesh(kind, lod: lod)
            let trunk = Self.triangles(m, .trunk).count, branches = Self.triangles(m, .branch).count, crown = Self.triangles(m, .crown).count
            line += " | lod\(lod) trunk \(trunk) branches \(branches) crown \(crown) total \(m.triangleCount)"
            #expect(branches <= Self.branchBudget[lod], "\(kind) lod \(lod): \(branches) branch triangles")
            if lod == 2 { #expect(crown <= Self.farCrownBudget, "\(kind): far crown \(crown) triangles") }
        }
        print(line)
    }

    /// Nothing pokes out of a leafy crown: every branch vertex lies inside that level's crown (a closed
    /// lobe, or the far crown) or right under it, checked against the crown mesh itself.
    @Test(arguments: kinds)
    func branchesStayInsideTheLeafyCrown(_ kind: PropKind) throws {
        for lod in 0..<3 {
            let m = try Self.mesh(kind, lod: lod)
            let crown = Self.pieces(m, Self.triangles(m, .crown))
            #expect(crown.count == [PropLibrary.lobes(kind).lobes.count, 2, 1][lod], "\(kind) lod \(lod): \(crown.count) crown pieces")
            var outside: [SIMD3<Float>] = []
            for v in 0..<m.vertexCount where Self.part(m, vertex: v) == .branch {
                let p = m.positions[v]
                if !crown.contains(where: { Self.inside(m, $0, p) }) && !crown.contains(where: { Self.under(m, $0, p) }) { outside.append(p) }
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
    /// AO 0.75) with no leaf threshold; crown lobes sway 1 with thresholds in (0.1, 1], the far crown 0.5.
    @Test(arguments: kinds)
    func paintsAndLeafThresholds(_ kind: PropKind) throws {
        let palette = try Self.palette()
        let bark = Float(palette.named("bark")), leaves = Float(palette.named("deciduous1"))
        for lod in 0..<3 {
            let m = PropLibrary.mesh(kind, variant: 0, lod: lod, palette: palette)
            var wrong = 0
            for v in 0..<m.vertexCount {
                let paint = m.paints[v], extra = m.extras[v]
                switch Self.part(m, vertex: v) {
                case .trunk: if paint.x != bark || paint.z != 0 || paint.w != 0 || extra.y != 0 { wrong += 1 }
                case .branch: if paint.x != bark || paint.z != 0 || paint.w != Float(0.3) || extra.y != 0 || abs(extra.x - 0.75) > 1e-6 { wrong += 1 }
                case .crown:
                    let flags = Float(Paint.Flags.variant4.rawValue)
                    if paint.x != leaves || paint.z != flags || (lod == 2 ? extra.y != 0.5 : !(extra.y > 0.1 && extra.y <= 1)) { wrong += 1 }
                }
            }
            #expect(wrong == 0, "\(kind) lod \(lod): \(wrong) vertices with unexpected paint or leaf threshold")
            #expect(Self.triangles(m, .branch).count > 0 && Self.triangles(m, .crown).count > 0)
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
        let bare = extent(.branch), leafy = extent(.crown)
        let width = (bare.hi - bare.lo) / (leafy.hi - leafy.lo)
        #expect(width.x >= 0.65 && width.z >= 0.65, "\(kind): bare crown spans \(width.x) × \(width.z) of the leafy one")
        #expect(bare.hi.y >= 0.85 * leafy.hi.y, "\(kind): bare crown reaches \(bare.hi.y / leafy.hi.y) of the leafy top")
    }

    /// The far crown is round, not a diamond: its faces stay near the ellipsoid through its corners (an
    /// octahedron's sink to 58%), and seen from the side it covers about what the near crown covers.
    @Test(arguments: kinds)
    func farCrownIsRoundAndKeepsTheNearOutline(_ kind: PropKind) throws {
        let far = try Self.mesh(kind, lod: 2), near = try Self.mesh(kind, lod: 0)
        let (center, radii) = PropLibrary.farCrownEllipsoid(PropLibrary.lobes(kind))
        let farCrown = Self.triangles(far, .crown), nearCrown = Self.triangles(near, .crown)
        let sunk = farCrown.filter { t in
            let (a, b, c) = Self.corners(far, t)
            return simd_length(((a + b + c) / 3 - center) / radii) < 0.8
        }
        #expect(sunk.isEmpty, "\(kind): \(sunk.count) far crown faces sink inside the ellipsoid")
        let ratio = (0..<8).map { k -> Double in
            let yaw = Float(k) * .pi / 4
            return Double(Self.coverage(far, farCrown, yaw: yaw)) / Double(Self.coverage(near, nearCrown, yaw: yaw))
        }.reduce(0, +) / 8
        #expect(ratio > 0.85 && ratio < 1.15, "\(kind): far crown covers \(ratio) of the near crown")
    }

    // MARK: - Silhouettes

    /// Pixels a side view at `yaw` (orthographic, 1.2 tree heights across) shows of `tris`; `paint` also
    /// colours them into `pixels`.
    static func coverage(_ m: MeshBuffers, _ tris: [Int], yaw: Float, size: Int = 160,
                         paint: (color: SIMD3<UInt8>, pixels: UnsafeMutableBufferPointer<SIMD3<UInt8>>)? = nil) -> Int {
        var covered = [Bool](repeating: false, count: size * size)
        let scale = Float(size) / 1.2
        func screen(_ p: SIMD3<Float>) -> SIMD2<Float> { SIMD2((cos(yaw) * p.x - sin(yaw) * p.z + 0.6) * scale, (1.1 - p.y) * scale) }
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
                    covered[y * size + x] = true
                    if let paint { paint.pixels[y * size + x] = paint.color }
                }
            }
        }
        return covered.filter { $0 }.count
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
                        _ = Self.coverage(m, Self.triangles(m, part), yaw: c.yaw, size: cell * ss, paint: (color, buffer))
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
