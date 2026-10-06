import Foundation
import Testing
@testable import WorldGeo
@testable import WorldMap

/// The context ring (`worldbake fetch --layers context`): a second OSM source per area, read by
/// the same parser, never loaded into the detailed world. Skipped for areas without a context file.
@Suite("Context ring")
struct ContextRingTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Data/areas")
    static let areas = ["sloans-lake", "evanston-south", "lakeview-sheil-park"]

    private static func contextSource(_ area: String) -> (dir: URL, manifest: AreaManifest, source: AreaManifest.Source)? {
        let dir = root.appendingPathComponent(area)
        guard let m = try? AreaLoader.loadManifest(dir),
              let s = m.sources.first(where: { $0.layers == ["context"] }) else { return nil }
        return (dir, m, s)
    }

    @Test(arguments: areas)
    func contextFileParsesWithTheSharedLoader(area: String) throws {
        guard let (dir, manifest, source) = Self.contextSource(area) else { return }
        #expect(source.format == "osm-overpass-json")
        #expect(source.path == "context.json")
        #expect(source.license == "ODbL-1.0")
        #expect(source.attribution == "© OpenStreetMap contributors")
        // The ring box contains the area box, 3 km beyond it on every side.
        #expect(source.bounds.south < manifest.bounds.south && source.bounds.north > manifest.bounds.north)
        #expect(source.bounds.west < manifest.bounds.west && source.bounds.east > manifest.bounds.east)

        var only = manifest
        only.sources = [source]
        let doc = try AreaLoader.loadDocument(dir, manifest: only, layers: ["context"])
        #expect(doc.timestamp != nil)
        #expect(doc.ways.values.contains { $0.tags["highway"] != nil })
        #expect(doc.ways.values.contains { $0.tags["building"] != nil })
        #expect(doc.ways.values.contains { $0.tags["landuse"] != nil })
        // Every way's nodes are present (the file is recursed with `>`).
        let broken = doc.ways.values.filter { doc.coordinates(of: $0) == nil }
        #expect(broken.isEmpty)
    }

    @Test(arguments: areas)
    func detailedWorldDoesNotLoadTheContextSource(area: String) throws {
        guard let (dir, manifest, source) = Self.contextSource(area) else { return }
        let detailedSources = manifest.sources.filter { $0.layers != ["context"] }
        var detailedOnly = manifest
        detailedOnly.sources = detailedSources
        // loadFeatures asks for layer "all": the context source must add nothing.
        let withContext = try AreaLoader.loadDocument(dir, manifest: manifest, layers: ["all"])
        let without = try AreaLoader.loadDocument(dir, manifest: detailedOnly, layers: ["all"])
        #expect(withContext.nodes.count == without.nodes.count)
        #expect(withContext.ways.count == without.ways.count)
        #expect(withContext.relations.count == without.relations.count)
        #expect(source.layers == ["context"])
    }
}
