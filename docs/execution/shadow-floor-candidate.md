# Shadow-floor candidate — 2026-10-09

## Authority and inputs

R approved merge of 5d6cf40, lossless finite wind bounds, an independent approximate-shadow fallback if required, the candidate bundle and consumption of A4 far geometry only after its report. Web and iOS must be qualified together; no native acceptance is inferred from web results.

Read: spatial-order-and-shadow-diagnosis.md §§General repair, Reconciled shadow categories and distance, Native transfer boundary; shadow-and-draw-floor.md §§Implementation, Qualification, Source-run concatenation; budget-tiers.md §Contracts and scope; docs/INDEX.md routing, docs/tracking/DECISIONS.md binding comparison/ship rules and docs/tracking/INDEX.md feature rows (docs/INDEX.md was added during this task); docs/tracking/MOCKS.md M-CAL-SLOANS/M-CAL-LAKEVIEW; docs/lookloop/GRADING.md §§M, N, C, E, PP. A3 owns scoring, including R-authorized paired scoring; no A10 scores.

Mocks opened: ~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/frames/06-sloans.png and frames/01-lakeview.png. These govern appearance, not aerial geography. Fixed shipping and bakeoff controls govern the lossless gate.

## Merge and wind envelope

The approved branch rebased without conflict and merged as 6e76ca7. 21 focused tests passed before merge. Existing scoreboard was launched after merge, admitting each heavy build/export/capture separately.

For the known foliage position node, InstanceNode precedes wind displacement. Let B be its highp interval transformed through the instance matrix. With maximum positive _paint.w S and Y=max(abs(B.min.y),abs(B.max.y)), each horizontal displacement has magnitude at most float32(.0025)*S*Y. Expand X/Z by that amplitude times (1+16*2^-23), plus 1e-5 model metres; leave Y unchanged. Then propagate existing gamma8 highp model-view/projection intervals; the first affine stage reserves its eighth operation for the wind coordinate addition (three products, three partial additions plus translation otherwise use seven). The trig mathematical range is [-1,1]; the 16-ulp/1e-5 numerical slack is explicitly stated and R-authorized, not a universal proof of every GPU trigonometric implementation. Unknown deformation/nonfinite values/insufficient highp still retain the complete source. Actual exact image+depth captures remain the acceptance test. No fixed half-metre assumption, reach change, simplification or shader edit.

## Initial exact results

Shipping Sloan 40 m: original 560,465/111 shadow T/D → conservative unbounded version 206,614/101 → finite wind 26,164/40. Shipping Sloan 150 m: 572,162/113 → 223,517/105 → 43,729/38. These save an additional 180,450/179,788 shadow triangles versus the approved unbounded version; both are below 150k. Shipping Sloan 600 m: 75,831/4 → 12,578/1 → 0/0, with a depth-clear control and exact unchanged pixels, not a shortened reach. All three fresh/repeat and OFF/ON image/depth comparisons are exactly 0/0, differing bytes 0. No shadow-only freeze or LOD fallback is needed for these fixed views. The complete matrix is recorded below.

A temporary batch wrapper used the status spelling `complete` instead of the capture tool's `completed`, and stopped before running any remaining batch. The accepted Sloan capture itself completed and passed; the wrapper spelling was corrected, then remaining batches resumed. No failed render is hidden or counted.

## Producer boundary at the finite-wind milestone

A4 reported its **plan**, not a completed far sidecar: existing package LOD1, additive hash-bound companion, complete-parent nearest-bound >=400 m, original near geometry and shadow casters retained. Consumption is not started. A5's water/ring prototype is merged as d82a68d; its report records pooled native water already present and explicitly leaves device qualification unproven. The final consumer must also keep the entire 40/150 m view on original transforms/order; a distance-only predicate cannot silently enable far rebaking in those views. Target-pose altitude and complete-parent distance are independent safeguards.

## Native change boundary — proposed, not edited

To consume the same general visibility/caster rule natively, shared files would be required: Sources/WorldEngine/World.swift (feature/instance caster entities and selected geometry); Sources/WorldEngine/RenderResources.swift (stable shadow-only resources); a new Sources/WorldEngine/ShadowCells.swift and Tests/WorldEngineTests/ShadowCellsTests.swift (native wind envelope and selection tests). The native deformation is different: WorldShaders.metal:497–528 `worldFoliageGeometry` uses weather windStrength, foliageSway, pow(clamp(modelY,0,1),1.5), distance fade and world wind direction, rotated/scaled back into model space. Its seasonal leaf-drop path can collapse a lobe to model point (0,.5,0), which must also be enclosed. Reuse that exact native formula and bound its sine; do not copy the web .0025 amplitude. RealityKit automatic projection/cascades are not exposed as this web orthographic frustum. Prove conservative native light bounds without reducing approved reach, or retain original casters; separately count every submitted shadow pass. No shared Swift/native files have been edited. R's file gate applies before implementing this plan.

