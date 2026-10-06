import Foundation
import Testing
@testable import WorldGeo
@testable import WorldMap

/// Synthetic area (200 × 200 m around 40, -105): OSM house at (0, 0), an OSM building:part at
/// (40, 40), an OSM building at x 90…120 whose centroid is outside the area, and ten Overture
/// records covering every merge rule (see make-up in each test).
@Suite("Overture buildings as a second footprint source")
struct OvertureTests {
    static func fixtureDir() throws -> URL {
        try #require(Bundle.module.url(forResource: "overture-area", withExtension: nil, subdirectory: "Fixtures"))
    }

    static func load() throws -> MapFeatures { try AreaLoader.loadFeatures(fixtureDir()) }

    static func overture(_ f: MapFeatures, _ gers: String) throws -> [Building] {
        let ref = try #require(OSMRef(overtureID: gers))
        return f.buildings.filter { $0.ref == ref }
    }

    /// The fixture copied to a temporary directory with the Overture source removed.
    static func osmOnlyCopy() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("overture-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for name in ["manifest.json", "osm.json"] {
            try FileManager.default.copyItem(at: try fixtureDir().appendingPathComponent(name), to: dir.appendingPathComponent(name))
        }
        var m = try AreaLoader.loadManifest(dir)
        m.sources.removeAll { $0.format == OvertureBuildings.format }
        try JSONEncoder().encode(m).write(to: dir.appendingPathComponent(AreaManifest.fileName))
        return dir
    }

    static func same(_ a: [Building], _ b: [Building]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy {
            $0.ref == $1.ref && $0.footprint == $1.footprint && $0.tags == $1.tags && $0.type == $1.type
                && $0.isPart == $1.isPart && $0.height == $1.height
        }
    }

    // MARK: Merge rules

    @Test func mergeReportCountsEveryRule() throws {
        let r = try Self.load().report.overture
        #expect(r.records == 10)
        #expect(r.droppedOSMSource == 1)
        #expect(r.droppedInsideOSM == 3)
        #expect(r.droppedOutsideBounds == 1)
        #expect(r.skipped == 1)
        #expect(r.added == 4)
        #expect(r.buildings == 5)
    }

    @Test func recordWithAnOSMSourceIsDropped() throws {
        #expect(try Self.overture(Self.load(), "0b000000-0000-4000-8000-00000000000b").isEmpty)
    }

    @Test func centroidInsideOSMBuildingOrPartIsDropped() throws {
        let f = try Self.load()
        #expect(try Self.overture(f, "0a000000-0000-4000-8000-00000000000a").isEmpty) // inside building=house
        #expect(try Self.overture(f, "0f000000-0000-4000-8000-00000000000f").isEmpty) // inside building:part
        // Inside an OSM building whose own centroid is outside the area (so not in `buildings`).
        #expect(try Self.overture(f, "1c000000-0000-4000-8000-00000000001c").isEmpty)
        #expect(!f.buildings.contains { $0.ref == OSMRef(.way, 120) })
    }

    @Test func centroidOutsideTheAreaIsDropped() throws {
        let f = try Self.load()
        #expect(try Self.overture(f, "0e000000-0000-4000-8000-00000000000e").isEmpty)
        for b in f.buildings { #expect(f.bounds.contains(b.footprint.centroid)) }
    }

    @Test func degenerateFootprintIsSkippedAndReported() throws {
        let f = try Self.load()
        let ref = try #require(OSMRef(overtureID: "1b000000-0000-4000-8000-00000000001b"))
        #expect(!f.buildings.contains { $0.ref == ref })
        #expect(f.report.skipped.contains { $0.ref == ref && $0.reason == "degenerate footprint" })
    }

    @Test func footprintsAreCleanedLikeOSM() throws {
        let g = try #require(try Self.overture(Self.load(), "1a000000-0000-4000-8000-00000000001a").first)
        #expect(RingMath.signedArea(g.footprint.outer) > 0) // given clockwise
        #expect(g.footprint.holes.count == 1)
        #expect(RingMath.signedArea(g.footprint.holes[0]) < 0) // given counter-clockwise
        #expect(g.footprint.outer.count == 4) // closing point dropped
        #expect(abs(g.footprint.area - (20 * 16 - 6 * 4)) < 1)
    }

    @Test func multiPolygonRecordAddsOneBuildingPerPolygon() throws {
        let parts = try Self.overture(Self.load(), "ffffffff-ffff-4fff-8000-0000000000ff")
        #expect(parts.count == 2)
        #expect(Set(parts.map(\.ref)).count == 1)
    }

    @Test func osmBuildingsComeFirstAndUnchanged() throws {
        let with = try Self.load()
        let dir = try Self.osmOnlyCopy()
        defer { try? FileManager.default.removeItem(at: dir) }
        let without = try AreaLoader.loadFeatures(dir)
        #expect(Self.same(Array(with.buildings.prefix(without.buildings.count)), without.buildings))
        #expect(with.buildings.dropFirst(without.buildings.count).allSatisfy { $0.ref.kind == .overture })
        #expect(with.roads.count == without.roads.count && with.points.count == without.points.count)
    }

    // MARK: Tags and heights

    @Test func tagsAndHeightGoThroughHeightRules() throws {
        let f = try Self.load()
        let c = try #require(try Self.overture(f, "0c000000-0000-4000-8000-00000000000c").first)
        #expect(c.type == "yes" && !c.isPart)
        #expect(c.tags["height"] == "9.5")
        #expect(c.tags["overture:id"] == "0c000000-0000-4000-8000-00000000000c")
        #expect(c.tags["overture:sources"] == "Microsoft ML Buildings,USGS Lidar")
        #expect(c.height == BuildingHeight(base: 0, top: 9.5, source: .heightTag))

        let d = try #require(try Self.overture(f, "0d000000-0000-4000-8000-00000000000d").first)
        #expect(d.type == "semidetached_house") // class "semi" mapped to the OSM value
        #expect(d.levels == 2 && d.roofShape == "gabled")
        #expect(d.height.source == .levels)
        #expect(d.height == HeightRules().resolve(tags: d.tags, type: d.type, ref: d.ref))

        let g = try #require(try Self.overture(f, "1a000000-0000-4000-8000-00000000001a").first)
        #expect(g.tags["building"] == "yes" && g.tags["height"] == nil && g.tags["building:levels"] == nil)
        #expect(g.height.source == .typeDefault)
        #expect(g.height == HeightRules().resolve(tags: g.tags, type: "yes", ref: g.ref))
    }

    /// Microsoft ML heights are dropped on house-sized footprints (lidar check, overture-source.md).
    @Test func microsoftHeightSourceIsDetected() {
        let ms = OvertureBuildings.Record(id: "a", polygons: [], height: 5.7,
                                          sources: [.init(dataset: OvertureBuildings.microsoftDataset)])
        let lidar = OvertureBuildings.Record(id: "b", polygons: [], height: 8.3, sources: [
            .init(dataset: OvertureBuildings.microsoftDataset), .init(dataset: "USGS Lidar", property: "/properties/height")])
        #expect(OvertureBuildings.heightDataset(ms) == OvertureBuildings.microsoftDataset)
        #expect(OvertureBuildings.heightDataset(lidar) == "USGS Lidar")
        #expect(OvertureBuildings.mlHeightMinDropArea == 90)
    }

    @Test func customHeightRulesApply() throws {
        var rules = HeightRules()
        rules.metersPerLevel = 4
        rules.jitterFraction = 0
        let f = try AreaLoader.loadFeatures(Self.fixtureDir(), heightRules: rules)
        let d = try #require(try Self.overture(f, "0d000000-0000-4000-8000-00000000000d").first)
        #expect(d.height.top == 8)
    }

    // MARK: Identity

    @Test func refsComeFromTheGERSID() throws {
        #expect(OSMRef(overtureID: "29d3611a-af94-4734-98d1-6d928d82e634") == OSMRef(.overture, 0x29d3_611a_af94_4734))
        #expect(OSMRef(overtureID: "08b2a100d2c8dfff0200f7a6b2fd1f1c") == OSMRef(.overture, 0x08b2_a100_d2c8_dfff)) // older 32-hex form
        let neg = try #require(OSMRef(overtureID: "ffffffff-ffff-4fff-8000-0000000000ff"))
        #expect(neg.id == Int64(bitPattern: 0xffff_ffff_ffff_4fff) && neg.id < 0)
        #expect(neg.description == "overture/-45057")
        #expect(OSMRef(overtureID: "abc") == nil)
        #expect(OSMRef(overtureID: "not-a-gers-id-at-all-zzzz") == nil)
    }

    @Test func seedsAreStableAndSeparateFromOSM() {
        var a = OSMRef(.overture, 5).random("x"), b = StableRandom(4, 5, salt: "x"), w = OSMRef(.way, 5).random("x")
        let (va, vb, vw) = (a.next(), b.next(), w.next())
        #expect(va == vb)
        #expect(va != vw)
    }

    @Test func loadingTwiceGivesIdenticalBuildings() throws {
        #expect(Self.same(try Self.load().buildings, try Self.load().buildings))
    }

    @Test func kindRoundTripsThroughCodable() throws {
        let ref = OSMRef(.overture, -42)
        let back = try JSONDecoder().decode(OSMRef.self, from: JSONEncoder().encode(ref))
        #expect(back == ref)
        #expect(OSMRef.Kind(rawValue: "overture") == .overture)
    }

    // MARK: Credits

    @Test func attributionListsTheDatasetsPresent() throws {
        let file = try OvertureBuildings.decode(Data(contentsOf: Self.fixtureDir().appendingPathComponent(OvertureBuildings.fileName)))
        let expected = "© OpenStreetMap contributors, Overture Maps Foundation; Esri Community Maps contributors (CC BY 4.0); "
            + "Google Open Buildings (CC BY 4.0); Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program"
        #expect(OvertureBuildings.attribution(for: file.datasets) == expected)
        let manifest = try AreaLoader.loadManifest(Self.fixtureDir())
        #expect(manifest.sources.first { $0.format == OvertureBuildings.format }?.attribution == expected)

        let msOnly = [OvertureBuildings.Dataset(dataset: "OpenStreetMap"), .init(dataset: "Microsoft ML Buildings", license: "ODbL-1.0")]
        #expect(OvertureBuildings.attribution(for: msOnly)
            == "© OpenStreetMap contributors, Overture Maps Foundation; Microsoft Global ML Building Footprints (ODbL)")
        #expect(OvertureBuildings.attribution(for: [.init(dataset: "OpenStreetMap")]) == OvertureBuildings.baseAttribution)
        // Unknown datasets fall back to name + Overture's licence, and are flagged.
        let unknown = [OvertureBuildings.Dataset(dataset: "City of Somewhere", license: "CC-BY-4.0")]
        #expect(OvertureBuildings.attribution(for: unknown) == OvertureBuildings.baseAttribution + "; City of Somewhere (CC-BY-4.0)")
        #expect(OvertureBuildings.uncreditedDatasets(unknown) == ["City of Somewhere"])
    }

    @Test func noticeNamesReleaseAndCredits() {
        let n = OvertureBuildings.notice(release: "2026-09-23.1", datasets: [.init(dataset: "Microsoft ML Buildings")])
        #expect(n == "Building footprints in `overture-buildings.json` come from the Overture Maps Foundation buildings theme "
            + "(release 2026-09-23.1), licensed under ODbL 1.0: © OpenStreetMap contributors, Overture Maps Foundation. "
            + "Contains Microsoft Global ML Building Footprints (ODbL). "
            + "OpenStreetMap buildings take precedence; Overture fills only footprints OSM lacks.")
    }

    // MARK: Regression: areas without Overture

    @Test func areaWithoutOvertureLoadsExactlyAsBefore() throws {
        let dir = try Self.osmOnlyCopy()
        defer { try? FileManager.default.removeItem(at: dir) }
        let manifest = try AreaLoader.loadManifest(dir)
        let viaLoader = try AreaLoader.loadFeatures(dir)
        let doc = try OSMDocument(overpassJSON: Data(contentsOf: dir.appendingPathComponent("osm.json")))
        let direct = MapFeatureBuilder(frame: manifest.frame, bounds: manifest.localBounds).build(doc)
        #expect(Self.same(viaLoader.buildings, direct.buildings))
        #expect(viaLoader.report.overture == OvertureMergeReport())
        #expect(viaLoader.report.skipped.count == direct.report.skipped.count)
    }

    @Test func loadDocumentSkipsOvertureAndStillRejectsUnknownFormats() throws {
        let dir = try Self.fixtureDir()
        let manifest = try AreaLoader.loadManifest(dir)
        let doc = try AreaLoader.loadDocument(dir, manifest: manifest)
        #expect(doc.ways.count == 4)
        var bad = manifest
        bad.sources[0].format = "something-else"
        #expect(throws: AreaLoader.LoadError.self) { try AreaLoader.loadDocument(dir, manifest: bad) }
    }
}

/// The committed areas have no Overture source: loading them must match the plain OSM builder.
@Suite("Real areas without Overture")
struct OvertureRegressionTests {
    static let areasDir = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/areas")

    @Test(arguments: ["sloans-lake", "evanston-south"])
    func loaderMatchesPlainBuilder(_ area: String) throws {
        let dir = Self.areasDir.appendingPathComponent(area)
        guard FileManager.default.fileExists(atPath: dir.appendingPathComponent("manifest.json").path) else { return }
        let manifest = try AreaLoader.loadManifest(dir)
        guard !manifest.sources.contains(where: { $0.format == OvertureBuildings.format }) else { return }
        let viaLoader = try AreaLoader.loadFeatures(dir)
        let direct = MapFeatureBuilder(frame: manifest.frame, bounds: manifest.localBounds)
            .build(try AreaLoader.loadDocument(dir, manifest: manifest, layers: ["all"]))
        #expect(OvertureTests.same(viaLoader.buildings, direct.buildings))
        #expect(viaLoader.report.overture == OvertureMergeReport())
        #expect(!viaLoader.buildings.contains { $0.ref.kind == .overture })
    }
}
