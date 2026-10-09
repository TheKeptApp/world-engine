# Budget floor — decision brief for R

## Recommendation

Choose **(c), two quality levels**, while preserving the current floor contract and using standard only as the provisional prototype target. Implement one general crown recipe with budgeted LOD and instancing, then qualify floor and standard separately; do not raise the floor to make an over-budget prototype pass. The Sloan web prototype still exceeds standard by 209,557 main triangles, so raising the floor alone would not solve it. Current desktop timing is encouraging but does not certify a phone, and historical phone runs do not establish current crown capacity. Keep hero experimental and avoid shipping automatic model-based selection before qualification. This is a decision proposal, not approval to alter budgets, shadows, code or supported devices.

**The one measurement that would change this recommendation:** a matched, unplugged, thermally settled **15-minute current-build standard-quality run on the weakest intended floor phone (iPhone 12)**, at fixed drawable size, with full-frame p95/p99 timing and per-pass counts, meeting the 60 fps target without resolution reduction, memory warning or serious thermal state. If that run passes with a meaningful A3 crown improvement, reconsider (b) and whether a separate floor mode is worth its maintenance cost. A 14 Pro or M1 Max result cannot answer that particular question. This run is proposed, not performed or authorized as a phone install here.

## Contracts and scope

Inspected main `b2eae2f`; existing files only, no new benchmark. [Device tiers v1](../perf/device-tiers-v1.md) owns definitions; R's latest instruction makes standard the provisional prototype target. Floor main is **strictly <400,000**; existing test uses **≤100 main draws**, despite shorthand “<400k/150k/100”. Shadow ≤150,000. Preserve the existing test boundary until R explicitly changes it. Standard ≤500,000 /180,000 /120; hero proposal ≤600,000 /225,000 /140. These are simultaneous main triangles / all-shadow-pass triangles / main draws, not interchangeable totals.

Evidence scope: all direct frame-stat JSON records under `web/bakeoff/evidence`, all saved summary runs under `docs/perf`, the walk CSV, native attribution report, package audit, Lakeview test handoff and A2 crown report. Tables below retain historical runs instead of treating them as current. Raw per-frame/per-second samples remain linked at source; this is a run-level inventory, not thousands of duplicated sample rows. **Unmeasured (U)** means absent for that metric/scope, not zero. No fresh current-main performance verification was done. Native build-header triangles/draws are not verified submitted main-pass counters. The saved web `phone-budget.json` is a desktop capture ledger, not measurements on phones.

## Current decision evidence

| Renderer / block / recorded tier | Main triangles | Shadow triangles | Main / shadow / post draws | Timing and device | Status/source |
|---|---:|---:|---|---|---|
| Web Sloan / floor, standard, hero labels | 347,177 | 5,008 observed | 99 /17 /1 | M1 Max Mac, Chrome WebGL2; exact timings by label below | Saved capture; labels have identical geometry, not three qualified modes |
| Web Lakeview / floor, standard, hero labels | 265,310 | 67,190 observed | 81 /81 /1 | Same Mac/browser; timings below | Saved capture, not phone certification |
| Web Sloan crown OFF / no qualified tier | 347,177 | ≤5,052 model | 99 /≤18 /1 | CPU model; frame/GPU time U; machine performance irrelevant | A2 model, not new rendering |
| Web Sloan crown ON / standard target | 709,557 | ≤5,458 model | 117 /≤21 /1 | Frame/GPU time U; native equivalent U | Fails floor and standard main triangles, also hero |
| Native Lakeview street / floor test | approximately 414,000 estimate | U | U /U /U | Mac shader/test execution; exact machine and frame time U | Historical ViewDrawBudgetTests failure, ~14k over floor |
| Native Sloan 40/150/600 m crown candidate / standard | U | U | U /U /U | U | Proposed in crowns.md; 1,200/360/80 mesh caps are hypotheses, not measured native counts |
| Native Wilmette, West Highland, Greenville / every tier | U | U | U /U /U | U | No qualifying per-tier performance records found in audited sources |
| Web Wilmette, West Highland, Greenville / every tier | U | U | U /U /U | U | No qualifying per-tier performance records found in audited sources |

