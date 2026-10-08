# Native crown BEFORE and SCENEREADY evidence — 2026-10-08

**Stopped before the allocator:** the 600 m independent BEFORE repeat has widespread brightness differences despite matched scene coverage. No allocator/render/shader edit, AFTER capture, visual score or phone installation. Crown brief stop condition: control noise that obscures the comparison.

## Build and frozen capture contract

Control source/build commit `e5a0a3e` (full commit in each native-capture.json). All 15 prerequisite-safe Simulator builds/captures succeeded, with no recorded crashes. Each invocation acquired and released scripts/heavy.sh independently; admitted one-minute loads ranged 6.85–20.23, strictly below 25. Other lanes took the lock between some runs; A10 did not change their locks. No capture ran outside heavy admission.

All frames: Sloan’s pose `39.7511195,-105.0389,ALT,270,45`, ALT 40/150/600 m AGL; date `2026-10-15T20:30:00Z`, clear/cloud0/wind0, no character, RealityKit, HUD off, FOV 50°, 1005×565 drawable. Every observed pose was checked against the request within 1e-7; PNG hashes were independently verified. All builds use foliage experiment off/constant 0. Shipping and compiled shader source SHA-256: `8bc481191914876a6f2b870080b8b7fb19ba6d6370426516409596437b49038a`. Engine/app metallib hashes are recorded per frame; the 600 m fresh/repeat libraries match exactly. No rendering or allocator source changed during capture.

## Three native validation passes

Counts are native CPU submission estimates, not hardware triangle/draw counters. At each pose, all three runs have exactly matching six-category triangles/draws, including context. The completed-frame threshold is **at least three**, not an exact counter of three: 40 m reports 3/3/4; 150 and 600 m report 3/3/3. Thus completed-frame counter values themselves are not identical at 40 m. A fourth callback can arrive before the 20 ms observer poll; it is an additional completion, not missing geometry. No claim of identical counter values is made.

| Pose | Main triangles, every run | Main draws, every run | Context triangles/draws | Completed/stable counts (runs 1/2/3) | Foliage triangles | Non-foliage N | Authored F |
|---|---:|---:|---|---|---:|---:|---:|
| 40 m | 313,022 | 53 | 3,914/2 | 3/3/4 | 140,563 | 172,459 | 120,000 |
| 150 m | 333,886 | 50 | 4,446/3 | 3/3/3 | 115,343 | 218,543 | 120,000 |
| 600 m | 228,159 | 43 | 7,321/6 | 3/3/3 | 68,631 | 159,528 | 120,000 |

F is a planning allowance from crowns.md, not measured device capacity. Native non-elm U, elm E, actual elm mesh chain and all-pass shadow costs have not been inventoried; no runtime promotion decision or denial log is claimed. Main floor gaps are zero at these controls. All-pass shadow compliance, device timing and total memory remain unproved.

## Readiness log ordering

World+Capture.swift returns only after explicit context completion and pending IBL task completion; a cancelled IBL task or absent sky environment throws. The app then arms the existing Metal completion observer. SCENEREADY is emitted only after stable successful buffers, before the snapshot call. Native build validates the API/type wiring, and each of the 15 launch logs independently proves context completion → SCENEREADY → VIEWREADY → VIEWSHOT. This proves task completion and command-buffer completion, not pixels settled or display presentation. IBL resource identity/successful replacement is not logged: Environment.swift uses a silent try? resource guard, so an older non-nil sky environment could survive a failed replacement. This is an additional limitation of the presence check, not a proven failure in these runs.

| Run | Pose | CONTEXT line | SCENEREADY line | VIEWREADY line | VIEWSHOT line |
|---|---:|---:|---:|---:|---:|
| validation/run-1 | 40 | 42 | 43 | 44 | 45 |
| validation/run-1 | 150 | 41 | 42 | 43 | 44 |
| validation/run-1 | 600 | 41 | 42 | 43 | 46 |
| validation/run-2 | 40 | 40 | 43 | 44 | 45 |
| validation/run-2 | 150 | 41 | 44 | 45 | 46 |
| validation/run-2 | 600 | 40 | 43 | 44 | 45 |
| validation/run-3 | 40 | 40 | 43 | 44 | 45 |
| validation/run-3 | 150 | 41 | 44 | 45 | 46 |
| validation/run-3 | 600 | 41 | 44 | 45 | 46 |
| before/fresh | 40 | 40 | 43 | 44 | 45 |
| before/fresh | 150 | 41 | 44 | 45 | 46 |
| before/fresh | 600 | 41 | 44 | 45 | 46 |
| before/repeat | 40 | 41 | 44 | 45 | 46 |
| before/repeat | 150 | 40 | 43 | 44 | 45 |
| before/repeat | 600 | 43 | 44 | 45 | 46 |

## Fresh BEFORE versus independent repeat

