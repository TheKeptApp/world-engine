import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

// Geometry checks for generated buildings: consistent winding (nothing inverted), finite
// positions, and sealed shells (a ray leaving the inside of a building always hits a surface).

enum GeometryCheck {
    /// Triangles whose winding disagrees with their vertex normals.
    static func windingErrors(_ m: MeshBuffers) -> [Int] {
        var bad: [Int] = []
        for t in 0..<m.triangleCount {
            let face = m.faceCross(t)
            guard simd_length(face) > 1e-7 else { continue }
            let n = m.normals[Int(m.indices[t * 3])] + m.normals[Int(m.indices[t * 3 + 1])] + m.normals[Int(m.indices[t * 3 + 2])]
            if simd_dot(simd_normalize(face), simd_normalize(n)) <= 0 { bad.append(t) }
        }
        return bad
    }

    static func finite(_ m: MeshBuffers) -> Bool {
        m.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite }
            && m.normals.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite }
    }

    /// Distance along the ray to the nearest triangle, or nil if it escapes.
    static func hit(_ m: MeshBuffers, origin o: SIMD3<Double>, dir d: SIMD3<Double>) -> Double? {
        var best: Double?
        for t in 0..<m.triangleCount {
            let a = SIMD3<Double>(m.positions[Int(m.indices[t * 3])])
            let b = SIMD3<Double>(m.positions[Int(m.indices[t * 3 + 1])])
            let c = SIMD3<Double>(m.positions[Int(m.indices[t * 3 + 2])])
            let e1 = b - a, e2 = c - a
            let p = simd_cross(d, e2)
            let det = simd_dot(e1, p)
            guard abs(det) > 1e-12 else { continue }
            let inv = 1 / det
            let s = o - a
            let u = simd_dot(s, p) * inv
            guard u >= -1e-6, u <= 1 + 1e-6 else { continue }
            let q = simd_cross(s, e1)
            let v = simd_dot(d, q) * inv
            guard v >= -1e-6, u + v <= 1 + 1e-6 else { continue }
            let dist = simd_dot(e2, q) * inv
            if dist > 1e-6, dist < (best ?? .infinity) { best = dist }
        }
        return best
    }

    /// Upward and horizontal ray directions (the shells have no floor).
    static let directions: [SIMD3<Double>] = {
        var out: [SIMD3<Double>] = [SIMD3(0, 1, 0)]
        for k in 0..<12 {
            let a = Double(k) / 12 * 2 * .pi + 0.13
            for elev in [0.0, 0.35, 0.9] {
                out.append(simd_normalize(SIMD3(cos(a) * cos(elev), sin(elev), sin(a) * cos(elev))))
            }
        }
        return out
    }()

    /// Rays from interior points that escape without hitting anything: (origin, direction).
    static func leaks(_ g: GeneratedBuilding, footprint: Polygon2D, samples: Int = 12, seed: UInt64 = 1) -> [(SIMD3<Double>, SIMD3<Double>)] {
        let m = g.mesh
        var r = StableRandom(seed, 7, salt: "leak")
        let b = footprint.bounds
        var out: [(SIMD3<Double>, SIMD3<Double>)] = []
        var tries = 0, found = 0
        while found < samples, tries < samples * 40 {
            tries += 1
            let p = LocalPoint(r.range(b.min.x, b.max.x), r.range(b.min.y, b.max.y))
            guard footprint.contains(p), distanceToBoundary(footprint, p) > 0.25 else { continue }
            let base = SIMD3<Double>(LocalFrame.scenePosition(p, y: 0.15))
            guard let up = hit(m, origin: base, dir: SIMD3(0, 1, 0)), up > 0.6 else {
                out.append((base, SIMD3(0, 1, 0)))
                found += 1
                continue
            }
            let o = base + SIMD3(0, r.range(0.1, up - 0.25), 0)
            for d in directions where hit(m, origin: o, dir: d) == nil { out.append((o, d)) }
            found += 1
        }
        return out
    }

    static func distanceToBoundary(_ poly: Polygon2D, _ p: LocalPoint) -> Double {
        var best = Double.infinity
        for ring in [poly.outer] + poly.holes {
            for i in 0..<ring.count {
                let a = ring[i], b = ring[(i + 1) % ring.count]
                let d = b - a
                let t = max(0, min(1, simd_dot(p - a, d) / max(simd_length_squared(d), 1e-12)))
                best = min(best, simd_distance(p, a + d * t))
            }
        }
        return best
    }
}

