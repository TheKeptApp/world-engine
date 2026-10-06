import Foundation
import WorldGeo
import WorldMap

/// Style profiles chosen per feature by location (the region catalog's zones), so one area can
/// cross zones, e.g. a suburb/city border (regions spec §2: one profile per building, selected at its
/// representative point; a building crossing a boundary gets one profile). The area profile stays
/// the fallback and still drives area-wide choices (season, mapped trees).
public struct ZoneProfiles: Sendable {
    public var catalog: RegionCatalog
    /// Decoded profiles by ID (every zone touching the area, plus the catalog default).
    public var profiles: [String: StyleProfile]
    public var frame: LocalFrame

    public init(catalog: RegionCatalog, profiles: [String: StyleProfile], frame: LocalFrame) {
        self.catalog = catalog
        self.profiles = profiles
        self.frame = frame
    }

    /// The zone profile ID at a local point.
    public func profileID(at p: LocalPoint) -> String { catalog.profileID(at: frame.coordinate(at: p)) }

    /// The zone profile at a local point, if it was loaded.
    public func profile(at p: LocalPoint) -> StyleProfile? { profiles[profileID(at: p)] }

    /// Loads the bundled catalog and every profile whose zone overlaps the area.
    public static func load(for manifest: AreaManifest) throws -> ZoneProfiles {
        let catalog = try StyleLibrary.regions()
        let b = manifest.bounds
        var ids: Set<String> = [catalog.defaultProfile]
        for r in catalog.regions where r.bounds.south <= b.north && r.bounds.north >= b.south && r.bounds.west <= b.east && r.bounds.east >= b.west {
            ids.insert(r.profile)
        }
        var profiles: [String: StyleProfile] = [:]
        for id in ids.sorted() { profiles[id] = try StyleLibrary.profile(id: id) }
        return ZoneProfiles(catalog: catalog, profiles: profiles, frame: manifest.frame)
    }
}