## Ledger text for A3

Approved lossless shadow/source-run branch merged 6e76ca7. Web is default off; native transfer remains unimplemented/unqualified. The old stop-at-draw-budget requirement is superseded by R's latest approximate-shadow/far-geometry decisions; historical failed budget measurements remain preserved.

## Final finite-wind qualification

All 24 comparisons (12 fixed + 12 stress) and 24 fresh/repeat controls pass exact decoded image and sampled 2048² shadow depth: max 0, mean 0, differing bytes 0. Matched source hashes are enforced by summarize-finite-wind.mjs; shadow counters reconcile to actual backend submissions. Light-edge and off-screen witnesses are present and low-sun maps contain non-clear depth. [Machine evidence](../../web/bakeoff/evidence/spatial-cells/finite-wind.json).

| Contract / view | Original shadow T/D | Finite-wind shadow T/D | Image/depth max, mean |
|---|---:|---:|---|
| scoreboard/sloans-lake/40 | 560,465/111 | 26,164/40 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/150 | 572,162/113 | 43,729/38 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/600 | 75,831/4 | 0/0 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/40 | 924,485/123 | 23,935/41 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/150 | 996,184/149 | 45,313/39 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/600 | 2,280/1 | 0/0 | 0, 0 / 0, 0 |
| bakeoff/sloans-40 | 69,639/62 | 61,209/60 | 0, 0 / 0, 0 |
| bakeoff/sloans-150 | 67,961/42 | 21,291/32 | 0, 0 / 0, 0 |
| bakeoff/sloans-600 | 0/0 | 0/0 | 0, 0 / 0, 0 |
| bakeoff/lakeview-40 | 76,124/79 | 67,505/76 | 0, 0 / 0, 0 |
| bakeoff/lakeview-150 | 73,212/62 | 26,436/51 | 0, 0 / 0, 0 |
| bakeoff/lakeview-600 | 0/0 | 0/0 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/light-edge | 526,080/118 | 43,637/42 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/offscreen-caster | 581,616/117 | 29,444/41 | 0, 0 / 0, 0 |
| scoreboard/sloans-lake/low-sun | 579,573/126 | 86,468/97 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/light-edge | 1,003,011/147 | 47,521/40 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/offscreen-caster | 933,875/146 | 50,363/38 | 0, 0 / 0, 0 |
| scoreboard/lakeview-sheil-park/low-sun | 995,299/145 | 87,157/101 | 0, 0 / 0, 0 |
| bakeoff/sloans-light-edge | 68,282/41 | 22,466/29 | 0, 0 / 0, 0 |
| bakeoff/sloans-offscreen-caster | 68,081/42 | 21,411/32 | 0, 0 / 0, 0 |
| bakeoff/sloans-low-sun | 69,639/62 | 63,106/62 | 0, 0 / 0, 0 |
| bakeoff/lakeview-light-edge | 74,353/67 | 27,552/45 | 0, 0 / 0, 0 |
| bakeoff/lakeview-offscreen-caster | 73,308/62 | 26,532/51 | 0, 0 / 0, 0 |
| bakeoff/lakeview-low-sun | 76,124/79 | 69,672/76 | 0, 0 / 0, 0 |

24 focused tests pass (10 shadow bounds/fail-closed/resource tests +14 spatial tests). Accepted admissions: 5.95, 6.89, 9.26, 5.95, 7.54, 6.64, 7.54, 6.50; all <25; locks released after each run. Batch coordinator was suspended at a release boundary to give A4/A5 a turn, without interrupting their or our captures or editing any lock.

## Post-merge default scoreboard

All 24 default shipping frames completed after merge 6e76ca7, wall time 1259.9 s including admission waits. 0/24 floor and 0/24 provisional standard budget passes; unchanged default route remains over budget. This is the required existing scoreboard, not the candidate bundle and not a visual score. Full per-frame T/D, floor/standard and structural checks: [post-merge scoreboard](../../web/bakeoff/evidence/spatial-cells/approved-postmerge-scoreboard.json). The new finite wind module was OFF in that run.

