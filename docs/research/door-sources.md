# Door sources: where is the front door along the wall?

Research notes, 2026-10-07. Question: is there a source that puts each house's entrance at its real position along
the street-facing wall? Today the wall is right in 51 of 58 labelled houses, but the position along it is a seeded
draw, so only 21 of 58 (0.36) land within 2 m of the real door ([map-confidence.md](map-confidence.md), "Entry points").

Areas (box = manifest centre ± width/2, height/2): `sloans-lake` (Denver), `evanston-south` (Evanston, Cook
County), `lakeview-sheil-park` (Chicago, Cook County). Footprints: closed `building=*` ways in the committed
`osm.json` (© OpenStreetMap contributors, ODbL 1.0).

**Nothing from these sources is in the repository.** Address points were fetched as geometry plus object id only
(no numbers, streets, units, PINs or owners) into `/tmp/claude-doors-work/<area>/` and used only for the aggregate
counts below. Any later use must keep stripping house numbers; we never export them.

## Summary

| Candidate | Licence | Coverage in the 3 boxes | Entrance-placed? | Door gain (0.36 today) | Effort / risk |
|---|---|---|---|---|---|
| **Cook County Address Points** (Evanston, Chicago) | Public Domain on the county's Socrata catalogue (verified); ArcGIS item carries only an as-is disclaimer | Evanston 1,045 points, Lakeview 2,078 | **No.** `Placement` empty for 99 % (9 "Rooftop", 2 "Site" in Evanston, none in Lakeview); points sit at structure centroids | **≈ 0** | Low effort (Socrata API works; ArcGIS query endpoint timed out). Rows last updated April 2024 |
| **City of Chicago** | n/a | No address-point or entrance dataset on data.cityofchicago.org | n/a | 0 | Chicago is covered by Cook County only |
| **City of Evanston Addresses** | CC BY 4.0 (verified), **but portal terms bar bots and scripts without written permission** | ~17,000 primary site points citywide (not fetched) | Unknown: the layer has no placement field | Unknown, probably ≈ 0 | Needs written permission from Evanston before any scripted fetch |
| **Denver Addresses** | CC BY 3.0, "City of Denver Open Data Catalog" (verified) | Sloan's Lake 986 points (951 structure, 31 utility, 4 land) | **No.** No placement field; points are near or inside structures, not at doors | **≈ 0** | Low effort; updated daily |
| **Overture addresses** (2026-09-23.1) | Per source: NAD under its own licence (**unverified**: transportation.gov answers 403); Colorado OIT "public data", disclaimer only | Sloan's Lake 1,009 (`us/co/statewide` via OpenAddresses); Evanston 1,057 and Lakeview 2,125 (`NAD`) | **No.** Overture drops any placement field; Lakeview points are exact building centroids | **≈ 0** | 4.3 MB of GeoParquet for all three boxes; same data as the city/county sets |
| **OSM front walks** (`highway=footway/path`, not sidewalk) | ODbL 1.0 (already used) | **0 houses** with a walk ending ≤ 1.5 m from the outline in any area | Walk end at the facade would be a door proxy | **0** | None mapped; no entrance nodes on houses either |

**Bottom line: none of the three candidates gives door positions in these areas.** A side finding: putting the door
at the midpoint of the street-facing wall would score 25 of 51 labelled on-wall doors (0.49) against 21 of 51 for
today's draw. On the 42 of those houses that have an address point, projecting the point onto that wall and taking the
midpoint both score 24 of 42 (the draw: 16). Address points add nothing over the midpoint.

## 1. City and county address points

### Cook County Address Points (Evanston and Chicago)

- **Dataset:** "Cook County Address Points", Cook County GIS. Socrata: https://datacatalog.cookcountyil.gov/d/78yw-iddh
  (API `https://datacatalog.cookcountyil.gov/resource/78yw-iddh.geojson`); ArcGIS item `5ec856ded93e4f85b3f6e1bc027a2472`,
  service `https://gis.cookcountyil.gov/traditional/rest/services/addressZipCode/MapServer/0`. Covers Chicago too
  (`geocode_muni` = CHICAGO for all 2,078 Lakeview points).
- **Licence:** Socrata licence field "Public Domain" (verified via the dataset metadata). The ArcGIS item's licence
  field is only an as-is disclaimer, and the county's site terms (https://www.cookcountyil.gov/terms-use, read for
  [map-confidence.md](map-confidence.md)) say site content is copyrighted. Public Domain on the dataset is the most
  specific statement; confirm with Cook County GIS before shipping anything derived.
