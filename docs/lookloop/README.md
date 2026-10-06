# Look loop

Deterministic look captures, side-by-side contact sheets, rubric grading and a dated scoreboard, so any session can check the look quickly and honestly.

## Run it (for every session)

1. `Tools/lookloop/lookloop.sh run` captures all active views in a dedicated headless Simulator, measures them and draws the contact sheets. It also grades them when the `claude` CLI is logged in.
2. If it stops with **GRADING NEEDS THE SESSION**, spawn one sub-agent per line of `<run>/reviewers.md`, all in parallel. Each sub-agent follows [GRADING.md](GRADING.md).
3. Run `Tools/lookloop/lookloop.sh finish <run>`. It merges the grades, refreshes [latest/](latest/summary.md) and appends a row to [scoreboard.md](scoreboard.md). Commit `docs/lookloop/` with your merge.

Options:
- `SKIP_BUILD=1` reuses the last WorldLab build.
- `lookloop.sh run v2-01 showcase-03` captures only those views. It is good for a quick check, but don't publish partial runs over a full one: use `finish <run> --no-publish`.

## What it does

| Step | Tool | Output |
|---|---|---|
| Capture | [capture.sh](../../Tools/lookloop/capture.sh) | `raw/<id>.png`, `logs/<id>.log`. WorldLab is launched once per view in the Simulator **LookLoop iPhone 17 Pro**, which is created on first use and is nobody else's device. Launch args come from [views.json](../../Tools/lookloop/views.json) plus `-renderer realitykit -hud off -frame16x9 -rendertrace`. The tool waits for WorldLab's `STATS` line (world built), then waits `SETTLE` seconds (default 8) and takes a screenshot. The status bar and appearance are fixed. |
| Signals and sheets | [analyze.py](../../Tools/lookloop/analyze.py) | `frames/<id>.jpg` (16:9 frame at phone width 1206 px), `sheets/<id>.jpg` (target \| current \| previous plus luma histogram and numbers), `overview.jpg`, `signals.json` |
| Grading | [grade.py](../../Tools/lookloop/grade.py), or session sub-agents | `grades/<id>.json` per [GRADING.md](GRADING.md): v2 §8.3 scores, art-direction scores, total, gate, top 3 fixes |
| Finish | [finish.py](../../Tools/lookloop/finish.py) | `grades.json`, `summary.md`, publish to `docs/lookloop/latest/`, one row in `scoreboard.md` |

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

The first full run (6 Oct 2026, 17 views) took **16.9 min** while the Mac was saturated by six booted Simulators (load average 400–660):

| Step | Time |
|---|---|
| WorldLab build | 4 min, the first time in a fresh worktree only (pinned XcodeGen); `SKIP_BUILD=1` afterwards |
| Capture | 13.4 min. Each world builds in about 11.5 s, but `simctl launch` stalled for 20–100 s per view under the load |
| Analysis | 30 s |
| Grading | 17 Opus reviewers in parallel, 2.4 min (slowest 80 s) |
| Finish | a few seconds |

On a quiet machine, capture is about 25 s per view (about 7 min for 17 views), so a full run comes to about 10 min. Captures run one at a time on purpose: one Simulator, one app.

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

## Hooks needed from other sessions

| From | Hook | Why |
|---|---|---|
| WorldLab owner (5A) | `-area <id>` and `-camera lat,lon,heading,pitch,fov` (or a named regions camera) launch args, plus bundling of more than one area | Activates the Wilmette and Lakeview placeholders without the loop touching WorldLab |
| WorldLab owner (5A) | Print `viewTriangles` and draw calls once the view has settled (for example a `VIEWSTATS` line about 2 s after `STATS`) | `STATS` gives whole-world triangles; v2's 400k ceiling is per view |
| WorldLab / engine (5A) | GPU frame time from the default RealityView host in the `RENDER` line (today only the experimental `-host renderer` reports it) | Per-view GPU cost; Simulator frame time is vsync-capped |
| WorldLab / engine (5A) | A fixed-clock option (for example `-freezetime`: wind phase, cloud drift and particles at t = fixed) | Rain and snow particles, wind sway and cloud drift differ slightly run to run. The other pixels are stable. See the noise check in the gate report |
| P2 | Wilmette and Lakeview area data merged to main, with the regions fixture cameras' coordinates inside the area | Placeholder targets |
