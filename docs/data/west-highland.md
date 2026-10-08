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

The unchanged terrain pipeline saves native 1 m USGS CO_DRCOG_2020_B20 elevation, NAVD88 metres, plus the 100 m halo. Distance bands use mountain-terrain-v1/values.json#demByDistance: 10 m samples at 250 m–2 km, 30 m at 2–20 km, 60 m at 20–50 km, 120 m at 50–100 km, 240 m at 100–200 km. Native clips are unresampled; distant sample spacing is distinct from source resolution. Each band retains min/max envelopes. The existing pipeline writes bands relative to each area's centre; West Highland is not a shifted Sloan raster. Read-back is now present in elevation/qa.json: PASS_WITH_GAPS, 1,440,000/1,441,200 native mask cells (99.9167%), one edge row flagged; every distance band 100%, no invariant errors. Per-clip extraction completeness is not the same as requested-rectangle coverage; the earlier extraction-only 100% figure overstated the latter.

## Web bundle and ownership

`Tools/regionkit/export_observed_bundle.py` accepts any configured area, requires GREEN data and current QA digests, calls the unchanged exporter and copies observation sidecars byte-for-byte. The web manifest is `world/world.json`; `observations/` carries height, roof, elevation and QA files, raw OSM footprints and source metadata. `bundle.json` hashes every payload and explicitly sets `observationsAppliedToMesh: false` and `newFallbackLadderApplied: false`.

The standard mesh still uses existing generator rules. P2 owns reading the lidar height/roof sidecars; 5A owns consuming native terrain and reconciling NAVD88 with rendering coordinates. This export is not evidence that rendered buildings have lidar heights, nor a visual acceptance. No new fallback values are exported: see `fallback-validation.md` for the table shown to R and unresolved acceptance gate. The deterministic date input is 2026-07-15T20:00:00Z, copied from the existing web export recipe, not live conditions.

## Proposed fixed camera for A3

Proposed ID `west-highland-aerial-north-01`: target the area centre (39.764, −105.04) at scene y=0; eye at (39.759946, −105.04), scene y=350 m; vertical FOV 47°, portrait 390×780. This is an authored north-facing overview proposed before any capture or scoring, with no visual tuning; camera heights are relative to the current scene plane, not NAVD88. A3 subsequently confirmed and froze this camera unchanged in docs/lookloop/west-highland-capture-contract.json (main 55e6aed), before scored comparisons. Keep the existing shared atmosphere fixture and record it with the capture. No camera or look code was changed.

## Delivered local artifact

`Generated/west-highland-web-2026-10-08/world/world.json` and `Generated/west-highland-web-2026-10-08.zip` now exist in the A1 worktree. ZIP: 90,374,679 bytes; SHA256 `8dedc53b98d8914425cc5290a3bfe69754c42a37023192a9d3b94fc04d1482c0`. All bundle payload hashes, JSON reads, observed-sidecar equality and ZIP CRC verified. Outputs are local, git-ignored artifacts, not hosted. The checked-in elevation/qa.json is PASS_WITH_GAPS as described above.

Coverage denominators above belong to the observed-sidecar footprint reader, not the generated mesh population. No crosswalk between those populations is delivered here; do not transfer those percentages to rendered buildings. A8’s earlier absent-artifact finding was correct at the time; the explicit local paths and verified hashes above establish the later delivery. Independent height-reference rights remain unresolved (A9); no new reference source was loaded.

## Local terrain and bundle hashes — R-approved guard repair, 8 October

The six terrain binaries and web ZIP remain local and gitignored; they are excluded from all unpublished A1 commits. Regenerate terrain with the unchanged regionkit terrain pipeline and the West Highland area manifest; source URLs, survey, bounds, CRS, datum and processing parameters remain in the elevation metadata. Regenerate the bundle with export_observed_bundle.py using the recipe above. Hashes below identify the exact delivered bytes; qa.json remains tracked.

| Local artifact | SHA-256 |
|---|---|
| `Data/areas/west-highland/elevation/band-100000-200000m.npz` | `4d0f2e04012fb679852f6f5c623c50055edc075bee62406660b162dc0b06665b` |
| `Data/areas/west-highland/elevation/band-2000-20000m.npz` | `5cac71b0f4e3c8ae7a0d7d7ec282a892cf7872e653b263b2c3d93616d5651907` |
| `Data/areas/west-highland/elevation/band-20000-50000m.npz` | `3d1ecc7d01348dc42ce28c15d933826576fa24559ca6ba5f43e9028e0acf8065` |
| `Data/areas/west-highland/elevation/band-250-2000m.npz` | `cefbb7e5d62f5292a585808115cc638af9e8310fda7c32a9d7fda298eb5fcb9a` |
| `Data/areas/west-highland/elevation/band-50000-100000m.npz` | `eb16d64ca866253623a43c18a204d7399be87147323e5266f2d3194562a4c17d` |
| `Data/areas/west-highland/elevation/native-1m-0.tif` | `ee72a6b001a8669e2646b00099f38cdff80c2a5cdac525b6d5824bdd77cf0288` |
| `Generated/west-highland-web-2026-10-08.zip` | `8dedc53b98d8914425cc5290a3bfe69754c42a37023192a9d3b94fc04d1482c0` |
| `Data/areas/west-highland/elevation/qa.json` | `2db601b7a4d16128b71f438f453f561bf69479aabe35f2608235b825bb3ddd1d` |
