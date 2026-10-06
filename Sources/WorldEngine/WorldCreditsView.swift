import SwiftUI
import WorldEnvironment
import WorldGen

/// Every credit and licence notice for the world, with links: OpenStreetMap and the ODbL data
/// offer, every manifest source, the star catalog, the weather provider (mark + legal link, when
/// the host supplies its attribution), NAIP when used, and code notices with their licence text.
///
/// Host apps must show this (decision 6b): on their credits/about screen, or through
/// `WorldCreditsButton`. It complements the always-visible `WorldAttributionView`.
public struct WorldCreditsView: View {
    let credits: [WorldCredit]

    public init(credits: [WorldCredit]) {
        self.credits = credits
    }

    /// The standard credits for a world, merged with the host's weather attribution.
    public init(world: World, weather: WeatherAttributionInfo? = nil, naipDerivedValues: Bool = false,
                liveFeeds: [WorldLiveFeedCredit] = []) {
        self.credits = WorldCredits.list(for: world, weather: weather, naipDerivedValues: naipDerivedValues, liveFeeds: liveFeeds)
    }

    public var body: some View {
        List {
            ForEach(Self.sections) { section in
                let items = credits.filter { section.kinds.contains($0.kind) }
                if !items.isEmpty {
                    Section(section.title) {
                        ForEach(items) { WorldCreditRow(credit: $0) }
                    }
                }
            }
        }
    }

    struct CreditSection: Identifiable, Sendable {
        var title: String
        var kinds: Set<WorldCredit.Kind>
        var id: String { title }
    }

    static let sections: [CreditSection] = [
        .init(title: "Map data", kinds: [.mapData, .sourceData, .dataOffer]),
        .init(title: "Weather", kinds: [.weather]),
        .init(title: "Live data", kinds: [.liveData]),
        .init(title: "Sky", kinds: [.skyData]),
        .init(title: "Imagery", kinds: [.imagery]),
        .init(title: "Open-source software", kinds: [.code]),
    ]
}

/// One credit: title, credit line, detail, provider mark, links and (for code) the licence text.
struct WorldCreditRow: View {
    let credit: WorldCredit
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let mark = (colorScheme == .dark ? credit.markDarkURL : credit.markLightURL) ?? credit.markLightURL,
               let url = URL(string: mark) {
                // The provider's own mark (e.g. Apple Weather), never redrawn.
                AsyncImage(url: url) { $0.resizable().scaledToFit() } placeholder: { Text(credit.text) }
                    .frame(height: 18)
                    .accessibilityLabel(credit.text)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(credit.title).font(.headline)
                if credit.isPlaceholder {
                    Text("Pending").font(.caption2.weight(.semibold)).foregroundStyle(.orange)
                }
            }
            if credit.text != credit.title { Text(credit.text) }
            if let detail = credit.detail { Text(detail).font(.footnote).foregroundStyle(.secondary) }
            if let link = credit.link {
                Link(credit.displayURL ?? link.absoluteString, destination: link).font(.footnote)
            }
            if let license = credit.license {
                if let url = credit.licenseLink {
                    Link("Licence: \(license)", destination: url).font(.footnote)
                } else {
                    Text("Licence: \(license)").font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let text = credit.licenseText {
                DisclosureGroup("Licence text") {
                    Text(text).font(.caption.monospaced()).textSelection(.enabled)
                }
                .font(.footnote)
            }
        }
        .padding(.vertical, 2)
    }
}

/// A small info button that opens the credits sheet, for interactive views (OSMF attribution
/// guideline, interactive maps: an "(i)" button leading to the licence information).
///
/// It complements the always-visible `WorldAttributionView` (decision 6c), never replaces it.
/// Visually a 24 pt circle with the same fixed-contrast plate as the attribution; the tap
/// target is 44 × 44 pt.
public struct WorldCreditsButton: View {
    let credits: [WorldCredit]
    @State private var isPresented = false

    public init(credits: [WorldCredit]) {
        self.credits = credits
    }

    /// The standard credits for a world, merged with the host's weather attribution.
    public init(world: World, weather: WeatherAttributionInfo? = nil, naipDerivedValues: Bool = false,
                liveFeeds: [WorldLiveFeedCredit] = []) {
        self.credits = WorldCredits.list(for: world, weather: weather, naipDerivedValues: naipDerivedValues, liveFeeds: liveFeeds)
    }

    public var body: some View {
        Button { isPresented = true } label: {
            Image(systemName: "info")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.8), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Credits and licences")
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                WorldCreditsView(credits: credits)
                    .navigationTitle("Credits")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isPresented = false }
                        }
                    }
            }
            #if os(macOS)
            .frame(minWidth: 420, minHeight: 480)
            #endif
        }
    }
}
