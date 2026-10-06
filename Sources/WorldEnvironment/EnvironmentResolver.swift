import Foundation
import WorldGen
import WorldGeo

/// The one neutral resolver: time + place + normalized weather + surface checkpoint →
/// `EnvironmentDocument`. Pure and deterministic; no service calls, no renderer types.
public struct EnvironmentResolver: Sendable {
    public static let model = "worldengine-environment-v1"

    public var observer: SkyObserver
    public var tables: LightingTables
    public var stars: StarCatalog?
    public var phenologyProfile: PhenologyProfile?
    public var qualityTier = "target"

    public init(observer: SkyObserver, tables: LightingTables, stars: StarCatalog? = nil, phenologyProfile: PhenologyProfile? = nil) {
        self.observer = observer
        self.tables = tables
        self.stars = stars
        self.phenologyProfile = phenologyProfile
    }

    public struct Input: Sendable {
        public var time: Date
        public var mode: EnvironmentDocument.Time.Mode
        public var sample: WeatherSample?
        public var cell: WeatherCell?
        public var surface: SurfaceState
        public var provider: String
        public var dataKind: String
        public var attribution: WeatherAttributionInfo?
        public var fetchedAt: Date?
        public var expiresAt: Date?
        public var previousLabel: DominantState?
        public var aerial: Bool
        public var includeEvents: Bool

        public init(time: Date, mode: EnvironmentDocument.Time.Mode, sample: WeatherSample?, cell: WeatherCell?, surface: SurfaceState,
                    provider: String = "none", dataKind: String = "demo", attribution: WeatherAttributionInfo? = nil,
                    fetchedAt: Date? = nil, expiresAt: Date? = nil, previousLabel: DominantState? = nil, aerial: Bool = false,
                    includeEvents: Bool = true) {
            self.time = time
            self.mode = mode
            self.sample = sample
            self.cell = cell
            self.surface = surface
            self.provider = provider
            self.dataKind = dataKind
            self.attribution = attribution
            self.fetchedAt = fetchedAt
            self.expiresAt = expiresAt
            self.previousLabel = previousLabel
            self.aerial = aerial
            self.includeEvents = includeEvents
        }
    }