## Default source integrity

The following shipping sources match current main byte-for-byte:

- `web/bakeoff/main.js` SHA-256 `7ca8bb66947cfcce503f6a1de3f741e08419333cf1160d1e07ba92bff0fbc188`.
- `web/src/world.js` SHA-256 `e521c5b09ea1044b69bc1a3133dbd0050ce7b23d8627b728448e964bd295030c`.
- `web/src/materials.js` SHA-256 `9256b5c5114bb5cfe6af915251ffcd6f3a6648c68d013dbbc86900bbe0a41883`.
- `Sources/WorldEngine/Shaders/WorldShaders.metal` SHA-256 `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`.

## Ledger text for A3 — finite-wind result

Default-off web shadowCells now includes the bounded known wind envelope. Exact gate passes 24/24 comparisons +24/24 controls. Sloan 40/150 shadow costs 26,164/40 and 43,729/38, saving 180,450 and 179,788 triangles versus the approved unbounded selector. No approximate fallback is required for those fixed views; no reach change. Default shipping/native shaders unchanged. Raw OFF/ON paths for scoring/review are in finite-wind.json; A10 assigns no score. The full candidate bundle, producer far/water integration and native counterpart remain pending; do not record floor adoption from this shadow-only evidence.

## Candidate bundle qualification — capture contract

The new explicit all-flags route composes existing spatialCells, spatialMergeRuns, shadowCells, contextRing (including mapped buildings where a source exists), lightTrial=on and paletteB=tableA. All flags remain OFF by default. No look constants, budgets, crown mode, production renderer or native source changes. Read additionally: shadows.md wind/culling contract; spatial-cells-design.md recommendation; world-edge-options.md context recommendation; palette-diagnosis.md table A; web/bakeoff/evidence/light-trial/README.md existing trial; web/bakeoff/evidence/far-water-ring/README.md representation and native parity; docs/research-gpt/mobile-rendering-v1/README.md §§Evidence and budget contract, Top 10, RealityKit / Metal availability (research proposals, superseded budget arithmetic). The two approved calibration mocks above and matched candidate OFF/ON frames are the visual references, with no A10 score.

The candidate uses the existing bakeoff look renderer with full shipping-scoreboard packages and the scoreboard's camera/date/viewport. Its pass counts cannot be mixed with the shipping-material scoreboard. Independent OFF repeats must be exact; ON look differences are retained for A3. Shader clock is pinned only in the capture worker. Raw PNGs stay outside Git; manifests bind PNGs, source files, package hashes, actual pass submissions, camera checks and floor/standard checks.

Preparation initially refused an unexecutable wrapper with Permission denied, then completed using bash under admission. Sloan V1 stopped before any frame with `Cannot read properties of undefined (reading 'dem') at addFrontRange`: the worker had removed the existing Denver backdrop fixture. V2 retains that original fixture. West Highland V1 stopped during 150 m ON with `page.waitForFunction: Target page, context or browser has been closed`; its partial manifest remains preserved and a fresh V2 retry is separate. No failed control is accepted or masked. West Highland's context exporter reports missing-context-source, so that hold-out cannot establish mapped-building ring coverage.

Greenville's exported package exists, but the existing bakeoff regional adapter supports Denver and Chicagoland, not Greenville. Its three candidate views are explicitly unqualified rather than borrowing a false regional appearance. The default shipping scoreboard above does measure Greenville. No inferred candidate counts or look are substituted.

Evanston V2 fails its full-image OFF repeat: max 80 byte units, mean 0.04929291595121736, 2,967 differing bytes. All 989 differing pixels lie on row 27, x8–996: the lower edge of the translucent attribution rectangle. World pixels outside that row are exact. This is a full-image control failure, not accepted under a masked region; raw frames and manifest are retained at `/private/tmp/a10-budget-bundle-evanston-south-v2/`. An unchanged-source fresh retry is diagnostic; acceptance cannot erase this observed nondeterminism.

Phone-width inspection board `/private/tmp/a10-candidate-phone-board.png` presents Sloan150 OFF, ON and the approved Sloan mock, each 390 px wide. It was opened and inspected. Existing mapped bright-orange roof groups remain unchanged; the street-level mock cannot calibrate the aerial composition. No scores assigned.

