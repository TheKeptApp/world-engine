import CoreGraphics
import Foundation
import RealityKit
import WorldEnvironment
import WorldGen
import WorldGeo

// Postcard export (docs/postcards.md): the world rendered offscreen at each postcard's own size,
// reframed per aspect ratio from one pose, framed with the host's text block and with the credits
// burned in. The frame layout and drawing are renderer-neutral (WorldGen, tested on the Mac).

/// Postcard sizes, styles and text, re-exported so host apps only import WorldEngine.
public typealias PostcardSize = WorldGen.PostcardSize
public typealias PostcardStyle = WorldGen.PostcardStyle
public typealias PostcardAppearance = WorldGen.PostcardAppearance
public typealias PostcardText = WorldGen.PostcardText
public typealias PostcardWeather = WorldGen.PostcardWeather
public typealias PostcardLayout = WorldGen.PostcardLayout
public typealias PostcardFrame = WorldGen.PostcardFrame
public typealias PostcardReframe = WorldGen.PostcardReframe
public typealias PostcardLightState = WorldGen.PostcardLightState
public typealias PostcardGrade = WorldGen.PostcardGrade
public typealias PostcardGradeTable = WorldGen.PostcardGradeTable

/// What to export: every size in `sizes` for every style in `styles`.
public struct PostcardRequest: Sendable {
    /// The host's text block (place, local time, condition, temperature, optional Demo label).
    public var text: PostcardText
    /// Demo weather, or live provider data with the provider's mark images and legal page.
    public var weather: PostcardWeather
    public var sizes: [PostcardSize]
    public var styles: [PostcardStyle]
    /// Day or night frame; nil decides from the world's sun (night below −6°, after civil dusk).
    public var appearance: PostcardAppearance?
    /// The aspect the pose was composed for (16:9 for composed postcards).
    public var composedAspect: Double
    /// Grade, bloom and exposure as on screen: pass the live `WorldPostProcess`'s settings, copied
    /// at capture time. nil renders without them.
    public var post: WorldPostProcess.Settings?
    /// `.max` (default) renders the still at maximum quality; `.live` with the live view's settings.
    public var quality: PostcardQuality
    /// Draw the host's characters too, cloned in their current pose. Off by default: postcards are
    /// the no-character view (experience-v1), and the contact shadow is then left out as well.
    public var includeCharacters: Bool

    public init(text: PostcardText, weather: PostcardWeather, sizes: [PostcardSize] = PostcardSize.allCases,
                styles: [PostcardStyle] = [.classic], appearance: PostcardAppearance? = nil,
                composedAspect: Double = PostcardReframe.composedAspect, post: WorldPostProcess.Settings? = WorldPostProcess.Settings(),
                quality: PostcardQuality = .max, includeCharacters: Bool = false) {
        self.text = text
        self.weather = weather
        self.sizes = sizes
        self.styles = styles
        self.appearance = appearance
        self.composedAspect = composedAspect
        self.post = post
        self.quality = quality
        self.includeCharacters = includeCharacters
    }
}

/// One finished postcard.
public struct PostcardImage: Sendable {
    public let size: PostcardSize
    public let style: PostcardStyle
    /// The pose the picture was rendered from (the requested pose, reframed for the picture).
    public let pose: CameraPose
    public let layout: PostcardLayout
    /// The finished image (`size.pixelWidth` × `size.pixelHeight`, sRGB, credits burned in).
    public let image: CGImage
    public let info: PostcardRenderInfo
    public let timing: PostcardTiming

    /// `postcard-<style>-<size>.png`.
    public var fileName: String { PostcardFrame.fileName(style: style, size: size) }

    public func pngData() throws -> Data { try PostcardFrame.pngData(image) }
}

public enum PostcardExportError: Error, Sendable, CustomStringConvertible {
    /// Another export is still running (one bounded snapshot job at a time, experience-v1).
    case busy
    case metalUnavailable
    case rendererUnavailable(String)
    case renderFailed(String)
    /// The GPU did not finish a frame within 10 s.
    case timedOut

    public var description: String {
        switch self {
        case .busy: "another postcard export is running"
        case .metalUnavailable: "Metal is unavailable"
        case let .rendererUnavailable(why): "RealityRenderer unavailable: \(why)"
        case let .renderFailed(why): "render failed: \(why)"
        case .timedOut: "the GPU did not finish a frame within 10 s"
        }
    }
}

@MainActor
enum PostcardJobs {
    static var running = false
}

