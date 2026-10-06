import CoreGraphics
import Foundation
import Metal
import RealityKit
import Testing
@testable import WorldEngine
import WorldEnvironment
import WorldGen
import WorldGeo

/// The offscreen postcard render on the Mac (RealityKit's RealityRenderer exists on macOS too).
/// Runs only when the engine's shaders are compiled for the Mac (`scripts/postcard_mac_check.sh`;
/// `swift build` copies the Metal source uncompiled). Set `POSTCARD_TEST_OUT` to a folder to keep
/// the images. Mac timings show relative costs, not iPhone times.
@MainActor
@Suite("Offscreen postcards on the Mac", .serialized)
struct OffscreenPostcardTests {
    static let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let output = ProcessInfo.processInfo.environment["POSTCARD_TEST_OUT"].map { URL(fileURLWithPath: $0) }
    /// Sloan's Lake demo area and WorldLab's focus box (Data/areas, Apps/WorldLab/Resources/demo.json).
    static let area = packageRoot.appendingPathComponent("Data/areas/sloans-lake")
    static let focus = GeoBoundingBox(south: 39.747058, west: -105.0495, north: 39.7545, east: -105.037966)
    static let afternoon = ISO8601DateFormatter().date(from: "2026-07-15T21:30:00Z")!
    static let night = ISO8601DateFormatter().date(from: "2026-07-16T04:30:00Z")!
    static let text = PostcardText(placeName: "Sloan's Lake", localTime: "Jul 15, 2026 · 3:30 PM MDT", condition: "Clear",
                                   temperature: "84°F", demoLabel: "Demo")

    nonisolated static var shadersReady: Bool { RenderResources.shaderLibraryAvailable }
    static var cached: World?

    /// The demo world (built once for the suite) with Demo weather applied at `time`.
    static func world(at time: Date, weather: SyntheticWeather) async throws -> World {
        let world: World
        if let cached { world = cached } else {
            world = try await World.load(areaDirectory: area, options: WorldOptions(focus: focus, date: afternoon))
            cached = world
        }
        let resolver = try world.environmentResolver(timeZone: TimeZone(identifier: "America/Denver")!, phenologyProfileID: nil)
        world.apply(resolver.resolve(weather.input(at: time)))
        return world
    }

    /// What the live world looks like from outside: every entity's name and enabled state, instance
    /// counts and bounds, materials per model, whether light receivers use the world's own image-based
    /// light, and the sun's shadow.
    static func liveState(_ world: World) -> [String] {
        var out: [String] = []
        func visit(_ e: Entity, _ path: String) {
            var line = "\(path)/\(e.name) enabled=\(e.isEnabled)"
            if let part = e.components[MeshInstancesComponent.self]?[partIndex: 0] {
                line += " instances=\(part.data.instanceCount) bounds=\(String(describing: part.bounds))"
            }
            if let model = e.components[ModelComponent.self] { line += " materials=\(model.materials.count)" }
            if let r = e.components[ImageBasedLightReceiverComponent.self] { line += " ownIBL=\(r.imageBasedLight === world.iblEntity)" }
            if let s = e.components[DirectionalLightComponent.Shadow.self] { line += " shadow=\(s.shadowProjection) bias=\(s.depthBias)" }
            out.append(line)
            for c in e.children { visit(c, path + "/" + e.name) }
        }
        visit(world.rootEntity, "")
        return out
    }

    static func save(_ images: [PostcardImage], prefix: String) throws {
        guard let output else { return }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for p in images { try p.pngData().write(to: output.appendingPathComponent("\(prefix)-\(p.fileName)")) }
    }

    static func rgba(_ image: CGImage, side: Int? = nil) -> [UInt8] {
        let w = side ?? image.width, h = side ?? image.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        px.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = side == nil ? .none : .medium
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return px
    }

    /// Standard deviation of the picture's luma (a failed render is flat).
    static func spread(_ image: CGImage) -> Double {
        let px = rgba(image, side: 64)
        var sum = 0.0, sq = 0.0
        for i in stride(from: 0, to: px.count, by: 4) {
            let y = 0.2126 * Double(px[i]) + 0.7152 * Double(px[i + 1]) + 0.0722 * Double(px[i + 2])
            sum += y
            sq += y * y
        }
        let n = Double(px.count / 4)
        return (sq / n - (sum / n) * (sum / n)).squareRoot()
    }

    /// Mean absolute channel difference of two images of the same size.
    static func meanDifference(_ a: CGImage, _ b: CGImage) -> Double {
        let x = rgba(a), y = rgba(b)
        var total = 0
        for i in 0..<x.count where i % 4 != 3 { total += abs(Int(x[i]) - Int(y[i])) }
        return Double(total) / Double(x.count / 4 * 3)
    }

    static func megabytes(_ bytes: Int) -> String { String(format: "%.0f MB", Double(bytes) / 1_048_576) }

