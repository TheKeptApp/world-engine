import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// House details (house-details-v1): porches, stoops, trim, eaves and softened edges keep the entry
/// open, steps reach the ground, far and skyline stay unchanged, mid drops the near-only parts.
@Suite("House details")
struct HouseDetailTests {
    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    /// Footprints facing the test street (y = −12): a suburban box, a deep city lot, a wide ranch.
    static let rings: [(String, Ring)] = [("box", rect(0, 0, 12, 9)), ("deep", rect(0, 0, 7.5, 18)), ("wide", rect(0, 0, 17, 9))]
    static let profiles = ["evanston", "wilmette", "chicago-dense-north", "front-range"]

    static func generator(_ profile: String, details: Bool = true) throws -> BuildingGenerator {
        var g = BuildingGenerator(profile: try StyleLibrary.profile(id: profile), context: testContext())
        g.obstacles = PolygonIndex([])
        if !details {
            var lib = HouseFamilyLibrary.bundled
            for k in lib.families.keys { lib.families[k]?.details = nil }
            g.families = lib
        }
        return g
    }

    static func ray(_ m: MeshBuffers, _ p: LocalPoint, _ z: Double, _ d: SIMD3<Double>) -> Double? {
        GeometryCheck.hit(m, origin: SIMD3<Double>(LocalFrame.scenePosition(p, y: z)), dir: d)
    }

