# Design registry

The single list of every WorldEngine design pack, its status and which lanes use it. Maintained by P3 (look loop): on every 30-minute watch P3 checks `docs/proposals/` for new or changed folders and updates this file. Packs in `docs/proposals/` are read-only input (written by ChatGPT); this registry never edits them.

Status: **reference** (read for direction, not tracked), **in use** (lanes build or grade against it), **superseded** (kept for history), **pending** (announced, not yet in the repo). Lanes: 5A (light, weather, sky, post), P2 (buildings, yards, ground, vegetation placement), P3 (look loop and grading), L1, NJ.

Last checked: 2026-10-06 23:10 (P3).

**Images are local-only from 2026-10-06:** new pack images (PNG, JPG, ZIP, SVG over 1 MB) live in R's local checkout and are gitignored; each pack's README, JSON and prompts are committed. Images committed before then remain in git history.

**ChatGPT drop folder (from 2026-10-06):** ChatGPT saves new packs to `~/Desktop/worldengine-gpt-drop/<pack>/`, outside the repo, so its files never sit untracked in a checkout. Each watch runs `Tools/lookloop/ingest_drop.py`: text goes to `docs/proposals/<pack>/` (design packs, with images) or `docs/research-gpt/<pack>/` (research), and is committed; images are copied to the local `docs/proposals/<pack>/` (gitignored) and to iCloud. Nothing in the drop folder is deleted. The transit research files were placed there as the first entry (already filed; `Tools/lookloop/drop-map.json` keeps its existing path).

**iCloud backup:** P3 copies every pack's images (PNG, JPG, ZIP, SVG) to `iCloud Drive/WorldEngine-Design-Backup/proposals/` with `Tools/lookloop/backup_design_images.sh` (copy only, never deletes), on every watch and whenever a pack lands. First copy 2026-10-06: 150 files, 329 MB; after paintover-v1: 184 files, 384 MB; after fog-v1, night-v1 and house-details-v1: 207 files, 436 MB. Look-loop frames are not backed up (regenerable).

## Packs in this repo