    public func resolve(_ input: Input) -> EnvironmentDocument {
        let t = input.time
        let c = observer.coordinate
        // Sun and the time-of-day key (v2 §3.3).
        let sun = SolarPosition(date: t, at: c)
        let rising = SolarPosition(date: t.addingTimeInterval(600), at: c).elevation > sun.elevation
        let key = LightingModel.state(at: t, location: c, tables: tables)

        // Weather label, wind, atmosphere.
        var flags = input.sample?.flags ?? []
        let resolved = input.sample.map { WeatherClassifier.classify($0, previous: input.previousLabel) }
        flags += resolved?.flags ?? []
        let sample = input.sample ?? WeatherSample(validTime: t)
        let seed = input.cell?.seed ?? 0
        let wind = WindModel.resolve(speedMps: sample.windSpeedMps, fromDegrees: sample.windFromDegrees, gustMps: sample.windGustMps, cellSeed: seed)
        let label = resolved?.dominantState
        let intensity = resolved?.intensity01
        let appearance = WeatherAppearance.target(label: label ?? resolved?.displayFallback, intensity: intensity ?? 0, sample: sample,
                                                  wind: wind, baseFogStart: Double(key.fogStart), baseFogEnd: Double(key.fogEnd),
                                                  aerial: input.aerial, sunFloor: resolved?.flags.contains("sunFloor0.65") ?? false)
        let direct = Atmosphere.directSunGate(elevationDegrees: sun.elevation) * appearance.directMultiplier

        // Night: Moon fill, disk gate, stars.
        let moon = Moon.state(at: t, observer: observer)
        let active = (label?.isPrecipitation ?? false) && (intensity ?? 0) > 0
        let obscuration = (label?.isObscuration ?? false) ? (intensity ?? 0) : 0
        let cloud = sample.cloudCover01
        let b = MoonLight.fill(illuminatedFraction: moon.illuminatedFraction, cloud: cloud, altitudeDeg: moon.altitudeDeg)
        let wet = input.surface.wetness01 ?? 0
        let fillSky = min(0.35, max(0.20, tables.fill.sky + 0.03 * b))
        let fillGround = min(0.12, max(0.06, tables.fill.ground * (1 - 0.5 * wet)))
        let starStrength = Stars.strength(sunElevationDeg: sun.elevation, cloud: cloud, obscuration: obscuration, moonFill: b,
                                          activePrecipitation: active)
        let field = stars.map { Stars.field($0, at: t, observer: observer, strength: starStrength) }
            ?? StarField(strength: starStrength, visible: [], catalogCount: 0)

        // Seasons and particles.
        let phen = phenologyProfile.flatMap { p in observer.timeZone.map { Phenology.resolve(at: t, timeZone: $0, profile: p) } }
        let dropping = phen.map { 4 * $0.deciduous.drop * (1 - $0.deciduous.drop) } ?? 0
        let liquid = 1 - (sample.frozenFraction ?? (label == .snow ? 1 : 0))
        let particles = ParticleBudget.resolve(state: label, intensity: intensity ?? 0, liquidShare: liquid, leafDropRate: dropping,
                                               aerial: input.aerial)

        let surface = input.surface
        var uncertainty: [String] = []
        if surface.status != .modeled { uncertainty.append(surface.status.rawValue) }
        if case .assumedReference = surface.initialization { uncertainty.append("assumed_reference_initial_state") }
        if wind.directionAssumed { uncertainty.append("wind_direction_assumed") }

        return EnvironmentDocument(
            schemaVersion: EnvironmentDocument.schemaVersion,
            identity: .init(environmentModel: Self.model, weatherModel: Accumulation.modelVersion, solarModel: SunEvents.model,
                            lunarModel: Moon.model, starModel: Stars.model, phenologyModel: Phenology.model,
                            timezoneDataVersion: TimeZone.timeZoneDataVersion, starCatalogSHA256: stars?.source.sha256,
                            seed: seed, qualityTier: qualityTier),
            location: .init(cellID: input.cell?.id, cellCenter: input.cell?.center, observer: observer),
            time: .init(validTime: t, intervalStart: input.sample?.intervalStart, intervalEnd: input.sample?.intervalEnd,
                        fetchedAt: input.fetchedAt, expiresAt: input.expiresAt, mode: input.mode),
            provenance: .init(provider: input.provider, dataKind: input.dataKind, flags: flags, attribution: input.attribution),
            inputs: input.sample,
            state: .init(dominantState: label, intensity01: intensity, assumedIntensity: resolved?.assumedIntensity ?? false,
                         displayFallback: resolved?.displayFallback, cloudCover01: cloud, visibilityM: sample.visibilityM, wind: wind,
                         wetness01: surface.wetness01, snowCover01: surface.snowCover01, snowWaterEquivalentMm: surface.snowWaterEquivalentMm,
                         accumulationStatus: surface.status.rawValue, initialState: Self.describe(surface.initialization),
                         conflict: resolved?.conflict ?? false),
            light: .init(sunElevationDeg: sun.elevation, sunAzimuthDeg: sun.azimuth,
                         sunDirection: SIMD3(Double(sun.sceneDirection.x), Double(sun.sceneDirection.y), Double(sun.sceneDirection.z)),
                         branch: rising ? "rising" : "setting", timeOfDay: key, directStrength: direct, weather: appearance,
                         fillSky: fillSky, fillGround: fillGround, moonFill: b,
                         moonDiskOpacity: MoonLight.diskOpacity(altitudeDeg: moon.altitudeDeg, cloud: cloud, obscuration: obscuration,
                                                                activePrecipitation: active),
                         starStrength: starStrength),
            presentation: .init(particles: particles,
                                transitionSeconds: ["atmosphere": TransitionTiming.atmosphere, "fog": TransitionTiming.fog,
                                                    "wind": TransitionTiming.wind, "precipitationOn": TransitionTiming.precipitationOn,
                                                    "precipitationOff": TransitionTiming.precipitationOff,
                                                    "labelHold": TransitionTiming.labelHold, "recapWindow": TransitionTiming.recapWindow],
                                wetDarkeningMax: 0.12, wetRoughness: 0.50, lightning: false, sound: false),
            continuity: .init(checkpointTime: surface.status == .modeled ? surface.time : nil,
                              accumulationModelVersion: Accumulation.modelVersion, uncertainty: uncertainty),
            sky: .init(sunDay: input.includeEvents ? SunEvents.day(containing: t, observer: observer) : nil, moon: moon,
                       moonDay: input.includeEvents ? Moon.day(containing: t, observer: observer) : nil, stars: field,
                       starAttribution: StarCatalog.attribution),
            phenology: phen)
    }

    static func describe(_ i: SurfaceState.Initialization) -> String {
        switch i {
        case .unknown: "unknown"
        case .checkpoint(let source): "checkpoint:\(source)"
        case .assumedReference(let w, let s): "assumed_reference(W=\(w), S=\(s))"
        }
    }
}
