import SwiftUI
import WebKit

/// The three.js renderer in a WKWebView. A loopback server serves the bundled web app (dist),
/// the shared world package and the dog export; the page reports frame intervals back through
/// the "worldlab" message handler into the same TestRun the RealityKit screen uses.
struct WebScreen: View {
    let options: LaunchOptions
    let backend: String
    let testRun: Bool
    @State private var model = WebModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let url = model.url {
                WebView(url: url, model: model).ignoresSafeArea()
            } else if let e = model.error {
                Text(e).foregroundStyle(.white).padding()
            } else {
                ProgressView("Starting web renderer…").tint(.white).foregroundStyle(.white)
            }
        }
        .task { await model.start(options: options, backend: backend, testRun: testRun) }
    }
}

@MainActor
@Observable
final class WebModel: NSObject, WKScriptMessageHandler {
    var url: URL?
    var error: String?
    @ObservationIgnored var server: LocalServer?
    @ObservationIgnored var test: TestRun?
    @ObservationIgnored weak var webView: WKWebView?
    @ObservationIgnored private var statusTimer: Timer?
    @ObservationIgnored private var requested = ""

    func start(options: LaunchOptions, backend: String, testRun: Bool) async {
        guard server == nil else { return }
        requested = backend
        do {
            let demo = try DemoConfig.load()
            let bundle = Bundle.main.bundleURL
            let s = try LocalServer(mounts: [
                ("/world/", bundle.appendingPathComponent("package/\(demo.area)")),
                ("/dog/", bundle.appendingPathComponent("dog")),
                ("/", bundle.appendingPathComponent("dist")),
            ])
            let port = try await s.start()
            server = s
            var q = [URLQueryItem(name: "backend", value: backend), URLQueryItem(name: "hud", value: options.hud ? "1" : "0")]
            if let p = options.preset { q.append(URLQueryItem(name: "preset", value: p)) }
            if options.frame16x9 { q.append(URLQueryItem(name: "frame16x9", value: "1")) }
            if options.diagnostics.contains("noPost") { q.append(URLQueryItem(name: "post", value: "0")) }
            if options.diagnostics.contains("noShadows") { q.append(URLQueryItem(name: "shadows", value: "0")) }
            for key in ["matdebug", "sun", "env", "bg", "tm"] {
                if let m = ProcessInfo.processInfo.arguments.firstIndex(of: "-\(key)").map({ ProcessInfo.processInfo.arguments[$0 + 1] }) {
                    q.append(URLQueryItem(name: key, value: m))
                }
            }
            var c = URLComponents(string: "http://127.0.0.1:\(port)/index.html")!
            c.queryItems = q
            if testRun || options.metrics { test = TestRun(renderer: "threejs-\(backend)", stats: nil) }
            url = c.url
        } catch {
            self.error = "Web renderer failed to start: \(error)"
        }
    }

    nonisolated func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as? [String: Any] ?? [:]
        MainActor.assumeIsolated { handle(body) }
    }

    private func handle(_ body: [String: Any]) {
        switch body["type"] as? String {
        case "ready":
            let actual = body["backend"] as? String ?? "?"
            print("WEB ready backend=\(actual) requested=\(requested) drawable=\(body["drawable"] ?? "?") pixelRatio=\(body["pixelRatio"] ?? "?")")
            if let test {
                test.note = "backend=\(actual) requested=\(requested) drawable=\((body["drawable"] as? [Int])?.map(String.init).joined(separator: "x") ?? "?")"
                test.begin()
                statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated { self?.pushStatus() }
                }
            }
        case "frames":
            guard let test, let intervals = body["intervals"] as? [Double] else { return }
            for ms in intervals { test.frame(dt: ms / 1000, gpuMs: nil) }
        case "log":
            print("WEB \(body["level"] ?? "log"): \(body["message"] ?? "")")
        case "error":
            print("WEB error \(body["message"] ?? "")")
            error = "Web renderer error: \(body["message"] ?? "")"
        default:
            break
        }
    }

    private func pushStatus() {
        guard let test, let data = try? JSONSerialization.data(withJSONObject: [test.statusLine]),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.worldlabStatus = \(json)[0]")
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    let model: WebModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(model, name: "worldlab")
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isInspectable = true
        model.webView = view
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {}
}
