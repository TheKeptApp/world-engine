# Native versus web — Sloan’s comparison and matching limits

**No fully matched pair is available in this supplied set.** Nominal geographic poses and dates match, but the resolved native eye is 0.16 m higher at every altitude, exposure is not matched, and weather/context differ. Therefore **no matched-platform preference or gate conclusion is awarded**. The six-presentation observations below are retained as exploratory evidence, not an attributed renderer improvement. No code, capture, build or image correction was performed.

Sources: native `e5a0a3e`, [BEFORE evidence](../research/crown-native-before-evidence.md), fresh controls only; web capture `1580115`, delivery `c8c361d`, [post-near-plane OFF set](../lookloop/captures/a7-web-crown-all-near-fix/). No crown variants, summer frames or superseded web batches were mixed in.

## Matching audit — performed after grades/preferences locked

| Height | Pose/date match | Exposure and fixture | Admissible matched preference? |
|---|---|---|---|
| 40 m | Same requested lat/lon 39.7511195, −105.0389, heading 270°, pitch down 45°, FOV 50°, 1005×565; native resolved y=40.16 versus web 40 | Native automatic gain unrecorded; web fixed gain 1.2745606273192622 (+0.35 EV), contrast 1.06, saturation 1.08 | No: resolved eye +0.16 m and exposure/fixture confounds |
| 150 m | Same requested pose/date; native y=150.16 versus web 150 | Same exposure mismatch; exact EV difference unknown | No |
| 600 m | Same requested pose/date; native y=600.16 versus web 600 | Same mismatch plus known native repeat brightness noise | No; descriptive only |

Both retain `2026-10-15T20:30:00Z` replay metadata (date/time difference **0**); web uses authored afternoon light, not astronomical calculation from that UTC. Native resolved x/z 479.9372/−190.9308 versus web 479.9371916990588/−190.93080230114043: component differences about 0.0000083/0.0000023 m at saved precision. Native forward vector from the saved camera matrix is approximately (−0.7071068, −0.7071068, 0.0000001192), versus web (−0.7071067812, −0.7071067812, ~0): heading difference about **0.00001°**, pitch effectively identical. Nominal FOV difference 0°; native projection matrix/near/far was not retained in this manifest, so full projection equality is unproved. Web near/far is 10/150000, 37.5/150000 and 150/150000 m respectively. No image warping or cropping was used to manufacture registration.

