import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers
import WorldGeo
import WorldMap

/// Top-down 2D debug render of an area's parsed features (PNG).
enum DataMap {
    struct RGB { var r, g, b: CGFloat; var a: CGFloat = 1 }
    static func c(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
    }

    static let land = c(0xF3EFE6)
    static let areaColors: [AreaFeature.Kind: CGColor] = [
        .residential: c(0xECE6DA), .commercial: c(0xEADFD6), .recreation: c(0xD9EBCB),
        .park: c(0xCDE8B5), .garden: c(0xBFE3A6), .grass: c(0xBFE3A6), .meadow: c(0xC9E6A8),
        .wood: c(0x9CCB86), .scrub: c(0xB5D69A), .cemetery: c(0xC4DDB8),
        .pitch: c(0xA9D9A0), .playground: c(0xE9D7A8), .parking: c(0xD8D6D2), .pedestrianArea: c(0xE2DCD4),
        .sand: c(0xF0E2B6), .wetland: c(0xB9DCCF), .water: c(0x8CC4E8), .pool: c(0x8CC4E8), .pier: c(0xC8B8A2),
    ]
    static let areaOrder: [AreaFeature.Kind] = [
        .residential, .commercial, .recreation, .park, .cemetery, .meadow, .grass, .garden, .scrub, .wood,
        .pitch, .playground, .parking, .pedestrianArea, .sand, .wetland, .water, .pool, .pier,
    ]
    static let roadFill = c(0xFFFFFF)
    static let roadCasing = c(0xA59D92)
    static let pathColor = c(0xB07A4F)
    static let sidewalkColor = c(0x7E6BB0)
    static let tagged = c(0xE0662F)
    static let untagged = c(0x98A2AE)
    static let buildingStroke = c(0x4A4F57, 0.8)
    static let tree = c(0x3F8F3A, 0.85)
    static let bench = c(0x7A4A1E)
    static let lamp = c(0xF2C200)
    static let ink = c(0x2B2B2B)

