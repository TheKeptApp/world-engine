# Palette B — blind paired review, 9 October 2026

**Scoring only; no promotion or gate pass.** TableA is preferred to lot overall at Sloan 40/150/600 m (6/6 each), and to Lakeview 150 m default (6/6). Against exact c8c361d Sloan controls, tableA wins overall at 40/150 m (6/6); at 600 m it splits 4–2, **inconclusive**. Lot loses overall to the control at every height (6/6). These are visual preference observations, not scene-budget, rights, native, device or release acceptance.

## Source identity and pairing

R supplied local manifest `/private/tmp/worldengine-a2-bakeoff/web/bakeoff/evidence/palette-b/manifest.json`. Its `frames` array has 30 entries and `lakeviewControlIdentity` adds 4: **34 PNGs, 17 fresh/repeat conditions, 13 distinct SHA-256 images**. All 34 file hashes verified. Source was copied to `/private/tmp/a3-palette-b-source/` before review to preserve the supplied evidence while A2 rebased. Original capture implementation is identified as `7f16c53` in that manifest; A2 subsequently rebased its branch. This report grades the snapshotted hashes, not an unobserved new build.

Absent/off Sloan 40/150/600 and Lakeview 600 controls match the c8c361d PNGs exactly; every fresh/repeat condition is byte-identical. Requested variant pairs have equal camera, date, fixture, projection, exposure and every pass triangle/draw count. [Identity audit](palette-b-scoring/identity-audit.json) and [34-file hash/alias key](palette-b-scoring/blind-key.json) preserve the checks. Identical hashes share grades; repeat files are not counted as independent visual evidence.

**Lakeview scope matters:** default/tableA here is the matched **150 m** October ladder view. The four c8c361d identity-only Lakeview files are **600 m**; they were graded, but cannot act as the150 m palette baseline. The extra Sloan 150 m `tableA + crownV3 standard` condition was also graded, separately; it is not a clean palette-only contrast and has no matched v3-control preference in this report.

## Blind procedure and repeat checks

The parent acted only as evidence preparer/aggregator and read identities to establish the matched pairs. **Three new review sessions started with no inherited conversation, previous grades, manifest, variant names or expected winner.** Each received 13 shuffled neutral PNG copies, a rubric distilled from GRADING §M, and the same approved Sloan/Lakeview reference images. Each locked whole-point grades **before** opening 22 randomized spatial panels: two opposite-position presentations of each of 10 comparisons, plus two hidden identical-image controls. Original source pixels were pasted unchanged into A-left/B-right panels with an external label strip and gutter; both sides have the same scale and dimensions, no recolouring, cropping or masking. Only preparer held the separate key until reviews completed.

This implements the proposed [paired-preference protocol](paired-preference-protocol.md) from 0bd9d52: six judgments per pair across three fresh sessions, exactly three candidate-left and three candidate-right; no adjacent duplicate pair. Two presentations within a session remain correlated, and all sessions use the same model family. Fresh contexts are not independent humans or statistical proof. Reviewers recognized scene repetitions after first inspection but did not know implementation identities. Parent historical knowledge was not passed to them; no parent re-grading or preference override occurred.

**Controls: 6/6 passed** (every assessable aspect tied; roof answers agreed within each identical pair). Directional preferences counted as repeatable only at ≥5/6 with ≥2/3 wins in each position. All 6/6 wins are 3 left + 3 right; the sole 5/6 result (Sloan 150 control→tableA ground) wins 3 left + 2 right. No consistent preference flips solely with position; all raw disagreements remain below. Cross-session taste disagreement at 600 m remains **inconclusive**, not “reliable improvement.” [Raw results](palette-b-scoring/results.json); separate [session1](palette-b-scoring/session-1-preferences.json), [session2](palette-b-scoring/session-2-preferences.json), [session3](palette-b-scoring/session-3-preferences.json) preserve reasons, roof answers and recognition. No new captures, render changes or ΔE scoring.

## Requested comparisons — every aspect

Counts are **first-mode wins / second-mode wins / ties**, out of 6. Whole-point cells show **session 1/session 2/session 3**, not decimals, means or a consensus. Sky is **N/A everywhere by instruction**. “Repeatable” describes only this protocol's consistency screen; it does not promote a build.

