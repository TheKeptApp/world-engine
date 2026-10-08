# Look-loop grading procedure

A reviewer sub-agent follows these steps to score **one view**. The `/lookloop` skill spawns one reviewer per changed view, all in parallel, from the prompts in `<run>/reviewers.md`.

Reviewer models:
- **Sonnet** for routine runs.
- **Opus** for declared gate runs and for calibration.

Every reviewer works the same way, so scores are comparable run to run. When the grader model changes between two runs, read the regression guard with that in mind.

Sources (read-only): visual-v2 §8.3 rubric (`docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md`), experience-v1 §2 per-image guidance, regions-chicagoland-miami §3, §5, §6 and §14, and the owner's art direction (Phase 5 and P3 prompts).

## S. Style target (R decision, 6 Oct 2026; docs/decisions/style-target.md)

The look target is **rich stylized**: simplified geometry, material hints, varied lawns, haze, wet/dry surface response. It is photoreal only in colour, light, atmosphere and weather. This section outranks any reading of the anchors that rewards photo detail.

1. **Photoreal concepts.** When a target concept is more photoreal than this target, grade the capture's light, colour, atmosphere and weather against it fully. Do not lower any score for missing photo-like detail: individual bricks, shingles, grass blades, leaf-level foliage, photo textures, realistic cars or street clutter.
2. **Detail criteria at the stylized bar.** For `silhouettes`, `softnessAO`, `groundRichness`, `houseVariety` and `adGroundRich`, the 5 anchor is met by clear stylized forms and material hints that read at phone size (lawn tone variation, beds and shrubs as simple masses, roof and crown families). Fine surface detail adds nothing.
3. **Weights.** Colour, light and atmosphere count more than surface detail: `palette`, `light` and `depthFog` weigh 1.5 in `v2Score50` (section E). Weather is judged in `adRainReadable` and in those three.
4. **Style anchors.** Three concepts set colour and mood for every view and weigh highest when judging `palette`, `light` and `depthFog`:
   - `docs/proposals/regions-chicagoland-miami/images/03-northshore-fall.png` (fall)
   - `docs/proposals/regions-chicagoland-miami/images/04-northshore-snow.png` (winter)
   - `docs/proposals/regions-chicagoland-miami/images/06-chicago-alley-snow.png` ("very Chicago")

   Open the anchor nearest the view's season and mood alongside its own targets. Where a view's own target and an anchor disagree on colour or mood, follow the anchor; for layout, geography and time of day, follow the view's own target and data.

## V. Vegetation reference (owner, 6 Oct 2026; docs/proposals/vegetation-v1/)

Trees and shrubs are judged against the vegetation-v1 pack (style B, rich stylized). Read its README "Crown construction", "Four seasons and weather" and "Shrubs, hedges and beds" sections once per run; open the sheet for the view's region (`images/01-north-shore-chicago.png` for North Shore and Lakeview, `images/02-denver.png` for Sloan's Lake) and `images/04-crown-construction.png` when a tree is near the camera. The pack's numeric rules and exact JSON/SVG colours outrank its raster images; its fine leaf scalloping, bark grooves and grass texture are not requirements (section S).

Apply it to these criteria:

- **`silhouettes` (trees):** crowns read as unequal, merged masses around a branch skeleton with the family's sky-hole openness (oak, elm and honey locust visibly open; maple and linden mostly closed; spruce in staggered tiers). Score down for lollipops (one ball on a pole), stacked spheres, identical repeated crowns, uniform scallops or one flat green blob. At aerial scale, families should still differ by silhouette.
- **`palette` (vegetation colour):** foliage matches the season and region in `vegetation-colours.json` (`trees[].seasons`, `shrubs[]`): differentiated autumn (russet oak, orange-red maple, yellow elm/linden/honey locust in Chicago; gold cottonwood/ash/aspen in Denver), bare deciduous crowns in winter with evergreens kept green, and golden-hour warmth from the light rather than baked into foliage (a green tree at golden hour must not read as autumn). Judge by eye against the pack's swatches; small hue/value spread is expected.
- **`softnessAO` (trunk base and contact):** a restrained darkening (about 10–20 %) around each trunk base and under shrubs, no black ring, no floating trunk; gentle occlusion where crown masses meet, not dark outlines on every lobe. A cast crown shadow is separate from contact darkening.
- **`adGroundRich` (shrubs, hedges, beds):** foundation shrubs as 3–5 merged lobes, hedges as one continuous envelope with an irregular crest (never a string of identical balls), beds as 2–3 islands with visible mulch or gravel.
- **look-fix `LF-trees`:** fails on any of the silhouette faults above or a wrong-season crown.

