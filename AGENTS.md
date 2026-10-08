# AGENTS.md: working rules for GPT agents in this repo

**`CLAUDE.md` is the source of truth.** This file mirrors every binding rule in it for agents that read AGENTS.md instead (Astra, a GPT coding agent), plus a few Astra-only notes at the end. If the two disagree, `CLAUDE.md` wins: follow it and tell P3. **Any rule change updates both files in the same commit** (R, 8 Oct 2026).

Read at the start of every session: `CLAUDE.md`, `docs/roadmap.md`, `docs/decisions/owner-log.md` (R's decisions, newest first), `docs/proposals/INDEX.md` (which pack is approved for which feature) and `docs/pack-usage.md` (which lane uses which pack, and when).

## What this is

WorldEngine is a true-scale, stylized real-world 3D engine: an iPhone app (RealityKit and Swift) plus a web viewer (three.js and WebGL2). The look is rich Style B, leaning real, never cartoony. The owner is R, a non-technical founder who does not use Terminal.

- `~/Desktop/world-engine/` is the project repo (code and docs). Work in your own branch or worktree.
- `~/Desktop/worldengine-gpt-drop/` holds ChatGPT's design and research packs: read-only source for filing (P3 files them into `docs/proposals/` and `docs/research-gpt/`).
- Approved design targets: `docs/proposals/INDEX.md`, each pack's `STATUS.md`, and the compiled `Resources/look/mock-values.json`.

## Lanes and ownership

| Lane | Owns |
|---|---|
| **P0 (5A)** | Light, weather, sky and the renderer: `Sources/WorldEngine/`, `Sources/WorldEnvironment/`, `Sources/LiveSky/`, the look data (`Sources/WorldGen/Profiles/look.json`, `Look.swift`), shaders. **Water (the water code, the water shader and the water values wiring) is 5A's alone, Opus only.** |
| **P1** | Data and back end: `Tools/regionkit/`, `Tools/livefeeds/`, `Data/`, `Sources/WorldMap/`, `Sources/WorldPackage/`, `Sources/worldbake/`, `Sources/WorldGeo/`, `docs/research/`, `docs/data-sources/`, `docs/data-licensing.md`. |
| **P2** | Buildings, yards and vegetation: the generators in `Sources/WorldGen/`, `Sources/buildingviz/`, `docs/buildings/`. |
| **P3** | The look loop and the paperwork: `Tools/lookloop/`, `docs/lookloop/`, `docs/proposals/INDEX.md`, `docs/design-registry.md`, `docs/pack-usage.md`, `docs/decisions/owner-log.md`, `docs/roadmap.md`. P3 files ChatGPT's packs and logs every handoff. |

If you are not sure which lane owns a file, ask P3 before you edit it (`git log -- <file>` shows who last changed it).

**Astra is P1 (data and back end) only, during the trial (R, 8 Oct 2026).**
- Astra works in the P1 area above (the data work: OSM and Overture, lidar heights and roofs, assessor data, terrain and DEM, licences, QA) and may commit and merge to main there under the rules below.
- Astra may **not** edit render or look code (the 5A and P2 areas) without a handoff logged by P3: message P3 with the file, the change and the reason; P3 writes the handoff in `docs/decisions/owner-log.md` (date, files, who); only then edit exactly those files.
- **Astra must never edit water code or the water shader. 5A owns water, Opus only (R, 8 Oct 2026).** There is no handoff for this: do not edit, reformat, move or delete any file or part of a file whose job is water, lakes, shore reflection, waves or ice, and do not change the water values in the compiled mock values.
- The trial ends or widens only by R's decision, logged by P3.
- Astra's own installed instructions (commit `5e50686`, branch `astra-a3-filing-trackers`, 7 Oct 21:36) also name lanes A2 (a web look bake-off in `web/bakeoff/` only) and A3 (filing packs, trackers, roadmap, owner log, handoff log). R's 8 Oct block to P3 limits Astra to P1 during the trial and has P3 file packs; **R confirms any other lane for Astra before Astra works in it.**

Other GPT roles are different: ChatGPT design chats write packs to `~/Desktop/worldengine-gpt-drop/` only, never run git, and P3 files what they deliver. This replaces the older line that no GPT agent may run git, for Astra's P1 lane only.

## Binding rules (mirroring `CLAUDE.md`)

**Scope and privacy**
- Work only inside this repo. Do not read, modify or reference any other repo (DogWell, Toshi, Stretchy or others).
- No personal locations or personal data in the repo (names and emails of individuals included; role mailboxes of agencies are fine). Fetch OSM data with `out body`, not `out meta`, so contributor usernames and IDs stay out of the repo. Aggregate only; a user's home location stays on the device.
- Never print, log, paste or commit keys, tokens, passwords or credentials. The signing team ID lives in `.local/team_id` (git-ignored), never in `project.yml`.
- "© OpenStreetMap contributors" must stay visible whenever the world is on screen.
- Ask R before installing anything on his phone.

**The engine**
- The engine stays generic. It assumes nothing about host apps, owns no app logic, user data or surrounding UI, and receives characters as plain RealityKit `Entity` values.
- Nothing place-specific in engine or generator code; areas are data. Regional looks live in data (`Sources/WorldGen/Profiles/*.json`, selected by location via `regions.json`). Real OSM tags always override profiles.
- All generated detail is seeded via `OSMRef.random(salt)` / `StableRandom`. Never `Hasher`, `random()` or `SystemRandomNumberGenerator`.
- Minimum iOS 26.0. Report anything that works worse on 26 than on 18.
- Xcode projects are generated (XcodeGen). Never hand-edit or commit `.xcodeproj`.
- Current plan: `docs/plan-m1.md`. Binding visual requirements: `docs/VISUAL_DIRECTION.md`.
- Report before any design decision not covered by the plan goes into code.

**The owner and the tools**
- The owner does not use Terminal. Run commands yourself. When a manual step is unavoidable, give click-by-click instructions.
- Commands: `scripts/test.sh`, `scripts/generate.sh`, `scripts/snapshots.sh <out.png> -preset NAME`, `scripts/device.sh build`, `scripts/walk_test.sh LABEL`, `swift run worldbake …`.

**Proposals and packs**
- `docs/proposals/` is written by ChatGPT: read-only input. Never edit, move, rename or delete anything in it (P3 files packs there). The visual source of truth is `docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md`.
- `~/Desktop/worldengine-handoff/dog/` may be read (DogWell dog exports); never write there.
- Cite packs: every value, rule or design choice that comes from a pack names the pack and the key (for example `style-b-calibration-v2`, `style-b/water`) in the code or data comment and in your report. No uncited numbers.

**Visual work builds to approved mocks (owner, 2026-10-07)**
- Before any visual change, read `docs/proposals/INDEX.md`, open the matching mock images (absolute path in INDEX.md; they are not in worktrees), and use the pack's values JSON (`Resources/look/mock-values.json` for tools; the engine bundles `Sources/WorldGen/Profiles/mock-values.json`).
- `style-b-calibration-v2` owns the look (lighting, exposure, saturation, matte materials, detail by distance); packs own content. Images beat JSON for look; data owns measurements.
- Never invent a value that a mock's JSON already defines.
- Every pre-merge report includes a phone-size side-by-side (render vs mock), the values used, and the remaining gaps. Score with `Tools/lookloop/region_colours.py` and `compare_runs.py`; a merge must raise mock closeness or say why it does not.
- Report stage changes to P3: whenever a merge changes what is rendered or loaded (frames, mock values, area data, profiles), message P3 with the commit and the views you expect to move, so the look loop scores it.
- No logos, brands, readable signs, murals or public art, dogs or other animals, or host-app content in anything generated. (The host's character reaches the engine as an `Entity`; it is not engine content.) An exception needs R's ruling.

**Data**
- No raw data until it is GREEN. Until a dataset is GREEN for our use (`docs/research-gpt/metro-data-coverage-v1/`, `docs/data-licensing.md`) the engine does not load it; use rule-based generation and label it "inferred". Required credits stay with the data.
- Stale data is never shown as live. Every observed or live value shows its age; bundled, stale or forecast data is never presented as live; missing data never silently becomes live; observed, forecast, history and demo stay separate and labelled.

**Build in silence (R)**
- Nothing is deployed, published, posted, emailed or sent outside this Mac and the repo. No customer or third-party contact and no real customer logos. The only outward step is a merge to main.

## The shared Mac

- **Heavy jobs take turns.** A heavy job is an Xcode or Swift build, a full test suite, a Simulator run or the look loop. Run it as `scripts/heavy.sh "what it is" command args…`: it waits for the load to drop, waits for the lock `~/.agent-heavy-lock`, takes it atomically with an owner file, and releases only its own lock when the job ends. Python, docs, git and data fetches need no lock.
- **Never delete, edit, overwrite or "clean up" another lane's lock or owner file**, even if it looks stuck. `scripts/heavy.sh` reports an abandoned lock (dead PID or no owner file) on stderr as "HEAVY abandoned lock" and carries on without touching it; tell P3 in one line.
- Priority 5A (P0) > P2 > P3 > P1. One heavy job at a time; at most one booted Simulator per session, shut down when idle.
- **Disk guard:** keep at least 8 GB free (`df -h /`). Under 8 GB, pause heavy work and report to P3 and R. Never delete files you did not create to make room. Images stay out of git (gitignored); no file over 50 MB is committed.

## Git, reporting and merging

- Work on a branch or worktree; the tests for your area pass before you merge. **Stop on any merge conflict** and report it.
- Plan before coding. Reports are at most 15 lines in plain English (a one-table report is fine), say first whether the work is done or blocked, and list everything you touched. No silent workarounds: if something cannot be done, stop and say so.
- Decide what the specs already decide and log it; stop and ask only for decisions that are irreversible, outside the specs, or that change cost or privacy.
- **Merge to main when done.** Small and often, at least daily: fetch, rebase on `origin/main`, run the tests for your area (under the heavy lock), run `Tools/lookloop/commit_size.sh` (20 MB per commit), then push. Never force-push or rewrite pushed history.
- **If main moved while you were merging** (new commits on `origin/main` since you started, or between your fetch and your push), say so in the report, rebase again, re-run what your change touches, and push. Never overwrite another lane's commits.
- Every owner (R) decision you hear goes to P3, who logs it in `docs/decisions/owner-log.md`.

## Astra-only notes

- Last line of every Astra report: `Tracker update: <what changed, status, next>`, so the trackers stay current.
- R's current priorities: (1) the look gate: all four afternoon heroes at closeness 4 or more and every aspect 3 or more (Lakeview, Sloan's Lake and the other heroes); (2) real data for the test cities Chicago (Lakeview), Denver (Sloan's Lake) and Greenville SC; (3) a web viewer (three.js) that proves the look is reachable in a browser. Parked: smoke, Real mode, paid flight data, the "Somewhere" brand filing.
