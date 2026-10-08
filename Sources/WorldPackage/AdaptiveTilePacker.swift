import Foundation
import CryptoKit

/// Export-stage triangle repartitioning, never regeneration or appearance changes.
/// Budgets: mobile-rendering-v1/streaming-design.md §7 (2 MiB upload part, 16 MiB queue).
public enum AdaptiveTilePacker {
    public struct Budget: Sendable {
        public var uploadBytes = 2 * 1_048_576
        public var queueBytes = 16 * 1_048_576
        public var decodedLeafBytes = 8 * 1_048_576
        public var primitiveBytes = 2 * 1_048_576
        public init() {}
    }
    enum Failure: Error { case invalid(String) }
    static func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
    struct Attribute {
        var meta: [String: Any]
        var bytes: Data
        var width: Int
    }
    struct Primitive {
        var meta: [String: Any]
        var attributes: [String: Attribute]
        var indices: [UInt32]
        var positions: [Float]
        var material: String
    }
    struct Mesh {
        var template: [String: Any]
        var primitives: [Primitive]
        var origin: [Double]
        init(_ data: Data) throws {
            let file = try GLBFile(data: data)
            template = file.json
            guard file.nodes.count == 1, file.meshes.count == 1,
                  file.nodes[0]["mesh"] as? Int == 0, file.nodes[0]["children"] == nil, file.nodes[0]["matrix"] == nil, file.nodes[0]["rotation"] == nil,
                  file.nodes[0]["scale"] == nil else { throw Failure.invalid("Unsupported node transform") }
            origin = file.nodes[0]["translation"] as? [Double] ?? [0, 0, 0]
            primitives = []
            for p in file.meshes[0]["primitives"] as? [[String: Any]] ?? [] {
                guard (p["mode"] as? Int ?? 4) == 4, let ids = p["attributes"] as? [String: Int],
                      Set(ids.keys) == Set(["POSITION", "NORMAL", "_PAINT", "_EXTRA", "_FEATURE"]),
                      let index = p["indices"] as? Int, let materialID = p["material"] as? Int,
                      file.materialNames.indices.contains(materialID) else { throw Failure.invalid("Unsupported primitive") }
                var attrs: [String: Attribute] = [:]
                for (key, id) in ids {
                    let (bytes, a) = file.bytes(id)
                    let count = a["count"] as! Int
                    let view = file.bufferViews[a["bufferView"] as! Int]
                    guard count > 0, a["sparse"] == nil, a["normalized"] == nil,
                          (a["byteOffset"] as? Int ?? 0) == 0, view["byteStride"] == nil,
                          [5123, 5125, 5126].contains(a["componentType"] as! Int), bytes.count % count == 0
                    else { throw Failure.invalid("Unsupported accessor") }
                    attrs[key] = Attribute(meta: a, bytes: bytes, width: bytes.count / count)
                }
                guard attrs["POSITION"]?.width == 12, attrs["NORMAL"]?.width == 12,
                      attrs["_PAINT"]?.width == 16, attrs["_EXTRA"]?.width == 16,
                      [2, 4].contains(attrs["_FEATURE"]!.width),
                      !primitives.contains(where: { $0.material == file.materialNames[materialID] })
                else { throw Failure.invalid("Unsupported channel or repeated material") }
                let positions = file.floats(ids["POSITION"]!)
                let indices = file.uints(index)
                guard indices.count % 3 == 0, positions.allSatisfy(\.isFinite),
                      indices.allSatisfy({ Int($0) < positions.count / 3 }),
                      attrs.values.allSatisfy({ ($0.meta["count"] as? Int) == positions.count / 3 })
                else { throw Failure.invalid("Invalid triangle data") }
                primitives.append(Primitive(meta: p, attributes: attrs, indices: indices,
                                            positions: positions, material: file.materialNames[materialID]))
            }
        }
        var selection: [[Int]] { primitives.map { Array(0..<($0.indices.count / 3)) } }
        func centroid(_ primitive: Int, _ triangle: Int, _ axis: Int) -> Double {
            let p = primitives[primitive]
            return (0..<3).reduce(0) { $0 + Double(p.positions[Int(p.indices[triangle * 3 + $1]) * 3 + axis]) } / 3
        }
    }
    struct Encoded {
        var data: Data
        var decoded: Int
        var triangles: Int
        var vertices: Int
        var bounds: [[Double]]
        var parts: [[String: Any]]
        var ranges: [String: [Int: [[Int]]]]
    }
    struct Leaf { var suffix: String; var lods: [Encoded] }

