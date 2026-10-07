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
        /// The foliage-seasons-v1 species this family stands for (its summer colour in regions with a
        /// city mix); nil when the pack describes none (willow).
        public var packSpecies: String?
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
    /// foliage-seasons-v1 (R approved 2026-10-07): described species, nearest-species map and city mixes.
    public var foliageSeasons: FoliageSeasons?

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
        for (slot, entry) in region.slots {
            // "species@lag": a later-turning tree of that species (autumn colour lag × of the way back
            // toward its summer green, mixed in linear light), so one street mixes green, gold and orange.
            let parts = entry.split(separator: "@").map(String.init)
            guard let s = species[parts[0]], s.colours.count == 4 else { continue }
            var colours = s.colours
            if parts.count == 2, let lag = Double(parts[1]), lag > 0 {
                colours[2] = Self.mixHex(s.colours[2], s.colours[1], min(1, lag))
            }
            out.surfaces[slot] = colours
        }
        if let s = species[region.bark] { out.surfaces["bark"] = Array(repeating: s.branches, count: 4) }
        out.crownColors = region.crownColors
        return out
    }

    /// The species ID of a slot entry ("species" or "species@lag").
    public static func speciesID(_ entry: String) -> String { String(entry.split(separator: "@").first ?? Substring(entry)) }

    /// Two sRGB hex colours mixed in linear light (t = 0 → a, 1 → b).
    static func mixHex(_ a: String, _ b: String, _ t: Double) -> String {
        func rgb(_ h: String) -> [Double] {
            let v = UInt32(h.dropFirst(), radix: 16) ?? 0
            return [Double((v >> 16) & 255), Double((v >> 8) & 255), Double(v & 255)].map { $0 / 255 }
        }
        func lin(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        func srgb(_ c: Double) -> Double { c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1 / 2.4) - 0.055 }
        let m = zip(rgb(a), rgb(b)).map { srgb(lin($0) * (1 - t) + lin($1) * t) }
        return String(format: "#%02X%02X%02X", Int((m[0] * 255).rounded()), Int((m[1] * 255).rounded()), Int((m[2] * 255).rounded()))
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
