import Foundation
import WorldGeo

/// foliage-seasons-v1 (R approved and binding, 2026-10-07). Pack values are read by key from the shared
/// mock values (`Profiles/mock-values.json`, prefix `style-b/foliage/`, species and cities by id): summer
/// albedo, botanical height/spread, evergreen, the city mixes. `Profiles/vegetation.json`
/// `foliageSeasons` holds only P2's choices: the crown silhouette per described species, a nearest
/// described species for mix species the pack does not describe, and which profiles draw from which
/// city's mix.
public struct FoliageSeasons: Codable, Sendable {
    public struct Species: Codable, Sendable, Equatable {
        /// Crown silhouette (`PropKind` raw value: a species crown or "conifer"); nil when none fits
        /// (palms, evergreen broadleaves): mapped trees then keep their genus form.
        public var kind: String?
    }

    public struct CityMix: Codable, Sendable, Equatable {
        /// The pack city id (`cities.<city>`).
        public var city: String
        /// Style profiles whose inferred trees draw from this city's mix.
        public var profiles: [String]
    }

    /// Mock-value key prefix ("style-b/foliage/").
    public var prefix: String
    /// Every species the pack describes, by pack id.
    public var species: [String: Species]
    /// City-mix species the pack names but does not describe → the nearest described species (P2 choice).
    public var nearest: [String: String]
    public var mixes: [String: CityMix]

    /// How a tree's species was found: from its OSM tags, or drawn from the city mix.
    public enum Source: String, Sendable, Codable { case mapped, inferred }

    /// The mix dressing a profile, if any.
    public func mix(forProfile id: String) -> CityMix? {
        mixes.keys.sorted().compactMap { mixes[$0] }.first { $0.profiles.contains(id) }
    }

    // MARK: - Pack values (mock values)

    /// The pack's mix species for a city, in pack order (`cities.<city>.mix[i].id`), as described
    /// species (undescribed ones through `nearest`).
    public func mixSpecies(_ mix: CityMix, mock: MockValues? = .bundled) -> [String] {
        var out: [String] = []
        var i = 0
        while let id = mock?.string("\(prefix)cities.\(mix.city).mix[\(i)].id") {
            let described: String? = species[id] != nil ? id : nearest[id]
            if let d = described, !out.contains(d) { out.append(d) }
            i += 1
        }
        return out
    }

    /// The species' summer crown albedo (`species.<id>.seasonColours.summer`).
    public func summer(_ id: String, mock: MockValues? = .bundled) -> String? {
        mock?.string("\(prefix)species.\(id).seasonColours.summer")
    }

    /// Pack height and spread ranges (metres, `species.<id>.dimensionsM`).
    public func dimensions(_ id: String, mock: MockValues? = .bundled) -> (height: [Double], spread: [Double])? {
        func range(_ path: String) -> [Double] { (0..<2).compactMap { mock?.number("\(prefix)species.\(id).dimensionsM.\(path)[\($0)]") } }
        let h = range("height"), s = range("spread")
        return h.count == 2 && s.count == 2 ? (h, s) : nil
    }

    // MARK: - Species pick

    /// The described species a binomial names ("Acer platanoides", "Platanus × acerifolia"), directly
    /// or through `nearest`.
    public func described(binomial name: String) -> String? {
        let words = name.lowercased().replacingOccurrences(of: "×", with: " x ").split(separator: " ").map(String.init)
        guard words.count >= 2 else { return nil }
        let key = words[1] == "x" && words.count >= 3 ? "\(words[0])_x_\(words[2])" : "\(words[0])_\(words[1])"
        if species[key] != nil { return key }
        return nearest[key]
    }

    /// A mapped tree's species from its tags (`species`, `taxon`, then `genus`): an exact or nearest
    /// described species, else for a genus the mix's species of that genus (seeded pick), else the
    /// pack's described species of that genus. Nil when the tags name none.
    public func mappedSpecies(tags: [String: String], mix: CityMix?, random r: inout StableRandom) -> String? {
        let names = [tags["species"], tags["taxon"]].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        for name in names { if let id = described(binomial: name) { return id } }
        let genera = ([tags["genus"]] + names.map { $0.split(separator: " ").first.map(String.init) })
            .compactMap { $0?.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        let pool0 = mix.map { mixSpecies($0) } ?? []
        for genus in genera {
            let inMix = pool0.filter { $0.hasPrefix(genus + "_") }
            let pool = inMix.isEmpty ? species.keys.filter { $0.hasPrefix(genus + "_") }.sorted() : inMix
            if !pool.isEmpty { return pool[Int(r.next() % UInt64(pool.count))] }
        }
        return nil
    }

    /// An inferred tree's species: equal odds among the mix's species drawn in crown form `form`
    /// (`PropLibrary.crownForm`; "conifer" for conifers). The pack gives no abundances; the profile's
    /// crown-form weights (drawn before) keep each colour family's share, so the autumn mix holds.
    public func inferred(form: String, mix: CityMix, random r: inout StableRandom) -> String? {
        let pool = mixSpecies(mix).filter { id in
            guard let kind = kind(id) else { return false }
            return form == "conifer" ? kind == .conifer : kind != .conifer && PropLibrary.crownForm(kind) == form
        }
        guard !pool.isEmpty else { return nil }
        return pool[Int(r.next() % UInt64(pool.count))]
    }

    /// The silhouette a species is drawn with, if one fits.
    public func kind(_ id: String) -> PropKind? { species[id]?.kind.flatMap(PropKind.init(rawValue:)) }

    /// Width factor for a species drawn with a shared silhouette: its pack spread/height (range
    /// midpoints) over the silhouette's own crown width (unit height), within 0.6–1.2. Instances
    /// multiply their stretch by it.
    public func widthScale(_ id: String) -> Double {
        guard let kind = kind(id), let d = dimensions(id) else { return 1 }
        let target = (d.spread[0] + d.spread[1]) / (d.height[0] + d.height[1])
        return min(1.2, max(0.6, target / Double(PropLibrary.crownWidth(kind))))
    }
}

extension VegetationLibrary {
    /// Summer crown colours from foliage-seasons-v1 for profiles with a city mix: each crown slot of the
    /// profile's region takes its family's pack species' summer albedo (after the daytime master's crown
    /// greens). Spring, autumn, winter and slots without a pack species (willow) are unchanged; other
    /// profiles unchanged.
    public func applyingFoliageSummer(to seasonal: SeasonalPalette, profileID: String) -> SeasonalPalette {
        guard let foliage = foliageSeasons, foliage.mix(forProfile: profileID) != nil, let region = region(forProfile: profileID) else { return seasonal }
        var out = seasonal
        for (slot, entry) in region.slots.sorted(by: { $0.key < $1.key }) {
            guard let pack = species[Self.speciesID(entry)]?.packSpecies, let hex = foliage.summer(pack),
                  var row = out.surfaces[slot], row.count == 4 else { continue }
            row[1] = hex
            out.surfaces[slot] = row
        }
        return out
    }
}
