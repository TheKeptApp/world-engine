# Far water + ring batching — default-off prototype

## Used / Mock / Deviation

Used: `docs/execution/world-edge-options.md` §§Recommendation, measured scene-budget basis and iPhone conditions; `web/bakeoff/evidence/context-buildings/README.md` §§General rule and Results; `docs/execution/shadow-and-draw-floor.md` §§Draw reduction and exact limit, Evidence and validation (A10 `6e76ca7`); `docs/execution/budget-tiers.md` §§Current decision evidence and Measurement gaps. At the initial `6e76ca7` baseline, `docs/INDEX.md` was absent and routing resolved to `docs/tracking/INDEX.md`. During this work A3 landed `docs/INDEX.md`, `docs/tracking/DECISIONS.md` and `REFERENCE-MAP.md`; their current entry point, Water feature row and owner comparison/ship decisions were then read. `docs/proposals/INDEX.md` supplies approval status. `docs/tracking/MOCKS.md` M-CAL-SLOANS / M-CAL-LAKEVIEW supplies calibration authority.

Mock: `docs/proposals/style-b-calibration-v2/frames/06-sloans.png` and `01-lakeview.png`, opened from the owner's checkout. Also inspected: `lake-winter-v1/01-water-that-reads.png`, `02-big-lake-vs-city-lake.png`, `06-phone-readability-targets.png`; `water-surfaces-v1/images/sloan-summer.png` and `michigan-summer.png` (mechanics only, per its STATUS). Read `docs/execution/water.md` §§Research/approvals, Current drawing paths, Cost and matched frames, plus both pack STATUS files. These own appearance/mechanics within their approval scopes, not the 600 m geometry/camera. Winter/ice, rain street and other shoreline-type work is outside this geometry-batching experiment; no values are taken from those references. A10's exact matched shipping frames and fresh repeats own the technical comparison. No pending packs used.

Deviation: R explicitly permits non-pixel-exact far geometry at >=400 m, judged by A3 paired review and budgets. Ring-only Sloan still requires exact pixels. The first fixed group-order two-draw attempt failed (three colour bytes, max 68/255, one pixel); it is retained at `/private/tmp/a5-far-water-sloan-v1/`. The candidate now retains original source depth order inside the merged opaque ring and updates that order when the camera changes. This is an opt-in experiment, not device qualification or a look score. A10's stack is a dependency, not a silently substituted `sceneBudget=1` baseline. Its previous stop is superseded only for this requested water/ring experiment; existing shadow and triangle failures are not waived.

## General representation and native parity

`far-water.js` pools the currently selected indexed water triangles by identical material, attribute layout and receiver/render state. It rebakes each source transform into world coordinates, retaining every selected triangle and every attribute. There is no shoreline simplification, invented surface, palette or shader change. The same material object is reused. Noncasting water adds no shadows. The option activates at camera height 400 m above the current flat export datum and restores original submissions below it. Terrain-relative AGL must be supplied through the height callback for non-flat packages; the current test packages use the existing flat-datum contract.

The spatial selector retains responsibility for feature selection. Pool buffers are reused while that selection is unchanged, rebuilt when it changes, and retired buffers disposed. Extra CPU work, upload churn during movement and memory remain explicit prototype costs; static draw reduction is not a frame-time speed claim.

Native already implements the same representation: `Sources/WorldEngine/World.swift`, `buildChunks()`, appends every `chunk.waterMesh` into one `Chunk water` entity with `resources.waterMaterial` and `casts:false`. `World+Context.swift`, `attachContext()`, builds one ring-water entity with that material; its sector meshes already combine opaque land/building geometry. Therefore no second water shader, native visual fork or native code change is needed for this representation. Native sectors and web's whole-ring pool have different culling granularities; this experiment does not certify equal native draw counts. Current iPhone GPU/time/memory and paired visual qualification remain unmeasured. Both platforms retain their own existing water material; this does not claim previously missing cross-platform colour parity is fixed.

`contextMerge=2` combines the four land/road groups and mapped mass group into one opaque mesh, in their original camera-depth/source-ID order. Original source geometry is retained in CPU memory to rebuild this order after camera changes; its arrays are not a complete GPU-memory measurement. The existing `geometryBytes` field counts source arrays, not pooled peak residency. Water remains separate: two materials require two draws. Original triangles, colours, normals and source-edge fade remain. Existing source coverage, building selection and 40k ring triangle cap stay unchanged; A4's exporter is untouched. `contextMerge=1` remains the prior land-only experiment.

## Entry and measurement contract

Explicit preview flags: `contextRing=1&spatialCells=1&spatialMergeRuns=1&shadowCells=1&farWater=1&contextMerge=2`. All remain off by default. Shipping modules and shaders are unchanged. Context meshes are excluded from the spatial selector and counted separately.