Sources: [phone-labelled ledger](../../web/bakeoff/evidence/phone-budget.json), [laptop ledger](../../web/bakeoff/evidence/laptop-budget.json), [native tier contradictions](../perf/device-tiers-v1.md), [handoff](../tracking/handoffs.md), [crown brief](crowns.md). A2's `web/bakeoff/evidence/crown-v2/REPORT.md` was read from the same repository working checkout `/private/tmp/worldengine-a2-bakeoff`; absent from this inspected main. It is branch/working-copy evidence, not a main-path attachment. Its shadow values are **pre-frustum upper bounds**, which explains 5,052 versus the capture's 5,008; do not silently merge them.

Crown mesh topology: web near **2,606**, middle **910**, far **102** triangles including wood, one standalone draw with instancing sharing batches; shadow proxy 102 per caster/pass. Sloan has 705 elms; requested LOD populations shift from legacy 2/12/174/517 to 287/401/17. The prototype increase is **362,380 main triangles and 18 main draws**; four variants and LOD promotion matter as well as mesh complexity. Instancing reduces draw submission, **not instance-multiplied triangles**. Baseline has 52,823 triangles of nominal floor headroom (52,822 integer triangles under strict <400k) and one draw under ≤100. Standard headroom is 152,823 triangles and 21 draws. Prototype needs ≥209,557 triangles removed for inclusive standard, and ≥309,558 for strict floor, plus 17 draws for ≤100. No evidence yet establishes the quality cost of those reductions.

## Intended hardware, not certified hardware

| Tier | Intended phones from existing study | Intended laptops / web | Evidence and missing qualification |
|---|---|---|---|
| Floor | iPhone 12–13 families, weakest reference base 12 | No approved laptop mapping; proposed compatibility/default for unqualified integrated-GPU laptops | No current WorldEngine phone floor qualification. Hardware specifications alone cannot prove throughput. |
| Standard | iPhone 14 family and non-Pro 15/15 Plus; R's reference 14 Pro, iOS 26.4.2 | No approved laptop mapping; M1 Max is the measured desktop reference only | Historical 14 Pro data exists below, but no current standard-crown run. Base 14 is weaker than R's reference and still needs qualification. |
| Hero | iPhone 15 Pro/Pro Max and individually qualified newer models | No approved laptop mapping; high-end laptop is only a candidate, not automatic hero | No phone hero qualification. Desktop labels do not prove a hero-quality workload. |

This inherits hardware intent and Apple-source research from [device tiers v1 §1](../perf/device-tiers-v1.md); no new hardware claims or certification. Native RealityKit, browser WebGL2 and WebGPU require separate qualification. Do not infer device from a desktop user-agent string or select purely by year/GPU-core count. Two-level selection would need a tested allowlist/capability policy, conservative fallback, stable transitions and a user quality choice; hero remains outside the initial two-level proposal.

## Three choices

| Option | Look-quality cost | Work cost (qualitative estimate) | Risk / decision consequence |
|---|---|---|---|
| (a) Keep floor; make crowns fit | Coarser far/mid crowns and fewer near promotions may weaken silhouette at 150 m. Preserve mapped trees, silhouette and shadow reach; A3 must prove 2→3 and no hold-out loss. | Medium–high: reduce mesh/variant complexity, nearest-first LOD, batching/culling and native shadow accounting; repeat paired captures. | Most conservative compatibility target, but may spend time optimizing unmeasured limits. 99 baseline draws leaves little room. Instancing alone cannot fix 710k triangles. |
| (b) Raise floor to standard | Allows more detail than floor, but existing prototype still fails by 209,557 triangles. No demonstrated visual gain from the extra allocation yet. | Low to change a number, medium–high to qualify devices and optimize remaining overage. | Weakest phones may throttle or fail; retiring compatibility is a product decision, not a test fix. It would hide the old floor gap unless preserved historically. Cannot recommend on current evidence. |
| (c) Floor + standard by qualified device | Better crowns where measured affordable; floor may look simpler but must retain identity and pass its own A3 gates. | Highest QA/selection cost, but one recipe/LOD chain should serve both; avoid two asset forks. | Requires stable selection, memory/thermal telemetry, two renderer test matrices. Best separates provisional prototype look work from compatibility claims; no automatic enablement before qualification. |

