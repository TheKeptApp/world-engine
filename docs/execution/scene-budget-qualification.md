# Scene-budget variant qualification — 2026-10-08

## Decision

**FAIL: do not adopt afc72bd.** It reduces submitted work, but Lakeview 150 m is not pixel-identical and the moving pan also changes a pixel. Main-draw savings alone do not establish safe equivalence or sustained performance. This commit adds qualification tooling and evidence only: shipping `main.js`, the afc72bd variant, shaders, native sources, v3 and allocator are unchanged. Flag stays OFF by default. No scoring.

The [original variant](scene-budget-variant.md) passed three stationary Sloan views; that evidence is preserved, not extrapolated to other cameras. The [machine-readable report](../../web/bakeoff/evidence/scene-budget-qualification/manifest.json) retains every measured motion frame, sampled image hash, pose, actual main submission counter, selection/pooling timing, allocation observation and every differing 32-pixel region. Max/mean are decoded **RGBA byte units (0–255)**; normalized values divide by 255. Gate is **exact zero**, not the separate foliage/control-noise gate. No region, alpha channel, small component or differing byte was excluded.

## Hold-outs

Lakeview uses the existing frozen eye 41.945182,-87.66432 with the shared 40/150/600 m ladder, heading 270°, pitch down 45°, FOV 50°, 1005×565, October 15 replay fixture. Local-frame origin is read from its existing flat-ground export so the analytic direction is exact. Wilmette uses the already recorded `northshore-postcard` eye/heading and September 15 fixture from `a3-capture-contract.json`; no export or camera tuning. Its existing 25-chunk export was copied unchanged from the retained A7 baseline into the ignored capture mount. World manifest SHA-256: `fb5c6f99f65dcedac52e8526aa76a5329b8b4470c35d53ba604e3cf5e2fce3ce`. The 600 m Wilmette view is mostly sky/export boundary; its result does **not** qualify missing far-context geometry.

| Area / height | Default main triangles / draws | Variant main triangles / draws | Max / mean absolute byte difference | Differing bytes / pixels; every region |
|---|---:|---:|---:|---|
| Lakeview 40 m | 320,733 / 112 | 47,686 / 43 | 0 / 0 | 0 / 0; none |
| Lakeview 150 m | 323,901 / 131 | 150,628 / 64 | **42 / 0.00009598027561308502** | **6 / 2; x=283,285, y=546**, bottom-left building/detail edge; 32px region (256,544,32,21) |
| Lakeview 600 m | 209,528 / 101 | 72,065 / 32 | 0 / 0 | 0 / 0; none |
| Wilmette 40 m | 616,918 / 278 | 328,418 / 96 | 0 / 0 | 0 / 0; none |
| Wilmette 150 m | 599,588 / 252 | 250,788 / 71 | 0 / 0 | 0 / 0; none |
| Wilmette 600 m | 43,549 / 12 | 1,986 / 2 | 0 / 0 | 0 / 0; none |

At the two Lakeview pixels the default RGBA is (142,114,100,255), variant (170,156,139,255). Independent default fresh/repeat 150 m captures are both encoded-PNG and decoded-RGBA identical to the initial default. Thus baseline repeat noise does not explain this failure. The exact underlying primitive/order cause is **unproved**; changed opaque/coplanar submission ordering after pooling is a hypothesis, not a demonstrated diagnosis. No shader or threshold fix was made to conceal it.

Local static PNGs and metadata:

- `/private/tmp/a10-qual-lakeview-{off,on}/lakeview-{40,150,600}-foliage-off-crown-off[-scene-budget].png`
- `/private/tmp/a10-qual-wilmette-{off,on}/wilmette-{40,150,600}-foliage-off-crown-off[-scene-budget].png`
- `/private/tmp/a10-qual-lakeview150-control/`: independent default fresh/repeat; originals retained.

The manifest expands these patterns to exact existing paths and SHA-256s. Each directory has `web-capture.json`. Static frames compare full screenshots including credits; motion comparisons compare the full rendered canvas and credits remain visible on the capture page. Both compare all their RGBA bytes. Fixed exposure is the existing 1.2745606273192622 gain; original fixture, projection and camera metadata match within every pair.

## Moving camera protocol and limits

`scripts/qualify-scene-budget.sh` owns heavy admission and the 900-second watchdog; no nested lock. The capture-only HTML override loads `scene-budget-qualification-entry.js`; **no normal page imports it**. The server instruments timing anchors in a served copy of afc72bd `scene-budget.js`; it refuses non-unique/missing anchors and leaves the on-disk variant untouched. The original frame callback is advanced once per planned frame, with fixed elapsed time, fixed exposure, completed GL submission (`finish`) and no skipped camera steps. Existing LOD, facade and DEM camera-refresh callbacks still run. Default/variant use independent fresh browser contexts and matching poses/projections/dates.

