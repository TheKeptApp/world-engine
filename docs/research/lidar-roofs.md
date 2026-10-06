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

A follow-up measures **tree heights and crown radii** from the same lidar for three test areas and updates the
profiles' `trees.heightMeters` and `trees.youngShare`: see [section 13](#13-tree-heights-follow-up-2026-10-06).

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
   (22 of them on a non-vegetated surface in NAIP 2023, so probably built after the flight, or the footprint sits
   on pavement). Lidar sees 420 building-class structures of at least 30 m² with no OSM footprint within
   1.5 m (median 108 m², 7.8 ha in all); 305 of them are still non-vegetated in 2023. Most look like unmapped garages and houses; this is not
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
28–40°. Garages use 15–25° in the `evanston`, `wilmette` and `chicago-dense-north` profiles; only `default` and `front-range` use 15–27°.

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
  - Raise the share of complex assemblies (wings, crossing gables) towards 40–45 % of houses. P2 has 17 %. *(2026-10-06: P2 commits 8c69ac8 and 56addf9 have since moved evanston-south to 47 % multi-mass roofs.)*
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

## 13. Tree heights (follow-up, 2026-10-06)

The generator calibrates generated yard and street trees toward each profile's measured `trees.canopyShare`
(NAIP), but falls far short: evanston-south 0.16 achieved against 0.47, wilmette 0.18 against 0.55, lakeview 0.09
against 0.18. A mesh tree's crown radius follows its height (radius = 0.29 × height × 1.15 for the broad crown),
so the question is whether the profiles' `trees.heightMeters` ranges (evanston 10–18 m, wilmette 11–19, chicago
8–15) match what lidar sees, and whether the crown-radius ratio does. Same dataset and tool family as the roof
pilot: `Tools/regionkit/lidar/trees.py` (tree module `treeheights.py`, config `data/trees.json`), aggregates in
`Tools/regionkit/lidar/results/trees.json`. Per-tree values stayed in the work directory (deleted).

### 13.1 Summary

1. **The profile heights are too low, and so are the crowns.** Detected trees in the three areas have median
   heights of 14.6 m (Evanston), 14.7 m (Wilmette) and 12.6 m (Lakeview, 13.2 m clear of buildings). The generator,
   with the old profile values, draws trees with a mean height 14, 9 and 24 % below the measured mean (Evanston,
   Wilmette, Lakeview) and a mean squared height (what crown area follows) 26, 20 and 41 % low.
2. **Crowns are also wider per metre of height than the meshes.** The crown radius of a detected tree is
   **0.38 × height** in Evanston, **0.36** in Wilmette and **0.40** in Lakeview (least squares through the origin),
   against **0.343** for the profiles' archetype mix (broad 0.334, oval 0.219, spreading 0.414; Lakeview's mix
   0.327). The ratio falls with height: in Evanston and Wilmette about 0.43–0.45 for trees of 3–7 m, 0.41–0.42 for
   7–12 m, 0.37–0.38 for 12–17 m and 0.35–0.36 for 17–22 m (Lakeview 0.42, 0.42, 0.39, 0.40). It depends on where
   the crown edge is put (0.34–0.42 over the edge settings tried, 13.8), and the watershed gives each tree only its
   own part of a touching canopy, so it is a lower bound for the free crown.