No option authorizes thinning mapped houses/trees, shortening approved shadows, hidden dynamic resolution changes or per-block budget exceptions. Rendering is often pixel/bandwidth/shadow limited: triangle count alone cannot predict frame time, as the native opaque-foliage experiment below illustrates.

## Saved desktop web run inventory

Rows are individual saved captures, including superseded experiments; linked JSON is authoritative for camera, hashes, resolution and timing method. Main/shadow split is recomputed only from recorded pass counters. Where absent, all-pass totals remain separate and main is U. Time is **p95 frame interval / GPU mean / GPU p95**, milliseconds; these are different metrics. Device is the recorded M1 Max ANGLE/Chrome desktop unless the row explicitly says otherwise. Tier labels do not imply different geometry or device. Missing GPU timer = U, even if a descriptive ledger string says otherwise.

| Source / block | Tier | Main tris / shadow tris | Main / shadow / other draws | All-pass tris / draws | p95 frame / GPU mean / p95 ms | Device |
|---|---|---|---|---|---|---|
| [baseline/lakeview.json](../../web/bakeoff/evidence/baseline/lakeview.json) / lakeview | standard | 256834 / 267113 | 67 / 70 / 13 | 523960 / 150 | 10.480 / 2.726 / 2.848 | M1 Max / Chrome |
| [baseline/sloans.json](../../web/bakeoff/evidence/baseline/sloans.json) / sloans | standard | 201658 / 111530 | 90 / 39 / 13 | 313201 / 142 | 10.320 / 2.836 / 2.919 | M1 Max / Chrome |
| [candidate/lakeview.json](../../web/bakeoff/evidence/candidate/lakeview.json) / lakeview | standard | 265310 / 67190 | 81 / 81 / 1 | 332501 / 163 | 10.660 / 1.436 / 1.514 | M1 Max / Chrome |
| [candidate/sloans.json](../../web/bakeoff/evidence/candidate/sloans.json) / sloans | standard | 347177 / 5008 | 99 / 17 / 1 | 352186 / 117 | 10.940 / 1.671 / 1.749 | M1 Max / Chrome |
| [candidate-floor/lakeview.json](../../web/bakeoff/evidence/candidate-floor/lakeview.json) / lakeview | floor | 265310 / 67190 | 81 / 81 / 1 | 332501 / 163 | 10.955 / 1.430 / 1.507 | M1 Max / Chrome |
| [candidate-floor/sloans.json](../../web/bakeoff/evidence/candidate-floor/sloans.json) / sloans | floor | 347177 / 5008 | 99 / 17 / 1 | 352186 / 117 | 10.710 / 1.662 / 1.731 | M1 Max / Chrome |
| [candidate-hero/lakeview.json](../../web/bakeoff/evidence/candidate-hero/lakeview.json) / lakeview | hero | 265310 / 67190 | 81 / 81 / 1 | 332501 / 163 | 10.510 / 1.437 / 1.516 | M1 Max / Chrome |
| [candidate-hero/sloans.json](../../web/bakeoff/evidence/candidate-hero/sloans.json) / sloans | hero | 347177 / 5008 | 99 / 17 / 1 | 352186 / 117 | 10.945 / 1.704 / 1.876 | M1 Max / Chrome |
| [overnight/00-start/lakeview.json](../../web/bakeoff/evidence/overnight/00-start/lakeview.json) / lakeview | standard | 262138 / 322277 | 67 / 126 / 1 | 584416 / 194 | 20 / U / U | M1 Max / Chrome |
| [overnight/00-start/sloans.json](../../web/bakeoff/evidence/overnight/00-start/sloans.json) / sloans | standard | 382040 / 276536 | 91 / 67 / 1 | 658577 / 159 | 10.505 / U / U | M1 Max / Chrome |
| [overnight/01-haze/lakeview.json](../../web/bakeoff/evidence/overnight/01-haze/lakeview.json) / lakeview | standard | 262138 / 322277 | 67 / 126 / 1 | 584416 / 194 | 11.460 / U / U | M1 Max / Chrome |
| [overnight/01-haze/sloans.json](../../web/bakeoff/evidence/overnight/01-haze/sloans.json) / sloans | standard | 382040 / 276536 | 91 / 67 / 1 | 658577 / 159 | 11.125 / U / U | M1 Max / Chrome |
| [overnight/02-trees/lakeview.json](../../web/bakeoff/evidence/overnight/02-trees/lakeview.json) / lakeview | standard | 245498 / 296294 | 77 / 149 / 1 | 541793 / 227 | 20.005 / U / U | M1 Max / Chrome |
| [overnight/02-trees/sloans.json](../../web/bakeoff/evidence/overnight/02-trees/sloans.json) / sloans | standard | 346193 / 243606 | 97 / 69 / 1 | 589800 / 167 | 11.715 / U / U | M1 Max / Chrome |
| [overnight/03-light/lakeview.json](../../web/bakeoff/evidence/overnight/03-light/lakeview.json) / lakeview | standard | 245498 / 296294 | 77 / 149 / 1 | 541793 / 227 | 20.005 / U / U | M1 Max / Chrome |
| [overnight/03-light/sloans.json](../../web/bakeoff/evidence/overnight/03-light/sloans.json) / sloans | standard | 346193 / 243606 | 97 / 69 / 1 | 589800 / 167 | 11.295 / U / U | M1 Max / Chrome |
| [overnight/04-water/lakeview.json](../../web/bakeoff/evidence/overnight/04-water/lakeview.json) / lakeview | standard | 245498 / 296294 | 77 / 149 / 1 | 541793 / 227 | 20.005 / U / U | M1 Max / Chrome |
| [overnight/04-water/sloans.json](../../web/bakeoff/evidence/overnight/04-water/sloans.json) / sloans | standard | 346193 / 243606 | 97 / 69 / 1 | 589800 / 167 | 11.225 / U / U | M1 Max / Chrome |
| [overnight/05-facades/lakeview.json](../../web/bakeoff/evidence/overnight/05-facades/lakeview.json) / lakeview | standard | 265310 / 322586 | 81 / 155 / 1 | 587897 / 237 | 20.005 / U / U | M1 Max / Chrome |
| [overnight/05-facades/sloans.json](../../web/bakeoff/evidence/overnight/05-facades/sloans.json) / sloans | standard | 347177 / 245154 | 99 / 70 / 1 | 592332 / 170 | 11.125 / U / U | M1 Max / Chrome |
| [overnight/06-budget/lakeview.json](../../web/bakeoff/evidence/overnight/06-budget/lakeview.json) / lakeview | standard | 265310 / 322586 | 81 / 155 / 1 | 587897 / 237 | 20.005 / 1.995 / 3.185 | M1 Max / Chrome |
| [overnight/06-budget/sloans.json](../../web/bakeoff/evidence/overnight/06-budget/sloans.json) / sloans | standard | 347177 / 245154 | 99 / 70 / 1 | 592332 / 170 | 11.360 / 2.080 / 3.225 | M1 Max / Chrome |
| [pre-haze/lakeview.json](../../web/bakeoff/evidence/pre-haze/lakeview.json) / lakeview | standard | 262138 / 322277 | 67 / 126 / 1 | 584416 / 194 | 19.980 / U / U | M1 Max / Chrome |
| [pre-haze/sloans.json](../../web/bakeoff/evidence/pre-haze/sloans.json) / sloans | standard | 382040 / 276536 | 91 / 67 / 1 | 658577 / 159 | 10.950 / U / U | M1 Max / Chrome |
| [previous-a2/lakeview.json](../../web/bakeoff/evidence/previous-a2/lakeview.json) / lakeview | U | U / U | U / U / U | 1068448 / 194 | 20 / U / U | M1 Max / Chrome |
| [previous-a2/sloans.json](../../web/bakeoff/evidence/previous-a2/sloans.json) / sloans | U | U / U | U / U / U | 1442985 / 160 | 10.900 / U / U | M1 Max / Chrome |
| [shadow-colour/before/lakeview.json](../../web/bakeoff/evidence/shadow-colour/before/lakeview.json) / lakeview | standard | 265310 / 322586 | 81 / 155 / 1 | 587897 / 237 | 20.005 / 1.995 / 3.185 | M1 Max / Chrome |
| [shadow-colour/before/sloans.json](../../web/bakeoff/evidence/shadow-colour/before/sloans.json) / sloans | standard | 347177 / 245154 | 99 / 70 / 1 | 592332 / 170 | 11.360 / 2.080 / 3.225 | M1 Max / Chrome |

