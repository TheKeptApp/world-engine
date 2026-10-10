# Sloan’s Lake extended package

## Plan and contract

Use the existing area loader/exporter/packer with a general optional geographic grid anchor for extent expansions. Fetch a complete ODbL street extract and a fresh 3 km context ring; export full LOD0 and reduced LOD1 for every core cell, then validate the packed output independently against all original triangles/channels. Preserve the old Sloan’s test area. Raw sources and binaries stay local; source manifests, queries, hashes and measured receipts are tracked. No renderer, style or appearance-value edits; only general chunk-grid alignment changes in generation.

The requested geographic rectangle is preserved. WGS84 gives approximately 2,199 × 1,750 m. Extent expansions now optionally retain the previous area’s geographic **gridAnchor**; first/last cells clip to the extent rather than padding or shrinking it. This gives the requested **12 × 9 = 108** cells. The earlier 99-cell calculation used a newly southwest-anchored grid; it was not the requested alignment. `ChunkGrid` is general and has no area names or coordinates; manifests without an anchor retain the previous layout. Configuration: `Tools/regionkit/data/package-extents.json`. The small projection allowance encloses all requested corners.

The full core includes the shoreline and nearby streets. Both detail levels remain available throughout the neighbourhood; selecting/streaming those levels is the consumer’s job. This data build does not implement the native spec’s polygon-distance detail selector. The existing web exporter has no context mesh payload; the paired native source area carries the coarse context extract for the existing native context builder.

## Source coverage and gaps

Fresh core: 4,243 buildings excluding 12 parts; 720 roads; 339 paths; five water polygons (715,731 m² summed). The core extract has zero missing way-node references. Sloan’s Lake relation 4049789 has both member ways, with source bounds S 39.7440833, W −105.0530619, N 39.7526625, E −105.0367503, entirely inside the requested rectangle. Four skipped degenerate areas are grass ways 560604155, 561045284, 566875808 and 566875809; no skipped building/road/water is reported by the loader. All old core source refs remain present with the relevant tag: 1,427 building ways/relations, 624 highway ways/relations and five water ways/relations; zero absent or tag-changed. These raw-source counts differ from clipped/loaded feature counts. This checks held-source closure, **not** completeness against independent surveying or imagery.

Fresh context: 20.75 MB; 12,825 loaded buildings, 6,632 roads, 73 water areas. Roads/land/water extend to the new box plus 3 km. Building coverage is intentionally limited to the existing 500 m band, and minor paths/point details are absent in coarse context by policy. No relation has ≥300 members in the ring; the large-water cap did not remove Sloan’s Lake. Four context building footprints are degenerate and skipped. Overpass returned 504/429 errors; the unchanged backoff recovered, with seven requests total, 25.12 MB decoded transfer including overlapping subqueries. Both final extracts have OSM timestamp 2026-10-10T00:47:03Z (9 Oct local); source rights GREEN ODbL intake.

Heights/roofs remain a gap: three explicit OSM heights, 562 additional heights from levels, 3,678 type defaults; 88 roof-shape tags. Existing generator estimates remain estimates. The enlarged area has no new survey-height/roof or DEM sidecars, and the old core sidecars are not relabelled as extended coverage. Package terrain stays the existing flat datum. No ladder rung promoted.

## Reproduction

Read the extent configuration and new area manifest, including its `gridAnchor`. The anchor is configuration data, not an area-name branch in code. Raw `osm.json` and `context.json` remain local and hashed; queries reproduce selection, but a later Overpass response will not reproduce the historical snapshot. The delivery bundle retains those exact extracts. Commands use the existing pipeline:

