# P2 Batch 2 — blind native roadclip / commercialpoints pairs

10 Oct 2026. Scoring only; **no promotion, no recapture**. [Source README](../lookloop/captures/p2-batch2-roadclip-commercial/README.md), delivered on main `9137307`; manifest capture commit `5949a777edb55a99aa8c6ce18d7b79574a8dcdff`. Existing source PNGs preserved.

## Result

All **24/24 identical controls pass** their scoped aspect, overall and roof consistency; no control-flagged unreliable aspect. All **66 overall grades are2/5** (22 frames×3 sessions), with no whole-point change in any pair.

- **roadclip, six ladder views:** roads/sidewalks and overall each **0 OFF /0 roadclip /6 ties** at Sloan40/150/600 and Lakeview40/150/600. No defensible preference at the registered phone presentation. This does not negate the crossing-removal measurements: an implementation correction can be too small to move a whole-view look judgment.
- **commercialpoints, six ladder views:** buildings/houses and overall each **0 OFF /0 commercialpoints /6 ties**. Sloan40 and Lakeview40 commercial frames are byte-identical to OFF; their pair judgments correctly tie and their whole-point grades agree. Other small differences do not produce a repeatable ladder preference.
- **commercialpoints, both storefront pairs:** buildings/houses and overall each **0 OFF /6 commercialpoints /0 ties**, with candidate winning **3 left/3 right**. At Sloan the reviewers see readable wall colour/openings instead of a near-black wall band and gentler roof/wall contrast. At Lakeview they see clearer warm-wall/dark-roof separation and window rhythm. This is a repeatable preference within the2/5 band, **not a3/5 or gate pass**. Detailed storefront compliance, actual classification and fixture equivalence are not proved.

Across168 real-pair aspect judgments:144 ties and24 commercialpoints wins (12 left/12 right); all84 within-session swapped aspect judgments agree. Reviewers report scene/repeat familiarity but no variant identity knowledge. No position-dependent reversal, discarded vote or additional result-chasing session. No focus-gain/Lakeview-loss pattern in this batch: both close-ups prefer the same treatment and ladder grades stay fixed. Wilmette, West Highland and Greenville native evidence is absent; hold-out acceptance remains pending. **No promotion.**

## Registered scope and exposure limit

| Trial | Scored preferences | Scope limit |
|---|---|---|
| roadclip | Roads/sidewalks; overall | Circulation and road/sidewalk boundaries. Buildings, foliage, light and shadows are not separately scored or recorded as ties. |
| commercialpoints | Buildings/houses; overall | Building massing, wall/roof/trim separation and facade rhythm; includes the storefront views. Roads, foliage, light and shadows are not separately scored. Overall includes the whole visible scene. |

**Exposure caveat:** frames use **pinned exposure gain1.0**. R supplied 5A’s measured live settled Sloan gains: **1.11 at40m,1.17 at150m,0.65–0.70 at600m**; the reported consequence is **40/150m frames10–15% too dark and600m frames35–43% too bright**. This is the supplied live-vs-pinned exposure caveat, not a new pixel-luminance measurement by A3. No exposure correction, live-app score or recapture. These measured gains were supplied for Sloan; no Lakeview or storefront settled gains were supplied.

The four extra storefront PNGs are **two OFF/ON pairs**, one per area, not four independent pairs. README says40m from a converted building with45° pitch; exact camera/date/exposure logs for these close-ups are absent from the manifest. They are scored descriptively as the requested supplied pairs; full matching/provenance remains unverified. Do not infer geographic classification accuracy or a gate pass from their appearance.

## Frozen inputs and blind procedure

18 ladder PNG hashes match the manifest. Four tracked close-up hashes were recorded independently; they are not enumerated in that manifest. All22 PNGs are1005×565. Ladder fixture is native Simulator,2026-10-15T20:30Z, clear/cloud0/wind0, no character, cameras referenced to Batch0. No independently observed camera logs in this manifest; source documentation supplies matching, not an A3 recapture. The batch uses original `sloans-lake`, not the later108-cell extended package.

Three fresh reviewer contexts received only their own neutral copies, scope list, ten reference images and rubric/protocol, without source labels, prior grades, expected changes or other sessions. Coordinator prepared the identity key and did not grade. Each locked22 overall1–5 grades before viewing36 shuffled A/B panels:14 comparisons, twice with reversed spatial positions, plus8 identical controls. That is six judgments per pair,three OFF-left/three OFF-right across three contexts. Each session includes the six supplied ladder OFF-copy controls, plus two coordinator-prepared identical pairs from the close-up OFF frames. Those extra controls are not independent captures. Every control’s displayed RGB content was checked identical.

