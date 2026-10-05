# GPU attribution samples (iPhone 14 Pro, iOS 26.4.2), 2026-10-05

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
