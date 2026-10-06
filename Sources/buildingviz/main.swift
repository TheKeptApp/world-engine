import Foundation
import simd
import WorldGeo
import WorldMap
import WorldMesh
import WorldGen

// buildingviz: CPU debug renderer for generated buildings (macOS, no RealityKit).
// Usage: see `usage` below.

let usage = """
buildingviz --area DIR --profile ID --out out.png
  [--center LAT,LON | --local X,Y] [--radius 60] [--lod near|mid|far|skyline]
  [--yaw 210] [--pitch 35] [--dist 90] [--fov 40] [--width 1600] [--height 900]
  [--sun-azimuth 225 --sun-elevation 35] [--ssaa 2] [--roads 1]
buildingviz --gallery --profile ID --out out.png [--shapes rectangle,L,T,...] [--ids 6]
  [--local X,Y] (same camera options; camera auto-fits the grid unless --dist is given; gallery default yaw 0 pitch 50;
  --local aims at one cell: footprints start at x = 25 × column, y = −48 × row)
Camera: yaw = compass direction the camera looks toward (0 north, 90 east), pitch = degrees down,
        target = center point at ground level (+3 m), distance in meters. Back faces are culled.
"""

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data((msg + "\n").utf8))
    exit(1)
}

var opts: [String: String] = [:]
var flags: Set<String> = []
do {
    var i = 1
    let args = CommandLine.arguments
    while i < args.count {
        let a = args[i]
        guard a.hasPrefix("--") else { fail("unexpected argument \(a)\n\(usage)") }
        let key = String(a.dropFirst(2))
        if ["gallery", "help", "scene", "zones"].contains(key) { flags.insert(key); i += 1; continue }
        guard i + 1 < args.count else { fail("missing value for \(a)") }
        opts[key] = args[i + 1]
        i += 2
    }
}
if flags.contains("help") { print(usage); exit(0) }

@MainActor func num(_ key: String, _ def: Double) -> Double {
    guard let s = opts[key] else { return def }
    guard let v = Double(s) else { fail("--\(key) expects a number, got \(s)") }
    return v
}
@MainActor func pair(_ key: String) -> (Double, Double)? {
    guard let s = opts[key] else { return nil }
    let p = s.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
    guard p.count == 2 else { fail("--\(key) expects A,B") }
    return (p[0], p[1])
}

guard let profileID = opts["profile"] else { fail("--profile is required\n\(usage)") }
guard let outPath = opts["out"] else { fail("--out is required\n\(usage)") }
let isGallery = flags.contains("gallery")

let lodNames: [String: BuildingLOD] = ["near": .near, "mid": .mid, "far": .far, "skyline": .skyline]
guard let lod = lodNames[opts["lod"] ?? "near"] else { fail("--lod must be near|mid|far|skyline") }

let profile: StyleProfile
var palette: Palette
do {
    profile = try StyleLibrary.profile(id: profileID)
    palette = Palette(base: try StyleLibrary.baseColors())
} catch { fail("cannot load profile \(profileID): \(error)") }

// MARK: - Load features

var features: MapFeatures
var galleryCells: [Gallery.Cell] = []
var centerLocal = LocalPoint(0, 0)
var radius = num("radius", 60)
var galleryRadius: Double?
var galleryHalf = LocalPoint(0, 0)

if isGallery {
    let shapes = (opts["shapes"]?.split(separator: ",").map(String.init)) ?? Gallery.defaultShapes
    let columns = Int(num("ids", 6))
    do {
        (features, galleryCells) = try Gallery.features(shapes: shapes, columns: columns, spacing: 25, rowSpacing: 48)
    } catch { fail("gallery failed: \(error)") }
    let maxX = Double(columns - 1) * 25 + 8
    let minY = -Double(shapes.count - 1) * 48
    centerLocal = LocalPoint(maxX / 2, (minY + 12) / 2)
    galleryRadius = (simd_length(LocalPoint(maxX + 40, 12 - minY + 30)) / 2)
    galleryHalf = LocalPoint((maxX + 40) / 2, (12 - minY + 30) / 2)
    radius = .infinity
    // Close-ups: aim at one cell (footprints start at x = 25 × column, y = −48 × row).
    if let (x, y) = pair("local") { centerLocal = LocalPoint(x, y) }
} else {
    guard let area = opts["area"] else { fail("--area or --gallery is required\n\(usage)") }
    do {
        let url = URL(fileURLWithPath: area)
        features = try AreaLoader.loadFeatures(url)
    } catch { fail("cannot load area \(area): \(error)") }
    if let (lat, lon) = pair("center") {
        centerLocal = features.frame.localPoint(of: GeoCoordinate(latitude: lat, longitude: lon))
    } else if let (x, y) = pair("local") {
        centerLocal = LocalPoint(x, y)
    }
}

// MARK: - Generate

let clock = ContinuousClock()
let genStart = clock.now
var gen = BuildingGenerator(profile: profile, context: StreetContext(features))
gen.obstacles = PolygonIndex(features.buildings.map(\.footprint))

