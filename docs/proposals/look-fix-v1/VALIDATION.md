# Validation notes

6 October 2026. Proposal/artifact validation only; no device build, engine test, performance run or independent look-loop grading was performed.

## Checked

- Read the latest look-loop summary/sheets, calibration and rubric; phase 5A report; building gate; relevant visual-v2, experience-v1, Chicagoland/Miami and postcard/widget proposals.
- 21 distinct PNG deliverables: 4 ground, 12 lighting, 2 aerial, 3 sky. Final paths, dimensions, byte counts and SHA-256 hashes are in image-manifest.json.
- Inspected generated outputs visually for broad composition, regional scale, readable weather, season and material style; correction attempts are retained in PROMPT-LOG.json. Initial photorealistic master and superseded attempts were not copied into this proposal's images/.
- Ground clear/rain pair retains the same North Shore street composition. Lighting variants retain the same trail/lake/house/tree arrangement in broad terms; do not assume pixel-locked geometry across generated edits.
- January snow/night concepts have bare northern deciduous trees, without autumn leaf litter. The snow scene keeps open water. The North Shore summer ornamental red shrub is a cultivar-color appearance, not a northern autumn blanket.
- Aerials contain no sky/horizon or floating slab; visible context continues to the image boundary.
- Solar positions calculated from a transcription of SolarPosition.swift. Lunar positions calculated from a transcription of Moon.swift including its coefficient tables, observer parallax and phase vectors. No production source was changed or executed.
- Moon-night calculation: approximately altitude17.230°, azimuth71.954°, illuminated fraction.9916. Cross-check against the existing experience-v1 reference agrees within.1°; this is a sanity check, not independent ephemeris certification.
- Moonless-night calculation: Moon altitude approximately −21.492°, so the absence of a lunar disk/directional light is supported by geometry.
- Star projection uses the current bundled BSC5 catalog, motion/precession and pinhole camera arithmetic; 11 entries lie in each tested night-camera frustum before scene occlusion. No proper names were redistributed. Source catalog hash and source notice are linked in sky-projection-reference.json.
- Image statistics measured with PIL without editing pixels: whole-frame encoded-sRGB Y using the same coefficients as the look-loop, percentiles, HSV saturation and extreme clipping fractions. These are **measured concept values**, not device measurements.

## Remaining limitations — do not copy these into the engine

1. **Astronomy:** generated stars are illustrative and do not match the projected catalog. Generated Moon/Sun disk sizes and positions remain approximate after correction. In particular, the ESE moon-night illustration does not land exactly on the fixture's UV≈(.1722,.0589). The dedicated water views also have approximate source size/elevation. Use the JSON/math, not raster sampling, for celestial implementation or grading. These night/sky images are not astrometric baselines.
2. **Shadow precision:** directional corrections remove the most obvious contradictory foreground shadows and forward sunset glitter. Perspective artwork cannot prove the required 1°/5% bearing/length tolerances; some ground/aerial shadow contours remain ambiguous. Use the 2m diagnostic-pole engine capture described in the spec. No image here is certified to pass wrong-sun-bearing.
3. **Material simplification:** the references still contain some generated fine turf/water/roof detail; do not interpret it as authorization for authored surface textures, dense blades, per-leaf geometry or extra reflection passes. Ground revisions deliberately simplify facades/crowns, but that also flattens some shading; retain the spec's contact/fill and silhouette targets.
4. **Wetness:** the rain illustrations can exaggerate puddle/sheened area. The North Shore street is a weather-readability study, not a measured5% puddle mask. Implement the numeric masks and prohibit recognizable object/full-surface mirrors.
5. **Geography:** these are fictional/regional or location-inspired compositions, not reconstructed parcels or audited OSM geometry. Their attribution text demonstrates intended app placement; it does not certify that the illustrated buildings were sourced from OSM. Use mapped data unchanged in production.
6. **Photometry:** the generated concepts do not all land inside the proposed mean/percentile/saturation bands. The table below records exceptions rather than retroactively widening the spec to match them. A bright or attractive image is not a graded pass.
7. **Performance:** GPU labels and effect envelopes are engineering proposals. No evidence here proves a sustained10ms frame on iPhone13-class hardware. Main/shadow visible counts must be measured separately from whole-world counters.
8. **Calibration:** no independent target scores were assigned. Keep the current frozen targets until these studies are reviewed; do not silently replace them or treat their mean score as35.2.