3. **Per tree, a lidar crown covers 92–112 m² of plan area.** A mesh tree covers 39–74 m² with the old profile
   heights (1.5–2.7 times less than the lidar's 105–112 m², the Lakeview figure for its clear subset) and 63–85 m² with
   the new ones (1.3–1.7 times less). The new heights close roughly a third to a half of that difference (in
   logarithms); the rest is the radius ratio. Neither explains the whole canopy gap (0.16 against 0.47 is a
   factor of 2.9): how many trees there are, and how they overlap, matters too.
4. **Trees per hectare, lidar: 38 (Evanston), 37 (Wilmette), 25 (Lakeview)** after the clutter rules of 13.3. The
   detected crowns cover 0.43, 0.41 and 0.23 of the built fabric, against NAIP's leaf-on 0.47, 0.55 and 0.18
   (13.7), so the detection finds roughly the canopy NAIP sees (Lakeview's true value was put at 0.20–0.25).
5. **The vendor's "vegetation" class is not clean.** Roof edges, wall and porch-post returns, rooftop plant and
   overhead wires are classed as vegetation (class 3/4/5 holds more than 98 % of the non-ground, non-building
   points above 3 m outside footprints, so there is no better class to use). With all clutter rules switched off
   the detection finds 7,754, 7,277 and 12,983 "trees" instead of 3,763, 3,684 and 2,517, with median heights of
   10.4, 9.7 and 11.4 m instead of 14.6, 14.7 and 12.6 (13.8). In Lakeview (tall courtyard buildings, back
   porches, alley wires) clutter still passes next to buildings: of 6 validation tops there, 5 were not trees.
   Evanston and Wilmette had no non-trees in their validation samples.
6. **Profile values applied** (13.8): `heightMeters` evanston 10–18 → **12.1–18.4**, wilmette 11–19 →
   **11.8–19.4**, chicago-dense-north 8–15 → **11.3–16.0**; `youngShare` 0.18 → **0.11**, 0.18 → **0.12**,
   0.22 → **0.07**. `youngHeightMeters` unchanged.

### 13.2 Data and access

| | Value |
|---|---|
| Dataset | Same EPT as section 1: `USGS_LPC_IL_4County_Cook_2017_LAS_2019`, `usgs-lidar-public` bucket, anonymous HTTPS, public domain (credit: U.S. Geological Survey, 3D Elevation Program) |
| Coverage | `ept.json` conforming bounds 41.434–42.158° N, −88.267 to −87.481° E. All three committed areas are inside, and each returned nodes with points. Wilmette: the point (42.0779, −87.7137) from the brief and the committed area (centre 42.0762, −87.7165, box 42.0717–42.0807 N, −87.7225 to −87.7105 E) are both inside |
| Flight | 16 April – 7 May 2017: **leaf-off to early leaf-out** (section 1). Tree tops are captured, crowns are sparse (13.7) |
| Read | Octree depth ≤ 10 for each area box plus 10 m: Evanston 280 nodes, Wilmette 301, Lakeview 295. 15.7 M, 16.5 M and 12.5 M points in the box plus margin: 15.1, 15.9 and 12.0 points per m² of all classes, of which vegetation 11.1, 11.5 and 7.7, ground 3.0, 3.4 and 2.5 |
| Classes | Vegetation classes 3/4/5 are populated (high vegetation, class 5, holds most). Class 1 (unclassified) is negligible above 3 m outside footprints: 6,424 points in Evanston, 37 in Wilmette, 2,545 in Lakeview. Class 6 (building) outside OSM or Overture footprints (unmapped buildings, trees misclassed as buildings): 367 k, 50 k and 66 k points. Lakeview also has 34 k class-17 points (bridge deck in the LAS specification), not used |
| Not read | Depth 11 (full resolution: 23–28 M more points per area, 36–40 points per m² cumulative) would not fit the budget (13.12) |

### 13.3 Method

Thresholds are in `data/trees.json`. They were set before any crop was viewed except where 13.6 says otherwise.

1. **Points and ground.** All points of the area box plus 10 m, in local metres. Ground = median of class-2 points
   per 2 m cell (nearest cell fills the gaps), the same `ground_model` as the roof pilot. Height above ground =
   z − ground at the point.
2. **Canopy height model (CHM).** 1 m raster of the maximum height above ground of the vegetation points (class
   3/4/5) between 2 and 45 m. A second raster holds the building-class maximum.
3. **Roof clutter** (`treeheights.remove_roof_clutter`, `tops_on_roofs`). The roof zone is the building-class cells
   at least 2.5 m high, closed once, holes of up to 60 cells filled (a real courtyard is bigger and stays open), then
   grown by one cell to take in the wall line. A vegetation cell in the zone is removed unless it rises more than
   0.75 m above the roof beside it (the highest building cell within 2 cells, or the nearest one). Tops inside the
   roof mask that stand less than 5 m above the roof are dropped. The vegetation cells removed equal 10.0, 9.2 and
   23.1 % of the area (Evanston, Wilmette, Lakeview).
4. **Tree tops.** Gaussian smoothing, σ = 1 m, then local maxima of at least 3 m with a height-adaptive disc
   (radius = 1 m + 0.12 × height, between 1.5 and 5 m: 2.2 m for a 10 m tree, 3.4 m for a 20 m tree). Each plateau
   gives one top. A tree's height is the highest raw CHM cell within one cell of its top (smoothing flattens
   peaks). Only tops inside the area box count (the 10 m margin is for crowns, not trees).
5. **Crowns.** Marker-controlled watershed of the inverted smoothed CHM from the tops. The crown is the part of
   a basin at least max(2.5 m, 0.3 × the tree's height) high and connected to the top; its radius is that of the
   circle with the same area. A crown is "free-standing" when at most 10 % of its boundary touches another tree's
   basin.
6. **Wires, poles and stray points.** A top is dropped when (a) its crown has fewer than 3 cells, (b) the top
   layer of its crown (within 1.5 m of the smoothed peak) is under 1.2 cells thick (a wire or pole is one or two
   cells wide), or (c) fewer than 60 vegetation points lie within 2 m of it in its top 3 m (a crown top has
   dozens even leaf-off). Dropped in sequence, Evanston / Wilmette / Lakeview: 55 / 37 / 447 (a), 867 / 769 / 3,004
   (b), 227 / 224 / 418 (c), and 8 / 11 / 39 tops on roofs, from 5,152 / 4,996 / 6,739 tops found.
7. **Statistics.** Heights and crown radii as percentiles. "Young" is a detected height under 7 m. Radius against
   height by least squares through the origin (the mesh assumption is a constant ratio), the median ratio, and a
   free linear fit; for all trees, the free-standing ones and those at least 7 m.
8. **Subset for Lakeview.** Where clutter still passes next to buildings, the statistics are also given for trees
   with no building-class cell within 3 cells.

### 13.4 Results per area

Aggregates of `results/trees.json` (`stats`; `statsClearOfBuildings` for the last column). Heights are metres
above ground.

| | Evanston | Wilmette | Lakeview, all | Lakeview, clear of buildings |
|---|---:|---:|---:|---:|
| Trees detected | 3,763 | 3,684 | 2,517 | 1,851 |
| per hectare (area box) | 37.6 | 36.8 | 25.2 | 18.5 |
| Height p10 / p25 / p50 / p75 / p90 | 6.8 / 10.6 / 14.6 / 18.0 / 20.7 | 6.5 / 9.9 / 14.7 / 18.9 / 21.9 | 6.7 / 9.4 / 12.6 / 15.3 / 17.8 | 7.8 / 10.6 / 13.2 / 15.7 / 18.1 |
| Share below 7 m ("young") | 0.107 | 0.124 | 0.118 | 0.072 |
| Trees of 7 m or more: p25 / p75 | 12.1 / 18.4 | 11.8 / 19.4 | 10.7 / 15.6 | 11.3 / 16.0 |
| Crown radius p10 / p25 / p50 / p75 / p90 | 2.9 / 3.9 / 5.2 / 6.8 / 8.7 | 2.7 / 3.7 / 5.1 / 6.8 / 8.3 | 2.6 / 3.6 / 4.8 / 6.2 / 7.8 | 3.2 / 4.0 / 5.1 / 6.7 / 8.0 |
| Radius / height, through origin (median) | 0.381 (0.390) | 0.364 (0.377) | 0.400 (0.404) | 0.411 (0.416) |
| Radius / height, free-standing crowns only (n; share of trees) | 0.417 (495; 13 %) | 0.393 (568; 15 %) | 0.419 (425; 17 %) | 0.438 (224; 12 %) |
| Mean crown plan area per tree (m²) | 112 | 108 | 92 | 105 |

Tallest detected trees: 29.3 m (Evanston), 31.8 m (Wilmette, 8 trees of 30 m or more), 26.8 m (Lakeview); plausible
for old cottonwood, oak, maple and ash. Radius against height by height class (median radius / height, trees):
Evanston 0.447 (401), 0.419 (834), 0.382 (1,308), 0.361 (1,042), 0.362 (178) for 3–7, 7–12, 12–17, 17–22 and 22 m or
more; Wilmette 0.431, 0.405, 0.374, 0.348, 0.341; Lakeview 0.416, 0.415, 0.394, 0.398.

**Against the mesh assumption.** The mesh radius per metre of height is 0.3335 for the broad crown
(0.29 × 1.15), 0.2185 for oval and 0.414 for spreading. Weighted by each profile's `crownWeights` the mean is
**0.343** (Evanston, Wilmette; root-mean-square 0.350) and **0.327** (chicago-dense-north; 0.336). Lidar
(least squares through the origin, all trees) / mesh: 1.11, 1.06 and 1.22. Conifers (5–8 % of trees) and
a narrow-crowned species mix are not separated in the lidar, so the comparison is for the whole population.

### 13.5 Mean crown area, in numbers

Generated crown plan area per tree = π × (mean squared radius ratio of the archetype mix: 0.1226; 0.1132 for
Lakeview) × mean squared height of the draw (uniform over `heightMeters` for the old and new profiles; young trees
uniform 3–6 m with probability `youngShare`).

| | Evanston | Wilmette | Lakeview (clear subset) |
|---|---:|---:|---:|
| Measured mean height; mean height², lidar | 14.3 m; 228 | 14.5 m; 241 | 13.1 m; 187 |
| Old profile: mean height; mean height² | 12.3 m; 169 | 13.1 m; 193 | 10.0 m; 111 |
| New profile: mean height; mean height² | 14.1 m; 213 | 14.2 m; 220 | 13.0 m; 176 |
| Crown plan area per tree, old profile / new profile / lidar (m²) | 65 / 82 / 112 | 74 / 85 / 108 | 39 / 63 / 105 |

The new heights bring the generated mean height within 1–2 % of the lidar's (the old ones were 9–24 % low). The
remaining crown-area gap (lidar 1.3–1.7 times the new mesh crowns) is the radius ratio, which this note only
reports: it is generator code.

### 13.6 Validation of the detection

Method: crops (scratch only, deleted). Each tile shows a 44 m window of the vegetation CHM (colour = height) with
tops, the focal crown outline and the building footprints, beside a side view of the lidar points of a 5 m strip
coloured by class. The agent labelled the marked top. The final sample (`data/trees_validation.json`, 36 tiles)
was drawn with a fixed seed after the rules were set: 8 random trees per area and 4 more within 3 cells of a
building-class cell.

| | Single tree | Merged crowns | Ambiguous | Not a tree |
|---|---:|---:|---:|---:|
| Evanston (12) | 10 | 1 | 1 | 0 |
| Wilmette (12) | 10 | 0 | 2 | 0 |
| Lakeview (12): 8 random | 6 | 0 | 1 | 1 |
| Lakeview: 4 more next to buildings | 0 | 0 | 0 | 4 |

- Of the 8 random tops in each area, 3 (Evanston), 1 (Wilmette) and 2 (Lakeview) lay within 3 cells of a
  building-class cell. Lakeview, tops within 3 cells of a building: 1 tree, 5 not trees (of the 2 random ones, 1
  each). Lakeview, tops clear of buildings: 5 single trees and 1 ambiguous, no non-trees (6 random tops).
- In every tile that showed a tree, the marked height matched the highest vegetation points of the side view.
- Ambiguous: shrub-like mounds of 6–8 m, and a columnar conifer whose crown outline spreads along the gap between
  two houses. Merged: two neighbouring crowns in one region (radius 7.5 m for a 13 m tree).
- Tuning crops (viewed while the rules were set, not counted above): 9 of 9 tops that only exist without the roof
  rule were roof edges, parapets or porch frames; of 9 tops rejected as too thin, 7 were wires, poles or porch
  frames and 2 were real trees (a 14.5 m tree with a narrow top, a columnar conifer); of 12 rejected for too few
  points, 10 were stray points or wires, 1 a sparse leaf-off 13 m tree and 1 a 6 m shrub. So the rules cost a few
  percent of real trees (sparse crowns, columnar conifers), which biases the young share down.
- **No independent height reference exists here.** The three committed OSM extracts hold no `natural=tree` node
  with a `height` tag (Evanston 0 trees, Wilmette 0, Lakeview 5 untagged), and no other height source was used. The
  check is the side views, not ground truth.

### 13.7 Leaf-off, and a check against the leaf-on NAIP canopy

- **Tops.** In April–May 2017 deciduous crowns were bare or just leafing out. The vegetation point density is
  7.7–11.5 points per m² in the box, so the highest twig of a bare crown is usually hit but not always. Published
  leaf-off studies put the loss of height at about 0–1.5 m for broadleaf trees; this data set has no leaf-on
  flight to measure it, so it is not corrected. The proposed heights are probably a little low (0.5–1 m is a fair
  guess) for that reason, and for another: **the flight is nine years old**, so surviving trees are 1–2 m taller
  now, while trees lost since (ash to emerald ash borer, storm and development losses) are missing from today's
  canopy and not removed here.
- **Cover.** Detected crown plan area (non-overlapping) against the NAIP 2023 leaf-on canopy of the built fabric
  (`Tools/regionkit/aerial/results/canopy_areas.json`):

  | | Lidar crowns (fabric) | Lidar cells ≥ 2.5 m after clutter (fabric) | NAIP canopy (fabric) |
  |---|---:|---:|---:|
  | Evanston | 0.433 | 0.469 | 0.473 |
  | Wilmette | 0.410 | 0.445 | 0.551 |
  | Lakeview | 0.232 | 0.287 | 0.178 (true value put at 0.20–0.25) |

  Evanston matches, Wilmette's leaf-off canopy is 74 % of the leaf-on one (sparser maples and oaks, and the
  roof-overhang crowns removed with the clutter), and Lakeview is above NAIP, where residual clutter near buildings
  is the likely reason. Before the roof-clutter rules, the vegetation cells of 2.5 m or more covered 0.55, 0.52 and
  0.51 of the whole areas against NAIP's 0.46, 0.54 and 0.18: 9 points more in Evanston and 33 in Lakeview, so
  the clutter was a large share of the "canopy" there.
- **Young trees.** Small trees have few returns when leafless, and the thickness and point rules reject sparse
  tops, so the share below 7 m is probably biased low. Shrubs of 3–7 m count as trees, which biases it high. The
  detection scale decides it more than the leaf state: the share is 0.077–0.129 (Evanston), 0.082–0.150 (Wilmette)
  and 0.055–0.085 (Lakeview, clear subset) over the settings of 13.4.

### 13.8 Profile values: proposed and applied

`heightMeters` is the range the generator draws from for a tree that is not young (`SceneGenerator`,
`YardGeneration`: young with probability `youngShare`, else uniform over `heightMeters`). The brief asked for the
p25 and p75 of the detected trees; for the generator's draw model that range must describe the trees that are not
young, or the trees under 7 m are counted twice and trees of 7–10 m are lost. The applied `heightMeters` is therefore
p25 and p75 of the trees of **7 m or more**; the p25/p75 of all trees is given beside it, and swapping it in is a
two-number edit.

| Profile | `heightMeters` old → applied (p25–p75 of all trees) | `youngShare` old → applied | Basis |
|---|---|---|---|
| evanston | [10, 18] → **[12.1, 18.4]** ([10.6, 18.0]) | 0.18 → **0.11** | all 3,763 trees; no non-trees in the validation sample |
| wilmette | [11, 19] → **[11.8, 19.4]** ([9.9, 18.9]) | 0.18 → **0.12** | all 3,684 trees; no non-trees in the validation sample |
| chicago-dense-north | [8, 15] → **[11.3, 16.0]** ([10.6, 15.7]) | 0.22 → **0.07** | the 1,851 trees at least 3 m from a building-class cell |

- Provenance entries (`trees.heightMeters`, `trees.youngShare`) are in each profile, marked measured, with the
  previous value, the check and the sensitivity.
- **Sensitivity** (one setting at a time: window slope 0.08/0.18 per m, smoothing σ 0.5/1.5 m, crown edge 0.2/0.45 of
  the height, minimum height 4 m, the roof rule off, the thickness rule off, the point rule off or at 100; plus one
  run with all clutter rules off, listed separately in 13.1): all-tree p25 and p75 vary by about 1.3 m at most in
  Evanston (10.1–11.4 / 17.7–18.3), 1.8 m in Wilmette (9.1–10.9 / 18.3–19.2) and 0.9 m in Lakeview's clear subset
  (10.0–10.9 / 15.5–16.1). The detection scale moves the tree count much more (Evanston 2,941–5,100) than the
  height quantiles. The crown edge moves the radius ratio (0.34–0.42 for the 0.45 and 0.2 settings over the three
  areas) and the tree count not at all.
- **Lakeview** uses the clear subset because the sample showed clutter next to buildings. That subset leaves out yard
  trees beside houses, which in the other two areas are 0.7–1.0 m shorter at p25 and add 0.03 to the young share, so
  its p25 is probably 0.5–1 m high and the share 0.03 low. Even so the old values lie below everything the
  detection produced (p25 of 8 m against 9.4–10.9; young share 0.22 against 0.055–0.15 over all settings and
  subsets), so they are replaced.
- **`youngHeightMeters` [3, 6] unchanged.** The measured trees below 7 m have a median of 5.7–6.0 m (p25–p75 5.0–6.4)
  and almost none are under 4 m, but trees under 4 m are the ones leaf-off lidar and the rules miss most, so the data
  do not say the range is wrong.
- Nothing was withheld. The Lakeview values are the least certain (clutter next to buildings); keeping the old
  ones there is possible, but no setting of the detection produced them.

### 13.9 What this means for the canopy gap

Reported only; the generator and renderer were not touched.

- With the new heights the generated trees are the right height, but their crowns are 0.6–0.8 of the measured
  crown area (13.5). A crown radius ratio near **0.38** (instead of 0.343) would bring Evanston and Wilmette to
  0.90–0.97 of it (area goes with the square of the ratio), and would not overshoot the leaf-on NAIP cover:
  lidar crown area at the 0.3 × height edge is already 0.91 (Evanston) and 0.74 (Wilmette) of NAIP.
- The lidar canopy is made of about 38 trees per hectare (Evanston, Wilmette) and 25 (Lakeview; about 19 for the
  clear subset alone) whose crowns touch. Whether the generator places that many is the first thing to compare
  against the 0.16 / 0.18 / 0.09 achieved.
- Per-tree heights keyed to OSM or Overture IDs are not proposed (same licensing and design questions as the roof
  hints in section 8).

### 13.10 Limits

- One area per profile, one leaf-off flight, nine years old; one labeller (the agent), 36 validation tiles.
- No leaf-on lidar and no ground truth for height (13.6, 13.7).
- Depth ≤ 10 (11–15 vegetation points per m² in Evanston and Wilmette, 7.7 in Lakeview): thin crowns lose points.
- The vendor class carries wall, wire and roof returns; the rules in 13.3 are tuned on crops of these three areas
  and may not transfer to areas with other building types. Lakeview still has roughly a fifth to a quarter of its
  tops that are not trees (26 % of its trees stand within 3 cells of a building, and 5 of the 6 sampled there were
  clutter).
- The areas include their parks (Evanston 5.6 % of the area, Wilmette 6.9 %, Lakeview 0.5 %); the statistics for
  the built fabric alone (`statsFabric`) differ by about 0.2 m at most at every percentile.
- A watershed crown is the tree's share of a touching canopy: overlap is invisible, the radius is a lower bound
  for a crown standing alone, and two trees can merge (1 of 36 tiles) or one tree can split.
- Tree height in a 1 m CHM cell is the highest return in that cell; a leaning or very narrow tree can be a few cells
  off.

### 13.11 Decisions

1. **Vegetation classes 3/4/5**, because they are populated and class 1 is negligible; the "non-ground, non-building
   above 2 m outside footprints" route of the brief would add only the clutter classes.
2. **Depth ≤ 10 and a 10 m margin** for all three areas (about 100–131 MB each), the only choice that fits the
   400 MB budget; no sub-box.
3. **Roof, wall, wire and sparse-top rules** added after the first crops showed tops on roof edges (the first
   version of the rule was a roof-height band; a second, the roof zone; then the thickness and point-count rules for
   Lakeview's wires and porch posts). The values are in `data/trees.json`; their effect is in `sensitivity`.
4. **`heightMeters` from the trees of 7 m or more**, not from all detected trees (13.8), with the all-trees values
   reported beside it.
5. **Lakeview from the clear-of-buildings subset** (13.8).
6. **`youngHeightMeters` untouched** (13.8).
7. **Overture footprints** (Wilmette) join OSM only for diagnostics (tops inside a footprint); they do not filter
   the CHM.
8. **Roof clutter by the lidar's own building class**, not by footprints, because OSM footprints are 1–3 m off the
   lidar roofs (section 3) and miss unmapped buildings (section 7).

### 13.12 Bytes downloaded (tree measurement)

| What | Bytes |
|---|---:|
| EPT LAZ nodes: Evanston 280 + Wilmette 301 + Lakeview 295 (depth 0–10) | 117,612,558 + 131,479,560 + 99,876,912 = 348,969,030 |
| EPT hierarchy files (three areas) | 593,765 |
| `ept.json` (three times) | 7,770 |
| **Total** | **349,570,565 (≈ 349.6 MB, 87 % of the 400 MB budget)** |

Python wheels (numpy, scipy, shapely, pillow, rasterio, laspy with lazrs, scikit-image and small dependencies)
came to roughly 80–100 MB (estimate: uv does not log bytes; the unpacked environment is 221 MB). They are tooling,
not data; counted in the budget they would bring the total to about 430–450 MB. The unpacked environment, the
points and the crops lived in the scratch directory and were deleted.

### 13.13 How to re-run

See the lidar tool README: `trees.py plan`, `fetch` (about 350 MB), `measure --sensitivity --write`, and `crops`
for the visual check (scratch only). The tests (`tests/test_treeheights.py`) are offline.