/// One offscreen copy of the world and its renderer, for every picture taken from one eye.
@MainActor
final class OffscreenSession {
    let renderer: OffscreenWorldRenderer
    let quality: PostcardQuality
    let grade: (PostcardGrade, threshold: Double, softness: Double)?
    let baseInfo: PostcardRenderInfo
    /// Preparation, copy and set-up times (and the rain or snow warm-up as settle time), charged
    /// to the first picture.
    private var pending = PostcardTiming()
    private var first = true

    /// `widestVerticalFOV` and `widestHorizontalFOV` cover all the pictures to come: quality
    /// detail is decided for that frustum.
    init(world: World, eye: SIMD3<Double>, target: SIMD3<Double>, widestVerticalFOV: Double, widestHorizontalFOV: Double,
         quality: PostcardQuality, post: WorldPostProcess.Settings?, includeCharacters: Bool) async throws {
        var clock = Date()
        func lap() -> Double {
            let now = Date()
            defer { clock = now }
            return now.timeIntervalSince(clock) * 1000
        }
        var timing = PostcardTiming()
        let e = SIMD3<Float>(eye), t = SIMD3<Float>(target)
        // Camera state for this eye (a no-op when the live view already shows it), then a copy of
        // the world as it is now. Nothing the live view does afterwards reaches the copy.
        world.prepareOffscreenView(eye: e, target: t, keepContact: includeCharacters)
        timing.prepare = lap()
        let copy: (root: Entity, copies: [ObjectIdentifier: Entity])
        do {
            copy = try world.offscreenCopy(includeCharacters: includeCharacters, quality: quality)
        } catch {
            throw PostcardExportError.renderFailed("world copy: \(error)")
        }
        timing.copy = lap()
        var info = PostcardRenderInfo()
        let vHalf = widestVerticalFOV / 2 * .pi / 180, hHalf = widestHorizontalFOV / 2 * .pi / 180
        let planes = World.postcardFrustum(eye: e, target: t, verticalFOV: widestVerticalFOV, aspect: tan(hHalf) / tan(vHalf))
        world.applyQuality(quality, root: copy.root, copies: copy.copies, eye: e, planes: planes, info: &info)
        if quality.finalGrade {
            let state = world.postcardLightState
            info.gradeState = state
            if let table = try? PostcardGradeTable.bundled() {
                grade = (table.grade(for: state), table.shadeThreshold, table.shadeSoftness)
            } else {
                grade = nil
            }
        } else {
            grade = nil
        }
        timing.quality = lap()
        renderer = try OffscreenWorldRenderer(root: copy.root, environment: world.skyEnvironment,
                                              background: WorldGen.Color.srgb(world.shaderGlobals.fogColor), post: post)
        timing.setUp = lap()
        self.quality = quality
        baseInfo = info
        if let seconds = World.precipitationWarmUp(in: copy.root) {
            // The cloned emitter starts over in the new scene; restart it explicitly so it spawns.
            if let p = copy.root.children.first(where: { $0.name == "Precipitation" }),
               var emitter = p.components[ParticleEmitterComponent.self] {
                emitter.restart()
                emitter.isEmitting = true
                emitter.simulationState = .play
                p.components.set(emitter)
            }
            try await renderer.warmUp(seconds: seconds)
            timing.settle = lap()
        }
        pending = timing
    }

    /// One picture of `width` × `height` from `pose` (supersampled per the quality). The first
    /// picture of a copy draws `quality.settleFrames` frames before the final one.
    func picture(pose: CameraPose, width: Int, height: Int) async throws -> (image: CGImage, info: PostcardRenderInfo, timing: PostcardTiming) {
        var timing = pending
        pending = PostcardTiming()
        let size = quality.renderSize(width: width, height: height)
        var info = baseInfo
        info.renderWidth = size.width
        info.renderHeight = size.height
        info.supersample = Double(size.width) / Double(max(1, width))
        let image = try await renderer.render(pose: pose, width: width, height: height, renderWidth: size.width, renderHeight: size.height,
                                              settleFrames: first ? quality.settleFrames : 0, grade: grade, timing: &timing)
        first = false
        info.metalMegabytes = Double(renderer.lastAllocatedBytes) / 1_048_576
        return (image, info, timing)
    }

    func close() {
        renderer.close()
    }
}

@MainActor
extension World {
    /// Night (white type on a dark plate) once the sun is below −6° (civil dusk), else day.
    public var postcardAppearance: PostcardAppearance {
        let elevation = environment?.light.sunElevationDeg ?? lighting.sunElevation
        return elevation < -6 ? .night : .day
    }

