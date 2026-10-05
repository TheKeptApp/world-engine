import Foundation
import Network

/// A tiny HTTP/1.1 file server on 127.0.0.1 (loopback only) for the bundled three.js renderer.
/// WebGPU needs a secure context; loopback http is one. Mounts map URL prefixes to folders.
final class LocalServer: @unchecked Sendable {
    private let listener: NWListener
    private let mounts: [(prefix: String, directory: URL)]
    private let queue = DispatchQueue(label: "worldlab.localserver")
    private(set) var port: UInt16 = 0

    init(mounts: [(String, URL)]) throws {
        self.mounts = mounts.sorted { $0.0.count > $1.0.count }
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: params)
    }

    /// Starts listening and returns the chosen port.
    func start() async throws -> UInt16 {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UInt16, Error>) in
            // State changes arrive on `queue` only, so this flag needs no further locking.
            final class Once: @unchecked Sendable { var done = false }
            let once = Once()
            listener.stateUpdateHandler = { [weak self] state in
                guard let self, !once.done else { return }
                switch state {
                case .ready:
                    once.done = true
                    self.port = self.listener.port?.rawValue ?? 0
                    cont.resume(returning: self.port)
                case .failed(let e):
                    once.done = true
                    cont.resume(throwing: e)
                default: break
                }
            }
            listener.newConnectionHandler = { [weak self] c in self?.serve(c) }
            listener.start(queue: queue)
        }
    }

    func stop() { listener.cancel() }

    private func serve(_ c: NWConnection) {
        c.start(queue: queue)
        receiveRequest(c, buffer: Data())
    }

    private func receiveRequest(_ c: NWConnection, buffer: Data) {
        c.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, done, error in
            guard let self else { return }
            var buf = buffer
            if let data { buf.append(data) }
            if let end = buf.range(of: Data("\r\n\r\n".utf8)) {
                let head = String(decoding: buf[..<end.lowerBound], as: UTF8.self)
                self.respond(c, requestLine: head.components(separatedBy: "\r\n").first ?? "")
            } else if done || error != nil {
                c.cancel()
            } else {
                self.receiveRequest(c, buffer: buf)
            }
        }
    }

    private func respond(_ c: NWConnection, requestLine: String) {
        let parts = requestLine.split(separator: " ")
        var status = "404 Not Found", body = Data("not found".utf8), type = "text/plain"
        if parts.count >= 2, parts[0] == "GET" || parts[0] == "HEAD" {
            let raw = String(parts[1].split(separator: "?").first ?? "/")
            let path = raw.removingPercentEncoding ?? raw
            if let file = resolve(path), let data = try? Data(contentsOf: file, options: .mappedIfSafe) {
                status = "200 OK"
                body = parts[0] == "HEAD" ? Data() : data
                type = Self.types[file.pathExtension.lowercased()] ?? "application/octet-stream"
            }
        }
        var head = "HTTP/1.1 \(status)\r\nContent-Type: \(type)\r\nContent-Length: \(body.count)\r\n"
        head += "Cache-Control: no-cache\r\nConnection: close\r\n\r\n"
        c.send(content: Data(head.utf8) + body, completion: .contentProcessed { _ in c.cancel() })
    }

    private func resolve(_ path: String) -> URL? {
        for (prefix, dir) in mounts where path.hasPrefix(prefix) {
            var rel = String(path.dropFirst(prefix.count))
            if rel.isEmpty { rel = "index.html" }
            let url = dir.appendingPathComponent(rel).standardizedFileURL
            guard url.path.hasPrefix(dir.standardizedFileURL.path) else { return nil }
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue { return url }
            return nil
        }
        return nil
    }

    static let types = ["html": "text/html", "js": "text/javascript", "json": "application/json", "glb": "model/gltf-binary",
                        "png": "image/png", "bin": "application/octet-stream"]
}
