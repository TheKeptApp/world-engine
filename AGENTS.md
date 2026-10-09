# AGENTS.md: working rules for GPT agents in this repo

**`CLAUDE.md` is the source of truth.** This file mirrors every binding rule in it for agents that read AGENTS.md instead (Astra, a GPT coding agent), plus a few Astra-only notes at the end. If the two disagree, `CLAUDE.md` wins: follow it and tell P3. **Any rule change updates both files in the same commit** (R, 8 Oct 2026).

Read at the start of every session: `CLAUDE.md`, `docs/roadmap.md`, `docs/decisions/owner-log.md` (R's decisions, newest first), `docs/proposals/INDEX.md` (which pack is approved for which feature) and `docs/pack-usage.md` (which lane uses which pack, and when; A3 may move it under `docs/tracking/`).

## What this is

WorldEngine is a true-scale, stylized real-world 3D engine: an iPhone app (RealityKit and Swift) plus a web viewer (three.js and WebGL2). The look is rich Style B, leaning real, never cartoony. The owner is R, a non-technical founder who does not use Terminal.

- `~/Desktop/world-engine/` is the project repo (code and docs). Work in your own branch or worktree.
- `~/Desktop/worldengine-gpt-drop/` holds ChatGPT's design and research packs: read-only source for filing (Astra's lane A3 files them into `docs/proposals/` and `docs/research-gpt/`).
- Approved design targets: `docs/proposals/INDEX.md`, each pack's `STATUS.md`, and the compiled `Resources/look/mock-values.json`.

## Lanes and ownership

