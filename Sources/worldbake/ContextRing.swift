import CryptoKit
import Foundation
import WorldGeo
import WorldMap

/// Context ring: real OpenStreetMap ground around an area at low detail, so aerial views can
/// continue real ground to the horizon instead of a detailed tile floating on a flat plane.
/// Nothing is invented: the file is an unmodified OSM extract, read by the same parser as the
/// detailed data.
///
///     worldbake fetch <dir> --layers context [--building-band-km N] [--max-mb N] [--probe 1] [--split 1] [--no-split 1] [--cache-dir PATH] [--dry-run 1]
///     worldbake stats <dir> --layers context
///
/// Ring box = the manifest's bounds expanded by 3 km on every side (the core is included).
/// Building footprints only within a band around the area's own bounds (default 1.5 km; stepped
/// down to 1.0 and 0.5 km when the file would exceed the size cap). Documentation:
/// `docs/data/context-rings.md`.
enum ContextRing {
    static let layer = "context"
    static let fileName = "context.json"
    static let queryFileName = "context.overpassql"
    static let ringMeters = 3000.0
    static let bandStepsKm = [1.5, 1.0, 0.5]
    /// Multipolygon relations with this many members or more are never pulled (a huge lake
    /// relation would drag in most of a coastline); such water appears only as coastline ways.
    static let memberCap = 300
    static let defaultMaxBytes = 25_000_000
    /// landuse=grass ways with a shorter perimeter than this are not fetched.
    static let minGrassPerimeterMeters = 200
    /// The timeout is a reservation on a shared server; large ones are the first thing a busy
    /// Overpass instance refuses (HTTP 504 "probably too busy"), so stay at the usual 180 s.
    static let queryTimeoutSeconds = 180

    // Tag values, shared by the query and by the stats report so they cannot drift apart.
    static let majorHighways = ["motorway", "trunk", "primary", "secondary", "tertiary"]
    static let minorHighways = ["unclassified", "residential", "living_street"]
    static let railways = ["rail", "light_rail", "subway", "tram", "narrow_gauge", "monorail"]
    static let waterways = ["river", "canal", "stream"]
    static let naturalAreas = ["wood", "scrub", "grassland", "wetland", "beach", "sand"]
    static let leisureAreas = ["park", "golf_course", "pitch", "playground", "garden", "nature_reserve", "recreation_ground"]

    // MARK: - Boxes

    static func ringBox(_ m: AreaManifest) -> GeoBoundingBox {
        GeoBoundingBox(center: m.center, widthMeters: m.widthMeters + 2 * ringMeters, heightMeters: m.heightMeters + 2 * ringMeters)
    }

    static func buildingBox(_ m: AreaManifest, bandKm: Double) -> GeoBoundingBox {
        GeoBoundingBox(center: m.center, widthMeters: m.widthMeters + 2 * bandKm * 1000, heightMeters: m.heightMeters + 2 * bandKm * 1000)
    }

    // MARK: - Query

    /// Query groups. One query with all four is the normal case; the groups exist so a query
    /// that times out can be split into at most four sub-queries.
    enum Part: String, CaseIterable {
        case roads, linear, areas, buildings
    }

    private static func regex(_ values: [String], link: Bool = false) -> String {
        "^(" + values.joined(separator: "|") + ")" + (link ? "(_link)?" : "") + "$"
    }

