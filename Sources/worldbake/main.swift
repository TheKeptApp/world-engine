// worldbake: offline data tool for WorldEngine areas (macOS).
//
//   worldbake init-area <dir> --id ID --name NAME --lat LAT --lon LON --width M --height M
//   worldbake fetch <dir> [--layers all|buildings|overture] [--release R]
//                    (overture: Overture buildings via scripts/data/fetch_overture.py and uv; R = Overture
//                    release, default the latest; see docs/research/overture-source.md)
//   worldbake stats <dir>                               (Markdown to stdout)
//   worldbake datamap <dir> <out.png> [--scale PX_PER_M]
//   worldbake ring-stats <dir> --inner-width M --inner-height M
//   worldbake export <dir> <out-dir> --date ISO [--state NAME=ISO ...] [--focus S,W,N,E] [--profile ID]
//                    [--season N] [--version STRING]      (shared world package, see WorldPackage)
//                    [--margin M] [--map-diagnostics FILE] [--previous PKG]  (map data layer: road margin beyond the
//                                       area, confidence features for calibration, ID migration from the previous package)
//   worldbake fetch <dir> --layers relations [--margin M]  (turn restrictions and transit routes for the map layer)
//
// No command contains place-specific values: the area directory's manifest is the only input.

import Foundation
import WorldGen
import WorldGeo
import WorldMap
import WorldPackage

struct Args {
    var positional: [String] = []
    var options: [String: String] = [:]
    /// Repeatable `--state NAME=ISO` (light states to export).
    var states: [String] = []

    init(_ argv: [String]) {
        var i = 0
        while i < argv.count {
            let a = argv[i]
            if a.hasPrefix("--"), i + 1 < argv.count {
                let key = String(a.dropFirst(2))
                if key == "state" { states.append(argv[i + 1]) } else { options[key] = argv[i + 1] }
                i += 2
            } else {
                positional.append(a)
                i += 1
            }
        }
    }

    func require(_ key: String) throws -> String {
        guard let v = options[key] else { throw ToolError.usage("missing --\(key)") }
        return v
    }

    func double(_ key: String) throws -> Double {
        guard let v = Double(try require(key)) else { throw ToolError.usage("--\(key) must be a number") }
        return v
    }
}

enum ToolError: Error, CustomStringConvertible {
    case usage(String)
    case fetchFailed(String)

    var description: String {
        switch self {
        case .usage(let s): "usage: \(s)"
        case .fetchFailed(let s): "fetch failed: \(s)"
        }
    }
}

let usage = """
worldbake init-area <dir> --id ID --name NAME --lat LAT --lon LON --width M --height M
worldbake fetch <dir> [--layers all|buildings|overture] [--release R]
worldbake stats <dir>
worldbake pack <existing-package-dir> <new-output-dir>
worldbake datamap <dir> <out.png> [--scale PX_PER_M]
worldbake ring-stats <dir> --inner-width M --inner-height M
worldbake export <dir> <out-dir> --date ISO [--state NAME=ISO ...] [--focus S,W,N,E] [--profile ID] [--season N] [--version S] [--margin M] [--map-diagnostics FILE] [--previous PKG]
worldbake fetch <dir> --layers relations [--margin M]
worldbake compose <dir> --date ISO [--focus S,W,N,E]
worldbake fetch <dir> --layers context [--building-band-km 1.5|1.0|0.5] [--max-mb 25] [--probe 1] [--split 1] [--no-split 1] [--cache-dir PATH] [--dry-run 1]
    (context ring: real OSM at low detail, area bounds + 3 km, building footprints within the band; see docs/data/context-rings.md)
worldbake stats <dir> --layers context
worldbake diagnostics <dir> [<dir> ...] --date ISO [--season N] [--output Data/quality/unsupported-features.json]
"""

func writeManifest(_ m: AreaManifest, to dir: URL) throws {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try enc.encode(m).write(to: dir.appendingPathComponent(AreaManifest.fileName))
}

