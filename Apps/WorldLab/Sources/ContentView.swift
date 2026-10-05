import RealityKit
import SwiftUI
import WorldEngine

/// WorldLab root: a launcher (renderer switch, free walk, 10-minute test run) or, with launch
/// arguments, straight into a renderer/preset (used by scripts).
struct ContentView: View {
    private let options = LaunchOptions()
    @State private var session: Session?

    struct Session: Equatable {
        var renderer: String
        var testRun: Bool
    }

    var body: some View {
        Group {
            if let s = session ?? options.renderer.map({ Session(renderer: $0, testRun: false) }) ?? (options.preset != nil ? Session(renderer: "realitykit", testRun: false) : nil) {
                if s.renderer == "realitykit" {
                    RealityKitScreen(options: options, testRun: s.testRun)
                } else {
                    WebScreen(options: options, backend: s.renderer, testRun: s.testRun)
                }
            } else {
                LauncherView { session = $0 }
            }
        }
    }
}

/// Picks a renderer and a mode.
struct LauncherView: View {
    var start: (ContentView.Session) -> Void
    @State private var renderer = "realitykit"

    var body: some View {
        NavigationStack {
            Form {
                Section("Renderer") {
                    Picker("Renderer", selection: $renderer) {
                        Text("RealityKit").tag("realitykit")
                        Text("three.js WebGL2").tag("webgl2")
                        Text("three.js WebGPU").tag("webgpu")
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Button("Free walk") { start(.init(renderer: renderer, testRun: false)) }
                    Button("Start 10-minute test run") { start(.init(renderer: renderer, testRun: true)) }
                } footer: {
                    Text("Test run: walks the 985 m loop for 10 minutes at 50% screen brightness, logs frame times, heat, memory and battery to the app's Documents folder, then stops.")
                }
            }
            .navigationTitle("WorldLab")
        }
    }
}

/// The RealityKit renderer: loads the demo area, walks the character along its loop and follows
/// it with the street camera. Launch arguments pick screenshot presets and test options.
struct RealityKitScreen: View {
    let options: LaunchOptions
    let testRun: Bool
    @State private var world: World?
    @State private var camera: WorldCamera?
    @State private var error: String?
    @State private var metrics = Metrics()
    @State private var post = WorldPostProcess()
    @State private var test: TestRun?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let world, let camera {
                framed {
                    WorldView(world: world, camera: camera, gesturesEnabled: options.preset == nil,
                              post: options.diagnostics.contains("noPost") ? nil : post) { dt in
                        metrics.frame(dt: dt, gpuMs: post.recentGPUms(1).last)
                        test?.frame(dt: dt, gpuMs: post.recentGPUms(1).last)
                    }
                }
                if options.hud { HUD(metrics: metrics, world: world, test: test) }
            } else if let error {
                Text(error).foregroundStyle(.white).padding()
            } else {
                ProgressView("Building world…").tint(.white).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await load() }
    }

