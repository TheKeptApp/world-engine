# WorldEngine street-to-space streaming — proposal fitted to the checkout

**7 October 2026. For R and Claude lane review; no implementation authorized by this document.** Baseline minimum iOS 26, already present in the inspected code. Read alongside [compatibility.md](~/Desktop/worldengine-gpt-drop/mobile-rendering-v1/compatibility.md).

All descriptions of existing behavior are **inferred from code reading**. All sizes, thresholds, queue limits, memory allowances and phase estimates below are **proposed assumptions** until profiled. New P1 metadata mapping is **unverified — checkout behind main**, per R's clarification. No git, builds, tests or app runs were performed.

## 1. Fit the existing boundaries

**Inferred:** WorldMap parses source features; WorldGeo supplies the local frame and deterministic seeds; WorldGen/WorldBuild owns roofs, colors, lots, placement and mesh choices. WorldEngine uploads/updates native entities. WorldPackage exports renderer-neutral GLB plus metadata. The web WorldScene reads that package rather than generating houses. Preserve this division. [Package.swift](~/Desktop/world-engine/Package.swift:23), [WorldBuild.swift](~/Desktop/world-engine/Sources/WorldGen/WorldBuild.swift:30), [WorldPackage.swift](~/Desktop/world-engine/Sources/WorldPackage/WorldPackage.swift:54), [web world.js](~/Desktop/world-engine/web/src/world.js:1).

**Inferred:** current native loading generates an entire area, synchronously uploads many resources on the main actor, and only then starts detached context generation. Building near/mid/far/skyline cell meshes and merged tile variants are all resident, even when disabled. Current ground merges and native instance batches are rendering optimizations, not independently fetchable/resident tiles. The package exports a different two-level chunk representation. [World.swift](~/Desktop/world-engine/Sources/WorldEngine/World.swift:208), [building upload](~/Desktop/world-engine/Sources/WorldEngine/World.swift:484), [context](~/Desktop/world-engine/Sources/WorldEngine/World+Context.swift:36).

**Proposed architectural change:** offline WorldGen produces shared immutable tiles; runtime selection decides which prepared representations to fetch, decode, retain and display. RealityKit loads tile buffers through existing MeshUpload/CustomMaterial/instances; it does not re-run house rules for every tile arrival. Keep current in-process World.load as a tooling/demo adapter during migration, not the production streaming path.

## 2. Spatial grid and identity

| Layer | Proposed extent | Purpose / fit |
|---|---:|---|
| Ground/road/water leaf | 200 × 200 m | Matches package/1 chunks; preserve local node-relative vertices and existing feature mappings |
| Building detail cell | 100 × 100 m | Matches native buildingCells; near and mid are independent assets |
| Instance ownership leaf | 200 × 200 m | Index placed trees/props with the ground leaf; retain legacy 400 m cell as metadata, not mandatory batch extent |
| Mid aggregate | 400 × 400 m | 2 × 2 ground leaves / 4 × 4 building cells; merged simplified buildings/ground, cheap tree instances |
| Far aggregate | 800 × 800 m | Parent of four mid cells, with skyline/context geometry; bounded spatial batching rather than whole-world merging |
| Coarse district parent | 1,600 × 1,600 m | Sparse ground/water/major-road and skyline fallback for first launch and long clear views |

These are **transport/ownership units**, not promises that each tile contributes only one draw. Ground/water/material/foliage slots can contribute multiple draws. Sparse adjacent cells may share a render aggregate; ownership and eviction remain independently identifiable. Dense cells can have multiple bounded payload parts without changing their identity.

**Inferred:** current chunk/building indices use offsets from `features.bounds.min`, while prop cells use local x/y divided by 400. A bare `i_j` is not globally stable when area bounds/frame change. [SceneGenerator.swift](~/Desktop/world-engine/Sources/WorldGen/SceneGenerator.swift:206), [building cells](~/Desktop/world-engine/Sources/WorldGen/SceneGenerator.swift:251), [Props.swift](~/Desktop/world-engine/Sources/WorldGen/Props.swift:36).

**Proposed phase-1 rule:** namespace current cell IDs by immutable `frameId`, grid origin and size; a tile address includes `{frameId, gridId, level, i, j}` and a content revision/hash. Do not pretend legacy indices remain stable across a frame/bounds revision. For wider continuous coverage, P1 must publish stable regional grid origins and neighbor-frame transforms; retain Double geodetic/frame origins and float32 tile-relative vertices. Planet-scale canonical coordinates, camera-relative precision and globe attachments are mandatory from day one, including for the first bounded region; see §§12–14. Crossing frames must preserve true-scale coordinates and avoid duplicated seams. Do not seed style from tile indices.

Feature identity remains source-qualified strings (`way/123`, `node/…`, `relation/…`, `gen:…`), never JavaScript numeric Int64 values. **Inferred:** Overture is currently converted to an OSMRef using a shortened integer identity, while the source record contains the full GERS ID. [OSMDocument.swift](~/Desktop/world-engine/Sources/WorldMap/OSMDocument.swift:6), [OvertureSource.swift](~/Desktop/world-engine/Sources/WorldMap/OvertureSource.swift:241). **Proposed:** carry P1's full stable Overture ID through the new index, plus legacy aliases/migration metadata; do not manufacture a new ID from clipped geometry or array position. Generator choices are baked once using the existing deterministic identity/salts. [StableRandom.swift](~/Desktop/world-engine/Sources/WorldGeo/StableRandom.swift:1).

Whole buildings/lots/trees have one owner leaf by stable source centroid/anchor, with content bounds allowed to cross tile edges. Roads/water/large polygons may be clipped into fragments carrying the same feature ID and a deterministic fragment ID. Neighbor lookup uses actual content bounds, not only grid boxes. Build generation with a halo for street frontage/yard/garage/near-tree decisions; halo input is not duplicated rendered output. Multi-polygon parts must not be deduplicated merely because they share one source reference.

## 3. Tile contract: reuse package assets, add a streaming index

**Proposed:** an additive `streaming/index.json` declares a new extension identifier **`worldengine.streaming/1`**, separate from the existing `worldengine.package/1` identifier and P1's colloquial “v2 map layer.” A renderer must explicitly support the extension; the old eager viewer ignores it only when its original package/1 content is also available. Avoid dumping every detailed feature/instance into a giant root manifest.

