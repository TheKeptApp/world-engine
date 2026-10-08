# WorldEngine roadmap

Owner direction as decided; details and dates live in each lane's plan. Every change here is also in `docs/decisions/owner-log.md`. Maintained by P3 on the owner's instruction.

## Principle: home + landmarks first (owner, 2026-10-06)

People look for their own house first, then for famous places. Work is ordered to serve that.

## Now: the look gate

The current phase (5A light, weather and sky; P2 buildings, yards and vegetation; P3 look loop) runs until the **look gate** passes (R, 2026-10-07): all four afternoon heroes at calibration closeness 4 or more and every aspect (sky, light, saturation, ground, foliage, materials) 3 or more. A routine run that passes triggers one full Opus confirmation run (R, 2026-10-08). See `docs/lookloop/README.md` and `docs/lookloop/calibration-baseline.md`.

## Decided scope (R, 2026-10-08)

- **Launch countries:** Canada, UK, Netherlands, Mexico, Australia, Japan (Australia, the UK and Japan drive on the left).
- **Test locations:** Chicago, Denver, Greenville SC.
- **Hero markets:** San Francisco and New York.
- **Engine capability:** terrain, slope and mountains (terrain-slope-v1, mountain-terrain-v1).
- **Builder:** Easy and Pro (creator-kit-ux-v3); Builder phase after the engine look gate.
- **Device tiers:** hero, standard, floor.
- **Live flights are ON at launch**, from the adsb.lol hosted feed (ODbL; coordinate with the operator before building). The flight database layer is kept separate; airliners only, no tail numbers; LADD and PIA aircraft are suppressed; a lawyer opinion comes before launch (`docs/research/licensing.md` Q54, §20); airport gates later via a paid feed or FAA SWIM. Estimated cost about $7-25 a month at 1k monthly users and $35-150 at 100k (the research's estimate, not a quote).
- **Real mode** is a future idea, not scheduled.

## Milestones (order, not dates; P3's ordering from R's decisions, R can change it)

1. **Engine look gate** (now): the four heroes at closeness 4 or more, every aspect 3 or more, confirmed by an Opus run.
2. **After the look gate:** Builder phase (Easy and Pro; venues and campuses parts, `venues-campuses-v1`), the ambient life layer (life packs, `regional-car-mix-v1` for P2's ambient vehicles; one actor pool, events off unless verified), and streaming.
3. **Engine capability:** terrain, slope and mountains. The mountain pack's r2 fixes and hiking trails reached the drop folder after R's 8 Oct note; R has not reviewed them yet.
4. **Launch:** the six countries, live flights on, hero markets San Francisco and New York, test locations Chicago, Denver and Greenville SC; device tiers hero, standard and floor.
5. **Later:** airport gates, real mode, coverage growth. City kit status per city: `docs/proposals/master-trackers-v1/coverage-by-country-Cities.csv` (the city-kit checklist; `coverage-by-country-Countries.csv` has the country rows).

## Phase 3: live world + landmarks (right after the look gate)

- **Live world** (L1): live sky, transit and ambient planes, as already planned (`docs/live-world/`).
- **Landmark pack, Chicago + Denver**, about 10 each, alongside the live world. Examples: Willis Tower, Wrigley Field, Soldier Field, Northwestern campus; Colorado State Capitol, Coors Field, Red Rocks.
- **Design reference:** `docs/proposals/landmarks-v1/` (28 sheets, 18 Chicago + 10 Denver).
- **How landmarks are picked:** candidates from map tags, ranked by Wikipedia/Wikidata popularity.
- **Three tiers:**
  1. Hero models: agent-built and owned.
  2. Tuned generators: a generator adjusted for one specific landmark.
  3. Type generators: stadiums, campuses, airports, hospitals, malls.

## Wave 2 landmarks (R approved 2026-10-07; PROPOSED order)

`docs/proposals/landmarks-style-b-v2/`: 65 landmark studies and 13 skyline far-views over 13 metros (New York, Los Angeles, San Francisco, Seattle, Boston, Washington, Philadelphia, Atlanta, Dallas-Fort Worth, Houston, Austin, Nashville, Phoenix). Approved for look, topology, must-be-exact requirements and detail tiers; dimensions unverified except four heights; skylines are concept only, never sightlines. **Build order later: San Francisco and New York landmarks first**, after P2's infrastructure stages and the v1 shells (Wrigley, Bahá'í, Empower). P1 verifies the 15-item list first (`sources.md`, "Verify first"); the trademark and architectural-rights check before any marketing use is on the lawyer list (`docs/research/licensing.md` Q53).

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
- **PROPOSED — ground-state layer** (P1, after the look gate's data needs): wet / dry / snow / ice per area, labelled "estimated", built from NOAA data (MRMS rain, NOHRSC / SNODAS snow, melt) plus our own sun and shadow. Owner-decided weather source rules are in `docs/decisions/owner-log.md` (2026-10-07).
- **Planned change — NOAA HRRR → RRFS:** NOAA plans to replace the HRRR short-range model with RRFS; the research cites a 3 Nov 2026 implementation notice, but dates conflict and need confirming. P1 plans the switch for any HRRR-derived input.
- **Hosting estimate (hypothetical, not a plan):** Cloudflare R2 storage and reads about $1.35–70 a month for 10k–1M monthly users, under the research's assumptions (100 GB stored, 200 origin requests and 100 MB per user a month, no edge caching; delivery, compute, live APIs and taxes excluded).


## After the look gate: "alive" and AI layers — PROPOSED (R decides)

Nothing in this section is decided. Owners are the proposed lanes.

1. **PROPOSED — responsiveness** (5A): 60 fps held while moving; area streaming with prefetch ahead of the camera; instant relaunch to the last view; smooth time scrubbing.
2. **PROPOSED — ambient life layer** (5A rendering, P2 generators, L1 live data): rules on the device, no runtime AI. Wind in trees, clouds moving with the live wind, traffic, birds, dusk lights. Everything labelled simulated.
3. **PROPOSED — NPCs:** varied daily routines (dog walkers, joggers, school runs, porch sitters, game-day crowds near stadiums) written with AI offline at build time and run by simple rules on the phone. Live on-device AI only for optional interaction (for example tapping an NPC), on newer phones only. NPCs are always labelled simulated and never represent real people; any crowd sized from real data shows its source.
4. **PROPOSED — local area feed** (server side, cached per area, not per user):
   - a) Phase 1, official open data: road closures, permits, 311, city events, school closings, NWS alerts.
   - b) Phase 2, news: headline and source link only; AI summaries only where licensing allows; no scraping. Lawyer question: `docs/research/licensing.md` Q48.
   - c) No crime mapping or crime heat overlays; safety appears only as official alerts.
   - Every item shows its source and time, and a "summary" label when AI-written.