func testBuilding(_ id: Int64, _ ring: Ring, type: String = "house", tags: [String: String] = [:]) -> Building {
    var t = tags
    t["building"] = type
    let poly = Polygon2D(outer: RingMath.signedArea(ring) < 0 ? ring.reversed() : ring)
    return Building(ref: OSMRef(.way, id), footprint: poly, tags: t, type: type, isPart: false,
                    height: BuildingHeight(base: 0, top: 6, source: .typeDefault))
}

func testContext() -> StreetContext {
    var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 42, longitude: -87.7)),
                        bounds: Rect2D(min: LocalPoint(-200, -200), max: LocalPoint(200, 200)))
    f.roads = [
        WayFeature(ref: OSMRef(.way, 1), kind: .residential, centerline: [LocalPoint(-200, -12), LocalPoint(200, -12)],
                   tags: ["highway": "residential", "name": "Test Street"], width: 9, sidewalkLeft: .unknown, sidewalkRight: .unknown,
                   isCrossing: false, layer: 0, isBridge: false, isTunnel: false),
        WayFeature(ref: OSMRef(.way, 2), kind: .service, centerline: [LocalPoint(-200, 45), LocalPoint(200, 45)],
                   tags: ["highway": "service", "service": "alley"], width: 4, sidewalkLeft: .unknown, sidewalkRight: .unknown,
                   isCrossing: false, layer: 0, isBridge: false, isTunnel: false),
    ]
    return StreetContext(f)
}

@Suite("Building geometry")
struct BuildingGeometryTests {
    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    /// Footprints that exercise the roof planner: arms, notches, bays, non-orthogonal shapes.
    static let footprints: [(String, Ring)] = [
        ("rectangle", rect(0, 0, 12, 9)),
        ("narrow-deep", rect(0, 0, 7.5, 18)),
        ("L", [LocalPoint(0, 0), LocalPoint(14, 0), LocalPoint(14, 6), LocalPoint(6, 6), LocalPoint(6, 12), LocalPoint(0, 12)]),
        ("T", [LocalPoint(0, 4), LocalPoint(4, 4), LocalPoint(4, 0), LocalPoint(9, 0), LocalPoint(9, 4), LocalPoint(13, 4),
               LocalPoint(13, 10), LocalPoint(0, 10)]),
        ("U", [LocalPoint(0, 0), LocalPoint(16, 0), LocalPoint(16, 12), LocalPoint(11, 12), LocalPoint(11, 5), LocalPoint(5, 5),
               LocalPoint(5, 12), LocalPoint(0, 12)]),
        ("front-bay", [LocalPoint(0, 1.2), LocalPoint(3, 1.2), LocalPoint(3, 0), LocalPoint(6, 0), LocalPoint(6, 1.2), LocalPoint(9, 1.2),
                       LocalPoint(9, 14), LocalPoint(0, 14)]),
        ("stepped", [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 5), LocalPoint(12, 5), LocalPoint(12, 11), LocalPoint(3, 11),
                     LocalPoint(3, 8), LocalPoint(0, 8)]),
        ("notched-corner", [LocalPoint(0, 0), LocalPoint(11, 0), LocalPoint(11, 7), LocalPoint(9.5, 7), LocalPoint(9.5, 9),
                            LocalPoint(0, 9)]),
        ("trapezoid", [LocalPoint(0, 0), LocalPoint(12, 0), LocalPoint(11, 9), LocalPoint(1.5, 9)]),
        ("chamfered", [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(12, 2), LocalPoint(12, 10), LocalPoint(0, 10)]),
        ("rotated-L", [LocalPoint(0, 0), LocalPoint(12, 5), LocalPoint(9.7, 10.5), LocalPoint(4.2, 8.2), LocalPoint(1.9, 13.7),
                       LocalPoint(-3.6, 11.4)]),
        ("jittered", [LocalPoint(0, 0), LocalPoint(6.02, 0.03), LocalPoint(12, 0), LocalPoint(12.05, 9.97), LocalPoint(0.04, 10)]),
    ]

    static let profiles = ["evanston", "wilmette", "chicago-dense-north", "front-range"]

    static func generator(_ profile: String) throws -> BuildingGenerator {
        var g = BuildingGenerator(profile: try StyleLibrary.profile(id: profile), context: testContext())
        g.obstacles = PolygonIndex([])
        return g
    }

    @Test(arguments: profiles)
    func everyFootprintEveryLODIsCleanAndSealed(_ profile: String) throws {
        let gen = try Self.generator(profile)
        var palette = Palette(base: try StyleLibrary.baseColors())
        for (name, ring) in Self.footprints {
            for id in Int64(1)...Int64(12) {
                let b = testBuilding(id * 101, ring)
                for lod in BuildingLOD.allCases {
                    let g = gen.generate(b, palette: &palette, lod: lod)
                    let label = "\(profile) \(name) #\(id) \(lod) \(g.family ?? "-") \(g.roofShape) masses=\(g.roofMasses)"
                    #expect(!g.mesh.isEmpty, "\(label)")
                    #expect(GeometryCheck.finite(g.mesh), "\(label)")
                    let bad = GeometryCheck.windingErrors(g.mesh)
                    #expect(bad.isEmpty, "\(label): \(bad.count) inverted triangles")
                    #expect(g.optionalRoofTriangles <= BuildingGenerator.optionalRoofCap, "\(label)")
                    if lod != .skyline, id <= 4 {
                        let leaks = GeometryCheck.leaks(g, footprint: b.footprint, samples: 6, seed: UInt64(id))
                        #expect(leaks.isEmpty, "\(label): \(leaks.count) leaking rays, first \(leaks.first.map { "\($0.0) → \($0.1)" } ?? "")")
                    }
                }
            }
        }
    }

    @Test func sameBuildingSameMeshEveryTime() throws {
        for profile in Self.profiles {
            let gen = try Self.generator(profile)
            for (_, ring) in Self.footprints {
                var p1 = Palette(base: try StyleLibrary.baseColors()), p2 = p1
                let b = testBuilding(777, ring)
                #expect(gen.generate(b, palette: &p1, lod: .near).mesh == gen.generate(b, palette: &p2, lod: .near).mesh)
            }
        }
    }
}

