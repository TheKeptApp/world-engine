# A1 data lane

Earlier entries below are historical; this batch supersedes their execution order and hold-out restrictions.

## Overnight batch — 8 October 2026

Plan: unchanged cached-survey height measurement → roofs → native 1 m and distance DEM, in Sloan / Lakeview / West Highland order; then identical building and terrain QA. Only GREEN USGS data and ODbL OSM footprints. Missing values stay null; derived classifications remain labelled, uncalibrated grade D. No look changes. Disk: 83 GiB free (8 GB minimum).

The earlier terrain handoff merge conflicted with A3 facade filing. Rebase aborted safely; work preserved on astra-a1-overnight-data, merging deferred until batch checks finish. West Highland has no saved fixed rectangle or manifest; its steps must stop for missing input rather than invent boundaries. No Mac 2 host is exposed.

| Area | Step | Coverage | Quality / gaps | Licence |
|---|---|---|---|---|

# A1 data lane — R, 8 October 2026

Approved Greenville rectangles and 100 m processing buffers are saved in `Data/planned-areas/greenville-approved.json`. Processing is on HOLD by R. These are planned areas, not loaded area manifests.

## Current order
1. Sloan's Lake lidar building heights and A–D grades.
2. Sloan's Lake roof form, pitch and ridge direction; P2 handoff.
3. Sloan's Lake true 1 m elevation DEM plus coarse Front Range distance bands; 5A handoff.
4. Denver assessor year-built: verify YELLOW licence; storeys excluded while RED.
5. Sloan's Lake data QA.
6. Validate deferred full-GERS draft `952c16a` on `astra-a1-data` when the heavy lock is free.
7. Lakeview and Greenville later; Greenville processing still needs authorization.

## Height plan
Use USGS CO_DRCOG_2_2020 lidar, same-survey class-2 ground and supported roof samples. Preserve missing records and diagnostics; store provenance, datum, original units and methods. Uncalibrated records grade D; A–C require independent calibration. No arbitrary height fill. Verify under the heavy lock, then merge this task separately.

References: `docs/research-gpt/building-heights-v1/`, `Tools/regionkit/terrain/data/areas.json`, `docs/research-gpt/data-licence-check-v1/`; mountain-terrain-v1 reference in the owner-supplied drop folder. Render/look/water code is outside A1 scope.

## Height extraction result (verification pending)
Full-density 2020 survey: 204 EPT nodes, 56,764,086 compressed bytes. No class-6 returns exist in the area. Conservative planar class-1 candidates yield 407/1,399 heights (29.1%), all grade D, 2.348–10.377 m. Remaining 992 heights are null; 888 footprints fail planar support, 99 have too few elevated points, and downstream footprint/coverage gates reject another five candidates. No independent accuracy claim. Full lidar suite is queued under the shared heavy lock; no merge before it passes.
Hold-outs: not processed this turn (R deferred Lakeview/Greenville and expressly prohibited Greenville processing); no hold-out quality claim. General pipeline configuration controls the authorized area.

| sloans-lake | heights | 29.1% | 407/1399; 992 null; all D, uncalibrated; 2020-05-26 to 2020-06-12 | GREEN |

| sloans-lake | roofs | 29.1% | 407/1399; 992 null; inferred classification, all D | GREEN |

Batch method note: cached full-density survey measurement and roof classification are rerun unchanged. Existing native DEM clips and all distance bands are reused only after full digest, resolution, mask, finite-value and envelope read-back checks under the heavy lock. Denver Front Range bands are stored once in the Sloan elevation package; no duplicated backdrop is generated. Heights are derived observations, roof types/ridges are inferred classifications; all retain survey dates and grade D. No null is filled. Building QA flags small/sliver footprints, missing/zero/invalid or repeated heights, inconsistent eaves, and roof/height/source mismatches. Geometry checks operate on the existing reader output (including its generic polygon repair), not an independent footprint survey.