Paths are general local-coordinate movement around the saved Sloan ladder eye (39.7511195,-105.0389): a 200 m east-west translation at 150 m, constant heading 270° / pitch down 45°; descent 600→40 m at that eye, same orientation/FOV. This is a translational pan, not an orbit. Each complete diagnostic has **10 seconds of logical camera time at fixed 2 Hz**, 21 completed frames including endpoints; sample indices **0,2,4,5,7,9,11,13,15,16,18,20** (12 distinct samples/path). The unchanged `updateCameraNear` callback runs on every frame: pan near plane 37.5 m, descent 150→10 m (quarter of altitude). Default/variant recorded cameras match exactly, including this dynamic near plane; no new projection rule was introduced.

**Interactive-rate qualification failed.** The initially planned 30 Hz variant pan was stopped when multi-second completed frames made the bounded full sequence infeasible. A corrected non-retaining probe retry still degraded to ~4.57 seconds at frame 94 and was stopped after 95 completed frames / 4 samples, preserving `frames.ndjson` and `qualification.json` in `/private/tmp/a10-qual-pan-on-30-final/`. Exact interruption error: `page.evaluate: Target page, context or browser has been closed`; wrapper exit 143. It is not a completed 30 Hz result. The earlier default 30 Hz run completed 301 logical frames in 21.676 s, not real time. Earlier strong-reference probe runs are superseded for memory analysis; their data/files remain preserved. Completing sparse 2 Hz comparisons does not certify 30/60 Hz, unsampled pixels, rotation, longer traversal or a phone.

Final memory probe uses WeakMap/WeakRef; it cannot keep discarded buffer handles alive. It records logical WebGL buffer allocations, per-completed-frame observed peaks, upload bytes and explicit deletion/GC-handle release. CDP heap measurements force GC before/after the path. **GPU driver residency, process RSS and actual GPU execution time are unmeasured**; `frameMs` includes CPU work, submission and synchronous GPU completion, not a GPU timer. Texture/render-target dimensions stay fixed; constant targets do not eliminate buffer/CPU-copy churn. Initial warmup is three completed frames; timing distributions cover every path frame, including index 0's unchanged-camera fast path.

### Completed motion evidence

Both paths have **one failing sample**: pan index 20 / 10 s, pixel (283,275), max 14, mean 0.00001629023026460617 byte, 3 differing bytes; descent index 5 / 2.5 s  / 460 m, pixel (866,497), max 46, mean 0.00005327345573019856 byte, 3 differing bytes. Regions are respectively (256,256,32,32) and (864,480,32,32), at building/ground detail edges. Exact primitive cause remains unproved. All other 11 samples/path are exactly identical, with no differing region. Pan default RGBA (192,184,170,255)→variant(204,198,181,255); descent (157,151,134,255)→(203,192,168,255).

| Path | Selection CPU p50/p95/max ms | Pooling CPU p50/p95/max ms | Total incl. maintenance ms | Completed-frame p50/p95/max ms | Actual wall seconds |
|---|---:|---:|---:|---:|---:|
| pan variant | 11.1/12.2/12.5 | 21.8/25.6/27.0 | 34.4/38.6/39.8 | 526.4/615.0/623.7 | 13.171 |
| pan default | n/a (probe 0) | n/a (probe 0) | n/a | 97.3/159.5/162.3 | 10.243 |
| descent variant | 12.7/19.1/24.7 | 24.0/28.8/31.2 | 38.6/48.7/49.8 | 4752.0/5680.5/5857.5 | 97.935 |
| descent default | n/a (probe 0) | n/a (probe 0) | n/a | 430.6/858.1/1098.9 | 11.101 |

`Selection` covers frustum/instance tests and bucket membership; `pooling` covers geometry/instance array creation and mesh construction; `maintenance` covers scene traversal, signatures and removal/disposal of previous pools. They exclude the rest of rendering, GPU wait and readback. No default selection/pooling implementation is timed; zeros mean the opt-in probes did not run, not zero total default CPU cost. Variant total CPU alone is >33.3 ms at the median in both paths; moving-frame uploads/resource churn remain outside that phase total. No frames skipped to hide a slow sample.

