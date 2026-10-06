# Data notice

## OpenStreetMap

`osm.json` is an unmodified extract of OpenStreetMap data.

Map data © OpenStreetMap contributors, available under the Open Database License (ODbL 1.0):
https://www.openstreetmap.org/copyright

- **How it was fetched:** with `worldbake fetch` using the query in `osm.overpassql`, with `out body`, so it contains no contributor usernames, user IDs or edit timestamps.
- **Where to look up details:** `manifest.json` records the bounds, the OSM data timestamp, the fetch time and the file's SHA-256.

## Overture buildings

Building footprints in `overture-buildings.json` come from the Overture Maps Foundation buildings theme (release 2026-09-23.1), licensed under ODbL 1.0: © OpenStreetMap contributors, Overture Maps Foundation. Contains Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program. OpenStreetMap buildings take precedence; Overture fills only footprints OSM lacks.

- **How it was fetched:** with `worldbake fetch <dir> --layers overture` (`scripts/data/fetch_overture.py`), reading only the area's bounding box from Overture's public GeoParquet.
- **Where to look up details:** `manifest.json` records the release, the fetch time and the file's SHA-256; the file lists the GeoParquet files read and every source dataset with its licence.

## Canopy blocks

`canopy-blocks.json` holds per-block canopy shares and tree-spacing estimates derived from USDA NAIP aerial imagery (public domain; requested credit: "NAIP imagery provided by USDA Farm Service Agency") and the street centrelines in `osm.json` (© OpenStreetMap contributors, ODbL 1.0). Aggregates per street-bounded block only; no imagery. The NAIP item, date and method are in the file header; format in `docs/research/aerial.md` 13.9.

## Context ring

`context.json` is an unmodified extract of OpenStreetMap data (same license as above), fetched with `out body` by `worldbake fetch --layers context` using the query in `context.overpassql`. Purpose: low-detail real ground around the area (main and residential roads, rail, water, coastline, landuse and park areas, and building footprints only within 1.5 km of the area box; `landuse=grass` ways with a perimeter under 200 m are left out) so aerial views continue real ground to the horizon. It covers the area box plus 3 km on every side and is not loaded into the detailed street-level world. Water relations with 300 or more members (very large lakes and seas) are not fetched whole: the file carries the relation itself (tags and member list, not recursed) and only those member ways that touch the ring box, so the shoreline inside the ring is present as open way segments and the relation's other members are not in the file. Open-sea shorelines also arrive as `natural=coastline` ways (land on the left of the way direction) where OSM maps them that way; the Great Lakes are not mapped as coastline. See `docs/data/context-rings.md`.

## Lidar roof hints

`lidar-roofs.json` and `roof-mix-blocks.json` are derived from USGS 3D Elevation Program lidar (dataset `USGS_LPC_IL_4County_Cook_2017_LAS_2019`, flown 2017-04-16 to 2017-05-07; US Government Public Domain; credit "USGS 3D Elevation Program") and from this folder's footprints and street centrelines: `osm.json` (© OpenStreetMap contributors, ODbL 1.0) and the Overture buildings the engine adds on top of OSM (`overture-buildings.json`, © OpenStreetMap contributors, Overture Maps Foundation; Contains Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program). Per-footprint values are keyed by the engine's ref (`way/<id>`, `relation/<id>`, `overture/<id>`, the signed 64-bit integer of the first 16 hex digits of the Overture id); blocks with fewer than 5 classified buildings carry no shares. Method: `docs/research/lidar-roofs.md` sections 14 and 15 (method version 2.0; the mansard rule is UNVALIDATED; the roof forms of this area were not hand-checked).