    /// Optionally letterboxes the view to 16:9 for comparison with the v2 target images.
    @ViewBuilder func framed<V: View>(@ViewBuilder _ v: () -> V) -> some View {
        let content = v()
        if options.frame16x9 {
            GeometryReader { geo in
                content.frame(width: geo.size.width, height: geo.size.width * 9 / 16)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .ignoresSafeArea()
        } else {
            content.ignoresSafeArea()
        }
    }

    private func load() async {
        do {
            let demo = try DemoConfig.load()
            let dir = Bundle.main.url(forResource: demo.area, withExtension: nil)!
            let w = try await World.load(areaDirectory: dir, options: WorldOptions(
                focus: demo.focusBox, profileID: options.profile, date: options.date(demo), diagnostics: options.diagnostics))
            let character = await makeCharacter()
            let motion = w.move(character, along: demo.routeCoordinates, speed: demo.walkSpeed, loop: true)
            w.contactEntity = character
            let cam = WorldCamera(mode: .street(following: character))
            Presets.apply(options.preset, demo: demo, world: w, camera: cam, motion: motion, character: character)
            if ProcessInfo.processInfo.arguments.contains("-cutdebug") { w.shaderGlobals.debug = 2 }
            if ProcessInfo.processInfo.arguments.contains("-aodebug") { w.shaderGlobals.debug = 3 }
            metrics.start(world: w)
            if testRun || options.metrics {
                test = TestRun(renderer: "realitykit", stats: w.stats)
                test?.begin()
            }
            let st = w.stats
            print("STATS profile=\(st.profileID) season=\(st.season) light=\(st.lightKeys) chunks=\(st.chunkCount) static=\(st.staticTriangles) props=\(st.propTriangles) trees=\(st.treeTriangles) instances=\(st.propInstances) draws=\(st.drawCalls) meshBytes=\(st.meshBytes) build=\(String(format: "%.2f", st.buildSeconds))s generated=\(st.generated)")
            world = w
            camera = cam
        } catch {
            self.error = "Failed to build world: \(error)"
        }
    }
}

/// Fixed camera setups for screenshots (`-preset NAME`). Loop positions are meters along the loop.
@MainActor
enum Presets {
    static func apply(_ name: String?, demo: DemoConfig, world: World, camera: WorldCamera, motion: WorldMotion, character: Entity) {
        guard let name else { return }
        camera.autoRecenter = false
        func stop(at meters: Double) {
            motion.seek(to: meters)
            motion.isPaused = true
        }
        let f = demo.fixtures
        switch name {
        case "v2-01", "v2-04":
            // v2 §6.2 street comparison: dog at the West 23rd Ave anchor looking west; camera
            // 2.6 m east, 1.25 m up, look-at 0.48 m over the dog, vertical FOV 50°.
            motion.isPaused = true
            let anchor = world.position(of: GeoCoordinate(latitude: f.streetAnchor.lat, longitude: f.streetAnchor.lon))
            world.place(character, at: GeoCoordinate(latitude: f.streetAnchor.lat, longitude: f.streetAnchor.lon))
            character.orientation = simd_quatf(angle: -.pi / 2, axis: [0, 1, 0]) // face west (−X)
            let o = f.streetCameraOffset, t = f.streetTargetOffset
            camera.mode = .fixed(position: anchor + SIMD3(o[0], o[1], o[2]), target: anchor + SIMD3(t[0], t[1], t[2]),
                                 fieldOfViewDegrees: f.fovDegrees)
        case "v2-06":
            stop(at: 150)
            let c = world.position(of: GeoCoordinate(latitude: f.aerialCenter.lat, longitude: f.aerialCenter.lon))
            let o = f.aerialCameraOffset
            camera.mode = .fixed(position: SIMD3(c.x, 0, c.z) + SIMD3(o[0], o[1], o[2]), target: SIMD3(c.x, 0, c.z), fieldOfViewDegrees: f.fovDegrees)
        case "street-mid":
            stop(at: 150)
            camera.absoluteYaw = .pi / 2 + 0.35
            camera.pitchOffset = -6
            camera.zoom = 2.5
        case "corner":
            stop(at: 255)
            camera.absoluteYaw = .pi / 4
            camera.zoom = 2.4
            camera.pitchOffset = -4
        case "lake-path":
            stop(at: 705)
            camera.absoluteYaw = -.pi / 4 - 0.25
            camera.zoom = 2.5
            camera.pitchOffset = -6
        case "tree-cutaway":
            var best: (meters: Double, yaw: Float)?
            for meters in stride(from: 20.0, to: 260.0, by: 1.0) {
                motion.seek(to: meters)
                let p = character.position(relativeTo: nil)
                let near = world.treePositions(near: p, radius: 5)
                let flat = { (t: SIMD3<Float>) in simd_distance(SIMD2(t.x, t.z), SIMD2(p.x, p.z)) }
                guard !near.contains(where: { flat($0) < 2.0 }), let tree = near.first(where: { flat($0) > 3.0 }) else { continue }
                let d = tree - p
                best = (meters, atan2(d.x, d.z))
                break
            }
            stop(at: best?.meters ?? 120)
            camera.absoluteYaw = best?.yaw
            camera.zoom = 1.8
            camera.pitchOffset = 4
        case "aerial-low":
            stop(at: 150)
            let c = world.position(of: world.coordinate(at: [242, 0, -40]))
            camera.mode = .overview(center: c, distance: 170, pitchDegrees: 36, yawDegrees: -50, fieldOfViewDegrees: 40)
        case "lineup":
            stop(at: 150)
            let origin = SIMD3<Float>(0, 0, 1500)
            let (_, entries) = world.footprintLineup(origin: origin)
            for e in entries { print("LINEUP \(e.label) | \(e.osmRef) | \(e.houseType) | \(e.footprintClass) | \(e.roofShape) | \(Int(e.area)) m² | \(Int(e.rectangularity * 100))%") }
            camera.mode = .overview(center: origin + [0, 0, 14], distance: 215, pitchDegrees: 55, yawDegrees: 0, fieldOfViewDegrees: 45)
        default:
            break
        }
    }
}

/// Debug overlay: frame rate, GPU time, triangles, draw calls, memory, thermal state.
struct HUD: View {
    let metrics: Metrics
    let world: World
    let test: TestRun?

    var body: some View {
        let s = world.stats
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.0f fps  frame %.1f ms  gpu %.1f ms", metrics.fps, metrics.frameMs, metrics.gpuMs))
            Text("view \(s.viewTriangles / 1000)k tris  all \(s.triangles / 1000)k (trees \(s.treeTriangles / 1000)k)  draws \(s.drawCalls)")
            Text(String(format: "mem %.0f MB  mesh %.1f MB  %@", metrics.memoryMB, Double(s.meshBytes) / 1_048_576, metrics.thermal))
            if let test { Text(test.statusLine) }
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .padding(6)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
        .padding(.top, 54)
        .padding(.leading, 8)
        .allowsHitTesting(false)
    }
}
