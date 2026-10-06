# P3 look loop: handoff (6 Oct 2026)

## Done (on main 6a4b5f6, plus this handoff)

- `/lookloop` skill is the official visual gate.
  - The gate is concept parity ≥ 100 % plus v2's per-criterion floors.
  - The end-of-5B gate adds every art-direction score ≥ 3.
  - Milestones for mean parity: 85 % at the end of 5A's wrap, 100 % by the end of 5B.
- Batched capture through WorldLab's `-viewlist`:
  - one launch per area and date;
  - frames are in-app captures;
  - unchanged views are reused;
  - a regression guard compares each run with the previous one;
  - look-fix-v1 checks are in GRADING.md §H, and its reference images are on matching views;
  - calibration against the concept images is done.
- Last gate run (6 Oct 09:16, engine 78e7541, 32 views): parity **77 %**, gate 0/32, region buildings & ground 2.3 (P2 target 3.5).

## In progress / waiting

- **5A** will send a main commit with the look-fix pass (weather, light, fog/smoke, sky, Chicagoland phenology). Run it as a **declared gate**: it is 5A's wrap checkpoint against the 85 % milestone.
- **P2** will send two commits:
  - yards and ground;
  - road width.
  - After each, rerun the region views (routine, Sonnet).
  - After both, plus 5A's lawn shader, do an Opus gate read of the region views for P2.
- The 2-hourly watch (cron) is cancelled because of the usage limit. Recreate it on resume.

## Exact next step

1. `git fetch`, then rebase the `p3-lookloop` worktree on `origin/main`.
2. Take `~/.agent-heavy-lock` (atomic `mkdir`, owner lines as `key=value`).
3. Run `Tools/lookloop/lookloop.sh run --gate`.
4. Spawn the Opus reviewers from `<run>/reviewers.md`, at most 20 at once.
5. Run `lookloop.sh finish <run>`.
6. Merge to main from a detached `origin/main` and push.
7. Report parity first, then per-lane fixes, to 5A and P2.
8. Shut the simulator down.

## Waiting on the owner

Nothing.
