# Data notice

`osm.json` is an unmodified extract of OpenStreetMap data.

Map data © OpenStreetMap contributors, available under the Open Database License (ODbL 1.0):
https://www.openstreetmap.org/copyright

- **How it was fetched:** with `worldbake fetch` using the query in `osm.overpassql`, with `out body`, so it contains no contributor usernames, user IDs or edit timestamps.
- **Where to look up details:** `manifest.json` records the bounds, the OSM data timestamp, the fetch time and the file's SHA-256.

## Context ring

`context.json` is an unmodified extract of OpenStreetMap data (same license as above), fetched with `out body` by `worldbake fetch --layers context` using the query in `context.overpassql`. Purpose: low-detail real ground around the area (main and residential roads, rail, water, coastline, landuse and park areas, and building footprints only within 0.5 km of the area box; `landuse=grass` ways with a perimeter under 200 m are left out) so aerial views continue real ground to the horizon. It covers the area box plus 3 km on every side and is not loaded into the detailed street-level world. Water relations with 300 or more members (very large lakes and seas) are not fetched whole: the file carries the relation itself (tags and member list, not recursed) and only those member ways that touch the ring box, so the shoreline inside the ring is present as open way segments and the relation's other members are not in the file. Open-sea shorelines also arrive as `natural=coastline` ways (land on the left of the way direction) where OSM maps them that way; the Great Lakes are not mapped as coastline. See `docs/data/context-rings.md`.

## Canopy blocks

`canopy-blocks.json` holds per-block canopy shares and tree-spacing estimates derived from USDA NAIP aerial imagery (public domain; requested credit: "NAIP imagery provided by USDA Farm Service Agency") and the street centrelines in `osm.json` (© OpenStreetMap contributors, ODbL 1.0). Aggregates per street-bounded block only; no imagery. The NAIP item, date and method are in the file header; format in `docs/research/aerial.md` 13.9.

## Lidar roof hints

`lidar-roofs.json` and `roof-mix-blocks.json` are derived from USGS 3D Elevation Program lidar (dataset `USGS_LPC_IL_4County_Cook_2017_LAS_2019`, flown 2017-04-16 to 2017-05-07; US Government Public Domain; credit "USGS 3D Elevation Program") and from this folder's `osm.json` footprints and street centrelines (© OpenStreetMap contributors, ODbL 1.0). Per-footprint values are keyed by OSM ref; blocks with fewer than 5 classified buildings carry no shares. Method: `docs/research/lidar-roofs.md` section 14.