@Suite("Roof envelope")
struct RoofEnvelopeTests {
    static func masses(_ name: String) -> [RoofMass] {
        let main = RoofMass(center: LocalPoint(0, 0), axis: LocalPoint(1, 0), halfLength: 6, halfWidth: 4, form: .gable, pitch: 40, overhang: 0.4, eave: 6)
        switch name {
        case "cross":
            return [main, RoofMass(center: LocalPoint(1, -4), axis: LocalPoint(0, 1), halfLength: 3.5, halfWidth: 2, form: .gable, pitch: 40, overhang: 0.4, eave: 6)]
        case "hip-wing":
            var m = main; m.form = .hip
            return [m, RoofMass(center: LocalPoint(8, 0), axis: LocalPoint(1, 0), halfLength: 3, halfWidth: 2.5, form: .hip, pitch: 30, overhang: 0.5, eave: 6)]
        case "lower-collinear":
            return [main, RoofMass(center: LocalPoint(8.5, 0), axis: LocalPoint(1, 0), halfLength: 3, halfWidth: 2.5, form: .gable, pitch: 30, overhang: 0.3, eave: 6)]
        default:
            return [main]
        }
    }

    @Test(arguments: ["single", "cross", "hip-wing", "lower-collinear"])
    func fragmentsTileTheUnionAndFollowTheHighestRoof(_ name: String) {
        let ms = Self.masses(name)
        let env = RoofEnvelope(masses: ms)
        // Every fragment faces up and lies on the highest roof at its centroid.
        for f in env.fragments {
            #expect(RingMath.signedArea(f.polygon) > 0)
            let c = RingMath.centroid(f.polygon)
            #expect(abs(f.height(c) - (env.height(at: c) ?? -1)) < 1e-6, "\(name)")
        }
        // Coverage without overlap: fragment areas sum to the union of the roof outlines.
        let fragArea = env.fragments.reduce(0) { $0 + RingMath.signedArea($1.polygon) }
        let outlines = ms.map { ConvexClip.halfPlanes($0.domain) }
        var inside = 0, total = 0
        let step = 0.1
        for x in stride(from: -15.0, to: 15.0, by: step) { for y in stride(from: -12.0, to: 12.0, by: step) {
            total += 1
            let p = LocalPoint(x + step / 2, y + step / 2)
            if outlines.contains(where: { hp in hp.allSatisfy { $0(p) >= 0 } }) { inside += 1 }
        } }
        let union = Double(inside) * step * step
        #expect(abs(fragArea - union) / union < 0.01, "\(name): fragments \(fragArea) union \(union)")
    }

