# Map data coverage: where the world will look accurate and where it will look generic

Workstream B, 2026-10-06 (revised the same day: relation geometry fixed, phase 5A tree meshes). 46 sample cells, each 1 km × 1 km around a named public place: 4 on the North Shore, 9 in Chicago, and 3 in each of 11 other US metros (urban core, inner suburb, outer suburb). For every cell: what OpenStreetMap (OSM) holds for buildings and trees, what Overture Maps adds, and what the generator therefore has to estimate. The last part counts the triangles a dense Chicago cell produces: measured from exported packages of the post-P2 generator (phase 5B, generator `b8f6c71`), with the earlier pre-P2 estimate kept as the baseline.

Every measured number is produced by `Tools/regionkit/audit/` (one command re-runs it, see [Method](#method-and-how-to-re-run)) and stored in `Tools/regionkit/audit/results/`:
- `cells.csv`, `osm_metrics.json`, `overture_metrics.json`: per cell;
- `summary.json`: tiers and the overall figures;
- `triangles.json`: calibration and triangle estimates (pre-P2 baseline);
- `triangles_p2.json`: triangles measured from exported packages (post-P2);
- `downloads.json`: bytes.

Numbers taken from elsewhere cite their file. Estimates are labelled as estimates.

## Summary

1. **The North Shore has almost no houses in OSM.** The four cells hold 154 OSM buildings (shops, churches, civic buildings) against 3,601 in Overture. All 3,448 extra footprints come from Microsoft ML Buildings. From OSM alone these cells would show a few landmarks on otherwise empty blocks.
   - The Evanston cell (Lovelace Park) sits on the Wilmette line, so it is not typical of Evanston.
   - The region kit's Smith Park cell in central Evanston has 160 OSM buildings (`Tools/regionkit/drafts/chicagoland/evanston/report.md`): still sparse, but not empty.
2. **Elsewhere OSM footprints are mostly complete.** Chicago's city import leaves Overture 0.2–0.9% per cell to add. The real holes are:
   - Montclair NJ: 599 of 723 Overture buildings are missing from OSM.
   - Englewood CO: 252 missing, mostly small sheds from Esri Community Maps.
   - Glendale AZ: 110 missing.
3. **Heights are the biggest attribute gap.** Across all cells 42.7% of OSM buildings have `height` or `building:levels` (14.4% height, 32.0% levels).
   - That figure is carried by Chicago's import (51.5%, levels only), the downtowns (67.4% in the other urban cores) and three suburbs with municipal height imports (Culver City, Santa Clarita, Coral Gables: 94–99% `height`).
   - In the other 19 suburban cells, 3.2% of houses have either tag (197 of 6,231). Richardson supplies 134 of those; the other 18 cells are at 1.0%.
   - Overture gives a height for 91.3% of its buildings, and for **85.8% of the OSM buildings that lack one**: USGS lidar for 54% of those, Microsoft's ML estimate for 46%.
   - Overture's `num_floors` never fills an OSM building that lacks levels, and none of its extra footprints has floors.
4. **Roof shape is nearly absent: 2.6% overall, 0% on the North Shore.** None of the North Shore cells has a single `roof:shape` tag, so there are no top values to list. Overture's `roof_shape` adds nothing beyond OSM. North Shore roofs must come entirely from zone profiles and footprints.
5. **Materials and colours (`building:material` or `building:colour`): 2.3% overall.** By tier:
   - 16.2% in the other urban cores;
   - 5.4% in Chicago's two downtown cells;
   - about 0% elsewhere.

   Roof colour or material (`roof:colour` or `roof:material`) is 1.9% overall.
6. **Mapped trees are rare.** North Shore 0.5 per km², Chicago neighbourhoods 78, suburbs about 20.
   - Sloan's Lake, for comparison, has 5,400 mapped trees, or 2,812 per km² (`triangles.json` calibration).
   - Overture has no trees.
   - The generator placed only mapped trees, so most streets would have been treeless. P2's yards (`fd1680f`) now add parkway and yard trees by zone.
7. **`building:part`: 4,916 parts, 97% with height or levels**, almost all downtown (Denver 1,967, Manhattan 1,185, Boston 671, Loop 156). The generator skips parts today.
8. **Triangles (measured after P2, generator `b8f6c71`).** `worldbake export` packages of the five dense cells (four audit cells plus P2's Lakeview), counted from their meshes and run through the audit's street-view culling:
   - Full detail over a whole cell is **0.69–2.24 M static triangles** (`chicago-dense-north` 1.21–1.38 M in the residential cells).
   - A typical street view submits **0.19–0.53 M** with full detail everywhere, **0.10–0.27 M** with a WorldLab-sized focus.
   - The worst views reach **0.55–1.83 M** with full detail everywhere and **0.34–1.08 M** with the focus, against the 400 k ceiling.
   - With the focus, the Loop and Lakeview break the ceiling at p90 (688 k, 482 k). Every `chicago-dense-north` cell breaks it in its worst view (464–605 k).
   - P2's generated parkway and yard trees add 23–61 k to the average view. One Loop chunk alone casts 181 k shadow triangles, over the 150 k ceiling.
   - The pre-P2 estimate (a Python port of the counting rules, within 0.25 % of the recorded Sloan's Lake numbers) held for what it modelled: before yards, the measured views matched it within a few per cent. Curbs still cost 12 triangles per metre of street.

## Main table

Counting follows the engine (`MapFeatureBuilder`):
- One building per closed way, and one per assembled outer polygon of a `type=multipolygon` relation. Each counts when its own centroid (of the raw outer ring) lies inside the cell's ±500 m rectangle.
- `building:part` is counted separately. Cells are 1 km², so buildings per km² equals the count.
- "% material or colour" means `building:material` or `building:colour`.
- "Overture extras" gives two counts: Overture buildings in the cell whose `sources` contain no OpenStreetMap record, and, stricter, those whose centroid also lies inside no current OSM building or part footprint.

| Region | Cell (anchor) | Centre | Buildings | per km² | % height or levels | % roof:shape | % material or colour | Trees per km² | Overture extras: no OSM source / outside OSM footprints | building:part |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| North Shore | Evanston (Walter S. Lovelace Park) | 42.0680, -87.7260 | 26 | 26 | 0.0 | 0.0 | 0.0 | 0 | 991 / 991 | 0 |
| North Shore | Wilmette (Vattman Park) | 42.0779, -87.7137 | 63 | 63 | 4.8 | 0.0 | 0.0 | 0 | 1,129 / 1,129 | 0 |
| North Shore | Winnetka (Village Green Park) | 42.1052, -87.7289 | 49 | 49 | 6.1 | 0.0 | 0.0 | 2 | 532 / 532 | 0 |
| North Shore | Kenilworth (Kenilworth Metra station) | 42.0871, -87.7176 | 16 | 16 | 0.0 | 0.0 | 0.0 | 0 | 796 / 796 | 0 |
| Chicago | Loop (Daley Plaza) | 41.8839, -87.6302 | 437 | 437 | 56.3 | 1.4 | 8.7 | 425 | 1 / 1 | 156 |
| Chicago | River North (Montgomery Ward Park) | 41.8938, -87.6425 | 396 | 396 | 33.8 | 0.5 | 1.8 | 56 | 3 / 3 | 15 |
| Chicago | Lincoln Park (Oz Park) | 41.9206, -87.6457 | 2,232 | 2,232 | 48.0 | 0.0 | 0.0 | 71 | 14 / 14 | 0 |
| Chicago | Lakeview (Gill Park) | 41.9522, -87.6504 | 958 | 958 | 60.6 | 0.4 | 0.5 | 264 | 6 / 6 | 66 |
| Chicago | Rogers Park / Edgewater (Broadway Armory Park) | 41.9893, -87.6596 | 1,405 | 1,405 | 58.4 | 0.1 | 0.1 | 74 | 10 / 10 | 6 |
| Chicago | Logan Square (Illinois Centennial Monument) | 41.9284, -87.7073 | 2,050 | 2,050 | 50.8 | 0.1 | 0.0 | 77 | 18 / 18 | 1 |
| Chicago | Lincoln Square (Giddings Plaza) | 41.9676, -87.6876 | 2,429 | 2,429 | 52.0 | 6.0 | 0.0 | 51 | 23 / 23 | 0 |
| Chicago | Portage Park (Portage Park) | 41.9551, -87.7646 | 2,451 | 2,451 | 50.4 | 0.0 | 0.0 | 0 | 19 / 19 | 0 |
| Chicago | Hyde Park (Nichols Park) | 41.7973, -87.5938 | 1,194 | 1,194 | 44.7 | 0.0 | 0.0 | 9 | 4 / 4 | 2 |
| Denver | LoDo (Union Station) | 39.7532, -105.0003 | 339 | 339 | 83.5 | 4.7 | 74.0 | 2,008 | 1 / 1 | 1,967 |
| Denver | Englewood (Englewood station) | 39.6556, -104.9999 | 218 | 218 | 0.9 | 0.0 | 0.0 | 141 | 252 / 252 | 0 |
| Denver | Highlands Ranch (Civic Green Park) | 39.5457, -104.9959 | 273 | 273 | 1.8 | 0.0 | 0.0 | 0 | 90 / 90 | 1 |
| Dallas–Fort Worth | Downtown Dallas (Main Street Garden) | 32.7812, -96.7948 | 182 | 182 | 49.5 | 0.0 | 0.0 | 180 | 6 / 6 | 34 |
| Dallas–Fort Worth | Richardson (Richardson City Hall / Civic Center) | 32.9596, -96.7315 | 349 | 349 | 73.4 | 0.3 | 0.0 | 0 | 40 / 40 | 0 |
| Dallas–Fort Worth | Frisco (Frisco City Hall) | 33.1500, -96.8346 | 96 | 96 | 16.7 | 1.0 | 0.0 | 80 | 15 / 15 | 0 |
| Houston | Downtown Houston (Market Square Park) | 29.7627, -95.3623 | 186 | 186 | 48.4 | 0.5 | 2.7 | 39 | 4 / 4 | 23 |
| Houston | Bellaire (Bellaire City Hall) | 29.7034, -95.4684 | 827 | 827 | 0.6 | 0.0 | 0.0 | 0 | 7 / 7 | 1 |
| Houston | Sugar Land (Sugar Land Town Hall) | 29.5953, -95.6217 | 77 | 77 | 9.1 | 5.2 | 2.6 | 0 | 8 / 8 | 2 |
| Phoenix | Downtown Phoenix (Civic Space Park) | 33.4532, -112.0745 | 348 | 348 | 19.8 | 4.0 | 2.3 | 1,562 | 12 / 12 | 48 |
| Phoenix | Glendale (Murphy Park) | 33.5392, -112.1844 | 642 | 642 | 8.7 | 0.0 | 0.0 | 23 | 110 / 110 | 0 |
| Phoenix | Gilbert (Gilbert Civic Center) | 33.3307, -111.7882 | 361 | 361 | 0.6 | 0.0 | 0.0 | 0 | 29 / 29 | 0 |
| Los Angeles | Downtown Los Angeles (Pershing Square) | 34.0484, -118.2530 | 352 | 352 | 91.8 | 6.2 | 4.0 | 173 | 2 / 2 | 79 |
| Los Angeles | Culver City (Culver City Hall) | 34.0214, -118.3957 | 1,182 | 1,182 | 95.8 | 19.6 | 0.0 | 0 | 7 / 7 | 164 |
| Los Angeles | Santa Clarita, Valencia (Santa Clarita City Hall) | 34.4127, -118.5538 | 534 | 534 | 98.5 | 0.0 | 0.0 | 0 | 2 / 2 | 0 |
| Seattle | Downtown Seattle (Westlake Park) | 47.6109, -122.3371 | 337 | 337 | 68.8 | 3.0 | 13.9 | 115 | 20 / 20 | 271 |
| Seattle | Shoreline (Shoreline City Hall) | 47.7563, -122.3435 | 612 | 612 | 5.4 | 0.0 | 0.0 | 34 | 34 / 33 | 5 |
| Seattle | Sammamish (Sammamish Commons) | 47.6014, -122.0367 | 260 | 260 | 1.2 | 0.4 | 0.0 | 113 | 4 / 4 | 0 |
| Minneapolis | Downtown Minneapolis (Peavey Plaza) | 44.9723, -93.2756 | 196 | 196 | 39.8 | 12.8 | 12.2 | 321 | 49 / 49 | 82 |
| Minneapolis | Richfield (Richfield Municipal Center) | 44.8807, -93.2689 | 972 | 972 | 0.5 | 0.0 | 0.0 | 0 | 29 / 29 | 0 |
| Minneapolis | Woodbury (Woodbury City Hall) | 44.9189, -92.9367 | 91 | 91 | 2.2 | 0.0 | 0.0 | 21 | 30 / 30 | 7 |
| Atlanta | Downtown Atlanta (Woodruff Park) | 33.7556, -84.3886 | 293 | 293 | 42.0 | 2.4 | 0.3 | 83 | 10 / 10 | 54 |
| Atlanta | Decatur (Decatur History Center, old courthouse on the square) | 33.7751, -84.2965 | 362 | 362 | 7.7 | 0.8 | 0.0 | 0 | 19 / 19 | 5 |
| Atlanta | Alpharetta (Alpharetta City Hall) | 34.0746, -84.2923 | 409 | 409 | 3.9 | 0.0 | 0.0 | 15 | 9 / 9 | 0 |
| Miami | Brickell (Brickell station) | 25.7627, -80.1953 | 226 | 226 | 69.9 | 0.0 | 0.0 | 174 | 11 / 11 | 44 |
| Miami | Coral Gables (Venetian Pool) | 25.7458, -80.2732 | 621 | 621 | 97.3 | 0.0 | 0.0 | 1 | 8 / 8 | 24 |
| Miami | Pembroke Pines (Pembroke Pines City Hall) | 26.0033, -80.2866 | 239 | 239 | 0.8 | 0.0 | 0.0 | 0 | 6 / 6 | 0 |
| Boston | Financial District (Norman B. Leventhal Park) | 42.3563, -71.0556 | 447 | 447 | 83.7 | 27.5 | 30.2 | 363 | 12 / 12 | 671 |
| Boston | Arlington, MA (Arlington Town Hall) | 42.4157, -71.1564 | 817 | 817 | 2.1 | 0.5 | 0.0 | 11 | 8 / 8 | 3 |
| Boston | Natick (Natick Common) | 42.2837, -71.3471 | 1,094 | 1,094 | 0.3 | 0.0 | 0.0 | 6 | 12 / 12 | 0 |
| New York | Midtown Manhattan (Bryant Park) | 40.7538, -73.9835 | 775 | 775 | 85.2 | 15.1 | 14.2 | 652 | 1 / 1 | 1,185 |
| New York | Montclair, NJ (Bay Street station) | 40.8082, -74.2087 | 124 | 124 | 4.8 | 0.8 | 0.8 | 0 | 599 / 599 | 0 |
| New York | Levittown, NY, Long Island (Levittown Public Library) | 40.7233, -73.5297 | 880 | 880 | 0.0 | 0.0 | 0.0 | 0 | 57 / 57 | 0 |

Anchor names follow OSM, with a short description where the OSM name alone is ambiguous. Every anchor, its OSM element and the reason it was chosen are in `Tools/regionkit/audit/cells.json`.

**Agreement with the region kit:** the eight cells both workstreams share match exactly: Coral Gables 621, Hyde Park 1,194, Lakeview 958, Loop 437, Edgewater 1,405, Wilmette 63, Lincoln Park 2,232, Portage Park 2,451. Two fixes were needed to get there:
- relations were re-fetched with their member geometry;
- the counting rectangle is now exactly ±500 m in the local frame, as the region kit uses. Before that it came from the rounded lat/lon corners and differed by centimetres (up to 0.07 m in the cells checked); one Lincoln Park building has its centroid 8 mm outside the line.

**Engine behaviours found while matching the engine (reported, not changed; P2 fixed both on main in `1085568`):**
- A way tagged `building` that is also the outer of a building multipolygon is counted, and drawn, twice. This happens twice in these cells (downtown Atlanta, Decatur).
- `MapFeatureBuilder` also assembles `type=building` relations that carry a `building` tag. Their outline and part members then become extra full-height building polygons. There are 9 such relations here: Lakeview 1, downtown Seattle 8. The audit does not count them; the triangle model mirrors the engine.

### Detail: the height split and what Overture adds

"Overture % floors" is the share of Overture buildings with `num_floors`. Its denominator (Overture buildings in the cell) differs from OSM's, so it doesn't match OSM's levels share cell by cell (Wilmette 4.8% vs 0.3%). Two things are supported:
- `num_floors` fills no OSM building that lacks levels (0 of 16,287 across all cells);
- no extra footprint has floors.

The roof column measures `roof:colour` or `roof:material`. The "… that Overture gives a height" column counts OSM buildings without height or levels that get an Overture height, matched by OSM ID through Overture's `sources.record_id`.

MS = Microsoft ML Buildings, USGS = USGS lidar (3DEP), Esri = Esri Community Maps.

| Cell | % height | % levels | % roof colour or material | Overture buildings | Overture % height | Overture % floors | OSM buildings missing height/levels | … that Overture gives a height (source) | Extras by source (median area m²) |
|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| Evanston | 0.0 | 0.0 | 0.0 | 1,017 | 99.8 | 0.0 | 26 | 92.3% (MS 11; USGS 13) | MS 991 (142) |
| Wilmette | 0.0 | 4.8 | 0.0 | 1,191 | 99.7 | 0.3 | 60 | 93.3% (MS 17; USGS 38) | MS 1129 (114) |
| Winnetka | 0.0 | 6.1 | 0.0 | 581 | 98.5 | 0.5 | 46 | 80.4% (MS 14; USGS 23) | MS 532 (185) |
| Kenilworth | 0.0 | 0.0 | 0.0 | 812 | 99.9 | 0.0 | 16 | 93.8% (MS 1; USGS 14) | MS 796 (146) |
| Loop | 16.7 | 55.1 | 1.6 | 441 | 58.5 | 54.9 | 191 | 28.3% (MS 3; USGS 51) | MS 1 (192) |
| River North | 2.8 | 33.8 | 0.5 | 399 | 92.2 | 33.6 | 262 | 89.3% (MS 17; USGS 217) | MS 3 (37) |
| Lincoln Park | 0.0 | 48.0 | 0.0 | 2,246 | 98.0 | 47.7 | 1,160 | 96.5% (MS 99; USGS 1020) | MS 14 (47) |
| Lakeview | 0.5 | 60.3 | 0.1 | 962 | 91.0 | 60.1 | 377 | 78.8% (MS 38; USGS 257) | MS 6 (48) |
| Rogers Park / Edgewater | 0.0 | 58.4 | 0.0 | 1,415 | 86.2 | 58.0 | 585 | 69.1% (MS 122; USGS 282) | MS 10 (35) |
| Logan Square | 0.0 | 50.8 | 0.0 | 2,068 | 94.2 | 50.4 | 1,008 | 88.5% (MS 152; USGS 740) | MS 18 (48) |
| Lincoln Square | 0.0 | 52.0 | 0.0 | 2,452 | 94.7 | 51.5 | 1,166 | 89.0% (MS 214; USGS 824) | MS 23 (49) |
| Portage Park | 0.0 | 50.4 | 0.0 | 2,470 | 96.6 | 50.0 | 1,215 | 93.2% (MS 327; USGS 805) | MS 19 (50) |
| Hyde Park | 0.0 | 44.7 | 0.0 | 1,198 | 90.1 | 44.6 | 660 | 82.3% (MS 56; USGS 487) | MS 4 (75) |
| LoDo, Denver | 44.0 | 79.1 | 78.8 | 340 | 70.6 | 78.8 | 56 | 14.3% (MS 2; USGS 6) | MS 1 (44) |
| Englewood | 0.0 | 0.9 | 0.0 | 470 | 52.1 | 0.4 | 216 | 97.2% (MS 110; USGS 100) | Esri 245; MS 7 (28) |
| Highlands Ranch | 0.0 | 1.8 | 0.0 | 363 | 94.8 | 1.4 | 268 | 95.5% (MS 256) | Esri 89; MS 1 (202) |
| Downtown Dallas | 18.1 | 38.5 | 0.0 | 187 | 88.2 | 35.3 | 92 | 82.6% (MS 29; USGS 47) | MS 6 (88) |
| Richardson | 45.0 | 32.1 | 0.0 | 389 | 94.6 | 28.8 | 93 | 93.5% (MS 49; USGS 38) | Esri 36; MS 4 (58) |
| Frisco | 2.1 | 15.6 | 0.0 | 111 | 55.0 | 13.5 | 80 | 55.0% (MS 44) | MS 15 (79) |
| Downtown Houston | 28.5 | 30.6 | 0.0 | 190 | 76.3 | 30.0 | 96 | 55.2% (MS 12; USGS 41) | MS 4 (103) |
| Bellaire | 0.0 | 0.6 | 0.0 | 834 | 99.0 | 0.6 | 822 | 99.0% (MS 587; USGS 227) | MS 7 (15) |
| Sugar Land | 3.9 | 9.1 | 0.0 | 85 | 80.0 | 7.1 | 70 | 75.7% (MS 53) | MS 8 (448) |
| Downtown Phoenix | 4.0 | 18.1 | 1.7 | 359 | 92.5 | 16.7 | 279 | 90.3% (MS 60; USGS 192) | MS 12 (88) |
| Glendale | 0.0 | 8.7 | 0.0 | 752 | 95.1 | 7.4 | 586 | 98.5% (MS 216; USGS 361) | Esri 88; MS 22 (42) |
| Gilbert | 0.0 | 0.6 | 0.0 | 389 | 97.4 | 0.5 | 359 | 98.1% (MS 92; USGS 260) | MS 29 (64) |
| Downtown Los Angeles | 85.5 | 47.2 | 2.8 | 353 | 95.2 | 47.0 | 29 | 51.7% (MS 3; USGS 12) | MS 2 (173) |
| Culver City | 93.7 | 25.4 | 0.0 | 1,189 | 98.7 | 25.1 | 50 | 86.0% (MS 10; USGS 33) | MS 7 (59) |
| Santa Clarita (Valencia) | 98.5 | 0.2 | 0.0 | 536 | 98.7 | 0.2 | 8 | 12.5% (USGS 1) | MS 2 (50) |
| Downtown Seattle | 14.5 | 67.1 | 3.0 | 357 | 82.1 | 63.0 | 105 | 81.9% (USGS 86) | Esri 19; MS 1 (53) |
| Shoreline | 0.0 | 5.4 | 0.0 | 645 | 98.1 | 5.1 | 579 | 97.9% (MS 295; USGS 272) | MS 34 (41) |
| Sammamish | 0.4 | 0.8 | 0.8 | 264 | 92.0 | 0.8 | 257 | 91.8% (MS 125; USGS 111) | MS 4 (461) |
| Downtown Minneapolis | 9.2 | 39.8 | 0.5 | 244 | 30.3 | 31.6 | 118 | 23.7% (MS 28) | Esri 45; MS 4 (18) |
| Richfield | 0.0 | 0.5 | 0.0 | 1,001 | 92.3 | 0.5 | 967 | 92.1% (MS 891) | MS 29 (39) |
| Woodbury | 0.0 | 2.2 | 0.0 | 121 | 78.5 | 1.7 | 89 | 71.9% (MS 64) | MS 30 (245) |
| Downtown Atlanta | 9.9 | 41.6 | 0.0 | 301 | 90.0 | 40.5 | 170 | 85.9% (MS 19; USGS 127) | MS 10 (65) |
| Decatur | 0.0 | 7.7 | 0.0 | 380 | 66.6 | 4.2 | 334 | 64.1% (MS 213) | MS 19 (62) |
| Alpharetta | 0.0 | 3.9 | 0.0 | 390 | 46.2 | 4.1 | 393 | 41.7% (MS 164) | MS 9 (73) |
| Brickell, Miami | 66.4 | 11.5 | 0.0 | 237 | 73.8 | 11.0 | 68 | 33.8% (USGS 23) | MS 11 (83) |
| Coral Gables | 97.3 | 0.0 | 0.0 | 628 | 99.8 | 0.0 | 17 | 94.1% (MS 8; USGS 8) | MS 8 (56) |
| Pembroke Pines | 0.4 | 0.4 | 0.0 | 245 | 84.9 | 0.4 | 237 | 86.1% (MS 204) | MS 6 (72) |
| Financial District, Boston | 34.2 | 78.1 | 28.2 | 456 | 91.9 | 75.7 | 73 | 69.9% (Esri 19; MS 2; USGS 30) | Esri 11; MS 1 (50) |
| Arlington, MA | 0.0 | 2.1 | 0.0 | 825 | 88.1 | 2.1 | 800 | 87.8% (MS 350; USGS 352) | MS 8 (32) |
| Natick | 0.0 | 0.3 | 0.0 | 1,105 | 88.0 | 0.2 | 1,091 | 87.8% (MS 584; USGS 374) | MS 12 (42) |
| Midtown Manhattan | 83.7 | 17.3 | 15.2 | 776 | 95.7 | 17.3 | 115 | 73.9% (MS 6; USGS 79) | MS 1 (135) |
| Montclair, NJ | 0.0 | 4.8 | 0.0 | 723 | 94.9 | 0.8 | 118 | 68.6% (MS 81) | MS 599 (124) |
| Levittown, NY | 0.0 | 0.0 | 0.0 | 937 | 88.3 | 0.0 | 880 | 87.5% (MS 770) | MS 57 (36) |

### By kind of place (building-weighted)

| Tier | Cells | OSM buildings | % height or levels (houses / blocks) | % roof:shape | % `building:material` or `building:colour` | Trees per km² | `building:part` | Overture extras (share of Overture) | Overture % with height | OSM height gaps Overture fills |
|---|---:|---:|---|---:|---:|---:|---:|---|---:|---:|
| North Shore | 4 | 154 | 3.9 (0.0 / 5.6) | 0.0 | 0.0 | 0.5 | 0 | 3,448 (95.8%), all MS | 99.6 | 89.2% |
| Chicago downtown | 2 | 833 | 45.6 (16.2 / 61.2) | 1.0 | 5.4 | 241 | 171 | 4 (0.5%) | 74.5 | 63.6% |
| Chicago neighbourhoods | 7 | 12,719 | 51.5 (52.8 / 68.7) | 1.2 | 0.0 | 78 | 75 | 94 (0.7%) | 93.9 | 87.9% |
| Other urban cores | 11 | 3,681 | 67.4 (68.0 / 70.5) | 9.1 | 16.2 | 516 | 4,458 | 128 (3.4%) | 84.0 | 68.5% |
| Inner suburbs | 11 | 6,726 | 31.9 (23.6 / 48.7) | 3.6 | 0.0 | 19 | 202 | 1,113 (14.2%) | 91.6 | 91.7% |
| Outer suburbs | 11 | 4,314 | 13.5 (13.2 / 15.6) | 0.1 | 0.0 | 21 | 10 | 262 (5.8%) | 85.9 | 83.1% |
| **All** | **46** | **28,427** | **42.7** (houses 39.2) | **2.6** | **2.3** | | **4,916** | **5,049 (15.1%)** | **91.3** | **85.8%** |

"Houses" and "blocks" are the generator's roles (`BuildingGenerator.role`): houses are the house types plus `building=yes` under 250 m²; blocks are everything else that isn't a garage or shed. Overture's 30,519 heights in these cells come from:
- USGS lidar: 13,960;
- Microsoft ML: 12,318;
- OSM: 4,085;
- Esri: 156.

Caveat on the outer-suburb row: those anchors are civic centres, and in Frisco, Sugar Land and Woodbury the cell is mostly a civic or commercial campus (77–96 OSM buildings). The coverage percentages hold for that fabric. Subdivision houses are better represented by the inner-suburb cells, Levittown and Natick. See [Decisions for the owner](#decisions-for-the-owner).

## Biggest gaps, ranked, and what the generator should do

**Update after P2 buildings (main `91ed01c`, merged 2026-10-06, after this analysis of `772ff24`).** P2 added an alley-garage rule to the generator (`BuildingGenerator.role(for:)`: `building=yes` of 14–75 m², at most 1.5 levels, a mapped alley edge within 9 m and no street front within 9 m becomes a garage), keeps large `building=yes` below the profile's `hugeArea` with ≤ 3 levels as houses, picks block families from tag evidence (`HouseFamilies.blockFamily`: tall, court, commercial, apartments, else the plain block), and adds roof assemblies (cross-gables, dormers, chimneys) and rear porches toward mapped alleys (`docs/buildings/README.md`). It also adopted `chicago-dense-north`, `evanston` and `wilmette` unchanged. That addresses gap 6 (garages) and the block-family part of the triangle and roof discussion; gaps 1–5 and 7–9 stand. The two map behaviours listed under the main table (a building way that is also a multipolygon outer drawn twice; tagged `type=building` relations becoming extra full-height buildings) were fixed by P2 on main in `1085568`. Since then P2's yards (`fd1680f`) also generate parkway and yard trees by zone, which addresses gap 4 (841–1,971 trees per dense cell; their triangle cost is in the measured counts below).

Ranked by how much of the world they make generic. "Zone default" names the proposed zone profile that would supply the value (`docs/proposals/regions-chicagoland-miami/`, read-only proposal; outside those zones the bundled `default` / `front-range` profiles).

1. **Whole neighbourhoods without footprints (North Shore, Montclair, parts of Englewood and Glendale). Fill from Overture.**
   - **Scale:** OSM has 4% of the North Shore's buildings (154 of 3,601). All 3,448 extras are Microsoft ML footprints, and their median area of 114–185 m² says these are the houses themselves, not sheds.
   - **Merge rule:** the buildings theme is ODbL, so it can sit in the same area manifest as a second source. De-duplication is nearly free: in 45 of 46 cells every Overture building without an OSM source also has its centroid outside every OSM footprint (Shoreline: 34 vs 33). "Add Overture buildings with no OSM source" is therefore a sufficient merge rule, and real OSM tags keep winning wherever OSM has the building.
   - **Licensing:** see `licensing.md` O12 and V1.
     - O12: merging non-OSM data onto OSM features by OSM ID, such as heights, is not a trivial transformation, so share-alike covers the combination.
     - V1: per-source credits apply, for example Esri Community Maps (CC BY 4.0), whose extras appear in 7 of these cells.
   - **Zone defaults in the proposed catalog:**
     - the Lovelace (Evanston) cell falls in the `wilmette` box;
     - the Wilmette cell maps to `wilmette`;
     - Kenilworth maps to `kenilworth`;
     - the Winnetka cell's centre lies in no box: it is just east of the `winnetka` box, so the catalog falls back to `generic-temperate-v1`.

2. **Floors missing for most houses outside Chicago and the height-import cities. Fill height from Overture, then estimate floors; else default by zone.**
   - **Scale:** in the 19 suburban cells without a municipal height import, 3.2% of houses have height or levels, and 1.0% without Richardson. On the North Shore none of the 3,448 filled footprints has floors.
   - **Current behaviour:** the generator ignores the type-default heights in `HeightRules` and uses the chosen house type's first floor count.
     - With the bundled `default` profile, the triangle model makes **85.0% of untagged houses one-storey** in those 19 cells (5,162 of 6,071; `summary.json`). The "unknown" rule weights alone already give 85% one-floor types (compactGabled 50 + broadLow 25 + flatRoof 10 of 100).
     - Natick: 916 of 1,000 houses are one-storey (1.084 floors on average), although New England colonials are mostly two storeys.
     - Untagged blocks get 1 floor in `default` and 3 in the proposed `chicago-*` profiles.
   - **Handling:**
     - Use Overture `height` where OSM has none. It covers 99.6% of North Shore buildings (Microsoft's ML estimate), and 85.8% of OSM's gaps across all cells: USGS lidar for 54% of those fills (measured) and Microsoft ML for 46% (estimated; less reliable).
     - Floors = round((height − roof rise) / zone `perFloor`), clamped to the zone family's `floors`. A family should only be eligible if it fits.
     - No height at all: zone default by footprint (`chicago-greystone-twoflat` 2–3 floors on narrow deep lots, `chicago-bungalow-belt` 1, North Shore profiles 2).
     - Overture `num_floors` is not worth reading (see the detail table).

3. **Towers with a height but no levels get one row of windows.** Manhattan has 83.7% `height` but 17.3% levels; Brickell 66% / 12%; downtown Los Angeles 86% / 47%. The generator keeps such blocks at the type's first floor count, so a 200 m tower gets ground-floor windows only. Estimate floors from height (blocks: height / 3.5–4.0 m, `chicago-downtown` `perFloor` 3.2–4.1). **This must ship together with facade LOD (gap 9):** in the triangle model, Manhattan's buildings go from 0.80 M to 2.56 M triangles when floors come from height.

4. **No street trees. Generate them by zone.**
   - **Scale:** mapped trees per km² are 0.5 on the North Shore, 78 in Chicago neighbourhoods, about 20 in the suburbs and 516 in the other urban cores (Denver 2,008, Phoenix 1,562, Manhattan 652). Sloan's Lake (5,400 mapped trees, 2,812 per km²) shows what dense mapping looks like. Overture has no trees.
   - **Effect:** the generator only places mapped trees, so the North Shore, which is heavily wooded, would render treeless.
   - **Handling:** add parkway trees along residential streets (spacing per zone) plus yard trees by lot size, seeded by street/lot ID. The zone profiles already give species shares and sizes (`trees` block) but no density; a density field is missing from the profile format.
   - **Budget:** at Sloan's Lake density, trees cost about 100 k triangles per street view with the phase 5A tree meshes (model median along the Sloan's Lake walk loop; 65 k with the earlier meshes).

5. **Roof shapes: default by zone, estimate from footprint.** 2.6% overall, 0% on the North Shore (no `roof:shape` tag at all, so there is no top-value list), 1.2% in Chicago's neighbourhoods. Overture adds nothing.
   - Keep today's footprint rules (rectangles, L/T decomposition, irregular → flat).
   - The North Shore's cross-gables, Tudor and Prairie hips come only from the zone families' roof mixes (`evanston`: tudor 0.9 gabled, prairie 0.9 hipped, and so on).
   - The current roof vocabulary (gabled/hipped/flat/slab per rectangle) has no cross-gable or dormer element, which is a profile/generator gap rather than a data gap.

6. **Small untagged outlines, probably detached garages, become houses. Estimate the role from footprint and context.**
   - **Count:** in the seven Chicago neighbourhood cells, 3,525 of 12,719 OSM buildings (27.7%) are `building=yes`, under 60 m² and without `building:levels` (`summary.json`, `_chicagoSmallYesNoLevels`). That is a share of all buildings, with no road test.
   - **Related measure:** the region kit's "probable garage" (`docs/research/region-kit.md`) is stricter and uses a different base. It counts generator houses with `building=yes`, under 60 m², within 8 m of a service road, as a share of generator houses: 31.5% in its dense-north zone, 30% greystone, 44% bungalow belt.
   - **Caveat:** both are unvalidated heuristics; they read like the city import's alley garages but haven't been checked against imagery.
   - **Effect:** the generator's role rule makes them "houses", so they get front doors, porches, foundation bushes and windows.
   - **Handling:** treat an untagged footprint under about 60 m² with an edge on an alley or service road as a garage. The same rule covers Overture's small extras (Englewood median 28 m²).

7. **Materials and colours: default by zone palette.** 2.3% overall (16.2% in the other urban cores, 5.4% in Chicago's downtown, about 0% elsewhere). Keep the profile colour tuples (`chicago-greystone-twoflat` limestone/brick families and so on). Where `building:colour` or `roof:colour` exists it already overrides.

8. **`building:part` towers: implement parts.** 4,916 parts, 97% with height or levels, mostly downtown (Denver 1,967 in one cell). The generator skips every part (`SceneGenerator`: `where !building.isPart`), so stepped towers render as their outline at the outline's height. The data is good where it exists; this is generator work (already planned before downtown Denver in `plan-m1.md`).

9. **Facade detail on tall blocks: needs LOD before any of the above lands.** See the triangle counts: window frames are 97% of the Loop's building triangles (pre-P2 port), and one Loop chunk alone is 181 k triangles (measured).

## Triangle counts for a dense Chicago cell

Two parts:
- **Measured after P2** (below): `worldbake export` packages of the current generator, counted from their meshes.
- **Pre-P2 baseline** (further down): the earlier estimate from a Python port of the generator at `772ff24`, kept for comparison.

### Measured after P2 (generator `b8f6c71`)

**Commit.** Measured on main `b8f6c71` (2026-10-06); main has since moved to `680d47b`, which adds only the Wilmette test area, with no generator change. The generator at `b8f6c71` includes:
- P2's buildings (`91ed01c`);
- P2's two `MapFeatureBuilder` fixes (`1085568`): a building way that is also a building-multipolygon outer is drawn once, and `type=building` relations no longer make extra buildings;
- P1's profile update (`f69c2bf`: measured dense-north storey mix);
- P2's facades (`a8cf90c`), yards with parkway and yard trees (`fd1680f`), and relative size thresholds (`057fc02`).

The measurement is therefore **after** P2's two map fixes. The same runs were also made on `1085568` and `44eeaa3`. Whole cell, static triangles and street-view mean:

| Run (whole cell) | `1085568` | `44eeaa3` (storey mix) | `b8f6c71` (facades, yards, trees) |
|---|---|---|---|
| Loop, `default` | 2,239,714; 508,623 | same | 2,240,042; 525,069 |
| River North, `default` | 686,892; 168,876 | same | 690,952; 193,474 |
| Lincoln Park, `chicago-dense-north` | 1,188,577; 288,923 | 1,204,170; 292,188 | 1,291,041; 373,283 |
| Edgewater, `chicago-dense-north` | 1,104,595; 266,759 | 1,106,567; 267,172 | 1,209,903; 339,670 |
| Lakeview, `chicago-dense-north` | 1,259,469; 308,560 | 1,270,225; 310,882 | 1,380,018; 408,913 |

Most of the latest step is generated trees. Lakeview's whole cell went from 5 trees (mapped) to 1,967, and the street view gained 61 k tree triangles on average.

**Nothing ran on a device.** These are the triangles RealityKit would be asked to draw under `World.estimateViewTriangles`' rules, measured from the exported meshes. They are not GPU timings.

**Method** (`Tools/regionkit/audit/pkgtris.py`; runs in `pkgruns.json`; results in `results/triangles_p2.json`; one command, see the audit README).
- **Areas:**
  - the four dense cells: `worldbake init-area` (1000 m × 1000 m around the `cells.json` centre), then `worldbake fetch` (OSM base 2026-10-06T12:33:02Z and 12:34:03Z);
  - Lakeview: a copy of the committed `Data/areas/lakeview-sheil-park` (OSM 06:22:21Z);
  - Overture's extra footprints (`fetch --layers overture`) were not added; they are 0.2–0.9 % of buildings in these cells.
- **Export:** `worldbake export --date 2026-10-22T20:00:00Z`, twice per cell:
  - whole area (no focus), so every chunk gets full detail;
  - a WorldLab-sized focus of 470 m × 599 m, centred. `world.json` confirms it selects the central 3 × 3 chunks.
- **Profiles:**
  - Loop and River North: `default`. That is the generator's own pick: Chicago's region boxes don't reach downtown, and the engine has no downtown profile.
  - Lincoln Park, Edgewater and Lakeview: `chicago-dense-north`, as P2's BuildingLab uses it for Lakeview, and what `regions.json` picks for all three.
  - The residential cells were also exported with `default`, for a like-for-like comparison with the pre-P2 baseline.
- **Static triangles:**
  - summed from the index accessors of every chunk's `lod0.glb` and `lod1.glb`; they equal the per-chunk `triangles` in `world.json`;
  - split by feature kind with `_FEATURE` and `scene.json`;
  - split into flat ground and raised geometry with `World.splitFlatGround`'s rule (every corner below 0.3 m = flat).
- **Street view:** the pre-P2 audit's cameras and wedge test (25 positions at the chunk centres × 8 headings, portrait 9:19.5, 50° vertical field of view). Each item counts whole when its bounds meet the view, as in World.swift:
  - each chunk is two entities, as in `World.buildChunks`: flat ground plus water, and raised geometry, each culled by its own mesh bounds;
  - props come from `instances.json`, grouped as in `World.buildProps` (kind, variant and 400 m cell; LOD buckets at 45 and 160 m), with each prototype's measured triangles;
  - lamps and benches are culled per group;
  - plus 200 tufts × 17 and the 2-triangle boundary.
  - The pre-P2 method culled whole chunks by their 200 m grid squares. It is reported alongside as "grid culling", so the two can be compared.
- **Shadows:**
  - the raised triangles of chunks whose raised-entity bounds meet an 80 m view wedge (the pre-P2 audit's approximation of RealityKit's 80 m shadow distance);
  - and the heaviest single chunk's raised triangles: what one shadow-casting chunk entity submits;
  - trees within 80 m add 6–15 k on average (`shadowTrees80Mean`).

| Cell | Profile | Focus | lod0 static | lod1 static | … buildings / curbs (lod0) | Street view mean / p90 / max | … trees / bushes (view mean) | Same, grid culling | Heaviest chunk, raised | Shadow casters per view mean / max | Trees placed |
|---|---|---|---:|---:|---|---|---|---|---:|---|---:|
| Loop | default | whole cell | 2,240,042 | 41,775 | 2,035,150 / 173,844 | **525,069** / 1,045,584 / 1,832,038 | 23,524 / 6,654 | 511,923 / 1,020,637 / 1,506,361 | 180,925 | 90,442 / 332,630 | 902 |
| Loop | default | WorldLab-sized | 1,024,595 | 41,551 | 951,729 / 50,052 | **270,516** / 688,414 / 1,084,666 | 23,356 / 2,768 | 261,319 / 672,786 / 858,572 | 180,925 | 45,226 / 332,630 | 900 |
| River North | default | whole cell | 690,952 | 29,518 | 544,711 / 122,700 | **193,474** / 424,616 / 549,969 | 22,558 / 8,780 | 186,831 / 414,576 / 540,962 | 70,761 | 24,345 / 100,683 | 841 |
| River North | default | WorldLab-sized | 283,067 | 28,739 | 235,181 / 32,952 | **96,253** / 262,599 / 337,426 | 22,611 / 3,491 | 95,473 / 259,973 / 331,153 | 70,761 | 10,412 / 71,385 | 843 |
| Lincoln Park | chicago-dense-north | whole cell | 1,291,041 | 130,534 | 1,117,101 / 141,300 | **373,283** / 653,995 / 958,381 | 51,539 / 19,009 | 350,806 / 642,373 / 904,499 | 57,794 | 44,386 / 96,693 | 1,721 |
| Lincoln Park | chicago-dense-north | WorldLab-sized | 455,227 | 130,149 | 395,260 / 33,888 | **168,521** / 340,928 / 469,134 | 51,592 / 5,511 | 162,186 / 331,952 / 455,448 | 54,364 | 15,596 / 71,011 | 1,722 |
| Lincoln Park | default | whole cell | 1,025,710 | 130,882 | 852,069 / 141,300 | **312,121** / 548,867 / 801,408 | 45,878 / 18,412 | 289,149 / 526,034 / 742,690 | 45,477 | 32,683 / 67,552 | 1,635 |
| Lincoln Park | default | WorldLab-sized | 380,611 | 130,495 | 320,825 / 33,888 | **146,655** / 290,272 / 397,654 | 45,954 / 5,501 | 139,811 / 276,571 / 382,487 | 37,737 | 12,459 / 55,789 | 1,638 |
| Edgewater | chicago-dense-north | whole cell | 1,209,903 | 104,703 | 1,034,903 / 132,048 | **339,670** / 644,939 / 923,669 | 41,920 / 15,689 | 320,647 / 606,609 / 878,803 | 78,474 | 40,475 / 132,977 | 1,388 |
| Edgewater | chicago-dense-north | WorldLab-sized | 455,531 | 103,041 | 385,571 / 39,924 | **162,544** / 382,675 / 464,080 | 42,548 / 5,714 | 154,532 / 354,423 / 457,798 | 47,643 | 15,134 / 47,643 | 1,414 |
| Edgewater | default | whole cell | 1,013,574 | 104,737 | 838,856 / 132,048 | **293,776** / 550,354 / 794,369 | 37,368 / 14,794 | 273,568 / 515,920 / 749,084 | 76,961 | 32,312 / 130,928 | 1,353 |
| Edgewater | default | WorldLab-sized | 376,904 | 103,075 | 307,164 / 39,924 | **140,314** / 317,204 / 395,442 | 37,894 / 5,240 | 131,669 / 295,232 / 385,424 | 37,120 | 11,824 / 37,120 | 1,372 |
| Lakeview (Sheil Park) | chicago-dense-north | whole cell | 1,380,018 | 153,148 | 1,177,545 / 166,158 | **408,913** / 800,759 / 1,083,852 | 60,874 / 20,767 | 385,356 / 747,095 / 1,049,107 | 53,866 | 45,691 / 99,092 | 1,967 |
| Lakeview (Sheil Park) | chicago-dense-north | WorldLab-sized | 577,114 | 153,050 | 498,819 / 47,658 | **211,705** / 482,085 / 604,826 | 60,994 / 7,877 | 203,282 / 454,453 / 591,215 | 51,911 | 19,510 / 51,911 | 1,971 |
| Lakeview (Sheil Park) | default | whole cell | 1,078,142 | 152,143 | 876,068 / 166,158 | **338,412** / 649,305 / 878,685 | 54,430 / 20,101 | 314,459 / 612,044 / 846,947 | 38,435 | 32,823 / 65,022 | 1,889 |

**Against the pre-P2 baseline** (same cells, `default` profile, whole cell):

| Cell | Baseline static | Measured static | Baseline view mean / p90 / max | Measured, grid culling (same method) | Measured, entity culling (engine) |
|---|---:|---:|---|---|---|
| Loop | 2,188,944 | 2,240,042 (+2.3 %) | 496,198 / 973,985 / 1,439,850 | 511,923 / 1,020,637 / 1,506,361 | 525,069 / 1,045,584 / 1,832,038 |
| River North | 667,908 | 690,952 (+3.4 %) | 173,499 / 363,811 / 481,699 | 186,831 / 414,576 / 540,962 | 193,474 / 424,616 / 549,969 |
| Lincoln Park | 932,888 | 1,025,710 (+9.9 %) | 244,803 / 430,282 / 600,282 | 289,149 / 526,034 / 742,690 | 312,121 / 548,867 / 801,408 |
| Edgewater | 981,255 | 1,013,574 (+3.3 %) | 247,994 / 450,828 / 641,205 | 273,568 / 515,920 / 749,084 | 293,776 / 550,354 / 794,369 |

What changed:
- **The model held up for what it modelled.** At `44eeaa3`, before yards and generated trees, the measured packages matched the pre-P2 port within a few per cent on statics and on grid-culled views (Loop mean 495,502 vs 496,198).
- **Buildings:**
  - P2's buildings add 2–9 % with `default` (building triangles: Loop +2.5 %, Edgewater +2.0 %, Lincoln Park +9.3 %).
  - `chicago-dense-north` adds +26 % (Lincoln Park), +19 % (Edgewater) and +28 % (Lakeview) static against `default` in the same cell: more storeys and window rows, roof assemblies, porches, rear porches, bays.
- **Yards and trees** (`fd1680f`):
  - Trees: the generator now places parkway and yard trees: 841–1,971 per cell against 5–425 mapped before. They add **23–61 k triangles to the average street view**, against the 100 k the pre-P2 audit estimated for Sloan's Lake density.
  - Yard ground: lawns, walks, driveways and beds add 16–25 k static triangles per residential cell.
  - Bushes: more shrubs and hedges roughly double the bush triangles in view in the residential cells, to 15–21 k with the whole cell at full detail.
- **Culling the two chunk entities by their mesh bounds** (what the engine does) adds 3–8 % to the means and up to 26 % to the worst views (Loop).
  - Generated curb and sidewalk-edge runs belong to the chunk where they start, so a flat-ground entity's bounds can reach about 70 m into the next chunk (Lakeview).
- **Tree prototypes are heavier than the pre-P2 audit assumed:**
  - broad and oval 571 / 238 / 81 triangles near / mid / far, spreading 663 / 235 / 84;
  - pre-P2: 422 / 194 / 32 and 524 / 200 / 32.
  - The tuft prototypes have 18 and 24 triangles, but the engine's estimate still counts 17 per tuft.
- **Lod1 buildings are unchanged** (Loop 22.5 k, as before), as P2 intended: far LOD ≈ the old simple detail. Lod1 totals rose only through the yard ground.

**Against the ceilings** (v2 §8.1: 400 k main ceiling, about 290 k plan target, 150 k shadow ceiling):

| | Whole cell at full detail (no focus) | WorldLab-sized focus |
|---|---|---|
| **400 k ceiling** | **Not met.** Loop mean 525 k and Lakeview mean 409 k (`chicago-dense-north`). The p90 is above 400 k in every cell (River North 425 k to Loop 1.05 M), and so is every worst view (550 k to 1.83 M). | **Met on average and at p90 except in the Loop** (p90 688 k) **and Lakeview** (p90 482 k). The worst views break it in every `chicago-dense-north` cell: Lakeview 605 k, Lincoln Park 469 k, Edgewater 464 k. Loop: 1.08 M. With `default`: 395–398 k, at the line; River North 337 k. |
| **~290 k target (mean)** | Met only in River North (193 k); Edgewater `default` sits at the line (294 k). With `chicago-dense-north`: Lincoln Park 373 k, Edgewater 340 k, Lakeview 409 k. | Met on average everywhere: Loop 271 k, Lakeview 212 k, the others 96–169 k. At p90 Lincoln Park `default` is at the line (290 k); the others are above it (317–688 k), except River North (263 k). |
| **150 k shadow ceiling** | **Not met in the Loop:** one chunk's raised geometry alone is 181 k, and an 80 m view wedge reaches 333 k at worst. Edgewater comes close: 133 k static casters at worst plus about 9 k of trees. Elsewhere 65–100 k plus 6–15 k of trees. | Same Loop chunk (181 k). Elsewhere at most 71 k plus trees. |

**Distance LOD what-if** (not current behaviour; full-detail chunk within 150 m of the camera, lod1 beyond; props as now; measured lod0 and lod1, whole cell):

| Cell | View mean / p90 / max |
|---|---|
| Loop | 277,398 / 473,225 / 654,027 |
| River North | 119,313 / 226,985 / 332,168 |
| Lincoln Park | `chicago-dense-north` 237,005 / 352,066 / 462,515; `default` 205,130 / 314,004 / 391,639 |
| Edgewater | `chicago-dense-north` 212,086 / 326,697 / 428,166; `default` 186,917 / 287,938 / 396,182 |
| Lakeview | `chicago-dense-north` 265,133 / 393,033 / 513,718; `default` 227,590 / 347,331 / 444,372 |

- Chunk-level distance LOD alone no longer brings the dense-north cells inside 400 k in their worst views (428–514 k): the trees and the near chunk's houses remain.
- P2's per-building LOD by distance is finer: near / mid / far / skyline, which the renderer doesn't switch yet (gate-5b gap 3). In P2's street cameras it brings dense Lakeview views to 46–54 k building triangles (`BuildingViewBudgetTests`, before yards).
- That LOD plus a cheaper mid and far tree (or fewer near-LOD trees) is the route to the budget. Window grids on Loop towers still need a facade LOD.

**Still true from the pre-P2 analysis:**
- Curbs are 12 triangles per street metre: 122–174 k per dense cell, 8–18 % of whole-cell statics.
- With no focus every chunk is full detail.
- The package can't separate window frames from walls. The pre-P2 port put the Loop's window frames at 97 % of its building triangles, and the measured building total agrees with that port within 2.5 %.

## Pre-P2 baseline: triangle estimate (generator `772ff24`)

**This is the pre-P2 baseline.** The model ports the generator at `772ff24` (phase 5A tree meshes included). P2 (`91ed01c`) later changed building geometry (roof assemblies, details, per-LOD output) and tree props; the measured counts above supersede these numbers.

**This was an estimate. Nothing was built or run.** The Mac was reserved for another session, so the estimate comes from a model.

### Method and check

`Tools/regionkit/audit/trimodel.py` ports the generator's triangle counting to Python: the same pieces with the same counts.
- `StableRandom` is ported bit-exactly, so per-building choices (type, roof, porch, chimney, window size) match for the same OSM IDs.
- `FootprintAnalysis` (oriented rectangle, L/T decomposition) is ported exactly.
- Walls, roofs, openings, porches, steps, chimneys and the contact skirt follow `BuildingGenerator.swift` and `Shapes.swift`.
- Ground covers chunk-clipped ribbons, earcut caps, curbs and generated sidewalks resampled as in `Streetscape.swift`, and lamp placement.
- Props follow `Props.swift` at the current HEAD, which includes phase 5A's crown branches.

Checked against the recorded Sloan's Lake numbers (front-range profile):

| Quantity | Model | Recorded | Error |
|---|---:|---:|---:|
| Package lod0 static triangles (`docs/package-format.md`; WorldLab focus as of commit b76580c) | 258,930 | 258,769 | +0.06% |
| Package lod1 static triangles | 100,372 | 100,197 | +0.17% |
| M2 matched-run header (`docs/perf/m2-matched/*summary.json`): static + boundary + lamps + benches, before tree LODs | 279,080 | 278,817 | +0.09% |
| Phase 5A gate-run header with the current, wider WorldLab focus (`docs/perf/m3-phase5a-gate/realitykit-20261005-231905-summary.json` and `-232127`) | 402,930 | 401,965 | +0.24% |
| Lamps (generated + mapped) | 158 | 157 (278,817 − 258,769 − 2 − 56 × 72 = 157 × 102) | |
| Street view along the walk loop, 13 cameras, pre-5A tree meshes (`docs/m2/report.md`) | median 181 k, range 69–232 k | "169–276 k" | close; the model's camera sits on the route, not behind the character |
| Same, phase 5A tree meshes | median 205 k, range 78–273 k | none recorded | |

Known approximations:
- The front edge is guessed from the footprint (no street lookup).
- Ribbon bevel joins are skipped.

### Unit costs (from the code)

| Piece | Triangles |
|---|---:|
| Window (glass + 4 frame pieces + muntin, 6 quads) | 12 |
| Wall edge (foundation band + 2 AO bands, pitched roof, full detail) | 6 per footprint edge |
| Gabled / hipped / slab roof per roof rectangle | 30 / 20–22 / 12 |
| Flat roof | earcut cap (vertices − 2) + 2 per edge of parapet |
| Covered porch / stoop with canopy (+ steps, 10 per step) | 42 / 22 |
| Curb (Streetscape resamples every 1 m; 3 faces) | 6 per metre per side → **12 per metre of street** |
| Generated sidewalk + its edges (2 m samples) | 1 + 4 per metre per side |
| Deciduous tree near / mid / far (45 m, 160 m), phase 5A | broad and oval 422 / 194 / 32; spreading 524 / 200 / 32 |
| … before phase 5A (per-tree delta) | 334 / 170 / 14 and 434 / 186 / 14 (+88 / +24 / +18 and +90 / +14 / +18) |
| Conifer near / mid / far (unchanged) | 66 / 42 / 14 |
| Bush near / mid / far | 80 / 20 / 8 |
| Lamp / bench / grass tuft | 102 / 72 / 17 |

Phase 5A adds one limb per crown lobe at every LOD (5 sides at lod 0, 3 otherwise; only the first 3 lobes at lod 2), plus two 3-sided twigs per limb at lod 0.

Averages per building in Lincoln Park at full detail: house 302 (windows 172), block 715, garage 83. In the Loop a block averages **5,432, of which 5,285 is windows** (12.3 floors on average). Simple detail averages 41–57 per building in the four dense cells (lod1 building triangles ÷ OSM buildings).

### Results (pre-P2 settings: bundled `default` profile; Chicago had no region in `regions.json` then)

World = the 1 km² cell (25 chunks of 200 m), with real OSM buildings, roads, areas, trees, lamps and benches for each cell. Two focus settings:
- **whole cell**: the default when an app passes no focus, so every chunk gets full detail;
- **WorldLab-sized**: a 470 × 600 m focus centred in the cell, which selects the central 3 × 3 chunks (0.36 km²).

Street view: 25 camera positions (chunk centres) × 8 headings, portrait 9:19.5, 50° vertical field of view. Culling is per chunk and per instanced-prop entity, as in `World.estimateViewTriangles`, plus up to 200 tufts.

| Cell | Focus | Static triangles | … buildings / of which windows / curbs | Street view: mean / p90 / max | Camera at cell centre: mean |
|---|---|---:|---|---|---:|
| Loop | whole cell | 2,188,944 | 1,986,239 / 1,926,708 / 173,490 | **496,198** / 973,985 / 1,439,850 | 519,224 |
| Loop | WorldLab-sized | 1,001,220 | 930,217 / 893,592 / 49,980 | 247,915 / 627,992 / 801,847 | 278,411 |
| River North | whole cell | 667,908 | 525,965 / 476,652 / 122,292 | 173,499 / 363,811 / 481,699 | 205,693 |
| River North | WorldLab-sized | 271,318 | 227,033 / 199,920 / 32,994 | 76,902 / 217,442 / 259,567 | 110,610 |
| Lincoln Park | whole cell | 932,888 | 779,777 / 478,248 / 141,180 | 244,803 / 430,282 / 600,282 | 244,346 |
| Lincoln Park | WorldLab-sized | 338,742 | 298,185 / 138,252 / 33,900 | 90,128 / 185,104 / 255,015 | 96,456 |
| Edgewater | whole cell | 981,255 | 822,668 / 610,320 / 131,892 | 247,994 / 450,828 / 641,205 | 262,908 |
| Edgewater | WorldLab-sized | 348,631 | 294,196 / 166,416 / 39,852 | 93,616 / 214,865 / 274,575 | 113,752 |

**North Shore, for comparison:** with Overture's footprints added (as `building=yes` with Overture's height), the cells come to 0.15–0.26 M building triangles at full detail: Wilmette 256,945, Evanston 226,660, Kenilworth 193,473, Winnetka 154,694. That is a suburban load, well below the Chicago cells.

**Zone profiles:** with the proposed `chicago-downtown` and `chicago-dense-north` (more floors for untagged buildings), whole-cell static triangles rise by 1.3% (Loop), 12.2% (River North), 14.6% (Lincoln Park) and 7.2% (Edgewater). Street-view means become 503 k, 191 k, 273 k and 263 k.

**Range (estimate):** a typical street view in a dense Chicago cell at current settings submits **0.17–0.50 M triangles** with full detail everywhere, or 0.08–0.25 M with a WorldLab-sized focus. The worst views reach **0.48–1.44 M with full detail everywhere (0.26–0.80 M WorldLab-sized)**.
- **400 k ceiling, whole cell at full detail:** the Loop is above it on average. The p90 is above it in Lincoln Park (430 k), Edgewater (451 k) and the Loop (974 k), and River North's worst view is 482 k.
- **400 k ceiling, WorldLab-sized focus:** only the Loop breaks it (p90 628 k).
- **~290 k plan target:** met on average everywhere except the Loop at full detail, but not in the worst views.

**Shadows (rough):** with RealityKit's 80 m shadow distance and per-chunk casters, a view's shadow casters average 27–88 k with the whole cell at full detail. One Loop chunk alone holds **185 k triangles, more than the 150 k shadow ceiling**.

**Draw calls:** not modelled. Sloan's Lake recorded 108 for its 48 chunks (`docs/perf/m2-matched/*summary.json`, `drawCalls=108`; 109 in the phase 5A gate runs); a 1 km² cell has 25 chunks.

Assumptions that move the numbers:
- The world is exactly the 1 km² cell. A larger area adds roughly one more chunk per 200 m of view depth.
- Trees are the few mapped in Chicago (56–425 per cell). With phase 5A meshes the Loop's 425 trees already average 5.4 k triangles per view. Generated street trees at Sloan's Lake density would add about 100 k per view.
- Culling is per chunk or entity, not per triangle, which matches what RealityKit is asked to draw.
- Levels come from OSM, else the type default. Floors from height would raise the downtown numbers sharply (gap 3).

### Where LOD or simplification is needed

1. **Window grids on tall blocks.** They are 1.93 M of the Loop's 1.99 M building triangles.
   - A what-if with per-camera chunk LOD (full detail for chunks within 150 m, the existing lod1 beyond) leaves the Loop at a 263–266 k mean and **604–609 k worst**, because one 200 m chunk of towers is already 185 k. These ranges span the current and the proposed zone profiles.
   - The same what-if brings Lincoln Park and Edgewater to a 150–168 k mean and 282–313 k worst, and River North to 103–111 k and 263–283 k, all inside the ceiling.
   - Window geometry therefore needs a per-building distance limit (v2 §8.1: no window frames beyond 150 m) and a cheaper mid form. Glass-only quads are 2 instead of 12 triangles: about 1.6 M fewer in the Loop, by arithmetic.
   - Window rows above about the 5th floor are better as a facade pattern or strips.
2. **Curbs:** 12 triangles per street metre, because curbs are resampled every metre. That is 122–174 k per dense cell, 8–18% of static with the whole cell at full detail (Loop 7.9%, Edgewater 13.4%, Lincoln Park 15.1%, River North 18.3%). Straight runs need only one segment; resample only at bends and road ends.
3. **Default focus = whole area.** With no focus, every chunk is full detail. A dense world needs distance-based chunk detail. Lod1 already exists in the package; in the Loop, lod1 buildings are about 1% of lod0 buildings (22,473 vs 1,986,239).
4. **`building:part` towers** (when implemented) multiply the window problem; same facade LOD.
5. **Shadow casters:** use the simple (lod1) chunk mesh as the shadow caster, or smaller shadow chunks, so one Loop chunk can't exceed the shadow ceiling.

### How it was measured later

Steps 1–3 of the plan written here (`worldbake init-area`, `fetch`, `export` with and without a focus) are now
`Tools/regionkit/audit/pkgtris.py run`; the results are the [measured section above](#measured-after-p2-generator-b8f6c71).
Step 4, on device (WorldLab's per-frame view count and `scripts/walk_test.sh` frame times for these areas), is
still to do. Area folders and packages stay outside `Data/`.

## Datasets, dates and licences

| Dataset | Version / date | Licence |
|---|---|---|
| OpenStreetMap via Overpass (`out geom`, `out count`, `out center`; never `out meta`) | `osm3s.timestamp_osm_base`, one fetch per cell (per-cell values in `osm_metrics.json`): <br>• buildings 2026-10-06T05:48:50Z to 07:05:15Z (Seattle was re-fetched last after server timeouts); <br>• dense-cell ground layers 07:06:20Z to 07:23:36Z; <br>• anchors 05:49:52Z to 05:57:06Z (`cells.json`). <br>Responses older than 3 days are now rejected: an earlier anchor lookup had been served from a May 2026 mirror database. Sloan's Lake calibration uses the repo's 2026-10-05T17:39:35Z extract. | © OpenStreetMap contributors, [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/); [copyright and attribution](https://www.openstreetmap.org/copyright) |
| Overture Maps, buildings theme, `building` type | Release **2026-09-23.1**, the latest in the [STAC catalog](https://stac.overturemaps.org/catalog.json) on 2026-10-06. Its OSM records carry `sources.version` 2026-09-06 (28,384 of 28,385 OSM records in these cells; `summary.json`). | [ODbL](https://opendatacommons.org/licenses/odbl/) for the theme (STAC collection `license: ODbL-1.0`; [Overture attribution page](https://docs.overturemaps.org/attribution/)). The page lists the contributing sources: OpenStreetMap (ODbL), Microsoft Global ML Building Footprints (ODbL), Esri Community Maps (CC BY 4.0), Google Open Buildings (CC BY 4.0), USGS 3D Elevation Program, and two non-US datasets. Attribution to OpenStreetMap contributors is required. Details: [licensing.md](licensing.md) (V1, O12). |

No raw data is committed: results hold per-cell aggregates only.

## Method and how to re-run

```
uv run --with duckdb==1.5.6 python3 Tools/regionkit/audit/audit.py all \
  --dense loop-daley-plaza river-north-montgomery-ward-park lincoln-park-oz-park edgewater-broadway-armory-park
```

Add `--zone-profiles <folder with region-catalog.json and profiles/>` to include the zone-profile comparison. Details are in `Tools/regionkit/audit/README.md`.

- **Cells:** one batched Overpass query per metro finds each anchor by exact name and tags (`out center`). The centre is rounded to 4 decimals. Data are selected with a ±500 m lat/lon box (same formula as `Tools/regionkit`) and counted in the exact ±500 m local rectangle.
  - Five anchors needed a second, documented lookup because OSM names them differently: "Sugar Land Town Hall", "Gilbert Civic Center", "Sammamish Commons", "Richardson City Hall / Civic Center", and the old courthouse for Decatur Square.
- **OSM:** per cell, ways and relations with `building` or `building:part` (`out geom`, which carries relation member geometry), plus `natural=tree` nodes and `tree_row` ways (`out count`).
  - Footprints are cleaned as the engine does: merge < 1 cm, drop collinear points, minimum area 1 m².
  - A relation whose rings don't close is skipped, as in the engine (none here).
  - Tag values are parsed with ports of `TagParsing.length` / `number`.
- **Overture:** files are chosen from the release's STAC collection (per-file bounding boxes). DuckDB then runs `read_parquet` over HTTPS with a `bbox` filter, so only intersecting row groups are read: about 2–4 MB per cell, all cells in one session. Centroids come from the WKB outer ring.
- **Etiquette:**
  - One Overpass request at a time, ≥ 5 s apart, with a status check first.
  - 60 s back-off on 429/504, and every response cached by query hash.
  - The primary endpoint (`overpass.private.coffee`) didn't answer its status page, so all cell data came from the fallback `overpass-api.de`.
  - No block was worked around: no User-Agent changes, no other endpoints.

Downloaded:
- **This revision** (`results/downloads.json`):
  - Overpass: 64 requests, 6.4 MB (gzip). That includes two attic `out count` checks, which found the same number of building ways and relations in the Lincoln Park box at both workstreams' fetch times (2,293 + 3).
  - Overpass status checks: 108 (28 kB).
  - Overture: 181.9 MB of Parquet range reads + 32 kB of STAC.
  - Tooling (estimates): the DuckDB wheel (~17 MB) and httpfs extension (16 MB), downloaded again.
- **The first run** (superseded, figures from its ledger):
  - Overpass: 4.4 MB.
  - Overture: 181.9 MB, plus about 9 MB of exploratory reads (estimate).
  - Tooling: the same ~33 MB.

**Measured triangles (phase 5B).** From the repository root, with a built `worldbake`
(`swift build -c release --product worldbake`) and a work folder outside the repository:

```
uv run --no-project --with numpy python3 Tools/regionkit/audit/pkgtris.py run --work <folder>
```

- For each cell without an area folder in `<folder>/areas/`: `worldbake init-area` and `worldbake fetch`, one
  Overpass request per cell, 10 s apart. Lakeview is copied from `Data/areas/`.
- Then the exports in `pkgruns.json` are measured. Each package is deleted after reading (about 70–180 MB each
  while it exists).
- This run: 4 Overpass requests through `worldbake fetch`, 21,251,878 bytes of `osm.json` (Loop 4.1 MB, River North
  2.2 MB, Lincoln Park 3.0 MB, Edgewater 12.0 MB; sizes after decompression, so the transfer may have been smaller).
- About 2 s per export and 2–5 s per measurement.

## Decisions for the owner

1. **Outer-suburb anchors are civic campuses.** The Frisco, Sugar Land and Woodbury cells are mostly commercial or civic and hold 77–96 OSM buildings. I kept them (documented, conservative) rather than re-picking. If you want subdivision fabric instead, swap those three anchors in `cells.json` for neighbourhood parks and re-run.
2. **Overture as a second building source** (gap 1). It needs:
   - a loader for a second source in the area manifest;
   - the credits in `licensing.md` V1: OSM, Overture and per-source, e.g. Esri Community Maps CC BY 4.0;
   - the share-alike decision in O12, if Overture heights are merged onto OSM buildings.

   This is a design decision not covered by the plan, so it is reported here, not built.
3. **Floors from height** (gaps 2–3) should not land before facade LOD (gap 9), or downtown triangle counts multiply (Manhattan 0.80 M → 2.56 M in the model).
4. **Tree density** has no field in the profile format; generated street trees would need one.
5. **Microsoft ML heights** are estimates. Use them, or only USGS lidar heights (covering 54% of fills)? This is a quality choice to confirm.
6. **Engine behaviours** found while matching the engine's counting (see the main table notes): duplicate drawing of a way that is also a multipolygon outer, and assembly of tagged `type=building` relations into extra building polygons. Both fixed by P2 on main in `1085568`; the measured triangle counts include the fix.