5. **PROPOSED — on-device AI, optional extra:** plain-language map questions, a "your block" weather brief, one-line alert summaries, using Apple's on-device Foundation Models (iOS 26, iPhone 15 Pro and newer only) with a non-AI fallback. AI text is never shown as observed data. Ships with the weather-for-your-block app, not the engine core.

## Creator kit — PROPOSED (R's lead wedge candidate; pending creator-kit-demand-v1 research)

Nothing in this section is decided, except the UX direction: **R approved `creator-kit-ux-v3` on 2026-10-08** (Easy + Pro, supersedes v2) with the **Builder phase after the engine look gate**. Order: after the look gate and streaming; demand research now (ChatGPT, `creator-kit-demand-v1`).

1. **PROPOSED — creator kit:** non-technical users start from a ready-made view of their real place, add detail from a Style B parts kit, and share or embed a live view (weather, sun, time).
   - Paid tiers: free private builds; per event; per site monthly; business tier. Prices to be set from the research.
   - First segment candidate: race and event organizers.
2. **PROPOSED — trust model (protects the base map):**
   - Two layers: the base map (verified) and customer overlays (private to their build or share). Overlays never change the base map.
   - Temporary items (routes, tents, phases) carry dates and expire.
   - Permanent facts (shape, roof, door, species) are promoted only with evidence: agreement with other data, independent confirmations or a verified owner, and automatic sanity checks.
   - Contributors have trust levels; verified owners are prioritized for their own property.
   - Every fact is labelled observed, community or owner-verified, with author and date. Everything is reversible through stable IDs and the migration map, with bulk revert for vandal accounts.
   - Promotions are reviewed by a person at first, with agent-assisted triage.
3. **PROPOSED — community corrections:** users fixing doors, species and roofs on their block feed the same promotion pipeline.
4. **PROPOSED — official partner builds** (universities, stadiums) with licensed logos and colours, as a partnership product. Outside partner builds, the legal lines above still apply (no logos on models).

Lawyer questions: `docs/research/licensing.md` Q49–Q52 (user-content ownership and licence including ODbL, contributor warranties, takedown/DMCA, logos and trademarks in user builds). The engine stays generic (CLAUDE.md): the kit, accounts and user content belong to the app and a service, not the engine.

## Licensing path to revenue — PROPOSED (R decides)

From ChatGPT's competitors-as-customers teardown (`docs/research-gpt/creator-kit-demand-v1/competitors-as-customers.md`, `.csv`; research, unverified). Nothing in this section is decided.

1. **PROPOSED — engine licensing:** 5–7 engine-licensing deals (ranges from the teardown: Mapme, CampusTours, Concept3D, OnePlan, Terranaut, Racemap) could reach about $150–200k a year. Shadowmap is a partner, not a customer. All figures are the research's estimates, not quotes.
2. **PROPOSED — sequence after the look gate:**
   - a) Streaming core and the three.js web viewer together, on a shared tile format.
   - b) First SDK: a WorldEngine custom 3D layer for MapLibre GL JS (reaches Mapme, Felt and other MapLibre products).
   - c) Embeddable viewer (iframe) for partners not on MapLibre.
   - d) Coverage growth.
3. **PROPOSED — licensing prerequisites to plan for:**
   - Web and Android browser support.
   - A coverage list with the age of each source.
   - About 99.9 % availability, with burst capacity for events.
   - OEM and white-label terms metered by views or sites.
   - Customer data (routes, BIM, plans) stays authoritative over ours.
   - Weather labelled observed or forecast.

Licensing questions already open: `docs/research/licensing.md` (Q49–Q52 user content and logos; §16 data layers; §18 weather redistribution). The engine stays generic (CLAUDE.md): SDKs and viewers wrap it; partner logic stays in the partner's app.
