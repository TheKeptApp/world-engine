# WorldEngine: Milestone 1 technical plan

Status: proposal, awaiting approval. No feature code has been written.
Toolchain on the build Mac (checked 2026-10-05): Xcode 26.4, Swift 6.3, iOS 26.4 SDK, iPhone 17-series simulators. No Homebrew, XcodeGen or Tuist is installed.

---

## 0. Area check (coordinates verified against OpenStreetMap)

| Feature | OSM object | Bounds (lat / lon) | Center |
|---|---|---|---|
| Sloan's Lake (water) | relation 4049789 | 39.7441–39.7527 / −105.0531 to −105.0368 | 39.7484, −105.0449 |
| Sloan's Lake Park | relation 20618025 | 39.7440–39.7548 / −105.0532 to −105.0358 | 39.7494, −105.0445 |

The center in the brief (39.750, −105.045) is correct. It sits on the water about 180 m north of the lake's middle and about 70 m from the park's center.

**One issue.** The lake is about 1.4 km east–west and 0.95 km north–south, and the park is about 1.5 × 1.2 km. A 1 × 1 km box cuts off both ends of the lake.

I measured both options with live Overpass queries (data timestamp 2026-10-05):

| | **A: 1.0 × 1.0 km** (as briefed) | **B: 1.6 × 1.2 km** (recommended) |
|---|---|---|
| Center | 39.7500, −105.0450 | 39.7494, −105.0445 (park center) |
| Bounding box (S, W, N, E) | 39.7455, −105.0508, 39.7545, −105.0392 | 39.7440, −105.0538, 39.7548, −105.0352 |
| Raw Overpass JSON | 1.9 MB (214 KB gzipped) | 4.2 MB (470 KB gzipped) |
| Buildings | 555 | 1,400 |
| …with a `height` tag | 0 | 1 |
| …with `building:levels` | 55 (10%) | 131 (9%) |
| Roads and paths (ways) | 277 | 617 |
| Mapped individual trees (`natural=tree`) | 2,270 | 5,389 |
| Lake and park complete? | No, both clipped | Yes |

**Recommendation:** use B. The whole lake and park fit, and the data and triangle budget stay small. If you prefer A, the plan works unchanged except that the lake and park polygons get clipped at the box edge (section 3.4).

Three findings from the measurement shape the plan:
1. Nearly no building has a real height, and only about 10% have a floor count. **The height fallback by building type decides how about 90% of the city looks.**
2. Most buildings are houses, detached garages and sheds (about 95%), so typical buildings are small and low-poly.
3. Thousands of trees are already mapped as individual points. We will place those first and scatter extra trees only into park areas that have none nearby.

---

## 1. Repo and project structure

```
world-engine/
├── Package.swift                  # the WorldEngine Swift package (the thing apps depend on)
├── Sources/
│   ├── WorldGeo/                  # pure Swift: lat/lon ↔ local meters, bounding boxes
│   ├── WorldMap/                  # pure Swift: Overpass JSON parsing, ring assembly, feature
│   │                              #   classification (tags → building/road/area/tree), height rules
│   ├── WorldMesh/                 # pure Swift + simd: triangulation, clipping, extrusion, road
│   │                              #   ribbons, tree generation → plain vertex/index buffers
│   ├── WorldEngine/               # RealityKit + SwiftUI: the ONLY public module apps import
│   │                              #   (World, WorldView, camera, materials, placement, routes)
│   └── worldbake/                 # macOS command-line tool: fetch Overpass data, write manifest
├── Tests/
│   ├── WorldGeoTests/  WorldMapTests/  WorldMeshTests/   # run with `swift test` on the Mac
│   ├── WorldEngineTests/                                 # run on the iOS simulator
│   └── Fixtures/                                         # tiny hand-written OSM files
├── Data/
│   └── areas/sloans-lake/         # raw extract + query + manifest (ODbL data, see §6)
├── Apps/
│   └── WorldLab/
│       ├── project.yml            # XcodeGen spec (the source of truth for the Xcode project)
│       └── Sources/ Resources/
├── Tools/
│   └── Package.swift              # pins the XcodeGen version; built locally, no Homebrew
├── scripts/
│   ├── generate.sh                # build pinned XcodeGen → generate WorldLab.xcodeproj
│   ├── test.sh                    # swift test + simulator tests
│   └── snapshots.sh               # build, launch in simulator, capture screenshots
└── docs/
    ├── plan-m1.md
    ├── integration-contract.md    # (M1) the shareable API doc from §7
    └── screenshots/m1/
```

