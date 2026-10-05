import Foundation
import simd
import Testing
@testable import WorldGeo

@Suite("Coordinates")
struct CoordinateTests {
    let origin = GeoCoordinate(latitude: 39.75, longitude: -105.045)
    var frame: LocalFrame { LocalFrame(origin: origin) }

    @Test func originMapsToZero() {
        let p = frame.localPoint(of: origin)
        #expect(abs(p.x) < 1e-9 && abs(p.y) < 1e-9)
        #expect(frame.scenePosition(of: origin) == SIMD3<Float>(0, 0, 0))
    }

    @Test func thousandthDegreeNorthIsWGS84MeridianArc() {
        // Meridian radius of curvature at 39.75°: M ≈ 6,361,540 m → 0.001° ≈ 111.03 m.
        let p = frame.localPoint(of: GeoCoordinate(latitude: 39.751, longitude: -105.045))
        #expect(abs(p.y - 111.03) < 0.02)
        #expect(abs(p.x) < 0.001)
    }

    @Test func thousandthDegreeEastShrinksWithLatitude() {
        // Prime-vertical radius N·cos(φ) ≈ 4,910,500 m → 0.001° ≈ 85.70 m.
        let p = frame.localPoint(of: GeoCoordinate(latitude: 39.75, longitude: -105.044))
        #expect(abs(p.x - 85.70) < 0.02)
        #expect(abs(p.y) < 0.01)
    }

    @Test(arguments: [
        LocalPoint(0, 0), LocalPoint(1000, 0), LocalPoint(0, -1000), LocalPoint(-750, 600),
        LocalPoint(1500, 1500), LocalPoint(-3, 0.25),
    ])
    func roundTripWithinOneMillimeter(_ p: LocalPoint) {
        let back = frame.localPoint(of: frame.coordinate(at: p))
        #expect(simd_distance(back, p) < 0.001)
    }

    @Test func sceneAxesEastPlusXNorthMinusZ() {
        #expect(LocalFrame.scenePosition(LocalPoint(10, 0)) == SIMD3<Float>(10, 0, 0))
        #expect(LocalFrame.scenePosition(LocalPoint(0, 10)) == SIMD3<Float>(0, 0, -10))
        #expect(LocalFrame.scenePosition(LocalPoint(0, 0), y: 3) == SIMD3<Float>(0, 3, 0))
    }

    @Test func boundingBoxHasRequestedSize() {
        let box = GeoBoundingBox(center: origin, widthMeters: 1600, heightMeters: 1200)
        let sw = frame.localPoint(of: GeoCoordinate(latitude: box.south, longitude: box.west))
        let ne = frame.localPoint(of: GeoCoordinate(latitude: box.north, longitude: box.east))
        #expect(abs(sw.x + 800) < 0.01 && abs(sw.y + 600) < 0.01)
        #expect(abs(ne.x - 800) < 0.01 && abs(ne.y - 600) < 0.01)
        #expect(box.contains(origin))
    }

    @Test func curvatureDropIsSmallAtOneKilometer() {
        let c = frame.coordinate(at: LocalPoint(1000, 0))
        let up = frame.enu(of: c).z
        #expect(up < 0 && up > -0.1) // ~ -8 cm
    }
}

@Suite("Polygons")
struct PolygonTests {
    let square: Ring = [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 10), LocalPoint(0, 10)]

    @Test func signedAreaIsPositiveForCounterClockwise() {
        #expect(RingMath.signedArea(square) == 100)
        #expect(RingMath.signedArea(square.reversed()) == -100)
    }

    @Test func centroidAndContains() {
        #expect(simd_distance(RingMath.centroid(square), LocalPoint(5, 5)) < 1e-9)
        #expect(RingMath.contains(square, LocalPoint(5, 5)))
        #expect(!RingMath.contains(square, LocalPoint(11, 5)))
    }

    @Test func cleanedOrientsRingsAndKeepsHoles() throws {
        let hole: Ring = [LocalPoint(4, 4), LocalPoint(6, 4), LocalPoint(6, 6), LocalPoint(4, 6)] // CCW in
        let p = try #require(Polygon2D(outer: square.reversed(), holes: [hole]).cleaned())
        #expect(RingMath.signedArea(p.outer) > 0)
        #expect(RingMath.signedArea(p.holes[0]) < 0)
        #expect(p.area == 96)
        #expect(p.contains(LocalPoint(1, 1)))
        #expect(!p.contains(LocalPoint(5, 5)))
    }

    @Test func cleanedDropsClosingDuplicatesAndCollinearPoints() throws {
        let messy: Ring = [
            LocalPoint(0, 0), LocalPoint(5, 0), LocalPoint(10, 0), LocalPoint(10, 0.004),
            LocalPoint(10, 10), LocalPoint(0, 10), LocalPoint(0, 0),
        ]
        let p = try #require(Polygon2D(outer: messy).cleaned())
        #expect(p.outer.count == 4)
        #expect(abs(p.area - 100) < 1e-9)
    }

    @Test func cleanedRejectsTinyOrDegenerateRings() {
        #expect(Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(0.5, 0), LocalPoint(0.5, 0.5)]).cleaned() == nil)
        #expect(Polygon2D(outer: [LocalPoint(0, 0), LocalPoint(5, 0), LocalPoint(10, 0)]).cleaned() == nil)
        let tinyHole = Polygon2D(outer: square, holes: [[LocalPoint(1, 1), LocalPoint(1.1, 1), LocalPoint(1.1, 1.1)]])
        #expect(tinyHole.cleaned()?.holes.isEmpty == true)
    }
}

