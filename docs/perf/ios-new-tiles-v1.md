# A10 — iOS / RealityKit on A1's adaptive tiles

8 October 2026. **Compatibility audit complete; native new-tile frame measurements blocked.** Report only: no loader, generator, renderer, shader, test, app bundle or phone changes.

Inspected main `293abbcc0391bd1e6a7c89e9668989ac04f47f75`, which contains A1 checkpoint `4d58fe3` and its adaptive packer predecessors. `4d58fe3` itself changes retention/documentation, not the native loader. Package audit provenance is `Data/quality/adaptive-tile-packing.json` (`targetCommit: 939d04f`). The actual packed artifacts were read from A1's worktree `Generated/adaptive-targets/{sloans-lake,lakeview-sheil-park}`. These are generated local artifacts, not committed GLBs.

## Loader compatibility: it does not consume the tile format

The native RealityKit path consumes an **area directory with raw sources**, not a `worldengine.package/1` directory. Smaller exported leaves therefore do not reach native rendering unchanged. There is no existing adaptive package loader to exercise.

Exact checked paths (line numbers at the inspected main):

| File / line | Executed or inspected code path | Finding |
| --- | --- | --- |
| `Apps/WorldLab/Sources/ContentView.swift:517` | `RealityKitScreen.load`, bundle lookup at 525, `World.load` at 529 | Chooses the bundled raw area directory, not `Generated/adaptive-targets` or `world.json`. |
| `Sources/WorldEngine/World.swift:208` | `World.load` → detached `WorldBuild.generate` at 213 → `World.init` at 216 | Generates meshes from raw area data. No exported tile ingestion. |
| `Sources/WorldGen/WorldBuild.swift:47` | `generate` → `AreaLoader.loadManifest` at 48 → `loadFeatures` at 49 → generator at 57–60 | Native uses `buildingLODs = true` supplied at `World.swift:211`; export recipes/package chunks are not a drop-in equivalent. |
| `Sources/WorldMap/AreaManifest.swift:72` | `loadManifest` reads the area manifest filename; `loadDocument` at 79; `loadFeatures` at 93 | Loads `manifest.json`, then raw OSM/Overture feature sources; not `world.json`, chunk GLBs or replacement groups. |
| `Sources/WorldGen/SceneGenerator.swift:126` | 200 m generated chunk size, 100 m building cells at 136 | These existing generator units do not become adaptive leaves by changing an export directory. |
| `Sources/WorldEngine/World.swift:435` | `buildChunks` indexes generated chunks by grid `index` at 438, merges/splits them at 454–460 | Adaptive leaf `index` repeats the parent index. Direct substitution into this dictionary path would overwrite siblings. No substitution exists today. |
| `Sources/WorldEngine/World.swift:482` | `buildBuildingCells` → per-cell `BuildingLOD` mesh uploads | Native building LOD state is constructed from generated cells; package `featureOwnership` metadata is not read. |
| `Sources/WorldEngine/MeshUpload.swift:13` | `resource` consumes `WorldMesh.MeshBuffers`, uploads position/normal/paint/extra | No GLB decoder here. The `_FEATURE` join channel would need separate preservation in a package adapter; it is not an attribute in this native vertex layout. |
| `Sources/WorldEngine/World+Context.swift:37` | `startContext` → `ContextRing.build` at 46 | Still generates context from raw manifest sources; no adaptive residency path. |
| `Apps/WorldLab/Sources/WebScreen.swift:39` | `WebModel.start` mounts bundled `package/<area>` at 46 in a WKWebView | Package access here is the web renderer branch, not RealityKit. Checked `LocalServer.swift` file-serving path at 66–75 as well. |
| `Apps/WorldLab/project.yml:25` | Raw area folder resources, optional generated package at 47 | Adaptive-target directories are not bundled by this configuration. |
| `Sources/WorldPackage/AdaptiveTilePacker.swift:259` | Emits decoded costs, empty LODs at 262, groups at 303, ownership at 304, `tileLayout` at 305 and required capability at 309 | The package consumer must explicitly support `adaptive-budget-bvh/1`; keeping schema `/1` does not make it compatible with a raw-area loader. |

Repository searches for `GLB`, `glb`, `world.json`, `tileLayout`, package directories and `WorldPackage` in `Sources/WorldEngine` and the app's native path found no adaptive package reader. A loopback GLB MIME entry in `LocalServer` is not a native decoder.

### Executed input-contract probe

After A4 released its lock, ran an A10 job through `scripts/heavy.sh`, with `HEAVY_AGENT=A10` and `HEAVY_LOAD=25`. An additional check inside the job required actual load <25 before and after. Admission/start/end one-minute load was **17.91**; disk had approximately 77 GiB free. The job completed successfully and released its own lock normally; no other lane's lock was modified.

Used A1's existing `worldbake stats <packed-directory>` executable for each area. Both returned exit **1**, Cocoa error **260**, missing **`manifest.json`**. This is a shared **AreaLoader input-contract probe**, not an iOS launch or a RealityKit frame test: `Sources/worldbake/main.swift:128` → `Stats.markdown` in `Sources/worldbake/Stats.swift:20` → `AreaLoader`. The inspected `WorldBuild.generate` requires that same manifest at its first step. Both directories have `world.json` and lack `manifest.json`; copying them into the native raw-area slot cannot load them unchanged. Renaming `world.json` is insufficient because its schema and subsequent payloads differ.

## Measurements and floor comparison

**Requested native measurements with new tiles:**

