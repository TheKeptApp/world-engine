# WorldEngine: Milestone 1 technical plan (revision 2)

**Status:** foundation built (Prompt 2, part D). Rendering not started.
**Binding requirements:** [VISUAL_DIRECTION.md](VISUAL_DIRECTION.md) (street view, scale, generalization).
**Measured data:** [data/sloans-lake-street-data.md](data/sloans-lake-street-data.md).
**Toolchain (checked 2026-10-05):** Xcode 26.4, Swift 6.3, iOS 26.4 SDK. Minimum iOS 18.0 (approved).

## What changed since revision 1, and why

| Area | Revision 1 (aerial only) | Revision 2 (street + aerial) | Why |
|---|---|---|---|
| Default camera | Isometric overview | **Third-person street camera**; aerial is the second mode | First app is a walking game (B) |
| Batching | One mesh per material, whole world (~12 draw calls) | **Per material per 200 m chunk**, 3 levels of detail (LOD) | At street level most of the world is behind the camera; whole-world meshes can't be culled (B.1) |
| LOD | "Not needed" | L0 full detail under 150 m, L1 simplified to 600 m, L2 silhouettes beyond, clutter under ~50 m | Required (B.2) |
| Geometry | Extruded boxes, flat roofs | Generated houses (roofs, doors, windows, porches), apartments, storefronts, sidewalks/curbs, clutter; all seeded by OSM ID | Street view needs detail OSM lacks (B.3) |
| Materials | Stock `PhysicallyBasedMaterial`, fixed pastel palette | **`CustomMaterial` (Metal shaders)**, palette as data in a texture, fog/snow/wet/night in the shader | RealityKit has no scene fog (checked SDK); palettes must shift by season, time and weather (B.4) |
| World edge | None | Buildings-only backdrop ring (3 × 3 km), fog, per-location horizon | Data edge is visible from the lake path (B.6) |
| Environment | API stubs only | Sun from real time and place, keyframed light, night lights, eased weather, particles, seasons | B.9 |
| Budget | ~240k triangles, aerial | ~290k main + ~100k shadow triangles, ≤ 100 draw calls; 60 fps on iPhone 13-class | B.7 |
| Data format | One raw file | Manifest with a list of bounded sources, merged and de-duplicated by OSM ID | Ready for tiles and any-location loading (C.6) |
| Effort | 8–9 days | ~30–38 days in 5 sub-milestones | Scope roughly 4× |

---

## 1. Repo and modules

```
Package.swift                  WorldEngine package (product: WorldEngine only)
Sources/
  WorldGeo/      ✅ built   lat/lon ↔ local meters (exact WGS84), 2D polygons, clipping, StableRandom
  WorldMap/      ✅ built   Overpass JSON → typed features; ring assembly; height/width rules; area manifest
  WorldMesh/     ✅ built   earcut port, footprint extrusion, road ribbons → plain MeshBuffers
  WorldGen/      planned   procedural detail: house kit, roofs, facades, sidewalks/curbs, props, clutter, trees
  WorldEngine/   started   RealityKit + SwiftUI: chunks, LOD, materials, camera rigs, environment, public API
                           (today: WorldAttributionView only)
  worldbake/     ✅ built   macOS tool: init-area, fetch, stats, datamap, ring-stats
Tests/           ✅ 61 tests (89 cases incl. parameterized), `swift test`, all pass
Data/areas/sloans-lake/      ✅ manifest.json, osm.json (4.4 MB), osm.overpassql, NOTICE.md
Apps/WorldLab/   ✅ project.yml (XcodeGen 2.46.0, pinned in Tools/), empty shell app
scripts/         ✅ generate.sh, test.sh, snapshots.sh
```

- **Concurrency:** everything except `WorldEngine` is pure Swift, `Sendable`, and runs off the main thread.
- **Where host-app code goes:** only into `WorldEngine`.
- **Generator code** lives in `WorldGen`. It takes typed features plus style data and returns `MeshBuffers` per chunk, LOD and material class. That keeps it unit-testable on the Mac and keeps RealityKit out of it.

---

## 2. Data

