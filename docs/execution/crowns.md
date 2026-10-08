# American elm crowns — native execution brief, restart batch 1

**One general rule:** every `ulmus_americana` uses the same branch-connected, open-vase crown recipe and budgeted LOD policy. Species, dimensions, season and stable seed are data; no block, coordinate or capture-altitude exceptions. P2 owns mesh construction; 5A owns the bounded native batching/LOD adapter and reviews colour preservation. A3 owns blind scoring.

Docs-only specification; inspected main `e49b2f0`. R's supplied approval is dated **9 October 2026**, as recorded in [crown STATUS](../proposals/crown-silhouettes-v2/STATUS.md) and [MOCKS](../tracking/MOCKS.md). Historical pending captions and the crown exclusion in older execution briefs are superseded for this task. **Standard is R's prototype target**; older floor-only restart stop wording does not override this instruction. Floor compliance remains an independently reported gap. No new score, implementation or measured native cost is claimed here.

## Research and exact judgement references

Implements [foliage-rendering-v1](../research/foliage-rendering-v1.md), silhouette/LOD allocation recommendation, using the method in [foliage-exp1-spec](../research/foliage-exp1-spec.md) “Before / after frames” and “Cost and stop conditions”. The experiment's [final evidence](../research/foliage-exp1-native-final-evidence.md) and [A3 scores](../lookloop/foliage-exp1-native-scores.md) establish **foliage 2/5 in all nine frames**: shading was not the effective lever in that experiment. Freeze shader, palette, lights, AO and the existing default-off emissive behaviour; do not rerun removal/layered shading as part of this candidate.

Approved shape authority: [crown values](../proposals/crown-silhouettes-v2/values.json), `content.speciesByCity.denver[name=American elm]`, matching Chicago elm entry, `content.construction` and `lod`. Local pixels under `~/Desktop/world-engine/docs/proposals/crown-silhouettes-v2/`:

- `panels/01-american-elm.png` and `14-american-elm.png`: same species in two regional contexts; neither authorizes location-specific code.
- `panels/17-branch-scaffold.png`, `18-lower-layer.png`, `19-middle-layer.png`, `20-upper-layer.png`, `21-near-crown.png`, `22-middle-crown.png`: scaffold → layered crown → reduced crown.
- `images/03-lobe-construction.png`: branch-connected layering; `images/04-distance-fade.png`: distance simplification principle. The latter's honeylocust/spruce examples are not an elm geometry template.

Overall light/style: `~/Desktop/world-engine/docs/proposals/style-b-calibration-v2/frames/06-sloans.png`; Chicago/Wilmette `frames/01-lakeview.png`. Preserve [foliage-seasons-v1](../proposals/foliage-seasons-v1/) seasonal authority. **sky-cloud-v1 and street-ground-v1: not approved, excluded.** Record reference hashes before execution. Missing pixels or changed approvals stop the comparison.

A2 comparison evidence: `web/bakeoff/evidence/crown-v2/REPORT.md`, inspected in the same repository's A2 working checkout `/private/tmp/worldengine-a2-bakeoff` (HEAD `aa3a068`); it is **not present on inspected main**. Its control is `7ff7e24c8053a661a2efde11fd1fea24bc6e735b`. Preserve/report its content hash when consuming it; uncommitted report content is not pinned by the checkout SHA. A2 reports elm **2,606 / 910 / 102 triangles** near/middle/far, and Sloan main **347,177 / 99 → 709,557 / 117** triangles/draws. These are web CPU submission estimates, not native timings or accepted pixels. Its 705 elms, four variants and projected LOD promotions cannot be transplanted as a native budget. The result exceeds standard main triangles by **209,557**, with only three main draws of standard headroom; it also exceeds hero by 109,557 triangles.

## Exact future files and ordered change

