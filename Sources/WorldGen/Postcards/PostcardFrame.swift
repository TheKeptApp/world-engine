#if canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import WorldMap

// Postcard frames (docs/postcards.md; spec: docs/proposals/postcards-widgets-v1, frame studies and
// one-page spec). Renderer-neutral CoreGraphics/CoreText, so the layout rules are unit-tested on
// the Mac; WorldEngine renders the picture offscreen and hands it to `PostcardFrame.compose`.

// MARK: - What a postcard is

/// Export sizes (one-page spec: "Exports: 1080×1080, 1080×1350, 1080×1920").
public enum PostcardSize: String, CaseIterable, Codable, Sendable {
    /// 1080 × 1080.
    case square
    /// 1080 × 1350 (4:5).
    case portrait
    /// 1080 × 1920 (9:16), with 240 px kept free at the top and bottom.
    case story

    public var pixelWidth: Int { 1080 }

    public var pixelHeight: Int {
        switch self {
        case .square: 1080
        case .portrait: 1350
        case .story: 1920
        }
    }

    /// Bands at the top and bottom kept free of type, credits and the picture (spec: "Story
    /// reserve 240 px top/bottom"; story viewers draw their own controls there).
    public var reservedBand: Int { self == .story ? 240 : 0 }
}

/// Frame styles (frame studies `frame-<style>-<size>`): plate, text colour and margin. The layout is
/// the same for all three: place name and details above the picture, credits below it.
public enum PostcardStyle: String, CaseIterable, Codable, Sendable {
    /// Deep teal plate, white type.
    case bold
    /// Warm paper plate, slate type, the wider 55 px margin.
    case classic
    /// White plate, slate type.
    case minimal

    /// Space between the canvas edge and the picture, type and credits (spec: "Keep type/credits
    /// 32 px inside edges; classic 55 px").
    public var margin: Int { self == .classic ? 55 : 32 }

    /// Day plates follow the frame studies. Night scenes get white type on a quiet, opaque dark
    /// plate (spec: "Night text white on a quiet opaque plate"); bold already is one.
    public func colors(_ appearance: PostcardAppearance) -> PostcardColors {
        let white = SIMD3<Double>(1, 1, 1)
        let slate = PostcardColors.rgb(0x303942)
        switch (self, appearance) {
        case (.bold, _): return PostcardColors(plate: PostcardColors.rgb(0x152F38), text: white)
        case (.classic, .day): return PostcardColors(plate: PostcardColors.rgb(0xF5F0E5), text: slate)
        case (.classic, .night): return PostcardColors(plate: PostcardColors.rgb(0x2A2724), text: white)
        case (.minimal, .day): return PostcardColors(plate: white, text: slate)
        case (.minimal, .night): return PostcardColors(plate: PostcardColors.rgb(0x16191D), text: white)
        }
    }
}

/// Day or night scene: night switches every style to white type on a dark plate.
public enum PostcardAppearance: String, CaseIterable, Codable, Sendable {
    case day, night
}

/// A frame's plate and type colours (sRGB, 0–1). Both are opaque.
public struct PostcardColors: Sendable, Equatable {
    public var plate: SIMD3<Double>
    public var text: SIMD3<Double>

    public init(plate: SIMD3<Double>, text: SIMD3<Double>) {
        self.plate = plate
        self.text = text
    }

    /// Dark plates take the provider mark made for dark backgrounds.
    public var isDark: Bool { Self.luminance(plate) < 0.18 }

    /// WCAG contrast ratio of the type against the plate.
    public var contrast: Double {
        let a = Self.luminance(plate), b = Self.luminance(text)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// WCAG relative luminance of an sRGB colour.
    public static func luminance(_ c: SIMD3<Double>) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.x) + 0.7152 * lin(c.y) + 0.0722 * lin(c.z)
    }

    static func rgb(_ hex: UInt32) -> SIMD3<Double> {
        SIMD3(Double((hex >> 16) & 0xFF), Double((hex >> 8) & 0xFF), Double(hex & 0xFF)) / 255
    }
}

/// The text block, supplied by the host as plain strings (already localized and formatted).
public struct PostcardText: Codable, Sendable, Equatable {
    /// Place display name; set in capitals, as in the frame studies.
    public var placeName: String
    /// Local time, e.g. "Oct 6, 2026 · 2:30 PM MDT". Set with tabular figures.
    public var localTime: String
    /// Condition, e.g. "Partly cloudy".
    public var condition: String
    /// Temperature with its unit, e.g. "58°F"; nil leaves it out.
    public var temperature: String?
    /// A short label after the details, e.g. "Demo" for synthetic weather; nil for none.
    public var demoLabel: String?