- **Placement:** the schema follows NENA NG9-1-1 and has `Placement` and `Structure` fields, but they are almost
  empty here: Evanston 9 "Rooftop", 2 "Site", 1,034 blank; Lakeview 2,078 blank. No methodology text is published.
- **Update cadence:** "As needed", publishing weekly per the metadata; rows last updated 2024-04-08.
- **Access:** the ArcGIS query endpoint timed out on every request (even `returnCountOnly`); the Socrata API answered
  in seconds. Fetched `$select=objectid,the_geom` with `within_box`.

### City of Chicago

No address-point or building-entrance dataset on https://data.cityofchicago.org (catalogue searched for "address
points", "address" and "entrance"). Building footprints (`hz9b-7nh8`) carry address ranges, not entrances. Chicago
relies on the Cook County set above.

### City of Evanston Addresses

- **Dataset:** "Addresses" (ArcGIS item `6d0b7733d4ee475ca8028b876ba6e605`), layer
  `https://maps.cityofevanston.org/arcgis/rest/services/OpenData/ArcGISOpenData/MapServer/4`. Just over 17,000
  primary site addresses, no units. The fields include a NENA site id but no placement field.
- **Licence / terms:** https://data.cityofevanston.org/pages/terms (effective 2025-05-13, read): data is CC BY 4.0
  unless the metadata says otherwise; derived data must credit the City of Evanston. **The same terms forbid "automated
  tools (including bots or scripts) to access or extract data from the Portal, unless authorized in writing."**
  I read the item and layer metadata (one request each) and the terms page, then stopped: no points were fetched.
- **Update cadence:** item last modified 2025-07-03; not stated.
- Using it needs written permission from the City of Evanston. Because the Cook points for Evanston are centroids and
  this layer has no placement field, the expected gain does not justify asking.

### Denver Addresses

- **Dataset:** "Addresses", City and County of Denver (ArcGIS item `059a534c87d448dc945637ca54261c14`), layer
  `https://services1.arcgis.com/zdB7qR0BtYrg0Xpl/arcgis/rest/services/ODC_CITY_LOC_ADDRESSPUBLIC_P/FeatureServer/31`.
  Active addresses from the Denver Address Database: "structure, utility, and land addresses".
- **Licence:** CC BY 3.0; credit "City of Denver Open Data Catalog" with a link to http://data.denvergov.org and name
  the licence (https://opendata-geospatialdenver.hub.arcgis.com/pages/terms-of-use, read through the hub site's
  configuration, verified). The item adds an as-is disclaimer, an indemnity clause and "NOT FOR ENGINEERING PURPOSES".
- **Placement:** `ADDRESS_TYPE` only (Structure / Land / Utility / Associated); the metadata has no placement
  method. Sloan's Lake: 951 S, 31 U, 4 L.
- **Update cadence:** daily (metadata).

### Measured against OSM footprints

Distinct point locations; "near" = ≤ 2 m from the outline. "Centroid ratio" = distance from the footprint centroid
over √area for points inside (0 = at the centroid). "Street-facing" = the nearest edge's outward normal points within
45° of the nearest named street.

| | Sloan's Lake (Denver) | Evanston (Cook) | Lakeview (Cook) |
|---|---:|---:|---:|
| Points | 976 | 1,045 | 2,078 |
| Inside, near the outline | 407 (42 %) | 75 (7 %) | 188 (9 %) |
| Outside, near the outline | 159 (16 %) | 6 (1 %) | 9 (0 %) |
| Inside, interior | 287 (29 %) | 596 (57 %) | 1,843 (89 %) |
| Outside, > 2 m | 123 (13 %) | 368 (35 %) | 38 (2 %) |
| Near points on a street-facing / other edge | 265 / 299 | 22 / 58 | 25 / 172 |
| Interior centroid ratio, median (p90) | 0.42 (0.66) | 0.19 (0.45) | 0.09 (0.43) |
| House-like buildings with a point inside or near | 726 of 788 | 595 of 876 | 1,564 of 2,763 |
| … with a point near the street-facing edge | 234 (30 %) | 22 (3 %) | 24 (1 %) |

