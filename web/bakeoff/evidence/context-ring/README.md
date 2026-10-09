# Default-off context-ring prototype

**600 m coverage gate PASS for the three requested views; no score or default change.** The first bounded band of [world-edge option (a)](../../../../docs/execution/world-edge-options.md) is reachable with `?contextRing=1&sceneBudget=1`. No native renderer/shared exporter code changed. Native `ContextRing.generate` supplies the mesh through a bakeoff-only adapter. See [phone-width OFF/ON/calibration comparisons](review.html), [frozen plan](../context-ring-PLAN.md), and the measurement manifests.

## Requested 600 m result

These are the retained bakeoff ladders, **not** the centre-based shipping scoreboard cameras. Corrected Wilmette reproduces the reported 53.55% baseline exactly. Cameras, projection, lighting, atmosphere, palette experiment OFF, foliage/crown OFF, fixture/date, geometry and source data are fixed within each pair.

| View | Blank OFF → ON | Added main triangles / draws | Total main triangles / draws | Total shadow triangles / draws | Floor | Standard |
|---|---:|---:|---:|---:|---|---|
| Sloan 600 m | 31.08% → **23.59%** | 20,859 / 5 | 340,895 / 117 | 0 / 0 | FAIL draws | PASS |
| Lakeview 600 m | 71.88% → **8.92%** | 17,580 / 5 | 89,645 / 37 | 0 / 0 | PASS | PASS |
| Wilmette 600 m | 53.55% → **7.82%** | 14,504 / 5 | 383,366 / 80 | 5,918 / 1 | PASS | PASS |

All added context fits the **40k / 8 maximum** envelope and adds **zero shadow triangles/draws**. Lakeview and Wilmette need less than the 20k planning lower bound; no geometry was added merely to fill a budget. Floor remains <400k main /150k shadow /100 draws; standard <=500k/180k/120. Sloan's pre-existing 112 draws already fail floor. Post is recorded separately (1 triangle /1 draw), not hidden inside context. Counters are actual WebGL2 backend submissions, not estimated native or iPhone costs.

[Main capture manifest](main-600/manifest.json) records all nine OFF/OFF-repeat/ON captures, hashes, counters, source sizes/hashes, camera resolution and structural sample counts. Fresh-process control repeats are pixel-identical. Existing non-context main and shadow submissions must remain identical; the summary checker fails otherwise.

## Hold-outs and lower-height controls

All six 40/150 m OFF→ON images are **pixel-identical**, not merely similar, and existing pass counters are unchanged. Context still costs five draws because the quadrant bounds intersect those frusta; finer selection is deferred. The blank metric and all tier budgets pass at these poses.

| View | Blank OFF = ON | ON main triangles / draws | Shadow triangles / draws |
|---|---:|---:|---:|
| Sloan 40 m | 2.99% | 70,703 / 50 | 69,639 / 62 |
| Sloan 150 m | 1.54% | 226,208 / 80 | 67,961 / 42 |
| Lakeview 40 m | 11.71% | 65,266 / 48 | 76,124 / 79 |
| Lakeview 150 m | 9.82% | 168,208 / 69 | 73,212 / 62 |
| Wilmette 40 m | 3.65% | 54,644 / 52 | 68,059 / 47 |
| Wilmette 150 m | 3.76% | 233,581 / 94 | 66,723 / 38 |
| West Highland frozen 350 m | 21.51% | 281,995 / 75 | 25,875 / 5 |

West Highland has **no context source**. Its OFF/OFF-repeat/ON images and counters are identical; ON explicitly reports `missing-context-source`, adds zero geometry and leaves coverage unresolved outside its source grid. Its held 350 m view already passes the structural threshold; this is not proof of a new 600 m coverage fix.

Greenville also lacks context and a bakeoff climate adapter. Its [fresh-process shipping-scoreboard attempt](greenville-missing/manifest.json) **failed pixel equality**; the failed manifest and OFF PNG are retained, cause unmeasured. The harness threw before saving the ON PNG/difference magnitude, a disclosed evidence limitation. A separate same-paused-frame regression tests only that the missing-data call leaves that scene untouched; it cannot qualify fresh-process visual parity or wider coverage. No new data or regional rendering assumptions were introduced to force that hold-out through.

## Implementation and values

- `entry.js` imports `context-ring-entry.js` only when `contextRing=1`. OFF makes no context request. Other experiments are rejected except sceneBudget; defaults remain untouched.
- `tools/export-context.swift` calls the unmodified native generator, consumes the manifest's context source only, retains buildings only as native shoreline land-side evidence, and disables **all** building meshes with negative transition width/infinite tall thresholds. No buildings beyond the 0.5 km band—or inside it—are exported; no invented skyline. Rail is excluded from this roads/land/water scope.
- Native aerial geometry rules: area simplification **6 m**, road **5 m**, minimum area **8,000 m²**, native water simplification **3 m**, outer fade **200 m**. One general prototype override retains mapped minor roads throughout available coverage rather than the native aerial 400 m minor-road reach. No location/camera-specific rule.
- `context-ring.js` clips every triangle against the exact source coverage minus the detailed core, including road ribbon width at the seam. It pools four land/road quadrants plus one water batch; all `castShadow=false`. `scene-budget.js` excludes those marked context batches from its own pools, preventing duplicate submission/accounting.
- Existing exported named palette slots provide land colours. Calibration-v2 `sharedLook.materials.groundBaseHex` and `roughness.masonry` provide ground/road response. Native edge fade tends to the existing seasonal backdrop slot. Existing world water material is reused; no new water shader/sky texture or native water edit. Existing single haze and grade remain unchanged. No sky-cloud-v1 or street-ground-v1 concepts used.
- This is a **bounded, eagerly loaded prototype band**, not the complete tile streaming/eviction system. The ring is loaded from a separate export before capture. Interactive roaming, progressive network arrival, distant DEM, iPhone upload timing and residency remain unqualified.