| View; comparison (first → second) | Aspect | Preference counts | First grades | Second grades | Conclusion |
|---|---|---|---|---|---|
| sloans-40; lot → tableA | saturation | 0/6/0 | 2/2/2 | 3/3/3 | tableA preferred |
| sloans-40; lot → tableA | materials | 0/6/0 | 2/2/2 | 2/2/2 | tableA preferred |
| sloans-40; lot → tableA | ground | 0/6/0 | 2/1/2 | 3/2/3 | tableA preferred |
| sloans-40; lot → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-40; lot → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40; lot → tableA | overall | 0/6/0 | 2/2/2 | 2/2/2 | tableA preferred |
| sloans-150; lot → tableA | saturation | 0/6/0 | 2/2/2 | 3/3/3 | tableA preferred |
| sloans-150; lot → tableA | materials | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| sloans-150; lot → tableA | ground | 0/6/0 | 2/2/2 | 3/2/3 | tableA preferred |
| sloans-150; lot → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-150; lot → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150; lot → tableA | overall | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| sloans-600; lot → tableA | saturation | 0/6/0 | 2/2/2 | 3/3/3 | tableA preferred |
| sloans-600; lot → tableA | materials | 0/4/2 | 2/2/2 | 2/2/3 | inconclusive |
| sloans-600; lot → tableA | ground | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| sloans-600; lot → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-600; lot → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600; lot → tableA | overall | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| lakeview-150; absent → tableA | saturation | 0/6/0 | 3/3/3 | 3/3/3 | tableA preferred |
| lakeview-150; absent → tableA | materials | 0/6/0 | 3/2/2 | 3/2/3 | tableA preferred |
| lakeview-150; absent → tableA | ground | 0/6/0 | 3/2/3 | 3/2/3 | tableA preferred |
| lakeview-150; absent → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| lakeview-150; absent → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150; absent → tableA | overall | 0/6/0 | 3/2/2 | 3/2/3 | tableA preferred |

## Sloan comparisons against c8c361d controls

`absent` is the exact c8c361d crown-OFF image; explicit palette-off is identical.

| View; comparison (first → second) | Aspect | Preference counts | First grades | Second grades | Conclusion |
|---|---|---|---|---|---|
| sloans-40; absent → lot | saturation | 6/0/0 | 2/2/2 | 2/2/2 | absent preferred |
| sloans-40; absent → lot | materials | 4/0/2 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-40; absent → lot | ground | 6/0/0 | 3/2/3 | 2/1/2 | absent preferred |
| sloans-40; absent → lot | foliage | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40; absent → lot | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40; absent → lot | overall | 6/0/0 | 2/2/2 | 2/2/2 | absent preferred |
| sloans-40; absent → tableA | saturation | 0/6/0 | 2/2/2 | 3/3/3 | tableA preferred |
| sloans-40; absent → tableA | materials | 0/6/0 | 2/2/2 | 2/2/2 | tableA preferred |
| sloans-40; absent → tableA | ground | 0/6/0 | 3/2/3 | 3/2/3 | tableA preferred |
| sloans-40; absent → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-40; absent → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40; absent → tableA | overall | 0/6/0 | 2/2/2 | 2/2/2 | tableA preferred |
| sloans-150; absent → lot | saturation | 6/0/0 | 2/3/2 | 2/2/2 | absent preferred |
| sloans-150; absent → lot | materials | 4/0/2 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-150; absent → lot | ground | 6/0/0 | 3/2/3 | 2/2/2 | absent preferred |
| sloans-150; absent → lot | foliage | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150; absent → lot | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150; absent → lot | overall | 6/0/0 | 2/2/2 | 2/2/2 | absent preferred |
| sloans-150; absent → tableA | saturation | 0/6/0 | 2/3/2 | 3/3/3 | tableA preferred |
| sloans-150; absent → tableA | materials | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| sloans-150; absent → tableA | ground | 0/5/1 | 3/2/3 | 3/2/3 | tableA preferred |
| sloans-150; absent → tableA | foliage | 0/2/4 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-150; absent → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150; absent → tableA | overall | 0/6/0 | 2/2/2 | 2/2/3 | tableA preferred |
| sloans-600; absent → lot | saturation | 6/0/0 | 3/3/3 | 2/2/2 | absent preferred |
| sloans-600; absent → lot | materials | 4/0/2 | 2/2/2 | 2/2/2 | inconclusive |
| sloans-600; absent → lot | ground | 6/0/0 | 2/2/2 | 2/2/2 | absent preferred |
| sloans-600; absent → lot | foliage | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600; absent → lot | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600; absent → lot | overall | 6/0/0 | 2/2/2 | 2/2/2 | absent preferred |
| sloans-600; absent → tableA | saturation | 2/4/0 | 3/3/3 | 3/3/3 | inconclusive |
| sloans-600; absent → tableA | materials | 0/4/2 | 2/2/2 | 2/2/3 | inconclusive |
| sloans-600; absent → tableA | ground | 2/4/0 | 2/2/2 | 2/2/3 | inconclusive |
| sloans-600; absent → tableA | foliage | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600; absent → tableA | light | 0/0/6 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600; absent → tableA | overall | 2/4/0 | 2/2/2 | 2/2/3 | inconclusive |

## Whole-point sensitivity and disagreements

**The whole-point scale misses much of the partial progress, but it is not wholly insensitive.** All three reviewers keep overall at 2 for Sloan 40 control, lot and tableA despite6/6 preferences; foliage and light remain2 in those comparisons. TableA saturation at 40 is 3/3/3 versus lot/control 2/2/2: that particular change does cross a whole-point boundary. At150/600, tableA overall is 2/2/3, while lot/control overall stays 2/2/2. Lakeview default overall 3/2/2 becomes 3/2/3 with tableA, despite a 6/6 paired preference. Report the individual vectors rather than forcing them to “all2” or selecting the most favourable reviewer.

