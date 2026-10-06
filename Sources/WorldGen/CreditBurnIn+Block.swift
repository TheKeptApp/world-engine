#if canImport(CoreGraphics) && canImport(CoreText)
import CoreGraphics
import CoreText
import Foundation

/// Credits set as a block inside a framed export (postcards). An extension of `CreditBurnIn`
/// (decision 6c), added for the postcard frames.
///
/// The corner `burn(_:credits:style:)` sets the credits on their own fixed-contrast plate over the
/// picture. A framed export already has a quiet opaque plate of its own, so here the same lines
/// (`lines(for:)`: the OSM line first, then every other burn-in credit for images, wording
/// unchanged) are set straight onto the frame in its text colour: top-down, left-aligned, at a
/// fixed type size, inside an area the frame reserves for them (its safe area).
///
/// The weather provider's entry gains one row just before its own line (the modified-data
/// notice): the provider mark the host loaded (for Apple Weather, the image at
/// `combinedMarkLightURL` or `combinedMarkDarkURL`), drawn unmodified and proportional, followed
/// by the printed legal-page URL. Nothing is truncated: a line too wide first splits at " · ",
/// then shrinks to `minimumFontSize`, then wraps.
extension CreditBurnIn {
    /// Type and spacing of a credit block, in pixels.
    public struct BlockStyle: Sendable, Equatable {
        /// Credit type size.
        public var fontSize: Double
        /// Lines too wide for the block shrink to this size before they wrap.
        public var minimumFontSize: Double
        /// Space between rows.
        public var rowGap: Double
        /// Height of the provider mark; its width follows the image's own aspect ratio.
        public var markHeight: Double
        /// Space between the mark and the printed URL.
        public var markGap: Double

        public init(fontSize: Double = 24, minimumFontSize: Double = 22, rowGap: Double = 8, markHeight: Double = 28,
                    markGap: Double = 18) {
            self.fontSize = fontSize
            self.minimumFontSize = minimumFontSize
            self.rowGap = rowGap
            self.markHeight = markHeight
            self.markGap = markGap
        }
    }

    /// A laid-out credit block. Frames use image pixels with the origin at the top left.
    public struct Block: Sendable, Equatable {
        public struct Line: Sendable, Equatable {
            public var text: String
            public var fontSize: Double
            /// The line's typographic box (ascent + descent high, as wide as the text).
            public var frame: CGRect
            public var baseline: Double
        }

        public struct Row: Sendable, Equatable {
            public enum Kind: String, Sendable {
                /// A credit line: OSM, a manifest source, the weather provider's notice.
                case credit
                /// The weather provider's mark and printed legal-page URL.
                case provider
            }

            public var kind: Kind
            public var lines: [Line]
            /// Where the provider mark goes (provider rows, when a mark is given).
            public var mark: CGRect?
            public var frame: CGRect
        }

        public var rows: [Row]
        /// The area the block was set in: as wide as asked, as tall as its rows.
        public var frame: CGRect

        /// Every line, top to bottom.
        public var lines: [Line] { rows.flatMap(\.lines) }

        /// The same block moved by (dx, dy).
        public func offsetBy(dx: Double, dy: Double) -> Block {
            func move(_ r: CGRect) -> CGRect { r.offsetBy(dx: dx, dy: dy) }
            return Block(rows: rows.map { row in
                Row(kind: row.kind,
                    lines: row.lines.map { Line(text: $0.text, fontSize: $0.fontSize, frame: move($0.frame), baseline: $0.baseline + dy) },
                    mark: row.mark.map(move), frame: move(row.frame))
            }, frame: move(frame))
        }
    }