## Saved native and historical phone-web runs

These runs predate the tier policy: **tier unassigned**, block identity not reliably pinned in each summary (Front Range/Raleigh Street context where the attribution note says so; do not relabel as the current Sloan hero camera). Phone reference is the historical iPhone 14 Pro / iOS 26.4.2 from perf documentation; individual summaries do not independently identify hardware. Build-header triangle/draw totals below are resident/renderer-summary scope, **main triangles U, shadow triangles U, verified main draws U for every row**. Values must not be retroactively compared as verified main submissions. GPU fields without an explicit source may be post-process-only/ambiguous; retained with that warning, not treated as full-frame GPU evidence. Each source includes duration, thermal state, scale and raw samples.

| Source / renderer | Header tris / draws (not main) | Average fps / max frame ms | Reported GPU mean / p95 ms; scope | Duration s / scale→cap / thermal | Device / tier |
|---|---|---|---|---|---|
| [m2-matched/realitykit-20261005-174330-summary.json](../perf/m2-matched/realitykit-20261005-174330-summary.json) / realitykit | 278817 / 108 | 59.806 / 35.954 | 1.647 / 1.740; unverified scope | 60.411 / unrecorded / nominal,fair | 14 Pro historical reference / unassigned |
| [m2-matched/realitykit-20261005-183941-summary.json](../perf/m2-matched/realitykit-20261005-183941-summary.json) / realitykit | 278817 / 108 | 48.456 / 50.101 | 1.647 / 1.766; unverified scope | 600.597 / unrecorded / nominal | 14 Pro historical reference / unassigned |
| [m2-matched/threejs-webgl2-20261005-174628-summary.json](../perf/m2-matched/threejs-webgl2-20261005-174628-summary.json) / threejs-webgl2 | U / U | 19.989 / 227 | U / U; unverified scope | 60.185 / unrecorded / serious | 14 Pro historical reference / unassigned |
| [m2-matched/threejs-webgl2-20261005-190031-summary.json](../perf/m2-matched/threejs-webgl2-20261005-190031-summary.json) / threejs-webgl2 | U / U | 19.327 / 653 | U / U; unverified scope | 600.166 / unrecorded / nominal | 14 Pro historical reference / unassigned |
| [m2-matched/threejs-webgpu-20261005-174458-summary.json](../perf/m2-matched/threejs-webgpu-20261005-174458-summary.json) / threejs-webgpu | U / U | 59.858 / 80 | U / U; unverified scope | 60.162 / unrecorded / fair,serious | 14 Pro historical reference / unassigned |
| [m2-matched/threejs-webgpu-20261005-174910-summary.json](../perf/m2-matched/threejs-webgpu-20261005-174910-summary.json) / threejs-webgpu | U / U | 58.696 / 54 | U / U; unverified scope | 45.547 / unrecorded / serious | 14 Pro historical reference / unassigned |
| [m2-matched/threejs-webgpu-20261005-191838-summary.json](../perf/m2-matched/threejs-webgpu-20261005-191838-summary.json) / threejs-webgpu | U / U | 29.823 / 478 | U / U; unverified scope | 600.424 / unrecorded / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-212357-summary.json](../perf/m3-phase5a/realitykit-20261005-212357-summary.json) / realitykit | 278817 / 108 | 59.953 / 17.269 | U / U; none | 60.109 / 2.50,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-212519-summary.json](../perf/m3-phase5a/realitykit-20261005-212519-summary.json) / realitykit | 278817 / 108 | 55.281 / 44.651 | 30.143 / 35.601; kernel per-process GPU time (task_power_info_v2), full frame | 60.265 / 2.50,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-212641-summary.json](../perf/m3-phase5a/realitykit-20261005-212641-summary.json) / realitykit | 278817 / 108 | 59.790 / 35.930 | U / U; none | 60.309 / 3.00,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-212803-summary.json](../perf/m3-phase5a/realitykit-20261005-212803-summary.json) / realitykit | 278817 / 108 | 59.953 / 17.195 | U / U; none | 60.104 / 2.00,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-212957-summary.json](../perf/m3-phase5a/realitykit-20261005-212957-summary.json) / realitykit | 278817 / 108 | 52.343 / 75.896 | 31.104 / 34.171; kernel per-process GPU time (task_power_info_v2), full frame | 120.735 / 2.50,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a/realitykit-20261005-213218-summary.json](../perf/m3-phase5a/realitykit-20261005-213218-summary.json) / realitykit | 278817 / 108 | 29.977 / 33.392 | 31.666 / 33.751; kernel per-process GPU time (task_power_info_v2), full frame | 120.118 / 2.50,60,2.50,30 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a-gate/realitykit-20261005-231905-summary.json](../perf/m3-phase5a-gate/realitykit-20261005-231905-summary.json) / realitykit | 401965 / 109 | 59.589 / 65.149 | U / U; none | 60.173 / 2.50,60 / nominal | 14 Pro historical reference / unassigned |
| [m3-phase5a-gate/realitykit-20261005-232127-summary.json](../perf/m3-phase5a-gate/realitykit-20261005-232127-summary.json) / realitykit | 401965 / 109 | 58.920 / 231.791 | U / U; none | 60.314 / 2.50,60,2.25,60 / nominal,fair | 14 Pro historical reference / unassigned |

