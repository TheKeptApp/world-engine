# Lidar roof forms: USGS 3DEP pilot in South Evanston

Phase 5B measurement, 2026-10-06. The question: can public lidar tell the generator each roof's form (flat,
gable, hip or complex, plus pitch and ridge direction), and how well do the roof forms the generator assigns
today match it? Area: the committed P2 test area `Data/areas/evanston-south` (1 km², centre 42.0372, −87.6912),
compared with P2's generator at `b8f6c71` (main `680d47b` has the same generator) using the `evanston` profile, as
P2's BuildingLab and BuildingAreaTests do.

Tool: [`Tools/regionkit/lidar/`](../../Tools/regionkit/lidar/README.md) (one command re-runs it). Numbers come
from `Tools/regionkit/lidar/results/comparison.json`, `handcheck.json` and `vintage.json`. Aggregates only: no
building IDs, per-building values, point clouds or images are in the repository, and distributions over fewer
than 5 buildings are reported as counts.

## Summary

1. **Data and licence.** The public Entwine Point Tiles dataset `USGS_LPC_IL_4County_Cook_2017_LAS_2019`
   (EPSG:3857, metres, classified) covers the area. The flight was **16 April – 7 May 2017** (early spring, mostly leaf-off), from
   the delivery's FGDC metadata. The AWS Open Data registry lists the licence as "US Government Public Domain";
   the USGS copyright page itself was blocked (403), so that wording is unverified at the source. The pilot read
   **118 MB**: the octree nodes over the area down to depth 10, about 4 building points per m² of roof.
2. **The lidar classifier is good on simple form and over-calls "complex".** On 30 hand-checked roofs it agrees
   on the simple form (flat / gable / hip) **26 of 30 (86.7 %, 95 % interval 70–95 %)** and on the four classes
   **24 of 30 (80 %, 63–91 %)**. It found every one of the 12 complex roofs but also called 6 of the 18 simple
   ones complex (dormers or a flat porch roof counted as extra planes). Run on P2's own roof meshes, the same
   classifier recovers P2's assigned form for **98.6 %** of buildings, so the geometry path is sound.
3. **P2's per-building roof form agrees with lidar at chance level.** Simple-form agreement is **47.9 %**
   (381 of 796; interval 44.4–51.3 %; kappa 0.05). Matching the marginals by chance gives 45.1 %, and calling
   every roof a gable would score 55.4 %. That is expected: P2 draws each house's family and roof from the
   profile's weights, independently of the real house.
4. **Real roofs are more complex and flatter-pitched than P2 draws them.**
   - Complex roofs: P2 draws 17 % of houses with more than a simple gable or hip (wings, cross-gables). The
     hand-checked houses are complex 10 of 22 (45 %), and lidar calls 64 % complex (about 45 % after its
     over-call rate is taken out).
   - Houses, simple form: lidar **gable 55 %, hip 32 %, flat 12 %**; P2 assigns gable 67 %, hip 24 %, flat 9 %.
   - Garages: lidar **gable 59 %, hip 34 %, flat 7 %**; P2 assigns gable 70 %, hip 7 %, flat 22 %.
   - Pitch: house gables have a median **35°** (interquartile 28–42°) in lidar against 43° in P2's meshes; garage
     gables 26.5° against 20°.
   - Ridge direction is mostly right where both see a gable: within 20° for 79 % (n = 308).
5. **The 2017 lidar and 2026 OSM mostly agree, but OSM misses structures.** 38 footprints have no lidar roof
   (22 of them on a non-vegetated surface in NAIP 2023, so probably built after the flight). Lidar sees 420
   building-class structures of at least 30 m² with no OSM footprint within 1.5 m (median 108 m², 7.8 ha in
   all); 305 of them are still non-vegetated in 2023. Most look like unmapped garages and houses; this is not
   checked per building.