    /// The printed form of a credit's link for media that cannot carry one: `displayURL`, else
    /// `url` without its scheme.
    public static func printedURL(_ credit: Credit) -> String? {
        guard var s = credit.displayURL ?? credit.url else { return nil }
        for scheme in ["https://", "http://"] where s.lowercased().hasPrefix(scheme) { s.removeFirst(scheme.count) }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    /// Sets `lines(for: credits)` as a block `width` pixels wide with its top left corner at
    /// `origin`. `markAspect` (width / height of the provider mark image) adds the mark to the
    /// weather provider's row; without it the row carries the printed legal URL only.
    public static func block(for credits: [Credit], origin: CGPoint = .zero, width: Double, style: BlockStyle = .init(),
                             markAspect: Double? = nil) -> Block {
        let width = max(1, width)
        let provider = credits.first { $0.kind == .weather && $0.burnIn && $0.surfaces.contains(.image) && !$0.isPlaceholder }
        let providerLine = provider.map { $0.burnInLine.trimmingCharacters(in: .whitespacesAndNewlines) }
        let url = provider.flatMap(printedURL)
        let aspect = markAspect.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }

        var rows: [Block.Row] = []
        var y = Double(origin.y)
        let x = Double(origin.x)
        func append(_ row: Block.Row) {
            rows.append(row)
            y = Double(row.frame.maxY) + style.rowGap
        }
        var providerPlaced = false
        for line in lines(for: credits) {
            if provider != nil, !providerPlaced, line == providerLine {
                providerPlaced = true
                if let row = providerRow(url: url, markAspect: aspect, x: x, y: y, width: width, style: style) { append(row) }
            }
            append(textRow(line, kind: .credit, x: x, y: y, width: width, style: style, isURL: false))
        }
        // A provider whose own line is empty still gets its mark and legal URL.
        if provider != nil, !providerPlaced,
           let row = providerRow(url: url, markAspect: aspect, x: x, y: y, width: width, style: style) {
            append(row)
        }
        let bottom = rows.last.map { Double($0.frame.maxY) } ?? Double(origin.y)
        return Block(rows: rows, frame: CGRect(x: x, y: Double(origin.y), width: width, height: bottom - Double(origin.y)))
    }

