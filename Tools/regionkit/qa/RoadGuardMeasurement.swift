// Compiled by road_guard_measurement.py against both the baseline and current modules.
// No generation rules live here. Hash serialization is documented in docs/data/tunnel-guard.md.
import Foundation
import CryptoKit
import WorldGeo
import WorldMap
import WorldGen
let args = CommandLine.arguments
precondition(args.count >= 7, "root output diagnostics-or-dash ISO-date season area...")
let root = URL(fileURLWithPath: args[1]), date = ISO8601DateFormatter().date(from: args[4])!, season = Int(args[5])!
var rows: [[String:Any]] = []
#if GUARD
var diagnostics: [String:UnsupportedFeatures.Report] = [:]
#endif
for area in args.dropFirst(6) {
    let build = try WorldBuild.generate(areaDirectory: root.appendingPathComponent("Data/areas/" + area), recipe: WorldRecipe(date:date,season:season))
    #if GUARD
    diagnostics[area] = build.unsupportedFeatures
    #endif
    let refs = Set(build.features.roads.map { $0.ref.description })
    let pedestrianWays = build.features.paths + build.features.sidewalks
    let pedestrianRefs = Set(pedestrianWays.map { $0.ref.description })
    var pedestrianTriangles = 0, pedestrianBatches = 0
    var waterHash = SHA256(), waterProfiles: [String:Int] = [:]
    var drawnPedestrians = Set<String>()
    func digest(_ value: some Sequence<UInt8>) -> String { value.map { String(format:"%02x",$0) }.joined() }

    var triangles = 0, batches = 0, hash = SHA256()
    hash.update(data: Data("WorldEngine-static-position-index-v2\0".utf8))
    func word(_ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of:&little) { hash.update(data:Data($0)) }
    }
    for chunk in build.scene.chunks {
        let name = Data(chunk.id.utf8); word(UInt32(name.count)); hash.update(data:name)
        let mesh = chunk.staticMesh
        let water = chunk.waterMesh
        var waterWords: [UInt32] = [UInt32(water.vertexCount),UInt32(water.indices.count)]
        for (p,e) in zip(water.positions,water.extras) {
            waterWords += [p.x.bitPattern,p.y.bitPattern,p.z.bitPattern,e.x.bitPattern,e.y.bitPattern,e.z.bitPattern,e.w.bitPattern]
            waterProfiles[String(Int(e.w)),default:0] += 1
        }
        waterWords += water.indices
        for value in waterWords { var little=value.littleEndian; withUnsafeBytes(of:&little) { waterHash.update(data:Data($0)) } }
        var pedestrianOwners = [Int](repeating:-1,count:mesh.vertexCount)
        for (owner,range) in chunk.staticFeatures.enumerated() where pedestrianRefs.contains(range.feature) {
            drawnPedestrians.insert(range.feature)
            for v in range.start..<(range.start+range.count) { pedestrianOwners[v]=owner }
        }
        var pc=0
        for i in stride(from:0,to:mesh.indices.count,by:3) {
            let a=pedestrianOwners[Int(mesh.indices[i])], b=pedestrianOwners[Int(mesh.indices[i+1])], c=pedestrianOwners[Int(mesh.indices[i+2])]
            if a >= 0 && a == b && b == c { pc += 1 }
        }
        pedestrianTriangles += pc; if pc > 0 { pedestrianBatches += 1 }

        word(UInt32(mesh.positions.count)); word(UInt32(mesh.indices.count))
        // Fixed x/y/z Float32 bit patterns; never SIMD padding or host-native struct bytes.
        for p in mesh.positions { word(p.x.bitPattern); word(p.y.bitPattern); word(p.z.bitPattern) }
        for i in mesh.indices { word(i) }
        var owners = [Int](repeating:-1,count:mesh.vertexCount)
        for (owner,range) in chunk.staticFeatures.enumerated() where refs.contains(range.feature) {
            for vertex in range.start..<(range.start+range.count) { owners[vertex] = owner }
        }
        var count = 0
        for i in stride(from:0,to:mesh.indices.count,by:3) {
            let a = owners[Int(mesh.indices[i])], b = owners[Int(mesh.indices[i+1])], c = owners[Int(mesh.indices[i+2])]
            if a >= 0 && a == b && b == c { count += 1 }
        }
        triangles += count; if count > 0 { batches += 1 }
    }
    // Loaded clipped roads, in loader order. This is not the complete exported routing graph.
    let graph = build.features.roads.map { ["ref":$0.ref.description,"points":$0.centerline.map { [$0.x,$0.y] }] as [String:Any] }
    let graphData = try JSONSerialization.data(withJSONObject:graph,options:[.sortedKeys])
    let pedestrianGraph=pedestrianWays.map { ["ref":$0.ref.description,"points":$0.centerline.map { [$0.x,$0.y] }] as [String:Any] }
    let pedestrianData=try JSONSerialization.data(withJSONObject:pedestrianGraph,options:[.sortedKeys])
    let tunnelPedestrians=pedestrianWays.filter { $0.isTunnel }.map {
        ["ref":$0.ref.description,"tags":$0.tags,"drawn":drawnPedestrians.contains($0.ref.description)] as [String:Any]
    }
    rows.append(["area":area,
                 "mappedTreePoints":build.features.points.filter { $0.kind == .tree && !$0.fromWay }.count,
                 "mappedTreePointsWithTaxon":build.features.points.filter { $0.kind == .tree && !$0.fromWay && ($0.tags["species"] != nil || $0.tags["genus"] != nil) }.count,
                 "pedestrianTriangles":pedestrianTriangles,"pedestrianBearingChunkBatches":pedestrianBatches,
                 "pedestrianGraphSHA256":digest(SHA256.hash(data:pedestrianData)),"tunnelPedestrians":tunnelPedestrians,
                 "waterSHA256":digest(waterHash.finalize()),"waterProfileVertexCounts":waterProfiles,
                 "waterAreas":build.features.areas.filter { $0.kind == .water || $0.kind == .pool }.map { ["ref":$0.ref.description,"tags":$0.tags] },"roads":build.features.roads.count,"tunnelSegments":build.features.roads.filter { $0.isTunnel }.count,
                 "roadTriangles":triangles,"roadBearingChunkBatches":batches,"staticChunkBatches":build.scene.chunks.filter { !$0.staticMesh.isEmpty }.count,
                 "staticTriangles":build.scene.chunks.reduce(0) { $0+$1.staticMesh.triangleCount },
                 "graphSHA256":SHA256.hash(data:graphData).map { String(format:"%02x",$0) }.joined(),
                 "staticGeometrySHA256":hash.finalize().map { String(format:"%02x",$0) }.joined()])
    print("ROAD-AUDIT \(area) triangles=\(triangles) batches=\(batches)")
}
try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:args[2]))
#if GUARD
if args[3] != "-" {
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys,.withoutEscapingSlashes]
    try encoder.encode(diagnostics).write(to:URL(fileURLWithPath:args[3]))
}
#endif