**Why four modules:** everything except `WorldEngine` is pure Swift with no RealityKit, so geometry and data logic can be unit-tested quickly on the Mac without a simulator. Later the same code could run in an offline bake tool or on a server. Host apps see only `WorldEngine`, which keeps the public surface small. The internals stay `package`-visible rather than public.

**Settings:** Swift 6 language mode with strict concurrency. Minimum iOS 18.0, the first version with `LowLevelMesh`, `RealityView` on iOS and `OrthographicCameraComponent`. Host apps would need iOS 18 or later; tell me if any of them target lower.

**Engine vs. demo data:** the engine does not bundle Sloan's Lake. WorldLab bundles `Data/areas/sloans-lake/` as an app resource and passes the file URL to the engine. Any app can load any area the same way.

### Generating the Xcode project: XcodeGen (recommended)

| Option | Verdict |
|---|---|
| **XcodeGen** | **Recommended.** One short `project.yml` describes the WorldLab app. Running it regenerates `WorldLab.xcodeproj` deterministically. The `.xcodeproj` is git-ignored, so it can never drift or cause merge conflicts, and no one hand-edits it. It's mature, MIT-licensed, a build-time tool only, and nothing ships in the app. |
| Tuist | More powerful, but heavier. It needs its own installer (mise), has its own project DSL and cache, and pushes its cloud features. That's overkill for one demo app. |
| Hand-made `.xcodeproj` | Rejected. It's opaque and merge-hostile, and you'd eventually have to click through Xcode settings. |
| Swift Playgrounds `.swiftpm` app | Can't cleanly express a separate test target and resource layout, and is awkward for command-line builds. |

**How it's installed without Homebrew:** `Tools/Package.swift` declares XcodeGen at an exact version. `scripts/generate.sh` builds it once with `swift build` into `Tools/.build/`, which is git-ignored, then runs it. The version is pinned in `Tools/Package.resolved`, so every machine gets the same generator. The first run downloads XcodeGen's source from GitHub. **I'll ask before that download in step 2.**

---

## 2. Data pipeline

### Fetch (once, by me, with the `worldbake` tool)
- One Overpass query for the bounding box. It collects:
  - buildings: `building=*` ways and relations
  - roads and paths: `highway=*` ways
  - water: `natural=water`, `waterway=*`
  - green areas: `leisure=park|garden|pitch|playground`, `landuse=grass|forest|recreation_ground|meadow`, `natural=wood|scrub|grassland`
  - trees: `natural=tree` nodes and `natural=tree_row` ways
  - every node those ways and relations need
- Output is `out body`, **not** `out meta`. That keeps contributor usernames, user IDs and edit timestamps out of the repo, so no personal data gets in.
- The tool sends a descriptive User-Agent, makes a single request, and falls back across public Overpass mirrors. **Today the main Overpass server returned "too busy" or timeout errors on two of three tries.** That alone justifies committing the data.

### Store (in the repo, so builds never touch the network)
```
Data/areas/sloans-lake/
  overpass.json      # raw Overpass JSON, unmodified: ~4.2 MB for area B (~1.9 MB for A)
  query.overpassql   # the exact query, so anyone can re-fetch
  manifest.json      # bbox, center, OSM data timestamp, fetch date, query hash, license = ODbL-1.0
  NOTICE.md          # "© OpenStreetMap contributors, ODbL" + link
```
4 MB of JSON is fine in git. If we later add many areas (more than about 50 MB in total), we switch to compressed `.json.gz` or Git LFS.

### Load (at runtime, in the engine)
1. **Parse:** decode the Overpass JSON into nodes, ways and relations (`Codable`, on a background task).
2. **Assemble rings:** join multipolygon relation member ways into closed rings, then assign inner rings (holes) to their containing outer ring by point-in-polygon. The lake and park are multipolygon relations.
3. **Classify:** turn tags into a typed feature model: `Building`, `Road(kind, width)`, `Area(kind)`, `Tree`. Unknown tags are ignored and counted in the load report.
4. **Project:** convert to local meters (section 3.1) and clip to the area box (section 3.4).
5. **Build meshes:** see section 3.