| Area | Main triangles vs 400k | Shadow triangles vs 150k | Main draws vs 100 | Verdict |
| --- | --- | --- | --- | --- |
| Sloan's Lake | Unavailable: new tiles cannot enter native loader | Unavailable | Unavailable | Blocked, no floor pass/fail measured |
| Lakeview | Unavailable: new tiles cannot enter native loader | Unavailable | Unavailable | Blocked, no floor pass/fail measured |

Unavailable does not mean zero. Running the existing native `ViewDrawBudgetTests` would regenerate from `Data/areas` and could not establish a result **on the new exported tiles**. It was not run or represented as such. Its existing checks at `Tests/WorldEngineTests/ViewDrawBudgetTests.swift:155` and `:156` are main-view estimates (`<=100` draws, strictly `<400_000` triangles), not shadow counters.

`WorldStats` in `Sources/WorldEngine/World.swift:36` exposes resident and estimated main-view geometry/draw counts, but no shadow-triangle counter. `estimateView` at 903 applies camera-frustum bounds and adds main-view categories; it is not a shadow pass measurement. Shadow participation flags at `World.swift:446` and `:971` cannot reveal RealityKit's actual per-pass submissions. Even after a native adapter exists, measuring the 150k limit requires native per-shadow-pass telemetry or a labelled conservative caster estimate validated against a graphics capture. A1's byte limits do not establish that limit.

**Additional measurements actually performed:** independently read every packed leaf's two GLBs, validated headers, counted index triples and nonempty primitives, and recomputed decoded attribute/index-array bytes against package metadata. These are whole-area **static package totals**, excluding prototypes/instances, clutter, boundary, sky, host content and shadow work. They are not native per-frame triangles or draw calls.

| Area | Adaptive leaves | All-leaf LOD0 triangles | All-leaf LOD1 triangles | Nonempty GLB primitives, LOD0 / LOD1 | Worst pair decoded arrays (max LOD per leaf) |
| --- | ---: | ---: | ---: | ---: | ---: |
| Sloan's Lake | 76 | 451,997 | 133,249 | 110 / 110 | 3,756,466 B |
| Lakeview | 114 | 1,370,373 | 164,560 | 114 / 114 | 4,176,512 B |

If all static LOD0 triangles were submitted in one frame, Sloan's alone would exceed 400k by 51,997 (13.0%) and Lakeview by 970,373 (242.6%), before other content. This is a hypothetical full-area submission, not an observed frame. Primitive counts are potential unbatched mesh parts, not actual RealityKit draws. LOD1 triangle totals must not be compared to the shadow allowance: they are lower-detail main geometry, not shadow geometry. Smaller leaves reduce individual decoded bursts but preserve the underlying triangles; extra partitions can also increase submissions if not culled/batched.

Package `world.json` SHA-256 values match A1's completed audit:

- Sloan's: `2be0e8eca19ef56ceebf12830fbbd847ae71b3c9f7f5e065f33a0f6741c7093e`.
- Lakeview: `be237920c636ea240e934fe3c491bbaeab5156c31f8029f5e53822cb357a0f57`.

The earlier Lakeview street ~414k-vs-400k native estimate remains historical, open evidence; it was not rerun, fixed or waived by this audit. No native performance gain follows from A1's smaller GLBs until native integration is implemented and measured.

## Native changes required only if adopting the adaptive packages

**No native change is required to keep loading the existing raw areas.** To render A1's packed tiles instead, the following integration work is required; it is not a one-line format adjustment. Locations below identify the existing code that would need an alternative path, not instructions to make unauthorized edits.

| Existing location | Required integration |
| --- | --- |
| `ContentView.swift:525` / `:529`; `Apps/WorldLab/project.yml:47` | Select/bundle or retrieve the chosen adaptive package, distinguish raw-area and package entry points, and report unsupported capability explicitly. Keep the raw path valid. |
| `World.swift:208`; `WorldBuild.swift:47`; `AreaManifest.swift:72` | Add a dedicated validated package reader for `world.json`, schema/capability checks, file hashes, frame, materials, recipes, features and package resources. Do not reinterpret package JSON as `AreaManifest` or regenerate its geometry. |
| `MeshUpload.swift:13`; `World.swift:250` | Decode the exported GLB subset into native resources with original node origin, POSITION/NORMAL/_PAINT/_EXTRA and feature joins; handle valid empty LODs before attempting mesh upload. Preserve appearance and material-specific water/static behavior. |
| `World.swift:438` / `:455`; `:482` | Use unique leaf IDs and actual bounds, not repeated parent grid indices. Preserve stable feature ownership and avoid double-generating buildings already contained in packed chunks. Reconcile package two-level LODs with the existing native four-level building path explicitly. |
| `World.swift:208` / `:250` / `:482`; `World+Context.swift:37` | Add bounded asynchronous residency/decode/upload/eviction and atomic replacement-group switching: keep all required parent coarse payloads until every required child is ready, then switch without gaps or double draw. Account for overlaps, decode staging, CPU copies, GPU residency, props and context. Current eager generation/upload does not implement these policies. |
| `World.swift:36` / `:903`; `Tests/WorldEngineTests/ViewDrawBudgetTests.swift:125` | Add package-path measurement coverage and shadow-pass accounting; compare main triangles, shadow triangles and main draws at frozen Sloan's/Lakeview cameras with the floor. Existing raw-generator tests must not serve as package integration proof. |

File paths abbreviated in the last table resolve to the exact full repository-relative paths in the checked-path table above. Renderer owner approval and implementation are outside this report-only task. Next native measurement is gated on that integration and the available telemetry; no phone install or rendering edit was performed.
