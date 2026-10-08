# Airport gate/stand audit

Measured bounded OSM response inventory, retrieved 2026-10-07. Counts are not completeness percentages or verified occupied stands. Full-airport queries failed for four airports; smaller terminal extracts succeeded. No airport edits were made.

| Airport | Gate objects | Distinct gate refs | Stand objects | Distinct stand refs | Stand objects missing ref | Scope |
|---|---:|---:|---:|---:|---:|---|
| ORD | 216 | 208 | 202 | 201 | 1 | terminal-area bounding box |
| MDW | 42 | 42 | 36 | 30 | 6 | terminal-area bounding box |
| DEN | 177 | 176 | 260 | 236 | 23 | broad airport bounding box |
| GSP | 13 | 13 | 22 | 14 | 8 | broad airport bounding box |
| JFK | 137 | 122 | 254 | 192 | 19 | terminal-area bounding box |
| SFO | 121 | 109 | 214 | 107 | 99 | terminal-area bounding box |

## ORD

**Measured inventory, authored risk interpretation:** 216 objects exceed the official 201-gate January2025 reference. Validate future/closed/duplicate/terminal meanings; 8 objects have no ref. Do not interpret count surplus as extra capacity.

[Raw extract](osm-ord-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-87.915,41.972,-87.892,41.991)

## MDW

**Measured inventory, authored risk interpretation:** 42 gate refs compared with official January2025 count43; 36 stand ways, only30 labelled. Curate aliases (including split gates) and all missing labels before occupancy.

[Raw extract](osm-mdw-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-87.755,41.779,-87.743,41.791)

## DEN

**Measured inventory, authored risk interpretation:** Large stand inventory includes non-passenger/remote stands. 23 stand objects lack ref; one labelled ref repeats. Map concourse namespace and separate terminal from concourses.

[Raw extract](osm-den-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-104.71,39.83,-104.65,39.91)

## GSP

**Measured inventory, authored risk interpretation:** 13 gate refs and14 distinct labelled stand refs; additional stands are not necessarily passenger gates. Small inventory is a good manual-audit candidate, not proof of completeness.

[Raw extract](osm-gsp-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-82.23,34.875,-82.2,34.915)

## JFK

**Measured inventory, authored risk interpretation:** Gate labels repeat across terminals and stand objects/refs repeat. Construction and terminal namespace matter; 19 stand objects have no ref.

[Raw extract](osm-jfk-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-73.801,40.636,-73.763,40.656)

## SFO

**Measured inventory, authored risk interpretation:** Repeated gate refs,99 stand objects without ref. Do not use old numeric-only maps as current aliases; terminal/boarding-area namespace is required.

[Raw extract](osm-sfo-raw.osm) · [Public query](https://api.openstreetmap.org/api/0.6/map?bbox=-122.398,37.607,-122.375,37.627)

## Completeness method and limitations
No current full passenger-gate/stand roster with verified reuse rights was obtained, so all completeness percentages are null. Official dated ORD/MDW counts are only sanity checks (CDA-GATES). Extra OSM objects may be closed/future, duplicates, bus gates or naming variations. Stand ways and stand nodes can duplicate physical locations. The extracted counts are not deduplicated physical aircraft capacity. Ways can extend outside the query bbox; do not infer complete airport coverage from a successful response.

Before launch, match airport + terminal/concourse + normalized ref against a current permitted roster. Preserve raw ref; do not merge A4A/A4B, leading zero variants or same numeric gate across terminals without curated aliases. Validate stand-way endpoint/heading, nose-wheel stop, aircraft compatibility, jet bridge and apron elevations. Report passenger-gate recall and valid parking-pose share separately; denominator and date must be explicit.

All six airports have OSM gate/stand objects in the inspected extracts. Actual physical precision, active-status correctness and usable taxi connectivity remain unverified. Proposed priority: GSP and curated MDW, then DEN; ORD/JFK/SFO after namespace/construction validation. Public airport maps are naming references, not automatically permitted tracing sources.

© OpenStreetMap contributors, [ODbL](https://www.openstreetmap.org/copyright). Raw extracts retain public source metadata; use offline/package ingestion, not per-user OSM API polling.
