# House contrast v1 — shared afternoon revision

**7 October 2026 · Style B · proposal only.** Four existing house paint-overs now use one clear mid-afternoon target. [Phone-size grid PNG](hero-phone-comparison.png) · [Portable SVG](hero-phone-comparison.svg) · [Review gallery](index.html) · [Shared lighting and house values](paintover-values.json) · [Conflicts](lighting-conflicts.md) · [Prompt log](hero-image-prompts.json).

## What changed

Lakeview's pink haze/lavender paving, Wilmette's purple sky/lime lighting and postcard yellow rim lines have been replaced by blue sky, soft clouds, softly warm sun, cool-neutral shade, neutral grey asphalt, light warm-grey concrete and natural lawn green. Denver received a smaller color/lighting adjustment. Brick, trim, recessed glass, entry canopies, stoops and cornices remain the house detail authority; no redesign or additional floors was requested.

The postcard also has grey-brown trunks, varied irregular/oval/open crowns with restrained early-autumn color, three illustrative unbranded curbside cars, generic unlit lamps and tree pits at existing trunks. These are inferred concept dressing, not observed/live vehicles or verified municipal fixtures. Source trunk bases and road/sidewalk layout govern placement; do not infer a survey from AI pixels. Remaining tiny surface patterning is incidental, not a requirement for grass/leaf/brick geometry or photo textures.

## Renders used

The **current** column means the existing house paint-over before this lighting revision, rather than raw renderer output. Its house details are retained. Both columns show full uncropped frames; each panel is 390 CSS px wide at 100% viewing scale. Overview fitting reduces that width and is explicitly labelled.

| View | Existing edit target in `images/` | New file |
|---|---|---|
| Lakeview sidewalk | `lakeview-paintover.png` | [lakeview hero](images/lakeview-hero.png) |
| Denver — W 23rd Avenue | `denver-paintover.png` | [denver hero](images/denver-hero.png) |
| Wilmette | `wilmette-paintover.png` | [wilmette hero](images/wilmette-hero.png) |
| Lakeview postcard | `lakeview-postcard-paintover.png` | [postcard hero](images/postcard-hero.png) |

The first three original engine captures came from P3 look-loop run **20261007-062707**: `lakeview-street.png`, `ordinary-street.png` (Denver W 23rd Avenue), and `wilmette-street.png`. The postcard originates from `lakeview-postcard.png` in that same run. Paths and hashes are in [hero-manifest.json](hero-manifest.json). Original captures and all earlier PNG drafts remain untouched. Earlier metadata/gallery are preserved as `*.pre-hero.*`, including [earlier gallery](index.pre-hero.html) and [earlier README](README.pre-hero.md).

## One lighting target

`sharedLighting` is one block used by all four views. Sky zenith/mid/horizon: **#73A5CC / #A2C4DC / #DBDCD1**, softly warm only below 10° elevation. Sun **#FFE8C6**, relative clear-state intensity **1**, illustrative elevation **40°**, true-north azimuth **225°**. No yellow edge outlines. Shade **#7F8F99** is an appearance cue, not a purple overlay or material color. Exposure **+.35 EV** relative to frozen clear-day E0, gain **1.2745606273**, applied once; contrast **1.06**, saturation **1.08**, extra warmth grade **0**. Ground asphalt/concrete/lawn: **#626A70 / #C5C0B3 / #73865B**.

The neutral witness has direct contribution .38 and diffuse fill .62 when normalized to lit=1, so shadow/lit=.62 and key:fill=.612903. These are plane contribution ratios, not universal RealityKit/three.js intensity units. The old 2.2 ratio cannot simultaneously describe that same witness. Engine adapters must calibrate E0, tone mapping and witness geometry rather than treating this JSON as measured lux.

**Approved #5 ambiguity:** no unambiguous approval-to-file mapping was found. On-disk `lighting-05-blue-hour.png` is blue hour, incompatible with this brief. Clarification was requested; the working anchor is your explicitly named Denver house paint-over, supported by `look-fix-v1/images/lighting-03-ordinary-1530.png`. This pack does not claim that file was R's approved #5. The supplied blue-afternoon description is followed.

The fixed sun is an art-review fixture, not a fabricated real timestamp. Camera headings and generated shadow bearings are not ephemeris-verified. Live/recap uses the engine solar model; a hero preset must never override real recorded weather/time. Same atmosphere/palette does not mean identical cloud pixels in differently oriented cameras.

## Compatibility and validation

All existing `houseTypes` numeric/color data remains unchanged. Earlier per-view day grades are superseded only for these four hero references. Rain uses its own single per-surface wetness policy; night/blue-hour/fog replace clear-state lighting and exposure. Do not add their exposure values to hero EV, leave hero sun on at night, or double-darken rain surfaces. [Detailed conflict register](lighting-conflicts.md).

Inputs and selected outputs were visually inspected, then arranged into a phone-size grid. AI relighting preserves broad composition/architectural details, not exact source pixels or every incidental edge. No renderer code, phone benchmark, official grading gate, surveyed dressing or exact lighting equivalence is claimed. All new colors/intensities/dimensions are authored assumptions. Current source hashes, valid JSON, four hero files and unchanged house values are checked. No logos or people added; existing Denver dog retained. No git or engine-file writes.
