import Foundation
import RealityKit
import SwiftUI
import WorldEngine

/// Launch arguments (all optional):
///   -area NAME          bundled area folder (default sloans-lake)
///   -profile ID         style profile override
///   -date ISO8601       e.g. 2026-10-22T20:00:00Z (default now)
///   -focus S,W,N,E      full-detail box (default: whole area)
///   -look LAT,LON,H,HEADING,PITCH,FOV   fixed street camera
///   -overview LAT,LON,DIST,PITCH,YAW,FOV   overview camera
///   -frame16x9          letterbox the world view to 16:9
struct LaunchArgs {
    private let args = ProcessInfo.processInfo.arguments

    func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    func numbers(_ key: String, count: Int) -> [Double]? {
        guard let s = value(key) else { return nil }
        let n = s.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        return n.count == count ? n : nil
    }

    var area: String { value("-area") ?? "sloans-lake" }
    var profile: String? { value("-profile") }
    var frame16x9: Bool { args.contains("-frame16x9") }
    var date: Date {
        guard let s = value("-date") else { return Date() }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? Date()
    }
    var focus: GeoBoundingBox? {
        guard let n = numbers("-focus", count: 4) else { return nil }
        return GeoBoundingBox(south: n[0], west: n[1], north: n[2], east: n[3])
    }
}

struct ContentView: View {
    private let launch = LaunchArgs()
    @State private var world: World?
    @State private var camera: WorldCamera?
    @State private var error: String?
    @State private var post = WorldPostProcess()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let world, let camera {
                framed {
                    WorldView(world: world, camera: camera, gesturesEnabled: false, post: post)
                }
            } else if let error {
                Text(error).foregroundStyle(.white).padding()
            } else {
                ProgressView("Building world…").tint(.white).foregroundStyle(.white)
            }
        }
        .task { await load() }
    }

    @ViewBuilder func framed<V: View>(@ViewBuilder _ v: () -> V) -> some View {
        let content = v()
        if launch.frame16x9 {
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
            guard let dir = Bundle.main.url(forResource: launch.area, withExtension: nil) else {
                error = "Area \"\(launch.area)\" is not bundled."
                print("BUILDINGLAB ERROR area not bundled: \(launch.area)")
                return
            }
            let w = try await World.load(areaDirectory: dir, options: WorldOptions(
                focus: launch.focus, profileID: launch.profile, date: launch.date))
            let cam = WorldCamera(mode: Self.cameraMode(launch, world: w))
            let st = w.stats
            print("BUILDINGLAB STATS area=\(launch.area) profile=\(st.profileID) season=\(st.season) light=\(st.lightKeys) chunks=\(st.chunkCount) static=\(st.staticTriangles) props=\(st.propTriangles) trees=\(st.treeTriangles) instances=\(st.propInstances) draws=\(st.drawCalls) meshBytes=\(st.meshBytes) build=\(String(format: "%.2f", st.buildSeconds))s generated=\(st.generated)")
            world = w
            camera = cam
            print("BUILDINGLAB READY")
        } catch {
            self.error = "Failed to build world: \(error)"
            print("BUILDINGLAB ERROR \(error)")
        }
    }

    /// -look / -overview, falling back to an overview of the area centre.
    static func cameraMode(_ a: LaunchArgs, world w: World) -> WorldCamera.Mode {
        if let n = a.numbers("-look", count: 6) {
            var eye = w.position(of: GeoCoordinate(latitude: n[0], longitude: n[1]))
            eye.y += Float(n[2])
            let heading = Float(n[3]) * .pi / 180, pitch = Float(n[4]) * .pi / 180
            // East +X, up +Y, north -Z; heading clockwise from north.
            let dir = SIMD3<Float>(sin(heading) * cos(pitch), sin(pitch), -cos(heading) * cos(pitch))
            return .fixed(position: eye, target: eye + dir * 30, fieldOfViewDegrees: Float(n[5]))
        }
        if let n = a.numbers("-overview", count: 6) {
            var c = w.position(of: GeoCoordinate(latitude: n[0], longitude: n[1]))
            c.y = 0
            return .overview(center: c, distance: Float(n[2]), pitchDegrees: Float(n[3]), yawDegrees: Float(n[4]), fieldOfViewDegrees: Float(n[5]))
        }
        return .overview(center: .zero, distance: 300, pitchDegrees: 40, yawDegrees: 0, fieldOfViewDegrees: 45)
    }
}
