import Foundation
import simd
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap
@testable import WorldMesh

/// Road paint (infrastructure-kit-v1 stage 1): lane lines and crosswalks from tags.
@Suite("Road markings")
struct RoadMarkingsTests {
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let values = MarkingValues.bundled!
    static let tuning = LookSpec.bundled!.markings!

    static func road(_ id: Int64, _ kind: HighwayKind, _ line: [LocalPoint], width: Double? = nil, tags extra: Tags = [:]) -> WayFeature {
        var tags = extra
        tags["highway"] = kind.rawValue
        return WayFeature(ref: OSMRef(.way, id), kind: kind, centerline: line, tags: tags,
                          width: width ?? RoadRules().width(kind: kind, tags: tags),
                          sidewalkLeft: .unknown, sidewalkRight: .unknown, isCrossing: false, layer: 0, isBridge: false, isTunnel: false)
    }

    static func crossing(_ id: Int64, _ line: [LocalPoint], tags extra: Tags) -> WayFeature {
        var tags = extra
        tags["highway"] = "footway"; tags["footway"] = "crossing"
        return WayFeature(ref: OSMRef(.way, id), kind: .footway, centerline: line, tags: tags, width: 2,
                          sidewalkLeft: .unknown, sidewalkRight: .unknown, isCrossing: true, layer: 0, isBridge: false, isTunnel: false)
    }