The typed feature model (step 3) is the seam for future data sources. Overture and lidar heights get merged here, keyed by OSM ID or by footprint overlap, without touching the geometry code.

Expected load time for area B: parsing 4 MB of JSON plus building meshes is on the order of a few hundred milliseconds on a recent iPhone. M1 measures the real number. If it's too slow, M2 adds a compact pre-baked binary format produced by `worldbake`.

### Building heights now (M1)
Applied in order, first match wins:
1. `height` tag. Accepts `12`, `12 m`, `12.5m`, `40'` and `40'6"` (feet converted to meters). Garbage values fall through to the next rule.
2. `building:levels` × 3.2 m, plus `roof:levels` × 3.2 m if present.
3. **Default by `building` type:**

| Type | Default height |
|---|---|
| `house`, `detached`, `semidetached_house` | 7.0 m |
| `residential`, `terrace` | 8.0 m |
| `garage`, `garages`, `carport` | 3.0 m |
| `shed` | 2.5 m |
| `roof` (canopy) | thin slab at 3.0 m |
| `apartments` | 12.8 m (4 levels) |
| `commercial`, `retail` | 5.0 m |
| `office` | 10.0 m |
| `church` | 10.0 m |
| `school` | 8.0 m |
| `industrial`, `warehouse` | 7.0 m |
| `yes` and anything unknown | 6.0 m |

`min_height` (when present) lifts the base. Fallback heights get a **deterministic ±10% jitter seeded by the OSM ID**, so a street of identical houses doesn't look stamped out, and the result is identical on every run. All defaults live in a `HeightRules` value that apps can override.

### Building heights later (M2 or later)
- **Overture Maps buildings** include a `height` attribute for many buildings. Its sources vary by region, so first we check how much of this area it actually covers. Overture buildings are themselves ODbL (they include OSM), so mixing them in keeps the same license obligations (section 6).
- **USGS 3DEP lidar** (public domain) is the more direct option: for each footprint, take a high percentile of the lidar surface model minus the ground model. `worldbake` would do this offline and write a small `heights.json` keyed by OSM way ID. The engine then uses it as rule 0, ahead of everything above.
- Height sources merge into the feature model only, so this is a data change, not an engine change.

---

## 3. Geometry

### 3.1 Coordinates
- Exact WGS84 → ECEF → local ENU (east, north, up) around the area center, computed in `Double`. Over 1–2 km the curvature drop is about 8 cm, so we discard the up component and treat the ground as flat in M1.
- RealityKit axes (right-handed, Y up): **east = +X, north = −Z, up = +Y**, in meters. Vertex buffers use `Float`. At ≤1 km from the origin, Float precision is about 0.06 mm.
- **Terrain is assumed flat in M1.** The area is gently sloped. Real elevation (USGS DEM) is a later milestone, and the placement APIs already return ground-snapped positions, so callers won't change.

### 3.2 Polygon triangulation (including holes and courtyards)
- **Algorithm:** a Swift port of **earcut** (Mapbox; ISC license; the notice is kept). It's the standard choice for map footprints. It handles concave shapes and holes by bridging each hole into the outer ring, it's fast and simple, and it needs no dependency.
- **Clean-up before triangulating:**
  - drop the duplicated closing point
  - merge points closer than 1 cm
  - remove collinear points
  - force the outer ring counter-clockwise and holes clockwise (viewed from above)
  - drop rings with an area under 0.5 m²
- **Bad data:** if a ring self-intersects or earcut's area check fails (triangle-area sum vs. polygon area off by more than 1%), skip that feature, log its OSM ID and count it in the load report. One broken building never breaks the world.

### 3.3 Building extrusion
- **Walls:** one quad (2 triangles) per edge of every ring, outer ring and courtyard holes alike. Each quad has its own outward-facing normal. Hole edges face into the courtyard automatically because of the winding rule above.
- **Roof:** the triangulated footprint at height *h*, facing up. No floor (never visible).
- **Flat shading:** each face gets its own vertices with the face normal, so no smoothing between faces and a crisp low-poly look.
- `building=roof` (carport canopies) is a thin slab with no walls.
- Typical house with 8–9 footprint corners: about 16 wall triangles plus about 7 roof triangles, roughly 23 triangles.
- `building:part` and roof shapes (gabled, hipped) are out of scope for M1.

