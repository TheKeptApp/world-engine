import Foundation
import WorldGeo

/// Overture Maps buildings as a second footprint source (manifest format "overture-buildings-v1").
///
/// OpenStreetMap stays the primary source. Overture only fills footprints OSM lacks:
/// - records with any OpenStreetMap source are dropped (OSM already has them);
/// - footprints whose centroid lies inside any OSM `building` or `building:part` footprint are
///   dropped (in the document, so also OSM buildings whose own centroid is outside the area);
/// - footprints are kept whole when their centroid is inside the area, like OSM buildings;
/// - footprints are cleaned exactly like OSM ones (outer ring CCW, holes CW, under 1 m² dropped).
///
/// Survivors become ordinary `Building`s with OSM-style tags, so the generator, height rules and
/// renderers need no Overture-specific code. File format and rules: docs/research/overture-source.md.
public enum OvertureBuildings {
    public static let format = "overture-buildings-v1"
    public static let fileName = "overture-buildings.json"
    /// The dataset name Overture uses for OpenStreetMap records.
    public static let osmDataset = "OpenStreetMap"

    // MARK: - File format

    /// `overture-buildings.json`, written by `worldbake fetch <dir> --layers overture`.
    public struct File: Codable, Sendable, Equatable {
        public var format: String
        /// Overture release, e.g. "2026-09-23.1".
        public var release: String
        public var theme: String?
        public var type: String?
        /// Licence of the theme as stated by Overture's STAC collection (ODbL-1.0 for buildings).
        public var license: String?
        /// The box that was queried (records whose bbox meets it).
        public var bbox: GeoBoundingBox?
        /// The GeoParquet files that were read.
        public var files: [String]?
        /// Every dataset named in any record's `sources`, with Overture's licence for it.
        public var datasets: [Dataset]
        public var buildings: [Record]

        public init(release: String, datasets: [Dataset], buildings: [Record]) {
            self.format = OvertureBuildings.format
            self.release = release
            self.datasets = datasets
            self.buildings = buildings
        }
    }

    public struct Dataset: Codable, Sendable, Equatable {
        public var dataset: String
        public var license: String?
        /// Records naming this dataset in any source entry.
        public var records: Int?

        public init(dataset: String, license: String? = nil, records: Int? = nil) {
            self.dataset = dataset
            self.license = license
            self.records = records
        }
    }

    /// One Overture building. Optional fields are omitted from the file when Overture has none.
    public struct Record: Codable, Sendable, Equatable {
        /// GERS ID.
        public var id: String
        /// GeoJSON MultiPolygon coordinates: polygons → rings (first outer, then holes) → [lon, lat].
        public var polygons: [[[[Double]]]]
        /// Meters.
        public var height: Double?
        public var minHeight: Double?
        public var numFloors: Int?
        public var roofShape: String?
        public var buildingClass: String?
        public var subtype: String?
        public var sources: [SourceRef]

        enum CodingKeys: String, CodingKey {
            case id, polygons, height, subtype, sources
            case minHeight = "min_height", numFloors = "num_floors", roofShape = "roof_shape", buildingClass = "class"
        }

        public init(id: String, polygons: [[[[Double]]]], height: Double? = nil, minHeight: Double? = nil, numFloors: Int? = nil,
                    roofShape: String? = nil, buildingClass: String? = nil, subtype: String? = nil, sources: [SourceRef]) {
            self.id = id
            self.polygons = polygons
            self.height = height
            self.minHeight = minHeight
            self.numFloors = numFloors
            self.roofShape = roofShape
            self.buildingClass = buildingClass
            self.subtype = subtype
            self.sources = sources
        }

        /// Distinct datasets in source order.
        public var datasets: [String] {
            var seen = Set<String>()
            return sources.map(\.dataset).filter { seen.insert($0).inserted }
        }

        public var hasOSMSource: Bool { sources.contains { $0.dataset == OvertureBuildings.osmDataset } }
    }

