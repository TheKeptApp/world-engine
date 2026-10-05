import simd
import Testing
@testable import WorldGeo
@testable import WorldMesh

private func triangleArea(_ v: [LocalPoint], _ idx: [Int]) -> (total: Double, minSigned: Double) {
    var total = 0.0, minSigned = Double.infinity
    for t in stride(from: 0, to: idx.count, by: 3) {
        let a = RingMath.cross(v[idx[t + 1]] - v[idx[t]], v[idx[t + 2]] - v[idx[t]]) / 2
        total += a
        minSigned = min(minSigned, a)
    }
    return (total, minSigned)
}

private func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Ring {
    [LocalPoint(x0, y0), LocalPoint(x1, y0), LocalPoint(x1, y1), LocalPoint(x0, y1)]
}

@Suite("Triangulation")
struct TriangulationTests {
    @Test func squareIsTwoTriangles() {
        let r = Earcut.triangulate(Polygon2D(outer: rect(0, 0, 10, 10)))
        #expect(r.indices.count == 6)
        let a = triangleArea(r.vertices, r.indices)
        #expect(abs(a.total - 100) < 1e-9)
        #expect(a.minSigned > 0) // all counter-clockwise → face up in scene space
    }

    @Test func clockwiseInputStillComesOutCounterClockwise() {
        let r = Earcut.triangulate(Polygon2D(outer: rect(0, 0, 10, 10).reversed()))
        #expect(triangleArea(r.vertices, r.indices).minSigned > 0)
    }

    @Test func squareWithSquareHole() throws {
        let p = try #require(Polygon2D(outer: rect(0, 0, 10, 10), holes: [rect(3, 3, 7, 7)]).cleaned())
        let r = Earcut.triangulate(p)
        #expect(r.indices.count == 8 * 3)
        let a = triangleArea(r.vertices, r.indices)
        #expect(abs(a.total - 84) < 1e-9)
        #expect(a.minSigned > 0)
    }

    @Test(arguments: [
        // L-shape
        Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 4), LocalPoint(4, 4), LocalPoint(4, 10), LocalPoint(0, 10)]),
        // U-shape
        Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(12, 0), LocalPoint(12, 10), LocalPoint(8, 10), LocalPoint(8, 4),
                          LocalPoint(4, 4), LocalPoint(4, 10), LocalPoint(0, 10)]),
        // Courtyard building with two courtyards
        Polygon2D(outer: rect(0, 0, 30, 12), holes: [rect(3, 3, 9, 9).reversed(), rect(18, 3, 27, 9).reversed()]),
        // Courtyard touching nothing but with a notch in the outer ring
        Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(20, 0), LocalPoint(20, 20), LocalPoint(12, 20), LocalPoint(10, 15),
                          LocalPoint(8, 20), LocalPoint(0, 20)], holes: [rect(5, 4, 15, 10).reversed()]),
    ])
    func shapesKeepTheirArea(_ polygon: Polygon2D) throws {
        let p = try #require(polygon.cleaned())
        let r = try #require(Triangulator.triangulate(p))
        let a = triangleArea(r.vertices, r.indices)
        #expect(abs(a.total - p.area) < 1e-6)
        #expect(a.minSigned > 0)
    }

    @Test func degenerateInputsDontCrash() {
        // Repeated closing point and collinear points.
        let r = Earcut.triangulate(Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(5, 0), LocalPoint(10, 0), LocalPoint(10, 10),
                                                     LocalPoint(0, 10), LocalPoint(0, 0)]))
        #expect(abs(triangleArea(r.vertices, r.indices).total - 100) < 1e-9)
        // Zero area.
        #expect(Earcut.triangulate(Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(5, 0), LocalPoint(10, 0)])).indices.isEmpty)
        // Fewer than three points.
        #expect(Earcut.triangulate([0, 0, 1, 1]).isEmpty)
        #expect(Earcut.triangulate([]).isEmpty)
    }

    @Test func selfIntersectingRingIsRejected() {
        let bowtie = Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(10, 10), LocalPoint(10, 0), LocalPoint(0, 10)])
        #expect(Triangulator.triangulate(bowtie) == nil)
    }

    /// 1,000 random star-shaped polygons, half with a hole. Vertices are evenly spaced in angle
    /// with jitter, so every gap is under 110°: the origin is in the polygon's kernel (simple by
    /// construction) and every edge stays at least 11 m from the origin, clear of the hole.
    @Test func fuzzAreaConservation() {
        var rng = StableRandom(seed: 2026)
        var failures = 0
        for i in 0..<1000 {
            let n = 6 + Int(rng.unit() * 60)
            let step = 2 * Double.pi / Double(n)
            let outer: Ring = (0..<n).map { k in
                let a = Double(k) * step + rng.range(-0.4, 0.4) * step
                let r = rng.range(20, 100)
                return LocalPoint(cos(a) * r, sin(a) * r)
            }
            // A small rotated square (max radius 5.8 m) around the origin.
            let holes: [Ring] = i % 2 == 0 ? [] : [[LocalPoint(-5, -3), LocalPoint(-3, 5), LocalPoint(5, 3), LocalPoint(3, -5)].reversed()]
            guard let p = Polygon2D(outer: outer, holes: holes).cleaned() else { continue }
            let r = Earcut.triangulate(p)
            let a = triangleArea(r.vertices, r.indices)
            if abs(a.total - p.area) / p.area > 0.001 || a.minSigned < -1e-9 { failures += 1 }
        }
        #expect(failures == 0)
    }
}

