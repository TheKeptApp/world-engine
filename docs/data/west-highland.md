# West Highland data handoff — 8 October 2026

R approved the exact 1 km × 1 km rectangle centred at 39.764, −105.04, with a 100 m processing halo. Bounds: south 39.75949671668853, west −105.04583518358649, north 39.768503283311475, east −105.03416481641352. `Data/areas/west-highland/manifest.json` is the production area. No hand-edited buildings, block rules or parameter tuning.

## Sources and coverage

OSM extract fetched using `out body`, with attribution and ODbL retained. No tagged building ways are lost to duplicate skeleton elements in this extract. USGS 3DEP CO_DRCOG_2_2020 lidar, collected 2020-05-26 to 2020-06-12, is GREEN public domain; full-density source, same-survey class-2 ground. The survey has class-1 returns rather than vendor building labels, so the existing generic planar-candidate method is used. All accepted heights and classified roofs remain grade D without independent error calibration.

| Area | Heights | Roof forms | Height nulls | Building QA |
|---|---:|---:|---:|---|
| Sloan's Lake | 407/1399 (29.1%) | 407/1399 (29.1%) | 992 | PASS_WITH_GAPS |
| Lakeview | 2618/2799 (93.5%) | 2563/2799 (91.6%) | 181 | PASS_WITH_GAPS |
| Greenville Downtown | 437/681 (64.2%) | 419/681 (61.5%) | 244 | PASS_WITH_GAPS |
| West Highland | 476/2496 (19.1%) | 474/2496 (19.0%) | 2020 | PASS_WITH_GAPS |

All four use identical height/roof methods and identical QA policies. West Highland: 225 flat, 72 gable, 41 hip, 136 other and 2,022 unknown roofs. QA flags 140 small/implausible footprints and the missing heights, with zero broken invariants. Classifications and ridge direction are inferred from lidar support, not confirmed physical forms. Quality grades are not acceptance probabilities.

The unchanged terrain pipeline saves native 1 m USGS CO_DRCOG_2020_B20 elevation, NAVD88 metres, plus the 100 m halo. Distance bands use mountain-terrain-v1/values.json#demByDistance: 10 m samples at 250 m–2 km, 30 m at 2–20 km, 60 m at 20–50 km, 120 m at 50–100 km, 240 m at 100–200 km. Native clips are unresampled; distant sample spacing is distinct from source resolution. Each band retains min/max envelopes. The existing pipeline writes bands relative to each area's centre; West Highland is not a shifted Sloan raster. Extraction reports 100% coverage; final read-back result is in elevation/qa.json.

## Web bundle and ownership

`Tools/regionkit/export_observed_bundle.py` accepts any configured area, requires GREEN data and current QA digests, calls the unchanged exporter and copies observation sidecars byte-for-byte. The web manifest is `world/world.json`; `observations/` carries height, roof, elevation and QA files, raw OSM footprints and source metadata. `bundle.json` hashes every payload and explicitly sets `observationsAppliedToMesh: false` and `newFallbackLadderApplied: false`.

The standard mesh still uses existing generator rules. P2 owns reading the lidar height/roof sidecars; 5A owns consuming native terrain and reconciling NAVD88 with rendering coordinates. This export is not evidence that rendered buildings have lidar heights, nor a visual acceptance. No new fallback values are exported: see `fallback-validation.md` for the table shown to R and unresolved acceptance gate. The deterministic date input is 2026-07-15T20:00:00Z, copied from the existing web export recipe, not live conditions.

## Proposed fixed camera for A3

Proposed ID `west-highland-aerial-north-01`: target the area centre (39.764, −105.04) at scene y=0; eye at (39.759946, −105.04), scene y=350 m; vertical FOV 47°, portrait 390×780. This is an authored north-facing overview proposed before any capture or scoring, with no visual tuning; camera heights are relative to the current scene plane, not NAVD88. A3 must confirm/freeze it before scored comparisons. Keep the existing shared atmosphere fixture and record it with the capture. No camera or look code was changed.
