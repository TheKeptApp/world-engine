import SwiftUI

/// The three.js renderer screen (WKWebView). Filled in with the web renderer.
struct WebScreen: View {
    let options: LaunchOptions
    let backend: String
    let testRun: Bool

    var body: some View {
        Text("three.js renderer (\(backend)) not built yet").foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
}
