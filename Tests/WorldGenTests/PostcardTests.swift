import CoreGraphics
import CoreText
import Foundation
import ImageIO
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap

/// Postcard frames (docs/postcards.md; spec: docs/proposals/postcards-widgets-v1).
@Suite("Postcard frames")
struct PostcardFrameTests {
    // MARK: Fixtures

    static let text = PostcardText(placeName: "Evanston", localTime: "Oct 6, 2026 · 2:30 PM CDT", condition: "Partly cloudy",
                                   temperature: "58°F", demoLabel: "Demo")

    /// Solid stand-ins for the provider marks (never a real logo): blue for light plates, orange for dark.
    static let markLight = solid(231, 42, r: 0, g: 0, b: 255)
    static let markDark = solid(231, 42, r: 255, g: 128, b: 0)

    static let liveCredit = WeatherCredit(serviceName: "Apple Weather", legalPageURL: "https://weatherkit.apple.com/legal-attribution.html",
                                          markLightURL: "https://example.invalid/light.png", markDarkURL: "https://example.invalid/dark.png",
                                          modifiedNotice: "Weather visualization modified from Apple Weather data.")
    static let live = PostcardWeather.live(credit: liveCredit, markLight: markLight, markDark: markDark)

    static func solid(_ w: Int, _ h: Int, r: UInt8, g: UInt8, b: UInt8) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()!
    }

    /// A stand-in for the rendered world: a vertical gradient (sky to ground).
    static func picture(_ layout: PostcardLayout) -> CGImage {
        let w = Int(layout.picture.width), h = Int(layout.picture.height)
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(srgbRed: 0.55, green: 0.7, blue: 0.9, alpha: 1), CGColor(srgbRed: 0.3, green: 0.45, blue: 0.25, alpha: 1)] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: colors, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
        return ctx.makeImage()!
    }

    /// RGBA bytes, row 0 = top.
    static func pixels(_ image: CGImage) -> [UInt8] {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        data.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return data
    }

    static func pixel(_ p: [UInt8], width: Int, x: Int, y: Int) -> SIMD3<Int> {
        let i = (y * width + x) * 4
        return SIMD3(Int(p[i]), Int(p[i + 1]), Int(p[i + 2]))
    }

    /// Pixels inside `rect` within `tolerance` (per channel) of `color` (sRGB 0–1).
    static func count(_ p: [UInt8], width: Int, in rect: CGRect, near color: SIMD3<Double>, tolerance: Int = 40) -> Int {
        let target = SIMD3<Int>(Int((color.x * 255).rounded()), Int((color.y * 255).rounded()), Int((color.z * 255).rounded()))
        var n = 0
        for y in Int(rect.minY.rounded(.down))..<Int(rect.maxY.rounded(.up)) {
            for x in Int(rect.minX.rounded(.down))..<Int(rect.maxX.rounded(.up)) {
                let d = pixel(p, width: width, x: x, y: y) &- target
                if abs(d.x) <= tolerance, abs(d.y) <= tolerance, abs(d.z) <= tolerance { n += 1 }
            }
        }
        return n
    }

    static func layout(_ size: PostcardSize, _ style: PostcardStyle, _ appearance: PostcardAppearance = .day,
                       weather: PostcardWeather = .demo, text: PostcardText = PostcardFrameTests.text,
                       sources: [AreaManifest.Source] = []) -> PostcardLayout {
        PostcardFrame.layout(size: size, style: style, appearance: appearance, text: text, weather: weather,
                             credits: PostcardFrame.imageCredits(sources: sources, weather: weather))
    }

    static func inside(_ inner: CGRect, _ outer: CGRect) -> Bool {
        inner.minX >= outer.minX - 0.01 && inner.minY >= outer.minY - 0.01 && inner.maxX <= outer.maxX + 0.01 && inner.maxY <= outer.maxY + 0.01
    }

    // MARK: Sizes, styles and safe areas

    @Test func sizesStylesAndMargins() {
        #expect(PostcardSize.allCases.map { [$0.pixelWidth, $0.pixelHeight] } == [[1080, 1080], [1080, 1350], [1080, 1920]])
        #expect(PostcardStyle.allCases.map(\.margin) == [32, 55, 32])
        #expect(PostcardSize.story.reservedBand == 240 && PostcardSize.square.reservedBand == 0 && PostcardSize.portrait.reservedBand == 0)
        #expect(PostcardFrame.fileName(style: .bold, size: .story) == "postcard-bold-story.png")
    }

    @Test func everythingStaysInsideTheSafeArea() {
        let long = PostcardText(placeName: "Village of Winnetka and the North Shore Lakefront Bluffs", localTime: "Wednesday, December 31, 2026 · 11:59 PM CST",
                                condition: "Thunderstorms with heavy rain and small hail", temperature: "−12°C", demoLabel: "Demo")
        let overture = AreaManifest.Source(format: "overture-buildings-v1", path: "x.json", layers: ["buildings"],
                                           bounds: GeoBoundingBox(south: 0, west: 0, north: 0.01, east: 0.01), dataTimestamp: nil,
                                           fetchedAt: nil, bytes: nil, sha256: nil, license: "ODbL-1.0",
                                           attribution: "© OpenStreetMap contributors, Overture Maps Foundation")
        for size in PostcardSize.allCases {
            for style in PostcardStyle.allCases {
                for appearance in PostcardAppearance.allCases {
                    for weather in [PostcardWeather.demo, Self.live] {
                        for text in [Self.text, long] {
                            let l = Self.layout(size, style, appearance, weather: weather, text: text, sources: [overture])
                            let edge = Double(style.margin)
                            let band = Double(max(style.margin, size.reservedBand))
                            // The safe area: the style's margin on every side (classic 55 px), story bands 240 px.
                            #expect(l.safeArea.minX == edge && l.canvas.maxX - l.safeArea.maxX == edge)
                            #expect(l.safeArea.minY == band && l.canvas.maxY - l.safeArea.maxY == band)
                            #expect(edge >= 32 && (style != .classic || edge >= 55))
                            for e in l.elements {
                                #expect(Self.inside(e.frame, l.safeArea), "\(size) \(style) \(appearance) \(e.name) \(e.frame) outside \(l.safeArea)")
                                #expect(e.frame.width >= 0 && e.frame.height >= 0)
                            }
                            // The picture is whole pixels and keeps a sensible share of the canvas.
                            #expect(l.picture == l.picture.integral)
                            #expect(l.picture.height > l.canvas.height * 0.45, "\(size) \(style) picture \(l.picture)")
                            // Long names shrink to 20 pt, then end in "…"; nothing overlaps the picture.
                            #expect(l.place.fontSize >= 40 && l.place.fontSize <= 54)
                            #expect(l.place.frame.maxY < l.picture.minY && (l.details?.frame.maxY ?? 0) < l.picture.minY)
                            #expect(l.credits.frame.minY > l.picture.maxY)
                        }
                    }
                }
            }
        }
        let truncated = Self.layout(.square, .classic, text: long)
        #expect(truncated.place.string.hasSuffix("…") && truncated.place.fontSize == 40)
    }

    @Test func storyKeepsItsBandsFree() {
        for style in PostcardStyle.allCases {
            let l = Self.layout(.story, style)
            let top = l.elements.map(\.frame.minY).min()!, bottom = l.elements.map(\.frame.maxY).max()!
            #expect(top >= 240 && bottom <= 1920 - 240, "\(style) \(top) \(bottom)")
        }
    }

    // MARK: Credits

    @Test func osmCreditIsBurnedIntoEveryPostcard() throws {
        for size in PostcardSize.allCases {
            for style in PostcardStyle.allCases {
                for appearance in PostcardAppearance.allCases {
                    for weather in [PostcardWeather.demo, Self.live] {
                        let l = Self.layout(size, style, appearance, weather: weather)
                        let first = try #require(l.credits.lines.first)
                        #expect(first.text == CreditBurnIn.osmLine && first.text.hasPrefix("© OpenStreetMap contributors"))
                        #expect(Self.inside(first.frame, l.safeArea) && Self.inside(first.frame, l.canvas))
                        // Burned in: the line's box holds type in the frame's text colour.
                        let image = try PostcardFrame.compose(picture: Self.picture(l), layout: l, weather: weather)
                        #expect(image.width == size.pixelWidth && image.height == size.pixelHeight)
                        let inked = Self.count(Self.pixels(image), width: image.width, in: first.frame, near: l.colors.text)
                        #expect(inked > 150, "\(size) \(style) \(appearance): \(inked) text pixels in the OSM credit")
                    }
                }
            }
        }
    }

    @Test func demoWeatherShowsALabelAndNoProviderMark() throws {
        for style in PostcardStyle.allCases {
            let l = Self.layout(.portrait, style, weather: .demo)
            let label = try #require(l.demoWeather)
            #expect(label.text.string == "Demo weather" && label.text.string == PostcardFrame.demoWeatherLabel)
            #expect(Self.inside(label.capsule, l.safeArea) && label.capsule.minY > l.credits.frame.maxY)
            #expect(l.credits.rows.allSatisfy { $0.kind == .credit && $0.mark == nil })
            #expect(!l.credits.lines.contains { $0.text.contains("Apple") || $0.text.contains("modified from") })
            #expect(l.demoTag?.text.string == "Demo")
            // Drawn: the label's capsule holds type in the text colour; no mark colour anywhere.
            let image = try PostcardFrame.compose(picture: Self.picture(l), layout: l, weather: .demo)
            let p = Self.pixels(image)
            #expect(Self.count(p, width: image.width, in: label.capsule, near: l.colors.text) > 100)
            #expect(Self.count(p, width: image.width, in: l.canvas, near: SIMD3(0, 0, 1), tolerance: 2) == 0)
            #expect(Self.count(p, width: image.width, in: l.canvas, near: SIMD3(1, 0.5, 0), tolerance: 2) == 0)
        }
        // Without the host's label the details line has no tag; the credit label stays.
        var plain = Self.text
        plain.demoLabel = nil
        let l = Self.layout(.square, .bold, weather: .demo, text: plain)
        #expect(l.demoTag == nil && l.demoWeather != nil)
    }

    @Test func liveWeatherShowsTheMarkTheLegalURLAndTheNotice() throws {
        for style in PostcardStyle.allCases {
            for appearance in PostcardAppearance.allCases {
                let l = Self.layout(.square, style, appearance, weather: Self.live)
                #expect(l.demoWeather == nil)
                let provider = try #require(l.credits.rows.first { $0.kind == .provider })
                let mark = try #require(provider.mark)
                // Proportional: the mark keeps the image's aspect ratio, 14 pt (28 px) high.
                #expect(abs(mark.width / mark.height - 231.0 / 42.0) < 0.001 && abs(mark.height - 28) < 0.001)
                // The legal page as readable text (no scheme), and the modified-data notice after it.
                #expect(provider.lines.map(\.text) == ["weatherkit.apple.com/legal-attribution.html"])
                let lines = l.credits.lines.map(\.text)
                #expect(lines.first == CreditBurnIn.osmLine)
                #expect(lines.last == "Weather visualization modified from Apple Weather data.")
                let rows = l.credits.rows
                let providerIndex = try #require(rows.firstIndex { $0.kind == .provider })
                #expect(rows.indices.contains(providerIndex + 1)
                        && rows[providerIndex + 1].lines.first?.text == "Weather visualization modified from Apple Weather data.")

                // Drawn unmodified: the mark's own colour, exactly, inside its box; the mark for the
                // plate's brightness and never the other one.
                let image = try PostcardFrame.compose(picture: Self.picture(l), layout: l, weather: Self.live)
                let p = Self.pixels(image)
                let expected: SIMD3<Double> = l.usesDarkMark ? SIMD3(1, 128.0 / 255, 0) : SIMD3(0, 0, 1)
                let other: SIMD3<Double> = l.usesDarkMark ? SIMD3(0, 0, 1) : SIMD3(1, 128.0 / 255, 0)
                let inner = mark.insetBy(dx: 2, dy: 2)
                let total = (Int(inner.maxX.rounded(.up)) - Int(inner.minX.rounded(.down))) * (Int(inner.maxY.rounded(.up)) - Int(inner.minY.rounded(.down)))
                #expect(Self.count(p, width: image.width, in: inner, near: expected, tolerance: 0) == total)
                #expect(Self.count(p, width: image.width, in: l.canvas, near: other, tolerance: 2) == 0)
                #expect(l.usesDarkMark == (style == .bold || appearance == .night))
            }
        }
    }

    @Test func liveWeatherWithoutANoticeGetsTheStandardOne() {
        var credit = Self.liveCredit
        credit.modifiedNotice = nil
        let l = Self.layout(.square, .minimal, weather: .live(credit: credit, markLight: Self.markLight, markDark: Self.markDark))
        #expect(l.credits.lines.last?.text == "Weather visualization modified from Apple Weather data.")
    }

    @Test func extraSourceCreditsFollowTheOSMLineAndLongOnesWrap() {
        let source = AreaManifest.Source(format: "test-source", path: "x.json", layers: ["all"],
                                         bounds: GeoBoundingBox(south: 0, west: 0, north: 0.01, east: 0.01), dataTimestamp: nil,
                                         fetchedAt: nil, bytes: nil, sha256: nil, license: "CC-BY-4.0",
                                         attribution: String(repeating: "Contributors of a very long attribution line ", count: 4))
        let l = Self.layout(.square, .classic, sources: [source])
        let lines = l.credits.lines
        #expect(lines.first?.text == CreditBurnIn.osmLine)
        #expect(lines.count > 2)
        // Wrapped, not truncated: every character of the attribution is still there.
        let rejoined = lines.dropFirst().map(\.text).joined(separator: " ")
        #expect(rejoined.replacingOccurrences(of: " ", with: "") == source.attribution.replacingOccurrences(of: " ", with: ""))
        #expect(lines.allSatisfy { $0.fontSize >= 22 && Self.inside($0.frame, l.safeArea) })
    }

    // MARK: Night plate and type

    @Test func nightPutsWhiteTypeOnAQuietOpaquePlate() {
        for style in PostcardStyle.allCases {
            let night = style.colors(.night), day = style.colors(.day)
            #expect(night.text == SIMD3(1, 1, 1))
            #expect(PostcardColors.luminance(night.plate) < 0.05 && night.isDark)
            #expect(night.contrast >= 7 && day.contrast >= 7, "\(style) contrast \(night.contrast) / \(day.contrast)")
            // Quiet: low chroma.
            #expect(night.plate.max() - night.plate.min() < 0.15)
            let l = Self.layout(.portrait, style, .night)
            #expect(l.colors == night && l.usesDarkMark)
        }
        #expect(!PostcardStyle.classic.colors(.day).isDark && !PostcardStyle.minimal.colors(.day).isDark && PostcardStyle.bold.colors(.day).isDark)
    }

    @Test func typeFollowsTheSpec() throws {
        let l = Self.layout(.square, .bold)
        // Place 20–28 pt, condition 15–17 pt, credits 11–12 pt, at 2 px per pt.
        #expect(l.place.fontSize == 54 && l.place.bold && l.place.string == "EVANSTON")
        let details = try #require(l.details)
        #expect(details.fontSize == 30 && details.tabularFigures)
        #expect(details.string == "Oct 6, 2026 · 2:30 PM CDT  ·  Partly cloudy · 58°F")
        #expect(l.credits.lines.allSatisfy { $0.fontSize >= 22 && $0.fontSize <= 24 })
        // Tabular time: every digit has the same advance.
        let font = PostcardFrame.font(30, bold: false, tabular: true)
        let widths = (0...9).map { PostcardFrame.width("\($0)\($0):\($0)\($0)", font: font) }
        #expect(widths.allSatisfy { abs($0 - widths[0]) < 0.001 }, "\(widths)")
        #expect(PostcardText(placeName: "X", localTime: "", condition: "Clear").detailsLine == "Clear")
        #expect(PostcardText(placeName: "X", localTime: "9:15 PM", condition: "", temperature: "54°F").detailsLine == "9:15 PM  ·  54°F")
    }

    // MARK: Determinism

    @Test func sameInputsGiveTheSameImage() throws {
        for weather in [PostcardWeather.demo, Self.live] {
            let a = Self.layout(.story, .classic, .night, weather: weather)
            let b = Self.layout(.story, .classic, .night, weather: weather)
            #expect(a == b)
            let one = try PostcardFrame.compose(picture: Self.picture(a), layout: a, weather: weather)
            let two = try PostcardFrame.compose(picture: Self.picture(b), layout: b, weather: weather)
            #expect(Self.pixels(one) == Self.pixels(two))
            #expect(try PostcardFrame.pngData(one) == PostcardFrame.pngData(two))
        }
    }

    @Test func pngIsTheFullCanvas() throws {
        let l = Self.layout(.portrait, .minimal)
        let image = try PostcardFrame.compose(picture: Self.picture(l), layout: l, weather: .demo)
        let png = try PostcardFrame.pngData(image)
        #expect(png.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        let source = try #require(CGImageSourceCreateWithData(png as CFData, nil))
        let decoded = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(decoded.width == 1080 && decoded.height == 1350)
        // The picture lands one pixel per pixel where the layout put it.
        let p = Self.pixels(decoded), q = Self.pixels(Self.picture(l))
        let x = Int(l.picture.midX), y = Int(l.picture.midY)
        #expect(Self.pixel(p, width: 1080, x: x, y: y) == Self.pixel(q, width: Int(l.picture.width), x: x - Int(l.picture.minX), y: y - Int(l.picture.minY)))
    }
}

