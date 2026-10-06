import CoreGraphics
import Foundation
import WorldEnvironment
import WorldGen
import WorldMap

/// One credit or licence notice (renderer-neutral, from WorldGen), re-exported for host apps.
public typealias WorldCredit = WorldGen.Credit
/// The host's weather-provider attribution in credit form.
public typealias WorldWeatherCredit = WorldGen.WeatherCredit
/// One live feed's attribution as the relay sends it (live-feed data contract §8.8).
public typealias WorldLiveFeedCredit = WorldGen.LiveFeedCredit
/// Burns the required credits into exported images. Every exported image must pass through it.
public typealias WorldCreditBurnIn = WorldGen.CreditBurnIn

extension WeatherCredit {
    /// The weather provider's attribution (e.g. Apple Weather: mark URLs, legal page, modified notice).
    public init(_ info: WeatherAttributionInfo) {
        self.init(serviceName: info.serviceName, legalPageURL: info.legalPageURL, markLightURL: info.markLightURL,
                  markDarkURL: info.markDarkURL, modifiedNotice: info.modifiedNotice)
    }
}

/// The standard credits (decision 6b): the engine's static credits (`credits.json`: OpenStreetMap,
/// the ODbL data offer, the star catalog, code notices, NAIP) merged with the world's
/// manifest sources and the host's weather attribution.
///
/// Host apps must show these credits: put `WorldCreditsView` on the app's credits/about screen,
/// or `WorldCreditsButton` next to the world. Both complement, never replace, the always-visible
/// `WorldAttributionView`.
public enum WorldCredits {
    /// Credits for one surface. `sources` are the area's manifest sources (`world.manifest.sources`).
    /// If the bundled catalog cannot be read, the OpenStreetMap credit is still returned.
    public static func list(sources: [AreaManifest.Source] = [], weather: WeatherAttributionInfo? = nil,
                            naipDerivedValues: Bool = false, liveFeeds: [WorldLiveFeedCredit] = [],
                            surface: WorldCredit.Surface = .app) -> [WorldCredit] {
        guard let catalog = try? CreditsCatalog.bundled() else { return [fallbackOSM] }
        return catalog.merged(sources: sources, weather: weather.map(WeatherCredit.init), naipDerivedValues: naipDerivedValues,
                              liveFeeds: liveFeeds, surface: surface)
    }

    /// Credits for a loaded world (its manifest sources) on one surface.
    @MainActor
    public static func list(for world: World, weather: WeatherAttributionInfo? = nil, naipDerivedValues: Bool = false,
                            liveFeeds: [WorldLiveFeedCredit] = [], surface: WorldCredit.Surface = .app) -> [WorldCredit] {
        list(sources: world.manifest.sources, weather: weather, naipDerivedValues: naipDerivedValues, liveFeeds: liveFeeds,
             surface: surface)
    }

    /// Burns "© OpenStreetMap contributors · openstreetmap.org/copyright" plus every other required
    /// credit for these sources (and the weather notice when `weather` is given) into an exported
    /// image. Every exported image (postcards, snapshots, share images, widget images, video
    /// frames) must pass through this or `WorldCreditBurnIn`; throws rather than return an
    /// uncredited image.
    public static func burnIn(_ image: CGImage, sources: [AreaManifest.Source] = [], weather: WeatherAttributionInfo? = nil,
                              naipDerivedValues: Bool = false, liveFeeds: [WorldLiveFeedCredit] = [],
                              corner: WorldCreditBurnIn.Corner = .bottomTrailing) throws -> CGImage {
        let credits = list(sources: sources, weather: weather, naipDerivedValues: naipDerivedValues, liveFeeds: liveFeeds,
                           surface: .image)
        return try CreditBurnIn.burn(image, credits: credits, style: .init(corner: corner))
    }

    /// The OpenStreetMap credit as `WorldAttributionView` shows it (used only if `credits.json` is unreadable).
    static let fallbackOSM = WorldCredit(
        id: CreditsCatalog.osmCreditID, kind: .mapData, title: "OpenStreetMap", text: "© OpenStreetMap contributors",
        detail: "Map data available under the Open Database License (ODbL 1.0).", url: "https://www.openstreetmap.org/copyright",
        displayURL: "openstreetmap.org/copyright", license: "ODbL-1.0", licenseURL: "https://opendatacommons.org/licenses/odbl/1-0/",
        burnIn: true, burnInText: CreditBurnIn.osmLine)
}
