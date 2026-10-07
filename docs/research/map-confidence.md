# Map confidence: validation ground truth

Research notes, 2026-10-06. Purpose: ground truth to calibrate confidence numbers for generated yards (lots),
front doors and driveway ends. Calibration means the share of a validation sample with a given score whose
generated lot overlaps the real one at IoU ≥ 0.6, or whose real door / driveway end lies within 2 m / 3 m of
the generated one.

Test areas (box = manifest centre ± width/2, height/2): `sloans-lake` (Denver, 1.6 × 1.2 km),
`evanston-south` and `lakeview-sheil-park` (Cook County, 1 × 1 km each).

**No parcel data, crops or per-house values are in the repository.** Parcel outlines single out private homes.
They sit in a work directory outside the repo (`/tmp/claude-parcels-work/`) and may only feed aggregate
calibration numbers. OSM counts: © OpenStreetMap contributors (ODbL 1.0).

## Validation sources

### Parcels (lot ground truth)

| | Denver | Cook County (Evanston, Chicago) |
|---|---|---|
| Dataset | "Parcels", City and County of Denver Open Data Catalog (hub item `7c53bd0894134e80ae1e478c0789bf49`) | "Parcels - Historical - 2025" (tax year 2025), Cook County GIS (hub item `4a4a4b47c8804b5e850371b0fdf25244`) |
| Service | `https://services1.arcgis.com/zdB7qR0BtYrg0Xpl/arcgis/rest/services/ODC_PROP_PARCELS_A/FeatureServer/245` | `https://gis.cookcountyil.gov/traditional/rest/services/parcelHistorical/MapServer/2025` |
| Licence | **CC BY 3.0.** Credit "City of Denver Open Data Catalog" (link http://data.denvergov.org) and name the licence. Item licence field adds an as-is disclaimer, an indemnity clause and "NOT FOR ENGINEERING PURPOSES". | **No explicit open licence.** The item's licence field is an as-is disclaimer only. The portal's terms page (https://www.cookcountyil.gov/terms-use) disclaims warranty and says site content is copyrighted, so permission should be presumed needed to reproduce it. On the Socrata catalogue (datacatalog.cookcountyil.gov) the 2016-and-older parcel sets are tagged Public Domain; Parcel 2021 says "See Terms of Use". |
| Terms URL | https://opendata-geospatialdenver.hub.arcgis.com/pages/terms-of-use (text read from the hub site's configuration, site item `08ac95d2733c45059ec5a3c76faa770d`) | https://www.cookcountyil.gov/terms-use ; item: https://hub-cookcountyil.opendata.arcgis.com (item above) |
| Status | Service verified; licence verified | Service verified; licence **unverified**: there is no stated grant for 2025 parcels. Internal, aggregate-only calibration looks low-risk; publishing derived geometry would need a question to Cook County GIS |
| Fields fetched | `OBJECTID` and geometry only. The layer also carries owner names, owner addresses, situs addresses, values and sales; none were requested. | `OBJECTID` and geometry only. The layer also carries PINs, tax code, assessor building class and neighbourhood, centroid lat/lon and districts; none were requested. |

Fetch method: ArcGIS REST `query`, envelope in EPSG:4326, `spatialRel=esriSpatialRelIntersects`,
`outFields=OBJECTID`, `outSR=4326`. First an ids-only request, then geometry by `objectIds` in POST batches
of 500 as GeoJSON. Parcels that cross the box edge are included whole. Script:
`/tmp/claude-parcels-work/fetch_parcels.py`.

| Area | Parcels | Distinct shapes | Downloaded | File | < 100 m² | **100–2,000 m²** | > 2,000 m² | Median |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| sloans-lake | 876 | 873 | 407 KB | 413 KB | 20 | **842** | 11 | 566 m² |
| evanston-south | 1,105 | 1,105 | 400 KB | 390 KB | 25 | **1,058** | 22 | 571 m² |
| lakeview-sheil-park | 1,979 | 1,958 | 738 KB | 720 KB | 101 | **1,836** | 21 | 294 m² |

Size bins are over distinct shapes (stacked duplicates removed), with areas from a local equirectangular
projection. Lakeview's 101 parcels under 100 m² are probably condo or sliver parcels; check before using them.
The Denver service reports 240,435 parcels citywide; the Cook 2025 layer has 1,432,483.

### Front doors and driveways in OSM (committed `osm.json`)

| Area | Buildings | with `addr:street` | with `addr:housenumber` | `entrance=*` nodes (on building ways) | Driveways | touching a building | end ≤ 3 m from one | end 3–5 m | no building ≤ 5 m |
|---|---:|---:|---:|---|---:|---:|---:|---:|---:|
| sloans-lake | 1,427 | 845 | 845 | none | 12 | 0 | 0 | 1 | 11 |
| evanston-south | 900 | 590 | 590 | yes: 2 (2) | 10 | 0 | 0 | 2 | 8 |
| lakeview-sheil-park | 2,868 | 1,680 | 1,680 | exit: 2 (0) | 17 | 3 | 2 | 7 | 5 |

Driveways = `highway=service` + `service=driveway`. "Touching" = sharing a node with a building way. The
other columns measure from either driveway end to the nearest building outline (garages count as
buildings). No address values were read out, only counted.

Conclusion: OSM gives **no usable door ground truth** (2 entrance nodes in 5,195 buildings) and **almost no
driveway-end ground truth** (39 driveways, 5 touching or within 3 m of a building). Addresses on 59–66 % of
buildings say which street a house faces, a weak side-of-building check, not a position. Alleys (26, 47, 57
`service=alley` ways) matter more for rear garages than mapped driveways do.

### Aerial check (NAIP 2023, 0.3 m)

Source: USDA NAIP through Microsoft Planetary Computer (STAC collection `naip`, anonymous SAS token, public
domain; credit "NAIP imagery provided by USDA Farm Service Agency"). Same access as
`Tools/regionkit/aerial/aerial.py` `fetch_naip`. Status: verified (used in [aerial.md](aerial.md)).

Helper: `/tmp/claude-parcels-work/crop.py --lat … --lon … [--cog URL | --state il] [--size 40] --out x.png`.
It reads a 40 × 40 m window (133 × 133 px) of a COG through GDAL `/vsicurl/` (byte ranges only), signing
Planetary Computer blob URLs with the anonymous token, and writes the RGB crop plus a 4× copy. Without
`--cog` it picks the newest NAIP item at the point through STAC. It runs under `uv run --with rasterio
--with numpy --with pillow` as in the aerial README.

Tested once per area on a residential street intersection near the centre:

| Area | Item | Date |
|---|---|---|
| sloans-lake | `co_m_3910524_ne_13_030_20230925_20240104` | 2023-09-25 |
| evanston-south | `il_m_4208759_sw_16_030_20230710_20240209` | 2023-07-10 |
| lakeview-sheil-park | `il_m_4108703_ne_16_030_20230710_20240209` | 2023-07-10 |

Judgement from the three crops:
- **Driveways (about 3 m = 10 px) are clearly discernible** where they are not under canopy. Sidewalks
  (about 1.5 m = 5 px), curb ramps, crosswalks and parkway strips are sharp.
- **Front walks (1–1.2 m = 3–4 px) are discernible** as light concrete strips across lawns when unoccluded.
  Where a walk meets the facade is a usable door proxy.
- **Doors themselves are not visible** (vertical faces, eaves, porches). Expect 1–2 m error from the walk
  proxy alone, plus image-to-footprint offset; aerial.py's global shift estimate handles the offset.
- **Occlusion is the limit.** Canopy covers much of Evanston (47 % residential canopy) and parts of Lakeview
  (18 %). Leaf-on July imagery hides many walks and driveway ends there; Denver (September, 25 %) is clearer.
  Plan on "unreadable" labels and report them.
- Feasible as hand-labelled validation (a few hundred crops per area, at 30–40 KB per crop).

## Calibration results (2026-10-07)

Tool: `Tools/regionkit/mapconf/` (`mapconf.py` outcomes and blind labelling sheets, `fit.py` tables). Aggregate
table: `Tools/regionkit/mapconf/results/calibration.json`. Code: `Sources/WorldPackage/MapLayer/MapCalibration.swift`
(the bin rules there and in `fit.py` must stay identical). Per-record outcomes, parcels, crops and labels stay in
`/tmp/claude-mapconf-work` and `/tmp/claude-parcels-work`, outside the repository.

A confidence is the pooled share of the validation sample in the record's bin whose value was right, over Sloan's
Lake, Evanston South and Lakeview (the three exported areas). "Leave-one-area-out gap" is the largest difference
between a bin's share in one area and its share from the other two: how far the number can move in an unseen area.

### Frontage (2,881 buildings with `addr:street`; right = the segment's name is the addressed street)

| Bin | n | Share | Gap |
|---|---:|---:|---:|
| not a corner, door < 12 m from the street | 160 | 0.950 | 0.39 |
| not a corner, 12–20 m | 1,372 | 0.991 | 0.02 |
| not a corner, ≥ 20 m | 218 | 0.812 | 0.18 |
| corner (another named street within 40 m), other street < 20 m | 37 | 0.189 | 0.11 |
| corner, other street 20–30 m | 581 | 0.475 | 0.19 |
| corner, other street 30–40 m | 513 | 0.864 | 0.02 |

Overall 0.838. Corner houses are the weak case: the generator faces the nearest named street, the address is often on
the other one.

(Numbers after P2's review fixes to the lot split: dropped pieces counted as cells outside the outline; beds not
subtracted twice on front-garden lots.)

### Lots (5,538 lots; right = IoU ≥ 0.6 with the parcel minus the footprint, split at the same front line)

| Bin | n | Share | Gap |
|---|---:|---:|---:|
| front, dropped pieces > 5 % | 197 | 0.264 | 0.24 |
| front < 40 m² | 734 | 0.388 | 0.30 |
| front ≥ 250 m² | 164 | 0.409 | 0.07 |
| front 40–250 m², door < 12 m from the street (or no frontage) | 115 | 0.139 | 0.02 |
| front 40–250 m², 12–16 m | 787 | 0.647 | 0.23 |
| front 40–250 m², 16–20 m | 510 | **0.749** | 0.11 |
| front 40–250 m², 20–30 m | 117 | **0.701** | 0.14 |
| front 40–250 m², ≥ 30 m | 49 | 0.041 | 0.07 |
| back, dropped pieces > 5 % | 990 | 0.067 | 0.02 |
| back < 150 m² | 364 | 0.047 | 0.05 |
| back 150–250 m² | 469 | 0.192 | 0.11 |
| back 250–600 m² | 780 | 0.263 | 0.19 |
| back ≥ 600 m² | 262 | 0.164 | 0.04 |

Overall 0.328 (front 0.522, back 0.147); median IoU 0.49. Only the two bold bins (627 front lots across the three
areas) reach NJ's 0.7 floor, and the 20–30 m bin can fall below it in an unseen area. Back yards never do: the
inferred yard stops at the zone's maximum lot depth and at other buildings, while the parcel runs to the alley.
Reported to P2 (yard generator owner) as the main accuracy finding.

### Entry points (blind labels on NAIP 2023 0.3 m crops)

| Kind | Sampled | Labelled (discernible) | Right | Share | Gap |
|---|---:|---:|---:|---:|---:|
| front door (same wall, within 2.0 m along it) | 210 | 58 | 21 | 0.362 | 0.45 |
| driveway end (within 3.0 m) | 120 | 101 | 87 | 0.861 | 0.28 |

- The door's position along its wall is a seeded draw from the regional house type (provenance: simulated), so a low
  share is expected; the wall itself was right in 51 of the 58 (7 labelled on another side).
- Most sampled garages open straight onto alleys, so most driveway mouths are within a few metres of the garage door.
- Labels are an agent's reading of 0.3 m leaf-on imagery (about ±1 m; the footprint outline is often offset 1–4 m
  from the roof), and only discernible cases are scored. A first pass read Sloan's Lake crops from one NAIP tile, so
  47 sheets outside it were black; they were regenerated from the right tiles and relabelled blind.

### Slope

From the grid's own validation (`Data/areas/*/terrain-slope.json` `validation`): per lot, the share of validation
cells whose slope agrees within 2 percentage points for the lot's slope class (< 15 % or ≥ 15 %), the lower of the
USGS 1 m DEM comparison and the split-sample test; the grid's `confidence` and the method's `defaultConfidence` use
all validated cells. Sloan's Lake: < 15 % 0.946, ≥ 15 % 0.53 (DEM) / 0.66 (split); Evanston: 0.995 / 0.89;
Lakeview: 0.993 / 0.71. Both references come from the same lidar: this is gridding and noise error, not ground truth.

### What it means for NJ

With the 0.7 floor: frontage passes for non-corner houses and wide corners; lots pass only for front yards of
40–250 m² set 16–30 m back; front doors never pass (0.36), so Paper and Pizza customers (who need a confident door)
are excluded until doors improve; driveway ends pass (0.86).