Scope rotates across ladder controls; close-up controls use buildings/houses. In total:9 road controls,15 building controls,24 overall controls. Controls are hidden among ordinary panels with the same task. Reference content: calibration06-sloans/01-lakeview; corrected facade-detail-v2 Denver mixed-use image and near/mid/far panels; v2b Chicago cornerMixedUse; approved infrastructure residential, alley and crossing sheets. Images govern qualitative look, not literal geography or inferred real building dimensions. Exact camera-matched mock unavailable. No pending pack promoted.

Neutral full frames supplied whole-point grades before the fixed390px-per-side full-frame pairs. No crops or post-hoc zoom/enhancement. Reference images retained supplied sizes. A tie means no defensible preference at this presentation size, not byte identity. Recognition, reasons, roof answers, positions and lock timestamps are preserved in the [raw records](p2-batch2-scoring/results.json) and [separate key](p2-batch2-scoring/key.json). [Protocol](paired-preference-protocol.md): ≥5/6 wins with≥2/3 in each position is repeatable preference;≥5/6 ties is repeatable tie; other outcomes inconclusive, not-assessable leaves incomplete. Failed controls flag affected session/aspect and conservatively its pooled aspect results; none are discarded. This is a consistency screen, not population statistics or independent human replication.

## Per-view counts and overall grades

Counts=OFF wins / candidate wins / ties / not assessable (six judgments). Overall grades=session1/session2/session3, not averaged. Position=OFF wins left/right; candidate wins left/right.

| View / candidate | Aspect | Counts | Position | OFF overall | Candidate overall | Conclusion |
|---|---|---|---|---|---|---|
| lakeview-150 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-150 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-40 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| lakeview-600 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-150 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-40 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / commercialpoints | buildings_houses | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / commercialpoints | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / roadclip | roads_sidewalks | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| sloans-600 / roadclip | overall | 0/0/6/0 | 0/0; 0/0 | 2/2/2 | 2/2/2 | repeatable tie |
| storefront-lakeview / commercialpoints | buildings_houses | 0/6/0/0 | 0/0; 3/3 | 2/2/2 | 2/2/2 | commercialpoints preferred |
| storefront-lakeview / commercialpoints | overall | 0/6/0/0 | 0/0; 3/3 | 2/2/2 | 2/2/2 | commercialpoints preferred |
| storefront-sloans / commercialpoints | buildings_houses | 0/6/0/0 | 0/0; 3/3 | 2/2/2 | 2/2/2 | commercialpoints preferred |
| storefront-sloans / commercialpoints | overall | 0/6/0/0 | 0/0; 3/3 | 2/2/2 | 2/2/2 | commercialpoints preferred |

## Controls

| Session | View | Panel | Scope | Failed aspects | Roof consistency |
|---|---|---|---|---|---|
| 1 | lakeview-40 | pair-03 | roads_sidewalks | none | True |
| 1 | storefront-lakeview | pair-09 | buildings_houses | none | True |
| 1 | lakeview-600 | pair-10 | buildings_houses | none | True |
| 1 | sloans-40 | pair-13 | buildings_houses | none | True |
| 1 | lakeview-150 | pair-20 | buildings_houses | none | True |
| 1 | sloans-150 | pair-24 | roads_sidewalks | none | True |
| 1 | storefront-sloans | pair-28 | buildings_houses | none | True |
| 1 | sloans-600 | pair-30 | roads_sidewalks | none | True |
| 2 | lakeview-600 | pair-04 | roads_sidewalks | none | True |
| 2 | storefront-lakeview | pair-10 | buildings_houses | none | True |
| 2 | lakeview-150 | pair-17 | roads_sidewalks | none | True |
| 2 | sloans-40 | pair-18 | roads_sidewalks | none | True |
| 2 | sloans-600 | pair-19 | buildings_houses | none | True |
| 2 | lakeview-40 | pair-26 | buildings_houses | none | True |
| 2 | sloans-150 | pair-28 | buildings_houses | none | True |
| 2 | storefront-sloans | pair-34 | buildings_houses | none | True |
| 3 | lakeview-150 | pair-01 | buildings_houses | none | True |
| 3 | lakeview-600 | pair-07 | buildings_houses | none | True |
| 3 | sloans-40 | pair-13 | buildings_houses | none | True |
| 3 | lakeview-40 | pair-14 | roads_sidewalks | none | True |
| 3 | storefront-lakeview | pair-15 | buildings_houses | none | True |
| 3 | storefront-sloans | pair-21 | buildings_houses | none | True |
| 3 | sloans-150 | pair-22 | roads_sidewalks | none | True |
| 3 | sloans-600 | pair-24 | roads_sidewalks | none | True |

