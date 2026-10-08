# A10: 600 m outer coverage investigation

8 October 2026. Existing artifacts only; no new build, Simulator run, capture, or heavy admission. A3’s [7e800f7 review](../lookloop/foliage-exp1-native-scores.md) and grades are unchanged.

## Proven cause: context attachment races the timed capture

The visible outer coverage really differs in the saved layered image; the camera pose does not. Baseline/remove each record **228,159 triangles / 43 draws**, including **7,321 context triangles / 6 context draws**. Layered records **220,838 / 37**, including **0 context triangles / 0 context draws**. Subtracting context gives exactly **220,838 / 37** in all modes. The detailed chunk/building/foliage/prop/other splits are identical. This identifies the missing asynchronous context ring, which uses static ground/road/building meshes, rather than a wider/narrower camera or a foliage-generated coverage decision.

Source launch-log order, 1-based lines:

| Mode | Context completion | VIEWREADY | VIEWSHOT | Context at shot |
|---|---:|---:|---:|---|
| Baseline | 41 | 42 | 45 | 7,321 triangles / 6 draws |
| Remove | 41 | 44 | 45 | 7,321 / 6 |
| Layered | **45, after shot** | 42 | **43** | **0 / 0** |

All three context-completion records report 18 cells and the same generated near/aerial/street/far/water triangle totals. `CONTEXT cells=…` is printed only after entity creation/attachment, LOD selection and recount, at `Sources/WorldEngine/World+Context.swift:111–125`. Thus the CPU scene finished attaching at a different phase relative to capture. We cannot infer the precise GPU completion time or the appearance of a subsequently completed layered frame from these files; those require a future properly gated capture. The printed parse/generate durations omit attachment/upload time, and event timestamps are too coarse for precise attach latency.

## Metadata and integrity

All three: requested/observed pose `39.751119500,-105.038900000,600.000000,270.000000,45.000000`, date `2026-10-15T20:30:00Z`, clear/cloud=0/wind=0, no character, 1005×565 RealityKit source, zero recorded crashes, capture code `ec14fed65c358c8b1271a93b61b1d5124ff8c5f8`. Full batch data: `/private/tmp/worldengine-a10/.build/a10-foliage-final/sloans-batch/batch.json`. Each saved PNG hash independently rechecked. Lens/projection matrices were not separately logged; the arguments, code, viewport and visible detailed footprint agree.

| Mode | Build seconds | Capture seconds | Total seconds | Frame SHA-256 |
|---|---:|---:|---:|---|
| off | 8.44 | 38.32 | 46.91 | `b127bfa00447b921ef3f11a37cc8f63acb3f52046432ef3f30693d1b5309e05a` |
| remove | 9.55 | 38.16 | 47.85 | `7656bc80dcc25f9ad7f1bc9bff5b02740dd5824d52f95f095f902b2e59376189` |
| layered | 9.33 | 37.52 | 47.01 | `0154f34a0ed49682349435328d130aec6653c0c4b8a3e01ca74f201059cec5f6` |

| Mode | Compile constant | Compiled source SHA-256 | Engine metallib SHA-256 |
|---|---:|---|---|
| off | 0 | `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a` | `7d6890038a603e48d9bce41da002dcf097a3c92219fce75e8477c651434e32ce` |
| remove | 1 | `a1664667fe7d34d38227a4f77b136db23e65785ea045ce00c61ed6bba660d488` | `becdf16677a431f4671bab56bf1a7473b2feee64ea80d899190944c02783ad5e` |
| layered | 2 | `a1664667fe7d34d38227a4f77b136db23e65785ea045ce00c61ed6bba660d488` | `d5784f7458135a8730c68e49a148de57b4a1dec78373d45ac4298f11daf3cb91` |

Common app-level default.metallib SHA-256: `2624af0882a4d3cdd0c12a4323790d72fbcb7cc971eb145c0fc9886962c372be`. Shipping source SHA-256 remains `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`, byte-identical to current main and the captured baseline. Different mode library hashes are expected; they do not prove a different camera or geometry.

## Variant scope audit

Regenerated temporary source SHA-256 exactly matches the recorded experimental source `a1664667…660d488`. Comparing text before and after worldFoliageSurface gives byte identity everywhere else, except the three leading `#ifndef/#define/#endif` mode-selector directives. FOLIAGE_EXP1_MODE appears nowhere in the shipping source and is consumed only inside the inserted foliage rule. No World+Context.swift/World.swift/frustum/bounds/road/ground/geometry changes exist in the variant build. Ground/road and context use staticMaterial, not worldFoliageSurface. No shared finish or geometry shader edit. This is a source-scope proof, not a claim that every separately compiled non-foliage GPU function is bit-identical. The decisive runtime evidence is context absent before the layered shot and attached after it.

## What permits the race

