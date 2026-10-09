# A3 native season check — summer BEFORE

A3 scored the three fresh A10 frames from [ae0e110](../research/crown-native-summer-before-evidence.md), capture build `0600748`, against approved `style-b-calibration-v2/frames/06-sloans.png`, using GRADING.md §M with §S/§V seasonal interpretation. July 15, 2026 at 20:30 UTC; clear/cloud0/wind0, no character; Sloan’s pose 39.7511195, -105.0389, heading 270, pitch 45, FOV 50; 1005×565; foliage exp1 off, no crown adapter, pinned gain 1.0. No new capture/build or render changes by A3.

## Blind grades and October comparison

Fresh PNGs were copied unchanged to `/private/tmp/a3-season-blind/`, randomly shuffled and labelled R/S/T. Grades/reasons were locked before opening the source key; the random order happened to be 40/150/600 m. Altitude is visually inferable and summer was known: this is label-blind grading, not a blinded season experiment. [JSON](crown-native-summer-scores.json) records the lock timestamp, labels, original paths, checked SHA-256 hashes and per-frame reasons. Originals preserved. Sky is outside the downward views (N/A), not a missing-feature grade. All numeric grades /5.

| Altitude / date | Sky | Light | Saturation | Ground | Foliage | Materials | Overall |
|---|---|---|---|---|---|---|---|
| 40 m October 15, historical | N/A | 2 | 2 | 2 | 2 | 2 | 2 |
| 40 m July 15, R | N/A | 2 | 2 | 2 | 2 | 2 | 2 |
| 150 m October 15, historical | N/A | 2 | 2 | 2 | 2 | 2 | 2 |
| 150 m July 15, S | N/A | 2 | 2 | 2 | 2 | 2 | 2 |
| 600 m July 15, T | N/A | 2 | 2 | 2 | 2 | 2 | 2 |

At both comparable altitudes, the **reported grade difference is zero for light, saturation, ground, foliage, materials and overall; sky is unassessable**. October 600 m remains unscored because of its noisy control, so no 600 m seasonal delta is available. [October BEFORE grades](crown-native-before-scores.md) are preserved, not regraded. No foliage 2→3 or aspect drop is observed. At 40 m crowns still read as large faceted blobs with abrupt lobe joins and mechanically exposed scaffold. At 150 m repeated angular masses and strong green/teal colours remain; green matches the summer palette family better without reaching a higher whole-point grade. Flat lawns/roads, simple material response and broad uniform shadows remain the main non-foliage gaps. At 600 m canopy/ground masses and flat cyan water remain simplified; do not penalize missing fine leaf detail or the mock’s different layout. ΔE did not determine grades.

## Is the summer mock fair for October?

**Fair as a shared form/shading/material-quality reference; not fair as a literal foliage-colour match.** The calibration frame has green summer foliage, while GRADING.md §V and vegetation-v1 README “Four seasons and weather” require region/species-appropriate autumn colours. October should not lose points merely for appropriate gold/yellow/orange rather than green. Judge crown volume, light relationships and material quality against the calibration; judge seasonal pigments against the approved seasonal references. The Denver vegetation sheet was viewed alongside the calibration. This qualifies the use of the target without rewriting historical scores or changing its gate assignment.

**No demonstrated ≥1-point movement, so no score-triggered gate-date change is recommended. The gate remains unchanged.** These are descriptive scores, not a clean causal season experiment: October `e5a0a3e` used auto-exposure, July `0600748` uses pinned gain; source/data revisions and solar conditions also differ. Old auto-exposed frames are not matched controls for pinned captures. To establish a season-only effect would require an October/July pair on the same revision and pinned policy, with the intended date-driven sun difference explicit. No such new capture is authorized or run here. These inspection views do not replace the four street heroes or establish a hold-out/reject-rule pass.

## Control and evidence limits

A10’s 150 m fresh/repeat has matching six-category coverage, pose/date/size and shader/library hashes; decoded RGBA max 1/255, mean 0.000213093822921 byte units, 484/2,271,300 differing bytes. PNGs are not byte-identical. These reported control numbers do not amend any gate or prove a shader-category pass. No 40/600 m repeat was supplied in this task. No hold-outs run; native hero 3/5 and saved web pair 2/5 remain historical, separate fixtures.

Used: GRADING.md §M/§S/§V; crown-native-summer-before-evidence.md §Frames and metadata / 150 m fresh versus repeat. Mock: style-b-calibration-v2/frames/06-sloans.png; vegetation-v1/images/02-denver.png. Deviation: exposure/revision-confounded seasonal comparison; sky N/A; October 600 m unscored.
Tracker update:
