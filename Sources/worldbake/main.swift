// worldbake: offline data tool for WorldEngine areas (macOS).
//
//   worldbake init-area <dir> --id ID --name NAME --lat LAT --lon LON --width M --height M
//   worldbake fetch <dir> [--layers all|buildings]
//   worldbake stats <dir>                               (Markdown to stdout)
//   worldbake datamap <dir> <out.png> [--scale PX_PER_M]
//   worldbake ring-stats <dir> --inner-width M --inner-height M
//   worldbake export <dir> <out-dir> --date ISO [--state NAME=ISO ...] [--focus S,W,N,E] [--profile ID]
//                    [--season N] [--version STRING]      (shared world package, see WorldPackage)
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
worldbake fetch <dir> [--layers all|buildings]
worldbake stats <dir>
worldbake datamap <dir> <out.png> [--scale PX_PER_M]
worldbake ring-stats <dir> --inner-width M --inner-height M
worldbake export <dir> <out-dir> --date ISO [--state NAME=ISO ...] [--focus S,W,N,E] [--profile ID] [--season N] [--version S]
worldbake compose <dir> --date ISO [--focus S,W,N,E]
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

    case "fetch":
        var m = try AreaLoader.loadManifest(dir)
        let layer = args.options["layers"] ?? "all"
        let source = try await Fetcher.fetch(manifest: m, layer: layer, into: dir)
        m.sources.removeAll { $0.path == source.path }
        m.sources.append(source)
        try writeManifest(m, to: dir)
        print("Wrote \(source.path): \(source.bytes ?? 0) bytes, OSM data \(source.dataTimestamp ?? "?")")

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
        let s = try WorldPackage.export(areaDirectory: dir, to: out, options: .init(recipe: recipe, lightStates: states,
                                                                                    generatorVersion: args.options["version"] ?? "dev"))
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
