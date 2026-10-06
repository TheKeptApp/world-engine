import Foundation
import simd
import WorldGeo
import WorldMap

/// Everything that decides a generated world besides the map data and the bundled profiles.
public struct WorldRecipe: Sendable, Codable, Equatable {
    /// Force a style profile by ID; nil = chosen by location from the region data.
    public var profileID: String?
    /// The moment that sets the sun, light keys and season.
    public var date: Date
    /// Force a season (0 spring … 3 winter); nil = from the date and the profile.
    public var season: Int?
    /// Region with full street detail; nil = the whole area.
    public var focus: GeoBoundingBox?

    public init(profileID: String? = nil, date: Date = Date(), season: Int? = nil, focus: GeoBoundingBox? = nil) {
        self.profileID = profileID
        self.date = date
        self.season = season
        self.focus = focus
    }
}

/// The one place a world is generated (one decision owner): the RealityKit renderer calls this
/// at load time and `worldbake export` calls it to write the shared package for other renderers.
public struct WorldBuild: Sendable {
    public var manifest: AreaManifest
    public var features: MapFeatures
    public var profile: StyleProfile
    public var season: Int
    public var lighting: LightingState
    public var focus: Rect2D
    public var scene: GeneratedScene
    /// No-character experience defaults: composed postcards, aerial fit, motion bounds.
    public var experience: ExperienceDefaults?
    /// Per-building zone profiles (nil when the recipe forces one profile).
    public var zones: ZoneProfiles?

    public static func generate(areaDirectory: URL, recipe: WorldRecipe) throws -> WorldBuild {
        let manifest = try AreaLoader.loadManifest(areaDirectory)
        let features = try AreaLoader.loadFeatures(areaDirectory)
        let profile = try recipe.profileID.map(StyleLibrary.profile(id:)) ?? StyleLibrary.profile(at: manifest.center)
        let season = recipe.season ?? profile.seasons.season(at: recipe.date, longitude: manifest.center.longitude)
        let lighting = LightingModel.state(at: recipe.date, location: manifest.center, tables: try StyleLibrary.lighting())
        let focus = Self.focusRect(recipe.focus, frame: manifest.frame) ?? features.bounds
        // An explicit profile is a test override for every building; otherwise each building
        // takes the zone profile at its centroid.
        let zones = recipe.profileID == nil ? try ZoneProfiles.load(for: manifest) : nil
        var gen = try generator(features: features, profile: profile, season: season, focus: focus)
        gen.zones = zones
        let scene = gen.generate()
        var build = WorldBuild(manifest: manifest, features: features, profile: profile, season: season, lighting: lighting,
                               focus: focus, scene: scene)
        build.zones = zones
        build.experience = ExperienceDefaults.compose(build: build, date: recipe.date)
        return build
    }

    /// The generator configured for this build (also used for the reduced-detail LOD1 pass).
    public static func generator(features: MapFeatures, profile: StyleProfile, season: Int, focus: Rect2D) throws -> SceneGenerator {
        SceneGenerator(features: features, profile: profile, seasonal: try StyleLibrary.seasonalPalette(),
                       baseColors: try StyleLibrary.baseColors(), season: season, focus: focus)
    }

    /// Chunk geometry at reduced detail (LOD1): every building simple, no curbs or sidewalk edges.
    /// Starts from the full build's palette so slot numbers agree.
    public func reducedDetail() throws -> GeneratedScene {
        var gen = try Self.generator(features: features, profile: profile, season: season, focus: focus)
        gen.lod = 1
        gen.startPalette = scene.palette
        gen.zones = zones
        return gen.generate()
    }

    public static func focusRect(_ f: GeoBoundingBox?, frame: LocalFrame) -> Rect2D? {
        guard let f else { return nil }
        let a = frame.localPoint(of: GeoCoordinate(latitude: f.south, longitude: f.west))
        let b = frame.localPoint(of: GeoCoordinate(latitude: f.north, longitude: f.east))
        return Rect2D(min: simd_min(a, b), max: simd_max(a, b))
    }
}
