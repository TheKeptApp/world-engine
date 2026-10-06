import Foundation
import WorldMap

/// One credit or licence notice: a data source, the ODbL data offer, a code notice or a
/// host-supplied provider credit. Renderer-neutral (decisions 6a–6f, `docs/data-licensing.md`).
///
/// The static engine credits live in `Profiles/credits.json`; `CreditsCatalog.merged(...)` adds
/// the area's manifest sources and the host's weather attribution.
public struct Credit: Codable, Sendable, Equatable, Identifiable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        /// OpenStreetMap: the map data every world is built from.
        case mapData
        /// A manifest source other than the built-in OSM credit (e.g. Overture buildings).
        case sourceData
        /// The ODbL §4.6 offer of the world data.
        case dataOffer
        case skyData
        case imagery
        case weather
        /// Live vehicle positions from a transit or aircraft feed, supplied by the host from the
        /// relay response's `attribution[]` (data contract, `docs/research/live-feeds.md` §8.8).
        case liveData
        case code
    }

    /// When an entry applies.
    public enum Condition: String, Codable, Sendable {
        case always
        /// Only when NAIP-derived values are used (`merged(naipDerivedValues: true)`).
        case naipDerivedValues
        /// Only when the host supplies it at runtime (the weather provider's attribution).
        case hostSupplied
    }

    /// Where an entry applies.
    public enum Surface: String, Codable, Sendable, CaseIterable {
        /// An app's credits / about screen.
        case app
        /// The web renderer.
        case web
        /// The world package's licence notice and `world.json` credits.
        case package
        /// Exported images (postcards, snapshots, video frames, widgets).
        case image
    }

    public var id: String
    public var kind: Kind
    public var title: String
    /// The credit line as shown.
    public var text: String
    public var detail: String?
    /// Link target for the credit (e.g. openstreetmap.org/copyright, a provider's legal page).
    public var url: String?
    /// Printable form of `url` for media that cannot carry a link.
    public var displayURL: String?
    /// SPDX-style licence identifier (keys of `CreditsCatalog.licenses`).
    public var license: String?
    public var licenseURL: String?
    /// Full licence text where the licence requires it to travel with copies (code notices).
    public var licenseText: String?
    public var condition: Condition
    public var surfaces: [Surface]
    /// True when this credit must be drawn onto every exported image it applies to.
    public var burnIn: Bool
    /// The exact line to burn into images (default: `text`).
    public var burnInText: String?
    /// Provider marks (light and dark appearance), e.g. the Apple Weather mark.
    public var markLightURL: String?
    public var markDarkURL: String?
    /// Content still pending; must be filled before any public release.
    public var placeholder: Bool?
    /// Manifest source formats that this credit covers.
    public var sources: [String]?
    public var note: String?

    public init(id: String, kind: Kind, title: String, text: String, detail: String? = nil, url: String? = nil,
                displayURL: String? = nil, license: String? = nil, licenseURL: String? = nil, licenseText: String? = nil,
                condition: Condition = .always, surfaces: [Surface] = Surface.allCases, burnIn: Bool = false,
                burnInText: String? = nil, markLightURL: String? = nil, markDarkURL: String? = nil,
                placeholder: Bool? = nil, sources: [String]? = nil, note: String? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.text = text
        self.detail = detail
        self.url = url
        self.displayURL = displayURL
        self.license = license
        self.licenseURL = licenseURL
        self.licenseText = licenseText
        self.condition = condition
        self.surfaces = surfaces
        self.burnIn = burnIn
        self.burnInText = burnInText
        self.markLightURL = markLightURL
        self.markDarkURL = markDarkURL
        self.placeholder = placeholder
        self.sources = sources
        self.note = note
    }

    public var isPlaceholder: Bool { placeholder ?? false }
    public var link: URL? { url.flatMap(URL.init(string:)) }
    public var licenseLink: URL? { licenseURL.flatMap(URL.init(string:)) }
    /// The line `CreditBurnIn` draws for this credit.
    public var burnInLine: String { burnInText ?? text }
}