| File / symbol | P2 or 5A action |
|---|---|
| `Sources/WorldGen/Props.swift`: `PropLibrary.mesh`, `deciduous`, `lobes(.treeVase)`; helpers `bareSkeleton`, `addBareBranches`, `addBranch`, `fineLobes`, `speciesLumpyLobes`, `blendedCrownNormal`, `bakeCrownAO`, `farShellTree`, `farTree`, `skylineTree` | P2 adds an elm-specific mesh route and layered scaffold recipe. Keep existing AO/normal/paint conventions, dimensions and other species. `.treeVase` also serves cottonwood: changing that case globally is incorrect. |
| `Sources/WorldGen/SceneGenerator.swift`: `PropInstance.species` and existing species assignment; `Sources/WorldGen/Foliage.swift`: `FoliageSeasons.kind` / `widthScale` | Trace existing `ulmus_americana` identity through the mesh request. Preserve source identity, positions, counts, scale, width and seasonal mapping. Do not multiply mapped width twice. Missing species uses the unchanged fallback. |
| `Sources/WorldEngine/World.swift`: `cached`, `buildProps`, `LODGroup`, `LODBatch`, `updateLODs` | 5A handoff: add recipe identity to cache/group keys; route only elms; implement measured-cost nearest-first promotions. Existing `kind/variant/lod` keys are insufficient to distinguish elm from cottonwood. Preserve culling and cut-away behaviour. |
| `Sources/WorldEngine/PostcardQuality.swift`: `applyQuality`, `setInstances` | 5A checks that inspection/postcard submission and counters retain selected elm meshes/LOD; avoid a second conflicting LOD or budget policy. |
| `Tests/WorldGenTests/` (new focused `ElmCrownTests.swift`, existing foliage/leaf-atlas tests) | P2 adds deterministic geometry/identity/budget checks described below; no broad snapshot rewrite. |

1. Freeze current-main baseline, all input hashes and full loaded coverage. Inventory elm count, visible count by LOD, actual mesh counts, other-foliage and non-foliage costs at all three cameras before choosing promotions. Do not alter scene membership.
2. Preserve all non-elm routes. Add one elm recipe identifier through the paths above, including cache keys and shadow accounting. Start with **one geometry variant per LOD**, retaining existing per-instance yaw, dimensions, colour and season seed. Mesh construction uses `StableRandom`; do not use unstable hash/random functions or four new geometry variants. If variant affects seasonal identity, keep that identity separate from the geometry key.
3. Construct an upward, spreading woody scaffold; lobes attach to limb endpoints, leaving the lower centre open. Use **three layers** (within approved 3–5), **16 near / 6 middle / 3 far** primary lobes (approved ranges 16–32 / 6–12 / 3–5). Batch-1 authored allocation: near layers **4/6/6**, middle **2/2/2**, far **1/1/1**. Reuse the normalized tree envelope and scaffold coordinates; select/merge connected branch fans deterministically rather than placing disconnected spheres. Preserve top/spread/extremal limb silhouette across LODs. Layer counts are implementation choices, not measurements from the picture.
4. Use pack primary-lobe radius range **0.8–2.5 m** for the reference tree, scaled with its existing size; do not clamp every juvenile to mature absolute radii. No new inferred tree heights. Let the reference envelope and existing `widthScale` own dimensions. Coarse ellipsoid lobes must overlap at branch junctions without closing the vase centre. Keep existing bark and crown vertex flags/AO packing; no new leaf atlas, alpha cards, secondary clusters, shader tint or crossfade in batch 1. Approved secondary scale 0.15–0.45 m and <2 px cull remain future work, not an obligation to add geometry now.
5. Produce the cost-capped chain below, inspect single-tree silhouette/bounds, then wire native budgeted LOD. Retain current skyline fallback and seasonal bare-tree handling. Never replace a leafless elm with an opaque summer crown. No changes to tree count, coverage radius, shadow reach, ground, water or overall lighting.
6. Run geometry/accounting tests, capture the nine frames, have A3 grade blind, then run paired untouched hold-outs. Freeze the shape result before the later water and general budget batches. Builders update the integration/mock ledger with the actual consuming build; approval alone is not consumption.

## Budget and nearest-first allocation

[Device tiers](../perf/device-tiers-v1.md): **floor 400k main / 150k all-pass shadow / 100 main draws; standard 500k / 180k / 120; hero 600k / 225k / 140**. Standard is this prototype ceiling, not measured device capacity or permission to use hero. Report total texture/mesh/target memory and timings separately; Simulator captures cannot certify phone performance.

**Authored starting allowance, not a measured capacity:** total foliage main target **120,000 triangles**, subject to `F = max(0, min(120000, 500000 - N - 20000))`, where `N` is measured non-foliage main submissions for that frame. The 20k is planning headroom, not a new product requirement. Subtract unchanged non-elm foliage `U`: elm allowance `E=max(0,F-U)`. If the fallback elm chain alone exceeds E, stop/report; do not delete trees or steal another feature's budget. Reconcile measured N/U before execution; this brief cannot predict the scene total from a web sample.

