# Mapped context building masses — default-off bakeoff prototype

R requested mapped coarse masses beyond the detailed core, a total ring ceiling of 40,000 main triangles /8 draws /zero shadow additions, retained Greenville failure images, compatible-batch measurements, and the existing shipping scoreboard after merge. No scores are assigned.

## General rule and implementation

`tools/export-context.swift` reuses the existing licensed context document, `MapFeatureBuilder` height resolution and `WorldMesh.Extrusion`. Each non-part mapped footprint becomes flat walls and a flat roof, with courtyard holes retained. There are no facades, roof decorations, invented footprints or skyline. A footprint’s bounding box must lie entirely outside the core and inside actual context coverage; every outer vertex must be within 500 m of the core. Bounding boxes that intersect the core are conservatively omitted rather than duplicated (including concave footprints whose bounding box overlaps). Heights record `heightTag`, `levels`, or `typeDefault` (inferred, not surveyed).

The exporter sorts by distance to the core, then stable OSM reference. `context-ring.js` preserves the existing land/roads/water triangles, then accepts whole building masses in that order while total uploaded ring geometry stays at or below 40,000 triangles. A mass too large for the remaining allowance is skipped; later smaller masses may fit. The cap is on uploaded geometry, not merely visible submissions. One building mesh adds at most one draw to the prior five ring draws. No ring mesh casts or receives shadows. No location-specific parameters exist.

The mass material reuses the existing residential palette slot, standard material lighting and calibration-v2 masonry roughness. Roof and wall normals are retained; the existing 200 m source-edge fade remains. This is neutral coarse massing, not family appearance parity. Budget selection can end the building band before the source does; the remaining region stays explicitly coarse. No wider data is fetched, no streaming or iPhone performance is claimed.

`?contextRing=1&sceneBudget=1` enables the prototype. Default entry remains unchanged. `&contextMerge=1` is a diagnostic variant merging the four same-material land/road batches in their existing triangle order. Water retains its distinct shader and building masses retain their separate batch. Merging is not silently enabled in the ordinary ring variant.

## Measurement contract

`tools/run-context-buildings.sh` uses the existing Sloan/Lakeview inspection ladder, corrected Wilmette camera, untouched West Highland contract and separate Greenville shipping-renderer fixture. OFF, fresh OFF-repeat, ON and merged ON run in fresh Chrome processes with frozen capture conditions. Counts come from actual main/shadow submissions, with context counted separately. Blank fraction uses the existing 81×45 structural ray grid: boundary/generated ground count as blank; mapped context land/water/buildings do not. This is structural coverage, not a visual score. The prior ring-only measurements remain in `../context-ring/`.

Raw images are local ignored evidence. Manifests contain PNG hashes, source hashes, camera contracts, counters and differences. `review.html` displays 390 CSS-pixel panels against the approved calibration reference; calibration owns appearance, not the aerial geometry/camera.

## Greenville capture diagnosis

The fresh-process harness now writes every PNG and the ×16 absolute difference image before asserting equality. It records renderer shader time as well as camera and pass counts. Raw-clock OFF/ON reproductions and fixed-clock OFF/repeat/ON are separate fresh processes. The fixed clock only changes this capture fixture's Three.js NodeFrame; it is not a shipping renderer edit. Water ripple and foliage sway consume `time` in `web/src/materials.js`; freezing after readiness alone does not select the same time in separate processes. The experiment confirms the clock as the cause of this fresh-process mismatch; missing context remains a no-op, not a coverage claim.

## Results

600 m measured values (ON includes masses; `contextMerge=1` is separate):

| View | Blank OFF → ON | Total ring tris / draws | Buildings drawn (inferred height) | Main ON tris / draws | Main merged draws | ON → merged differing bytes |
|---|---:|---:|---:|---:|---:|---:|
| Sloan | 31.08% → 20.25% | 40,000 /6 | 1,033 (916) | 360,036 /118 | 115 | 0 |
| Lakeview | 71.88% → 8.26% | 39,996 /6 | 1,315 (673) | 112,061 /38 | 35 | 1 (max 1/255) |
| Wilmette corrected | 53.55% → 7.38% | 17,006 /6 | 90 (85) | 385,868 /81 | 78 | 0 |