    static func render(areaDir: URL, to out: URL, pixelsPerMeter s: Double) throws {
        let manifest = try AreaLoader.loadManifest(areaDir)
        let f = try AreaLoader.loadFeatures(areaDir)
        let margin = 24.0
        let legendH = 190.0
        let mapW = f.bounds.width * s, mapH = f.bounds.height * s
        let W = Int(mapW + margin * 2), H = Int(mapH + margin * 2 + legendH)

        guard let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        ctx.setFillColor(c(0xFFFFFF)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

        // CoreGraphics is y-up, like local north.
        let ox = margin - f.bounds.min.x * s, oy = margin + legendH - f.bounds.min.y * s
        func pt(_ p: LocalPoint) -> CGPoint { CGPoint(x: ox + p.x * s, y: oy + p.y * s) }
        func ringPath(_ r: Ring, _ path: CGMutablePath) { path.addLines(between: r.map(pt)); path.closeSubpath() }
        func polyPath(_ p: Polygon2D) -> CGPath {
            let path = CGMutablePath()
            ringPath(p.outer, path)
            p.holes.forEach { ringPath($0, path) }
            return path
        }
        func stroke(_ line: [LocalPoint], width: Double, color: CGColor, dash: [CGFloat] = []) {
            let path = CGMutablePath(); path.addLines(between: line.map(pt))
            ctx.addPath(path); ctx.setStrokeColor(color); ctx.setLineWidth(width)
            ctx.setLineCap(.round); ctx.setLineJoin(.round); ctx.setLineDash(phase: 0, lengths: dash)
            ctx.strokePath(); ctx.setLineDash(phase: 0, lengths: [])
        }
        func dot(_ p: LocalPoint, r: Double, fill: CGColor, stroke: CGColor? = nil, square: Bool = false) {
            let rect = CGRect(x: pt(p).x - r, y: pt(p).y - r, width: r * 2, height: r * 2)
            ctx.setFillColor(fill)
            square ? ctx.fill(rect) : ctx.fillEllipse(in: rect)
            if let stroke { ctx.setStrokeColor(stroke); ctx.setLineWidth(1); square ? ctx.stroke(rect) : ctx.strokeEllipse(in: rect) }
        }

        // Map frame + land.
        let mapRect = CGRect(x: margin, y: margin + legendH, width: mapW, height: mapH)
        ctx.saveGState()
        ctx.clip(to: mapRect)
        ctx.setFillColor(land); ctx.fill(mapRect)

        for kind in areaOrder {
            for a in f.areas(of: kind) {
                ctx.addPath(polyPath(a.polygon)); ctx.setFillColor(areaColors[kind]!); ctx.fillPath(using: .evenOdd)
            }
        }
        for l in f.lines {
            switch l.kind {
            case .stream: stroke(l.line, width: 2, color: areaColors[.water]!)
            case .hedge, .treeRow: stroke(l.line, width: 1.5, color: tree)
            default: stroke(l.line, width: 0.8, color: c(0x6B6B6B), dash: [3, 2])
            }
        }
        // Roads: casing then fill, widest first.
        let roads = f.roads.sorted { $0.width > $1.width }
        for r in roads { stroke(r.centerline, width: r.width * s + 1.5, color: roadCasing) }
        for r in roads { stroke(r.centerline, width: r.width * s, color: roadFill) }
        for p in f.paths { stroke(p.centerline, width: max(1.2, p.width * s * 0.6), color: pathColor, dash: p.isCrossing ? [2, 2] : []) }
        for p in f.sidewalks { stroke(p.centerline, width: max(1.2, p.width * s * 0.6), color: sidewalkColor) }

        for b in f.buildings where !b.isPart {
            ctx.addPath(polyPath(b.footprint))
            ctx.setFillColor(b.hasHeightTag || b.hasLevelsTag ? tagged : untagged)
            ctx.setStrokeColor(buildingStroke); ctx.setLineWidth(0.6)
            ctx.drawPath(using: .eoFillStroke)
        }
        for t in f.points(of: .tree) { dot(t.position, r: max(1.5, 1.6 * s), fill: tree) }
        for b in f.points(of: .bench) { dot(b.position, r: 2.5, fill: bench, square: true) }
        for l in f.points(of: .streetLamp) { dot(l.position, r: 3, fill: lamp, stroke: ink) }
        ctx.restoreGState()
        ctx.setStrokeColor(ink); ctx.setLineWidth(1); ctx.stroke(mapRect)

        // Scale bar (100 m) and north arrow, bottom-left inside the map.
        let sbX = margin + 16, sbY = margin + legendH + 16
        ctx.setFillColor(c(0xFFFFFF, 0.85)); ctx.fill(CGRect(x: sbX - 8, y: sbY - 8, width: 100 * s + 70, height: 34))
        ctx.setFillColor(ink); ctx.fill(CGRect(x: sbX, y: sbY, width: 100 * s, height: 4))
        text("100 m", at: CGPoint(x: sbX + 100 * s + 8, y: sbY - 2), size: 13, ctx: ctx)
        text("N ↑", at: CGPoint(x: margin + mapW - 44, y: margin + legendH + mapH - 26), size: 16, bold: true, ctx: ctx)

        // Legend.
        let b = f.buildings.filter { !$0.isPart }
        let nTagged = b.filter { $0.hasHeightTag || $0.hasLevelsTag }.count
        var y = margin + legendH - 30
        text("\(manifest.name): parsed OSM features (\(Int(f.bounds.width)) × \(Int(f.bounds.height)) m)", at: CGPoint(x: margin, y: y), size: 18, bold: true, ctx: ctx)
        y -= 22
        text("OSM data \(manifest.sources.first?.dataTimestamp ?? "?") · © OpenStreetMap contributors (ODbL)", at: CGPoint(x: margin, y: y), size: 12, ctx: ctx)
        let entries: [(String, CGColor, String)] = [
            ("Building with height or levels tag (\(nTagged))", tagged, "fill"),
            ("Building without (\(b.count - nTagged))", untagged, "fill"),
            ("Road (\(f.roads.count) ways)", roadCasing, "line"),
            ("Path / footway / cycleway (\(f.paths.count))", pathColor, "line"),
            ("Mapped sidewalk (\(f.sidewalks.count))", sidewalkColor, "line"),
            ("Water", areaColors[.water]!, "fill"),
            ("Park / grass / pitch", areaColors[.park]!, "fill"),
            ("Tree (\(f.points(of: .tree).count))", tree, "dot"),
            ("Bench (\(f.points(of: .bench).count))", bench, "square"),
            ("Street lamp (\(f.points(of: .streetLamp).count))", lamp, "dot"),
        ]
        let colW = (Double(W) - margin * 2) / 3
        for (i, e) in entries.enumerated() {
            let ex = margin + Double(i % 3) * colW
            let ey = y - 34 - Double(i / 3) * 26
            let sw = CGRect(x: ex, y: ey, width: 22, height: 14)
            ctx.setFillColor(e.1)
            switch e.2 {
            case "line": ctx.fill(CGRect(x: ex, y: ey + 5, width: 22, height: 4))
            case "dot": ctx.fillEllipse(in: CGRect(x: ex + 5, y: ey + 1, width: 12, height: 12))
            case "square": ctx.fill(CGRect(x: ex + 6, y: ey + 2, width: 10, height: 10))
            default: ctx.fill(sw); ctx.setStrokeColor(buildingStroke); ctx.stroke(sw)
            }
            text(e.0, at: CGPoint(x: ex + 30, y: ey + 1), size: 13, ctx: ctx)
        }

        let image = ctx.makeImage()!
        let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw ToolError.usage("could not write \(out.path)") }
    }

    static func text(_ s: String, at p: CGPoint, size: CGFloat, bold: Bool = false, ctx: CGContext) {
        let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
        let attrs: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        ctx.textPosition = p
        CTLineDraw(line, ctx)
    }
}
