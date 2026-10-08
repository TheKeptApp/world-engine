# Status

**R approved – 2026-10-08.** Approved; supersedes canada-style-b-v1.

**Owner lane:** P2, P1. **Phase:** Launch country Canada, after the look gate.

Style B design pack for the Canada launch country; it replaces canada-style-b-v1's visual concepts. 16 boards: 11 building types, 6 district boards, 2 block paint-overs, transit, street details, seasons and lawns, weather moments and a night strip, for Toronto, Vancouver and Montréal.

Binding rules from the pack:
- Driving side is RIGHT. Observed geometry overrides these defaults. Numeric ranges are authored proposals, not surveys, zoning or city standards. Calibration lighting and exposure apply once; weather replaces the clear-day fixture; local material colours do not justify separate city exposure grades.
- Signs and signals come from road-signs-signals-v1 (Ontario baseline; BC and Québec overrides still to verify). Sign panels are blank coloured bands for bilingual layouts. Generated lamps may show several colours at once: never copy them as live phases; use one exclusive state per head.
- Snow: do not raise all terrain; layer banks on curb-edge strips; keep breaks for doors, stair treads, curb ramps, crosswalks, transit boarding and lanes. The Montréal removal convoy is a staged picture, not live data. Do not infer citywide thresholds from one borough's procedure.
- Seasons follow observed weather and phenology, with no fixed calendar switch. Cherry blossom is local and short. Vancouver winters are usually wet and green, with snow as an episode. Eastern lawns go dormant under variable snow. Autumn leaf litter is local.
- When building, remove brick and road microtexture and dense distant leaf geometry; the art is more detailed than the runtime target. Paint-overs keep each block approximately. No logos, readable text, dogs, real murals or public art. Concepts, not engine captures; the 45 degree view is art-directed.
- Data rules: Vancouver lidar uses CGVD28GVRD but HRDEM uses CGVD2013, so transform, never align by eye. Toronto trees can be address-geocoded. TTC GTFS is static only. MSC licence (v2.1.1, Aug 2026) needs its own credit and must not alter warnings.

Authored or unverified: (1) All numbers are authored: storeys, lot widths, setbacks, street and right-of-way widths, tree mixes, snow bank heights and palette hexes. None is measured. Tree mixes are labelled 'not inventory'. Snowbank rules are visual rules, not city policy. (2) Licences were read on 7 Oct 2026 and nothing was ingested. Unverified: Toronto 3D archive contents, Vancouver licence full text, Montréal pages (direct access blocked; read via catalogue index), HRDEM coverage, OSM completeness in all three cities, BC and Québec signs. (3) Images are AI-generated concepts with schematic backdrops and art-directed cameras. The phone check was Chrome emulation: 51 layout checks at 320, 390 and 1440 px, with no physical Safari or iPhone test and no performance test.

Flags for R:
- Look: sharedLook equals calibration-v2's uncorrected JSON (sky #73A5CC, #A2C4DC, #DBDCD1); calibration-v2 STATUS.md corrects it to #7AAFE2, #8FBAE7, #A0C8F2. Do not compile this pack's sharedLook. The night strip look belongs to night-fog-v1 (approved). Autumn reds and yellows on the sheet match foliage-seasons-v1 (#B34B32 maple red, #D6B342 Norway maple yellow); no clash seen.
- Street geometry: street-geometry-rules-v1 (CA rows) wins. Residential 8.5 m vs pack 6-9 (Toronto, Vancouver) and 6-10 (Montréal); arterial 12.6 vs 12-20; lane 4.5 vs service lane 4-6; sidewalk 1.8 (2.1 on arterials) vs 1.7-3. Right-of-way totals have no rule row. Boards draw protected bike lanes; the rules give no dedicated cycle geometry.
- Supersedes v1: values.json replaces canada-style-b-v1 'visual concepts', but v1 (delivered, not approved) also holds archetypes this pack drops (worker cottage, main-street mid-rise, West Coast modern, Edwardian wood), yards, vehicles and furniture sheets, and a 35k-triangle budget with size tiers. Which stay is unclear. regional-car-mix-v1 already owns Canada's cars.
- Snow: snowbank_rules fix heights by city (Toronto 0.15-0.6 m, Montréal 0.4-1.2 m, Vancouver 0-0.3 m, piles to 1.8 m). Approved lake-winter-v1 old-snow states, carried in weather-moments-v1, use bank 0.15-0.3 m, pile 0.3-0.45 m, curb zone 0.8 m, driven by snow history, with no plowing inferred. Its rules win; no Canadian snow rule exists: unclear.

Compiled into `mock-values.json` under `style-b/canada` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). The `street_profiles_m` keys carry `supersededFor: geometry` and `signals_rules` carries `supersededFor: signs-signals` (street-geometry-rules-v1 and road-signs-signals-v1 own them); `snowbank_rules` (fixed heights per city) is not compiled because the approved weather rules are history-driven.
