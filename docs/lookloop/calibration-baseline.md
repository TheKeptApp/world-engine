# Calibration v2 baseline: current main against style-b-calibration-v2

Measured 7 Oct 2026 by P3 on R's order ("score current main against style-b-calibration-v2 … and send the new baseline to 5A and P2"). Run `20261007-164728`, engine `debec74` (5A's daytime master follow-up; nothing since changed the engine), the four afternoon hero views. R approved style-b-calibration-v2 as binding on 2026-10-07: "packs own content; calibration owns look", and it replaces the old Lakeview street as the look-gate target (`docs/proposals/style-b-calibration-v2/STATUS.md`). This is the starting line for that target.

**How to read it.** The calibration frames are painted stills with their own camera and content, so the measurements compare the same *surface class* (sky, road, sidewalk, lawn, crowns) rather than the same pixels; judge direction and size, not the last decimal. Colour is CIE76 dE with the sign of the difference (`Tools/lookloop/calibration_colours.py`, boxes in `Tools/lookloop/calibration-regions.json`). Closeness is a Sonnet reviewer's 1–5 on look only (GRADING.md §M, "Calibration look"): it ignores layout, objects and wall hue, because the packs keep wall albedo. Wilmette has no frame of its own in the pack; the Chicago frame is its nearest regional look.

## Hero closeness (1–5, look only)

| View | vs frame | Closeness | Sky | Light | Saturation | Ground | Foliage | Materials |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| lakeview-street-afternoon | 01-lakeview | **3** | 3 | 3 | 3 | 3 | 3 | 4 |
| lakeview-postcard-afternoon | 01-lakeview | **3** | 3 | 2 | 3 | 3 | 2 | 3 |
| wilmette-street-afternoon | 01-lakeview | **3** | 3 | 2 | 3 | 3 | 2 | 3 |
| ordinary-street-afternoon | 06-sloans | **3** | 3 | 3 | 3 | 3 | 3 | 4 |
| **mean** | | **3.0** | 3.0 | **2.5** | 3.0 | 3.0 | **2.5** | 3.5 |

3 means "same lighting and palette family, visibly different". The weakest aspects are **light** (shadows) and **foliage**.

## Surface colour against the calibration frames

dE per surface (newest run, with the 16:13 run after the arrow), and the direction of the miss as engine minus calibration in Lab (dL lighter +, da greener −, db yellower +):

