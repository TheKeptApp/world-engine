import Foundation
import simd
import Testing
@testable import WorldGeo
@testable import WorldMap

@Suite("Tag parsing")
struct TagParsingTests {
    @Test(arguments: [
        ("12", 12.0), ("12 m", 12.0), ("12.5m", 12.5), ("12,5", 12.5), ("7 metres", 7.0),
        ("40'", 12.192), ("40'6\"", 12.3444), ("40 ft", 12.192), ("9;12", 9.0),
    ])
    func lengths(_ raw: String, _ meters: Double) throws {
        let v = try #require(TagParsing.length(raw))
        #expect(abs(v - meters) < 0.0001)
    }

    @Test(arguments: ["tall", "", "-5", "0", "12 km", "5000"])
    func badLengthsAreRejected(_ raw: String) {
        #expect(TagParsing.length(raw) == nil)
    }

    @Test func numbers() {
        #expect(TagParsing.number("3") == 3)
        #expect(TagParsing.number("2.5") == 2.5)
        #expect(TagParsing.number("2;3") == 2)
        #expect(TagParsing.number("lots") == nil)
    }
}

@Suite("Height fallback")
struct HeightRuleTests {
    let rules = HeightRules()
    let ref = OSMRef(.way, 12345)

    @Test func heightTagWinsAndIsNotJittered() {
        let h = rules.resolve(tags: ["height": "12", "building:levels": "10"], type: "house", ref: ref)
        #expect(h.top == 12 && h.base == 0 && h.source == .heightTag)
        #expect(rules.resolve(tags: ["height": "40'"], type: "yes", ref: ref).top == 12.192)
    }

    @Test func garbageHeightFallsThroughToLevels() {
        let h = rules.resolve(tags: ["height": "tall", "building:levels": "3"], type: "house", ref: ref)
        #expect(h.source == .levels)
        #expect(h.top >= 9.6 * 0.9 && h.top <= 9.6 * 1.1)
    }

    @Test func levelsPlusRoofLevels() {
        let h = rules.resolve(tags: ["building:levels": "2", "roof:levels": "1"], type: "house", ref: ref)
        #expect(h.top >= 9.6 * 0.9 && h.top <= 9.6 * 1.1)
    }

    @Test(arguments: [("house", 7.0), ("garage", 3.0), ("shed", 2.5), ("apartments", 12.8),
                      ("commercial", 5.0), ("office", 10.0), ("yes", 6.0), ("unknown_type", 6.0)])
    func typeDefaults(_ type: String, _ meters: Double) {
        let h = rules.resolve(tags: [:], type: type, ref: ref)
        #expect(h.source == .typeDefault)
        #expect(h.top >= meters * 0.9 && h.top <= meters * 1.1)
    }

    @Test func minHeightLiftsBase() {
        let h = rules.resolve(tags: ["height": "20", "min_height": "5"], type: "yes", ref: ref)
        #expect(h.base == 5 && h.top == 20)
        let lvl = rules.resolve(tags: ["building:levels": "4", "building:min_level": "2"], type: "yes", ref: ref)
        #expect(abs(lvl.base - 6.4) < 1e-9)
    }

    @Test func jitterIsDeterministicAndVariesByBuilding() {
        let a = rules.resolve(tags: [:], type: "house", ref: OSMRef(.way, 1))
        let a2 = rules.resolve(tags: [:], type: "house", ref: OSMRef(.way, 1))
        let tops = (1...50).map { rules.resolve(tags: [:], type: "house", ref: OSMRef(.way, Int64($0))).top }
        #expect(a == a2)
        #expect(Set(tops).count > 40)
        #expect(tops.allSatisfy { $0 >= 6.3 && $0 <= 7.7 })
    }
}

@Suite("Road widths")
struct RoadRuleTests {
    let rules = RoadRules()

    @Test func widthTagThenLanesThenDefault() {
        #expect(rules.width(kind: .residential, tags: ["width": "9"]) == 9)
        #expect(abs(rules.width(kind: .primary, tags: ["lanes": "4"]) - 13.2) < 1e-9)
        #expect(rules.width(kind: .residential, tags: [:]) == 6)
        #expect(rules.width(kind: .footway, tags: ["lanes": "2"]) == 2) // lanes ignored on paths
    }

    @Test func linkRoadsUseTheirBaseKind() {
        #expect(HighwayKind(tag: "primary_link") == .primary)
        #expect(HighwayKind(tag: "nonsense") == .other)
    }

    @Test func sidewalkTags() {
        #expect(MapFeatureBuilder.sidewalks(["sidewalk": "both"]) == (.tagged, .tagged))
        #expect(MapFeatureBuilder.sidewalks(["sidewalk": "right"]) == (.none, .tagged))
        #expect(MapFeatureBuilder.sidewalks(["sidewalk:both": "separate"]) == (.separate, .separate))
        #expect(MapFeatureBuilder.sidewalks(["sidewalk": "both", "sidewalk:left": "no"]) == (.none, .tagged))
        #expect(MapFeatureBuilder.sidewalks([:]) == (.unknown, .unknown))
    }
}