Snow on trees is a weather overlay on upward-facing boughs, never white foliage or an opaque snowball crown; score it under `palette` and `adRainReadable` when wet.

## M. Approved mocks are the target (owner, 7 Oct 2026)

Packs R approved in ChatGPT are the exact visual direction (`docs/proposals/INDEX.md`, status "R approved – binding target"). Where a view has a matching approved mock (same feature area and, as far as possible, the same region, season, weather and time of day), it is listed in the view's targets with a label starting "approved mock". Grade the frame as usual, then compare it with that mock and add to the JSON:

```json
"mockGap": {"mock": "docs/proposals/<pack>/images/<file>", "closeness": 1-5, "gaps": ["what still separates the frame from the mock, most important first (max 3)"]}
```

`closeness` is how near the frame is to the mock in what the mock is about (5 = indistinguishable at phone size in that feature, 1 = the feature is missing). Geometry, camera and object inventory still come from the capture; judge the mock's look (colour, light, materials, weather, vegetation, density), not its exact layout. A view without a matching approved mock omits `mockGap`. The report lists the gap per view next to concept parity.

**Merge gate (owner, 7 Oct 2026):** every visual merge is scored on closeness to its mock on the views it targets. P3 flags any merge that does not raise mean `closeness` on those views, or that arrives without the pre-merge phone-size side-by-side (render vs mock, values used, remaining gaps) that CLAUDE.md requires.

**Matched conditions (owner, 7 Oct 2026):** closeness is scored only on a view captured at the mock's own time of day and weather (`mockConditions` in `Tools/lookloop/views.json`). house-contrast-v1 heroes are clear mid-afternoon (sun 40°, azimuth 225°), so `lakeview-street`, `lakeview-postcard`, `wilmette-street` and `ordinary-street` have `-afternoon` twins that carry the mock; the golden-hour originals are scored on parity only. night-fog-v1 was painted over the `showcase-01`, `lakeview-street` and `wilmette-street` cameras, so each has `-blue-hour`, `-night` and `-morning-fog` twins on that camera. lake-winter-v1 mocks stay on the winter views already in their states. rain-v1 is pre-rule (R to confirm): its conditions are recorded as `mockPending` and get no closeness score until R approves it.

**House archetypes (R approved 2026-10-07, house-archetypes-v1):** views with an `archetypeMock` (the Chicago block paint-over on `lakeview-postcard-afternoon` and `lakeview-street-afternoon`, the Denver one on `ordinary-street-afternoon`) also get `"archetypeGap"` with the mockGap shape, judged on houses only (forms, materials, palette variety, porches, garages, yards), not lighting. Miami targets are registered on the inactive `miami-street` entry until a Miami test area exists.

**Infrastructure (R approved 2026-10-07, infrastructure-kit-v1, all 48 sheets):** the four afternoon hero views carry `infraSheets` (road sheets: arterial, residential, markings, crosswalks) and reviewers add `"infraGap"` with the mockGap shape, judged on road look only (lane markings, crosswalks, curbs, paving colours and materials), never on widths: `street-geometry-rules-v1` owns street geometry (R, 2026-10-07). Baseline before P2's markings stage: expect 1.

