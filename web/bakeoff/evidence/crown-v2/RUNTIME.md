# Crown runtime: floor startup and draw accounting

## Findings and fixes

A7's 494,604 triangles / 121 draws was an **all-pass** renderer counter: 489,507/101 main + 5,096/19 shadow + 1/1 post. The previous CPU report's 489,507/101 was explicitly main-only, but did not provide exact submitted all-pass counters. The extra twenty draws were nineteen shadow submissions and one post draw, not twenty extra main variants or transparency splits. The old shadow numbers were pre-frustum upper bounds. `crown-v2-cost.mjs` now builds the same directional-light camera, applies its actual shadow frustum, and reports exact submitted shadow and all-pass totals separately from main and potential upper bounds. `RUNTIME_COMPARE=1` asserts equality with all six measured ledgers.

To satisfy Sloan's stricter requested ≤120 even on the all-pass counter, `shadow-casters.js` batches only crownV2 elm far casters sharing the same depth material. Every instance, far topology, per-tree main allocation and 120 m reach remains. Main cost is unchanged. Standard now measures **494,670 triangles / 119 all-pass draws**, comprising main 489,507/101, shadow 5,162/17, post 1/1. Two shadow draws are saved. The combined bounding volume submits one additional 66-triangle crown previously rejected by the shadow frustum; this is accounted for, not hidden as a triangle saving. Crown OFF takes the original path. All non-elm content and all look/placement/allocation inputs are unchanged.

The recorded A7 floor log (`/private/tmp/a7-crown-floor.log`) says `web capture failed: contract Unsupported capture mode`. `scripts/web_capture_checks.mjs` accepted only off/on, and `capture_web.mjs` also expected boolean crown metadata although standard/floor are strings. Both contract errors are fixed by A7 on current main; parser/metadata regression tests cover off/on/standard/floor. R authorized the conflict resolution: all three A7 tooling files were retained byte-for-byte from main, which already supplies the required crown modes; no duplicate additions were necessary. No A7 watchdog, cleanup trap or Sloan ladder changes are included in this A2 commit. A renderer hang was **not reproduced**: the unmodified floor renderer reached ready in 20.682 seconds without warnings/errors; see `runtime/before-sloans-floor.json`. Do not label this as a proven shader/GPU hang fix. A separate future failure needs its own log.

## Measured results

Fresh headless installed Chrome 155.0.8059.39, sandbox enabled; WebGL2 via ANGLE Metal Renderer: Apple M1 Max. Frozen web scenes/viewport/date and localhost assets; no export regeneration, screenshots or art grades. Each case starts a fresh browser/server, waits for scene-ready and ≥60 frame samples, checks mode metadata/errors and sums every draw pass, then closes both and releases its heavy lock. Raw counters, GPU identity, source hashes and mode are in `runtime/after-<scene>-<mode>.json`.

| Scene / crown mode | Main tris / draws | Shadow tris / draws | Post tris / draws | All-pass tris / draws | Ready seconds |
|---|---:|---:|---:|---:|---:|
| Sloan OFF | 347,177 / 99 | 5,008 / 17 | 1 / 1 | 352,186 / 117 | 11.044 |
| Sloan standard | 489,507 / 101 | 5,162 / 17 | 1 / 1 | 494,670 / 119 | 6.065 |
| Sloan floor | 383,481 / 96 | 5,162 / 17 | 1 / 1 | 388,644 / 114 | 6.192 |
| Lakeview OFF | 265,310 / 81 | 67,190 / 81 | 1 / 1 | 332,501 / 163 | 4.646 |
| Lakeview standard | 303,842 / 83 | 67,300 / 81 | 1 / 1 | 371,143 / 165 | 4.988 |
| Lakeview floor | 275,968 / 80 | 67,300 / 81 | 1 / 1 | 343,269 / 162 | 4.984 |

