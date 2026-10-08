# Status

**R approved – 2026-10-08.** Approved, including the NYC board (nyc-verification.json and the nyc-check screenshots).

**Owner lane:** 5A, L1. **Phase:** Weather states (look gate and the alive layer); NYC board included.

Before/after hero moments for 21 weather, time-of-day and night states across nine regions, including four New York pairs, with numeric endpoint targets and a proposed, unconnected live-data binding plan.

Binding rules from the pack:
- Weather and actual time override the clear-day fixture (house-contrast sharedLighting is copied unchanged as base). Apply exposure once; no second darkening layer (rain pack cap 12% per surface), no duplicate AO or fog; one extinction term across terrain, buildings, trees and water.
- Keep camera, lens, road and shore polygons, building identity and trunk positions stable; interpolate sky and light in linear RGB. Rain and snow pools ramp over 5 s and fog over 20 s, as presentation targets, not predictions.
- Keep surface-water and snow reservoirs independent and history-driven: no instant dry road, no lake freeze inferred from snowfall, no instant leaf-colour switch. Wet reflections only on eligible stable patches, never mirror roads.
- Gating: a rainbow needs visible sun plus a sunlit rain volume opposite it; alpenglow needs terrain still sunlit; hail is a sparse optional cue with no damage solver; desert stars need real catalogue and sidereal positions, no invented constellations or moon.
- Live bindings are proposed only: keep observed, forecast, history and demo separate with age or staleness shown; missing data never silently becomes live. Dust wall, rainbow, cloud geometry, foliage peak and street wetness need regional evidence or a labelled authored fallback.
- No dogs, people or characters, logos, brands, signage text or host-app content; architecture and terrain stay intact through storms. All numeric values are authored targets.

Authored or unverified: (1) All numeric endpoints are authored targets, not sampled from pixels; before and after cameras only approximately match; no engine, device performance, physical colour or live-event validation. (2) Live bindings are proposed, not connected or tested (78 bindings, all proposed_adapter_not_connected). Documentation checked 7 Oct 2026 only; MRMS and GOES product mapping unverified; the NHC fetch returned 403 (adapter unverified); solar and phenology are required or authored inputs, not feeds. (3) Not observable from the generic feeds: dust-wall position, rainbow occurrence, exact cloud geometry, foliage peak, street-level wetness. Marine fog layer geometry and the dust approach are authored examples. (4) Solar fixtures are not ephemeris-verified (ephemerisVerified false on all 42 endpoints); the NYC low-sun alignment is an illustrative canyon fixture; Ocean Drive fixture placement and colours are unsurveyed.

Flags for R:
- Fog exposure: every endpoint uses relativeEV +0.35 (blue hour +0.20), but night-fog-v1's morning-fog state is +0.10 (direct sun 0.45, haze 0.0015/m). The sf-fog and sf-gold endpoints (fog 0.008 and 0.004/m) use +0.35. No approved pack defines overcast or rain exposure; which value wins is unclear.
- Clear-state sky: endpoints and the inherited sharedLighting use the pale house-contrast JSON (zenith #73A5CC). R's images-beat-JSON corrections replace it (house-contrast #6FAFE4, #91C4ED, #A7CFED; calibration-v2 #7AAFE2, #8FBAE7, #A0C8F2). Board pixels were not sampled here, so the size of the disagreement is unmeasured.
- The four NYC pairs versus nyc-hero-v1's light states (approved together): winter low sun 8 deg / 225 deg here (before 25 deg) against 15 deg / 155 deg there; snow day direct light 0.08 against directSun 0; rainy night via rain-v1 steady_rain (asphalt roughness 0.52, patch-only reflections) against wetRoadRoughness 0.2-0.35. No precedence is stated.
- nyc-rain-night reuses the Miami Ocean Drive accent block unchanged (amber #F3B96F, coral #EAAE98, turquoise #8ECBC4), while nyc-hero-v1's rainy night is warm neutral lamps with no neon.

Compiled into `mock-values.json` under `style-b/weather-moments` (the copied look or lighting block is not compiled: look is owned by `style-b-calibration-v2`). The exposure keys repeated on every endpoint are not compiled (see the `weather-exposure` ruling pending in `precedence`).
