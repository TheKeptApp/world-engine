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
    /// Grade and bloom, as on screen (pass the live `WorldPostProcess`'s settings); nil for none.
    public var post: WorldPostProcess.Settings?
    /// Draw the host's characters too, cloned in their current pose. Off by default: postcards are
    /// the no-character view (experience-v1), and the contact shadow is then left out as well.
    public var includeCharacters: Bool

    public init(text: PostcardText, weather: PostcardWeather, sizes: [PostcardSize] = PostcardSize.allCases,
                styles: [PostcardStyle] = [.classic], appearance: PostcardAppearance? = nil,
                composedAspect: Double = PostcardReframe.composedAspect, post: WorldPostProcess.Settings? = WorldPostProcess.Settings(),
                includeCharacters: Bool = false) {
        self.text = text
        self.weather = weather
        self.sizes = sizes
        self.styles = styles
        self.appearance = appearance
        self.composedAspect = composedAspect
        self.post = post
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
        // Camera-dependent state for this pose (a no-op when the live view shows it), then a copy
        // of the world as it is now. The copy never changes afterwards.
        prepareOffscreenView(eye: SIMD3<Float>(pose.eye), target: SIMD3<Float>(pose.target), keepContact: request.includeCharacters)
        let copy: Entity
        do {
            copy = try offscreenCopy(includeCharacters: request.includeCharacters)
        } catch {
            throw PostcardExportError.renderFailed("world copy: \(error)")
        }
        let renderer = try OffscreenWorldRenderer(root: copy, environment: skyEnvironment,
                                                  background: WorldGen.Color.srgb(shaderGlobals.fogColor), post: request.post)
        defer { renderer.close() }
        if let seconds = Self.precipitationWarmUp(in: copy) { try await renderer.simulate(seconds: seconds) }

        var images: [PostcardImage] = []
        for style in request.styles {
            for size in request.sizes {
                let layout = PostcardFrame.layout(size: size, style: style, appearance: appearance, text: request.text,
                                                  weather: request.weather, credits: credits)
                let width = Int(layout.picture.width), height = Int(layout.picture.height)
                let framed = pose.reframed(forAspect: Double(width) / Double(height), composedAspect: request.composedAspect)
                let picture = try await renderer.render(pose: framed, width: width, height: height)
                let image: CGImage
                do {
                    image = try PostcardFrame.compose(picture: picture, layout: layout, weather: request.weather)
                } catch {
                    throw PostcardExportError.renderFailed("frame: \(error)")
                }
                images.append(PostcardImage(size: size, style: style, pose: framed, layout: layout, image: image))
            }
        }
        return images
    }

    /// Seconds of simulation that fill the air with rain or snow (emitters start empty in the
    /// offscreen scene); nil when nothing falls.
    static func precipitationWarmUp(in copy: Entity) -> Double? {
        guard let p = copy.children.first(where: { $0.name == "Precipitation" }), p.isEnabled,
              let emitter = p.components[ParticleEmitterComponent.self], emitter.isEmitting else { return nil }
        return min(Double(emitter.mainEmitter.lifeSpan), 8) + 0.5
    }
}
