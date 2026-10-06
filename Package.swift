// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "WorldEngine",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        // Host apps depend on this product only.
        .library(name: "WorldEngine", targets: ["WorldEngine"]),
        // Renderer-neutral environment resolver (weather, sky, seasons).
        .library(name: "WorldEnvironment", targets: ["WorldEnvironment"]),
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
        .target(name: "WorldEngine", dependencies: ["WorldGeo", "WorldMap", "WorldMesh", "WorldGen", "WorldEnvironment"], resources: [.process("Shaders")]),
        // Pure Swift: time, weather, sky and season resolved into the environment.json contract.
        .target(name: "WorldEnvironment", dependencies: ["WorldGeo", "WorldMap", "WorldGen"], resources: [.copy("Catalog")]),
        // Shared world package (glTF + JSON) for renderers other than RealityKit (macOS tooling).
        .target(name: "WorldPackage", dependencies: ["WorldGeo", "WorldMap", "WorldMesh", "WorldGen"]),
        // macOS command-line tool: fetch area data, print stats, draw debug maps, export packages.
        .executableTarget(name: "worldbake", dependencies: ["WorldGeo", "WorldMap", "WorldGen", "WorldPackage"]),
        // macOS command-line debug renderer for generated buildings (CPU rasterizer, no RealityKit).
        .executableTarget(name: "buildingviz", dependencies: ["WorldGeo", "WorldMap", "WorldMesh", "WorldGen"]),

        .testTarget(name: "WorldGeoTests", dependencies: ["WorldGeo"]),
        .testTarget(
            name: "WorldMapTests",
            dependencies: ["WorldMap", "WorldGeo"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(name: "WorldMeshTests", dependencies: ["WorldMesh", "WorldGeo"]),
        .testTarget(name: "WorldGenTests", dependencies: ["WorldGen", "WorldMap", "WorldMesh", "WorldGeo"]),
        .testTarget(name: "WorldEnvironmentTests", dependencies: ["WorldEnvironment", "WorldGeo", "WorldGen"]),
        .testTarget(name: "WorldPackageTests", dependencies: ["WorldPackage", "WorldGen", "WorldMap", "WorldMesh", "WorldGeo"]),
    ]
)
