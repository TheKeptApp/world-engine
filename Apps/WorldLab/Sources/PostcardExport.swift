import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UIKit
import WeatherKit
import WorldEngine

/// WorldLab's postcard export: the "Export postcard" menu item and `-exportpostcard STYLE`.
/// Exports the current postcard pose at 1080×1080, 1080×1350 and 1080×1920 with one frame style,
/// writes `postcard-<style>-<size>.png` to the app's Documents and offers a share sheet. The
/// engine renders, frames and credits the images (`World.exportPostcards`, docs/postcards.md).
@MainActor
enum PostcardExports {
    /// What an export needs from the running screen.
    struct Source {
        var world: World
        var pose: CameraPose
        var env: EnvironmentController
        /// The grade and bloom on screen (nil when the screen runs without them).
        var post: WorldPostProcess.Settings?
    }

    /// The pose to export: the camera's postcard view (composed, showcase or `-camera`), else the
    /// composed postcard the Postcard mode returns to.
    static func pose(camera: WorldCamera, fallback: CameraPose) -> CameraPose {
        if case let .postcard(pose) = camera.mode { return pose }
        return fallback
    }

    /// The text block: place, local time in the area's time zone, condition, temperature, "Demo".
    static func text(_ env: EnvironmentController) -> PostcardText {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = env.timeZone
        f.dateFormat = "MMM d, yyyy '·' h:mm a zzz"
        return PostcardText(placeName: env.locationLabel, localTime: f.string(from: env.time), condition: env.conditionText,
                            temperature: env.temperatureText, demoLabel: "Demo")
    }

    /// WorldLab shows Demo weather, so its postcards carry the "Demo weather" label and no provider
    /// mark. With live WeatherKit data this becomes `appleWeather()`: the Apple Weather mark and
    /// legal page come from WeatherKit at runtime and are never bundled.
    static func weather(for env: EnvironmentController) async -> PostcardWeather {
        .demo
    }

    /// Postcard attribution for live WeatherKit data: WeatherKit's service name and legal page, the
    /// modified-data notice, and both combined marks loaded from their URLs (the engine draws the
    /// one that suits the frame's plate, unmodified). Unused while WorldLab shows Demo weather.
    static func appleWeather() async throws -> PostcardWeather {
        let a = try await WeatherService.shared.attribution
        let lightURL = a.combinedMarkLightURL, darkURL = a.combinedMarkDarkURL
        let credit = WorldWeatherCredit(serviceName: a.serviceName, legalPageURL: a.legalPageURL.absoluteString,
                                        markLightURL: lightURL.absoluteString, markDarkURL: darkURL.absoluteString,
                                        modifiedNotice: "Weather visualization modified from Apple Weather data.")
        let markLight = try await image(at: lightURL)
        let markDark = try await image(at: darkURL)
        return .live(credit: credit, markLight: markLight, markDark: markDark)
    }

    enum ExportError: Error, CustomStringConvertible {
        case unreadableImage(URL)
        var description: String {
            switch self {
            case let .unreadableImage(url): "unreadable image at \(url)"
            }
        }
    }