| Native complete tree mesh | Expected upper allocation (hypothesis) | Construction allocation |
|---|---:|---|
| Near | **1,200 triangles** | 16 opaque lobes ≤60 each + woody scaffold ≤240 |
| Middle | **360 triangles** | 6 lobes ≤40 each + woody scaffold ≤120 |
| Far | **80 triangles** | 3 lobes ≤20 each + wood ≤20 |
| Skyline fallback | **12 triangles** | Keep existing skyline cap/identity; verify actual output |

These include wood, not just leaf crowns. They are proposed caps to test, not native measurements or approved pack triangle counts. Existing native near/middle caps are smaller; this is an explicit elm-only allocation change. If matching the approved silhouette requires more, stop and report the measured tradeoff rather than silently borrowing the web meshes. Combined geometry remains one material submission per occupied batch/slot, not one draw per lobe/tree. One variant implies at most five elm slots (near cut-away, near opaque, middle, far, skyline), but this is **not** a guaranteed +5 total: existing splits/materials/shadow passes must be counted.

Algorithm: retain current visibility and shadow eligibility, seed every eligible elm with its cheapest valid far/skyline representation, reserve that cost, then consider promotions in ascending **3D eye distance**, stable source-ID tie-break. Use actual crown projected height in **drawable pixels**: desired near ≥20, middle ≥6, otherwise far; 10% hysteresis from `lod`. Retain existing skyline-distance rule for sub-6 px distant crowns; no disappear-by-budget fallback. Promote only when the incremental actual triangle cost and any newly occupied draw slot fit E and the whole-scene standard limits. Re-evaluate on camera/FOV/viewport changes, not movement alone. A 40/150/600 m camera altitude does not select a tree LOD; view distance and projection do. Use consistent reference bounds, not whichever LOD happens to be active. Log requested versus assigned LOD and budget-denied promotions. Large denied crowns are a visible budget failure to score, not an excuse to enlarge features.

Count `sum(mesh.triangleCount × submittedInstanceCount)` by LOD/batch, including wood, cut-away slots and every actual submitted duplicate. Whole-scene main = non-foliage + non-elm foliage + elm. Count each occupied draw/material/pass; post-processing draws remain separately labelled, never hidden. All-pass shadow = the sum of submitted triangles over every shadow pass/cascade, including off-camera casters. Do not assume web's 102-triangle shadow proxy exists on RealityKit. Retain native caster policy/reach, measure its actual selected meshes; if a separate shadow proxy is needed, hand off to 5A and stop this candidate until cost/appearance is accounted for. Record raw counters versus estimates explicitly.

Report per-frame floor gaps `max(0, main-400000)`, `max(0, shadow-150000)`, `max(0, mainDraws-100)` alongside standard headroom. The repository's strict floor boundary still applies; exactly reaching a strict cap is not a floor pass. Example only: 20 near +100 middle +300 far = **84,000 elm triangles**, before skyline/other foliage/scene/shadows; it is arithmetic, not a predicted Sloan count.

## Tests, nine-frame capture and A3 acceptance

Before capture, test: identical seed produces identical buffers; elm-only dispatch leaves cottonwood/unknown species and non-elm meshes unchanged; finite vertices/normals, valid indices, per-LOD cap and envelope preservation; woody attachment and open centre via silhouette review; full bare-season identity; no doubled width; budget allocator conserves all eligible instances, uses stable nearest-first order, respects actual costs/slots, and behaves at 6/20 px plus hysteresis boundaries. Count tests must include cut-away and multi-pass shadows. Run focused tests/build under the heavy protocol, not a render-editing session by A5.

**Nine frames = three altitudes × three states: fresh BEFORE, repeated BEFORE noise control, AFTER shape candidate.** This replaces the former off/remove/layered matrix; all nine use foliage-exp1 **off**, identical shader hash and exposure settings. Baseline-repeat is a second independent settled capture of the same control build. Record actual baseline score rather than assuming it remains 2.

Freeze Sloan pose **39.7511195,-105.0389,ALT,270,45**, ALT **40/150/600 m AGL**, date **2026-10-15T20:30:00Z**, clear/cloud0/wind0, character none, RealityKit, HUD off, original FOV, **1005×565** drawable, matching [final native evidence](../research/foliage-exp1-native-final-evidence.md) and [capture contract](../lookloop/a3-capture-contract.json). Inspection uses app `-inspectionpose`; the wrapper spelling is `--inspectionpose`. Reconcile the contract and recorded metadata before accepting any frame.

