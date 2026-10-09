# A8 blind inter-rater check

## Locked independent grades

Locked before reading A3: 2026-10-09T04:36:56.362057+00:00; JSON SHA-256 `688b66422c33cd854a4b12f8276391b86c5a60dd73bcc7e40151e0531f5fd310`. Neutral labels, byte-identical copies, random shuffle; source key remained unopened. A8 had prior code/evidence knowledge from earlier audits and could recognize repeated views and crown styles; this is label-blind, not a naive observer. Sky is unobservable in these downward views and is N/A rather than a camera/layout penalty. Whole-point grades otherwise follow §M; §N parity thresholds are not converted into 1–5 thresholds.

| Neutral | Closeness | Sky | Light | Saturation | Ground | Foliage | Materials | Reason |
|---|---:|---|---:|---:|---:|---:|---:|---|
| N01 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Flat ground and bright crown dots dominate; water reads as grain rather than the target’s calm reflected light. |
| N02 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Coherent crown masses but repetitive faceted orange forms and flat lawns; roof contrast competes with foliage. |
| N03 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Small crown differences do not overcome the flat surfaces and excessive local colour contrast. |
| N04 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Fine sparse crown marks lose volume at this scale; ground and water remain visually simplified. |
| N05 | 2 | N/A | 3 | 2 | 2 | 2 | 2 | Branch openings and more articulated shadows help, but oversized leaf patches and bright roofs remain unlike the target. |
| N06 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Massed crowns remain opaque and faceted; ground and roof material separation is too diagrammatic. |
| N07 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Open crown structure is visible but becomes sparse orange noise; surfaces still lack the target’s tonal richness. |
| N08 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Full crown silhouettes read clearly, but balloon-like volumes and hard shadow shapes remain coarse. |
| N09 | 2 | N/A | 2 | 2 | 2 | 1 | 2 | Smooth clustered blobs and long exposed stems do not convey the target’s leaf-scale shading. |
| N10 | 2 | N/A | 2 | 2 | 2 | 1 | 2 | Large planar green crown pieces and blocky shadows are especially unlike the target foliage. |
| N11 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Distant vegetation reads as coloured dots; broad ground and water treatments dominate the look gap. |
| N12 | 2 | N/A | 2 | 2 | 2 | 2 | 2 | Little foliage is resolvable and built surfaces are uniformly flat; the blank backdrop provides no sky evidence. |

## Unblinding and agreement

A3 files were first opened after lock commit `fcf0ccb`. A3 lock: 2026-10-09T03:25:13.510974+00:00. Matched by full PNG SHA-256, never by presumed mode. All 16 originals deduplicate to 12: three OFF repeats and identical v2 standard/floor at 600 m. No duplicate is counted as another independent judgment.

| A8 label | Source aliases | A3 label | SHA-256 |
|---|---|---|---|
| N01 | sloans-600-foliage-off-crown-floor.png; sloans-600-foliage-off-crown-standard.png | frame-01.png | `70b37c5398c4d7fb3856937b9fec42bb53927c45db86f04e6353c4194ed9f6d0` |
| N02 | sloans-150-foliage-off-crown-standard.png | frame-02.png | `73b669c1f8fdf791267dc1bbee92373c89b9cbfebeecc9570582fb92b1f92c7e` |
| N03 | sloans-150-foliage-off-crown-floor.png | frame-08.png | `9cafa42063744dce7727e0c4eebf32df3e80167251e20aaa1ce1f24fad41bc94` |
| N04 | sloans-600-foliage-off-crown-off-v3-standard.png | frame-03.png | `f1bc136769e27c049e3b9e0b6864fc9b489c423f1c5a52ed187b29ce9aa8d37a` |
| N05 | sloans-40-foliage-off-crown-off-v3-standard.png | frame-04.png | `f68537439150135b4ae8d38673e2cc254df0c3fa9374d0f796b5ec117d0accb1` |
| N06 | sloans-150-foliage-off-crown-off-fresh.png; sloans-150-foliage-off-crown-off-repeat.png | frame-12.png | `ea9f9e78f42e471788547a077f14562d1741522fc965596f0a8cdbe086624db6` |
| N07 | sloans-150-foliage-off-crown-off-v3-standard.png | frame-10.png | `d88dcbf8cbcf92a2b7cd2f1d5eb15c2a0edd9e5044f2c8e51b8f4a2153988b8d` |
| N08 | sloans-40-foliage-off-crown-standard.png | frame-11.png | `0a99d45fa2e5ac484570a52522120b25ba50a473d1285c8134d38d914eef692b` |
| N09 | sloans-40-foliage-off-crown-off-fresh.png; sloans-40-foliage-off-crown-off-repeat.png | frame-05.png | `e1ac9873b1f81df6f82b6fd9a43544374d7f24a1bf9ce5c9c9cd18506e34ea4a` |
| N10 | sloans-40-foliage-off-crown-floor.png | frame-07.png | `48e809b0b859b2f0d776c4ff166f92b678f746c06b7b8df930a0d09e553e035d` |
| N11 | sloans-600-foliage-off-crown-off-fresh.png; sloans-600-foliage-off-crown-off-repeat.png | frame-06.png | `cdb41641abbe438ac3c9980173ce1dab549eb636197a88145dbf87b30538bd84` |
| N12 | lakeview-foliage-off-crown-off.png | frame-09.png | `49cfee051ffcbe39f94d7b6e6d9932450cdbc0bdae318c1297a954e3f84453be` |

