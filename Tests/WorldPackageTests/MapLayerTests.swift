import Foundation
import Testing
@testable import WorldGeo
@testable import WorldMap
@testable import WorldPackage

/// The map data layer's fixed rules (worldengine.map/2): network splitting and IDs, normalized
/// tags, privacy, number format.
@Suite("Map layer")
struct MapLayerTests {
    static let origin = GeoCoordinate(latitude: 40, longitude: -105)
    static let frame = LocalFrame(origin: origin)

    /// A node `east`, `north` metres from the origin (small offsets, so plain degree arithmetic).
    static func node(_ id: Int64, _ east: Double, _ north: Double, tags: [String: String]? = nil) -> String {
        let c = frame.coordinate(at: LocalPoint(east, north))
        let t = tags.map { ", \"tags\": \(json($0))" } ?? ""
        return "{\"type\": \"node\", \"id\": \(id), \"lat\": \(c.latitude), \"lon\": \(c.longitude)\(t)}"
    }

    static func way(_ id: Int64, _ nodes: [Int64], _ tags: [String: String]) -> String {
        "{\"type\": \"way\", \"id\": \(id), \"nodes\": \(nodes), \"tags\": \(json(tags))}"
    }

    static func json(_ t: [String: String]) -> String {
        String(decoding: try! JSONSerialization.data(withJSONObject: t, options: [.sortedKeys]), as: UTF8.self)
    }

    static func doc(_ elements: [String]) throws -> OSMDocument {
        try OSMDocument(overpassJSON: Data("{\"elements\": [\(elements.joined(separator: ","))]}".utf8))
    }

    /// A street (way 10: nodes 1–2–3) crossed at node 2 by way 20 (2–4), a gate on way 20 at node 4
    /// continuing to 5, and a closed footway loop (way 30) touching nothing.
    static func sample() throws -> OSMDocument {
        try doc([
            node(1, 0, 0), node(2, 50, 0), node(3, 100, 0, tags: ["highway": "stop"]),
            node(4, 50, 40, tags: ["barrier": "gate", "access": "private"]), node(5, 50, 80),
            node(6, 0, 100), node(7, 20, 100), node(8, 20, 120),
            way(10, [1, 2, 3], ["highway": "residential", "name": "A Street", "addr:street": "A Street", "oneway": "-1", "maxspeed": "25 mph"]),
            way(20, [2, 4, 5], ["highway": "service", "service": "driveway", "access": "private", "width": "10'6\""]),
            way(30, [6, 7, 8, 6], ["highway": "footway"]),
        ])
    }

    @Test func splitsAtJunctionsBarriersAndLoops() throws {
        let n = MapNetwork(doc: try Self.sample(), frame: Self.frame, playable: Rect2D(centerWidth: 400, height: 400), marginM: 0)
        #expect(n.segments.map(\.id) == ["way/10:0", "way/10:1", "way/20:0", "way/20:1", "way/30:0", "way/30:1"])
        #expect(n.segments.allSatisfy { $0.nodeIDs.first != $0.nodeIDs.last })
        #expect(n.barriers.map(\.node) == [4])
        let s = n.segments[0]
        #expect(s.lengthM >= 50 && s.lengthM < 50.002)
        #expect(s.tags["addr:street"] == nil && s.tags["name"] == "A Street")
        // The stop sign at the end of way 10 is a segment end there, so it is the node's own control.
        #expect(n.controls[3]?.kind == "stop")
    }

    @Test func piecesOutsideTheMarginAreLeftOutWhole() throws {
        let n = MapNetwork(doc: try Self.sample(), frame: Self.frame, playable: Rect2D(min: LocalPoint(-10, -10), max: LocalPoint(60, 10)), marginM: 5)
        #expect(n.segments.map(\.id) == ["way/10:0", "way/10:1", "way/20:0"])
    }

    @Test func normalizedFieldsFollowTheFixedRules() {
        #expect(MapNetwork.oneway(["oneway": "yes"]) == "forward")
        #expect(MapNetwork.oneway(["oneway": "-1"]) == "backward")
        #expect(MapNetwork.oneway(["oneway": "alternating"]) == "reversible")
        #expect(MapNetwork.oneway(["junction": "roundabout"]) == "forward")
        #expect(MapNetwork.oneway(["junction": "roundabout", "oneway": "no"]) == "no")
        #expect(MapNetwork.oneway([:]) == "no")
        #expect(MapNetwork.access(["access": "private", "foot": "yes"]) == ["all": "private", "foot": "yes", "bicycle": "private", "motorVehicle": "private"])
        #expect(MapNetwork.access(["vehicle": "no"]) == ["bicycle": "no", "motorVehicle": "no"])
        #expect(MapNetwork.access([:]).isEmpty)
        #expect(MapJSON.round3(MapNetwork.maxspeedKmh("35 mph")!) == 56.327)
        #expect(MapNetwork.maxspeedKmh("US:urban") == nil)
        #expect(MapNetwork.maxspeedKmh("50") == 50)
        #expect(MapJSON.round3(MapNetwork.widthM("10'6\"")!) == 3.2)
        #expect(MapNetwork.widthM("12 ft").map(MapJSON.round3) == 3.658)
        #expect(MapNetwork.widthM("3.5") == 3.5)
        #expect(MapNetwork.widthM("wide") == nil)
    }

