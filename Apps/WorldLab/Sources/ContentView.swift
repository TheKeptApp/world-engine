import RealityKit
import SwiftUI
import WorldEngine

/// WorldLab: loads the demo area, walks the stand-in along its loop and follows it with the
/// street camera. Launch arguments pick screenshot presets and test options.
struct ContentView: View {
    @State private var world: World?
    @State private var camera: WorldCamera?
    @State private var error: String?
    @State private var metrics = Metrics()
    @State private var lineup: [World.LineupEntry] = []
    private let options = LaunchOptions()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if let world, let camera {
                WorldView(world: world, camera: camera, gesturesEnabled: options.preset == nil) { dt in
                    metrics.frame(dt: dt, world: world)
                }
                if options.hud { HUD(metrics: metrics, world: world, instancing: options.instancing) }
            } else if let error {
                Text(error).padding()
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Building world…").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            let demo = try DemoConfig.load()
            let dir = Bundle.main.url(forResource: demo.area, withExtension: nil)!
            let w = try await World.load(areaDirectory: dir, options: WorldOptions(
                focus: demo.focusBox, profileID: options.profile, instancing: options.instancing, date: goldenHour,
                diagnostics: options.diagnostics))
            let standIn = makeStandIn()
            let motion = w.move(standIn, along: demo.routeCoordinates, speed: demo.walkSpeed, loop: true)
            let cam = WorldCamera(mode: .street(following: standIn))
            applyPreset(options.preset, world: w, camera: cam, motion: motion, standIn: standIn)
            if ProcessInfo.processInfo.arguments.contains("-shaderdebug") { w.shaderGlobals.debug = 1 }
            if ProcessInfo.processInfo.arguments.contains("-cutdebug") { w.shaderGlobals.debug = 2 }
            metrics.start(logging: options.metrics, world: w)
            // Keep the screen on during the timed walk test.
            if options.metrics { UIApplication.shared.isIdleTimerDisabled = true }
            let st = w.stats
            print("STATS profile=\(st.profileID) chunks=\(st.chunkCount) static=\(st.staticTriangles) props=\(st.propTriangles) instances=\(st.propInstances) draws=\(st.drawCalls) meshBytes=\(st.meshBytes) build=\(String(format: "%.2f", st.buildSeconds))s generated=\(st.generated)")
            world = w
            camera = cam
        } catch {
            self.error = "Failed to build world: \(error)"
        }
    }

    /// Fixed camera setups for screenshots (`-preset NAME`). Positions are meters along the loop.
    private func applyPreset(_ name: String?, world: World, camera: WorldCamera, motion: WorldMotion, standIn: Entity) {
        guard let name else { return }
        camera.autoRecenter = false
        func stop(at meters: Double) {
            motion.seek(to: meters)
            motion.isPaused = true
        }
        switch name {
        case "street-mid":
            stop(at: 150)                          // west sidewalk of Raleigh St, walking north
            camera.absoluteYaw = .pi / 2 + 0.35    // camera over the street (east), facing the houses
            camera.pitchOffset = -6
            camera.zoom = 2.5
        case "corner":
            stop(at: 255)                          // Raleigh St & W 23rd Ave
            camera.absoluteYaw = .pi / 4           // from the intersection (south-east), looking north-west
            camera.zoom = 2.4
            camera.pitchOffset = -4
        case "lake-path":
            stop(at: 705)                          // Sloan's Lake Trail
            camera.absoluteYaw = -.pi / 4 - 0.25   // camera south-west, over the shore, looking back north-east at the houses
            camera.zoom = 2.5
            camera.pitchOffset = -6
        case "tree-cutaway":
            // Find a spot on the loop with a tree 3–5 m from the stand-in (and none closer than
            // 2 m), then look at the stand-in through it from ~8 m back so the tree is midway.
            var best: (meters: Double, yaw: Float, tree: SIMD3<Float>)?
            for meters in stride(from: 20.0, to: 260.0, by: 1.0) {
                motion.seek(to: meters)
                let p = standIn.position(relativeTo: nil)
                let near = world.treePositions(near: p, radius: 5)
                let flat = { (t: SIMD3<Float>) in simd_distance(SIMD2(t.x, t.z), SIMD2(p.x, p.z)) }
                guard !near.contains(where: { flat($0) < 2.0 }),
                      let tree = near.first(where: { flat($0) > 3.0 }) else { continue }
                let d = tree - p
                best = (meters, atan2(d.x, d.z), tree)
                break
            }
            stop(at: best?.meters ?? 120)
            camera.absoluteYaw = best?.yaw
            camera.zoom = 1.8
            camera.pitchOffset = 4
            print("CUTAWAY meters=\(best?.meters ?? -1) standIn=\(standIn.position(relativeTo: nil)) tree=\(String(describing: best?.tree))")
        case "aerial-low":
            stop(at: 150)
            let c = world.position(of: world.coordinate(at: [242, 0, -40]))
            camera.mode = .overview(center: c, distance: 170, pitchDegrees: 36, yawDegrees: -50, fieldOfViewDegrees: 40)
        case "lineup":
            stop(at: 150)
            let origin = SIMD3<Float>(0, 0, 1500)
            let (_, entries) = world.footprintLineup(origin: origin)
            lineup = entries
            for e in entries { print("LINEUP \(e.label) | \(e.osmRef) | \(e.footprintClass) | \(e.roofShape) | \(Int(e.area)) m² | \(Int(e.rectangularity * 100))%") }
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
    let instancing: Bool

    var body: some View {
        let s = world.stats
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.0f fps  frame %.1f ms (max %.1f)", metrics.fps, metrics.frameMs, metrics.frameMaxMs))
            Text("tris \(s.triangles / 1000)k (+\(s.clutterInstances) tufts)  draws \(s.drawCalls)  \(instancing ? "instanced" : "merged")")
            Text(String(format: "mem %.0f MB  mesh %.1f MB  %@", metrics.memoryMB, Double(s.meshBytes) / 1_048_576, metrics.thermal))
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
