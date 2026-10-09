# A3 post-near-plane crown ladder scores

Delivery **c8c361d**, rendered revision **1580115**. Scoring only; no code, captures or builds. This is the current matched October control set. Older 18-frame and recapture sets are superseded as comparison controls; their historical grades are preserved.

## Blind method

Read STATE.md and GRADING.md §§M/N first; judged against `style-b-calibration-v2/frames/06-sloans.png`. Shuffled byte-exact copies into neutral frame names; separate key stayed closed, as did the manifest, until grades were locked at **2026-10-09T03:25:13.510974+00:00**. [Locked scores](crown-v3-ladder-blind-scores.json); [separate key](crown-v3-ladder-blind-key.json). All 16 PNG SHA-256 values subsequently matched the manifest. There are **12 distinct images**: three exact OFF repeats plus identical v2 standard/floor 600 m bytes. Each distinct image was scored once; aliases inherit that grade. Original files remain intact.

Grades judge stylized volume, light, colour and materials, not identical geography or summer pigment in October. Sky is out of frame throughout: N/A, not an invented numerical score. Water is discussed under materials/overall; §M has six aspects, not a separate water grade. ΔE is not the score. Lakeview uses the requested Sloan look target as a style reference, not a geographic target.

## Locked per-image grades

| Neutral frame | Sky | Light | Saturation | Ground | Foliage | Materials | Overall | Reason |
|---|---|---|---|---|---|---|---|---|
| frame-01.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Continuous blue lake without rectangular bands; uniform green ground and tiny geometric crowns remain schematic. |
| frame-02.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Clustered crowns add contour but angular orange caps dominate; flat lawns and simple roof materials limit richness. |
| frame-03.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Lake is continuous; sparse stippled canopy lacks connected shaded masses and leaves the park visually thin. |
| frame-04.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Branch scaffolds and openings are visible, but thin angular lobes read as repeated leaves-on-sticks rather than substantial crowns. |
| frame-05.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Large rounded balloon clusters and faceted caps dominate; hard flat lighting and uniform lawns remain far from target volume. |
| frame-06.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Unbroken lake surface improves readability; foliage remains small repeated polygon masses on uniform ground. |
| frame-07.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Some crowns show clustered openings, but broad angular green plates and orange balloon forms remain conspicuous. |
| frame-08.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Angular caps and clustered green forms repeat across blocks; lawn, lighting and building surfaces remain flat. |
| frame-09.png | N/A | 2 | 2 | 1 | 2 | 2 | 1 | Large blank green field dominates above an abrupt populated-area edge; small repeated crowns and flat surfaces give an incomplete scene. |
| frame-10.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Open branching is clearer but crowns become sparse orange fragments; no coherent shaded canopy mass at this distance. |
| frame-11.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Green crowns have more lobes and visible scaffolds, but orange balloons and faceted silhouettes still dominate the scene. |
| frame-12.png | N/A | 2 | 2 | 2 | 2 | 2 | 2 | Some clustered crowns improve local structure, but repeated angular caps, flat ground and simple materials dominate. |

## Unblinded results

All Sloan frames: 2026-10-15 replay, 1005×565, fixed calibration exposure; simulated clear/day summer atmosphere retained separately from the October foliage calendar. Near planes 10 / 37.5 / 150 m at 40 / 150 / 600 m. The manifest records a replay fixture, not observed weather.