    @Test func wallsMeetTheRoofAtEveryPoint() {
        let env = RoofEnvelope(masses: Self.masses("cross"))
        // Profile along the main front wall (y = -4) rises into the crossing gable.
        let spans = env.profile(LocalPoint(-6, -4), LocalPoint(6, -4))
        #expect(spans.first?.t0 == 0 && abs((spans.last?.t1 ?? 0) - 1) < 1e-9)
        for (a, b) in zip(spans, spans.dropFirst()) { #expect(abs(a.t1 - b.t0) < 1e-9 && abs(a.z1 - b.z0) < 1e-6) }
        #expect(spans.map { max($0.z0, $0.z1) }.max()! > 6 + 1.5) // the gable peak
    }
}

@Suite("Building roles and families")
struct BuildingRoleTests {
    static func gen(_ profile: String) throws -> BuildingGenerator {
        BuildingGenerator(profile: try StyleLibrary.profile(id: profile), context: testContext())
    }
    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    @Test func smallBuildingOnTheAlleyIsAGarage() throws {
        let g = try Self.gen("chicago-dense-north")
        // The test alley runs along y = 45; the street along y = -12.
        #expect(g.role(for: testBuilding(1, Self.rect(0, 37, 6, 43), type: "yes")) == .garage)
        #expect(g.role(for: testBuilding(2, Self.rect(0, -6, 6, 0), type: "yes")) == .house)
        // A tagged house is never reclassified.
        #expect(g.role(for: testBuilding(3, Self.rect(0, 37, 6, 43), type: "house")) == .house)
    }

    @Test func largeSuburbanHouseStaysAHouse() throws {
        let g = try Self.gen("evanston")
        let big = testBuilding(4, Self.rect(0, 0, 20, 15), type: "yes") // 300 m²
        #expect(g.role(for: big) == .house)
        #expect(g.role(for: testBuilding(5, Self.rect(0, 0, 30, 20), type: "yes")) == .block) // beyond hugeArea
    }

    @Test func blockFamiliesNeedEvidence() throws {
        let g = try Self.gen("chicago-dense-north")
        func fam(_ b: Building) -> String? { g.blockFamily(for: b, shape: FootprintAnalysis(b.footprint))?.id }
        let r = Self.rect(0, 0, 20, 25)
        #expect(fam(testBuilding(10, r, type: "yes")) == "plainBlock")
        #expect(fam(testBuilding(11, r, type: "apartments")) == "sixFlat")
        #expect(fam(testBuilding(12, r, type: "yes", tags: ["building:levels": "3"])) == "sixFlat")
        #expect(fam(testBuilding(13, r, type: "yes", tags: ["shop": "bakery"])) == "cornerMixedUse")
        #expect(fam(testBuilding(14, r, type: "yes", tags: ["building:levels": "12"])) == "vintageHighRise")
        let court = Building(ref: OSMRef(.way, 15), footprint: Polygon2D(outer: r, holes: [Self.rect(6, 6, 14, 18).reversed()]),
                             tags: ["building": "yes"], type: "yes", isPart: false, height: BuildingHeight(base: 0, top: 9, source: .typeDefault))
        #expect(fam(court) == "courtyardMass")
    }