/// The host's weather-provider attribution, renderer-neutral (WorldEngine converts
/// `WeatherAttributionInfo` into this). For Apple Weather: `serviceName`, the legal attribution
/// page, the combined mark URLs and the "modified from" notice for value-added visuals.
public struct WeatherCredit: Codable, Sendable, Equatable {
    public var serviceName: String
    public var legalPageURL: String?
    public var markLightURL: String?
    public var markDarkURL: String?
    /// "Weather visualization modified from <provider> data."
    public var modifiedNotice: String?

    public init(serviceName: String, legalPageURL: String? = nil, markLightURL: String? = nil, markDarkURL: String? = nil,
                modifiedNotice: String? = nil) {
        self.serviceName = serviceName
        self.legalPageURL = legalPageURL
        self.markLightURL = markLightURL
        self.markDarkURL = markDarkURL
        self.modifiedNotice = modifiedNotice
    }
}

/// One live feed's attribution as the relay sends it (`attribution[]` in the live-feed data contract,
/// `docs/research/live-feeds.md` §8.8). The host passes the entries for feeds whose vehicles are on
/// screen; `text` is shown verbatim and burned into exports.
public struct LiveFeedCredit: Codable, Sendable, Equatable {
    public var source: String
    public var text: String
    public var url: String?
    public var licenseUrl: String?
    /// Optional provider mark images, light and dark (same shape as the weather slot); only where a feed's
    /// terms ask for or allow a logo. RTD's terms do not allow its marks, so the relay sends none.
    public var markLightURL: String?
    public var markDarkURL: String?

    public init(source: String, text: String, url: String? = nil, licenseUrl: String? = nil,
                markLightURL: String? = nil, markDarkURL: String? = nil) {
        self.source = source
        self.text = text
        self.url = url
        self.licenseUrl = licenseUrl
        self.markLightURL = markLightURL
        self.markDarkURL = markDarkURL
    }
}

/// `Profiles/credits.json`: the static engine credits plus the licence table used to resolve
/// licence URLs for manifest sources.
public struct CreditsCatalog: Codable, Sendable, Equatable {
    public struct License: Codable, Sendable, Equatable {
        public var name: String
        public var url: String?
        /// Whether the licence requires credit on works made from the data (drives burn-in for
        /// manifest sources).
        public var attributionRequired: Bool
        public var shareAlike: Bool?
        public var note: String?

        public init(name: String, url: String? = nil, attributionRequired: Bool, shareAlike: Bool? = nil, note: String? = nil) {
            self.name = name
            self.url = url
            self.attributionRequired = attributionRequired
            self.shareAlike = shareAlike
            self.note = note
        }
    }

    public var schema: String
    public var comment: String?
    public var credits: [Credit]
    public var licenses: [String: License]

    public static let resourceName = "credits"
    public static let osmCreditID = "openstreetmap"
    public static let weatherCreditID = "weather-provider"

    public init(schema: String = "worldengine.credits/1", comment: String? = nil, credits: [Credit], licenses: [String: License]) {
        self.schema = schema
        self.comment = comment
        self.credits = credits
        self.licenses = licenses
    }

    /// The catalog bundled with the engine (`Sources/WorldGen/Profiles/credits.json`).
    public static func bundled() throws -> CreditsCatalog {
        try JSONDecoder().decode(CreditsCatalog.self, from: StyleLibrary.data(resourceName))
    }

    /// Entries still pending (e.g. the star catalog credit, the ODbL offer URL). Release gate:
    /// this must be empty before any public release.
    public var placeholders: [Credit] { credits.filter(\.isPlaceholder) }

    public func licenseURL(for license: String?) -> String? {
        license.flatMap { licenses[$0]?.url }
    }