| Pack | Folder | Date | Covers | Status | Lanes | Open notes and gaps |
|---|---|---|---|---|---|---|
| visual-v2 | `docs/proposals/visual-v2/` | 2026-10-05 | The visual spec: nine target images, richness parameters, Baseline/Target/Stretch ladder, camera and light fixtures, 10 ms budget, ten-criterion rubric (§8.3) | in use | 5A, P2, P3 | Source of truth for the rubric (GRADING.md §A) and budgets. Its concept images enlarge the dog and oversize the sun disk; graded as faults. The two duplicate review ZIPs were removed from the current files on 2026-10-06 (the pack README still links one; history keeps both). |
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
| vegetation-v1 | `docs/proposals/vegetation-v1/` | 2026-10-06 | Style-B tree and shrub reference: crown construction, four seasons for Chicago, Denver and Miami, shrubs, hedges and beds, exact colours (`vegetation-colours.json`), phone-distance and triangle budgets | in use | P2, P3 | Weeping-willow addendum landed 2026-10-06 (`ADDENDUM-Weeping-Willow.md`, 2 images) — closes the willow gap. P3: tree and shrub grading reference (GRADING.md §V, from the run after ec7a62a). |
| rain-v1 | `docs/proposals/rain-v1/` | 2026-10-06 | Style-B rain readability: wetness states, puddle stain vs water, rain at phone distance, dusk/night rain, snow phone stages, phone rain/snow acceptance; values in `rain-values.json`; `verification.md`, `index.html` | **landed** (reference) | 5A, P3 | Landed 2026-10-06 (text committed; 7 images local-only, backed up). Not yet a P3 grading reference. |
| ground-v1 | `docs/proposals/ground-v1/` | 2026-10-06 | Style-B ground construction: lawn tone, pavement rhythm, worn edges, soft contact shade, restrained weather response; colours in `ground-colours.json`; reference images | **landed** (reference) | P2, 5A | Landed 2026-10-06 (committed unedited, 17 MB). Brick-streets and stone-paving addendum landed 2026-10-06 (`ADDENDUM-Brick-Streets-and-Stone-Paving.md`, 3 images) — closes the Chicago brick/cobblestone gap. Not yet a P3 grading reference. |
| live-world-v1 | `docs/proposals/live-world-v1/` | 2026-10-06 | Style-B live objects: rail vehicles (CTA, Metra-inspired, RTD-inspired), elevated rail and portals, planes and other live layers; styling in `live-style.json` | **landed** (reference) | 5A (render), L1 (contracts) | Landed 2026-10-06 (committed unedited, 15 MB). Not yet a P3 grading reference. |
| paintover-v1 | `docs/proposals/paintover-v1/` | 2026-10-06 | ChatGPT paint-overs of six look-loop frames from `393ed1e` (ordinary-street, evanston-street, showcase-03 Sloan's Lake rain, showcase-06 smoke, v2-06 golden-hour aerial, lakeview-street): original + paint-over + phone comparison + numbered callouts per view; authored grade values in `paintover-values.json` | **landed** (in use) | 5A, P2, P3 | The originals (the captures) govern geometry: camera, roads, footprints, shoreline, object inventory; small silhouette/window/leaf differences are not targets. One documented artefact: the rain puddle in showcase-03 keeps a slightly rimmed edge (target is a flush sky reflection). P3: per-view paint-over target and paint-over parity (GRADING.md §P), calibrated blind by Opus. Text committed; 6 PNG paint-overs, 6 originals and 12 SVGs (all over 1 MB) local-only, backed up. |
| fog-v1 | `docs/proposals/fog-v1/` | 2026-10-06 | Style-B morning fog: density and distance anchors (light mist, moderate, dense), Sloan's Lake low sun and aerial fog lifting, Chicago lakefront; values in `fog-values.json`; `sources.md`, `verification.md`, phone gallery | **landed** (reference) | 5A | Arrived via the ChatGPT drop folder. Priority stated by the pack: depth separation first, readable nearby surfaces, soft glow; never a uniform grey filter. Values marked [A] are authored, not measured. Not yet a P3 grading reference (showcase-05 fog could use it). 7 PNGs and 9 SVGs over 1 MB local-only (gitignored), backed up. |
| night-v1 | `docs/proposals/night-v1/` | 2026-10-06 | Style-B dusk and night: blue hour to night (Chicago glow vs Denver suburb), windows and porches 6 pm/11 pm, sodium and warm LED streetlight pools, full moon vs moonless, night rain and snow; values in `night-values.json` | **landed** (reference) | 5A | Arrived via the ChatGPT drop folder. Renderer-neutral appearance proposal. Not yet a P3 grading reference (showcase-09 clear night could use it). 5 PNGs local-only, backed up; `06-exact-night-values.svg` committed (under 1 MB). |
| house-details-v1 | `docs/proposals/house-details-v1/` | 2026-10-06 | Style-B house families (Tudor, Colonial, Prairie, Queen Anne, Chicago bungalow, two-flat; greystone, courtyard, Denver bungalow/ranch/Victorian), distance and bevel rules, material colours in `house-details-colours.json` | **landed** (reference) | P2 | Arrived via the ChatGPT drop folder. Dimensions, colours and bevels are authored starting values; JSON and README govern, raster micro-detail is not a requirement. Not yet a P3 grading reference (houseVariety). 2 PNGs local-only, backed up; 2 SVGs committed (under 1 MB). |

## Research (text, not design packs)

| Research | Folder | Date | Covers | Status | Users | Notes |
|---|---|---|---|---|---|---|
| transit-feeds-top20 | `docs/research-gpt/` (`transit-feeds-top20.csv`, `README.md`) | 2026-10-06 | 32 US agencies: realtime feed, key/access, commercial use, redistribution, caching, attribution, rate limits, static GTFS URL, each with official citations; "unclear" where unknown | **landed** (reference; written by ChatGPT, committed unedited) | L1 (live world), P1 | P3 spot-checked 8 rows (2 verified, 4 corrected, 2 unclear: Metra 403, MBTA licence PDF unread); results in `docs/data-sources/metro-transit.csv`; lawyer questions Q33–Q38 in `docs/research/licensing.md`. No key values recorded. CTA and Pace are not in this list (covered in `docs/research/live-feeds.md`). |
| live-aircraft-research | `docs/research-gpt/live-aircraft-research/` (`aircraft-sources.csv`, `README.md`) | 2026-10-06 | Live aircraft providers (OpenSky, ADS-B Exchange, FlightAware, Flightradar24, FAA SWIM, adsb.lol, airplanes.live, adsb.fi): coverage, latency, commercial use, distribution, licensing to other apps, caching, attribution, price tiers and cost estimates for 1, 2 and 20 metros at 10 s | **landed** (reference; ChatGPT via the drop folder, committed unedited) | L1 (live world), owner | P3 spot-checked 5 rows: ADS-B Exchange and adsb.lol verified (one URL fix, one indemnity addition), OpenSky and FlightAware partly verified, FAA SWIM unclear (pages blocked or unreadable); results in `docs/data-sources/live-aircraft-checks.md`; lawyer questions Q39–Q43. No key values recorded. |

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
| 2026-10-06 | Tree crowns as leaf cards (option a) rather than smooth puffs, subject to 5A's phone overdraw check (fallback: puffs with stronger interior darkening). The paint-overs are a lighting reference, not a tree-shape reference. | `docs/decisions/owner-log.md` | vegetation-v1, paintover-v1 |

## Change log

- 2026-10-06: registry created; seeded with every folder in `docs/proposals/`, the two pending packs and three external packs.
- 2026-10-06 18:00: ground-v1 appeared in the main checkout (uncommitted); row filled in, still pending. No other pack folders changed.
- 2026-10-06 18:40: ground-v1 and live-world-v1 landed (committed unedited); statuses, contents, users and gaps set per owner. NJ paused note added.
- 2026-10-06 19:10: image files made local-only (gitignored); visual-v2 review ZIPs removed from the current files.
- 2026-10-06 19:25: iCloud image backup started (150 files, 329 MB); rain-v1 arriving (3 images, pending).
- 2026-10-06 20:00: verified local vs iCloud after 5A's move: nothing missing from ground-v1 or vegetation-v1; restored the two visual-v2 ZIPs locally from iCloud (gitignored); addenda landed (brick/stone, willow); rain-v1 landed; backup updated, keeping the earlier rain-v1 01 image as `.prev-2026-10-06`. Per pack local/iCloud: experience 11/11, ground 15/15, live-world 11/11, look-fix 21/21, postcards 45/45, rain 7/7, regions-chicagoland-miami 10/10, regions-v1 6/6, vegetation 11/11, visual-v1 11/11, visual-v2 11/11 (345 MB).
- 2026-10-06 22:30: paintover-v1 landed (text committed unedited; 24 images local-only and backed up to iCloud, 39 MB; its 12 SVGs are all over 1 MB and gitignored). Users 5A, P2, P3; P3 adds paint-over parity (GRADING.md §P).
- 2026-10-06 22:55: research section added; transit-feeds-top20 (ChatGPT research, 32 agencies) committed and spot-checked (8 rows).
- 2026-10-06 22:40: drop folder `~/Desktop/worldengine-gpt-drop/` created and the ingest process set up; untracked duplicates of the committed research files removed from the owner's checkout (originals kept in the drop folder).
- 2026-10-06 23:10: first packs filed through the drop folder: fog-v1 and night-v1 (5A), house-details-v1 (P2), live-aircraft-research (research). Text committed unedited, images local and backed up (207 files, 436 MB), 9 fog-v1 SVGs over 1 MB gitignored.