Absolute difference is over 2,271,300 decoded RGBA bytes per frame; mean includes equal bytes and alpha. This is a byte comparison, not A3 grading. PNG-file identity is checked separately.

| Pose | Max byte difference | Mean absolute byte difference | Differing bytes | PNG byte-identical |
|---|---:|---:|---:|---|
| 40 m | 0 | 0.0000000000 | 0 | True |
| 150 m | 1 | 0.0000303791 | 69 | False |
| 600 m | 7 | 3.1852701096 | 1,694,760 | False |

At 600 m, fresh hash `f9bbd6d8b5d489007870198a062da8398a75bf60e0b251d42218055539af6b57`; repeat hash `9b767162695aafc1306ae8f14c10cd2ef7f925a5fd6fcefe83e0a947546b5610`. Coverage, requested/observed pose, date/arguments, source commit, source hashes, compiled constant, metallib hashes, drawable and scene signature match. Both are full context: 7,321 context triangles, six draws. This is **not the earlier missing-ground/context coverage race**. The paired pictures visibly differ in brightness; no shape improvement is scored.

Exposure convergence is a **hypothesis, not proved**: PostProcess.swift exposureSolve retains and eases meanBuffer gain every frame (default exposureRate 0.06); CaptureFrameTracker signatures include camera/FOV/category costs/size, but not that gain or actual pixel output. Context/IBL completion can change input brightness while exposure history still evolves. No gain/readback/pixel-stability telemetry was saved, so these files cannot establish the precise cause. A future capture-only fix should observe completed-frame exposure/output stability (with a bounded timeout) rather than just lengthening a sleep. No such fix or extra capture was attempted after the control failure.

## Paths for A3 and retained evidence

No self-score; AFTER shape and blind scoring remain pending. These are BEFORE controls, not an accepted matched-pixel comparison.

| Pose | Fresh BEFORE | Repeat BEFORE |
|---|---|---|
| 40 m | [fresh](/private/tmp/worldengine-a10/.build/a10-crown-before/before/fresh/40/raw/ordinary-street-afternoon.png) | [repeat](/private/tmp/worldengine-a10/.build/a10-crown-before/before/repeat/40/raw/ordinary-street-afternoon.png) |
| 150 m | [fresh](/private/tmp/worldengine-a10/.build/a10-crown-before/before/fresh/150/raw/ordinary-street-afternoon.png) | [repeat](/private/tmp/worldengine-a10/.build/a10-crown-before/before/repeat/150/raw/ordinary-street-afternoon.png) |
| 600 m | [fresh](/private/tmp/worldengine-a10/.build/a10-crown-before/before/fresh/600/raw/ordinary-street-afternoon.png) | [repeat](/private/tmp/worldengine-a10/.build/a10-crown-before/before/repeat/600/raw/ordinary-street-afternoon.png) |

Full metadata, frame hashes and validation controls: `/private/tmp/worldengine-a10/.build/a10-crown-before/validation-manifest.json` (15 entries). Pixel measurements: `/private/tmp/worldengine-a10/.build/a10-crown-before/before-repeat-diff.json`. Approved input hashes: `/private/tmp/worldengine-a10/.build/a10-crown-before/reference-hashes.json` (12 present crown/calibration references). Per-frame native-capture.json, pipeline.log and logs preserve source/build/readiness evidence. Heavy admission/release log: `/private/tmp/a10-crown-runs.log`, plus `/private/tmp/a10-crown-validation-first.log`. Old foliage frames remain untouched.

## Ledger text for A3

A10: capture-only SCENEREADY natively built and exercised in nine validation captures plus six BEFORE controls. At each of 40/150/600 m, three validation runs match all geometry/category/context counts: 313,022/53; 333,886/50; 228,159/43 main triangles/draws. Completed-frame threshold ≥3 passes; 40 m logged completion counts are 3/3/4, not exact equality. All 15 logs prove readiness before snapshot, no crashes, unchanged shipping shader/default off, per-run heavy releases. BEFORE repeats: 40 m max/mean/count 0/0/0; 150 m 1/0.0000303791/69; 600 m 7/3.1852701096/1,694,760 decoded-byte differences. STOP: 600 m control noise; allocator and AFTER candidate not started. Exposure convergence is suspected but unproved, and needs capture-only investigation before a valid crown comparison. A3 scores/hold-outs unchanged; no new score or phone-performance claim.

INTEGRATION.md, STATE.md and handoffs.md are deliberately untouched. A3 applies this text while preserving other lanes’ rows.

Used: docs/execution/crowns.md Budget and nearest-first allocation / Tests, nine-frame capture and A3 acceptance; capture-readiness investigation §Scene-ready implementation. Mock: crown 01/14/17–22, images 03/04, calibration 06-sloans. Deviation: stopped on noisy 600 m control; allocator not started; exact GPU counter equality absent at 40 m; Simulator evidence only.