    @Test func familyIsStableAndFollowsTheProfileMix() throws {
        let g = try Self.gen("evanston")
        var counts: [String: Int] = [:]
        for id in 1...400 {
            let b = testBuilding(Int64(1000 + id), Self.rect(0, 0, 11, 10))
            let shape = FootprintAnalysis(b.footprint)
            let a = g.houseFamily(for: b, shape: shape, frontEdge: 0).0.id
            #expect(a == g.houseFamily(for: b, shape: shape, frontEdge: 0).0.id)
            counts[a, default: 0] += 1
        }
        // Detached-house lottery only: no block family, every profile family appears.
        #expect(counts["plainBlock"] == nil)
        #expect(Set(counts.keys).isSuperset(of: ["tudor", "colonial", "queenAnne"]))
    }
}

/// Facade pass: entry kits stay in front of the door within 1.6 m, inferred bays are shallow,
/// sealed and only where the space in front is clear, details follow the LOD rules.
@Suite("Facade kits")
struct FacadeKitTests {
    static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
        [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
    }

    static func generator(_ profile: String, obstacles: [Polygon2D] = []) throws -> BuildingGenerator {
        var g = BuildingGenerator(profile: try StyleLibrary.profile(id: profile), context: testContext())
        g.obstacles = PolygonIndex(obstacles)
        return g
    }

    /// Vertices standing clear of the walls (beyond wall trim, sills and lintels) between
    /// heights `z0` and `z1`, as local points.
    static func outside(_ m: MeshBuffers, _ fp: Polygon2D, z0: Double, z1: Double) -> [LocalPoint] {
        m.positions.compactMap { p in
            let lp = LocalPoint(Double(p.x), Double(-p.z))
            guard Double(p.y) > z0, Double(p.y) < z1, !fp.contains(lp) else { return nil }
            return GeometryCheck.distanceToBoundary(fp, lp) > 0.16 ? lp : nil
        }
    }

    @Test func entryKitsSitInFrontOfTheDoorWithinTheirDepth() throws {
        let gen = try Self.generator("evanston")
        var palette = Palette(base: try StyleLibrary.baseColors())
        var kits: [String: Int] = [:]
        for id in Int64(1)...Int64(240) {
            let b = testBuilding(5000 + id, Self.rect(0, 0, 12, 9))
            let g = gen.generate(b, palette: &palette, lod: .near)
            guard let kit = g.entryKit, kit != "surround", let e = g.frontEdge else { continue }
            kits[kit, default: 0] += 1
            let (p, dir, n, len) = BuildingGenerator.edge(b.footprint.outer, e)
            // Everything standing in front of the facade above the steps (columns, beam, pediment,
            // vestibule walls and roof, the main eave): along the front wall, at most 1.6 m out
            // (+ the 0.12 m vestibule rake), and the kit itself reaches beyond the eave.
            func front(_ m: MeshBuffers, _ z0: Double, _ z1: Double) -> [(s: Double, t: Double)] {
                Self.outside(m, b.footprint, z0: z0, z1: z1).map { (simd_dot($0 - p, dir), simd_dot($0 - p, n)) }.filter { $0.t > 0.16 }
            }
            let standing = front(g.mesh, 0.6, 5.0)
            #expect(standing.contains { $0.t > 0.98 }, "\(kit) #\(id) has nothing standing in front of the door")
            for q in standing {
                #expect(q.t <= 1.72, "\(kit) #\(id): \(q.t) m out")
                #expect(q.s >= -0.2 && q.s <= len + 0.2, "\(kit) #\(id): \(q.s) along a \(len) m wall")
            }
            // Mid keeps the portico roof and platform, not the columns.
            if kit == "portico" {
                let mid = gen.generate(b, palette: &palette, lod: .mid)
                #expect(front(mid.mesh, 0.6, 2.4).isEmpty, "portico #\(id) has columns at mid")
                #expect(front(mid.mesh, 2.4, 5.0).contains { $0.t > 0.98 }, "portico #\(id) lost its roof at mid")
                #expect(mid.entryKit == "portico")
            }
        }
        #expect((kits["portico"] ?? 0) > 3 && (kits["vestibule"] ?? 0) > 3, "\(kits)")
    }