**Calibration look (R approved 2026-10-07, style-b-calibration-v2, binding; "packs own content; calibration owns look"; R: it replaces the old Lakeview street as the look-gate target):** the four afternoon heroes carry a `calibration` frame (`lakeview-street-afternoon`, `lakeview-postcard-afternoon` and `wilmette-street-afternoon` against `frames/01-lakeview.png`, `ordinary-street-afternoon` against `frames/06-sloans.png`; the pack has no Wilmette frame, so the Chicago frame is the nearest regional look). The reviewer adds `"calGap"` with the shape of `mockGap` plus `"aspects": {"sky", "light", "saturation", "ground", "foliage", "materials"}`, each 1-5. The frame is a painted still with its own camera and content, and the packs keep wall and roof hue, so judge look only (sky, light direction and softness, shadow colour and depth, saturation, ground colours and surfaces, foliage colour and shading, matte materials), never layout, objects or wall hue. `finish` reports it beside the gate. **LOOK GATE (R approved 2026-10-07; replaces the old concept-parity gate):** pass = all four heroes at calibration closeness 4 or more **and** every aspect (sky, light, saturation, ground, foliage, materials) 3 or more on every hero. `finish` prints "Look gate: PASS / FAIL / NOT EVALUATED" at the top of the summary (NOT EVALUATED when a calibrated hero has no `calGap`) and puts the result in the scoreboard row. Concept parity, the old per-view gate and the 5B gate are still computed and reported beside it, but they no longer decide pass or fail. The full Opus `--gate` run now starts when a routine Sonnet run passes the look gate (R confirmed 2026-10-08), and the gate counts as passed only when the Opus run agrees. Surface colours against the frames: `Tools/lookloop/calibration_colours.py`; which wall and variant is behind a hero's walls and whether it faces the sun: `Tools/lookloop/wall_variants.py`. Baseline: `docs/lookloop/calibration-baseline.md`.

## P. Paint-over targets (owner, 6 Oct 2026; docs/proposals/paintover-v1/)

Six views have a ChatGPT paint-over of their own camera: `ordinary-street`, `evanston-street`, `showcase-03`, `showcase-06`, `v2-06` and `lakeview-street`. The paint-over is listed as the view's last target. It is the closest thing to an exact appearance target: it starts from the same capture, so compare like for like (crown shading, ground families, contact pockets, wet sheen, sky, haze) and name in the fixes what still separates the frame from it. The pack's README and `paintover-values.json` give the authored values per view.

Limits, from the pack: the capture's camera, roads, footprints, shoreline and object inventory govern geometry; the paint-over's small silhouette, window and leaf differences are not targets; the rain puddle in `showcase-03`'s paint-over keeps a slightly rimmed edge that is a known artefact (the target is a flush sky reflection). Generated grain is not a texture requirement (section S still applies).

Scoring does not change: grade the frame against GRADING.md as usual. `finish` also reports **paint-over parity** = the view's /50 ÷ the paint-over's own blind /50 (calibrated by Opus, `calibrate.py --paintover`), beside the gate and never part of it. Concept parity stays the gate. Paint-over parity uses the same Opus calibration as concept parity, so Sonnet routine runs read it high (calibration.md); use it for change between runs.

## N. Grader noise and what counts as a real change — PROPOSED (owner decides; measured 7 Oct 2026)

**Measured, no new grading:** routine Sonnet grades of views a merge could not reach, across three consecutive-run pairs (house details 1/3 on non-North-Shore views, house details 2/3 on non-Lakeview views, 5A wet paving and overcast clouds on dry clear views): 63 view pairs. The change in a view's parity between two runs had a standard deviation of 4.2 points (about 2.9 points of noise in a single grade); 90 % of changes were within 6 points and 95 % within 8; 20 of 63 moved by more than 3 points; the largest were 15 and 12 (showcase-10, the noisiest view: −15 then +12). The mean shift across the untouched views of one pair ranged from −1.2 to +1.7 points; the full-set mean parity moved within 80.3–82.1 % over seven runs in which most merges had no measurable effect.