### 3.4 Clipping to the area box
Features that straddle the box edge are clipped to the box:
- **Polygons:** Sutherland–Hodgman against the box, applied to outer and inner rings. It works for concave polygons because the clip region is convex.
- **Lines:** Liang–Barsky, segment by segment.

Buildings are kept whole if their centroid is inside the box, so we never get half-houses.

### 3.5 Road and path ribbons
- **Width:** the `width` tag if present, else `lanes` × 3.3 m, else a default by type:

| Type | Default width |
|---|---|
| primary | 12 m |
| secondary | 10 m |
| tertiary | 8 m |
| residential, unclassified | 6 m |
| service | 4 m |
| cycleway | 2.5 m |
| footway, path, pedestrian | 2 m |
| track | 3 m |

- **Ribbon:** offset the polyline left and right by half the width. Joins are mitered, falling back to a bevel when the miter exceeds 2× the half-width (sharp turns). Duplicate points are removed first, which prevents NaNs.
- **Overlaps:** roads overlap at intersections. Ribbons of the same material overlapping at the same height are invisible as seams, so M1 doesn't need true intersection geometry.

### 3.6 Ground layers (no flicker)
- **Layers, bottom to top:**
  1. base ground plane (covers the whole area)
  2. parks and grass
  3. water
  4. roads
  5. paths
- **How each layer stays visible:** each layer is also raised a few centimeters, and draw order is fixed with `ModelSortGroupComponent`. That's RealityKit's built-in way to stop flicker between overlapping flat surfaces. The offsets alone would flicker when the camera is far away.

### 3.7 Trees
- **Mapped trees:** every mapped `natural=tree` node becomes a tree.
- **Scattered trees:** park and wood polygons get extra trees by Poisson-disk sampling (minimum spacing about 8 m). Candidates are rejected if they are within 6 m of a mapped tree, within 2 m of a path or road ribbon, or inside water or a pitch. A seeded random generator keeps the result identical every run.
- **Model:** a low-poly tree with a faceted canopy (an icosahedron squashed vertically, 20 triangles) and a 3-sided trunk (6 triangles), so about 26 triangles each. Scale and rotation vary per tree, using the same seeded generator.
- **Batching:** all trees are merged into two meshes, canopy and trunk.

### 3.8 Which RealityKit mesh API: `LowLevelMesh` (recommended)
| | `MeshDescriptor` → `MeshResource.generate` | **`LowLevelMesh`** (iOS 18+) |
|---|---|---|
| Vertex layout | RealityKit decides; positions, normals and UVs as Swift arrays | We define it exactly (interleaved position and normal, `uint32` indices) |
| Build cost | RealityKit re-processes the arrays on the CPU | We write straight into GPU buffers; no extra processing pass |
| Multiple materials in one mesh | Yes (via parts) | Yes (`LowLevelMesh.Part` with a `materialIndex`) |
| Updating later | Regenerate the whole resource | Update buffers in place (useful for weather, e.g. snow, or streaming chunks) |
| Ease | Easier | More code, but contained in one file |

**Choice: `LowLevelMesh`.** Geometry code outputs plain `MeshBuffers` (positions, normals, indices, material slot). A small adapter in `WorldEngine` copies them into a `LowLevelMesh` and wraps that in a `MeshResource`. The adapter is the only RealityKit-specific mesh code, so swapping to `MeshDescriptor` would take about an hour if `LowLevelMesh` ever misbehaves. (I checked the iOS 26.4 SDK: `LowLevelMesh` is iOS 18+ and main-actor-isolated. Heavy geometry work happens off the main thread, and only the final buffer copy runs on the main actor.)

---

## 4. Rendering and performance

### Batching
- A fixed **palette of about 12 pastel materials**, each a `PhysicallyBasedMaterial` with no textures, high roughness and zero metallic:
  - ground
  - grass
  - water
  - road
  - path
  - 3 wall tints
  - 2 roof tints
  - tree canopy
  - trunk
- Each building picks a wall tint and a roof tint deterministically from its OSM ID.
- **Every feature that shares a material is merged into one mesh part.** The whole world is a single `LowLevelMesh` with about 12 parts, which is about 12 draw calls for the world.
- The character capsule and any host-app entities add their own draw calls.
- Later optimization, not needed in M1: per-vertex color with one material could bring the world to 2–3 draw calls.

