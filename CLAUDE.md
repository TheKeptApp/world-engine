# WorldEngine: working rules

- Work only inside this repo. Do not read, modify or reference any other repo (DogWell, Toshi, Stretchy or others).
- No personal locations or personal data in the repo. Fetch OSM data with `out body`, not `out meta`, so contributor usernames and IDs stay out of the repo.
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
