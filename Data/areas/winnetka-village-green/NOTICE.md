# Data notice

## OpenStreetMap

`osm.json` is an extract of OpenStreetMap data, clipped in one way. The Overpass query (`osm.overpassql`) recurses into every multipolygon that touches the area box, which pulled in all 1,251 member ways (82,285 nodes, 8.7 MB) of the Lake Michigan relation (relation/1205149), of which only a few touch the box. `Tools/regionkit/regionkit.sh osmclip` then removed, from that relation only, the member ways whose bounding box does not intersect the context-ring box (the bounds of the `context` source in `manifest.json`) and the nodes that only those ways used: 1,245 ways and 79,144 nodes. The relation itself (tags and its full member list) and all other elements are unchanged and copied byte for byte; 6 of its member ways remain, the same stub shape `context.json` uses for very large water. Because the relation's other members are absent, the shared feature builder reports it as one skipped multipolygon (member way missing) and no longer builds a lake polygon from it (the old inventory listed one 56,439 m² water area; the file has no other water polygon, so it came from this relation). Size went from 9,468,942 to 772,767 bytes. `manifest.json` records the clipped file's size and SHA-256. See `docs/data/area-size-budget.md`.

Map data © OpenStreetMap contributors, available under the Open Database License (ODbL 1.0):
https://www.openstreetmap.org/copyright

- **How it was fetched:** with `worldbake fetch` using the query in `osm.overpassql`, with `out body`, so it contains no contributor usernames, user IDs or edit timestamps.
- **Where to look up details:** `manifest.json` records the bounds, the OSM data timestamp, the fetch time and the file's SHA-256.


## Overture buildings

Building footprints in `overture-buildings.json` come from the Overture Maps Foundation buildings theme (release 2026-09-23.1), licensed under ODbL 1.0: © OpenStreetMap contributors, Overture Maps Foundation. Contains Microsoft Global ML Building Footprints (ODbL); USGS 3D Elevation Program. OpenStreetMap buildings take precedence; Overture fills only footprints OSM lacks.

- **How it was fetched:** with `worldbake fetch <dir> --layers overture` (`scripts/data/fetch_overture.py`), reading only the area's bounding box from Overture's public GeoParquet.
- **Where to look up details:** `manifest.json` records the release, the fetch time and the file's SHA-256; the file lists the GeoParquet files read and every source dataset with its licence.

## Context ring

`context.json` is an unmodified extract of OpenStreetMap data (same license as above), fetched with `out body` by `worldbake fetch --layers context` using the query in `context.overpassql`. Purpose: low-detail real ground around the area (main and residential roads, rail, water, coastline, landuse and park areas, and building footprints only within 1.5 km of the area box; `landuse=grass` ways with a perimeter under 200 m are left out) so aerial views continue real ground to the horizon. It covers the area box plus 3 km on every side and is not loaded into the detailed street-level world. Water relations with 300 or more members (very large lakes and seas) are not fetched whole: the file carries the relation itself (tags and member list, not recursed) and only those member ways that touch the ring box, so the shoreline inside the ring is present as open way segments and the relation's other members are not in the file. Open-sea shorelines also arrive as `natural=coastline` ways (land on the left of the way direction) where OSM maps them that way; the Great Lakes are not mapped as coastline. See `docs/data/context-rings.md`.