### Estimated triangle budget (area B)
| Layer | Count | Triangles |
|---|---|---|
| Buildings | 1,400 × ~23 | ~32k |
| Roads and paths | ~620 ways | ~20k |
| Water, parks, grass, pitches | | ~10k |
| Trees (mapped + scattered) | ~7k × 26 | ~180k |
| **Total** | | **~240k** (area A: about 110k) |

- **Budget ceiling:** 400k triangles and 25 draw calls for the world.
- **Memory:** with flat shading, roughly 3 vertices per triangle at 24 bytes each comes to about 17 MB of vertex data for area B. That's acceptable, and normals could be packed to 16-bit later if needed.
- **Headroom:** I expect this to be well within budget for a recent iPhone (iPhone 12 or later, which handles over 1M static triangles per frame in RealityKit). **These are estimates; M1 measures on a real device.**

### Level of detail (LOD)
**Not needed for 1–2 km².** At the default isometric zoom almost the whole area is on screen, so splitting it into chunks would add draw calls without culling anything.
- **Built-in readiness:** the mesh builder is chunk-aware from day one. Features are bucketed by a grid cell that defaults to one cell, so larger areas later just raise the grid size and gain frustum culling.
- **Tree escape hatch:** if trees prove too heavy, `MeshInstancesComponent` (GPU instancing, iOS 26+) is available. We'd use it only on iOS 26, with the merged mesh as the fallback.

### Lighting
- One directional "sun" light with shadows, plus image-based ambient light from the built-in environment.
- **Risk:** shadow maps spread across 1.5 km can look blurry. Fallback: limit shadow distance, or turn shadows off for trees.

### Reporting
- `World.stats` reports:
  - triangle count per layer
  - draw calls (number of mesh parts)
  - vertex memory
  - parse and build time
  - features skipped
- WorldLab shows these in a debug overlay.
- I cross-check the numbers on a device with Xcode's GPU frame capture and the "RealityKit Trace" Instruments template. **Simulator performance is not representative,** so frame-rate claims come from a real iPhone only.

### Camera
- Custom rig, not the built-in camera controls, so we can enforce game-like limits.
- **Default:** perspective with a narrow field of view (~30°), pitched 35° down, rotated 45°. That reads as isometric but keeps depth.
- **Optional true isometric:** `OrthographicCameraComponent` (iOS 18+).

| Gesture | Action |
|---|---|
| One-finger drag | Pan across the ground |
| Pinch | Zoom |
| Two-finger twist | Orbit (rotate) |
| Two-finger vertical drag | Tilt (15°–75°) |

The camera stays clamped inside the area.

### Demo character
- A capsule made with `MeshResource.generateCapsule` (no imported models). WorldLab passes it to the engine through the same public API any app would use.

### Attribution
- `WorldView` always draws "© OpenStreetMap contributors" in a corner overlay, legible over any background.
- Tapping it opens openstreetmap.org/copyright.
- Host apps can choose the corner but cannot hide it (section 6).

---

## 5. Tests

**Framework:** Swift Testing. Pure modules run with `swift test` on the Mac in seconds. `WorldEngine` tests run on the iPhone 17 Pro simulator via `xcodebuild test`. `scripts/test.sh` runs both, and I run it, so you don't have to.

| Area | Tests |
|---|---|
| **Coordinate conversion** | Center → (0, 0, 0). 0.001° north at this latitude → ~111.0 m along −Z (WGS84 value, ±1 cm). 0.001° east → ~85.6 m along +X. Lat/lon → local → lat/lon round trip within 1 mm. Axis convention (north = −Z, east = +X). |
| **Triangulation** | Square → 2 triangles. Square with square hole → 8 triangles, area = outer − inner. L-shape, U-shape, courtyard. Duplicate closing point, collinear points, near-zero area, self-intersecting ring (skipped, not a crash). All output triangles face up. Fuzz: 1,000 random simple polygons, triangle area sum = polygon area (±0.1%). |
| **Extrusion** | 10 × 10 m box, h = 6 → 8 wall + 2 roof triangles, normals outward, bounds = (10, 6, 10). Courtyard walls face inward to the courtyard. Flat-shaded vertex count is correct. |
| **Height fallback** | `"12"`→12, `"12 m"`→12, `"40'"`→12.19, `"40'6\""`→12.34, `"tall"`→falls through. Levels 3 → 9.6. Levels 2 + roof:levels 1 → 9.6. Each type default. `min_height`. Jitter is identical across runs and stays within ±10%. |
| **Road ribbons** | Straight line width 6 → 6 m-wide rectangle. 90° turn → miter. Hairpin → bevel. Duplicate points → no NaN. |
| **Data** | Ring assembly from split multipolygon member ways. Inner/outer assignment. Parser on a tiny hand-written fixture. Clipping a lake-like polygon to a box. |
| **Integration** | Load the real Sloan's Lake extract. Feature counts are in the expected range, the triangle total is under the 400k ceiling, and fewer than 1% of features are skipped. |

