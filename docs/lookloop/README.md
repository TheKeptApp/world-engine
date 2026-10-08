# Look loop

**Gate (owner decision, 6 Oct 2026).** A view passes when both hold:
- its **concept parity** is **≥ 100 %**: its v2 /50 divided by the calibrated /50 of its target concept;
- **v2's per-criterion floors** are met: no §8.3 score below 3, geography ≥ 4, character ≥ 4, no hard-gate flags.

Milestones for the mean parity: **≥ 85 % at the end of 5A's wrap**, **≥ 100 % by the end of 5B**.

**End-of-5B gate:** each view also needs **every art-direction score ≥ 3**. This is look-fix-v1 §8, and it is tracked separately until then.

**look-fix-v1 checks** (GRADING.md §H) are reported beside the gate. Checks that a still cannot show (rain with particles hidden, stars during camera movement, all 12 lighting frames) are marked "not checkable". v2's 40/50 stays the long-term goal. Every summary and scoreboard row shows parity first.

Deterministic look captures, side-by-side contact sheets, rubric grading and a dated scoreboard, so any session can check the look quickly and honestly.

## Run it (for every session)

The look loop is the official visual gate. In any Claude session:

1. Type `/lookloop`, or `/lookloop gate` for a declared gate run. The skill is in `.claude/skills/lookloop/SKILL.md`.
2. The skill runs `Tools/lookloop/lookloop.sh run [--gate]`, spawns the reviewer sub-agents listed in `<run>/reviewers.md`, then runs `lookloop.sh finish <run>`.
3. Commit `docs/lookloop/` with the change you were judging. Then read `latest/regressions.md`.

Run kinds:

| Kind | What it captures | Reviewers |
|---|---|---|
| Routine | Only views whose inputs changed since `latest/`; the rest are reused with their grades | Sonnet |
| `--gate` | Every view | Opus |
| `--all` | Every view, without declaring a gate | Sonnet |

Options: `lookloop.sh run v2-01 showcase-03` runs only those views. `lookloop.sh calibrate` grades the concept images themselves (see [calibration.md](calibration.md)).

## What it does

| Step | Tool | Output |
|---|---|---|
| Plan | [plan.py](../../Tools/lookloop/plan.py) | Fingerprints each view's inputs and reuses unchanged views. The inputs are the git trees of `Sources`, `Apps/WorldLab`, `Package.swift` and the view's area; uncommitted changes there; the dog asset; the view entry; the common args; `capture.sh`; `GRADING.md`; and the targets. Reused views carry their previous frame and grade |
| Capture | [capture.sh](../../Tools/lookloop/capture.sh), [batch.py](../../Tools/lookloop/batch.py) | **Batched:** one WorldLab launch per area with 5A's `-viewlist`, and a Simulator screenshot at each `VIEWREADY`, so frames keep the letterbox and the OSM credit. In-view triangles and draw calls come from the `VIEWSHOT`/`VIEW` lines. When the build has no view-list hook, it falls back to one launch per view. | `raw/<id>.png`, `logs/<id>.log`. WorldLab is launched once per view in the Simulator **LookLoop iPhone 17 Pro**, which is created on first use and is nobody else's device. Launch args come from [views.json](../../Tools/lookloop/views.json) plus `-renderer realitykit -hud off -frame16x9 -rendertrace`. The tool waits for WorldLab's `STATS` line (world built), then waits `SETTLE` seconds (default 3) and takes a screenshot. Frames at 2 s and 8 s differ by less than 0.1/255. The status bar and appearance are fixed. |
| Signals and sheets | [analyze.py](../../Tools/lookloop/analyze.py) | `frames/<id>.jpg` (16:9 frame at phone width 1206 px), `sheets/<id>.jpg` (target \| current \| previous plus luma histogram and numbers), `overview.jpg`, `signals.json` |
| Grading | [grade.py](../../Tools/lookloop/grade.py), or session sub-agents | `grades/<id>.json` per [GRADING.md](GRADING.md): v2 §8.3 scores, art-direction scores, total, gate, top 3 fixes |
| Finish | [finish.py](../../Tools/lookloop/finish.py) | `grades.json`, `summary.md` (with concept parity), and `regressions.md`. The regression guard flags any view down 2 or more on /50, or any criterion down 1 or more, against the previous published run, with cautions when the grader or GRADING.md changed. Then it publishes to `docs/lookloop/latest/` and appends one row to `scoreboard.md` |

**Views**
- v2 presets 01, 04 and 06.
- experience-v1 showcase 01–09, plus aerials 10 and 11.
- Three ordinary-day entries:
  - the lake-trail afternoon (WorldLab showcase 12)
  - the W 23rd Ave street at 15:30 clear
  - the same street in light rain
- Six inactive placeholders for Wilmette (golden, rain, fall, snow) and Lakeview (three-flat, alley snow). Each carries its regions fixture values and target image.

Activate a placeholder by giving it `args` and removing `"active": false` once WorldLab can open that area and camera (see hooks below).