**Proposed rule:**
1. A single view counts as a real change only if it moves **more than 8 parity points**, or more than 5 points in the same direction in **two consecutive runs**, **and** the reviewer's reasons change in a way the merge could cause.
2. The mean counts as real only if it moves **more than 2 points on the full set** (29 views) or **more than 2.5 points on the core set** (13 views; mean noise ≈ 4.2/√13 ≈ 1.2).
3. A change concentrated in the views the merge targets (for example a region's views) counts at **more than 4 points** on that group's mean, again with matching reviewer reasons (the Sloan's Lake lemon-yellow regression and its fix both met this).
4. The current "> 3 points" regression flag stays as a list to re-check, not as a finding: about a third of untouched views cross it by chance.
5. **A view whose frame did not change cannot count at all** (PROPOSED addition, 7 Oct 2026). The renderer is deterministic enough that an unreached view gives the same frame twice (under 0.5 % of pixels differ by more than 12 levels; measured 0.0-0.05 % for unchanged views and 1 % and up for changed ones). Control measured on the 10:12 to 11:45 pair (P2 house gaps, which touched only Lakeview and one Denver view): 12 of 17 frames unchanged, and their parity moved by −3.1 on average over the 9 with a parity (v2-06 −12, showcase-06 −8, wilmette-street −6, showcase-01 +4; /50 mean −1.1, range −4.2 to +1.1). On the pair before (09:15 to 10:12) the same unchanged views moved v2-06 +12, wilmette-street +3, wilmette-aerial −3.2 /50. v2-06 read 23.2, 27.4, 23.2 on three runs of the same render, so a single-run move of 8 parity points is not safe on the aerials and showcase-06. `finish.py` now labels flags on views whose frame did not change as grader variance, lists them apart and leaves them out of the flag count.

**Core set (owner, 7 Oct 2026):** each merge is scored with Sonnet on the 13 views marked `core` in `Tools/lookloop/views.json` (`lookloop.sh run --core`): ordinary-street, evanston-street, evanston-street-rain, wilmette-street, wilmette-street-fall, wilmette-aerial, lakeview-street, lakeview-postcard, showcase-01, showcase-03, showcase-06, v2-01, v2-06 (all six paint-over views, the three regions, rain, smoke, fall and two aerials). The full set runs only for gate checks. Since 7 Oct 2026 (afternoon capture) the core set also holds four `-afternoon` twins of the hero views for §M closeness (17 views); they have no parity, so core mean parity is still taken over the 13 parity views (12 with a calibrated concept). Core runs are compared with core views of the previous run, never with full-set means.

## Inputs

For view `<id>` in run directory `<run>`:

| File | What it is |
|---|---|
| `<run>/sheets/<id>.jpg` | Contact sheet: target concept image(s) (blue), current capture (yellow), previous run (grey), luma histogram and numbers |
| `<run>/frames/<id>.jpg` | Current capture at full phone width (1206 px, 16:9). Use it to inspect detail |
| target PNG(s) | Paths in the view entry. Open them when the sheet is too small to judge |
| `Tools/lookloop/views.json` (or the manifest named in your prompt, such as `calibration.json`) | The view entry: time, weather, season, character, `wet`, `na`, camera, sun, targets (may be empty) |
| `<run>/signals.json` | Objective signals for `<id>`: histograms vs target and previous, triangles, Simulator frame time. The `perf` counters are whole-world totals: they never prove what is or isn't visible. Judge visibility from the pixels only |

## Steps

1. Read the view entry in the manifest and its `signals.json` entry.
2. Look at the sheet. Then look at the full-size current frame, and at a target PNG wherever detail matters.
3. Score the ten v2 §8.3 criteria (table A), each as an integer 1–5.
   - 2 and 4 interpolate between the anchors.
   - Write `null` for criteria in the view's `na` list:
     - 6 when no character is in frame.
     - 10 always for stills, because motion needs video.
   - Give one short reason per score that names what you saw.
4. Score the three art-direction criteria (table B), 1–5, or `null` where marked not applicable.
5. Apply the style target (section S), the vegetation reference (section V), the paint-over target where the view has one (section P) and the strictness rules (section C). They outrank any instinct to be kind.
6. List hard-gate flags (section D) that you can actually see. Do not guess.
7. Compute the totals (section E).
8. Run the look-fix-v1 checks (section H).
9. Write the top 3 fixes (section F).
10. Write the result JSON (section G) to `<run>/grades/<id>.json`. If no file path or Write tool is available, output only the JSON instead (the headless runner saves it).

## A. Visual-v2 §8.3 criteria

The anchors and the Reference column are verbatim from v2 §8.3.

**Using the references (calibration rule, added 6 Oct 2026).** v2 §8.3 names the concept images that illustrate the 5 anchor for each criterion. The anchors are absolute, but the references set the scale:
- A frame that reaches the quality the reference images show on a criterion scores **4–5**: 5 when it also meets every specific in the 5 anchor, 4 otherwise.
- The references' own documented limitations are not part of that quality. These are the enlarged dog, the oversized sun disk, invented parcels, the misplaced Moon and wrong shadow bearings. Score them as faults wherever they appear.
- Use **3** when a frame is clearly below the references but meets the 3 anchor.
- Without this rule, the concept images themselves averaged 33.9/50 (docs/lookloop/calibration.md), so a 5 was effectively unreachable.

| # | Key | 1 — fails | 3 — baseline acceptable | 5 — target excellence | Reference (visual-v2 images) |
|---|---|---|---|---|---|
| 1 | `silhouettes` | Box roofs, identical crowns; types merge | Roof/crown families readable but repetitive | Clear bungalow/foursquare/modern profiles; distinct tree archetypes and stable LOD outline | 01, 07, 09 |
| 2 | `palette` | Candy noise, pure-black holes, clipped snow | Coherent families, modest weather variation | Restrained base relationships survive noon, rain, snow and night without losing coat colors | 02–05, 08 |
| 3 | `light` | Everything orange, contradictory key/shadows | Warm hero, neutral noon, cool readable night | Warm/cool balance with one coherent sun; no double tint; morning/evening distinct | 01, 02, 04, 05; numeric sun fixtures |
| 4 | `softnessAO` | Floating steps/shrubs or black dirty seams | Basic contact and soft shadows | Subtle eave/porch/crown/base occlusion and bevel glints; no burned-in directional shading | 04, 07 |
| 5 | `groundRichness` | Flat sterile carpet or noisy blade forest | Some seams and edge clusters | Low-frequency variation, sparse rule-based leaves, credible wet streaks/patchy snow, quiet route center | 01–04, 09 |
| 6 | `characterReadability` | Dog disappears, floats, glows or fills half screen | Recognizable common coat on path | Coat stays readable over each difficult surface, contact intact, 20–25% framing | 08 plus 02/03/04; bounds gate overrides art oversizing |
| 7 | `depthFog` | Missing edge, flat distance, heavy blur wall | Useful atmospheric separation | Lake/shore/backdrop continuous; low horizon depth, no fog discontinuity, aerial sharp center | 01, 03, 06 |
| 8 | `houseVariety` | Every facade random or identical | Several believable kit families | Footprint-appropriate mass, stable openings/entry/access, garage/alley relationships and modern/old mix | 07, 09 |
| 9 | `geography` | Moved paths, fake shoreline, skyline/sun wrong bearing | Broad map correct but a few unverified details | Map overlay agrees; shadow bearing and backdrop azimuth verified; honest gaps, no invented parcel access | 06, 09 plus actual data map and presets |
| 10 | `motion` | Popping LODs, swimming masks, flickering cutaways | Stable ordinary walking with occasional transitions | Ten-minute walk feels continuous (video only) | Captured engine video; still art cannot pass |

Notes:

- **Geography (9).** Each view entry carries `camera` (heading, pitch, FOV) and `sun` (elevation, azimuth, shadow bearing). Check the lit side of trunks and walls and the direction of cast shadows against them, relative to the camera heading. Quick reads:
  - v2 street faces west (270°). At golden hour the sun is ahead-left and shadows fall toward the camera and right.
  - The showcase street faces ESE (100°). The sun is behind or right, and no sunset disk or western mountains should appear.
  - The Sloan's Lake aerials (v2-06, showcase 10/11) face north with no horizon. Region obliques use their own named camera; always take the heading from the view's `camera` field.
  - If shadows are too soft or absent to judge the bearing (overcast, fog, rain, night), score geography on paths, shoreline and layout alone, and say so.
  - Score from what is visible; you have no map overlay:
    - **5:** the shadow bearing is checked and correct, and the layout clearly matches the camera notes (for example lake side, street direction, backdrop azimuth).
    - **4:** nothing visible contradicts the camera, sun or known layout, even if some details can't be verified from pixels.
    - **3:** something is doubtful but not clearly wrong.
    - **2 or below:** a visible contradiction, such as a shadow or sun on the wrong side, mountains in an east-facing frame, or a backdrop at the wrong azimuth.
  - "Can't verify against the map" alone is never a reason to go below 4.
- **Houses (8).** On views where no house is visible (lake trail), score what is visible in the distance. If nothing is, score 3 and say so.
- **Character (6).** Framing is 20–25 % of frame height. The concept images enlarge the dog to about 40 %. Do not reward copying that.

## B. Art-direction criteria

These come from the owner and are scored like §8.3.

| Key | 1 | 3 | 5 | Applies |
|---|---|---|---|---|
| `adGroundRich` — rich ground | One flat lawn colour everywhere, no shrubs or beds, hard grass/path edges | Some lawn colour variation, a few shrubs or edge clusters | Varied lawns (patches, worn edges, shade tone), shrubs at foundations and fences, planting beds, leaf litter under real crowns, all calm at phone size | Always |
| `adRainReadable` — readable rain | No visible difference from a dry day | Darker wet ground and some sheen | Wet sheen on roads and paths, puddles in low spots that reflect sky, darker grass, restrained streaks, rain readable at a glance without heavy particles | Only when `wet` is true. Otherwise `null` |
| `adRegional` — regional signature | Generic anywhere-town, or details from the wrong region | Some regional cues (house families, tree mix, backdrop) | The place reads as itself: Front Range Denver for Sloan's Lake (bungalows/foursquares, cottonwoods and conifers, low western mountain band only where the camera faces west); North Shore and Lakeview cues per regions §3/§5 | Always. For aerials, judge the land-use pattern |

## C. Strictness rules (binding)

1. **Ordinary days and light rain are graded as hard as snow and fall.**
   - A clear afternoon, an overcast noon or light rain gets no leniency for being "just a normal day". Ordinary weather is what users see most.
   - If an ordinary view looks flat, sterile or empty, score it that way, even if dramatic states look good.
2. **Anchors, not effort.** Score what is on screen against the anchors. Do not score against progress, intent, or what the code is supposed to do.
3. **Targets are qualitative.** Numbers, map data and sun position outrank the concept art.
   - Do not penalize the capture for differing from listed target errors: the enlarged dog, oversized sun disk, invented houses, mountains in an east-facing frame, mis-placed Moon in 09.
   - Do penalize it for missing what the target does right: richness, softness, palette restraint, weather readability.
4. **look-fix-v1 references** are labelled "appearance reference; not calibrated".
   - They show intent for ground, light, weather, aerial edges and sky.
   - Per the pack's VALIDATION.md, the numbers and true astronomy govern over these images.
   - They never set parity. Parity uses only the first (calibrated) target.
   - Do not reward copying their invented details or sun and moon positions.
5. **Phone size.** The final read is at phone size, so judge the frame as a whole first. Use the full-size frame to confirm a defect, not to hunt for sub-pixel issues.
6. **Broken captures.**
   - If the frame is black, shows UI or error text, or is clearly not the requested view, set every applicable score to 1.
   - Add hard-gate flag `capture-failed` and explain.
7. **Previous run.** Note in `vsPrevious` whether the view got better, worse or is unchanged, and how.
   - The previous run never changes the scores. Scores are absolute against the anchors.
8. **One decimal of honesty.** If you cannot tell (for example a detail is too small), say so in the reason. Do not inflate.

## D. Hard-gate flags

Report only what you can see. Use these ids:

- `wrong-sun-bearing`
- `horizon-in-steep-aerial`
- `moved-geography`
- `authored-surface-imagery` (photo textures or painted ground)
- `full-surface-reflection` (mirror-lake or mirror-road)
- `osm-credit-missing` ("© OpenStreetMap contributors" must be visible). Exception: batched runs use WorldLab's in-app view captures, which contain no UI (the run's `run.json` `frameSource` says so). For those frames, do not raise this flag; the credit is checked on the run's UI screenshots (`ui/`) by the tools.
- `clipped-snow-or-black-holes`
- `capture-failed`

## E. Totals and gate

- `v2Total` = sum of the non-null §8.3 scores.
- `v2Max` = 5 × number of non-null §8.3 scores.
- `v2Score50` = round(50 × Σ wᵢsᵢ / (5 × Σ wᵢ), 1) over the non-null §8.3 scores, with weight 1.5 for `palette`, `light` and `depthFog` and 1 for the rest (section S, since 6 Oct 2026). This keeps views with different `na` lists comparable on the v2 /50 scale. `v2Total` and `v2Max` stay unweighted.
- `adMean` = mean of the non-null art-direction scores, to 2 decimals.
- `v2Floors` = v2's per-criterion minimums. It is true only when **all** of the following hold:
  - No non-null **§8.3** score is below 3.
  - `geography` ≥ 4.
  - `characterReadability` ≥ 4 when it is scored.
  - There are no hard-gate flags.
- `gatePass`: the tools compute this when `finish` runs. It follows the owner's decision of 6 Oct 2026.
  - It is true when **parity ≥ 100 %** and `v2Floors` holds.
  - Parity = this view's `v2Score50` ÷ the calibrated `v2Score50` of its target concept (`docs/lookloop/calibration-scores.json`).
  - A view whose target is only a style reference has no parity. For that view, `gatePass` = `v2Floors` and `v2Score50` ≥ 40.
- `longTerm40` = `v2Score50` ≥ 40. This is v2's own bar, kept as the long-term goal and not gated.
- `adPass` = every non-null art-direction score is ≥ 3 (look-fix §8). It is tracked separately now.
- `gate5B` = `gatePass` and `adPass`. This is the **end-of-5B gate** (owner decision, 6 Oct 2026): parity ≥ 100 %, v2 floors, and every art-direction score ≥ 3.
  - The owner's richness rules ask for more than the concept images show (calibration: the concept art averaged 2.8 on rich ground).

Write `gatePass` from the floors and the 40/50 bar; `finish` replaces it with the parity rule. Scoring never depends on parity: score the anchors.

## F. Top 3 fixes

Rank fixes by how much they would raise the look of **this** view at phone size. Each fix gives:

- `area`: one of `ground`, `vegetation`, `buildings`, `light`, `sky`, `weather`, `water`, `fog`, `post`, `character`, `camera`, `data`.
- `fix`: a concrete change, for example "add foundation shrubs and lawn tone patches", not "improve ground".
- `why`: what in the frame shows the problem.
- `expectedGain`: the criterion keys that would rise.

Do not propose engine code. Describe the visible change.

## G. Output JSON (exact shape)

```json
{
  "view": "showcase-03",
  "grader": "<model id>",
  "scores": {
    "silhouettes": {"score": 3, "reason": "..."},
    "palette": {"score": 3, "reason": "..."},
    "light": {"score": 3, "reason": "..."},
    "softnessAO": {"score": 3, "reason": "..."},
    "groundRichness": {"score": 2, "reason": "..."},
    "characterReadability": {"score": null, "reason": "no character in frame"},
    "depthFog": {"score": 3, "reason": "..."},
    "houseVariety": {"score": 3, "reason": "..."},
    "geography": {"score": 4, "reason": "..."},
    "motion": {"score": null, "reason": "still capture"}
  },
  "artDirection": {
    "adGroundRich": {"score": 2, "reason": "..."},
    "adRainReadable": {"score": 2, "reason": "..."},
    "adRegional": {"score": 3, "reason": "..."}
  },
  "v2Total": 24, "v2Max": 40, "v2Score50": 30.0, "adMean": 2.33, "gatePass": false, "adPass": false,
  "hardGateFlags": [],
  "topFixes": [
    {"area": "weather", "fix": "...", "why": "...", "expectedGain": ["adRainReadable", "groundRichness"]},
    {"area": "...", "fix": "...", "why": "...", "expectedGain": ["..."]},
    {"area": "...", "fix": "...", "why": "...", "expectedGain": ["..."]}
  ],
  "vsPrevious": "better|worse|unchanged|no previous: one sentence",
  "summary": "Two sentences: the overall read at phone size and the single biggest gap."
}
```

## H. look-fix-v1 checks (additional; owner instruction 6 Oct 2026)

These are the "pass if…" checklists of ChatGPT's look-fix pack (`docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md` §1.4, §2.4, §3.3, §4, §5, §6.3 and §8). They are extra checks.

- They never change an anchor score or the gate.
- A failed check must appear among the top fixes, unless three bigger fixes outrank it.

Report each check as `true`, `false` or `null` with a one-line reason:
- `null` when the check does not apply to this view. Start the reason with **"n/a:"**.
- `null` when the check cannot be judged from a still. Start the reason with **"not checkable:"**. Examples: rain with particles hidden, stars during camera movement, all 12 lighting frames.

The summary counts both kinds separately from passes and fails.

| Id | Applies to | Pass if (all visible in this frame) |
|---|---|---|
| `LF-ground` | Views with visible foreground ground | `groundRichness` ≥ 3 and `adGroundRich` ≥ 3, plus all of:<br>- at least three distinct ground or planting layers in an eligible foreground (for example lawn tones, beds or shrubs, walks or drives, litter);<br>- grass does not span roads and yards indiscriminately;<br>- Lakeview views stay dense;<br>- no invented detail changes geography |
| `LF-light` | All views | `light` ≥ 3 and `palette` ≥ 3, plus all of:<br>- dark roofs and trunks stay distinguishable;<br>- source and shadow bearings agree with the view's `sun`;<br>- summer reads as summer, and winter has bare northern deciduous trees;<br>- exposure does not flatten the architecture |
| `LF-weather` | Wet, fog, smoke and snow views | **Wet** (`wet` true, not snow): `adRainReadable` ≥ 3 with three cues visible:<br>- wet surface contrast;<br>- small sheen or puddles;<br>- an atmospheric or sky change.<br>Judge with the particles present; whether the cues survive with particles hidden cannot be checked from a still, so say so.<br>**Fog/smoke:** contrast visibly differs between near (~50 m), mid (~150 m) and far (~500 m) objects.<br>**Snow:** the surface keeps its separation; no clipped snow, no invented ice, and no orange leaves in January |
| `LF-aerial` | Aerial and oblique views | `silhouettes` ≥ 3, `depthFog` ≥ 3 and `geography` ≥ 4, plus all of:<br>- no horizon in a steep aerial;<br>- no floating tile or flat green plane outside the world;<br>- no uniform diamond crowns;<br>- no route hidden under an arbitrary fade |
| `LF-trees` | Views with trees | `silhouettes` ≥ 3 and `adRegional` ≥ 3, plus all of:<br>- no three adjacent repeated inferred tree silhouettes;<br>- the season is correct for the date;<br>- at night, near and far trunks stay readable |
| `LF-sky` | Views with visible sky | The sky strengthens palette, light and depth without moving astronomy, plus all of:<br>- no sunset disk in the ESE showcase view;<br>- sparse cumulus stays simple;<br>- water glitter obeys light and water geometry.<br>Star fixedness during camera movement needs video, so do not judge it |

Add this field to the JSON of section G:

```json
"lookFixChecks": {
  "LF-ground": {"pass": false, "reason": "..."},
  "LF-light": {"pass": true, "reason": "..."},
  "LF-weather": {"pass": null, "reason": "n/a: dry, clear view"},
  "LF-aerial": {"pass": null, "reason": "n/a: street view"},
  "LF-trees": {"pass": false, "reason": "..."},
  "LF-sky": {"pass": true, "reason": "..."}
}
```

## Prompt for a reviewer sub-agent

`lookloop.sh` writes one prompt per view into `<run>/reviewers.md`. The template:

> Repo root is the current checkout; relative paths are relative to it. Modify no file except the grades JSON named below. You are a strict visual reviewer for WorldEngine. Follow docs/lookloop/GRADING.md exactly to grade view `<id>` of look-loop run `<run>`. Read GRADING.md first, then the view entry in `<manifest>`, the `<id>` entry in `<run>`/signals.json, the contact sheet `<run>`/sheets/`<id>`.jpg, the full frame `<run>`/frames/`<id>`.jpg and the target PNG(s) if any. Write only the JSON object of section G to `<run>`/grades/`<id>`.json (set "grader" to your model id), then reply "done".
