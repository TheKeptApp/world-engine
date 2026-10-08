# Status

**R approved – 2026-10-08.** Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.

**Owner lane:** P2, 5A, L1. **Phase:** Ambient life layer, after the look gate (hero market San Francisco).

22 AI-generated three-view studies plus a data file for San Francisco street and waterfront life: cable cars, trolleybuses, robotaxis, shops, hill parking, stair streets, sea lions and fog, with sizes, speeds, grades and hourly activity ranges.

Binding rules from the pack:
- Map first: every route, pier, street, curb, overhead network, parklet, stair path and landmark sightline comes from the map; no eligible location means count 0; markets need an active schedule (count 0 outside it).
- Count order: mapped site existence, service and event hours; then an observed or licensed feed; then hour, weekend, season and weather fallback; round once and clamp. Counts are concurrent subjects per eligible 100 m face (marine per 1 km water view, sea lions per visible 12 x 6 m dock), not trips per hour.
- Riders, crew, vendors and stalls are separate count fields; never apply marine counts to street faces. The pack states no shared actor pool.
- Hills: houses stay vertical with level floors and stepped foundations; wheels turn toward the curb downhill and away from it uphill; angled parking is back-in at mapped designated bays only; stair streets are pedestrian paths, not car routes.
- Transit and weather: cable car has an underground slot and no overhead power; trolleybus wires only where mapped; historic streetcar on the waterfront only. Fog is the regional western slab, not city-wide, integrated once in linear light; the horn clip is authored ambience that needs a mapped vessel and weather.
- No readable signs, plates or labels, brands, logos, agency patches, murals or public art, dogs or leashed animals, host overlays, encampments or poverty stereotypes. Sea lions are wild, on mapped haul-out docks only, with no staged contact.

Authored or unverified: (1) All 24-hour envelopes, weekend and season multipliers and visible-subject caps are UNVERIFIED priors; hourly peaks exceed the stated baseline range and the scene cap in 21 of 22 scenes (the cap clamps them). (2) Trolley overhead numbers (5.5 m wire height, 30 m support spacing, 0.6 m pair separation, 8 m poles) are UNVERIFIED authoring numbers, not SFMTA specifications. (3) Vehicle and vessel dimensions (trolleybus 12.2 m, coach 13 m, streetcar 14.3 m, ferry 38 x 10 m, ship 250 x 38 m, 10 m sailboat) are plausible classes, not replicas; only the cable-car 9.5 mph to 15.3 km/h conversion is sourced. (4) Parklet 12 x 2.2 m deck with 2 m clear walk, stair riser 0.165 m and tread 0.30 m, 12-riser flights with 1.8 m landings, and the curbing and back-in rules are visual proposals, not permit or code compliance; the unnamed 15% block is not located.

Flags for R:
- Animals: sea lions on a haul-out dock are expressly part of this kit, but style-b-calibration-v2 sharedLook.prohibited lists 'animals' and 'dogs'. R approved the content on 8 Oct without naming wildlife: record the sea lions as an approved exception or ask R.
- Look values: surfacePolicy (wall 0.86, trim 0.8, roof 0.9, glass 0.5, asphalt 0.92, sidewalk 0.9, foliage 0.9) and scenes[].surfaceValues (skin 0.85, bodyLight 0.45, bodyDark 0.5, metal 0.4, same in all 22 scenes) differ from calibration v2's roughness table (masonry, plaster, wood, concrete, asphalt 0.82; foliage 0.92; glass 0.28; skin 0.65; vehicle paint 0.55; painted metal 0.68). Look belongs to calibration v2: do not compile them.
- Water: surfacePolicy.waterRoughness01 0.28 and waterReflectionStrength01 0.3 differ from the lake pack values R kept on 8 Oct (roughness floor 0.18); 0.28 is the water-surfaces-v1 minimum R did not adopt. Do not compile; whether 0.28 breaks a 'floor' is unclear.
- Detail tiers: scenes use under 6, 6 to 20 and over 20 px and drop sub-2 px detail; calibration v2 owns actor detail at near 48 px and up, mid 16 to 48, far 5 to 16, cull below 5 (the thresholds chicago-denver-life-v1 keeps).

Compiled into `mock-values.json` under `style-b/life-sf` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). Scene surface values, detail tiers and face policies are not compiled; the sea-lion exception needs R's ruling against calibration v2's animal ban.