## Roof balance / repeat diagnostics

| Pair | Mode | Yes/no/not assessable |
|---|---|---|
| storefront-lakeview/commercialpoints | commercialpoints | 2/4/0 |
| storefront-lakeview/commercialpoints | off | 2/4/0 |
| lakeview-600/commercialpoints | off | 0/6/0 |
| lakeview-600/commercialpoints | commercialpoints | 0/6/0 |
| storefront-sloans/commercialpoints | commercialpoints | 6/0/0 |
| storefront-sloans/commercialpoints | off | 6/0/0 |
| lakeview-150/commercialpoints | off | 0/6/0 |
| lakeview-150/commercialpoints | commercialpoints | 0/6/0 |
| lakeview-600/roadclip | roadclip | 0/6/0 |
| lakeview-600/roadclip | off | 0/6/0 |
| sloans-40/roadclip | roadclip | 6/0/0 |
| sloans-40/roadclip | off | 6/0/0 |
| lakeview-150/roadclip | off | 0/6/0 |
| lakeview-150/roadclip | roadclip | 0/6/0 |
| sloans-600/roadclip | roadclip | 0/6/0 |
| sloans-600/roadclip | off | 0/6/0 |
| lakeview-40/roadclip | off | 0/6/0 |
| lakeview-40/roadclip | roadclip | 0/6/0 |
| lakeview-40/commercialpoints | off | 0/6/0 |
| lakeview-40/commercialpoints | commercialpoints | 0/6/0 |
| sloans-150/commercialpoints | commercialpoints | 6/0/0 |
| sloans-150/commercialpoints | off | 6/0/0 |
| sloans-40/commercialpoints | off | 6/0/0 |
| sloans-40/commercialpoints | commercialpoints | 6/0/0 |
| sloans-150/roadclip | off | 6/0/0 |
| sloans-150/roadclip | roadclip | 6/0/0 |
| sloans-600/commercialpoints | commercialpoints | 0/6/0 |
| sloans-600/commercialpoints | off | 0/6/0 |

All swapped judgments and recognition notes are retained, including disagreement; no extra session added to obtain a preferred result.

## Technical limits, separate from scores

| Ladder view | OFF main tris/draws | roadclip | commercialpoints |
|---|---|---|---|
| lakeview-150 | 271,763/48 | 271,763/48 | 271,961/48 |
| lakeview-40 | 295,759/56 | 295,759/56 | 295,196/56 |
| lakeview-600 | 194,160/35 | 194,160/35 | 193,754/35 |
| sloans-150 | 333,744/50 | 333,464/50 | 333,744/50 |
| sloans-40 | 312,880/53 | 312,606/53 | 312,880/53 |
| sloans-600 | 228,013/43 | 227,999/43 | 228,001/43 |

Ladder main counts satisfy<400k triangles/≤100 draws; that is not a shadow, device, memory or full floor acceptance. Close-up counts absent. Manifest original OFF/main check: four exact, Sloan150/600max1/255 (42/40 differing channel bytes). Later README main5c511f9 recheck supersedes that comparison: four exact, Sloan150max1/255(197 bytes), Sloan600max2/255(198 bytes). Do not relabel the rechecked600m as lossless.

Geometric crossing counts and classification totals in P2’s README are implementation measurements, not A3 look grades. Width/curb-end and alley exceptions, small-shop limitations, inherited window-size deviation and incomplete close-up fixture provenance remain. No new family approval, small-shop conversion ruling, shadow reach change or promotion. Wilmette, West Highland and Greenville native paired scores remain pending.

Used: Batch2 README §§1–3 and merge recheck; facade-detail-v2 content.families[denver-mixed-use], v2b chicago-cornerMixedUse; GRADING §§M/N and paired-preference protocol. Mock: calibration06-sloans/01-lakeview, facade mixed-use boards, infrastructure residential/alley/crossing sheets; full list in key. Deviation: scoped preferences, close-up hashes/controls prepared locally, incomplete close-up manifest provenance, pinned exposure mismatch; no promotion.