### 2.1 Stored format (generic, ready for tiles)
- **`manifest.json`** holds: area id, name, center (the origin of the local frame), size, and a **list of sources**. Each source has a format, path, layers, bounds, data timestamp, size, SHA-256 and license.
- **Today:** one `osm-overpass-json` source with layer `all`.
- **Later:** many tile sources; nothing else changes.
- **Loader:** `AreaLoader` reads every source and **merges them, de-duplicating by OSM element ID**, so overlapping tiles combine cleanly. Covered by `mergingDocumentsDeduplicatesByID`.
- **Feature identity:** every feature carries an `OSMRef` (`way/123`). It is the seed for all generated detail and the key for future per-building overrides.
- **No place-specific code:** the area (center, size) is input data, and every rule keys off tags. The same tool and builder produced the downtown Denver and Bernal Heights measurements below without changes.

### 2.2 What Sloan's Lake actually has (D.6)

Full tables are in [data/sloans-lake-street-data.md](data/sloans-lake-street-data.md).

| Street-view input | Mapped in OSM | What must be generated |
|---|---|---|
| Buildings | 1,399 (769 houses, 490 detached garages, 84 sheds) | Nothing; all footprints exist |
| `height` | 0 | Heights come from levels (9%) or type defaults (91%) |
| `building:levels` | 130 (1: 74, 2: 12, 3: 44) | Default by type for the rest |
| `roof:shape` | **0** | **All roofs.** Gabled vs. hipped chosen from footprint shape + seeded choice |
| `roof:colour` / `building:colour` | 62 / 16 | Use when present; otherwise seeded palette pick |
| Building types | house, garage, shed, yes, retail, roof, commercial, apartments, office, public, toilets, residential | Rules per type |
| Sidewalks | **212 separate ways, 20.8 km** (`footway=sidewalk`) + 69 crossings | Roads aren't tagged: 26.8 km of street side has no `sidewalk` tag, only 3.7 km says `separate`. **Rule: generate a sidewalk only where no mapped sidewalk runs parallel within ~15 m.** Most streets here already have one. |
| Curbs | 0 | All curbs along road edges |
| Benches | 56 (park) | Streets: none; generate a few along park paths where none are within ~60 m |
| Street lamps | 55 (park paths, Sheridan Blvd) | **Residential streets have almost none.** Generate at ~35–45 m spacing, alternating sides |
| Trees | **5,400 mapped**, no species / leaf type / height | Place all mapped trees; leaf type and size seeded; scatter more only in parks with gaps |
| Yard and verge grass | 1,550 `landuse=grass` polygons (26 ha), mostly tree lawns and yards | Grass tufts and flower beds can key off these |
| Hedges / fences | 12 / 6 ways | Few; yard fences and hedges generated sparingly |
| Other | 32 picnic tables, 15 hydrants, 5 bike racks | Use as mapped |

**Takeaway:** the footprints, paths, sidewalks and trees are real. Roofs, facades, curbs, street lamps, leaf types and clutter are generated.

### 2.3 Debug map
- **Where:** `docs/screenshots/m1/data-map.png`, produced by `worldbake datamap` from the parsed features (not the raw file), so it also checks the parser.
- **What it shows:** buildings in **orange where height or levels are tagged (130)** and **grey where not (1,269)**, plus roads, paths, sidewalks, water, parks, trees, benches and lamps.

---

## 3. Geometry and generation

### 3.1 Built now (pure functions, tested)
- **Earcut port:** 2.2.4, ISC license, without the z-order hash. Handles holes and courtyards. `Triangulator` rejects results whose triangle area differs from the polygon area by more than 1%, which catches self-intersections.
- **Footprint extrusion:** flat-shaded walls with outward normals, courtyard walls facing in, flat roof.
- **Ribbons:** miter joins with a bevel fallback, always facing up.
- **Clipping:** Sutherland–Hodgman for polygons and Liang–Barsky for lines. Buildings are kept whole if their centroid is inside the area.

### 3.2 Generated detail (WorldGen, planned; all seeded by `OSMRef`)

**Houses**
- **Front side:** the footprint edge facing the nearest street (vehicle road within 40 m), preferring the edge nearest the house's address street.
- **Roof:**
  - A footprint at least 85% the size of its minimum oriented bounding rectangle gets a gabled roof (ridge along the long axis) or a hipped roof, chosen by seed.
  - L- and T-shapes are split into rectangles, each roofed.
  - Other shapes get a hipped roof via a straight skeleton (M1c) or a low flat roof.
  - Overhang 0.4 m; pitch 25–40° by seed.
  - Stylized: roof height is added on top of wall height.