Capture-only control repair: the attribution uses 9px text × inherited 1.5 line-height + 6px padding = 19.5px height. The observed repeat difference is exactly its half-pixel bottom edge. The remaining worker pins that credit line-height to 14px (20px box); attribution and every pixel remain present. This changes capture UI only, not world rendering. Earlier accepted captures retain the original style; every within-area OFF/ON pair shares its style. The summary explicitly permits only this worker-hash revision and lists it per row; render-module and served fixed-clock hashes must still match. The repaired repeat is measured, not assumed.

## Candidate per-frame budget results

19 measured views: 17 floor /18 standard passes. Five views remain unqualified: Greenville40/150/600 (regional adapter absent), Winnetka150/600 (180000 ms stability timeout). Winnetka40 completed its OFF/repeat/ON trio before that failure; its source hashes match the other frames. No missing measurement is counted as a pass. All 19 accepted OFF repeats are exact. Candidate ON differences are intentional look trials, reported without masking or scoring. [Counts, differences and all OFF/ON frame paths](../../web/bakeoff/evidence/spatial-cells/candidate-bundle.json).

| View | OFF main T/D | ON main T/D | ON shadow T/D | Floor / standard |
|---|---:|---:|---:|---|
| sloans-lake/40 | 791,213/184 | 89,454/52 | 61,367/60 | PASS / PASS |
| sloans-lake/150 | 935,422/257 | 245,049/81 | 21,405/32 | PASS / PASS |
| sloans-lake/600 | 698,361/305 | 412,672/117 | 0/0 | FAIL / PASS |
| lakeview-sheil-park/40 | 1,084,028/219 | 92,088/45 | 78,074/91 | PASS / PASS |
| lakeview-sheil-park/150 | 1,209,778/238 | 374,137/89 | 38,399/33 | PASS / PASS |
| lakeview-sheil-park/600 | 960,351/219 | 547,180/69 | 0/0 | FAIL / FAIL |
| wilmette-vattmann-park/40 | 539,594/217 | 49,790/40 | 52,381/109 | PASS / PASS |
| wilmette-vattmann-park/150 | 526,404/234 | 191,244/88 | 24,975/54 | PASS / PASS |
| wilmette-vattmann-park/600 | 378,991/226 | 239,028/63 | 0/0 | PASS / PASS |
| west-highland/40 | 970,403/251 | 42,932/42 | 50,753/108 | PASS / PASS |
| west-highland/150 | 920,831/254 | 252,393/84 | 12,848/44 | PASS / PASS |
| west-highland/600 | 783,076/238 | 358,627/65 | 0/0 | PASS / PASS |
| evanston-south/40 | 525,893/242 | 60,786/48 | 56,613/114 | PASS / PASS |
| evanston-south/150 | 495,636/231 | 154,224/86 | 22,737/60 | PASS / PASS |
| evanston-south/600 | 355,096/241 | 172,283/65 | 0/0 | PASS / PASS |
| kenilworth-station/40 | 429,058/218 | 45,804/35 | 17,147/55 | PASS / PASS |
| kenilworth-station/150 | 422,859/239 | 177,458/88 | 7,390/24 | PASS / PASS |
| kenilworth-station/600 | 369,837/239 | 255,201/67 | 0/0 | PASS / PASS |
| winnetka-village-green/40 | 322,738/198 | 28,096/36 | 20,017/88 | PASS / PASS |
| winnetka-village-green/150 | — | — | — | UNQUALIFIED / UNQUALIFIED |
| winnetka-village-green/600 | — | — | — | UNQUALIFIED / UNQUALIFIED |
| greenville-downtown/40 | — | — | — | UNQUALIFIED / UNQUALIFIED |
| greenville-downtown/150 | — | — | — | UNQUALIFIED / UNQUALIFIED |
| greenville-downtown/600 | — | — | — | UNQUALIFIED / UNQUALIFIED |

The bundle has not reached floor at Sloan600 (412,672/117) or Lakeview600 (547,180/69). This is a different look renderer from the shipping scoreboard, not a disagreement to hide in the CPU model. West Highland and Greenville lack context-source exports; no buildings are invented. A4's producer report on 9 October gives a completed separate far-parent trial; its source bindings match the packages here. The consumer stage can now begin. Native implementation remains at R's shared-file gate; the earlier asynchronous file-list question is unanswered, so no Swift/native changes are authorized here.

## Ledger text for A3 — candidate bundle

