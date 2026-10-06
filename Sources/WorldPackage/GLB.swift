import Foundation

/// Minimal glTF 2.0 binary (.glb) writer for WorldEngine packages: one buffer, float32/uint16/
/// uint32 accessors, meshes with several primitives, underscore-prefixed custom attributes.
/// Output is deterministic (sorted JSON keys, fixed layout) so equal inputs give equal bytes.
public final class GLBBuilder {
    public enum ComponentType: Int {
        case unsignedShort = 5123, unsignedInt = 5125, float = 5126
    }

    private var bin = Data()
    private var bufferViews: [[String: Any]] = []
    private var accessors: [[String: Any]] = []
    private var materials: [[String: Any]] = []
    private var meshes: [[String: Any]] = []
    private var nodes: [[String: Any]] = []

    public init() {}

    private func align4() { while bin.count % 4 != 0 { bin.append(0) } }

    private func view(_ data: Data, target: Int?, stride: Int? = nil) -> Int {
        align4()
        var v: [String: Any] = ["buffer": 0, "byteOffset": bin.count, "byteLength": data.count]
        if let target { v["target"] = target }
        if let stride { v["byteStride"] = stride }
        bin.append(data)
        bufferViews.append(v)
        return bufferViews.count - 1
    }

    /// Float vertex attribute with `components` per element (1 = SCALAR … 4 = VEC4).
    public func floats(_ values: [Float], components: Int, minMax: Bool = false) -> Int {
        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        let v = view(data, target: 34962)
        var a: [String: Any] = ["bufferView": v, "componentType": ComponentType.float.rawValue,
                                "count": values.count / components, "type": Self.type(components)]
        if minMax, !values.isEmpty {
            var lo = [Float](repeating: .infinity, count: components), hi = [Float](repeating: -.infinity, count: components)
            for i in 0..<values.count { lo[i % components] = min(lo[i % components], values[i]); hi[i % components] = max(hi[i % components], values[i]) }
            a["min"] = lo.map(Double.init)
            a["max"] = hi.map(Double.init)
        }
        accessors.append(a)
        return accessors.count - 1
    }

    /// Unsigned integer vertex attribute (SCALAR), 16-bit when every value fits.
    public func uints(_ values: [UInt32]) -> Int {
        let small = values.allSatisfy { $0 <= UInt32(UInt16.max) }
        let data: Data = small
            ? values.map { UInt16($0) }.withUnsafeBufferPointer { Data(buffer: $0) }
            : values.withUnsafeBufferPointer { Data(buffer: $0) }
        let v = view(data, target: 34962)
        accessors.append(["bufferView": v, "componentType": (small ? ComponentType.unsignedShort : .unsignedInt).rawValue,
                          "count": values.count, "type": "SCALAR"])
        return accessors.count - 1
    }

    /// Triangle indices (uint32).
    public func indices(_ values: [UInt32]) -> Int {
        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        let v = view(data, target: 34963)
        accessors.append(["bufferView": v, "componentType": ComponentType.unsignedInt.rawValue, "count": values.count, "type": "SCALAR"])
        return accessors.count - 1
    }

    /// A fallback PBR material. Renderers that understand the package replace it by `name`.
    public func material(name: String, baseColor: [Double] = [0.8, 0.8, 0.8, 1], roughness: Double = 0.85, doubleSided: Bool = false) -> Int {
        materials.append(["name": name, "doubleSided": doubleSided,
                          "pbrMetallicRoughness": ["baseColorFactor": baseColor, "metallicFactor": 0.0, "roughnessFactor": roughness]])
        return materials.count - 1
    }

    /// A primitive: attribute name → accessor, indices accessor, material.
    public func primitive(attributes: [String: Int], indices: Int, material: Int) -> [String: Any] {
        ["attributes": attributes, "indices": indices, "material": material, "mode": 4]
    }

    public func mesh(name: String, primitives: [[String: Any]]) -> Int {
        meshes.append(["name": name, "primitives": primitives])
        return meshes.count - 1
    }

    public func node(name: String, mesh: Int, translation: [Double]? = nil, extras: [String: Any]? = nil) -> Int {
        var n: [String: Any] = ["name": name, "mesh": mesh]
        if let translation { n["translation"] = translation }
        if let extras { n["extras"] = extras }
        nodes.append(n)
        return nodes.count - 1
    }