| Proposed file | Contents |
|---|---|
| `world.json` | Existing frame, recipe/profile versions, shared palette/material/environment paths, credits/license notice and extension reference; compatibility export can still contain old chunk index |
| `streaming/index.json` | WGS84/ECEF and datum definitions; six globe roots and regional frame/grid attachments; small startup dependency set; policy defaults; hierarchical index-shard URLs/hashes/bytes |
| `streaming/index/<district>.json` | Tile addresses, geometric-error bounds, actual AABB, representations, child relationships, dependency hashes and byte/cost estimates |
| `tiles/<address>/tile.json` | Representation parts, geometry counts, native/web decoded-byte estimates, origin, covered feature classes/child masks, neighbor/ownership references, metadata links and material capabilities |
| `tiles/<address>/<representation>-<part>.glb` | Shared ground/building/water geometry with `_PAINT`, `_EXTRA`, `_FEATURE`; translation relative to tile origin. Far/mid proxies generated by WorldGen, not renderer decimation |
| `tiles/<leaf>/instances.json` | Stable IDs, kind/variant, transforms/stretch and owner; references shared prototype LODs, with explicit source/provenance link |
| `tiles/<leaf>/collision.json`, `clutter-tufts.bin` | Local collision hulls and bounded clutter candidates, not global startup documents |
| `mapmeta/…` | P1 metadata paths preserved once verified: identity, provenance/confidence, migration and lots/yards/doors/driveway links |
| `independent/…` | Separately licensed lot-slope/grid assets, referenced without relabeling their license or folding into ODbL map meshes |
| shared prototypes/palettes/materials/environment/credits | Content-addressed/versioned assets already owned by WorldGen; reused across all tiles/renderers |

Names above except current package files and user-identified P1 paths are **proposed**, not claims about existing filenames. Exact NJ/P1 field names must be adopted after review, not replaced by this table.

