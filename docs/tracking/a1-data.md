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