### Visual checks
- `scripts/snapshots.sh` builds WorldLab and boots the iPhone 17 Pro simulator.
- It launches the app with a fixed camera preset and fixed lighting (`-camera iso | top | street | lake-edge`).
- It waits for a "world ready" signal, then captures the screen with `xcrun simctl io booted screenshot`.
- Screenshots go to `docs/screenshots/m1/<preset>.png` and are committed, so each change shows a visible before and after in git.
- Tree scatter and colors are seeded, so screenshots are reproducible. M1 relies on human review; automatic image diffing can come later.

---

## 6. Licensing checklist (OpenStreetMap / ODbL)

**Attribution: where it goes**
- [ ] On the map, at all times: "© OpenStreetMap contributors", drawn by `WorldView` itself and linking to openstreetmap.org/copyright.
- [ ] Each host app's About or Acknowledgements screen: the same line plus "Data available under the Open Database License".
- [ ] Repo: README, plus `Data/areas/*/NOTICE.md` next to every extract.
- [ ] Screenshots and marketing images of the map (App Store, social): include the attribution line in the image or caption.
- [ ] Don't use the OpenStreetMap logo in a way that suggests OSM endorses the apps.

**What is fine (only attribution needed).** Rendering the world on screen, including screenshots and video, is a **Produced Work** under ODbL. You can show it in commercial apps and keep the app and its code closed-source. **The ODbL does not affect our code license.**

**What would trigger share-alike.** Share-alike means you must offer the database under ODbL. It's triggered by making a **Derivative Database** and then using it publicly (shipping it in an app counts as public use).

| Action | Effect |
|---|---|
| Shipping the raw extract in an app bundle (WorldLab and future apps) | Public use of an OSM database: keep it ODbL and attributed. It's unmodified, so it's simple. |
| **Shipping a pre-baked format** of OSM data (a planned possibility for M2) | It's still the database in another form, so it's ODbL. Fine, but we must offer it, or the bake tool and inputs, under ODbL on request. |
| **Merging other data into OSM features** (Overture or lidar heights, ML-estimated heights, hand-fixed footprints) and shipping the result | A Derivative Database: the merged data must be offered under ODbL. Overture buildings are already ODbL, and USGS lidar is public domain, so this is manageable, but it **is** share-alike. |
| **Storing app or user data on top of OSM features** (e.g., a DogWell user tags a park as "dog friendly", stored keyed to that OSM park) | **The main risk area.** Keep app and user data in a **separate** store, linked only loosely (by coordinates or our own IDs). Never publish a merged OSM-plus-user dataset. A separate store is a "Collective Database" and doesn't pull user data under ODbL. |
| Routes and positions computed by the app on top of the map (a dog-walk route) | Usually fine as produced output, but don't publish them as a database of OSM-derived geometry. |

**Other licenses**
- Earcut port: ISC license, notice kept in source.
- XcodeGen: MIT, build tool only, never shipped.
- Overpass and Nominatim usage policies: we fetch rarely, with an identifying User-Agent, and cache in the repo. That complies.

*This is engineering guidance, not legal advice. Before a public App Store launch that uses merged datasets, a short review by counsel is worth it.*

---

## 7. Integration contract (public API of `WorldEngine`)

Shareable with app teams. Names may get small refinements in M1; the shape is the commitment.

```swift
import WorldEngine
```

**Describing and loading a world**

| API | What it does |
|---|---|
| `GeoCoordinate(latitude:longitude:)` | A WGS84 lat/lon point; the only geographic type apps use. |
| `WorldArea(center:size:)` | The region to build: a center coordinate and a size in meters (east–west × north–south). |
| `WorldSource.overpassJSON(url:)` | Points the engine at a bundled raw OSM extract file. |
| `WorldStyle` | Palette, height rules, road widths and tree density; `.default` is the pastel look. |
| `World.load(area:source:style:) async throws -> World` | Parses data and builds all meshes off the main thread; returns a ready world. |
| `World.loadReport` | Feature counts, skipped features with OSM IDs, and timings. |