// --scene: the whole generated world (zones, ground, yards, trees, props) instead of buildings only.
let isScene = flags.contains("scene") && !isGallery
var sceneBuild: WorldBuild?
var generated: [GeneratedBuilding] = []
if isScene {
    let manifest = try! AreaLoader.loadManifest(URL(fileURLWithPath: opts["area"]!))
    let c = manifest.frame.coordinate(at: centerLocal)
    let half = radius / 111_000
    let focusBox = GeoBoundingBox(south: c.latitude - half, west: c.longitude - half / cos(c.latitude * .pi / 180),
                                  north: c.latitude + half, east: c.longitude + half / cos(c.latitude * .pi / 180))
    let date = opts["date"].flatMap { ISO8601DateFormatter().date(from: $0) } ?? ISO8601DateFormatter().date(from: "2026-07-15T19:00:00Z")!
    do {
        sceneBuild = try WorldBuild.generate(areaDirectory: URL(fileURLWithPath: opts["area"]!),
                                             recipe: WorldRecipe(profileID: flags.contains("zones") ? nil : profileID, date: date, focus: focusBox))
    } catch { fail("scene generation failed: \(error)") }
} else {
    for b in features.buildings where !b.isPart {
        if radius.isFinite, simd_length(b.footprint.centroid - centerLocal) > radius { continue }
        generated.append(gen.generate(b, palette: &palette, lod: lod))
    }
}
let genTime = clock.now - genStart

// MARK: - Assemble scene

var scene = Scene()
let groundColor = SIMD3<Float>(0x9A, 0xA3, 0x83) / 255
let roadColor = SIMD3<Float>(0x5F, 0x62, 0x66) / 255

@MainActor func addQuad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>, color: SIMD3<Float>) {
    scene.tris.append(.init(a: a, b: b, c: c, color: color, shade: 1, ao: 1, glass: false, cull: false))
    scene.tris.append(.init(a: a, b: c, c: d, color: color, shade: 1, ao: 1, glass: false, cull: false))
}

// Ground (two-sided, normal forced up by winding: a→b→c CCW seen from above).
let target = LocalFrame.scenePosition(centerLocal, y: 3)
let extent = Float(max(400, (galleryRadius ?? radius) * 3, num("dist", 90) * 6))
let gy: Float = -0.3
let gc = SIMD3<Float>(target.x, gy, target.z)
addQuad(gc + SIMD3(-extent, 0, extent), gc + SIMD3(extent, 0, extent), gc + SIMD3(extent, 0, -extent), gc + SIMD3(-extent, 0, -extent),
        color: groundColor)

// Scene mode: chunk meshes and prop instances near the view.
if let build = sceneBuild {
    let pal = build.scene.palette
    let reach = Float(radius * 2.5)
    func addMesh(_ m: MeshBuffers, transform: simd_float4x4? = nil, cull: Bool) {
        var k = 0
        while k + 2 < m.indices.count {
            let i0 = Int(m.indices[k]), i1 = Int(m.indices[k + 1]), i2 = Int(m.indices[k + 2])
            k += 3
            var a = m.positions[i0], b = m.positions[i1], c = m.positions[i2]
            if let t = transform {
                func tf(_ p: SIMD3<Float>) -> SIMD3<Float> { let q = t * SIMD4(p, 1); return SIMD3(q.x, q.y, q.z) }
                a = tf(a); b = tf(b); c = tf(c)
            }
            let mid = (a + b + c) / 3
            if simd_length(SIMD2(mid.x - target.x, mid.z - target.z)) > reach { continue }
            let p0 = m.paints[i0]
            let slot = min(max(0, Int(p0.x)), pal.colors.count - 1)
            let ao = (m.extras[i0].x + m.extras[i1].x + m.extras[i2].x) / 3
            scene.tris.append(.init(a: a, b: b, c: c, color: pal.colors[slot], shade: p0.y, ao: ao, glass: (Int(p0.z) & 1) != 0, cull: cull))
        }
    }
    for chunk in build.scene.chunks { addMesh(chunk.staticMesh, cull: true); addMesh(chunk.waterMesh, cull: true) }
    var propMeshes: [String: MeshBuffers] = [:]
    for inst in build.scene.instances where simd_length(LocalPoint(inst.x, inst.y) - centerLocal) < Double(reach) {
        let key = "\(inst.kind.rawValue)-\(inst.variant)"
        if propMeshes[key] == nil { propMeshes[key] = PropLibrary.mesh(inst.kind, variant: inst.variant, lod: 0, palette: pal) }
        addMesh(propMeshes[key]!, transform: inst.transform, cull: true)
    }
    let st = build.scene.stats
    print("scene: profile \(build.profile.id) lots \(st["lots"] ?? 0) walks \(st["walks"] ?? 0) driveways \(st["driveways"] ?? 0) beds \(st["beds"] ?? 0) shrubs \(st["shrubs"] ?? 0) hedgeSegments \(st["hedgeSegments"] ?? 0) yardTrees \(st["yardTrees"] ?? 0) streetTrees \(st["streetTrees"] ?? 0) yardMillis \(st["yardMillis"] ?? 0) [raster \(st["yardMsRaster"] ?? 0) assign \(st["yardMsAssign"] ?? 0) lots \(st["yardMsLots"] ?? 0) street \(st["yardMsStreet"] ?? 0)] instances \(build.scene.instances.count)")
}

