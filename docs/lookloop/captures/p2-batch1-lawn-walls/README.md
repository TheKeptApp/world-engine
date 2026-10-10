# P2 Batch 1: lawn spread, gray houses, grade attribution (9 Oct 2026)

Two generator rules, both **default off** and region-independent, plus an attribution report. No shader, grade, exposure, palette table or renderer file is touched. Map data © OpenStreetMap contributors.

Flags are capture only: `-lookexp lawnsmooth` / `-lookexp wallspread` (`Sources/WorldGen/LookExperiments.swift`). The app logs `LOOKEXP active=…` and `scripts/capture_native.py --lookexp` checks that line. `Tools/lookloop/batch.py` now passes `-lookexp` as a launch argument, because it shapes the world at load.

## Frames for A3

There are six views on the Batch 0 cameras ([p2-native-ladder-b0](../p2-native-ladder-b0/README.md)): Sloan's and Lakeview at 40, 150 and 600 m. Exposure is pinned at gain 1.0, the sky is clear, wind is 0 and there is no character.

Each view has four frames:
- `VIEW-off.png`
- `VIEW-lawnsmooth.png`
- `VIEW-wallspread.png`
- `VIEW-off-control.png`, a byte copy of the OFF frame, for the identical-image control pair.

Pairs, hashes and observed flags are in [manifest.json](manifest.json). The phone-size comparison with the mock is [side-by-side-phone.png](side-by-side-phone.png).

**Controls.** Main triangles and draws are identical in all 18 frames: 312,880/53, 333,744/50, 228,013/43, 295,759/56, 271,763/48 and 194,160/35. OFF against main (Batch 0):
- Byte-identical: Sloan's 40 and Lakeview 40/150/600.
- Sloan's 150 m: at most 1/255 (36 bytes).
- Sloan's 600 m: at most **2/255** (316 bytes, mean 1.9e-4). That is the known 600 m repeat noise (5A), not "within 1/255".

## 1. Lawn spread (`lawnsmooth`)

**Variant chosen: a smooth field, not halved steps.** Shade and tone come from one low-frequency field (seeded value noise, 60 m wavelength), evaluated at every lawn vertex. Its amplitude is half the lot range: shade 0.92–1.07 → 0.958–1.033, and tone 0–1 → 0.25–0.75.

Why this variant: the "pasted rectangles" are edges where neighbouring lots differ by one or two steps. The current step colouring forces neighbours to differ. Halving the steps would keep those edges, only weaker. A field evaluated per vertex has no lot edges at all. Patches, mowing, pools and wear stay as they are.

Generator measurement (tests, neighbouring lots):

| Area | Mean neighbour Δshade | Mean neighbour Δtone |
|---|---|---|
| Sloan's | 0.067 → 0.020 | 0.42 → 0.04 |
| Lakeview | 0.063 → 0.017 | 0.40 → 0.05 |

Rendered lawn L* p10–p90:
- Sloan's 40 m: 47–70 → 46–62. Sloan's 150 m: 52–68 → 53–62.
- Lakeview 40 m: 49–62 → 50–62. Lakeview 150 m: 53–63 → 51–63.

Adjacent 12-px lawn blocks differing by more than ΔL* 4:
- Sloan's: 23% → 21% at 40 m, 38% → 33% at 150 m.
- Lakeview: 12% → 10% at 40 m, 32% → 22% at 150 m.

**Gap:** crown shadows and contact pools dominate what is left of the frame contrast, so the rendered change is smaller than the generator change.

## 2. Gray houses (`wallspread`)

Measured against style-b-calibration-v2 `06-sloans` (house band, median per patch) and native Sloan's at 40 m:

| | Mock | Native |
|---|---|---|
| Lit walls L* | 57–77 (range ≈20) | 61–65 (range 4) |
| Walls C* | 3–21 | 1–14 |
| Walls hue | warm 30–63° (peach/rose/tan) | yellow-gray 83–115° |
| Roofs L* | 36–40 | 41–49 |
| Roofs C* | 12–18 | 3–12 |
| Roofs hue | slate ≈275° | warm-gray, mixed |

Rule built: unmapped house/block walls take an extra value factor of 0.82–1.22. It is stable per building (`OSMRef.random("wall-value")`, never per run); mapped `building:colour` walls are untouched. It changes no table and no geometry.

Result: Sloan's lit-wall L* range 4 → 9 (sd 2.1 → 4.1). Lakeview's range was already 20 (sd 6.5 → 7.0).

**Gap, stopped as instructed:**
- The hue and chroma gap cannot be closed without a table change: walls need warmer variants, roofs need darker slate. That is house-families / front-range colour tuples and archetype variant weights, not a generator rule.
- The rule also scales approved archetype wall values by up to ±20% in value (not hue).

## 3. Grade attribution: #9F390C red on native, orange on web

The stage responsible is **exposure and the tone curve**, not saturation or contrast.

- Web lifts luminance by `linearGain/0.6` through an ACES fit before its grade. That is `web/bakeoff/main.js` post `outputNode` (lines 165–168: `x=sourceY.mul(L.exposure.linearGain/.6)`, `mappedY=…`).
- Native capture applies pinned gain 1.0 to the soft curve. That is `Sources/WorldEngine/PostProcess.swift` `composite` / `toneOf`, with `g = state^2.2 × lookGain`. The master's +0.35 EV is faded out of `gradeLook.exposureEV` in `Environment.swift`; on device it is realised by auto exposure, which the pinned capture replaces with 1.0.

Simulated with the same input radiance:
- Native and web keep about the same Lab hue (46–47°), but web is about 8 L* lighter and about 13 C* more chromatic. The same hue at lower lightness reads red.
- Putting web's tone stage into the native chain gives #D94300, against web's #DD3B00.
- Removing native's linear saturation or contrast changes the hue by less than 3°.

Owners: 5A (native exposure for captures) and A2 (web gain). No change made.

Used: restart-P2.md; Batch 0 README; ground-trial-paired-scores.md (OFF preferred, lot rectangles); palette-diagnosis.md roof/wall inventory; house-contrast-v1 sharedLighting.exposure (linearGain, saturationFactor, contrastSlope). Mock: style-b-calibration-v2 frames/06-sloans.png (house band). Deviation: wall value factor range 0.82–1.22 is P2's choice (no mock key defines wall spread); hue/roof gap needs a table change, not built.