    private static func statements(_ part: Part, ring r: String, band b: String) -> [String] {
        let cap = "(if: count_members() < \(memberCap))"
        switch part {
        case .roads:
            return [
                "way[\"highway\"~\"\(regex(majorHighways, link: true))\"](\(r));",
                "way[\"highway\"~\"\(regex(minorHighways))\"](\(r));",
                "way[\"highway\"=\"service\"][\"service\"=\"alley\"](\(r));",
            ]
        case .linear:
            return [
                "way[\"railway\"~\"\(regex(railways))\"](\(r));",
                "way[\"natural\"=\"coastline\"](\(r));",
                "way[\"natural\"=\"water\"](\(r));",
                "relation[\"type\"=\"multipolygon\"][\"natural\"=\"water\"](\(r))\(cap);",
                "way[\"waterway\"~\"\(regex(waterways))\"](\(r));",
            ]
        case .areas:
            let mp = "relation[\"type\"=\"multipolygon\"]"
            return [
                // Some cities map every lawn as landuse=grass (tens of thousands of tiny polygons,
                // tens of MB); at aerial distance only the larger ones matter.
                "way[\"landuse\"][\"landuse\"!=\"grass\"](\(r));",
                "way[\"landuse\"=\"grass\"](\(r))(if: length() >= \(minGrassPerimeterMeters));",
                "way[\"natural\"~\"\(regex(naturalAreas))\"](\(r));",
                "way[\"leisure\"~\"\(regex(leisureAreas))\"](\(r));",
                "way[\"amenity\"=\"grave_yard\"](\(r));",
                "\(mp)[\"landuse\"](\(r))\(cap);",
                "\(mp)[\"natural\"~\"\(regex(naturalAreas))\"](\(r))\(cap);",
                "\(mp)[\"leisure\"~\"\(regex(leisureAreas))\"](\(r))\(cap);",
                "\(mp)[\"amenity\"=\"grave_yard\"](\(r))\(cap);",
            ]
        case .buildings:
            return [
                "way[\"building\"](\(b));",
                "relation[\"building\"][\"type\"=\"multipolygon\"](\(b))\(cap);",
            ]
        }
    }

    /// Very large water relations (the Great Lakes are mapped only as relations, never as
    /// `natural=coastline`) are not fetched whole. Instead: the relation itself without
    /// recursion (tags and member list, so a reader knows which ways are shoreline) and only
    /// its member ways that touch the ring box, with their nodes. Outside the union that is
    /// recursed with `>`, which would pull every member of the relation.
    private static func bigWaterDefinition(ring r: String) -> String {
        "relation[\"type\"=\"multipolygon\"][\"natural\"=\"water\"](\(r))(if: count_members() >= \(memberCap))->.bigwater;"
    }

    private static func bigWaterOutput(ring r: String) -> [String] {
        [".bigwater out body qt;", "way(r.bigwater)(\(r));", "(._;>;);", "out body qt;"]
    }

    /// Explicit per-statement boxes (not the global `[bbox:]`), as in `Fetcher`, so recursion
    /// is never filtered: ways and multipolygons crossing the edge come back complete.
    static func query(ring: GeoBoundingBox, buildings: GeoBoundingBox, parts: [Part] = Part.allCases) -> String {
        let r = ring.overpassString, b = buildings.overpassString
        let body = parts.flatMap { statements($0, ring: r, band: b) }.map { "  " + $0 }.joined(separator: "\n")
        let bigWater = parts.contains(.linear)
        var q = "[out:json][timeout:\(queryTimeoutSeconds)];\n"
        if bigWater { q += bigWaterDefinition(ring: r) + "\n" }
        q += "(\n\(body)\n);\n(._;>;);\nout body qt;\n"
        if bigWater { q += bigWaterOutput(ring: r).joined(separator: "\n") + "\n" }
        return q
    }

    // MARK: - Fetch