All three blank gates pass. Added shadow geometry/draws are zero; the old detailed pass submissions are unchanged. Relative to the prior ring-only experiment, blank falls by 3.34 /0.66 /0.44 percentage points respectively. All main counts fit standard; Sloan still fails the 100-draw floor. Its detailed baseline is already 112 draws, so context merging alone cannot make it pass. The old five-batch ring was 117 total; new unmerged masses make 118, and the four-to-one land merge gives 115. Water uses a different shader; its merge is not demonstrated. Building-plus-land consolidation is not tested. No claim that any other batch merge is pixel-safe.

The land/road merge is exactly pixel-identical at Sloan and Wilmette600, **not universally identical**: Lakeview differs by one byte. It remains an explicit diagnostic flag, not the ordinary ring path. No tolerance is silently substituted for exact equality.

Uncompressed context JSON sizes: Sloan 22,454,998 B, Lakeview 24,192,500 B, Wilmette 2,972,092 B. GPU geometry arrays: 10,320,000 /10,453,464 /4,387,548 B. Export includes all eligible candidate masses; the renderer budget selects 1,033 of 5,710, 1,315 of 6,396 and 90 of 90. This eager candidate payload is a prototype limitation and is **not a phone/network shipping qualification**. Later package compaction/streaming needs its own evidence.

Greenville fresh-process raw OFF shader time was 2.0914000000 s and ON was 2.0855 s: **19 decoded colour bytes differed**, max 13/255, mean 0.0000162902 byte units. Fixed shader time 0 yielded **zero differing bytes** for both a fresh OFF-repeat and fresh ON. No context exists there, so `installContextRing` returns before touching the scene. The time-driven water ripple/foliage sway explains the capture mismatch; this is not a context geometry defect. Attribution, pose and renderer remain unchanged. `greenville/raw-on.png`, `raw-on-diff-x16.png`, `fixed-on.png` and `fixed-on-diff-x16.png` are saved even if later checks fail. No bakeoff Greenville look or new-coverage qualification is claimed.

The first lower-view run is retained in `holdouts-40/manifest.json`: screenshot timed out after 30 seconds on Sloan OFF-repeat, after the OFF PNG had saved. Screenshot timeout was raised to 120 seconds without changing rendering; the fresh rerun is `holdouts-40-r2/`.

The 40 m checks pass: blank fractions are unchanged (Sloan 2.99%, Lakeview 11.71%, Wilmette 3.65%); every fresh OFF-repeat is exact and all three land-merge comparisons have zero differing bytes. The 150 m checks also pass: blank remains 1.54% /9.82% /3.76%. All six 40/150 m OFF→ON images are pixel-identical despite the separately counted additional submissions; all six merge comparisons are exact. West Highland remains explicit missing context: 21.51% blank, 281,995 main triangles /75 draws, zero added context; OFF-repeat, ON and merged ON are exact. Existing detailed main/shadow submissions are unchanged across every comparison. Fourteen focused tests pass. For those later captures the helper explicitly stops the render loop before PNG collection, matching the existing scoreboard; this changes capture quiescence only. Exact source hashes and capture phases are retained in `source-hashes.json`.

**Remaining visible edge:** the structural detector counts mapped land colour as coverage. The new mass band is visibly finite, especially in Lakeview, and does not create an endless populated city. Passing this blank detector is not a look gate or a shipping declaration. Larger held building coverage and a compact streaming representation remain separate work.

The post-merge scoreboard is pending.

## Reproduction

Under the shared heavy lock: build `tools/build-context-exporter.sh`, then `tools/run-context-buildings.sh`. Existing output directories intentionally refuse overwrite. Run `node tools/summarize-context-buildings.mjs` from the bakeoff directory after captures. The existing shipping `scripts/world-scoreboard.sh --output <fresh JSON>` is run after merge; it exercises the default-off renderer, not the opt-in context prototype.

Used: `docs/execution/world-edge-options.md`, Recommendation and first test; native `ContextRing.swift` / `World+Context.swift` as reference. Mock: `style-b-calibration-v2/frames/06-sloans.png` and `01-lakeview.png`. Deviation: bounded prototype only; no scores, streaming or phone qualification.
