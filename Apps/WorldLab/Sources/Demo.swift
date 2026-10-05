import Foundation
import RealityKit
import WorldEngine

/// WorldLab's demo data (Resources/demo.json): focus box, walking loop, speed.
struct DemoConfig: Decodable {
    struct Point: Decodable { var lat: Double; var lon: Double }
    struct Box: Decodable { var south, west, north, east: Double }
    var area: String
    var focus: Box
    var walkSpeed: Double
    var route: [Point]

    static func load() throws -> DemoConfig {
        let url = Bundle.main.url(forResource: "demo", withExtension: "json")!
        return try JSONDecoder().decode(DemoConfig.self, from: Data(contentsOf: url))
    }

    var routeCoordinates: [GeoCoordinate] { route.map { GeoCoordinate(latitude: $0.lat, longitude: $0.lon) } }
    var focusBox: GeoBoundingBox { GeoBoundingBox(south: focus.south, west: focus.west, north: focus.north, east: focus.east) }
}

/// Launch arguments (used by scripts/snapshots.sh and the device test).
struct LaunchOptions {
    var preset: String?
    var instancing = true
    var profile: String?
    var hud = true
    var metrics = false
    /// Comma-separated engine diagnostics, e.g. `-diag noShadows,opaqueProps`.
    var diagnostics: Set<String> = []

    init(_ args: [String] = ProcessInfo.processInfo.arguments) {
        func value(_ key: String) -> String? {
            guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        preset = value("-preset")
        instancing = value("-instancing") != "off"
        profile = value("-profile")
        hud = value("-hud") != "off"
        metrics = value("-metrics") == "on"
        diagnostics = Set((value("-diag") ?? "").split(separator: ",").map(String.init))
    }
}

/// The golden-hour moment used for all M1 screenshots: 22 Sept 2026, 17:45 MDT
/// (sun ~13° up in the west-southwest at Sloan's Lake).
let goldenHour = ISO8601DateFormatter().date(from: "2026-09-22T23:45:00Z")!

/// The stand-in character: a capsule with a nose so its heading is visible. Its origin is at its feet.
@MainActor
func makeStandIn() -> Entity {
    let root = Entity()
    root.name = "Stand-in"
    // A capsule (cylinder + two spheres), 0.9 m tall.
    let paint = SimpleMaterial(color: .init(red: 0.95, green: 0.55, blue: 0.25, alpha: 1), roughness: 0.6, isMetallic: false)
    let body = ModelEntity(mesh: .generateCylinder(height: 0.46, radius: 0.22), materials: [paint])
    body.position = [0, 0.45, 0]
    for y: Float in [0.22, 0.68] {
        let cap = ModelEntity(mesh: .generateSphere(radius: 0.22), materials: [paint])
        cap.position = [0, y, 0]
        root.addChild(cap)
    }
    let nose = ModelEntity(mesh: .generateSphere(radius: 0.07),
                           materials: [SimpleMaterial(color: .init(white: 0.15, alpha: 1), isMetallic: false)])
    nose.position = [0, 0.7, 0.21]
    root.addChild(body)
    root.addChild(nose)
    return root
}
