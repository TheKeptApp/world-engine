# WorldEngine — demo storyboard v1

Open index.html locally. No server, installation, network, or git required. Print the browser board to PDF if desired. The timing preview highlights shots; it does not simulate engine output.

## Contents

- storyboard-board.png: 16-frame visual contact sheet, row-major shot order.
- storyboard-board.md: shot-by-shot camera, lighting and release evidence.
- script.md: narration, captions, screen text, exact 90 / 30 / 15-second edits, music and five brand-line options.
- index.html: responsive storyboard board, printable cards and cut timing preview.
- shots.json: machine-readable master timing and production flags.
- image-prompt.txt: final image-generation prompt and provenance.

## Art direction and precedence

Approved daytime lighting is the shared mid-afternoon master in house-contrast-v1. The user has explicitly confirmed approval in this session. Images win over conflicting JSON: clear blue sky with soft white clouds, warm-neutral sunlight, cool-neutral readable shadows, no lavender or sepia grade. The JSON art fixture is sun elevation 40 degrees / azimuth 225 degrees, +0.35 EV once, shadow/lit neutral witness 0.62. These are review targets, not verified renderer calibration or geographically correct sun at every city/time. Real solar date/location must control the time-lapse and any live view.

House forms follow house-archetypes-v1: Chicago brick bungalow/flats, Denver bungalow and other local forms, Miami low-rise stucco and roof variants. No invented tiny decorative geometry or universal house palette. Concepts are approximate, not measured street reconstructions.

Night uses night-fog-v1: readable blue ambient, sparse stable warm windows, lamp-ground pools and dark gaps, restrained bloom. Night is dry in this sequence. Fog is not required by this story. Rain uses rain-v1: per-surface material policy once, darkening <=12%, restrained broken grazing sheen, no mirror streets or automatic deep puddles. Clear daytime master applies to dry daylight shots; time, rain and night appropriately override it.

References inspected (read-only):
- ~/Desktop/worldengine-gpt-drop/house-contrast-v1/paintover-values.json (sharedLighting) and hero-phone-comparison.png
- ~/Desktop/worldengine-gpt-drop/house-archetypes-v1/phone-sheet-preview.png and city archetype pack
- ~/Desktop/worldengine-gpt-drop/night-fog-v1/night-fog-values.json and images/lakeview-night.png
- ~/Desktop/world-engine/docs/proposals/rain-v1/rain-values.json
The Desktop drop rain-v1 path was absent; the filed copy was readable. No raster rain reference was present there; rain frames follow the numeric/material specification. Final generated board targets this reference language; its visual interpretation has not received a new approval.

## Engine versus mockup

E: all world geometry, true-scale grounding, sun/shadows, rain/wetness, night lights, moving trains, region/globe, route placement and village asset transforms must be rendered by the actual engine before release. This package contains no engine footage and verifies no current engine capability.

O: captions, titles, source/time labels, cursor highlights, city locators and satellite labels can be composited. A satellite marker may be composited only from the same world coordinates/epoch used by the engine. Editing can join views with honest match cuts; do not imply a continuous zoom if unsupported.

M: creator editor chrome can be mocked during planning and may appear at release only with a readable “Concept interface” label. Actual course placement and village placement must be shown in the engine. AI frames and painted weather cannot pass as engine footage. Any concept insert retained in an external video requires an on-screen “Concept visualization” label and cannot substitute for an E shot.

## Release gate

1. Replace every E storyboard scene with engine capture; keep shot IDs, original capture files and render settings in a footage manifest. Show real engine footage before release, including street scale, environmental transitions and creator placement.
2. Verify city capture coordinates, mapped footprint/height/curb scale and route-to-street alignment. Geographic art is illustrative. Confirm route and village persist after camera movement/reload. No performance or survey-accuracy claim is made.
3. Separate LIVE, REPLAY and CONTROLLED states visibly. Capture source name, UTC observation time, fetch time and freshness threshold. Threshold is a source-specific release decision, not invented here. Suppress LIVE on feed failure or stale data; rewrite narration or recapture.
4. Time-lapse uses controlled date/time; rain and night are controlled engine states unless verified observations support a live claim. Do not imply the three cities or state montage are simultaneous.
5. For satellites, record orbital-element epoch, computation time and source. Label calculated position; never present it as a live camera observation. True-scale geometry can coexist with a schematic marker; marker size is a UI symbol, not satellite size.
6. Remove all logos and people from engine scene/capture. Keep unbranded trains and event assets. Add required data attribution as readable plain text in the frame or end slate, according to actual sources; no logo is needed.
7. Review Style B against approved images, confirm wet/night readability and match-camera continuity. Check full-screen and phone-size legibility. No device-performance claim without actual measurement.
8. Select the closing line, clear music/sound rights, complete caption and 24 fps timing check, and review each cut independently. If a required capability is missing, recapture after implementation or reduce the released scope and update copy; do not silently fill it with concept art.

## Timing and audience

90s = 2,160 frames; 30s = 720; 15s = 360 at 24 fps. The long cut proves street/environment context, three-city coverage, current transit and orbital context, then practical creator placement for map, event/race-map, media and proptech audiences. It does not assert an available SDK, commercial license terms or operational event approval. Portrait cut prioritizes place and creation with no unsupported live claim.

Brand line remains pending. No files under sources/ or the reference packs were changed. No git operations performed.

## Visual review notes

The generated sheet matches the simplified Style B architecture and clear blue daytime direction. It is a composition guide, not an exact style or geometry acceptance frame: rain panels 04/05/12 show stronger sheen than the specified rain-v1 target; reduce it in engine. Denver mountain scale in 09/10 is exaggerated; replace with verified distant silhouette. Course panel 13 runs beside a waterway; its line is illustrative and must be redrawn against a verified street graph. Orbit dot sizes are schematic symbols. Shared-camera registration in 01–03 remains approximate. These deviations are identified rather than approved as new art direction.