@Suite("Clipping")
struct ClippingTests {
    let rect = Rect2D(min: LocalPoint(0, 0), max: LocalPoint(10, 10))

    @Test func polygonPartlyOutsideIsCutToTheBox() throws {
        let p = Polygon2D(outer: [LocalPoint(5, 5), LocalPoint(15, 5), LocalPoint(15, 15), LocalPoint(5, 15)])
        let c = try #require(Clipping.clip(p, to: rect))
        #expect(abs(c.area - 25) < 1e-9)
    }

    @Test func polygonInsideIsUnchangedAndOutsideIsDropped() {
        let inside = Polygon2D(outer: [LocalPoint(1, 1), LocalPoint(2, 1), LocalPoint(2, 2)])
        #expect(Clipping.clip(inside, to: rect) == inside)
        let outside = Polygon2D(outer: [LocalPoint(20, 20), LocalPoint(30, 20), LocalPoint(30, 30)])
        #expect(Clipping.clip(outside, to: rect) == nil)
    }

    @Test func concaveLakeShapeKeepsCorrectArea() throws {
        // A "U" crossing the right edge: the two arms leave the box.
        let u = Polygon2D(outer: [
            LocalPoint(2, 2), LocalPoint(14, 2), LocalPoint(14, 4), LocalPoint(4, 4),
            LocalPoint(4, 6), LocalPoint(14, 6), LocalPoint(14, 8), LocalPoint(2, 8),
        ])
        let c = try #require(Clipping.clip(u, to: rect))
        // Inside the box: 8×2 (bottom arm) + 8×2 (top arm) + 2×2 (spine middle) = 36.
        #expect(abs(c.area - 36) < 1e-9)
    }

    @Test func polylineLeavingAndReenteringSplitsIntoPieces() {
        let line = [LocalPoint(-5, 5), LocalPoint(5, 5), LocalPoint(5, 15), LocalPoint(8, 15), LocalPoint(8, 5)]
        let pieces = Clipping.clip(polyline: line, to: rect)
        #expect(pieces.count == 2)
        #expect(pieces[0] == [LocalPoint(0, 5), LocalPoint(5, 5), LocalPoint(5, 10)])
        #expect(pieces[1] == [LocalPoint(8, 10), LocalPoint(8, 5)])
    }

    @Test func polylineFullyOutsideIsDropped() {
        #expect(Clipping.clip(polyline: [LocalPoint(-5, -5), LocalPoint(-1, -8)], to: rect).isEmpty)
    }
}

@Suite("Determinism")
struct StableRandomTests {
    @Test func sameInputsGiveSameSequence() {
        var a = StableRandom(2, 123_456, salt: "roof-color")
        var b = StableRandom(2, 123_456, salt: "roof-color")
        for _ in 0..<100 { #expect(a.next() == b.next()) }
    }

    @Test func saltsAndIDsAreIndependent() {
        var a = StableRandom(2, 123_456, salt: "roof-color")
        var b = StableRandom(2, 123_456, salt: "door-color")
        var c = StableRandom(2, 123_457, salt: "roof-color")
        let x = a.next()
        #expect(x != b.next())
        #expect(x != c.next())
    }

    /// Golden value: fails if the generator ever changes, which would change every generated
    /// house on every device.
    @Test func goldenValue() {
        var r = StableRandom(2, 42, salt: "golden")
        #expect(r.next() == StableRandomTests.golden)
    }

    static let golden: UInt64 = 6_800_808_780_219_071_596

    @Test func unitIsInRange() {
        var r = StableRandom(seed: 7)
        for _ in 0..<1000 {
            let u = r.unit()
            #expect(u >= 0 && u < 1)
        }
    }
}
