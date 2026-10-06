# WorldEngine: visual direction

Requirements from the project owner (Prompt 2, sections B and C), recorded verbatim in substance. These are binding for all milestones. How they are met is in [plan-m1.md](plan-m1.md).

**Visual source of truth (since Prompt 4):** [Visual Spec Proposal v2](proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) and its images. Where v2 is more specific than the requirements below, v2 governs; the items marked **v2** below were updated to match it. The numbers live in data (`Sources/WorldGen/Profiles/*.json`), not here.

### v2 at a glance (what the engine implements)
- **Palettes as data** (v2 §3.2–§4.3): seasonal surface rows, house color tuples per type, interpolated in linear light.
- **Light by sun elevation, not clock** (v2 §3.3): six time-of-day keys (dawn, morning, noon, golden, dusk, night) with rising/setting anchors; sun from the real time and place. Each key also carries an **exposure** (engine addition; v2 says sun intensity is not an exposure).
- **Fog:** street distances from the key; **aerial** uses its own policy (≈900–2500 m at the fixture, from camera height) and a soft world boundary instead of a fog wall.
- **R1 baked vertex AO** (fill only, floor 0.65), **R2** near-camera bevels, **R3** lawn mottling + edge tufts (≤200 within 25 m), **R7** sidewalk joints, **R8** hemispheric fill + character contact shadow, **R9** gentle grade + emissive bloom, **R10** slow sway.
- **Trees:** three crown archetypes (broad, oval, spreading) of 4–5 smooth lobes; near/mid/far meshes (45 m / 160 m); conifers by tag or profile share.
- **Character framing:** the character's *projected bounds* fill 20–25% (22%) of the view height, not its standing height.
- **Comparison fixtures:** v2 §6.2 (`proposals/visual-v2/comparison-presets.json`), presets `v2-01`, `v2-04`, `v2-06` in WorldLab and the web renderer.

---

## B. Street-level view

The first app on this engine is a dog world. **The default camera is street level:** a third-person camera following a character walking real paths. Aerial (diorama) view stays as the second mode.

### B.1 Merging
One mesh per material for the whole world can't be culled, and at street level most of the world is behind the camera. Merge per material **per chunk** (start at about 200 m). Report the chunk size and resulting draw calls.

### B.2 Detail by distance (required)
- Full detail near the camera (start at about 150 m). **v2:** AO and bevels full to 150 m, reduced to 600 m.
- Simplified out to about 600 m. Props switch near/mid/far at 45 m and 160 m; chunks have lod0/lod1 meshes in the shared package.
- Silhouettes beyond that, with fog at the edge.
- Ground clutter (grass, bushes, small props) exists only near the camera.

### B.3 Generated street-level detail (OSM rarely has it)
- **Houses first** (most of what a walk passes):
  - door, windows, porch or steps, roof overhang
  - gabled or hipped roof when `roof:shape` is missing
  - a garage when the footprint suggests one
- **Apartments:** window grids, balconies.
- **Commercial:** ground-floor storefront glass, flat roof.
- **Sidewalks and curbs** along residential streets when not mapped; path edges.
- **Vegetation:** grass tufts, bushes and flower beds in parks and yards.
- **Benches, street lamps and trees:** use OSM when present; otherwise place them procedurally at sensible spacing.
- **Determinism (required):** seed all generated detail from the OSM element ID, so the same house looks the same on every visit and every device.
- **Plan for, don't build:** a per-building override keyed by OSM ID, so a user can later set their own house's color, roof and door.

### B.4 Shading and palette
- Smooth shading on organic things (trees, bushes, characters). Flat shading is fine on buildings.
- Palettes are data, not hardcoded, and shift by season, time of day and weather.
- Snow on up-facing surfaces and a wet look come from the shared materials.
- Fog/haze: check whether RealityKit has scene fog for a non-AR view; if not, report how it will be done.
- Report the approach for each item (ShaderGraphMaterial, CustomMaterial or other).

### B.5 Camera
- **Street mode:**
  - Follows behind and slightly above the character.
  - Drag to orbit, with zoom limits.
  - Recenters about 5 s after the user lets go.
  - By default the character fills about 20–25% of screen height. **v2:** measured on the character's projected bounds (22% target), so a long dog seen from behind and above is framed correctly.
  - Distance, height and FOV are tunable.
- **Occlusion:** when a lamp post, tree or building gets between the camera and the character, push the camera in or fade the blocker. Never clip through geometry.
- **Aerial mode:** angled overview, optional tilt-shift blur. **v2:** pitch 45–60°, 50° vertical FOV, the true 1.6 × 1.2 km area (no shrinking); tilt-shift only in aerial; no horizon in the steep aerial.
- **Transitions:** smooth fly between the two modes.

### B.6 World edge
At street level the end of the data is visible within a few hundred meters of the lake path.
- **Backdrop ring:** buildings only, rendered as simple low blocks (no facades, trees or clutter).
- **Fog**, plus a **horizon backdrop configured per location** (for the test area: mountain silhouettes to the west). **v2:** the western Front Range is a low band (about 2–3°, none above 5° without horizon data), only where its bearings enter the frustum; where coverage ends, show a soft world boundary rather than dense fake fog.

### B.7 Budget
- Re-estimate triangles with facades, clutter and the backdrop included.
- **Target:** steady 60 fps in street mode on iPhone 13-class hardware, with no thermal throttling over a 10-minute walk. Measured on a device later.

### B.8 Characters
The engine stays character-agnostic: a character arrives as a plain host entity (RealityKit) or host asset (web). **WorldLab** uses DogWell's Luna (read-only handoff export, converted at build time, never committed); a capsule stand-in is used when the export is missing. Ambient cars and pedestrians are a later milestone.

### B.9 Weather, time and season (both camera modes)
- Sun position from the real time and location.
- Light color keyframed through the day.
- At night, windows and lamps light up.
- **Weather states:** clear, cloudy, rain, snow, fog (the WeatherKit conditions mapped to these). Changes ease over seconds and never snap.
- **Precipitation:** rain streaks and snowflakes only in a box around the camera.
- **Seasons:** seasonal tree and grass palettes, falling leaves in autumn, bare deciduous trees in winter.

### B.10 Avoid in M1
- photoreal textures
- satellite imagery
- building interiors
- a first-person camera
- hand-modeling real buildings
- anything dog-specific in the engine

---

## C. Scale and generalization

### C.1 True scale
- **1 unit = 1 meter.** Never move, shorten or distort geography.
- **What stylization may change:** the size and proportion of objects. Characters, trees, lamps and benches can be chunkier than real, and building heights can be stylized.
- **What it never changes:** footprint positions or distances.
- **Only exception:** the horizon backdrop.

### C.2 Speed
Character movement speed is a tunable parameter, independent of scale. Apps compress time, not space.

### C.3 No place-specific code
Nothing Sloan's Lake-specific in generator code: no hardcoded coordinates, IDs or per-place tuning. Rules key off OSM tags, building types and footprint shape. **The area is input data only.**

### C.4 Generalization test
Planned now, run after the first visual milestone.
- Build 2 other public areas with the same rules and no retuning:
  - one dense urban area (downtown, mid/high-rise)
  - one hilly area
- Screenshot all three areas from the same camera presets.

### C.5 Terrain
M1 is flat; terrain is a later milestone. Avoid flat-world assumptions that would block it.

### C.6 Loading any location
- M1 ships one area's data in the app; on-demand loading of any location is a later milestone.
- **Design the M1 data format now** so the switch doesn't need a rewrite.
- **Public Overpass servers are not an app backend.**