    static func build(roads: [WayFeature], paths: [WayFeature] = [], points: [PointFeature] = []) -> RoadMarkings.Output {
        var f = MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 41.94, longitude: -87.66)),
                            bounds: Rect2D(min: LocalPoint(-300, -300), max: LocalPoint(300, 300)))
        f.roads = roads; f.paths = paths; f.points = points
        return RoadMarkings(features: f, values: values, tuning: tuning).build()
    }

    static let eastWest = [LocalPoint(-100, 0), LocalPoint(100, 0)]

    // MARK: - Values

    /// Every look.json copy equals the pack JSON at its key path, and every key the loader reads is copied.
    @Test func lookCopyEqualsThePack() throws {
        let pack = try JSONSerialization.jsonObject(with: Data(contentsOf: Self.root
            .appendingPathComponent("docs/proposals/infrastructure-kit-v1/infrastructure-values.json")))
        func at(_ path: String) -> Any? {
            var o: Any? = pack
            let scanner = path.replacingOccurrences(of: "[", with: ".[").split(separator: ".")
            for part in scanner {
                if part.hasPrefix("[") { o = (o as? [Any]).flatMap { a in Int(part.dropFirst().dropLast()).flatMap { $0 < a.count ? a[$0] : nil } } }
                else { o = (o as? [String: Any])?[String(part)] }
            }
            return o
        }
        let copy = try #require(LookSpec.bundled?.infrastructure)
        #expect(!copy.entries.isEmpty)
        for e in copy.entries {
            #expect(e.source.hasPrefix("infrastructure-kit-v1/"))
            let v = at(String(e.source.dropFirst("infrastructure-kit-v1/".count)))
            if let n = e.number { #expect((v as? NSNumber)?.doubleValue == n, "\(e.source)") }
            else { #expect(v as? String == e.string, "\(e.source)") }
        }
        for k in MarkingValues.keys {
            #expect(copy.entries.contains { $0.source == k.key }, "\(k.key) not copied")
            // The asset at that index is the one the key is meant for.
            let assetPath = k.key.dropFirst("infrastructure-kit-v1/".count).split(separator: "]")[0] + "].id"
            #expect(at(String(assetPath)) as? String == k.asset, "\(k.key)")
        }
    }

    /// A compiled mock value wins over the look.json copy.
    @Test func mockValuesWinOverTheCopy() throws {
        let key = MarkingValues.keys[0].key
        let mock = MockValues(strings: [:], numbers: [key: 0.2])
        let v = try #require(MarkingValues(mock: mock, copy: LookSpec.bundled?.infrastructure))
        #expect(v.lineWidth == 0.2)
        #expect(MarkingValues(mock: mock, copy: nil) == nil)
    }

    // MARK: - Lane lines

    @Test func twoWayFourLaneArterialHasDoubleYellowAndOneDividerPerDirection() {
        let r = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "4"])
        let lay = RoadMarkings(features: MapFeatures(frame: LocalFrame(origin: GeoCoordinate(latitude: 0, longitude: 0)), bounds: Rect2D(min: .zero, max: .zero)),
                               values: Self.values, tuning: Self.tuning).layout(r)
        #expect(lay.forward == 2 && lay.backward == 2 && lay.longitudinal && !lay.inferredLanes)
        let out = Self.build(roads: [r])
        let centre = out.marks.filter { $0.role == .centre }
        #expect(centre.count == 2 && centre.allSatisfy { $0.colour == .yellow })
        // The pair straddles the centre, doubleLineGap apart between the lines' inner edges.
        let ys = centre.map { $0.line[0].y }.sorted()
        #expect(abs((ys[1] - ys[0]) - (Self.values.doubleLineGap + Self.values.lineWidth)) < 1e-9)
        let dashes = out.marks.filter { $0.role == .laneDivider }
        #expect(dashes.allSatisfy { $0.colour == .white && abs(Polyline.length($0.line) - Self.values.dashLength) < 1e-6 })
        // Two dividers over 200 m at 3 m + 9 m: 17 dashes each.
        let period = Self.values.dashLength + Self.values.dashGap
        #expect(dashes.count == 2 * (Int((200 - Self.values.dashLength) / period) + 1))
        #expect(Set(dashes.map { $0.line[0].y > 0 }).count == 2)
    }

    @Test func oneWayArterialHasWhiteDividersOnly() {
        let out = Self.build(roads: [Self.road(1, .secondary, Self.eastWest, tags: ["lanes": "3", "oneway": "yes"])])
        #expect(out.marks.allSatisfy { $0.colour == .white })
        #expect(Set(out.marks.filter { $0.role == .laneDivider }.map { ($0.line[0].y * 100).rounded() }).count == 2)
    }

    @Test func untaggedArterialLaneCountIsInferredFromWidth() {
        let r = Self.road(1, .secondary, Self.eastWest, width: 14, tags: ["parking:both": "no"])
        let out = Self.build(roads: [r])
        #expect(out.marks.contains { $0.role == .centre && $0.inferred })
        // 14 m / 3.3 m lanes: two per direction.
        #expect(Set(out.marks.filter { $0.role == .laneDivider }.map { ($0.line[0].y * 100).rounded() }).count == 2)
    }

    @Test func localStreetsAlleysAndServiceRoadsStayUnpaintedUnlessTagged() {
        #expect(Self.build(roads: [Self.road(1, .residential, Self.eastWest, tags: ["lanes": "2"])]).marks.isEmpty)
        #expect(Self.build(roads: [Self.road(1, .service, Self.eastWest, tags: ["lanes": "2", "service": "alley"])]).marks.isEmpty)
        #expect(Self.build(roads: [Self.road(1, .tertiary, Self.eastWest)]).marks.isEmpty)
        #expect(Self.build(roads: [Self.road(1, .primary, Self.eastWest, tags: ["lane_markings": "no"])]).marks.isEmpty)
        #expect(Self.build(roads: [Self.road(1, .residential, Self.eastWest, tags: ["lane_markings": "yes"])]).marks.contains { $0.role == .centre })
        #expect(Self.build(roads: [Self.road(1, .tertiary, Self.eastWest, tags: ["lanes": "2"])]).marks.contains { $0.role == .centre })
    }

    @Test func taggedBikeLaneSitsBetweenParkingAndTraffic() {
        let r = Self.road(1, .secondary, Self.eastWest, tags: ["lanes": "2", "cycleway:right": "lane", "parking:right": "lane"])
        let out = Self.build(roads: [r])
        let bike = out.marks.filter { $0.role == .bikeLane }
        #expect(bike.count == 1)
        let y = bike[0].line[0].y
        #expect(abs(y - (-r.width / 2 + RoadRules().parkingLaneWidth + Self.tuning.bikeLaneWidthM)) < 1e-9)
    }

    @Test func linesStopAtJunctions() {
        let main = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "2"])
        let side = Self.road(2, .residential, [LocalPoint(0, 0), LocalPoint(0, 80)])
        let out = Self.build(roads: [main, side])
        #expect(!out.marks.isEmpty)
        let r = side.width / 2
        #expect(out.marks.filter { $0.source == main.ref }.allSatisfy { m in m.line.allSatisfy { abs($0.x) >= r - 1e-6 } })
    }

    // MARK: - Crosswalks

    @Test func zebraCrossingPaintsBarsAlongTheRoadAndCutsLines() {
        let main = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "2"])
        let cw = Self.crossing(10, [LocalPoint(20, -12), LocalPoint(20, 12)], tags: ["crossing": "uncontrolled", "crossing:markings": "zebra"])
        let out = Self.build(roads: [main], paths: [cw])
        let bars = out.marks.filter { $0.role == .crosswalkBar }
        let pitch = Self.values.stripeWidth + Self.values.stripeGap
        #expect(bars.count == Int((main.width - Self.values.stripeWidth) / pitch) + 1)
        // Bars run along the traffic direction, crossingWidth long.
        #expect(bars.allSatisfy { abs($0.line[0].y - $0.line[1].y) < 1e-9 && abs(abs($0.line[1].x - $0.line[0].x) - Self.values.crossingWidth) < 1e-9 })
        #expect(bars.allSatisfy { abs($0.line[0].y) <= main.width / 2 })
        #expect(out.marks.filter { $0.source == main.ref }.allSatisfy { m in m.line.allSatisfy { abs($0.x - 20) >= Self.values.crossingWidth / 2 - 1e-6 } })
        // The crossing band is replaced by paint on the carriageway only.
        #expect(out.crossingSpans[0] == [(12 - main.width / 2)...(12 + main.width / 2)])
    }

    @Test func crossingStylesFollowTags() {
        #expect(RoadMarkings.style(["crossing:markings": "ladder"])?.style == .ladder)
        #expect(RoadMarkings.style(["crossing:markings": "lines"])?.style == .lines)
        #expect(RoadMarkings.style(["crossing": "unmarked"])?.style == RoadMarkings.Crosswalk.Style.none)
        #expect(RoadMarkings.style(["crossing:markings": "no"])?.style == RoadMarkings.Crosswalk.Style.none)
        #expect(RoadMarkings.style(["crossing": "traffic_signals"]).map { $0.style == .bars && $0.inferred } == true)
        #expect(RoadMarkings.style([:]) == nil)

        let main = Self.road(1, .residential, Self.eastWest)
        let ladder = Self.build(roads: [main], paths: [Self.crossing(10, [LocalPoint(0, -8), LocalPoint(0, 8)], tags: ["crossing:markings": "ladder"])])
        #expect(ladder.marks.filter { $0.role == .crosswalkLine }.count == 2 && ladder.marks.contains { $0.role == .crosswalkBar })
        let lines = Self.build(roads: [main], paths: [Self.crossing(10, [LocalPoint(0, -8), LocalPoint(0, 8)], tags: ["crossing:markings": "lines"])])
        #expect(lines.marks.map(\.role) == [.crosswalkLine, .crosswalkLine])
        let unmarked = Self.build(roads: [main], paths: [Self.crossing(10, [LocalPoint(0, -8), LocalPoint(0, 8)], tags: ["crossing": "unmarked"])])
        #expect(unmarked.marks.isEmpty && unmarked.crosswalks.count == 1)
    }

    @Test func crossingNodesPaintOnlyWithEvidence() {
        let main = Self.road(1, .residential, [LocalPoint(-100, 0), LocalPoint(30, 0), LocalPoint(100, 0)])
        let bare = PointFeature(ref: OSMRef(.node, 5), kind: .crossing, position: LocalPoint(30, 0), tags: ["highway": "crossing"])
        #expect(Self.build(roads: [main], points: [bare]).marks.isEmpty)
        let zebra = PointFeature(ref: OSMRef(.node, 5), kind: .crossing, position: LocalPoint(30, 0), tags: ["highway": "crossing", "crossing:markings": "zebra"])
        let out = Self.build(roads: [main], points: [zebra])
        #expect(out.crosswalks.count == 1 && !out.marks.isEmpty && out.marks.allSatisfy { $0.role == .crosswalkBar })
    }

    @Test func noCrosswalksInventedAtSignalisedJunctions() {
        let main = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "2"])
        let side = Self.road(2, .secondary, [LocalPoint(0, -100), LocalPoint(0, 100)], tags: ["lanes": "2"])
        let signal = PointFeature(ref: OSMRef(.node, 7), kind: .crossing, position: .zero, tags: ["highway": "traffic_signals"])
        let out = Self.build(roads: [main, side], points: [signal])
        #expect(out.crosswalks.isEmpty)
        #expect(!out.marks.contains { $0.role == .crosswalkBar || $0.role == .stopBar })
    }

    @Test func signalisedCrossingAtAJunctionGetsAStopBarOnTheApproachOnly() {
        let main = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "2", "parking:both": "no"])
        let side = Self.road(2, .residential, [LocalPoint(0, 0), LocalPoint(0, 100)])
        // Crossing on the main road's west leg, just outside the junction.
        let cw = Self.crossing(10, [LocalPoint(-8, -10), LocalPoint(-8, 10)], tags: ["crossing": "traffic_signals", "crossing:markings": "zebra"])
        let out = Self.build(roads: [main, side], paths: [cw])
        let bars = out.marks.filter { $0.role == .stopBar }
        #expect(bars.count == 1)
        // West of the crosswalk, across the eastbound (right-hand, y < 0) lane only.
        let b = bars[0]
        let expectedX = -8 - Self.values.crossingWidth / 2 - Self.tuning.stopBarSetbackM - Self.values.stopBarWidth / 2
        #expect(abs(b.line[0].x - expectedX) < 1e-6)
        #expect(b.line.allSatisfy { $0.y <= 1e-6 })
    }

    @Test func wearIsSeededAndDeterministic() {
        let r = Self.road(1, .primary, Self.eastWest, tags: ["lanes": "4"])
        let a = Self.build(roads: [r]), b = Self.build(roads: [r])
        #expect(a.marks == b.marks)
        #expect(a.marks.allSatisfy { $0.shade <= 1 && Double($0.shade) >= 1 - Self.tuning.wearShadeMax - 1e-6 })
        #expect(Set(a.marks.map(\.shade)).count > 1)
    }

    // MARK: - Real area budget

    /// Lakeview: paint goes into the existing chunk meshes (no new draws) at a small triangle cost.
    @Test(.enabled(if: BuildingAreaTests.has("lakeview-sheil-park")))
    func lakeviewPaintStaysInBudget() throws {
        let b = try YardTests.build("lakeview-sheil-park", "chicago-dense-north")
        let s = b.scene.stats
        let tris = try #require(s["markingTriangles"])
        let km2 = b.focus.width * b.focus.height / 1e6
        print("MARKINGS lakeview tris=\(tris) km2=\(km2) trisPerKm2=\(Double(tris) / km2) marks=\(s["markingMarks"] ?? 0) crosswalks=\(s["crosswalks"] ?? 0) painted=\(s["crosswalksPainted"] ?? 0) conflicts=\(s["markingConflicts"] ?? 0)")
        #expect(s["crosswalksPainted"]! > 50)
        #expect(Double(tris) / km2 < 25_000)
        // One static mesh per chunk, as before: paint is a feature range inside it.
        #expect(b.scene.chunks.allSatisfy { c in c.staticFeatures.filter { $0.feature == "gen:markings" }.count <= 1 })
    }
}
