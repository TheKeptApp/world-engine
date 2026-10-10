import CoreGraphics
import RealityKit
import SwiftUI
import UIKit
import WorldEngine
import WorldGeo

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
    @State private var multisampling = true
    @State private var postcardSheet = false
    @State private var inspection: InspectionCamera?
    @State private var showCameraDebug = false

    /// The experience UI (strip, scrubber, mode bar) shows outside presets, tests and showcase shots.
    private var experienceUI: Bool { options.preset == nil && !testRun && !options.metrics && options.showcase == nil && options.hud }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let world, let camera {
                framed {
                    var view = WorldView(world: world, camera: camera, gesturesEnabled: inspection == nil && options.preset == nil && options.showcase == nil,
                                         post: options.diagnostics.contains("noPost") ? nil : post,
                                         settings: options.renderSettings, renderState: render, isPaused: hostPaused) { dt in
                        let postMs = post.recentGPUms(1).last
                        metrics.frame(dt: dt, gpuMs: render.gpuFrameMs ?? postMs)
                        test?.frame(dt: dt, gpuMs: render.gpuFrameMs, postMs: postMs)
                    }
                    let _ = view.multisampling = multisampling
                    view.overlay {
                        if inspection != nil {
                            InspectionGestures(
                                orbit: { delta in changeInspection(world: world, camera: camera) { $0.orbit(by: delta, ground: groundClearance(world)) } },
                                pan: { delta, height in changeInspection(world: world, camera: camera) { $0.pan(by: delta, viewportHeight: height, ground: groundClearance(world)) } },
                                zoom: { scale in changeInspection(world: world, camera: camera) { $0.zoom(by: scale, ground: groundClearance(world)) } })
                        }
                    }
                }
                if showCameraDebug, let inspection {
                    let ground = groundClearance(world)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(format: "Camera alt %.2f m · heading %.2f° · pitch %.2f°", inspection.altitude(ground: ground), inspection.heading, inspection.pitch))
                        Text(inspection.launchArgument(frame: world.frame, ground: ground))
                        Text("lat, lon, AGL m, heading°, pitch down°")
                    }
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.white)
                    .padding(8).background(.black.opacity(0.65)).padding(.top, 92).allowsHitTesting(false)
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
            metrics.logHitches = true
            print("CONDITIONS \(TestRun.conditions())")
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Int(Date().timeIntervalSince(started)) % 10 == 0 { print("CONDITIONS \(TestRun.conditions())") }
                print(String(format: "RENDER t=%.0f fps=%.1f gpu=%@ %@", Date().timeIntervalSince(started), metrics.liveFPS(),
                             render.gpuFrameMs.map { String(format: "%.2f", $0) } ?? "-", render.summary))
                // What the current view asks the GPU to draw (P3's look loop): frustum-tested
                // triangles and draw calls of the world (sky, stars and rain one draw each; characters
                // not counted), then the draw calls and triangles by category.
                if let w = world {
                    print(String(format: "VIEW t=%.0f triangles=%d draws=%d", Date().timeIntervalSince(started),
                                 w.stats.viewTriangles, w.stats.viewDrawCalls)
                          + " drawsplit[\(w.stats.viewDraws.summary)] trisplit[\(w.stats.viewTriangleSplit.summary)]")
                }
            }
        }
        .task {
            // `-attribution`: one feature off at a time (7 s each by default), for a GPU trace split by feature.
            // Phase starts are printed with absolute times to align with the trace.
            let args = ProcessInfo.processInfo.arguments
            guard let ai = args.firstIndex(of: "-attribution") else { return }
            // Phase length in seconds (`-attribution 40` leaves room for one 8 s trace per phase).
            let seconds = ai + 1 < args.count ? Double(args[ai + 1]) ?? 7 : 7
            while world == nil { try? await Task.sleep(for: .milliseconds(200)) }
            try? await Task.sleep(for: .seconds(14))
            guard let world else { return }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            @MainActor func phase(_ name: String, _ change: @MainActor () -> Void) async {
                change()
                print("ATTR \(name) \(iso.string(from: Date()))")
                try? await Task.sleep(for: .seconds(seconds))
            }
            // Every "off" phase sits between two "all" phases, so slow drift (heat, clocks) cancels.
            // Most decision-relevant first (the phone warms during the run).
            await phase("all1") {}
            await phase("noShadows") { world.set(.shadows, enabled: false) }
            await phase("all2") { world.set(.shadows, enabled: true) }
            // The live range comes from look.json (120 m); 60 m was the range before 7 Oct.
            let range = world.shadowRange
            await phase("shadow60") { world.setShadowDistance(60) }
            await phase("all3") { world.setShadowDistance(range) }
            await phase("shadow150") { world.setShadowDistance(150) }
            await phase("all4") { world.setShadowDistance(range) }
            await phase("noMSAA") { multisampling = false }
            await phase("all5") { multisampling = true }
            await phase("noFoliage") { world.set(.foliage, enabled: false) }
            await phase("all6") { world.set(.foliage, enabled: true) }
            // The previous material set-up (every tree and bush on the cut-away pipeline).
            await phase("cutDetail") { world.set(.opaqueDetail, enabled: false) }
            await phase("all7") { world.set(.opaqueDetail, enabled: true) }
            await phase("noSky") { world.set(.sky, enabled: false) }
            await phase("all8") { world.set(.sky, enabled: true) }
            // Surface detail includes the far crown shadows (one canopy-map sample on lawns and walks).
            await phase("noSurfaceDetail") { world.set(.surfaceDetail, enabled: false) }
            await phase("all9") { world.set(.surfaceDetail, enabled: true) }
            await phase("noPost") { post.settings.enabled = false }
            await phase("all10") { post.settings.enabled = true }
            await phase("noBuildings") { world.set(.buildings, enabled: false) }
            await phase("all11") { world.set(.buildings, enabled: true) }
            print("ATTR end \(iso.string(from: Date()))")
        }
        .task {
            // `-pantest` (launch with `-mode route`): scripted pan across the whole package (5A Batch 1): lawnmower rows 250 m apart
            // at street eye height, 30 m/s (see `panRig`); this task only logs: one PAN line per second with the
            // process footprint, the worst stream-upload frame and the stream counters.
            guard ProcessInfo.processInfo.arguments.contains("-pantest") else { return }
            while world == nil || camera == nil { try? await Task.sleep(for: .milliseconds(200)) }
            try? await Task.sleep(for: .seconds(8))
            guard let world, let camera else { return }
            let start = Date()
            print("PAN start lengthM=\(Int(camera.route?.length ?? 0))"); fflush(nil)
            while let r = camera.route, r.distance < r.length - 1, Date().timeIntervalSince(start) < 600 {
                try? await Task.sleep(for: .seconds(1))
                print(String(format: "PAN t=%.0f dist=%.0f mem=%.1f uploadMaxMs=%.3f ", Date().timeIntervalSince(start), camera.route?.distance ?? 0,
                             Double(World.physicalFootprint()) / 1_048_576, world.takeStreamFrameMaxMs()) + world.streamSummary)
                fflush(nil)
            }
            print("PAN done"); fflush(nil)
        }
        .task {
            // `-memreport`: the engine's MEMORY attribution line every 10 s (5A Batch 1, device runs).
            guard ProcessInfo.processInfo.arguments.contains("-memreport") else { return }
            while true {
                try? await Task.sleep(for: .seconds(10))
                if let world { print(world.memoryReport()); fflush(nil) }
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
        .task {
            guard let seconds = options.snapshotSeconds else { return }
            await saveSnapshot(after: seconds)
        }
        .task {
            // `-viewlist`: step through several views in one launch (P3's look loop).
            guard let list = options.viewList else { return }
            while world == nil, error == nil { try? await Task.sleep(for: .milliseconds(200)) }
            guard error == nil else { print("VIEWS failed: \(error ?? "")"); return }
            await runViewList(list)
        }
        .task { await PostcardExports.runLaunchArgument(source: { postcardSource }, failed: { error != nil }) }
    }

    /// The world, the current postcard pose, the environment and the on-screen grade (PostcardExport.swift).
    private var postcardSource: PostcardExports.Source? {
        guard let world, let camera, let env else { return nil }
        return .init(world: world, pose: PostcardExports.pose(camera: camera, fallback: currentPostcard(world: world)), env: env,
                     post: options.diagnostics.contains("noPost") ? nil : post.settings)
    }

    // MARK: Snapshot (`-snapshot SECONDS`)

    /// The name part of the snapshot's file: `-snapshotname`, else showcase NN, the preset or the mode, else
    /// walk (the street loop of tests) or postcard (the experience's opening view). File-name safe.
    private var snapshotLabel: String {
        let raw = options.snapshotName ?? options.showcase.map { "showcase-\($0)" } ?? options.preset ?? options.mode
            ?? ((testRun || options.metrics) ? "walk" : "postcard")
        return String(raw.map { $0.isASCII && ($0.isLetter || $0.isNumber || "-_.".contains($0)) ? $0 : "-" })
    }

    /// `-snapshot SECONDS`: once the world is on screen and has had SECONDS to settle, write a PNG of the
    /// RealityKit view to Documents as `snapshot-realitykit-<name>.png` (the web renderer's naming) and print
    /// `SNAPSHOT saved <file>`, or `SNAPSHOT failed ...`. scripts/device_snapshots.sh waits for that line and
    /// pulls the file; the view only (no HUD, controls or attribution overlay), see `WorldRenderState.snapshot`.
    private func saveSnapshot(after seconds: Double) async {
        func report(_ line: String) { print(line); fflush(nil) }
        UIApplication.shared.isIdleTimerDisabled = true // a screen that locks stops the rendering
        let name = "snapshot-realitykit-\(snapshotLabel).png"
        let file = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        try? FileManager.default.removeItem(at: file) // a run that fails must not leave an older capture under this name
        while world == nil, error == nil { try? await Task.sleep(for: .milliseconds(200)) }
        if let error { report("SNAPSHOT failed \(name): \(error)"); return }
        try? await Task.sleep(for: .seconds(seconds))
        var polls = 0 // the view attaches just after the first frames; matters only for very short waits (-snapshot 0)
        while !render.attached, polls < 50 { try? await Task.sleep(for: .milliseconds(200)); polls += 1 }

        // The capture comes back nil, or as one flat colour, when RealityKit could not read the view:
        // then the compositor's image of the view is the next best thing.
        func capture(_ source: WorldRenderState.SnapshotSource) async -> CGImage? {
            guard let image = await render.snapshot(source: source) else { report("SNAPSHOT \(source) capture returned nothing"); return nil }
            guard !Self.isOneColour(image) else { report("SNAPSHOT \(source) capture is one flat colour"); return nil }
            return image
        }
        var source = options.snapshotSource
        var image = await capture(source)
        if image == nil, source == .realityKit {
            source = .compositor
            report("SNAPSHOT trying the compositor instead")
            image = await capture(source)
        }
        guard let image, let png = UIImage(cgImage: image).pngData() else {
            report("SNAPSHOT failed \(name): no usable image (\(render.summary))")
            return
        }
        do {
            try png.write(to: file, options: .atomic)
        } catch let failure {
            report("SNAPSHOT failed \(name): \(failure)")
            return
        }
        report("SNAPSHOT source=\(source) size=\(image.width)x\(image.height) view=\(render.summary)")
        report("SNAPSHOT saved \(name)")
    }

    /// RealityKit's capture of the view (the compositor's if RealityKit returns nothing or one flat
    /// colour) as PNG data, or nil.
    private func capturePNG() async -> (data: Data, size: String, source: WorldRenderState.SnapshotSource)? {
        var polls = 0
        while !render.attached, polls < 50 { try? await Task.sleep(for: .milliseconds(200)); polls += 1 }
        for source in [options.snapshotSource, .compositor] {
            if let image = await render.snapshot(source: source), !Self.isOneColour(image), let png = UIImage(cgImage: image).pngData() {
                return (png, "\(image.width)x\(image.height)", source)
            }
        }
        return nil
    }

    /// The final accepted witness is saved; no unchecked extra snapshot follows the stability gate.

    // MARK: View list (`-viewlist`)

    /// `-viewlist FILE` / `-viewlist64 BASE64`: step through views in one launch (one area). Each view
    /// is set up in place from its own launch arguments (preset, showcase, weather, weatherspec,
    /// date, camera, mode, character), left to settle, then saved to Documents/views/<id>.png.
    /// Prints `VIEWREADY id=…` before the capture (a Simulator script can screenshot then instead)
    /// and `VIEWSHOT id=… file=… size=… triangles=… draws=…` after it, then `VIEWS done n=…`.
    private func runViewList(_ list: [ViewSpec]) async {
        guard let world, let camera, let env, let demo else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("views")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var done = 0
        for spec in list {
            let o = LaunchOptions(["WorldLab"] + spec.args)
            if let area = o.area, area != demo.area {
                print("VIEWSHOT id=\(spec.id) skipped: area \(area) needs its own launch"); fflush(nil); continue
            }
            guard ["off", "remove", "layered"].contains(o.foliageExperiment),
                  o.inspectionPose == nil || InspectionCamera.Input(o.inspectionPose!) != nil else {
                print("VIEWS failed: invalid foliage mode or inspection pose for \(spec.id)"); fflush(nil); return
            }
            let shippingAutoExposure = post.settings.autoExposure
            defer {
                if o.sceneReady {
                    post.captureFrames.end()
                    post.settings.autoExposure = shippingAutoExposure
                }
            }
            var captureSignature: String?
            var captureSize: String?
            await applyView(o, world: world, camera: camera, env: env, demo: demo)
            try? await Task.sleep(for: .seconds(options.viewSettle))
            if o.sceneReady {
                do {
                    guard !options.diagnostics.contains("noPost"), !spec.args.contains("-capturequality") else {
                        throw NSError(domain: "SceneReady", code: 4, userInfo: [NSLocalizedDescriptionKey: "SCENEREADY requires the Metal frame completion observer; noPost and offscreen capturequality are unsupported"])
                    }
                    try await world.awaitCaptureSceneCompletion()
                    // Capture-only deterministic gain: the unchanged composite kernel uses gain 1
                    // when autoExposure is false. Keep look grading; restore shipping policy on exit.
                    post.settings.autoExposure = false
                    post.captureFrames.begin()
                    let deadline = Date().addingTimeInterval(30)
                    while post.captureFrames.proof() == nil {
                        try Task.checkCancellation()
                        if let failure = post.captureFrames.failure { throw NSError(domain: "SceneReady", code: 5, userInfo: [NSLocalizedDescriptionKey: failure]) }
                        if Date() >= deadline { throw NSError(domain: "SceneReady", code: 6, userInfo: [NSLocalizedDescriptionKey: "Stable submitted frames timed out (paused, unattached or moving view)"]) }
                        try await Task.sleep(for: .milliseconds(20))
                    }
                    guard let proof = post.captureFrames.proof() else {
                        throw NSError(domain: "SceneReady", code: 7, userInfo: [NSLocalizedDescriptionKey: "Scene changed at readiness boundary"])
                    }
                    captureSignature = proof.signature
                    captureSize = "\(proof.width)x\(proof.height)"
                    let signature = Data(proof.signature.utf8).base64EncodedString()
                    print(world.memoryReport()); fflush(nil)
                    print("SCENEREADY id=\(spec.id) context=\(world.captureSceneState == .notRequired ? "not-required" : "ready") exposure=pinned-1 gpuCompleted=\(proof.sequence) stableFrames=\(proof.stableFrames) size=\(proof.width)x\(proof.height) signature=\(signature)"); fflush(nil)
                } catch {
                    post.captureFrames.end()
                    print("VIEWS failed: SCENEREADY id=\(spec.id): \(error)"); fflush(nil); return
                }
            }
            print("VIEWREADY id=\(spec.id)"); fflush(nil)
            if options.viewHold > 0 { try? await Task.sleep(for: .seconds(options.viewHold)) }
            let file = dir.appendingPathComponent("\(spec.id).png")
            try? FileManager.default.removeItem(at: file)
            // `-capturequality`: the postcard quality-mode render of this view instead (PostcardExport.swift).
            let shot: (data: Data, size: String, source: String)?
            if spec.args.contains("-capturequality") {
                shot = await PostcardExports.qualityCapture(world: world, camera: camera, size: render.drawableSize,
                                                            post: options.diagnostics.contains("noPost") ? nil : post.settings)
            } else {
                shot = await capturePNG().map { (data: $0.data, size: $0.size, source: "\($0.source)") }
            }
            guard let shot else { print("VIEWSHOT id=\(spec.id) failed: no image"); fflush(nil); continue }
            if o.sceneReady, (post.captureFrames.proof()?.signature != captureSignature || shot.size != captureSize) {
                print("VIEWS failed: scene changed during capture id=\(spec.id)"); fflush(nil); return
            }
            do { try shot.data.write(to: file, options: .atomic) } catch {
                print("VIEWSHOT id=\(spec.id) failed: \(error)"); fflush(nil); continue
            }
            print("VIEWSHOT id=\(spec.id) file=views/\(spec.id).png size=\(shot.size) source=\(shot.source) triangles=\(world.stats.viewTriangles) draws=\(world.stats.viewDrawCalls) \(render.summary) drawsplit[\(world.stats.viewDraws.summary)] \(world.stats.shadowSummary)")
            fflush(nil)
            done += 1
        }
        print("VIEWS done n=\(done) of \(list.count)"); fflush(nil)
    }

    /// `-pantest` route (5A Batch 1): lawnmower rows 250 m apart over the whole package, 50 m in from
    /// the edges, at the route rig's street eye height and 30 m/s (test speed). Set at launch only:
    /// changing the camera route mid-session re-runs the RealityView update, which traps on device.
    static func panRig(_ world: World) -> RouteRig {
        let b = world.manifest.localBounds, margin = 50.0
        var rows: [LocalPoint] = []
        var y = b.min.y + margin, flip = false
        while y <= b.max.y - margin {
            let a = LocalPoint(b.min.x + margin, y), c = LocalPoint(b.max.x - margin, y)
            rows += flip ? [c, a] : [a, c]
            flip.toggle(); y += 250
        }
        var motion = ExperienceDefaults.Motion()
        motion.routeMaxSpeed = 30
        var rig = RouteRig(path: rows, loop: false, motion: motion)
        rig.scenicSpeed = 30
        return rig
    }

    /// Sets one view up in place, as a launch with these options would (same area).
    private func applyView(_ o: LaunchOptions, world: World, camera: WorldCamera, env: EnvironmentController, demo: DemoConfig) async {
        print("FOLIAGE_EXP1 mode=\(o.foliageExperiment) value=\(["off", "remove", "layered"].firstIndex(of: o.foliageExperiment) ?? 0) defaultConstant=0 buildTimeVariant=true slots=3-6,24-28"); fflush(nil)
        inspection = nil
        camera.transitionSeconds = 0
        camera.autoRecenter = true
        camera.absoluteYaw = nil
        camera.yawOffset = 0
        camera.pitchOffset = 0
        camera.zoom = 1
        world.lookTuning = o.tune ?? World.LookTuning()
        // Character: presets walk Luna (the matched-test setup); other views have none unless asked.
        let wanted = demo.route.isEmpty ? "none" : (o.character ?? (o.preset != nil ? "luna" : "none"))
        if wanted != characterChoice {
            await setCharacter(wanted, world: world, camera: camera)
            characterChoice = wanted
        }
        motion?.isPaused = false
        if let id = o.showcase, let p = env.presets.first(where: { $0.id == "showcase-\(id)" }) {
            select(preset: p, env: env, world: world, camera: camera)
            env.aerial = p.camera == "aerial"
            env.resolve()
            return
        }
        env.select(env.presets.first { $0.id == (o.weather ?? "clear") } ?? env.presets[0])
        if let spec = o.weatherSpec { env.select(.init(id: "custom", title: "Custom", weather: spec)) }
        if let t = o.dateOverride ?? (o.preset != nil ? o.date(demo) : nil) { env.set(time: t) } else { env.goLive() }
        env.aerial = false
        if let preset = o.preset, let c = character, let m = motion {
            camera.mode = .street(following: c)
            Presets.apply(preset, demo: demo, world: world, camera: camera, motion: m, character: c)
        } else if let spec = o.cameraSpec(demo) {
            camera.mode = .postcard(Self.pose(spec, world: world))
            env.aerial = spec.distance != nil || (spec.height ?? 1.65) > 60
        } else if let m = o.mode {
            mode = m
            apply(mode: m, world: world, camera: camera, env: env)
        } else {
            camera.mode = .postcard(currentPostcard(world: world))
        }
        if let text = o.inspectionPose, let input = InspectionCamera.Input(text) {
            mode = "aerial"; env.aerial = true
            startInspection(world: world, camera: camera, from: defaultInspectionPose(world: world))
            changeInspection(world: world, camera: camera) { $0.set(input, frame: world.frame, ground: groundClearance(world)) }
        }
        showCameraDebug = o.cameraDebug
        env.resolve()
    }

    /// True when a 16×16 reduction of the image has no more than one level of difference between any two samples.
    /// A real render of the world never does; a capture that failed quietly (all black) does.
    private static func isOneColour(_ image: CGImage) -> Bool {
        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(data: raw.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return false }
        var low = 255, high = 0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            for channel in 0..<3 { low = min(low, Int(pixels[i + channel])); high = max(high, Int(pixels[i + channel])) }
        }
        return high - low <= 1
    }

    // MARK: Experience UI

    @ViewBuilder
    private func experienceOverlay(env: EnvironmentController, world: World, camera: WorldCamera) -> some View {
        VStack(spacing: 8) {
            if showControls { WeatherStrip(env: env).padding(.top, 4) }
            Spacer()
            if showControls {
                HStack(spacing: 8) {
                    Picker("Mode", selection: Binding(get: { mode }, set: { next in
                        mode = next
                        apply(mode: next, world: world, camera: camera, env: env)
                    })) {
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
                        Button("Reset view") {
                            mode = "aerial"
                            startInspection(world: world, camera: camera, from: defaultInspectionPose(world: world))
                        }
                        Menu("Debug") {
                            Toggle("Camera pose", isOn: $showCameraDebug)
                            if let inspection {
                                Button("Copy camera launch argument") {
                                    UIPasteboard.general.string = "-inspectionpose " + inspection.launchArgument(frame: world.frame, ground: groundClearance(world))
                                }
                            }
                        }
                        Button("Export postcard") { postcardSheet = true }
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
        .sheet(isPresented: $postcardSheet) { PostcardExportSheet(source: postcardSource) }
        .onChange(of: characterChoice) { _, c in Task { await setCharacter(c, world: world, camera: camera) } }
    }

    private func select(preset p: EnvironmentController.Preset, env: EnvironmentController, world: World, camera: WorldCamera) {
        inspection = nil
        env.select(p)
        if let cam = p.camera, let pose = showcasePose(cam, world: world) {
            mode = cam == "aerial" ? "aerial" : "postcard"
            camera.mode = .postcard(pose)
            if cam == "aerial" { startInspection(world: world, camera: camera, from: pose) }
        }
    }

    private func apply(mode m: String, world: World, camera: WorldCamera, env: EnvironmentController) {
        env.aerial = m == "aerial"
        inspection = nil
        switch m {
        case "aerial":
            startInspection(world: world, camera: camera, from: defaultInspectionPose(world: world))
        case "explore":
            // Explore is also a free inspection camera; the same altitude safety applies.
            startInspection(world: world, camera: camera, from: currentPostcard(world: world))
        case "route":
            if ProcessInfo.processInfo.arguments.contains("-pantest") { camera.route = Self.panRig(world) }
            else if let demo { camera.route = world.makeRouteRig(route: demo.routeCoordinates, loop: true) }
            camera.mode = .route
        case "follow":
            if let character { camera.mode = .street(following: character) }
        default:
            camera.mode = .postcard(currentPostcard(world: world))
        }
        env.resolve()
    }

    private func defaultInspectionPose(world: World) -> CameraPose {
        world.makeAerialRig()?.pose ?? currentPostcard(world: world)
    }

    /// Existing rendered terrain is flat. Use a conservative upper bound of each ground mesh,
    /// including the existing curb-height allowance; no collision/shader changes.
    private func groundClearance(_ world: World) -> (SIMD2<Double>) -> Double {
        var surfaces: [BoundingBox] = []
        func visit(_ entity: Entity) {
            if entity.name.hasSuffix(" ground") || entity.name == "Boundary ground" {
                let bounds = entity.visualBounds(relativeTo: nil)
                if !bounds.isEmpty { surfaces.append(bounds) }
            }
            for child in entity.children { visit(child) }
        }
        visit(world.rootEntity)
        return { p in
            surfaces.filter { Double($0.min.x) <= p.x && p.x <= Double($0.max.x) && Double($0.min.z) <= -p.y && -p.y <= Double($0.max.z) }
                .map { Double($0.max.y) }.max() ?? 0
        }
    }

    private func startInspection(world: World, camera: WorldCamera, from pose: CameraPose) {
        inspection = InspectionCamera(pose: pose, defaultPose: defaultInspectionPose(world: world), bounds: world.manifest.localBounds, ground: groundClearance(world))
        camera.transitionSeconds = 0
        camera.moveInput = .zero; camera.turnInput = 0
        if let inspection { camera.mode = .postcard(inspection.pose) }
    }

    private func changeInspection(world: World, camera: WorldCamera, change: (inout InspectionCamera) -> Void) {
        guard var next = inspection else { return }
        change(&next)
        inspection = next
        camera.transitionSeconds = 0
        camera.mode = .postcard(next.pose)
        camera.userDidInteract()
        print("CAMERA -inspectionpose \(next.launchArgument(frame: world.frame, ground: groundClearance(world)))")
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
            guard let foliageMode = ["off", "remove", "layered"].firstIndex(of: options.foliageExperiment) else {
                throw NSError(domain: "WorldLab", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid -foliageexp1: expected off, remove or layered"])
            }
            if let text = options.inspectionPose, InspectionCamera.Input(text) == nil {
                throw NSError(domain: "WorldLab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid -inspectionpose: expected lat,lon,alt,heading,pitch; pitch 5–85° down"])
            }
            guard var demo = try DemoConfig.load().forArea(options.area) else {
                self.error = "Unknown area \(options.area ?? "") (demo.json areas)"
                return
            }
            if let f = options.focus { demo.focus = f }
            self.demo = demo
            guard let dir = Bundle.main.url(forResource: demo.area, withExtension: nil) else {
                self.error = "Area \(demo.area) is not bundled"
                return
            }
            let w = try await World.load(areaDirectory: dir, options: WorldOptions(
                focus: demo.focusBox, profileID: options.profile ?? demo.defaultProfile, date: options.date(demo), diagnostics: options.diagnostics))
            print("FOLIAGE_EXP1 mode=\(options.foliageExperiment) value=\(foliageMode) defaultConstant=0 buildTimeVariant=true slots=3-6,24-28")
            fflush(nil)
            // Presets and test runs walk a character with the street camera (the matched-test
            // setup); the experience opens on a composed postcard with no character. Only the
            // demo's own area has a walking loop.
            let walking = demo.isDemoArea && (options.preset != nil || testRun || options.metrics)
            let choice = demo.route.isEmpty ? "none" : (options.character ?? (walking ? "luna" : "none"))
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
            if let t = options.tune { w.lookTuning = t }
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
                if let spec = options.weatherSpec { e.select(.init(id: "custom", title: "Custom", weather: spec)) }
                if let t = options.dateOverride ?? (walking ? options.date(demo) : nil) { e.set(time: t) } else { e.goLive() }
            }
            // `-camera`: a named or explicit fixed view (P3's look loop, P2's areas).
            if let spec = options.cameraSpec(demo) {
                cam.mode = .postcard(Self.pose(spec, world: w))
                e.aerial = spec.distance != nil || (spec.height ?? 1.65) > 60
                e.resolve()
            } else if options.camera != nil {
                self.error = "Unknown camera \(options.camera ?? "") for \(demo.area)"
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
            showCameraDebug = options.cameraDebug
            if let text = options.inspectionPose {
                guard let input = InspectionCamera.Input(text) else {
                    throw NSError(domain: "WorldLab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid -inspectionpose: expected lat,lon,alt,heading,pitch; pitch 5–85° down"])
                }
                mode = "aerial"
                e.aerial = true
                e.resolve()
                startInspection(world: w, camera: cam, from: defaultInspectionPose(world: w))
                changeInspection(world: w, camera: cam) { $0.set(input, frame: w.frame, ground: groundClearance(w)) }
            }
            try? await Task.sleep(for: .milliseconds(600))
            cam.transitionSeconds = 1.2
        } catch {
            self.error = "Failed to build world: \(error)"
        }
    }
}

extension RealityKitScreen {
    /// The world pose of a named or explicit camera: standing at lat/lon (eye `height` m up), or
    /// orbiting the ground point from `distance` m, looking along heading/pitch.
    @MainActor
    static func pose(_ c: DemoConfig.NamedCamera, world w: World) -> CameraPose {
        let heading = c.heading * .pi / 180, pitch = (c.pitchDown ?? 3) * .pi / 180
        // Scene axes: east +X, up +Y, north −Z.
        let f = SIMD3(sin(heading) * cos(pitch), -sin(pitch), -cos(heading) * cos(pitch))
        let origin = GeoCoordinate(latitude: c.lat, longitude: c.lon)
        let eye = c.distance.map { -f * $0 } ?? SIMD3(0, c.height ?? 1.65, 0)
        let target = c.distance == nil ? eye + f * 30 : SIMD3<Double>(0, 0, 0)
        return w.pose(origin: origin, eye: [eye.x, eye.y, eye.z], target: [target.x, target.y, target.z],
                      fieldOfViewDegrees: c.fov ?? 50)
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
            // RealityKit gives no whole-frame GPU time (gpuFrameMs is nil), so the figure is the
            // post-processing pass alone: label it, or it reads as the frame's GPU cost.
            Text(String(format: "%.0f fps  frame %.1f ms  %@ %.1f ms", metrics.fps, metrics.frameMs,
                        render.gpuFrameMs == nil ? "post pass" : "gpu", metrics.gpuMs))
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

/// One view of a `-viewlist` run: an id and the launch arguments that set it up (P3's views.json entries).
struct ViewSpec: Decodable, Sendable {
    var id: String
    var args: [String]
}