/// Camera reframing per aspect ratio (docs/postcards.md, "Reframing").
@Suite("Postcard reframing")
struct PostcardReframeTests {
    static let pose = CameraPose(eye: SIMD3(10, 1.65, -20), target: SIMD3(30, 0.08, -40), verticalFOVDegrees: 50)

    @Test func keepsTheEyeAndTheLookAtPoint() {
        for aspect in [0.5, 0.84, 1, 1.39, 16.0 / 9, 2.4] {
            let r = Self.pose.reframed(forAspect: aspect)
            #expect(r.eye == Self.pose.eye && r.target == Self.pose.target)
        }
        // The composed 16:9 frame is unchanged.
        #expect(abs(Self.pose.reframed(forAspect: 16.0 / 9).verticalFOVDegrees - 50) < 1e-9)
    }

    @Test func keepsTheDiagonalFieldOfView() {
        let composed = PostcardReframe.diagonalFOV(verticalFOV: 50, aspect: 16.0 / 9)
        for aspect in [0.84, 0.88, 1.0, 1.39, 1.45] {
            let v = Self.pose.reframed(forAspect: aspect).verticalFOVDegrees
            #expect(abs(PostcardReframe.diagonalFOV(verticalFOV: v, aspect: aspect) - composed) < 1e-6)
            #expect(v > 50 && v <= PostcardReframe.maxVerticalFOVDegrees)
        }
    }

    @Test func tallPicturesKeepMostOfTheComposedWidth() {
        let composedWidth = PostcardReframe.horizontalFOV(verticalFOV: 50, aspect: 16.0 / 9)
        for size in PostcardSize.allCases {
            for style in PostcardStyle.allCases {
                let l = PostcardFrame.layout(size: size, style: style, appearance: .day, text: PostcardFrameTests.text, weather: .demo,
                                             credits: PostcardFrame.imageCredits(weather: .demo))
                let v = Self.pose.reframed(forAspect: l.pictureAspect).verticalFOVDegrees
                let h = PostcardReframe.horizontalFOV(verticalFOV: v, aspect: l.pictureAspect)
                #expect(h >= 0.75 * composedWidth && h <= composedWidth, "\(size) \(style): \(h)° of \(composedWidth)°")
            }
        }
        // Very tall frames stop widening vertically at 75°.
        #expect(Self.pose.reframed(forAspect: 0.2).verticalFOVDegrees == 75)
    }
}
