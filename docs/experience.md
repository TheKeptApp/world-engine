# No-character experience (experience-v1)

Spec (read-only input): [experience-v1](proposals/experience-v1/WorldEngine-Experience-Spec-v1.md). The world is the experience; a character is optional.

## Shared, renderer-neutral (WorldGen)
| Piece | File | What it does |
|---|---|---|
| Postcard composer | `Sources/WorldGen/Experience/PostcardComposer.swift` | §4 heuristic: candidates every ~10 m on public paths and park edges (never in water, buildings or private ways; ≤ 256, spread out), 24 headings, eye 1.65 m, 50° FOV, ≤ 32 coarse rays per pose against building hulls, tree crowns/trunks and a 4 m ground grid (water, green, road, building). Scores open depth, geographic interest, composition (water 15–40%, sky 25–45%, layered depth, no near trunk in the centre third), light fit (real sun at golden hour, noon and mid-morning), weather fit and coverage, weighted 0.25/0.20/0.20/0.15/0.10/0.10. The best 12 locations are refined with denser rays and ±7.5° headings. Deterministic; ~0.5 s for Sloan's Lake. |
| Ray world | `Sources/WorldGen/Experience/RayWorld.swift` | The CPU scene used by the composer; `WalkMap` reuses it for free-exploring collision (buildings, water, data edge). |
| Experience defaults | `Sources/WorldGen/Experience/ExperienceDefaults.swift` | Composed postcards, the aerial diorama fit (bounds + 10%, 55°, 50° FOV, north up) and motion bounds. Written to the package's `environment.json` (`experience`) and carried by `WorldBuild`, so RealityKit and three.js read the same choice. |
| Camera rigs | `Sources/WorldGen/Experience/CameraRigs.swift` | `AerialRig` (pan, pinch distance, two-finger heading, tilt 45–65°, centre kept on the data), `ExploreRig` (1.65 m eye, 1.4 m/s (0.7–3), ≤ 1.5 m/s², ≤ 60°/s turns, pitch −45…+60°, blocked by buildings/water/edge), `RouteRig` (2 m eye, aim 1.2 m at clamp(2 + 2v, 4, 18) m ahead, scenic 1.4 m/s, ≤ 1 m/s², ≤ 30°/s, ≤ 20° down, slows before sharp turns, shorter look-ahead at hairpins), `CameraPose` blending. |

`worldbake compose <area> --date ISO` prints the composed postcards with scores and reasons.

## RealityKit (WorldEngine)
- `WorldCamera` modes: `.postcard(pose)`, `.aerial`, `.explore`, `.route`, plus `.street(following:)` (character follow), `.overview`, `.fixed`. Changing mode eases over 1.2 s (0 = cut).
- `WorldView` routes gestures by mode: one-finger drag orbits (follow), pans (aerial) or looks (explore); pinch zooms (follow) or changes distance (aerial); two-finger rotation turns the aerial; explore shows a thumb pad.
- Host entities: `World.characters` (zero, one or many); the first gets the contact shadow.
- Helpers: `world.postcards`, `world.pose(of:)`, `world.pose(origin:eye:target:fieldOfViewDegrees:)`, `world.makeAerialRig()`, `world.makeExploreRig(from:)`, `world.makeRouteRig(route:loop:)`.

## WorldLab
Opens on the best composed postcard with no character, live clock and Demo weather. Mode bar (Postcard · Aerial · Explore · Route · Follow when a character is present); menu for Demo weather presets and showcase states 01–12, character (None · Luna · Capsule), next postcard and clean view. Weather strip at the top (condition icon and text, temperature, precipitation, wind, place, local time, "Demo" label, reserved Apple Weather attribution slot); time scrubber above the OSM credit (sunrise/sunset markers, day and week steps, Return to live).

Launch arguments: `-showcase NN`, `-mode NAME`, `-character none|luna|capsule`, `-weather ID`, `-date ISO`, `-debughud`.