    @Test func inferredBaysAreShallowSealedAndNeedClearSpace() throws {
        let gen = try Self.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        let ring = Self.rect(0, 0, 8, 18)
        var withBay: [Int64] = []
        for id in Int64(1)...Int64(160) {
            let b = testBuilding(7000 + id, ring)
            let g = gen.generate(b, palette: &palette, lod: .near)
            for bay in g.inferredBays {
                withBay.append(id)
                // Projection ≤ 0.6 m from the street wall (y = 0, facing −y), width 2.4–3.2 m.
                let ys = bay.map(\.y), xs = bay.map(\.x)
                #expect(ys.min()! >= -0.6 - 1e-6 && ys.max()! <= 1e-6, "#\(id) projects \(-ys.min()!) m")
                #expect(xs.max()! - xs.min()! >= 2.4 - 1e-6 && xs.max()! - xs.min()! <= 3.2 + 1e-6, "#\(id) width")
                // Sealed: rays from inside the bay volume always hit something.
                let inside = (bay[0] + bay[1] + bay[2] + bay[3]) / 4
                for z in [0.5, 2.0] {
                    let o = SIMD3<Double>(LocalFrame.scenePosition(inside, y: z))
                    for d in GeometryCheck.directions {
                        #expect(GeometryCheck.hit(g.mesh, origin: o, dir: d) != nil, "#\(id) bay leaks at \(z) m toward \(d)")
                    }
                }
            }
            // Mid keeps the bay mass; far and skyline never have it.
            if !g.inferredBays.isEmpty {
                #expect(gen.generate(b, palette: &palette, lod: .mid).inferredBays.count == g.inferredBays.count)
                #expect(gen.generate(b, palette: &palette, lod: .far).inferredBays.isEmpty)
            }
        }
        #expect(withBay.count >= 10, "only \(withBay.count) inferred bays")
        // A neighbor 1.5 m in front of the facade removes every inferred bay.
        let blocked = try Self.generator("chicago-dense-north", obstacles: [Polygon2D(outer: Self.rect(-5, -4, 13, -1.5))])
        for id in withBay {
            #expect(blocked.generate(testBuilding(7000 + id, ring), palette: &palette, lod: .near).inferredBays.isEmpty, "#\(id)")
        }
    }

    @Test func mappedStreetBaysAreDressed() throws {
        let gen = try Self.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        // Deep city lot with a mapped three-sided bay beside a wider entry face.
        let ring = [LocalPoint(0, 0.6), LocalPoint(0.9, 0.6), LocalPoint(1.5, 0), LocalPoint(3.3, 0), LocalPoint(3.9, 0.6),
                    LocalPoint(8, 0.6), LocalPoint(8, 18), LocalPoint(0, 18)]
        var dressed = 0
        for id in Int64(1)...Int64(40) {
            let g = gen.generate(testBuilding(9000 + id, ring), palette: &palette, lod: .near)
            if g.mappedBays > 0 {
                dressed += 1
                #expect(g.inferredBays.isEmpty, "a mapped bay is never doubled by an inferred one")
            }
        }
        #expect(dressed > 0)
    }
}

/// Side walls (gate gap 5): chimney breasts only on long side walls facing open ground, nothing on
/// walls that touch a neighbour, and gangway walls get one window per story in each stack.
@Suite("Side walls")
struct SideWallTests {
    static let ring = FacadeKitTests.rect(0, 0, 8, 18)
    /// Glass vertices on the side wall at x = `x` (windows sit 0.03 m out from the wall).
    static func glass(_ m: MeshBuffers, x: Double) -> [SIMD3<Float>] {
        zip(m.positions, m.paints).compactMap { p, paint in
            (Int(paint.z) & 1) != 0 && abs(Double(p.x) - x) < 0.1 && -Double(p.z) > 0.3 && -Double(p.z) < 17.7 ? p : nil
        }
    }

