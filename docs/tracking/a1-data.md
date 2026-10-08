# A1 overnight map data — 8 October 2026

Status: partial; West Highland blocked on missing fixed boundary and manifest. Other steps are recorded individually below.

## Plan and scope

Same pipeline and parameters for Sloan’s Lake, Lakeview and West Highland: heights → roofs → native 1 m DEM, then identical building and terrain QA. Existing full-density caches used for heights/roofs; existing DEM packages reused after complete read-back validation. Denver Front Range distance bands are stored once in the Sloan package. No per-block code, hand fixes, render/look/generator changes or inferred height fills. Mac 2 is not exposed as a connected host; batch ran locally. Disk started at 83 GiB, minimum guard 8 GB.

Source: USGS 3DEP CO_DRCOG_2020_B20 (Denver, 2020) and IL_4_County_QL1_LiDAR_2016_B16 (Lakeview, acquired 2017), GREEN public-domain lidar and DEM; OSM footprints under ODbL with attribution retained. Heights use ground from the same survey. All supported heights/roofs remain uncalibrated grade D. Roof forms/ridges are inferred classifications, not independently confirmed observations. Dates remain in source metadata; these are not live data.

## Step ledger

| Area | Step | Coverage | Quality / gaps | Licence |
|---|---|---|---|---|
| sloans-lake | heights | 29.1% | 407/1399; 992 null; all D, uncalibrated; 2020-05-26 to 2020-06-12 | GREEN |
| sloans-lake | roofs | 29.1% | 407/1399; 992 null; inferred classification, all D | GREEN |
| lakeview-sheil-park | heights | 93.5% | 2618/2799; 181 null; all D, uncalibrated; 2017-04-16 to 2017-05-07 | GREEN |
| lakeview-sheil-park | roofs | 91.6% | 2563/2799; 236 null; inferred classification, all D | GREEN |
| west-highland | heights | N/A | BLOCKED: fixed area boundary and manifest missing | NOT LOADED |
| west-highland | roofs | N/A | BLOCKED: fixed area boundary and manifest missing | NOT LOADED |
| all | lidar-tests | N/A | PASS; 126 tests, 3 skipped | GREEN |
| all | terrain-tests | N/A | PASS; 16 tests, 0 skipped | GREEN |
| all | qa-tests | N/A | PASS; 4 tests, 0 skipped | GREEN |
| sloans-lake | dem | 100.0% | PASS; saved native 1 m + distance bands fully read-back verified; 0 errors | GREEN |
| sloans-lake | building-qa | see heights/roofs | PASS_WITH_GAPS; flags {"footprint_implausible_or_below_method_size": 104, "height_missing": 992}; errors {} | GREEN |
| lakeview-sheil-park | dem | 100.0% | PASS; saved native 1 m + distance bands fully read-back verified; 0 errors | GREEN |
| lakeview-sheil-park | building-qa | see heights/roofs | PASS_WITH_GAPS; flags {"footprint_implausible_or_below_method_size": 4, "height_missing": 181}; errors {} | GREEN |
| west-highland | dem | N/A | BLOCKED: fixed area boundary and manifest missing | NOT LOADED |
| west-highland | building-qa | N/A | BLOCKED: fixed area boundary and manifest missing | NOT LOADED |

## QA comparison

The same QA policy applies to every area. Missing input is blocked, not a pass. Heights/roofs were rerun byte-identically for both available areas. Read-back terrain checks verify hashes, native 1 m resolution, finite values, coverage masks, distance bands and min/max envelopes. Building checks flag missing, zero, invalid and repeated heights, implausible footprints, and roof/height/source inconsistencies. Footprint checks operate on the existing reader’s repaired geometry; they are not an independent survey of OSM completeness.

| Area | Building QA | Terrain QA |
|---|---|---|
| sloans-lake | PASS_WITH_GAPS; flags {"footprint_implausible_or_below_method_size": 104, "height_missing": 992}; errors {} | PASS; saved native 1 m + distance bands fully read-back verified; 0 errors |
| lakeview-sheil-park | PASS_WITH_GAPS; flags {"footprint_implausible_or_below_method_size": 4, "height_missing": 181}; errors {} | PASS; saved native 1 m + distance bands fully read-back verified; 0 errors |
| west-highland | BLOCKED: fixed area boundary and manifest missing | BLOCKED: fixed area boundary and manifest missing |

## Blocks and handoff

West Highland: no saved fixed rectangle or area manifest; height, roof, DEM and QA steps stop on that ambiguity. No source loaded and no camera guessed. A fixed rectangle is required to prepare the dedicated hold-out with the unchanged pipeline.

Merge: the earlier terrain rebase conflicted with A3’s handoff filing and was aborted safely. Batch is saved on astra-a1-overnight-data. Tests gate merging; any new merge conflict stops integration.

P2: building-heights.json and building-roofs.json remain the same measured/derived contracts. 5A: elevation/metadata.json indexes native NAVD88 metre clips and the distance bands; datum reconciliation and rendering remain with 5A. No visual acceptance is claimed. Earlier assessor, full-GERS and Greenville follow-ups were outside this overnight batch.

Verification used the existing Python 3.14 lidar environment plus the existing rasterio site-packages, without installation; all checks ran directly beneath scripts/heavy.sh. The initially queued DEM check was consolidated into one owned-lock job; other lane locks were untouched.

## Integration stopped

Main advanced to b012b71. Rebase stopped on a content conflict in docs/tracking/handoffs.md (A3 facade handoff versus the earlier A1 terrain handoff). No resolution or push attempted. Rebase aborted safely to preserve all completed batch files on astra-a1-overnight-data. 146 tests ran successfully under the owned heavy lock, with 3 skipped; no check failures. Disk remained above 8 GB. West Highland stays blocked on its missing fixed rectangle/manifest.

## R-approved handoff resolution — 8 October

Both 8 October handoff entries retained add-only in date order, as R expressly approved for handoffs.md. Rebase complete; 126 lidar tests (3 skipped), 16 terrain tests and 4 observed QA tests pass under the heavy lock, plus read-back audits of all three saved DEM packages and both overnight building areas. Integration ready; earlier conflict status above is historical. No fallback or West Highland rectangle approved or applied.