For each state/build and altitude, use the existing command (replace ALT and unique RUN path; never overwrite a prior run):

```sh
HEAVY_LOAD=25 scripts/capture-native.sh --view ordinary-street-afternoon \
  --inspectionpose '39.7511195,-105.0389,ALT,270,45' \
  --foliageexp1 off --output .build/lookloop/RUN
```

`capture-native.sh` already acquires `scripts/heavy.sh`; **do not wrap it in another heavy lock**. Keep 1-minute load strictly <25, ≥8 GB free, one Simulator, preserve others' `~/.agent-heavy-lock`. No phone install. Rebuild/install the correct control or candidate revision for each group; `--foliageexp1 off` does not choose the crown revision. Save SHA, mesh/shader/metallib and input hashes, requested/observed pose, drawable size, environment, loaded tile IDs/counts, all tree counts and the cost ledger beside each image. The previous 600 m mismatch was a loading race: verify matching fully loaded coverage before accepting captures. If the wrapper cannot prove settled coverage, reject that run and resolve readiness with its owner; waiting an arbitrary fixed interval is not proof.

A3 receives randomized A/B identifiers and the reference pixels, with the state mapping withheld until grades are locked; include BEFORE-repeat controls and identical phone-size presentations. Score closeness and every aspect using [GRADING](../lookloop/GRADING.md) §M/§N. AFTER hypothesis: recognizable upward elm fans, branching/open centre and coherent broad lobes at 40/150 m; stable spreading silhouette at 600 m. **Acceptance: foliage rises from 2 to at least 3 at both 40 and 150 m; no other aspect or overall closeness declines; 600 m does not regress; standard costs pass, floor gap explicit.** If current BEFORE differs from 2, report it and require an actual improvement, not a relabelled historical delta. No score promised; an unclear blind comparison is pending, not a pass. This experiment is not the full four-hero release gate.

After focus scoring, capture fresh paired untouched **Lakeview street/postcard, Wilmette, West Highland** using their frozen contracts; include **Greenville Downtown only once A4 data/export and native capture contract are ready**. Do not invent a camera or silently treat missing evidence as passed. Keep exactly the same recipe/budget policy. A Sloan gain with any hold-out loss is reject-flagged. Keep hold-out results separate from the nine focus frames.

Stop for standard overage in any ledger component, unknown shadow costs, altered non-elm identity/scene coverage, unmatched load state, missing approved reference, broken branch connections, spherical blob silhouette, LOD popping or inconsistent seasons, control noise that obscures the result, changed shaders/lighting, no 40/150 m gain, or any non-foliage/hold-out decline. Do not relax shadows, shrink coverage, thin trees, introduce per-block settings or try hero to rescue a failed standard candidate. Report the specific next constraint; at most one recipe candidate in this batch.

## Builder report and evidence line

Use a per-frame table: `blind ID | revealed state | altitude/pose | loaded coverage hash | elm near/mid/far/skyline counts | denied promotions | non-foliage/other-foliage/elm main tris | whole main/shadow tris | main/other draws | memory/timing provenance | A3 closeness + all aspects | floor gaps | standard pass`. Follow with hold-out pairs, deviations and keep/reject/pending. Include command/output paths and reference hashes; no inferred GPU time or image score.

Builder evidence template:

`feature=elm-crown-shape | baseSHA=… candidateSHA=… | recipe=ulmus_americana/all-blocks | pack/mock hashes=… | native mesh tris near/mid/far/skyline=… | nine-frame paths+metadata=… | A3 blind 40/150/600 before→after=… | other aspects=… | hold-outs=pass/reject/pending(reason) | whole main/shadow tris+draws=… | standard=… floor gaps=… | timing=measured/unavailable | heavy-lock/load<25=… | stops/deviations=… | decision=…`

End the execution report with the filled evidence line below, then `Tracker update:`:

`Used: crown-silhouettes-v2 values + native mesh/accounting evidence; Mock: 01/14/17–22, images 03/04, calibration 06-sloans/01-lakeview; Deviation: …; Evidence: SHAs, nine-frame manifest, A3 blind scores, hold-outs, standard ledger and floor gaps …`
