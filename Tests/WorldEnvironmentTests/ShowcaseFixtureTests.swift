import Foundation
import Testing
@testable import WorldEnvironment
import WorldGen
import WorldGeo

/// experience-v1 showcase states (docs/proposals/experience-v1/showcase-presets.json, read-only
/// input) resolved through the shared resolver: fog distances, direct strength and tint must match
/// the proposal's resolved values.
enum ShowcaseFixtures {
    static let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("docs/proposals/experience-v1/showcase-presets.json")
    static var json: [String: Any] { (try? JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]) ?? [:] }
    static var fixtures: [[String: Any]] { json["fixtures"] as? [[String: Any]] ?? [] }
    static var available: Bool { !fixtures.isEmpty }
    static let ids: [String] = fixtures.compactMap { $0["id"] as? String }

    static func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)!
    }

    static func weather(_ f: [String: Any]) -> SyntheticWeather {
        func n(_ k: String) -> Double { (f[k] as? NSNumber)?.doubleValue ?? 0 }
        let surface = f["surfaceCheckpoint"] as! [String: Any]
        return SyntheticWeather(label: DominantState(rawValue: f["atmosphere"] as! String)!, intensity: n("intensity"),
                                cloudFraction: n("cloudFraction"),
                                precipitationMmPerHour: n("precipitationLiquidEquivalentMMPerHour"),
                                visibilityM: (f["visibilityM"] as? NSNumber)?.doubleValue,
                                wetness: (surface["wetness"] as! NSNumber).doubleValue,
                                snowWaterEquivalentMm: (surface["snowWaterEquivalentMM"] as! NSNumber).doubleValue)
    }
}

@Suite("Showcase states (docs/proposals/experience-v1)")
struct ShowcaseFixtureTests {
    @Test(.enabled(if: ShowcaseFixtures.available), arguments: ShowcaseFixtures.ids)
    func resolvesLikeTheProposal(_ id: String) throws {
        let f = ShowcaseFixtures.fixtures.first { $0["id"] as? String == id }!
        let cameras = ShowcaseFixtures.json["cameras"] as! [String: Any]
        let camera = cameras[f["camera"] as! String] as! [String: Any]
        let origin = camera["originLatLon"] as! [Double]
        let observer = SkyObserver(latitude: origin[0], longitude: origin[1], timeZoneID: "America/Denver")
        let resolver = EnvironmentResolver(observer: observer, tables: try StyleLibrary.lighting(), stars: nil, phenologyProfile: .denverDemo)
        let t = ShowcaseFixtures.date(f["timeUTC"] as! String)
        let env = resolver.resolve(ShowcaseFixtures.weather(f).input(at: t, aerial: f["camera"] as? String == "aerial"))
        let r = f["resolved"] as! [String: Any]
        func n(_ k: String) -> Double { (r[k] as! NSNumber).doubleValue }
        print("SHOWCASE \(id) label=\(env.state.dominantState?.rawValue ?? "-") i=\(env.state.intensity01 ?? -1) fog=\(env.light.weather.fogStartM)–\(env.light.weather.fogEndM) (want \(n("fogStartM"))–\(n("fogEndM"))) direct=\(env.light.directStrength * Double(env.light.timeOfDay.sunIntensity)) (want \(n("directStrength"))) tintW=\(env.light.weather.tintWeight) (want \(n("tintLinearMixWeight"))) snow=\(env.state.snowCover01 ?? -1)")
        // Aerial fog: the renderer applies its own height-based policy (v2 §3.3 FogPolicy) at the
        // camera; the proposal's aerial numbers assume a fixed 900–2500 m base, so only street
        // states are compared here.
        if f["camera"] as? String == "street" {
            #expect(abs(env.light.weather.fogStartM - n("fogStartM")) <= 0.5, "\(id) fog start")
            #expect(abs(env.light.weather.fogEndM - n("fogEndM")) <= 0.5, "\(id) fog end")
        }
        // The proposal's direct strength includes the time-of-day sun intensity.
        let direct = env.light.directStrength * Double(env.light.timeOfDay.sunIntensity)
        #expect(abs(direct - n("directStrength")) <= 0.005, "\(id) direct")
        #expect(abs(env.light.weather.tintWeight - n("tintLinearMixWeight")) <= 0.001, "\(id) tint weight")
        let surface = f["surfaceCheckpoint"] as! [String: Any]
        #expect(abs((env.state.snowCover01 ?? 0) - (surface["eligibleSnowCoverage"] as! NSNumber).doubleValue) <= 1e-6, "\(id) snow coverage")
    }
}
