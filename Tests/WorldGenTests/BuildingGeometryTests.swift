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