    /// Exact source attribute bytes are gathered; shared vertices are copied only once per primitive/leaf.
    static func encode(_ mesh: Mesh, _ selections: [[Int]]) throws -> Encoded {
        var bin = Data(), views: [[String: Any]] = [], accessors: [[String: Any]] = [], primitives: [[String: Any]] = []
        var decoded = 0, triangles = 0, vertices = 0
        var parts: [[String: Any]] = []
        var lo = [Double](repeating: .infinity, count: 3), hi = [Double](repeating: -.infinity, count: 3)
        var ranges: [String: [Int: [[Int]]]] = [:]
        func append(_ bytes: Data, _ metadata: [String: Any], target: Int) -> Int {
            while bin.count % 4 != 0 { bin.append(0) }
            views.append(["buffer": 0, "byteOffset": bin.count, "byteLength": bytes.count, "target": target])
            bin.append(bytes); decoded += bytes.count
            var a = metadata; a["bufferView"] = views.count - 1; a.removeValue(forKey: "byteOffset")
            accessors.append(a); return accessors.count - 1
        }
        for (pi, selected) in selections.enumerated() where !selected.isEmpty {
            let p = mesh.primitives[pi], decodedStart = decoded
            var oldVertices: [Int] = [], mapping: [UInt32: UInt32] = [:], indices: [UInt32] = []
            for t in selected { for old in p.indices[(t * 3)..<(t * 3 + 3)] {
                if mapping[old] == nil { mapping[old] = UInt32(oldVertices.count); oldVertices.append(Int(old)) }
                indices.append(mapping[old]!)
            } }
            var attrs: [String: Int] = [:]
            for key in p.attributes.keys.sorted() {
                let a = p.attributes[key]!
                var bytes = Data(); bytes.reserveCapacity(oldVertices.count * a.width)
                for old in oldVertices { bytes.append(a.bytes.subdata(in: (old * a.width)..<((old + 1) * a.width))) }
                var meta = a.meta; meta["count"] = oldVertices.count
                if key == "POSITION" {
                    var low = [Double](repeating: .infinity, count: 3), high = [Double](repeating: -.infinity, count: 3)
                    for old in oldVertices { for axis in 0..<3 {
                        let v = Double(p.positions[old * 3 + axis]); low[axis] = min(low[axis], v); high[axis] = max(high[axis], v)
                        lo[axis] = min(lo[axis], v + mesh.origin[axis]); hi[axis] = max(hi[axis], v + mesh.origin[axis])
                    } }
                    meta["min"] = low; meta["max"] = high
                }
                if key == "_FEATURE" {
                    let values: [Int] = bytes.withUnsafeBytes { raw in
                        (0..<oldVertices.count).map { i in
                            a.width == 2 ? Int(raw.loadUnaligned(fromByteOffset: i * 2, as: UInt16.self)) : Int(raw.loadUnaligned(fromByteOffset: i * 4, as: UInt32.self))
                        }
                    }
                    var result: [Int: [[Int]]] = [:], start = 0
                    while start < values.count {
                        var end = start + 1
                        while end < values.count && values[end] == values[start] { end += 1 }
                        result[values[start], default: []].append([start, end - start]); start = end
                    }
                    ranges[p.material] = result
                }
                attrs[key] = append(bytes, meta, target: 34962)
            }
            let bytes = indices.withUnsafeBufferPointer { Data(buffer: $0) }
            let idx = append(bytes, ["componentType": 5125, "count": indices.count, "type": "SCALAR"], target: 34963)
            var prim = p.meta; prim["attributes"] = attrs; prim["indices"] = idx; primitives.append(prim)
            parts.append(["primitiveIndex": primitives.count - 1, "material": p.material,
                          "decodedBytes": decoded - decodedStart, "triangles": indices.count / 3, "vertices": oldVertices.count])
            triangles += indices.count / 3; vertices += oldVertices.count
        }
        while bin.count % 4 != 0 { bin.append(0) }
        var json = mesh.template, meshes = json["meshes"] as! [[String: Any]]
        meshes[0]["primitives"] = primitives; json["meshes"] = meshes
        json["accessors"] = accessors; json["bufferViews"] = views; json["buffers"] = [["byteLength": bin.count]]
        var header = try WorldPackage.json(json, pretty: false)
        while header.count % 4 != 0 { header.append(0x20) }
        var data = Data()
        func u32(_ value: Int) { var v = UInt32(value).littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        u32(0x46546c67); u32(2); u32(28 + header.count + bin.count)
        u32(header.count); u32(0x4e4f534a); data.append(header); u32(bin.count); u32(0x004e4942); data.append(bin)
        return Encoded(data: data, decoded: decoded, triangles: triangles, vertices: vertices,
                       bounds: vertices == 0 ? [] : [lo, hi], parts: parts, ranges: ranges)
    }

    /// Stable median split along the widest centroid axis; ties use other axis, LOD, primitive, triangle.
    /// Whole triangles stay unchanged, so bounds may overlap. Empty LODs are explicit, never zero-byte errors.
    static func split(_ meshes: [Mesh], budget: Budget) throws -> [Leaf] {
        guard budget.uploadBytes > 0, budget.queueBytes > 0, budget.decodedLeafBytes > 0, budget.primitiveBytes > 0 else { throw Failure.invalid("Invalid budget") }
        struct Ref { var lod: Int; var primitive: Int; var triangle: Int; var x: Double; var z: Double }
        func visit(_ selection: [[[Int]]], suffix: String) throws -> [Leaf] {
            let encoded = try zip(meshes, selection).map { try encode($0, $1) }
            if encoded.allSatisfy({ $0.data.count <= budget.uploadBytes && $0.decoded <= min(budget.decodedLeafBytes, budget.queueBytes / 2) && $0.parts.allSatisfy { ($0["decodedBytes"] as! Int) <= budget.primitiveBytes } }) {
                return [Leaf(suffix: suffix, lods: encoded)]
            }
            var refs: [Ref] = []
            for l in meshes.indices { for p in selection[l].indices { for t in selection[l][p] {
                refs.append(Ref(lod: l, primitive: p, triangle: t, x: meshes[l].centroid(p, t, 0), z: meshes[l].centroid(p, t, 2)))
            } } }
            guard refs.count > 1 else { throw Failure.invalid("Budget cannot hold one triangle and GLB metadata") }
            let x = refs.map(\.x), z = refs.map(\.z)
            let axisX = x.max()! - x.min()! >= z.max()! - z.min()!
            refs.sort {
                let a = axisX ? [$0.x, $0.z] : [$0.z, $0.x], b = axisX ? [$1.x, $1.z] : [$1.z, $1.x]
                if a[0] != b[0] { return a[0] < b[0] }; if a[1] != b[1] { return a[1] < b[1] }
                if $0.lod != $1.lod { return $0.lod < $1.lod }; if $0.primitive != $1.primitive { return $0.primitive < $1.primitive }
                return $0.triangle < $1.triangle
            }
            var left = selection.map { $0.map { _ in [Int]() } }, right = left
            for (i, r) in refs.enumerated() {
                if i < refs.count / 2 { left[r.lod][r.primitive].append(r.triangle) }
                else { right[r.lod][r.primitive].append(r.triangle) }
            }
            for l in meshes.indices { for p in left[l].indices { left[l][p].sort(); right[l][p].sort() } }
            return try visit(left, suffix: suffix + "0") + visit(right, suffix: suffix + "1")
        }
        return try visit(meshes.map(\.selection), suffix: "")
    }

    /// Packs an existing export so A4's exact measured inputs can be compared without regeneration.
    /// Destination must be new. Non-geometry files and material/vertex values are copied unchanged.
    public static func pack(source: URL, to output: URL, budget: Budget = .init()) throws -> [String: Any] {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: output.path) else { throw Failure.invalid("Destination already exists") }
        let sourceData = try Data(contentsOf: source.appendingPathComponent("world.json"))
        var world = try JSONSerialization.jsonObject(with: sourceData) as! [String: Any]
        guard world["schema"] as? String == "worldengine.package/1", world["tileLayout"] == nil else { throw Failure.invalid("Expected unpacked package/1") }
        let original = world["chunks"] as! [[String: Any]], oldFiles = world["files"] as! [String: [String: Any]]
        var hashes: [String: Any] = [:], chunks: [[String: Any]] = [], before: [[String: Any]] = [], after: [[String: Any]] = []
        var groups: [[String: Any]] = []
        var buildingBounds: [String: [Double]] = [:], buildingParents: [String: Set<String>] = [:]
        func read(_ path: String) throws -> Data {
            guard !path.hasPrefix("/"), !path.split(separator: "/").contains(".."), let expected = oldFiles[path] else { throw Failure.invalid("Unindexed path") }
            let data = try Data(contentsOf: source.appendingPathComponent(path))
            guard data.count == expected["bytes"] as? Int, digest(data) == expected["sha256"] as? String else { throw Failure.invalid("Source digest mismatch: " + path) }
            return data
        }
        func write(_ data: Data, _ path: String) throws {
            let url = output.appendingPathComponent(path)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url); hashes[path] = ["sha256": digest(data), "bytes": data.count]
        }
        for path in oldFiles.keys.sorted() where !path.hasPrefix("chunks/") { try write(read(path), path) }
        for parent in original {
            let id = parent["id"] as! String, paths = parent["lods"] as! [String]
            let data = try paths.map(read), meshes = try data.map(Mesh.init)
            guard paths.count == 2, !id.contains("/"), !id.contains("\\"), !id.contains("..") else { throw Failure.invalid("Invalid parent tile ID or LOD count") }
            let sceneData = try read(parent["scene"] as! String)
            let scene = try JSONSerialization.jsonObject(with: sceneData) as! [String: Any]
            for l in meshes.indices {
                let e = try encode(meshes[l], meshes[l].selection)
                before.append(["id": id, "lod": l, "glbBytes": data[l].count, "decodedBytes": e.decoded, "triangles": e.triangles])
            }
            // Immutable logical ownership is separate from adaptive payload membership.
            let buildingIDs = Dictionary(uniqueKeysWithValues: (scene["features"] as! [[String: Any]]).filter { $0["kind"] as? String == "building" }.map { ($0["index"] as! Int, $0["id"] as! String) })
            for primitive in meshes[0].primitives {
                let feature = primitive.attributes["_FEATURE"]!
                for vertex in Set(primitive.indices).sorted() {
                    let v = Int(vertex)
                    let fi = feature.bytes.withUnsafeBytes { raw in feature.width == 2 ? Int(raw.loadUnaligned(fromByteOffset: v * 2, as: UInt16.self)) : Int(raw.loadUnaligned(fromByteOffset: v * 4, as: UInt32.self)) }
                    guard let ref = buildingIDs[fi] else { continue }
                    let x = Double(primitive.positions[v * 3]) + meshes[0].origin[0], north = -(Double(primitive.positions[v * 3 + 2]) + meshes[0].origin[2])
                    let old = buildingBounds[ref] ?? [x, north, x, north]
                    buildingBounds[ref] = [min(old[0], x), min(old[1], north), max(old[2], x), max(old[3], north)]
                    buildingParents[ref, default: []].insert(id)
                }
            }
            var childIDs: [String] = [], childBoxes: [[[Double]]] = []
            for leaf in try split(meshes, budget: budget) {
                let childID = leaf.suffix.isEmpty ? id : id + "." + leaf.suffix, base = "chunks/" + childID
                var child = parent, childScene = scene, features = scene["features"] as! [[String: Any]]
                let bounds = leaf.lods.map(\.bounds).filter { !$0.isEmpty }
                let box: [[Double]] = bounds.isEmpty ? [] : [(0..<3).map { axis in bounds.map { $0[0][axis] }.min()! }, (0..<3).map { axis in bounds.map { $0[1][axis] }.max()! }]
                var lodPaths: [String] = []
                for (l, e) in leaf.lods.enumerated() {
                    let path = "\(base)/lod\(l).glb"; try write(e.data, path); lodPaths.append(path)
                    for i in features.indices {
                        let fi = features[i]["index"] as! Int
                        features[i]["lod\(l)"] = ["static": e.ranges["worldStatic"]?[fi] ?? [], "water": e.ranges["worldWater"]?[fi] ?? []]
                    }
                    after.append(["id": childID, "parent": id, "lod": l, "glbBytes": e.data.count, "decodedBytes": e.decoded, "triangles": e.triangles])
                }
                child["id"] = childID; child["parentID"] = id; child["bounds"] = box; child["lods"] = lodPaths
                child["scene"] = base + "/scene.json"; child["triangles"] = leaf.lods.map(\.triangles)
                child["decodedBytes"] = leaf.lods.map(\.decoded)
                child["parts"] = leaf.lods.map(\.parts)
                child["glbBytes"] = leaf.lods.map { $0.data.count }
                child["emptyLODs"] = leaf.lods.indices.filter { leaf.lods[$0].triangles == 0 }
                childScene["chunk"] = childID; childScene["parentID"] = id; childScene["features"] = features
                childScene["vertices"] = leaf.lods.map(\.vertices); childScene["triangles"] = leaf.lods.map(\.triangles)
                childScene["bounds"] = box
                if !box.isEmpty { childScene["rect"] = [box[0][0], -box[1][2], box[1][0], -box[0][2]] }
                try write(WorldPackage.json(childScene, pretty: false), base + "/scene.json"); chunks.append(child)
                childIDs.append(childID); if !box.isEmpty { childBoxes.append(box) }
            }
            // Retain source LOD1 as bounded coarse coverage until ALL child replacements are ready.
            var coarse: [[String: Any]] = []
            for leaf in try split([meshes[1]], budget: budget) {
                let e = leaf.lods[0], base = "chunks/" + id + ".coarse" + leaf.suffix
                var parentScene = scene, features = scene["features"] as! [[String: Any]]
                for i in features.indices {
                    let fi = features[i]["index"] as! Int
                    features[i]["lod0"] = ["static": [[Int]](), "water": [[Int]]()]
                    features[i]["lod1"] = ["static": e.ranges["worldStatic"]?[fi] ?? [], "water": e.ranges["worldWater"]?[fi] ?? []]
                }
                parentScene["features"] = features; parentScene["vertices"] = [0, e.vertices]; parentScene["triangles"] = [0, e.triangles]
                parentScene["bounds"] = e.bounds
                try write(e.data, base + "/lod1.glb"); try write(WorldPackage.json(parentScene, pretty: false), base + "/scene.json")
                coarse.append(["file": base + "/lod1.glb", "scene": base + "/scene.json", "sourceLOD": 1,
                               "decodedBytes": e.decoded, "glbBytes": e.data.count, "parts": e.parts,
                               "triangles": e.triangles, "bounds": e.bounds, "empty": e.triangles == 0])
            }
            let groupBounds: [[Double]] = childBoxes.isEmpty ? [] : [(0..<3).map { a in childBoxes.map { $0[0][a] }.min()! }, (0..<3).map { a in childBoxes.map { $0[1][a] }.max()! }]
            groups.append(["id": id, "parentIndex": parent["index"]!, "bounds": groupBounds, "children": childIDs,
                           "coarsePayloads": coarse, "switchRule": "Keep all parent coarse payloads until every required child LOD is ready; atomically replace the group. Never draw parent and child geometry together."])
        }
        var ownership: [String: Any] = [:]
        for ref in buildingBounds.keys.sorted() {
            let box = buildingBounds[ref]!
            ownership[ref] = ["buildingCell": [Int(floor((box[0] + box[2]) / 200)), Int(floor((box[1] + box[3]) / 200))],
                              "sourceParents": buildingParents[ref]!.sorted()]
        }
        let report: [String: Any] = ["format": "worldengine-adaptive-tiles/1", "sourceWorldSHA256": digest(sourceData),
            "uploadBytes": budget.uploadBytes, "primitiveDecodedBytes": budget.primitiveBytes, "leafDecodedBytes": budget.decodedLeafBytes, "twoTileDecodedQueueBytes": budget.queueBytes,
            "budgetSource": "web/stream/targets.md at A4 939d04f; mobile-rendering-v1/streaming-design.md section 7",
            "before": before, "after": after, "beforeTiles": original.count, "afterTiles": chunks.count,
            "memoryScope": "Decoded vertex/index arrays only; excludes retained world, worker copies, JS objects, GPU and textures"]
        world["chunks"] = chunks; world["files"] = hashes; world["tilePacking"] = report
        world["replacementGroups"] = groups
        world["featureOwnership"] = ["buildingCellMeters": 100, "frame": "package local east/north, origin 0,0", "rule": "floor of source LOD0 feature bounding-box centre / 100 m; stable across payload splits", "buildings": ownership]
        world["tileLayout"] = ["type": "adaptive-budget-bvh/1", "parentChunkSizeM": world["chunkSize"] ?? NSNull(),
                               "indexMeaning": "Parent grid index; not unique. Use id and actual bounds, which can overlap.",
                               "emptyLODMeaning": "emptyLODs are valid empty coverage; skip GLB decode/draw for that LOD", "replacement": "Atomic parent coverage groups; see replacementGroups"]
        var capabilities = world["capabilities"] as! [String: Any]
        capabilities["required"] = (capabilities["required"] as! [String]) + ["adaptive-budget-bvh/1 bounds, IDs, emptyLODs and atomic replacementGroups"]
        world["capabilities"] = capabilities
        try WorldPackage.json(world).write(to: output.appendingPathComponent("world.json"))
        return report
    }
}