    @Test(.enabled(if: shadersReady, "needs the Mac shader library (scripts/postcard_mac_check.sh)"))
    func liveAndMaxQualityRenderAndLeaveTheLiveWorldAlone() async throws {
        let world = try await Self.world(at: Self.afternoon, weather: SyntheticWeather(label: .clear, cloudFraction: 0.15))
        let pose = try #require(world.postcards.first.map(world.pose(of:)))
        // A frame of the live view first, as WorldView would draw it.
        world.prepareOffscreenView(eye: SIMD3<Float>(pose.eye), target: SIMD3<Float>(pose.target), keepContact: true)
        let before = Self.liveState(world)
        let device = MTLCreateSystemDefaultDevice()!
        for (label, quality) in [("live", PostcardQuality.live), ("max", PostcardQuality.max)] {
            let baseline = device.currentAllocatedSize
            let started = Date()
            let images = try await world.exportPostcards(pose: pose, request: PostcardRequest(text: Self.text, weather: .demo, styles: [.classic],
                                                                                            quality: quality))
            let seconds = Date().timeIntervalSince(started)
            #expect(images.count == 3)
            for p in images {
                #expect(p.image.width == p.size.pixelWidth && p.image.height == p.size.pixelHeight)
                let picture = try #require(p.image.cropping(to: p.layout.picture))
                #expect(Self.spread(picture) > 8, "\(label) \(p.fileName): picture looks flat")
                print("POSTCARD timing \(label) \(p.fileName) \(p.timing.line)")
                print("POSTCARD info \(label) \(p.fileName) render=\(p.info.renderWidth)x\(p.info.renderHeight) ss=\(p.info.supersample) shadow=\(p.info.shadowDistance)m tufts=\(p.info.tufts) near=\(p.info.nearInstances) cells=\(p.info.nearBuildingCells) grade=\(p.info.gradeState?.rawValue ?? "none")")
            }
            print("POSTCARD export \(label): \(String(format: "%.2f", seconds)) s, Metal memory \(Self.megabytes(baseline)) → \(Self.megabytes(device.currentAllocatedSize))")
            if quality == .max {
                #expect(images.allSatisfy { $0.info.supersample > 1.4 && $0.info.nearInstances > 0 && $0.info.tufts > 0 })
                #expect(images.allSatisfy { $0.info.shadowDistance >= 80 && $0.info.gradeState == .ordinary })
            } else {
                #expect(images.allSatisfy { $0.info.supersample == 1 && $0.info.nearInstances == 0 && $0.info.gradeState == nil })
            }
            // Quality work happens on the copy only.
            #expect(Self.liveState(world) == before, "\(label) export changed the live world")
            try Self.save(images, prefix: label)
        }
    }

    @Test(.enabled(if: shadersReady, "needs the Mac shader library (scripts/postcard_mac_check.sh)"))
    func rainyNightInQualityMode() async throws {
        let world = try await Self.world(at: Self.night, weather: SyntheticWeather(label: .rain, cloudFraction: 0.9, precipitationMmPerHour: 2,
                                                                                   wetness: 0.8))
        let pose = try #require(world.postcards.first.map(world.pose(of:)))
        #expect(world.postcardAppearance == .night)
        #expect(world.postcardLightState == .moonlessNight)
        let text = PostcardText(placeName: "Sloan's Lake", localTime: "Jul 15, 2026 · 10:30 PM MDT", condition: "Rain", temperature: "61°F",
                                demoLabel: "Demo")
        let images = try await world.exportPostcards(pose: pose, request: PostcardRequest(text: text, weather: .demo, sizes: [.portrait],
                                                                                        styles: [.minimal], quality: .max))
        let p = try #require(images.first)
        #expect(p.layout.colors == PostcardStyle.minimal.colors(.night))
        print("POSTCARD timing rain-night \(p.fileName) \(p.timing.line)")
        try Self.save(images, prefix: "max-rain-night")
    }

    @Test(.enabled(if: shadersReady, "needs the Mac shader library (scripts/postcard_mac_check.sh)"))
    func theCopyIgnoresLaterChangesToTheLiveWorld() async throws {
        let world = try await Self.world(at: Self.afternoon, weather: SyntheticWeather(label: .clear, cloudFraction: 0.15))
        let pose = try #require(world.postcards.first.map(world.pose(of:)))
        func session() async throws -> OffscreenSession {
            try await OffscreenSession(world: world, eye: pose.eye, target: pose.target, widestVerticalFOV: 50,
                                       widestHorizontalFOV: PostcardReframe.horizontalFOV(verticalFOV: 50, aspect: 16.0 / 9),
                                       quality: .live, post: nil, includeCharacters: false)
        }
        let first = try await session()
        defer { first.close() }
        let a = try await first.picture(pose: pose, width: 320, height: 180).image
        // The live world switches to a debug view (every surface green or red) after the copy was taken.
        world.shaderGlobals.debug = 2
        world.resources.update(globals: world.shaderGlobals)
        defer {
            world.shaderGlobals.debug = 0
            world.resources.update(globals: world.shaderGlobals)
        }
        let b = try await first.picture(pose: pose, width: 320, height: 180).image
        let unchanged = Self.meanDifference(a, b)
        #expect(unchanged < 1.5, "the copy followed the live world (mean difference \(unchanged))")
        // A copy taken now does show it, so the check can tell.
        let second = try await session()
        defer { second.close() }
        let c = try await second.picture(pose: pose, width: 320, height: 180).image
        let changed = Self.meanDifference(a, c)
        #expect(changed > 20, "a new copy did not show the debug view (mean difference \(changed))")
        print("POSTCARD copy independence: same copy \(String(format: "%.2f", unchanged)), new copy \(String(format: "%.1f", changed))")
    }
}
