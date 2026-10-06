import Metal
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
    /// experience-v1 showcase: camera poses (local metres around an origin) and Demo weather states.
    struct Showcase: Decodable {
        struct Camera: Decodable {
            var origin: Point
            var position: [Double]
            var target: [Double]
            var fovDegrees: Double
        }
        struct State: Decodable {
            var id: String
            var name: String
            var camera: String
            var utc: String
            var label: String
            var intensity: Double
            var cloud: Double
            var rateMmPerHour: Double
            var visibilityM: Double?
            var wetness: Double
            var sweMm: Double
            var note: String?
        }
        var cameras: [String: Camera]
        var states: [State]
    }
    var area: String
    var focus: Box
    var walkSpeed: Double
    var route: [Point]
    var fixtures: Fixtures
    var locationLabel: String?
    var timeZone: String?
    var phenology: String?
    var showcase: Showcase?

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
    /// `-date ISO8601`: the moment for this run (overrides the fixtures).
    var dateOverride: Date?
    /// `-renderscale native|policy|<number>`, `-calm off`: display settings (default: the shared policy).
    var renderSettings = WorldRenderSettings()
    /// `-pausetest N`: pause at N s, resume at 2N s (checks that rendering stops).
    var pauseTest: Double?
    /// `-character none|luna|capsule` (default: none for the experience, Luna for presets/tests).
    var character: String?
    /// `-mode postcard|aerial|explore|route|follow`: start in this camera mode.
    var mode: String?
    /// `-showcase NN`: experience-v1 showcase state 01…11 at its camera (screenshots).
    var showcase: String?
    /// `-weather ID`: a Demo weather preset (clear, cloudy, rain, storm, fog, smoke, snow, aftersnow).
    var weather: String?
    /// `-debughud`: keep the performance HUD under the experience UI.
    var debugHUD = false
    /// `-snapshot SECONDS`: SECONDS after the world is on screen, save a PNG of the RealityKit view to the
    /// app's Documents (`snapshot-realitykit-<name>.png`) and print `SNAPSHOT saved <file>`. For device
    /// screenshots (scripts/device_snapshots.sh). The web renderer has its own `-snapshot` (WebScreen).
    var snapshotSeconds: Double?
    /// `-snapshotname NAME`: the name in the file (default: showcase NN, the preset, the mode, or walk/postcard).
    var snapshotName: String?
    /// `-snapshotsource realitykit|compositor`: how the snapshot is taken (default: RealityKit's own capture).
    var snapshotSource: WorldRenderState.SnapshotSource = .realityKit

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
        dateOverride = value("-date").flatMap { ISO8601DateFormatter().date(from: $0) }
        switch value("-renderscale") {
        case "native": renderSettings.scale = nil
        case let v?: renderSettings.fixedScale = Double(v)
        case nil: break
        }
        if value("-calm") == "off" { renderSettings.calm = nil }
        if value("-host") == "renderer" { renderSettings.host = .realityRenderer }
        pauseTest = value("-pausetest").flatMap(Double.init)
        character = value("-character")
        mode = value("-mode")
        showcase = value("-showcase")
        weather = value("-weather")
        debugHUD = args.contains("-debughud")
        snapshotSeconds = value("-snapshot").flatMap(Double.init)
        snapshotName = value("-snapshotname")
        if value("-snapshotsource") == "compositor" { snapshotSource = .compositor }
    }

    /// The moment for this run: `-date`, else v2 summer noon for the noon preset, else the v2
    /// golden-hour fixture.
    func date(_ demo: DemoConfig) -> Date {
        dateOverride ?? (preset == "v2-04" ? demo.noonDate : demo.goldenDate)
    }
}

/// The walking character: DogWell's Luna (converted to USDZ, see scripts/convert-dog.sh) with her
/// walk clip when bundled, else (or for `kind: "capsule"`) a 0.65 m capsule stand-in. Origin at
/// the feet, facing +Z.
@MainActor
func makeCharacter(world: World, kind: String = "luna") async -> Entity {
    if kind != "capsule", let url = Bundle.main.url(forResource: "luna_light", withExtension: "usdz", subdirectory: "dog"),
       let dog = try? await Entity(contentsOf: url) {
        dog.name = "Luna"
        DogCoat.apply(to: dog, fill: world.shaderGlobals.fillSky)
        if let walk = dog.availableAnimations.first {
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

/// Luna's coat material (see DogCoat.metal): vertex-color coat + world fill + readability rim.
@MainActor
enum DogCoat {
    static let rimStrength: Float = 0.35

    static func apply(to dog: Entity, fill: SIMD3<Float>) {
        guard let device = MTLCreateSystemDefaultDevice(), let library = device.makeDefaultLibrary(),
              var coat = try? CustomMaterial(surfaceShader: .init(named: "dogCoatSurface", in: library), lightingModel: .lit) else { return }
        coat.custom.value = SIMD4(fill.x, fill.y, fill.z, rimStrength)
        func visit(_ e: Entity) {
            if var model = e.components[ModelComponent.self] {
                // The body part carries the coat colors; other parts keep their own materials.
                for m in model.mesh.contents.models { for part in m.parts where part.id == "luna_body" {
                    if part.materialIndex < model.materials.count { model.materials[part.materialIndex] = coat }
                } }
                e.components.set(model)
            }
            for c in e.children { visit(c) }
        }
        visit(dog)
    }
}
