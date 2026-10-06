import Foundation
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap

/// Profile schema: the optional fields stay optional (older JSON decodes unchanged), documentation keys
/// are ignored, every bundled profile decodes, and the region boxes pick the expected profiles.
@Suite("Style profile schema")
struct StyleProfileSchemaTests {
    static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let percentileKeys = ["smallAreaPercentile", "largeAreaPercentile", "hugeAreaPercentile"]

    /// IDs of the files in `Sources/WorldGen/Profiles` that are style profiles (they have `houseTypes`).
    static func styleProfileIDs() throws -> [String] {
        let dir = root.appendingPathComponent("Sources/WorldGen/Profiles")
        return try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> String? in
                let obj = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
                return obj?["houseTypes"] != nil ? url.deletingPathExtension().lastPathComponent : nil
            }
            .sorted()
    }

    static func json(_ id: String) throws -> [String: Any] {
        try #require(try JSONSerialization.jsonObject(with: StyleLibrary.data(id)) as? [String: Any])
    }

    static func decode(_ obj: [String: Any]) throws -> StyleProfile {
        try JSONDecoder().decode(StyleProfile.self, from: JSONSerialization.data(withJSONObject: obj))
    }

    /// A profile as it was written before the optional fields and documentation keys existed.
    static func withoutOptionalFields(_ obj: [String: Any]) -> [String: Any] {
        var o = obj
        o.removeValue(forKey: "provenance")
        if var t = o["trees"] as? [String: Any] {
            t.removeValue(forKey: "canopyShare")
            o["trees"] = t
        }
        if var th = o["typeThresholds"] as? [String: Any] {
            for k in percentileKeys { th.removeValue(forKey: k) }
            o["typeThresholds"] = th
        }
        if var r = o["typeRules"] as? [String: Any] {
            r.removeValue(forKey: "comment")
            o["typeRules"] = r
        }
        return o
    }

    @Test func olderJSONDecodesWithTheNewFieldsNil() throws {
        for id in try Self.styleProfileIDs() {
            let old = try Self.decode(Self.withoutOptionalFields(try Self.json(id)))
            #expect(old.trees.canopyShare == nil, "\(id)")
            #expect(old.typeThresholds.smallAreaPercentile == nil, "\(id)")
            #expect(old.typeThresholds.largeAreaPercentile == nil, "\(id)")
            #expect(old.typeThresholds.hugeAreaPercentile == nil, "\(id)")
            // Everything else is identical to the full file.
            var full = try StyleLibrary.profile(id: id)
            full.trees.canopyShare = nil
            full.typeThresholds.smallAreaPercentile = nil
            full.typeThresholds.largeAreaPercentile = nil
            full.typeThresholds.hugeAreaPercentile = nil
            #expect(old == full, "\(id)")
        }
    }

    @Test func newFieldsDecode() throws {
        var obj = Self.withoutOptionalFields(try Self.json("default"))
        var trees = try #require(obj["trees"] as? [String: Any])
        trees["canopyShare"] = 0.42
        obj["trees"] = trees
        var th = try #require(obj["typeThresholds"] as? [String: Any])
        th["smallAreaPercentile"] = 0.02
        th["largeAreaPercentile"] = 0.865
        th["hugeAreaPercentile"] = 0.99
        obj["typeThresholds"] = th
        let p = try Self.decode(obj)
        #expect(p.trees.canopyShare == 0.42)
        #expect(p.typeThresholds.smallAreaPercentile == 0.02)
        #expect(p.typeThresholds.largeAreaPercentile == 0.865)
        #expect(p.typeThresholds.hugeAreaPercentile == 0.99)
        #expect(p.typeThresholds.largeArea == 220)   // the absolute fallback is still there

        // JSON null counts as absent.
        th["largeAreaPercentile"] = NSNull()
        obj["typeThresholds"] = th
        trees["canopyShare"] = NSNull()
        obj["trees"] = trees
        let q = try Self.decode(obj)
        #expect(q.typeThresholds.largeAreaPercentile == nil)
        #expect(q.trees.canopyShare == nil)
    }

    @Test func provenanceAndRuleCommentsAreIgnored() throws {
        let base = Self.withoutOptionalFields(try Self.json("front-range"))
        var obj = base
        obj["provenance"] = ["comment": "doc", "typeRules.unknown": ["status": "measured", "n": 1756]] as [String: Any]
        var rules = try #require(obj["typeRules"] as? [String: Any])
        rules["comment"] = "note"
        obj["typeRules"] = rules
        let p = try Self.decode(obj)
        #expect(p == (try Self.decode(base)))
        #expect(p.typeRules["comment"] == nil)
    }

    @Test func everyBundledProfileDecodes() throws {
        let ids = try Self.styleProfileIDs()
        #expect(Set(["default", "front-range", "evanston", "wilmette", "chicago-dense-north"]).isSubset(of: Set(ids)))
        for id in ids {
            let p = try StyleLibrary.profile(id: id)
            #expect(p.id == id)
            if let c = p.trees.canopyShare { #expect((0...1).contains(c), "\(id)") }
            let t = p.typeThresholds
            let pct = [t.smallAreaPercentile, t.largeAreaPercentile, t.hugeAreaPercentile]
            #expect(pct.allSatisfy { $0 != nil }, "\(id): all engine profiles carry the relative thresholds")
            let present = pct.compactMap { $0 }
            #expect(present.allSatisfy { (0...1).contains($0) }, "\(id)")
            #expect(zip(present, present.dropFirst()).allSatisfy { $0 < $1 }, "\(id): small < large < huge")
            #expect(t.smallArea <= t.largeArea && t.largeArea <= t.hugeArea, "\(id): absolute fallback kept")
        }
        #expect(try StyleLibrary.profile(id: "wilmette").trees.canopyShare == 0.58)
        let catalog = try StyleLibrary.regions()
        #expect(ids.contains(catalog.defaultProfile))
        for r in catalog.regions { #expect(ids.contains(r.profile), "\(r.id) → \(r.profile)") }
    }

    /// Committed test areas and region-kit sample cells resolve to the expected profiles (first match).
    @Test(arguments: [
        ("Data/areas/sloans-lake", 39.7494, -105.0445, "front-range"),
        ("Data/areas/evanston-south", 42.0372, -87.6912, "evanston"),
        ("Data/areas/lakeview-sheil-park", 41.94567, -87.66361, "chicago-dense-north"),
        ("cell lakeview-gill-park", 41.9522, -87.6504, "chicago-dense-north"),
        ("cell lincoln-park-oz-park", 41.9206, -87.6457, "chicago-dense-north"),
        ("cell edgewater-broadway-armory-park", 41.9893, -87.6596, "chicago-dense-north"),
        ("cell wilmette-vattmann-park", 42.0779, -87.7137, "wilmette"),
        ("cell evanston-lovelace-park (park is in Evanston)", 42.068, -87.726, "evanston"),
        ("cell evanston-smith-park", 42.0499, -87.6932, "evanston"),
        ("cell winnetka-village-green (no engine profile)", 42.1052, -87.7289, "default"),
        ("cell kenilworth-station (no engine profile)", 42.0871, -87.7176, "default"),
        ("New York", 40.7128, -74.0060, "default"),
    ])
    func regionsResolveExpectedProfiles(_ name: String, _ lat: Double, _ lon: Double, _ expected: String) throws {
        let catalog = try StyleLibrary.regions()
        #expect(catalog.profileID(at: GeoCoordinate(latitude: lat, longitude: lon)) == expected, "\(name)")
    }

    /// The whole extent (all four corners) of the committed Chicagoland test areas and the dense-north
    /// sample cells lies in its profile's boxes, not only the centre.
    @Test func chicagolandTestAreasAndCellsAreFullyCovered() throws {
        let catalog = try StyleLibrary.regions()
        var boxes: [(String, GeoBoundingBox, String)] = []
        for (area, profile) in [("evanston-south", "evanston"), ("lakeview-sheil-park", "chicago-dense-north")] {
            let dir = Self.root.appendingPathComponent("Data/areas/\(area)")
            guard FileManager.default.fileExists(atPath: dir.appendingPathComponent("manifest.json").path) else { continue }
            boxes.append((area, try AreaLoader.loadManifest(dir).bounds, profile))
        }
        for (cell, lat, lon) in [("lakeview-gill-park", 41.9522, -87.6504), ("lincoln-park-oz-park", 41.9206, -87.6457),
                                 ("edgewater-broadway-armory-park", 41.9893, -87.6596)] {
            boxes.append((cell, GeoBoundingBox(center: GeoCoordinate(latitude: lat, longitude: lon), widthMeters: 1000, heightMeters: 1000),
                          "chicago-dense-north"))
        }
        for (name, b, profile) in boxes {
            for (lat, lon) in [(b.south, b.west), (b.south, b.east), (b.north, b.west), (b.north, b.east)] {
                #expect(catalog.profileID(at: GeoCoordinate(latitude: lat, longitude: lon)) == profile, "\(name) corner \(lat), \(lon)")
            }
        }
    }
}