- **Door, porch or steps, chimney** on the front side.
- **Windows** per wall by length and floors.
- **Garage:** Sloan's Lake already maps 490 detached garages, so a garage is generated only when the footprint has a narrow wing on the side facing a service road or driveway.

**Apartments**
- Window grid by floor.
- Balconies on street-facing walls, every other bay by seed.
- Flat roof with a parapet.

**Commercial and retail**
- Ground-floor storefront glass band on street-facing walls.
- Awning by seed.
- Flat roof with a parapet.

**Streets**
- Curbs: 15 cm raised edge on the road ribbon.
- Sidewalks per the rule in 2.2, with grass verges between curb and sidewalk where OSM grass exists.
- Path edges: darker border strips.

**Props**
- Lamps and benches: mapped first, then generated by spacing rules.
- Fences and hedges: as mapped, plus sparse seeded yard fences.

**Vegetation**
- Trees: smooth, low-poly canopies. Leaf type when tagged, otherwise seeded deciduous/evergreen by a **style parameter** (decision 2).
- Clutter: grass tufts, bushes and flower beds in yards, verges and parks. Only placed in chunks near the camera.

**Determinism**
- All randomness comes from `StableRandom(osmRef, salt)`, a portable SplitMix64.
- A golden-value test fails if the generator ever changes.
- Never `Hasher` or `random()`.

**Overrides (designed, not built)**
- `BuildingOverride { wallColor, roofColor, roofShape, doorColor, doorStyle }`, keyed by `OSMRef`.
- Applied after generation. It's a pure function of (building, seed, override), so an override changes only that house.
- Stored by the host app, never by the engine. ODbL note: keep override data separate from OSM data (see licensing).

### 3.3 Mesh API
- **Mesh upload:** `LowLevelMesh` (iOS 18+, main-actor). Geometry is built off the main thread into `MeshBuffers`, and only the copy into the `LowLevelMesh` runs on the main actor.
- **Vertex layout:**
  - position (float3)
  - normal (packed)
  - color / palette index (uv1)
  - flags: window, emissive, sway weight (uv2)

---

## 4. Rendering

### 4.1 Chunks and draw calls (B.1)
- **Chunk size:** 200 m. Area B (1,600 × 1,200 m) is **8 × 6 = 48 chunks**.
- **Material classes:**

  | Class | Contents |
  |---|---|
  | `static` | Buildings, ground, roads, props; windows are a vertex flag |
  | `foliage` | Smooth shading, wind sway |
  | `water` | Lake and ponds |
  | `clutter` | L0 only |

- **Per chunk:** one entity per LOD, holding one `LowLevelMesh` with one part per material class.

| Street mode (typical view) | Chunks | Draw calls |
|---|---|---|
| L0 (< 150 m) | ~4 | 4 × 3 classes + 4 clutter = 16 |
| L1 (150–600 m) | ~12 in view | 12 × 2 = 24 |
| L2 + backdrop sectors (> 600 m) | 8 sectors | 8 |
| Sky dome, horizon, ground ring | | 3 |
| Character (host) | | ~5 |
| **Total** | | **≈ 56** (ceiling: 100) |

**Aerial mode:**
- The whole area is in view, so L1 chunks merge into 400 m super-chunks (12 × 2 = 24) plus L2 and the backdrop.
- That comes to **≈ 40 draw calls**.

### 4.2 Detail by distance (B.2)
- **Thresholds:** 150 m and 600 m, measured from the camera's look-at point in street mode and from the camera in aerial mode.
- **Hysteresis:** ±10% stops LODs flickering at the boundary.
- **Cross-fade:** LOD changes cross-fade over ~0.4 s with a dithered alpha test (`CustomMaterial.opacityThreshold` plus screen-space noise). That avoids the cost of the transparency pass.
- **Clutter:** exists only in L0 chunks and fades out by ~50 m.
- **L1 content:** boxes with simple roofs, no facades, 20-triangle trees, merged ground.
- **L2 content:** footprint blocks with flat roofs, tree blobs merged per chunk, fog-tinted.

### 4.3 Shading, palette, weather in materials (B.4)

