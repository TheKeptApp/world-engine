// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "WorldEngine",
    platforms: [.iOS(.v26), .macOS(.v26)],
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
        // Pure Swift: procedural street-level detail (houses, sidewalks, props, vegetation), seeded by OSM ID.
        .target(name: "WorldGen", dependencies: ["WorldGeo", "WorldMap", "WorldMesh"], resources: [.copy("Profiles")]),
        // RealityKit + SwiftUI: the public engine surface.
        .target(name: "WorldEngine", dependencies: ["WorldGeo", "WorldMap", "WorldMesh", "WorldGen"], resources: [.process("Shaders")]),
        // macOS command-line tool: fetch area data, print stats, draw debug maps.
        .executableTarget(name: "worldbake", dependencies: ["WorldGeo", "WorldMap"]),

        .testTarget(name: "WorldGeoTests", dependencies: ["WorldGeo"]),
        .testTarget(
            name: "WorldMapTests",
            dependencies: ["WorldMap", "WorldGeo"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "WorldMeshTests", dependencies: ["WorldMesh", "WorldGeo"]),
        .testTarget(name: "WorldGenTests", dependencies: ["WorldGen", "WorldMap", "WorldMesh", "WorldGeo"]),
    ]
)
