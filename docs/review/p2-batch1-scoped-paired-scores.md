# P2 Batch 1 — fresh, scope-limited native paired scoring

9 Oct 2026 (America/Denver). Fresh review requested after the [first five-aspect review](p2-batch1-paired-scores.md); that history remains intact. The new aspect scope was registered before judgments. Same source delivery `5ded499`, capture build `64d1185dda3a7d2371885300510498592e5bec29`; no new captures, builds, look changes or promotion. [P2 evidence](../lookloop/captures/p2-batch1-lawn-walls/README.md).

## Result

**No measured visual preference at the registered presentation size; no promotion.** At every view—Sloan40/150/600 and Lakeview40/150/600—lawnsmooth ground and overall are **0 OFF /0 candidate /6 ties**, and wallspread houses and overall are **0/0/6**. All54 overall grades (18 images×3 sessions) are **2/5**. No whole-point difference within any OFF/candidate pair. All18 identical-image controls pass the assigned feature, overall and roof consistency; **no scored aspect is flagged unreliable by a control**.

The viewers describe similarly flat lawns, equivalent wall/roof/trim separation at phone size, angular crowns and limited material richness. Sloan's conspicuous red roof group competes with foliage at40/150m; neither trial visibly resolves the overall balance. These are reasons for overall2, not additional foliage/shadow scores. At600m, distant massing and broad park/context surfaces dominate; small lawn/wall adjustments do not produce a defensible preference.

All144 real-pair aspect judgments are ties, with0 directional left/right votes and72/72 within-session swapped aspect judgments agreeing. Repeat/scene recognition is disclosed in every review; no variant identity was claimed. This supports a tie **at390px per side**, not pixel identity or proof that the change is invisible at every scale. Conventional grades used the neutral full frames before the phone-size pair stage; references retained their supplied image sizes, so exact aerial-to-mock pixel/composition matching is not claimed.

The earlier review's Lakeview40/150 overall3/3/2 and isolated ground preferences are retained as historical reviewer variation. This fresh, separately scoped run is not pooled with it, cannot retroactively erase it, and is not evidence of a renderer regression or improvement: source bytes are unchanged. No Sloan-gain/Lakeview-loss trigger in these comparisons; other required hold-outs remain pending.

## Scope fixed before review

| Comparison | Scored preferences | Excluded aspects and reason |
|---|---|---|
| OFF vs lawnsmooth | Ground; overall | Houses, foliage and shadows: no changes to their geometry/material rules or the shadow pass. Lawn albedo can change perceived contrast; any effect on the whole scene is assessed in overall, without attributing a new crown or shadow rule. |
| OFF vs wallspread | Houses; overall | Ground, foliage and shadows: the trial changes only unmapped wall value factors; no ground, crown, lighting or shadow rule changes. Relative scene contrast is assessed in overall. |

Excluded aspects are **outside scope**, never scored as ties or presumed unchanged from an image test. Whole-point grades are **overall only**, as requested; the scored feature has preference counts. A control is assigned one of the same scopes, so its task does not identify it as a control. Each of the six views has its supplied identical OFF-copy pair in each session; scope assignment rotates across sessions, giving nine ground controls, nine house controls and eighteen overall controls, with both feature scopes covered at every view across the three sessions.

## Blind method, provenance and limits

Three fresh reviewer contexts receive only their own neutral frames, references, rubric, protocol and scope list—not prior scores, labels, implementation claims, manifests, keys or other sessions. A separate coordinator knows identities and does not grade. Reviewers inspect 14 references and lock 18 overall grades before opening 30 shuffled A/B panels each:12 comparisons repeated in opposite positions plus6 controls. This yields6 judgments per comparison,3 OFF-left and3 OFF-right, across3 contexts. This is a repeatability screen, not six independent people or a validated statistical test. No extra judgments were added in response to a result.

All18 source frame SHA-256 hashes and six supplied OFF-copy controls were checked. Camera and main triangle/draw counts match within each view; sources are native Simulator,1005×565,2026-10-15T20:30Z, clear/cloud0/wind0, heading270°, pitch45°, FOV50°. **Pinned exposure gain1.0 may look darker than the real app.** Scores describe this fixture only. Source controls are copied images, not independent render repeats. Against main Batch0, four OFFs are byte-identical; Sloan150 differs36 channel bytes,max1/255; Sloan600 differs316,max2/255. Known noise remains disclosed. Source PNGs were preserved.

Byte-exact neutral originals precede equal-size A/B panels at390px per side; no crops, pixel compensation or post-hoc enhancement. Calibration06-sloans/01-lakeview govern the broad look; approved house-contrast and archetype boards supplement architecture. Ground-v1/look-fix sheets are historical research context, not new approval for their numeric values. No exact approved aerial composition target exists for these six poses; October pigment is not forced to a summer mock. The [key and source hashes](p2-batch1-scoped-scoring/key.json), [identity audit](p2-batch1-scoped-scoring/identity-audit.json), panel hashes, individual grades and all reasons are retained.

