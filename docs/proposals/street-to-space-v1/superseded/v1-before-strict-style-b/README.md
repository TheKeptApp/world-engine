# Street to space · Style B v1

7 October 2026. Denver / Sloan’s Lake, seven day and seven night concept frames. Generated with the built-in image tool using the Denver house-contrast hero as style reference; exact prompts in prompts.json. No git or engine changes.

## Deliverables

- images/: 14 standalone PNG frames, numbered in zoom order.
- phone-zoom-strip.png: day and night side by side, each column 390 px wide, full uncropped frames. Separate day/night strips are each 390 px wide. At 100% size these are phone-width scrolling comparisons, not one-screen seven-frame layouts.
- index.html: responsive local gallery with full-frame links.
- values.json: per-level day/night land cover, water, clouds, atmosphere, night lights and space; preserved shared day lighting block and replacement night fixture.
- manifest.json: dimensions and SHA-256 per frame; prompts.json: generation record.

## Authority and continuity

Inputs: mobile-rendering-v1/streaming-design.md §12 and §§15–16; house-contrast-v1/images/denver-hero.png and paintover-values.json sharedLighting. User explicitly supplies approval authority for house-contrast lighting. Its older unresolved approval-number note is retained inside the copied source block for provenance, not treated as a new approval blocker. Night fixture follows night-fog-v1 night values as an authored extension.

Keep the selected feature's authoritative WGS84 anchor through the entire zoom. Sloan’s Lake remains northwest/west of downtown Denver; Rockies remain west of the plains. The concept frames show broad geographic relationships, not surveyed road/building placement. The lake must become subpixel at region scale rather than being enlarged to remain a visual icon. Earth and coastlines are artist-generalized; production uses consistent georeferenced surface tiles. Illustrative altitude labels are design fixtures, not recovered camera measurements.

One matte world: terracotta/cream houses, grey roads, natural green park, slate-blue water. Earth expands the same palette into forest, grass, crops, dry plains, rock and snow. Change spatial frequencies and representation; avoid introducing photographic satellite textures or a different globe art style. Swatches are authored sRGB appearance targets, not material albedo, measured pixels or promises of exact generated colours.

## Transition notes

| Transition | Retain | Remove / aggregate |
|---|---|---|
| Street → neighbourhood | Lake shore, street grid, roof colour, same feature identity | Recesses, trim and window geometry fade before unreadable; trees become crowns; houses become roof/body solids |
| Neighbourhood → city | Park/water silhouette, major roads, downtown silhouette | Roof/body solids collapse into bounded block volumes; crowns blend into canopy coverage; no repeated detailed houses |
| City → region | Denver position, Front Range boundary, river corridor | Block height flattens into urban fraction; only major urban patches remain; no local lake enlargement |
| Region → continent | Class fractions, mountain ranges, basin shapes | Fine roads/lakes disappear by projected size; relief becomes lower-frequency terrain shading; generalized coastlines blend with finer coastlines |
| Continent → globe | Same ellipsoid, sun vector, cloud fields and coastlines | Curvature gradually dominates; haze becomes atmosphere limb; no replacement planet |
| Globe → orbit | Same Earth object and selected anchor | Earth shrinks continuously; stars, moon and computed satellite points become exposure-visible |

Use the §12 overlapping presentation bands, not seven altitude switches: street 1–80 m; neighbourhood 30 m–2 km; city 1–30 km; region 20–300 km; continent 200–2,500 km; globe 1,500–20,000 km; outer orbit 20,000–100,000 km. Projected error and footprint govern detail; an orbit camera at lower altitude still uses appropriate surface LOD.

Suggested authored timing from the input: terrain/normal geomorph and linear-colour land-cover blend 0.3–0.8 s; urban replacement 0.8–1.5 s using stable complementary coverage or compatible morphs. Parent stays until complete child coverage is ready. Blend land-cover class fractions in linear colour; never average categorical class IDs. Houses disappear before subpixel shimmer; blocks flatten before city-wide mass becomes land colour. Fade casters with geometry. Avoid transparent overlapping full cities and duplicate houses.

Exposure follows one state with a 1–2 s adaptation proposal. Day uses warm sun #FFE8C6, cool-neutral shade #7F8F99, asphalt #626A70, concrete #C5C0B3, lawn #73865B; +0.35 EV applied once. Night replaces direct sunlight with zero and its own fill/exposure; +0.35 night EV is not added to day EV. No neon street grids. Warm windows/lamp pools aggregate into quality-masked urban radiance, preserving dark parks, mountains and water.

One world-space sun drives local shadows, cloud lighting, atmosphere and terminator. On globe frames “day” or “night” describes Denver; both hemispheric lighting states may coexist in a single image. Night lights are suppressed on the sunlit side and tapered through twilight. Sunlit cloud tops beyond the terminator remain distinct from dark local clouds. No uniform blue overlay over the entire night Earth.

Clouds have live-style shapes here, not live data or an asserted timestamp. Production should use dated cloud snapshots, masks and coherent shell reprojection; cached snapshot interpolation is not observation. Outside coverage use an explicit simulated/unavailable policy. Stars are inertial directions, satellites computed from dated elements, and moon phase/illumination follow the same UTC and sun. These pictures are illustrative and are not propagated ephemerides. Moon framing is schematic; do not copy its displayed size/separation as physical scale. Satellite points are intentionally legible concepts, not resolvable vehicle models.

## Review limits

AI concept frames preserve style and broad place cues, not exact geometry or pixel correspondence across independent generations. No live feed, terrain survey, phone performance benchmark or engine validation is claimed. Phone strip assembly fits complete frames without cropping. Palette continuity and the representation ladder should be reviewed before implementation; use source geometry for exact shorelines and feature anchors. The values specify the intended transition even where incidental generated detail is denser than a production LOD should retain.