Use the current package custom vertex semantics and reject unsupported material capabilities. Native currently has no shared-package GLB importer inferred; propose a **bounded parser for the exporter-controlled GLB subset**, extracting vertex/index/custom attributes into MeshBuffers → MeshUpload. Do not assume Entity.load preserves `_PAINT` / `_EXTRA` custom semantics automatically. Start uncompressed; later require equivalent verified decode on both platforms before meshopt/quantization. The web can reuse GLTFLoader and material rebinding. [MeshUpload.swift](~/Desktop/world-engine/Sources/WorldEngine/MeshUpload.swift:6), [package-format.md](~/Desktop/world-engine/docs/package-format.md:64), [GLTFLoader documentation](https://threejs.org/docs/pages/GLTFLoader.html) (checked 2026-10-07).

## 4. Required P1/NJ metadata mapping — unverified checkout

R identifies P1's newer mainline mapmeta, calibrated map-confidence, migration map, independent slope data and NJ lots/yards/doors/driveway export. They were not present in this checkout; mapmeta/confidence/slope **field-level mapping is unverified — checkout behind main**. The available P1 handoff is older. Design against the following semantic requirements, then bind to the actual fields during phase 0:

| User-described field family | Proposed streaming requirement | What cannot be asserted yet |
|---|---|---|
| Stable IDs including Overture | Preserve full IDs and legacy aliases across near/mid/far geometry, instance and feature tables | Exact ID namespace/encoding/alias schema |
| Observed / inferred / simulated labels | Carry original status per property/feature; aggregate proxies retain provenance links, never promote inferred content to observed | Whether labels are per value, feature or both; enum/version names |
| Calibrated confidence | Retain the calibration method/version and original score; do not average arbitrary scores into a misleading parent confidence | Confidence units, calibration classes, validity intervals |
| Split/merged feature migration | Resolve source-revision changes with explicit many-to-many mappings and lineage; IDs and cached choices migrate atomically | Migration record schema and override conflict semantics |
| Lots/yards/doors/driveways | Preserve stable owner-building/lot and geometry/property links; inferred yards are not surveyed parcels; streamed facade LOD must not erase access anchors | NJ geometry type, feature names and reference rules |
| Lot slope / terrain-slope grid | Keep independent paths, units/CRS/nodata/source/license; expose query interface to camera/dressing consumers | Actual grid format/resolution, slope-vs-elevation semantics and license terms |

**Proposed constraint:** do not derive a terrain height field from slope alone. Current geometry is flat y=0; slope may inform dressing or placement only after P1 verifies its meaning. Detailed terrain displacement and matching collision heights are later scope; curvature, frame reprojection and datum-aware coordinates are required in the core design (§14). Do not wedge slope into palette attributes or merge separately licensed source data into the ODbL payload. Existing package license classification and visible OpenStreetMap attribution continue for all streamed states. [WorldPackage frame/license](~/Desktop/world-engine/Sources/WorldPackage/WorldPackage.swift:286), [repo rules](~/Desktop/world-engine/CLAUDE.md:9).

## 5. Near/mid/far selection and budget admission

**Proposed initial street detail bands:** buildings near 0–50 m, mid 50–150 m, far roof/body 150–600 m, skyline beyond 600 m; foliage retain current 45/160/400 m bands as a compatibility mode. Transport tile tier does not force every object to the same detail: a 400 m cell can contain near building subcells alongside a far aggregate with those subcells excluded.

**Proposed screen-error policy:** `E = e × H / (2 × z × tan(fovY/2))`, with authored conservative geometric error e, actual drawable height H and conservative positive distance z to content bounds. Refine above 2.5 px, coarsen below 1.5 px; ordinary movement has 0.3 s dwell, teleports bypass dwell. These thresholds are assumptions. Measure approximation error offline against the full mesh; do not assign invented errors just to force a desired tier. Near/intersecting bounds receive conservative detail selection. Aerial uses 3D eye-to-bounds distance and projected error; it must not preserve near facades simply because its x/z lies above a cell. Current building horizontal-distance behavior is a concrete gap to fix. [current LOD selection](~/Desktop/world-engine/Sources/WorldEngine/World.swift:566).

Run spatial selection at about 5 Hz, plus immediate turn/FOV/teleport invalidation; retain the existing 8 m rebucket trigger where useful. Instance transforms update only when membership changes. Selection order: visible missing coverage → near interaction/collision → desired refinement → shadow-support representation → prefetch. Frustum bounds have a conservative turn margin; known shadow casters are eligible even when visually offscreen. Cull before fetch, but retain small turn lookahead.

Use separate render-coverage ownership for ground, buildings and foliage. For each class, a parent proxy either renders the whole covered class or explicit uncovered child subparts. **Never disable an entire 800 m parent because just one 200 m child is ready.** Choose either (a) atomic complete child-set replacement or (b) exporter-authored coverage masks/subparts. Initial coverage scheduling uses complete replacement groups with budgeted morph/complementary fades (§15); near detail can overlay only if its matching parent building/foliage section is absent. Plain overlapping coarse and fine buildings are not acceptable.

Memory readiness and draw/triangle admission precede a visible switch. Parents stay until complete child replacement is decoded, uploaded and attached; failure keeps prior coverage. Eviction reverses that process: prepare/show parent, then remove descendants. No persistent crossfade duplication; temporary transitions must satisfy the same hard gates (§15). Prevent refinement that blows the draw budget even if its geometric error requests it.

**Proposed render admission envelope**, honoring the existing main/shadow contract:

| Main-view category | Draw planning allowance | Triangle planning allowance |
|---|---:|---:|
| Ground/roads/water | 15 | 70k |
| Near buildings | 25 | 80k |
| Mid buildings | 15 | 45k |
| Far/context buildings and ground proxies | 16 | 20k |
| Foliage | 14 | 50k |
| Fixed props | 4 | 5k |
| Host characters | 3 | 15k |
| Sky/weather/other | 4 | 5k |
| **Planned main total** | **96, plus 4 draw margin** | **290k; do not fill 400k ceiling automatically** |

These allocations are assumptions, not measured entitlements or current test counts. Current native estimates omit host/sky/weather triangles; extend reporting during implementation so these categories are honestly visible. Keep a **separate 150k shadow-triangle ceiling** from the v2 spec, plus measured pass costs. Retain current 120 m / 150 m low-sun shadow policy pending R/P3 review; geometry at far tiers should not cast by default. Budget shadow-only supports at reduced geometry while preserving near receiver quality. No new cascades or fixed-sun lightmaps required.

**Proposed:** adapt detail by global priority when near cells are dense; do not claim a fixed 3×3 near area guarantees <100 draws. Native can consolidate visible instances from multiple ownership leaves into existing kind/variant/slot groups, preferably bounded 800 m render aggregates only where the draw count permits. Ownership cell ≠ instance batch. Avoid five slots × all kinds × every 200 m tile. Index CPU membership spatially so it stops scanning a city-wide resident list. Keep stable origins/color/season hash inputs through tile-relative transforms.

## 6. Prefetch: walking, recap and aerial

| Mode | Proposed lookahead | Priority and cancellation |
|---|---|---|
| Ordinary walking | 12 s along heading/velocity, distance clamped 60–180 m; one 200 m lateral leaf margin | Next near/mid cells before fine rear detail; hysteresis on heading; cancel after route change |
| Known walk recap | About 20 s of the recorded route, capped at 300 m; compute in playback speed, not wall-clock assumptions | Sequence tile dependencies for upcoming bends; scrubbing invalidates old generation immediately |
| Aerial orbit/pan | Current visible projected footprint plus approximately 20% edge margin and 2 s camera-motion prediction | Coarse parents first; mid cells where error/budget justify them; no all-visible near-detail prefetch |
| Zoom/teleport/mode transition | New district parent and desired visible leaf set | Pause obsolete prefetch, preserve old valid coverage or openly show loading; do not clamp geography to hide a missing tile |

Every value is an assumed starter. At walking speeds, the minimum margin intentionally exceeds the short distance traveled so a turn can reveal ready geometry. Under serious heat, low-power intent, weak network or pressure: suppress speculative detail first while retaining immediate visible/coarse coverage. No exact user-home request requirement is added here; route data stays in the app, and the engine requests tile addresses rather than uploading a recorded route.

## 7. Residency, queues and memory

**Approved desktop Chrome amendment — R, 9 October 2026:** validate with about 20 other Chrome tabs and normal apps; record tab count and max load per flight/control. Staged whole-step upload p99 ≤0.5 ms, max ≤2 ms; renderer-side upload peak reported and attributed separately; resident geometry ≤48 MiB. Load <5 is optional reference only. Native ledger assumptions below remain unchanged. See [approved desktop criteria](../../design/streaming-design.md#7-residency-queues-and-memory).

**Proposed A16 trial ceiling: 256 MiB logical streamed-content allowance**, not a proven safe iOS memory limit and not 256 MiB added on top of the current eager world. It replaces that world's comparable allocations. Native unified memory must not be confused with independent physical CPU/GPU pools; count logical ownership conservatively and confirm actual process footprint. Global app/UI/host character, framebuffer/shadow/post targets and OS/driver overhead need separate measured room.

| Ledger component | Proposed allowance |
|---|---:|
| Resident streamed geometry and instance GPU allocations | 96 MiB |
| Shared prototypes / palette / tile texture resources | 32 MiB |
| Retained decoded CPU data | 48 MiB, including ≤16 MiB warm inactive cache |
| In-flight source/decode/upload staging | 24 MiB |
| Index, metadata and collision working set | 8 MiB |
| Unallocated transition/pressure margin | 48 MiB |
| **Logical allowance** | **256 MiB** |

Pin shared resources, a compact coarse coverage set, active near collision and visible representations. Pin only bounded parent coverage, not every hierarchy level. Compress/store inactive content on disk rather than retaining every CPU mesh plus its GPU copy. Track bytes by content hash/owner and reference counts. `meshBytes` is useful input but not a complete memory ledger. [current byte estimate](~/Desktop/world-engine/Sources/WorldMesh/MeshBuffers.swift:152).

Evict obsolete speculative work → inactive decoded details → offscreen fine tiles → finer visible details after parents are ready. On memory warning/critical heat, lower the dynamic allowance and turn off speculative prefetch; no promise that the initial ceiling is safe. Maintain last-known coarse content offline. Disk cache starts at a proposed 512 MiB cap (compressed bytes), user-clearable and versioned; available storage can lower it. Derived per-tile cost estimates guide admission before downloads, with actual allocation telemetry correcting them.

Proposed queues: at most 4 network requests, 2 decoders, and 1 main-actor upload/attachment operation per frame. Limit each upload payload part to roughly 2 MiB; the original native proposal targets ≤0.5 ms measured main-thread upload/attachment work per frame (desktop Chrome now uses the approved staged p99/max amendment above), but do not claim Task.yield enforces it. A single long upload cannot be preempted by yielding afterward; exporter split or staged mesh upload is required. Cap decoded queued bytes at 16 MiB within staging. Hash/version/epoch-check every result; cancelled or old-camera results may enter disk cache but cannot attach as current content. Use measured dependency scheduling rather than unbounded Promise.all or city-wide generated arrays.

## 8. Coarse-first useful launch

1. Read small root index, frame, material/palette/credits/environment and initial camera/experience metadata. Prebundle the static six-face fallback Earth, a loading state and attribution, not a fabricated real neighborhood (§13).
2. Show cached or small district coarse mesh plus sky using the correct world frame. Proposed cold download starter ≤2 MiB total coarse/startup assets where feasible; this is a packaging target, not a time guarantee.
3. Load immediate 200 m ground leaf, neighboring crossing content bounds, and near collision/access anchors. Until these are ready, allow aerial/coarse navigation but mark street-follow readiness pending; do not walk through missing hulls.
4. Refine near building cells and visible foliage; load the minimal prototype set, then other seasonal/LOD dependencies on demand. Existing context ring resources become coarse streaming parents rather than one late full-ring attachment.
5. Report **first displayed frame**, **first usable coarse world**, **street-follow ready**, and **near refinement settled** separately. Cold/warm/offline are separate results.

No target launch seconds can be verified without a build/device/network run. Keep palette/environment changes separate from geometry invalidation; time scrub must not redownload roofs or shuffle inferred yard/tree identities.

## 9. three.js reuse

**Inferred:** the web already loads GLB with GLTFLoader, replaces materials using the shared custom semantics, groups instances by kind/variant/400 m cell, and loads chunk LOD0 everywhere. It eagerly loads global JSON/binary data. [web world.js](~/Desktop/world-engine/web/src/world.js:87).

**Proposed:** replace eager load with the same index/selection policy and tile store. Decode the same GLBs; preserve `_FEATURE` for metadata instead of deleting it during chunk traversal. Convert instance records into the existing InstancedMesh path; preserve the code's backend-specific capacity rule until validated otherwise. Render backend may vary, but geometry/style/placements/provenance remain identical. Native and web fixture selection should compare IDs, origins, tier choices, owner coverage, material semantics and ≤1 cm placement tolerance. This is a future validation plan, not a test performed here.

Use workers for decode where supported, bounded uploads on the render loop, and explicit geometry/texture disposal without freeing shared prototypes still referenced elsewhere. Browser cache/storage availability and thermal telemetry differ; share policy inputs/schema, not an assumption that web gets iOS thermal notifications or a known RAM allowance. Keep independent slope assets and metadata available to NJ/data consumers even when rendered far detail is simplified.

## 10. Original regional phased plan and cost — superseded by §18

**Assumed effort:** engineer-days of focused work, inclusive of normal review/validation but excluding dataset acquisition, whole-US service hosting, new terrain rendering or a renderer rewrite. Agent throughput cannot be predicted from this review. No dollar estimate is supplied without a labor rate. Phases can overlap only after contract review; do not sum agent concurrency into a guaranteed calendar date.

| Phase | Scope / current-code seam | Assumed effort and relative cost | Exit criterion for Claude review |
|---|---|---|---|
| 0 — reconcile evidence and contract | P1 actual mapmeta/NJ/slope mapping; counter/GPU target definitions; API/runtime probe review | **1–2 days, low** | Exact field/unit/license mapping; main vs shadow agreement; no unknown API required by baseline |
| 1 — shared tile exporter | WorldGen/WorldBuild authored LOD parity; WorldPackage additive index, split payloads, IDs/ownership/proxies/metadata | **4–7 days, high** | Byte-stable same-input exports; near/mid/far identity/coverage/seam fixtures; budget/decoded-byte metadata; licenses preserved |
| 2 — tile store and native importer | Bounded GLB subset → MeshBuffers; shared dependencies, cache/hash/epoch and resource lifetime | **4–6 days, med/high** | Lazy load/evict without growth; cancelled result cannot attach; unsupported materials rejected |
| 3 — native selection/residency | Refactor eager World.load/buildChunks/buildBuildingCells/buildProps/ContextRuntime; parent replacement, projected LOD, caster support | **4–7 days, high** | No holes/doubles; correct street/aerial/low-sun behavior; main/shadow limits reported separately |
| 4 — web adapter and contract parity | Refactor web WorldScene load; bounded GLTF loads, retain feature metadata, dispose resources | **3–5 days, medium** | Same tile IDs/coordinates/choices/provenance and seam behavior across both renderers |
| 5 — launch, walking/aerial prefetch and heat | Coarse-first stages; route/camera predictions; DisplayPolicy integration and memory-pressure ladder | **3–5 days, medium** | Useful launch metrics; bounded waste/staging; offline/mode-switch/recap correctness |
| 6 — sustained validation and tuning | Existing view gates plus actual pass captures, dense-city routes, 20–30 minute A16 run | **2–4 days, medium** | Stable memory plateau, useful coverage increase, warm 60 fps, reconciled GPU target, art approval |
| **Total assumption** | Baseline shared streaming, not nationwide production infrastructure | **21–36 engineer-days** | Review each phase before widening scope |

Suggested initial areas are the existing Sloan's Lake and Lakeview public test fixtures: one water/long-view scene and one dense street. Add Wilmette/Evanston afterward to catch large crowns, mixed density and independent P1 data. Do not require all US metros before proving bounded residency.

## 11. Decisions for R and lanes

1. Confirm the current 120/150 m sun look and reconcile v2's older GPU/device target with the A16 60 fps context. Keep visual quality when choosing admission priorities.
2. Review the additive globe contract and 200/100/400/800/1,600 m local hierarchy, with camera-relative precision and explicit parent coverage replacement (§§12–15).
3. Have P1/NJ bind the semantic metadata table to their actual merged export; missing fields remain unverified until then.
4. Approve the trial memory/queue allowances as tuning starting points, not supported-device guarantees.
5. Keep textured crown impostors, new native cascades/lightmaps, GPU-driven Metal submission and detailed DEM/cloud ingestion outside the core ladder; globe coverage, curvature, precision and depth design belong in it (§18).

This document makes those proposals reviewable. It does not ask Claude lanes to start work, run commands or make changes.

## 12. Street-to-space requirement and complete level ladder

**Scope update, 7 October 2026:** continuous zoom must reach space. The regional streaming proposal above is now the detail end of a planet-scale design. Sections 12–18 supersede the original regional-only sequencing and effort estimate in §10. All design numbers below are **proposed assumptions**, not device measurements. External source facts are **verified against the linked primary sources on 2026-10-07**; repository behavior remains **inferred**. No global coverage of individual buildings is implied by global terrain coverage.

Keep one true-scale Earth, one geodetic camera target and a continuous logarithmic zoom control. Use camera altitude, slant distance, projected error and visible footprint together; altitude alone is inadequate for a grazing horizon view. These names describe overlapping presentation bands, not abrupt switches or seven independent worlds. Illustrative altitude is above the local reference surface; footprint depends on field of view and tilt.

| Band | Illustrative camera altitude / extent | Visible data and representation |
|---|---|---|
| Street | 1–80 m; immediate 5–600 m surroundings | Existing detailed houses, trees, yards, roads, walk collision and nearby live objects; locally accurate ground where available |
| Neighbourhood | 30 m–2 km; roughly 0.5–10 km footprint | 200 m leaves transitioning into 400/800/1,600 m aggregates; simplified buildings/crowns, major road edges, land cover and terrain |
| City | 1–30 km; roughly 5–100 km footprint | Terrain, major roads/water, aggregate urban mass and landmark silhouettes where licensed assets exist; individual trees and house details disappear |
| Region | 20–300 km; roughly 100–1,500 km footprint | Terrain relief, land-cover colour fields, coastlines, large lakes, coarse city areas; cloud layer and night radiance |
| Continent | 200–2,500 km; roughly 1,000–8,000 km footprint | Coarser relief and land cover, coastlines, terminator, clouds, major night-light concentrations; no individual urban geometry |
| Globe | 1,500–20,000 km; Earth increasingly fits the view | Ellipsoidal Earth, streamed surface tiles, simple atmosphere limb, sunlit/night sides, cloud coverage and night lights |
| Orbit / space | Default continuation 20,000–100,000 km; Earth can shrink to an object | Same Earth plus inertial stars, sun/moon and computed satellite points; no separate replacement planet |

An optional low-Earth-orbit camera at 200–2,000 km belongs to the **orbit camera mode**, while its surface LOD follows region/continent rules. Thus “orbit” is not an assertion that satellites begin above the globe band. The initial outer limit is 100,000 km from Earth's surface; arbitrary solar-system travel is outside scope. Moon placement can be physically correct beyond that camera range. Sun/stars are directional sky rendering, not enormous float-coordinate meshes.

Preserve the selected street/house's WGS84 anchor during zoom. Camera orientation smoothly changes from local up to planet-centred framing, with continuous roll and a stable previous tangent basis near poles. Globe navigation must support poles, the antimeridian, oceans and Southern Hemisphere locations from its first release. Returning to street level restores the same feature ID, heading and walk position. At uncovered streets, show coarse mapped coverage and an explicit detail-unavailable state rather than invented houses presented as mapped.

## 13. Global tile hierarchy and local chunk attachment

**Proposed:** use a six-face cube projected onto the WGS84 ellipsoid, with a quadtree on each face: `{schemeVersion, face, level, x, y}`. Four children refine each tile. Define face orientation, edge-neighbour rotations, bounds and ellipsoid projection in the shared contract, with fixtures at all twelve cube edges, poles and the dateline. This avoids a Web Mercator polar cutoff. It is a proposed custom addressing scheme, not a claim that the existing exporter implements 3D Tiles.

Keep the current metric grid. A globe leaf is **not an exact 200 m square**: its physical size varies across the cube projection. Existing 200 m ENU ground chunks and 100 m building cells attach to global tiles through geodetic content bounds and a regional detail index. Their primary owner remains the immutable regional frame/grid/feature identity in §2. Intersection references may appear in several globe tiles, but the tile store renders the owner once. Existing 400/800/1,600 m aggregates remain local parents inside that attachment. Do not re-seed houses, split a whole building or rename P1 features to fit cube edges.

Global roots → face quadtree surface tiles → regional index attachment → 1,600/800/400 m local aggregates → 200 m ground/ownership leaves → 100 m building cells. Global terrain and regional details are independent layer trees sharing coverage rules; they need not have identical refinement levels. Choose depth from measured geometric error and projected texel size, not a hardcoded level-to-altitude table. A deep face level may have a scale of a few hundred metres, but only the local grid guarantees the package's exact 200 m extent.

Extend the proposed streaming manifest with:

- WGS84 ellipsoid/version, ECEF Double origins, local-to-ECEF rotation, horizontal CRS, vertical datum and metres as canonical units;
- six globe roots, optional regional-detail attachments, per-layer child availability and fallback coverage;
- geodetic bounds, conservative ECEF bounds, min/max height, geometric error, texture sampling error and horizon-culling bounds;
- layer/product/version, source date, licence/credit reference, quality/nodata mask and observed/inferred/simulated status;
- actual payload hashes/bytes/costs, parent-child edge compatibility, local detail owners and P1 migration links.

Bundle a small static six-face fallback Earth with generalized land/ocean colours and a licence manifest. This supplies coverage before networking; it is clearly a static cartographic layer, not current imagery. Regional detail remains independently downloadable. An initial ≤2 MiB compressed starter remains a packaging goal; high-resolution clouds, DEM and land cover are not startup dependencies.

Selection combines frustum culling, conservative ellipsoid horizon culling, screen-space error, projected texture error and residency admission. Tiles crossing the horizon must not be rejected merely because their centre is hidden. Refine camera-facing ground before distant limb detail. Reuse §5 hysteresis; neighbour terrain LOD differs by at most one level, including across face edges. Navigation prediction extends §6: walking predicts metric leaf crossings; aerial motion predicts the projected footprint; globe rotation predicts the arriving limb and one adjacent coarse ring. Pin coarse roots and bounded fallback parents, never an entire ancestor chain for every leaf.

## 14. Planet precision, curvature and depth — mandatory from day one

**Inferred:** [LocalFrame.swift](~/Desktop/world-engine/Sources/WorldGeo/LocalFrame.swift) already uses Double WGS84/ECEF calculations, then flattens the local result and casts scene coordinates to Float. This is a useful mathematical starting point, not a planet-ready render transform. The existing flat-ground assumption must be explicit legacy metadata.

**Proposed canonical model:** store feature anchors, tile origins, camera, routes and ephemerides as Double geodetic/ECEF metres. Preserve ellipsoid up/curvature. GPU mesh vertices stay float32 **relative to their small tile origin**. Subtract large coordinates before conversion to float. For tile origin `P`, render origin `C`, tile rotation `Rtile`, view rotation `Rview`, and small local vertex `v`, compute `Rviewᵀ(P − C)` in Double, then combine with `Rviewᵀ Rtile v` in the render adapter. Do not first cast `P` and `C` to Float. A float32 coordinate around Earth's 6.4 million metre radius has approximately 0.5 m spacing (**derived from float32 precision**), enough to damage street details.

Near rendering uses a camera-relative origin, optionally snapped to a 256 m ECEF/local grid to avoid rewriting every resource each frame. Rebase before local camera offset exceeds a proposed 1 km; only transforms change, not feature identity, canonical routes or cached geometry. Far surface tiles also use their own origins and camera-relative transforms; adapters may use high/low encoded coordinates or render-only kilometre scaling where needed. Canonical units and collision remain metres. Relative-to-eye rendering is an established precision approach; see the official [Cesium precision API explanation](https://cesium.com/downloads/cesiumjs/releases/b20/Documentation/czm_modelViewProjectionRelativeToEye.html) (historical API reference, checked 2026-10-07), not an assertion that WorldEngine adopts that API.

Define these acceptance goals now: cross-renderer near-placement agreement ≤1 cm **excluding source terrain accuracy**; rebase-induced image shift <0.25 pixel; distant coordinate quantization contributes <0.25 pixel projected error. Test long flights, hemisphere changes, return-to-home, polar movement and face boundaries. Do not loosen canonical precision because globe pixels are coarse.

Precision also requires a **near/far depth partition**. A single camera with centimetre near clipping and a 100,000 km far plane is not an acceptable baseline. Day-one adapter interfaces must support a near street pass and a far Earth/sky pass with common camera/lighting and explicit nonoverlapping coverage. Illustrative near clips are 0.05 m–10 km, tightened dynamically; far rendering uses scaled units and a near clip appropriate to the nearest visible Earth surface. An overlap around 2–10 km is resolved by coverage masks and synchronized transitions, not two coplanar ground layers. Actual clips follow camera geometry and tests, not fixed numbers in all modes.

**Native feasibility remains unverified:** [OffscreenRenderer.swift](~/Desktop/world-engine/Sources/WorldEngine/OffscreenRenderer.swift) uses RealityRenderer for offscreen postcards; that does not prove efficient continuous two-pass composition inside the current RealityView. Phase G1 must prove the composition path and depth/occlusion cost before committing to its implementation. An owned Metal far pass is an alternative requiring review, not an assumed free RealityView capability. Three.js can implement separate near/far scenes/cameras and ordered composition; reverse/logarithmic depth is backend-dependent and must be validated rather than made a shared requirement.

Terrain height is a separate precision issue: SRTM uses EGM96 orthometric heights; Copernicus DEM uses EGM2008. Convert `h = H + N` using the appropriate geoid correction before joining to ellipsoid coordinates; retain original datum and nodata. P1 slope alone cannot provide height. Copernicus is a **surface model including buildings/vegetation**, so do not place a procedural house on its rooftop height or call it surveyed street ground. Day one must carry datum/quality fields and curvature; detailed DEM ingestion and trusted local ground reconciliation can follow. [USGS SRTM](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm), [Copernicus DEM definition](https://dataspace.copernicus.eu/explore-data/data-collections/copernicus-contributing-missions/collections-description/COP-DEM) (verified 2026-10-07).

## 15. Seamless refinement and atmosphere

**Approved desktop Chrome amendment — R, 9 October 2026:** compiles after startup 0 and completed detail groups >0 for every streaming flight; retain atomic coarse/outgoing coverage until complete replacement. Pair every flight with uploads-disabled control under the same realistic profile; no visible-hole requirement is waived. See [approved refinement criteria](../../design/streaming-design.md#15-seamless-refinement-and-useful-detail).

**Proposed visual contract:** no visible holes, duplicated houses, sudden silhouette swaps or exposure jumps during a continuous zoom. Parent coverage stays until all required replacement parts are ready. Under poor networking, hold a coarser valid surface rather than revealing empty fine tiles. Admission limits apply to both representations during every transition.

Terrain vertices geomorph from the parent's sampled height to the child over 0.3–0.8 s; matching edge samples and bounded skirts prevent cracks. Carry the morph through normals and adjoining tiles. Never use a skirt as a substitute for correct street/collision height. Land-cover textures blend in linear colour over the same interval. Urban aggregates transition over 0.8–1.5 s using stable world-seeded complementary coverage/dither, with geometry fading out before its projected detail becomes unreadable. Prefer opaque coverage transitions over blended stacks of every tree/building. Depth and shadow handling for dither in the native material path must be proven; otherwise use compatible mesh morphs and subpixel detail removal, then review captures before accepting the transition.

Reserve at most 15% above the planned main-view triangle count for active transitions, still below the absolute 400k limit; admit one bounded replacement group at a time if necessary. Do not crossfade two full cities. Fade caster contribution with detail coverage and keep the existing 120/150 m sun-shadow look at street level. Large-scale terrain uses cheap directional shading rather than continent-wide real-time shadow maps.

Sky colour, aerial haze and atmosphere limb derive continuously from altitude, sun direction and optical-path approximations. Use a cheap gradient/LUT and one limb shell; no volumetric ray marching in the baseline. Ground-level haze should recede as the observer climbs rather than turning space into a grey sky dome. Adjust exposure smoothly with an explicit time constant (proposed 1–2 s), preserving readable street lighting and a natural dark space background. These are art/math assumptions requiring style-B review, not measured atmospheric simulation.

## 16. Layer sources, licences and live-sky integration

**Verified source facts, checked 2026-10-07.** Proposed use is explicitly separate from the source facts. Keep licences layer-specific; a public-domain raster does not remove OSM obligations. A build manifest retains product/version, URL, licence, attribution, modifications, source date and quality mask. The app's data/credits panel exposes these at all zoom levels, with required visible credit overlays where applicable.

| Layer / source | Verified availability and rights | Proposed use and limitations |
|---|---|---|
| SRTM, official NASA/USGS release | Approximately 30 m at 1 arcsecond; coverage 60° N–56° S, acquired in 2000; EGM96 heights. NASA-led data follow CC0 unless a product specifies restrictions; USGS-authored released data are public domain. [USGS product](https://www.usgs.gov/centers/eros/science/usgs-eros-archive-digital-elevation-shuttle-radar-topography-mission-srtm), [NASA policy](https://www.earthdata.nasa.gov/engage/open-data-services-software/data-use-policy), [USGS licensing](https://www.usgs.gov/data-management/data-licensing) | Regional terrain fallback, not polar coverage, survey-grade streets or ocean-floor data. Record the precise product's rights; do not assume third-party SRTM derivatives have identical terms. |
| Copernicus DEM GLO-30 / GLO-90 | Worldwide land surface model, nominal 30/90 m; EGM2008. Public GLO products use a custom free licence permitting adaptation/distribution with obligations, **not CC0**. [Product](https://dataspace.copernicus.eu/explore-data/data-collections/copernicus-contributing-missions/collections-description/COP-DEM), [licence PDF: public GLO-30 terms, pp. 22–24](https://dataspace.copernicus.eu/sites/default/files/media/files/2025-06/copernicus_contributing_mission_data_access_v2_cop_dem_licenses.pdf) | Preferred broader land DEM after datum/quality reconciliation. Preserve required original/modified credit, liability notice, no endorsement and downstream terms from the applicable licence. Review exact notice text during ingestion. No bare-earth or bathymetry claim. |
| ESA WorldCover | 2020 v100 and 2021 v200, 10 m, eleven land-cover classes, CC BY 4.0. [Data access and credit requirements](https://esa-worldcover.org/en/data-access), [2021 dataset](https://doi.org/10.5281/zenodo.7254221) | Static region-to-globe stylized colour fields. Use class fractions/majority when downsampling, not arithmetic averages of class codes. Retain ESA's required map credit, licence and modification statement. Not imagery, current lawn condition or individual-yard truth. |
| Natural Earth | Raster/vector datasets public domain. [Terms](https://www.naturalearthdata.com/about/terms-of-use/) | Generalized 1:10 million / 1:50 million / 1:110 million coastlines for continent/globe fallback. These scales are not metre resolutions. Match/fade to finer licensed coastlines near cities; do not use generalized coastlines to relocate mapped local water. |
| NOAA GOES ABI | Full-disk scans normally every ten minutes; visible and infrared bands. Current GOES-East/West are GOES-19/18. NOAA-authored data are generally public domain, with exceptions for third-party content and no endorsement. [ABI](https://www.nesdis.noaa.gov/our-satellites/currently-flying/goes-east-west/advanced-baseline-imager-abi), [coverage/schedules](https://www.nesdis.noaa.gov/our-satellites/currently-flying/goes-east-west/goes-schedules-and-scan-sectors), [rights](https://www.noaa.gov/office-education/outreach-communication/faq) | Reproject an identified NOAA cloud product to surface tiles; Western Hemisphere coverage, **not global clouds**. Use day/night-appropriate products and quality masks. Additional hemispheres need separately verified providers/licences later. |
| NASA Black Marble VNP46A4 | Global annual night-light composite at 15 arcseconds; NASA data policy applies, subject to product-specific terms. [Product](https://ladsweb.modaps.eosdis.nasa.gov/missions-and-measurements/products/VNP46A4/), [Collection 2 DOI](https://doi.org/10.5067/VIIRS/VNP46A4.002), [policy](https://www.earthdata.nasa.gov/engage/open-data-services-software/data-use-policy) | Static, quality-masked night radiance pyramid, illuminated only on the night side. **Inferred:** existing [black_marble_xyz.py](~/Desktop/world-engine/scripts/data/black_marble_xyz.py) builds a regional input for sky glow; it is not yet a global surface-light layer. No individual-window or live-power claim. |

For GOES, store acquisition time per footprint, retrieval time, product ID, quality and coverage. Crossfade two cached cloud snapshots without labelling their interpolation observed. Proposed refresh is every 10–15 minutes, stale after 30 minutes; missing/stale thresholds remain assumptions. A shell placed at an assumed 6–12 km is **simulated height** unless an actual cloud-height product supplies it. Unknown outside coverage remains unknown, or a clearly labelled simulated cloud option. NOAA's [experimental viewer warning](https://goes.noaa.gov/systeminfo.php?src=nav) also means the visual cloud layer must not serve as an operational hazard-warning feed. Recaps must use timestamped archived data or mark unavailable; never substitute today's clouds for a historical walk.

**Inferred LiveSky reuse:** retain existing sun/moon calculations, stars and satellite propagation, but change the observer to the camera's geodetic/ECEF position when leaving the ground. [Sky contract](~/Desktop/world-engine/docs/live-world/sky.md), [SatellitePasses.swift](~/Desktop/world-engine/Sources/LiveSky/Satellites/SatellitePasses.swift), [SkyGlow.swift](~/Desktop/world-engine/Sources/LiveSky/Sky/SkyGlow.swift). Existing ground-topocentric altitude/azimuth cannot simply become orbital coordinates. Define Earth-fixed ↔ inertial rotation at a shared UTC instant, document UT1/UTC and propagation approximations, and carry frame/units in every body record. Stars are inertial directions; satellites and the moon have positions, occultation and illumination. Sun drives the same terminator, clouds and local shadows across both passes. Moon scale/phase is continuous, not a decorative replacement disk.

Satellite positions are **computed from dated elements**, not live observed positions. Cache elements and propagate locally. [CelesTrak policy](https://celestrak.org/usage-policy.php) (updated 2026-05-22, checked 2026-10-07) specifies two-hour GP update cadence and error handling; commercial redistribution rights are **unverified** by that usage page and must be resolved before packaging a feed. Existing [star notice](~/Desktop/world-engine/Sources/WorldEnvironment/Catalog/STARS-NOTICE.md) documents the catalogue and a remaining rights-verification caveat; preserve it, and separately clear expanded catalogues. Do not assign blanket CC0 to LiveSky's inputs.

At orbit altitude, disable the ground-observer skyglow kernel; star visibility follows exposure, sun/bright Earth glare and occultation. Retain existing computational/provenance labels. Proposed cheap caps: 256 bright star points and 64 selected satellite points initially, with no satellite models or trails required. Higher-density stars are later assets with their own rights/performance review.

## 17. A16 budgets and shared three.js implementation

**Approved desktop Chrome amendment — R, 9 October 2026:** frame p99 ≤20 ms; intervals >33.33 ms ≤0.1%; staged whole-step p99 ≤0.5 ms/max ≤2 ms; compiles 0; streaming detail groups >0; resident geometry ≤48 MiB; renderer upload peak attributed. About 20 other Chrome tabs, normal apps, paired controls and tab count/max load per flight are required. Load <5 is optional reference, not validity. M1 Max results do not prove mid-range laptop behavior; lower-tier testing comes later. These desktop criteria do not change the native A16 assumptions below. See [approved desktop qualification](../../design/streaming-design.md#17-desktop-frame-timing-and-qualification-limits).

**Assumptions to validate on a warm A16, 60 fps:** counts below sum near and far main-view submissions, including surface, clouds, atmosphere and sky. They do not hide a second globe pass outside the budget. Shadow submissions are reported separately, along with actual total passes/GPU time. Existing counters are estimates (§5 and compatibility.md); expand their scope before using them to certify these targets.

| Band | Planned main draws | Planned main triangles | Shadow triangle ceiling | Proposed total GPU target | Streamed-content allowance ceiling |
|---|---:|---:|---:|---:|---:|
| Street | 96 | 290k | 150k | ≤12 ms | 256 MiB |
| Neighbourhood | 85 | 250k | 150k, near casters only | ≤11 ms | 256 MiB |
| City | 70 | 220k | 0; baked/analytic shading | ≤10 ms | 224 MiB |
| Region | 55 | 160k | 0 | ≤8 ms | 192 MiB |
| Continent | 40 | 100k | 0 | ≤7 ms | 160 MiB |
| Globe | 30 | 80k | 0 | ≤6 ms | 128 MiB |
| Orbit | 40 | 100k | 0 | ≤7 ms | 160 MiB |

Absolute main-view gates remain **≤100 draws and <400k triangles**, including temporary transitions. A 15% street triangle reserve reaches 333.5k, leaving room below the ceiling; street draw transitions must fit the four spare draws or replace smaller groups. GPU targets include compositing, shadow and post costs; they are proposed headroom beneath the stated A16 13–15 ms context, **not evidence of meeting v2's older ≤10 ms iPhone-13 target**. That target still requires an explicit product decision and device measurements.

The §7 256 MiB ledger is still the maximum logical content allowance, not an added planet allocation or safe process-memory guarantee. Within it, a proposed globe-heavy rebalance is 64 MiB geometry/instances, 64 MiB shared prototypes and tile textures, 48 MiB retained CPU, 24 MiB staging, 8 MiB metadata and 48 MiB reserve. This also sums to 256 MiB. Smaller globe-only modes lower the actual allowance in the table; they do not fill every pool. Release high-detail GPU assets as zoom moves outward; retain only a bounded warm cache for returning home. Framebuffers/depth/compositing targets remain separate measured app costs.

Use bounded 256/512 px tile textures and mip chains; budget actual decoded texture bytes, not downloads. Share land-cover/night-light atlas pages across visible tiles. Limit cloud rendering to a single cheap shell and at most two dated texture sets during interpolation. No baseline volumetric clouds, cloud-shadow map, global cascades or individual satellite meshes. At the limb, cap overlapping transparent pixels and profile fill cost; triangle counts alone do not predict cloud/atmosphere expense. Dynamic resolution, coarser texture/terrain error and reduced update rates precede dropping coherent coverage under heat.

Three.js reuses the same cube addresses, geodetic/ECEF Double math (JavaScript Number), tile-relative assets, geometric errors, texture pyramids, licence metadata, ownership and transition timing. Adapters own GPU transforms, shader/depth composition and resource lifetime. Shared fixtures compare canonical anchors, camera path, tile selection, coverage and sun/moon/terminator alignment. Set browser memory/GPU tiers from measured capability; the A16 native targets do not automatically apply to every browser. Keep server-generated data/pyramids renderer-neutral so no parallel web-specific world export is required.

## 18. Revised phases: design now, richness later

**Mandatory now:** globe addressing and regional attachments; Double canonical coordinates and camera-relative rendering; curvature and vertical-datum fields; near/far depth/composition proof; global fallback coverage; layer licences/provenance; continuous camera navigation; bounded parent replacement and transition admission. These cannot be retrofitted after widespread flat Float assets and independent camera modes ship.

**Revised effort assumptions:** the following replaces, rather than adds to, §10's 21–36 day regional estimate. Engineer-days are rough focused-work estimates, not promised agent/calendar throughput. No builds were performed to establish feasibility. Production global dataset services and high-detail coverage costs are excluded.

| Phase | Required scope | Assumed effort | Review gate |
|---|---|---:|---|
| G0 — contract | P1 binding, cube/metric addressing, datums, layers/licences, depth/pass budgets and continuous camera contract | 2–3 days | No regional-only origin or ambiguous height/frame remains in the new contract |
| G1 — precision and renderer proof | Camera-relative native/web transforms, rebasing, Earth curvature and near/far composition prototype | 4–7 days | Street precision, planet-depth occlusion and pass costs proven before exporter commitment |
| G2 — exporter and tile store | Existing authored detail LODs, global roots/regional attachments, bounded native importer, shared caches/ownership | 8–13 days | Coarse roots work offline; 200 m package detail attaches without ID changes or duplicate coverage |
| G3 — continuous native ladder | Street-to-100,000 km navigation, basic static Earth, SSE/horizon selection, parent morph/fades and bounded residency | 7–12 days | Whole ladder usable; poles/dateline/return-home work; missing detail is honest and no visible popping accepted |
| G4 — web parity and sustained operation | Same ladder/data in three.js, walking/aerial/orbit prefetch, launch/heat/memory policy | 6–10 days | Comparable coverage/anchors; no eager planet load; mode budgets include both passes |
| G5 — device/art validation | Dense streets, globe flights, interrupted network, long warm runs, precision and transition captures | 3–5 days | Review actual A16 GPU/all-pass counts, memory plateau and style-B continuity |
| **Core ladder total** | Basic continuous street-to-space product, with available local detail and static global fallback | **30–50 engineer-days** | Supersedes original regional-only total |

Later independent richness phases (**assumptions**, not part of core total): global DEM/WorldCover pyramids and datum reconciliation **6–10 days**; NOAA GOES reprojection/cache/quality and dated cloud playback **5–9 days**; expanded Black Marble surface layer plus orbital LiveSky observer/illumination integration **3–6 days**; trusted local ground/collision and street-to-DEM reconciliation **6–12 days**. These estimates assume permitted accessible data and no renderer rewrite. Global non-GOES cloud providers require separate rights/availability research before estimation. Expanded stars, volumetric clouds and detailed orbital vehicles are optional later work.

R/Claude review should settle three remaining gates before implementation: continuous RealityView/far-pass composition feasibility; the exact GPU/device acceptance target; and the actual merged P1/NJ metadata/datum mapping (**unverified — checkout behind main**). The design commits to globe geometry and precision now while permitting progressively richer data coverage later.
