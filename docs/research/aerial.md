# Aerial roof study: roof colour, roof type and tree canopy from NAIP

Workstream E, 2026-10-06; revised the same day after an independent check. This is a feasibility test on one
500 m × 500 m residential cell on the North Shore. The cell is centred on a public park, the same anchor as the
region kit's 1 km cell `wilmette-vattmann-park` (radius 500 m). The question: can public aerial imagery tell the
generator each roof's colour family and roof type, and the tree canopy per block?

Tool: `Tools/regionkit/aerial/` (one command re-runs it; see [How to re-run](#11-how-to-re-run)). Numbers come
from `Tools/regionkit/aerial/results/summary.json` and `accuracy.json`. Aggregates only: no per-building values,
crops or building IDs are in the repository, and statistics over fewer than 5 buildings are reported as counts.

The independent check reproduced `accuracy.json` byte for byte and found no arithmetic errors. A blind second
opinion on 10 labels agreed on colour 9/10 and roof type 8/10. The figures marked "independent check" below
come from the checker's reproduction (per-pixel or per-building data that is not committed); everything else
recomputes from the committed results and the hand labels.

## Summary

1. **Imagery and licence.** The newest Illinois NAIP covering the cell is from **10 July 2023: 0.3 m, four bands
   (red, green, blue, near-infrared), leaf-on**. USDA has placed NAIP in the public domain and *asks* for the
   credit "NAIP imagery provided by USDA Farm Service Agency". The study read only the cell's window from a
   cloud-optimised GeoTIFF on Microsoft Planetary Computer: 18.6 MB of byte ranges out of a 1.87 GB file, no
   account.
2. **Tree canopy per block works.** NDVI alone cannot separate lawns from trees, because both sit near 0.5 in July.
   NDVI plus near-infrared texture can.
   - **Cell canopy:** **58.3 %** from the mask. Photo interpretation of random points gives **54.3 %** (95 %
     interval 44–65 %). The 8 unreadable points could move that between 50 % and 58 %.
   - **Agreement:** the mask matches photo interpretation at **85 % of 92 points** (kappa 0.69). Always answering
     "tree" would score 54 %, and NDVI alone 80 % (independent check).
   - **Per block:** the 4 complete blocks have 59–72 % canopy (area-weighted 63 %). Faces clipped by the cell edge
     go down to 23 % and up to 85 %, but those extremes are slivers under 0.2 ha.
3. **Roof colour is usable only as a profile-level lightness mix, and it misses warm roofs.**
   - **Agreement:** exact agreement with hand labels is **60 %** (33 of 55, rules written before labelling), or
     **74.5 %** (41 of 55) if neighbouring families count, e.g. charcoal vs grey. Always answering "grey" scores 49 %.
   - **Lightness:** captured for charcoal and grey. Black and white are untested: the labels contain 0 black roofs
     and 1 white. All 3 sampled roofs the rules called black were labelled charcoal, so the cell's 10 % "black" is
     probably partly shadowed charcoal.
   - **Warm roofs:** brown and tan make up 13 of 55 labels (23.6 %), against 3–18 % in the estimates. They mostly
     come out charcoal or grey, because NAIP roof colours are almost unsaturated (median chroma C\* 4).
   - **Scene-relative rules:** a rule set designed on the first sample gained 1 roof on the fresh sample (65.4 %
     vs 61.5 %). Brown went from 0/4 to 3/4, but grey lost 2.
4. **The roof-type guess has not been shown to beat a constant guess** (n = 51; about ±20 points on the
   difference).
   - **Pooled:** 25 of 51 correct (49.0 %), the same as always answering "complex". But the sample
     over-represents OSM buildings (10 of 60, against 16 of 274 estimated roofs in the cell).
   - **By source:** OSM 2/10 (always "complex" 8/10). Overture 23/41 = 56.1 % (always "complex" 17/41 = 41.5 %,
     always "hip" 16/41).
   - **Weighted to the cell** (5.8 % OSM, 94.2 % Overture): about 54 % vs 44 %. The independent check's paired
     bootstrap of the Overture difference gives +14.6 points (95 % interval −10 to +37), not distinguishable from
     zero.
   - **Generator-usable forms:** on the 26 labelled roofs that are not complex (forms the generator can draw), it
     gets 15 right; always "hip" gets 16.
   - **Unstable across samples:** it beat the baseline on sample A (58.6 vs 44.8 %) and lost on B (36.4 vs
     54.5 %).
   - **Confidence:** carries no signal (12/29 correct at ≥ 0.7, 13/22 below).
   - **Small vs large:** it got 5 of 7 roofs under 50 m² right (n = 7, about ±35 points) and 20 of 44 at 50 m² or
     more, a group that is mostly houses but not only houses.
   - **At 0.6 m:** 39 %.
5. **Canopy hides few roofs.** 32 of 274 footprints (12 %) are more than half covered by vegetation pixels, and
   20 (7 %) are too covered or too shaded for any colour estimate. In the 60 hand-labelled roofs, 3 were mostly
   under canopy and 6 more were unreadable: 5 because of tree shadow, 1 because the footprint covered only part
   of the roof.
6. **Recommendation.** Use the imagery at **profile level only**, and ship no per-building hints from NAIP.
   - **Canopy:** a canopy share per zone. This needs a profile tree-density or canopy field, which doesn't exist
     yet.
   - **Roof colour:** the roof lightness mix for the roof colour slots, after a check of black and white roofs.
     Raise the warm share above what the rules estimate.
   - **Roof type per building:** from USGS 3DEP lidar (QL1, public domain, covers the cell), not from imagery.
   - **Roof mix weights:** a cheap, aggregate-only alternative is to photo-interpret 50–100 random roofs per zone,
     weighted by footprint source.
   - Details are in [section 8](#8-recommendation).
7. **Phase 5B: canopy of the committed test areas** ([section 13](#13-canopy-share-of-the-committed-test-areas-phase-5b)).
   - Same mask, NAIP 2023 at 0.3 m. Residential fabric (land without parks or water):
     - South Evanston **47 %**;
     - Lakeview (Sheil Park) **18 %**;
     - Sloan's Lake, Denver **25 %**;
     - the new Wilmette test area (1 km² around Vattmann Park) **55 %**.
   - Recommended `trees.canopyShare`: `evanston` **0.47**, `chicago-dense-north` **0.18**, `front-range` **0.25**,
     `wilmette` **0.55** (the profile had 0.58, from the 0.25 km² study cell; it now carries 0.55).
   - A 50-point photo check per area agrees 74–91 %. On balance the mask reads a few points lower than the
     labelled points.
   - Later calibration (13.10): Wilmette's tree count is corrected from 51 to **45 trees/ha** (95 % range 39–54),
     and Winnetka (58 % canopy) and Kenilworth (58 %) were added.

## 1. Licence and access

**Licence (quoted from authoritative sources):**

- Embedded by the producer in the very file read (TIFF `ImageDescription` of the 2023 tile): "Imagery has been
  placed in the public domain and may be used and reproduced without permission or fee. Please credit 'NAIP
  imagery provided by USDA Farm Service Agency' on any use."
- USDA FSA FGDC metadata for the same quarter-quad (2019 delivery, the newest with a metadata file on Planetary
  Computer): `Access_Constraints: There are no limitations for access.` / `Use_Constraints: None. The
  USDA-FPAC-BC Aerial Photography Field office asks to be credited in derived products.`
- USDA FSA "Policies and Links" page (fsa.usda.gov/help/policies-and-links): "Public domain information may be
  freely distributed or copied, but use of appropriate byline/photo/image credits is requested."
- Planetary Computer's STAC collection `naip` gives the licence as proprietary-with-link, titled "Public
  Domain", pointing to that FSA page.

**Access used:**
- The Planetary Computer STAC search (collection `naip`, point query) found 8 items for the cell (2011–2023).
- An anonymous SAS token came from `planetarycomputer.microsoft.com/api/sas/v1/token/naip`.
- GDAL `/vsicurl/` read the 1667 × 1667 px window in 9 HTTP range requests, 18,580,724 bytes. That is more than
  the window itself, because the 512 px DEFLATE tiles overhang it.
- No whole tile was downloaded. The full file is 25,277 × 19,423 px, 1,867,512,608 bytes (`Content-Length` of a
  HEAD request).

**Alternatives checked:**

| Source | Result |
|---|---|
| USGS The National Map, NAIP Plus ImageServer (`imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer`, `exportImage` for a bbox) | Works and is public domain, but serves only the **2019, 0.6 m** acquisition at this point (catalog query) |
| USDA APFO image services (`https://gis.apfo.usda.gov/arcgis/rest/services/NAIP`) | No connection from this machine; the independent check got a connection reset |
| Esri NAIP image service (`https://naip.imagery1.arcgis.com/arcgis/rest/services/NAIP/ImageServer` tried here: no connection; `naip.arcgis.com`: answers "Token Required", code 499, per the independent check) | Not anonymously usable |
| AWS `naip-*` buckets | Requester-pays, avoided |

Whether a newer (2025) Illinois acquisition exists is unconfirmed: Planetary Computer's catalog ends at 2023 and
the USDA and Esri services above were not readable.

**Acquisition used:**
- Item `il_m_4208759_nw_16_030_20230710_20240209` (quarter-quad "Evanston NW 4208759").
- Acquired 2023-07-10, processed 2024-02.
- 0.3 m GSD, 4 × 8-bit bands, UTM 16N (EPSG:26916).
- The STAC time of day (16:00 Z) looks like a placeholder, so only the date is used.
- **Season:** July, full leaf. Trees cover part of many roofs, and tree shadows darken more.

## 2. Cell and footprints

The cell is 500 m × 500 m in the tile's own UTM grid, centred on the park anchor (42.0779, −87.7137) from
`Tools/regionkit/regions/chicagoland.json`. Buildings count when their footprint centroid lies inside the cell.

| | Count |
|---|---|
| OSM buildings in the query box (cell + 30 m) | 28 |
| Overture rows in the query box | 384 (28 with an OpenStreetMap source, 356 without, all Microsoft ML Buildings) |
| Overture rows without an OSM source dropped as overlapping an OSM footprint | 0 (Overture already conflates OSM) |
| Merged footprints (28 OSM + 356 Overture) with centroid in the cell | 293 |
| … of which ≥ 15 m² | **292** (19 OSM, 273 Overture) |
| Estimated (footprint window fully inside the image) | **274** (16 OSM = 5.8 %, 258 Overture = 94.2 %) |

**Decision:** the brief said "each OSM building footprint", but OSM holds 19 buildings here, so OSM was combined
with Overture (Microsoft ML footprints) and each footprint's source was recorded. OSM-only results are reported
separately below. The 274 estimated roofs are the population that the source weights in sections 5 and 8 refer
to.

## 3. Method

**Alignment.** Footprints and the orthophoto disagree by a metre or more. NAIP is orthorectified to the ground,
so roofs lean away from the camera, and the footprints were digitised from other imagery. One global shift is
searched (±3 m, 0.3 m steps) that maximises the mean luminance gradient along all footprint outlines. Result:
**0.9 m east, 1.2 m south** (gradient score 6.3 → 9.9). A single shift keeps the fit from adapting to each
building.

**Roof colour (per footprint).**
- The footprint is eroded by 0.9 m.
- Pixels with NDVI > 0.2 (overhanging trees) and deep shadow (max(R,G,B) < 35) are dropped.
- The colour is the per-channel **median in CIE L\*a\*b\***, given as hex.
- No estimate is made if fewer than 40 % of the eroded pixels, or under 5.4 m², remain.
- Colour confidence = min(1, usable share ÷ 0.8).

**Colour families (data: `data/roof_families.json`).** There are nine families: black, charcoal, grey, white,
brown, tan, red, green, blue.

*Rule set 1* (written before any labelling). These rules make a colour achromatic:
- chroma C\* below 8;
- `darkAchromatic`: L\* < 30 and C\* < 12. Added after the first aggregate run, which classed 5 very dark roofs
  as blue. It came before any scoring and changed no sampled roof;
- `achromaticHues`: hue 290–345° with C\* < 14 (slight magenta casts on grey roofs).

Achromatic colours split by L\* into black < 28, charcoal < 45, grey < 76, and white above. All other colours go
by hue sector:
- red 345–50° (C\* ≥ 14);
- brown or tan 0–100°, split at L\* 52;
- green 100–200°;
- blue 200–345°. Between 290° and 345° this applies only when C\* ≥ 14; below that the colour is achromatic.

*Rule set 2* (`sceneRelative`, designed on sample A after scoring it) is a grey-world white balance on roofs:
- chroma and hue are measured from the scene's median roof a\*b\* (−1.8, 1.5);
- relative chroma below 3.5 counts as achromatic;
- cool casts (hue 180–320°, relative chroma < 10) count as achromatic;
- white starts at L\* 70.

**Roof type (heuristic, `roofcore.classify_roof`).** The inputs are the footprint's minimum-area rectangle and
the L\* luminance of the usable roof pixels. Three planar facet models are fitted inside the rectangle: gable
with the ridge along the long axis (two halves), gable with the ridge across, and hip (each pixel belongs to its
nearest rectangle side, which is the plan view of an equal-pitch hip roof). R² is the share of luminance
variance the facet means explain. The rules are applied in order:
1. too few usable pixels → unknown;
2. robust std of L\* < 4 and best adjusted R² < 0.10 → flat;
3. rectangularity < 0.80 (L, T, U footprints) → complex;
4. best adjusted R² < 0.12 on a textured roof → complex;
5. hip if its adjusted R² beats the best gable by more than 0.03, otherwise gable.

The heuristic relies on the sun lighting opposite roof planes differently. Confidence is a heuristic margin,
not calibrated. All thresholds are in `data/params.json`.

**Canopy.**
- **Vegetation** is NDVI > 0.2. NDVI alone cannot separate lawns from crowns. At the patches checked, lawn
  measured 0.49–0.50 and crowns 0.48–0.52; the independent check measured 0.49 and 0.51 near the park.
- **Canopy** is vegetation whose NIR standard deviation exceeds 8 digital numbers. The deviation is taken over
  the vegetation pixels of a window of **radius 1.5 m** (5 px, so 11 × 11 px, 3.3 m across). Lawns are smooth
  (std ≈ 2). Crowns are lumpy: median about 18, p10–p90 about 10–35 (independent check); the two crown patches
  checked here gave 11.5 and 25.6.
- **Clean-up:** an opening and then a majority filter, each with radius 0.9 m (3 px, 7 × 7 px). The opening
  removes thin texture bands along lawn and shadow edges; the majority filter removes specks.
- Thresholds were set by eye on the whole-cell overview before the point check.

**Blocks.**
- Blocks are the faces of polygonised OSM street centrelines plus the cell outline. Street classes run from
  motorway to living_street; service roads and paths are excluded.
- Each face includes half the street right-of-way, so street trees count.
- Faces closed by the cell outline are clipped edge blocks.

**Accuracy protocol.**
- **Sample A:** 30 buildings, stable sha256 sample with fixed seeds; at least 5 OSM buildings, the rest Overture.
  Crops were made in the scratchpad (RGB, RGB with outline, colour infrared with outline, 5 m scale bar). The
  agent labelled colour family and roof type, or can't-tell, **before computing or viewing any estimate**.
- **Sample B:** 30 more buildings, another seed, none from A. Labelled after sample A was scored and rule set 2
  designed, but before rule set 2 was applied to them.
- Rule set 1 and the roof heuristic never changed after scoring, so A and B can be pooled for them. Rule set 2 is
  judged on B only.
- **Labelling drift (caveat):**
  - The roof-type can't-tell rate rose from 1/30 in sample A to 8/30 in sample B (Fisher exact, two-sided,
    p = 0.026). The labeller was stricter in B.
  - A and B also disagree on the heuristic (58.6 % vs 36.4 %).
  - Pooled figures therefore blend two labelling regimes.
- **Sampling weights:** both samples force at least 5 OSM buildings each. The pool therefore holds 10 OSM of 60
  (17 %), against 5.8 % OSM among the 274 estimated roofs. Per-source figures and source-weighted figures
  (weights 16/274 OSM, 258/274 Overture) are given where it matters.
- **Canopy points:** 100 stable random points in 15 m patches with a crosshair. 23 ambiguous points were
  re-checked on 12 m RGB and colour-infrared zooms. The mask was never shown during labelling.
- **Resolution:** a 0.6 m version (2 × 2 block average of the same scene) reruns everything, with thresholds in
  m², not pixels.

## 4. Results (whole cell, aggregates)

**Roof colour families (274 estimated roofs).** Median colours are the aerial appearance; families with fewer than
5 roofs show the count only.

| Family | Rule set 1: share (n) | Rule set 1: median colour | Rule set 2: share (n) |
|---|---|---|---|
| black | 10.6 % (29) | #2C303A | 9.9 % (27) |
| charcoal | 28.8 % (79) | #5B5F61 | 24.5 % (67) |
| grey | 47.4 % (130) | #7D807A | 35.8 % (98) |
| white | 1.5 % (4) | n < 5 | 2.6 % (7) |
| brown | 2.2 % (6) | #776D5F | 7.3 % (20) |
| tan | 0.7 % (2) | n < 5 | 10.6 % (29) |
| red / green / blue | 0.4 / 0.7 / 0.4 % (1 / 2 / 1) | n < 5 | 0.4 / 0.7 / 1.1 % (1 / 2 / 3) |
| unknown (hidden or shaded) | 7.3 % (20) | | 7.3 % (20) |

- **All roofs with a colour (254):** median L\*a\*b\* (46.9, −1.8, 1.5) = #6D706D. L\* p10–p90 26.7–58.9; chroma
  p10–p90 2.2–7.1.
- **Small buildings (< 50 m²):** 22 % "black" (likely tree shadow on small roofs) and 20 % unknown. These are
  probably mostly garages and sheds, but that is an inference from size: Overture's `class` is empty for 376 of
  the 384 rows (independent check).
- **OSM-only (16 roofs; larger, often non-residential buildings):**
  - rule set 1: grey 8, charcoal 5, white 2, black 1;
  - rule set 2: grey 6, charcoal 5, white 3, black 1, brown 1.

**Roof type (heuristic; read the accuracy section before using it):**
- All 274 roofs: gable 32.8 %, hip 35.0 %, complex 19.3 %, flat 5.5 %, unknown 7.3 %.
- OSM-only (16): hip 8, complex 5, gable 2, flat 1.
- The labelled mix, source-weighted, is about complex 44 %, hip 37 %, gable 17 %, flat 2 % (section 8). Against
  it, the heuristic over-calls gable and under-calls complex.

**Canopy:**

| | Value |
|---|---|
| Cell canopy (mask) | **58.3 %** (vegetation incl. lawns: 67.7 %) |
| Cell canopy (photo-interpreted points, n = 92) | **54.3 %** (95 % interval 44.2–64.5 %); **50–58 %** if the 8 can't-tell points (all mask = tree) count as not tree / tree |
| Complete blocks (4 faces bounded only by streets) | 59.3, 63.5, 65.6, 72.2 %; area-weighted **63.1 %** |
| All 18 faces (14 clipped by the cell edge), area-weighted | **58.3 %** |
| Faces of at least 1 ha (9 faces, 90 % of the cell) | 28.5–65.6 % |
| Faces under 1 ha | 9 of 18; they include both extremes, 22.7 % (746 m², 0.3 % of the cell) and 85.1 % (1,588 m², 0.6 %) |
| Distribution (all faces, 10 % bins, unweighted) | 20–30: 2; 40–50: 1; 50–60: 4; 60–70: 7; 70–80: 3; 80–90: 1 |
| Vegetation share inside footprints | median 15 %, p90 53 %; 32 of 274 (12 %) more than half covered |

The lowest large face (28.5 %, about 1 ha) lies in the cell's north-east corner. There the overview shows
commercial roofs, parking and a rail line.

## 5. Accuracy

**Caveat:**
- The hand labels are judgments by the same AI agent from the same imagery (0.3 m here, finer than the ~0.6 m the
  brief expected). They are uncertain, not ground truth.
- Colour agreement measures agreement on family boundaries for the same pixels, not true roof colour.
- Sample B's labeller already knew the rule set 2 hypothesis, and the labelling got stricter between A and B
  (section 3).
- With n = 22–55, every percentage carries roughly ±13–21 points of sampling error (95 %). The baselines are the
  best constant chosen from the same labels, which flatters them slightly.

**Overview, 0.3 m.**
- "Excl." drops can't-tell labels and counts an estimate of "unknown" as wrong. "Neighbour families" uses the
  same denominator.
- "Incl." keeps can't-tell labels and counts them as not correct.
- The baseline always answers the most common label.

| Measure | Sample | Excl. can't-tell | Incl. can't-tell | Neighbour families | Baseline |
|---|---|---|---|---|---|
| Colour, rule set 1 | A | 17/29 (58.6 %) | 17/30 (56.7 %) | 21/29 (72.4 %) | grey 51.7 % |
| Colour, rule set 1 | B | 16/26 (61.5 %) | 16/30 (53.3 %) | 20/26 (76.9 %) | grey 46.2 % |
| Colour, rule set 1 | **A+B** | **33/55 (60.0 %)** | 33/60 (55.0 %) | **41/55 (74.5 %)** | grey 49.1 % |
| Colour, rule set 2 | A (design sample, optimistic) | 24/29 (82.8 %) | 24/30 (80.0 %) | 27/29 (93.1 %) | |
| Colour, rule set 2 | **B (honest test)** | **17/26 (65.4 %)** | 17/30 (56.7 %) | 22/26 (84.6 %) | grey 46.2 % |
| Roof type | A | 17/29 (58.6 %) | 17/30 (56.7 %) | | complex 44.8 % |
| Roof type | B | 8/22 (36.4 %) | 8/30 (26.7 %) | | complex 54.5 % |
| Roof type | **A+B** | **25/51 (49.0 %)** | 25/60 (41.7 %) | | **complex 49.0 %** |

**Roof type by footprint source (A+B, readable labels).** Recomputed from the labels plus the committed OSM-only
counts; Overture = pooled minus OSM.

| | OSM (10) | Overture (41) | Source-weighted (5.8 % / 94.2 %) |
|---|---|---|---|
| Heuristic | 2/10 (20 %) | 23/41 (56.1 %) | ≈ 54 % |
| Always "complex" | 8/10 (80 %) | 17/41 (41.5 %) | ≈ 44 % |
| Always "hip" | 0/10 | 16/41 (39.0 %) | |
| Label mix | complex 8, gable 2 | complex 17, hip 16, gable 7, flat 1 | |

The independent check's paired bootstrap of the Overture difference (heuristic minus always "complex") gives
+14.6 points, 95 % interval −10 to +37. That is not distinguishable from zero. On the 26 labelled non-complex
roofs (flat, gable or hip, the forms the generator draws), the heuristic gets 15 right and always "hip" 16.

**Colour rule set 2 per class, sample B (rule set 1 → rule set 2, correct / labelled):**
- charcoal 7/9 → 7/9;
- grey 9/12 → 7/12;
- brown 0/4 → 3/4;
- tan 0/1 → 0/1.

Net gain: +1 roof.

- **Can't-tell labels:**
  - colour 5 of 60, roof type 9 of 60. The 9 roof-type cases drop out of the roof-type figures; they are the
    shaded and canopied roofs.
  - Of the 9: 3 roofs were mostly under canopy, 3 in deep tree shadow, 2 half in shadow without visible facets,
    and 1 had a footprint covering only part of the roof.
  - Two footprints cut by the image edge left sample A in an early draw (decision 7).
- **Estimate "unknown":** 3 of 60.
- **Roof type by confidence (A+B):** 12/29 correct at ≥ 0.7, 13/22 below 0.7.
- **Roof type by size:** 5/7 under 50 m² (n = 7, about ±35 points) and 20/44 at 50 m² or more.
- **OSM-only (10 labelled):** colour rule set 1 5/10; rule set 2 7/10, but that includes the design sample A (A
  3/5, B 4/5); roof type 2/10.
- **Black and white are untested.** The labels contain 0 black and 1 white roof. All 3 roofs the rules called
  black were labelled charcoal.
- **Warm roofs:** 13 of 55 colour labels are brown or tan (23.6 %; about 24 % source-weighted). The estimates
  give 2.9 % (rule set 1) or 17.9 % (rule set 2) for the cell.

**Roof type confusion, A+B, 0.3 m** (rows: label, columns: estimate):

| label \ estimate | flat | gable | hip | complex |
|---|---|---|---|---|
| flat | | 1 | | |
| gable | 1 | 5 | 1 | 2 |
| hip | | 4 | 10 | 2 |
| complex | | 6 | 9 | 10 |

**Colour confusion, rule set 1, A+B, 0.3 m:**

| label \ estimate | black | charcoal | grey | unknown |
|---|---|---|---|---|
| charcoal | 3 | 11 | | |
| grey | | 4 | 22 | 1 |
| white | | | 1 | |
| brown | | 8 | 1 | |
| tan | | | 4 | |

**Colour confusion, rule set 2, sample B only (honest test):**

| label \ estimate | black | charcoal | grey | white | brown | tan | unknown |
|---|---|---|---|---|---|---|---|
| charcoal | 2 | 7 | | | | | |
| grey | | 2 | 7 | 1 | | 1 | 1 |
| brown | | 1 | | | 3 | | |
| tan | | | 1 | | | | |

**Resolution (0.6 m by 2 × 2 averaging of the same scene, A+B):**

| | 0.3 m | 0.6 m |
|---|---|---|
| Colour, rule set 1 | 60.0 % | 63.6 % |
| Roof type | 49.0 % | 39.2 % |
| Global shift found | 0.9 m E, 1.2 m S | 1.2 m E, 1.2 m S |

Colour doesn't need the finer pixels. Roof type gets worse at 0.6 m, the resolution of most NAIP years and
states.

**Canopy point check (92 readable points, 8 can't-tell):**

| | Mask: tree | Mask: not tree |
|---|---|---|
| Label: tree | 44 | 6 |
| Label: not tree | 8 | 34 |

- **Agreement:** 84.8 %, kappa 0.69. Always answering "tree" scores 54.3 %.
- **Bias:** the mask gives 56.5 % canopy at these points and the labels 54.3 %. So the mask slightly overstates
  canopy, through lawn next to crowns and tree-shadow edges.
- **Can't-tell points:** all 8 are mask = tree.
- **NDVI alone** (independent check): agreement drops to 80.4 % and false-tree points rise from 8 to 17. Its
  67.7 % cell "canopy" lies above the 64.5 % upper limit of the photo-interpreted interval. That supports the
  texture rule (decision 8).

## 6. Limits

- **One cell, one scene, one season, one labeller.** Thresholds in digital numbers (NIR texture 8, shadow 35)
  are tied to this scene's radiometry; NAIP colour balance varies by state, year and vendor. Rule set 2
  re-centres colour per scene, but its gain on fresh data was 1 roof in 26.
- **NAIP colour is not ground colour.**
  - Roof chroma is compressed (median C\* 4), dark roofs carry a blue cast and shadows are blue-grey.
  - Warm roofs (brown and tan shingles) are the main colour error, and they are underestimated.
  - Black and white were not tested.
- **Leaf-on imagery.** Trees hide parts of roofs and shade more. Leaf-off orthophotos from local programmes
  would help colour and type (not checked here: availability and licences unknown); NAIP is always flown in the
  growing season.
- **Lean and footprint fit.**
  - NAIP is not a true orthophoto, so roofs shift by a metre or more per storey away from the camera. One global
    shift helps on average.
  - Microsoft ML footprints are simplified rectangles, so the footprint-shape rules for "complex" rarely fire:
    23 of the 25 hand-labelled complex roofs sat on footprints with rectangularity ≥ 0.80.
- **Roof type from shading is fundamentally limited** at 0.3–0.6 m with a high July sun. Cross gables, dormers
  and multiple wings dominate the houses here, and the facet models only describe single-ridge and hip roofs.
- **Canopy method.**
  - The texture rule counts tree-shadow edges and lawn next to crowns.
  - Mask and photo interpretation agree within the interval, but per-block values carry about ±5–10 points of
    method error on top of the labeller's uncertainty.
  - Small clipped faces swing widely, so per-block values need an area floor (e.g. 1 ha) before use.

## 7. Better sources for roof type

- **USGS 3DEP lidar** (public domain; AWS bucket `usgs-lidar-public` as Entwine Point Tiles, not
  requester-pays, so bbox reads are possible).
  - **Coverage:** the TNM API lists project **`IL_4_County_QL1_LiDAR_2016_B16`** for this cell, delivery folder
    `IL_4County_Cook_2017`.
  - **Public EPT dataset:** **`USGS_LPC_IL_4County_Cook_2017_LAS_2019`**. Its `ept.json` (EPSG:3857, about 93.7
    billion points) has bounds that contain the cell centre (checked here).
  - **Density:** QL1 is at least 8 points/m², so about 1,000 or more points on a typical roof.
  - **Download size:** the LAZ delivery tiles are 130–157 MB each, so nothing beyond `ept.json` was downloaded.
  - **Method:** planar segmentation (RANSAC or region growing on roof points above ground) gives facet count,
    orientation and pitch. That is what gable, hip, flat and complex need, plus pitch for the profile's `pitch`
    ranges and real heights. This is the right source for per-building roof type.
  - **Date:** the acquisition year is unverified (the project name says 2016, the delivery folder 2017). Houses
    built since are missing either way.
  - **Since done (phase 5B):** the lidar pilot on South Evanston, in [lidar-roofs.md](lidar-roofs.md).
    - The flight was 2017-04-16 to 05-07 (FGDC metadata).
    - The EPT carries no return numbers.
    - Reading to octree depth 10 gives about 4 building points per m² (118 MB per km²).
    - On 30 hand-checked roofs the classifier gets the simple form right 26 times.
- **Overture `roof_shape`** is empty for all 384 Overture rows in the query box (cell + 30 m; 293 merged
  footprints have their centroid in the cell). Overture's heights (Microsoft ML, or USGS lidar for OSM buildings)
  are present for all of them and could feed floors, but not roof type.

## 8. Recommendation

**Feed the generator at profile level, not per building.**

**Trees** (new field needed: a per-zone canopy share or street-tree density; `trees` has none, see
`data-coverage.md` gap 4).
- **Supports:** a canopy share per zone from the NAIP mask, reported with the photo-interpreted check (here mask
  58 %, points 54 %, interval 44–65 %).
- **Per block:** use values only above an area floor (e.g. 1 ha).
- **Confidence: good.** 85 % per-point agreement (kappa 0.69), and the cell values agree within the interval.

**Roof colour slot** (4th entry of each `colors` tuple).
- **Supports:** the charcoal/grey split. Use a lightness mix only after a check of black and white roofs (none
  labelled black, 1 white), since the 10 % "black" is likely partly shadowed charcoal.
- **Warm share:** underestimated. The labels show 23.6 % brown or tan (about 24 % source-weighted), against 3–18 %
  estimated, so set it from labels, not from the rules.
- **Rendering:** use the family colours in `renderHex`, not the aerial medians.
- **Confidence:** medium for charcoal vs grey, untested for black and white, low (underestimated) for the warm
  share.

**Roof mix weights** (`roof` gabled/hipped/flat per house type).
- **Not from the heuristic.** It has not been shown to beat a constant, and its mix over-calls gable.
- **From photo interpretation instead:** the 51 readable hand-labelled roofs, source-weighted (OSM 5.8 %,
  Overture 94.2 %), give about complex 44 %, hip 37 %, gable 17 %, flat 2 % (±14 points). Unweighted they give
  49/31/18/2.
- **Missing roofs:** both mixes leave out the 9 can't-tell roofs (15 %), which are the shaded and canopied ones.
- **Mapping:** the generator's mix has no "complex", so complex roofs need a mapping decision, e.g. the dominant
  form.
- **Confidence:** photo interpretation medium; heuristic none.

**Per-building hints: not from NAIP for now.**
- **Roof type** has not been shown to beat a constant guess (n = 51; about ±20 points on the difference, and the
  Overture-only gain of +14.6 points has an interval spanning zero). Its confidence carries no signal, so no
  threshold makes it usable.
- **Colour** is right about 60 % of the time, or 74.5 % within one neighbouring family. That is plausible as a
  default but visibly wrong on about one house in four, and systematically wrong for warm roofs.

If per-building hints are wanted later:
- roof type from 3DEP lidar planes;
- colour only as a lightness family (charcoal, grey; black and white after a check), for roofs with usable share
  ≥ 0.8, i.e. colour confidence 1.0;
- one separate optional layer that user overrides replace.

Format proposed but not produced: `{"key": {"osm": "way/…"} | {"gers": "…"}, "roofColour": {"family", "hex",
"confidence"}, "roofType": {"value", "confidence", "method": "lidar-planes"|"naip-shading"}, "provenance":
{"imagery": "NAIP 2023-07-10 0.3 m, USDA FSA, public domain", "footprint": "osm"|"overture:Microsoft ML
Buildings", "tool": "regionkit-aerial 0.1"}}`. It would be generated at bake time for the baked area only and
never committed to the repository.

**Licensing** (a reading of the sources, not legal advice; see [licensing.md](licensing.md)).
- **NAIP:** USDA has placed it in the public domain and *requests* the credit "NAIP imagery provided by USDA Farm
  Service Agency" ("Please credit … on any use"; FGDC: "asks to be credited in derived products"). Honour it
  wherever derived values are used and add it to the credits list (licensing.md O13).
- **Profile-level statistics:** these are derived from NAIP pixels selected by OSM and Overture footprints, so
  they look like aggregates of the same kind as the region kit's existing OSM-derived profile statistics.
  Probably no obligation arises beyond the requested credit, but that is a judgement, not a settled answer. It
  belongs with the region-kit questions in licensing.md (O12 and section 9).
- **Per-building hints keyed by OSM ID or Overture GERS ID:** these add external observation data to ODbL
  features. That is not a trivial transformation (licensing.md **O12**), so the combined database would likely
  be a Derivative Database offered under ODbL. Public-domain NAIP doesn't conflict with that, but O12 has to be
  decided first, and provenance has to be kept per value (the format above does).

## 9. Decisions (conservative choices not covered by the brief)

1. **Footprints:** OSM plus Overture buildings with no OSM source (Microsoft ML, ODbL), source recorded per
   footprint, OSM-only reported separately. OSM alone has 19 buildings in the cell.
2. **Imagery:** the newest NAIP at the cell is 0.3 m (2023), finer than the ~0.6 m the brief expected. The 0.6 m
   question was answered by block-averaging the same scene, with no second download.
3. **Cell:** 500 m square in the tile's UTM grid around the park anchor already resolved in
   `regions/chicagoland.json`.
4. **Alignment:** one global footprint shift for the whole cell, not per building, to avoid overfitting.
5. **Colour rules:** rule set 1 frozen before labelling. One dark-cast rule was added after seeing aggregates and
   before scoring; the version without it scores the same, also reported. Rule set 2 was designed on sample A
   after scoring and tested on a fresh sample B instead of being reported on A alone.
6. **Sample:** at least 5 OSM buildings per sample (proportional would be 2) so OSM results exist. Sample B
   excludes sample A. This over-weights OSM, so per-source and source-weighted figures are reported.
7. **Sample A redraw:** the first draw included two footprints cut by the image edge, which can't be estimated.
   Eligibility was fixed to match the estimator and the sample redrawn mid-labelling. Labels were keyed by ID:
   the 5 finished labels were kept and 1 was dropped.
8. **Canopy:** NDVI plus NIR texture rather than NDVI alone, which would count lawns as canopy. NDVI alone gives
   67.7 %, above the photo-interpreted interval; it agrees 80.4 % per point and has 17 false-tree points against
   8. Thresholds were set on the overview before the point check.
9. **Blocks:** faces of street centrelines, so street trees count; faces closed by the cell edge reported
   separately.
10. **Pixel thresholds became areas** (5.4 m²) so the 0.6 m rerun is fair. This changes nothing at 0.3 m.
11. **"Mostly hidden" (estimate):** more than 50 % of footprint pixels with NDVI > 0.2. This also counts footprints
    that sit partly on lawn.
12. **Privacy floor:** any committed per-family or per-group statistic over fewer than 5 buildings is reported as
    its count only (`params.json` `minGroupN`, `roofcore.suppress_small`). This applies to median colours,
    colour percentiles and footprint vegetation percentiles. Block canopy values are area aggregates and stay.
    The committed `summary.json` was regenerated without a re-run by a script that applies `suppress_small`
    exactly where `aerial.py` now does: 35 statistics suppressed (n = 1: 16, n = 2: 12, n = 3: 3, n = 4: 4).
    `accuracy.json` contains no colour values.
13. **Neighbour-family denominator:** `withNeighbourFamilies` in `accuracy.json` now uses the same denominator as
    the exact figure (estimate "unknown" counts as wrong). The committed file was re-based from its own counts by
    the same script; a fresh `score` writes the same values.

## 10. Bytes downloaded

| What | Bytes |
|---|---|
| NAIP COG byte ranges (GDAL log sum, 9 requests) | 18,580,724 |
| Overture GeoParquet (DuckDB HTTP log, 1 file of release 2026-09-23.1) | 3,950,552 |
| Overture STAC (collection + 1 item) | 111,697 |
| Overpass (1 request; one earlier attempt got HTTP 429 and backed off 65 s) | 75,008 |
| Planetary Computer STAC search + SAS token | 23,960 |
| **Pipeline data total** (`summary.json` → `bytesDownloaded`) | **22,741,941** |
| Exploration before the tool (catalog and licence pages, NAIP Plus metadata, FGDC metadata, TNM lidar query) | ≈ 0.57 MB |
| Revision checks (SAS token, NAIP HEAD request, lidar `ept.json`) | ≈ 3 KB |
| DuckDB `httpfs` extension (16,030,718 bytes on disk) | ≤ 16.0 MB |
| Python wheels (numpy, pillow, shapely, rasterio, duckdb and 5 small deps), installed twice (CPython 3.12, then 3.14); numpy once more for the revision's tests | ≈ 2 × 49.5 MiB + 5.2 MiB ≈ 109 MB |
| CPython 3.12 build fetched by uv by mistake, uninstalled again | ≈ 20 MB (estimate) |
| **Total** | **≈ 168 MB** (limit 500 MB) |

## 11. How to re-run

From the repository root, with the work directory outside the repository:

```sh
UV_CACHE_DIR=/tmp/aerial-uv UV_PYTHON_DOWNLOADS=never uv run --no-project --python python3 \
  --with numpy --with pillow --with shapely --with rasterio --with duckdb \
  python Tools/regionkit/aerial/aerial.py all --work /tmp/aerial-work
```

- **Data:** this re-fetches about 23 MB (plus wheels and the 16 MB DuckDB extension on first run) and rewrites
  `results/summary.json`.
- **Reproducibility:** rerunning from cached data reproduced every aggregate exactly, and the independent check
  reproduced `accuracy.json` byte for byte. The revision's two output rules (privacy floor, neighbour
  denominator) were applied to the committed files by a script using the same code; see decisions 12–13.
- **Accuracy:** needs the hand labels. `crops`, `crops --set B` and `points` regenerate the crops for
  re-labelling.

## 12. Sources and dates

- USDA NAIP, Illinois 2023 (acquired 2023-07-10, 0.3 m, RGBN), via Microsoft Planetary Computer STAC `naip`,
  read 2026-10-06.
  - Licence: TIFF `ImageDescription`; FGDC metadata `m_4208759_nw_16_060_20190802.txt`;
    [USDA FSA Policies and Links](https://www.fsa.usda.gov/help/policies-and-links).
- [USGS NAIP Plus ImageServer](https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer)
  (catalog checked 2026-10-06).
- OpenStreetMap via Overpass API (`timestamp_osm_base` 2026-10-06T06:48:49Z), ODbL 1.0,
  © OpenStreetMap contributors.
- Overture Maps buildings, release 2026-09-23.1 (STAC `https://stac.overturemaps.org/catalog.json`), ODbL;
  footprints from Microsoft ML Building Footprints.
- USGS 3DEP:
  - [TNM Access API](https://tnmaccess.nationalmap.gov/api/v1/products): project
    `IL_4_County_QL1_LiDAR_2016_B16`, delivery `IL_4County_Cook_2017`, listed 2026-10-06.
  - EPT `s3://usgs-lidar-public/USGS_LPC_IL_4County_Cook_2017_LAS_2019/ept.json`, checked 2026-10-06.
  - [AWS registry: USGS 3DEP LiDAR Point Clouds](https://registry.opendata.aws/usgs-lidar/) (public domain).
- Cross-references: [licensing.md](licensing.md) (O12, O13, V1), [data-coverage.md](data-coverage.md) (gap 4),
  [region-kit.md](region-kit.md).

## 13. Canopy share of the committed test areas (phase 5B)

Added 2026-10-06 for the profiles' new optional `trees.canopyShare` field (`docs/style-profiles.md`: "measured share (0–1) of the ground covered by tree crowns, zone level, from leaf-on aerial imagery"). Tool: `Tools/regionkit/aerial/canopy_areas.py` (data `data/canopy_areas.json`, results `results/canopy_areas.json`). It reuses this study's NAIP access and the unchanged canopy mask (NDVI > 0.2 and NIR texture > 8 DN over 1.5 m, opening and majority 0.9 m).

**Areas and imagery.**
- **Areas:** each committed area's own rectangle (manifest centre and size), laid out in the NAIP item's UTM grid.
- **Streets, parks and water:** from the committed `osm.json`, so no Overpass request was made.
  - Parks are public open space polygons of at least 1,000 m²: `leisure` park, pitch, playground, garden and similar; `landuse` recreation ground, cemetery, forest or village green; `natural=wood`.
  - `landuse=grass` is not a park: Sloan's Lake maps 1,551 lawn and parkway polygons, and their street trees belong to the residential fabric.
- **Imagery:**

| Area (profile) | NAIP item(s) | Acquired | GSD | Window read |
|---|---|---|---|---|
| South Evanston (`evanston`) | `il_m_4208759_sw_16_030_20230710_20240209` | 2023-07-10 | 0.3 m | 54.3 MB of COG ranges |
| Lakeview, Sheil Park (`chicago-dense-north`) | `il_m_4108703_ne_16_030_20230710_20240209` | 2023-07-10 | 0.3 m | 56.9 MB |
| Sloan's Lake, Denver (`front-range`; 1.6 × 1.2 km) | `co_m_3910524_ne_13_030_20230925_20240104` + `co_m_3910516_se_13_030_20230925_20240104` (mosaic of two quarter-quads) | 2023-09-25 | 0.3 m | 120.2 MB |
| Wilmette, Vattmann Park (`wilmette`; P2's new test area, added after its merge) | `il_m_4208759_nw_16_030_20230710_20240209` (the study cell's quarter-quad) | 2023-07-10 | 0.3 m | 56.3 MB |

- The newest acquisition at each area is 2023. Older years at the same places: Illinois 2011–2021, Colorado 2011–2021.
- Colorado 2023 is also 0.3 m. Its late-September date is still leaf-on in the scene, but its radiometry differs from the Illinois scene the texture threshold was set on (see the point check).

**Canopy share (mask):**

| Area | Whole area | Land (no water) | **Residential fabric** (no parks, no water) | In parks | Parks / water share of the area | Vegetation incl. lawns (fabric) |
|---|---:|---:|---:|---:|---|---:|
| South Evanston | 46.2 % | 46.2 % | **47.3 %** | 26.9 % | 5.6 % / 0 % | 60.8 % |
| Lakeview (Sheil Park) | 17.8 % | 17.8 % | **17.8 %** | 19.8 % | 0.5 % / 0 % | 22.5 % |
| Sloan's Lake | 14.9 % | 23.5 % | **24.8 %** | 21.4 % | 22.8 % / 37.3 % | 42.6 % |
| Wilmette (Vattmann Park) | 53.7 % | 53.7 % | **55.1 %** | 33.9 % | 6.9 % / 0 % | 64.2 % |

**Block faces.**
- Faces are polygonised OSM street centrelines plus half the right-of-way, as in section 3.
- "Residential" faces: at least 1 ha, with under 10 % park or water.
- Faces closed by the area edge are included in "all", not in "complete".

| Area | All faces: n, area-weighted | Complete faces: n, area-weighted, p10–p90 | Residential faces ≥ 1 ha: n, area-weighted, p25–p75 |
|---|---|---|---|
| South Evanston | 52, 46.2 % | 29, 50.1 %, 38.5–61.3 % | 34, 47.6 %, 41.1–55.8 % |
| Lakeview (Sheil Park) | 68, 17.8 % | 37, 19.6 %, 4.6–26.6 % | 51, 18.3 %, 12.8–21.5 % |
| Sloan's Lake | 68, 14.9 % | 37, 28.4 %, 19.5–35.9 % | 39, 24.7 %, 19.6–32.1 % |
| Wilmette (Vattmann Park) | 46, 53.7 % | 19, 57.1 %, 50.6–70.5 % | 29, 56.9 %, 54.3–60.8 % |

**Photo check** (50 stable random points per area inside the image; 15 m patches with a crosshair; labelled before the mask was looked at; same labeller and caveats as section 5):

| Area | Readable | Agreement | Labels: canopy (95 % interval) | Mask at the same points | Mask misses / false tree |
|---|---:|---:|---|---:|---|
| South Evanston | 43 of 50 | 86.0 % | 53.5 % (38.9–67.5 %) | 48.8 % | 4 / 2 |
| Lakeview (Sheil Park) | 47 | 87.2 % | 31.9 % (20.4–46.2 %) | 23.4 % | 5 / 1 |
| Sloan's Lake | 46 | 91.3 % | 19.6 % (10.7–33.2 %) | 15.2 % | 3 / 1 |
| Wilmette (Vattmann Park) | 42 | 73.8 % | 47.6 % (33.4–62.3 %) | 50.0 % | 5 / 6 |

- In Evanston, Lakeview and Sloan's Lake the mask is below the labels at the points; in Wilmette it is 2 points above, as in the Wilmette study. Pooled over the four checks: 17 missed tree points against 10 false ones (n = 178 readable).
- Wilmette's agreement (74 %, n = 42) is lower than the study's 85 % (n = 92); the causes were not analysed.
- Each area's interval is ±12–14 points, so the checks support the mask values but cannot fix a correction factor.
- 16 of Sloan's Lake's points fell on the lake.

**Recommended `trees.canopyShare`.** Use the residential-fabric share: parks and water have their own surfaces in the generator, and street and yard trees belong to the fabric.

| Profile | Value | Reasoning |
|---|---:|---|
| `evanston` | **0.47** | Fabric 47.3 % (whole area 46.2 %; complete blocks 50 %). The parks (Crown, Grey, Larimer: 5.6 % of the area) are less wooded (27 %), so they lower the whole-area value slightly rather than inflate it. Point check 53.5 % (39–68 %). |
| `chicago-dense-north` | **0.18** | Fabric = whole area = 17.8 %; residential blocks 18.3 %. **The park does not inflate it:** Sheil Park is a polygon of about 1,609 m² in OSM (way 203672734; the 1,739–1,740 m² polygon is Margaret Donahue Park), the parks of at least 1,000 m² total about 4,550 m² (0.46 % of the area, shown as 0.5 %), and their canopy (19.8 %) matches the fabric. The point check reads higher (31.9 %, interval 20–46 %); with 5 of 15 tree points missed, the true value may be 0.20–0.25. The coordinator may round up, but the measured mask is 0.18. |
| `front-range` | **0.25** | Fabric 24.8 %, residential blocks 24.7 %, land 23.5 %. The whole-area 14.9 % is deflated by Sloan Lake (37 % of the area) and must not be used. Caveat: one inner-city neighbourhood with mature trees stands for a profile that covers Colorado Springs to Fort Collins, and newer suburbs will be far lower. The Illinois texture threshold was not re-tuned for this scene (point check 91 %, mask slightly low). |
| `wilmette` (was 0.58; the profile now has 0.55) | **0.55** | The committed 1 km² test area (P2, same park anchor) gives fabric 55.1 % (whole area 53.7 %, residential blocks 56.9 %). The earlier 0.58 is the whole-cell mask of the 0.25 km² study cell (section 4), a smaller and more wooded window. Use 0.55 for the same definition as the other profiles (the profile now does); keeping 0.58 would have been within the method error too. |

**Bytes:** NAIP COG ranges 287,689,177 + STAC searches 135,028 + SAS tokens 1,602 = **287.8 MB** (`results/canopy_areas.json` `bytesDownloaded`; Wilmette 56.3 MB of it). No Overpass or Overture requests.

### 13.9 Per-block canopy and tree spacing (`Data/areas/<id>/canopy-blocks.json`)

Added 2026-10-06 as the "area profile" data for the yard and street-tree generator. Written by `canopy_areas.py blocks` (reuses the NAIP windows and the unchanged canopy mask of this section; pure functions in `blockmath.py`, offline tests `tests/test_blockmath.py`). Aggregates per block only: no per-house values, no imagery. Six areas: evanston-south, lakeview-sheil-park, sloans-lake, wilmette-vattmann-park, plus (calibration step, 13.10) winnetka-village-green and kenilworth-station. Method version `canopy-blocks 1` (evanston, lakeview, sloans-lake) uses the lidar crown below as divisor; `canopy-blocks 2` (wilmette, winnetka, kenilworth) uses a calibrated effective crown area and adds a `calibration` header object (13.10).

**File.** A header plus a `blocks` array (one line per block, sorted by id).
- Header: `format` (`worldengine-canopy-blocks 1`), `area`, `profile`, `methodVersion` (`canopy-blocks 1`), `naip` (item ids, acquisition date, `gsdMeters`, `credit` "NAIP imagery provided by USDA Farm Service Agency", licence: public domain), `canopyMethod`, `blockSource`, `crown` (mean and range of crown plan area, source), `confidenceBasis`, `osmTimestamp`, `blockCount`.
- Block fields: `id`, `lat`, `lon` (centroid, 5 decimals), `areaM2`, `landAreaM2` (face minus water), `frontageM`, `edgeCut`, `parkOrWaterPct`, `waterPct`, `canopyShare` (0-1, of the land area; `null` below 500 m² of land), `trees`, `treesPerHa`, `treesPerHaRange`, `gridSpacingM`, `frontageSpacingM`, `confidence` (0-1), `confidenceTier`, `bounds` (number of bounding street ways). The tree fields are absent when the block has no canopy.

**Block id.** `cb-` plus the first 8 hex digits of SHA-256 over the sorted OSM way ids of the street ways that bound the face (a street way bounds a face when at least 5 m of the face boundary lies within 0.5 m of it). It does not depend on geometry, the area window or block order, so it changes only when the street network around the block changes. Faces bounded by the same way set get `-2`, `-3` in order of descending area. Faces are the polygonised street centrelines clipped to the area rectangle (as above); faces under 500 m² (slivers cut by the window edge) are omitted.

**Tree estimate.** Per block, with `crown` the lidar mean non-overlapping crown plan area per tree (lidar-roofs.md 13.4: Evanston 112 m², Wilmette 108, Lakeview 105 clear of buildings (92 for all detected trees); Sloan's Lake has no lidar run and borrows 108, the mean of the three):
- `trees` = canopyShare × landArea / crown.
- `treesPerHa` = canopyShare × 10,000 / crown. `treesPerHaRange` uses the lidar spread 112 to 92 m².
- `gridSpacingM` = sqrt(10,000 / treesPerHa): the tree-to-tree distance on a square grid.
- `frontageSpacingM` = frontageM / trees, where frontageM is the length of the face boundary that lies on streets. It is the spacing of a single street-tree row that alone would produce the block's canopy, so it is a lower bound on real street-tree spacing (most trees are in yards). Absent for fewer than one tree.

Assumptions and caveats:
- Leaf-on NAIP canopy merges touching crowns, so the count is canopy cover divided by the mean crown the lidar found, not a tree detection. Cross-check against the lidar counts (lidar-roofs.md 13.4): Evanston 40.7 trees/ha median over residential blocks against 37.6 detected, so it fits; Wilmette 55 against 36.8, which looked like 1.4 times too high but was recalibrated in 13.10 (hand counts and point checks put it at 45 to 50, about 1.1 times high, not 1.4); Lakeview 18 against 18.5 to 25.2.
- The 2017 lidar crowns are leaf-off and older than the 2023 NAIP; Denver's crown size is an assumption.
- The mask is a lower bound where trees overhang buildings, and the point checks put it 2 to 8 points under the labels in three areas (above); this is not corrected.

**Confidence.** Basis: the photo check above, 85 % agreement per point overall (Evanston 86.0 %, n = 43; Lakeview 87.2 %, n = 47; Sloan's Lake 91.3 %, n = 46; Wilmette 73.8 %, n = 42). Per block, `confidence` = area point agreement × size × edge × park/water. These are heuristics, not a measured per-block accuracy:
- size = min(1, sqrt(area / 10,000 m²)), at least 0.5 (faces under 1 ha);
- edge = 0.85 when the face is cut by the area window (`edgeCut`);
- park/water = 0.80 when at least 10 % of the face is park or water.

Tiers: `high` at 0.75 or more, `medium` at 0.6 or more, otherwise `low`. The header carries the area's agreement, so a consumer can rescale. Wilmette's tiers use the agreement of the fresh calibration check (75.9 %, n = 108; the earlier check gave 73.8 %, n = 42, and no `high` block); Winnetka's use 93.2 % (n = 44) and Kenilworth's 86.7 % (n = 45).

| Area | Blocks (edge-cut) | Canopy p10 / median / p90 (complete residential faces, n) | Trees per ha | Grid spacing (m) | Frontage spacing (m) | Tiers high / medium / low |
|---|---|---|---|---|---|---|
| South Evanston | 50 (21) | 0.38 / 0.46 / 0.59 (28) | 34 / 41 / 53 | 13.5 / 15.0 / 17.0 | 4.7 / 6.3 / 7.9 | 28 / 10 / 12 |
| Lakeview (Sheil Park) | 68 (31) | 0.14 / 0.19 / 0.26 (32) | 13 / 18 / 25 | 19.7 / 23.2 / 27.1 | 11 / 17 / 23 | 32 / 25 / 11 |
| Sloan's Lake | 67 (30) | 0.20 / 0.28 / 0.35 (31) | 18 / 26 / 33 | 17.5 / 19.5 / 23.5 | 12 / 14 / 19 | 50 / 11 / 6 |
| Wilmette (Vattmann Park), `canopy-blocks 2`, calibrated | 44 (25) | 0.55 / 0.60 / 0.65 (14) | 45 / 50 / 54 (was 50 / 55 / 59) | 13.7 / 14.2 / 14.8 | 4.3 / 5.4 / 6.2 | 14 / 19 / 11 |
| Winnetka (Village Green), `canopy-blocks 2` | 53 (26) | 0.44 / 0.67 / 0.74 (24) | 47 / 72 / 79 | 11.2 / 11.8 / 14.6 | 3.7 / 4.2 / 6.2 | 39 / 4 / 10 |
| Kenilworth (station), `canopy-blocks 2` | 50 (27) | 0.50 / 0.62 / 0.68 (16) | 46 / 58 / 63 | 12.6 / 13.2 / 14.8 | 3.9 / 4.6 / 6.6 | 16 / 15 / 19 |

"Complete residential" = at least 1 ha, not edge-cut, under 10 % park or water. All other faces are in the files.

**Bytes.** The NAIP windows were read again for this step: 287,689,177 bytes of COG ranges (plus STAC and token calls), as in the section above; no Overpass or lidar requests.

### 13.10 Calibration of the tree count: Wilmette, then Winnetka and Kenilworth

Added 2026-10-06. The question: are the Wilmette block counts (about 55 trees/ha, from NAIP canopy over the lidar crown of 108 m²) really about 1.4 times too high against the lidar tree-top count (36.8/ha)? Tool: `canopy_areas.py` (per-area `calibration` and `crownAreaM2` in `data/canopy_areas.json`) and the pure functions of `blockmath.py` (Wilson interval, ratio estimator, cluster bootstrap, paired difference, effective crown area; tests in `tests/test_blockmath.py`). All labelling and counting is by one labeller, from 0.3 m NAIP crops kept in scratch (not committed); the lidar tops are those of `Tools/regionkit/lidar/trees.py` (same settings, EPT depth ≤ 10).

**Result.**
- **Corrected Wilmette estimate: 45 trees/ha over the built fabric** (45.5; bootstrap over the 14 plots 42–49; 95 % range 39–54 when the spread between the hand count and the lidar count is added). Before: 51 at the fabric canopy share (block median 55). Block medians now 50 (p10–p90 45–54) instead of 55 (50–59).
- The "1.4 times too high" reading was partly a lidar undercount. The lidar count (36.8) is a lower bound for true trees; in the same plots the hand count is 1.19 times the lidar tops (189 against 159; bootstrap of the ratio 1.07–1.32). The NAIP-based count was about 1.1 times high (51 against 45), not 1.4. The raw lidar number is 0.81 of the corrected value.
- **Confidence: medium.** The sampling interval is ±7 %; the difference between the two ways of counting is ±20 %; the labeller is one person; dense plots (merged crowns) are counted with an uncertainty of about 25 %. The block values are therefore good to roughly ±15 % as a group, and no better than that for single blocks.

**Method.**
1. **Point check** (fresh stable sample: 120 points over the built fabric, SHA-256 seeded, a seed different from the 5B check; 15 m patches with a crosshair; labelled before the mask was looked at; tree = the crosshair lies under a tree crown, a shadow without foliage is not a tree; 12 unreadable). Of 108 readable points, 53 are tree (**49.1 %**, Wilson 39.8–58.4 %) while the mask says tree at 65 (60.2 %). Agreement 75.9 %; 7 missed tree points, 19 false ones. Paired difference label minus mask: **−11.1 points** (bootstrap −20.4 to −1.9). Applied to the mask's fabric share of 55.1 %, the label-corrected canopy is **about 0.44 (0.35–0.53)**.
   - All 19 false points were reviewed on a mask-outline sheet: about 10 are tree shade on pavement, lawn or between houses, which the mask takes as canopy; the rest sit at crown edges or on small shrubs and hedges.
   - Pooled with the 5B check (42 readable points, mask 2 points above the labels), the mask is 8.7 points above the labels (n = 150). The labeller's treatment of shade explains most of the difference between the two checks, so the size of the over-call is uncertain.
   - **Not applied.** The block `canopyShare` stays the mask value, so it stays comparable with the profiles and the other areas. The label-corrected share is recorded in the header and in `results/canopy_areas.json`. Whether `trees.canopyShare` of the `wilmette` profile (0.55) should fall to 0.44 is left to the owner; the other profiles were measured with the same mask and may also be a few points high, but the evidence is not clear enough to change them.
2. **Plots** (14 non-overlapping 50 m × 50 m squares, at least 95 % built fabric, stable random). Trees whose crown centre lies in the box were counted twice: by eye on the NAIP crop (before the lidar was looked at), and as kept lidar tree tops (leaf-off 2017, lidar-roofs.md 13.3). Counts per plot: eye 9–20, lidar 6–16; mask canopy 0.40–0.82. Eye total 189, lidar total 159 over 3.5 ha (54 and 45 trees/ha; the plots have a mean mask canopy of 60 % against the area's 55 %).
   - Where the plots disagree, the eye count is higher (plots 5, 6, 7, 10, 12, 13, 14: small ornamental, understory and shaded trees, crowns merged under a taller one); where the crowns are separate the counts agree.
   - The eye count may over-split multi-stem trees and big shrubs; the lidar count drops tops by its roof-clutter, thickness and point-count rules. Truth is taken as lying between them.
3. **Effective crown area** = mask canopy area of the plots / trees. This is not a crown size: leaf-on crowns overlap, and the mask also takes in some shade. It converts this mask's canopy area into a tree count, so the mask's over-call of shade cancels (the plots and the blocks use the same mask).

| Count used | Effective crown (m²) | Bootstrap over plots | Trees/ha (fabric mask 55.1 %) |
|---|---:|---|---:|
| Hand count | 111.7 | 101.3–123.1 | 49.4 (44.8–54.4) |
| Lidar tops | 132.7 | 125.5–142.6 | 41.5 (38.7–43.9) |
| **Mean of the two (used)** | **121.3** | 113.6–130.0 | **45.5 (42.4–48.6)** |
| Before (lidar crown, nothing else) | 108 | | 51.1 |

   - Applied as `crownAreaM2` 121 and `crownRangeM2` 101–143 (the extremes of the two rows), so `treesPerHaRange` of the blocks is 39–54 at the fabric canopy share.
   - Cross-check with a different estimator: whole-area lidar tops (36.8/ha) × the hand/lidar ratio of the plots (1.19) = 43.7/ha, inside the interval.
   - Canopy does scale roughly linearly with the count over the plots (about 21 trees per 50 m plot per unit of mask canopy), so a single factor is reasonable; the plots are too few to test a curve.

**Winnetka and Kenilworth (coverage).** NAIP `il_m_4208759_nw_16_030_20230710_20240209` (acquired 2023-07-10, 0.3 m; the same quarter-quad covers the Wilmette, Kenilworth and Winnetka areas, so no mosaic), canopy method unchanged. 1 km² each, streets, parks and water from the committed `osm.json` (no Overpass request).

| | Winnetka (Village Green) | Kenilworth (station) |
|---|---|---|
| Blocks (edge-cut), `canopy-blocks 2` | 53 (26) | 50 (27) |
| Canopy, whole area / land / fabric | 54.9 % / 58.2 % / 58.2 % | 58.1 % / 58.1 % / 58.3 % |
| Parks / water of the area | 1.8 % / 5.6 % (Lake Michigan) | 3.0 % / 0 % |
| Canopy of complete residential blocks, p10 / p50 / p90 (n) | 0.44 / 0.67 / 0.74 (24) | 0.50 / 0.62 / 0.68 (16) |
| Trees per ha | 47 / 72 / 79 | 46 / 58 / 63 |
| Grid spacing (m) | 11.2 / 11.8 / 14.6 | 12.6 / 13.2 / 14.8 |
| Photo check, 50 stable random points | 44 readable (6 unreadable: 3 on the lake), agreement 93.2 %, labels 50.0 % (35.8–64.2 %), mask at the points 52.3 % | 45 readable, agreement 86.7 %, labels 35.6 % (23.2–50.2 %), mask at the points 48.9 % (6 false tree points, 0 missed: shade again) |
| Effective crown used | 93 m² (6 plots, eye 122 trees; eye-only 85.6, bootstrap 80.9–89.9) | 108 m² (6 plots, eye 97 trees; eye-only 99.4, bootstrap 90.8–110.3) |
| Confidence (block tiers high / medium / low) | 39 / 4 / 10 | 16 / 15 / 19 |

- **Calibration where justified.** Neither town has a lidar run here. Each got six 50 m plots counted by eye, and the eye-only effective crown was multiplied by Wilmette's mean-to-eye ratio (121.3 / 111.7 = 1.086) to put it on the same basis. Winnetka's eye-only value (85.6) lies outside Wilmette's interval (101–123), so Wilmette's 121 would not transfer: its lots hold more and narrower crowns (spruce rows, dense mixed woods). Kenilworth's interval overlaps Wilmette's; its own value is kept because six plots cannot tell the two apart. Ranges use Wilmette's ratios (0.835 to 1.18 around the estimate).
- **Confidence is lower than the point checks suggest.** Six plots per town give an interval of only ±5–10 % on the effective crown, but the crowns of the dense plots were hard to separate (±25 %). Treat Winnetka and Kenilworth tree counts as about ±25 %. Winnetka's mask agrees with the labels (93 %); Kenilworth's reads about 13 points above them.
- Winnetka's file includes Lake Michigan: the 5.6 % of the area that is water is left out of every block's land area (one lake-edge block has `waterPct` 37.6).

**Other areas.** No change.
- Evanston: block median 41 trees/ha against lidar tops 37.6. The hand-to-lidar ratio of Wilmette (1.19) would put the lidar-based figure at 45 and the NAIP-based one lies between the two.
- Lakeview: 18 against 18.5–25.2 (all-trees to clear-of-buildings).
- Sloan's Lake has no lidar run.
- Their crown areas came from lidar tops directly, so the same undercount would make the counts slightly low, not high; the evidence from one town is not enough to apply a correction. The mask's shade over-call (11 points in Wilmette, 13 in Kenilworth) did not show in 5B for these three areas (the mask was below the labels at the points there), so it may depend on the labeller or the scene.

**Bytes.** NAIP COG ranges 141,943,325 + STAC and SAS 71,874 (three areas, 0.3 m); lidar EPT depth ≤ 10 for Wilmette 131,698,496 (reproduces the 0.41 crown share and 36.8/ha of lidar-roofs.md 13.4); total 273,713,695 (`results/canopy_areas.json` `bytesDownloadedCalibrationRun`). No Overpass or Overture requests. Scratch crops and plot images were deleted.
