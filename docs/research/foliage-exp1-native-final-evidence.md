# Native foliage experiment 1: FINAL gate evidence

8 October 2026. R’s FINAL amendment is in [the spec](foliage-exp1-spec.md#final-native-non-mask-gate-amendment--8-october-2026-r-a10). Shipping shader source stays byte-for-byte identical to fetched main: SHA-256 `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`. Default builds compile that shipping source. Only explicit FOLIAGE_EXP1_BUILD=remove/layered generates a temporary variant and compiles constant 1/2; the generated variant changes only worldFoliageSurface. Renderer resource selection, geometry, tile logic, budgets, palette, shadows, haze and AO composition remain unchanged.

## Category proof

Native macOS RealityKit isolated 512×512 RGBA controls, leaf fractions 1 and 0, same light/camera/palette. Maximum byte differences divide by 255 for normalized difference. Mean absolute difference is in **byte units**, averaged over all 1,048,576 bytes including background; differing count uses those same bytes. CPU arithmetic witnesses and generated exclusion tests pass. Baseline-repeat and remove each have max=0, mean=0, differing bytes=0 for every row below. Layered passes BOTH max≤2/255 and mean≤5e-4 byte units. No visual score is inferred.

| Category | Leaf fraction | Layered max byte difference | Mean absolute byte difference | Differing bytes |
|---|---:|---:|---:|---:|
| bush | 1 | 1 | 9.34600830078e-05 | 98 |
| bush | 0 | 1 | 9.34600830078e-05 | 98 |
| flower-bush | 1 | 1 | 7.15255737305e-05 | 75 |
| flower-bush | 0 | 1 | 7.15255737305e-05 | 75 |
| conifer | 1 | 1 | 2.67028808594e-05 | 28 |
| conifer | 0 | 1 | 2.67028808594e-05 | 28 |
| tuft | 1 | 0 | 0 | 0 |
| tuft | 0 | 0 | 0 | 0 |
| bark | 1 | 1 | 9.53674316406e-07 | 1 |
| bark | 0 | 1 | 9.53674316406e-07 | 1 |
| skyline-crown | 1 | 2 | 9.53674316406e-06 | 9 |
| skyline-crown | 0 | 1 | 1.43051147461e-05 | 15 |
| leaf-cards | 1 | 1 | 1.62124633789e-05 | 17 |
| leaf-cards | 0 | 1 | 9.53674316406e-07 | 1 |

## Capture procedure and provenance

The nine-frame batch calls A7’s capture worker through one heavy admission, immediately after the passing category suites. Invocation from this worktree: `HEAVY_AGENT=A10 HEAVY_LOAD=25 scripts/capture-foliage-exp1.sh --output .build/a10-foliage-final/sloans-batch` (new output directory required). The combined verification/capture execution used the same worker within its existing heavy lock, never nested locks. Admission load 5.62, waited 0 seconds. Each frame performs native prerequisite generation, Simulator build, installation and capture; no phone install.

The app `-foliageexp1` argument labels the requested capture mode; it does not switch shaders at runtime. The capture CLI `--foliageexp1` selects and rebuilds the corresponding compile-time variant.

Camera: `-inspectionpose 39.7511195,-105.0389,ALT,270,45`, ALT=40/150/600 m above ground. Native date `2026-10-15T20:30:00Z`; clear weather, cloud=0, wind=0, character none, renderer RealityKit, HUD off, frame 16:9. These owner-requested inspection views replace the street preset while preserving the frozen native date and renderer contract. Hold-out protocol and A3 scoring remain unchanged.

Capture metadata records requested and observed pose, shipping and compiled source SHA-256, compile constant, metallib hashes, frame hash, size, timing and crashes. Category controls are macOS evidence; the nine scenes are iOS Simulator evidence, not iPhone 14 Pro performance. Preserve this worktree and ignored `.build/a10-foliage-final` artifacts until A3 has scored. Source/tests/build changes are the separate variant generator, build workflows, app batch inspection/provenance parsing, capture worker/batch and focused tests; no render-source edits.

All nine frames passed: valid non-flat PNG, 1005×565, RealityKit source, zero recorded crashes, requested/observed poses equal within 1e-7, and frame hashes independently rechecked. Each mode’s compiled library hash is stable across its three heights and distinct from the other modes. Capture code commit: `ec14fed65c358c8b1271a93b61b1d5124ff8c5f8`; subsequent delivery changes only documentation. Heavy job exits 0 and releases its lock.

## Frames for A3

No self-score. A3 judges these side-by-side mode groups and applies the existing untouched hold-out and confirmation rules. Local ignored images stay out of git.

| Altitude AGL | Baseline | Remove | Layered |
|---|---|---|---|

| 40 m | [baseline 40 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/baseline/40/raw/ordinary-street-afternoon.png) | [remove 40 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/remove/40/raw/ordinary-street-afternoon.png) | [layered 40 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/layered/40/raw/ordinary-street-afternoon.png) |
| 150 m | [baseline 150 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/baseline/150/raw/ordinary-street-afternoon.png) | [remove 150 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/remove/150/raw/ordinary-street-afternoon.png) | [layered 150 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/layered/150/raw/ordinary-street-afternoon.png) |
| 600 m | [baseline 600 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/baseline/600/raw/ordinary-street-afternoon.png) | [remove 600 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/remove/600/raw/ordinary-street-afternoon.png) | [layered 600 m](/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/layered/600/raw/ordinary-street-afternoon.png) |

## Compiled provenance

| Mode | Constant | Compiled source SHA-256 | Engine metallib SHA-256 |
|---|---:|---|---|
| off | 0 | `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a` | `7d6890038a603e48d9bce41da002dcf097a3c92219fce75e8477c651434e32ce` |
| remove | 1 | `a1664667fe7d34d38227a4f77b136db23e65785ea045ce00c61ed6bba660d488` | `becdf16677a431f4671bab56bf1a7473b2feee64ea80d899190944c02783ad5e` |
| layered | 2 | `a1664667fe7d34d38227a4f77b136db23e65785ea045ce00c61ed6bba660d488` | `d5784f7458135a8730c68e49a148de57b4a1dec78373d45ac4298f11daf3cb91` |

Full per-frame metadata/pose/frame SHA-256: `/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/batch.json`. Category measurements: `/private/tmp/worldengine-a10/.build/a10-foliage-final/category-results.json`. Verification/build/capture log: `/private/tmp/worldengine-a10/.build/a10-foliage-final/verification-and-capture.log`.

Used: foliage-exp1-spec.md FINAL native non-mask gate amendment / Exact candidate math; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: owner-approved build-time variant and FINAL numeric gate; Simulator evidence only, no visual score or hold-out claim.

## Files changed

- `Apps/WorldLab/Sources/ContentView.swift`
- `Apps/WorldLab/Sources/Demo.swift`
- `Tests/WorldEngineTests/FoliageExperimentTests.swift`
- `docs/decisions/owner-log.md`
- `docs/research/foliage-exp1-native-final-evidence.md`
- `docs/research/foliage-exp1-native-pixel-stop.md`
- `docs/research/foliage-exp1-native-variant-stop.md`
- `docs/research/foliage-exp1-spec.md`
- `docs/tracking/INDEX.md`
- `docs/tracking/INTEGRATION.md`
- `docs/tracking/MOCKS.md`
- `docs/tracking/STATE.md`
- `docs/tracking/handoffs.md`
- `scripts/build-native.sh`
- `scripts/capture-foliage-exp1.sh`
- `scripts/capture_foliage_exp1.py`
- `scripts/capture_native.py`
- `scripts/foliage_variant.py`
- `scripts/postcard_mac_check.sh`
- `scripts/tests/test_native_capture.py`
