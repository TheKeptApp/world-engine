import CryptoKit
import Foundation
import WorldGeo
import WorldMap

/// `worldbake fetch <dir> --layers overture`: Overture Maps buildings for the area's box.
///
/// The download itself is `scripts/data/fetch_overture.py` (DuckDB over Overture's public
/// GeoParquet, run with `uv run --script`, which installs DuckDB into uv's cache on first use).
/// This side validates the file, records it as a manifest source with the credits for the
/// datasets it contains, and adds the Overture paragraph to the area's NOTICE.md.
enum OvertureFetcher {
    /// The helper ships in the repo; found next to this source file's checkout, else under the
    /// current directory.
    static func helperURL() throws -> URL {
        let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let relative = "scripts/data/fetch_overture.py"
        for base in [repo, URL(fileURLWithPath: FileManager.default.currentDirectoryPath)] {
            let url = base.appendingPathComponent(relative)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        throw ToolError.fetchFailed("\(relative) not found (run worldbake from the WorldEngine repo)")
    }

    static func uvURL() throws -> URL {
        let env = ProcessInfo.processInfo.environment
        var dirs = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        dirs += [NSHomeDirectory() + "/.local/bin", NSHomeDirectory() + "/.cargo/bin", "/opt/homebrew/bin", "/usr/local/bin"]
        for d in dirs {
            let url = URL(fileURLWithPath: d).appendingPathComponent("uv")
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        throw ToolError.fetchFailed("uv not found (https://docs.astral.sh/uv/); it runs the Overture helper")
    }

    static func fetch(manifest: AreaManifest, into dir: URL, release: String?) throws -> AreaManifest.Source {
        let out = dir.appendingPathComponent(OvertureBuildings.fileName)
        let b = manifest.bounds
        var args = ["run", "--script", try helperURL().path,
                    "--bbox", "\(b.south),\(b.west),\(b.north),\(b.east)", "--out", out.path]
        if let release { args += ["--release", release] }
        let p = Process()
        p.executableURL = try uvURL()
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw ToolError.fetchFailed("Overture helper exited with \(p.terminationStatus)") }

        let data = try Data(contentsOf: out)
        let file = try OvertureBuildings.decode(data) // validates the payload
        for d in OvertureBuildings.uncreditedDatasets(file.datasets) {
            FileHandle.standardError.write("  note: no credit wording on file for Overture dataset \"\(d)\"; using its name and licence. Check https://docs.overturemaps.org/attribution/ and add it to OvertureBuildings.datasetCredits.\n".data(using: .utf8)!)
        }
        try updateNotice(in: dir, release: file.release, datasets: file.datasets)
        return AreaManifest.Source(
            format: OvertureBuildings.format, path: OvertureBuildings.fileName, layers: ["buildings"], bounds: b,
            dataTimestamp: file.release,
            fetchedAt: ISO8601DateFormatter().string(from: Date()),
            bytes: data.count,
            sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
            license: "ODbL-1.0",
            attribution: OvertureBuildings.attribution(for: file.datasets)
        )
    }

    static let noticeHeading = "## Overture buildings"

    /// Replaces the NOTICE.md Overture section (or appends it; creates the file if missing).
    static func updateNotice(in dir: URL, release: String, datasets: [OvertureBuildings.Dataset]) throws {
        let url = dir.appendingPathComponent("NOTICE.md")
        var text = (try? String(contentsOf: url, encoding: .utf8)) ?? "# Data notice\n"
        if let start = text.range(of: "\n" + noticeHeading + "\n") {
            let rest = text[start.upperBound...]
            let end = rest.range(of: "\n## ")?.lowerBound ?? text.endIndex
            text.removeSubrange(start.lowerBound..<end)
        }
        while text.hasSuffix("\n\n") { text.removeLast() }
        if !text.hasSuffix("\n") { text += "\n" }
        text += "\n\(noticeHeading)\n\n\(OvertureBuildings.notice(release: release, datasets: datasets))\n\n"
        text += "- **How it was fetched:** with `worldbake fetch <dir> --layers overture` (`scripts/data/fetch_overture.py`), reading only the area's bounding box from Overture's public GeoParquet.\n"
        text += "- **Where to look up details:** `manifest.json` records the release, the fetch time and the file's SHA-256; the file lists the GeoParquet files read and every source dataset with its licence.\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