    static func fetch(dir: URL, options: [String: String]) async throws {
        var manifest = try AreaLoader.loadManifest(dir)
        let ring = ringBox(manifest)
        let startBand = options["building-band-km"].flatMap(Double.init) ?? bandStepsKm[0]
        let bands = bandStepsKm.filter { $0 <= startBand + 1e-9 }
        guard !bands.isEmpty else { throw ToolError.usage("--building-band-km must be at least \(bandStepsKm.last!)") }
        let maxBytes = options["max-mb"].flatMap(Double.init).map { Int($0 * 1_000_000) } ?? defaultMaxBytes
        var client = Overpass()

        if options["probe"] != nil {
            try await probe(manifest: manifest, bands: bandStepsKm, client: &client)
            return
        }

        if options["dry-run"] != nil {
            print(query(ring: ring, buildings: buildingBox(manifest, bandKm: bands[0])), terminator: "")
            return
        }
        log("ring box \(ring.overpassString) (area bounds + \(Int(ringMeters)) m)")
        for band in bands {
            let buildings = buildingBox(manifest, bandKm: band)
            log("building band \(band) km: box \(buildings.overpassString)")
            let result = try await fetchOnce(ring: ring, buildings: buildings, forceSplit: options["split"] != nil, noSplit: options["no-split"] != nil,
                                          cache: options["cache-dir"].map { URL(fileURLWithPath: $0, isDirectory: true) }, name: manifest.id, client: &client)
            if result.data.count > maxBytes {
                log(String(format: "context.json would be %.1f MB (cap %.1f MB): shrinking the building band", Double(result.data.count) / 1e6, Double(maxBytes) / 1e6))
                continue
            }
            let doc = try OSMDocument(overpassJSON: result.data)
            try result.data.write(to: dir.appendingPathComponent(fileName))
            try result.queryText.write(to: dir.appendingPathComponent(queryFileName), atomically: true, encoding: .utf8)
            let source = AreaManifest.Source(
                format: "osm-overpass-json", path: fileName, layers: [layer], bounds: ring,
                dataTimestamp: doc.timestamp,
                fetchedAt: ISO8601DateFormatter().string(from: Date()),
                bytes: result.data.count,
                sha256: SHA256.hash(data: result.data).map { String(format: "%02x", $0) }.joined(),
                license: "ODbL-1.0",
                attribution: "© OpenStreetMap contributors"
            )
            manifest.sources.removeAll { $0.path == source.path }
            manifest.sources.append(source)
            try writeManifest(manifest, to: dir)
            try appendNotice(dir: dir, bandKm: band)
            print(String(format: "Wrote %@: %.2f MB, OSM data %@, building band %.1f km, %d nodes / %d ways / %d relations",
                         fileName, Double(result.data.count) / 1e6, doc.timestamp ?? "?", band, doc.nodes.count, doc.ways.count, doc.relations.count))
            print(String(format: "Downloaded in this run: %.2f MB after decoding, %.2f MB on the wire, %d request(s)",
                         Double(client.decodedBytes) / 1e6, Double(client.wireBytes) / 1e6, client.requests))
            return
        }
        throw ToolError.fetchFailed("context.json exceeds the size cap even with a \(bandStepsKm.last!) km building band; nothing was written")
    }

    private struct Result {
        var data: Data
        var queryText: String
    }

    private static func fetchOnce(ring: GeoBoundingBox, buildings: GeoBoundingBox, forceSplit: Bool, noSplit: Bool, cache: URL?, name: String, client: inout Overpass) async throws -> Result {
        if !forceSplit {
            let q = query(ring: ring, buildings: buildings)
            do {
                return Result(data: try await client.request(q, heavyOn504: true), queryText: q)
            } catch Overpass.Failure.tooHeavy(let why) {
                // --no-split: keep the file a single, byte-for-byte Overpass response; fail and retry later.
                if noSplit { throw Overpass.Failure.tooHeavy(why) }
                log("single query too heavy (\(why)): splitting into \(Part.allCases.count) sub-queries")
            }
        }
        var datas: [Data] = []
        var texts: [String] = []
        for part in Part.allCases {
            let q = query(ring: ring, buildings: buildings, parts: [part])
            log("sub-query \(part.rawValue)")
            // Optional scratch cache (--cache-dir): a re-run after a failure resumes instead of
            // downloading finished parts again. Keyed by the exact query text.
            let key = SHA256.hash(data: Data(q.utf8)).prefix(6).map { String(format: "%02x", $0) }.joined()
            let cached = cache?.appendingPathComponent("\(name)-\(part.rawValue)-\(key).json")
            if let cached, let data = try? Data(contentsOf: cached) {
                log("sub-query \(part.rawValue): using cached response \(cached.lastPathComponent) (\(data.count) bytes)")
                datas.append(data)
            } else {
                let data = try await client.request(q)
                if let cached { try? data.write(to: cached) }
                datas.append(data)
            }
            texts.append("// part: \(part.rawValue)\n" + q)
        }
        return Result(data: try merge(datas), queryText: texts.joined(separator: "\n"))
    }

