# Form coverage: do the engine's shapes match the mocks?

2026-10-07, read-only audit (no grading runs) of every design pack's visible forms — species × season, crown construction, branch structure, winter forms, blossom, aerial read, shrubs, ground forms, house forms, water, ice, snow, fog, night, live objects — against the engine (main). Colour values are audited separately in `mock-coverage.md`. Details per element: [vegetation](form-coverage-vegetation.md), [ground, houses and the rest](form-coverage-other.md). Phone-size side-by-sides (render vs mock) are local only, under `docs/lookloop/form-sides/<pack>/` in the p3-lookloop worktree (gitignored); most use the whole mock sheet, not a tight crop.

Status counts (built / partial / missing): vegetation-v1 7 / 60 / 21 of 88 elements (64 species × season cells plus 24 construction, shrub and colour elements); ground-v1 4 / 3 / 2; house-details-v1 7 / 3 / 0; house-contrast-v1 2 / 3 / 0; lake-winter-v1 1 / 3 / 3; night-fog-v1 1 / 1 / 2; rain-v1 3 / 2 / 0; look-fix-v1 3 / 1 / 1; live-world-v1 0 / 0 / 5; landmarks-v1 not due (Phase 3).

## Top 10 visible vegetation form gaps

| # | Gap | Status | Owner |
|---|---|---|---|
| 1 | Crowns read as balls on a pole (the pack's "too crude"), not merged masses; the default solid crown style is used, leaf cards and puffs are off | partial | P2 |
| 2 | No readable sky holes or forks: limbs exist but are hidden inside solid lobes | partial | P2 |
| 3 | Winter bare trees: 3–4 thick limbs, no twig orders | partial | P2 |
| 4 | Peak-fall forms read as orange/yellow balloons (colours already right) | partial | P2 (5A crown shading) |
| 5 | Spruce and blue spruce: smooth stacked cones, no ragged drooping tiers | partial | P2 |
| 6 | Aerial read: one or two spheres per tree | partial | P2 |
| 7 | Root flare only in the puffs style; contact darkening not visible | partial | P2 (flare), 5A (contact) |
| 8 | Foundation shrubs are small grey-green pills | partial | P2 |
| 9 | Elm and honey locust reuse the oak shape (no vase or umbrella) | partial | P2 |
| 10 | Denver yards: no bed islands, mulch, rocks or grass ribbons | missing | P2 |

Also missing: Miami (no region or species), crabapple spring blossom, winter twigs on shrubs; aspen only for tagged trees, no clumps.

## Top 10 visible form gaps outside vegetation

| # | Gap | Status | Owner |
|---|---|---|---|
| 1 | Streetlight pools on the ground | missing | 5A |
| 2 | Real reflective puddles | partial | 5A |
| 3 | Lake ice sheets and edges | missing | 5A |
| 4 | Old-snow piles and slush | missing | P2 shapes, 5A shading |
| 5 | Ground-fog layer (fog is distance-only) | missing | 5A |
| 6 | Water bands and waves | partial | 5A |
| 7 | Brick and stone streets (only gravel `surface=` handled) | missing | P2 |
| 8 | Hero-house porch, trim and eave depth vs the house-contrast mocks | partial | P2 |
| 9 | Snow on boughs and roofs as shapes | partial | 5A |
| 10 | Elevated rail and trains | missing | L1 |

Statuses come mostly from code and data evidence; a few were checked by eye on the side-by-sides.