| Lane | Owns |
|---|---|
| **P0 (5A)** | Light, weather, sky and the renderer: `Sources/WorldEngine/`, `Sources/WorldEnvironment/`, `Sources/LiveSky/`, the look data (`Sources/WorldGen/Profiles/look.json`, `Look.swift`), shaders. **Water (the water code, the water shader and the water values wiring) is 5A's alone, Opus only; Astra may build water only inside his own `web/bakeoff/` folder.** |
| **P1** | Data and back end: `Tools/regionkit/`, `Tools/livefeeds/`, `Data/`, `Sources/WorldMap/`, `Sources/WorldPackage/`, `Sources/worldbake/`, `Sources/WorldGeo/`, `docs/research/`, `docs/data-sources/`, `docs/data-licensing.md`. |
| **P2** | Buildings, yards and vegetation: the generators in `Sources/WorldGen/`, `Sources/buildingviz/`, `docs/buildings/`. |
| **P3** | Paused (R, 8 Oct 2026); look capture, scoring and reporting pass to A3 (R, 8 Oct 2026). Filing (ChatGPT's packs, the trackers, `docs/proposals/INDEX.md`, `docs/design-registry.md`, `docs/pack-usage.md`, `docs/decisions/owner-log.md`, `docs/roadmap.md`, the handoff log) passes to Astra's lane A3 (R, 8 Oct 2026, to save usage). |

If you are not sure which lane owns a file, ask before you edit it (`git log -- <file>` shows who last changed it).

**Astra's lanes (R, 8 Oct 2026; Astra is on trial):**
- **A1 (Astra): data and back end**, the P1 area above (OSM and Overture, lidar heights and roofs, assessor data, terrain and DEM, licences, QA). Astra may commit and merge to main there under the rules below.
- **A2 (Astra): the web look bake-off**, in `web/bakeoff/` only (three.js); water is allowed only inside that folder, never in the iOS water code or shader.
- **A3 (Astra): the only filing lane, including trackers, plus look capture/scoring/reporting**, no engine code: ChatGPT's packs, the trackers, INDEX, the registry, pack usage, the roadmap, the owner log and the handoff log (`docs/tracking/handoffs.md`). A3 took filing over from P3 on 8 Oct 2026 to save usage; P3 is paused and does not file packs.
- Astra may **not** edit render or look code (the 5A and P2 areas) without a logged handoff: write the file, the change and the reason to `docs/tracking/handoffs.md` (A3 keeps it) and wait for the owner of that area to agree; then edit exactly those files.
- **Water: 5A owns it, Opus only. Astra never edits the iOS water code, the water shader or the water values in the compiled mock values.** Astra may build water only inside his own bake-off folder, `web/bakeoff/` (R, 8 Oct 2026).
- The trial ends or widens only by R's decision.

Other GPT roles are different: ChatGPT design chats write packs to `~/Desktop/worldengine-gpt-drop/` only, never run git, and A3 files what they deliver. This replaces the older line that no GPT agent may run git, for Astra's lanes only.

## Binding rules (mirroring `CLAUDE.md`)

### A3 web scoring and map-only order (R, 8 Oct 2026)

Keep an A3 web baseline separate from iOS, using GRADING.md §M and §N and the frozen A2 views. After each A2 merge, record Sloan's and Lakeview before/after closeness and six aspects; reject-flag Sloan's gains paired with hold-out losses. West Highland and Greenville stay pending capture-ready data/export/cameras; data delivery alone is not a visual pass. File A2 RULES.md in docs/tracking and cross-link it for 5A/P2 restart. Current execution order is map-only: Sloan's gate, hold-outs, Builder Easy + Pro, then jobs game (docs/tracking/roadmap.md). No unattended recurring automation or auto-merges.

### A3 look-scoring takeover (R, 8 Oct 2026)

A3 now owns look capture, scoring and reporting; Claude P3 is paused. Re-score current main as the A3 baseline and explicitly record the grader change from Claude P3; do not interpret cross-grader score movement as engine improvement. Preserve GRADING.md §M closeness and §N noise controls. R’s 9 October ship bar in DECISIONS.md supersedes the older 4/3 gate: overall ≥3/5, no aspect <2, no catastrophic failures and floor budget on the minimum device. Retain historical grades without relabelling them as new passes.

After each look merge from 5A, P2 or A2, A3 scores Sloan's Lake and untouched hold-outs Lakeview, Wilmette, West Highland and Greenville Downtown. Missing captures remain pending, not a waived hold-out. Freeze area/view IDs and conditions before comparisons, without tuning. Log Sloan's score and each hold-out score in the scoreboard and trackers; reject-flag any merge that raises Sloan's while lowering a hold-out. Missing captures/data stay pending and cannot prove a pass. Updates follow R's requests or lane reports; no unattended recurring automation or auto-merges. See docs/lookloop/a3-baseline.md for the baseline and Denver proposal.

### RULE — NO BLOCK-SPECIFIC FIXES (R, 8 Oct)

1. Every look, data and generator change must be a general rule driven by data or region (climate, species, era, material, latitude, season), never a hand-tuned value for one place, one building or one camera. Sloan's Lake is the test, not the product.
2. HOLD-OUT TEST: after every merge that changes look, also render and score the untouched hold-out blocks — Lakeview, Wilmette, West Highland and Greenville Downtown — with NO tuning. Report both: Sloan's Lake score and hold-out score. A merge that raises Sloan's but lowers the hold-outs is rejected.
3. Data pipelines must run unchanged on any area; report hold-out coverage/quality alongside Sloan's.
4. docs/lookloop/mock-exceptions.md stays near empty; every new exception needs R's written approval.

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
- `docs/proposals/` is written by ChatGPT: read-only input. Never edit, move, rename or delete anything in it (A3 files packs there). The visual source of truth is `docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md`.
- `~/Desktop/worldengine-handoff/dog/` may be read (DogWell dog exports); never write there.
- Cite packs: every value, rule or design choice that comes from a pack names the pack and the key (for example `style-b-calibration-v2`, `style-b/water`) in the code or data comment and in your report. No uncited numbers.

**Visual work builds to approved mocks (owner, 2026-10-07)**
- Before any visual change, read `docs/proposals/INDEX.md`, open the matching mock images (absolute path in INDEX.md; they are not in worktrees), and use the pack's values JSON (`Resources/look/mock-values.json` for tools; the engine bundles `Sources/WorldGen/Profiles/mock-values.json`).
- `style-b-calibration-v2` owns the look (lighting, exposure, saturation, matte materials, detail by distance); packs own content. Images beat JSON for look; data owns measurements.
- Never invent a value that a mock's JSON already defines.
- Every pre-merge report includes a phone-size side-by-side (render vs mock), the values used, and the remaining gaps. Score with `Tools/lookloop/region_colours.py` and `compare_runs.py`; a merge must raise mock closeness or say why it does not.
- Report stage changes to A3 (the look loop): whenever a merge changes what is rendered or loaded (frames, mock values, area data, profiles), report the commit to A3 and the views you expect to move, so the look loop scores it.
- No logos, brands, readable signs, murals or public art, dogs or other animals, or host-app content in anything generated. (The host's character reaches the engine as an `Entity`; it is not engine content.) An exception needs R's ruling.

**Data**
- No raw data until it is GREEN. Until a dataset is GREEN for our use (`docs/research-gpt/metro-data-coverage-v1/`, `docs/data-licensing.md`) the engine does not load it; use rule-based generation and label it "inferred". Required credits stay with the data.
- Stale data is never shown as live. Every observed or live value shows its age; bundled, stale or forecast data is never presented as live; missing data never silently becomes live; observed, forecast, history and demo stay separate and labelled.

**Build in silence (R)**
- Nothing is deployed, published, posted, emailed or sent outside this Mac and the repo. No customer or third-party contact and no real customer logos. The only outward step is a merge to main.

## The shared Mac

- **Heavy jobs take turns.** A heavy job is an Xcode or Swift build, a full test suite, a Simulator run or the look loop. Run it as `scripts/heavy.sh "what it is" command args…`: it waits for the load to drop, waits for the lock `~/.agent-heavy-lock`, takes it atomically with an owner file, and releases only its own lock when the job ends. Python, docs, git and data fetches need no lock.
- **Never delete, edit, overwrite or "clean up" another lane's lock or owner file**, even if it looks stuck. `scripts/heavy.sh` reports an abandoned lock (dead PID or no owner file) on stderr as "HEAVY abandoned lock" and carries on without touching it; tell R in one line.
- Priority 5A (P0) > P2 > P3 > P1. One heavy job at a time; at most one booted Simulator per session, shut down when idle.
- **Disk guard:** keep at least 8 GB free (`df -h /`). Under 8 GB, pause heavy work and report to R. Never delete files you did not create to make room. Images stay out of git (gitignored); no file over 50 MB is committed.

## Git, reporting and merging

- Work on a branch or worktree; the tests for your area pass before you merge. Follow the standing conflict rule below.
- Plan before coding. Reports are at most 10 lines plus one evidence link in plain English, say first whether the work is done or blocked, and list everything you touched. No silent workarounds: if something cannot be done, stop and say so.
- Decide what the specs already decide and log it; stop and ask only for decisions that are irreversible, outside the specs, or that change cost or privacy.
- **Merge to main when done.** Small and often, at least daily: fetch, rebase on `origin/main`, run the tests for your area (under the heavy lock), run `Tools/lookloop/commit_size.sh` (20 MB per commit), then push. Never force-push or rewrite pushed history.
- **If main moved while you were merging** (new commits on `origin/main` since you started, or between your fetch and your push), say so in the report, rebase again, re-run what your change touches, and push. Never overwrite another lane's commits.
- Every owner (R) decision you hear goes to A3, who logs it in `docs/decisions/owner-log.md`.

## Astra-only notes

- Last line of every Astra report: `Tracker update: <what changed, status, next>`, so the trackers stay current.
- R's current priorities: (1) the 9 October ship bar in DECISIONS.md, including minimum-device budget and all four named hold-outs; (2) real data for Chicago, Denver and Greenville SC; (3) web as the main surface carrying Builder, with iOS moving alongside it and independently scored. Parked: smoke, Real mode, paid flight data, the "Somewhere" brand filing.

**Standing conflict rule (R, 8 Oct 2026):** Resolve add-only conflicts in `docs/tracking/handoffs.md` by keeping both entries in date order. All other conflicts still stop and must be reported.

## Build report evidence — shared rule (R, 8 Oct 2026)

Every build report must end with an evidence line immediately before `Tracker update:`: `Used: <research doc and section>. Mock: <mock file or frame>. Deviation: <none or reason>.` A build report without this line is incomplete.

## Source-of-truth and routing — shared rule (R, 8 Oct 2026)

The repository is the only source of truth. Read docs/tracking/STATE.md, INDEX.md, INTEGRATION.md, then the relevant feature row and MOCKS.md entry. Follow docs/tracking/SOURCE-OF-TRUTH.md. Pending/unapproved packs are never used. A feature is done only when a renderer file consumes it and INTEGRATION.md records that consumption; visual/performance/rights gates still apply. Builders update the ledger row and input/mock citations in the same implementation commit; rewrite STATE after every report, keeping history in handoffs.

Any lane can be run by any model; model choice changes none of the checks or lane/file ownership. Before a model switch, the lane state note in docs/tracking/handoffs.md must be current. This later instruction supersedes earlier model-specific routing restrictions, including render/water model requirements; native water remains 5A-owned and A2 remains web/bakeoff-only.

Every build report must end with `Used: <doc §>. Mock: <file/frame>. Deviation: <none or why>` immediately before `Tracker update:`. Without that evidence line it is incomplete.

## Decisions and complete feature references — shared rule (R, 9 Oct 2026)

Before any task, read `docs/tracking/DECISIONS.md` first. Its dated owner decisions supersede conflicting older instructions, including the historical look-gate threshold and report length. Read the [REFERENCE-MAP.md](docs/tracking/REFERENCE-MAP.md) rows for every feature your task touches. Compare your renders against their listed visible traits, respecting street/aerial scope. Then open `docs/tracking/INDEX.md` and `docs/tracking/MOCKS.md` (the repository’s MOCKS.md registry). Find and read every research document and visual mock for every feature the task touches, following the feature index, execution briefs, proposal status and registry links; do not restrict references to calibration-v2 `06-sloans` and `01-lakeview`. Preserve approval scopes: a listed reference is not permission to use a pending pack. Missing references must be reported as gaps/deviations, never guessed or silently replaced by a pending pack.

List every actual research document/section and mock file/frame read in the report evidence line: `Used: <research docs/sections> / Mock: <mock files/frames> / Deviation: <none or reason>`. Place it before `Tracker update:`. A report that lists no research document or mock for the feature is incomplete. For documentation-only policy work with no visual feature, cite the policy sources and mock registry and state that scope explicitly; do not claim an image was inspected. Reports are at most 10 lines plus one evidence link. Apply the current ship bar and comparison gate in DECISIONS.md; historical scores are not reclassified automatically. The linked evidence can contain the complete source/mock list. Web evidence never substitutes for native evidence. Follow the four-heavy-agent cap and scoreboard requirement in DECISIONS.md.