    public struct SourceRef: Codable, Sendable, Equatable {
        public var dataset: String
        public var recordID: String?
        /// JSON pointer of the property this source supplied (e.g. "/properties/height");
        /// nil for the geometry source.
        public var property: String?

        enum CodingKeys: String, CodingKey {
            case dataset, property
            case recordID = "record_id"
        }

        public init(dataset: String, recordID: String? = nil, property: String? = nil) {
            self.dataset = dataset
            self.recordID = recordID
            self.property = property
        }
    }

    public static func decode(_ data: Data) throws -> File {
        let file = try JSONDecoder().decode(File.self, from: data)
        guard file.format == format else { throw AreaLoader.LoadError.unsupportedFormat(file.format) }
        return file
    }

    // MARK: - Tags

    /// Overture `class` values that differ from the OSM `building=*` value for the same thing.
    /// Every other class is already an OSM value (Overture derives the list from OSM).
    public static let classToOSM: [String: String] = [
        "semi": "semidetached_house",
        "bridge_structure": "bridge",
        "dwelling_house": "house",
    ]

    /// Footprints at least this large (m², house-sized) ignore a Microsoft ML height.
    public static let mlHeightMinDropArea = 90.0
    public static let microsoftDataset = "Microsoft ML Buildings"

    /// The dataset that supplied a record's height: the source for `/properties/height`, else the
    /// first non-OSM (geometry) source.
    public static func heightDataset(_ r: Record) -> String? {
        if let s = r.sources.first(where: { $0.property == "/properties/height" }) { return s.dataset }
        return r.sources.first { $0.dataset != osmDataset }?.dataset
    }

    /// OSM-style tags for a record. `HeightRules` reads `height`, `min_height` and
    /// `building:levels` exactly as it does for OSM buildings.
    public static func tags(for r: Record) -> Tags {
        var t: Tags = ["building": r.buildingClass.map { classToOSM[$0] ?? $0 } ?? "yes"]
        if let h = r.height, h > 0 { t["height"] = number(h) }
        if let h = r.minHeight, h > 0 { t["min_height"] = number(h) }
        if let n = r.numFloors, n > 0 { t["building:levels"] = String(n) }
        if let s = r.roofShape, !s.isEmpty { t["roof:shape"] = s }
        t["overture:id"] = r.id
        t["overture:sources"] = r.datasets.joined(separator: ",")
        return t
    }

    private static func number(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }

    // MARK: - Credits

    /// Credit lines for Overture building datasets, keyed by Overture's `dataset` name. Wording
    /// follows https://docs.overturemaps.org/attribution/#buildings (checked 2026-10-06).
    public static let datasetCredits: [String: String] = [
        "Microsoft ML Buildings": "Microsoft Global ML Building Footprints (ODbL)",
        "Esri Community Maps": "Esri Community Maps contributors (CC BY 4.0)",
        "Google Open Buildings": "Google Open Buildings (CC BY 4.0)",
        "USGS Lidar": "USGS 3D Elevation Program",
    ]

    /// Overture's own line for OSM-based data.
    public static let baseAttribution = "© OpenStreetMap contributors, Overture Maps Foundation"

    /// Credits for the non-OSM datasets present, sorted. A dataset without a known credit falls
    /// back to its name plus the licence Overture gives for it.
    public static func credits(for datasets: [Dataset]) -> [String] {
        var out = Set<String>()
        for d in datasets where d.dataset != osmDataset {
            if let c = datasetCredits[d.dataset] {
                out.insert(c)
            } else if let l = d.license, !l.isEmpty {
                out.insert("\(d.dataset) (\(l))")
            } else {
                out.insert(d.dataset)
            }
        }
        return out.sorted()
    }

    /// Datasets with no entry in `datasetCredits` (their credit is a fallback; check the wording).
    public static func uncreditedDatasets(_ datasets: [Dataset]) -> [String] {
        datasets.map(\.dataset).filter { $0 != osmDataset && datasetCredits[$0] == nil }.sorted()
    }

    /// The manifest `attribution` for an Overture buildings source.
    public static func attribution(for datasets: [Dataset]) -> String {
        ([baseAttribution] + credits(for: datasets)).joined(separator: "; ")
    }

