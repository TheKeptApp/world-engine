import CryptoKit
import Foundation
import WorldGeo
import WorldMap

/// Downloads raw OSM data for an area from the Overpass API.
///
/// Public Overpass servers are for occasional developer fetches like this one, never an app
/// backend. One request per fetch, an identifying User-Agent, and mirror fallback.
enum Fetcher {
    static let endpoints = [
        "https://overpass-api.de/api/interpreter",
        "https://overpass.private.coffee/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
    ]

    /// `out body` (not `out meta`) keeps contributor usernames, user IDs and edit times out of
    /// the data.
    static func query(layer: String, bbox: GeoBoundingBox) throws -> String {
        // Explicit per-statement boxes (not the global [bbox:] setting) so recursion (`>`) is
        // never filtered: ways and multipolygons crossing the edge come back complete.
        let b = "(\(bbox.overpassString))"
        let header = "[out:json][timeout:180];"
        switch layer {
        case "all":
            // Everything mapped in the box, plus complete multipolygons that reach into it.
            // Route/boundary relations are left out: their members can span whole cities.
            return header + """
            (node\(b);way\(b);relation["type"="multipolygon"]\(b);relation["type"="building"]\(b););
            (._;>;);
            out body qt;
            """
        case "buildings":
            return header + """
            (way["building"]\(b);relation["building"]["type"="multipolygon"]\(b););
            (._;>;);
            out body qt;
            """
        default:
            throw ToolError.usage("unknown layer \(layer)")
        }
    }

    static func fetch(manifest: AreaManifest, layer: String, into dir: URL) async throws -> AreaManifest.Source {
        let q = try query(layer: layer, bbox: manifest.bounds)
        let fileName = layer == "all" ? "osm.json" : "osm-\(layer).json"
        try q.write(to: dir.appendingPathComponent(fileName.replacingOccurrences(of: ".json", with: ".overpassql")), atomically: true, encoding: .utf8)

        var lastError = "no endpoints"
        for attempt in 0..<2 {
            for endpoint in endpoints {
                do {
                    let data = try await post(q, to: endpoint)
                    let doc = try OSMDocument(overpassJSON: data) // validates the payload
                    try data.write(to: dir.appendingPathComponent(fileName))
                    return AreaManifest.Source(
                        format: "osm-overpass-json", path: fileName, layers: [layer], bounds: manifest.bounds,
                        dataTimestamp: doc.timestamp,
                        fetchedAt: ISO8601DateFormatter().string(from: Date()),
                        bytes: data.count,
                        sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                        license: "ODbL-1.0",
                        attribution: "© OpenStreetMap contributors"
                    )
                } catch {
                    lastError = "\(endpoint): \(error)"
                    FileHandle.standardError.write("  \(lastError)\n".data(using: .utf8)!)
                }
            }
            if attempt == 0 { try await Task.sleep(for: .seconds(15)) }
        }
        throw ToolError.fetchFailed(lastError)
    }

    static func post(_ query: String, to endpoint: String) async throws -> Data {
        var req = URLRequest(url: URL(string: endpoint)!)
        req.httpMethod = "POST"
        req.timeoutInterval = 240
        req.setValue("WorldEngine-worldbake/0.1 (offline map data bake tool)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        req.httpBody = ("data=" + query.addingPercentEncoding(withAllowedCharacters: allowed)!).data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200, data.first == UInt8(ascii: "{") else {
            throw ToolError.fetchFailed("HTTP \(status), \(data.count) bytes")
        }
        return data
    }
}
