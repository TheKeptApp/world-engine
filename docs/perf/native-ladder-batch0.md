# Native ladder measurement — 5A Batch 0 (9 Oct 2026)

Measure only; no renderer, look, shader or shadow-reach change. Commit `b95e060` (current main). One fresh worktree, `scripts/capture-native.sh --view VIEW --inspectionpose lat,lon,AGL,heading,pitch --date UTC`, each its own heavy admission (loads 6–9). Pose/date as the web ladder (`scripts/web_sloans_ladder.json`; Lakeview eye from `web_capture_blocks.mjs` lakeview-ladder; Wilmette northshore-postcard pose at its contract date). Pinned capture exposure (gain 1.0), SCENEREADY ≥3 completed stable frames, 1005×565, Simulator (LookLoop iPhone 17 Pro). Frames stay local (not committed): `/private/tmp/claude-501/-Users-robwoodbury-Desktop-world-engine/fbbed06e-5a68-4c8f-a839-c797a86daf66/scratchpad/b0/<view>/raw/`.

## 1. Baseline
`swift build --build-tests` OK; `scripts/test.sh` under `scripts/heavy.sh`: **421 tests / 106 suites pass** (533 s, load 6.05). Note: main's `scripts/test.sh` still runs without the Mac shader library, so `ViewDrawBudgetTests` returns early without measuring (5A branch `5a-no-silent-skips` fixes this; unmerged).

## 2. 600 m control noise — measured cause and result
Repeat pair `sloans-600` vs `sloans-600-repeat`: **max 1/255, mean 0.000074 byte units, 167 of 2,271,300 bytes differ** — meets the proposed control gate (max ≤2/255, mean ≤1e-3). Cause of A10's earlier 7/255 / mean 3.19: the shipping auto exposure eases its solved gain at 6 % per frame (`PostProcess.swift` exposureRate 0.06); at 600 m the frame's brightness differs most from the start state, so the snapshot landed at different points of convergence. The capture path now pins gain 1.0 (A10 pin-only, already on main: `SCENEREADY … exposure=pinned-1`); the residual few-byte difference is time-driven animation (water ripple/cloud drift use the scene clock). No code change needed in this batch.

## 3. Near plane at 40 m
Camera near 0.1 m / far 5000 m (`WorldView.swift:171`). Both 40 m frames (Sloan's, Lakeview) show no clipping; the nearest geometry is tens of metres away. Nothing to fix.

## 4. Submitted main pass per view (native counters, `VIEWSHOT`)
| View | Pose (lat,lon,AGL,heading,pitch) | UTC | Main triangles | Main draws | Draw split | PNG SHA-256 |
|---|---|---|---:|---:|---|---|
| sloans-40 | 39.7511195,-105.0389,40,270,45 | 2026-10-15T20:30:00Z | 312,880 | 53 | chunks=7 buildings=7 foliage=33 props=1 context=2 other=3 | `41bd4276f96ede35` |
| sloans-150 | 39.7511195,-105.0389,150,270,45 | 2026-10-15T20:30:00Z | 333,744 | 50 | chunks=8 buildings=18 foliage=18 props=1 context=3 other=2 | `45e95786f8bd2774` |
| sloans-600 | 39.7511195,-105.0389,600,270,45 | 2026-10-15T20:30:00Z | 228,013 | 43 | chunks=9 buildings=17 foliage=8 props=1 context=6 other=2 | `0937e4bfa3604b77` |
| sloans-600-repeat | 39.7511195,-105.0389,600,270,45 | 2026-10-15T20:30:00Z | 228,013 | 43 | chunks=9 buildings=17 foliage=8 props=1 context=6 other=2 | `7e18f2aef102b221` |
| lakeview-40 | 41.945182,-87.66432,40,270,45 | 2026-10-15T20:30:00Z | 295,759 | 56 | chunks=9 buildings=7 foliage=34 props=1 context=2 other=3 | `7771776939501ea4` |
| lakeview-150 | 41.945182,-87.66432,150,270,45 | 2026-10-15T20:30:00Z | 271,763 | 48 | chunks=7 buildings=15 foliage=20 props=1 context=3 other=2 | `768e1dc9f41d8e40` |
| lakeview-600 | 41.945182,-87.66432,600,270,45 | 2026-10-15T20:30:00Z | 194,160 | 35 | chunks=5 buildings=11 foliage=8 props=1 context=8 other=2 | `1942c2b653c0890d` |
| wilmette-600 | 42.074933,-87.719996,600,90,45 | 2026-09-15T19:56:00Z | 235,885 | 36 | chunks=10 buildings=9 foliage=7 props=1 context=7 other=2 | `a1da773656ea47b8` |

**Not measurable natively in this batch (pending):** shadow passes, cascade count, shadow-map allocation and all-pass shadow triangles — RealityKit exposes none of them (directional light, `.automatic(maximumDistance: 120 m)`, depth bias scaled by range; no per-pass counter). GPU frame time and memory need the phone (Simulator GPU time and memory are not device-representative); last device record: Sloan's street view ~608 MB resident, 59.8 fps, 6 Oct (`docs/perf/` local logs). Proposed measurement for Batch 1+: one Xcode GPU frame capture per ladder pose on the phone (counts every encoded pass/draw incl. shadow cascades) — needs R's OK to install.

## 5. Floor tiers on native
Main pass: **every ladder view passes the floor** (<400k triangles: max 333,744 at Sloan's 150 m; ≤100 draws: max 56). Shadow ≤150k: **unknown on native** (not measured; web saw 560k → 26k only with finite-wind culling, which native lacks). The open native floor failure remains the Lakeview street hero (~414k, historical), not this ladder.

## 6. Roaming readiness (Sloan's Lake)
(a) Package `Data/areas/sloans-lake`: 1,600 × 1,200 m around 39.7494,-105.0445 (89 MB raw data). The lake spans x −733…663 m, y −592…363 m (1,396 × 955 m): it fits, but with only 8–67 m margin west/south/east. Lake + ~400 m needs ~2,196 × 1,755 m (x −1,133…1,063, y −992…763): missing ~330 m west, ~260 m east, ~390 m south. Full street detail (`demo.json` focus) covers only x −428…559, y −261…568 (north-east of the lake); the rest is context-detail.
(b) Loading is eager and whole-area: `World.load → WorldBuild.generate → AreaLoader` builds the entire area on device at load (detached task), all resident; no tiles, no unloading. Memory ~608 MB on the phone at street view.
(c) Blockers to free movement: no extent beyond the package (hard world edge at ±800/600 m; the context ring gives distant silhouettes only); detail limited to the focus box; no runtime streaming/unloading (A1's adaptive tiles are web/GLB, native cannot read them); free walk/drive/fly across the whole lake untested on native; memory headroom near the floor's 600 MiB allowance before the area is enlarged.

Used: docs/tracking/restart-5A.md (budget authority table), docs/research/crown-allocator-exposure-v1.md §Pin-only capture default, docs/data/adaptive-tiles.md, docs/review/a4-streaming-review-2026-10-08.md, scripts/web_sloans_ladder.json. Mock: none (measurement only; calibration-v2 06-sloans/01-lakeview untouched). Deviation: shadow/GPU/memory counters pending — not exposed by RealityKit on Simulator; phone capture needs R.
