import Foundation
import RealityKit
import WorldEngine

/// WorldLab's demo data (Resources/demo.json): focus box, walking loop, speed, v2 fixtures.
struct DemoConfig: Decodable {
    struct Point: Decodable { var lat: Double; var lon: Double }
    struct Box: Decodable { var south, west, north, east: Double }
    struct Fixtures: Decodable {
        var streetAnchor: Point
        var streetCameraOffset: [Float]
        var streetTargetOffset: [Float]
        var aerialCenter: Point
        var aerialCameraOffset: [Float]
        var fovDegrees: Float
        var goldenUTC: String
        var noonUTC: String
    }
    var area: String
    var focus: Box
    var walkSpeed: Double
    var route: [Point]
    var fixtures: Fixtures

    static func load() throws -> DemoConfig {
        let url = Bundle.main.url(forResource: "demo", withExtension: "json")!
        return try JSONDecoder().decode(DemoConfig.self, from: Data(contentsOf: url))
    }

    var routeCoordinates: [GeoCoordinate] { route.map { GeoCoordinate(latitude: $0.lat, longitude: $0.lon) } }
    var focusBox: GeoBoundingBox { GeoBoundingBox(south: focus.south, west: focus.west, north: focus.north, east: focus.east) }
    var goldenDate: Date { ISO8601DateFormatter().date(from: fixtures.goldenUTC)! }
    var noonDate: Date { ISO8601DateFormatter().date(from: fixtures.noonUTC)! }
}

/// Launch arguments (used by scripts/snapshots.sh and the device tests).
struct LaunchOptions {
    var preset: String?
    var profile: String?
    var hud = true
    var metrics = false
    var frame16x9 = false
    /// realitykit | webgl2 | webgpu
    var renderer: String?
    /// Comma-separated engine diagnostics, e.g. `-diag noShadows,noPost`.
    var diagnostics: Set<String> = []

    init(_ args: [String] = ProcessInfo.processInfo.arguments) {
        func value(_ key: String) -> String? {
            guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        preset = value("-preset")
        profile = value("-profile")
        hud = value("-hud") != "off"
        metrics = value("-metrics") == "on"
        frame16x9 = args.contains("-frame16x9")
        renderer = value("-renderer")
        diagnostics = Set((value("-diag") ?? "").split(separator: ",").map(String.init))
    }

    /// The moment for this run: v2 golden-hour fixture, or v2 summer noon for the noon preset.
    func date(_ demo: DemoConfig) -> Date { preset == "v2-04" ? demo.noonDate : demo.goldenDate }
}

/// The walking character: DogWell's Luna (converted to USDZ, see scripts/convert-dog.sh) with her
/// walk clip when bundled, else a 0.65 m capsule stand-in. Origin at the feet, facing +Z.
@MainActor
func makeCharacter() async -> Entity {
    if let url = Bundle.main.url(forResource: "luna_light", withExtension: "usdz"),
       let dog = try? await Entity(contentsOf: url) {
        dog.name = "Luna"
        if let walk = dog.availableAnimations.first(where: { $0.name?.contains("walk") == true && $0.name?.contains("turn") == false })
            ?? dog.availableAnimations.first {
            dog.playAnimation(walk.repeat())
        }
        let root = Entity()
        root.name = "Character"
        root.addChild(dog)
        return root
    }
    let root = Entity()
    root.name = "Stand-in"
    let paint = SimpleMaterial(color: .init(red: 0.95, green: 0.55, blue: 0.25, alpha: 1), roughness: 0.6, isMetallic: false)
    let body = ModelEntity(mesh: .generateCylinder(height: 0.41, radius: 0.12), materials: [paint])
    body.position = [0, 0.325, 0]
    for y: Float in [0.12, 0.53] {
        let cap = ModelEntity(mesh: .generateSphere(radius: 0.12), materials: [paint])
        cap.position = [0, y, 0]
        root.addChild(cap)
    }
    let nose = ModelEntity(mesh: .generateSphere(radius: 0.04), materials: [SimpleMaterial(color: .init(white: 0.15, alpha: 1), isMetallic: false)])
    nose.position = [0, 0.5, 0.11]
    root.addChild(body)
    root.addChild(nose)
    return root
}