[Earlier 10-minute walk](../perf/walk-10min/metrics.csv): 614 one-second samples; header **493,025 triangles /108 draws**, scope not verified main; shadow U. Sample fps range **17.00–60.00**, per-second average frame-time range **16.66–17.84 ms**, per-second worst frame range **17.21–40.59 ms**. Device 14 Pro/iOS26.4.2 per perf README; profile front-range, exact block/tier unassigned. These ranges are not per-frame percentiles or a present-day pass.

### Native traced GPU attribution (historical, not tier certification)

Source: [GPU attribution](../perf/gpu-attribution.md), fixed `street-mid`, 14 Pro/iOS26.4.2, character present, golden hour; charging/thermal/clock caveats apply. All main/shadow triangle and draw counts U. GPU busy time is not display frame interval.

| Run / state | GPU evidence ms | Limitation |
|---|---|---|
| M2 Raleigh baseline | mean15.35 /p95 15.78 /max17.60 | Induced minimum clock; not crown comparison |
| M2 noShadows | 15.47 /15.94 /17.65 | Same caveat |
| M2 opaqueProps | 15.47 /15.99 /17.14 | Same caveat |
| M2 noClutter | 15.29 /15.81 /21.52 | Same caveat |
| M2 noProps | 15.01 /15.91 /16.51 | Same caveat; report says variants held60fps |
| Attribution1 all-on medium clock | total15.2; main pixels11.26, shadow1.52, post1.14, main geometry0.72, composite0.53, skinning0.22 | Components rounded; charging/serious heat |
| Attribution1 feature removal | shadows save5.6; foliage pixels save4.1; MSAA1.7; extras0.2; ground removal costs2.7 | Paired clock restrictions in source; not additive savings |
| Attribution2 transparent→opaque distant foliage | 15.37→12.41; main pixels11.37→8.27 | Same medium clock; genuine historical comparison, not current crown geometry |
| Attribution3 minimum clock | approximately15.3 | Governor invalidates feature-pair conclusions |
| Attribution3 MSAA-off maximum clock | total8.51; pixels5.22, post1.07, shadow geometry0.87, main geometry0.70, composite0.43 | MSAA-on 9–9.5 is an estimate, not a measurement |