    /// Exports postcards of the world from `pose`: each size and style rendered offscreen at its own
    /// picture size (never upscaled from the screen, never cropped from another size), with the
    /// world's grade and bloom, framed with `request.text`, and with "© OpenStreetMap contributors"
    /// (plus the provider mark, legal URL and modified-data notice for live weather) burned in.
    /// `request.quality` decides how hard each picture works (`.max` by default).
    ///
    /// The live view keeps running: the world is copied for the offscreen renderer, never moved.
    /// Results come back style by style, sizes in request order. One export runs at a time.
    public func exportPostcards(pose: CameraPose, request: PostcardRequest) async throws -> [PostcardImage] {
        guard !request.sizes.isEmpty, !request.styles.isEmpty else { return [] }
        guard !PostcardJobs.running else { throw PostcardExportError.busy }
        PostcardJobs.running = true
        defer { PostcardJobs.running = false }

        let appearance = request.appearance ?? postcardAppearance
        let credits = PostcardFrame.imageCredits(sources: manifest.sources, weather: request.weather)
        var jobs: [(style: PostcardStyle, size: PostcardSize, layout: PostcardLayout, pose: CameraPose)] = []
        for style in request.styles {
            for size in request.sizes {
                let layout = PostcardFrame.layout(size: size, style: style, appearance: appearance, text: request.text,
                                                  weather: request.weather, credits: credits)
                jobs.append((style, size, layout, pose.reframed(forAspect: layout.pictureAspect, composedAspect: request.composedAspect)))
            }
        }
        let vFOV = jobs.map(\.pose.verticalFOVDegrees).max() ?? pose.verticalFOVDegrees
        let hFOV = jobs.map { PostcardReframe.horizontalFOV(verticalFOV: $0.pose.verticalFOVDegrees, aspect: $0.layout.pictureAspect) }.max() ?? vFOV
        let session = try await OffscreenSession(world: self, eye: pose.eye, target: pose.target, widestVerticalFOV: vFOV,
                                                 widestHorizontalFOV: hFOV, quality: request.quality, post: request.post,
                                                 includeCharacters: request.includeCharacters)
        defer { session.close() }

        var images: [PostcardImage] = []
        for job in jobs {
            let r = job.layout.picture
            var shot = try await session.picture(pose: job.pose, width: Int(r.width), height: Int(r.height))
            let started = Date()
            let image: CGImage
            do {
                image = try PostcardFrame.compose(picture: shot.image, layout: job.layout, weather: request.weather)
            } catch {
                throw PostcardExportError.renderFailed("frame: \(error)")
            }
            shot.timing.frame = Date().timeIntervalSince(started) * 1000
            images.append(PostcardImage(size: job.size, style: job.style, pose: job.pose, layout: job.layout, image: image,
                                        info: shot.info, timing: shot.timing))
        }
        return images
    }

    /// The bare picture of `pose` at `width` × `height`, without a frame or burned-in credits: a
    /// test artifact like `WorldRenderState.snapshot` (P3's look loop compares quality mode with the
    /// live view). With `composedAspect` the pose is reframed for the picture first. Anything shown
    /// to people goes through `exportPostcards`.
    public func renderStill(pose: CameraPose, width: Int, height: Int, quality: PostcardQuality, post: WorldPostProcess.Settings?,
                            composedAspect: Double? = nil, includeCharacters: Bool = false) async throws
        -> (image: CGImage, info: PostcardRenderInfo, timing: PostcardTiming) {
        guard !PostcardJobs.running else { throw PostcardExportError.busy }
        PostcardJobs.running = true
        defer { PostcardJobs.running = false }
        let aspect = Double(width) / Double(max(1, height))
        let framed = composedAspect.map { pose.reframed(forAspect: aspect, composedAspect: $0) } ?? pose
        let session = try await OffscreenSession(
            world: self, eye: framed.eye, target: framed.target, widestVerticalFOV: framed.verticalFOVDegrees,
            widestHorizontalFOV: PostcardReframe.horizontalFOV(verticalFOV: framed.verticalFOVDegrees, aspect: aspect),
            quality: quality, post: post, includeCharacters: includeCharacters)
        defer { session.close() }
        return try await session.picture(pose: framed, width: width, height: height)
    }

    /// Seconds of simulation that fill the air with rain or snow (emitters start empty in the
    /// offscreen scene); nil when nothing falls.
    static func precipitationWarmUp(in copy: Entity) -> Double? {
        guard let p = copy.children.first(where: { $0.name == "Precipitation" }), p.isEnabled,
              let emitter = p.components[ParticleEmitterComponent.self], emitter.isEmitting else { return nil }
        return min(Double(emitter.mainEmitter.lifeSpan), 8) + 0.5
    }
}