| Area | Uncompressed ring JSON bytes | Allocated geometry attribute/index bytes | Native skipped pieces |
|---|---:|---:|---:|
| Sloan | 3,905,575 | 5,381,622 | 0 |
| Lakeview | 2,955,709 | 4,535,640 | 0 |
| Wilmette | 2,520,190 | 3,742,032 | 3 |

Geometry bytes exclude transient JSON/arrays, driver padding, reused materials and baseline resources. They are allocation arithmetic, not process/GPU residency measurements. JSON contains all aerial cells; visible counts depend on camera/frustum. Raw OSM source files are verified against manifest bytes/SHA-256 before capture; no new fetch. Lakeview and Wilmette each use native partial-water relation assembly with zero dropped shoreline pieces. Wilmette has three native triangulation skips across generated LODs; retained as a limitation, not silently repaired. Water outside the displayed frusta is not visually qualified by these views.

## Measurement contract and limitations

The `81×45 = 3,645` structural ray grid uses the scoreboard's pixel centres and blank numerator (`boundary` + `generated-ground`). Props/instances are excluded, so it remains an upper-bound structural measure. Real mapped context geometry supplies additional nearest hits; **unknown ground is not relabelled**. Strict requested gate is `<35%`. `context-probe.mjs` works on original detailed geometry even when sceneBudget moves those source objects to a non-rendered layer; it includes only the separately drawn context meshes. An equal sample method is not a perceptual score.

Direct image inspection: the roads and mapped land continue beyond the previous rectangle; nearby house masses still end at that rectangle, the distant view is flat and sparse, and surface/material quality remains the baseline. **Do not promote this to a look-gate pass or an endless-world implementation.** No A3 scores requested or assigned. Approved appearance references opened: calibration-v2 `frames/06-sloans.png` and `01-lakeview.png`; they are different street cameras, not aerial geometry targets. Local review HTML presents 390 CSS pixel renders beside them without distorting image proportions.

## Final verification

- **13 focused tests passed**: exact core/source clipping and area conservation, missing-data no-op, default-off entry, separate sceneBudget treatment, and the existing sceneBudget suite.
- **30 bakeoff frames** (ten OFF/OFF-repeat/ON triplets) completed; all fresh control repeats exact. The summary verifies every non-context main/shadow bucket is unchanged. Six lower-height ON frames and West Highland ON are pixel-identical to OFF.
- [Greenville paused-frame check](greenville-missing-paused/manifest.json) passed: exact pixels, zero added geometry/draws. Its earlier fresh-process failure remains in the report and is not superseded as a visual-parity result.
- Normal preview smoke passed: OFF makes **zero** context requests; ON makes **one** request and installs the available ring. These tests used the normal scenes.json URLs rather than capture overrides.
- Heavy admission loads: primary comparisons **10.44**, hold-outs **7.60**, final no-op/preview/tests **9.21**, all below25. The wrappers released their own locks. Disk remained above8 GB. No phone run or deployment.
- [Summary](summary.json), [final input hashes](source-hashes.json). All numerical checks are technical observations; no scores assigned. Main advanced during preparation; the branch was rebased and native modules/exports rebuilt before the recorded batches.

## Reproduction

From the worktree root (at least 8 GB free), run each command separately; wrappers take the shared lock with the load ceiling below 25:

```sh
HEAVY_AGENT='A5 context' HEAVY_LOAD=25 scripts/heavy.sh 'context primary comparisons' bash web/bakeoff/tools/run-context.sh
HEAVY_AGENT='A5 context hold-outs' HEAVY_LOAD=25 scripts/heavy.sh 'context hold-outs' bash web/bakeoff/tools/run-context-holdouts.sh
node web/bakeoff/tools/summarize-context.mjs
```

Pinned web dependencies must be installed via `npm ci --prefix web`; existing approved pack JSON and held source data must exist. The exporter builder links worktree-local native module objects without editing those modules. PNGs and generated ring payloads are gitignored; manifests/hashes, source and reports are versioned. New reruns should use fresh output directories to preserve evidence. For regular bakeoff preview, `prepare-context.sh` produces the `generated/context/<area>.json` files named by the optional `context` URL in `scenes.json`; start the existing bakeoff server and append `?contextRing=1&sceneBudget=1`. Capture-only scene IDs use explicit per-scene data overrides. The URLs select datasets, never location-specific rendering rules.

Used: docs/execution/world-edge-options.md Recommendation and first test; native ContextRing/World+Context. Mock: style-b-calibration-v2/frames/06-sloans.png and 01-lakeview.png. Deviation: bounded no-building band; no scores, default change, dynamic streaming or iPhone qualification.
