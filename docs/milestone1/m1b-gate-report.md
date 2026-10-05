# M1b gate report: first visual milestone

Date: 2026-10-05. Area: Raleigh Street (east of Sloan's Lake) + Sloan's Lake Trail, inside the Sloan's Lake area B extract.
Build: iOS 26.0 minimum, Xcode 26.4, Swift 6.3.

## Screenshots (`docs/screenshots/m1/milestone1/`)

| File | What |
|---|---|
| `1-street-mid.png` | Street camera mid-block on Raleigh St, camera over the street facing the houses |
| `2-corner.png` | Street camera at Raleigh St & W 23rd Ave |
| `3-lake-path-looking-back.png` | On Sloan's Lake Trail, looking back north-east at the houses |
| `4-aerial-low.png` | Low aerial over the street (gabled/hipped roofs, chimneys, alley garages, curbs, tree shadows) |
| `5-tree-cutaway.png` | Street-tree trunk between camera and stand-in, cut away (dithered) |
| `6-footprint-lineup.png` | Six real house footprints: rectangle, L-shape, complex orthogonal, smallest, largest, least rectangular |

All shots use golden hour, 22 Sept 2026 17:45 MDT (sun 13° up, WSW), with shadows, shader fog and a sky gradient. They're reproducible with `scripts/snapshots.sh <out.png> -preset <name> -hud off`.

### Footprint lineup (picked automatically by shape, not by hand)

| # | Pick | OSM | Class | Roof | Area | Fill of bounding rectangle |
|---|---|---|---|---|---:|---:|
| 1 | Typical rectangle | way/570467718 | rectangle | gabled | 116 m² | 93% |
| 2 | L-shape | way/350197538 | orthogonal (2 rects) | hipped | 343 m² | 85% |
| 3 | Complex orthogonal | way/557329833 | orthogonal (3+ rects) | hipped | 224 m² | 70% |
| 4 | Smallest house | way/1503249640 | rectangle | hipped | 48 m² | 97% |
| 5 | Largest house | way/560602182 | orthogonal | hipped | 425 m² | 65% |
| 6 | Least rectangular (worst) | way/577339083 | irregular | flat + parapet | 287 m² | 53% |

## What the generator does with irregular footprints (risk #2)

| Footprint | Rule | Result |
|---|---|---|
| Rectangle (≥ 90% of its minimum oriented bounding rectangle) | One roof over the oriented rectangle | Gabled or hipped per profile/OSM, ridge along the long axis |
| L, T, U, notched (≥ 85% of edges at right angles) | Split into up to 6 rectangles (grid split, largest-first); each gets its own roof; leftovers < 6 m² get flat slabs | Cross-gables/hips. Smaller wings have lower ridges because ridge height follows wing width. |
| Small notch (still ≥ 90% fill) | Treated as a rectangle | The eave overhangs the notch like a covered porch. Footprint positions are unchanged. |
| Roughly rectangular, not orthogonal (75–90% fill, ≤ 400 m²) | One roof over the bounding rectangle | May overhang the missing corner |
| Very small (< 12 m²: sheds, kiosks) | Flat slab roof, no windows | |
| Very large non-rectangular (> 400 m²) and anything else irregular, incl. courtyards | Flat roof with parapet + window grid | No pitched roof is guessed. This is the honest fallback. |
| Any shape | Windows per wall by length and stories, door/porch on the street-facing edge, garage door on the alley edge | Tested: no inside-out faces, no NaNs, deterministic per OSM ID |

Generated house details:
- **Facade:** front door with trim, porch with posts and roof (70% in the Front Range profile) or stoop + canopy, steps down from a raised foundation.
- **Openings:** windows with frames and a muntin.
- **Roof:** eave soffits and fascia, chimneys (45%).
- **Yard:** foundation bushes (some flowering).

## Simulator numbers (iPhone 17 Pro simulator, whole area B built)

| | Instanced props (default) | Merged props (comparison) |
|---|---:|---:|
| Triangles in scene | 493k (173k static + 320k props) | 493k |
| Grass tufts near camera | ~2,000 instances (~14 tris each) | same |
| Prop instances | 5,797 | 5,797 |
| Draw calls (all entities, before culling) | 108 | 91 |
| World mesh GPU memory | **15.7 MB** | **30.0 MB** |
| App memory footprint | 73–114 MB | 80–81 MB |
| Scene build time | 2.2 s (debug) | 2.5 s |

- **Instancing:** halves mesh memory. It costs about 17 more draw calls, because each (prop kind, variant, cell) is its own draw, while the merged path folds all kinds into one mesh per cell.
- **Visible draw calls:** per-chunk culling brings the visible count lower in street view.
- **iOS 26 vs 18:** nothing got worse. On iOS 18 instancing wasn't available, so the merged column is what iOS 18 would have used.

## On-device numbers (iPhone 14 Pro, iOS 26.4.2, Release build)

Detected over USB: iPhone 14 Pro (iPhone15,2), Developer Mode on, already paired.
Signing used the existing Apple Development certificate; the team ID is in git-ignored `.local/team_id`.

**10-minute walk loop** (`docs/perf/walk-10min/metrics.csv`, no Instruments attached, phone on USB power):

| Measure | Result |
|---|---|
| Duration | 614 s |
| Frame rate | 59.96 fps mean; lowest one-second average 59.2 fps; 0 seconds below 58 fps |
| Frame time | 16.68 ms mean; worst single frame 21.0 ms; 3 seconds contained a frame > 20 ms |
| Memory footprint | 308–334 MB, flat (no growth) |
| Thermal state | `fair` from t = 20 s (the phone was warm from earlier test runs) to the end; never `serious` or `critical` |
| Scene build on device | 0.4–0.8 s |

**GPU frame time** (Instruments Metal System Trace, `docs/perf/gpu-attribution.md`):
- Instruments records with the GPU **induced to its Minimum performance state**, even though Xcode's Device Conditions show none.
- At that lowest clock the GPU was busy **15.4 ms per frame** (p95 15.8 ms) and still held 60 fps.
- Switching off shadows, props, grass or the transparent foliage pipeline changed it by < 0.5 ms. At minimum clock, busy time fills the frame regardless.
- So there is **no valid normal-clock GPU number yet.**

## Pass/fail

| Criterion | Result |
|---|---|
| GPU ≤ 10 ms per frame | **Not verified.** The only GPU measurement available was at the forced minimum clock: 15.4 ms busy, a fail as measured. The frame still fits 60 fps at the lowest clock, so I expect a pass at normal clocks, but it's unproven. |
| No thermal throttling over 10 minutes | **Pass on iPhone 14 Pro:** 60 fps held for 614 s; thermal state `fair`, never `serious`. |

**iPhone 13 margin estimate:**
- The iPhone 13's A15 GPU (4-core) is roughly 25–35% slower than the A16 at full clocks.
- We know the A16 holds 60 fps even at its lowest GPU clock.
- But I can't convert "fits at minimum clock" into an iPhone 13 number without one valid normal-clock measurement. The margin is therefore **unknown, probably positive**.
- Two ways to settle it:
  - Record GPU time with Instruments' GUI with performance-state induction off.
  - Run the same walk on an iPhone 13.

## Honest read

**What looks wrong**
1. **Lighting is flat in shade.** Under the dense street-tree canopy the scene goes dark and green; there's no ambient occlusion or bounce light. The lawn is a uniform saturated green (soft noise helps only a little).
2. **Grass tufts read as realistic blades,** not chunky stylized tufts. They're too sparse in places and too "photo".
3. **Tree trunks** are still a bit thick and long. The lollipop canopies are fine from above but repetitive at street level (only 3 deciduous + 2 conifer shapes).
4. **The cut-away leaves a faint ghost outline** of the trunk edges, and its dither is blocky.
5. **Houses:** colors and porches vary, but the wall material is uniform (no brick or siding texture in the shader). Windows are dark slabs. Corner lots sometimes face the side street.
6. **Sky** is a plain gradient with no clouds. The sun glow in the skybox isn't verified to line up exactly with the light direction.
7. **Fog** is subtle at street level and only shows in the aerial view. There's no visible world edge yet because the whole area B is built, but the backdrop ring isn't built.
8. **The whole area B is drawn,** focus region at full detail and the rest simplified, so props total 320k triangles. Distance-based detail levels (next phase) will cut this.

**What I'd fix next**
1. Get one normal-clock GPU measurement (Instruments GUI, or an iPhone 13).
2. Find a workaround for custom post-processing (minimal repro, then Apple feedback).
3. Make the tufts stylized and more varied, add 2–3 more tree shapes, thin the trunks.
4. Add a cheap ambient-occlusion term (vertex AO at wall bases and under canopies) and warmer bounce light in the shader.
5. Add simple procedural brick/siding patterns in the shader (world-space stripes) and slightly reflective windows.
6. Handle corner lots: prefer the street the address is on (`addr:street`).

**What I couldn't do**
- **Color-grade post-process (optional item B.8):** not done. RealityKit traps when `customPostProcessing` is set, in both the Simulator and on the device.
- **In-app GPU timing:** not possible, because it depended on that same post-processing hook.
- **Valid normal-clock GPU numbers from the command line:** Instruments forces the minimum GPU state while recording.

## Process notes

These are for the record: none are product defects, but some cost device time.
- **10-minute run ended at 8 s:** an unretained RealityKit update subscription stopped per-frame updates after 8 s. Fixed by owning the subscription in `World`.
- **Run interrupted at about 4 minutes:** the phone went off the cable. Re-run cleanly with the phone untouched.
- **Toolchain:** the Metal Toolchain (Xcode component) had to be downloaded once, with approval, to compile the shaders.
