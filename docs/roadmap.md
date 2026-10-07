# WorldEngine roadmap

Owner direction as decided; details and dates live in each lane's plan. Every change here is also in `docs/decisions/owner-log.md`. Maintained by P3 on the owner's instruction.

## Principle: home + landmarks first (owner, 2026-10-06)

People look for their own house first, then for famous places. Work is ordered to serve that.

## Now: the look gate

The current phase (5A light, weather and sky; P2 buildings, yards and vegetation; P3 look loop) runs until the look gate passes (concept parity ≥ 100 % on the v2 floors; full Opus gate when a routine run reaches 92 %). See `docs/lookloop/README.md`.

## Phase 3: live world + landmarks (right after the look gate)

- **Live world** (L1): live sky, transit and ambient planes, as already planned (`docs/live-world/`).
- **Landmark pack, Chicago + Denver**, about 10 each, alongside the live world. Examples: Willis Tower, Wrigley Field, Soldier Field, Northwestern campus; Colorado State Capitol, Coors Field, Red Rocks.
- **Design reference:** `docs/proposals/landmarks-v1/` (28 sheets, 18 Chicago + 10 Denver).
- **How landmarks are picked:** candidates from map tags, ranked by Wikipedia/Wikidata popularity.
- **Three tiers:**
  1. Hero models: agent-built and owned.
  2. Tuned generators: a generator adjusted for one specific landmark.
  3. Type generators: stadiums, campuses, airports, hospitals, malls.

## First flagship app: home personalization

- On-device-only house personalization: colour, roof, door, car and yard.
- Never uploaded and never shown to others.
- Ships with the first flagship app. The engine stays generic (CLAUDE.md): it receives the choices as plain inputs and stores nothing.

## Every new city

Landmarks first, then general coverage.

## Legal lines for models

- Buildings may be modelled.
- Public artworks and sculptures (for example Cloud Gate, the Chicago Picasso) are excluded unless permission is obtained. Cloud Gate appears in landmarks-v1 as a reference only (owner, 2026-10-07): written permission first.
- No team, university or sponsor logos or names on models.

## Build model

- Everything in the engine is agent-built and owned; no marketplace assets.
- ChatGPT does design, research and draft code, delivered only to the drop folder (`~/Desktop/worldengine-gpt-drop/`).
- A Claude lane reviews, tests and commits all code. ChatGPT research is spot-checked before use.

## Data layers — PROPOSED (R decides)

From ChatGPT's data-layers research (`docs/research-gpt/data-layers-research-v1/`), not yet verified. Nothing here is decided.

- **PROPOSED — top layers, in priority order:** crop type, phenology, water, terrain, tides, building footprints, places, park amenities.
- **PROPOSED — rights order:** our own apps use a layer first; licensed or redistributed products include it only after its rights are confirmed (`docs/research/licensing.md` §16, Q44–Q46).
- **PROPOSED — water:** USGS legacy water services retire in February 2027, so any water layer uses the new USGS APIs from day one.
- **PROPOSED — snow states need weather history:** how much snow lies on the ground depends on snowfall over the last 1–3 days and on melt, not just today's weather. A future P1 data task supplies that history to the snow states.
- **Hosting estimate (hypothetical, not a plan):** Cloudflare R2 storage and reads about $1.35–70 a month for 10k–1M monthly users, under the research's assumptions (100 GB stored, 200 origin requests and 100 MB per user a month, no edge caching; delivery, compute, live APIs and taxes excluded).