- `Sources/WorldEngine/World.swift:219–221`: start background context then return World.load; detailed-world STATS is not complete-scene readiness.
- `World+Context.swift:43–54,77–110`: detached utility build plus yielded main-actor mesh uploads/attachment.
- `Apps/WorldLab/Sources/ContentView.swift:332–344`: apply view, sleep viewSettle, print VIEWREADY, capture. There is no context wait.
- `Tools/lookloop/batch.py`: SETTLE defaults to 3 seconds; it accepts VIEWSHOT plus an existing file. STATS only resets the timeout; VIEWREADY only means the timed sleep finished.
- Capture-build `scripts/capture_native.py` verified TSV/PNG/pose/mode/hash, without checking context readiness or equal geometry coverage. `capture_foliage_exp1.py` accepted each independent run without comparing scene counters across modes.

## Tooling guard delivered; scene-ready wait proposed

The worker now derives expected context from the area manifest (using the native context-source predicate), requires a context completion **before VIEWREADY** and a post-attachment VIEW update before accepting VIEWSHOT, and rejects context failures/missing or ambiguous logs. Explicit noContext diagnostics are recognized, not mistaken for a successful complete scene. Metadata records CPU readiness evidence and explicitly `gpuCompletionProved=false`. The foliage batch compares triangle/draw/category-draw fingerprints at each altitude and stops on unmatched coverage, with no automatic recapture. Eight focused lightweight tooling tests pass; offline replay accepts existing baseline/remove 600 m CPU readiness and rejects layered 600 m. No original artifact changed.

This guard rejects known incomplete evidence; it **does not implement a pre-capture wait or prove GPU readiness**. Proposed native capture handshake (not implemented in this docs/tooling-only task):

1. Capture-only readiness state: pending/attached/not-required/failed for context and every relevant async scene task; do not change interactive first-frame behavior or rendering/culling.
2. After pose/date/weather application, await attachment completion or explicit not-required; fail on loading error or a bounded timeout. Do not replace this with a longer guessed sleep.
3. Await post-attachment camera/LOD update and renderer-submitted stable frames; verify unchanged pose, drawable dimensions and coverage counters. Counters alone do not prove pixels finished rendering.
4. Emit `SCENEREADY id=…` with requested/observed pose, context state, geometry signature and submitted frame sequence; only then allow in-app capture. External batch.py waiting after VIEWREADY cannot fix an image the app already captured. Worker must require the scene-ready record preceding that view’s capture and retain matched coverage signatures.
5. After A4’s validation is explicitly finished and the readiness hook is built/verified under heavy lock at load <25, capture a new matched batch into a new directory. Keep the old frames/review intact; A3 scores, hold-outs and confirmation rules remain unchanged. No recapture authorized by a momentarily absent lock alone.

Additional existing-file audit: baseline 150 m has no context-completion record and zero context draws; layered 40 m completes context after its shot; layered 150 m has completion before capture but still records zero context draws while remove 150 m records three. These also preclude asserting nine matched full scenes from pose/hash checks alone. The 150 m logs do not by themselves prove final GPU coverage; a complete readiness handshake is still needed. The numeric isolated-category gates remain valid.

Used: foliage-exp1-native-final-evidence.md provenance; foliage-exp1-spec.md FINAL gate; World+Context.swift context attachment; ContentView.swift runViewList; A3 review 7e800f7. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: existing-file proof and tooling guard only; native SCENEREADY hook proposed, no heavy validation or recapture while A4 is validating.

## Ledger text for A3

A3 applies these findings to current ledgers; preserve all other rows, including the newly approved crown-shape row. This commit deliberately does not edit INTEGRATION.md, STATE.md or handoffs.md.

Intended Foliage integration row (replace that row only, preserving newer score/approval details):

```markdown
| Foliage | foliage-exp1-spec.md; foliage-rendering-v1.md §1 | [M-CAL-SLOANS](MOCKS.md#m-cal-sloans), [M-CAL-LAKEVIEW](MOCKS.md#m-cal-lakeview) | partial overall; native exp1 integrated default-off: `scripts/foliage_variant.py` → `build-native.sh` → engine bundle metallib → unchanged `RenderResources.init`; shipping shader byte-identical; A3 inspection review no gain, hold-outs pending | partial; web exp1 off/remove/layered consumed in `web/bakeoff/foliage.js` and `main.js`, default off; approved 66aac35 deciduous identity gate consumed, excluded conifers retain original graph; arithmetic/structural identity tested by `foliage-exp1.test.mjs`; GPU/pixels pending | web exp1: this implementation commit (history of `web/bakeoff/foliage-exp1.test.mjs`), control `fc439aa`; native capture build `ec14fed`: FINAL max≤2/255 AND mean≤5e-4 gate passes every category/leaf fraction; repeat/remove exact zero; nine Sloan’s Simulator frames at 40/150/600 m; no visual/performance gain claimed; [evidence](../research/foliage-exp1-native-final-evidence.md) | [A3 nine-frame review](../lookloop/foliage-exp1-native-scores.md): baseline/remove/layered at 40/150/600 m all foliage 2, overall 2; layered 600 m coverage confound traced to context completing after capture; [investigation/tooling guard](../research/foliage-exp1-600m-coverage-investigation.md), native scene-ready wait pending. Historical street overall 3 unchanged; hold-outs pending; web foliage 2 historical |
```