    /// The finished .glb bytes.
    public func encoded(generator: String = "WorldEngine worldbake", extras: [String: Any]? = nil) throws -> Data {
        align4()
        var json: [String: Any] = [
            "asset": ["version": "2.0", "generator": generator],
            "scene": 0,
            "scenes": [["nodes": Array(0..<nodes.count)]],
            "nodes": nodes, "meshes": meshes, "materials": materials,
            "accessors": accessors, "bufferViews": bufferViews,
            "buffers": [["byteLength": bin.count]],
        ]
        if let extras { json["extras"] = extras }
        var jsonData = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .withoutEscapingSlashes])
        while jsonData.count % 4 != 0 { jsonData.append(0x20) }
        var out = Data()
        func u32(_ v: Int) { var x = UInt32(v).littleEndian; withUnsafeBytes(of: &x) { out.append(contentsOf: $0) } }
        u32(0x4654_6C67)                                // "glTF"
        u32(2)
        u32(12 + 8 + jsonData.count + 8 + bin.count)
        u32(jsonData.count); u32(0x4E4F_534A)           // "JSON"
        out.append(jsonData)
        u32(bin.count); u32(0x004E_4942)                // "BIN\0"
        out.append(bin)
        return out
    }

    static func type(_ components: Int) -> String {
        switch components { case 1: "SCALAR"; case 2: "VEC2"; case 3: "VEC3"; default: "VEC4" }
    }
}

/// Reads the subset of glTF binary that `GLBBuilder` writes (tests and tools).
public struct GLBFile {
    public let json: [String: Any]
    public let bin: Data

    public enum ReadError: Error { case notGLB, missingChunk }

    public init(data: Data) throws {
        func u32(_ o: Int) -> Int { Int(data.subdata(in: o..<(o + 4)).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }) }
        guard data.count >= 20, u32(0) == 0x4654_6C67, u32(4) == 2 else { throw ReadError.notGLB }
        let jsonLength = u32(12)
        guard u32(16) == 0x4E4F_534A else { throw ReadError.missingChunk }
        json = try JSONSerialization.jsonObject(with: data.subdata(in: 20..<(20 + jsonLength))) as? [String: Any] ?? [:]
        let binStart = 20 + jsonLength
        guard data.count >= binStart + 8, u32(binStart + 4) == 0x004E_4942 else { throw ReadError.missingChunk }
        bin = data.subdata(in: (binStart + 8)..<(binStart + 8 + u32(binStart)))
    }

    var accessors: [[String: Any]] { json["accessors"] as? [[String: Any]] ?? [] }
    var bufferViews: [[String: Any]] { json["bufferViews"] as? [[String: Any]] ?? [] }

    public var nodes: [[String: Any]] { json["nodes"] as? [[String: Any]] ?? [] }
    public var meshes: [[String: Any]] { json["meshes"] as? [[String: Any]] ?? [] }
    public var materialNames: [String] { (json["materials"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String } }

    /// Primitive `p` of mesh `m`: attribute accessors, indices accessor and material index.
    public func primitive(mesh m: Int, _ p: Int) -> (attributes: [String: Int], indices: Int, material: Int) {
        let prim = (meshes[m]["primitives"] as! [[String: Any]])[p]
        return (prim["attributes"] as! [String: Int], prim["indices"] as! Int, prim["material"] as! Int)
    }

    public func primitiveCount(mesh m: Int) -> Int { (meshes[m]["primitives"] as? [[String: Any]])?.count ?? 0 }

    private func bytes(_ accessor: Int) -> (Data, [String: Any]) {
        let a = accessors[accessor]
        let v = bufferViews[a["bufferView"] as! Int]
        let start = (v["byteOffset"] as? Int ?? 0) + (a["byteOffset"] as? Int ?? 0)
        return (bin.subdata(in: start..<(start + (v["byteLength"] as! Int))), a)
    }

    public func floats(_ accessor: Int) -> [Float] {
        let (d, _) = bytes(accessor)
        return d.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }

    public func uints(_ accessor: Int) -> [UInt32] {
        let (d, a) = bytes(accessor)
        switch a["componentType"] as! Int {
        case GLBBuilder.ComponentType.unsignedShort.rawValue: return d.withUnsafeBytes { $0.bindMemory(to: UInt16.self).map(UInt32.init) }
        default: return d.withUnsafeBytes { Array($0.bindMemory(to: UInt32.self)) }
        }
    }
}