    /// Draws a block that is already placed in image coordinates over a copy of `image`: the lines
    /// in `color`, the provider mark (when the block has a mark row) unmodified, aspect-fit.
    public static func burn(_ image: CGImage, block: Block, color: CGColor, mark: CGImage? = nil) throws -> CGImage {
        let w = image.width, h = image.height
        let opaque = [CGImageAlphaInfo.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo)
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: (opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast).rawValue) else {
            throw BurnError.renderFailed
        }
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        draw(block, in: ctx, imageHeight: h, color: color, mark: mark)
        guard let out = ctx.makeImage() else { throw BurnError.renderFailed }
        return out
    }

    /// Draws a placed block into a context whose pixel height is `imageHeight` (CoreGraphics
    /// draws bottom-up; block frames are top-down).
    public static func draw(_ block: Block, in ctx: CGContext, imageHeight: Int, color: CGColor, mark: CGImage?) {
        let h = CGFloat(imageHeight)
        ctx.saveGState()
        defer { ctx.restoreGState() }
        for row in block.rows {
            if let r = row.mark, let mark, mark.width > 0, mark.height > 0 {
                // Unmodified and proportional: fitted inside the reserved rectangle, left aligned.
                let aspect = CGFloat(mark.width) / CGFloat(mark.height)
                var mw = r.width, mh = r.width / aspect
                if mh > r.height { mh = r.height; mw = mh * aspect }
                let top = r.minY + (r.height - mh) / 2
                ctx.interpolationQuality = .high
                ctx.draw(mark, in: CGRect(x: r.minX, y: h - top - mh, width: mw, height: mh))
            }
            for line in row.lines {
                let ct = ctLine(line.text, font: blockFont(line.fontSize), color: color)
                ctx.textMatrix = .identity
                ctx.textPosition = CGPoint(x: line.frame.minX, y: h - CGFloat(line.baseline))
                CTLineDraw(ct, ctx)
            }
        }
    }

    // MARK: - Setting lines

    static func blockFont(_ size: Double) -> CTFont {
        CTFontCreateUIFontForLanguage(.system, CGFloat(size), nil) ?? CTFontCreateWithName("Helvetica" as CFString, CGFloat(size), nil)
    }

    static func textWidth(_ text: String, _ size: Double) -> Double {
        Double(CTLineGetTypographicBounds(ctLine(text, font: blockFont(size), color: nil), nil, nil, nil))
    }

    /// Characters a printed URL may break after.
    static let urlBreaks: Set<Character> = ["/", ".", "-", "?", "&", "=", "_"]

    /// One row of text lines: fits as is, else splits at " · ", else shrinks to the minimum size,
    /// else wraps (words, or URL parts, then characters). Every character is kept.
    static func textRow(_ text: String, kind: Block.Row.Kind, x: Double, y: Double, width: Double, style: BlockStyle,
                        isURL: Bool) -> Block.Row {
        let (strings, size) = fitted(text, width: width, style: style, isURL: isURL)
        let m = metrics(size)
        var lines: [Block.Line] = []
        var top = y
        for s in strings {
            lines.append(Block.Line(text: s, fontSize: size, frame: CGRect(x: x, y: top, width: textWidth(s, size), height: Double(m.lineHeight)),
                                    baseline: top + Double(m.ascent)))
            top += Double(m.lineHeight + m.gap)
        }
        let bottom = lines.last.map { Double($0.frame.maxY) } ?? y
        let right = lines.map { Double($0.frame.maxX) }.max() ?? x
        return Block.Row(kind: kind, lines: lines, mark: nil, frame: CGRect(x: x, y: y, width: right - x, height: bottom - y))
    }

    static func fitted(_ text: String, width: Double, style: BlockStyle, isURL: Bool) -> (lines: [String], size: Double) {
        let size = style.fontSize
        if textWidth(text, size) <= width { return ([text], size) }
        let parts = text.components(separatedBy: " · ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if parts.count > 1, parts.allSatisfy({ textWidth($0, size) <= width }) { return (parts, size) }
        var s = size
        while s > style.minimumFontSize {
            s = max(style.minimumFontSize, s - 0.5)
            if textWidth(text, s) <= width { return ([text], s) }
        }
        let breaks: Set<Character> = isURL ? urlBreaks : [" "]
        return ((parts.count > 1 ? parts : [text]).flatMap { wrap($0, size: s, width: width, breakAfter: breaks) }, s)
    }

    /// Greedy wrap that breaks after `breakAfter` characters, and inside a token only when the
    /// token alone is wider than the line.
    static func wrap(_ text: String, size: Double, width: Double, breakAfter: Set<Character>) -> [String] {
        var tokens: [String] = []
        var token = ""
        for ch in text {
            token.append(ch)
            if breakAfter.contains(ch) { tokens.append(token); token = "" }
        }
        if !token.isEmpty { tokens.append(token) }
        func fits(_ s: String) -> Bool { textWidth(s.trimmingCharacters(in: .whitespaces), size) <= width }
        var lines: [String] = []
        var line = ""
        for t in tokens {
            if fits(line + t) { line += t; continue }
            if !line.isEmpty { lines.append(line); line = "" }
            if fits(t) { line = t; continue }
            for ch in t {
                if line.isEmpty || fits(line + String(ch)) {
                    line.append(ch)
                } else {
                    lines.append(line)
                    line = String(ch)
                }
            }
        }
        if !line.isEmpty { lines.append(line) }
        return lines.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    /// The weather provider's row: the mark, and the printed legal URL beside it when it fits
    /// there, else on its own lines below the mark.
    static func providerRow(url: String?, markAspect: Double?, x: Double, y: Double, width: Double, style: BlockStyle) -> Block.Row? {
        guard markAspect != nil || url != nil else { return nil }
        guard let aspect = markAspect else {
            return url.map { textRow($0, kind: .provider, x: x, y: y, width: width, style: style, isURL: true) }
        }
        let markWidth = min(width, style.markHeight * aspect)
        let markHeight = markWidth / aspect
        let m = metrics(style.fontSize)
        let urlX = x + markWidth + style.markGap
        if let url, textWidth(url, style.fontSize) <= x + width - urlX {
            let rowHeight = max(markHeight, Double(m.lineHeight))
            let mark = CGRect(x: x, y: y + (rowHeight - markHeight) / 2, width: markWidth, height: markHeight)
            let top = y + (rowHeight - Double(m.lineHeight)) / 2
            let line = Block.Line(text: url, fontSize: style.fontSize,
                                  frame: CGRect(x: urlX, y: top, width: textWidth(url, style.fontSize), height: Double(m.lineHeight)),
                                  baseline: top + Double(m.ascent))
            return Block.Row(kind: .provider, lines: [line], mark: mark,
                             frame: CGRect(x: x, y: y, width: Double(line.frame.maxX) - x, height: rowHeight))
        }
        let mark = CGRect(x: x, y: y, width: markWidth, height: markHeight)
        guard let url else {
            return Block.Row(kind: .provider, lines: [], mark: mark, frame: mark)
        }
        let below = textRow(url, kind: .provider, x: x, y: y + markHeight + style.rowGap, width: width, style: style, isURL: true)
        return Block.Row(kind: .provider, lines: below.lines, mark: mark, frame: mark.union(below.frame))
    }
}
#endif