```markdown
| A10 | WorldLab inspection controls integrated in this implementation commit: pinch, two-finger pan, orbit, reset, opt-in debug pose and launch pose. Simulator build/tests and Sloan’s 40/150/600 m captures pass; repeated launch preserves pose (≤1/255 RGB difference). No render/tile/budget changes or phone install. R approved the native foliage mask correction (predicate plus slots 3–6/24–28), now amended in the spec. Native default-off build variant `ec14fed` passes arithmetic/mask tests and R’s FINAL category gate (max≤2/255 AND mean≤5e-4 byte units); repeat/remove max/mean/differing count all zero. Shipping shader byte-identical to main. Nine pose-matched Sloan’s Simulator frames delivered (40/150/600 m × baseline/remove/layered), all poses and hashes verified, no crashes. [Frame/category evidence](../research/foliage-exp1-native-final-evidence.md). A3 nine-frame review completed: foliage/overall 2/2 throughout, no gain; layered 600 m mismatch proved to be asynchronous context loading (0 context draws at shot, completion afterward; baseline/remove 6 draws). [Readiness investigation](../research/foliage-exp1-600m-coverage-investigation.md): tooling now rejects incomplete or unequal coverage; full native SCENEREADY wait proposed, not implemented. No new build/capture while A4 validates; eight lightweight tooling tests pass. Untouched hold-outs remain pending. Native adaptive reader and floor overage remain open. [Evidence](../experience-inspection.md#3-verification-evidence). |
```

Coverage race finding for handoff/state: baseline/remove 600 m have 7,321 context triangles and six context draws; layered has zero at shot line 43, context completion afterward at line 45. Detailed non-context counts and pose/date match. Timed capture, not full scene readiness, allowed the discrepancy. Shipping shader stays unchanged. Tooling guard rejects known incomplete or unequal coverage; a native SCENEREADY handshake is the next separate change. A3 grades remain unchanged; no new capture until A4 finishes and heavy admission succeeds.

### Next scene-ready branch scope for A3

R explicitly authorizes the separate capture-only handshake. Planned consumers: World.swift/World+Context.swift expose explicit context completion/failure; World+Capture.swift drains pending context/IBL work with a bounded wait; CaptureFrameTracker.swift tracks ordered completed Metal frame buffers with capture epochs and scene signatures; WorldView.swift supplies current view counters/camera signature only while armed; PostProcess.swift observes its existing command-buffer completion without changing kernels or encoding; ContentView.swift/Demo.swift opt in through -sceneready; capture_native.py requires the handshake. No shader, geometry, palette, culling or interactive first-frame policy change. Ledger files remain A3-owned and untouched.

## Scene-ready implementation — 2026-10-08

The separate branch implements the proposed handshake; it does not retroactively validate the old frames. `-sceneready` is opt-in for view-list captures, and `capture_native.py` now supplies it and requires its record before VIEWREADY. Context attachment has explicit pending/ready/not-required/failed state. `World+Capture.swift` waits for context and the latest pending image-based lighting task with a 60-second loading deadline. Interactive World.load still returns as before.

After completion, a capture epoch observes existing Metal command-buffer completion callbacks. It requires three ordered, successful completions with unchanged camera transform/FOV, triangle/draw signature and drawable size, with a 30-second deadline. Scene updates refresh diagnostic estimates while armed; they are not counted as GPU completions. Old epochs, old scene revisions and duplicate callbacks cannot satisfy readiness. Failures, unsupported noPost/offscreen capturequality, timeout, or a signature/size change during snapshot stop capture. SCENEREADY records context state, completed sequence, stable count, size and base64 scene signature. This proves command-buffer completion, not display presentation or a pixel comparison. Geometry counters remain estimates.

Validation: nine lightweight Python worker tests pass; standalone Swift tracker checks pass for ordering, stale epochs/revisions, pose and size changes, failed buffers and inactive/invalid targets. Swift syntax parsing passed for the changed app/native files. The standalone tracker executable is not a native app build. Native app type-check/build and real GPU/snapshot validation remain deferred until A4 finishes and heavy-lock admission at load <25 is available. No Simulator, heavy job or recapture was run. Shipping WorldShaders.metal and postprocess kernel source remain unchanged.

A3 ledger follow-up text: replace the older “native scene-ready wait pending/proposed” wording with “capture-only SCENEREADY handshake implemented: await context/IBL completion and three stable completed Metal frame buffers; lightweight tests pass; native app build and capture validation deferred until A4 finishes and heavy admission succeeds.” Preserve all existing scores, hold-outs and original frame evidence. INTEGRATION.md, STATE.md and handoffs.md are untouched.