Pan default exceeds 100 on **all indices 0–20** (232–277 draws); variant **none** (71–88 draws). Descent default exceeds 100 on **all indices 0–20** (182–341 draws); variant **indices 0–12**, times 0–6 s / 600–264 m, with draws **112,113,113,111,111,111,116,126,114,119,120,109,110**. Variant remaining indices 13–20 have 97,94,86,75,70,58,60,45 draws. Variant main triangles range 132,648–266,066 on pan and 49,844–364,817 on descent (every diagnostic frame under 400k); default ranges 771,713–843,019 and 624,433–866,170. All per-frame categories/counters, including non-samples, are in the manifest.

| Path/mode | GL logical buffer MiB start→end (peak) | Handles start→end after GC | Upload MiB during path | JS used heap MiB start→after GC | CPU backing-storage MiB start→after GC |
|---|---:|---:|---:|---:|---:|
| pan/default | 68.89→73.49 (73.49) | 2268→3281 | 40.16 | 25.33→27.80 | 150.60→158.51 |
| pan/variant | 34.25→52.31 (52.62) | 982→7583 | 814.44 | 47.64→68.53 | 180.66→990.26 |
| descent/default | 52.00→71.52 (71.52) | 2327→3144 | 39.88 | 25.56→27.14 | 150.69→151.02 |
| descent/variant | 41.37→26.25 (58.14) | 918→7644 | 825.76 | 47.55→69.79 | 193.23→1013.93 |

Variant pan creates 14,903 / deletes 8,302 additional GL buffers; descent creates 16,916 / deletes 10,190. Logical handle and CPU backing-store growth survives forced GC; the probe releases 0 handles by GC in these observations. This demonstrates retained resources over the measured paths, **not** a measured physical GPU memory leak rate or proof of indefinite growth. Descent end bytes fall as fewer features are visible, but peak and handle/backing-storage growth remain. Periodic longer-loop residency measurements are still needed.

Final frames: `/private/tmp/a10-qual-{pan,descent}-{off,on}-weak/{pan,descent}-{off,on}-{000,002,004,005,007,009,011,013,015,016,018,020}.png`; each directory retains all 21 per-frame NDJSON records and full qualification metadata. The manifest gives every exact sampled filename/hash.

## Last 12 draws at 600 m

The current unchanged variant's static Sloan 600 m main submission is 320,036 triangles/112 draws: opaque 70, facade 2, water 27, foliage 12, sky 1. The existing material/model/layout/transparent-order distinctions cannot be discarded to force 100. A general candidate is **pool compatible visible static geometry across spatial bins**, after fine visibility selection, retaining exact material, model matrix, layout, render order, category and transparent source identity. It removes only the 800 m cell component in a **served-copy diagnostic**, never a shipping or variant file edit. No distance LOD: it changes silhouettes/coverage and carries a pixel risk.

Measured candidate: **320,036 triangles /109 draws**, encoded-PNG and decoded-RGBA exactly identical to the matched default 600 m frame (max 0, mean 0, differing regions: none). It removes **only 3 draws**, not the requested 12. Thus **no proven general pixel-preserving rule in the tested current compatibility model gets 600 m to ≤100**. Remaining independent material/model/order keys need a different batching architecture and new equivalence proof; do not claim shared shader state or distance LOD is automatically safe. Candidate remains diagnostic-only and unadopted. Frame: `/private/tmp/a10-qual-static600-global/descent-on-000.png`; source-copy hash and counters retained in manifest.

Even a successful single 600 m counterfactual would need hold-out and motion equivalence, stable ordering, buffer reuse and bounded costs before implementation/adoption. It would not repair the existing Lakeview/pan failures by assertion.

## What 5A must reproduce in RealityKit

1. Reproduce actual main-only submission budgets at the matched Sloan/Lakeview/Wilmette poses and along both paths, with native scene/context/IBL complete and stable completed Metal frames. Keep the native/default paired camera/date/exposure contract exact; distinguish missing context/export coverage from culling. Check **<400k main, ≤150k shadow, ≤100 main draws** separately. `World.swift:904` `estimateView` is CPU bounds/accounting, not proof of actual GPU calls; measure native completed submissions and each category, including sky/context and shadows.
2. Verify feature/instance bounds include the complete geometry and approved motion/displacement margin; preserve every transform, tint, palette identity, vertex layout, shadow receiver/caster and transparent/coplanar ordering. Main frustum rejection must not remove a caster whose shadow enters the view. Native `World.swift:828–896` already uses widened view plus shadow reach and 3D prop distance; preserve that policy rather than transplanting web whole-batch visibility. Buildings already have adaptive 800 m/40k tile splitting and native building LOD policies; test interaction instead of importing a second conflicting LOD path.
3. Pool only native-compatible material/geometry/layout/state, retain deterministic ordering, update reused instance/index resources without rebuilding/uploading all copies per pose, and measure selection+pooling CPU p50/p95/max, completed frame costs, uploads, resident/mesh/texture/target peaks and retained buffers across repeated pan/descent loops. Test every frame over 100 draws and transition/popping; the web motion memory growth is an explicit warning. Run on R's 14 Pro/iOS 26.4.2 and the intended weaker floor device separately, with thermal state and sustained frame rate; desktop results certify neither.
4. Native exact paired pixel/repeat tests and hold-outs must stand on native output. WebGL counters, Three.js material UUID/layout keys, geometry clones/disposal, 1001-capacity workaround, backend draw interception, uniform-buffer/cache lifetimes, Chrome/CDP/WeakRef measurements and raw GL readback **do not transfer directly**. RealityKit owns its passes, batching and buffers. The web DEM patch strategy, near-plane behavior and missing flat-export context also do not define native geometry/budgets. Shader/allocator/v3 integration remains out of scope.

## Reproduction, source identity and tests

Use each wrapper independently; it acquires/releases admission only for the run. All recorded loads are below 25 (static 4.71–7.72; final 2 Hz motion 5.39–6.16). Disk guard retained >8 GiB (53 GiB observed during qualification). Images stay local and out of git. Example full commands:

```sh
scripts/capture-web.sh --block lakeview-ladder --output NEW_LAKEVIEW_DEFAULT
scripts/capture-web.sh --block lakeview-ladder --sceneBudget --output NEW_LAKEVIEW_VARIANT
scripts/capture-web.sh --block wilmette --existingExports --output NEW_WILMETTE_DEFAULT
scripts/capture-web.sh --block wilmette --existingExports --sceneBudget --output NEW_WILMETTE_VARIANT
scripts/qualify-scene-budget.sh --path pan --mode off --fps 2 --output NEW_PAN_DEFAULT
scripts/qualify-scene-budget.sh --path pan --mode on --fps 2 --output NEW_PAN_VARIANT
scripts/qualify-scene-budget.sh --path descent --mode off --fps 2 --output NEW_DESCENT_DEFAULT
scripts/qualify-scene-budget.sh --path descent --mode on --fps 2 --output NEW_DESCENT_VARIANT
scripts/qualify-scene-budget.sh --path descent --mode on --static600 --globalStatic --output NEW_STATIC_DIAGNOSTIC
```

The report worker is read-only over finished directories and retains all failing comparisons. Its invocation and source hashes are in the manifest. It deliberately reports FAIL without changing a pixel gate or rewriting an experiment. afc72bd shipping main SHA-256 remains `55b0834efc482a33a320e008c3c58d8a533dd9bdbc9b1b723fdc19a7e25e76d5`; full variant/source hashes are retained and checked against that commit. No shipping/native/variant file changes; only capture workers/server/contract adapter, dedicated probes/tests, this document and evidence added/edited. No INTEGRATION/STATE/handoffs edits.

Thirty focused tests pass under heavy admission (load 7.39): camera/export-origin contract, override MIME/idempotent cleanup, strict timing anchors, all-byte differences, non-retaining buffer accounting, all-frame evidence integrity and existing scene-budget/main-shadow/default-routing regressions. Qualification itself remains **FAIL**, independently of tooling tests. Main advanced from afc72bd to 243a41f during the work with docs-only commits; rebase completed without conflicts and the same 30 focused checks passed again before push (load 9.14).

## Ledger text for A3

A10 afc72bd qualification **FAIL / do not adopt**, default OFF unchanged. Lakeview 150 m changes 2 pixels (max 42 byte, mean 0.00009598027561308502); independent default repeats exact. Wilmette existing-export three heights exact, but 600 m far context absent. Moving pan and descent each have a sampled pixel failure; sparse 2 Hz diagnostics and failed 30 Hz attempt do not establish interactive performance. Buffer/upload/CPU backing-store growth requires a resource-reuse redesign and native measurement; 600 m current 112 draws still over floor; global-static counterfactual saves only 3 (109 draws), exact at the one tested pose. Detailed per-frame counters, pixel regions, source hashes and 5A checklist in this doc/manifest. No scoring, v3/allocator integration or renderer adoption; ledger ownership stays A3.

Used: scene-budget-variant.md §General implementation rules; budget-tiers.md §Current budget contracts; R's qualification request. Mock: retained default Lakeview/Wilmette and Sloan motion frames (manifest). Deviation: exact pixel failures and bounded 2 Hz diagnostics after 30 Hz runtime failure; no native certification.
