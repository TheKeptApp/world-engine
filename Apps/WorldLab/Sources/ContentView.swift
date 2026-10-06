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
        /// Demo weather for a test run (gate: clear and rain).
        var weather: String? = nil
    }

    var body: some View {
        Group {
            if let s = session ?? options.renderer.map({ Session(renderer: $0, testRun: false) }) ?? (options.preset != nil ? Session(renderer: "realitykit", testRun: false) : nil) {
                if s.renderer == "realitykit" {
                    RealityKitScreen(options: options, testRun: s.testRun, testWeather: s.weather)
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
                    Button("Explore the world") { start(.init(renderer: renderer, testRun: false)) }
                    Button("10-minute test run, clear") { start(.init(renderer: renderer, testRun: true, weather: "clear")) }
                    Button("10-minute test run, rain") { start(.init(renderer: renderer, testRun: true, weather: "rain")) }
                } footer: {
                    Text("Test run: Luna walks the 985 m loop for 10 minutes at golden hour in Demo weather, at 50% screen brightness; frame times, heat, memory, battery, Low Power Mode and charging are logged to the app's Documents folder, then it stops.")
                }
            }
            .navigationTitle("WorldLab")
        }
    }
}

/// The RealityKit renderer: loads the demo area, walks the character along its loop and follows
/// it with the street camera, or (no preset, no test) opens the no-character experience: a composed
/// postcard with modes, a character switch, the weather strip and the time scrubber.
struct RealityKitScreen: View {
    let options: LaunchOptions
    let testRun: Bool
    var testWeather: String? = nil
    private let started = Date()
    @State private var world: World?
    @State private var camera: WorldCamera?
    @State private var env: EnvironmentController?
    @State private var demo: DemoConfig?
    @State private var error: String?
    @State private var metrics = Metrics()
    @State private var post = WorldPostProcess()
    @State private var test: TestRun?
    @State private var render = WorldRenderState()
    @State private var hostPaused = false
    @State private var mode = "postcard"
    @State private var characterChoice = "none"
    @State private var character: Entity?
    @State private var motion: WorldMotion?
    @State private var postcardIndex = 0
    @State private var showControls = true

