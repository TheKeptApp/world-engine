# Status

**R approved – 2026-10-08.** Content approved; look is owned by style-b-calibration-v2; life rules are binding: one actor pool, events off unless verified.

**Owner lane:** P2, 5A, L1. **Phase:** Ambient life layer, after the look gate (hero market New York).

32 AI-generated three-view scene studies plus a data file for New York street life: shops, vendors, workers, vehicles, daily rhythms and waterfront, with sizes, speeds and expected counts per 150 m block face by season and hour.

Binding rules from the pack:
- Never sum all 32 activity tables or put them on one block: pick a compatible district and scenario first, cap crowd density and reserve circulation space.
- Crew, carriage and rig counts are whole assemblies including their people or vehicle; never spawn the components again from another profile. The pack never names a shared actor pool; this is its nearest rule.
- Conditional activities: Christmas-tree sellers only 25 Nov to 24 Dec (proposed window); snow maintenance only during a selected clearing operation; trash, collection and sweeping only in an explicitly selected scenario; emergency vehicles are optional background, never inferred incidents or dispatch.
- Counts are UNVERIFIED expected simultaneous visible instances per 150 m block face, not throughput; sample fractions to whole objects; shop counts include closed shops; times are illustrative clock hours, not a live schedule.
- JSON is the modelling authority; pixels do not certify scale, geometry, camera or light. No legal speed limit is inferred from animation speeds; summer AC counts are installed units, not active cooling.
- Generic people and vehicles: no detailed faces, branding, readable plates, route labels, insignia, murals, dogs or pets. The one animal allowed is the horse harnessed to its carriage, never led.

Authored or unverified: (1) Every envelope, speed, seasonal multiplier, per-150 m count, customer pattern, placement rule and calendar window is an authored preset (countStatus UNVERIFIED); not a measured New York average, supplier spec, policy or timetable. (2) The 25 Nov to 24 Dec Christmas-tree window is proposed, not a real rule. Collection, sweeping and snow-clearing activations are selected scenarios; no real route, day or alternate-side schedule is encoded. (3) Raster perspective, camera elevation, light calibration and metre accuracy are unverified and the art is illustrative. No meshes, rigging, animation engine, crowd-simulation or mobile rendering benchmark; checks are layout only. (4) Light: the hero clear-day block is a copy whose anchor file identity is UNRESOLVED; winter, snow and night lighting are pointers to nyc-hero-v1, not values.

Flags for R:
- Animals: the horse harnessed to a carriage is the pack's one animal exception, but style-b-calibration-v2 sharedLook.prohibited lists 'dogs' and 'animals'. R approved the content on 8 Oct without naming the horse: record it as an approved exception or ask R.
- Lighting: lightingReference copies the daytime master verbatim (pre-correction sky stops) and points winter, snow and night at nyc-hero-v1 hero families. README calls nyc-hero-v1 approved; INDEX lists it pending. Calibration v2 says weather and time replace the clear-day fixture, and night belongs to night-fog-v1, so do not compile any of it.
- Events: five records switch on by a proposed date window or a selected scenario (Christmas trees 25 Nov to 24 Dec; collection and sweeping pass; trash night; snow clearing), not by a verified schedule. Under R's 'events off unless verified', treat them as OFF unless verified or a labelled demo.
- Unit: counts are per 150 m block face; chicago-denver-life-v1 and sf-life-v1 use 100 m. One actor pool across packs needs one unit.

Compiled into `mock-values.json` under `style-b/life-nyc` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). Event keys carry `gatedBy: events-off-unless-verified`; the horse exception is recorded as pack content and needs R's ruling against calibration v2's animal ban.