| Aspect | Numeric pairs | Exact agreement | Within one point | Mean absolute difference |
|---|---:|---:|---:|---:|
| sky | 0 | Both N/A on 12/12 | N/A | N/A |
| light | 12 | 11/12 | 12/12 | 0.0833 |
| saturation | 12 | 12/12 | 12/12 | 0.0000 |
| ground | 12 | 11/12 | 12/12 | 0.0833 |
| foliage | 12 | 10/12 | 12/12 | 0.1667 |
| materials | 12 | 12/12 | 12/12 | 0.0000 |
| overall | 12 | 11/12 | 12/12 | 0.0833 |

Across the five visible aspects: **56/60 exact (93.33%), MAD 0.0667**, all within one point. Overall is reported separately, not counted as a sixth visible aspect. No disagreement ≥2 exists (0/60 aspect comparisons; 0/12 overall). No missing sky grade was replaced by zero.

## Every nonzero disagreement

| Image | Aspect | A8 / A3 | Reason for difference, after unblinding |
|---|---|---|---|
| N05 / sloans-40-foliage-off-crown-off-v3-standard.png | light | 3 / 2 | A8 credited more articulated directional tree shadows; A3 retained 2 for the still-flat overall lighting. This is one-point calibration variance, not proof of a lighting improvement. |
| N09 / sloans-40-foliage-off-crown-off-fresh.png | foliage | 1 / 2 | A8 weighted smooth crown blobs/exposed stems as a severe foliage mismatch; A3 used 2 for visible but schematic foliage. Rubric 1 is anchored to a missing feature, so A8’s severity interpretation should be clarified in a future calibration, not retrospectively revised. |
| N10 / sloans-40-foliage-off-crown-floor.png | foliage | 1 / 2 | A8 weighted the planar green crown pieces more heavily; A3 still saw present but schematic crowns. Same 1-versus-2 anchor ambiguity as N09. |
| N12 / lakeview-foliage-off-crown-off.png | ground | 2 / 1 | A8 judged the visible ground/material style without penalizing the absent scene inventory; A3 included the blank field/abrupt coverage edge in ground and overall. This is a look-versus-coverage scope disagreement under §M, not different source pixels. |
| N12 / lakeview-foliage-off-crown-off.png | overall | 2 / 1 | A8 judged the visible ground/material style without penalizing the absent scene inventory; A3 included the blank field/abrupt coverage edge in ground and overall. This is a look-versus-coverage scope disagreement under §M, not different source pixels. |

## Is the scale sensitive enough?

It distinguishes gross absence/artifacts from a developed target, but this experiment does **not** establish sensitivity to incremental crown progress. A3 assigned every Sloan mode the same overall and foliage 2; A8 assigned every overall 2 and detected only two worse 40 m foliage cases plus one light difference. Qualitative observations detect a trade-off (more openings versus thinner fragmented canopy) that mostly stays inside the same whole-point bucket. Neither rater grants v3 foliage ≥3. High agreement is largely agreement on a compressed, low-scoring set; it is not demonstrated reliability over the entire 1–5 range or a significant improvement. No weighted kappa claim is made because several aspect columns have no variation.

Keep the official whole-point rubric and gate. Add repeat blinded paired-preference judgments and fixed reasons/anchors alongside it; do not invent fractional gate scores. Separate coverage failures from look scores and calibrate the 1/2 foliage boundary before the next independent round. §N’s historical parity noise is measured on a different scale and cannot validate one-point aspect deltas here. This single session has no hidden duplicate scoring/retest estimate; exact-image aliases inherited one score.

All views are downward-looking and sky-unobservable, the reference is a summer painted still while these use October foliage with a replayed afternoon atmosphere, and Lakeview is judged against the explicitly requested Sloan style target. Seasonal hue, layout, people, mountain presence and building inventory are not copied as targets. These are comparative style judgments, not a matched four-hero §M look-gate pass. Full images were inspected; no new captures, image synthesis or pixel modifications were used. Neutral filenames obscure labels, not recognizable content; prior code knowledge remains a bias limit.

Used: GRADING.md §§M/N; A8 locked grades/commit; A3 crown-v3-ladder-blind-scores.json and key opened only after lock; 12 distinct post-fix PNGs. Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: sky N/A, one session, no retest or visual gate claim.
Tracker update:
