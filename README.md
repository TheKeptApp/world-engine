# WorldEngine

A reusable Swift package that turns real-world map data (OpenStreetMap) into a stylized,
cartoon-but-semi-realistic 3D world, rendered with RealityKit inside SwiftUI. It has a
street-level third-person camera and an aerial diorama view.

It is app-agnostic. Host apps add their own characters as plain RealityKit entities.

- **Status:** first visual milestone (street of houses + lake path, street camera) built; iOS 26.0 minimum. See [docs/plan-m1.md](docs/plan-m1.md) and
  [docs/VISUAL_DIRECTION.md](docs/VISUAL_DIRECTION.md).
- **Demo app:** WorldLab (`Apps/WorldLab`, generated with XcodeGen).

## Layout

| Path | What |
|---|---|
| `Sources/WorldGeo` | Coordinates (exact WGS84 ↔ local meters), polygons, clipping, deterministic random |
| `Sources/WorldMap` | Raw OSM → typed features (buildings, roads, paths, sidewalks, areas, trees, benches, lamps) |
| `Sources/WorldMesh` | Earcut triangulation, footprint extrusion, road ribbons |
| `Sources/WorldGen` | Street-level generation (houses, roofs, sidewalks, curbs, lamps, trees, clutter) + regional style profiles (data) |
| `Sources/WorldEngine` | RealityKit/SwiftUI engine (public API), Metal shaders |
| `Sources/worldbake` | Data tool: `init-area`, `fetch`, `stats`, `datamap`, `ring-stats` |
| `Data/areas/` | Committed area extracts (ODbL) |
| `Apps/WorldLab` | Demo app (`project.yml` is the source of truth) |

## Commands

```bash
scripts/test.sh                      # unit tests
scripts/generate.sh                  # build pinned XcodeGen, generate WorldLab.xcodeproj
scripts/snapshots.sh out.png -preset street-mid   # build, run in simulator, save screenshot
scripts/device.sh build              # Release build + install on the connected iPhone
scripts/device_snapshots.sh          # on-device screenshots (showcase 01-12, v2 presets) pulled to docs/screenshots/m3/device
scripts/walk_test.sh baseline        # 10-minute device walk: fps, memory, heat + GPU samples
swift run worldbake stats Data/areas/sloans-lake
```

## Data attribution

Map data © OpenStreetMap contributors, available under the
[Open Database License (ODbL)](https://www.openstreetmap.org/copyright).
Any app built on WorldEngine must keep this attribution visible on the map.
It must also show the engine's credits (`WorldCreditsView`, or `WorldCreditsButton` beside the world)
and pass every exported image through `WorldCredits.burnIn(...)`. World packages carry their licence
notice in `LICENSE-DATA.md`. See `docs/data-licensing.md`.
