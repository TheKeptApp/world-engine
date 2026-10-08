# Haze + visibility v1

Use meteorological optical range (MOR) as the shared visibility control. Front Range clear fallback is **75 km, with a 50–100 km envelope**; Chicago summer clear fallback is **20 km, with a 15–25 km envelope**. Valid local observations/models override these authored regional presets. This pack is a design specification pending owner approval; it has not changed engine files or prior packs.

## Formula and units

`sigma = -ln(0.05) / (1000 × visibility_km) = 2.995732273554 / (1000 × visibility_km)`; `T = exp(-sigma × distance_m)` in uniform air, or `T = exp(-∫sigma(s) ds)` through layers. In linear light, uniform-air output is `T × lit_surface + (1−T) × airlight`. This follows the 5% MOR convention in [WMO No.8, Part I chapter 9](https://www.weather.gov/media/epz/mesonet/CWOP-WMO8.pdf).

Old weather-moments `visibilityEquivalentM` values use approximately **3.912/sigma**, the 2% convention. Recompute with 2.995732/sigma; do not mix conventions. The preset visibility range in JSON maps to an ascending extinction range in reverse order. Values are full-precision formula results rounded to 12 decimal places.

| Case | MOR km | Extinction /m | T at20km | T at50km | T at100km |
|---|---:|---:|---:|---:|---:|
| Front Range clear | 75 | 0.000039943 | 0.4498 | 0.1357 | 0.0184 |
| Chicago summer clear | 20 | 0.000149787 | 0.0500 | 0.0006 | 0.0000 |
| Old lake fixture | 3.745 | 0.000800000 | 0.000000113 | 4.25e−18 | 1.80e−35 |

## Region and season presets

**Authored/unverified regional envelopes, not measured averages or probabilities.** The two requested anchors are owner design targets. Other values are reasonable calibration starting points requiring local validation. Each region × local season × six weather states is expanded in `values.json` with km, /m, and ranges. Summer is DJF in Australia, JJA in the Northern Hemisphere; tropical wet/dry regimes need local data. Canada, Mexico, Australia and Japan are split by climate rather than assigned a national atmosphere.

| Region | Clear spring / summer / autumn / winter km | Hazy km, same order | Humid km, same order |
|---|---|---|---|
| Denver / Colorado Front Range | 75 / 75 / 90 / 85 | 30 / 25 / 40 / 35 | 20 / 18 / 25 / 20 |
| Chicago / Great Lakes | 35 / 20 / 40 / 45 | 20 / 15 / 25 / 25 | 15 / 12 / 20 / 20 |
| Northeast / Mid-Atlantic | 40 / 25 / 45 / 50 | 20 / 15 / 25 / 25 | 15 / 12 / 20 / 20 |
| Southeast inland | 35 / 25 / 40 / 45 | 20 / 15 / 25 / 25 | 15 / 12 / 20 / 20 |
| Southern Plains / Hill Country | 45 / 35 / 50 / 55 | 25 / 20 / 30 / 30 | 20 / 15 / 25 / 25 |
| Gulf / subtropical coast | 30 / 25 / 35 / 40 | 18 / 15 / 20 / 25 | 12 / 10 / 15 / 18 |
| Pacific marine coast | 55 / 45 / 60 / 50 | 30 / 25 / 35 / 30 | 20 / 15 / 25 / 20 |
| Arid Southwest / inland California | 70 / 60 / 80 / 80 | 35 / 25 / 40 / 40 | 25 / 20 / 30 / 30 |
| UK maritime | 40 / 35 / 45 / 40 | 25 / 20 / 25 / 20 | 20 / 15 / 20 / 15 |
| Netherlands lowland | 40 / 35 / 45 / 40 | 25 / 20 / 25 / 20 | 20 / 15 / 20 / 15 |
| Mexico highland | 50 / 40 / 55 / 60 | 25 / 20 / 30 / 30 | 20 / 15 / 25 / 25 |
| Mexico tropical coast | 30 / 25 / 35 / 35 | 18 / 15 / 20 / 20 | 12 / 10 / 15 / 15 |
| Australia temperate coast | 50 / 45 / 55 / 55 | 30 / 25 / 35 / 30 | 20 / 18 / 25 / 20 |
| Australia dry interior | 80 / 70 / 90 / 90 | 40 / 30 / 45 / 45 | 30 / 25 / 35 / 35 |
| Japan temperate urban | 40 / 25 / 45 / 55 | 20 / 15 / 25 / 30 | 15 / 10 / 20 / 25 |
| Japan northern | 50 / 40 / 55 / 55 | 30 / 25 / 35 / 30 | 20 / 15 / 25 / 20 |

Smoke, falling rain and falling snow use the following conditional defaults in **every region and season**; this intentional consistency reflects event severity, not likelihood. Seasons never activate smoke, rain or snow. Wet streets, settled snow and cloud cover alone do not reduce visibility.

| State | Default km | Envelope km | Default extinction /m |
|---|---:|---:|---:|
| clear (Front Range spring example for first three states) | 75 | 50–100 | 0.000039943 |
| hazy (Front Range spring example for first three states) | 30 | 22.5–37.5 | 0.000099858 |
| humid (Front Range spring example for first three states) | 20 | 15.0–25.0 | 0.000149787 |
| smoke (Front Range spring example for first three states) | 5 | 1–15 | 0.000599146 |
| rain (Front Range spring example for first three states) | 5 | 2–10 | 0.000599146 |
| snow (Front Range spring example for first three states) | 2 | 0.5–5 | 0.001497866 |

Severity overrides (km → /m): lightRain: 12 → 0.000249644; heavyRain: 1.5 → 0.001997155; lightSnow: 8 → 0.000374467; snowSquall: 0.3 → 0.009985774; denseSmoke: 0.8 → 0.003744665; localDenseFog: 0.2 → 0.014978661. All are authored scenarios, not a rain-rate or AQI conversion. Humidity can enhance aerosol haze but does not by itself define extinction. No universal AQI/PM2.5-to-visibility mapping is specified.

## Distant mountains and distance tint

Keep map-positioned mountains when the curved-earth DEM sightline is unblocked, the summit is not hidden by local cloud, projected silhouette height is at least **2 px**, and retained horizon contrast is at least **0.05**. For estimated initial contrast `C0=0.5`, `C=C0×T`, and `dMax=ln(0.5/0.05)/sigma ≈0.7686×MOR`: a 75 km clear preset retains nominal silhouette contrast to about **57.6 km**; a 100 km clear preset to **76.9 km**. At100km/MOR100km the nominal contrast is0.025: fade it unless actual initial contrast is higher or the ray traverses cleaner air above the haze layer. MOR is not a hard geometry cutoff or a promise all mountains remain visible.

Fade across contrast0.03–0.05; omit internal folds below0.10. These are authored phone targets, not human-vision measurements. Never make mountains brighter, larger or closer to compensate. At20/50/100km use progressively simpler relief/silhouettes and the same atmosphere, with earth curvature. Peaks above a valley layer use the integrated ray, not a uniform ground-visibility coefficient. Sloan’s Lake west-facing scene has mountains; east-facing downtown does not.

Tint comes from **one linear-light airlight mix**: optical depth0.1/0.5/1/3 produces9.52/39.35/63.21/95.02% airlight. No extra blue-distance grade, desaturation pass or white fog overlay. Day fallback airlight is clear#BDD0D9, hazy#C3CED4, humid#CCD2CD, smoke#B1AA9A, rain#A1ADB0, snow#B9C7D0. Prefer directional lit sky/horizon radiance; these hexes are palette fallbacks. Golden hour mixes35%#C4C3B6 into the state colour in linear light; blue hour#8294AE and night#475568 replace fallback colour, **not extinction**. Local lamps do not brighten the global airlight. Calibration-v2 exposure/saturation/materials stay unchanged.

## Data selection and layer handling

Prefer representative uncensored current visibility, then a validated spatial weather adapter, then the region/season/state fallback. US ASOS [10SM is a reporting ceiling](https://www.weather.gov/asos/Visibility.html): it means at least16.09344km, not exactly16km. International9999 is likewise a ≥10km bin. Preserve censored flags and estimate from a regional prior with uncertainty; never interpret a capped clear-day report as the actual horizon. Do not pretend airport conditions resolve a neighbourhood or mountain layer.

Authored freshness policy:60min soft age,180min hard expiry, source cadence may override. Expired data loses live status. Use fresh model/event or marked estimated fallback; known adverse events do not silently become clear when data expires. Smooth ordinary extinction changes over10s; validated severe changes within1s. Reject invalid values rather than manufacture visibility.

A total measured extinction already includes its contributors. Do not add rain/smoke/fog again. Without measurements, simultaneous authored states choose the minimum visibility (maximum coefficient), explicitly an approximation. Sum only independently calibrated components. Preserve spatial ground/marine fog and integrate its local coefficient only along intersected ray segments; fit it to observations to avoid double counting. Ground fog can hide bases while ridges remain clear. Layered colours need ordered radiance integration; an optical-depth-weighted colour average is not exact. One shared atmosphere covers land, water, buildings and terrain; do not re-fog sky or already-atmospheric reflection radiance.

## Explicit overrides

- **lake-winter-v1:** replaces `/water/haze/fixtureExtinctionPerM = 0.0008` and its hard-coded exponential. That coefficient is only3.745km MOR and is unsuitable as generic clear lake haze. Water palettes, wave mechanics, ice and shore states stay.
- **weather-moments-v1:** replaces inherited lake haze and all homogeneous before/after `fog.sigmaPerM` defaults, including universal clear0.0005/m. Recompute visibility equivalents using5% MOR. JSON includes all21 moment migrations. Preserve event content, light, palette/time intent, wetness, snow history and independently specified local layers. Named squall and heavy-rain after states use severity overrides; other states resolve actual weather and region.
- **mountain-terrain-v1:** replaces background clear1e−5/m, summerHaze2.5e−5/m and storm5e−5/m profiles; keeps DEM, LOD, curvature, terrain and snow rules.
- **night-fog-v1:** replaces background/far haze coefficients only, preserving local ground fog0.035/m, layer bounds and patch masks. Darkness alone never increases density.

These are field-level precedence rules, not retroactive approval or edits to earlier packs. Existing images remain historical references if their distant contrast conflicts. Regional kits consuming those defaults must resolve this pack’s atmosphere rather than copy legacy numbers.

## Files and verification

`values.json`:16 climate regions ×4 seasons ×6 states =384 explicit preset entries,6 severity overrides, airlight, mountain rules, source links and override/migration map. `README.md`:formula, tables, assumptions and precedence. Only these two files are delivered; no project files or git operations. Formula round trips, range ordering and transmittance examples were checked. Regional climate ranges remain unverified and should be calibrated against uncensored observations or known-distance photographs; no current conditions or climate dataset was retrieved.
