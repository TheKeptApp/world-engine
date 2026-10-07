# Design registry

The single list of every WorldEngine design pack, its status and which lanes use it. Maintained by P3 (look loop): on every 30-minute watch P3 checks `docs/proposals/` for new or changed folders and updates this file. Packs in `docs/proposals/` are read-only input (written by ChatGPT); this registry never edits them.

Status: **reference** (read for direction, not tracked), **in use** (lanes build or grade against it), **superseded** (kept for history), **pending** (announced, not yet in the repo). Lanes: 5A (light, weather, sky, post), P2 (buildings, yards, ground, vegetation placement), P3 (look loop and grading), L1, NJ.

Last checked: 2026-10-06 18:40 (P3).

## Packs in this repo

| Pack | Folder | Date | Covers | Status | Lanes | Open notes and gaps |
|---|---|---|---|---|---|---|
| visual-v2 | `docs/proposals/visual-v2/` | 2026-10-05 | The visual spec: nine target images, richness parameters, Baseline/Target/Stretch ladder, camera and light fixtures, 10 ms budget, ten-criterion rubric (§8.3) | in use | 5A, P2, P3 | Source of truth for the rubric (GRADING.md §A) and budgets. Its concept images enlarge the dog and oversize the sun disk; graded as faults. |
| visual-v1 | `docs/proposals/visual-v1/` | 2026-10-05 | First spec and five concept images; original-resolution drafts | superseded | — | Historical baseline, superseded by visual-v2. |
| experience-v1 | `docs/proposals/experience-v1/` | 2026-10-05 | Eleven weather and time-of-day concepts (golden hour, overcast, rain, storm, fog, smoke, snow, night, aerial rain and snow) | in use | 5A, P3 | Calibrated parity targets for the showcase views. |
| regions-chicagoland-miami | `docs/proposals/regions-chicagoland-miami/` | 2026-10-05 | North Shore (golden, rain, fall, snow) and Chicago (three-flat, alley snow) concepts; regional cues | in use | P2, P3 | Concepts 03, 04 and 06 are the style anchors (see decisions). Miami concepts not yet used by any view. |
| regions-northshore-chicago-miami | `docs/proposals/regions-northshore-chicago-miami/` | 2026-10-05 | Regional profiles draft, profile evidence, images | reference | P2 | Draft data; regional looks in production live in `Sources/WorldGen/Profiles/`. |
| regions-v1 | `docs/proposals/regions-v1/` | 2026-10-05 | Renderer-neutral regional profile data and geometry rules | reference | P2 | Superseded in practice by the regions packs above for North Shore and Chicago. |
| weather-v1 | `docs/proposals/weather-v1/` | 2026-10-05 | Weather and time specification | reference | 5A | |
| sky-seasons-v1 | `docs/proposals/sky-seasons-v1/` | 2026-10-05 | Sky and seasons spec and fixtures | reference | 5A | |
| engine-choice | `docs/proposals/engine-choice/` | 2026-10-05 | Engine-choice review | reference | — | Decision input only. |
| postcards-widgets-v1 | `docs/proposals/postcards-widgets-v1/` | 2026-10 | Scene studies, framed postcards, frame variations, widget boards, one-page spec | reference | — | Design proposal, not deployed UI. Widget attribution fit and provider review still required. Lane not assigned. |
| look-fix-v1 | `docs/proposals/look-fix-v1/` | 2026-10-06 | Ground, lawn, shrubs, light, weather, aerial edges and sky fixes; 21 reference images; "pass if" checks | in use | 5A, P2, P3 | **R override:** lawn contrast exceeds §1.1 (P2 ground pass 2: in-lot patches ±10–15 %, pools −25 % under trees, −18 % under shrubs and hedges, mowing bands). "Pass if" checks are GRADING.md §H. Images are uncalibrated appearance references. |
| vegetation-v1 | `docs/proposals/vegetation-v1/` | 2026-10-06 | Style-B tree and shrub reference: crown construction, four seasons for Chicago, Denver and Miami, shrubs, hedges and beds, exact colours (`vegetation-colours.json`), phone-distance and triangle budgets | in use | P2, P3 | **Gap:** Chicago needs a willow (later). P3: tree and shrub grading reference (GRADING.md §V, from the run after ec7a62a). |
| ground-v1 | `docs/proposals/ground-v1/` | 2026-10-06 | Style-B ground construction: lawn tone, pavement rhythm, worn edges, soft contact shade, restrained weather response; colours in `ground-colours.json`; reference images | **landed** (reference) | P2, 5A | Landed 2026-10-06 (committed unedited, 17 MB). **Gap:** Chicago red-brick and cobblestone streets missing (later). Not yet a P3 grading reference. |
| live-world-v1 | `docs/proposals/live-world-v1/` | 2026-10-06 | Style-B live objects: rail vehicles (CTA, Metra-inspired, RTD-inspired), elevated rail and portals, planes and other live layers; styling in `live-style.json` | **landed** (reference) | 5A (render), L1 (contracts) | Landed 2026-10-06 (committed unedited, 15 MB). Not yet a P3 grading reference. |

## External packs (other projects, listed by path only)

Listed at the owner's request, by path only; P3 does not read or use them. Paths to be confirmed by the owner (this repo's rules forbid looking inside other repos to find them).

| Pack | Project | Path | Note |
|---|---|---|---|
| controls-research-v1 | neighborhood-jobs (NJ) | to confirm | Drag & coast chosen. NJ paused for cloud credit (`docs/handoff/nj-f1-paused-for-credit.md` in that repo); resumes when the v2 export lands. |
| places-v1 | DogWell | to confirm | |
| cast-options-v1 | Stretchy | to confirm | |

## Decisions tied to packs

The full list of owner decisions is `docs/decisions/owner-log.md`; this table keeps only the ones tied to a pack.

| Date | Decision | Where recorded | Packs affected |
|---|---|---|---|
| 2026-10-06 | Style target **B, rich stylized**: simplified geometry and material hints; photoreal only in colour, light, atmosphere and weather; no photo textures or fine detail. | `docs/decisions/style-target.md`; GRADING.md §S | all |
| 2026-10-06 | Style anchors for colour and mood: regions concepts **03** (North Shore fall), **04** (North Shore snow), **06** (Chicago alley snow). Adopted; weighted highest when grading palette, light and depth. | `docs/decisions/style-target.md`; GRADING.md §S | regions-chicagoland-miami |
| 2026-10-06 | Owner override: lawn contrast beyond look-fix §1.1 (see look-fix-v1 row). | P2 merge `ec7a62a` | look-fix-v1 |
| 2026-10-06 | Owner override: wet paving darkening and puddle cover beyond the bible's ranges so rain reads on the phone (5A `df6baf4`). | 5A merge message | experience-v1, look-fix-v1 |
| 2026-10-06 | Look loop gate: concept parity ≥ 100 % of the calibrated concept plus v2 floors; art-direction ≥ 3 required at the end of 5B; full Opus gate when a routine Sonnet loop reaches ≥ 92 % (85 % + measured 7-point offset). | `docs/lookloop/README.md`, `scoreboard.md` | visual-v2, look-fix-v1 |

## Change log

- 2026-10-06: registry created; seeded with every folder in `docs/proposals/`, the two pending packs and three external packs.
- 2026-10-06 18:00: ground-v1 appeared in the main checkout (uncommitted); row filled in, still pending. No other pack folders changed.
- 2026-10-06 18:40: ground-v1 and live-world-v1 landed (committed unedited); statuses, contents, users and gaps set per owner. NJ paused note added.