Default-off combined web route captured 19/24 scoreboard views: 17 floor/18 standard. Four requested hold-outs have explicit per-view rows: Lakeview, Wilmette and West Highland measured; Greenville cannot run this existing look adapter. Wynn150/600 timeout retained; no promotion. All accepted repeat controls exact; palette/light/context paired scoring belongs to A3. Raw OFF/ON images are in candidate-bundle.json. Native not implemented or qualified.

## Reported A4 dependency and far consumer

A4 reported its completed/rebased three-area validation on 9 October, then stopped on stash-restoration conflicts in its STATE.md/handoffs.md. This lane imports only its reported final source/tests/report/machine evidence; none of its ledgers or conflict markers. Initial producer commit f2b28da is provenance, not a claim that it contains the final corrected bounds. The copied spatial-far.js, exporter and qualifier SHA values match A4's rebased capture summary. Original/package/GLB and payload bindings were checked before copying the two additive sidecars. No geometry export was run or rewritten by this consumer.

The independent candidate-far-runtime adapter consumes A4's unchanged representation and adds a conservative view-height gate: camera Y minus the larger of declared package maximum Y and A4's actual complete-core static maximum Y must be >=400 m. This includes every original and simplified ground/static point; it is conservative relative to exported ground, rather than an assumed zero datum. The current flat-datum packages declare 40 m, above their actual static maximums (11.45 /25.49 /15.95 m). Missing/nonfinite bounds reject the trial. A4's complete-parent 3D distance and visible changed-building near-plane tests still apply. A 40/150 m camera outside the core cannot activate the trial solely because it is distant. On descent, restore exact original source visibility and remove farShadowVisible overrides. Unknown static deformation rejects far consumption. No new shadow reach or caster LOD.

Original far-hidden rigid sources retain shadow visibility in shadowCells; the parent itself casts no shadows. The actual caster test verifies full selected source submission while main visibility is false, and a hidden ancestor still disables it. A5 farWater and two-draw ring consume their existing representation with the same conservative height predicate. Ring pooling restores the original source objects/geometry/IDs below the threshold and reuses the pool on ascent; a transition test verifies exclusive coverage and unchanged source indices. All options require the explicit bundle and separate `farParent=1&farWater=1&contextMerge=2`; shipping defaults remain unchanged.

Used additionally: A4 simplified-far-parent.md §§Decision/contract, Validation, Rebase verification; facades.md §§One general rule, Exact values/coverage (authority, not a v2 migration); REFERENCE-MAP Facades/Context/camera gaps; facade-detail-v2 and v2b STATUS (immutable base colours, classification scope). Opened facade-detail-v2/panels/12-chicago-apartment-block-far.png and 09-denver-mixed-use-strip-far.png as qualitative form references only. No colours/dimensions were sampled or family classifier changed; A4 reuses the package's pre-existing LOD1 instead of adopting v2/v2b. There is no approved calibrated 600 m whole-scene target, so A3 judges the requested matched pairs.

A4's payloads duplicate original ground and cost 49,264,633 /66,786,122 /46,662,547 bytes (Sloan/Lakeview/Wilmette), with original resources still resident. This is not a memory or device pass; Lakeview exceeds the 48 MiB production policy even before original buffers. No budget is raised to accommodate it. Shipping main/world/material/Metal source hashes remain identical to approved merge 6e76ca7.

### Consumer setup failures, retained

Far bundle V1 stopped at Sloan40 ON with `Far source coverage mismatch`. Existing main.js replaces the mesh's static material but leaves world.materials.static referring to the loader material. V2 uses the actually bound compatible material; it stopped with `Ambiguous far source identity`. Seven chunks have the identical local four-vertex geometry fingerprint `4/6/291370567`, so a hash alone cannot identify a chunk. These are binding failures before a candidate PNG, not pixel passes. Both BEFORE controls were exact, and both failed directories remain intact.

V3 follows the loader's documented manifest chunk order (the same contract facadeColours already uses), verifies exactly one matching static source and the expected signature inside each chunk, and passes that ordered source list to the transfer. No geography, feature ID whitelist, sort relaxation or exporter change. The parent reuses the actual compatible static material. Existing _facade assignments are copied by ordered feature plus original paint slot; ambiguity/missing provenance stops before swapping, and uncovered far paint slots retain the original palette fallback with a reported count. This supplies the attribute required by the existing matte shader without classifying or recolouring any building. Focused tests cover repeated local signatures with different feature overrides, actual material replacement, exact original restoration and caster visibility. A4's copied runtime/exporter bytes remain identical to its reported source hashes.