```sh
# Compile/test/export/pack under scripts/heavy.sh, with disk >=8 GB.
HEAVY_AGENT=A1 scripts/heavy.sh 'exporter' swift build --product worldbake -j 2
# Populate the area manifest from package-extents.json before fetching.
.build/debug/worldbake fetch Data/areas/sloans-lake-extended --layers all
.build/debug/worldbake fetch Data/areas/sloans-lake-extended --layers context --building-band-km 0.5 --split 1
HEAVY_AGENT=A1 scripts/heavy.sh 'export' .build/debug/worldbake export Data/areas/sloans-lake-extended Generated/sloans-lake-extended/world --date 2026-10-15T18:00:00Z --season 2 --version sources-86ae00c3f5c9d2c991e8a552a85e4fa9ab6aa4a7
HEAVY_AGENT=A1 scripts/heavy.sh 'pack' .build/debug/worldbake pack Generated/sloans-lake-extended/world Generated/sloans-lake-extended/adaptive
# Use a Python environment with the existing regionkit dependencies for the independent audit.
HEAVY_AGENT=A1 scripts/heavy.sh 'audit' python3 Tools/regionkit/qa/adaptive_package.py --source Generated/sloans-lake-extended/world --packed Generated/sloans-lake-extended/adaptive --output docs/data/sloans-lake-extended-adaptive-qa.json
HEAVY_AGENT=A1 scripts/heavy.sh 'accounting' python3 Tools/regionkit/qa/package_extent.py --area Data/areas/sloans-lake-extended --package Generated/sloans-lake-extended/world --config Tools/regionkit/data/package-extents.json --output docs/data/sloans-lake-extended-qa.json
```

The generator version label is `sources-86ae00c3f5c9d2c991e8a552a85e4fa9ab6aa4a7`, the exact Git tree of `Sources/` used for the build; it remains reproducible through documentation-only rebases.

Source area uses a new frame origin (39.7483715, −105.044909); consumers must use its manifest frame, or convert existing camera geocoordinates. Do not reuse old Sloan’s local metre positions without transformation. All binary outputs are ignored; no renderer, look profile, default held-area source or generator was changed.

## Delivery

**Verified delivery: 108 parent cells (12 × 9), 217 adaptive leaves.** Core bounds cover all four requested corners; the geographic anchor retains the original grid phase. The earlier 99-cell archive is preliminary and is not the handoff. The requested final source area is `Data/areas/sloans-lake-extended`; the local bundle is `Generated/sloans-lake-extended/bundle.zip` in the A1 worktree (`~/Desktop/world-engine/.claude/worktrees/astra-a1-data`). The unpacked bundle is adjacent at `bundle/`.

| Detail payload | Cells | Mean GLB MB/cell | Median | Maximum | Mean decoded geometry MB/cell |
|---|---:|---:|---:|---:|---:|
| LOD0, full street detail | 108 | 2.404 | 2.351 | 6.499 | 2.402 |
| LOD1, reduced buildings/streets | 108 | 0.453 | 0.381 | 1.319 | 0.451 |

MB = 10^6 bytes. Standard package: 345,436,908 bytes; shared assets/metadata add 36.846 MB, not attributed to individual cells. Source context is 20.75 MB and generated by the existing native context reader, not a new web context-mesh payload. These figures exclude native GPU duplication, renderer resources and runtime residency; they are not the native spec’s GPU estimates.

Adaptive audit: maximum LOD0 GLB 2,081,760 B; maximum decoded primitive 2,078,792 B, below 2 MiB. Worst two leaves 4,152,304 B (3.960 MiB), below 16 MiB. All 108 coarse replacement groups retained; all 1,980,818/345,831 LOD0/LOD1 triangles, channels, feature joins and non-chunk appearance files preserved by packing. Repeat pack is byte-identical. This is data/queue accounting, not a device-floor pass.

| Stage | Measured wall seconds (excludes lock waiting) |
|---|---:|
| Export | 135.638 |
| Adaptive pack | 82.706 |
| Independent full audit | 29.305 |
| Coverage/hash accounting | 0.557 |
| Bundle/ZIP + read-back | 15.740 |
| Repeat pack | 85.333 |
| Repeat bundle | 15.363 |
| 42 tests + compilation | 202.447 |

Legacy controls run the same October 15/season-2 recipe with `grid-compat-v1` on the saved pre-change binary and rebuilt binary. Every output file is byte-identical: Sloan’s 281, Lakeview 212, Greenville 344. Initial compiler/package checks also passed before the grid change; the final 42 tests include grid coverage/translation/backward-compatible manifests and deterministic real-data package tests. All heavy work used the load-gated wrapper; disk remained above 8 GB. An initial nested audit launcher was refused by its direct-parent guard; the final audit ran directly in the wrapper’s Python child, with the guard unchanged.