    @Test func numbersAreRoundedAndDeterministic() {
        let v: MapJSON = .object(["b": .num(1.0006), "a": .num(-0.0001), "c": .num(2), "d": .array([.string("x\"y")])])
        let text = String(decoding: v.encoded(), as: UTF8.self)
        #expect(text == "{\n  \"a\": 0,\n  \"b\": 1.001,\n  \"c\": 2,\n  \"d\": [\n    \"x\\\"y\"\n  ]\n}\n")
        #expect(MapJSON.format(-2.0006) == "-2.001")
    }

    @Test func projectionGivesOffsetAndSide() {
        let line = [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 10)]
        let a = MapNetwork.project(LocalPoint(5, 3), onto: line)
        #expect(abs(a.offset - 5) < 1e-9 && a.side == "left" && abs(a.distance - 3) < 1e-9)
        let b = MapNetwork.project(LocalPoint(12, 5), onto: line)
        #expect(abs(b.offset - 15) < 1e-9 && b.side == "right")
    }

    @Test func gatedAreasNeedPrivateAccessOnAnArea() {
        #expect(MapNetwork.isGatedArea(["amenity": "parking", "access": "private"]))
        #expect(MapNetwork.isGatedArea(["landuse": "residential", "gated": "yes"]))
        #expect(!MapNetwork.isGatedArea(["amenity": "parking"]))
        #expect(!MapNetwork.isGatedArea(["building": "house", "access": "private"]))
    }

    @Test func migrationClassifiesSplitsMergesAndDeletions() {
        let entry: (String, [String], String) -> MapJSON = { o, n, c in .object(["old": .string(o), "new": MapJSON.strings(n), "change": .string(c)]) }
        let recs = MapMigration.classify(["way/1:0": ["way/1:0b", "way/1:1"], "way/2:0": ["way/9:0"], "way/3:0": ["way/9:0"], "way/4:0": [],
                                          "way/5:0": ["way/5:1"], "way/6:0": ["way/7:0"]],
                                         sameSource: { o, n in o.split(separator: ":")[0] == n.split(separator: ":")[0] }, entry: entry)
        let changes = recs.compactMap { r -> String? in
            guard case .object(let o) = r, case .string(let id)? = o["old"], case .string(let c)? = o["change"] else { return nil }
            return "\(id) \(c)"
        }
        #expect(changes == ["way/1:0 split", "way/2:0 merged", "way/3:0 merged", "way/4:0 deleted", "way/5:0 renumbered", "way/6:0 replaced"])
        let square: Ring = [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 10), LocalPoint(0, 10)]
        let half: Ring = [LocalPoint(0, 0), LocalPoint(10, 0), LocalPoint(10, 5), LocalPoint(0, 5)]
        let o = MapMigration.overlap(square, half)
        #expect(abs(o.ofOld - 0.5) < 0.02 && abs(o.iou - 0.5) < 0.02)
    }

    @Test func terrainGridIsWrittenAsTheContractsUInt16() {
        let src = MapTerrain.Source(id: "t", title: "", attribution: "", license: "public-domain", licenseURL: nil, url: nil, dataTimestamp: nil,
                                    sha256: "", method: "", validation: "")
        let g = MapTerrain(cellM: 1, minX: -1, minY: -1, cols: 2, rows: 2, values: [0, 9, 254, 255], source: src, confidence: nil)
        let d = [UInt8](g.uint16le())
        #expect(d == [0, 0, 194, 1, 156, 49, 255, 255]) // 0 %, 4.5 % (450), ≥ 127 % → 12700, no data
        let c = MapTerrain.confidence(["vsReference1mDEM": ["slopeBelow15": ["cells": 90, "shareWithin2Pts": 0.99], "slope15AndAbove": ["cells": 10, "shareWithin2Pts": 0.8]],
                                       "splitSample": ["slopeBelow15": ["cells": 900, "shareWithin2Pts": 0.95], "slope15AndAbove": ["cells": 100, "shareWithin2Pts": 0.9]]])
        #expect(c?.below15 == 0.95 && c?.from15 == 0.8 && c?.overall == 0.945)
    }

    @Test func overtureRefsAreHex() {
        #expect(OSMRef(.overture, -1).description == "overture/ffffffffffffffff")
        #expect(OSMRef(.way, 42).description == "way/42")
    }

    @Test func placesKeepTheirOwnTagsOnly() {
        #expect(MapLayer.placeClass(["leisure": "park"])! == ("park", "leisure=park"))
        #expect(MapLayer.placeClass(["shop": "bakery"])! == ("shop", "shop=bakery"))
        #expect(MapLayer.placeClass(["amenity": "bench"]) == nil)
        #expect(MapLayer.placeClass(["highway": "bus_stop", "amenity": "shelter"]) == nil)
        #expect(MapLayer.stopKind(["highway": "bus_stop"]) == "bus_stop")
    }
    @Test func undergroundWaysStayConnectedInMapNetwork() throws {
        for tags in [["highway":"residential", "tunnel":"yes"], ["highway":"residential", "layer":"-1"]] {
            let d = try Self.doc([Self.node(1, -20, 0), Self.node(2, 0, 0), Self.node(3, 20, 0),
                                  Self.way(10, [1,2,3], tags)])
            let network = MapNetwork(doc: d, frame: Self.frame, playable: Rect2D(centerWidth: 100, height: 100), marginM: 0)
            #expect(network.segments.count == 1)
            #expect(network.segments[0].nodeIDs == [1,2,3])
            #expect(network.segments[0].way == 10)
        }
    }

}