The numeric spec and fixtures take precedence over incidental pixels. These limitations mean the pack is an implementation proposal with visual guidance, **not a set of fully certified regression goldens**.

## Acceptance handoff

P2: implement stable inferred ground/yard layers and crown/LOD variety; preserve mapped positions and access.
5A: verify environment-to-material bindings, fix light/fill first, then wetness/fog/smoke; use true source vectors. Compare fixed captures with the current rubric, criterion floors and owner-directed per-view parity gate. Sky polish remains later.

No changes were made outside look-fix-v1 except generated attempts in the explicitly allowed image-tool default folder. No git commands were used. No supplied video screenshots were copied or used as image-generation inputs.

## Measured final image statistics

See the following table and image-manifest.json. “Mean band” refers only to the spec's whole-frame lighting-state band; it is not an overall pass/fail.

| Image | Mean Y | P5 / P50 / P95 | Mean S | Mean band |
|---|---:|---|---:|---|
| aerial-01-continuation-clear | 135.05 | 72 / 124 / 220 | 139.91 | not a lighting-state fixture |
| aerial-02-continuation-snow | 155.3 | 88 / 144 / 231 | 52.98 | not a lighting-state fixture |
| ground-01-north-shore-clear | 141.25 | 84 / 139 / 219 | 119.6 | not a lighting-state fixture |
| ground-02-north-shore-rain | 121.21 | 67 / 116 / 189 | 99.39 | not a lighting-state fixture |
| ground-03-denver-clear | 151.43 | 98 / 157 / 220 | 118.49 | not a lighting-state fixture |
| ground-04-lakeview-clear | 139.3 | 68 / 141 / 225 | 87.45 | not a lighting-state fixture |
| lighting-01-morning | 130.54 | 65 / 138 / 191 | 109.52 | 125–145: inside |
| lighting-02-midday | 144.63 | 74 / 146 / 212 | 126.96 | 135–155: inside |
| lighting-03-ordinary-1530 | 144.56 | 77 / 147 / 203 | 121.6 | 130–150: inside |
| lighting-04-golden-hour | 146.97 | 75 / 153 / 201 | 129.44 | 120–140: outside |
| lighting-05-blue-hour | 94.23 | 43 / 97 / 139 | 110.93 | 78–98: inside |
| lighting-06-overcast | 136.23 | 68 / 140 / 185 | 97.76 | 127–147: inside |
| lighting-07-light-rain | 135.72 | 66 / 144 / 179 | 89.97 | 116–136: inside |
| lighting-08-storm | 89.03 | 50 / 91 / 122 | 97.08 | 86–106: inside |
| lighting-09-fog | 156.34 | 85 / 172 / 197 | 63.01 | 137–157: inside |
| lighting-10-snow | 148.51 | 71 / 156 / 203 | 68.81 | 156–176: outside |
| lighting-11-moon-night | 61.12 | 32 / 55 / 104 | 128.79 | 47–67: inside |
| lighting-12-moonless-night | 44.77 | 18 / 32 / 107 | 166.41 | 33–53: inside |
| sky-01-golden-water | 126.91 | 77 / 131 / 165 | 123.77 | not a lighting-state fixture |
| sky-02-moon-water | 42.96 | 22 / 37 / 92 | 204.85 | not a lighting-state fixture |
| sky-03-clear-afternoon | 158.71 | 93 / 157 / 222 | 155.11 | not a lighting-state fixture |
