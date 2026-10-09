import CryptoKit
import Foundation
import WorldMesh

/// Separate, opt-in derivative database. No field is added to world.json or GLB.
public enum SurfaceCompanion {
    public enum Error: Swift.Error { case overlappingDestination, invalidAnnotations, invalidGLB }
    static func sha(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    static func triangles(_ mesh: MeshBuffers) throws -> [UInt16] {
        guard mesh.surfaceWords.isEmpty || mesh.surfaceWords.count == mesh.vertexCount else { throw Error.invalidAnnotations }
        if mesh.surfaceWords.isEmpty { return Array(repeating: 0, count: mesh.triangleCount) }
        return try stride(from: 0, to: mesh.indices.count, by: 3).map { i in
            let words = (i..<i+3).map { mesh.surfaceWords[Int(mesh.indices[$0])] }
            guard words[0] == words[1] && words[1] == words[2] else { throw Error.invalidAnnotations }
            return words[0]
        }
    }

    static func write(files: [String: Data], annotations: [String: [[UInt16]]], witnesses: [[String: Any]], to destination: URL) throws {
        var payload = Data(), entries: [[String: Any]] = []
        for path in files.keys.sorted() where path.hasSuffix(".glb") {
            let data = files[path]!
            guard data.count >= 20 else { throw Error.invalidGLB }
            let length = data[12..<16].enumerated().reduce(0) { $0 | Int($1.element) << ($1.offset * 8) }
            guard 20 + length <= data.count,
                  let glb = try JSONSerialization.jsonObject(with: data[20..<20+length]) as? [String: Any],
                  let meshes = glb["meshes"] as? [[String: Any]], let accessors = glb["accessors"] as? [[String: Any]] else { throw Error.invalidGLB }
            var annotatedPrimitive = 0
            for (mi, mesh) in meshes.enumerated() {
                guard let primitives = mesh["primitives"] as? [[String: Any]] else { throw Error.invalidGLB }
                for (pi, primitive) in primitives.enumerated() {
                    guard let index = primitive["indices"] as? Int, let count = accessors[index]["count"] as? Int, count % 3 == 0 else { throw Error.invalidGLB }
                    let words = annotations[path].map { $0[annotatedPrimitive] } ?? Array(repeating: UInt16(0), count: count / 3)
                    guard words.count == count / 3 else { throw Error.invalidAnnotations }
                    while payload.count % 4 != 0 { payload.append(0) }
                    let offset = payload.count
                    for word in words { payload.append(UInt8(word & 255)); payload.append(UInt8(word >> 8)) }
                    entries.append(["path": path, "sha256": sha(data), "mesh": mi, "primitive": pi,
                                    "lod": Int(path.components(separatedBy: "lod").last?.split(separator: ".").first ?? "0") ?? 0, "triangleCount": words.count, "byteOffset": offset])
                    annotatedPrimitive += 1
                }
            }
            if let annotated = annotations[path], annotated.count != annotatedPrimitive { throw Error.invalidAnnotations }
        }
        let index: [String: Any] = ["schema": "worldengine.surface-roles/1", "packageHash": ["path": "world.json", "sha256": sha(files["world.json"]!)],
            "payload": ["path": "triangles.u16le", "sha256": sha(payload), "bytes": payload.count],
            "roles": ["other", "roof", "wall", "trim", "door"], "materialClasses": SurfaceCapture.materials,
            "provenance": ["none", "mapped_tag", "family_inference"],
            "encoding": ["roleBits": [0, 2], "materialBits": [3, 7], "materialProvenanceBits": [8, 9], "colourProvenanceBits": [10, 11], "reservedBits": [12, 15]],
            "primitives": entries, "featureSources": witnesses,
            "scope": "Generation-time building semantics; unannotated nonbuilding triangles are other/unknown/none. No material class inferred from colour or family. Companion does not apply after repacking."]
        let json = try JSONSerialization.data(withJSONObject: index, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        // Do not remove directories supplied by the operator; overwrite only our three files.
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try payload.write(to: destination.appendingPathComponent("triangles.u16le"), options: .atomic)
        try json.write(to: destination.appendingPathComponent("index.json"), options: .atomic)
        let notice = "Surface-role derivative database: ODbL 1.0. Source attribution and data access: see the bound package LICENSE-DATA.md. Generated roles and colour choices are inferred unless an explicit source tag is recorded; material classes are explicit tags only.\n"
        try Data(notice.utf8).write(to: destination.appendingPathComponent("LICENSE-DATA.md"), options: .atomic)
    }
}
