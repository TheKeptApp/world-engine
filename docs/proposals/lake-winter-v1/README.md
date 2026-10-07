# Lake water + winter gaps — WorldEngine Style B
7 October 2026 · Authored proposal · iPhone review

This pack adds lake water, lake scale, ice, tree snow and aged snow to rain-v1. It preserves rain-v1's linear-light darkening and reflected-sky sheen definitions, cream/forest poster format, and exact inherited snow colours. It does not replace rain-v1's wet street, puddle, rain-distance, dusk/night or snowfall-stage studies.

[Exact data](lake-winter-values.json) governs all settings. [Water swatches](07-exact-water-values.svg) and [winter swatches](08-exact-winter-values.svg) are deterministic vector charts. The six generated boards illustrate appearance; their pixels, labelled distances, apparent thicknesses and coverage are not measurements. No current Sloan's Lake or Chicago engine render was attached. Lake scenes therefore use conceptual city-lake/open-lake framing; the old-snow board uses the supplied rain-v1 snow-street composition. These are not surveyed lake outlines or engine paintovers.

## Boards and review
1. [Water that reads](01-water-that-reads.png): calm / breezy / golden hour at 20 m, 100 m and aerial.
2. [Big lake vs city lake](02-big-lake-vs-city-lake.png): matched clear afternoon, wind 10 km/h and exposure; different horizon, water palette and wave profile.
3. [Ice that reads](03-ice-that-reads.png): 55% ice, 100% ice, then 85% snow on ice; street and aerial.
4. [Snow on trees](04-snow-on-trees.png): fresh versus a supplied day-2 wind/melt fixture, bare deciduous and evergreen, 5 m / 20 m / aerial.
5. [Old snow](05-old-snow.png): day 2 / day 5 / thaw, plus lawn, plowed pile and slush details.
6. [Phone readability targets](06-phone-readability-targets.png): lake day / golden hour / frozen aerial / old-snow street.

[Review page](index.html) shows the four target scene crops at 390 CSS px, with a 320 px toggle and full boards below. Compare the scene without reading its caption. Review against real phone renders before adoption; no device timing or animated readability result is claimed.

## Build first: cost-ranked cues
Costs are relative engineering effort, not GPU timing. Existing material/mask paths make low-cost items inexpensive; missing history/data infrastructure can raise their cost.

| Rank | Cost | Effect / cue that sells it at phone distance | Implementation and limit |
|---|---|---|---|
| 1 | Low | Lake day: broad sky reflection over blue-green water | Existing opaque material, angular sky blend 0.12 normal → 0.55 grazing. Time-correct sky, no white emissive floor. |
| 2 | Low | City lake versus big lake: enclosed shore versus open horizon | Correct mapped lake geometry/camera first. Sloan water #477C8D; Michigan #315F7F in clear fixture. One shared haze extinction 0.0008/m; long views naturally soften more. |
| 3 | Low | Shore: shallow-colour belt and softened material boundary | Sloan #668C82 across 2 m, Michigan #557F83 across 4 m. Water-side darkening 12% across 0.60 m; material transition 0.40 m. Bathymetry overrides defaults. |
| 4 | Low | Ice: broad opaque cool sheet, open water still dark/moving | Ice #91ADBA, r0.32, sheen0.18; stable coverage mask, 0.30 m soft boundary. Frozen areas stop waves. |
| 5 | Low | Snow on ice: large white areas broken by cool ice | #E4E9EB, shadow tint #C3CDD6, r0.90, sheen0.01; opaque area coverage, not transparent white wash. |
| 6 | Low | Old snow: cleaner lawns, grey-beige piles, darker dirty base | Dirty body #A5A698, lower bank #91958D on bottom20% height; dry snow r0.88 / sheen0.02. Broad colour regions, no dirt texture. |
| 7 | Low | Slush: flat grey curb strip with broad water sheen | #858E93, r0.30, sheen0.32; width0.35 m, thickness0.025 m, retained support within0.80 m of curb. Existing drainage/history only. |
| 8 | Medium | Breeze: coherent low wave bands rather than sparkle | Two analytic components, shared material. World wavelengths/amplitudes remain real-scale. Fade detail below1.5 CSS px; keep broad roughness response. |
| 9 | Medium | Tree snow: thin bright top caps against structural silhouette | Near caps0.035 m thick, max12/tree; 20 m max5; aerial max3 crown lobes. At most24 visible capped trees. No leaf/needle detail. |
| 10 | Medium | Melting bank: shrinking rounded ridge with clear walking corridor | Reuse supplied bank geometry; day2/day5 banks0.30 m, day5 pile0.45 m; thaw bank0.15 m. Clip to clear routes/ramps/crossings. |
| 11 | High | Ice state follows the actual lake rather than present air temperature | Integrate supplied/observed ice geometry, surface water temperature and lake thermal history. No universal freeze-hours switch. |
| 12 | High | Waves and retained snow respond plausibly over days | Fetch/depth/directional wind history; snow load, exposure, melt and displaced-bank reservoirs. Full simulation is optional; explicit observed states can feed the low-cost visuals. |