| Item | Approach | Notes |
|---|---|---|
| Base look | **`CustomMaterial`** (Metal surface shader, iOS 15+, works in `RealityView`). Lit by RealityKit's PBR and shadows. | Recommended over `ShaderGraphMaterial`, which must be authored in Reality Composer Pro as USD and is hard to review or generate. |
| Palettes as data | Palette JSON → small **`LowLevelTexture`** (rows = palettes; columns = slots like "wall 3" or "grass"). Vertices store a palette slot. The shader blends two palette rows by a uniform. | Season, time and weather change palettes **without rebuilding meshes**. |
| Flat vs smooth | Buildings: per-face vertices (flat). Trees, bushes, character stand-in: shared vertices with normals pointing out from the canopy center (soft, toy-like). | |
| Snow | Shader: `snowAmount × smoothstep(normal.y) × noise` → white, rougher. | Up-facing only, uniform-driven, eased. |
| Wet | Shader: darker base, roughness down to ~0.2, puddle mask on flat ground from world-position noise. | |
| Fog/haze | **RealityKit has no scene fog** (searched the iOS 26.4 SDK: no fog API). Fog is done **in our shaders**: fog factor from distance and height. The lit color is scaled by (1 − f), and f × fog color is added as emissive. | Works on iOS 18. Host entities (characters) aren't fogged; they're near the camera, so it doesn't show. |
| Night windows and lamps | Window flag × `nightFactor` × seeded on/off per window → emissive. Lamp heads emissive. The **nearest 4–8 lamps** get real `PointLightComponent`s (no shadows); the rest are emissive only. | |
| Tilt-shift (aerial) | Post-process blur on depth. `RealityView` post-processing (`PostProcessEffect`) is **iOS 26+ only**. | **Tradeoff:** on iOS 18–25 aerial view has no tilt-shift. The alternative, `ARView` in `.nonAR` mode, has post-processing on iOS 15+, but it's the older UIKit API. Recommend RealityView with iOS 26-only tilt-shift (decision 1). |
| Wind sway | `CustomMaterial` geometry modifier: vertex offset by the sway weight in uv2 × time. | Trees and clutter only. |

**Shader uniforms:** `CustomMaterial` gives one `float4` custom parameter plus one custom texture per material. We pack global state (time of day, wetness, snow, fog) into the texture's last row. The SDK confirms shaders can read world position, vertex color, uv0–uv7, time and view direction on iOS 18.

### 4.4 Camera (B.5)

**Street rig: a spring arm**
- **Target:** the character's position plus about 0.8 × its height.
- **Distance:** so the character fills a target fraction of screen height (default 22%): distance = h / (2·tan(FOV/2)·fraction).
  - For FOV 50°, a 0.6 m character → ~2.9 m; a 1.8 m character → ~8.8 m.
- **Tunables:** screen fraction (or fixed distance), height offset, pitch (default 14°), FOV, zoom limits (0.5×–2.5× default distance), damping, recenter delay (5 s).
- **Controls:** drag orbits (yaw and pitch, clamped 5°–60°); pinch zooms within limits. After 5 s idle, a critically damped spring brings the camera back behind the direction of travel.

**Occlusion**
- **Large blockers (buildings, terrain later):** a sphere cast (`Scene.convexCast`, radius 0.3 m) from target to desired camera position against per-chunk static collision shapes. On a hit, the camera pulls in fast and eases back out slowly. The cast radius exceeds the near-plane half-size (near plane 0.1 m), so it **never clips**.
- **Thin blockers (lamp posts, trunks, hedges):** merged meshes can't be faded per object, so the shared shader **dither-cuts any world fragment inside a capsule from camera to character**. The character's position and radius go in the material's `float4` parameter.
- This is cheaper than pulling the camera in at every tree among 5,400. The capsule radius shrinks to 0 when nothing is blocking.

**Aerial rig**
- Orbit around a ground point: pitch 30°–65°, narrow FOV (~30°), optional orthographic.
- Tilt-shift on iOS 26+.

**Transitions**
- Interpolate rig parameters (target, yaw, pitch, log-distance, FOV) with ease-in-out over ~1.2 s.
- The path arcs upward so it never passes through buildings.

### 4.5 World edge (B.6)
**Backdrop ring:** measured with `worldbake ring-stats` on a 3 × 3 km box centered on area B, minus area B.