### Additional saved GPU trace summaries

Recorded trace statistics below retain busy versus span distinction; span includes gaps and is not interchangeable with busy or display frame time. Devices/thermal caveats inherit the historical run above; tier unassigned and verified pass triangle/draw counts U.

| Source | Metric | Samples | Mean / median / p95 / worst1% / max ms |
|---|---|---:|---|
| [street-v3/noMSAA-maxclock-gpu.txt](../perf/m3-phase5a-attribution/street-v3/noMSAA-maxclock-gpu.txt) | busy | 331 | 8.51 / 8.53 / 8.69 / 8.82 / 8.84 |
| [street-v3/noMSAA-maxclock-gpu.txt](../perf/m3-phase5a-attribution/street-v3/noMSAA-maxclock-gpu.txt) | span | 331 | 12.49 / 12.47 / 13.70 / 14.22 / 14.40 |
| [m3-phase5a-gate/loop-clear-gpu.txt](../perf/m3-phase5a-gate/loop-clear-gpu.txt) | busy | 524 | 14.07 / 14.21 / 14.41 / 14.65 / 14.96 |
| [m3-phase5a-gate/loop-clear-gpu.txt](../perf/m3-phase5a-gate/loop-clear-gpu.txt) | span | 524 | 18.03 / 18.20 / 20.18 / 31.27 / 32.34 |
| [m3-phase5a-gate/loop-rain-gpu.txt](../perf/m3-phase5a-gate/loop-rain-gpu.txt) | busy | 542 | 15.06 / 15.06 / 15.86 / 19.75 / 22.00 |
| [m3-phase5a-gate/loop-rain-gpu.txt](../perf/m3-phase5a-gate/loop-rain-gpu.txt) | span | 542 | 18.94 / 18.05 / 20.57 / 115.01 / 229.03 |
| [m3-phase5a-gate/maxclock-clear-gpu.txt](../perf/m3-phase5a-gate/maxclock-clear-gpu.txt) | busy | 536 | 14.04 / 14.14 / 14.38 / 14.53 / 14.63 |
| [m3-phase5a-gate/maxclock-clear-gpu.txt](../perf/m3-phase5a-gate/maxclock-clear-gpu.txt) | span | 536 | 17.91 / 18.30 / 20.03 / 23.21 / 28.52 |