**Showing a world**

| API | What it does |
|---|---|
| `WorldView(world:)` | Ready-made SwiftUI view: RealityView, camera rig, gestures and OSM attribution. The recommended way to show a world. |
| `World.rootEntity` | The world as a plain RealityKit `Entity`, for apps with their own RealityView. The app must then also show `WorldAttributionView()`. |
| `WorldAttributionView()` | The required "© OpenStreetMap contributors" label, for custom layouts. |

**Coordinates**

| API | What it does |
|---|---|
| `World.position(of: GeoCoordinate) -> SIMD3<Float>` | Converts lat/lon to a ground-level position in world meters. |
| `World.coordinate(at: SIMD3<Float>) -> GeoCoordinate` | Converts a world position back to lat/lon. |
| `World.coordinate(atScreenPoint:in:) -> GeoCoordinate?` | Turns a tap on the map into the lat/lon on the ground, or nil if off-map. |

**Placing and moving entities** (M1 implements place and move; the app owns the entity)

| API | What it does |
|---|---|
| `World.place(_ entity: Entity, at: GeoCoordinate, heading: Angle? = nil)` | Adds any app-provided entity to the world at a lat/lon, standing on the ground. |
| `World.remove(_ entity: Entity)` | Removes an entity the app placed; the engine never deletes app entities on its own. |
| `World.move(_ entity:, along: [GeoCoordinate], speed: Double, options:) -> WorldMotion` | Walks an entity along a route at a speed in m/s, turning to face the direction of travel. |
| `WorldMotion.pause()` / `resume()` / `cancel()` | Controls a running route movement. |
| `WorldMotion.progress: AsyncStream<WorldMotion.Progress>` | Reports distance covered, current coordinate and finish, so the app can drive its own logic. |

**Camera**