    /// Joins the sub-query responses, de-duplicating elements by (type, id). Only used after a
    /// timeout; numbers are re-serialised (same values, possibly different float formatting).
    static func merge(_ responses: [Data]) throws -> Data {
        var elements: [[String: Any]] = []
        var seen = Set<String>()
        var stamp: String?
        for data in responses {
            guard let top = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let els = top["elements"] as? [[String: Any]] else { throw ToolError.fetchFailed("unexpected response shape") }
            if let t = (top["osm3s"] as? [String: Any])?["timestamp_osm_base"] as? String, stamp == nil || t < stamp! { stamp = t }
            for e in els {
                guard let type = e["type"] as? String, let id = e["id"] as? NSNumber else { continue }
                if seen.insert("\(type)/\(id)").inserted { elements.append(e) }
            }
        }
        let top: [String: Any] = [
            "version": 0.6, "generator": "Overpass API (merged sub-queries)",
            "osm3s": ["timestamp_osm_base": stamp ?? "", "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."],
            "elements": elements,
        ]
        return try JSONSerialization.data(withJSONObject: top, options: [.withoutEscapingSlashes])
    }

    /// Building counts per band in one cheap request (no recursion, counts only), to choose a
    /// starting band that will fit the size cap.
    private static func probe(manifest: AreaManifest, bands: [Double], client: inout Overpass) async throws {
        var q = "[out:json][timeout:120];\n"
        for band in bands { q += "way[\"building\"](\(buildingBox(manifest, bandKm: band).overpassString));\nout count;\n" }
        let data = try await client.request(q)
        struct Counts: Decodable { struct E: Decodable { var tags: [String: String]? }; var elements: [E] }
        let counts = try JSONDecoder().decode(Counts.self, from: data).elements.compactMap { $0.tags?["ways"].flatMap(Int.init) }
        for (band, n) in zip(bands, counts) { print("building band \(band) km: \(n) building ways") }
    }

    private static func appendNotice(dir: URL, bandKm: Double) throws {
        let url = dir.appendingPathComponent("NOTICE.md")
        var text = (try? String(contentsOf: url, encoding: .utf8)) ?? "# Data notice\n"
        // Re-running replaces an earlier context paragraph (it states the band and the query's rules).
        if let r = text.range(of: "\n## Context ring") { text = String(text[..<r.lowerBound]) }
        text = text.trimmingCharacters(in: .newlines) + "\n"
        text += """

        ## Context ring

        `context.json` is an unmodified extract of OpenStreetMap data (same license as above), fetched with `out body` by `worldbake fetch --layers context` using the query in `context.overpassql`. Purpose: low-detail real ground around the area (main and residential roads, rail, water, coastline, landuse and park areas, and building footprints only within \(String(format: "%g", bandKm)) km of the area box; `landuse=grass` ways with a perimeter under \(minGrassPerimeterMeters) m are left out) so aerial views continue real ground to the horizon. It covers the area box plus \(Int(ringMeters / 1000)) km on every side and is not loaded into the detailed street-level world. Water relations with \(memberCap) or more members (very large lakes and seas) are not fetched whole: the file carries the relation itself (tags and member list, not recursed) and only those member ways that touch the ring box, so the shoreline inside the ring is present as open way segments and the relation's other members are not in the file. Open-sea shorelines also arrive as `natural=coastline` ways (land on the left of the way direction) where OSM maps them that way; the Great Lakes are not mapped as coastline. See `docs/data/context-rings.md`.

        """
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    static func log(_ s: String) {
        FileHandle.standardError.write("  context: \(s)\n".data(using: .utf8)!)
    }

    // MARK: - Overpass client

    /// One request at a time, at least 5 s apart, the same User-Agent and endpoints as
    /// `Fetcher`, and a back-off of at least 60 s on 429 or 504.
    struct Overpass {
        enum Failure: Error, CustomStringConvertible {
            case tooHeavy(String)
            case blocked(String)
            case badQuery(String)
            var description: String {
                switch self {
                case .tooHeavy(let s): "query too heavy: \(s)"
                case .blocked(let s): "blocked: \(s)"
                case .badQuery(let s): "query rejected: \(s)"
                }
            }
        }

        static let userAgent = "WorldEngine-worldbake/0.1 (offline map data bake tool)"
        static let minGap: TimeInterval = 5
        static let backoff: Duration = .seconds(65)

        var lastRequestEnd: Date?
        var decodedBytes = 0
        var wireBytes = 0
        var requests = 0

        private enum Outcome {
            case ok(Data)
            case busy(String)
            case failed(String)
        }

        private final class Metrics: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
            var wire = 0
            func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
                wire = metrics.transactionMetrics.reduce(0) { $0 + Int($1.countOfResponseBodyBytesReceived) }
            }
        }