### Package totals are not frames

[Native adaptive-package audit](../perf/ios-new-tiles-v1.md): Sloan all-leaf LOD0/LOD1 **451,997/133,249 triangles**, **110/110 primitives**, 76 leaves; Lakeview **1,370,373/164,560**, **114/114 primitives**, 114 leaves. These measured static index totals exclude instances/props and do not imply simultaneous drawing. Frame time, shadow triangles and actual draws U; no tier or measured phone. Do not use LOD1 totals as shadow counts.

## Measurement gaps and decision gate

No current build has a complete block × renderer × tier × physical-device matrix. Native all-pass shadow submissions remain unmeasured in these records. Saved desktop timings are short, small-viewport trials; historical phone logs include different scenes, characters, thermal states, scale changes and renderer versions. `gpuMs` names alone do not establish timing scope. No laptop class beyond the M1 Max reference is qualified. The three tier labels in saved web runs do not prove three quality implementations. Missing phone GPU, native shadow, thermal and memory evidence must stay unmeasured, not inferred from desktop fps.

Before accepting either level, freeze build/assets/camera/date/weather/drawable size and quality settings, collect main/shadow/other counters, CPU and complete GPU frame-time p50/p95/p99, memory/thermal timeline and transitions, then A3 blind score current crowns and untouched hold-outs. Use current heavy-lock/load protocol; installs/testing remain separately authorized. No benchmark, device selection policy, gate change or other document is edited by this brief.

Used: saved web/perf run tables, A2 crown CPU report, device-tiers-v1 and crowns.md. Mock: unchanged approved crown/calibration targets; no new capture. Deviation: historical counts/timings are not current tier qualification; all missing metrics explicitly unmeasured.
Tracker update:
