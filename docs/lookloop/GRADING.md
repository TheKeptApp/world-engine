# Look-loop grading procedure

A reviewer sub-agent follows these steps to score **one view**. The `/lookloop` skill spawns one reviewer per changed view, all in parallel, from the prompts in `<run>/reviewers.md`.

Reviewer models:
- **Sonnet** for routine runs.
- **Opus** for declared gate runs and for calibration.

Every reviewer works the same way, so scores are comparable run to run. When the grader model changes between two runs, read the regression guard with that in mind.

Sources (read-only): visual-v2 §8.3 rubric (`docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md`), experience-v1 §2 per-image guidance, regions-chicagoland-miami §3, §5, §6 and §14, and the owner's art direction (Phase 5 and P3 prompts).

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
5. Apply the strictness rules (section C). They outrank any instinct to be kind.
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
- `v2Score50` = round(50 × v2Total / v2Max, 1). This makes views with different `na` lists comparable on the v2 /50 scale.
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