R supplied A8's “all frames at 2” observation; the fresh sessions were not told it. Their different absolute scores, including higher scores for byte-identical historical controls, demonstrate grader/session variation, **not a newly improved control renderer**. Historical A3 scores stay unchanged. The separate tableA+v3 frame gets foliage 3/3/3 and overall 3/2/3 here; that is not isolated evidence for either palette or crown progress and cannot revise the earlier v3 verdict or gate. No accepted whole-point gain is declared by this report.

## What drove preference

- **Saturation:** tableA's quieter ochre/olive foliage and subdued ground generally feel closer to the rich but restrained target. Lot's yellow/lemon ground is consistently less preferred than either control or tableA. At600 m, two judgments favour the control's stronger colour over tableA; tableA-versus-control saturation is therefore inconclusive.
- **Materials:** muted colour makes some surfaces/crowns appear more matte and gives clearer tonal separation, without proving new material/shading mechanics. TableA wins 40/150 and Lakeview 150, but600 tableA-versus-lot is 4 wins/2 ties and does not meet the threshold.
- **Ground:** tableA/control greens beat lot's yellow ground. TableA's benefit over control at 150 is modest (5 wins/1 tie); at 600 tableA versus control splits 4–2. Broad flat areas and schematic surfaces remain.
- **Foliage:** angular caps/balloon masses remain in palette-only frames. TableA usually draws 2 foliage preferences and 4 ties; **no repeatable palette-only foliage preference** is established. Colour restraint must not be reported as a proven shape improvement.
- **Light:** all compared pairs tie 6/6. Hard directional shadows and weak soft depth remain; palette differences do not demonstrate changed illumination.
- **Overall:** tableA wins the requested four comparisons6/6, but the exact c8c361d600 m comparison is mixed. Do not extrapolate close-view preference to every altitude or block.

“Roofs compete with trees”: Sloan 40/150 **yes 6/6 for both lot and tableA**; Sloan 600 and Lakeview 150 **no 6/6 for both sides** at the registered scale. The bright Sloan roof group remains a distraction even where palette preference improves. This is attention balance, not permission to change mapped roof colours.

Lakeview 150 preference points in the same direction as Sloan 40/150; there is no observed opposite-direction preference in this one matched hold-out pair. Other hold-outs, motion, device and budget qualification remain outside this task. **No promotion, no gate pass, no automatic merge of render code.**

## Coverage of all 34 supplied files

One row per unique image; the separate hash key maps all 34 originals, including repeats and absent/off aliases. Grade vectors are sessions 1/2/3. Raw whole-point reasons: [session1](palette-b-scoring/session-1-grades.json), [session2](palette-b-scoring/session-2-grades.json), [session3](palette-b-scoring/session-3-grades.json).

| Neutral ID | Source condition | Saturation | Materials | Ground | Foliage | Light | Overall |
|---|---|---|---|---|---|---|---|
| frame-01.png | sloans-600 / absent | 3/3/3 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-02.png | sloans-150 / lot | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-03.png | lakeview-600 / absent | 3/3/3 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-04.png | sloans-150 / tableA + crownV3 standard | 3/3/3 | 2/2/2 | 3/2/3 | 3/3/3 | 2/2/2 | 3/2/3 |
| frame-05.png | sloans-150 / absent | 2/3/2 | 2/2/2 | 3/2/3 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-06.png | sloans-40 / tableA | 3/3/3 | 2/2/2 | 3/2/3 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-07.png | sloans-600 / lot | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-08.png | lakeview / tableA | 3/3/3 | 3/2/3 | 3/2/3 | 2/2/2 | 2/2/2 | 3/2/3 |
| frame-09.png | sloans-150 / tableA | 3/3/3 | 2/2/3 | 3/2/3 | 2/2/2 | 2/2/2 | 2/2/3 |
| frame-10.png | sloans-600 / tableA | 3/3/3 | 2/2/3 | 2/2/3 | 2/2/2 | 2/2/2 | 2/2/3 |
| frame-11.png | lakeview / absent | 3/3/3 | 3/2/2 | 3/2/3 | 2/2/2 | 2/2/2 | 3/2/2 |
| frame-12.png | sloans-40 / absent | 2/2/2 | 2/2/2 | 3/2/3 | 2/2/2 | 2/2/2 | 2/2/2 |
| frame-13.png | sloans-40 / lot | 2/2/2 | 2/2/2 | 2/1/2 | 2/2/2 | 2/2/2 | 2/2/2 |

Used: paired-preference-protocol.md (0bd9d52), GRADING.md  §M, supplied palette-B manifest and c8c361d SHA-256 controls. Mock: calibration-v2/frames/06-sloans.png and01-lakeview.png. Deviation: none from requested spatial/fresh-session method; correlated same-model repeats and absolute-grade disagreement disclosed; no promotion.
