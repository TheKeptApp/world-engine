# A3 calibration baseline and hold-out protocol

Owner instruction: R, 8 Oct 2026. Grader changed from Claude P3 to A3 (Codex visual review). This is a new grading baseline, not a claim of engine improvement relative to Claude scores. The old [calibration baseline](calibration-baseline.md) and historical scoreboard rows remain intact.

## Scope and reproducibility

Main advanced from `8359603` to `0b9d255` while the shared capture queue was busy. Captured checkout: `0b9d255`; last rendered-input commit: `1c44e94` (A1 roof data). Four afternoon heroes are forcibly captured rather than reusing grades. This review scores §M calibration closeness and its six aspects only; it does not re-score legacy /50, art-direction totals, full-core parity, weather or motion. Exact area, camera, time, weather, sun, target and common arguments are frozen in [a3-capture-contract.json](a3-capture-contract.json), copied from main's view definitions. No look, data, generator, camera or target values were tuned.

The gate remains all four heroes at closeness ≥4/5 and every aspect ≥3. A routine pass still requires the existing full confirmation. Missing second-Denver evidence prevents a complete paired hold-out clearance even if the four-hero look gate passes. A2 web results require a separate renderer-specific baseline before before/after comparisons.

## Denver and Greenville coverage

**Proposed: West Highland, Denver.** It offers a second Denver neighbourhood outside Sloan's Lake. Main has no dedicated West Highland area or fixed camera: `Data/areas/` contains Sloan's Lake, Lakeview, Wilmette, Evanston, Kenilworth and Winnetka only. The Denver region-kit definition also contains Sloan's Lake only. Sloan's broad context extract is not a validated second neighbourhood area. A1 must prepare the dedicated area with the unchanged pipeline, report source/coverage/quality and freeze the view before it joins the test. This is a proposal, not a claim that a render-ready area exists. No second Denver score is fabricated.

Greenville Downtown is deferred until area data exists, as R instructed. Design-pack availability alone is not capture data. Its score is pending, not zero or pass.

## After each look merge (5A, P2, A2)

1. Record merge SHA, renderer, affected views and source/rubric hashes. Compare to the last A3-scored pre-merge commit; a grader change requires re-scoring the same reference first.
2. Render Sloan's and all ready hold-outs under the frozen conditions, without tuning. Preserve per-view raw frames and inspect current/target images at phone size. Lakeview street and postcard remain separate scores; Wilmette uses the nearest Chicago calibration frame, as in §M.
3. Record §M closeness plus sky, light, saturation, ground, foliage and materials for every view. Run `region_colours.py`, `calibration_colours.py` and `compare_runs.py`; keep deterministic surface measurements beside subjective scores. For full-core reviews, retain the existing full rubric as well.
4. Use §N's unchanged-frame check (less than 0.5% of pixels differ by more than 12 luma levels) to distinguish grader variance. Proposed numerical parity thresholds remain proposed, not newly approved. Do not claim engine gains across the Claude/A3 handoff or infer a visual regression from missing raw frames.
5. Log the merge/run and individual before/after values in scoreboard **Sloan's score** and **hold-out score** and the tracking ledger. If Sloan's rises and any hold-out falls, **REJECT-FLAG** the merge; investigate changed frames/reasons before attributing cause. A flagged merge gets no A3 clearance; this does not authorize reverting someone else's code. Missing required evidence is **PENDING**, never pass. An unchanged-frame score shift is logged as variance and does not establish a look gain/loss.
6. Update roadmap and handoffs with the lane report. Run only when R asks or a lane report arrives; no unattended schedule or auto-merge. This scoring/reporting merge is explicitly requested by R.

## Metro skyline check — R, 8 Oct 2026

For every R-supplied metro reference photo, add the [private matched-view skyline check](../screenshots/metro-reference/README.md#metro-skyline-check) to hold-out review: A3 hides build labels, grades skyline height/massing PASS/FAIL, and reports the tallest ten visible buildings with public IDs, sourced heights, rendered heights and uncertainties. Missing reference/camera/height evidence stays PENDING; no guessed ranks or per-block tuning. The linked protocol governs privacy, matching and structural regression reporting; it supplements, without changing, the §M look gate. No photos or completed checks are claimed by this addition.

## New A3 baseline — captured 2026-10-07 22:50 MDT (R’s 8 Oct instruction)

**Look gate: FAIL, 0/4 heroes.** All four closeness scores are 3/5; foliage is 2/5 throughout, and Lakeview saturation is 2/5. Every other calibration aspect is 3/5. These are fresh A3 visual judgments after reviewing raw frames and phone-size comparisons; no old grades were reused. Passing needs 4/5 closeness and every aspect ≥3, so no full confirmation run was triggered.

| View | Closeness /5 | Sky | Light | Saturation | Ground | Foliage | Materials | Result |
|---|---|---|---|---|---|---|---|---|
| Sloan's Lake (focus) | 3 | 3 | 3 | 3 | 3 | 2 | 3 | fail |
| Lakeview street (hold-out) | 3 | 3 | 3 | 2 | 3 | 2 | 3 | fail |
| Lakeview postcard (hold-out) | 3 | 3 | 3 | 2 | 3 | 2 | 3 | fail |
| Wilmette (hold-out) | 3 | 3 | 3 | 3 | 3 | 2 | 3 | fail |

West Highland (proposed) and Greenville Downtown: **pending data, unscored**. Complete hold-out clearance is pending; no comparable A3 pre-merge baseline exists for the historical merged work. The Sloan's-gain/hold-out-loss reject test starts with subsequent A3 comparisons. No retrospective clearance or rejection is inferred from the grader change.

The main visible gaps are broad, smooth crown shading rather than layered softness, overly strong Lakeview greens, and flat ground/material transitions. Seasonal orange in Sloan's is not penalized against a green-season target, nor are missing photo-level leaves, brick textures, objects, or the calibration's different layout. Wilmette uses Chicago's nearest regional look target, as P3's setup specifies.

Evidence: [per-view grades and provenance](a3-baseline/evidence.json), [signals](a3-baseline/signals.json), [capture results](a3-baseline/capture.tsv), [colour and frame comparison](a3-baseline/measurements.md). Four captures succeeded; raw frames are 1005×565, matching the historical raw-frame dimensions. Rendered-input trees did not change during build/capture, and the app binaries were rebuilt after run start. The capture workflow's exit 3 means ready for review, not capture failure. Existing compile warnings remain; no engine code was changed by A3.

The frame comparison finds 12.5% Sloan's, 13.8% Wilmette, 69.4% Lakeview street and 73.1% postcard changed pixels relative to P3's last run, all above the unchanged-frame threshold. Several engine/data merges intervene and graders differ, so these are descriptive comparisons, not attribution to one merge. Mean calibration surface dE: sky 12.6, road 10.5, sidewalk 17.3, lawn 20.0, crowns 27.2; geometry/season limits are recorded in the measurement report. These colour distances do not replace the six visual aspect scores.

Local-only raw frames and phone comparisons are under `~/Desktop/world-engine/.build/lookloop/runs/20261007-225009/` (`raw/`, `a3-phone/`). Images remain out of git; source values and calibration image hashes are recorded in evidence.json. Historical P3 latest/full-core reports remain unchanged; this document is the current A3 calibration reference.