## Final far-consumer qualification

V3 stopped before a candidate frame with `Ambiguous within-feature facade assignment`: a feature/paint slot can include both declared facade body and non-body geometry. V4 resolves this through the producer's hash-bound `lod1.static` ranges, not a guessed normal or colour predicate. Preparation rechecks original scene/LOD1 SHA values, reconstructs the producer's vertex-first-appearance ordering and copies only the original declared body overrides; temporary parsed resources are disposed. Missing provenance fails closed. The focused test covers a body and non-body sharing a slot. A4 runtime/exporter/qualifier remain byte-identical to its reported final source.

52 focused tests passed under heavy admission; every V4 capture admitted below load 25 and released its lock. All 27 frames completed. Nine independent BEFORE repeats and all six 40/150 m BEFORE/AFTER comparisons are exact full-image max/mean/count 0/0/0. Original shadow triangle/draw submissions remain unchanged at all nine views. The far parent, pooled water and pooled ring are active only at 600 m. Machine evidence includes source/package/frame hashes, actual pass counts, flags and all raw paths: [far-bundle.json](../../web/bakeoff/evidence/spatial-cells/far-bundle.json).

| View | AFTER main T/D | AFTER shadow T/D | Floor / standard |
|---|---:|---:|---|
| Sloan40 | 89,454/52 | 61,367/60 | PASS / PASS |
| Sloan150 | 245,049/81 | 21,405/32 | PASS / PASS |
| Sloan600 | 294,354/53 | 0/0 | PASS / PASS |
| Lakeview40 | 92,088/45 | 78,074/91 | PASS / PASS |
| Lakeview150 | 374,137/89 | 38,399/33 | PASS / PASS |
| Lakeview600 | 200,364/55 | 0/0 | PASS / PASS |
| Wilmette40 | 49,790/40 | 52,381/109 | PASS / PASS |
| Wilmette150 | 191,244/88 | 24,975/54 | PASS / PASS |
| Wilmette600 | 134,377/50 | 0/0 | PASS / PASS |

At 600 m the full pre-far bundle → consumer main deltas are Sloan 412,672/117 →294,354/53 (−118,318 triangles/−64 draws); Lakeview 547,180/69 →200,364/55 (−346,816/−14); Wilmette 239,028/63 →134,377/50 (−104,651/−13). Shadow draws have no tier limit. These are actual bakeoff passes, not shipping-material or native counts.

Intentional far-look full-image differences, byte units: Sloan max127 /mean0.1773389688724519 /35,061 differing bytes; Lakeview 149 /0.7189569849865716 /116,002; Wilmette118 /0.2155628934971162 /50,117. These are not lossless claims and are handed to A3 without a score. Phone-width paired board `/private/tmp/a10-far-review.png` was opened: existing ground/road coverage remains visible; far building detail changes remain for paired judgment. No calibrated whole-scene 600 m mock exists.

A3 frame directories (all contain `40`, `150`, `600` × `before`, `repeat`, `after` PNGs): `/private/tmp/a10-far-bundle-sloans-lake-v4/`, `/private/tmp/a10-far-bundle-lakeview-sheil-park-v4/`, `/private/tmp/a10-far-bundle-wilmette-vattmann-park-v4/`. Before is the explicit candidate bundle; after adds separate farParent/farWater/contextMerge flags. Earlier default OFF versus candidate ON paths remain in candidate-bundle.json. Raw failed V1/V2/V3 directories are preserved; a mistaken summary-tool path produced MODULE_NOT_FOUND, corrected to web/bakeoff/tools with no rendering rerun.

The web target now passes, default off. This does not repair the five unqualified scoreboard rows, absent Greenville look adapter, missing mapped-building context in West Highland/Greenville, or Lakeview sidecar memory excess. Native implementation/qualification still requires R's shared-file approval; no answer has been received and no native files were edited. A3 look approval remains pending.

## Ledger text for A3 — far consumer

Default-off consumer of A4's reported final sidecar plus A5 water/ring reaches floor and standard in all nine measured Sloan/Lakeview/Wilmette ladder views. Near pairs and all repeats exact; unchanged shadow submissions; 600 m differences intentionally retained for A3 paired scoring, no A10 score or promotion. Frame paths and full numeric deltas are above. Shipping main/world/material/Metal bytes unchanged. Native shared-file gate, production-memory limit and remaining scoreboard/hold-out gaps prevent adoption claims.
