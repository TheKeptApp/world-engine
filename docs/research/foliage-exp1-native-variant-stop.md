# Native foliage build variant: amended gate failure

8 October 2026. R approved the build-time variant and amended ≤1/255 gate. Shipping source and fetched main both have SHA-256 `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`; byte-for-byte unchanged. Default build uses original source. Generated experimental source changes only worldFoliageSurface; remove/layered compile constants 1/2. No runtime uniform transport or geometry/budget/tile changes.

Arithmetic witnesses and generated exclusions pass. Native Metal build passes. Baseline-repeat control max/mean **0** for all seven categories at leaf fractions 1 and 0. Remove max/mean **0** for all seven categories. Layered results below; maximum byte differences divide by 255 for normalized differences. Mean is absolute RGBA difference over every byte of the 512×512 isolated category image, including background, not only object pixels. These are macOS RealityKit controls, not iPhone measurements.

| Category | Leaf fraction | Layered max byte difference | Layered mean absolute byte difference |
|---|---:|---:|---:|
| bush | 1.0 | 1 | 9.34600830078125e-05 |
| bush | 0.0 | 1 | 9.34600830078125e-05 |
| flower-bush | 1.0 | 1 | 7.152557373046875e-05 |
| flower-bush | 0.0 | 1 | 7.152557373046875e-05 |
| conifer | 1.0 | 1 | 2.6702880859375e-05 |
| conifer | 0.0 | 1 | 2.6702880859375e-05 |
| tuft | 1.0 | 0 | 0.0 |
| tuft | 0.0 | 0 | 0.0 |
| bark | 1.0 | 1 | 9.5367431640625e-07 |
| bark | 0.0 | 1 | 9.5367431640625e-07 |
| skyline-crown | 1.0 | 2 | 9.5367431640625e-06 |
| skyline-crown | 0.0 | 1 | 1.430511474609375e-05 |
| leaf-cards | 1.0 | 1 | 1.621246337890625e-05 |
| leaf-cards | 0.0 | 1 | 9.5367431640625e-07 |

**FAIL:** skyline-crown at full leaf exceeds 1/255 (max 2/255). Exact error: `Expectation failed: (maximum → 2) <= ((mode == 0 ? 0 : 1) → 1)`, FoliageExperimentTests.swift:130:25. Both separate-return and common-finish equivalent control-flow layouts fail this category. Baseline-repeat remains zero; do not attribute the failure to arbitrary baseline noise or weaken the gate.

Implementation retained on `astra/a10-foliage-build-variant`; not merged. Sloan’s baseline/remove/layered 40/150/600 m captures were not started because the category gate failed. No scoring. Default main shader remains unchanged. Verification uses scripts/heavy.sh at load below 25; jobs release their locks. No other lane's lock touched. Last log: `/private/tmp/a10-foliage-heavy.log`; raw frames/controls: `/private/tmp/worldengine-a10/.build/a10-foliage-variant/controls`.

Used: foliage-exp1-spec.md Approved native build-variant / pixel gate amendment; execution/ao.md Authority; weekend-brief.md §0. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: skyline non-mask max 2/255 fails amended gate; captures and code merge stopped.