    public init(placeName: String, localTime: String, condition: String, temperature: String? = nil, demoLabel: String? = nil) {
        self.placeName = placeName
        self.localTime = localTime
        self.condition = condition
        self.temperature = temperature
        self.demoLabel = demoLabel
    }

    /// "<local time>  ·  <condition> · <temperature>", empty parts left out (frame studies).
    public var detailsLine: String {
        func clean(_ s: String?) -> String { (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        let weather = [clean(condition), clean(temperature)].filter { !$0.isEmpty }.joined(separator: " · ")
        return [clean(localTime), weather].filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }
}

/// Where the weather on the postcard came from, which decides its attribution.
public enum PostcardWeather: Sendable {
    /// Synthetic (Demo) weather: no provider mark; a small "Demo weather" label instead.
    case demo
    /// Live data from a weather provider. For Apple Weather: `credit` from WeatherKit's
    /// `WeatherService.attribution` (service name, `legalPageURL`, the mark URLs, and the notice
    /// "Weather visualization modified from Apple Weather data."), with the two mark images the host
    /// loaded at runtime from `combinedMarkLightURL` (drawn on light plates) and
    /// `combinedMarkDarkURL` (drawn on dark plates). Marks are drawn unmodified and proportional;
    /// WorldEngine never bundles or draws a provider logo of its own.
    case live(credit: WeatherCredit, markLight: CGImage, markDark: CGImage)

    /// The provider's attribution, its modified-data notice filled in ("Weather visualization
    /// modified from <provider> data.", the wording the providers use) when the host left it out.
    public var providerCredit: WeatherCredit? {
        guard case let .live(credit, _, _) = self else { return nil }
        var c = credit
        if (c.modifiedNotice ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            c.modifiedNotice = "Weather visualization modified from \(c.serviceName) data."
        }
        return c
    }

    /// The mark for a dark or light plate (nil for Demo weather).
    public func mark(dark: Bool) -> CGImage? {
        guard case let .live(_, light, darkMark) = self else { return nil }
        return dark ? darkMark : light
    }

    public var isDemo: Bool {
        if case .demo = self { return true }
        return false
    }
}

// MARK: - Layout

/// Where everything goes on one postcard. Pixels, origin at the top left of the canvas.
public struct PostcardLayout: Sendable, Equatable {
    /// One line of type: its typographic box (ascent + descent high) and baseline.
    public struct Text: Sendable, Equatable {
        public var string: String
        public var fontSize: Double
        public var bold: Bool
        public var tabularFigures: Bool
        public var frame: CGRect
        public var baseline: Double
    }

    /// A short label in an outlined capsule.
    public struct Tag: Sendable, Equatable {
        public var text: Text
        public var capsule: CGRect
    }

    /// A named rectangle, for safe-area checks.
    public struct Element: Sendable, Equatable {
        public var name: String
        public var frame: CGRect
    }

    public var size: PostcardSize
    public var style: PostcardStyle
    public var appearance: PostcardAppearance
    public var colors: PostcardColors
    public var canvas: CGRect
    /// Type, credits and the picture all stay inside: the style's margin from every edge, and the
    /// story's reserved bands.
    public var safeArea: CGRect
    /// The world picture, in whole pixels. WorldEngine renders it at exactly this size.
    public var picture: CGRect
    public var place: Text
    /// Local time · condition · temperature (nil when all three are empty).
    public var details: Text?
    /// The host's optional label after the details ("Demo").
    public var demoTag: Tag?
    /// Credits, set by `CreditBurnIn.block` and burned in by `CreditBurnIn.burn`.
    public var credits: CreditBurnIn.Block
    /// "Demo weather", in place of a provider mark (Demo weather only).
    public var demoWeather: Tag?

    /// Dark plates take the provider mark for dark backgrounds (`combinedMarkDarkURL`).
    public var usesDarkMark: Bool { colors.isDark }

    /// Width / height of the picture: the aspect the camera is reframed for.
    public var pictureAspect: Double { Double(picture.width / max(1, picture.height)) }

    /// Every typeset element, credit line, mark and the picture.
    public var elements: [Element] {
        var out = [Element(name: "picture", frame: picture), Element(name: "place", frame: place.frame)]
        if let details { out.append(Element(name: "details", frame: details.frame)) }
        if let demoTag { out.append(Element(name: "demoTag", frame: demoTag.capsule)) }
        for (i, row) in credits.rows.enumerated() {
            for line in row.lines { out.append(Element(name: "credit\(i): \(line.text)", frame: line.frame)) }
            if let mark = row.mark { out.append(Element(name: "mark", frame: mark)) }
        }
        if let demoWeather { out.append(Element(name: "demoWeather", frame: demoWeather.capsule)) }
        return out
    }
}

/// Lays out and draws postcard frames.
public enum PostcardFrame {
    /// The label drawn in place of a provider mark for Demo weather.
    public static let demoWeatherLabel = "Demo weather"

    /// The spec gives type in points (place 20–28 pt, condition 15–17 pt, credits 11–12 pt). The
    /// 1080-px canvases use 2 px per point, the scale of the frame studies (27 pt place = 54 px,
    /// 12 pt OSM credit = 24 px).
    public static let pixelsPerPoint = 2.0

    /// Type sizes and spacing (px).
    public enum Typography {
        public static let placeSize = 27 * PostcardFrame.pixelsPerPoint
        public static let placeMinimumSize = 20 * PostcardFrame.pixelsPerPoint
        public static let detailsSize = 15 * PostcardFrame.pixelsPerPoint
        public static let tagSize = 11 * PostcardFrame.pixelsPerPoint
        public static let tagPadding = (horizontal: 10.0, vertical: 4.0)
        public static let tagStroke = 2.0
        public static let tagGap = 14.0
        public static let headerGap = 4.0
        public static let gapAbovePicture = 24.0
        public static let gapBelowPicture = 20.0
        /// Credits: 12 pt, shrinking to 11 pt before a line wraps; the provider mark 14 pt high.
        public static let credits = CreditBurnIn.BlockStyle(fontSize: 12 * PostcardFrame.pixelsPerPoint,
                                                           minimumFontSize: 11 * PostcardFrame.pixelsPerPoint, rowGap: 8,
                                                           markHeight: 14 * PostcardFrame.pixelsPerPoint, markGap: 18)
    }

    public enum FrameError: Error, Sendable {
        case renderFailed
        case encodeFailed
    }

    /// The file name WorldEngine hosts use: `postcard-<style>-<size>.png`.
    public static func fileName(style: PostcardStyle, size: PostcardSize) -> String {
        "postcard-\(style.rawValue)-\(size.rawValue).png"
    }

    /// The credits a postcard burns in: the bundled catalog's image credits (OSM, every manifest
    /// source whose licence asks for credit) merged with the live weather provider's entry.
    public static func imageCredits(sources: [AreaManifest.Source] = [], weather: PostcardWeather) -> [Credit] {
        let provider = weather.providerCredit
        if let catalog = try? CreditsCatalog.bundled() {
            return catalog.merged(sources: sources, weather: provider, surface: .image)
        }
        // Catalog unreadable: the burn-in still adds the OSM line; keep the provider's entry.
        guard let p = provider else { return [] }
        return [Credit(id: CreditsCatalog.weatherCreditID, kind: .weather, title: "Weather", text: p.serviceName, detail: p.modifiedNotice,
                       url: p.legalPageURL, condition: .hostSupplied, surfaces: [.app, .web, .image], burnIn: true,
                       burnInText: p.modifiedNotice, markLightURL: p.markLightURL, markDarkURL: p.markDarkURL)]
    }

    /// The layout of one postcard. `credits` are the image credits (`imageCredits(...)`); the OSM
    /// line is always set first, even for an empty list.
    public static func layout(size: PostcardSize, style: PostcardStyle, appearance: PostcardAppearance, text: PostcardText,
                              weather: PostcardWeather, credits: [Credit]) -> PostcardLayout {
        let w = Double(size.pixelWidth), h = Double(size.pixelHeight)
        let side = Double(style.margin)
        let inset = max(side, Double(size.reservedBand))
        let safe = CGRect(x: side, y: inset, width: w - 2 * side, height: h - 2 * inset)
        let width = Double(safe.width)
        let colors = style.colors(appearance)

        // Header: the place, then local time · condition · temperature and the host's tag.
        let place = setLine(text.placeName.uppercased(), sizes: Typography.placeSize, Typography.placeMinimumSize, bold: true,
                            tabular: false, x: side, top: inset, width: width)
        let detailsTop = Double(place.frame.maxY) + Typography.headerGap
        let label = text.demoLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let tagSize = label.isEmpty ? nil : self.tagSize(label)
        let line = text.detailsLine
        let detailsWidth = width - (tagSize.map { Double($0.width) + Typography.tagGap } ?? 0)
        let details = line.isEmpty ? nil : setLine(line, sizes: Typography.detailsSize, Typography.detailsSize, bold: false, tabular: true,
                                                   x: side, top: detailsTop, width: detailsWidth)
        var headerBottom = Double((details ?? place).frame.maxY)
        var demoTag: PostcardLayout.Tag?
        if let tagSize {
            let rowHeight = details.map { Double($0.frame.height) } ?? Double(tagSize.height)
            let x = details.map { Double($0.frame.maxX) + Typography.tagGap } ?? side
            let tag = makeTag(label, x: x, y: detailsTop + (rowHeight - Double(tagSize.height)) / 2)
            headerBottom = max(headerBottom, Double(tag.capsule.maxY))
            demoTag = tag
        }

        // Credits from the bottom of the safe area up; a live provider always brings its entry.
        var credits = credits
        if weather.providerCredit != nil, !credits.contains(where: { $0.kind == .weather }) {
            credits += imageCredits(weather: weather).filter { $0.kind == .weather }
        }
        let markAspect = weather.mark(dark: colors.isDark).map { Double($0.width) / Double(max(1, $0.height)) }
        let probe = CreditBurnIn.block(for: credits, width: width, style: Typography.credits, markAspect: markAspect)
        let demoSize = weather.isDemo ? self.tagSize(demoWeatherLabel) : nil
        let creditsHeight = Double(probe.frame.height) + (demoSize.map { Typography.credits.rowGap + Double($0.height) } ?? 0)
        let creditsTop = Double(safe.maxY) - creditsHeight
        let block = probe.offsetBy(dx: side, dy: creditsTop)
        let demoWeather = demoSize.map { _ in makeTag(demoWeatherLabel, x: side, y: Double(block.frame.maxY) + Typography.credits.rowGap) }

        // The picture fills what is left between them, in whole pixels.
        let top = (headerBottom + Typography.gapAbovePicture).rounded(.up)
        let bottom = max(top + 1, (creditsTop - Typography.gapBelowPicture).rounded(.down))
        let picture = CGRect(x: side, y: top, width: width, height: bottom - top)

        return PostcardLayout(size: size, style: style, appearance: appearance, colors: colors,
                              canvas: CGRect(x: 0, y: 0, width: w, height: h), safeArea: safe, picture: picture, place: place,
                              details: details, demoTag: demoTag, credits: block, demoWeather: demoWeather)
    }

    // MARK: - Drawing

    /// The finished postcard: plate, picture (one picture pixel per canvas pixel when it has the
    /// layout's size), type, and the credits burned in through `CreditBurnIn`.
    public static func compose(picture: CGImage, layout: PostcardLayout, weather: PostcardWeather) throws -> CGImage {
        let w = Int(layout.canvas.width), h = Int(layout.canvas.height)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw FrameError.renderFailed
        }
        let ink = cgColor(layout.colors.text)
        ctx.setFillColor(cgColor(layout.colors.plate))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        let r = layout.picture
        ctx.interpolationQuality = picture.width == Int(r.width) && picture.height == Int(r.height) ? .none : .high
        ctx.draw(picture, in: CGRect(x: r.minX, y: CGFloat(h) - r.maxY, width: r.width, height: r.height))

        draw(layout.place, color: ink, in: ctx, height: h)
        if let details = layout.details { draw(details, color: ink, in: ctx, height: h) }
        for tag in [layout.demoTag, layout.demoWeather].compactMap({ $0 }) { draw(tag, color: ink, in: ctx, height: h) }
        guard let framed = ctx.makeImage() else { throw FrameError.renderFailed }

        // Decision 6c: every export passes through the burn-in helper.
        return try CreditBurnIn.burn(framed, block: layout.credits, color: ink, mark: weather.mark(dark: layout.usesDarkMark))
    }

    /// PNG bytes of a postcard.
    public static func pngData(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else {
            throw FrameError.encodeFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw FrameError.encodeFailed }
        return data as Data
    }

    // MARK: - Type

    static func font(_ size: Double, bold: Bool, tabular: Bool) -> CTFont {
        let base = CTFontCreateUIFontForLanguage(bold ? .emphasizedSystem : .system, CGFloat(size), nil)
            ?? CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, CGFloat(size), nil)
        guard tabular else { return base }
        // Tabular (monospaced) figures, so times line up (spec: "Use tabular time").
        let feature: [CFString: Any] = [kCTFontFeatureTypeIdentifierKey: kNumberSpacingType,
                                        kCTFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFeatureSettingsAttribute: [feature]] as CFDictionary)
        return CTFontCreateCopyWithAttributes(base, CGFloat(size), nil, descriptor)
    }

    static func ctLine(_ text: String, font: CTFont, color: CGColor?) -> CTLine {
        CreditBurnIn.ctLine(text, font: font, color: color)
    }

    static func width(_ text: String, font: CTFont) -> Double {
        Double(CTLineGetTypographicBounds(ctLine(text, font: font, color: nil), nil, nil, nil))
    }

    /// One line at the largest size in `sizes` that fits `width` (whole pixels), else at the
    /// smallest size with its tail replaced by "…".
    static func setLine(_ string: String, sizes largest: Double, _ smallest: Double, bold: Bool, tabular: Bool, x: Double, top: Double,
                        width: Double) -> PostcardLayout.Text {
        var size = largest
        var f = font(size, bold: bold, tabular: tabular)
        while size > smallest, Self.width(string, font: f) > width {
            size = max(smallest, size - 1)
            f = font(size, bold: bold, tabular: tabular)
        }
        var text = string
        if Self.width(text, font: f) > width {
            var chars = Array(string)
            while !chars.isEmpty, Self.width(String(chars) + "…", font: f) > width { chars.removeLast() }
            text = String(chars).trimmingCharacters(in: .whitespaces) + "…"
        }
        let ascent = Double(CTFontGetAscent(f)), descent = Double(CTFontGetDescent(f))
        return PostcardLayout.Text(string: text, fontSize: size, bold: bold, tabularFigures: tabular,
                                   frame: CGRect(x: x, y: top, width: Self.width(text, font: f), height: ascent + descent),
                                   baseline: top + ascent)
    }

    static func tagSize(_ label: String) -> CGSize {
        let f = font(Typography.tagSize, bold: true, tabular: false)
        let lineHeight = Double(CTFontGetAscent(f) + CTFontGetDescent(f))
        return CGSize(width: width(label, font: f) + 2 * Typography.tagPadding.horizontal,
                      height: lineHeight + 2 * Typography.tagPadding.vertical)
    }

    static func makeTag(_ label: String, x: Double, y: Double) -> PostcardLayout.Tag {
        let size = tagSize(label)
        let f = font(Typography.tagSize, bold: true, tabular: false)
        let ascent = Double(CTFontGetAscent(f)), descent = Double(CTFontGetDescent(f))
        let textTop = y + Typography.tagPadding.vertical
        let text = PostcardLayout.Text(string: label, fontSize: Typography.tagSize, bold: true, tabularFigures: false,
                                       frame: CGRect(x: x + Typography.tagPadding.horizontal, y: textTop, width: width(label, font: f),
                                                     height: ascent + descent),
                                       baseline: textTop + ascent)
        return PostcardLayout.Tag(text: text, capsule: CGRect(x: x, y: y, width: Double(size.width), height: Double(size.height)))
    }

    static func cgColor(_ c: SIMD3<Double>) -> CGColor {
        CGColor(srgbRed: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: 1)
    }

    static func draw(_ text: PostcardLayout.Text, color: CGColor, in ctx: CGContext, height: Int) {
        let line = ctLine(text.string, font: font(text.fontSize, bold: text.bold, tabular: text.tabularFigures), color: color)
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: text.frame.minX, y: CGFloat(height) - CGFloat(text.baseline))
        CTLineDraw(line, ctx)
    }

    static func draw(_ tag: PostcardLayout.Tag, color: CGColor, in ctx: CGContext, height: Int) {
        let s = Typography.tagStroke
        let r = tag.capsule
        let box = CGRect(x: r.minX, y: CGFloat(height) - r.maxY, width: r.width, height: r.height).insetBy(dx: s / 2, dy: s / 2)
        let radius = box.height / 2
        ctx.saveGState()
        ctx.setStrokeColor(color)
        ctx.setLineWidth(s)
        ctx.addPath(CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.strokePath()
        ctx.restoreGState()
        draw(tag.text, color: color, in: ctx, height: height)
    }
}
#endif