Per the [paired protocol](paired-preference-protocol.md) and GRADING §§M/N: preference requires ≥5/6 for the same image and ≥2/3 in each screen position; ≥5/6 ties is repeatable tie. Other results are inconclusive; not-assessable votes stay incomplete. Any directional control vote marks the affected session/aspect unreliable; this report conservatively flags its pooled aspect results and retains every vote. Roof-answer inconsistency is also disclosed. Passing controls cannot remove recognition, display-size limits or grader drift.

## Per-view counts and overall grades

Counts = OFF wins / candidate wins / ties / not assessable, out of6. Overall grades are sessions1/2/3 (not averaged). Position = OFF wins left/right; candidate wins left/right.

| View / candidate | Aspect | Counts | Position | Overall OFF | Overall candidate | Conclusion |
|---|---|---|---|---|---|---|
| lakeview-150 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / lawnsmooth | ground | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / lawnsmooth | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / wallspread | houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / wallspread | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |

## Identical controls

| Session | View | Panel | Scope | Failed aspects | Roof answers consistent |
|---|---|---|---|---|---|
| 1 | sloans-150 | pair-08 | ground | none | True |
| 1 | sloans-600 | pair-19 | ground | none | True |
| 1 | lakeview-600 | pair-21 | houses | none | True |
| 1 | lakeview-150 | pair-23 | houses | none | True |
| 1 | sloans-40 | pair-25 | houses | none | True |
| 1 | lakeview-40 | pair-26 | ground | none | True |
| 2 | lakeview-40 | pair-01 | houses | none | True |
| 2 | sloans-40 | pair-04 | ground | none | True |
| 2 | lakeview-600 | pair-15 | ground | none | True |
| 2 | lakeview-150 | pair-19 | ground | none | True |
| 2 | sloans-600 | pair-21 | houses | none | True |
| 2 | sloans-150 | pair-24 | houses | none | True |
| 3 | lakeview-150 | pair-01 | houses | none | True |
| 3 | sloans-150 | pair-03 | ground | none | True |
| 3 | lakeview-40 | pair-08 | ground | none | True |
| 3 | sloans-40 | pair-19 | houses | none | True |
| 3 | sloans-600 | pair-21 | ground | none | True |
| 3 | lakeview-600 | pair-22 | houses | none | True |

## Roof balance and repeat diagnostics

| Pair | Mode | Yes / no / not assessable |
|---|---|---|
| lakeview-40/wallspread | off | 0/6/0 |
| lakeview-40/wallspread | wallspread | 0/6/0 |
| sloans-40/lawnsmooth | lawnsmooth | 6/0/0 |
| sloans-40/lawnsmooth | off | 6/0/0 |
| lakeview-600/wallspread | off | 0/6/0 |
| lakeview-600/wallspread | wallspread | 0/6/0 |
| sloans-600/wallspread | off | 0/6/0 |
| sloans-600/wallspread | wallspread | 0/6/0 |
| sloans-40/wallspread | wallspread | 6/0/0 |
| sloans-40/wallspread | off | 6/0/0 |
| lakeview-40/lawnsmooth | off | 0/6/0 |
| lakeview-40/lawnsmooth | lawnsmooth | 0/6/0 |
| sloans-150/wallspread | wallspread | 6/0/0 |
| sloans-150/wallspread | off | 6/0/0 |
| lakeview-600/lawnsmooth | off | 0/6/0 |
| lakeview-600/lawnsmooth | lawnsmooth | 0/6/0 |
| sloans-600/lawnsmooth | lawnsmooth | 0/6/0 |
| sloans-600/lawnsmooth | off | 0/6/0 |
| lakeview-150/wallspread | off | 0/6/0 |
| lakeview-150/wallspread | wallspread | 0/6/0 |
| lakeview-150/lawnsmooth | off | 0/6/0 |
| lakeview-150/lawnsmooth | lawnsmooth | 0/6/0 |
| sloans-150/lawnsmooth | off | 6/0/0 |
| sloans-150/lawnsmooth | lawnsmooth | 6/0/0 |

All swapped-pair agreement records and raw minority votes remain in [results.json](p2-batch1-scoped-scoring/results.json); recognition notes remain in each session record. No failed control or unfavorable judgment is discarded.

## Bounded technical evidence

| View | Main triangles (all modes) | Main draws (all modes) |
|---|---|---|
| lakeview-150 | 271,763 | 48 |
| lakeview-40 | 295,759 | 56 |
| lakeview-600 | 194,160 | 35 |
| sloans-150 | 333,744 | 50 |
| sloans-40 | 312,880 | 53 |
| sloans-600 | 228,013 | 43 |

Main counts meet <400k triangles/≤100 draws in these frames only. This does not establish shadow cost, memory, minimum-device performance or a ship-bar pass. Missing Wilmette, West Highland and Greenville native comparisons stay pending. Wallspread0.82–1.22 is an experimental P2 choice, not a newly approved mock value. Neither trial is promoted.

Used: P2 Batch1 README §§1–3, native Batch0 controls, palette-diagnosis §1, paired-preference protocol, GRADING §§M/N. Mock: calibration-v2 06-sloans/01-lakeview plus house-contrast/archetype boards; full reference list in key.json. Deviation: fresh scope-limited review, six controls per session, pinned gain1.0; no promotion.
