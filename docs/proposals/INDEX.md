# Design packs index

Maintained by P3 (not written by ChatGPT; added on the owner's instruction, 2026-10-07). One place to find the mock for any visual feature. Approved packs are the exact visual direction: lanes build to match them (CLAUDE.md, "Visual work builds to approved mocks"; owner-log 2026-10-07). Full history per pack: `docs/design-registry.md`.

**Where the images are.** Pack images (PNG, JPG, ZIP, large SVG) are gitignored, so they are **not in worktrees or fresh clones** (checked 2026-10-07: a fresh worktree has the README and JSON but no `images/`). Open them from the owner's checkout, which always has them:

- `~/Desktop/world-engine/docs/proposals/<pack>/` (primary; P3 copies every pack's images there when it files the pack)
- `~/Library/Mobile Documents/com~apple~CloudDocs/WorldEngine-Design-Backup/proposals/<pack>/` (iCloud backup, same layout)

The README, values JSON and prompts are committed, so they are readable from any worktree at `docs/proposals/<pack>/`.

**Status:** "R approved – binding target" when the pack has a `STATUS.md` saying R approved; "pending R approval" otherwise (packs filed before the rule are marked "in use (pre-rule; R to confirm)").

| Feature | Pack | Images (owner's checkout) | Values JSON (repo) | Status |
|---|---|---|---|---|
| House archetypes, Chicago (form, dimensions, roof pitch, palette variants, detail tiers, porch/garage/yard rules) | house-archetypes-v1 | `~/Desktop/world-engine/docs/proposals/house-archetypes-v1/` (images at the pack root): sheets `chicago-01-bungalow … chicago-05-ranch-sheet.png`, board `chicago-board.png`, block paint-over `chicago-block.png` (Lakeview postcard camera) | `docs/proposals/house-archetypes-v1/archetypes-values.json` (`archetypes[id=…]`) | **R approved – binding target** (per-type house values; daytime lighting stays house-contrast-v1) |
| House archetypes, Denver (form, dimensions, roof pitch, palette variants, detail tiers, porch/garage/yard rules) | house-archetypes-v1 | `~/Desktop/world-engine/docs/proposals/house-archetypes-v1/` (images at the pack root): sheets `denver-01-square … denver-06-infill-sheet.png`, board `denver-board.png`, block paint-over `denver-block.png` (Denver street camera) | `docs/proposals/house-archetypes-v1/archetypes-values.json` (`archetypes[id=…]`) | **R approved – binding target** (per-type house values; daytime lighting stays house-contrast-v1) |
| House archetypes, Miami (form, dimensions, roof pitch, palette variants, detail tiers, porch/garage/yard rules) | house-archetypes-v1 | `~/Desktop/world-engine/docs/proposals/house-archetypes-v1/` (images at the pack root): sheets `miami-01-ranch … miami-05-suburban-sheet.png`, board `miami-board.png`, block paint-over `miami-block.png` (borrowed Denver camera; no Miami view yet) | `docs/proposals/house-archetypes-v1/archetypes-values.json` (`archetypes[id=…]`) | **R approved – binding target** (per-type house values; daytime lighting stays house-contrast-v1) |
| Infrastructure look: roads, bridges, rail, airports, water, utilities, parks (markings, materials, palettes, LOD tiers; street geometry is owned by street-geometry-rules-v1) | infrastructure-kit-v1 | `~/Desktop/world-engine/docs/proposals/infrastructure-kit-v1/` (97 images, 48 sheets) | `docs/proposals/infrastructure-kit-v1/infrastructure-values.json` | **R approved – binding target** (all 48 sheets, 7 Oct 2026; look only) |
| Foliage by season: species crowns, season colours, city mixes, regional plantings | foliage-seasons-v1 | `~/Desktop/world-engine/docs/proposals/foliage-seasons-v1/` (25 images) | `docs/proposals/foliage-seasons-v1/foliage-values.json` | **R approved – binding target** (7 Oct 2026) |
| Water mechanics: wave terms, foam, shore types, ice gating, live inputs, budget (water COLOUR stays with lake-winter-v1 and style-b-calibration-v2; Lake Michigan stays #315F7F) | water-surfaces-v1 | `~/Desktop/world-engine/docs/proposals/water-surfaces-v1/` (28 images) | `docs/proposals/water-surfaces-v1/water-values.json` | **R approved – binding target, MECHANICS only** (7 Oct 2026) |
| Road signs and signals, seven countries, and all road markings outside the US (US lane markings and crosswalks stay with infrastructure-kit-v1) | road-signs-signals-v1 | `~/Desktop/world-engine/docs/proposals/road-signs-signals-v1/` (11 images) | `docs/proposals/road-signs-signals-v1/road-signs-values.json` | **R approved – binding target** (7 Oct 2026) |
| Terrain and slope: floors level, buildings never tilt, foundations from the footprint, preserve breaklines, never drape bridges | terrain-slope-v1 | `~/Desktop/world-engine/docs/proposals/terrain-slope-v1/` (16 images) | `docs/proposals/terrain-slope-v1/values.json` | **R approved – binding target** (7 Oct 2026) |
| Greenville, SC (R's test location 3): six archetypes, four districts, trees, terrain, seasonal lawns, weather (look from style-b-calibration-v2) | greenville-sc-v1 | `~/Desktop/world-engine/docs/proposals/greenville-sc-v1/` (40 images) | `docs/proposals/greenville-sc-v1/values.json` | **R approved – binding target** (7 Oct 2026) |
| Chicago and Denver city life: food, alleys, transit, game day, seasons | chicago-denver-life-v1 | `~/Desktop/world-engine/docs/proposals/chicago-denver-life-v1/` (9 images) | `docs/proposals/chicago-denver-life-v1/values.json` | **R approved – binding target** (8 Oct 2026; Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.) |
| New York city life: shops, vendors, workers, vehicles and street rhythms | nyc-life-v1 | `~/Desktop/world-engine/docs/proposals/nyc-life-v1/` (73 images) | `docs/proposals/nyc-life-v1/values.json` | **R approved – binding target** (8 Oct 2026; Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.) |
| San Francisco city life: transit, tech, shops, workers, hills, water | sf-life-v1 | `~/Desktop/world-engine/docs/proposals/sf-life-v1/` (52 images) | `docs/proposals/sf-life-v1/sf-life-values.json` | **R approved – binding target** (8 Oct 2026; Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.) |
| NYC hero scenes, Style B (archetypes, districts, streets, bridges, light) | nyc-hero-v1 | `~/Desktop/world-engine/docs/proposals/nyc-hero-v1/` (61 images) | `docs/proposals/nyc-hero-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved.) |
| Metro looks, wave 2: nine US metros, SF hero r2 | us-metros-wave2-v1 | `~/Desktop/world-engine/docs/proposals/us-metros-wave2-v1/` (232 images) | `docs/proposals/us-metros-wave2-v1/metro-values.json` | **R approved – binding target** (8 Oct 2026; Approved, including the San Francisco revision 2 (SF r2); files marked superseded stay superseded.) |
| US metros wave 3: house and district looks for 12 metros | us-metros-wave3-v1 | `~/Desktop/world-engine/docs/proposals/us-metros-wave3-v1/` (94 images) | `docs/proposals/us-metros-wave3-v1/metro-values.json` | **R approved – binding target** (8 Oct 2026; Approved.) |
| Weather and night moments, Style B (21 before/after states incl. NYC) | weather-moments-v1 | `~/Desktop/world-engine/docs/proposals/weather-moments-v1/` (12 images) | `docs/proposals/weather-moments-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved, including the NYC board (nyc-verification.json and the nyc-check screenshots).) |
| Venues, campuses and event grounds, Style B (17 archetypes) | venues-campuses-v1 | `~/Desktop/world-engine/docs/proposals/venues-campuses-v1/` (34 images) | venues-campus-values.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved for the Builder phase.) |
| Regional car mix: ambient vehicle fixtures for 12 regions | regional-car-mix-v1 | `~/Desktop/world-engine/docs/proposals/regional-car-mix-v1/` (30 images) | `docs/proposals/regional-car-mix-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved for P2's ambient vehicles.) |
| Mexico and Australia Style B: archetypes, districts, trees, seasons, transit, weather | mexico-australia-v1 | `~/Desktop/world-engine/docs/proposals/mexico-australia-v1/` (75 images) | `docs/proposals/mexico-australia-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved; Australia drives on the left.) |
| Mountain terrain and hiking trails: Front Range seasons, snow, horizon, ski | mountain-terrain-v1 | `~/Desktop/world-engine/docs/proposals/mountain-terrain-v1/` (64 images) | `docs/proposals/mountain-terrain-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved (R's 8 Oct approvals list names mountains): v1 plus the r2 fixes (Sloan's Lake far-view correction, ski area re-render) and the hiking trails.) |
| Metro data coverage: source and licence inventory for 38 cities, import order | metro-data-coverage-v1 | `~/Desktop/world-engine/docs/proposals/metro-data-coverage-v1/` (0 images) | – | **R approved – binding target** (8 Oct 2026; Approved: P1's import order is New York and Amsterdam first; only GREEN datasets are loaded (no permission, no raw data).) |
| Live flights: provider rights, costs, airport gates and aircraft mocks | live-flights-v1 | `~/Desktop/world-engine/docs/proposals/live-flights-v1/` (5 images) | values.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved as the live-flights design and airport audit. Its FlightAware recommendation and pricing are not adopted: R chose the adsb.lol hosted feed.) |
| Real flights path: home receiver, adsb.lol under ODbL, FAA SWIM later | real-flights-path-v1 | `~/Desktop/world-engine/docs/proposals/real-flights-path-v1/` (0 images) | – | **R approved – binding target** (8 Oct 2026; Approved as the adsb.lol path to real flights. Where its sequencing (a Denver receiver proof first) differs from R's launch decision, R's decision stands.) |
| UK Style B: archetypes, districts, trees, seasons, city systems, weather, night | uk-style-b-v1 | `~/Desktop/world-engine/docs/proposals/uk-style-b-v1/` (67 images) | `docs/proposals/uk-style-b-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved; the UK drives on the left.) |
| Netherlands Style B: archetypes, districts, cycling, canals, trees, weather, night, Kings Day | netherlands-style-b-v1 | `~/Desktop/world-engine/docs/proposals/netherlands-style-b-v1/` (212 images) | `docs/proposals/netherlands-style-b-v1/values.json` | **R approved – binding target** (8 Oct 2026; Approved.) |
| Canada Style B v2: Toronto, Vancouver and Montréal archetypes, districts, transit, seasons, night | canada-style-b-v2 | `~/Desktop/world-engine/docs/proposals/canada-style-b-v2/` (24 images) | `docs/proposals/canada-style-b-v2/values.json` | **R approved – binding target** (8 Oct 2026; Approved; supersedes canada-style-b-v1.) |
| Seasonal and holiday street life: ten states on five US blocks, four regional scenes | seasonal-holiday-life-v1 | `~/Desktop/world-engine/docs/proposals/seasonal-holiday-life-v1/` (116 images) | `docs/proposals/seasonal-holiday-life-v1/values.json` | **R approved – binding target** (8 Oct 2026; Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.) |
| Race organizer operations: safety rules and three race-village concepts for Builder AI | race-organizer-ops-v1 | `~/Desktop/world-engine/docs/proposals/race-organizer-ops-v1/` (8 images) | rules.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved for the Builder phase.) |
| Builder event templates: five Style B event layouts with guest-count rules and parts | builder-event-templates-v1 | `~/Desktop/world-engine/docs/proposals/builder-event-templates-v1/` (26 images) | visual-values.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved for the Builder phase.) |
| Neighborhood product study: Common Ground, Gather and a jobs game, with phone screens | neighborhood-product-v1 | `~/Desktop/world-engine/docs/proposals/neighborhood-product-v1/` (79 images) | values.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved: the jobs game study (jobs-game/). The parent Common Ground study is not named in R's list and stays pending.) |
| Licensing demo: B2B web mock for licensing a 3D place to other businesses | licensing-demo-v1 | `~/Desktop/world-engine/docs/proposals/licensing-demo-v1/` (25 images) | style-b-values.json (not compiled into the engine) | **R approved – binding target** (8 Oct 2026; Approved as the B2B licensing demo design.) |
| Creator kit UX, Easy + Pro (app design; supersedes v2; Builder phase after the engine look gate) | creator-kit-ux-v3 | `~/Desktop/world-engine/docs/proposals/creator-kit-ux-v3/` (56 images) | `design-values.json` (app UI tokens; not compiled into the engine) | **R approved – binding target** (8 Oct 2026) |
| Style B look calibration: lighting, exposure, saturation, matte materials, distance detail (the look-gate target; replaces the old Lakeview street) | style-b-calibration-v2 | `~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/` (frames, 8 comparison sheets) | `docs/proposals/style-b-calibration-v2/values.json` | **R approved – binding target** (7 Oct 2026; packs own content, this owns look) |
| Landmark models, 13 more US metros (look, topology, must-be-exact, detail tiers; dimensions unverified except 4 heights; skylines concept only) | landmarks-style-b-v2 | `~/Desktop/world-engine/docs/proposals/landmarks-style-b-v2/` (157 images) | landmarks-values.json (not compiled: dimensions unverified) | **R approved – binding target** for look, topology, must-be-exact and detail tiers (7 Oct 2026) |
| Night and fog | night-fog-v1 | `~/Desktop/world-engine/docs/proposals/night-fog-v1/images/` | `docs/proposals/night-fog-v1/night-fog-values.json` | **R approved – binding target** |
| **Daytime lighting master** (sky, sun, shadow tint, exposure, ground colours) and houses (contrast) | house-contrast-v1 | `~/Desktop/world-engine/docs/proposals/house-contrast-v1/images/` (`*-hero.png` = one shared afternoon; earlier `*-paintover.png` superseded) | `docs/proposals/house-contrast-v1/paintover-values.json` (`sharedLighting` block) | **R approved – binding target; DAYTIME LIGHTING MASTER** (wins over paintover-v1 and other packs on daytime lighting) |
| Lake water and winter (ice, tree snow, old snow) | lake-winter-v1 | `~/Desktop/world-engine/docs/proposals/lake-winter-v1/` (images at the pack root) | `docs/proposals/lake-winter-v1/lake-winter-values.json` | **R approved – binding target** |
| Sky, lighting and grade per view (exposure, contrast, saturation, warmth, shadows, crowns, water) — **daytime lighting superseded by house-contrast-v1 sharedLighting** | paintover-v1 | `~/Desktop/world-engine/docs/proposals/paintover-v1/images/` | `docs/proposals/paintover-v1/paintover-values.json` | in use (pre-rule; R to confirm) |
| Trees (crowns, seasons, regions) and trunks | vegetation-v1 | `~/Desktop/world-engine/docs/proposals/vegetation-v1/images/` | `docs/proposals/vegetation-v1/vegetation-colours.json` | in use (pre-rule; R to confirm); Denver list superseded by owner decision 2026-10-07 |
| Ground and paths (lawn, paving, worn edges, brick/stone) | ground-v1 | `~/Desktop/world-engine/docs/proposals/ground-v1/images/` | `docs/proposals/ground-v1/ground-colours.json` | in use (pre-rule; R to confirm) |
| Rain and wet surfaces | rain-v1 | `~/Desktop/world-engine/docs/proposals/rain-v1/images/` | `docs/proposals/rain-v1/rain-values.json` | in use (pre-rule; R to confirm) |
| Night (dusk, windows, streetlights, moon) | night-v1 | `~/Desktop/world-engine/docs/proposals/night-v1/images/` | `docs/proposals/night-v1/night-values.json` | in use (pre-rule); night-fog-v1 is the approved night target |
| Fog | fog-v1 | `~/Desktop/world-engine/docs/proposals/fog-v1/images/` | `docs/proposals/fog-v1/fog-values.json` | in use (pre-rule); night-fog-v1 is the approved fog target |
| Houses (families, details, colours) | house-details-v1 | `~/Desktop/world-engine/docs/proposals/house-details-v1/` | `docs/proposals/house-details-v1/house-details-colours.json` | in use (pre-rule; R to confirm) |
| Landmarks (Chicago, Denver) | landmarks-v1 | `~/Desktop/world-engine/docs/proposals/landmarks-v1/images/` | `docs/proposals/landmarks-v1/landmarks-colours.json` | reference – build after the look gate; Cloud Gate reference only |
| Live objects (rail, planes) | live-world-v1 | `~/Desktop/world-engine/docs/proposals/live-world-v1/images/` | `docs/proposals/live-world-v1/live-style.json` | in use (pre-rule; R to confirm) |
| Look fixes (ground, light, weather, aerial edges, sky) | look-fix-v1 | `~/Desktop/world-engine/docs/proposals/look-fix-v1/images/` | `docs/proposals/look-fix-v1/sky-projection-reference.json` | in use (pre-rule; R to confirm) |
| Mascots (app characters) | mascots-v1 | `~/Desktop/world-engine/docs/proposals/mascots-v1/` | – | pending R approval (app, not engine) |
| Visual spec, concepts and rubric | visual-v2 | `~/Desktop/world-engine/docs/proposals/visual-v2/images/` | `docs/proposals/visual-v2/comparison-presets.json` | in use (grading source of truth) |
| Weather and time concepts | experience-v1 | `~/Desktop/world-engine/docs/proposals/experience-v1/images/` | `docs/proposals/experience-v1/showcase-presets.json` | in use (concept parity targets) |
| Regional concepts (North Shore, Chicago) | regions-chicagoland-miami | `~/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/` | `docs/proposals/regions-chicagoland-miami/region-catalog.json` | in use (style anchors 03, 04, 06) |