At 20 m, keep shoreline transition, a few broad wave bands and a clear reflected-sky mass. At 100 m, remove subpixel ripple normals; horizon, opposite shore, sky colour and roughness carry the lake. Aerial retains broad lake/ice/snow masks and shoreline width; reflection strength scales0.65 and wave normal amplitude0.5. Trees merge caps into crown masses. Ground keeps a broad dirty-bank/slush band, without ice grains or footprint detail.

## Exact material values
Each states[].surfaceValues[] retains rain-v1's surface, darkeningPercent, linearBaseMultiplier, roughness and sheenStrength. This extension adds baseColourHex and resultHex. Decode sRGB to linear, multiply by (1−darkeningPercent/100), then encode the deterministic swatch. Light and reflection are applied separately in linear space.

Water sky defaults are authored base materials, not sampled reflected sky:
| Sky | Sloan's Lake | Michigan | Reflected-sky fixture |
|---|---|---|---|
| Clear | #477C8D | #315F7F | #8FBDD7 |
| Overcast | #718C9A | #627E91 | #8F9FAA |
| Golden hour | #477884 | #355F79 | #E7BA79 |
| Night | #243D5A | #1D304B | #24314B |

The actual sky is sampled in the reflected direction. Water uses k=(0.12+0.43×(1−abs(N·V))^5)×exposure×aerialScale. Sheen0.55 is the grazing maximum, not metallicness or physical F0. Ice/slush/snow use the rain-v1 cubic angular proxy. Use this proxy OR a calibrated BRDF/environment path, never add both. Roughness widens/filter the reflection response; adapters must calibrate it. Baseline has no geometric building/tree mirror pass, SSR, planar reflections or added world capture.

| Wind km/h | r | Sloan wavelength / amplitude | Michigan wavelength / amplitude |
|---|---:|---|---|
| 0 | .18 | 0 /0 m | 0 /0 m |
| 10 | .28 | .80 /.025 m | 3.0 /.10 m |
| 25 | .40 | 1.60 /.070 m | 6.0 /.25 m |

