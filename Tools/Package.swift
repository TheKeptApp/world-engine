// swift-tools-version:5.9
// Build-time tools only. Nothing here ships in an app.
import PackageDescription

let package = Package(
    name: "Tools",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.46.0"),
    ],
    targets: []
)