    /// The experience UI (strip, scrubber, mode bar) shows outside presets, tests and showcase shots.
    private var experienceUI: Bool { options.preset == nil && !testRun && !options.metrics && options.showcase == nil && options.hud }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let world, let camera {
                framed {
                    WorldView(world: world, camera: camera, gesturesEnabled: options.preset == nil && options.showcase == nil,
                              post: options.diagnostics.contains("noPost") ? nil : post,
                              settings: options.renderSettings, renderState: render, isPaused: hostPaused) { dt in
                        let postMs = post.recentGPUms(1).last
                        metrics.frame(dt: dt, gpuMs: render.gpuFrameMs ?? postMs)
                        test?.frame(dt: dt, gpuMs: render.gpuFrameMs, postMs: postMs)
                    }
                }
                if options.hud && (!experienceUI || options.debugHUD) { HUD(metrics: metrics, world: world, test: test, render: render) }
                if experienceUI, let env {
                    experienceOverlay(env: env, world: world, camera: camera)
                }
            } else if let error {
                Text(error).foregroundStyle(.white).padding()
            } else {
                ProgressView("Building world…").tint(.white).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await load() }
        .task {
            guard ProcessInfo.processInfo.arguments.contains("-viewdiag") else { return }
            try? await Task.sleep(for: .seconds(8))
            ViewDiagnostics.dump(tag: "realitykit")
        }
        .task {
            // Console trace for checks: frame rate and display state once a second. Keeps the
            // screen awake for unattended device checks.
            guard ProcessInfo.processInfo.arguments.contains("-rendertrace") else { return }
            UIApplication.shared.isIdleTimerDisabled = true
            UIDevice.current.isBatteryMonitoringEnabled = true
            print("CONDITIONS \(TestRun.conditions())")
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Int(Date().timeIntervalSince(started)) % 10 == 0 { print("CONDITIONS \(TestRun.conditions())") }
                print(String(format: "RENDER t=%.0f fps=%.1f gpu=%@ %@", Date().timeIntervalSince(started), metrics.liveFPS(),
                             render.gpuFrameMs.map { String(format: "%.2f", $0) } ?? "-", render.summary))
            }
        }
        .task {
            // `-pausetest N`: the host pauses the view at N s and resumes it at 2N s.
            guard let n = options.pauseTest else { return }
            try? await Task.sleep(for: .seconds(n))
            hostPaused = true
            try? await Task.sleep(for: .seconds(n))
            hostPaused = false
        }
    }

    // MARK: Experience UI

    @ViewBuilder
    private func experienceOverlay(env: EnvironmentController, world: World, camera: WorldCamera) -> some View {
        VStack(spacing: 8) {
            if showControls { WeatherStrip(env: env).padding(.top, 4) }
            Spacer()
            if showControls {
                HStack(spacing: 8) {
                    Picker("Mode", selection: $mode) {
                        Text("Postcard").tag("postcard")
                        Text("Aerial").tag("aerial")
                        Text("Explore").tag("explore")
                        Text("Route").tag("route")
                        if character != nil { Text("Follow").tag("follow") }
                    }
                    .pickerStyle(.segmented)
                    Menu {
                        Section("Weather (Demo)") {
                            ForEach(env.presets) { p in
                                Button(p.title) { select(preset: p, env: env, world: world, camera: camera) }
                            }
                        }
                        Section("Character") {
                            Picker("Character", selection: $characterChoice) {
                                Text("None").tag("none")
                                Text("Luna").tag("luna")
                                Text("Capsule").tag("capsule")
                            }
                        }
                        if mode == "postcard", world.postcards.count > 1 {
                            Button("Next postcard") {
                                postcardIndex = (postcardIndex + 1) % world.postcards.count
                                camera.mode = .postcard(world.pose(of: world.postcards[postcardIndex]))
                            }
                        }
                        Button(showControls ? "Clean view" : "Show controls") { showControls.toggle() }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title2)
                    }
                    .accessibilityLabel("Weather, character and view options")
                }
                .padding(.horizontal, 10)
                TimeScrubber(env: env).padding(.bottom, 34)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !showControls {
                Button { showControls = true } label: { Image(systemName: "slider.horizontal.3").padding(10) }
                    .background(.ultraThinMaterial, in: Circle()).padding(.trailing, 12).padding(.top, 8)
            }
        }
        .onChange(of: mode) { _, m in apply(mode: m, world: world, camera: camera, env: env) }
        .onChange(of: characterChoice) { _, c in Task { await setCharacter(c, world: world, camera: camera) } }
    }

    private func select(preset p: EnvironmentController.Preset, env: EnvironmentController, world: World, camera: WorldCamera) {
        env.select(p)
        if let cam = p.camera, let pose = showcasePose(cam, world: world) {
            mode = cam == "aerial" ? "aerial" : "postcard"
            camera.mode = .postcard(pose)
        }
    }

    private func apply(mode m: String, world: World, camera: WorldCamera, env: EnvironmentController) {
        env.aerial = m == "aerial"
        switch m {
        case "aerial":
            if camera.aerial == nil { camera.aerial = world.makeAerialRig() }
            camera.mode = .aerial
        case "explore":
            camera.explore = world.makeExploreRig(from: currentPostcard(world: world))
            camera.mode = .explore
        case "route":
            if let demo { camera.route = world.makeRouteRig(route: demo.routeCoordinates, loop: true) }
            camera.mode = .route
        case "follow":
            if let character { camera.mode = .street(following: character) }
        default:
            camera.mode = .postcard(currentPostcard(world: world))
        }
        env.resolve()
    }

    private func currentPostcard(world: World) -> CameraPose {
        if world.postcards.indices.contains(postcardIndex) { return world.pose(of: world.postcards[postcardIndex]) }
        return CameraPose(eye: SIMD3(0, 1.65, 0), target: SIMD3(0, 1.4, -30), verticalFOVDegrees: 50)
    }

    private func showcasePose(_ name: String, world: World) -> CameraPose? {
        guard let c = demo?.showcase?.cameras[name] else { return nil }
        return world.pose(origin: GeoCoordinate(latitude: c.origin.lat, longitude: c.origin.lon), eye: c.position, target: c.target,
                          fieldOfViewDegrees: c.fovDegrees)
    }

    /// Character slot: none, Luna or the capsule, walking the demo loop.
    private func setCharacter(_ choice: String, world: World, camera: WorldCamera) async {
        if let old = character { world.remove(old) }
        character = nil
        motion = nil
        if case .street = camera.mode { mode = "postcard" }
        guard choice != "none", let demo else { return }
        let c = await makeCharacter(world: world, kind: choice)
        motion = world.move(c, along: demo.routeCoordinates, speed: demo.walkSpeed, loop: true)
        character = c
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
            self.demo = demo
            let dir = Bundle.main.url(forResource: demo.area, withExtension: nil)!
            let w = try await World.load(areaDirectory: dir, options: WorldOptions(
                focus: demo.focusBox, profileID: options.profile, date: options.date(demo), diagnostics: options.diagnostics))
            // Presets and test runs walk a character with the street camera (the matched-test
            // setup); the experience opens on a composed postcard with no character.
            let walking = options.preset != nil || testRun || options.metrics
            let choice = options.character ?? (walking ? "luna" : "none")
            var cam: WorldCamera
            if choice != "none" {
                let c = await makeCharacter(world: w, kind: choice)
                let m = w.move(c, along: demo.routeCoordinates, speed: demo.walkSpeed, loop: true)
                character = c
                motion = m
                characterChoice = choice
                cam = WorldCamera(mode: .street(following: c))
                Presets.apply(options.preset, demo: demo, world: w, camera: cam, motion: m, character: c)
                if !walking { cam.mode = .postcard(w.postcards.first.map(w.pose(of:)) ?? CameraPose(eye: SIMD3(0, 1.65, 0), target: SIMD3(0, 1.4, -30), verticalFOVDegrees: 50)) }
            } else {
                cam = WorldCamera(mode: .postcard(w.postcards.first.map(w.pose(of:)) ?? CameraPose(eye: SIMD3(0, 1.65, 0), target: SIMD3(0, 1.4, -30), verticalFOVDegrees: 50)))
            }
            cam.transitionSeconds = 0
            if ProcessInfo.processInfo.arguments.contains("-cutdebug") { w.shaderGlobals.debug = 2 }
            if ProcessInfo.processInfo.arguments.contains("-aodebug") { w.shaderGlobals.debug = 3 }

            // Environment: the time and Demo weather drive the light, sky, season and surfaces.
            let e = try EnvironmentController(demo: demo, world: w)
            if let id = options.showcase, let p = e.presets.first(where: { $0.id == "showcase-\(id)" }) {
                e.select(p)
                if let camName = p.camera, let c = demo.showcase?.cameras[camName] {
                    cam.mode = .postcard(w.pose(origin: GeoCoordinate(latitude: c.origin.lat, longitude: c.origin.lon), eye: c.position,
                                                target: c.target, fieldOfViewDegrees: c.fovDegrees))
                    e.aerial = camName == "aerial"
                    e.resolve()
                }
            } else {
                if let id = testWeather ?? options.weather, let p = e.presets.first(where: { $0.id == id }) { e.select(p) }
                if let t = options.dateOverride ?? (walking ? options.date(demo) : nil) { e.set(time: t) } else { e.goLive() }
            }
            if let m = options.mode { mode = m }
            metrics.start(world: w)
            if testRun || options.metrics {
                test = TestRun(renderer: "realitykit", stats: w.stats)
                let render = render
                test?.note = "weather=\(e.preset.id) character=\(choice)"
                test?.display = { String(format: "%.2f,%d", render.scale, render.framesPerSecond) }
                test?.begin()
            }
            let st = w.stats
            print("STATS profile=\(st.profileID) season=\(st.season) light=\(st.lightKeys) chunks=\(st.chunkCount) static=\(st.staticTriangles) props=\(st.propTriangles) trees=\(st.treeTriangles) instances=\(st.propInstances) draws=\(st.drawCalls) meshBytes=\(st.meshBytes) build=\(String(format: "%.2f", st.buildSeconds))s postcards=\(w.postcards.count) generated=\(st.generated)")
            world = w
            camera = cam
            env = e
            if let m = options.mode { apply(mode: m, world: w, camera: cam, env: e) }
            try? await Task.sleep(for: .milliseconds(600))
            cam.transitionSeconds = 1.2
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
            // v2: the fixture was set for a 0.65 m upright stand-in; fit the actual character's
            // projected bounds to the same 22% along the fixture's view direction.
            let o = SIMD3(f.streetCameraOffset[0], f.streetCameraOffset[1], f.streetCameraOffset[2])
            let t = SIMD3(f.streetTargetOffset[0], f.streetTargetOffset[1], f.streetTargetOffset[2])
            let dir = simd_normalize(o - t)
            let b = character.visualBounds(relativeTo: character)
            let d = b.isEmpty ? simd_length(o - t) : WorldCamera.fittedDistance(
                bounds: b, orientation: character.orientation, viewDirection: -dir, fieldOfViewDegrees: f.fovDegrees, fraction: 0.22)
            camera.mode = .fixed(position: anchor + t + dir * d, target: anchor + t, fieldOfViewDegrees: f.fovDegrees)
            print("FIXTURE character bounds \(b.extents) fitted distance \(d) m (fixture \(simd_length(o - t)) m)")
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
    let render: WorldRenderState

    var body: some View {
        let s = world.stats
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.0f fps  frame %.1f ms  gpu %.1f ms", metrics.fps, metrics.frameMs, metrics.gpuMs))
            Text("view \(s.viewTriangles / 1000)k tris  all \(s.triangles / 1000)k (trees \(s.treeTriangles / 1000)k)  draws \(s.drawCalls)")
            Text(String(format: "mem %.0f MB  mesh %.1f MB  %@", metrics.memoryMB, Double(s.meshBytes) / 1_048_576, metrics.thermal))
            Text(render.summary)
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