@Suite("Extrusion")
struct ExtrusionTests {
    @Test func boxHasEightWallTrianglesAndTwoRoofTriangles() throws {
        let m = try #require(Extrusion.extrude(Polygon2D(outer: rect(0, 0, 10, 10)), base: 0, top: 6))
        #expect(m.triangleCount == 10)
        #expect(m.vertexCount == 4 + 4 * 4) // roof shares 4; each wall quad has its own 4 (flat shading)
        let b = try #require(m.bounds)
        #expect(b.min == SIMD3<Float>(0, 0, -10) && b.max == SIMD3<Float>(10, 6, 0))
        #expect(abs(m.surfaceArea - (100 + 4 * 60)) < 1e-3)
    }

    @Test func normalsPointOutwardAndMatchWinding() throws {
        let m = try #require(Extrusion.extrude(Polygon2D(outer: rect(0, 0, 10, 10)), base: 0, top: 6))
        let center = SIMD3<Float>(5, 3, -5)
        for t in 0..<m.triangleCount {
            let n = m.normals[Int(m.indices[t * 3])]
            let face = simd_normalize(m.faceCross(t))
            #expect(simd_dot(face, n) > 0.999) // winding agrees with the stored normal
            let p = m.positions[Int(m.indices[t * 3])]
            if n.y > 0.5 {
                #expect(n == SIMD3<Float>(0, 1, 0))
            } else {
                #expect(simd_dot(n, p - center) > 0) // wall faces away from the building
            }
        }
    }

    @Test func courtyardWallsFaceIntoTheCourtyard() throws {
        let fp = try #require(Polygon2D(outer: rect(0, 0, 20, 20), holes: [rect(8, 8, 12, 12)]).cleaned())
        let m = try #require(Extrusion.extrude(fp, base: 0, top: 9))
        #expect(m.triangleCount == 8 + 8 + 8) // outer walls + courtyard walls + roof with hole
        let courtyardCenter = SIMD3<Float>(10, 4.5, -10)
        var courtyardWalls = 0
        for t in 0..<m.triangleCount {
            let n = m.normals[Int(m.indices[t * 3])]
            guard n.y == 0 else { continue }
            let a = m.positions[Int(m.indices[t * 3])], b = m.positions[Int(m.indices[t * 3 + 1])], c = m.positions[Int(m.indices[t * 3 + 2])]
            let mid = (a + b + c) / 3
            if simd_distance(SIMD2(mid.x, mid.z), SIMD2(10, -10)) < 3 {
                courtyardWalls += 1
                #expect(simd_dot(n, courtyardCenter - mid) > 0)
            }
            #expect(simd_dot(simd_normalize(m.faceCross(t)), n) > 0.999)
        }
        #expect(courtyardWalls == 8)
        #expect(abs(m.surfaceArea - (384 + 80 * 9 + 16 * 9)) < 1e-2)
    }

