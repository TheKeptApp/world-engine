import Foundation
import Testing
@testable import WorldMap
@testable import WorldPackage

@Suite("Package timezone")
struct TimezoneTests {
    @Test func missingAndInvalidMetadataAreUnknown() throws {
        #expect(WorldPackage.exportedTimezone(nil) == "unknown")
        #expect(WorldPackage.exportedTimezone("") == "unknown")
        #expect(WorldPackage.exportedTimezone("not/a-zone") == "unknown")
        #expect(WorldPackage.exportedTimezone("America/Chicago") == "America/Chicago")
        #expect(WorldPackage.exportedTimezone("America/Denver") == "America/Denver")
        #expect(WorldPackage.exportedTimezone("Asia/Tokyo") == "Asia/Tokyo")
        let legacy = Data(#"{"formatVersion":1,"id":"test","name":"Test","center":{"latitude":0,"longitude":0},"widthMeters":100,"heightMeters":100,"sources":[]}"#.utf8)
        let manifest = try JSONDecoder().decode(AreaManifest.self, from: legacy)
        #expect(manifest.timezone == nil)
        #expect(WorldPackage.exportedTimezone(manifest.timezone) == "unknown")
    }

    @Test func heldAreaMetadataMatchesCivilZones() throws {
        let root = PackageTests.areaDir.deletingLastPathComponent()
        for (area, zone) in [("sloans-lake", "America/Denver"),
                             ("lakeview-sheil-park", "America/Chicago"),
                             ("wilmette-vattmann-park", "America/Chicago")] {
            let manifest = try AreaLoader.loadManifest(root.appendingPathComponent(area))
            #expect(WorldPackage.exportedTimezone(manifest.timezone) == zone)
            let roundtrip = try JSONDecoder().decode(AreaManifest.self, from: JSONEncoder().encode(manifest))
            #expect(roundtrip == manifest)
        }
    }
}