House-like = `building=house/detached/residential/yes` (Lakeview's count includes many alley garages tagged `yes`).

- **Cook (Evanston, Lakeview): structure centroids.** Lakeview points sit at the centre of the footprint; Evanston's
  are close to it. Evanston's 368 outside points: 181 are > 20 m from any OSM building, so most mark houses or lots
  without an OSM footprint.
- **Denver: on or near the structure, not at the door.** Many points sit near an outline, but no more on the
  street-facing edge than on the others, and the foot points are spread along the edges rather than clustered.
- **Check against the 51 blind NAIP labels on the right wall** (the real door read as where the front walk meets
  the facade; [map-confidence.md](map-confidence.md)). The labelled edge was matched to the OSM ring by length for
  all 51 (consistent: today's draw is within 2 m for 21, as published).

| Along the labelled wall, within 2 m of the real door | Sloan's Lake | Evanston | Lakeview | All |
|---|---:|---:|---:|---:|
| Today's seeded draw | 7 / 27 | 6 / 13 | 8 / 11 | 21 / 51 |
| Midpoint of the wall | 9 / 27 | 7 / 13 | 9 / 11 | 25 / 51 |
| Address point projected onto the wall (houses with a point inside or ≤ 3 m) | 8 / 19 | 6 / 12 | 10 / 11 | 24 / 42 |
| Midpoint, same 42 houses | 9 / 19 | 6 / 12 | 9 / 11 | 24 / 42 |
| Today's draw, same 42 houses | 3 / 19 | 5 / 12 | 8 / 11 | 16 / 42 |
| Address point itself ≤ 2 m from the door | 5 / 27 | 0 / 13 | 0 / 11 | 5 / 51 |

The projected point is right exactly as often as the midpoint (it is a centroid, so it projects near the middle). A
point that is actually at the door would land within 2 m nearly every time; these do so for 5 of 51 houses.

**Expected gain:** entrance-placed share ≈ 0 in all three boxes, so door confidence stays at 0.36. The general rule:
if a share X of houses got a true entrance point within 2 m, those houses would score about 0.85–0.9 (capped by
the 1–2 m label and footprint-offset error and the 7 of 58 wrong walls); overall ≈ 0.36 + X × 0.5. Here X ≈ 0.

**Side value (not doors):** linking a point to a building shows which buildings carry an address, a cheap
garage-versus-house check for small `building=yes` footprints. The house number is not needed for that.

## 2. Overture Maps addresses theme

- **Sources here** (release 2026-09-23.1, counted by `sources[].dataset`): Sloan's Lake 1,009 points, all
  `us/co/statewide` ("Colorado Public Addresses", Governor's Office of Information Technology, through
  OpenAddresses); Evanston 1,057 and Lakeview 2,125, all `NAD` (US DOT National Address Database).
- **Licences** (https://docs.overturemaps.org/attribution/, read): the theme has no single licence; each source
  keeps its own. Colorado: "public data", distributed by OpenAddresses; the state item
  (https://geodata.colorado.gov/datasets/b6e244650e7c472ba53667f19ee01181/about) carries only a disclaimer, and
  annual updates from counties and cities. NAD: "National Address Database Access and Usage License" plus the NAD
  disclaimer. **Unverified:** both transportation.gov pages answered 403 to a plainly identified request; I stopped
  there. Confirm them in a normal browser.
- **Placement:** the Overture guide (https://docs.overturemaps.org/guides/addresses/) says points "most often
  represent either building centroids, building entrances, points on a road, or parcel centroids" depending on the
  source; the schema (https://docs.overturemaps.org/schema/reference/addresses/address/) has no placement field.
  Measured: Lakeview median centroid ratio 0.0006 (exact building centroids), Evanston 0.19, Sloan's Lake 0.42
  with 568 near-outline points (264 on street-facing edges), the same pattern as Denver's own data. Label check: 6 of
  27 within 2 m in Sloan's Lake, 0 in Evanston and Lakeview.
- **How to get it:** the same method as `scripts/data/fetch_overture.py` (STAC → the `addresses/address` GeoParquet
  file covering the box → DuckDB `read_parquet` with a `bbox` filter, selecting only geometry and
  `sources[].dataset`). Cost: 4.3 MB of GeoParquet and 30 KB of STAC for all three boxes (plus the one-time DuckDB
  wheel). The raw NAD has a placement attribute that Overture drops; the national NAD download is several GB (not
  attempted), and Cook's own `Placement` field is empty, so NAD is unlikely to say more.
- **Expected gain:** ≈ 0. It repeats the city and county points, with weaker licence clarity.

## 3. OSM footway and path links

| | Sloan's Lake | Evanston | Lakeview |
|---|---:|---:|---:|
| Buildings (closed ways) | 1,427 | 899 | 2,861 |
| House-like | 788 | 876 | 2,763 |
| `footway`/`path` ways, excluding `footway=sidewalk` and `crossing` | 113 | 7 | 15 |
| Ends ≤ 1.5 m from a house-like outline | 0 | 0 | 0 |
| **Houses with a walk to the door** | **0 (0 %)** | **0 (0 %)** | **0 (0 %)** |
| `entrance=*` nodes | 0 | 2 (`yes`, both on buildings) | 2 `exit` + 2 `door=sliding`, none on buildings |

Nearest approach: 9 walk ends 1.5–5 m from a house in Lakeview, the rest > 5 m (mostly park paths in Sloan's Lake).
"Connects toward a street" was checked as: shares a node with a road or sidewalk, or its far end is within 3 m of a
sidewalk or 12 m of a road, or continues into another footway. It never came into play, since no end touches a house.

**Expected gain:** 0 today. OSM mappers in these neighbourhoods map sidewalks and crossings, not front walks.

## Recommendation

1. **Do not add an address-point source for doors.** In all three areas the points are structure centroids or
   loosely placed structure points, never entrances. Cook, Denver and Overture all agree; Evanston's own layer would
   need written permission and has no placement field.
2. **Decision to raise with the generator owner (not made here):** a deterministic "door at the middle of the
   street-facing wall" scored 25 of 51 against 21 of 51 for the seeded draw. The sample is small (Lakeview 11, Evanston
   13) and the gain (0.36 → about 0.43 overall) does not reach the 0.7 floor, but it costs nothing. It conflicts with
   regional house types that put the door off-centre, so it is a design question.
3. **The only door evidence in reach is the front walk in aerial imagery**, the same cue the labels used: walks
   (1–1.2 m, 3–4 NAIP pixels) are discernible where not under canopy (Denver best; Evanston worst at 47 % canopy). An
   automatic walk detector on NAIP, or a hand-labelled set, is the next thing to evaluate.
4. Optional, no door gain: a geometry-only Cook or Denver point join as garage-versus-house evidence.

## Sources and status

| URL | Used for | Status |
|---|---|---|
| https://api.us.socrata.com/api/catalog/v1 (domains data.cityofchicago.org, datacatalog.cookcountyil.gov) | Catalogue search | Read |
| https://datacatalog.cookcountyil.gov/api/views/78yw-iddh.json, `/resource/78yw-iddh.json` and `.geojson` | Cook metadata, licence, placement counts, geometry | Verified |
| https://www.arcgis.com/sharing/rest/content/items/5ec856ded93e4f85b3f6e1bc027a2472 | Cook ArcGIS item | Read |
| https://gis.cookcountyil.gov/traditional/rest/services/addressZipCode/MapServer/0 | Cook schema | Schema read; **query endpoint timed out** |
| https://www.cookcountyil.gov/terms-use | County site terms | Read earlier (map-confidence.md), not re-read |
| https://data.cityofchicago.org | No address-point dataset | Catalogue searched |
| https://www.arcgis.com/sharing/rest/content/items/059a534c87d448dc945637ca54261c14 (+ `/info/metadata/metadata.xml`) | Denver metadata | Verified |
| https://services1.arcgis.com/zdB7qR0BtYrg0Xpl/arcgis/rest/services/ODC_CITY_LOC_ADDRESSPUBLIC_P/FeatureServer/31 | Denver geometry | Verified |
| https://opendata-geospatialdenver.hub.arcgis.com/pages/terms-of-use (site item `08ac95d2733c45059ec5a3c76faa770d`) | Denver CC BY 3.0 | Verified |
| https://www.arcgis.com/sharing/rest/content/items/6d0b7733d4ee475ca8028b876ba6e605 and the Evanston MapServer/4 layer | Evanston metadata | Read; no data fetched |
| https://data.cityofevanston.org/pages/terms (page item `17407e3e88c44de8bae0b4d9ce1c50c3`) | Evanston terms | Verified |
| https://docs.overturemaps.org/attribution/, /guides/addresses/, /schema/reference/addresses/address/ | Overture sources, licences, placement | Verified |
| https://stac.overturemaps.org (release 2026-09-23.1, `addresses/address`) | Overture points | Verified |
| https://geodata.colorado.gov/datasets/b6e244650e7c472ba53667f19ee01181/about (item metadata via the ArcGIS API) | Colorado source terms | Read: disclaimer only |
| https://www.transportation.gov/gis/national-address-database and the NAD disclaimer page | NAD licence | **Unverified: HTTP 403** |
