import Foundation
import Testing
import WorldGeo
@testable import WorldMap
@testable import WorldGen

@Suite("Underground surface guard")
struct UndergroundGuardTests {
    func fixture(_ tags: [String:String]) throws -> (OSMDocument, MapFeatures) {
        let data = try JSONSerialization.data(withJSONObject: ["elements": [
            ["type":"node","id":1,"lat":0.0,"lon":-0.0002],
            ["type":"node","id":2,"lat":0.0,"lon":0.0],
            ["type":"node","id":3,"lat":0.0,"lon":0.0002],
            ["type":"way","id":10,"nodes":[1,2,3],"tags":tags]
        ]])
        let doc = try OSMDocument(overpassJSON:data)
        return (doc,MapFeatureBuilder(center:GeoCoordinate(latitude:0,longitude:0),widthMeters:100,heightMeters:100).build(doc))
    }
    @Test func undergroundRoadsRetainGraphButLoseSurface() throws {
        for tags in [["highway":"residential","tunnel":"yes"],["highway":"residential","tunnel":"building_passage"],
                     ["highway":"residential","tunnel":"culvert"],["highway":"residential","layer":"-1"]] {
            let (_,f) = try fixture(tags)
            #expect(f.roads.count == 1 && f.roads[0].centerline.count == 3)
            #expect(f.roads[0].isTunnel)
            let context = StreetContext(f)
            #expect(context.roadIndex.nearest(to:LocalPoint(0,0),within:1) != nil)
            let g = try WorldBuild.generator(features:f,profile:StyleLibrary.profile(id:"front-range"),season:1,focus:f.bounds)
            let scene = g.generate()
            #expect(!scene.chunks.flatMap(\.staticFeatures).contains { $0.feature == "way/10" })
            var surface = f; surface.roads[0].isTunnel=false; surface.roads[0].layer=0
            let visible = try WorldBuild.generator(features:surface,profile:StyleLibrary.profile(id:"front-range"),season:1,focus:f.bounds).generate()
            #expect(visible.chunks.flatMap(\.staticFeatures).contains { $0.feature == "way/10" })
            #expect(surface.roads[0].centerline == f.roads[0].centerline)
        }
    }
    @Test func diagnosticsSeparateFallbackFromMissingAndDeduplicate() throws {
        let (doc,f) = try fixture(["highway":"residential","bridge":"yes","power":"line"])
        let r = UnsupportedFeatures.collect(area:"fixture",document:doc,features:f,drawnRefs:["way/10"])
        #expect(r.entries.contains { $0.keyValue == "bridge=yes" && $0.reason == "flatRoadFallback" && $0.count == 1 })
        #expect(!r.entries.contains { $0.keyValue == "power=line" })
        let missing = UnsupportedFeatures.collect(area:"fixture",document:doc,features:f,drawnRefs:[])
        #expect(missing.entries.allSatisfy { $0.reason == "notDrawn" && $0.refs == ["way/10"] })
    }
    @Test func allRequestedDiagnosticKeysAreCountedOnce() throws {
        for tags in [["waterway":"stream"], ["waterway":"ditch"], ["waterway":"drain"],
                     ["barrier":"fence"], ["man_made":"tower"], ["power":"line"], ["aeroway":"runway"],
                     ["railway":"station"], ["railway":"platform"], ["building:part":"yes"]] {
            let (doc,f) = try fixture(tags)
            let report = UnsupportedFeatures.collect(area:"fixture",document:doc,features:f,drawnRefs:[])
            #expect(report.entries.count == 1)
            #expect(report.entries[0].count == 1 && report.entries[0].reason == "notDrawn")
            #expect(report.entries[0].keyValue == tags.first!.key + "=" + tags.first!.value)
        }
        let (doc,f) = try fixture(["highway":"residential","tunnel":"culvert"])
        var duplicated = f; duplicated.roads += f.roads
        let report = UnsupportedFeatures.collect(area:"fixture",document:doc,features:duplicated,drawnRefs:[])
        #expect(report.entries.count == 1 && report.entries[0].count == 1)
    }

}
