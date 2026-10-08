# West Highland hold-out — 8 Oct 2026

**Camera confirmed unchanged and frozen before any scored comparison:** `west-highland-aerial-north-01`. A1 authored the proposal before capture/scoring (R's report); A3 confirms its north-facing, oblique aerial geometry without inspecting a candidate render or optimizing composition. This is not a framing or terrain-visibility pass.

| Parameter | Frozen value |
|---|---|
| Target (WGS84 latitude, longitude; scene y) | (39.764, -105.04); y = 0 m |
| Eye (WGS84 latitude, longitude; scene y) | (39.759946, -105.04); y = 350 m |
| Lens / drawable | Vertical FOV 47°; portrait 390×780 pixels |
| Orientation | +Y up, roll 0°, look at frozen target; no auto-framing |

Scene y is neither height above local terrain nor a surveyed altitude. Use the area's documented geographic-to-scene transform; record its origin/datum with the capture. Do not shift the camera to conceal terrain or data failures. If the transform/terrain makes it invalid, log the blocker and version a revised contract before any scored pair; do not silently overwrite this baseline.

## Shared atmosphere and capture record

[Machine-readable frozen contract](west-highland-capture-contract.json) includes the current shared web fixture, source hashes and resolved Front Range preset: simulated summer-clear/day atmosphere, 75 km MOR under the **5%** convention, wind 10 km/h FROM 225°, no local atmosphere layers or summit-obscuring cloud; calibration-v2 sun elevation 40° / azimuth 225°. Airlight and single-application rules come from haze-visibility-v1. The replay date is 2026-10-08; foliage follows the shared calendar prior, not an assertion of observed phenology. No West Highland-specific atmosphere tuning.

For each capture, save this contract/hash, actual resolved fixture, source/pack/correction hashes, renderer/build, area/package hashes, scene origin/datum, tier, drawable/DPR, camera and capture timestamp. Record the applied sky corrections and engine-specific exposure/transfer implementation; do not transplant web light units to RealityKit. Compare within the same renderer, fixture and tier. A fixture or camera change starts a separately labelled baseline; it cannot establish a controlled delta against the old one. No capture was made in this docs-only task.

## Data-poor cohort — not a typical-block average

R reports West Highland building-height coverage **19.1%** and roof-form coverage **19.0%**, versus Lakeview height coverage **93.5%** and Sloan's **29.1%**. Those comparator figures are height coverage, not interchangeable roof coverage. These are reported coverage rates, not new A3 measurements, confidence scores or measured accuracy. Attach A1's counts, denominator, source dates and QA artifact to the first scored run. The checked-in A1 tracker still contains the historical blocked state; this update records R's newer report without fabricating a delivered manifest.

Score West Highland with existing §M closeness/six aspects and §N controls, explicitly labelled **data-poor aerial hold-out**. Keep its result separate from typical-block hold-outs and from street-view averages; explain missing data and inferred geometry without inventing a replacement look score. No zero or pass for missing captures. Do not tune on it or lower the rubric threshold. A Sloan's gain paired with a demonstrated West Highland loss still triggers the reject flag; cohort separation must not hide regressions.

**A1 sparse-density test: PENDING. The ladder is NOT PROMOTED.** No new rung, deployment, typical-block clearance, or generalization success is established by this camera decision. Require A1's test definition, density/coverage evidence and unchanged-method results before reviewing promotion; no test result is inferred here.