| Measure | Value |
|---|---|
| Buildings in the ring | **12,274** (13,673 in the box) |
| Footprint vertices | 79,741 |
| Raw Overpass JSON, buildings only | 11.9 MB (1.3 MB zlib) |
| Compact block format (int16 decimeter vertices + height) | **~390 KB** |
| As-is extruded blocks | 215k triangles: too many |
| **Planned:** drop buildings < 30 m² (garages and sheds ≈ 40%), simplify the rest to oriented boxes when rectangular (else 2 m Douglas–Peucker), flat roofs, merge into 8 sectors | **≈ 70–75k triangles**, of which ~25k are in view at once, all in fog |

**Fog**
- The fog distance is set so the backdrop's outer edge (1.5 km) is ~90% fogged in street mode.
- Aerial mode uses lighter haze.

**Horizon backdrop**
- A camera-centered (translation-only) ring of silhouette layers, unlit and fog-blended.
- It's **configured per location as data:** a profile of (azimuth → elevation angle) in the area manifest.
- **For Sloan's Lake:** the Front Range is ~25–60 km west and rises 1.5–2.5 km above the city, which is about 2–5° above the horizon to the west.
- **Profile source (decision 4):** generated by `worldbake horizon` from a global DEM, so it's automatic and generic, or a hand-entered profile in data for the first visual milestone.
- This is the one place geography may be distorted (C.1).

### 4.6 Environment (B.9)
**Sun and sky**
- **Sun:** NOAA solar-position algorithm, pure Swift and unit-tested, from date and time + the manifest's center gives azimuth and elevation. That drives the `DirectionalLightComponent`.
- **Shadows:** `shadowProjection: .automatic(maximumDistance:)` (iOS 18 API), ~100 m in street mode.
- **Light and sky color:** keyframed by **sun elevation**, not clock time, so dawn, golden hour and night work at any latitude or season. The keyframes are data.

**Weather**
- **States:** `WeatherState` (clear / cloudy / rain / snow / fog, each with an intensity).
- **Blending:** the engine blends continuous parameters (cloud cover, wetness, snow cover, fog density, precipitation rate) toward targets over 3–10 s. Snow builds up over minutes and never snaps.
- **The engine doesn't call WeatherKit:** the host app maps WeatherKit conditions to `WeatherState`. That keeps the engine free of entitlements and networking. WorldLab gets a debug picker.

**Particles**
- Rain streaks and snowflakes come from `ParticleEmitterComponent` (iOS 18) in a ~30 × 20 × 30 m box that follows the camera.
- Falling leaves are emitted near trees close to the camera in autumn.

**Seasons**
- Season phase comes from date + hemisphere (latitude sign). Seasonality strength scales with latitude (weak in the tropics), so no per-place tuning is needed.
- Seasonal palettes for trees and grass.
- Deciduous trees swap to a bare-branch mesh variant in winter. Chunk meshes are rebuilt at season change, which is rare.

**Ambient light**
- Image-based lighting uses 3–4 small bundled environment maps (day, golden, overcast, night), switched with intensity ramps.

**Later milestones:** ambient cars and pedestrians (B.8); terrain; any-location streaming.

### 4.7 Budget (B.7)

**Street mode, typical frame, area B**

| Content | Triangles |
|---|---|
| L0 chunks (~4): houses ~300 triangles each with facades, ~120 trees × 100, ground with curbs, props | ~130k |
| Clutter (< 50 m): ~1,500 tufts × 8 + ~200 bushes × 40 | ~20k |
| L1 chunks (~12 in view) | ~85k |
| L2 + backdrop in view | ~35k |
| Sky, horizon, ground ring | ~2k |
| Character (host budget) | ~20k |
| **Main pass** | **≈ 290k** (ceiling 400k) |
| Shadow pass (casters within ~100 m) | ≈ 100k (ceiling 150k) |
| Draw calls | ≈ 56 (ceiling 100) |

**Aerial mode:** ≈ 250k triangles, ≈ 40 draw calls.

**iPhone 13 (A15) target**
- 60 fps with no throttling over 10 minutes needs real headroom, so the goal is **GPU frame time ≤ 10 ms** (60% of the 16.7 ms budget).
- **Main risk:** fill rate at native 3× resolution with custom PBR shaders, shadows and fog. RealityView doesn't expose a render-scale setting.
- **Fallbacks:**
  - cheaper shader paths
  - shorter shadow distance
  - fewer L0 chunks
  - `ARView(.nonAR)` with `contentScaleFactor` as a last resort
