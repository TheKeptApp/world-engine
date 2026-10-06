# Look-loop grading procedure

A reviewer sub-agent follows these steps to score **one view**. `Tools/lookloop/grade.sh` runs one reviewer per view in parallel (headless `claude -p`, Read tool only). A session can instead spawn its own sub-agents with the prompt at the end of this file. Every reviewer works the same way, so scores are comparable run to run.

Sources (read-only): visual-v2 §8.3 rubric (`docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md`), experience-v1 §2 per-image guidance, regions-chicagoland-miami §3, §5, §6 and §14, and the owner's art direction (Phase 5 and P3 prompts).

## Inputs

For view `<id>` in run directory `<run>`:

| File | What it is |
|---|---|
| `<run>/sheets/<id>.jpg` | Contact sheet: target concept image(s) (blue), current capture (yellow), previous run (grey), luma histogram and numbers |
| `<run>/frames/<id>.jpg` | Current capture at full phone width (1206 px, 16:9). Use it to inspect detail |
| target PNG(s) | Paths in the view entry. Open them when the sheet is too small to judge |
| `Tools/lookloop/views.json` | The view entry: time, weather, season, character, `wet`, `na`, targets |
| `<run>/signals.json` | Objective signals for `<id>`: histograms vs target and previous, triangles, Simulator frame time. The `perf` counters are whole-world totals: they never prove what is or isn't visible. Judge visibility from the pixels only |

## Steps

1. Read the view entry in `views.json` and its `signals.json` entry.
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
8. Write the top 3 fixes (section F).
9. Write the result JSON (section G) to `<run>/grades/<id>.json`. If no file path or Write tool is available, output only the JSON instead (the headless runner saves it).

## A. Visual-v2 §8.3 criteria

The anchors are verbatim from v2 §8.3.

| # | Key | 1 — fails | 3 — baseline acceptable | 5 — target excellence |
|---|---|---|---|---|
| 1 | `silhouettes` | Box roofs, identical crowns; types merge | Roof/crown families readable but repetitive | Clear bungalow/foursquare/modern profiles; distinct tree archetypes and stable LOD outline |
| 2 | `palette` | Candy noise, pure-black holes, clipped snow | Coherent families, modest weather variation | Restrained base relationships survive noon, rain, snow and night without losing coat colors |
| 3 | `light` | Everything orange, contradictory key/shadows | Warm hero, neutral noon, cool readable night | Warm/cool balance with one coherent sun; no double tint; morning/evening distinct |
| 4 | `softnessAO` | Floating steps/shrubs or black dirty seams | Basic contact and soft shadows | Subtle eave/porch/crown/base occlusion and bevel glints; no burned-in directional shading |
| 5 | `groundRichness` | Flat sterile carpet or noisy blade forest | Some seams and edge clusters | Low-frequency variation, sparse rule-based leaves, credible wet streaks/patchy snow, quiet route center |
| 6 | `characterReadability` | Dog disappears, floats, glows or fills half screen | Recognizable common coat on path | Coat stays readable over each difficult surface, contact intact, 20–25% framing |
| 7 | `depthFog` | Missing edge, flat distance, heavy blur wall | Useful atmospheric separation | Lake/shore/backdrop continuous; low horizon depth, no fog discontinuity, aerial sharp center |
| 8 | `houseVariety` | Every facade random or identical | Several believable kit families | Footprint-appropriate mass, stable openings/entry/access, garage/alley relationships and modern/old mix |
| 9 | `geography` | Moved paths, fake shoreline, skyline/sun wrong bearing | Broad map correct but a few unverified details | Map overlay agrees; shadow bearing and backdrop azimuth verified; honest gaps, no invented parcel access |
| 10 | `motion` | Popping LODs, swimming masks, flickering cutaways | Stable ordinary walking with occasional transitions | Ten-minute walk feels continuous (video only) |

Notes:

- **Geography (9).** Each view entry carries `camera` (heading, pitch, FOV) and `sun` (elevation, azimuth, shadow bearing). Check the lit side of trunks and walls and the direction of cast shadows against them, relative to the camera heading. Quick reads:
  - v2 street faces west (270°). At golden hour the sun is ahead-left and shadows fall toward the camera and right.
  - The showcase street faces ESE (100°). The sun is behind or right, and no sunset disk or western mountains should appear.
  - Aerials face north with no horizon.
  - If shadows are too soft or absent to judge the bearing (overcast, fog, rain, night), score geography on paths, shoreline and layout alone, and say so. Do not cap the score just because the sun is hidden.
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
4. **Phone size.** The final read is at phone size, so judge the frame as a whole first. Use the full-size frame to confirm a defect, not to hunt for sub-pixel issues.
5. **Broken captures.**
   - If the frame is black, shows UI or error text, or is clearly not the requested view, set every applicable score to 1.
   - Add hard-gate flag `capture-failed` and explain.
6. **Previous run.** Note in `vsPrevious` whether the view got better, worse or is unchanged, and how.
   - The previous run never changes the scores. Scores are absolute against the anchors.
7. **One decimal of honesty.** If you cannot tell (for example a detail is too small), say so in the reason. Do not inflate.

## D. Hard-gate flags

Report only what you can see. Use these ids:

- `wrong-sun-bearing`
- `horizon-in-steep-aerial`
- `moved-geography`
- `authored-surface-imagery` (photo textures or painted ground)
- `full-surface-reflection` (mirror-lake or mirror-road)
- `osm-credit-missing` ("© OpenStreetMap contributors" must be visible)
- `clipped-snow-or-black-holes`
- `capture-failed`

## E. Totals and gate

- `v2Total` = sum of the non-null §8.3 scores.
- `v2Max` = 5 × number of non-null §8.3 scores.
- `v2Score50` = round(50 × v2Total / v2Max, 1). This makes views with different `na` lists comparable on the v2 /50 scale.
- `adMean` = mean of the non-null art-direction scores, to 2 decimals.
- `gatePass` = true only when **all** of the following hold:
  - `v2Score50` ≥ 40.
  - No non-null score (§8.3 or art direction) is below 3.
  - `geography` ≥ 4.
  - `characterReadability` ≥ 4 when it is scored.
  - There are no hard-gate flags.

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
  "v2Total": 24, "v2Max": 40, "v2Score50": 30.0, "adMean": 2.33, "gatePass": false,
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

## Prompt for a reviewer sub-agent

`grade.sh` sends this prompt. A session spawning its own sub-agent should use the same text, with `<id>`, `<run>` and `<out>` filled in:

> You are a strict visual reviewer for WorldEngine. Follow docs/lookloop/GRADING.md exactly to grade view `<id>` of look-loop run `<run>`. Read GRADING.md first, then the view entry in Tools/lookloop/views.json, the `<id>` entry in `<run>`/signals.json, the contact sheet `<run>`/sheets/`<id>`.jpg, the full frame `<run>`/frames/`<id>`.jpg and the target PNG(s). Write only the JSON object of section G to `<run>`/grades/`<id>`.json (set "grader" to your model id) and reply "done". If you have no Write tool, output only the JSON object, with no prose and no code fence.
