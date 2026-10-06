import Foundation
import Observation
import WorldEngine
import WorldEnvironment

/// WorldLab's environment source: a clock (live or scrubbed) and Demo weather (a showcase state
/// or a manual pick), resolved by the shared EnvironmentResolver and applied to the world.
/// Live WeatherKit data arrives in 5B; until then every weather state is labeled "Demo".
@MainActor
@Observable
final class EnvironmentController {
    /// A named Demo weather state (showcase fixture or manual pick).
    struct Preset: Identifiable, Equatable {
        var id: String
        var title: String
        var weather: SyntheticWeather
        /// Showcase states carry their own moment and camera.
        var time: Date?
        var camera: String?
    }

    private(set) var document: EnvironmentDocument?
    /// The moment shown; follows the wall clock while `isLive`.
    private(set) var time = Date()
    private(set) var isLive = true
    private(set) var preset: Preset
    let presets: [Preset]
    let locationLabel: String
    let timeZone: TimeZone

    @ObservationIgnored private let resolver: EnvironmentResolver
    @ObservationIgnored private weak var world: World?
    @ObservationIgnored private var clock: Timer?
    @ObservationIgnored var aerial = false

    init(demo: DemoConfig, world: World) throws {
        let tz = TimeZone(identifier: demo.timeZone ?? "UTC") ?? .gmt
        timeZone = tz
        locationLabel = demo.locationLabel ?? world.manifest.name
        resolver = try world.environmentResolver(timeZone: tz, phenologyProfileID: demo.phenology)
        var list: [Preset] = [
            Preset(id: "clear", title: "Clear", weather: SyntheticWeather(label: .clear, cloudFraction: 0.05)),
            Preset(id: "cloudy", title: "Overcast", weather: SyntheticWeather(label: .cloudy, intensity: 1, cloudFraction: 1)),
            Preset(id: "rain", title: "Light rain", weather: SyntheticWeather(label: .rain, cloudFraction: 0.8, precipitationMmPerHour: 0.5, wetness: 0.65)),
            Preset(id: "storm", title: "Thunderstorm", weather: SyntheticWeather(label: .thunderstorm, intensity: 1, cloudFraction: 1, precipitationMmPerHour: 8, windSpeedMps: 9, wetness: 0.9)),
            Preset(id: "fog", title: "Fog", weather: SyntheticWeather(label: .fog, intensity: 1, cloudFraction: 0.8)),
            Preset(id: "smoke", title: "Smoke", weather: SyntheticWeather(label: .smoke, intensity: 0.8, cloudFraction: 0.15, visibilityM: 1200)),
            Preset(id: "snow", title: "Falling snow", weather: SyntheticWeather(label: .snow, intensity: 1, cloudFraction: 1, precipitationMmPerHour: 2, wetness: 0.15, snowWaterEquivalentMm: 6)),
            Preset(id: "aftersnow", title: "After snow", weather: SyntheticWeather(label: .clear, cloudFraction: 0, wetness: 0.45, snowWaterEquivalentMm: 3)),
        ]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for s in demo.showcase?.states ?? [] {
            let w = SyntheticWeather(label: DominantState(rawValue: s.label) ?? .clear, intensity: s.intensity, cloudFraction: s.cloud,
                                     precipitationMmPerHour: s.rateMmPerHour, visibilityM: s.visibilityM, wetness: s.wetness,
                                     snowWaterEquivalentMm: s.sweMm)
            let t = iso.date(from: s.utc) ?? ISO8601DateFormatter().date(from: s.utc)
            list.append(Preset(id: "showcase-\(s.id)", title: "\(s.id) \(s.name.replacingOccurrences(of: "-", with: " "))", weather: w,
                               time: t, camera: s.camera))
        }
        presets = list
        preset = list[0]
        self.world = world
    }

    /// Starts following the wall clock (re-resolves every 30 s: the sky moves slowly).
    func goLive() {
        isLive = true
        time = Date()
        resolve()
        clock?.invalidate()
        clock = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isLive else { return }
                self.time = Date()
                self.resolve()
            }
        }
    }

    /// Shows a fixed moment (time scrubber, showcase state).
    func set(time t: Date) {
        isLive = false
        time = t
        resolve()
    }

    func select(_ p: Preset) {
        preset = p
        if let t = p.time { set(time: t) } else { resolve() }
    }

    func resolve() {
        let env = resolver.resolve(preset.weather.input(at: time, aerial: aerial))
        document = env
        world?.apply(env)
    }

    // MARK: Display

    /// Sunrise and sunset of the shown day (for the scrubber markers), if the sun crosses.
    var sunEvents: (sunrise: Date?, sunset: Date?) {
        let day = document?.sky.sunDay
        return (day?.sunrise.first?.utc, day?.sunset.first?.utc)
    }

    /// Start of the shown local day.
    var dayStart: Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.startOfDay(for: time)
    }

    func clockText(_ d: Date, date: Bool = true) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = date ? "MMM d, HH:mm zzz" : "HH:mm"
        return f.string(from: d)
    }

    var conditionText: String {
        guard let s = document?.state.dominantState else { return "Weather unknown" }
        switch s {
        case .clear: return (document?.light.sunElevationDeg ?? 0) > 0 ? "Clear" : "Clear night"
        case .cloudy: return "Overcast"
        case .rain: return (document?.state.intensity01 ?? 0) < 0.4 ? "Light rain" : "Rain"
        case .snow: return "Snow"
        case .fog: return "Fog"
        case .haze: return "Haze"
        case .smoke: return "Smoke"
        case .dust: return "Dust"
        case .thunderstorm: return "Thunderstorm"
        }
    }

    var conditionSymbol: String {
        switch document?.state.dominantState {
        case .clear?: return (document?.light.sunElevationDeg ?? 0) > 0 ? "sun.max" : "moon.stars"
        case .cloudy?: return "cloud"
        case .rain?: return "cloud.rain"
        case .snow?: return "cloud.snow"
        case .fog?: return "cloud.fog"
        case .haze?, .smoke?, .dust?: return "sun.haze"
        case .thunderstorm?: return "cloud.bolt.rain"
        case nil: return "questionmark.circle"
        }
    }

    var temperatureText: String? {
        document?.inputs?.temperatureC.map { String(format: "%.0f°C", $0) }
    }

    var windText: String? {
        guard let w = document?.state.wind, let u = w.speedMps else { return nil }
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let i = Int(((w.displayFromDegrees + 22.5).truncatingRemainder(dividingBy: 360)) / 45) % 8
        return String(format: "%@ %.0f m/s", points[i], u)
    }

    var precipitationText: String? {
        guard let r = document?.inputs?.precipitationRateMmPerHour, r > 0 else { return nil }
        return String(format: "%.1f mm/h", r)
    }
}
