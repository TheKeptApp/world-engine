# WorldEngine

A reusable Swift package that turns real-world map data (OpenStreetMap) into a stylized,
cartoon-but-semi-realistic 3D world, rendered with RealityKit inside SwiftUI. It has a
street-level third-person camera and an aerial diorama view.

It is app-agnostic. Host apps add their own characters as plain RealityKit entities.

- **Status:** foundation built; rendering next. See [docs/plan-m1.md](docs/plan-m1.md) and
  [docs/VISUAL_DIRECTION.md](docs/VISUAL_DIRECTION.md).
- **Demo app:** WorldLab (`Apps/WorldLab`, generated with XcodeGen).

## Layout

| Path | What |
|---|---|
| `Sources/WorldGeo` | Coordinates (exact WGS84 ↔ local meters), polygons, clipping, deterministic random |
| `Sources/WorldMap` | Raw OSM → typed features (buildings, roads, paths, sidewalks, areas, trees, benches, lamps) |
| `Sources/WorldMesh` | Earcut triangulation, footprint extrusion, road ribbons |
| `Sources/WorldEngine` | RealityKit/SwiftUI engine (public API) |
| `Sources/worldbake` | Data tool: `init-area`, `fetch`, `stats`, `datamap`, `ring-stats` |
| `Data/areas/` | Committed area extracts (ODbL) |
| `Apps/WorldLab` | Demo app (`project.yml` is the source of truth) |

## Commands

```bash
scripts/test.sh                      # unit tests
scripts/generate.sh                  # build pinned XcodeGen, generate WorldLab.xcodeproj
scripts/snapshots.sh worldlab-shell  # build, run in simulator, save screenshot
swift run worldbake stats Data/areas/sloans-lake
```

## Data attribution

Map data © OpenStreetMap contributors, available under the
[Open Database License (ODbL)](https://www.openstreetmap.org/copyright).
Any app built on WorldEngine must keep this attribution visible on the map.