| Source frame | Neutral frame | Site | Mode | Height m | Foliage | Overall |
|---|---|---|---|---|---|---|
| sloans-40-foliage-off-crown-off-fresh.png | frame-05.png | Sloan’s | OFF | 40 | 2 | 2 |
| sloans-150-foliage-off-crown-off-fresh.png | frame-12.png | Sloan’s | OFF | 150 | 2 | 2 |
| sloans-600-foliage-off-crown-off-fresh.png | frame-06.png | Sloan’s | OFF | 600 | 2 | 2 |
| sloans-40-foliage-off-crown-standard.png | frame-11.png | Sloan’s | v2 standard | 40 | 2 | 2 |
| sloans-150-foliage-off-crown-standard.png | frame-02.png | Sloan’s | v2 standard | 150 | 2 | 2 |
| sloans-600-foliage-off-crown-standard.png | frame-01.png | Sloan’s | v2 standard | 600 | 2 | 2 |
| sloans-40-foliage-off-crown-floor.png | frame-07.png | Sloan’s | v2 floor | 40 | 2 | 2 |
| sloans-150-foliage-off-crown-floor.png | frame-08.png | Sloan’s | v2 floor | 150 | 2 | 2 |
| sloans-600-foliage-off-crown-floor.png | frame-01.png | Sloan’s | v2 floor | 600 | 2 | 2 |
| sloans-40-foliage-off-crown-off-v3-standard.png | frame-04.png | Sloan’s | v3 standard | 40 | 2 | 2 |
| sloans-150-foliage-off-crown-off-v3-standard.png | frame-10.png | Sloan’s | v3 standard | 150 | 2 | 2 |
| sloans-600-foliage-off-crown-off-v3-standard.png | frame-03.png | Sloan’s | v3 standard | 600 | 2 | 2 |
| lakeview-foliage-off-crown-off.png | frame-09.png | Lakeview | OFF | 600 | 2 | 1 |

## Findings and limits

1. **v3 does not reach foliage ≥3 at either 40 or 150 m:** both are 2/5. Scaffolds and openings are clearer than v2, but narrow angular lobes form sparse sprays rather than substantial, connected shaded crown masses. At 150/600 m this becomes fragmented stippling. This is a qualitative structural change, not a whole-point improvement.
2. **Sloan’s 600 m rectangular lake banding is gone in all four modes. Overall is now 2/5, versus the historical 1/5.** Ground/materials are now 2 rather than the old artifact-affected 1. The lake remains grainy with strong broad glare, and the surrounding ground is schematic. This is a projection-fix comparison, not evidence that v3 caused the gain; old frames were not mixed into the blind set.
3. **v3 has no higher whole-point foliage or other aspect grade than matched v2.** No aspect drops numerically either. Its reduced canopy mass is a visible trade-off, especially at distance. All Sloan modes are overall 2 at all three heights; this does not pass the look gate.
4. **Repetition is visible:** v2 repeats balloon/cluster silhouettes; v3 repeats narrow branch-and-lobe spray motifs across differently coloured trees. Rotation/scale variation does not hide the shared recipe. Images alone cannot establish the literal claim that every tree of a species has identical geometry or identify every tree’s species.
5. **No obvious new near-plane cut faces or missing foreground slices are visible in the Sloan stills. Popping is untested:** stationary images cannot establish temporal continuity. After unblinding, A7’s manifest reports zero newly clipped v3 triangles at 40/150 m; that technical evidence is not a motion test. Lakeview’s abrupt populated-area edge/large blank region is visible, but this single frame does not establish its cause or attribute it to the near-plane change.
6. **Lakeview 600 m: overall 1, foliage 2, ground 1, other visible aspects 2; sky N/A.** It is a coverage/composition failure in this view. There is no matched pre-fix Lakeview 600 m score here, so no claimed hold-out delta. The Sloan gain cannot be promoted under the reject rule without matched hold-out comparisons; Wilmette/West Highland/Greenville remain pending. No new hold-outs run.

## Provenance / acceptance

Manifest read only after score lock: capture revision 1580115, Chrome/Playwright real scene capture, resolved cameras, per-pass geometry counters, non-flat PNG checks, and exact OFF repeats. These images are rendered scene outputs, not mock panels. No new budget or device acceptance is claimed; existing budget failures remain. The historical saved street-camera web pair 2/5 is not a matched aerial control. No gate, date or default mode changed.

Used: docs/lookloop/GRADING.md §§M/N; a7-web-crown-all-near-fix/manifest.json (after score lock). Mock: style-b-calibration-v2/frames/06-sloans.png. Deviation: sky unobservable; motion/popping and matched hold-out deltas pending.
