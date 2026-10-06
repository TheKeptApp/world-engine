import CoreGraphics
import Foundation
import Testing
@testable import WorldGen
@testable import WorldGeo
@testable import WorldMap

@Suite("Credits catalog and merge (decisions 6a-6c)")
struct CreditsTests {
    static let box = GeoBoundingBox(south: 0, west: 0, north: 0.01, east: 0.01)

    static func source(_ format: String, _ license: String, _ attribution: String, path: String = "x.json") -> AreaManifest.Source {
        .init(format: format, path: path, layers: ["all"], bounds: box, dataTimestamp: nil, fetchedAt: nil, bytes: nil, sha256: nil,
              license: license, attribution: attribution)
    }

    @Test func bundledCatalogHasTheRequiredEntries() throws {
        let c = try CreditsCatalog.bundled()
        let byID = Dictionary(uniqueKeysWithValues: c.credits.map { ($0.id, $0) })
        let osm = try #require(byID["openstreetmap"])
        #expect(osm.text == "© OpenStreetMap contributors")
        #expect(osm.url == "https://www.openstreetmap.org/copyright")
        #expect(osm.detail?.contains("Open Database License") == true)
        #expect(osm.burnIn && osm.burnInLine == CreditBurnIn.osmLine)
        #expect(Set(osm.surfaces) == Set(Credit.Surface.allCases))
        #expect(c.licenseURL(for: "ODbL-1.0") == "https://opendatacommons.org/licenses/odbl/1-0/")

        let star = try #require(byID["star-catalog"])
        #expect(!star.isPlaceholder && star.text.contains("Yale Bright Star Catalogue") && star.license == "public-domain")
        #expect(byID["odbl-offer"]?.kind == .dataOffer)
        #expect(byID["earcut"]?.license == "ISC" && byID["earcut"]?.licenseText?.contains("Copyright (c) 2016, Mapbox") == true)
        #expect(byID["threejs"]?.license == "MIT" && byID["threejs"]?.surfaces == [.web])
        #expect(byID["naip"]?.text == "NAIP imagery provided by USDA Farm Service Agency")
        #expect(byID["naip"]?.condition == .always) // NAIP canopy shares ship in profiles
        #expect(byID["weather-provider"]?.condition == .hostSupplied)
        // Every licence referenced by a static credit is in the table.
        for credit in c.credits { if let l = credit.license, !l.hasPrefix("STAR_") { #expect(c.licenses[l] != nil, "\(l)") } }
        #expect(Set(c.credits.map(\.id)).count == c.credits.count)
    }

    @Test func mergeListsEverySourceOnceAndKeepsConditions() throws {
        let c = try CreditsCatalog.bundled()
        let sources = [
            Self.source("osm-overpass-json", "ODbL-1.0", "© OpenStreetMap contributors", path: "osm.json"),
            Self.source("osm-overpass-json", "ODbL-1.0", "©  OpenStreetMap   contributors", path: "osm-buildings.json"),
            Self.source("overture-buildings-v1", "ODbL-1.0", "© OpenStreetMap contributors, Overture Maps Foundation"),
            Self.source("overture-buildings-v1", "ODbL-1.0", "© OpenStreetMap contributors, Overture Maps Foundation", path: "y.json"),
            Self.source("esri-extras", "CC-BY-4.0", "Esri Community Maps contributors"),
            Self.source("mystery", "Custom-1", "Someone"),
        ]
        let app = c.merged(sources: sources, surface: .app)
        let ids = app.map(\.id)
        // OSM tiles collapse into the built-in OSM credit.
        #expect(app.filter { $0.text.contains("OpenStreetMap contributors") && $0.kind == .mapData }.count == 1)
        #expect(app.first { $0.id == "openstreetmap" }?.sources == ["osm-overpass-json"])
        // Every other distinct (licence, attribution) appears exactly once, right after the map data.
        let overture = try #require(app.first { $0.text == "© OpenStreetMap contributors, Overture Maps Foundation" })
        #expect(app.filter { $0.text == overture.text }.count == 1)
        #expect(overture.license == "ODbL-1.0" && overture.licenseURL == "https://opendatacommons.org/licenses/odbl/1-0/")
        #expect(overture.burnIn && overture.sources == ["overture-buildings-v1"])
        let esri = try #require(app.first { $0.text == "Esri Community Maps contributors" })
        #expect(esri.licenseURL == "https://creativecommons.org/licenses/by/4.0/" && esri.burnIn)
        let mystery = try #require(app.first { $0.text == "Someone" })
        #expect(mystery.licenseURL == nil && mystery.burnIn)
        #expect(ids.firstIndex(of: "openstreetmap")! < ids.firstIndex(of: overture.id)!)
        #expect(ids.firstIndex(of: mystery.id)! < ids.firstIndex(of: "odbl-offer")!)
        // Conditions and surfaces.
        #expect(!ids.contains("weather-provider"))
        #expect(ids.contains("naip"))
        #expect(!ids.contains("threejs") && ids.contains("earcut"))
        #expect(c.merged(sources: sources, naipDerivedValues: true, surface: .app).contains { $0.id == "naip" })
        let web = c.merged(sources: sources, surface: .web).map(\.id)
        #expect(web.contains("threejs") && !web.contains("earcut"))
        let package = c.merged(sources: sources, surface: .package).map(\.id)
        #expect(package.contains("openstreetmap") && package.contains(overture.id) && !package.contains("star-catalog"))
        // Deterministic.
        #expect(c.merged(sources: sources, surface: .app) == app)
    }

    @Test func mergeFillsTheWeatherProviderEntry() throws {
        let c = try CreditsCatalog.bundled()
        let w = WeatherCredit(serviceName: "Apple Weather", legalPageURL: "https://example.invalid/legal",
                              markLightURL: "https://example.invalid/light.png", markDarkURL: "https://example.invalid/dark.png",
                              modifiedNotice: "Weather visualization modified from Apple Weather data.")
        let list = c.merged(weather: w, surface: .app)
        let weather = try #require(list.first { $0.kind == .weather })
        #expect(weather.text == "Apple Weather" && weather.url == "https://example.invalid/legal")
        #expect(weather.markLightURL == w.markLightURL && weather.markDarkURL == w.markDarkURL)
        #expect(weather.detail == w.modifiedNotice && weather.burnInLine == w.modifiedNotice)
        #expect(CreditBurnIn.lines(for: c.merged(weather: w, surface: .image)) == [CreditBurnIn.osmLine, w.modifiedNotice!])
    }

    /// Live-feed attribution from the relay (data contract §8.8): one credit per source, shown in the
    /// app and on the web, burned into exports, never in the package.
    @Test func mergeAddsLiveFeedCredits() throws {
        let c = try CreditsCatalog.bundled()
        let rtd = LiveFeedCredit(source: "rtd", text: "Live vehicle positions: RTD, Denver. Unofficial: not endorsed by RTD.",
                                 url: "https://example.invalid/feeds", licenseUrl: "https://example.invalid/licence")
        let app = c.merged(liveFeeds: [rtd, rtd], surface: .app)
        let live = app.filter { $0.kind == .liveData }
        #expect(live.count == 1 && live[0].id == "live-rtd" && live[0].text == rtd.text && live[0].burnIn)
        #expect(live[0].url == rtd.url && live[0].licenseURL == rtd.licenseUrl)
        let marked = LiveFeedCredit(source: "x", text: "X feed", markLightURL: "https://example.invalid/l.png", markDarkURL: "https://example.invalid/d.png")
        let m = try #require(c.merged(liveFeeds: [marked], surface: .app).first { $0.id == "live-x" })
        #expect(m.markLightURL == marked.markLightURL && m.markDarkURL == marked.markDarkURL)
        let ids = app.map(\.id)
        #expect(ids.firstIndex(of: "openstreetmap")! < ids.firstIndex(of: "live-rtd")!)
        #expect(!c.merged(liveFeeds: [rtd], surface: .package).contains { $0.kind == .liveData })
        #expect(CreditBurnIn.lines(for: c.merged(liveFeeds: [rtd], surface: .image)) == [CreditBurnIn.osmLine, rtd.text])
        #expect(!c.merged(surface: .app).contains { $0.kind == .liveData })
        // Illustrative, not-live entries (ambient planes) never become "Live data".
        let ambient = LiveFeedCredit(source: "ambient", text: "Illustrative air traffic, not live.", live: false)
        let amb = try #require(c.merged(liveFeeds: [ambient], surface: .app).first { $0.id == "illustrative-ambient" })
        #expect(amb.kind == .illustrative && !amb.title.contains("Live"))
        // The relay's JSON attribution entry decodes directly.
        let json = #"{"source":"rtd","text":"t","url":"https://example.invalid","licenseUrl":"https://example.invalid/l"}"#
        #expect(try JSONDecoder().decode(LiveFeedCredit.self, from: Data(json.utf8)).licenseUrl == "https://example.invalid/l")
    }

    @Test func burnInLinesAlwaysStartWithOSM() throws {
        #expect(CreditBurnIn.lines(for: []) == [CreditBurnIn.osmLine])
        let c = try CreditsCatalog.bundled()
        let lines = CreditBurnIn.lines(for: c.merged(sources: [
            Self.source("osm-overpass-json", "ODbL-1.0", "© OpenStreetMap contributors"),
            Self.source("overture-buildings-v1", "ODbL-1.0", "© OpenStreetMap contributors, Overture Maps Foundation"),
            Self.source("cc0", "CC0-1.0", "Public domain things"),
        ], surface: .image))
        #expect(lines == [CreditBurnIn.osmLine, "© OpenStreetMap contributors, Overture Maps Foundation"])
        #expect(!lines.contains { $0.contains("PENDING") })
        // The OSM line is added even when a caller passes other lines only.
        #expect(CreditBurnIn.layout(width: 1200, height: 800, lines: ["Other credit"]).lines == [CreditBurnIn.osmLine, "Other credit"])
    }
}

@Suite("Credit burn-in (decision 6c)")
struct CreditBurnInTests {
    /// A flat mid-grey RGBA image.
    static func image(_ w: Int, _ h: Int, gray: UInt8 = 128) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let g = CGFloat(gray) / 255
        ctx.setFillColor(CGColor(srgbRed: g, green: g, blue: g, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
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

    struct Stats { var changedInPlate = 0, changedOutside = 0, darkInPlate = 0 }

    static func stats(_ before: CGImage, _ after: CGImage, plate: CGRect) -> Stats {
        let a = pixels(before), b = pixels(after), w = before.width
        var s = Stats()
        for y in 0..<before.height {
            for x in 0..<w {
                let i = (y * w + x) * 4
                let changed = a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]
                let inside = plate.contains(CGPoint(x: Double(x) + 0.5, y: Double(y) + 0.5))
                if inside {
                    if changed { s.changedInPlate += 1 }
                    // Text: clearly darker than the plate over this background (≈ 236 over mid-grey).
                    if b[i] < 170 { s.darkInPlate += 1 }
                } else if changed {
                    s.changedOutside += 1
                }
            }
        }
        return s
    }

    @Test func burnsALegibleCreditIntoTheCorner() throws {
        let img = Self.image(1600, 900)
        let lines = [CreditBurnIn.osmLine, "© OpenStreetMap contributors, Overture Maps Foundation"]
        let layout = CreditBurnIn.layout(width: 1600, height: 900, lines: lines)
        #expect(layout.lines == lines)
        #expect(layout.fontSize >= 0.022 * 900 - 1e-9 && layout.fontSize >= 11)
        // Bottom-right corner, inside the image.
        #expect(layout.plate.maxX <= 1600 && layout.plate.maxY <= 900)
        #expect(layout.plate.minX > 800 && layout.plate.minY > 450)
        let out = try CreditBurnIn.burn(img, lines: lines)
        #expect(out.width == 1600 && out.height == 900)
        let s = Self.stats(img, out, plate: layout.plate)
        #expect(s.changedOutside == 0)
        #expect(Double(s.changedInPlate) > 0.9 * Double(layout.plate.width * layout.plate.height))
        #expect(s.darkInPlate > 200, "text pixels: \(s.darkInPlate)")
    }

    @Test(arguments: CreditBurnIn.Corner.allCases)
    func everyCornerStaysInside(_ corner: CreditBurnIn.Corner) throws {
        let img = Self.image(640, 480)
        let style = CreditBurnIn.Style(corner: corner)
        let layout = CreditBurnIn.layout(width: 640, height: 480, lines: [], style: style)
        #expect(CGRect(x: 0, y: 0, width: 640, height: 480).contains(layout.plate))
        let left = corner == .bottomLeading || corner == .topLeading, top = corner == .topLeading || corner == .topTrailing
        #expect(left ? layout.plate.minX < 320 : layout.plate.maxX > 320)
        #expect(top ? layout.plate.minY < 240 : layout.plate.maxY > 240)
        let s = Self.stats(img, try CreditBurnIn.burn(img, lines: [], style: style), plate: layout.plate)
        #expect(s.changedOutside == 0 && s.darkInPlate > 50)
    }

    @Test(arguments: [(320, 180), (120, 90), (64, 48)])
    func smallImagesStillGetTheCredit(_ size: (Int, Int)) throws {
        let (w, h) = size
        let img = Self.image(w, h)
        let layout = CreditBurnIn.layout(width: w, height: h, lines: [])
        // The credit is never dropped: both parts of the OSM line are present, split if needed.
        #expect(layout.lines.joined(separator: " · ") == CreditBurnIn.osmLine)
        #expect(CGRect(x: 0, y: 0, width: w, height: h).contains(layout.plate))
        #expect(layout.fontSize > 0)
        let s = Self.stats(img, try CreditBurnIn.burn(img, lines: []), plate: layout.plate)
        #expect(s.changedOutside == 0)
        #expect(s.changedInPlate > 0 && s.darkInPlate > 0, "\(w)×\(h): \(s.darkInPlate) text pixels")
    }

    @Test func darkAndBrightImagesKeepContrast() throws {
        for gray: UInt8 in [0, 255] {
            let img = Self.image(800, 600, gray: gray)
            let layout = CreditBurnIn.layout(width: 800, height: 600, lines: [])
            let s = Self.stats(img, try CreditBurnIn.burn(img, lines: []), plate: layout.plate)
            #expect(s.darkInPlate > 100, "background \(gray)")
        }
    }
}