    @Test func longSideWallFacingOpenGroundGetsABreast() throws {
        let gen = try FacadeKitTests.generator("chicago-dense-north")
        var palette = Palette(base: try StyleLibrary.baseColors())
        let fp = Polygon2D(outer: Self.ring)
        let chimney = Float(palette.named("chimney"))
        /// Chimney-coloured vertices standing clear of the side walls below `zMax`.
        func breastPoints(_ m: MeshBuffers, below zMax: Double) -> [LocalPoint] {
            zip(m.positions, m.paints).compactMap { p, paint in
                let lp = LocalPoint(Double(p.x), Double(-p.z))
                guard paint.x == chimney, Double(p.y) < zMax, lp.y > 0.5, lp.y < 17.5, !fp.contains(lp) else { return nil }
                return GeometryCheck.distanceToBoundary(fp, lp) > 0.16 ? lp : nil
            }
        }
        var breasts = 0
        for id in Int64(1)...Int64(300) {
            let b = testBuilding(11000 + id, Self.ring)
            let g = gen.generate(b, palette: &palette, lod: .near)
            guard g.chimneyBreast else { continue }
            breasts += 1
            #expect(g.hasChimney)
            // The breast: beside a side wall, 0.25–0.4 m proud, at most 1.8 m wide.
            let side = breastPoints(g.mesh, below: g.eaveHeight - 0.4)
            #expect(!side.isEmpty, "#\(id) breast missing")
            for q in side { #expect(GeometryCheck.distanceToBoundary(fp, q) <= 0.42, "#\(id): \(q) too far out") }
            if let lo = side.map(\.y).min(), let hi = side.map(\.y).max() { #expect(hi - lo <= 1.8 + 1e-6, "#\(id) breast \(hi - lo) m wide") }
            // One chimney: everything above the roof stands at that side wall.
            for p in g.mesh.positions where Double(p.y) > g.topHeight + 0.05 {
                let x = Double(p.x)
                #expect(min(abs(x), abs(x - 8)) < 0.7, "#\(id) second chimney at x = \(x)")
            }
            // Mid keeps the stack, not the projection.
            let mid = gen.generate(b, palette: &palette, lod: .mid)
            #expect(mid.chimneyBreast)
            #expect(breastPoints(mid.mesh, below: mid.eaveHeight - 0.5).isEmpty, "#\(id) mid")
        }
        #expect(breasts >= 5, "only \(breasts) breasts")
    }

    @Test func sideWallTouchingANeighbourGetsNothing() throws {
        let gen = try FacadeKitTests.generator("chicago-dense-north", obstacles: [Polygon2D(outer: FacadeKitTests.rect(-6, 0, 0, 18)),
                                                                                  Polygon2D(outer: FacadeKitTests.rect(8, 0, 14, 18))])
        var palette = Palette(base: try StyleLibrary.baseColors())
        for id in Int64(1)...Int64(300) {
            for lod in [BuildingLOD.near, .mid] {
                let g = gen.generate(testBuilding(11000 + id, Self.ring), palette: &palette, lod: lod)
                #expect(!g.chimneyBreast, "#\(id) breast on a party wall")
                #expect(g.gangwayStacks == 0)
                #expect(Self.glass(g.mesh, x: 0).isEmpty && Self.glass(g.mesh, x: 8).isEmpty, "#\(id) \(lod) windows on a party wall")
            }
        }
    }

    @Test func twoMetreGangwayGetsOneWindowPerFloor() throws {
        let gen = try FacadeKitTests.generator("chicago-dense-north", obstacles: [Polygon2D(outer: FacadeKitTests.rect(-8, 0, -2, 18)),
                                                                                  Polygon2D(outer: FacadeKitTests.rect(10, 0, 16, 18))])
        var palette = Palette(base: try StyleLibrary.baseColors())
        var stacked = 0
        for id in Int64(1)...Int64(120) {
            for lod in [BuildingLOD.near, .mid] {
                let g = gen.generate(testBuilding(11000 + id, Self.ring), palette: &palette, lod: lod)
                #expect(!g.chimneyBreast, "#\(id) breast in a 2 m gangway")
                guard g.gangwayStacks > 0 else { continue }
                stacked += 1
                #expect(g.gangwayStacks >= 2 && g.gangwayStacks <= 4, "#\(id) \(g.gangwayStacks) stacks")
                for x in [0.0, 8.0] {
                    // Each window is one glass quad (4 vertices): stacks × floors quads, two sill/head rows per floor.
                    let v = Self.glass(g.mesh, x: x)
                    let windows = v.count / 4
                    let stacks = windows / max(1, g.floors)
                    let rows = Set(v.map { Int((Double($0.y) * 20).rounded()) })
                    #expect(stacks >= 1 && stacks <= 2 && windows == stacks * g.floors, "#\(id) \(lod) x=\(x): \(windows) windows, \(g.floors) floors")
                    #expect(rows.count == 2 * g.floors, "#\(id) \(lod) x=\(x): \(rows.count) rows")
                }
            }
        }
        #expect(stacked >= 20, "only \(stacked) gangway walls dressed")
    }
}