// Roads (flat ribbons).
if !isScene, (opts["roads"] ?? "1") != "0" {
    let reach = (galleryRadius ?? radius) + 150
    for r in features.roads where r.kind.isVehicular && !r.isTunnel {
        let pts = r.centerline
        guard pts.count >= 2 else { continue }
        for i in 0..<(pts.count - 1) {
            let p = pts[i], q = pts[i + 1]
            if simd_length((p + q) / 2 - centerLocal) > reach { continue }
            let d = q - p
            let len = simd_length(d)
            if len < 0.01 { continue }
            let n = LocalPoint(-d.y, d.x) / len * (r.width / 2)
            let a = LocalFrame.scenePosition(p - n, y: 0), b = LocalFrame.scenePosition(p + n, y: 0)
            let c = LocalFrame.scenePosition(q + n, y: 0), dd = LocalFrame.scenePosition(q - n, y: 0)
            addQuad(a, b, c, dd, color: roadColor)
        }
    }
}

// Buildings.
var meshTriangles = 0
var legend: [String] = []
for (bi, g) in generated.enumerated() {
    let m = g.mesh
    meshTriangles += m.triangleCount
    var k = 0
    while k + 2 < m.indices.count {
        let i0 = Int(m.indices[k]), i1 = Int(m.indices[k + 1]), i2 = Int(m.indices[k + 2])
        k += 3
        let p0 = m.paints[i0]
        let slot = min(max(0, Int(p0.x)), palette.colors.count - 1)
        let ao = (m.extras[i0].x + m.extras[i1].x + m.extras[i2].x) / 3
        scene.tris.append(.init(a: m.positions[i0], b: m.positions[i1], c: m.positions[i2],
                                color: palette.colors[slot], shade: p0.y, ao: ao,
                                glass: (Int(p0.z) & 1) != 0, cull: true))
    }
    if isGallery {
        let c = galleryCells[bi]
        legend.append("row \(c.row) col \(c.column)  \(c.shape)  id \(c.id)  family \(g.family ?? "-")  roof \(g.roofShape.rawValue)  role \(g.role.rawValue)  floors \(g.floors)")
    }
}
if isGallery { print(legend.joined(separator: "\n")) }

// MARK: - Render

let galleryWidthDefault = 1400.0, galleryHeightDefault = 1400.0
let yawDefault = isGallery ? 0.0 : 210.0
let pitchDefault = isGallery ? 50.0 : 35.0
let fov = Float(num("fov", 40))
var dist = Float(num("dist", 90))
let pitchDeg = num("pitch", pitchDefault)
if isGallery, opts["dist"] == nil {
    // Fit the grid: depth extent is foreshortened by the pitch, width is seen across the view.
    let aspect = num("width", galleryWidthDefault) / num("height", galleryHeightDefault)
    let tanV = tan(Double(fov) * .pi / 360)
    let yawRad = num("yaw", yawDefault) * .pi / 180
    let hx = abs(cos(yawRad)) * galleryHalf.x + abs(sin(yawRad)) * galleryHalf.y // across the view
    let hy = abs(sin(yawRad)) * galleryHalf.x + abs(cos(yawRad)) * galleryHalf.y // along the view
    let depthSpan = hy * sin(pitchDeg * .pi / 180) + 8 * cos(pitchDeg * .pi / 180)
    dist = Float(max(depthSpan / tanV, hx / (tanV * aspect)) * 1.08)
}
let camera = Camera(target: target, yaw: Float(num("yaw", yawDefault)), pitch: Float(num("pitch", pitchDefault)),
                    distance: dist, fovDegrees: fov)
let az = Float(num("sun-azimuth", 225)) * .pi / 180, el = Float(num("sun-elevation", 35)) * .pi / 180
let sun = SIMD3<Float>(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
let width = Int(num("width", isGallery ? galleryWidthDefault : 1600)), height = Int(num("height", isGallery ? galleryHeightDefault : 900))
let renderer = SceneRenderer(width: width, height: height, ssaa: Int(num("ssaa", 2)), camera: camera, sunDirection: sun)

let renderStart = clock.now
let (pixels, drawn) = renderer.render(scene)
let renderTime = clock.now - renderStart
do {
    try writePNG(pixels, width: width, height: height, to: URL(fileURLWithPath: outPath))
} catch { fail("\(error)") }

func secs(_ d: Duration) -> String { String(format: "%.2fs", Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18) }
print("buildings \(generated.count)  mesh triangles \(meshTriangles)  drawn (front-facing) \(drawn)  generation \(secs(genTime))  render \(secs(renderTime))  -> \(outPath)")
