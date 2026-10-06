# GPU attribution

## Phase 5A: cost by feature on a fixed view (iPhone 14 Pro, iOS 26.4.2), 2026-10-06

`scripts/device_attribution.sh` (VIEW=street: the `street-mid` preset, Luna standing, golden hour, clear; fixed 2.5× scale) launches WorldLab with `-attribution 60`: each feature is switched off for 60 s between two "all features on" phases, and a 5 s Metal System Trace (template asking for the maximum GPU clock) is recorded inside each phase. `scripts/attribution_costs.py` then compares frames **at the same GPU clock state**, and splits GPU time by pass (encoder).

Why this method:
- **The camera must not move.** On the walking loop, GPU time changes from 11 to 15 ms with the view alone, so one phase per stretch of street measures the street, not the feature.
- **Heat holds the clock down.** These overnight runs were on the charger at "serious" heat: the trace's GPU performance state was "minimum" or "medium" although "maximum" was requested, and it changed during runs (`scripts/gpu_states.py` prints it per second). Busy time scales with the clock, so only frames at the same state are compared, and shares of the frame carry over better than milliseconds.
- **Charging runs are functional only** (your overnight rule): the shares below guide the work; the daytime session repeats the measurement unplugged at nominal heat.

### Run 1: every tree on the cut-away's transparent pipeline (`m3-phase5a-attribution/street-run1/`)

GPU time per pass in an all-on phase at the "medium" clock (ms per frame): main pass pixel shading 11.26, shadow map 1.52 (vertex 1.32 + pixels 0.20), post-processing compute 1.14, main pass geometry 0.72, final composite 0.53, Luna's skinning 0.22. Total busy 15.2.

| Switched off | Compared at | Saves | Share |
|---|---|---:|---:|
| Sun shadows | medium clock (post pass 1.07 vs 1.14 ms: same clock) | 5.6 ms | 37% |
| Trees and bushes | min clock, main pass pixels 14.6 → 10.6 ms | 4.1 ms of the main pass | ≈ 28% of it |
| MSAA | min clock, both neighbours | 1.7 ms | 8% |
| Surface extras (lawn patches, litter, puddles, snow) | min clock, both neighbours | 0.2 ms | 1% |
| Ground, streets, water and buildings | min clock | −2.7 ms (dearer: the sky dome then covers the screen, and sky pixels cost more than ground) | — |
| Post-processing | — | not measurable this way: switching it off still copies the image (0.6 ms) | — |

### Run 2: trees and bushes beyond 20 m opaque (`m3-phase5a-attribution/street/`)

- **The old transparent set-up costs 2.97 ms more per frame than the new one: 15.37 vs 12.41 ms at the medium clock** (post pass 1.17 vs 1.18 ms, so the clocks match); main pass pixel shading 11.37 → 8.27 ms. That is 24% of the frame.
- Every other pair in this run is void: the GPU ran at its minimum state and scaled its clock to the load, so busy time stayed at ≈ 15.3 ms whatever was switched off.

### Next
The daytime session repeats both runs unplugged at nominal heat, where the maximum-clock request held in the gate session (`m3-phase5a-gate/maxclock-clear-gpu.txt`), plus shorter shadow ranges (50 m, 30 m) and the walking loop with tonight's changes.

## Milestone 2 samples, 2026-10-05

8-second Metal System Trace per variant while the stand-in walks Raleigh Street. Parsed with `scripts/gpu_frames.py` (GPU busy = union of the frame's GPU intervals).

**Caveat:** Instruments recorded with the GPU **induced to its Minimum performance state** ("GPU Performance State: Minimum — due to active device conditions", induced = yes), although Xcode's Device Conditions shows none running. These are worst-case, lowest-clock numbers. At minimum clock the GPU stretches work to fill the frame, so the variants barely differ.

| Variant (`-diag`) | GPU busy mean | p95 | max |
|---|---:|---:|---:|
| baseline | 15.35 ms | 15.78 | 17.60 |
| `noShadows` | 15.47 ms | 15.94 | 17.65 |
| `opaqueProps` (no transparent pipeline for foliage/lamps) | 15.47 ms | 15.99 | 17.14 |
| `noClutter` (no grass tufts) | 15.29 ms | 15.81 | 21.52 |
| `noProps` (no trees, bushes, lamps, benches, tufts) | 15.01 ms | 15.91 | 16.51 |

Even at the minimum GPU clock, every variant held 60 fps.
