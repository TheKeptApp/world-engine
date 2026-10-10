# Native Batch 3 — merge, phone, extended Sloan's, capture exposure (5A, 10 Oct 2026)

No look, shader or palette change. Simulator captures via `scripts/capture-native.sh`; raw logs/frames local (`scratchpad/b3`).

## A. Merge
Batch 2 rebased on main; the `scripts/capture_native.py` conflict resolved as R authorised (P2's `--lookexp` and 5A's `--diag` both kept, nothing else); add-only handoffs conflicts kept in date order. Full suite **431/431**. On main: **165ed6e**.

## B. Phone
Install of this build failed: `CoreDeviceService was unable to locate a device matching the requested device identifier (ecid_4830159220776990)`, device state **unavailable** (locked, asleep or off Wi-Fi/USB). Storage state could not be read and whether WorldLab was deleted is unknown; the confirming pan is **skipped** (not run). 9 Oct 18:07 jetsam, 888 MB WorldLab: the Lakeview 40 m ladder launch, 6 s after the Sloan's 600 m pose run ended (pose logs 18:07:35; report 18:07:41), Batch 1 build (main b5a33cb code, branch 5a-stream-slice1), flags `-memreport -inspectionpose 41.945182,-87.66432,40,270,45 -area lakeview-sheil-park`, Metal HUD on, streaming off; the value is resident pages at the world-load peak (generated CPU geometry still held before release); the same launch settled at a 602.9 MiB footprint. Not killed.

## C. Extended Sloan's (A1's 108-cell area)
`Data/areas/sloans-lake-extended` (A1, 5c511f9; raw osm/context copied locally from A1's worktree, hashes match its manifest, git-ignored) bundled in WorldLab and listed in `demo.json` with focus = the whole 2,196 × 1,755 m box. One default-off flag `-diag roam` = shadow cells + near-level streaming. The scripted pan (`-mode route -pantest`) covers any area's bounds (extended: ~15.6 km at 30 m/s). Simulator, Sloan's ladder pose inside the new box:

| Height | Main tris/draws off → roam | Shadow tris/draws off → roam | Geometry GPU MiB off → roam |
|---|---|---|---|
| 40 m | 492,424/62 → 454,488/69 | 308,047/59 → **173,124/56** | 603.9 → 433.9 |
| 150 m | 512,177/52 → 479,555/64 | 271,217/44 → **162,685/41** | 603.9 → 433.9 |
| 600 m | 662,146/78 → 655,396/**110** | 129,017/6 → 53,671/5 | 603.9 → 433.9 |

**Native exceeds the floor on the extended area at every height:** main triangles 454k–655k (> 400k), shadow 163k–173k at 40/150 m (> 150k), main draws 110 at 600 m (> 100). Same direction as A1's web route (150/600 m over). Phone memory, frame times and upload gate on the extended area: **pending** (phone unavailable); Simulator footprint 760–768 → 585–595 MiB is not device-representative. Far parent **not ported** (instruction: report first). What it would address: 600 m main 655k/110 and 150 m 480k; the 40 m main overage (454k) and shadow at 40/150 m need more (far parent alone does not reach 40 m).

## D. Capture exposure
`scripts/capture-native.sh --exposure settled` (new; default stays `pinned`, gain 1.0): live auto exposure settles (30 frames within 0.05 %), then is frozen for the capture; SCENEREADY reports `exposure=frozen-<gain>`, `native-capture.json` records `captureExposure {mode, gain}`. App exposure behaviour and defaults unchanged (the freeze is capture-only and restored after). Contract updated: `docs/lookloop/a3-capture-contract.json` `captureExposure`.

| Pose | Settled gain | vs pinned 1.0 |
|---|---:|---|
| Sloan 40 m | 1.1116 | pinned 10 % darker |
| Sloan 150 m | 1.1691 | 14 % darker |
| Sloan 600 m | 0.6470 | 55 % brighter |
| Lakeview 40 m | 1.4317 | 30 % darker |
| Lakeview 150 m | 1.3182 | 24 % darker |
| Lakeview 600 m | 0.8493 | 18 % brighter |
| Wilmette 600 m | 0.6432 | 55 % brighter |

Sloan values repeat the Batch 2 live readings (1.112/1.170/0.648). Pinned-1.0 A3 frames understate brightness at street heights (Lakeview most) and overstate it from 600 m.

## Recommendation for Batch 4
Port the far parent and per-cell tree instancing natively for the extended area (600 m 655k/110 draws, 40/150 m shadow 163–173k), then the confirming phone pans once the phone is reachable.

Used: docs/data/sloans-lake-extended.md (A1, 5c511f9); docs/perf/native-batch2.md; docs/execution/simplified-far-parent.md; docs/lookloop/a3-capture-contract.json. Mock: none (no look change). Deviation: phone unavailable — B pan, C phone memory/frame/upload pending; extended area over floor, far parent not ported per instruction.