**Objective signals per view** (in `signals.json` and on each sheet):
- luma mean, p5/p50/p95 and clipped black/white
- mean RGB, saturation, colourfulness and edge density (detail)
- 12-bin hue histogram
- histogram intersections against each target and the previous run (luma, RGB, hue; 1 = identical)
- pixel change against the previous run
- triangles and draw calls from WorldLab's `STATS` line
- median frame time and GPU time from `RENDER` lines

Frame times and GPU times are **Simulator** figures. Use them to see change between runs, never as device performance. Know their limits:

- **Frame time** is the median after the world is built. In the Simulator it sits at the 60 Hz vsync (about 16.7 ms), so it only shows pacing problems.
- **GPU time** is `n/a` with WorldLab's default host. The default host does not time the GPU; see hooks.
- **Triangles** are whole-world totals from `STATS`, not what is in view; see hooks.
- **Render size** is recorded too. WorldLab renders the 16:9 frame at 1005 × 565 (scale 2.5×) and the screen shows it at 1206 × 678.

**Noise floor.** Two captures of the same view taken by different sessions and pipelines differ by about 1.5/255 mean per channel. The causes are rain particles, wind sway and JPEG compression. Treat a `pixel change` below about 3 against the previous run as "unchanged".

**History.**
- Every run stays in `.build/lookloop/runs/<stamp>/`, which is git-ignored. That holds the full-resolution PNGs and logs.
- Only `docs/lookloop/latest/` (JPEG frames and sheets, about 5 MB) and `scoreboard.md` go into git.
- "Previous" on the sheets is whatever `latest/` held before this run, so any checkout has a before/after.

## Timing

| Run | Capture + analysis | Grading | Notes |
|---|---|---|---|
| 6 Oct 01:02, 17 views | 13.9 min | 2.4 min (Opus) | One launch per view, 8 s settle, machine at load 400–660 |
| 6 Oct 06:39, 17 views | 6.8 min | about 1 min (Sonnet) | One launch per view, 3 s settle |
| 6 Oct 09:16 gate, 32 views | 3.5 min batched; region views redone in 3.75 min | about 3 min per wave (Opus, at most 20 at a time) | The row's 35 min includes a failed first attempt and the season recapture |

**Batched capture** (`batch.py`) does one WorldLab launch per **area and calendar date**. The world bakes its season from the launch date, so mixing dates in one launch gives the wrong season; that bug was caught and fixed in this run. The 32 views take 11 launches, each of which builds a world in 13–25 s and then steps through its views about 4 s apart.

- **Frames are WorldLab's in-app captures.** A simctl screenshot taken at `VIEWREADY` lands one view late.
- **In-app frames match settled single-launch screenshots** within 3.8–5.9/255.
- **Unchanged views are reused** (`plan.py`), so routine runs after unrelated merges capture nothing.

## Decisions (logged; covered by the specs or the P3 prompt)

1. **WorldLab is the renderer, driven through its own script arguments; there is no second app.**
   - A separate capture target cannot drive a world: `World.update` is internal, and only `WorldView` runs LOD, clutter and shader globals.
   - The showcase states, Demo weather and environment application live in WorldLab's app code (`EnvironmentController`, `Presets`, `demo.json`). A second target would have to copy them, and would then grade the copy instead of what ships.
   - The loop edits nothing in WorldLab.
   - "Offscreen" here means a headless Simulator. The Simulator app need not be open, and no screen or device is involved.
2. **The frame is 16:9, letterboxed at phone width (1206 × 678 px).** Both v2 (`frame_aspect` 16:9) and experience-v1 (aspect 16:9) define the comparison frame this way, and 5A's gate used the same frame.
3. **Default render settings** (the shared display policy). The loop grades what the app shows by default.
4. **Ordinary-day entries.** `ordinary-street` and `light-rain-street` use the v2 street camera (W 23rd Ave, where the houses, lawns and Luna are). They run at 15:30 MDT on 15 October with WorldLab's `clear` and `rain` Demo weather. `ordinary-trail` is WorldLab's own showcase 12.
5. **Rubric scale.**
   - v2 §8.3 is scored 1–5. Criterion 6 is `null` without a character, and criterion 10 is always `null` for stills (v2: "Score criterion 10 only from video").
   - The total is normalised to /50 so views are comparable.
   - The gate is v2's: ≥40/50, nothing below 3, geography ≥4, and character ≥4 when scored.
   - The owner's art-direction rules are three extra 1–5 criteria, reported beside the v2 score and not inside it, so the v2 number keeps its meaning.
6. **Grader.**
   - Reviewers are Opus (`claude-opus-5-5`), one per view, in parallel. Grading is judgement work, not mechanical.
   - Totals and the gate are recomputed in code from the scores.
   - The capture, measurement and sheet steps are plain scripts, so they need no model.
7. **Tooling is Python 3 plus Pillow**, both already on this Mac, with no new installs. The path is `Tools/lookloop/`: the existing `Tools/` folder, because the filesystem ignores case, so `tools/` would land in the same place.

8. **Evanston South replaces Wilmette** in the placeholders, as the owner asked for "Evanston South and Lakeview".
   - The cameras, focus boxes and profiles are P2's (`scripts/p2_gate_shots.sh`).
   - The targets are the regions concepts whose fixture moment each view reuses: 01/03 fall, 02 rain, 04 snow, 05 three-flat, 06 alley.
   - The aerials use street concepts as style references only.
