import Foundation
import RealityKit
import Testing
@testable import WorldEngine
import WorldEnvironment
import WorldGen
import WorldGeo

/// Draw calls and triangles in view (`World.estimateView`) for the look-loop cameras
/// (Tools/lookloop/views.json, with WorldLab's demo data: focus boxes, profiles, camera poses)
/// and P2's gate cameras, on the Mac. look-fix-v1 §7: ≤ 100 visible draw calls; triangles in
/// view under 400k. Prints one `DRAWS` line per view with the split by category. Runs only when
/// the engine's shaders are compiled for the Mac (`scripts/postcard_mac_check.sh`), like the
/// offscreen postcard tests; the 16:9 look-loop frame is the widest view the phone shows.
@MainActor
@Suite("Draw calls in view on the Mac", .serialized)
struct ViewDrawBudgetTests {
    static let root = OffscreenPostcardTests.packageRoot.appendingPathComponent("Data/areas")

    /// A look-loop camera: a pose in scene space, from WorldLab's presets and named cameras.
    struct View {
        var id: String
        /// A follow-camera view: the cut-away target is the pose's target.
        var follow = false
        var pose: @MainActor (World) -> CameraPose
    }

    struct Area {
        var id: String
        var focus: GeoBoundingBox
        var profile: String?
        var date: String
        var views: [View]
    }

    /// WorldLab's named camera: standing at lat/lon (eye 1.65 m) looking along heading/pitch, or
    /// orbiting the ground point from `distance` m (RealityKitScreen.pose).
    static func named(_ id: String, _ lat: Double, _ lon: Double, heading: Double, pitchDown: Double = 3, fov: Double = 50,
                      distance: Double? = nil) -> View {
        View(id: id) { w in
            let h = heading * .pi / 180, p = pitchDown * .pi / 180
            let f = SIMD3(sin(h) * cos(p), -sin(p), -cos(h) * cos(p))
            let eye = distance.map { -f * $0 } ?? SIMD3(0, 1.65, 0)
            let target = distance == nil ? eye + f * 30 : SIMD3<Double>(0, 0, 0)
            return w.pose(origin: GeoCoordinate(latitude: lat, longitude: lon), eye: [eye.x, eye.y, eye.z],
                          target: [target.x, target.y, target.z], fieldOfViewDegrees: fov)
        }
    }

    static let areas: [Area] = [
        Area(id: "sloans-lake", focus: GeoBoundingBox(south: 39.747058, west: -105.0495, north: 39.7545, east: -105.037966),
             profile: nil, date: "2026-10-15T21:30:00Z", views: [
                 // v2-01 / v2-04 / ordinary-street / light-rain-street: the West 23rd Ave fixture
                 // (camera 2.6 m east and 1.25 m up of the anchor, looking at 0.48 m over it).
                 View(id: "v2-01-street") { w in
                     let a = w.position(of: GeoCoordinate(latitude: 39.7511195, longitude: -105.0389))
                     let anchor = SIMD3<Double>(Double(a.x), Double(a.y), Double(a.z))
                     return CameraPose(eye: anchor + [2.6, 1.25, 0], target: anchor + [0, 0.48, 0], verticalFOVDegrees: 50)
                 },
                 // The same with the follow camera's cut-away on (walking the character there).
                 View(id: "v2-01-follow", follow: true) { w in
                     let a = w.position(of: GeoCoordinate(latitude: 39.7511195, longitude: -105.0389))
                     let anchor = SIMD3<Double>(Double(a.x), Double(a.y), Double(a.z))
                     return CameraPose(eye: anchor + [2.6, 1.25, 0], target: anchor + [0, 0.48, 0], verticalFOVDegrees: 50)
                 },
                 // v2-06, showcase 10/11: the aerial fixture.
                 View(id: "v2-06-aerial") { w in
                     w.pose(origin: GeoCoordinate(latitude: 39.7494, longitude: -105.0445), eye: [0, 1474.47367972, 1032.43758543],
                            target: [0, 0, 0], fieldOfViewDegrees: 50)
                 },
                 // showcase 01–09, ordinary-trail: the lake-trail street camera.
                 View(id: "showcase-street") { w in
                     w.pose(origin: GeoCoordinate(latitude: 39.7528379, longitude: -105.0467978), eye: [0, 1.65, 0],
                            target: [29.503743246398354, 0.0799213127116849, 5.202305966235185], fieldOfViewDegrees: 50)
                 },
             ]),
        Area(id: "lakeview-sheil-park", focus: GeoBoundingBox(south: 41.9415, west: -87.669, north: 41.948, east: -87.6585),
             profile: "chicago-dense-north", date: "2026-10-22T20:00:00Z", views: [
                 named("lakeview-postcard", 41.943402, -87.6632, heading: 90),
                 named("lakeview-street", 41.943402, -87.66075, heading: 270),
                 named("lakeview-alley", 41.944063, -87.666977, heading: 0),
                 named("lakeview-block-center", 41.94567, -87.66361, heading: 90),
                 named("lakeview-aerial", 41.944, -87.664, heading: 150, pitchDown: 32, fov: 45, distance: 110),
             ]),
        Area(id: "evanston-south", focus: GeoBoundingBox(south: 42.035, west: -87.694, north: 42.041, east: -87.6885),
             profile: "evanston", date: "2026-10-22T20:00:00Z", views: [
                 named("evanston-postcard", 42.037641, -87.6925, heading: 90),
                 named("evanston-street", 42.0382, -87.69135, heading: 180),
                 named("evanston-aerial", 42.0378, -87.6915, heading: 20, pitchDown: 32, fov: 45, distance: 95),
             ]),
        Area(id: "wilmette-vattmann-park", focus: GeoBoundingBox(south: 42.072, west: -87.7225, north: 42.079, east: -87.713),
             profile: "wilmette", date: "2026-10-22T20:00:00Z", views: [
                 named("wilmette-street", 42.074933, -87.719996, heading: 90),
                 named("wilmette-aerial", 42.0755, -87.718, heading: 20, pitchDown: 32, fov: 45, distance: 110),
             ]),
    ]

