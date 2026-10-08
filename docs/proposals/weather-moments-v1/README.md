# Weather + night moments · Style B v1

21 hero moments, 42 before/after views, nine regional image boards. Open index.html locally; it works offline with no weather requests, trackers or external fonts. Images live in images/. values.json contains every endpoint and source binding.

The approved Style B Bible calibration establishes grounded real proportions, restrained surfaces and soft coherent light. Current house-contrast-v1 sharedLighting is copied unchanged as the clear-day base; its earlier anchor-number uncertainty remains in the inherited object. Weather and actual time override the fixture rather than imposing daylight on night scenes. Night/fog, rain and lake/winter material values are copied from the supplied packs. rain-v1 was found in the filed docs at docs/proposals/rain-v1.

## Read the comparisons

Each row is one moment: left is the comparison state, right is the hero. Miami downpour/rainbow compares rain to clearing; SF golden hour compares cool fog to sunlit fog; Seattle clear day compares obscured to visible mountain; New England compares rain to post-rain autumn. Other rows compare ordinary daylight to the event. Region boards preserve camera and layout approximately within each row. Generated artwork is not a surveyed geography, pixel-exact geometry match, colour measurement or engine acceptance render.

No dogs, people/characters, logos, brands, signage text or host-app content. Architecture and terrain remain intact through storms. No lake-freeze inference from snowfall, instant dry road after rain, universal orange grade, mirror roads, cartoon trees or satellite texture.

## Transition rules

Keep camera, lens, road/shore polygons, building identity and trunk positions stable. Interpolate sky and lighting in linear RGB, apply exposure once, and keep materials separate from illumination. Rain/snow pools ramp over five seconds; fog over twenty seconds in these demo transitions. These durations are presentation targets, not predictions. Preserve independent surface-water and snow reservoirs from recent history. The rain pack's per-surface darkening cap is 12%; do not stack a second weather darkening layer. Wet reflections use eligible stable patches, not the whole street.

Use one extinction term consistently across terrain, buildings, trees and water. Marine fog layer geometry and dust-wall approach are authored examples; visibility at an airport cannot locate every hillside bank or dust boundary. Keep near geometry readable without falsifying actual sourced visibility. Hail is a sparse optional cue, with no damage or impact solver. A rainbow requires visible sun plus a sunlit rain volume opposite the sun; rain ending alone does not enable it. Alpenglow requires terrain still receiving low-angle sunlight. Autumn and green spring crowns require independent phenology, not an instantaneous weather-code change.

Night inherits cool readable fill, stable sparse warm window selection and localized light pools. Ocean Drive's plain accent fixtures have no lettering. Fixture placement and colours are unsurveyed concepts. Desert stars require real catalogue/sidereal positioning in production; no invented constellations or moon. Existing phone budgets are inherited constraints, not measured passes.

## Live data plan

Bindings are proposed, not connected or tested against a current event. Keep observed, forecast, history and demo modes separate and show age/staleness. Missing data never silently becomes a live observation. These sources and roles were checked on 7 October 2026:

- [NWS API documentation](https://www.weather.gov/documentation/services-web-api): forecasts, station observations and alerts. Discover the correct grid/stations with /points. Radar endpoints return status rather than display imagery; use a radar data service.
- [MRMS catalogue](https://mrms.ncep.noaa.gov/): radar-derived precipitation and candidate hail context, linked from NWS documentation. Product/unit/projection ingestion remains unverified.
- [NOHRSC National Snow Analyses](https://www.nohrsc.noaa.gov/nsa/): regional snow depth and history context, not measured canopy snow or plow history.
- [Aviation Weather data API](https://aviationweather.gov/data/api/): METAR visibility and low-cloud/weather context. Airport conditions do not establish each street's fog.
- [NOAA GOES viewer](https://www.star.nesdis.noaa.gov/GOES/): regional cloud context; imagery must become simplified parameters rather than photographic world textures. Product mapping remains unverified.
- [NHC GIS](https://www.nhc.noaa.gov/gis/): tropical advisory context only; this research fetch returned 403, so this adapter is explicitly unverified.

The per-moment liveBinding array identifies controls and missing-data behaviour. Dust wall position, rainbow occurrence, exact cloud geometry, foliage peak and street-level wetness are not directly observed by these generic feeds. Regional adapters must supply evidence or label an authored fallback.

## Files and acceptance

values.json: inherited reference objects, numeric endpoint targets, cameras, live controls and source-status manifest.
index.html: responsive offline gallery and state controls.
images/: nine original generated comparison boards.
prompts.json: full prompt set, built-in image_gen provenance.

All numerical weather appearance values are authored targets. No live event, rendering cost, physical colour match or device performance is claimed. Existing references were read only. No git.

Validation: gallery inspected at 1440, 390 and 320px widths, with no horizontal overflow or page errors; pair/before/after controls and value disclosures passed. See verification.md. Numeric appearance targets and generated image pixels remain distinct.

## NYC addition

Four pairs match NYC hero archetypes: snowy brownstone stoops, an approaching avenue thunderstorm, rainy tenement night with broken wet-patch reflections, and winter low sun through a masonry canyon. Bare winter trees stay bare in snow/low-sun rows. Materials, street geometry and camera are approximately stable within each pair. Empty streets retain the original no-people/no-animals/no-signage rules. Numeric endpoints are authored, not sampled from pixels. Low-sun alignment is an illustrative canyon fixture, not a verified date or solar bearing. All earlier regional images remain unchanged.