    /// Paragraph for the area's NOTICE.md.
    public static func notice(release: String, datasets: [Dataset]) -> String {
        let credits = credits(for: datasets)
        let contains = credits.isEmpty ? "" : " Contains \(credits.joined(separator: "; "))."
        return "Building footprints in `\(fileName)` come from the Overture Maps Foundation buildings theme (release \(release)), "
            + "licensed under ODbL 1.0: \(baseAttribution).\(contains) "
            + "OpenStreetMap buildings take precedence; Overture fills only footprints OSM lacks."
    }

    // MARK: - Merge

    /// Reads every "overture-buildings-v1" source of the manifest and appends the buildings OSM
    /// lacks. Does nothing (and reads nothing) when the manifest has no such source.
    public static func merge(directory: URL, manifest: AreaManifest, osm doc: OSMDocument,
                             heightRules: HeightRules, into features: inout MapFeatures) throws {
        let sources = manifest.sources.filter { $0.format == format }
        guard !sources.isEmpty else { return }
        let files = try sources.map { try decode(Data(contentsOf: directory.appendingPathComponent($0.path))) }
        merge(files, osmFootprints: osmBuildingFootprints(doc, frame: features.frame), heightRules: heightRules, into: &features)
    }

    /// Appends Overture buildings to `features` (whose frame and bounds are used). Records are
    /// processed in GERS ID order; an ID seen in an earlier file is skipped.
    public static func merge(_ files: [File], osmFootprints: [Polygon2D], heightRules: HeightRules, into out: inout MapFeatures) {
        let index = FootprintIndex(osmFootprints)
        var seenIDs = Set<String>()
        var seenRefs: [OSMRef: String] = [:]
        var report = OvertureMergeReport()
        for file in files {
            for r in file.buildings.sorted(by: { $0.id < $1.id }) where seenIDs.insert(r.id).inserted {
                report.records += 1
                if r.hasOSMSource {
                    report.droppedOSMSource += 1
                    continue
                }
                guard let ref = OSMRef(overtureID: r.id) else {
                    report.skipped += 1
                    continue
                }
                if let other = seenRefs[ref], other != r.id {
                    // Two GERS IDs sharing their first 16 hex digits: keep the first (by ID order).
                    out.report.skipped.append(.init(ref: ref, reason: "Overture ID collision with \(other)"))
                    report.skipped += 1
                    continue
                }
                seenRefs[ref] = r.id
                let tags = tags(for: r)
                let type = tags["building"] ?? "yes"
                var added = false, insideOSM = false, outside = false
                for poly in r.polygons {
                    guard let polygon = localPolygon(poly, frame: out.frame) else { continue }
                    let c = polygon.centroid
                    guard out.bounds.contains(c) else { outside = true; continue }
                    if index.contains(c) { insideOSM = true; continue }
                    guard let clean = polygon.cleaned(minArea: 1.0) else {
                        out.report.skipped.append(.init(ref: ref, reason: "degenerate footprint"))
                        continue
                    }
                    // Microsoft ML heights run ~2.9 m below the roof top on house-sized footprints (3DEP lidar,
                    // docs/research/overture-source.md "Heights vs lidar"), so there the profile defaults apply.
                    var bTags = tags
                    if clean.area >= mlHeightMinDropArea, heightDataset(r) == microsoftDataset { bTags["height"] = nil }
                    out.buildings.append(Building(
                        ref: ref, footprint: clean, tags: bTags, type: type, isPart: false,
                        height: heightRules.resolve(tags: bTags, type: type, ref: ref)
                    ))
                    report.buildings += 1
                    added = true
                }
                if added { report.added += 1 }
                else if insideOSM { report.droppedInsideOSM += 1 }
                else if outside { report.droppedOutsideBounds += 1 }
                else { report.skipped += 1 }
            }
        }
        out.report.overture = report
    }