    /// Builds the area's world as WorldLab does (focus, profile, date), waits for the context ring,
    /// applies clear weather (sky dome on), and measures each view in the 16:9 look-loop frame.
    @Test(arguments: ["sloans-lake", "lakeview-sheil-park", "evanston-south", "wilmette-vattmann-park"])
    func drawCallsInView(_ id: String) async throws {
        guard OffscreenPostcardTests.shadersReady else { Issue.record("missing test prerequisite: OffscreenPostcardTests.shadersReady"); return }
        let area = Self.areas.first { $0.id == id }!
        let dir = Self.root.appendingPathComponent(area.id)
        guard FileManager.default.fileExists(atPath: dir.appendingPathComponent("manifest.json").path) else { Issue.record("missing test prerequisite: FileManager.default.fileExists(atPath: dir.appendingPathComponent('manifest.json').path)"); return }
        let date = ISO8601DateFormatter().date(from: area.date)!
        let world = try await World.load(areaDirectory: dir, options: WorldOptions(focus: area.focus, profileID: area.profile, date: date))
        await world.context.task?.value
        let resolver = try world.environmentResolver(timeZone: TimeZone(identifier: "America/Chicago")!, phenologyProfileID: nil)
        world.apply(resolver.resolve(SyntheticWeather(label: .clear, cloudFraction: 0.1).input(at: date)))
        world.viewAspect = 16.0 / 9.0
        let camera = Entity()
        for view in area.views {
            let pose = view.pose(world)
            camera.components.set(PerspectiveCameraComponent(near: 0.1, far: 5000, fieldOfViewInDegrees: Float(pose.verticalFOVDegrees)))
            camera.look(at: SIMD3<Float>(pose.target), from: SIMD3<Float>(pose.eye), relativeTo: nil)
            world.lodCenter = nil
            let focus = SIMD3<Float>(Float(pose.target.x), 0, Float(pose.target.z))
            world.update(deltaTime: 0.5, camera: camera, focusPoint: focus, cutAwayTarget: view.follow ? SIMD3<Float>(pose.target) : nil)
            let s = world.stats
            print("DRAWS \(area.id) \(view.id) draws=\(s.viewDrawCalls) triangles=\(s.viewTriangles) "
                  + "drawsplit[\(s.viewDraws.summary)] trisplit[\(s.viewTriangleSplit.summary)] all=\(s.drawCalls)")
            if ProcessInfo.processInfo.environment["DRAWS_DETAIL"] != nil {
                let fov = Float(pose.verticalFOVDegrees) * .pi / 180
                let planes = World.frustumPlanes(view: camera.transformMatrix(relativeTo: nil).inverse, fovY: fov, aspect: world.viewAspect, near: 0.1, far: 5000)
                // Foliage draws/triangles per slot and tree-or-not, building draws/triangles per LOD
                // (cells; tiles as "tile-<lod>").
                var split: [String: (n: Int, t: Int)] = [:]
                for batch in world.lodBatches where batch.count > 0 {
                    if let b = batch.bounds, World.intersects(b, planes) {
                        let k = "s\(batch.slot)\(batch.kind.isTree ? "tree" : "bush")"
                        split[k, default: (0, 0)].n += 1
                        split[k, default: (0, 0)].t += batch.count * batch.triangles
                    }
                }
                for c in world.cullables where c.category == \ViewCost.chunks && World.intersects(c.bounds, planes) {
                    let k = c.name.hasSuffix("ground") ? "c-flat" : c.name.contains("water") ? "c-water" : "c-raised"
                    split[k, default: (0, 0)].n += 1
                    split[k, default: (0, 0)].t += c.triangles
                }
                for cell in world.buildingCells {
                    if let b = cell.bounds, let a = cell.active, World.intersects(b, planes) {
                        split["b-\(cell.levels[a].lod)", default: (0, 0)].n += 1
                        split["b-\(cell.levels[a].lod)", default: (0, 0)].t += cell.levels[a].triangles
                    }
                }
                for tile in world.buildingTiles {
                    if let a = tile.active, World.intersects(tile.levels[a].bounds, planes) {
                        split["b-tile-\(tile.levels[a].lod)", default: (0, 0)].n += 1
                        split["b-tile-\(tile.levels[a].lod)", default: (0, 0)].t += tile.levels[a].triangles
                    }
                }
                print("DETAIL \(view.id) " + split.keys.sorted().map { "\($0)=\(split[$0]!.n)/\(split[$0]!.t)" }.joined(separator: " "))
            }
            #expect(s.viewDrawCalls <= 100, "\(view.id): \(s.viewDrawCalls) draw calls in view")
            #expect(s.viewTriangles < 400_000, "\(view.id): \(s.viewTriangles) triangles in view")
        }
    }
}