    @Test func liftedBaseAndInvalidHeights() throws {
        let m = try #require(Extrusion.extrude(Polygon2D(outer: rect(0, 0, 4, 4)), base: 2.5, top: 3))
        #expect(m.bounds?.min.y == 2.5)
        #expect(Extrusion.extrude(Polygon2D(outer: rect(0, 0, 4, 4)), base: 3, top: 3) == nil)
    }

    @Test func clockwiseFootprintIsReoriented() throws {
        let m = try #require(Extrusion.extrude(Polygon2D(outer: rect(0, 0, 10, 10).reversed()), base: 0, top: 6))
        for t in 0..<m.triangleCount {
            #expect(simd_dot(simd_normalize(m.faceCross(t)), m.normals[Int(m.indices[t * 3])]) > 0.999)
        }
    }
}

@Suite("Ribbons")
struct RibbonTests {
    func allFaceUp(_ m: MeshBuffers) -> Bool {
        (0..<m.triangleCount).allSatisfy { m.faceCross($0).y > 0 }
    }

    @Test func straightRoadIsARectangle() throws {
        let m = Ribbon.build([LocalPoint(0, 0), LocalPoint(100, 0)], width: 6, y: 0.05)
        #expect(m.triangleCount == 2)
        #expect(abs(m.surfaceArea - 600) < 1e-3)
        let b = try #require(m.bounds)
        #expect(b.min == SIMD3<Float>(0, 0.05, -3) && b.max == SIMD3<Float>(100, 0.05, 3))
        #expect(allFaceUp(m))
    }

    @Test func rightAngleTurnIsMitered() {
        let m = Ribbon.build([LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 10)], width: 2, y: 0)
        #expect(m.triangleCount == 4)
        #expect(abs(m.surfaceArea - 40) < 1e-3) // miter joins keep area = length × width
        #expect(m.positions.contains(SIMD3<Float>(11, 0, 1))) // outer corner (east 11, north −1)
        #expect(allFaceUp(m))
    }

    @Test func hairpinIsBeveled() {
        let m = Ribbon.build([LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(0, 0.5)], width: 2, y: 0)
        #expect(m.triangleCount == 5) // two segments + one bevel triangle
        #expect(m.positions.allSatisfy { !$0.x.isNaN && !$0.z.isNaN })
        #expect(allFaceUp(m))
    }

    @Test func duplicatePointsAreIgnored() {
        let clean = Ribbon.build([LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 10)], width: 2, y: 0)
        let dup = Ribbon.build([LocalPoint(0, 0), LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 0), LocalPoint(10, 10)], width: 2, y: 0)
        #expect(clean == dup)
    }

    @Test func tooShortInputIsEmpty() {
        #expect(Ribbon.build([LocalPoint(1, 1)], width: 2, y: 0).isEmpty)
        #expect(Ribbon.build([LocalPoint(1, 1), LocalPoint(1, 1)], width: 2, y: 0).isEmpty)
        #expect(Ribbon.build([LocalPoint(0, 0), LocalPoint(1, 0)], width: 0, y: 0).isEmpty)
    }

    @Test func capFacesUp() throws {
        let m = try #require(Triangulator.cap(Polygon2D(outer: rect(0, 0, 5, 5)), y: 0.02))
        #expect(allFaceUp(m))
        #expect(abs(m.surfaceArea - 25) < 1e-4)
    }
}
