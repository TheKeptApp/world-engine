# WorldEngine morning fog — Style B v1

Proposal, 2026-10-06. [Open the phone gallery](index.html). Final images are in [images/](images/); prompts and correction history are in [image-prompts.json](image-prompts.json).

**Priority:** depth separation first, nearby rich surfaces second, soft light glow third. Nearby pavement must stay readable. Fog never becomes a uniform gray filter, opaque cloud sprites or a reason to change geography.

## Claim policy and anchors

**Authored assumptions [A]:** every density anchor, color, strength, layer height, demo wetness, visual evaluation and performance subdivision below. **Verified principles [V]:** exponential extinction; radiation fog forming near the surface and commonly dissipating under sunlight; lake/advection fog forming when moist warm air moves over colder water. See [sources.md](sources.md), checked 2026-10-06. Neither sources nor images establish a measured local event.

**Repository constraints [R]:** Style B smooth organic crowns, quiet ground families, bounded contact darkening, one material fog term, existing visual-v2 GPU buckets. Read-only anchors: [look-fix-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/look-fix-v1/LOOK-FIX-SPEC.md), [rain-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/rain-v1/README.md), [paintover-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/paintover-v1/README.md). No engine implementation changed.

## 1. Density and distance [A]

“Visibility” here is **V**, the model distance retaining 5% of an ideal object's original contrast. It is an authored rendering convention, not a meteorological category or guaranteed human detection range. A small low-contrast object can disappear sooner. Every demo preserves a near-clear 5m band.

| Density | V, 5% contrast | Sigma /m | T at 10m | T at 20m | T at 40m |
|---|---:|---:|---:|---:|---:|
| light_mist | 1000 m | 0.003011 | 98.5% | 95.6% | 90.0% |
| moderate | 220 m | 0.013934 | 93.3% | 81.1% | 61.4% |
| dense | 60 m | 0.054468 | 76.2% | 44.2% | 14.9% |

For the homogeneous street test: **sigma = ln(20)/(V−5); T(d) = exp(−sigma × max(0,d−5)); Cout = T × Csurface + (1−T) × Cfog**. All mixing is linear light. Sigma is in inverse meters. Five-percent contrast at V follows exactly from the formula. The near-clear offset is a readability concession, not a physical law.

- Light mist: 5–40m retains clear shapes and material identity; distant blocks are gently pale.
- Moderate: 5–10m remains crisp, 20–40m becomes lower contrast; silhouettes fade gradually rather than a wall at220m.
- Dense: 10m still readable, 20m heavily softened, 40m retains about15% contrast, 60m about5%; farther detail should vanish into the fog color.

“Soft” means reduced contrast, not a depth-of-field blur. Fog treats walls, trunks, lawns, shoreline, water and backdrop consistently. Keep near crown interior shade and short contact pockets; no extra contrast/saturation fade after the fog mix.

[Street density comparison](images/street-density-comparison.svg) — three 390px panels; scroll sideways in the gallery. [Exact curve diagram](images/density-curves.svg). AI images are mood/material references, not calibrated screenshots of this curve. Their camera/window details vary; the actual original map/camera is authoritative.

## 2. Light and time [A]

| Look | Example rising solar elevation | Fog / warm scatter color | Glow max | Shafts max |
|---|---:|---|---:|---:|
| Pre-sunrise | −4° | #AEBECD / no solar glow | 0 | 0 |
| Low sun | +4° | #C8D1D1 / #EBD8B8 | .12 | .045 |
| Overcast fog | +6° | #C1CACD / #C1CACD | 0 | 0 |
| Late morning lift | +25° | #CBD7DC / #E7DFCE | .025 | 0 |

These angles are look examples, not surveyed event times. Runtime sun position must be true. The soft sun glow follows its direction, 12° half-angle with support taper to25°, and mixes toward warm scatter color only where sky optical depth exists. No sun below the horizon; no warm glow in the opposite sky.

Low sun through fog keeps cool ambient fill, lightly warm facing planes and long faint shadows. Use direct multipliers .65/.35/.12 for light/moderate/dense, choosing the minimum of cloud and fog attenuation rather than multiplying both. Example shadow/lit ratios .70/.84/.92 keep dense fog shadows very faint. Actual shadow length stays height × cot(actual elevation).

Overcast fog is flat and cool, but nearby tree lobes and facade bases retain shape. Shafts are off. Low-sun shafts are an optional two-band, ≤3%-screen-coverage accent through actual canopy gaps, depth-occluded and sun-aligned. Omit when placement cannot be validated. No volumetric solver, camera-facing yellow cones or extra full-screen god-ray pass.

## 3. Places and aerials [A]

**Sloan's Lake:** references use the existing engine lake/path/shoreline as a visual starting point. A shallow8m layer with3m upper taper is a demo assumption; use supplied regional geometry/elevation. Cool gray-teal water (#839B9E at low sun), subdued reflection and a bank fading by real distance. Never move or fabricate the opposite shore. Demo water is unfrozen; fog alone cannot decide ice.

**Street:** houses and parkway trees create repeated distance cues. Near5–40m is the acceptance region. Smooth puff crowns, thick branching trunks and root flare stay readable; no leaf/bark detail or grass carpet is required. The three generated street views share a street axis but are not pixel-aligned density measurements.

**Chicago lakefront:** a generic public lakefront concept, not a surveyed site. Open water horizon, cool #7B919E water, inland building/tree silhouettes and small dawn lamp halo. Lake/advection fog is distinct from lake-effect snow. Steam fog requires cold-air/warm-water evidence; do not select it merely because the region contains a lake. No mountains or invented shore landmarks.