    /// GeoJSON polygon rings → local polygon (closing point removed). Nil without a usable outer ring.
    static func localPolygon(_ rings: [[[Double]]], frame: LocalFrame) -> Polygon2D? {
        func ring(_ coords: [[Double]]) -> Ring? {
            var r: Ring = coords.compactMap { c in
                c.count >= 2 ? frame.localPoint(of: GeoCoordinate(latitude: c[1], longitude: c[0])) : nil
            }
            if r.count > 1, r.first == r.last { r.removeLast() }
            return r.count >= 3 ? r : nil
        }
        guard let first = rings.first, let outer = ring(first) else { return nil }
        return Polygon2D(outer: outer, holes: rings.dropFirst().compactMap(ring))
    }

    /// Every OSM building and building:part footprint in the document, whether or not its
    /// centroid is inside the area. Used only for the "OSM wins" containment test.
    public static func osmBuildingFootprints(_ doc: OSMDocument, frame: LocalFrame) -> [Polygon2D] {
        var out: [Polygon2D] = []
        for way in doc.ways.values.sorted(by: { $0.id < $1.id })
        where way.isClosed && way.tags["area"] != "no" && MapFeatureBuilder.buildingType(way.tags) != nil {
            guard let coords = doc.coordinates(of: way) else { continue }
            out.append(Polygon2D(outer: coords.dropLast().map(frame.localPoint(of:))))
        }
        for rel in doc.relations.values.sorted(by: { $0.id < $1.id })
        where (rel.tags["type"] == "multipolygon" || rel.tags["type"] == "building") && MapFeatureBuilder.buildingType(rel.tags) != nil {
            if case .success(let polygons) = MultipolygonAssembler.assemble(rel, in: doc, frame: frame) {
                out += polygons
            }
        }
        return out
    }

    /// Uniform-grid lookup: is a point inside any of the footprints?
    struct FootprintIndex {
        static let cell = 32.0
        let polygons: [Polygon2D]
        let bounds: [Rect2D]
        var cells: [SIMD2<Int>: [Int]] = [:]

        init(_ polygons: [Polygon2D]) {
            self.polygons = polygons
            bounds = polygons.map(\.bounds)
            for (i, b) in bounds.enumerated() {
                let lo = Self.key(b.min), hi = Self.key(b.max)
                for x in lo.x...hi.x { for y in lo.y...hi.y { cells[SIMD2(x, y), default: []].append(i) } }
            }
        }

        static func key(_ p: LocalPoint) -> SIMD2<Int> {
            SIMD2(Int((p.x / cell).rounded(.down)), Int((p.y / cell).rounded(.down)))
        }

        func contains(_ p: LocalPoint) -> Bool {
            (cells[Self.key(p)] ?? []).contains { bounds[$0].contains(p) && polygons[$0].contains(p) }
        }
    }
}

/// What the Overture merge did, per load (in `LoadReport.overture`). All zero without an
/// Overture source.
public struct OvertureMergeReport: Sendable, Equatable {
    /// Distinct records read.
    public var records = 0
    /// Records with an OpenStreetMap source (OSM already has them).
    public var droppedOSMSource = 0
    /// Records whose every in-area footprint centroid lies inside an OSM building or part.
    public var droppedInsideOSM = 0
    /// Records with no footprint centroid inside the area.
    public var droppedOutsideBounds = 0
    /// Records with no usable footprint or ID.
    public var skipped = 0
    /// Records that added at least one building.
    public var added = 0
    /// Buildings appended (a MultiPolygon record can add several, sharing one ref).
    public var buildings = 0

    public init() {}
}

extension OSMRef {
    /// The ref for an Overture feature: the first 16 hex digits of its GERS ID (hyphens
    /// ignored) as a UInt64, stored bit for bit in `id`. Nil if the ID has fewer than 16 hex
    /// digits.
    public init?(overtureID gers: String) {
        let hex = gers.filter { $0 != "-" }.prefix(16)
        guard hex.count == 16, let v = UInt64(hex, radix: 16) else { return nil }
        self.init(.overture, Int64(bitPattern: v))
    }
}
