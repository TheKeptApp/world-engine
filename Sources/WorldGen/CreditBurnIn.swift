#if canImport(CoreGraphics) && canImport(CoreText)
import CoreGraphics
import CoreText
import Foundation

/// Burns the required credits into an exported image (decision 6c: no credit-free exports).
///
/// **Every exported image must pass through `burn(_:credits:style:)` (or `burn(_:lines:style:)`)
/// before it leaves the renderer**: postcards, snapshots, share images, widget images and video
/// frames. The on-screen `WorldAttributionView` is a SwiftUI overlay and never appears in
/// offscreen renders, so without this step an export carries no credit at all.
///
/// Draws "© OpenStreetMap contributors · openstreetmap.org/copyright" (always, first) plus every
/// other credit with `burnIn` for the `image` surface (manifest sources whose licence requires
/// credit, the weather provider's modified-data notice) in one corner, on a fixed-contrast plate
/// (white 85 %, text black 90 %, as on screen) so it stays legible over any picture. Text height
/// scales with the image (`Style.relativeFontSize` of the short side, at least
/// `Style.minimumFontSize` px). Lines too wide for the image first split at " · ", then the font
/// shrinks to fit: a small image still gets the full credit, never a truncated or missing one.
///
/// Pure CoreGraphics/CoreText (lives in WorldGen so it is unit-tested); WorldEngine re-exports it
/// as `WorldCreditBurnIn` and wraps it in `WorldCredits.burnIn(...)`.
public enum CreditBurnIn {
    /// The OpenStreetMap credit with its printed URL (OSMF attribution guideline, static images).
    public static let osmLine = "© OpenStreetMap contributors · openstreetmap.org/copyright"

    public enum Corner: String, Sendable, CaseIterable {
        case bottomTrailing, bottomLeading, topTrailing, topLeading
    }

    public struct Style: Sendable, Equatable {
        public var corner: Corner
        /// Font size as a fraction of the image's short side.
        public var relativeFontSize: Double
        /// Smallest font size in pixels, unless the image is too small to fit the text at it.
        public var minimumFontSize: Double

        public init(corner: Corner = .bottomTrailing, relativeFontSize: Double = 0.022, minimumFontSize: Double = 11) {
            self.corner = corner
            self.relativeFontSize = relativeFontSize
            self.minimumFontSize = minimumFontSize
        }
    }

    /// Where the credit goes. `plate` uses image pixel coordinates with the origin at the top left.
    public struct Layout: Sendable, Equatable {
        public var lines: [String]
        public var fontSize: Double
        public var plate: CGRect
    }

    public enum BurnError: Error, Sendable {
        case renderFailed
    }

    /// The lines to burn for a merged credit list: the OSM line first (always, even for an empty
    /// list), then each other `burnIn` credit that applies to images, without placeholders or
    /// duplicates.
    public static func lines(for credits: [Credit]) -> [String] {
        var out = [osmLine]
        for c in credits where c.burnIn && c.surfaces.contains(.image) && !c.isPlaceholder {
            let line = c.burnInLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if !line.isEmpty, !out.contains(line) { out.append(line) }
        }
        return out
    }

    /// Burns `lines(for: credits)` into the image.
    public static func burn(_ image: CGImage, credits: [Credit], style: Style = .init()) throws -> CGImage {
        try burn(image, lines: lines(for: credits), style: style)
    }

