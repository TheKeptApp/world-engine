# Netherlands Style B v1
Design proposal • checked 7 October 2026 • approval pending.

Packs own content; style-b-calibration-v2 owns look. The shared lighting/material block is copied from that pack. Dutch geometry is carried by narrow lots, gables, brick blocks, canals, lower Utrecht wharves, red cycle surfaces and contemporary Vinex rows, rather than a separate illustration style.

## Scope
Amsterdam: Canal ring, Jordaan, Oost, Zuid. Rotterdam: modern centre, Kralingen, West residential, riverfront. Utrecht: old centre, old lanes, eastern residential edge, station quarter. Leidsche Rijn is the Vinex study, using Terwijde, Langerak, Parkwijk and centre-inspired settings.

Each location has a seven-row archetype sheet and four district boards with street, approximately 45° aerial and far views, plus a neutral-massing → Style B block study. Regional reference archetypes are not claims that every type belongs in every district. The tower type is principally Rotterdam; post-war and houseboat examples in Vinex are regional references.

Shared sheets cover canals/bridges/cycling/ferries, trams/furniture/signals, elm/plane/linden across four seasons, four weather moments, night and Kings Day. No characters, dogs, logos, readable signage, real murals or public art are intended.

## Reading and implementation
Open index.html. Use the separate district PNGs for review; the original complete sheets remain in images/. Prompts and a file manifest accompany the images. Dimensions, storeys and species mix in values.json are authored fallbacks marked UNVERIFIED. Replace them with local measurements and inventories. They are not construction standards.

The block before/after images are authored concept massing, not captured engine output. Generated views express the same district and type; they are not surveyed models, registered cameras or proof of geospatial fidelity. Far views simplify facade details into block mass and land-cover colour; keep canals and cycle corridors identifiable without oversized furniture.

Driving side is RIGHT. Treat tram, ferry and cycle infrastructure as separate mapped networks. Use the existing [Dutch signal reference](../road-signs-signals-v1/netherlands.html); its live signal state must remain unknown without a verified source.

## Data
See research.md and sources.md for licences, attribution, dates and unresolved items. In particular, AHN5 must not inherit AHN4's CC0 assumption; Amsterdam tree access does not establish a standard reuse licence; aggregate GTFS must be checked for current GVB/NS inclusion. KNMI's replacement warning feeds contain TEST data until the announced 2 November 2026 transition.

## Review limits
This pack is a visual proposal, not approved-binding and not built or verified in engine. The values require measured local validation; no production feeds were connected. Phone-check records document the gallery layout, not engine performance. Existing reference packs were read only. No world-engine project files or git operations were used.

## Delivered files

- index.html: responsive review gallery.
- images/: 18 complete source boards (four archetype sheets, four district sheets, four block studies, six regional sheets).
- districts/: 16 standalone district boards and 48 individual street/aerial/far views.
- archetypes/: 84 individual views for 28 archetype studies.
- regional/: 36 individual infrastructure/season/weather/night/event views.
- blocks/: four convenient block-study copies.
- values.json; research.md; sources.md; prompts.json; manifest.json; FILE-LIST.txt.
- phone-check/: screenshots and layout report at 320, 390 and 1280 px.

The 16 district boards each contain three views. Individual PNGs are browser exports of those source panels, not independent engine renders. Gable variants, facade detail and exact geography still require local engine verification. Night views are quiet architectural studies with no motor vehicles; transit is illustrated on the dedicated kit sheets.
