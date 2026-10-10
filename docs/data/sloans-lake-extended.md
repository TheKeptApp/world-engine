# Sloan’s Lake extended package

## Plan and contract

Use the unchanged area loader, exporter and adaptive packer from current main. Fetch a complete ODbL street extract and a fresh 3 km context ring; export full LOD0 and reduced LOD1 for every core cell, then validate the packed output independently against all original triangles/channels. Preserve the old Sloan’s test area. Raw sources and binaries stay local; source manifests, queries, hashes and measured receipts are tracked. No renderer or generator edits.

The requested geographic rectangle takes precedence over the approximate metre dimensions and cell count in native-batch1. WGS84 gives approximately 2,199 × 1,750 m. The existing southwest-anchored 200 m exporter grid gives ceil(width/200) × ceil(height/200) = **11 × 9 = 99**, not 12 × 9 = 108. A 0.25 m per-edge projection allowance encloses the requested corners; no 200 m padding or per-block grid override. Configuration: `Tools/regionkit/data/package-extents.json`.

The full core includes the shoreline and nearby streets. Both detail levels remain available throughout the neighbourhood; selecting/streaming those levels is the consumer’s job. This data build does not implement the native spec’s polygon-distance detail selector. The existing web exporter has no context mesh payload; the paired native source area carries the coarse context extract for the existing native context builder.

## Source coverage and gaps

Fresh core: 4,243 buildings excluding 12 parts; 720 roads; 339 paths; five water polygons (715,731 m² summed). The core extract has zero missing way-node references. Sloan’s Lake relation 4049789 has both member ways, with source bounds S 39.7440833, W −105.0530619, N 39.7526625, E −105.0367503, entirely inside the requested rectangle. Four skipped degenerate areas are grass ways 560604155, 561045284, 566875808 and 566875809; no skipped building/road/water is reported by the loader. This checks held-source closure, **not** completeness against independent surveying or imagery.

Fresh context: 20.75 MB; 12,825 loaded buildings, 6,632 roads, 73 water areas. Roads/land/water extend to the new box plus 3 km. Building coverage is intentionally limited to the existing 500 m band, and minor paths/point details are absent in coarse context by policy. No relation has ≥300 members in the ring; the large-water cap did not remove Sloan’s Lake. Four context building footprints are degenerate and skipped. Overpass returned 504/429 errors; the unchanged backoff recovered, with seven requests total, 25.12 MB decoded transfer including overlapping subqueries. Both final extracts have OSM timestamp 2026-10-10T00:47:03Z (9 Oct local); source rights GREEN ODbL intake.

Heights/roofs remain a gap: three explicit OSM heights, 562 additional heights from levels, 3,678 type defaults; 88 roof-shape tags. Existing generator estimates remain estimates. The enlarged area has no new survey-height/roof or DEM sidecars, and the old core sidecars are not relabelled as extended coverage. Package terrain stays the existing flat datum. No ladder rung promoted.

## Reproduction

Read the extent configuration and new area manifest. Raw `osm.json` and `context.json` remain local and hashed; queries reproduce selection, but a later Overpass response will not reproduce the historical snapshot. The delivery bundle retains those exact extracts. Commands use the existing pipeline:

```sh
# Compile/test/export/pack under scripts/heavy.sh, with disk >=8 GB.
HEAVY_AGENT=A1 scripts/heavy.sh 'exporter' swift build --product worldbake -j 2
# Populate the area manifest from package-extents.json before fetching.
.build/debug/worldbake fetch Data/areas/sloans-lake-extended --layers all
.build/debug/worldbake fetch Data/areas/sloans-lake-extended --layers context --building-band-km 0.5 --split 1
HEAVY_AGENT=A1 scripts/heavy.sh 'export' .build/debug/worldbake export Data/areas/sloans-lake-extended Generated/sloans-lake-extended/world --date 2026-10-15T18:00:00Z --season 2 --version 08fd77b
HEAVY_AGENT=A1 scripts/heavy.sh 'pack' .build/debug/worldbake pack Generated/sloans-lake-extended/world Generated/sloans-lake-extended/adaptive
# Use a Python environment with the existing regionkit dependencies for the independent audit.
HEAVY_AGENT=A1 scripts/heavy.sh 'audit' python3 Tools/regionkit/qa/adaptive_package.py --source Generated/sloans-lake-extended/world --packed Generated/sloans-lake-extended/adaptive --output docs/data/sloans-lake-extended-adaptive-qa.json
HEAVY_AGENT=A1 scripts/heavy.sh 'accounting' python3 Tools/regionkit/qa/package_extent.py --area Data/areas/sloans-lake-extended --package Generated/sloans-lake-extended/world --config Tools/regionkit/data/package-extents.json --output docs/data/sloans-lake-extended-qa.json
```

Source area uses a new frame origin (39.7483715, −105.044909); consumers must use its manifest frame, or convert existing camera geocoordinates. Do not reuse old Sloan’s local metre positions without transformation. All binary outputs are ignored; no renderer, look profile, default held-area source or generator was changed.

## Delivery

Pending build and independent validation; not delivered yet. The existing ODbL public-offer URL remains pending, as in the current package; this internal data handoff is not an external-release clearance.

Used: docs/perf/native-batch1.md §4; docs/data/adaptive-tiles.md; docs/data/context-rings.md; docs/data-licensing.md; docs/tracking/REFERENCE-MAP.md Context ring/world edge, Ground, Water. Mock: none (data extent build, no appearance changes or visual grade). Deviation: 99 cells from actual grid arithmetic versus the spec’s 108; existing LOD payloads, no new consumer streaming or polygon-distance selector.