        private struct Remark: Decodable { var remark: String? }

        /// `heavyOn504`: for the single combined query, a 504 that repeats on every try of the main server counts
        /// as "timed out" (the caller then splits the query) instead of trying every mirror.
        mutating func request(_ query: String, heavyOn504: Bool = false) async throws -> Data {
            var lastError = "no endpoints"
            for endpoint in Fetcher.endpoints {
                // The main server gets five tries (a 504 within seconds means "busy"); each
                // mirror one, so a slow mirror is not hammered.
                let maxAttempts = endpoint == Fetcher.endpoints.first ? 5 : 1
                var attempt = 0
                while attempt < maxAttempts {
                    attempt += 1
                    if let last = lastRequestEnd {
                        let wait = Overpass.minGap - Date().timeIntervalSince(last)
                        if wait > 0 { try await Task.sleep(for: .seconds(wait)) }
                    }
                    let outcome = try await post(query, to: endpoint)
                    lastRequestEnd = Date()
                    switch outcome {
                    case .ok(let data):
                        return data
                    case .busy(let why):
                        // 429 or 504: wait at least 60 s before the next request.
                        lastError = "\(endpoint): \(why)"
                        ContextRing.log("\(lastError); backing off \(Overpass.backoff)")
                        try await Task.sleep(for: Overpass.backoff)
                        lastRequestEnd = Date()
                        if heavyOn504, attempt == maxAttempts, why == "HTTP 504" { throw Failure.tooHeavy("HTTP 504 on all \(maxAttempts) tries from \(endpoint)") }
                    case .failed(let why):
                        lastError = "\(endpoint): \(why)"
                        ContextRing.log(lastError)
                        attempt = maxAttempts
                    }
                }
            }
            throw ToolError.fetchFailed(lastError)
        }