- Measured on a device with Instruments (RealityKit Trace, thermal state) during a scripted 10-minute walk.

**iOS 18 vs 26:**
- **Instancing:** on iOS 26, trees and clutter can use `MeshInstancesComponent`, which takes less memory and builds faster. On iOS 18 they are merged meshes. Same look, so this is a performance-only difference.
- **Tilt-shift:** iOS 26 only.
- The minimum stays iOS 18.

---

## 5. Tests and visual checks
- **Unit tests now:** 61 tests (89 cases), all passing in `swift test`.

| Suite | What it covers |
|---|---|
| Coordinates | WGS84 distances, 1 mm round trip, scene axes, bounding boxes |
| Polygons | Cleaning, orientation |
| Clipping | Polygons, polylines |
| Determinism | Golden value |
| Tag parsing | Lengths, feet and inches |
| Height fallback | All rules, jitter determinism |
| Road widths, sidewalk tags | |
| Ring assembly | |
| Fixture | Hand-made OSM with a courtyard multipolygon, clipped road and water, a bench as a way, a broken way |
| Real-area | Ranges on the committed extract |
| Triangulation | Shapes, holes, degenerate input, 1,000-polygon fuzz |
| Extrusion | Counts, outward normals, courtyards |
| Ribbons | Miter, bevel, duplicates |

- **Next:**
  - WorldGen tests: roof selection, front-side choice, sidewalk inference, seeded stability.
  - Sun-position tests against NOAA reference values.
  - Chunking and LOD tests: every triangle lands in exactly one chunk.
- **Visual checks:** `scripts/snapshots.sh <name>` builds WorldLab, launches it in the iPhone 17 Pro simulator and saves `docs/screenshots/m1/<name>.png`.
  - Camera presets (`street`, `street-orbit`, `aerial`, `lake-edge`) and a fixed time (golden hour) arrive with rendering. Seeds make screenshots reproducible.
  - Today: `worldlab-shell.png` (empty shell, attribution visible) and `data-map.png`.

---

## 6. Licensing (unchanged from revision 1, plus additions)
- **Attribution:** "© OpenStreetMap contributors" on the map at all times (`WorldAttributionView`, fixed colors, legible on any background), plus a `NOTICE.md` beside each extract.
- **Share-alike risks:** generated detail is a Produced Work, so attribution only. The **per-building overrides** (3.2) are app or user data and must be stored separately from OSM data and never published merged with it.
- **New data sources:**

| Source | License and requirements |
|---|---|
| Copernicus DEM (horizon, terrain) | Free, attribution required |
| USGS 3DEP | Public domain |
| Hosted tiles | ODbL; offer on request |

---

## 7. Integration contract
Unchanged from revision 1 (place, move along route, camera, time of day, weather, coordinate conversion), with these additions:

| API | What it does |
|---|---|
| `WorldCamera.mode = .street(following: Entity) / .aerial` | Switches camera mode; the transition is animated. |
| `WorldCamera.streetSettings` | Screen fraction, height, pitch, FOV, zoom limits, recenter delay. |
| `WorldMotion` speed | In m/s and changeable while moving. Apps compress time, not space (C.2). |
| `World.setSeason(override:)` | Optional; the default comes from the date. |
| `World.setBuildingOverride(_:for: OSMRef)` | Planned, not in M1. |
| `World.setHorizon(_:)` | Planned. Defaults to the area manifest's profile. |

---

## 8. Sub-milestones and effort

| Sub-milestone | Scope | Estimate |
|---|---|---|
| **M1a Foundation** ✅ | XcodeGen, WorldLab shell, data fetch, Geo/Map/Mesh modules, tests, data map | done |
| **M1b First visual** | One street of houses + lake path, stand-in, golden hour, street camera (see §9) | 9–11 days |
| **M1c Whole area** | All chunks, L0/L1/L2 + cross-fade, clutter, props, apartments/commercial, aerial mode + transitions, backdrop ring, horizon | 8–10 days |
| **M1d Environment** | Real sun, light keyframes, night lights, weather states + easing, rain/snow particles, wet/snow shaders, seasons, leaves | 7–9 days |
| **M1e Device + generalization** | iPhone 13-class performance and 10-minute thermal walk, tuning, two more areas, three-area screenshot set | 5–7 days |
| **Total remaining** | | **≈ 29–37 working days** |