6. **Recommendation.** Feed lidar to the generator **at profile level now**: roof-form mix by role, complex
   share and pitch per zone. Per-building hints would raise per-building correctness from about 48 % to about
   87 % (simple form). They need the O12 decision first (per-building values keyed by OSM ID), and the
   complex over-call should be fixed and re-checked before any per-building use. Scaling to the Cook County
   North Shore is about 6–7 GB of lidar reads and minutes of compute; Lake County needs other projects (not
   checked). Details in [section 8](#8-recommendation).

## 1. Data, licence and access

| | Value |
|---|---|
| Dataset | EPT `s3://usgs-lidar-public/USGS_LPC_IL_4County_Cook_2017_LAS_2019/` (Hobu, Inc., AWS Open Data; not requester-pays) |
| USGS project | `IL_4_County_QL1_LiDAR_2016_B16`, delivery `IL_4County_Cook_2017` (TNM Access API, product for the area centre) |
| Acquisition | 2017-04-16 to 2017-05-07 (FGDC metadata `begdate`/`enddate` of tile LAS_15759550): early spring, mostly leaf-off. This settles the 2016/2017 question left open in [aerial.md §7](aerial.md#7-better-sources-for-roof-type) |
| `ept.json` | SRS EPSG:3857 (Web Mercator, horizontal), Z in metres (ground at the area 178.6–194.8 m, 1st–99th percentile); 93.7 billion points; data bounds 41.43–42.16° N, −88.27 to −87.48° E, so all of Cook County's North Shore (Evanston to Glencoe) is inside |
| Classes present | 1 unclassified, 2 ground, 3/4/5 low/medium/high vegetation, 6 building, 7 noise, 9 water, 10, 17 |
| Returns | Every point carries return 1 of 1 in this EPT, so first/last-return selection is not possible. The building class (6) is used instead, which also leaves out vegetation overhanging roofs |
| Read | The 280 octree nodes (depth 0–10) that meet the area box plus 15 m: 18.7 M points read, 16.0 M in the box; 117,612,558 bytes of LAZ, 189,042 bytes of hierarchy |
| Density | Building points inside footprints: median 4.1 per m² (p10 2.8, p90 5.1). Depth 11 (full resolution) would add about 27.7 M points (≈ 185 MB) |

**Licence.**
- AWS Open Data registry entry `usgs-lidar` (fetched from its GitHub source): "License: US Government Public
  Domain", linking to a USGS FAQ page.
- FGDC metadata of the delivery tile, `useconst`: "Acknowledgement of the originating agencies would be
  appreciated in products derived from these data." The same field says that a user who modifies the data must
  describe the modifications, and must not imply USGS approval.
- **Unverified:** the USGS copyright page `https://www.usgs.gov/information-policies-and-instructions/copyrights-and-credits`
  answered 403 (CloudFront "Request blocked"). Per the web rule it was not retried another way, and the FAQ page
  the registry links to (same host) was not fetched.
- See [licensing.md](licensing.md) row N2.

## 2. Footprints and coverage

Footprints are the committed area's OSM buildings (closed `building` ways and building multipolygons, as the
engine's `MapFeatureBuilder` builds them), counted when their centroid lies in the area: **887**, the same 887
buildings P2's export generates.

| Status | Buildings |
|---|---:|
| Classified (house 650, garage 134, block 13, by P2's role) | **797** |
| Footprint under 15 m² or nothing left after erosion | 15 |
| No lidar roof (fewer than 10 % of eroded cells within 1 m of a building point) | 38 |
| Roof only partly seen (significant planes cover less than half the eroded footprint) | 37 |

## 3. Method

Thresholds are data (`Tools/regionkit/lidar/data/params.json`), set before the hand check and before any
comparison with the generator.

1. **Alignment.** One shift for all lidar points maximises the overlap of building-class cells with the OSM
   footprints (±3 m, 0.5 m steps): **1.0 m west, 1.0 m north** (intersection-over-union 0.450 → 0.494). The
   remaining misfit is per building, as in the aerial study.
2. **Points.** Building class (6) at least 2 m above a 5 m ground grid (median of class 2), inside the footprint
   eroded by 0.75 m.
3. **Planes.** Normals from 12 nearest neighbours. Region growing seeds on the flattest points; a neighbour within
   1 m joins when its normal is within 12° and it lies within 0.2 m of the region plane; regions under 12 points
   are dropped. Each 0.5 m cell of the eroded footprint takes the plane of the nearest plane point within 1 m.
   Planes are the 4-connected parts of that raster.
4. **Classifier** (`roofplanes.classify_roof`, the same code for lidar and for P2's meshes):
   - **Significant planes:** at least 4 m² and at least 6 % of the roof. If they cover under half the eroded
     footprint, the roof is unknown.
   - **Flat:** planes under 10° pitch hold at least 85 % of the roof.
   - **Side shares:** for each side of the footprint's minimum-area rectangle, the share of roof cells within 2 m
     of that side that belong to a sloped plane facing out over it (aspect within 45°). A side counts when its
     share is at least 0.35.
   - **Simple form:**
     - flat if flat planes hold at least half the roof;
     - hip if all four sides count, or three including an opposite pair;
     - gable if only one opposite pair counts;
     - otherwise the dominant pair decides.
   - **Ridge:** along the rectangle axis whose sides are less covered.
   - **Complex:** any of
     - 15–85 % of the roof flat (mixed flat and sloped);
     - more sloped planes than the form needs (gable 2, hip 4);
     - a sloped plane more than 20° off the rectangle's axes;
     - no opposite pair.
   - **Form:** "complex" if complex, otherwise the simple form.
   - **Pitch:** area-weighted mean of the significant sloped planes.
5. **The generator's side.**
   - `worldbake export` of a copy of the area, whole area at full detail (`--profile evanston`).
   - Per building from `scene.json`: role and `roofShape`, mapped as gabled → gable, hipped → hip, flat and
     slab → flat. `roofShapeFrom` is "profile" for every building: the area has no `roof:shape` tag.
   - The package does not export P2's roof-assembly fields (`roofMasses`, `crossGable`, `dormers` exist on
     `GeneratedBuilding` but not in `scene.json`). P2's complex flag therefore comes from the meshes:
     - each building's lod0 triangles (by `_FEATURE`) are reduced to their upper envelope on the same 0.5 m
       raster;
     - coplanar triangles (2°, 8 cm) are grouped into planes;
     - the same classifier runs on those planes.
   - P2's "complex" therefore means the same as the lidar's: wings, crossing gables and dormers large enough to
     count.
6. **Hand check.**
   - Sample: 30 buildings from the classified set (stable sha256 sample, seed in `params.json`).
   - Images (scratch only, deleted):
     - a height surface coloured by downhill direction (hue) and slope (saturation), with flat areas grey;
     - vegetation points and the footprint outline;
     - two side views along the footprint's axes.
   - The agent labelled each roof (four classes plus the simple form) before looking at any classifier output.
     The images show the same points the classifier used, so this is a check of the classifier's reading, not
     ground truth.

## 4. Classifier checks

**On P2's meshes** (known geometry; rows: P2 `roofShape`, columns: classifier on the generated triangles; n = 791).
Agreement **98.6 %** (interval 97.5–99.2 %), kappa 0.97. The 11 errors are hipped roofs read as gables. In the
first run (`44eeaa3`, 10 errors) 9 of them sat on multi-wing footprints, where the sides of the footprint's
minimum-area rectangle do not line up with the hip ends.

| P2 \ classifier | flat | gable | hip |
|---|---:|---:|---:|
| flat | 100 | 0 | 0 |
| gable | 0 | 527 | 0 |
| hip | 0 | 11 | 153 |

**Hand check** (n = 30, no can't-tell; rows: hand label, columns: lidar classifier):

| hand \ lidar | flat | gable | hip | complex |
|---|---:|---:|---:|---:|
| flat | 2 | | | |
| gable | | 3 | | 4 |
| hip | | | 7 | 2 |
| complex | | | | 12 |

- Four classes: **24/30 = 80 %** (interval 63–91 %), kappa 0.70.
- Simple form: **26/30 = 86.7 %** (70–95 %), kappa 0.78:
  - flat 4/4;
  - gable 13/14 (one called hip);
  - hip 9/12 (three called gable).
- Complex flag: sensitivity 12/12. False complex: 6 of 18 simple roofs (33 %, interval 16–56 %):
  - four through an extra small plane (a dormer or a step in the ridge);
  - two through a flat part inside the footprint (a porch or addition roof, or footprint misfit).
- Sample by role: 22 houses, 6 garages, 2 blocks. Hand labels: houses complex 10/22, gable 12, hip 8, flat 2
  (simple form); garages hip 4, gable 2, none complex.

## 5. What lidar sees

| Role | n | Four classes (lidar) | Simple form (lidar) | P2 `roofShape` |
|---|---:|---|---|---|
| House | 650 | complex 413, hip 100, flat 70, gable 67 | gable 358 (55 %), hip 211 (32 %), flat 80 (12 %), unknown 1 | gabled 436 (67 %), hipped 157 (24 %), flat 57 (9 %); P2 meshes complex 108 of 644 (17 %) |
| Garage | 134 | gable 55, hip 41, complex 29, flat 9 | gable 79 (59 %), hip 46 (34 %), flat 9 (7 %) | gabled 94 (70 %), flat 30 (22 %), hipped 10 (7 %); none complex |
| Block | 13 | flat 7, complex 4, gable 2 | flat 9, gable 4 | flat 13 |

Lidar's complex share is inflated by the over-call in section 4. A rough correction (sensitivity 1, false-complex
rate 1/3 on simple roofs) gives about **45 %** of houses complex, the same as the hand-checked houses (10 of 22).
For garages the correction lands at about zero; the hand-checked garages had no complex roof.

**Pitch** (significant sloped planes; houses / garages):

| | Lidar median (IQR) | P2 meshes median (IQR) |
|---|---|---|
| House gable | 35.0° (27.8–41.5), n = 358 | 42.5° (36.7–46.9), n = 444 |
| House hip | 30.1° (22.8–37.2), n = 211 | 30.0° (18.4–41.1), n = 143 |
| Garage gable | 26.5° (21.5–32.6), n = 79 | 20.3° (17.1–22.8), n = 94 |
| Garage hip | 19.7° (18.1–25.4), n = 46 | 20.6° (n = 10) |

The `evanston` families' pitch ranges are steep for gables: Tudor 40–52°, Queen Anne 38–50°, Colonial
28–40°. Garages use 15–27° in every profile.

## 6. Agreement with P2's assigned roofs

**Simple form** (rows: lidar, columns: P2 `roofShape`; n = 796):

| lidar \ P2 | flat | gable | hip | recall |
|---|---:|---:|---:|---:|
| flat | 26 | 56 | 16 | 26.5 % |
| gable | 41 | 302 | 98 | 68.5 % |
| hip | 33 | 171 | 53 | 20.6 % |

- Agreement **47.9 %** (44.4–51.3 %), kappa 0.05.
- Baselines: chance agreement from the marginals 45.1 %; always "gable" 55.4 %.
- By role:
  - houses 46.5 % (42.7–50.4 %), kappa 0.01, n = 649;
  - garages 52.2 % (43.8–60.5 %), kappa 0.12;
  - blocks 9 of 13 (all flat in P2; 4 have a sloped roof in lidar).
- If the lidar classifier is right 87 % of the time on simple form, P2's true agreement is in the same range.

**Four classes** (lidar vs the classifier on P2's meshes; n = 791): agreement **30.0 %** (26.9–33.3 %),
kappa 0.12. Of the 443 roofs lidar calls complex, P2 draws 236 as gables, 70 as hips, 39 as flat and 98 as complex.

**Complex where P2 draws a simple roof:**
- Overall: lidar calls 345 of the 683 roofs P2 draws simple complex (50.5 %, interval 46.8–54.3 %). For houses
  it is 312 of 536 (58.2 %), for garages 29 of 134 (21.6 %).
- After the over-call correction: roughly a quarter of all P2-simple roofs and about 37 % of P2-simple houses.
- The other way round, lidar sees a simple roof where P2 drew a complex one 10 times.

**Ridge direction** where both lidar and P2's mesh read a gable: within 20° for 244 of 308 (79.2 %,
74.3–83.4 %).

**No link between P2's family and the real roof.** Lidar's complex share by the house family P2 assigned
ranges from 53 % (modernInfill) to 70 % (colonial), and the lidar hip share of P2's "prairie" houses (profile:
90 % hipped) is 12 of 43 (28 %), against 38 of 113 (34 %) for colonials. Families are drawn per building from the profile,
so they carry no information about the actual house (`comparison.json` `lidarFormByP2HouseFamily`).

## 7. Lidar vintage (spring 2017) vs current buildings (OSM 2026-10-06)

Checked against the NAIP scene of 2023-07-10 (0.3 m, `il_m_4208759_sw_16_030_20230710_20240209`, read for the
canopy work). "Non-vegetated" means median NDVI below 0.2 over the cells, i.e. a roof or pavement.

| Mismatch | Count | Non-vegetated in 2023 | Vegetated in 2023 |
|---|---:|---:|---:|
| OSM footprint, no lidar roof | 38 | 22: probably built after spring 2017, or the footprint sits on pavement | 16: footprint off the building, or a roof under canopy |
| Lidar building ≥ 30 m² with no OSM footprint within 1.5 m | 420 (median 108 m², IQR 55–183; 7.8 ha) | 305: standing structures OSM lacks (garages, houses), or footprints more than 1.5 m off | 115: demolished since 2017, under canopy, or vegetation misclassified as building |

The 420 are a finding for [data-coverage.md](data-coverage.md): even this well-mapped Evanston area seems to
lack a few hundred structures in OSM. Overture (now a second footprint source on main) may already hold them;
not checked here. Buildings built after July 2023 are invisible to both checks.

## 8. Recommendation

**Profile level now (aggregates only).**
- Houses in the `evanston` zone:
  - Raise the hip share: about 32 % of simple forms against P2's 25 %.
  - Raise the share of complex assemblies (wings, crossing gables) towards 40–45 % of houses. P2 has 17 %.
  - Lower the gable pitch: median 35°, IQR 28–42°, against P2's 43°.
  - Flat stays near 10 %.
- Garages: hip about a third and flat under 10 % (P2: 7 % hip, 22 % flat); gable pitch around 20–33°.
- These are statistics of public-domain data selected by OSM footprints, the same kind of aggregate as the
  region kit's OSM-derived profile statistics. Credit USGS 3DEP where they are used (licensing N2).
- Changing the profiles is P2's or the coordinator's call; nothing was changed here.

**Per-building hints: not yet.**
- Gain: the simple form would be right about 87 % of the time instead of about 48 %, and the complex flag would
  catch every complex roof in the sample.
- Blockers:
  1. The complex over-call (a third of simple roofs) must be fixed first and re-checked on a fresh sample:
     ignore planes under about 6 m² or inside the main planes' outline (dormers), and treat flat planes under
     about 15 % of the roof as porches.
  2. Licensing: lidar is public domain, but hints keyed by OSM ID add external observation data to OSM features.
     That is not a trivial transformation (licensing.md **O12**; O12 was updated on main for the Overture
     decision, so check its current text). Keep per-value provenance ("method": "lidar-planes", USGS project,
     acquisition dates), in a separate optional layer like the format proposed in
     [aerial.md §8](aerial.md#8-recommendation).
  3. The generator has no per-building roof input today. Adding one is a design decision outside the plan, so it
     is reported here, not built.
- Useful for any later comparison: exporting `roofMasses`, `crossGable` and `dormers` in `scene.json`.

**Scaling to the North Shore.**
- **Coverage:** the same EPT dataset covers Cook County to 42.16° N: Evanston, Wilmette, Kenilworth, Winnetka,
  Glencoe. Lake County (Highland Park and north) needs other 3DEP projects (not checked).
- **Data:**
  - about 118 MB per km² at depth ≤ 10, about 300 MB at full depth;
  - the Cook County North Shore towns are about 55 km² (rough), so roughly 6.5 GB at depth ≤ 10;
  - EPT nodes cannot be filtered by class before download.
- **Compute:** classification takes about half a minute per km² on this Mac.
- **Footprints:** OSM holds few North Shore houses (data-coverage.md). Use the Overture (Microsoft ML)
  footprints now merged on main, keyed by Overture id, or derive footprints from the building class itself.
- **Calibration:** fix the over-call, then hand-check 30 roofs per zone. Ship per-zone roof-mix statistics.

## 9. Limits

- One area, one flight, one labeller (the agent), labelling from the same points the classifier used.
- n = 30 for the hand check: every share carries ±15–20 points.
- Depth ≤ 10 means about 4 building points per m². Small dormers and garages carry few points (a 45 m² garage:
  about 120 points inside its eroded footprint), and the side views of the hand check are sparse.
- Footprint misfit: one global shift. Per-building offsets of 1–3 m remain, and they cause some "no opposite
  pair" and "mixed" calls.
- The vendor's building class decides what counts as roof. Vegetation classed as building (or the reverse)
  passes through.
- "Complex" is a definition, not a style: it counts planes and directions, not whether a roof reads as Tudor or
  Queen Anne.
- P2's complex flag comes from the meshes, not from P2's own roof-assembly fields, which the package does not
  export.

## 10. Decisions (conservative choices not covered by the brief)

1. **Depth ≤ 10 instead of full resolution**, to stay inside the download budget (118 MB instead of about 300 MB
   for the 1 km²). The whole area was kept rather than a sub-area.
2. **Building class instead of returns**: the EPT carries no return information (all points 1 of 1).
3. **One global footprint shift** (1 m W, 1 m N), as the aerial study did, not per building.
4. **P2's complex flag from its meshes**, because the roof-assembly fields are not exported. The classifier is the
   same on both sides; its check on P2's meshes (98.6 %) is reported.
5. **Generator commit:** compared at `b8f6c71`, the generator on main at the time of writing.
   - Runs at `1085568` and `44eeaa3` gave identical P2 roof forms between them.
   - `b8f6c71`'s relative size thresholds moved a few houses to other families. Simple-form agreement went
     from 48.4 % to 47.9 %; the conclusions did not change.
6. **Vintage check with the NAIP scene already read for the canopy work**, so no extra download.
7. **Thresholds frozen** before the hand check. The over-call it found is reported, not tuned away on the same
   sample.

## 11. Bytes downloaded (lidar pilot)

| What | Bytes |
|---|---:|
| EPT LAZ nodes (280, depth 0–10) | 117,612,558 |
| EPT hierarchy (root and sub-hierarchy files) + `ept.json` | 191,632 |
| Exploration before the tool (`ept.json`, root hierarchy) | 62,907 |
| TNM Access API product query, ScienceBase item, FGDC metadata XML, AWS registry YAML | 32,332 |
| USGS copyright page (403, blocked) | 919 |
| **Total** | **117,900,348 (≈ 117.9 MB)** |

Python wheels for all the phase 5B tools (numpy, scipy, shapely, pillow, rasterio, duckdb, laspy, lazrs, small
dependencies and pyflakes) came to about 70 MB. That is an estimate from the wheel sizes; uv does not log bytes.

## 12. How to re-run

See [`Tools/regionkit/lidar/README.md`](../../Tools/regionkit/lidar/README.md): `lidar.py all --work DIR`
(about 118 MB), then `handcheck` and labels in the work directory for `score`, and `vintage --naip TIF` with the
NAIP GeoTIFF that `Tools/regionkit/aerial/canopy_areas.py fetch` writes.