Both standard views pass ≤500k **main** triangles/≤120 **main** draws. Both floor views pass <400k main/≤100 main draws, with shadows below 150k. Sloan standard additionally passes the user-reported **all-pass** ≤500k/120 comparison. Lakeview's all-pass standard total remains 165 draws (83 main + 81 shadow + 1 post); it does not pass 120 if that is redefined as an all-pass limit. No broader shadow/content reduction was performed to conceal this distinction. These are desktop measured submissions, not phone speed or memory qualification.

## Reproduction and validation

From repo root, with `WORLDENGINE_ASSETS=~/Desktop/world-engine`, run `bash web/bakeoff/crown-runtime.sh`. This loads Sloan then Lakeview in OFF/standard/floor order, one heavy admission per actual run, with a ≥8 GB disk guard. All six passed at admission loads 7.89, 8.04, 12.35, 11.84, 11.37, 10.86 (<25); own locks released. Initial floor diagnosis and standard batching runs also passed. No lock was held for investigation or edits.

The earlier pre-rebase test admission at load 8.92 verified exact CPU/measured agreement in all six cases, 1,056 default-off crown geometry cases/material graphs, exp1 exclusion controls, seeded allocation/instance tests, eight capture-contract tests, and existing policy/overnight/atmosphere/sky-colour arithmetic tests. These are input/count checks, not rendered pixel identity or art scores. Crown allocation averages remain standard 216.11/215.62 and floor 74.40/73.85 for Sloan/Lakeview. No crown geometry, palette, lights, haze, exposure or placement changes in this correction.

For the existing A7 full capture command, `--crown off,standard,floor --expectedDifferent` is now accepted and validates resolved string modes. That full exporter/screenshot pipeline was not rerun here; the new headless regression uses the actual viewer and installed Chrome directly. Same-mode/non-foliage coverage guards remain strict.

## Authorized rebase validation

Rebased af4e4b9 onto current main (initial base f244741). Main already accepts standard/floor and validates their string metadata, so no crown additions were needed in the three conflicted A7 files. Their contents, the watchdog, heavy/cleanup traps and Sloan ladder remain identical to main. Re-ran all six headless cases after resolution: every main/shadow/post count and renderer source hash is unchanged from the previous evidence; all reached ready with no warnings/errors. A7's current suite contains 27 tests (12 Node capture checks plus 15 Python native-capture/watchdog tests), rather than the requested older 26; all 27 passed at load 7.89. Each actual admission released its own lock. Later main updates were documentation-only.

## Ledger text for A3

A2 crown runtime correction: default off; compatible elm shadow-depth batching reduces Sloan standard all-pass draws 121→119 without changing main allocations. Corrected CPU model matches all six measured main/shadow/all-pass ledgers exactly. Logged floor startup blocker was capture-contract rejection plus obsolete boolean metadata expectation; fixed in A7’s retained main tooling and covered by tests. Unmodified floor renderer and final six-mode scene-ready runs passed in sandboxed headless Chrome/M1 Max; no renderer hang reproduced. Native code and tracking files untouched. Consumers: `web/bakeoff/shadow-casters.js`, corrected model, `crown-runtime.test.mjs`/`.sh`; web capture contract consumed unchanged from A7’s `scripts/capture_web.mjs`, `web_capture_checks.mjs`, and associated tests. Captures/art scores, pixel identity and phone timing remain pending. Main-only tier pass is not an all-pass Lakeview draw pass. Implementation revision is the commit introducing this RUNTIME.md.

Used: crown-silhouettes-v2 content.construction/lod; R's nearest-first 217/75 allocation and runtime correction request; existing shadow-caster reach/LOD. Mock: crown panels 01/14/17–22 and images 03/04; calibration-v2 frames 06-sloans/01-lakeview. Deviation: no screenshots/scores; logged capture blocker fixed, renderer hang not reproduced; Lakeview all-pass standard is 165 draws while main is 83.
