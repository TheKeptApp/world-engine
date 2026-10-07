# WorldEngine dusk + night pack — Style B

**6 October 2026 · Appearance proposal · Renderer-neutral · Phone review**

Night should read through cool sky and filled shadow shapes, selective warm windows, and separated lamp pools. Rain adds source-owned wet reflections; snow adds matte blue-white coverage. Keep roads, roofs and crown silhouettes recognizable without making the entire world luminous.

## Files

| Sheet | Purpose |
|---|---|
| [01 Blue hour → night](images/01-blue-hour-to-night.png) | Chicago city glow versus a darker Denver suburb, with aerial insets |
| [02 Windows and porches](images/02-windows-porches-evening-late.png) | 6 pm / 11 pm after-dark demos, curtains and aerial changes |
| [03 Streetlights](images/03-streetlight-pools-and-trees.png) | Sodium / warm-white LED, pools, underlit trees and 5/20/40 m |
| [04 Moonlight](images/04-full-moon-vs-moonless.png) | Full moon / moonless street and aerial |
| [05 Rain and snow](images/05-night-rain-and-snow.png) | Wet reflections versus matte snow; street distance and aerial |
| [06 Exact palette](images/06-exact-night-values.svg) | Exact authored colors; intensity units remain separate |
| [Phone review gallery](index.html) | Selected scene panels at up to 390 CSS px, plus full sheets |
| [night-values.json](night-values.json) | Exact values, units, deterministic schedules and caps |
| [prompts.json](prompts.json) | Built-in generation prompts, style references and one edit history |
| [manifest.json](manifest.json) | Saved image sizes/hashes and limitations |

## Authority and claim policy

