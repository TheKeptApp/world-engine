# Look loop

**Gate (owner decision, 6 Oct 2026).** A view passes when both hold:
- its **concept parity** is **≥ 100 %**: its v2 /50 divided by the calibrated /50 of its target concept;
- **v2's per-criterion floors** are met: no §8.3 score below 3, geography ≥ 4, character ≥ 4, no hard-gate flags.

Milestones for the mean parity: **≥ 85 % at the end of 5A's wrap**, **≥ 100 % by the end of 5B**. v2's 40/50 stays the long-term goal. Every summary and scoreboard row shows parity first.

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
| Capture | [capture.sh](../../Tools/lookloop/capture.sh) | `raw/<id>.png`, `logs/<id>.log`. WorldLab is launched once per view in the Simulator **LookLoop iPhone 17 Pro**, which is created on first use and is nobody else's device. Launch args come from [views.json](../../Tools/lookloop/views.json) plus `-renderer realitykit -hud off -frame16x9 -rendertrace`. The tool waits for WorldLab's `STATS` line (world built), then waits `SETTLE` seconds (default 3) and takes a screenshot. Frames at 2 s and 8 s differ by less than 0.1/255. The status bar and appearance are fixed. |
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

| Run | Capture + analysis | Grading | Total |
|---|---|---|---|
| 6 Oct 01:02: first run, 17 views, 8 s settle, machine at load 400–660 | 13.9 min | 2.4 min (Opus) | 16.9 min |
| 6 Oct 06:39: 17 views, 3 s settle, one kept-booted Simulator, install only on change | 6.8 min | about 1 min (17 Sonnet reviewers in parallel, slowest 41 s) | **about 8 min** of work. The row says 9.6 because I held the reviewers while calibration finished |

- **Per view:** about 2 s launch, 11.5–15 s world build (rose after P2's buildings), 3 s settle, 1 s screenshot.
- **Build:** the WorldLab build is incremental, about 5 s when nothing changed.
- **Routine runs** after a docs-only or unrelated merge capture nothing: the plan reuses every view.
- **Biggest remaining cost:** one world build per view. A WorldLab hook that switches views without relaunching would cut a full run to about 3 minutes (see hooks).

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

## Hooks needed from other sessions

| From | Hook | Why |
|---|---|---|
| WorldLab owner (5A) | `-area <id>` plus `-camera lat,lon,heightM,headingDeg,pitchDeg,fovDeg` and `-overview lat,lon,dist,pitch,yaw,fov` launch args, matching BuildingLab's `-area`/`-look`/`-overview`, with the Evanston South and Lakeview areas bundled | Activates the eight Evanston/Lakeview views (P2 cameras already in views.json). The 2-hourly watch activates them when this lands |
| WorldLab owner (5A) | A sequence mode, for example `-showcase 01,02,…` that steps through states in one launch and prints `READY <id>` when each has settled | Removes 16 of 17 world builds: a full run in about 3 min |
| WorldLab owner (5A) | Print `viewTriangles` and draw calls once settled (`VIEWSTATS` line) | Whole-world triangles are now 460k; v2's 400k ceiling is per view |
| WorldLab / engine (5A) | GPU frame time from the default RealityView host in the `RENDER` line | Simulator frame time is vsync-capped |
| WorldLab owner (5A) | `-capture <path>`: write the rendered frame (16:9) to Documents once settled | Device mode. `devicectl` cannot take screenshots; with this, the loop can capture on the iPhone (when 5A is not using it) and pull frames with `devicectl device copy from` |
| P2 | Wilmette or Evanston and Lakeview area data on main | Done: `evanston-south` and `lakeview-sheil-park` are on main |