The archive contains 1,469 files, 788,459,258 uncompressed bytes, and is **102,636,658 bytes**. Every archived payload hash and ZIP CRC passed; a second independently assembled ZIP is byte-identical.

| Artifact | SHA-256 |
|---|---|
| Standard `world/world.json` | `9e465754b59da3d4e1ecbe7a896bf417300f6733c7bc62e62ca9ccf2f00e698d` |
| Adaptive `adaptive/world.json` | `702a0b10ab769066b1ae59b300bf5554b6d01ef738e978bf68f4cfa477b2f0e4` |
| `bundle/bundle.json` | `2b224888d0581ed9dffd1dae4f0d6aea2edb8659364df685b5c79113fcb81e78` |
| `bundle.zip` | `839560baa903a6a753eaa788c06629364ac4836af8fef372c95c942a57507dc7` |

Receipts: [coverage](sloans-lake-extended-qa.json), [full adaptive audit](sloans-lake-extended-adaptive-qa.json), [legacy controls](sloans-lake-extended-grid-controls.json), [timings/bundle](sloans-lake-extended-build.json). `Tools/regionkit/bundle_package.py` takes `--area`, `--world`, `--adaptive`, `--qa`, `--adaptive-qa`, and a new `--output` directory; it preserves the existing package schemas and creates a deterministic adjacent ZIP. Raw sources and binary outputs are gitignored; manifests, queries and hashes remain in Git. The existing ODbL public-offer URL remains pending, as in the current package; this internal handoff is not external-release clearance.

## Ledger text for A3

A1: new extended dataset, not a replacement for the existing Sloan’s control. General grid alignment only; renderer/appearance values unchanged. Original Sloan’s, Lakeview and Greenville packages are byte-identical under the same recipe. The new box has 108 cells and fresh OSM coverage; score it using frozen geographic cameras transformed through its new frame. Data integrity/queue gates pass, but no new visual grade or device-floor acceptance is claimed. Post-merge scoreboard status is filed separately below when available.

Used: docs/perf/native-batch1.md §4; docs/data/adaptive-tiles.md; docs/data/context-rings.md; docs/data-licensing.md; docs/tracking/REFERENCE-MAP.md Context ring/world edge, Ground, Water. Mock: none (data extent build, no appearance changes or visual grade). Deviation: existing LOD payloads, no new consumer streaming or polygon-distance selector. The requested 108 cells retain the prior grid phase; no renderer or look values changed.

## Post-merge scoreboard

Measured merged commit `36cd08c` with the unchanged shipping web renderer: [27-frame report](sloans-lake-extended-scoreboard.md), [machine receipt](sloans-lake-extended-scoreboard.json). All nine held datasets (eight places; original and extended Sloan’s are separate datasets) completed in 1,421.3 s including heavy-lock waits. Each heavy step released its lock. Disk stayed above 8 GB; redundant repeat outputs were removed after their equality receipts had been saved, retaining the final delivery.

Extended Sloan’s at 40/150/600 m submitted main triangles/draws of 106,290/85, 328,590/209 and 754,819/355; shadow triangles/draws were 35,380/16, 64,926/26 and 5,398/1. The 40 m frame passes the automatic checks; 150/600 m fail floor and standard budgets. None of the three flags blank ground or surface tunnel strips. These default centre cameras are not matched to the original Sloan’s frozen pose. No device-floor or aesthetic acceptance is claimed.

Across all 27 frames, 26 fail floor/standard budgets and seven flag blank ground. The prior 24-frame comparison adds only the three extended frames; West Highland is explicitly non-comparable because its input/capture contract differs. The other 21 existing frames have no reported metric/failure changes. Personal home-directory prefixes in these new receipts are normalized to `~`; metrics and hashes are unchanged. This documentation-only follow-up does not require another rendering run.