| Surface | dE 16:47 ← 16:13 | dL | da | db | Reading |
|---|---|---:|---:|---:|---|
| sky (4 views) | 14.5 ← 13.5 | −1 | **−11** | **+9** | engine sky is cyan (hue about 197–200); the frames are periwinkle (#77B0ED, #7CADDB, hue about 210) |
| road (3) | 10.7 ← 7.0 | +6 | −5 | +6 | lighter and teal-grey; the frames are violet-slate (#6A7182) |
| sidewalk (4) | 15.0 ← 17.3 | **+13** | −6 | −2 | near-white neutral (#E6E3D8); the frames are warm peach-cream (#CAB7AC in shade-mixed pixels, about #ECD0B8 sunlit) |
| lawn (3) | 19.0 ← 21.6 | **+13** | **−13** | +3 | pale mint-green; the frames are olive (#717842) |
| crowns (3) | 19.6 ← 20.2 | +8 (postcard +27, Wilmette −11) | −8 | +9 | postcard crowns far too light, Wilmette far too dark and saturated |

Per view (16:47): Lakeview street sky 18.2, road 13.7, sidewalk 15.7, parkway lawn 23.2, crowns 11.3 · postcard sky 14.5, road 10.8, sidewalk 14.4, lawn 17.9, crowns 32.0 · Wilmette sky 14.3, road 7.7, sidewalk 15.3, lawn 15.8, crowns 15.6 · Denver sky 11.1, path 14.6.

**One pattern runs through all of it:** every surface sits 5–13 units too far toward green on a* (sky −11, lawn −13, sidewalk −6, crowns −8, road −5), and most sit lighter. The frames carry a warm/magenta cast the engine's grade does not. That points at the global grade (5A) before any single albedo.

**Where the old heroes and the calibration disagree.** debec74 pulled the road toward the old house-contrast hero (road dE to those mocks 9.7 → 5.7), and against the calibration the same road got worse (7.0 → 10.7): the hero road is neutral grey (#7B7E7F), the calibration road is violet-slate (#6A7182). Sky likewise: 12.8 → 11.9 against the heroes, 13.5 → 14.5 against the calibration. By R's rule the calibration wins on look; the heroes keep their cameras and content.

## The gaps, most important first, and who owns them

All four reviewers independently named the same three, in this order.

1. **Shadows (5A).** Too deep and too blue: shade is about 0.26–0.33 of lit luminance (road tree shadow #335064 against lit #798488 on the postcard; #2C485C on Wilmette and Denver), where the pack's own witness is 0.62 (`shadows.neutralWitnessShadowToLitLinearY`) and its shade colour is a soft slate-lilac (#7F8F99, `appearanceHex`). There is no warm-key / cool-shade split. On Denver the building shadow on the lawn ramps over about 110 px (19 % of frame height) against about 10 px in the frame. Reviewer pixel samples, approximate.
2. **Sky (5A).** Cyan-leaning and darker at the zenith (#3DA3D2–#5AACD4) against periwinkle (#70ACED–#79B2EE); clouds are flat grey polygons against warm-lit cumulus; the far end stays crisp instead of fading to warm haze. (The stops in `style-b/look` were sampled from these frames: zenith #7AAFE2, mid #8FBAE7, horizon #A0C8F2, see `Tools/lookloop/mock-corrections.json`.)
3. **Foliage (P2 shape and colour, 5A shade).** Crowns are smooth two-tone balls: shaded sides go deep cool green or near-black saturated (#275729, #0B2300; blue channel at 0) where the frames have a warm olive shade (#4F5A35, hue about 78), and there are no sunlit lime-yellow tips (value up to 0.76 in the frames).
4. **Ground (5A grade, P2 albedo).** Lawn too vivid and light (Denver lawn is 45 % of the frame, chroma 38–46 against 26 for the sage-olive #73865B); sidewalk too neutral and too light; road teal-grey instead of violet-slate. The pack's own ground bases (asphalt #626A70, concrete #C5C0B3, lawn #73865B) are what the engine is configured with (conformance passes on them); the lit result ends 13 L\* above the frames on sidewalk and lawn, so the sun or the exposure gain lifts them more than the paintings do (the pack says its numbers are authoring targets, not sampled pixels; images beat JSON).
5. **Materials are already close** (3.5 of 5): matte, no gloss.

## Walls (reference only)

The packs own wall albedo, so walls are not part of the look score. Measured separately (`Tools/lookloop/wall_variants.py`): in three of the four views the wall in the measuring box faces away from the sun, so the engine's lit colour there is shade against a mock that paints it lit. Lakeview street: way/210329013 (3-storey block, albedo #A57450) in shade, lit #8B5827; postcard: chicago-02-flats variant 1 (#92513E, the darkest of four) mostly in shade, lit #671B00-#672D1F, while a sunlit variant 0 (#98664F) reads #BC7343, 14 dE from the calibration brick (#C08964); Wilmette: overture/193d2ed4 tan siding (#AD9274) faces the sun, lit #C1935E = albedo × sun colour (#FFE8C6) × 1.28, so the grade is as designed and the 33.8 dE to the hero mock's grey-green siding is albedo hue; Denver: denver-05-split variant 3 (#C8BBA0) in shade at 0.38 of albedo, neutral. Details went to P2 on 7 Oct.

## Run history against the calibration

| Run | Engine | Look gate | Closeness (street, postcard, Wilmette, Denver) | Aspect means (sky, light, sat, ground, foliage, materials) | dE sky / road / sidewalk / lawn / crowns |
|---|---|---|---|---|---|
| 16:47 baseline | `debec74` | not yet a gate | 3, 3, 3, 3 | 3.0, 2.5, 3.0, 3.0, 2.5, 3.5 | 14.5 / 10.7 / 15.0 / 19.0 / 19.6 |
| 18:49 (P2 wall weights) | `c49ecb0` | **FAIL 0 of 4** (approved gate) | 3, 3, 3, 3 | 3.0, 2.8, 2.8, 2.8, 2.8, 3.5 | 14.4 / 10.4 / 14.9 / 18.7 / 19.2 |

On the 18:49 run the weakest aspects were light and foliage on the postcard and saturation and ground on Wilmette. The Wilmette frame is pixel-identical to the baseline, yet its low aspects flipped, so one aspect point on one view is inside the grader's about +/-1 noise: read the gate across runs, and expect a routine PASS to need R's Opus confirmation.

## Look gate (R approved 2026-10-07)

All four heroes at calibration closeness 4 or more and every aspect 3 or more. It replaces the old concept-parity gate (still reported beside it); a routine PASS triggers one Opus confirmation run (R, 2026-10-08). The mean surface-distance figures (sky, road, sidewalk at most 10; lawn and crowns at most 12) are P3's reading aid, not part of the gate. From the baseline that means closeness 3.0 to 4 (+1) and light and foliage 2.5 to 3.

## Limits of this baseline

- One run, four views, one grader model (Sonnet; closeness scores carry the grader noise measured in GRADING.md §N, up to about ±1 on a 1–5 score). The dE figures are deterministic for a given frame; the closeness is not.
- The calibration frames are generated paintings, and the surface boxes sit on different geometry in each image (a surface-class comparison). Road and sidewalk boxes include cast shadows in both images.
- Shadow ratios and per-surface hexes quoted from the reviewers were sampled by them from the frames and are approximate.
- Frames are Simulator captures; use the figures for change between runs, not as device performance.
