import Foundation
import Testing
@testable import WorldGeo
@testable import WorldMap

/// Small inline Overpass documents for the way/relation de-duplication rules.
@Suite("Building ways and relations")
struct BuildingRelationTests {
    /// Four corner nodes (ids firstID...firstID+3); coordinates are units of 1e-7 degrees from (40, -105).
    private static func rect(_ firstID: Int, x0: Double, y0: Double, x1: Double, y1: Double) -> (nodes: String, ids: [Int]) {
        let corners = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        var json: [String] = []
        for (i, c) in corners.enumerated() {
            json.append(#"{"type":"node","id":\#(firstID + i),"lat":\#(40 + c.1 * 0.0000001),"lon":\#(-105 + c.0 * 0.0000001)}"#)
        }
        let ids = (0..<4).map { firstID + $0 }
        return (json.joined(separator: ","), ids + [ids[0]])
    }

    private static func way(_ id: Int, _ nodes: [Int], _ tags: [String: String]) -> String {
        let t = tags.map { #""\#($0.key)":"\#($0.value)""# }.sorted().joined(separator: ",")
        return #"{"type":"way","id":\#(id),"nodes":\#(nodes),"tags":{\#(t)}}"#
    }

    private static func relation(_ id: Int, _ members: [(String, Int, String)], _ tags: [String: String]) -> String {
        let m = members.map { #"{"type":"\#($0.0)","ref":\#($0.1),"role":"\#($0.2)"}"# }.joined(separator: ",")
        let t = tags.map { #""\#($0.key)":"\#($0.value)""# }.sorted().joined(separator: ",")
        return #"{"type":"relation","id":\#(id),"members":[\#(m)],"tags":{\#(t)}}"#
    }

    private static func features(_ parts: [String]) throws -> MapFeatures {
        let json = #"{"elements":[\#(parts.joined(separator: ","))]}"#
        let doc = try OSMDocument(overpassJSON: Data(json.utf8))
        return MapFeatureBuilder(center: GeoCoordinate(latitude: 40, longitude: -105), widthMeters: 400, heightMeters: 400).build(doc)
    }

    // Outer (about 17 x 22 m) with a courtyard inside it.
    private static let outer = rect(1, x0: 0, y0: 0, x1: 2000, y1: 2000)
    private static let courtyard = rect(11, x0: 600, y0: 600, x1: 1200, y1: 1200)

    @Test func wayThatIsAMultipolygonOuterIsCountedOnce() throws {
        let f = try Self.features([
            Self.outer.nodes, Self.courtyard.nodes,
            Self.way(100, Self.outer.ids, ["building": "yes", "building:levels": "4"]),
            Self.way(101, Self.courtyard.ids, [:]),
            Self.relation(200, [("way", 100, "outer"), ("way", 101, "inner")],
                          ["type": "multipolygon", "building": "apartments"]),
        ])
        let buildings = f.buildings.filter { !$0.isPart }
        #expect(buildings.count == 1)
        let b = try #require(buildings.first)
        #expect(b.ref == OSMRef(.relation, 200))
        #expect(b.footprint.holes.count == 1)
        #expect(b.type == "apartments")                // relation tags win
        #expect(b.tags["building:levels"] == "4")      // way tags fill gaps
        #expect(b.height.source == .levels)
    }

    @Test func wayIsKeptWhenTheRelationMakesNoBuilding() throws {
        let f = try Self.features([
            Self.outer.nodes, Self.courtyard.nodes,
            Self.way(100, Self.outer.ids, ["building": "house"]),
            Self.way(101, Self.courtyard.ids, [:]),
            Self.relation(200, [("way", 100, "outer"), ("way", 101, "inner")],
                          ["type": "multipolygon", "name": "No building tag"]),
        ])
        #expect(f.buildings.count == 1)
        #expect(f.buildings[0].ref == OSMRef(.way, 100))
    }

    @Test func wayIsKeptWhenTheRelationFailsToAssemble() throws {
        let f = try Self.features([
            Self.outer.nodes,
            Self.way(100, Self.outer.ids, ["building": "house"]),
            Self.relation(200, [("way", 100, "outer"), ("way", 999, "inner")],
                          ["type": "multipolygon", "building": "yes"]),
        ])
        #expect(f.buildings.map(\.ref) == [OSMRef(.way, 100)])
        #expect(f.report.skipped.map(\.ref) == [OSMRef(.relation, 200)])
    }

    @Test func relationOnlyMultipolygonStillWorks() throws {
        let f = try Self.features([
            Self.outer.nodes, Self.courtyard.nodes,
            Self.way(100, Self.outer.ids, [:]),
            Self.way(101, Self.courtyard.ids, [:]),
            Self.relation(200, [("way", 100, "outer"), ("way", 101, "inner")],
                          ["type": "multipolygon", "building": "retail"]),
        ])
        #expect(f.buildings.count == 1)
        let b = f.buildings[0]
        #expect(b.ref == OSMRef(.relation, 200) && b.type == "retail" && b.footprint.holes.count == 1)
    }

    @Test func buildingRelationMakesNoBuildingOfItsOwn() throws {
        let part1 = Self.rect(21, x0: 0, y0: 0, x1: 1000, y1: 2000)
        let part2 = Self.rect(31, x0: 1000, y0: 0, x1: 2000, y1: 2000)
        let f = try Self.features([
            Self.outer.nodes, part1.nodes, part2.nodes,
            Self.way(100, Self.outer.ids, ["building": "yes", "name": "Hall"]),
            Self.way(101, part1.ids, ["building:part": "yes", "height": "10"]),
            Self.way(102, part2.ids, ["building:part": "yes", "height": "20"]),
            Self.relation(200, [("way", 100, "outline"), ("way", 101, "part"), ("way", 102, "part")],
                          ["type": "building", "building": "yes"]),
        ])
        #expect(f.buildings.filter { !$0.isPart }.map(\.ref) == [OSMRef(.way, 100)])
        #expect(Set(f.buildings.filter(\.isPart).map(\.ref)) == [OSMRef(.way, 101), OSMRef(.way, 102)])
        #expect(f.buildings.count == 3)
    }

    @Test func buildingRelationTagsApplyToAnUntaggedOutline() throws {
        let part = Self.rect(21, x0: 0, y0: 0, x1: 1000, y1: 2000)
        let f = try Self.features([
            Self.outer.nodes, part.nodes,
            Self.way(100, Self.outer.ids, ["name": "Outline only"]),
            Self.way(101, part.ids, ["building:part": "yes"]),
            Self.relation(200, [("way", 100, "outline"), ("way", 101, "part")],
                          ["type": "building", "building": "church", "building:levels": "2"]),
        ])
        let whole = f.buildings.filter { !$0.isPart }
        #expect(whole.count == 1)
        #expect(whole[0].ref == OSMRef(.way, 100) && whole[0].type == "church")
        #expect(whole[0].tags["building:levels"] == "2")
        #expect(f.buildings.filter(\.isPart).count == 1)
    }

    @Test func buildingRelationWithoutBuildingTagLeavesOutlineAlone() throws {
        let f = try Self.features([
            Self.outer.nodes,
            Self.way(100, Self.outer.ids, ["name": "Not a building"]),
            Self.relation(200, [("way", 100, "outline")], ["type": "building"]),
        ])
        #expect(f.buildings.isEmpty)
    }
}