    /// Burns `lines` into the image. The OSM line is added first if it is missing.
    public static func burn(_ image: CGImage, lines: [String], style: Style = .init()) throws -> CGImage {
        let w = image.width, h = image.height
        let l = layout(width: w, height: h, lines: lines, style: style)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw BurnError.renderFailed }
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        // CoreGraphics draws bottom-up: flip the top-left layout rectangle.
        let plate = CGRect(x: l.plate.minX, y: CGFloat(h) - l.plate.maxY, width: l.plate.width, height: l.plate.height)
        let m = metrics(l.fontSize)
        let radius = min(plate.height / 2, CGFloat(l.fontSize) * 0.35)
        ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.85))
        ctx.addPath(CGPath(roundedRect: plate, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.fillPath()

        let font = CTFontCreateUIFontForLanguage(.system, CGFloat(l.fontSize), nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, CGFloat(l.fontSize), nil)
        let color = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.9)
        let trailing = style.corner == .bottomTrailing || style.corner == .topTrailing
        ctx.textMatrix = .identity
        var baseline = plate.maxY - m.padV - m.ascent
        for text in l.lines {
            let line = ctLine(text, font: font, color: color)
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let x = trailing ? plate.maxX - m.padH - width : plate.minX + m.padH
            ctx.textPosition = CGPoint(x: x, y: baseline)
            CTLineDraw(line, ctx)
            baseline -= m.lineHeight + m.gap
        }
        guard let out = ctx.makeImage() else { throw BurnError.renderFailed }
        return out
    }

    /// The plate, font size and final lines for an image of `width` × `height` pixels.
    public static func layout(width: Int, height: Int, lines input: [String], style: Style = .init()) -> Layout {
        var lines = input.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !lines.contains(osmLine) { lines.insert(osmLine, at: 0) }
        let w = Double(max(1, width)), h = Double(max(1, height))
        var size = max(style.minimumFontSize, min(w, h) * style.relativeFontSize)

        func box(_ lines: [String], _ size: Double) -> (width: Double, height: Double) {
            let m = metrics(size)
            let font = CTFontCreateUIFontForLanguage(.system, CGFloat(size), nil)
                ?? CTFontCreateWithName("Helvetica" as CFString, CGFloat(size), nil)
            let widest = lines.map { Double(CTLineGetTypographicBounds(ctLine($0, font: font, color: nil), nil, nil, nil)) }.max() ?? 0
            let textHeight = Double(lines.count) * Double(m.lineHeight) + Double(max(0, lines.count - 1)) * Double(m.gap)
            return (widest.rounded(.up) + 2 * Double(m.padH), textHeight + 2 * Double(m.padV))
        }
        func fits(_ b: (width: Double, height: Double), _ size: Double) -> Bool {
            let margin = Double(metrics(size).margin)
            return b.width <= w - 2 * margin && b.height <= h - 2 * margin
        }

        var b = box(lines, size)
        if !fits(b, size) {
            // Split "credit · url" pairs onto their own lines before shrinking anything.
            let split = lines.flatMap { $0.components(separatedBy: " · ") }
            if split.count > lines.count { lines = split; b = box(lines, size) }
        }
        var guardCount = 0
        while !fits(b, size), size > 0.5, guardCount < 60 {
            let margin = Double(metrics(size).margin)
            let scale = min((w - 2 * margin) / b.width, (h - 2 * margin) / b.height, 0.97)
            size = max(0.5, size * max(0.5, scale))
            b = box(lines, size)
            guardCount += 1
        }

        let margin = Double(metrics(size).margin)
        let pw = min(b.width, w), ph = min(b.height, h)
        let left = style.corner == .bottomLeading || style.corner == .topLeading
        let top = style.corner == .topLeading || style.corner == .topTrailing
        let x = left ? margin : w - margin - pw
        let y = top ? margin : h - margin - ph
        let plate = CGRect(x: max(0, x).rounded(.down), y: max(0, y).rounded(.down), width: pw.rounded(.up), height: ph.rounded(.up))
        return Layout(lines: lines, fontSize: size, plate: plate.intersection(CGRect(x: 0, y: 0, width: w, height: h)))
    }

    // MARK: - Text

    struct Metrics {
        var ascent: CGFloat, lineHeight: CGFloat, gap: CGFloat, padH: CGFloat, padV: CGFloat, margin: CGFloat
    }

    static func metrics(_ size: Double) -> Metrics {
        let font = CTFontCreateUIFontForLanguage(.system, CGFloat(size), nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, CGFloat(size), nil)
        let ascent = CTFontGetAscent(font), descent = CTFontGetDescent(font)
        let s = CGFloat(size)
        return Metrics(ascent: ascent, lineHeight: ascent + descent, gap: s * 0.15, padH: s * 0.5, padV: s * 0.3,
                       margin: max(1, s * 0.6))
    }

    static func ctLine(_ text: String, font: CTFont, color: CGColor?) -> CTLine {
        var attributes: [CFString: Any] = [kCTFontAttributeName: font]
        if let color { attributes[kCTForegroundColorAttributeName] = color }
        let string = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        return CTLineCreateWithAttributedString(string)
    }
}
#endif