Older and reference-only packs (visual-v1, weather-v1, sky-seasons-v1, engine-choice, regions-v1, regions-northshore-chicago-miami, postcards-widgets-v1): see the registry. Research (not design) is under `docs/research-gpt/`.

## New packs filed 7 Oct 2026 – pending R approval

Filed from the drop folder; none has a STATUS.md, so none is a binding target yet. Research packs (no images) are listed in the registry (`docs/design-registry.md`, Research).

| Feature | Pack | Images (owner's checkout) | Values JSON (repo) | Status |
|---|---|---|---|---|
| Landmark models, Style B (Chicago, Denver, Miami) | landmarks-style-b-v1 | `~/Desktop/world-engine/docs/proposals/landmarks-style-b-v1/` (206 images) | `docs/proposals/landmarks-style-b-v1/landmarks-values.json` | pending R approval |
| District looks, Chicago and Denver | districts-chi-den-v1 | `~/Desktop/world-engine/docs/proposals/districts-chi-den-v1/` (14 images) | `docs/proposals/districts-chi-den-v1/districts-values.json` | pending R approval |
| Japan, Style B | japan-style-b-v1 | `~/Desktop/world-engine/docs/proposals/japan-style-b-v1/` (31 images) | `docs/proposals/japan-style-b-v1/japan-values.json` | pending R approval |
| Japan, regional kit | japan-regional-kit-v1 | `~/Desktop/world-engine/docs/proposals/japan-regional-kit-v1/` (20 images) | `docs/proposals/japan-regional-kit-v1/regional-kit-values.json` | pending R approval |
| House archetypes: NYC, LA, Phoenix, Seattle | house-archetypes-v2 | `~/Desktop/world-engine/docs/proposals/house-archetypes-v2/` (41 images) | `docs/proposals/house-archetypes-v2/archetypes-values-v2.json` | pending R approval |
| US regional landscapes | us-regional-landscapes-v1 | `~/Desktop/world-engine/docs/proposals/us-regional-landscapes-v1/` (21 images) | `docs/proposals/us-regional-landscapes-v1/landscapes-values.json` | pending R approval |
| Ambient life: traffic, people, wildlife, effects | ambient-life-kit-v1 | `~/Desktop/world-engine/docs/proposals/ambient-life-kit-v1/` (3 images) | `docs/proposals/ambient-life-kit-v1/ambient-life-values.json` | pending R approval |
| Style B rule and realism levels | style-b-bible-v1 | `~/Desktop/world-engine/docs/proposals/style-b-bible-v1/` (5 images) | `docs/proposals/style-b-bible-v1/bible-values.json` | pending R approval |
| Street-to-space zoom ladder | street-to-space-v1 | `~/Desktop/world-engine/docs/proposals/street-to-space-v1/` (17 images) | `docs/proposals/street-to-space-v1/values.json` | pending R approval |
| Creator kit editor UX (web, v2) | creator-kit-ux-v1 | `~/Desktop/world-engine/docs/proposals/creator-kit-ux-v1/` (34 images) | `docs/proposals/creator-kit-ux-v1/v2/design-tokens.json` | superseded by creator-kit-ux-v3 (R, 8 Oct 2026) |
| Three-city demo storyboard (90/30/15 s) | demo-storyboard-v1 | `~/Desktop/world-engine/docs/proposals/demo-storyboard-v1/` (2 images) | `docs/proposals/demo-storyboard-v1/shots.json` | pending R approval |

## New packs filed 7 Oct 2026 – pending R approval

Filed from the drop folder; none has a STATUS.md, so none is a binding target yet. Research packs (no images) are listed in the registry (`docs/design-registry.md`, Research).

| Feature | Pack | Images (owner's checkout) | Values JSON (repo) | Status |
|---|---|---|---|---|

## New packs filed 7 Oct 2026 – pending R approval

Filed from the drop folder; none has a STATUS.md, so none is a binding target yet. Research packs (no images) are listed in the registry (`docs/design-registry.md`, Research).

| Feature | Pack | Images (owner's checkout) | Values JSON (repo) | Status |
|---|---|---|---|---|






## Delivered, research and parked packs (R, 8 Oct 2026)

Filed by R's full filing pass: delivered packs are reference and design input for the named lane, not binding visual targets; research is unverified; parked packs are not scheduled. Not filed: `somewhere-brand` (R is deciding) and `Southern` (not in the drop folder; awaiting R). The drop folder's zips are listed in `docs/pack-usage.md` for R to move.

| Feature | Pack | Where | Values | Status |
|---|---|---|---|---|
| Mobile rendering research; streaming-design.md and compatibility.md | mobile-rendering-v1 | `docs/research-gpt/mobile-rendering-v1/` (text) | – | delivered (R, 8 Oct 2026): 5A, P0; After the look gate (streaming, device tiers hero / standard / floor) |
| Strategic and data research | strategic-research-v1 | `docs/research-gpt/strategic-research-v1/` (text) | – | delivered (R, 8 Oct 2026): owner; Strategy |
| Data layers research (crop, water, terrain, tides, footprints) | data-layers-research-v1 | `docs/research-gpt/data-layers-research-v1/` (text) | – | delivered (R, 8 Oct 2026): P1; Data release |
| Street trees by metro | street-trees-by-metro-v1 | `docs/research-gpt/street-trees-by-metro-v1/` (text) | – | delivered (R, 8 Oct 2026): P2, P1; City kits (trees) |
| Catalog of regional looks | regional-look-catalog-v1 | `docs/research-gpt/regional-look-catalog-v1/` (text) | – | delivered (R, 8 Oct 2026): P1, P2; City kits (regional looks) |
| Tree and city data licence check | data-licence-check-v1 | `docs/research-gpt/data-licence-check-v1/` (text) | – | delivered (R, 8 Oct 2026): P1, owner; Data release (licences) |
| Event site-map import and parts schema | event-sitemap-ai-v1 | `~/Desktop/world-engine/docs/proposals/event-sitemap-ai-v1/` (18 images) | – | delivered (R, 8 Oct 2026): Builder; Builder phase |
| Building height sources and rules | building-heights-v1 | `docs/research-gpt/building-heights-v1/` (text) | – | delivered (R, 8 Oct 2026): P1, P2; Data release |
| Web stack research | web-stack-v1 | `docs/research-gpt/web-stack-v1/` (text) | – | delivered (R, 8 Oct 2026): owner, 5A; After the look gate (web viewer) |
| Street geometry rules by country and class | street-geometry-rules-v1 | `docs/research-gpt/street-geometry-rules-v1/` (text) | – | delivered (R, 8 Oct 2026): P1, P2; Look gate and city kits (street geometry owner, R 7 Oct) |
| Country shortlist research | country-shortlist-v1 | `docs/research-gpt/country-shortlist-v1/` (text) | – | delivered (R, 8 Oct 2026): owner; Launch countries (decided: Canada, UK, Netherlands, Mexico, Australia, Japan) |
| Japan showcase research | japan-showcase-v1 | `docs/research-gpt/japan-showcase-v1/` (text) | – | delivered (R, 8 Oct 2026): P2, owner; Launch country Japan |
| Canada, Style B | canada-style-b-v1 | `~/Desktop/world-engine/docs/proposals/canada-style-b-v1/` (26 images) | – | delivered (R, 8 Oct 2026): P2; Launch country Canada; superseded by canada-style-b-v2 (approved 8 Oct 2026) |
| Japan, infrastructure kit | japan-infrastructure-kit-v1 | `~/Desktop/world-engine/docs/proposals/japan-infrastructure-kit-v1/` (26 images) | – | delivered (R, 8 Oct 2026): P2; Launch country Japan |
| Metro onboarding, 4 metros | metro-onboarding-v1 | `~/Desktop/world-engine/docs/proposals/metro-onboarding-v1/` (4 images) | block-mix-values.json | delivered (R, 8 Oct 2026): P1; City-kit checklist (onboarding) |
| Live layers catalog | live-layers-catalog-v1 | `docs/research-gpt/live-layers-catalog-v1/` (text) | – | delivered (R, 8 Oct 2026): L1; Live layers |
| Creator kit demand research | creator-kit-demand-v1 | `docs/research-gpt/creator-kit-demand-v1/` (text) | – | delivered (R, 8 Oct 2026): owner; Builder demand |
| Blocklight hyperlocal weather research | hyperlocal-weather-v1 | `docs/research-gpt/hyperlocal-weather-v1/` (text) | – | parked (R, 8 Oct 2026): owner (R), P1; Parked (Blocklight) |
| Weather block (app UI design) | weather-block-design-v1 | `~/Desktop/world-engine/docs/proposals/weather-block-design-v1/` (11 images) | – | parked (R, 8 Oct 2026): owner (R); Parked (Blocklight) |

## Past packs – R to confirm

Packs filed before the STATUS.md rule (2026-10-07). P3 has **not** marked any of them binding; R confirms in one reply. "Evidence" is what the registry and owner log record about R approving or using the pack.

| Pack | Date | Covers | Registry status | Evidence of R approval or use |
|---|---|---|---|---|
| visual-v2 | 2026-10-05 | Visual spec: 9 targets, richness ladder, camera/light fixtures, 10 ms budget, 10-criterion rubric | in use | CLAUDE.md names it the visual source of truth; rubric of the look gate |
| visual-v1 | 2026-10-05 | First spec, 5 concepts | superseded | Superseded by visual-v2 |
| experience-v1 | 2026-10-05 | 11 weather/time concepts (golden hour, overcast, rain, storm, fog, smoke, snow, night, aerial rain/snow) | in use | Concept-parity targets of the look gate (owner decision 2026-10-06) |
| regions-chicagoland-miami | 2026-10-05 | North Shore and Chicago concepts, regional cues | in use | R chose concepts 03, 04, 06 as style anchors (2026-10-06) |
| regions-northshore-chicago-miami | 2026-10-05 | Regional profiles draft, evidence | reference | No approval recorded |
| regions-v1 | 2026-10-05 | Regional profile data, geometry rules | reference | No approval recorded |
| weather-v1 | 2026-10-05 | Weather and time spec | reference | No approval recorded |
| sky-seasons-v1 | 2026-10-05 | Sky and seasons spec, fixtures | reference | No approval recorded |
| engine-choice | 2026-10-05 | Engine-choice review | reference | Decision input only |
| postcards-widgets-v1 | 2026-10 | Postcard and widget designs | reference | No approval recorded; app UI, not engine |
| look-fix-v1 | 2026-10-06 | Ground, lawn, shrubs, light, weather, aerial, sky fixes; "pass if" checks | in use | R had its checks added to grading (§H); R override on lawn contrast |
| vegetation-v1 | 2026-10-06 | Style-B trees and shrubs: crown construction, 4 seasons for Chicago, Denver, Miami (Denver/Front Range: cottonwood, ash, blue spruce, aspen, crabapple), shrubs, hedges, beds, willow, colours | in use | R made it the tree grading reference (§V, 2026-10-06); R's tree-crown and Denver-mix decisions build on it (2026-10-07) |
| ground-v1 | 2026-10-06 | Lawn tone, pavement rhythm, worn edges, contact shade, brick/stone addendum | landed (reference) | Landed per R (2026-10-06); R stopped further lawn micro-detail passes |
| rain-v1 | 2026-10-06 | Wetness states, puddles, rain at phone distance, snow stages | landed (reference) | R-approved temporary exception against its 10 % wet darkening (2026-10-07) |
| live-world-v1 | 2026-10-06 | Rail vehicles, elevated rail, planes, live styling | landed (reference) | Landed per R; R's live-world decisions (L1) use it |
| paintover-v1 | 2026-10-06 | Paint-overs of 6 look-loop frames, per-view grade values | landed (in use) | R requested it and its grading; R liked its lighting, not its tree shape; daytime lighting now superseded by house-contrast-v1 (R 2026-10-07) |
| fog-v1 | 2026-10-06 | Morning fog density, Sloan's Lake aerial fog, lakefront | landed (reference) | No approval recorded; night-fog-v1 (approved) is the fog target |
| night-v1 | 2026-10-06 | Dusk and night: windows, streetlights, moon, night rain/snow | landed (reference) | No approval recorded; night-fog-v1 (approved) is the night target |
| house-details-v1 | 2026-10-06 | House families, details, distance/bevel rules, colours | landed (reference) | P2 built details 1/3 and 2/3 from it; no explicit R approval recorded |
| landmarks-v1 | 2026-10-06 | 28 landmark sheets, Chicago and Denver | reference – after the look gate | R: reference, Phase 3; Cloud Gate reference only (2026-10-07) |
| weather-block-design-v1 | 2026-10-07 | Weather block app UI | pending R approval – app, after look gate | Not engine work; the all-in-one zip stays local (gitignored) |
| mascots-v1 | 2026-10-07 | App mascots | pending R approval | Not engine work |

## Haze field-level precedence — approved by R, 8 Oct 2026

| Feature | Pack | Images | Values JSON | Status |
|---|---|---|---|---|
| Shared regional visibility/background haze; 5% MOR, not 2%; mountains contrast ≥0.05 and projected height ≥2 px | haze-visibility-v1 | None delivered | [values.json](haze-visibility-v1/values.json) | **Approved by R (8 Oct 2026)**; [STATUS](haze-visibility-v1/STATUS.md) |

`haze-visibility-v1` overrides only the haze fields identified in `values.json/overrides` in lake-winter-v1, weather-moments-v1, mountain-terrain-v1 and night-fog-v1. Recompute weather-moments visibility equivalents with 5% MOR. Other content and local fog remain as scoped in STATUS; earlier pack files are retained. A2 consumes now; 5A migrates weather-moments on restart.