Amplitude means half peak-to-trough height. These are appearance fixtures, not forecasts. Smaller sheltered lakes generally have less fetch and smaller waves; this principle is supported by [National Weather Service lake-wave guidance](https://www.weather.gov/fgf/lake_info_help). Wind direction, duration, depth, observed waves and residual swell matter. The zero-wind fixture deliberately has no retained swell. Interpolate speeds continuously; don't jump between three animated presets.

The shore multiplier is0.88 at the water edge, smoothly recovering to1 over0.60 m. It is applied to water only, not multiplied over the existing wet-ground policy. Shallow hue blends before this reduction. Opaque snow suppresses underlying ground/water/ice sheen. New and existing policies share one weather fog, one darkening owner and existing budgets.

Dirty snow and slush require hue replacements: a scalar darkening multiplier cannot turn blue-white snow beige-grey. Their swatches use the authored colour with zero further reduction. JSON additionally records the exact linear luminance difference relative to fresh #E4E9EB. Thus “−0%Y” on a material swatch means no extra darkening of that authored colour; it does not mean dirty snow is as bright as fresh snow. The chart prints the separate fresh-snow comparison.

## Weather history needed
| Effect | Required history / source | Missing-history behaviour |
|---|---|---|
| Reflection and golden hour | Current sun, cloud, sky radiance, exposure and camera; reflected direction | Follow existing weather/sky state; never paint a permanent orange stripe. |
| Waves | Wind speed/direction over last3 hours, fetch/depth or explicit look fixture, observed wave/swell state | Label fixture; do not describe authored wave height as live measured weather. |
| Ice | Observed/supplied ice coverage/shape, surface water temperature, multi-day thermal state, air-temperature series, mixing/wind | Unknown remains unknown; no automatic lake freeze from air temperature or season. |
| Snow on ice | Existing ice mask plus snowfall accumulation, exposure and melt history | No snow blanket without retained accumulation. |
| Branch snow | Event snowfall amount/end time, retained canopy load/type, gust/exposure history, positive-degree-hours and solar exposure | Keep supplied state; elapsed days alone cannot shed snow. |
| Old snow | Snow age and retained depth/coverage, thaw degree-hours, rain-on-snow, solar/shade, contamination and traffic | Do not grey all lawn snow just because it is old. |
| Banks/slush | Explicit plow/clear event and displaced volume, melt reservoir and curb drainage | Do not invent plowed ridges or block an accessible crossing from a weather code. |

Cumulative freezing degree-hours = sum(max(0,−TairC)×hours). This is a context signal, not an ice-coverage equation. NOAA studies ice with lake thermal structure, surface water temperature and weather history, and publishes observed/modelled coverage: [NOAA GLERL ice research and data](https://glerl.noaa.gov/data/ice/). The fully frozen board is a supplied Sloan fixture; it is not a prescription to freeze all Lake Michigan.

Tree day2 is explicitly48 h since snowfall, peak wind25 km/h and4 h above freezing: coverage falls from35% to12% of eligible bare branch tops and65% to25% of eligible evergreen crown tops. Snow stays the same colour. Exposure and retained load determine live shedding; these percentages are authored comparisons, not a physical retention prediction.

Old-snow panels are separate fixtures: day2 has90% lawn snow and zero positive-degree-hours, day5 has55% and24°C·h, thaw has20% and48°C·h. Bank height and coverage are explicit inputs; these thermal sums do not automatically generate those amounts. Retained material within0.80 m of the curb persists only while its supplied reservoir is nonzero;0.80 m is a distance limit, not an arbitrary survival time. New snowfall refreshes exposed retained snow, not the underlying dirt reservoir.

## Integration, budget and acceptance
This is renderer-neutral proposal JSON in rain-v1's conventions, with new lake/winter blocks and35 panel fixtures. It is not installed into a production shared file or tested against a production loader. Each board panel names exact material/environment/camera references; the engine adapter must support these fields and existing ownership rules before adoption. Generated panels do not establish camera calibration or numerical parity.

Rain-v1's reference ceiling remains10 ms GPU, content plan7.9 ms plus2.1 ms reserve. Surface patterns share0.25 ms, wet/local effects0.35 ms, and near geometry0.35 ms with all existing effects. These are reference allocations, not additional budgets or measured lake/winter timings. Reuse opaque materials, analytic masks and batched caps. Drop subpixel normals and optional edge geometry first; retain broad state and route geometry. Do not spend reserve on unmeasured extra captures or passes.

Acceptance on an actual iPhone at390 and320 CSS px:
- Lake water reads from sky colour and broad reflection before captions; no black hole, glitter noise or hard shoreline ring.
- Same-time Michigan view has an open horizon and broader waves; Sloan's opposite shore is visible. Both share lighting and weather haze.
- Ice distinguishes open water, bare ice and opaque snow; frozen regions have no water motion.
- At20 m tree snow remains a few bright masses; at aerial distance it is a crown silhouette cue.
- Cleaner lawn snow differs from dirty plowed base; slush is a low grey wet strip and crossings remain clear.
- Load exact JSON into the renderer, verify tone-mapped colour/roughness mapping, then measure combined weather performance on device. None of these renderer/device tests has been performed here.

## Files and art limits
All deliverables are in this folder. prompts.json records generation plus corrective edits; image-manifest.json records dimensions and hashes; verification.md records arithmetic/reference checks. Reference files were read only; no git used.

Corrective edits to all boards, plus a second targeted tree-shedding and dirty-bank edit, reduce leaf/surface detail, corrects the city-lake context and strengthens dirty/slush separation. Broad layout, lighting, colour and cue hierarchy are the intended reference. Residual mirrored silhouettes, small branches, snow-cap thickness, coverage percentages, apparent wave height or fine highlights in generated artwork are illustrative deviations; exact JSON and charts win. A scene generated from a poster cannot guarantee identical street geometry. No real lake outline, current weather, ice-safety assessment, shader parity or phone measurement is asserted.