    @Test(arguments: profiles)
    func entriesStayOpenAndStepsReachTheGround(_ profile: String) throws {
        let gen = try Self.generator(profile)
        guard try StyleLibrary.profile(id: profile).houseTypes.contains(where: { gen.families.grammar($0.id).details != nil }) else { return }
        var palette = Palette(base: try StyleLibrary.baseColors())
        var porches = 0, checked = 0
        for (name, ring) in Self.rings {
            for id in Int64(1)...Int64(60) {
                let b = testBuilding(31_000 + id, ring)
                let g = gen.generate(b, palette: &palette, lod: .near)
                guard g.role == .house, let entry = g.entry, g.entryKit != "vestibule",
                      gen.families.grammar(g.family).details != nil else { continue }
                checked += 1
                if !g.porchOutline.isEmpty { porches += 1 }
                let F = g.floorHeight, n = entry.normal
                let dir = LocalPoint(-n.y, n.x)
                let label = "\(profile) \(name) #\(id) \(g.family ?? "-") kit=\(g.entryKit ?? "-") porch=\(!g.porchOutline.isEmpty)"
                // Nothing stands in front of the door: horizontal rays from the door, 0.5–1.9 m up.
                for ds in [-0.3, 0.0, 0.3] {
                    for dz in [0.5, 1.2, 1.9] {
                        let start = entry.point + dir * ds + n * 0.1
                        let d3 = SIMD3<Double>(D(n))
                        if let hit = Self.ray(g.mesh, start, F + dz, d3) {
                            Issue.record("\(label): blocked \(hit) m out at \(dz) m, offset \(ds)")
                        }
                    }
                }
                // Walking out from the door the floor never rises and comes down to the ground in risers.
                var last = F + 0.01, heights: [Double] = []
                var t = 0.15
                while t <= 5.0 {
                    let q = entry.point + n * t
                    let z0 = F + 0.35
                    let h = Self.ray(g.mesh, q, z0, SIMD3(0, -1, 0)).map { z0 - $0 } ?? 0
                    heights.append(h)
                    #expect(h <= last + 0.03, "\(label): floor rises to \(h) at \(t) m (from \(last))")
                    #expect(last - h <= 0.4, "\(label): drop \(last - h) m at \(t) m")
                    last = h
                    t += 0.2
                }
                #expect((heights.last ?? 1) <= 0.05, "\(label): steps end \(heights.last ?? -1) m above ground")
                if F > 0.15 { #expect(abs(heights[0] - F) <= 0.05, "\(label): no floor at the door (\(heights[0]) vs \(F))") }
            }
        }
        #expect(checked > 20, "\(profile): only \(checked) entries checked")
        if profile != "chicago-dense-north" { #expect(porches > 0, "\(profile): no covered porch built") }
    }

    /// Skyline is untouched by the details and far stays within 5 % (a family eave range changes
    /// the roof plan a little), and near/mid keep their own per-house caps.
    @Test(arguments: profiles)
    func farAndSkylineUnchangedAndPerLODCaps(_ profile: String) throws {
        let gen = try Self.generator(profile), plain = try Self.generator(profile, details: false)
        var palette = Palette(base: try StyleLibrary.baseColors())
        var farA = 0, farC = 0
        for (name, ring) in Self.rings {
            for id in Int64(1)...Int64(30) {
                let b = testBuilding(32_000 + id, ring)
                let sa = gen.generate(b, palette: &palette, lod: .skyline).mesh.triangleCount
                let sc = plain.generate(b, palette: &palette, lod: .skyline).mesh.triangleCount
                #expect(sa == sc, "\(profile) \(name) #\(id) skyline: \(sa) vs \(sc)")
                farA += gen.generate(b, palette: &palette, lod: .far).mesh.triangleCount
                farC += plain.generate(b, palette: &palette, lod: .far).mesh.triangleCount
                let near = gen.generate(b, palette: &palette, lod: .near), mid = gen.generate(b, palette: &palette, lod: .mid)
                #expect(near.mesh.triangleCount <= 2500, "\(profile) \(name) #\(id) near \(near.mesh.triangleCount)")
                #expect(mid.mesh.triangleCount <= 900, "\(profile) \(name) #\(id) mid \(mid.mesh.triangleCount)")
                #expect(mid.mesh.triangleCount * 2 <= near.mesh.triangleCount + 40, "\(profile) \(name) #\(id) mid vs near")
            }
        }
        #expect(Double(farA) <= Double(farC) * 1.05, "\(profile) far \(farA) vs \(farC)")
    }

    /// Street corners get one chamfer face (or a chamfered corner board) at near; mid has none.
    @Test func streetCornersAreSoftenedNearOnly() throws {
        let gen = try Self.generator("evanston")
        var palette = Palette(base: try StyleLibrary.baseColors())
        let ring = Self.rect(0, 0, 12, 9)
        let corners = [LocalPoint(0, 0), LocalPoint(12, 0)]
        /// Diagonal, horizontal-normal vertices within 0.1 m of a front corner.
        func chamfers(_ m: MeshBuffers) -> Int {
            zip(m.positions, m.normals).filter { p, nn in
                let lp = LocalPoint(Double(p.x), Double(-p.z))
                return abs(nn.y) < 0.05 && abs(abs(nn.x) - 0.7071) < 0.02 && corners.contains { simd_distance($0, lp) < 0.1 }
            }.count
        }
        var softened = 0
        for id in Int64(1)...Int64(80) {
            let b = testBuilding(33_000 + id, ring)
            let g = gen.generate(b, palette: &palette, lod: .near)
            guard gen.families.grammar(g.family).details?.corners != nil else { continue }
            #expect(chamfers(g.mesh) >= 8, "#\(id) \(g.family ?? "-"): \(chamfers(g.mesh)) chamfer vertices")
            #expect(chamfers(gen.generate(b, palette: &palette, lod: .mid).mesh) == 0, "#\(id) mid has chamfers")
            softened += 1
        }
        #expect(softened > 20)
    }

    /// City families: stone stoops with solid cheek walls beside the steps, and a chamfered cornice
    /// cap (one 45° face) at near only.
    @Test func cityStoopsHaveCheekWallsAndChamferedCornices() throws {
        let gen = try Self.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var cheeks = 0, cornices = 0
        for id in Int64(1)...Int64(120) {
            let b = testBuilding(36_000 + id, Self.rect(0, 0, 7.5, 18))
            let g = gen.generate(b, palette: &palette, lod: .near)
            guard let d = gen.families.grammar(g.family).details, let entry = g.entry else { continue }
            let n = entry.normal, dir = LocalPoint(-n.y, n.x)
            if d.stoop?.cheeks == true, g.porchOutline.isEmpty, g.floorHeight > 0.5 {
                // Something stands beside the stair run (cheek walls), above knee height.
                let beside = g.mesh.positions.contains { p in
                    let lp = LocalPoint(Double(p.x), Double(-p.z)) - entry.point
                    let s = abs(simd_dot(lp, dir)), t = simd_dot(lp, n)
                    return t > 1.3 && t < 1.9 && s > 0.5 && s < 1.3 && Double(p.y) > 0.35
                }
                #expect(beside, "#\(id) \(g.family ?? "-"): no cheek walls")
                cheeks += 1
            }
            if d.copingBevel == true, g.roofShape == .flat, gen.families.grammar(g.family).facade?.cornice == true {
                func bevels(_ m: MeshBuffers) -> Int {
                    m.normals.filter { abs($0.y - 0.7071) < 0.02 && simd_dot(SIMD2($0.x, -$0.z), SIMD2(Float(n.x), Float(n.y))) > 0.69 }.count
                }
                #expect(bevels(g.mesh) >= 4, "#\(id) \(g.family ?? "-"): no cornice chamfer")
                #expect(bevels(gen.generate(b, palette: &palette, lod: .mid).mesh) == 0, "#\(id) mid cornice chamfer")
                cornices += 1
            }
        }
        #expect(cheeks >= 10 && cornices >= 10, "cheeks \(cheeks) cornices \(cornices)")
    }

    /// Trim colours stay within three linear-light steps of the family range (few palette slots).
    @Test func trimColoursAreThreeStepsPerFamily() throws {
        let gen = try Self.generator("evanston")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var seen: [String: Set<String>] = [:]
        for id in Int64(1)...Int64(300) {
            let g = gen.generate(testBuilding(34_000 + id, Self.rect(0, 0, 12, 9)), palette: &palette, lod: .near)
            guard let fam = g.family, let range = gen.families.grammar(fam).details?.trim else { continue }
            seen[fam, default: []].insert(g.colors[1])
            // Families mapped to a house-contrast-v1 type take that type's trim swatch instead.
            var allowed = (0..<3).map { HouseDetailColours.step(range[0], range[1], $0) }
            if let hc = BuildingGenerator.contrast, hc.families[fam] != nil { allowed = hc.types.values.map(\.trim) }
            #expect(allowed.contains(g.colors[1]), "\(fam): \(g.colors[1])")
        }
        #expect(seen.count >= 4)
        for (fam, s) in seen { #expect(s.count <= 3, "\(fam): \(s)") }
    }
}