| API | What it does |
|---|---|
| `WorldCamera` (observable, owned by `WorldView`) | Holds the current camera state; apps may read it or drive it. |
| `WorldCamera.focus(on: GeoCoordinate, zoom:, animated:)` | Moves the camera to look at a place. |
| `WorldCamera.follow(_ entity: Entity?)` | Keeps an entity (e.g., the app's character) in view; nil stops following. |
| `WorldCamera.mode` (`.isometric`, `.orthographic`, `.free`) | Switches camera style. Isometric is the default. |
| `WorldCamera.gesturesEnabled` | Lets the app temporarily disable pan, zoom and orbit. |

**Environment** (API designed now; M1 provides default lighting, real behavior comes later)

| API | What it does |
|---|---|
| `World.setTimeOfDay(_ date: Date)` | Sets sun direction and light color for that local time at the world's location. |
| `World.setWeather(_ weather: WeatherState)` | Sets the weather look. `WeatherState` is clear, cloudy, rain, snow or fog, each with an intensity from 0 to 1. |

**Diagnostics**

| API | What it does |
|---|---|
| `World.stats` | Triangle count, draw calls, vertex memory and build time, for performance dashboards. |

**Guarantees to host apps**
- The engine never touches app data, networking, analytics or UI outside `WorldView`.
- It never retains or modifies app entities beyond position and orientation while moving them.
- All public API is main-actor and Swift 6 concurrency-safe.

---

## 8. Risks, unknowns and time estimates

### Risks

| # | Risk / unknown | Likelihood | Mitigation |
|---|---|---|---|
| 1 | Missing heights make the city look uniform (measured: about 0% `height`, about 10% levels) | Certain | Type defaults + seeded jitter now; lidar or Overture heights later |
| 2 | Overpass is unreliable (2 of 3 requests failed today) | High | Fetch once, commit the raw data; mirror fallback in `worldbake` |
| 3 | Broken OSM polygons (self-intersections, unclosed multipolygons) | Medium | Clean-up, skip-and-log, load report |
| 4 | Flicker between flat ground layers when zoomed out | Medium | `ModelSortGroupComponent` + small offsets; check in screenshots |
| 5 | Sun shadows blurry or costly across 1.5 km | Medium | Tune shadow distance; disable tree shadows; fake depth via wall tints |
| 6 | 5–7k trees dominate the triangle count | Medium | Low-poly trees merged into one mesh; `MeshInstancesComponent` on iOS 26 if needed |
| 7 | `LowLevelMesh` quirks with Swift 6 main-actor rules | Low–medium | Geometry stays pure Swift; small adapter; `MeshDescriptor` fallback |
| 8 | Simulator performance isn't real | Certain | Frame-rate numbers only from a real iPhone (needs signing, §9) |
| 9 | Flat-terrain assumption: ground elevation varies by tens of meters around the lake | Low for M1 | Ground-snapped API now; DEM terrain later |
| 10 | Gestures conflict with host-app UI (sheets, scroll views) | Medium, later | `gesturesEnabled` flag; document patterns |
| 11 | Overture height coverage for Denver unknown | Unknown | Measure before committing to it; lidar is the fallback |
| 12 | Area choice (A vs. B) | Decision | Recommend B (§0) |

### Time estimates (focused working time, mostly my implementation plus your review)

| Part | Estimate |
|---|---|
| Package and XcodeGen setup, WorldLab skeleton, scripts | 0.5 day |
| `worldbake` fetch + commit extract; parser, ring assembly, classification | 1 day |
| Coordinates, height rules, clipping + tests | 0.5–1 day |
| Earcut port + triangulation tests and fuzzing | 1 day |
| Extrusion, road ribbons, ground layers, trees + tests | 1.5 days |
| RealityKit adapter (`LowLevelMesh`), materials, batching, lighting | 1 day |
| Camera rig, gestures, attribution, capsule, place/move API, environment stubs | 1.5 days |
| Snapshot script, device performance pass, tuning, integration-contract doc | 1 day |
| **Total** | **≈ 8–9 working days** (expect about 1.5× if lighting or shadows need extra tuning) |

---

## 9. What you need to do by hand

### A. Decisions (just reply in chat)
1. **Area:** B (1.6 × 1.2 km, whole lake; recommended) or A (1 × 1 km)?
2. **Bundle ID prefix** for WorldLab, in reverse-domain form, e.g. `com.yourcompany`. I won't guess one. It becomes `<prefix>.worldlab`.
3. **Minimum iOS:** OK with iOS 18.0?
4. **OK to download XcodeGen's source from GitHub** (MIT license, about 5 MB, build-time only) when step 2 starts?

### B. Nothing needed for the simulator
Screenshots and tests run in the iOS Simulator with no Apple account.

### C. To run WorldLab on your own iPhone (needed for real performance numbers)

Because the Xcode project is generated, **don't set signing inside Xcode.** Give me your Team ID and I'll put it in `project.yml`.

**1. Find your Team ID**
1. Open **Xcode**.
2. In the menu bar click **Xcode → Settings…** (or press ⌘,).
3. Click the **Accounts** tab.
4. If no Apple ID is listed, click **+** at bottom left → **Apple ID** → **Continue**, and sign in yourself.
5. Select your Apple ID in the left list. On the right, under **Team**, you'll see your team name. A free "Personal Team" works for running on your own phone.
6. To get the Team ID: open **developer.apple.com/account** in Safari → sign in → scroll to **Membership details** → copy **Team ID** (10 characters). Paste it to me in chat.
   - With only a free Personal Team, there's no Membership page. Tell me that and I'll set it up a different way.

**2. Prepare the iPhone (one time)**
1. Connect the iPhone to the Mac with a cable and unlock it. If it asks **"Trust This Computer?"**, tap **Trust** and enter your passcode.
2. On the iPhone: **Settings → Privacy & Security** → scroll to the bottom → **Developer Mode** → turn **On** → tap **Restart**. After restarting, tap **Turn On** and enter your passcode.
   - Developer Mode only appears after the phone has been connected to Xcode once. If it's missing, leave the phone connected, open Xcode, wait a minute, then look again.

**3. First launch on the phone (after I've built it)**
1. If the phone shows **"Untrusted Developer"**: on the iPhone go to **Settings → General → VPN & Device Management** → tap your Apple ID under **Developer App** → **Trust** → **Trust**.
2. Free Personal Team apps expire after 7 days. I'll just reinstall when needed.

---

## Step 1 deliverables
- Git repository initialized on `main` with `.gitignore`, `.gitattributes`, `README.md` and `CLAUDE.md` (working rules for future sessions).
- This plan, `docs/plan-m1.md`.
- No feature code, no Xcode project and no map data committed yet.