`tools/qualify-far-water.mjs` derives its served fixture from the existing shipping scoreboard page, installs A10's exact stack and then the ring/water options. The five modes are before, independent page repeat, ring-only, water-only, and combined after. Shader time and delta are pinned to zero after each NodeFrame update; each mode uses a fresh browser and at least 60 settled frame samples. A first Lakeview run had 1,389 differing colour bytes (463 pixels) confined to the attribution strip x8–454/y8–24; the world outside that strip was exact. That run is retained, rejected as a full-image control, and not used for acceptance. No strip is masked in the rerun. Screenshots are retained before comparisons; geometry/material/data/camera identities and per-pass counters are recorded. This is a shipping-material fixture in the bakeoff harness, not a change to the shipping default route. A3 receives before/after pairs and performs its own blind scoring; no scores here.

## Results

Final accepted fixed-clock V4 captures after clean rebase onto `e112565`, including A10 finite-wind `b66b146`:

| 600 m contract | Main triangles unchanged | Before → after draws | Water draws | Ring draws | Combined colour bytes different / max byte | Shadows triangles / draws unchanged |
|---|---:|---:|---:|---:|---:|---:|
| Sloan, A10 shipping pose | 353,611 | 112 → 82 | 27 → 1 | 6 → 2 | 4 / 1 | 0 / 0 |
| Lakeview, A10 shipping pose | 526,478 | 60 → 56 | 0 → 0 | 6 → 2 | 0 / 0 | 0 / 0 |
| Wilmette, corrected inspection pose | 485,157 | 66 → 62 | 0 → 0 | 6 → 2 | 0 / 0 | 0 / 0 |

All full-image repeat controls and all ring-only comparisons are exact. Sloan's four differing bytes affect four pixels; the measured mean is 0.0000017611 byte units across the full RGBA image. Lakeview and Wilmette have no selected detailed water in these west/east-facing views; their zero-change result is not an additional water-surface witness. They do exercise the ring.

Sloan accounting is 36 opaque + 1 water + 42 instances + 1 sky/composite + 2 ring = **82**. It fits these static floor counters; this is not minimum-device qualification. Lakeview remains 126,479 triangles above the strict floor allowance and 26,478 above standard. Wilmette remains 85,158 above the strict floor allowance, within standard. No triangle debt is hidden by the draw improvement. A4 owns the separate far-building/chunk remedy.

[Phone-width pairs](review.html), [machine summary](summary.json), and per-area `qualification.json` contain PNG/source hashes, cameras and per-pass ledgers. Native source is unchanged because its water is already pooled; no new native capture or device speed claim.

Visible limitations against the listed targets remain: the shipping fixture's lake is much flatter/less blue than the approved broad sky-response references; the opaque context ring has a clear colour/atmosphere seam and dark mass sides. Both BEFORE and AFTER retain these issues. They are not newly solved by batching and are not a score. The prototype remains default off for A3 paired review.


## Hold-outs, validation and merge

35 focused tests pass under the shared heavy lock, load 6.83. Real preview OFF makes zero context requests; ON and combined stack each load exactly one context source. The combined preview installs the water option. Default remains unchanged.

Sloan150: 243,078 main triangles; 74→70 draws from ring only. Water stays inactive below 400 m. All comparisons exact; shadows remain 43,729 triangles /38 draws. West Highland600: 318,226 triangles, 58→57 draws; Greenville600: 228,607 triangles, 59→56 draws. Both have missing context sources explicitly recorded as zero-cost no-ops; selected detailed water is pooled without inventing context. Every repeat, ring, water and combined image is exact in those hold-outs. All V4 shadow costs are unchanged within each pair. A10's newer selector—not this change—reduced the older dependency's shadow counts; do not attribute that reduction to water/ring.

V1's fixed-order ring was rejected; V2's Lakeview attribution-strip control was rejected. V3 three-area controls passed, but an old-base 150 m follow-up overlapped the rebase and its source-hash guard rejected it. No mixed-source run is accepted. V4 reran all three requested views, Sloan150 and both additional hold-outs with stable source hashes and exact controls. Earlier raw evidence remains under `/private/tmp/a5-far-water-*-v1/v2/v3` paths named in the run history, not presented as V4 acceptance.

Main advanced during work. The prototype rebased cleanly; all affected tests, the actual preview route and all six comparisons were rerun. A3 has 600 m before/after frames plus repeat and isolated variants; [review.html](review.html) uses 390 CSS-pixel panels with responsive stacking. No scores, no new native capture, no public deployment or phone installation.

The post-merge default-off scoreboard is pending until the implementation merge completes. It exercises shipping defaults, not this opt-in stack.
