// Bakeoff-only adapter, not a native renderer edit. Uses the shipped ContextRing generator.
import Foundation
import WorldGeo
import WorldMap
import WorldMesh
import WorldGen

let args = CommandLine.arguments
 guard args.count == 3 else { fatalError("export-context AREA_DIRECTORY OUTPUT_JSON") }
let directory = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[2])
let manifest = try AreaLoader.loadManifest(directory)
var result: [String: Any] = ["formatVersion": 2, "area": manifest.id,
    "origin": ["latitude": manifest.center.latitude, "longitude": manifest.center.longitude],
    "attribution": "© OpenStreetMap contributors", "license": "ODbL-1.0", "buildings": 0,
    "source": "Sources/WorldGen/Context/ContextRing.swift; World+Context.swift non-casting reference"]
if let coverage = ContextRing.coverage(of: manifest), var document = try AreaLoader.loadContextDocument(directory, manifest: manifest) {
    // Preserve buildings as land-side shoreline evidence only. No building mesh can pass settings.
    // Rail is outside this prototype's requested roads/land/water scope.
    document.ways = document.ways.filter { $0.value.tags["railway"] == nil }
    let palette = Palette(seasonal: try StyleLibrary.seasonalPalette(), season: 1, base: try StyleLibrary.baseColors())
    var input = ContextRingInput(frame: manifest.frame, core: manifest.localBounds, coverage: coverage,
                                palette: palette, profile: try StyleLibrary.profile(at: manifest.center), zones: nil)
    input.settings.transitionWidth = -1
    input.settings.tallHeight = Double.greatestFiniteMagnitude
    input.settings.tallFootprint = Double.greatestFiniteMagnitude
    // General prototype: retain mapped minor roads throughout the existing coverage, aerial tolerance 5 m.
    // Native aerial defaults otherwise unchanged (6 m area tolerance, 8,000 m² minimum area).
    input.settings.detail[ContextLOD.aerial.rawValue].minorReach = Double.greatestFiniteMagnitude
    let ring = ContextRing.generate(document, input: input)
    precondition(ring.stats["buildingsLow"] == 0 && ring.stats["buildingsTall"] == 0)
    func rect(_ r: Rect2D) -> [Double] { [r.min.x, -r.max.y, r.max.x, -r.min.y] }
    func mesh(_ m: MeshBuffers) -> [String: Any] {
        ["position": m.positions.flatMap { [$0.x, $0.y, $0.z] },
         "paint": m.paints.flatMap { [$0.x, $0.y, $0.z, $0.w] }, "index": m.indices]
    }
    // R: mapped footprint masses only, within the existing 500 m building source band.
    // Shared MapFeatureBuilder resolves tag/levels/default heights; defaults are labelled inferred.
    var slim = OSMDocument()
    slim.nodes = document.nodes
    slim.ways = document.ways.filter { $0.value.tags["building"] != nil }
    slim.relations = document.relations.filter { $0.value.tags["building"] != nil }
    for r in slim.relations.values { for m in r.members where m.kind == .way {
        if let w = document.ways[m.ref] { slim.ways[w.id] = w }
    } }
    let buildings = MapFeatureBuilder(frame: manifest.frame, bounds: coverage).build(slim).buildings
    let core = manifest.localBounds
    var masses: [[String: Any]] = []
    for b in buildings where !b.isPart {
        let box = b.footprint.bounds, c = b.footprint.centroid
        // Entire footprint outside core: never duplicate or slice a detailed building.
        guard box.max.x <= core.min.x || box.min.x >= core.max.x || box.max.y <= core.min.y || box.min.y >= core.max.y else { continue }
        guard coverage.contains(box.min), coverage.contains(box.max) else { continue }
        let dx = max(core.min.x - c.x, 0, c.x - core.max.x)
        let dy = max(core.min.y - c.y, 0, c.y - core.max.y)
        let distance = sqrt(dx * dx + dy * dy)
        guard b.footprint.outer.allSatisfy({ p in
            let x = max(core.min.x - p.x, 0, p.x - core.max.x), y = max(core.min.y - p.y, 0, p.y - core.max.y)
            return x * x + y * y <= 500 * 500
        }), let mass = Extrusion.extrude(b.footprint, base: b.height.base, top: b.height.top) else { continue }
        masses.append(["id": String(describing: b.ref), "distanceM": distance,
                       "heightSource": b.height.source.rawValue, "mesh": mesh(mass),
                       "normal": mass.normals.flatMap { [$0.x, $0.y, $0.z] }])
    }
    result["buildingMasses"] = masses.sorted {
        let a = $0["distanceM"] as! Double, b = $1["distanceM"] as! Double
        return a == b ? ($0["id"] as! String) < ($1["id"] as! String) : a < b
    }
    result["buildings"] = masses.count
    result["status"] = "available"
    result["core"] = rect(ring.core); result["coverage"] = rect(ring.coverage)
    result["fadeWidthM"] = ring.settings.fadeWidth
    result["palette"] = ring.palette.colors.map { Palette.hex($0) }
    result["namedSlots"] = ring.palette.namedSlots
    result["cells"] = ring.cells.map { ["id": $0.id, "rect": rect($0.rect), "mesh": mesh($0.mesh(.aerial))] as [String: Any] }
    result["water"] = mesh(ring.water)
    result["stats"] = ring.stats
    result["sources"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(manifest.contextSources))
} else {
    result["status"] = "missing-context-source"; result["cells"] = []
}
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]).write(to: output)
print("context \(manifest.id): \(result["status"]!) -> \(output.path)")
