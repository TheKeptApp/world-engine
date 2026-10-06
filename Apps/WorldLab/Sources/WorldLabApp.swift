import SwiftUI

@main
struct WorldLabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    if ProcessInfo.processInfo.arguments.contains("-weatherkit-probe") { await WeatherKitProbe.run() }
                }
        }
    }
}
