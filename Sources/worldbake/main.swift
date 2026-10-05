// worldbake: offline data tool for WorldEngine areas (macOS).
//
//   worldbake init-area <dir> --id ID --name NAME --lat LAT --lon LON --width M --height M
//   worldbake fetch <dir> [--layers all|buildings]
//   worldbake stats <dir>                               (Markdown to stdout)
//   worldbake datamap <dir> <out.png> [--scale PX_PER_M]
//   worldbake ring-stats <dir> --inner-width M --inner-height M
//
// No command contains place-specific values: the area directory's manifest is the only input.

import Foundation
import WorldGeo
import WorldMap

struct Args {
    var positional: [String] = []
    var options: [String: String] = [:]

    init(_ argv: [String]) {
        var i = 0
        while i < argv.count {
            let a = argv[i]
            if a.hasPrefix("--"), i + 1 < argv.count {
                options[String(a.dropFirst(2))] = argv[i + 1]
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

    default:
        throw ToolError.usage(usage)
    }
} catch {
    FileHandle.standardError.write("error: \(error)\n".data(using: .utf8)!)
    exit(1)
}