    static func image(at url: URL) async throws -> CGImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw ExportError.unreadableImage(url) }
        return image
    }

    /// Exports all three sizes in `style` and writes them to Documents (replacing earlier exports
    /// of the same style). Prints `POSTCARD timing` and `POSTCARD info` lines per image. Returns the
    /// files, square first.
    static func save(_ source: Source, style: PostcardStyle, quality: PostcardQuality = .max) async throws -> [URL] {
        let started = Date()
        let request = PostcardRequest(text: text(source.env), weather: await weather(for: source.env), sizes: PostcardSize.allCases,
                                      styles: [style], post: source.post, quality: quality)
        let postcards = try await source.world.exportPostcards(pose: source.pose, request: request)
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var files: [URL] = []
        for postcard in postcards {
            let file = folder.appendingPathComponent(postcard.fileName)
            let encoding = Date()
            try postcard.pngData().write(to: file, options: .atomic)
            report(postcard, png: Date().timeIntervalSince(encoding) * 1000)
            files.append(file)
        }
        report(String(format: "POSTCARD export style=%@ quality=%@ images=%ld total=%.1f ms", style.rawValue,
                      quality == .live ? "live" : "max", postcards.count, Date().timeIntervalSince(started) * 1000))
        return files
    }

    /// `POSTCARD timing <file> clone=… settle=… render=… post=… frame=… total=… ms png=… ms` and
    /// `POSTCARD info <file> render=WxH ss=… shadow=…m tufts=… near=… cells=… grade=…`.
    static func report(_ p: PostcardImage, png: Double) {
        let i = p.info
        report("POSTCARD timing \(p.fileName) \(p.timing.line) " + String(format: "png=%.1f ms", png))
        report("POSTCARD info \(p.fileName) render=\(i.renderWidth)x\(i.renderHeight) " + String(format: "ss=%.2f shadow=%.0fm", i.supersample, i.shadowDistance)
               + " tufts=\(i.tufts) near=\(i.nearInstances) cells=\(i.nearBuildingCells) grade=\(i.gradeState?.rawValue ?? "none")")
    }

    static func report(_ line: String) {
        print(line)
        fflush(nil)
    }

    // MARK: `-exportpostcard STYLE [-postcardquality live|max]`

    /// `-exportpostcard STYLE` (bold, classic or minimal), with `-postcardquality live|max`
    /// (default max): once the world has loaded and settled, export the current postcard pose in
    /// all three sizes and print `POSTCARD saved <file>` for each file in Documents (after the
    /// timing and info lines), or `POSTCARD failed <why>`. For scripts.
    static func runLaunchArgument(source: () -> Source?, failed: () -> Bool) async {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-exportpostcard") else { return }
        let name = i + 1 < args.count ? args[i + 1].lowercased() : ""
        guard let style = PostcardStyle(rawValue: name) else {
            report("POSTCARD failed: unknown style '\(name)' (bold, classic or minimal)")
            return
        }
        var quality = PostcardQuality.max
        if let q = args.firstIndex(of: "-postcardquality"), q + 1 < args.count {
            switch args[q + 1].lowercased() {
            case "live": quality = .live
            case "max": quality = .max
            default:
                report("POSTCARD failed: unknown quality '\(args[q + 1])' (live or max)")
                return
            }
        }
        UIApplication.shared.isIdleTimerDisabled = true // a locked screen stops the GPU
        while source() == nil {
            if failed() { report("POSTCARD failed: the world did not load"); return }
            try? await Task.sleep(for: .milliseconds(200))
        }
        // Let the sky light, detail levels and near-camera tufts settle, as for snapshots.
        try? await Task.sleep(for: .seconds(4))
        guard let s = source() else { report("POSTCARD failed: the world went away"); return }
        do {
            let files = try await save(s, style: style, quality: quality)
            for file in files { report("POSTCARD saved \(file.lastPathComponent)") }
        } catch {
            report("POSTCARD failed: \(error)")
        }
    }

    // MARK: `-viewlist` views with `-capturequality`

    /// The quality-mode offscreen render of the camera's current view at `size` (the live
    /// capture's size), as PNG, so P3's look loop can compare it with the live capture. A test
    /// artifact like the live snapshot: no frame, no burned-in credit.
    static func qualityCapture(world: World, camera: WorldCamera, size: CGSize,
                               post: WorldPostProcess.Settings?) async -> (data: Data, size: String, source: String)? {
        guard let pose = camera.currentPose, size.width >= 1, size.height >= 1 else {
            report("VIEWSHOT quality capture: no camera pose or view size yet")
            return nil
        }
        let w = Int(size.width.rounded()), h = Int(size.height.rounded())
        do {
            let still = try await world.renderStill(pose: pose, width: w, height: h, quality: .max, post: post)
            report("POSTCARD timing view-\(w)x\(h) \(still.timing.line)")
            guard let png = UIImage(cgImage: still.image).pngData() else { return nil }
            return (png, "\(w)x\(h)", "quality")
        } catch {
            report("VIEWSHOT quality capture failed: \(error)")
            return nil
        }
    }
}

/// The "Export postcard" sheet: frame style, export, the saved files and a share button.
struct PostcardExportSheet: View {
    let source: PostcardExports.Source?
    @Environment(\.dismiss) private var dismiss
    @State private var style: PostcardStyle = .classic
    @State private var files: [URL] = []
    @State private var working = false
    @State private var failure: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Frame", selection: $style) {
                        Text("Bold").tag(PostcardStyle.bold)
                        Text("Classic").tag(PostcardStyle.classic)
                        Text("Minimal").tag(PostcardStyle.minimal)
                    }
                    .pickerStyle(.segmented)
                    Button {
                        Task { await export() }
                    } label: {
                        HStack {
                            Text("Export square, portrait and story")
                            if working { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(working || source == nil)
                } footer: {
                    Text("The current postcard view, rendered at 1080×1080, 1080×1350 and 1080×1920 and saved to Documents as postcard-\(style.rawValue)-<size>.png. Demo weather is labeled as such.")
                }
                if let failure {
                    Section { Text(failure).foregroundStyle(.red) }
                }
                if !files.isEmpty {
                    Section("Saved") {
                        ScrollView(.horizontal) {
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(files, id: \.self) { thumbnail($0) }
                            }
                        }
                        ShareLink(items: files) { Label("Share", systemImage: "square.and.arrow.up") }
                    }
                }
                Section {
                    // The world stays partly visible behind the sheet: keep its credit in sight.
                    WorldAttributionView()
                }
            }
            .navigationTitle("Export postcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func thumbnail(_ url: URL) -> some View {
        VStack(spacing: 4) {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit().frame(height: 150)
                    .accessibilityLabel("Postcard \(url.lastPathComponent)")
            }
            Text(url.lastPathComponent).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func export() async {
        guard let source else { return }
        working = true
        failure = nil
        files = []
        defer { working = false }
        do {
            files = try await PostcardExports.save(source, style: style)
        } catch {
            failure = "Export failed: \(error)"
        }
    }
}