do {
    let args = Args(Array(CommandLine.arguments.dropFirst()))
    guard let command = args.positional.first, args.positional.count >= 2 else { throw ToolError.usage(usage) }
    let dir = URL(fileURLWithPath: args.positional[1], isDirectory: true)

    switch command {
    case "init-area":
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let m = AreaManifest(
            id: try args.require("id"), name: try args.require("name"),
            center: GeoCoordinate(latitude: try args.double("lat"), longitude: try args.double("lon")),
            widthMeters: try args.double("width"), heightMeters: try args.double("height")
        )
        try writeManifest(m, to: dir)
        print("Wrote \(dir.path)/\(AreaManifest.fileName) bbox \(m.bounds.overpassString)")

    case "fetch" where args.options["layers"] == "context":
        try await ContextRing.fetch(dir: dir, options: args.options)

    case "stats" where args.options["layers"] == "context":
        print(try ContextRing.stats(dir: dir))

    case "fetch":
        var m = try AreaLoader.loadManifest(dir)
        let layer = args.options["layers"] ?? "all"
        let margin = Double(args.options["margin"] ?? "") ?? MapLayer.Options().marginM
        let source = layer == "overture"
            ? try OvertureFetcher.fetch(manifest: m, into: dir, release: args.options["release"])
            : try await Fetcher.fetch(manifest: m, layer: layer, into: dir, marginM: margin)
        m.sources.removeAll { $0.path == source.path }
        m.sources.append(source)
        try writeManifest(m, to: dir)
        if layer == "overture" {
            print("Wrote \(source.path): \(source.bytes ?? 0) bytes, Overture release \(source.dataTimestamp ?? "?"); NOTICE.md updated")
            print("Attribution: \(source.attribution)")
        } else {
            print("Wrote \(source.path): \(source.bytes ?? 0) bytes, OSM data \(source.dataTimestamp ?? "?")")
        }

    case "diagnostics":
        // R: generic per-area audit; no fixed hero list or inferred geometry.
        let date = ISO8601DateFormatter().date(from: try args.require("date"))
        guard let date else { throw ToolError.usage("--date must be ISO 8601") }
        var reports: [String: UnsupportedFeatures.Report] = [:]
        for path in args.positional.dropFirst() {
            let build = try WorldBuild.generate(areaDirectory: URL(fileURLWithPath: path), recipe: WorldRecipe(date: date, season: args.options["season"].flatMap(Int.init)))
            reports[build.manifest.id] = build.unsupportedFeatures
        }
        let target = URL(fileURLWithPath: args.options["output"] ?? "Data/quality/unsupported-features.json")
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(reports).write(to: target, options: .atomic)

    case "stats":
        print(try Stats.markdown(for: dir))

    case "datamap":
        guard args.positional.count >= 3 else { throw ToolError.usage(usage) }
        let scale = Double(args.options["scale"] ?? "1.5") ?? 1.5
        try DataMap.render(areaDir: dir, to: URL(fileURLWithPath: args.positional[2]), pixelsPerMeter: scale)
        print("Wrote \(args.positional[2])")

    case "ring-stats":
        print(try Stats.ring(dir, innerWidth: try args.double("inner-width"), innerHeight: try args.double("inner-height")))

    case "compose":
        // Postcards composed from the area's map data (experience-v1 §4), printed best first.
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: try args.require("date")) else { throw ToolError.usage("--date must be ISO 8601") }
        var focus: GeoBoundingBox?
        if let f = args.options["focus"] {
            let v = f.split(separator: ",").compactMap { Double($0) }
            guard v.count == 4 else { throw ToolError.usage("--focus S,W,N,E") }
            focus = GeoBoundingBox(south: v[0], west: v[1], north: v[2], east: v[3])
        }
        let build = try WorldBuild.generate(areaDirectory: dir, recipe: WorldRecipe(date: date, focus: focus))
        let start = Date()
        let result = ExperienceDefaults.compose(build: build, date: date)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        print(String(data: try enc.encode(result), encoding: .utf8)!)
        print(String(format: "composed in %.2f s", Date().timeIntervalSince(start)))

    case "pack":
        guard args.positional.count == 3 else { throw ToolError.usage(usage) }
        let report = try AdaptiveTilePacker.pack(source: dir, to: URL(fileURLWithPath: args.positional[2], isDirectory: true))
        print("Packed \(report["beforeTiles"]!) → \(report["afterTiles"]!) tiles; budgets and measured arrays are in world.json tilePacking")

    case "export":
        guard args.positional.count >= 3 else { throw ToolError.usage(usage) }
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: try args.require("date")) else { throw ToolError.usage("--date must be ISO 8601") }
        var focus: GeoBoundingBox?
        if let f = args.options["focus"] {
            let v = f.split(separator: ",").compactMap { Double($0) }
            guard v.count == 4 else { throw ToolError.usage("--focus S,W,N,E") }
            focus = GeoBoundingBox(south: v[0], west: v[1], north: v[2], east: v[3])
        }
        var states: [(name: String, date: Date)] = []
        for s in args.states {
            let parts = s.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2, let d = iso.date(from: parts[1]) else { throw ToolError.usage("--state NAME=ISO") }
            states.append((parts[0], d))
        }
        if states.isEmpty { states = [("default", date)] }
        let recipe = WorldRecipe(profileID: args.options["profile"], date: date, season: args.options["season"].flatMap(Int.init), focus: focus)
        let out = URL(fileURLWithPath: args.positional[2], isDirectory: true)
        let start = Date()
        var mapOptions = MapLayer.Options()
        if let m = args.options["margin"].flatMap(Double.init) { mapOptions.marginM = m }
        mapOptions.diagnosticsURL = args.options["map-diagnostics"].map { URL(fileURLWithPath: $0) }
        mapOptions.previousPackage = args.options["previous"].map { URL(fileURLWithPath: $0, isDirectory: true) }
        let s = try WorldPackage.export(areaDirectory: dir, to: out, options: .init(recipe: recipe, lightStates: states,
                                                                                    generatorVersion: args.options["version"] ?? "dev",
                                                                                    mapLayer: mapOptions))
        print(String(format: "Wrote %@: %d files, %.1f MB, %d chunks, %d/%d triangles (lod0/lod1), %d instances, %d tuft candidates, %.1f s",
                     out.path, s.files, Double(s.bytes) / 1_048_576, s.chunks, s.triangles[0], s.triangles[1], s.instances, s.tufts,
                     Date().timeIntervalSince(start)))

    default:
        throw ToolError.usage(usage)
    }
} catch {
    FileHandle.standardError.write("error: \(error)\n".data(using: .utf8)!)
    exit(1)
}
