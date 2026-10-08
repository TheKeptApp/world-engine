import Metal
import Foundation
import RealityKit
import WorldEngine
import WorldEnvironment

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
    /// A camera by name (`-camera NAME`): standing at lat/lon with the eye `height` m up, looking
    /// along `heading` (clockwise from north) `pitchDown` degrees below level; with `distance` it
    /// orbits instead: it looks at lat/lon (on the ground) from that slant distance.
    struct NamedCamera: Decodable {
        var lat: Double
        var lon: Double
        var height: Double?
        var heading: Double
        var pitchDown: Double?
        var fov: Double?
        var distance: Double?
    }
    /// Another bundled area (`-area ID`): Data/areas/<id> with its focus box, style profile, local
    /// time zone, phenology, place label and named cameras. No walking loop or showcase.
    struct Area: Decodable {
        var focus: Box
        var profile: String?
        var locationLabel: String?
        var timeZone: String?
        var phenology: String?
        var cameras: [String: NamedCamera]?
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
    /// Named cameras of this area (`-camera NAME`).
    var cameras: [String: NamedCamera]?
    /// The other bundled areas, by id.
    var areas: [String: Area]?
    /// The area's style profile when `-profile` isn't given (nil: chosen by location).
    var defaultProfile: String?
    /// True for the demo's own area (Sloan's Lake): presets, the walking loop and the showcase.
    var isDemoArea = true

    /// The config for `-area ID`: the demo itself for nil or its own id, else that area (nil if
    /// unknown).
    func forArea(_ id: String?) -> DemoConfig? {
        guard let id, id != area else { return self }
        guard let a = areas?[id] else { return nil }
        var c = self
        c.area = id
        c.focus = a.focus
        c.locationLabel = a.locationLabel
        c.timeZone = a.timeZone
        c.phenology = a.phenology
        c.defaultProfile = a.profile
        c.cameras = a.cameras
        c.route = []
        c.showcase = nil
        c.isDemoArea = false
        return c
    }

    private enum CodingKeys: String, CodingKey {
        case area, focus, walkSpeed, route, fixtures, locationLabel, timeZone, phenology, showcase, cameras, areas
    }

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
    /// `-renderscale native|policy|<number>`: display settings (default: the shared policy).
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
    /// `-inspectionpose lat,lon,alt,heading,pitch`: AGL metres, degrees clockwise from north / down.
    var inspectionPose: String?
    var cameraDebug = false
    /// `-snapshot SECONDS`: SECONDS after the world is on screen, save a PNG of the RealityKit view to the
    /// app's Documents (`snapshot-realitykit-<name>.png`) and print `SNAPSHOT saved <file>`. For device
    /// screenshots (scripts/device_snapshots.sh). The web renderer has its own `-snapshot` (WebScreen).
    var snapshotSeconds: Double?
    /// `-snapshotname NAME`: the name in the file (default: showcase NN, the preset, the mode, or walk/postcard).
    var snapshotName: String?
    /// `-snapshotsource realitykit|compositor`: how the snapshot is taken (default: RealityKit's own capture).
    var snapshotSource: WorldRenderState.SnapshotSource = .realityKit
    /// `-area ID`: open another bundled area (demo.json `areas`; default: the demo's own area).
    var area: String?
    /// `-camera NAME` (the area's named cameras) or `-camera lat,lon,heading,pitchDown,fov`
    /// (eye 1.65 m) or `-camera lat,lon,height,heading,pitchDown,fov`: a fixed view.
    var camera: String?
    /// `-focus south,west,north,east`: the box that gets full street detail.
    var focus: DemoConfig.Box?
    /// `-weatherspec label=rain,intensity=0.5,cloud=0.8,rate=2,wetness=0.7,swe=0,visibility=…,wind=…`:
    /// explicit Demo weather (overrides `-weather`).
    var weatherSpec: SyntheticWeather?
    /// `-tune key=0.8,fill=1.6,ground=1.5,ibl=0.3,target=0.02,sat=0.9,contrast=1`: look tuning on
    /// top of the profiles (`World.LookTuning`), for sweeps on a device.
    var tune: World.LookTuning?
    /// `-viewlist FILE` (JSON array of {"id", "args"}) or `-viewlist64 BASE64` (the same JSON):
    /// step through views in one launch, saving each frame (see `RealityKitScreen.runViewList`).
    var viewList: [ViewSpec]?
    /// `-viewsettle SECONDS`: wait after setting each view up (default 4).
    var viewSettle: Double = 4
    /// `-viewhold SECONDS`: wait this long after `VIEWREADY` before capturing and moving on, so an
    /// outside screenshot (simctl io, with the letterbox and the OSM credit) lands on the same view.
    var viewHold: Double = 0

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
        pauseTest = value("-pausetest").flatMap(Double.init)
        character = value("-character")
        mode = value("-mode")
        showcase = value("-showcase")
        weather = value("-weather")
        debugHUD = args.contains("-debughud")
        inspectionPose = value("-inspectionpose")
        cameraDebug = args.contains("-cameradebug")
        snapshotSeconds = value("-snapshot").flatMap(Double.init)
        snapshotName = value("-snapshotname")
        if value("-snapshotsource") == "compositor" { snapshotSource = .compositor }
        area = value("-area")
        camera = value("-camera")
        if let f = value("-focus")?.split(separator: ",").compactMap({ Double($0) }), f.count == 4 {
            focus = DemoConfig.Box(south: f[0], west: f[1], north: f[2], east: f[3])
        }
        weatherSpec = value("-weatherspec").flatMap(Self.weather(spec:))
        tune = value("-tune").map(Self.tuning(spec:))
        let listData = value("-viewlist").flatMap { FileManager.default.contents(atPath: $0) }
            ?? value("-viewlist64").flatMap { Data(base64Encoded: $0) }
        viewList = listData.flatMap { try? JSONDecoder().decode([ViewSpec].self, from: $0) }
        viewSettle = value("-viewsettle").flatMap(Double.init) ?? 4
        viewHold = value("-viewhold").flatMap(Double.init) ?? 0
    }

    /// Parses `label=rain,intensity=0.5,cloud=0.8,rate=2,wetness=0.7,swe=6,visibility=1200,wind=4`.
    static func weather(spec: String) -> SyntheticWeather? {
        var v: [String: String] = [:]
        for part in spec.split(separator: ",") {
            let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2 { v[kv[0]] = kv[1] }
        }
        guard let label = v["label"].flatMap(DominantState.init(rawValue:)) else { return nil }
        let d = { (k: String) in v[k].flatMap(Double.init) }
        return SyntheticWeather(label: label, intensity: d("intensity"), cloudFraction: d("cloud") ?? 0.5,
                                precipitationMmPerHour: d("rate") ?? 0, visibilityM: d("visibility"), windSpeedMps: d("wind") ?? 3,
                                wetness: d("wetness") ?? 0, snowWaterEquivalentMm: d("swe") ?? 0)
    }

    /// Parses `-tune` (unknown keys are ignored).
    static func tuning(spec: String) -> World.LookTuning {
        var t = World.LookTuning()
        for part in spec.split(separator: ",") {
            let kv = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard kv.count == 2, let v = Float(kv[1]) else { continue }
            switch kv[0] {
            case "key": t.key = v
            case "fill": t.fill = v
            case "ground": t.groundFill = v
            case "ibl": t.iblEV = v
            case "target": t.exposureTarget = v
            case "sat": t.saturation = v
            case "contrast": t.contrast = v
            default: break
            }
        }
        return t
    }

    /// A fixed view from `-camera`: the area's named camera, or explicit numbers.
    func cameraSpec(_ demo: DemoConfig) -> DemoConfig.NamedCamera? {
        guard let camera else { return nil }
        let n = camera.split(separator: ",").compactMap { Double($0) }
        switch n.count {
        case 5: return .init(lat: n[0], lon: n[1], height: 1.65, heading: n[2], pitchDown: n[3], fov: n[4])
        case 6: return .init(lat: n[0], lon: n[1], height: n[2], heading: n[3], pitchDown: n[4], fov: n[5])
        default: return demo.cameras?[camera]
        }
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