**Aerial:** use the same environmental extinction coefficient, integrating only the ray segment inside the shallow layer. Roofs/crowns above the layer emerge; shallow rays through water-level fog obscure distant banks. Never simply apply stronger fog to the whole aerial image or enlarge V for an aerial camera.

The optional analytic layer is a broad flat test-region layer: weight1 from ground/lake reference to H−taper, linear taper to0 atH. Integrate its piecewise-linear height weight along the ray, starting after the near-clear band, then apply one exponential. Height varies linearly along a ray, allowing closed-form piecewise integration; no ray march or3D noise. Exactly one layer/domain is proposed. Do not combine it with a second distance fog: homogeneous distance fog is the fallback, height-integrated fog its replacement.

Local lake-only enrichment requires supplied domain information and a soft boundary. OSM water does not prove localized fog. Flat-layer assumptions need review in hilly terrain. Shader/backend support must be tested; a renderer without this extension can use homogeneous depth extinction and declare the limitation. Low clouds, low fog, camera height and supplied layer height are separate.

## 4. Dampness, dew and lamps [A]

Use the rain-v1 **damp** surface row once, not stacked darkening:

| Surface | Linear darkening | Roughness | Sky sheen max |
|---|---:|---:|---:|
| Concrete | 4% | .76 | .05 |
| Asphalt | 5% | .78 | .06 |
| Brick | 4% | .78 | .04 |
| Lawn | 3% | .92 | .01 |
| Roof | 2% | .82 | .03 |

Dampness, dew and fog are independent. Live accumulated wetness wins over these demo overrides. Fog does not create rain particles or puddles. Dew is a subtle broad grazing highlight (.025 maximum; combined lawn sheen capped.03), not white sparkles, grass blades or clear-coat lawn. Suppress under snow and on sheltered/non-upward surfaces. Missing dew evidence stays unknown; a labeled demo may set.5.

Lamp cores #F4CD92 use supplied schedules; the example dawn gate fades out between−2° and+12°. Fog does not force lamps on at noon. Up to6 street halo sources,0 aerial halos and2 local unshadowed lights. Halo half-radius6–18 CSSpx, support≤28px, weight≤.18; use the exact extinction-aware radial function in JSON. A farther light loses intensity, never glows through a wall. Emissive head receives scene fog once. Glow strength is a stylized linear blend, not lumens.

Dawn asphalt can show two short restrained light streak fields (1–4m, weight≤.06), from the existing wet-light machinery. Fog is not steady rain: no full-road mirror. Residual generated pavement grain and stronger lamp pools are not renderer requirements.

## 5. Lifting [A]

The90s demo moves moderate sigma toward light-mist sigma, and8m layer top toward3m with smoothstep. Warm scatter becomes more neutral as actual sun rises. World geography stays fixed, opposite bank returns gradually and damp ground does not instantly dry. The late-morning image is an appearance endpoint, not proof of an observed clearing event.

Live updates use weather-v1's20s fog and12s light display transitions from current frozen endpoints. Never clear fog merely because it is10am: use refreshed evidence. The [NWS radiation-fog source](https://www.weather.gov/safety/fog-radiation) supports sunlight often dissipating this fog, not a universal schedule.

## 6. Phone performance [R/A]

60fps, ≤10ms total GPU on iPhone13-class hardware, iOS26+, with7.90ms planned content and2.10ms reserved margin. Fog already belongs to the4.25ms base-world bucket. Damp surfaces share the existing.35ms wet/local-light bucket. Halo/optional shaft work shares the existing.35ms bloom envelope: .08ms halos + .05ms shafts are proposed targets within it, not extra allocations. No timings are measured.

Baseline: one analytic material extinction term,0 fog particles,0 fog cards,0 3D textures,0 extra fog pass, unchanged shadow geometry. Reuse one existing bloom/grade chain. Do not spend margin on decoration. Prefer smooth math over transparent sheets: sheets multiply overdraw, show layer crossings and mismatch water/roof depth. No photographic noise textures. Procedural density variation is excluded from the baseline.

Disable shafts first, then halos beyond2, then dew/local enrichment. Preserve depth fading and actual environmental V. Aerial omits shafts/individual halo sources. Test street and aerial transitions on a physical phone for10min with fixed drawable resolution, max/p95 GPU and thermal logs. Artwork is not a performance pass.

## 7. Acceptance and open questions

1. At390px width, light/moderate/dense must be distinguishable through distance cues, not global brightness.
2. Compare known objects at5,10,20,40,60m in a renderer fixture; verify measured contrast against JSON.
3. Geometry, path access and shoreline cannot change with fog.
4. Overcast/below-horizon frames have no shafts; source direction governs glow/shadows.
5. Confirm whether the chosen renderer can implement the single analytic shallow layer and depth-occluded halo within existing buckets.
6. Decide how host weather supplies fog-layer height/local extent and dew evidence. Until then: labeled assumptions, no fabricated local weather.

## Files

- Seven final portrait PNGs and seven390px phone-sheet SVGs.
- Street-density and aerial/lifting comparison SVGs; density-curve SVG.
- README.md; fog-values.json; image-prompts.json; sources.md.
- index.html gallery; manifest.json; verification.md.

Images generated with the built-in imagegen tool, one correction per image. SVGs embed unmodified raster bytes for portable phone-width presentation. They do not retouch pixels. No git commands or engine edits.
