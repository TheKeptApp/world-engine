# Status

**R approved – 2026-10-08.** Approved for P2's ambient vehicles.

**Owner lane:** P2. **Phase:** Ambient vehicles, after the look gate.

Per-region defaults for ambient light-duty cars on ordinary streets: body class, colour, BEV overlay, age, parking and density by street class and local hour, plus plate proxies and shared rain, road-film, salt and snow states, for 12 regions (6 US metros, 6 countries).

Binding rules from the pack:
- Mix: seven mutually exclusive body classes (kei takes precedence; kei is 0 outside Japan, 38 in Japan), eight finish colours, BEV as a separate powertrain overlay (EV means BEV; Canada's 5.2 % EV includes hybrids and is not used). Moving mixes shift 2 points from sedan to van.
- Market shares: every city share (body, colour, BEV, age, parking, density, material states) is an UNVERIFIED authoring fixture; only Canada's national SUV/crossover 41.9 % and passenger 35 % are verified, as proxies. Country rows are representative urban defaults, not national fleets. Replace with observed local weights when available.
- Traffic side: left in UK, Australia, Japan; right in the six US metros, Canada, Netherlands, Mexico. Mapped lane topology, one-way streets and restrictions override the region default; parked orientation comes from the map.
- No logos, badges, brand grilles or plate text. Plates are blank rectangles of regional proportion and colour (no serials, flags, seals or country codes); no taxi branding. Cars keep true size, never enlarged; cull below 5 projected px.
- Density means simultaneous vehicles per 100 m, not per hour. Clamp to mapped legal bays and driveway pads; never block driveways, crossings, fire accesses or cycle lanes; leave the curb clear if restrictions are unresolved; do not overlap hulls to hit a count.
- Rain film, salt and snow caps appear only when weather, travel or treatment history supports them. No regional grime or damage stereotype; age never forces damage; keep driving glass clear; apply the wet state once, not to world exposure.

Authored or unverified: (1) Fine body and colour mixes for all 12 regions, BEV shares, three-band age mixes, parking-location shares, condition percentages and moving-traffic shifts are authoring fixtures; only national aggregates (Canada SUV 41.9, passenger 35; Japan 37.716 mini share) are sourced. (2) All 300 density cases, hour multipliers, speeds and headways are proposals; no local traffic or parking counters were imported; not traffic or road-design guidance. (3) Plate sizes except California's 12 x 6 in are design proxies; Mexico right-side clause not extracted; Canada keep-right page not re-verified; Netherlands RDW aggregate retrieval failed (no body or colour extraction). (4) Vehicle dimensions are authoring targets, not manufacturer data; rain, road-film, salt and snow parameters are unverified authoring states.

Flags for R:
- Minor, against R's geometry-vs-look rule (street-geometry-rules-v1 owns street geometry): the parallel bay guide here is 6 x 2.3 m for every region, while that pack gives 2.3 m for the US but 2.1 m (CA) and 2.0 m (UK, NL, JP); it does not cover MX or AU. Take bay and street widths from mapped data and that pack; use this pack for car footprints, mixes and counts.

Compiled into `mock-values.json` under `style-b/car-mix` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`).