    /// The full credit list for one area.
    ///
    /// - Static engine credits keep their file order; entries whose `condition` is not met are dropped.
    /// - Every manifest source contributes its licence and attribution. Sources with the same
    ///   attribution and licence collapse into one credit; a source matching a static credit's text
    ///   and licence (OSM tiles vs the built-in OSM credit) only adds its format to that credit's
    ///   `sources`. New source credits follow the map-data credits.
    /// - The host-supplied weather entry is filled from `weather`, or dropped when it is nil.
    /// - Each live feed in `liveFeeds` (one per `source`, first wins) adds a `liveData` credit after the
    ///   map-data credits: app, web and image surfaces (never the package), burned into exports.
    /// - `surface` keeps only entries that apply there (nil keeps all).
    /// - Licence URLs missing from an entry are resolved from `licenses`.
    public func merged(sources: [AreaManifest.Source] = [], weather: WeatherCredit? = nil, naipDerivedValues: Bool = false,
                       liveFeeds: [LiveFeedCredit] = [], surface: Credit.Surface? = nil) -> [Credit] {
        var list: [Credit] = []
        for var c in credits {
            switch c.condition {
            case .always: break
            case .naipDerivedValues: guard naipDerivedValues else { continue }
            case .hostSupplied:
                guard c.kind == .weather, let weather else { continue }
                c = filled(c, with: weather)
            }
            if c.licenseURL == nil { c.licenseURL = licenseURL(for: c.license) }
            list.append(c)
        }

        var added: [Credit] = []
        for s in sources {
            let key = Self.normalized(s.attribution)
            if let i = list.firstIndex(where: { Self.normalized($0.text) == key && $0.license == s.license }) {
                list[i].sources = Self.appending(s.format, to: list[i].sources)
            } else if let i = added.firstIndex(where: { Self.normalized($0.text) == key && $0.license == s.license }) {
                added[i].sources = Self.appending(s.format, to: added[i].sources)
            } else {
                var id = "source-\(s.format)"
                var n = 2
                while list.contains(where: { $0.id == id }) || added.contains(where: { $0.id == id }) { id = "source-\(s.format)-\(n)"; n += 1 }
                let info = licenses[s.license]
                added.append(Credit(
                    id: id, kind: .sourceData, title: s.attribution, text: s.attribution,
                    detail: "Licence: \(info?.name ?? s.license). Source format \(s.format), layers \(s.layers.joined(separator: ", ")).",
                    license: s.license, licenseURL: info?.url, condition: .always, surfaces: Credit.Surface.allCases,
                    // Unknown licences are credited on images too, to be safe.
                    burnIn: info?.attributionRequired ?? true, sources: [s.format]))
            }
        }
        var seenFeeds = Set<String>()
        for f in liveFeeds where seenFeeds.insert(f.source).inserted {
            added.append(Credit(
                id: "live-\(f.source)", kind: .liveData, title: "Live data (\(f.source))", text: f.text,
                url: f.url, licenseURL: f.licenseUrl, condition: .always, surfaces: [.app, .web, .image],
                burnIn: true, markLightURL: f.markLightURL, markDarkURL: f.markDarkURL))
        }
        let insertAt = (list.lastIndex(where: { $0.kind == .mapData }).map { $0 + 1 }) ?? 0
        list.insert(contentsOf: added, at: insertAt)

        if let surface { list = list.filter { $0.surfaces.contains(surface) } }
        return list
    }

    /// The weather entry with the host's attribution: the provider name, its legal page, marks and
    /// the modified-data notice (also the burned-in line).
    func filled(_ c: Credit, with w: WeatherCredit) -> Credit {
        var c = c
        c.text = w.serviceName
        c.detail = w.modifiedNotice
        c.url = w.legalPageURL
        c.displayURL = nil
        c.markLightURL = w.markLightURL
        c.markDarkURL = w.markDarkURL
        let notice = w.modifiedNotice?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        c.burnInText = notice.isEmpty ? w.serviceName : notice
        c.note = nil
        return c
    }

    static func normalized(_ s: String) -> String {
        s.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    static func appending(_ format: String, to list: [String]?) -> [String] {
        var l = list ?? []
        if !l.contains(format) { l.append(format) }
        return l
    }
}
