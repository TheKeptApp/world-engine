# Design packs index

Maintained by P3 (not written by ChatGPT; added on the owner's instruction, 2026-10-07). One place to find the mock for any visual feature. Approved packs are the exact visual direction: lanes build to match them (CLAUDE.md, "Visual work builds to approved mocks"; owner-log 2026-10-07). Full history per pack: `docs/design-registry.md`.

**Where the images are.** Pack images (PNG, JPG, ZIP, large SVG) are gitignored, so they are **not in worktrees or fresh clones** (checked 2026-10-07: a fresh worktree has the README and JSON but no `images/`). Open them from the owner's checkout, which always has them:

- `~/Desktop/world-engine/docs/proposals/<pack>/` (primary; P3 copies every pack's images there when it files the pack)
- `~/Library/Mobile Documents/com~apple~CloudDocs/WorldEngine-Design-Backup/proposals/<pack>/` (iCloud backup, same layout)

The README, values JSON and prompts are committed, so they are readable from any worktree at `docs/proposals/<pack>/`.

**Status:** "R approved – binding target" when the pack has a `STATUS.md` saying R approved; "pending R approval" otherwise (packs filed before the rule are marked "in use (pre-rule; R to confirm)").

| Feature | Pack | Images (owner's checkout) | Values JSON (repo) | Status |
|---|---|---|---|---|
| Night and fog | night-fog-v1 | `~/Desktop/world-engine/docs/proposals/night-fog-v1/images/` | `docs/proposals/night-fog-v1/night-fog-values.json` | **R approved – binding target** |
| Houses (contrast) | house-contrast-v1 | `~/Desktop/world-engine/docs/proposals/house-contrast-v1/images/` | `docs/proposals/house-contrast-v1/paintover-values.json` | pending R approval |
| Lake water and winter (ice, tree snow, old snow) | lake-winter-v1 | `~/Desktop/world-engine/docs/proposals/lake-winter-v1/` (images at the pack root) | `docs/proposals/lake-winter-v1/lake-winter-values.json` | pending R approval |
| Sky, lighting and grade per view (exposure, contrast, saturation, warmth, shadows, crowns, water) | paintover-v1 | `~/Desktop/world-engine/docs/proposals/paintover-v1/images/` | `docs/proposals/paintover-v1/paintover-values.json` | in use (pre-rule; R to confirm) |
| Trees (crowns, seasons, regions) and trunks | vegetation-v1 | `~/Desktop/world-engine/docs/proposals/vegetation-v1/images/` | `docs/proposals/vegetation-v1/vegetation-colours.json` | in use (pre-rule; R to confirm); Denver list superseded by owner decision 2026-10-07 |
| Ground and paths (lawn, paving, worn edges, brick/stone) | ground-v1 | `~/Desktop/world-engine/docs/proposals/ground-v1/images/` | `docs/proposals/ground-v1/ground-colours.json` | in use (pre-rule; R to confirm) |
| Rain and wet surfaces | rain-v1 | `~/Desktop/world-engine/docs/proposals/rain-v1/images/` | `docs/proposals/rain-v1/rain-values.json` | in use (pre-rule; R to confirm) |
| Night (dusk, windows, streetlights, moon) | night-v1 | `~/Desktop/world-engine/docs/proposals/night-v1/images/` | `docs/proposals/night-v1/night-values.json` | in use (pre-rule); night-fog-v1 is the approved night target |
| Fog | fog-v1 | `~/Desktop/world-engine/docs/proposals/fog-v1/images/` | `docs/proposals/fog-v1/fog-values.json` | in use (pre-rule); night-fog-v1 is the approved fog target |
| Houses (families, details, colours) | house-details-v1 | `~/Desktop/world-engine/docs/proposals/house-details-v1/` | `docs/proposals/house-details-v1/house-details-colours.json` | in use (pre-rule; R to confirm) |
| Landmarks (Chicago, Denver) | landmarks-v1 | `~/Desktop/world-engine/docs/proposals/landmarks-v1/images/` | `docs/proposals/landmarks-v1/landmarks-colours.json` | reference – build after the look gate; Cloud Gate reference only |
| Live objects (rail, planes) | live-world-v1 | `~/Desktop/world-engine/docs/proposals/live-world-v1/images/` | `docs/proposals/live-world-v1/live-style.json` | in use (pre-rule; R to confirm) |
| Look fixes (ground, light, weather, aerial edges, sky) | look-fix-v1 | `~/Desktop/world-engine/docs/proposals/look-fix-v1/images/` | `docs/proposals/look-fix-v1/sky-projection-reference.json` | in use (pre-rule; R to confirm) |
| Weather block (app UI design) | weather-block-design-v1 | `~/Desktop/world-engine/docs/proposals/weather-block-design-v1/images/` | `docs/proposals/weather-block-design-v1/design-values.json` | pending R approval (UI, not engine) |
| Mascots (app characters) | mascots-v1 | `~/Desktop/world-engine/docs/proposals/mascots-v1/` | – | pending R approval (app, not engine) |
| Visual spec, concepts and rubric | visual-v2 | `~/Desktop/world-engine/docs/proposals/visual-v2/images/` | `docs/proposals/visual-v2/comparison-presets.json` | in use (grading source of truth) |
| Weather and time concepts | experience-v1 | `~/Desktop/world-engine/docs/proposals/experience-v1/images/` | `docs/proposals/experience-v1/showcase-presets.json` | in use (concept parity targets) |
| Regional concepts (North Shore, Chicago) | regions-chicagoland-miami | `~/Desktop/world-engine/docs/proposals/regions-chicagoland-miami/images/` | `docs/proposals/regions-chicagoland-miami/region-catalog.json` | in use (style anchors 03, 04, 06) |

Older and reference-only packs (visual-v1, weather-v1, sky-seasons-v1, engine-choice, regions-v1, regions-northshore-chicago-miami, postcards-widgets-v1): see the registry. Research (not design) is under `docs/research-gpt/`.