@Suite("Ring assembly")
struct RingAssemblyTests {
    @Test func joinsSplitAndReversedWays() throws {
        let rings = try #require(MultipolygonAssembler.joinRings([[1, 2, 3], [5, 4, 3], [5, 6, 1]]))
        #expect(rings.count == 1)
        #expect(rings[0].count == 7)
        #expect(rings[0].first == rings[0].last)
        #expect(Set(rings[0]) == [1, 2, 3, 4, 5, 6])
    }

    @Test func unclosedChainFails() {
        #expect(MultipolygonAssembler.joinRings([[1, 2, 3], [3, 4]]) == nil)
    }
}

@Suite("Feature building from a fixture")
struct FixtureTests {
    static func features() throws -> MapFeatures {
        let url = try #require(Bundle.module.url(forResource: "small-area", withExtension: "json", subdirectory: "Fixtures"))
        let doc = try OSMDocument(overpassJSON: try Data(contentsOf: url))
        let builder = MapFeatureBuilder(center: GeoCoordinate(latitude: 40, longitude: -105), widthMeters: 200, heightMeters: 200)
        return builder.build(doc)
    }

    @Test func parsesTimestampAndElementCounts() throws {
        let f = try Self.features()
        #expect(f.report.wayCount == 11)
        #expect(f.report.relationCount == 2)
    }

    @Test func buildingsIncludingCourtyard() throws {
        let f = try Self.features()
        #expect(f.buildings.count == 2)
        let house = try #require(f.buildings.first { $0.type == "house" })
        #expect(house.ref == OSMRef(.way, 100))
        #expect(house.height.source == .typeDefault)
        #expect(abs(house.footprint.area - 17.07 * 11.10) < 2)
        let apt = try #require(f.buildings.first { $0.type == "apartments" })
        #expect(apt.ref == OSMRef(.relation, 300))
        #expect(apt.footprint.holes.count == 1)
        #expect(apt.height.source == .levels)
        #expect(RingMath.signedArea(apt.footprint.outer) > 0)
        #expect(RingMath.signedArea(apt.footprint.holes[0]) < 0)
    }

    @Test func roadsArePathsAndSidewalksAreSeparated() throws {
        let f = try Self.features()
        #expect(f.roads.count == 1 && f.paths.count == 1 && f.sidewalks.count == 1)
        let road = f.roads[0]
        #expect(road.kind == .residential && road.width == 6)
        #expect(road.sidewalkLeft == .tagged && road.sidewalkRight == .tagged)
        // Starts 256 m west, so it's clipped at the area's west edge.
        #expect(abs(road.centerline[0].x + 100) < 1e-6)
        #expect(f.paths[0].kind == .path)
    }

    @Test func areasAreClippedToBounds() throws {
        let f = try Self.features()
        #expect(f.areas(of: .park).count == 1)
        let water = try #require(f.areas(of: .water).first)
        #expect(water.ref == OSMRef(.relation, 500))
        #expect(water.polygon.bounds.max.x <= 100 + 1e-9 && water.polygon.bounds.max.y <= 100 + 1e-9)
    }

    @Test func pointsInsideBoundsOnly() throws {
        let f = try Self.features()
        #expect(f.points(of: .tree).count == 1) // the second tree is 333 m north
        #expect(f.points(of: .bench).count == 2) // one node, one way
        #expect(f.points(of: .bench).contains { $0.fromWay })
        #expect(f.points(of: .streetLamp).count == 1)
    }

    @Test func brokenWayIsSkippedAndReported() throws {
        let f = try Self.features()
        #expect(f.report.skipped.map(\.ref) == [OSMRef(.way, 700)])
    }

    @Test func mergingDocumentsDeduplicatesByID() throws {
        let url = try #require(Bundle.module.url(forResource: "small-area", withExtension: "json", subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        var doc = try OSMDocument(overpassJSON: data)
        let once = doc.ways.count
        doc.merge(try OSMDocument(overpassJSON: data))
        #expect(doc.ways.count == once)
    }
}

/// Runs against the committed Sloan's Lake extract. Ranges, not exact counts, so a future
/// re-fetch with small OSM edits still passes.
@Suite("Real area data")
struct RealAreaTests {
    static let areaDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/areas/sloans-lake")

    @Test(.enabled(if: FileManager.default.fileExists(atPath: areaDir.appendingPathComponent("manifest.json").path)))
    func loadsWithFewSkips() throws {
        let f = try AreaLoader.loadFeatures(Self.areaDir)
        #expect((1_200...1_700).contains(f.buildings.count))
        #expect(f.points(of: .tree).count > 4_000)
        #expect(f.roads.count > 100 && f.paths.count > 100 && f.sidewalks.count > 100)
        let water = f.areas(of: .water).reduce(0) { $0 + $1.polygon.area }
        #expect(water > 500_000)
        let total = f.buildings.count + f.roads.count + f.paths.count + f.areas.count
        #expect(Double(f.report.skipped.count) < Double(total) * 0.01)
    }
}
