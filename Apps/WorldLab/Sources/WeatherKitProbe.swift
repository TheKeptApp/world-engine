import CoreLocation
import Foundation
import WeatherKit
import WorldEnvironment
import WorldGeo

/// `-weatherkit-probe`: one live WeatherKit request for a fixed public test point (Plano, TX city
/// centre, snapped to the 0.05° provider grid), printed and discarded. Nothing is stored.
/// Full live integration (provider, cache, refresh) comes later; this only proves the setup.
@MainActor
enum WeatherKitProbe {
    /// Public city-centre reference (sky-seasons fixtures), never a user location.
    static let planoCityCentre = GeoCoordinate(latitude: 33.0198, longitude: -96.6989)

    static func run() async {
        let cell = WeatherCell(containing: planoCityCentre)
        let c = cell.center
        print("WEATHERKIT request cell=\(cell.id) centre=\(c.latitude),\(c.longitude)")
        do {
            let current = try await WeatherService.shared.weather(for: CLLocation(latitude: c.latitude, longitude: c.longitude),
                                                                  including: .current)
            let s = WeatherKitAdapter.sample(current)
            print("WEATHERKIT ok condition=\(current.condition.rawValue) mapped=\(s.condition?.rawValue ?? "unmapped") "
                  + "cloud=\(s.cloudCover01.map { String(format: "%.2f", $0) } ?? "nil") "
                  + "tempC=\(s.temperatureC.map { String(format: "%.1f", $0) } ?? "nil") "
                  + "wind=\(s.windSpeedMps.map { String(format: "%.1f", $0) } ?? "nil")m/s from \(s.windFromDegrees.map { String(format: "%.0f", $0) } ?? "nil") "
                  + "visibility=\(s.visibilityM.map { String(format: "%.0f", $0) } ?? "nil")m "
                  + "rate=\(s.precipitationRateMmPerHour.map { String(format: "%.2f", $0) } ?? "nil")mm/h "
                  + "valid=\(current.date) expires=\(current.metadata.expirationDate)")
            let a = try await WeatherService.shared.attribution
            print("WEATHERKIT attribution service=\(a.serviceName) legal=\(a.legalPageURL)")
        } catch {
            print("WEATHERKIT error \(error) | \(String(describing: (error as NSError).userInfo))")
        }
    }
}

/// WeatherKit → WorldEnvironment's provider-neutral sample (units converted through their
/// Measurements; the original condition string kept).
enum WeatherKitAdapter {
    static func sample(_ w: CurrentWeather) -> WeatherSample {
        WeatherSample(validTime: w.date, condition: WeatherConditionCode(rawValue: w.condition.rawValue),
                      conditionRaw: w.condition.rawValue, cloudCover01: Normalize.fraction(w.cloudCover),
                      temperatureC: Normalize.celsius(w.temperature), humidity01: Normalize.fraction(w.humidity),
                      visibilityM: Normalize.visibilityMeters(w.visibility), windSpeedMps: Normalize.metersPerSecond(w.wind.speed),
                      windFromDegrees: Normalize.degrees(w.wind.direction), windGustMps: w.wind.gust.flatMap(Normalize.metersPerSecond),
                      precipitationRateMmPerHour: Normalize.millimetersPerHour(w.precipitationIntensity))
    }
}
