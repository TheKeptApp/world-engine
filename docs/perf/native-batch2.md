# Native Batch 2 — phone logs, exposure, shadow cells, streaming near view, Lakeview memory (5A, 9 Oct 2026)

No look, shader or palette change. Simulator captures through `scripts/capture-native.sh` (pinned exposure, SCENEREADY); phone = R's iPhone 14 Pro. Frames and raw logs stay local (`scratchpad/b2`).

## 0. Phone events, last 24 h (crash / jetsam / install logs pulled from the device)

| Time | Type | App build | Mine? | What R would have seen |
|---|---|---|---|---|
| 8 Oct 22:13 | Jetsam report: WorldLab suspended, 591 MB resident, **not killed** | unknown | no (5A stopped then) | nothing |
| 9 Oct 16:28 | **Crash** SIGTRAP in RealityKit `ARView.renderCallbacks` setter during a RealityView update | 5A Batch 1 pan test (mid-session camera-route change) | yes | the app closing |
| 9 Oct 18:07 | Jetsam report: WorldLab frontmost, 888 MB resident, largest process, **not killed** | 5A Batch 1 pose runs | yes | nothing |
| 9 Oct ~19:20 → | **Install error**: "Unable to Install 'WorldLab' … No space left on device" | Batch 2 builds | yes | an iOS "Unable to Install" alert — most likely the "fail" message |

No memory kill of WorldLab. The phone is full; 0.71 GB of it is 16 streaming-cache files left in WorldLab's `tmp/WorldEngineStream/` by my Batch 1 test runs (the cache was removed only in `deinit`, which a killed run never reaches). Fixed: the streamer now clears its own earlier caches at start. **R: delete the WorldLab app on the iPhone (press and hold its icon → Remove App → Delete App); this frees the space.** Until then nothing can be installed, so Batch 2's phone pan was not run.

## 1. Exposure (report only)

Live app (auto exposure on, same algorithm as the phone; Simulator, 45 s settle, `post.appliedLinearGain`): Sloan 40 m **1.112**, 150 m **1.170**, 600 m **0.648**; Wilmette 600 m **0.700**; Lakeview: no gain logged (pending). Scoring captures pin **1.0**: at 40/150 m they are **10–15 % (0.15–0.23 EV) darker** than the live app; at 600 m **35–43 % brighter**. Web's ~1.27 is an ACES-fit gain on a different tone curve, not comparable 1:1. **Recommendation:** one documented policy for scoring — let auto exposure converge, then freeze that gain for the capture (deterministic, matches what the user sees); record the gain in capture metadata. No default changed.

## 2. Shadow cells (`-diag shadowCells`, default off)

Rule (general, any area): a caster draws into the shadow map only if its shadow can reach the region RealityKit shadows: its footprint swept away from the sun by its shadow length comes within the shadow range + 1.5 × the camera's height above ground + the 8 m re-bucket distance (measured: RealityKit's automatic projection shadows ground 150–210 m away from a 150 m-high camera with a 120 m range). Trees: each instanced LOD batch has a non-casting twin for out-of-reach instances (sway bound 0.03 m included). Buildings: cells/tiles toggle casting by reach. Raised chunk geometry: 200 m tiles (were 800 m) so casting follows reach. Reach re-evaluated each LOD re-bucket. Shadow counts analytic (`World.shadowEstimate`).

| View | Shadow tris/draws off → on | Main tris/draws off → on | Image off vs on |
|---|---|---|---|
| Sloan 40 m | 224,435/58 → **140,806/52** | 312,880/53 → 303,824/61 | max 1/255, 6 bytes |
| Sloan 150 m | 184,893/46 → **138,487/43** | 333,744/50 → 329,708/63 | max 1/255, 287 bytes |
| Sloan 600 m | 0 → 0 | 228,013/43 → 220,351/55 | max 1/255, 160 bytes |
| Lakeview 40 m | 244,767/63 → **149,267/57** | 295,759/56 → 230,189/60 | max 3/255, 7 bytes |
| Lakeview 150 m | 214,423/44 → **126,499/39** | 271,763/48 → 260,903/57 | identical |
| Lakeview 600 m | 0 → 0 | 194,160/35 → 188,584/40 | identical |
| Wilmette 600 m | 65,802/8 → 51,507/7 | 235,885/36 → 229,919/47 | **max 38/255, 13 bytes** |

All four 40/150 m views now under 150k (Lakeview 40 m by 733). Near-lossless, not exact: Wilmette 600 m loses 13 bytes of shadow (RealityKit's aerial shadow extent exceeds the rule there); Lakeview 40 m 7 bytes. Main draws rise up to +13 (≤63, under 100) from twins and 200 m raised tiles; main triangles fall (smaller tiles cull better). An earlier rule without the height term lost visible shadows at 150 m (max 89/255) and was replaced. Frames for A3: `scratchpad/b2/off-*` vs `scratchpad/b2/r4/shadowCells-*`.

## 3. Streaming near view (`-diag streamCells`)

Prefetch: cells are measured from where the camera will be in 1.5 s (smoothed velocity) as well as from where it is; captures wait until streaming is idle. **Gate passed: streaming on vs off at 40 m, byte-identical at Sloan's and Lakeview (max 0/255), with streaming active (Sloan geometry 163 → 128 MB).** Upload outlier: finishing now spans three frames (GPU copy / parts / attach, each ≤0.29 ms in Batch 1's timings); the phone pan to confirm is **pending** (phone storage). Capture tooling: `-diag` now passes as a launch argument in batched captures (`Tools/lookloop/batch.py`, like `-lookexp`), so load-time diagnostics apply.

**Proposal (not applied):** turn streaming on by default once the phone pan confirms no upload frame over 0.5 ms.

## 4. Lakeview memory

Phone, Lakeview 40 m ladder pose, near-level streaming (Batch 1 streamer; this batch's build could not install), MiB:

| Category | Streaming off | Streaming on |
|---|---:|---:|
| Footprint | **603.7** | **489.4** (−19 % vs floor) |
| GPU allocations | 488.2 | 377.1 |
| — geometry | 355.4 (near 126.9) | 228.6 (near 0 resident at rest) |
| — RealityKit/other GPU | 132.8 | 148.6 (incl. slot pool) |
| Other CPU | 115.0 | 111.8 |

Lakeview 600 m: 600.8 → 485.6. Sloan 40 m: 411.2 → 380.3. Mid-level streaming not needed for the 10 % target.

## Recommendation for Batch 3
Once the enlarged package exists and the phone has space: roam the full extent with shadow cells and near-level streaming on (after one confirming phone pan), streaming mid as well only if the larger package needs it.

Used: docs/perf/native-batch1.md; docs/execution/shadow-and-draw-floor.md, shadow-floor-candidate.md, spatial-order-and-shadow-diagnosis.md (finite-wind bound); docs/review/a4-streaming-review-2026-10-08.md §§3–4,9. Mock: none (no look change). Deviation: shadow cells near-lossless not exact (Wilmette 600 m 13 bytes); phone pan and upload-outlier confirmation pending (phone storage full); Lakeview exposure pending; shadow counts analytic.
