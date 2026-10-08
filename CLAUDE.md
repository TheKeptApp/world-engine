# WorldEngine: working rules

- Work only inside this repo. Do not read, modify or reference any other repo (DogWell, Toshi, Stretchy or others).
- No personal locations or personal data in the repo (names and emails of individuals included; role mailboxes of agencies are fine). Fetch OSM data with `out body`, not `out meta`, so contributor usernames and IDs stay out of the repo. Aggregate only; a user's home location stays on the device.
- The engine stays generic. It assumes nothing about host apps, owns no app logic, user data or surrounding UI, and receives characters as plain RealityKit `Entity` values.
- The owner does not use Terminal. Run commands yourself. When a manual step is unavoidable, give click-by-click instructions.
- Xcode projects are generated (XcodeGen). Never hand-edit or commit `.xcodeproj`.
- "© OpenStreetMap contributors" must stay visible whenever the world is on screen.
- Current plan: `docs/plan-m1.md`.
- Binding visual requirements: `docs/VISUAL_DIRECTION.md`. Nothing place-specific in engine or generator code; areas are data.
- All generated detail is seeded via `OSMRef.random(salt)` / `StableRandom`. Never `Hasher`, `random()` or `SystemRandomNumberGenerator`.
- Minimum iOS 26.0 (approved in Prompt 3 for GPU instancing and RealityView post-processing). Report anything that works worse on 26 than on 18.
- Report before any design decision not covered by the plan goes into code.
- Regional looks live in data (`Sources/WorldGen/Profiles/*.json`, selected by location via `regions.json`). Real OSM tags always override profiles.
- Commands: `scripts/test.sh`, `scripts/generate.sh`, `scripts/snapshots.sh <out.png> -preset NAME`, `scripts/device.sh build`, `scripts/walk_test.sh LABEL`, `swift run worldbake …`.
- Signing: the team ID lives in `.local/team_id` (git-ignored), never in `project.yml`.
- `docs/proposals/` is written by ChatGPT: read-only input. Never edit it. The visual source of truth is `docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md` (VISUAL_DIRECTION.md is kept consistent with it).
- `~/Desktop/worldengine-handoff/dog/` may be read (DogWell dog exports); never write there.
- `AGENTS.md` mirrors every rule in this file for Astra (a GPT coding agent, on trial in lanes A1 to A3), who reads AGENTS.md instead. **Any rule change here updates `AGENTS.md` in the same commit, and the other way round** (R, 8 Oct 2026). If the two disagree, this file wins.

## Visual work builds to approved mocks

Approved GPT mocks are the exact visual direction (owner, 2026-10-07). All lanes read this at session start.

- Before any visual change, read `docs/proposals/INDEX.md`, open the matching mock images (absolute path in INDEX.md; they are not in worktrees), and use the pack's values JSON.
- Every pre-merge report includes a phone-size side-by-side (render vs mock), the values used, and the remaining gaps. A merge must raise mock closeness or say why it does not (`Tools/lookloop/region_colours.py`, `compare_runs.py`).
- Never invent a value that a mock's JSON already defines.

## Lanes and ownership (mirrored in AGENTS.md)

- **P0 (5A):** light, weather, sky and the renderer (`Sources/WorldEngine/`, `Sources/WorldEnvironment/`, `Sources/LiveSky/`, the look data in `Sources/WorldGen/Profiles/look.json` and `Look.swift`, shaders). **Water (code, shader and values wiring) is 5A's alone, Opus only; Astra may build water only inside his own `web/bakeoff/` folder.**
- **P1:** data and back end (`Tools/regionkit/`, `Tools/livefeeds/`, `Data/`, `Sources/WorldMap/`, `Sources/WorldPackage/`, `Sources/worldbake/`, `Sources/WorldGeo/`, `docs/research/`, `docs/data-sources/`, `docs/data-licensing.md`).
- **P2:** buildings, yards and vegetation (the generators in `Sources/WorldGen/`, `Sources/buildingviz/`, `docs/buildings/`).
- **P3:** paused (R, 8 Oct 2026); retains ownership of the look loop (`Tools/lookloop/`, `docs/lookloop/`). Filing (ChatGPT's packs, the trackers, `docs/proposals/INDEX.md`, `docs/design-registry.md`, `docs/pack-usage.md`, `docs/decisions/owner-log.md`, `docs/roadmap.md`, the handoff log) passes to Astra's lane A3 (R, 8 Oct 2026, to save usage).
- **Astra (GPT coding agent) is on trial with lanes A1 (data and back end: the P1 area), A2 (the web look bake-off, `web/bakeoff/` only; water allowed only there) and A3 (the only filing lane, including trackers, docs only; handoff log `docs/tracking/handoffs.md`; P3 is paused and does not file packs)** (R, 8 Oct 2026). Astra may not edit render or look code (the 5A and P2 areas) without a logged handoff, and **never edits the iOS water code or the water shader** (water only inside his own bake-off folder).
- If unsure which lane owns a file, ask P3 before editing it.

## Shared Mac, data and reporting rules (mirrored in AGENTS.md)

### RULE — NO BLOCK-SPECIFIC FIXES (R, 8 Oct)

1. Every look, data and generator change must be a general rule driven by data or region (climate, species, era, material, latitude, season), never a hand-tuned value for one place, one building or one camera. Sloan's Lake is the test, not the product.
2. HOLD-OUT TEST: after every merge that changes look, also render and score the untouched hold-out blocks — Lakeview (Chicago), one other Denver neighbourhood (not Sloan's Lake), Greenville Downtown — with NO tuning. Report both: Sloan's Lake score and hold-out score. A merge that raises Sloan's but lowers the hold-outs is rejected.
3. Data pipelines must run unchanged on any area; report hold-out coverage/quality alongside Sloan's.
4. docs/lookloop/mock-exceptions.md stays near empty; every new exception needs R's written approval.

- **Heavy jobs take turns** (Xcode/Swift builds, full test suites, Simulator runs, the look loop): run them as `scripts/heavy.sh "what it is" command…`. **Never delete, edit or "clean up" another lane's lock** (`~/.agent-heavy-lock`) or its owner file, even if it looks stuck; report an abandoned lock to R. Priority 5A > P2 > P3 > P1; one heavy job at a time; at most one booted Simulator per session.
- **Disk guard:** keep at least 8 GB free; under 8 GB, pause heavy work and report to R. Never delete files you did not create to make room. Images stay out of git; no file over 50 MB is committed.
- Never print, log or commit keys, tokens or credentials.
- **No raw data until it is GREEN** for our use (`docs/research-gpt/metro-data-coverage-v1/`, `docs/data-licensing.md`): use rule-based generation labelled "inferred". **Stale data is never shown as live**; every live or observed value shows its age, and missing data never silently becomes live.
- No logos, brands, readable signs, murals or public art, dogs or other animals, or host-app content in anything generated (an exception needs R's ruling).
- **Build in silence:** nothing is deployed, published, posted, emailed or sent outside this Mac and the repo, and there is no customer or third-party contact; the only outward step is a merge to main.
- **Cite packs:** every value or rule taken from a pack names the pack and key. **Report stage changes to P3** (any merge that changes what is rendered or loaded) so the look loop scores it.
- Ask R before installing anything on his phone. Work on a branch or worktree, pass the tests for your area before merging, and stop and report on any merge conflict.
- Reports are at most 15 lines and list everything touched. **Merge to main when done** (fetch, rebase on `origin/main`, test, `Tools/lookloop/commit_size.sh`, push; never force-push). **If main moved while you were merging, say so** in the report, rebase again and re-run what your change touches.