**Later milestones:** terrain; any-location loading; ambient cars and pedestrians; building overrides.

---

## 9. First visual milestone (M1b): proposal

**Scene**
- One residential street east of the lake (about two blocks, roughly 2 × 2 chunks) plus the lake path segment beside it.
- **Detail:** full L0 only, no LOD yet. Generated houses (roofs, doors, windows, porches), the mapped garages, mapped sidewalks plus generated curbs, verges, mapped trees (smooth), mapped and generated lamps and benches.
- **Ground:** water and ground.

**Light and sky**
- Golden hour at a fixed date and time, so screenshots are reproducible.
- Shader fog and a sky gradient.
- Simple flat western horizon silhouette from data.

**Character and camera**
- A capsule stand-in walks a route along the street and onto the lake path, at tunable speed.
- Street camera: follow, drag-orbit, pinch zoom, 5 s recenter, sphere-cast pull-in.

**Output**
- Screenshots `m1b-street`, `m1b-orbit`, `m1b-lake-path`.
- Triangle and draw-call counts.
- The first device performance read (I'll ask for the Team ID then).

The street and route are WorldLab demo data (coordinates in the app's demo config), not engine code.

---

## 10. Generalization, terrain and any-location (C.4–C.6)

### 10.1 Proposed generalization areas
Measured with the same tool and rules, each 1.6 × 1.2 km.

| | Sloan's Lake (B) | **Downtown Denver** (16th St / Union Station, 39.7495, −104.9960) | **Bernal Heights, San Francisco** (park summit, 37.7432, −122.4148) |
|---|---|---|---|
| Character | Lake, park, houses | Mid/high-rise core | Steep hill (~30 m → 133 m), dense row houses |
| Raw OSM JSON | 4.4 MB | **13.5 MB** | **6.3 MB** |
| Buildings | 1,399 | 660 + **3,346 `building:part`s** | 4,671 |
| with `height` / levels | 0% / 9% | 47% / 80% | **90%** / 0% |
| `roof:shape` | 0 | 50 (dome, round, pyramidal…) | 0 |
| Dominant type | house | commercial | **`yes` (95%)** |
| Trees / lamps / benches | 5,400 / 55 / 56 | 3,406 / 1,011 / 116 | 29 / 0 / 15 |
| Mapped sidewalks | 212 ways | 600 ways, 57.8 km | 147 ways |

**What they will test**
- **Downtown:** needs **`building:part` rendering** (draw parts instead of the outline when a building has parts; not yet implemented).
- **Bernal:** tests heights from tags with no type information, and tree scatter when OSM has almost no trees.
- **Bernal terrain:** Bernal is only a true hilly test **after terrain**. Before that it renders flat, which still tests the generation rules.
- **Data freshness:** the Bernal fetch came from a mirror with data from 2026-05-06. Re-fetch from the main server when the test runs.

### 10.2 Terrain (later milestone)

**Elevation sources**

| Region | Source | Resolution | License |
|---|---|---|---|
| US | **USGS 3DEP**, 1/3 arc-second DEM | ~10 m | Public domain |
| US | USGS 3DEP lidar-derived DEMs | 1 m | Public domain |
| Global | **Copernicus DEM GLO-30** | 30 m | Free, attribution required |
| Global | NASADEM / SRTM | 30 m | Public domain |
| Global | AWS Terrain Tiles (Terrarium) | Mixed | Open, attribution required |

**Plan:** bake per-chunk height grids (e.g., 2 m spacing) with `worldbake`, using 3DEP in the US and Copernicus elsewhere.

**Flat-world assumptions to avoid now (so terrain isn't a dead end)**

| Assumption | Fix |
|---|---|
| Ground at y = 0 | All placement goes through `World.groundHeight(at:)` (returns 0 in M1). |
| Ground layers stacked at fixed y offsets | Layers drape on terrain: per-vertex height + offset along the normal, plus `ModelSortGroup` order. Never a fixed y. |
| Ground as one flat triangulated polygon | Ground polygons must be subdivided to a grid (≤ 4 m) so they can bend. WorldGen triangulates ground on a grid-clipped basis from the start. |
| Buildings at one base height | Base = minimum terrain height under the footprint, walls extend down ~1 m (skirt). |
| Road ribbons flat | Ribbons get vertex heights sampled along the centerline; curbs follow. |
| Camera, sphere casts, routes and fog in flat terms | Use real collision against terrain; fog on distance, not on y alone. |
| Water | Stays flat at its own level. Lakes need the shoreline height, taken from the DEM. |

### 10.3 Loading any location (later milestone)

**Options**

| Option | How | Monthly cost at small scale | Verdict |
|---|---|---|---|
| **A. Own tiles** | Monthly planet (or US) build with **Planetiler** using a custom profile that keeps our layers (trees, benches, lamps, sidewalks, building parts; the standard OpenMapTiles schema drops street furniture). Output: one **PMTiles** archive (~70–120 GB planet, ~10–15 GB US) on **Cloudflare R2** + CDN. The app range-requests z14 tiles (~1.9 km at 40°N). | Storage ~$0.30–2; R2 has no egress fees; requests ~$0.36 per million; monthly rebuild on a rented 64–128 GB machine for a few hours ~$5–20. **≈ $10–30/month.** | **Recommended** |
| B. Self-hosted Overpass | Our own Overpass server, queried live | ~$100–250/month (server with 32 GB RAM, ~500 GB SSD); heavy queries, poor scaling | No |
| C. Commercial vector tiles (Mapbox, MapTiler, Stadia) | Their tiles | Free tiers, then ~$25–100+/month. Their schemas drop benches, lamps, trees and sidewalk detail, and their terms restrict caching and storage. | No |
| D. Overture Maps (GeoParquet on S3) | Tile ourselves like A, mixing in Overture building heights | Same as A | Possible input to A |

Public Overpass servers stay a developer tool only (C.6).

**Built into the M1 data format now (already in code)**
1. Manifest with **multiple bounded sources** and a format version.
2. **Merge and de-duplicate by OSM ID** across sources.
3. Features keyed and seeded by `OSMRef`, never by position or tile, so a house looks the same whichever tile it came from.
4. **Building ownership by centroid:** each building belongs to exactly one tile.
5. A local frame per session, separate from the data. Streaming will re-center the origin (floating origin) as the player walks far, which keeps Float precision.
6. Source-agnostic feature model: the loader can read `osm-tile-v1` alongside Overpass JSON.

**Still to design (M2):** tile addressing (slippy z/x/y), a chunk cache with eviction, and background loading.

---

## 11. Risks (ranked)

| # | Risk | Mitigation |
|---|---|---|
| 1 | **Performance and heat on iPhone 13 at native resolution** (custom shaders + shadows + fog) | 10 ms GPU budget, early device measurement in M1b, fallbacks in 4.7 |
| 2 | **Generated houses look wrong** (roofs on odd footprints, front-side choice) | Rectangle/L/T decomposition first, straight skeleton later, screenshot review per change |
| 3 | `CustomMaterial` limits (one `float4` + one texture for uniforms; fog via emissive interacts with tone mapping) | Packed uniform texture; validate fog look in M1b |
| 4 | Thin-blocker see-through flickers among 5,400 trees | Capsule cut with hysteresis; pull-in only for large blockers |
| 5 | LOD popping | Dithered cross-fade + hysteresis |
| 6 | iOS 18 vs 26 split (tilt-shift, instancing) | Same look; performance and tilt-shift are the only differences |
| 7 | Data gaps (roofs, leaf types, lamps, curbs) | Rules + style data; sidewalk-inference test |
| 8 | Overpass unreliability (failures again today) and stale mirrors | Committed data; check the timestamp at fetch; own tiles for apps |
| 9 | `building:part` handling for dense areas | Implement before the downtown test |
| 10 | Mesh memory (48 chunks × 3 LODs) and build time | Build LODs lazily; L0 only near the camera |
| 11 | Terrain retrofit | Flat-world assumptions avoided (10.2) |

---

## 12. Decisions needed
Listed in the Prompt 2 report. In short:
1. Tilt-shift approach (iOS 26-only vs `ARView`).
2. Default deciduous/evergreen mix and whether per-area style data is allowed.
3. Generalization areas.
4. Horizon profile source.
5. M1b scope.
6. GitHub backup via the steps given.
