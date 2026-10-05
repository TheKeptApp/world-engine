// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "WorldEngine",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Host apps depend on this product only.
        .library(name: "WorldEngine", targets: ["WorldEngine"]),
    ],
    targets: [
        // Pure Swift: geographic coordinates, local frames, 2D polygons, clipping, seeds.
        .target(name: "WorldGeo"),
        // Pure Swift: raw OSM (Overpass JSON) → typed map features.
        .target(name: "WorldMap", dependencies: ["WorldGeo"]),
        // Pure Swift + simd: triangulation, extrusion, ribbons → plain mesh buffers.
        .target(name: "WorldMesh", dependencies: ["WorldGeo"]),
        // RealityKit + SwiftUI: the public engine surface.
        .target(name: "WorldEngine", dependencies: ["WorldGeo", "WorldMap", "WorldMesh"]),
        // macOS command-line tool: fetch area data, print stats, draw debug maps.
        .executableTarget(name: "worldbake", dependencies: ["WorldGeo", "WorldMap"]),

        .testTarget(name: "WorldGeoTests", dependencies: ["WorldGeo"]),
        .testTarget(
            name: "WorldMapTests",
            dependencies: ["WorldMap", "WorldGeo"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "WorldMeshTests", dependencies: ["WorldMesh", "WorldGeo"]),
    ]
)