9. **Reuse over re-render.** A view is reused only when every input in its fingerprint is identical. Any engine, app, area, view, capture or GRADING.md change re-renders and re-grades it. Gate runs never reuse.
10. **One Simulator.**
    - `LookLoop iPhone 17 Pro` stays booted between views and runs, and capture never boots a second device.
    - It is the only simulator this session boots. The others on this Mac belong to other sessions.
11. **Concept parity is the gate** (owner decision, 6 Oct 2026), with v2's per-criterion floors. 40/50 is the long-term goal. See calibration.md for why.
12. **Device mode is not built yet.** It needs the `-capture` hook (below). The Simulator remains the gate.

13. **look-fix-v1 (pending).** When ChatGPT's `docs/proposals/look-fix-v1/` lands, its "pass if…" checklists are added to GRADING.md as additional checks. The 2-hourly watch looks for it.
    - Each check is reported per view.
    - A failed check adds a top fix; it does not change the anchor scores.

## Hooks from other sessions

Delivered by 5A (main 486b43a):
- `-area`, named cameras (`-camera NAME`) and explicit cameras (`-camera lat,lon[,height],heading,pitchDown,fov`);
- `-weatherspec`, used here for the regions fixtures' weather;
- in-view `VIEW` counts;
- `-viewlist` (batched capture);
- `scripts/device_views.sh` (device frames).

Still needed:

| From | Hook | Why |
|---|---|---|
| 5A | Bundle `wilmette-vattmann-park` (P2, on main) with a named camera at Highland Ave 42.074933,-87.719996, heading 90 | Activates the five Wilmette views. Their camera is the exact regions-fixture camera, the best concept comparison |
| 5A | GPU frame time from the default RealityView host | Simulator frame time is vsync-capped; on device, Metal System Trace only |


Gate (R, 7 Oct 2026): the **look gate** replaces the concept-parity gate: pass = all four afternoon heroes at calibration closeness ≥ 4 and every aspect ≥ 3 (GRADING.md §M, "Calibration look"). Run the full Opus `--gate` when a routine Sonnet run passes it; the gate counts as passed only when the Opus run agrees (P3's mapping of the old trigger, which was mean parity ≥ 92 %; R can change it). Concept parity is still reported beside the look gate. Under the §S rubric Sonnet scored 7.0 parity points above Opus on the same frames (ccb5f77: 80.2 vs 73.2), so read milestones from Opus gate rows only. See scoreboard.md.

Heavy lock (owner, 6 Oct 2026): priority 5A > P2 > P3 > P1 (FoodZen paused). P3 holds `~/.agent-heavy-lock` only while capturing frames (build, Simulator, capture, analysis) and releases it before any grading; grading needs no lock.

Daily sheet: each evening `python3 Tools/lookloop/daily.py` writes `docs/lookloop/daily/YYYY-MM-DD.png`, six key views (ordinary-street, light-rain-street, showcase-06 smoke, wilmette-street-snow, lakeview-postcard, v2-06 aerial) at the ccb5f77 baseline (`daily/baseline-ccb5f77/`) beside the latest published run, at phone width.

Committed: scoreboard, summary, regressions, grades and the daily before/after sheet. Frames, contact sheets and the overview stay local (gitignored); plan.py reuse and daily.py read them locally.

Commit size guard (owner, 6 Oct 2026): before every push, run `Tools/lookloop/commit_size.sh` (default range origin/main..HEAD). It lists commits that add more than 20 MB; report them before pushing. See `docs/repo-size.md`.

**Reading a merge's effect (owner process, 7 Oct 2026).** After every scored run: `python3 Tools/lookloop/compare_runs.py OLD NEW` (stamps under `.build/lookloop/runs/`) lists each view's frame change (share of pixels more than 12 levels off), /50, parity, mock and archetype closeness and house criteria, and separates the views whose frame did not change (their score moves are grader variance, GRADING §N item 5) from the changed ones. `python3 Tools/lookloop/region_colours.py NEW OLD…` measures the lit colour of the wall, road, sidewalk, lawns, crowns and sky of the four afternoon hero views against their mocks (boxes in `Tools/lookloop/regions.json`) as dE, because the 1–5 closeness is too coarse to show a merge that moves a surface part of the way. Run both from a checkout that has the runs (set `LOOKLOOP_RUNS` to the folder otherwise). `python3 Tools/lookloop/calibration_colours.py NEW OLD…` does the same against the R-approved style-b-calibration-v2 frames (a surface-class dE, because those frames have their own camera; boxes in `Tools/lookloop/calibration-regions.json`), and the reviewers add `calGap` (look closeness 1–5 with six aspects) on the four afternoon heroes. `python3 Tools/lookloop/wall_variants.py STAMP` says which building, archetype and palette variant is behind each hero's walls and whether that wall faces the sun, because a wall in shade is compared with a lit wall in a mock (needs the release `worldbake`; never builds it). Baseline: `docs/lookloop/calibration-baseline.md`.