All numeric appearance targets are **authored assumptions**, not observations of Chicago/Denver light pollution, household occupancy, lamp installations, emitted spectra, or physical moon illuminance. Repository budget/cap references were checked on disk on 6 October 2026. **Verified astronomy:** civil, nautical and astronomical twilight use solar-center elevations −6°, −12°, −18°. [US Naval Observatory, checked 6 October 2026](https://aa.usno.navy.mil/faq/RST_defs).

Read-only anchors: [look-fix-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/look-fix-v1/README.md), [paintover-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/paintover-v1/README.md), [rain-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/rain-v1/README.md), [live-world-v1](/Users/robwoodbury/Desktop/world-engine/docs/proposals/live-world-v1/README.md). These references live outside this delivery folder; the pack does not modify or copy them.

Generated sheets are concept scenes, not surveyed geography, renderer captures, precise source positions, measured pixel brightness or GPU evidence. JSON and the exact SVG govern numerical values. AI windows/stars/shadows/pool boundaries are illustrative. Do not implement incidental fine surface grain, invented lakes, duplicate props or new openings in a mapped scene.

## 1. Units and renderer calibration

Keep **lighting, emission, sky and exposure** distinct.

- **Erel** is diffuse irradiance relative to the renderer's calibrated neutral noon key E0=1. It is not lux, lumen, candela, watts, an arbitrary engine intensity, or a physically measured moon/day ratio.
- **Lrel** is emitted radiance relative to a unit-albedo Lambertian surface under E0. A lit window emits; it does not automatically become a point light.
- Lighting hex values specify chromaticity: decode sRGB, normalize by linear luminance Y, then multiply by Erel/Lrel. Preserve HDR values before tone mapping.
- Sky hex stops are **output display targets**. Each renderer uses exposure compensation or inverse grade/tone mapping to reach them; never warm/expose an output target twice.
- Exposure EV is relative to the existing E0 camera calibration. Multiply scene-linear radiance by 2^EV; apply the existing single grade and tone map. Do not copy editor slider values.
- Halo radii use **CSS/logical pixels at 390 px phone width**. Convert to drawable pixels using the actual drawable/logical width ratio. Geometry, lamp housings and Moon disk retain true projected scale.

Calibrate both renderers against the same neutral plane, window patch and lamp pool. The JSON gives exact shared targets; adapters must translate them to their own lighting units. A calibrated match is still required before adopting these values.

## 2. Blue hour, first stars and regional horizon

Use actual solar elevation, not “6 pm means blue hour.”

| Solar elevation | Stage | Chicago ambient Erel | Denver suburb ambient Erel | Exposure EV |
|---|---|---:|---:|---:|
| −4° | Blue-hour art key | .025 | .020 | +.8 |
| −8° | First-star art key | .010 | .007 | +1.5 |
| −18° | Night | .006 | .0035 | +2.0 |

Clamp outside these keys; smoothstep interpolate between them and interpolate colors in linear space. “Blue hour” is an art label rather than a new astronomical category. Dawn uses the same solar keys in reverse. Live sky/light smoothing is 12 seconds, exposure adaptation 4 seconds. Recap evaluates replay time directly; scrubbing must not wait for a wall-clock smoothing accumulator.

Chicago night zenith/horizon: **#182D4C / #5A5260**. Darker Denver suburb: **#0F2038 / #303746**. Chicago glow strength 1.0; Denver suburb .35. Horizon glow is broad and low, with supplied city-bearing direction. Unknown direction uses a weak isotropic fallback (.25 of configured strength), marked inferred; never put city glow toward west by default.

Clouds can softly brighten an urban horizon while hiding stars. Keep dark foreground material families and route boundaries; do not substitute a brighter universal blue wash.

Reuse live-world-v1's catalog projection, magnitude flux and spectral tint. Night gate is 1−smoothstep(−18,−6,sunElevation). Bright stars appear first; nominal moonless limiting magnitudes are **3 city / 4.5 suburb**, with atmospheric/cloud attenuation and up to two magnitudes of lunar loss. The Denver suburb is not a dark mountain: no default prominent Milky Way; its optional contrast cap is 2%, Chicago 0%. Overcast blocks stars and Moon. Generated star positions are never a catalog.

## 3. Windows, curtains and porches

The schedule is a **simulated decorative layer**, not an occupancy inference.

| Local time | Houses with ≥1 lit room | Lit rooms within a lit house | Porch fixtures on |
|---|---:|---:|---:|
| 6 pm | 68% | 40% | 55% |
| 8 pm | 75% | 45% | 62% |
| 11 pm | 24% | 20% | 55% |
| Midnight | 14% | 16% | 48% |

These are separate probabilities. All windows of a lit house do not light up. Group related openings by room; select at least one supported room when a house is selected. Small blocks need not hit an exact percentage. Daytime gates reduce the simulated interior lighting's night prominence; the 6 pm image is explicitly an after-dark comparison fixture, not an assertion that every season/location is dark then.

Use stable house/room hashes and fixed threshold ranks, smooth local-time interpolation, and a small rank-boundary fade. Late-night selections remain a subset of evening selections for these comparisons. No per-frame random flicker or scrambling on recap seek.

Three warm chromaticities: **#E7BA79 / #F0CF9C / #F1DFC2**, weighted 30/50/20%, with Lrel **.055 / .075 / .090**. Artistic nominal range 2400–3000 K; these hexes are not calibrated spectra. Late emission multiplier .85.

Curtains: **25% open / 45% sheer / 30% closed**; transmission **.90 / .55 / .15**. A closed curtain in a lit room can glow faintly; it does not mean the room is off. Broad 2–4 fold bands, ±8% emission modulation; avoid striped wallpaper detail. Reuse existing facade openings and materials, not room meshes or visible residents. Cull subpixel windows; never widen them for aerial visibility.

Porch source **#E7C38B**, Lrel .60, peak pool Erel .003; oval semi-axes 1.4/.9 m and 3 m reach. Porch schedules are independent of indoor rooms. Window spill is a facade-local shading cue, peak Erel .0008 and 1.5 m reach, clipped to supported surfaces. No automatic light through walls or across the road.

## 4. Streetlights, pools and underlit trees

| Family | Chromaticity | Source Lrel | Peak pool Erel |
|---|---|---:|---:|
| Older sodium | #E7BA79 | .8 | .006 |
| Warm-white LED | #EFDFC4 | .9 | .008 |

These are generic appearance families. Known lamp types override the fallback; do not force Chicago to sodium or Denver to LED. Unknown fixtures use an inferred warm-white generic style. Demo pole height 8 m and spacing 32 m are not new mapped placement rules.

Pool semi-axes **5 / 2.8 m**, major axis along road. In local footprint coordinates u/v, r²=(u/5)²+(v/2.8)² and K=max(0,1−r²)². Add owning lamp intensity × K to the receiver's diffuse lighting once. Peak combined overlap Erel ≤.012. Carry the same field across sidewalk/road materials and their normals; maintain a soft falloff and unlit intervals.

Clip fields to exposed eligible receivers using supplied visibility/occlusion or static precomputed eligibility. If eligibility is unknown, restrict to the immediately supported ground region; do not paint light through houses. The analytical mask is a cheap lighting approximation, not a real light that casts moving shadows.

Each receiver uses either the actual-light contribution or its analytic proxy for that source, never both. Apply source/overlap clamping once.

At most **two actual nearby unshadowed local lights globally**, shared with porches and live vehicles. Those can shade lower crown normals and trunks. Underlight reach ≤7 m; additional lower-crown contribution Erel ≤.0018. Distant tree proxies only affect preselected exposed faces. No foliage emission, neon lime crowns or whole-tree glowing rims.

Clean-air halo radius: **4 px at 5 m / 2 px at 20 m / 1 px at 40 m**; rain multiplier 1.5, absolute cap 6 logical px. Peak composite weight .10. Use the existing energy-normalized bloom, not an additive halo plus bloom. Off/hidden lamps have no halo. If bloom is unavailable, keep the small emissive core. No volumetric cone pass or fog beam in clear air.

Near cap 12 analytical pools, at most two candidates per receiving region; aerial cap 24 aggregated pools. These share one material evaluation and obey the existing budget, not one pass/draw/light per lamp.

## 5. Full moon and moonless

Keep the actual observer/time Moon direction, phase and horizon visibility. Fallback angular disk diameter **.5°**, never a giant enlarged decorative Moon. Phase p uses 0=new, .5=full, with I=(1−cos(2πp))/2; actual elongation is preferred.

Let q=I^1.3 × max(0,sin(moonElevation)) × cloudDirectTransmittance. Peak moon direct **.0015 Erel**, ambient increment **.001 Erel**, both scaled by q; chromaticity **#D5DDE7**. These are deliberately stylized readability values, not real photometry.

**Compatibility decision:** if adopted, these values replace live-world-v1's optional ≤.08 noon moon fill and any duplicate weather moon fill. They never add on top of those scalars. Moonless/below-horizon conditions remove both lunar terms, while base sky/artificial fill remains.

Only one directional shadow map exists. Night Moon ownership replaces Sun ownership; do not render a second map. Final lunar shadow luminance reduction ≤18%; fade shadows between Moon elevation 5–10°, opposite actual azimuth. Geometric length is height × cot(elevation); cap/fade footprints past 30 m rather than invent a higher Moon. Cloud attenuation affects disk, direct light and shadow together. Moonless has contact/ambient grounding but no lunar-direction cast shadow. Artificial lamp shadows shown incidentally in artwork are not authorization for extra shadow maps.

## 6. Night rain and snow

Reuse rain-v1's per-material wetness response, **≤12% hard-ground linear darkening**, once. Do not stack ground, weather and rain darkening. Rain has cool diffuse ambient plus warm, broken lamp-aligned streaks. Reflections belong to visible/eligible sources and are attenuated by source on/off, range, wetness and snow coverage.

Keep the existing **six reflection fields globally**, ≤two per local region. Length **1.2–4 m**, width **.10–.35 m**, night mix coefficient ≤.24, three breakup gaps. Aerial length ×.4 and coefficient ×.65; fade fields over 25–45 m. Up to **two of those same six** may depict lit-window reflections, only within 6 m of a supported opening, with .4× lamp-field coefficient. Skip a reflection when receiver/direction is unsupported. No emissive road without a source; no SSR, planar capture or extra world-reflection pass.

Snow fresh **#E4E9EB**, cool shadow display reference **#C3CDD6**, compacted **#ADB9C4**, bank **#DDE2E3**, dirty bank **#91958D**. Snow remains matte (roughness .88), non-emissive; bounded ambient bounce ×1.25 and exposure −.30 EV prevent white clipping. These are weather modifiers on the same night lighting, not three stacked brightness boosts. Snow hides underlying paving and wet fields where covered. Exposed cleared wet strips may still reflect.

Accumulation/clearing history governs snow, footprints and banks. The sheet's clear corridors/banks are demo assumptions, not a consequence of a snowfall label. Snow albedo can keep the world readable even with a moonless/overcast sky. Reuse rain-v1's precipitation counts and geometry caps; no new particle budget.

## 7. Phone hierarchy and performance

At **5 m**, window partitions/curtains, lamp pools and lower-crown light can read. At **20 m**, reduce room detail to grouped warm planes and keep pool falloff. At **40 m**, preserve separated warm points, roof/crown silhouettes and path boundaries; cull subpixel decoration. In aerial, use sparse facade emission and pool groups; do not light roof planes as windows or enlarge houses/fixtures.

The [v2 §8.1 budget](/Users/robwoodbury/Desktop/world-engine/docs/proposals/visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) governs:

| Existing bucket | Allowance | Night effects charged here |
|---|---:|---|
| Base opaque | 4.25 ms | Sky gradient, existing window emission and world materials; shared live sky |
| Sun/character shadows | 1.45 ms | Reused directional Moon map, existing bounded contact |
| Ambient/crown shaping | .15 ms | Night fill and existing crown/contact shaping |
| Surface pattern | .25 ms | Curtain masks and snow exposure alongside ground patterns |
| Near geometry | .35 ms | Existing snow caps/banks only; no new night geometry |
| Wet/local light | .35 ms | .22 wet/puddles + .10 pools/reflection fields/local lights + .03 optional ripples |
| Particles | .20 ms | Existing rain/snow allocation |
| Post total | .90 ms | .15 grade/composite + .35 shared bloom + .40 optional aerial blur |
| Reserved margin | 2.10 ms | Retained |

**7.90 ms planned content + 2.10 ms reserve = 10 ms**, 60 fps target; 400k main triangles, 150k shadow triangles, 100 draws. Subtargets are unmeasured and can require reducing other effects. No per-window real lights, extra shadow maps, per-lamp passes, transparent canopy layers or volumetric beams.

Degrade optional ripple/window-reflection fields first, then pool count/unresolved halos, aerial blur, particle density and distant detail. Keep path/material readability through the common calibrated fill/grade rather than extra character spotlights. Validate on actual iPhone 13-class hardware, iOS26+, with ten-minute street/aerial wet/snow transitions, actual drawable dimensions, worst GPU frame, p95, frame stalls and thermal behavior. Neither artwork nor the desktop review page establishes a GPU pass.

## Review checklist and open questions

1. Does every lamp/reflection belong to a supported source, and do disabled lights remove both cues?
2. Are window schedules deterministic, clearly simulated and stable after replay scrubbing?
3. Does moonless remain readable while full-moon shadows follow the actual source and reuse the map?
4. Are dry pavement, wet asphalt and matte snow visibly distinct at phone width?
5. Do both adapters agree on Erel/Lrel calibration and actual drawable halo size?

Remaining decisions: supply lamp-type/occlusion data or keep explicit inferred demo profiles; select a measured light-pollution dataset for directional glow; calibrate source emission and exposure in the chosen renderer; decide if Moon shadows merit their rendering cost at low elevation. These do not block the reference pack.

## Saved-image limitations

Five raster sheets were freshly generated with the built-in image tool; sheet 03 received one targeted dry-surface/LED/halo edit. Other sheets use their initial generation. Fine grain, interior furniture, exact window counts, invented waterfront context, sky positions and shadows are not implementation truth. Sheet 02's wet setting is an illustrative house-light comparison; rain values govern its wet response. Sheet 05's aerial “5/20/40 m” captions are conceptual detail labels, not calibrated camera altitude or slant-range measurements. The review gallery shows unmodified source pixels through CSS crops and is not an engine preview. Exact color diagrams were authored separately and are not substitutes for the scene illustrations.

All saved deliverables are inside this folder. No code or reference packs were changed; no git commands.