Native clear/cloud0/**wind0** versus web clear/day/**wind10 km/h from225°**, with a summer-clear atmosphere fixture separate from its October foliage calendar: wind-speed difference **10 km/h**. Native sun log is elevation35.8°/azimuth212.4°; exact cross-renderer illumination equivalence is not established. Native automatic exposure lacks saved gain/readback; **a numerical native–web EV delta cannot be recovered from these records**. Treating web +0.35 EV as the difference would be false. Native 600 m repeat differs in 1,694,760 RGBA bytes (max7, mean3.1852701096); its previous STOP remains in force. Native includes coarse surrounding context; web ends at its exported area. These are additional content differences, not camera motion.

The native source hashes were verified against the fresh entries in `validation-manifest.json`; web identity was checked against the requested OFF files. All original images remain intact.

## Review procedure and its limits

Six source images were copied byte-for-byte with shuffled neutral names; the [key](native-vs-web-blind-key.json) was kept separate. [Whole-point grades](native-vs-web-blind-grades.json) were locked first, then [24 presentation records](native-vs-web-blind-preferences.json): six per altitude plus six identical-image controls. Manifests/key were opened only after both locks in this turn. The web manifest had been seen in the prior scoring task, so this is **not first-exposure blinding**.

Three review passes each presented both orders of each pair, shuffled and interleaved. A and B were displayed sequentially at equal size by the image tool, **not spatial left/right side-by-side**. Thus this tests presentation-order consistency, not a left/right-position bias. All passes shared one conversation context, not three independent sessions; the presentation list exposed repeated neutral filenames, so controls were not fully hidden. Platforms were recognizable from shading and the web credit strip. These are material deviations from the proposed [paired-preference protocol](paired-preference-protocol.md); **do not call this a completed reliability test or statistically reliable blind experiment**. R explicitly requested the cross-renderer comparison; the protocol's usual separate-renderer scope is relaxed for this report only. Matching and promotion requirements remain intact.

All directional observations selected the same underlying image in each order (3/3 first, 3/3 second); saturation at 40/150 m was tie6/6. All six identical-image presentations yielded six-aspect ties and matching roof answers, but exposed control identity weakens that check. No dissent is hidden. Conventional exploratory grades stayed **2/5 overall and every visible aspect for all six images**, sky N/A. The 600 m native grade is an observation of this still only, not acceptance of its noisy capture control, and does not replace the earlier unscored gate record.

## Unblinded preference table

“Observed preference” is the locked visual choice for these specific images; **every row is excluded from a fully matched comparison**. Counts are native/web/tie across six presentations, not six independent reviewers.

| Height m | Aspect | Observed preferred platform | Native / web / tie | Matched conclusion |
|---|---|---|---|---|
| 40 | saturation | Tie | 0 / 0 / 6 | Not established |
| 40 | materials | Native (exploratory) | 6 / 0 / 0 | Not established |
| 40 | ground | Native (exploratory) | 6 / 0 / 0 | Not established |
| 40 | foliage | Native (exploratory) | 6 / 0 / 0 | Not established |
| 40 | light | Native (exploratory) | 6 / 0 / 0 | Not established |
| 40 | overall | Native (exploratory) | 6 / 0 / 0 | Not established |
| 150 | saturation | Tie | 0 / 0 / 6 | Not established |
| 150 | materials | Native (exploratory) | 6 / 0 / 0 | Not established |
| 150 | ground | Native (exploratory) | 6 / 0 / 0 | Not established |
| 150 | foliage | Native (exploratory) | 6 / 0 / 0 | Not established |
| 150 | light | Native (exploratory) | 6 / 0 / 0 | Not established |
| 150 | overall | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | saturation | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | materials | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | ground | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | foliage | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | light | Native (exploratory) | 6 / 0 / 0 | Not established |
| 600 | overall | Native (exploratory) | 6 / 0 / 0 | Not established |

## What the pictures show

**Native does better in these stills:** softer shadow edges, stronger shaded crown volume, visible lawn variation and cleaner water without the web's fine speckle. These account for the descriptive preference. They do not isolate the cause: exposure, lighting, geometry/LOD and ground treatments differ together.

**Web does better in specific details:** at 40 m several rounded crown groups have smaller lobes rather than native's few large polygon chunks, and at 600 m its lake has more visible surface modulation instead of a nearly flat fill. Those are local advantages, offset by flat crown shading and excessive water grain/glare; they did not yield an aspect-level preference. There is no defensible requirement to name a winning web aspect when none was preferred.

**Both lack:** convincing connected crown masses with natural branching/openings, restrained roof/foliage balance, rich but coherent ground materials and a convincing transition beyond the detailed area. Both still read as simplified polygon scenes rather than the approved calibration look. Autumn colour itself is not penalized for differing from a green summer mock.

- **Water:** native is cleaner at 600 m: smooth blue water, but too uniform. Web has pervasive fine grain and a broad cream/gold glare area on the left. Native **also has glare**, a localized bright white bloom at the left edge; it is false to say glare is absent in native. Neither shows the old rectangular web lake bands. Wind/exposure mismatch prevents attributing the difference solely to the water implementation. Water is absent at 40 m and only marginally visible at 150 m, so the useful water comparison is 600 m.
- **Lawn variation:** native has distinct green patches, mottling and softened shade; at 600 m some large rectilinear/checker-like patches are conspicuous. Web is largely uniform pale green. More native variation is preferred here, but it is not uniformly convincing texture or a verified recipe to port.
- **Loaded-area edge at 600 m:** native abruptly shifts from detailed neighbourhood to a coarse, flat road grid with simple blocks/rectangles. Web abruptly terminates the detailed package into broad blank green ground. Neither provides a convincing continuous city; native context presence should not be mistaken for detailed coverage, or web emptiness for successful simplification.
- **Orange roof group at 150 m:** **yes, both** show the vivid orange/red roof group in the lower-right foreground (also visible at40m). In all six presentations at40/150, “roofs compete with trees” is **yes for both**; at600 it is **no for both** at this display scale, where the lake dominates. This is attention balance, not an inference about source roof accuracy.

## Disposition

Matched-preference result **PENDING**. A future owner-authorized comparison needs resolved camera/projection equality, declared equivalent exposure/atmosphere, controlled content/LOD or explicit separation of those factors, and a stable native600 control. No captures are requested or run by this report. Fresh independent review and genuinely randomized spatial presentation would be required for the proposed protocol's reliability claim. Existing platform gates and hold-out status remain unchanged; no cross-renderer score delta, promotion or reject-rule pass is asserted.

Used: paired-preference-protocol.md; GRADING.md §M; crown-native-before-evidence.md and post-near-plane OFF manifests (after locks). Mock: style-b-calibration-v2/frames/06-sloans.png, already inspected in this scoring session history. Deviation: unmatched exposure/0.16m eye offset, noisy native600, recognizable platforms and same-context sequential-order repeats; exploratory only.
