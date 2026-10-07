---
name: lookloop
description: Run WorldEngine's look loop, the official visual gate. It captures the fixed views in the Simulator, draws contact sheets against the concept targets, grades every changed view with reviewer sub-agents against the v2 §8.3 rubric, flags regressions and appends a scoreboard row. Use after any change that affects visuals, before merging visual work, or when asked for /lookloop, a look check or a gate run. Pass "gate" for a declared gate run (every view, Opus reviewers).
---

# /lookloop

The look loop is the official visual gate for every session. A view passes at concept parity ≥ 100 % (its v2 /50 ÷ its target concept's calibrated /50) with v2's per-criterion floors met; 40/50 is the long-term goal. Details: `docs/lookloop/README.md`. Rubric procedure: `docs/lookloop/GRADING.md`.

**Arguments**
- none: routine run. Only views whose inputs changed are re-rendered and re-graded, by Sonnet reviewers.
- `gate`: declared gate run. Every view is re-rendered and graded by Opus reviewers.
- view ids (for example `v2-01 showcase-03`): only those views.

## Steps

1. From the checkout you want judged (your worktree or main), run:
   - routine: `Tools/lookloop/lookloop.sh run [view ids]`
   - gate: `Tools/lookloop/lookloop.sh run --gate`

   It builds WorldLab incrementally, captures in the single `LookLoop iPhone 17 Pro` Simulator, which stays booted (never boot a second simulator), and draws the sheets. Run it in the background and wait for it to exit; a full gate run captures for about 5–7 minutes.

2. What happens next depends on the exit code:
   - **0**: nothing changed, or every view was reused. Report that; there is no new row.
   - **3**: reviewers are needed. Continue with step 3.
   - **anything else**: stop and report the error. Do not work around it.

3. Open `<run>/reviewers.md`. Spawn **one sub-agent per listed line, all in a single message so they run in parallel**:
   - agent type: general-purpose
   - model: the one named at the top of the file (`sonnet` for routine runs, `opus` for gate runs)
   - prompt: that line's text, verbatim

   Each reviewer writes `<run>/grades/<id>.json`. A session can run at most 20 sub-agents at once: with more lines, spawn the first 20, then the rest as earlier ones finish. Wait for all of them.

4. Run `Tools/lookloop/lookloop.sh finish <run>`. It does three things:
   - checks and totals the grades;
   - writes `docs/lookloop/latest/` (frames, sheets, `summary.md`, `regressions.md`);
   - appends a dated row to `docs/lookloop/scoreboard.md`.

5. Report back, **concept parity first**:
   - the mean parity and gate passes against the milestones: ≥ 85 % at the end of 5A's wrap; by the end of 5B, ≥ 100 % plus every art-direction score ≥ 3 (the "5B" column);
   - heavy lock: priority 5A > P2 > P3 > P1; hold it only for capture and release before grading;
   - full Opus `--gate` only when a routine (Sonnet) loop reaches mean parity ≥ 92 % (85 % + offset; under §S Sonnet runs 7.0 points above Opus; milestones are read from Opus gate rows);
   - the new scoreboard row;
   - every line of `docs/lookloop/latest/regressions.md`, meaning any view down 2 or more on /50 or any criterion down 1 or more against the previous run;
   - the top fixes from `summary.md`.

   Commit `docs/lookloop/` together with the change you were judging.

## Rules

- **Per-merge scoring (owner, 7 Oct 2026):** run `Tools/lookloop/lookloop.sh run --core` (13 core views, Sonnet) for each merge and compare with the core views of the previous run; run the full set only for gate checks. Judge changes against GRADING.md §N (noise rule, proposed).
- **ChatGPT drop folder (owner, 6 Oct 2026):** ChatGPT saves to `~/Desktop/worldengine-gpt-drop/<pack>/`, outside the repo. On every watch tick run `Tools/lookloop/ingest_drop.py`; when it lists new files, run it with `--apply`, then commit the text files, run `Tools/lookloop/backup_design_images.sh` and log the pack in `docs/design-registry.md` (design packs under Packs, research under Research). Never delete or change anything in the drop folder; a CONFLICT line (same path, different content) is reported to the owner, never overwritten. ChatGPT research is spot-checked against official sources before use.
- Never edit `docs/proposals/` or the grades by hand. If a grade looks wrong, re-run that reviewer and say so.
- Reviewers never change scores to match expectations. If calibration looks off, follow `docs/lookloop/calibration.md`.
- If capture fails (the Simulator is stuck, or there is no `STATS` line), report it with the log path. Never substitute old frames silently; the plan reuses only frames whose inputs are byte-for-byte unchanged.
