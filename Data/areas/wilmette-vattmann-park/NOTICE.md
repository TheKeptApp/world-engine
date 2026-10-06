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