        private mutating func post(_ query: String, to endpoint: String) async throws -> Outcome {
            var req = URLRequest(url: URL(string: endpoint)!)
            req.httpMethod = "POST"
            req.timeoutInterval = TimeInterval(ContextRing.queryTimeoutSeconds + 120)
            req.setValue(Overpass.userAgent, forHTTPHeaderField: "User-Agent")
            req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            req.httpBody = ("data=" + query.addingPercentEncoding(withAllowedCharacters: allowed)!).data(using: .utf8)
            requests += 1
            let started = Date()
            ContextRing.log("request \(requests) to \(endpoint)")
            let metrics = Metrics()
            let data: Data, response: URLResponse
            do {
                (data, response) = try await URLSession.shared.data(for: req, delegate: metrics)
            } catch {
                ContextRing.log(String(format: "request error after %.0f s", Date().timeIntervalSince(started)))
                return .failed("\(error)")
            }
            decodedBytes += data.count
            wireBytes += metrics.wire
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            ContextRing.log(String(format: "HTTP %d, %.2f MB decoded, %.2f MB on the wire, %.0f s", status, Double(data.count) / 1e6, Double(metrics.wire) / 1e6, Date().timeIntervalSince(started)))
            let head = String(data: data.prefix(300), encoding: .utf8) ?? ""
            switch status {
            case 200:
                guard data.first == UInt8(ascii: "{") else {
                    if head.contains("timed out") || head.contains("out of memory") { throw Failure.tooHeavy(head) }
                    return .failed("HTTP 200 but not JSON, \(data.count) bytes")
                }
                // A query that dies mid-way still answers 200, with a "remark" after partial data.
                if let remark = try? JSONDecoder().decode(Remark.self, from: data).remark {
                    if remark.contains("rate_limited") { return .busy("rate limited: \(remark)") }
                    if remark.contains("runtime error") { throw Failure.tooHeavy(remark) }
                    return .failed("remark: \(remark)")
                }
                return .ok(data)
            case 429, 504:
                return .busy("HTTP \(status)")
            case 400:
                throw Failure.badQuery(head)
            case 403:
                // The owner's rule: if a site blocks us, stop, do not try another way.
                throw Failure.blocked("HTTP 403 from \(endpoint)")
            default:
                return .failed("HTTP \(status), \(data.count) bytes")
            }
        }
    }

    // MARK: - Stats

    /// Element counts of the context file alone, read through `AreaLoader` (so the same parser
    /// and manifest path the renderer will use), plus proof that the detailed features are
    /// unaffected by the extra source.
    static func stats(dir: URL) throws -> String {
        let manifest = try AreaLoader.loadManifest(dir)
        guard let src = manifest.sources.first(where: { $0.layers.contains(layer) }) else {
            throw ToolError.usage("\(dir.lastPathComponent) has no context source; run: worldbake fetch <dir> --layers context")
        }
        // The context source alone (sources containing "all" are always loaded by loadDocument).
        var only = manifest
        only.sources = [src]
        let doc = try AreaLoader.loadDocument(dir, manifest: only, layers: [layer])
        // As the renderer would ask for it next to the detailed data.
        let merged = try AreaLoader.loadDocument(dir, manifest: manifest, layers: [layer])
        let detailed = try AreaLoader.loadFeatures(dir)

        func count(_ pred: (OSMWay) -> Bool) -> Int { doc.ways.values.filter(pred).count }
        func tag(_ w: OSMWay, _ k: String) -> String? { w.tags[k] }
        func base(_ v: String?) -> String? { v.map { $0.hasSuffix("_link") ? String($0.dropLast(5)) : $0 } }

        var md = "# Context ring: \(manifest.name)\n\n"
        md += String(format: "`%@`: %.2f MB, OSM data %@, box %@ (area bounds + %d km)\n\n", src.path, Double(src.bytes ?? 0) / 1e6,
                     src.dataTimestamp ?? "?", src.bounds.overpassString, Int(ringMeters / 1000))
        md += "## Elements\n\n| Kind | Count |\n|---|---:|\n"
        md += "| nodes | \(doc.nodes.count) (\(doc.nodes.values.filter { !$0.tags.isEmpty }.count) tagged) |\n"
        md += "| ways | \(doc.ways.count) (\(doc.ways.values.filter { $0.tags.isEmpty }.count) untagged: relation members) |\n"
        md += "| relations | \(doc.relations.count) |\n"

        md += "\n## Ways by category\n\n| Category | Ways |\n|---|---:|\n"
        for h in majorHighways + minorHighways {
            md += "| highway=\(h)\(majorHighways.contains(h) ? " (+_link)" : "") | \(count { base(tag($0, "highway")) == h }) |\n"
        }
        md += "| highway=service, service=alley | \(count { tag($0, "highway") == "service" && tag($0, "service") == "alley" }) |\n"
        for r in railways { md += "| railway=\(r) | \(count { tag($0, "railway") == r }) |\n" }
        md += "| **natural=coastline** | \(count { tag($0, "natural") == "coastline" }) |\n"
        md += "| water polygons (natural=water) | \(count { tag($0, "natural") == "water" }) |\n"
        for w in waterways { md += "| waterway=\(w) | \(count { tag($0, "waterway") == w }) |\n" }
        md += "| landuse=* | \(count { tag($0, "landuse") != nil }) |\n"
        for n in naturalAreas { md += "| natural=\(n) | \(count { tag($0, "natural") == n }) |\n" }
        for l in leisureAreas { md += "| leisure=\(l) | \(count { tag($0, "leisure") == l }) |\n" }
        md += "| amenity=grave_yard | \(count { tag($0, "amenity") == "grave_yard" }) |\n"
        let buildingWays = doc.ways.values.filter { $0.tags["building"] != nil }
        md += "| **building footprints (ways)** | \(buildingWays.count) |\n"

        func rel(_ pred: (OSMRelation) -> Bool) -> Int { doc.relations.values.filter(pred).count }
        md += "\n## Relations by category (fewer than \(memberCap) members)\n\n| Category | Relations |\n|---|---:|\n"
        md += "| water multipolygons | \(rel { $0.members.count < memberCap && $0.tags["natural"] == "water" }) |\n"
        md += "| landuse / natural / leisure / grave_yard multipolygons | \(rel { $0.members.count < memberCap && $0.tags["natural"] != "water" && $0.tags["building"] == nil }) |\n"
        md += "| building multipolygons | \(rel { $0.members.count < memberCap && $0.tags["building"] != nil }) |\n"
        md += "| largest of these (members) | \(doc.relations.values.map(\.members.count).filter { $0 < memberCap }.max() ?? 0) |\n"

        // Where the building footprints reach, in meters beyond the area box.
        let frame = manifest.frame, box = manifest.localBounds
        var east = 0.0, west = 0.0, north = 0.0, south = 0.0
        for w in buildingWays {
            guard let cs = doc.coordinates(of: w) else { continue }
            for c in cs {
                let p = frame.localPoint(of: c)
                east = max(east, p.x - box.max.x); west = max(west, box.min.x - p.x)
                north = max(north, p.y - box.max.y); south = max(south, box.min.y - p.y)
            }
        }
        md += String(format: "\nBuilding footprints reach at most %.0f m east, %.0f m west, %.0f m north, %.0f m south beyond the area box.\n", east, west, north, south)

        // Very large water relations: only the relation (tags, member list) and its member ways
        // touching the ring box are in the file.
        let big = doc.relations.values.filter { $0.members.count >= memberCap }
        md += "\n## Very large water relations (members >= \(memberCap))\n\n"
        if big.isEmpty {
            md += "None in the ring box.\n"
        } else {
            md += "| Relation | Name | Members listed | Member ways in this file | Their nodes |\n|---|---|---:|---:|---:|\n"
            for r in big.sorted(by: { $0.id < $1.id }) {
                let present = r.members.filter { $0.kind == .way && doc.ways[$0.ref] != nil }.map { doc.ways[$0.ref]! }
                md += "| relation/\(r.id) | \(r.tags["name"] ?? "") | \(r.members.count) | \(present.count) | \(Set(present.flatMap(\.nodeIDs)).count) |\n"
            }
        }

        // What the renderer will get from the shared feature builder, bounds = the ring box.
        let corners: [LocalPoint] = [src.bounds.south, src.bounds.north].flatMap { lat in
            [src.bounds.west, src.bounds.east].map { frame.localPoint(of: GeoCoordinate(latitude: lat, longitude: $0)) }
        }
        let feats = MapFeatureBuilder(frame: frame, bounds: Rect2D(enclosing: corners)).build(doc)
        md += "\n## Shared feature builder on the context document (bounds = ring box)\n\n"
        md += "\(feats.buildings.filter { !$0.isPart }.count) buildings, \(feats.roads.count) roads, \(feats.paths.count) paths, \(feats.areas.count) areas ("
        md += Dictionary(grouping: feats.areas, by: \.kind).sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue) \($0.value.count)" }.joined(separator: ", ")
        md += "), \(feats.lines.count) lines, \(feats.points.count) points; \(feats.report.skipped.count) skipped"
        let reasons = Dictionary(grouping: feats.report.skipped, by: \.reason).mapValues(\.count).sorted { $0.value > $1.value }.prefix(5)
        md += reasons.isEmpty ? ".\n" : ": " + reasons.map { "\($0.value) x \($0.key)" }.joined(separator: "; ") + ".\n"

        md += "\n## Loader checks\n\n"
        md += "- `AreaLoader.loadDocument(layers: [\"context\"])` on the context source alone: \(doc.nodes.count) nodes, \(doc.ways.count) ways, \(doc.relations.count) relations.\n"
        md += "- The same call on the full manifest (sources with layer `all` are always loaded): \(merged.nodes.count) nodes, \(merged.ways.count) ways, \(merged.relations.count) relations.\n"
        md += "- `AreaLoader.loadFeatures` (detailed world, layer `all` only): \(detailed.buildings.filter { !$0.isPart }.count) buildings, \(detailed.roads.count) roads, \(detailed.paths.count) paths, \(detailed.areas.count) areas; read \(detailed.report.nodeCount) nodes, \(detailed.report.wayCount) ways, \(detailed.report.relationCount) relations.\n"
        return md
    }
}
