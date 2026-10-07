import Foundation

/// Tree species families and their regions (`Profiles/vegetation.json`; colours from vegetation-v1).
/// A region fills a scene palette's crown slots (deciduous1…8, conifer1…2), bark and per-form colour
/// families; OSM genus/species tags pick a mapped tree's crown form.
public struct VegetationLibrary: Codable, Sendable {
    public struct Species: Codable, Sendable, Equatable {
        /// Crown archetype: "broad", "oval", "spreading" or "conifer".
        public var form: String
        /// Crown colour per season (spring, summer, autumn, winter); bare winter = branch colour.
        public var colours: [String]
        /// Branch (bark) body colour.
        public var branches: String
    }

    public struct Region: Codable, Sendable, Equatable {
        /// Style profile IDs this region dresses.
        public var profiles: [String]
        /// Palette slot key → species ID.
        public var slots: [String: String]
        /// Species whose branch colour the bark slot takes.
        public var bark: String
        public var crownColors: [String: SeasonalPalette.CrownColors]
    }

    public var species: [String: Species]
    public var regions: [String: Region]
    /// OSM genus (or "Genus species") → crown form.
    public var genusForms: [String: String]

    public static let bundled: VegetationLibrary = {
        guard let data = try? StyleLibrary.data("vegetation"), let lib = try? JSONDecoder().decode(VegetationLibrary.self, from: data) else {
            return VegetationLibrary(species: [:], regions: [:], genusForms: [:])
        }
        return lib
    }()

    /// The region dressing a style profile, if any.
    public func region(forProfile id: String) -> Region? {
        regions.keys.sorted().compactMap { regions[$0] }.first { $0.profiles.contains(id) }
    }

    /// `seasonal` with the profile's region crown slots, bark and crown colour families (unchanged when
    /// the profile has no region).
    public func applying(to seasonal: SeasonalPalette, profileID: String) -> SeasonalPalette {
        guard let region = region(forProfile: profileID) else { return seasonal }
        var out = seasonal
        for (slot, id) in region.slots {
            if let s = species[id], s.colours.count == 4 { out.surfaces[slot] = s.colours }
        }
        if let s = species[region.bark] { out.surfaces["bark"] = Array(repeating: s.branches, count: 4) }
        out.crownColors = region.crownColors
        return out
    }

    /// Crown form for a mapped tree's tags: `species` / `taxon` ("Genus species") first, then `genus`
    /// (or the first word of species/taxon); nil when none is known.
    public func form(tags: [String: String]) -> String? {
        let names = [tags["species"], tags["taxon"], tags["genus"]].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        for name in names {
            let words = name.split(separator: " ").map(String.init)
            if words.count >= 2, let f = genusForms["\(words[0].capitalized) \(words[1].lowercased())"] { return f }
        }
        for name in names {
            if let genus = name.split(separator: " ").first.map({ String($0).capitalized }), let f = genusForms[genus] { return f }
        }
        return nil
    }
}
