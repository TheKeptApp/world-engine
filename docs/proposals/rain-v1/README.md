# WorldEngine rain readability pack — Style B
**6 October 2026 · Proposal only · Renderer-neutral · Phone-size review**

Rain should be identifiable through three independent cues: wet material response, shallow water reflecting its surroundings, and sparse moving precipitation. At dusk/night, warm lamp streaks on wet asphalt supply a fourth cue. Merely lowering brightness makes a scene gloomy; it does not establish rain.

This pack follows [ground-v1](../ground-v1/README.md) and [vegetation-v1](../vegetation-v1/README.md): construction sheets, exact data, procedural-mask guidance and prompt lineage. [rain-values.json](rain-values.json) governs values. Generated artwork supplies appearance references, not measured geometry, actual weather, shader output or GPU results.

All numeric settings are **authored proposal assumptions** except explicitly cited repository constraints and verified physical principles. Reviewed sources on **2026-10-06**. No production implementation is changed.

## Sheets
| Sheet | Purpose |
|---|---|
| [01 Wetness states](images/01-wetness-states.png) | Damp, light rain, steady rain, soaked and drying; consistent scene/lighting |
| [02 Stain versus water](images/02-puddle-stain-vs-water.png) | Side-by-side 5 / 20 / 40 m cues plus stable receding-water shape |
| [03 Rain at distance](images/03-rain-phone-distance.png) | Street-distance hierarchy and aerial simplification |
| [04 Rain at dusk/night](images/04-rain-dusk-night.png) | Warm lamp streaks over cool wet asphalt; aerial inset |
| [05 Snow stages](images/05-snow-phone-stages.png) | Falling, patchy, covered, cleared and aerials |
| [06 Phone targets](images/06-phone-rain-snow-acceptance.png) | Street and steep aerial rain/snow references |
| [07 Exact substrate chart](images/07-exact-wetness.svg) | Deterministic linear-light darkening swatches, not AI-estimated pixels |
| [Phone review page](index.html) | 390 CSS px panel crops, full sheets and exact surface values |
| [Image prompts](image-prompts.json) | Built-in generation prompts and single-edit history |
| [Manifest](image-manifest.json) | Dimensions, hashes and limitations |
| [Verification](verification.md) | Arithmetic/file checks and limits |

Open index.html in the built-in preview or desktop browser; each selected panel is displayed at up to 390 CSS px wide. Inspect at actual phone size, without zooming into a whole board. The boards' tiny annotations are not required to read the scene. CSS crops are presentation views of the original images; no generated bitmap was modified with pixel-processing code.

## 1. Wetness: exact surface darkening and sheen
Darkening is **linear RGB/luminance reduction relative to the dry substrate**, not sRGB byte subtraction or final-screen brightness. Decode sRGB, multiply linear RGB by (1−darkening/100), then shade and tone-map. Sheen is independent: a maximum synthetic reflected-sky mixing weight at grazing view, not metallicness, alpha or raw specular intensity. Roughness is perceptual roughness; adapters must calibrate their response.

Each cell below is **darkening % / sheen strength**:

| Surface | Damp | Light rain | Steady rain | Soaked | Drying |
|---|---:|---:|---:|---:|---:|
| Concrete | 4 / .05 | 8 / .12 | 10 / .20 | 12 / .27 | 6 / .08 |
| Asphalt | 5 / .06 | 9 / .15 | 11 / .25 | 12 / .32 | 7 / .10 |
| Brick | 4 / .04 | 7 / .10 | 10 / .17 | 12 / .23 | 6 / .07 |
| Lawn | 3 / .01 | 5 / .02 | 7 / .03 | 8 / .04 | 4 / .015 |
| Roof | 2 / .03 | 4 / .06 | 6 / .10 | 8 / .14 | 3 / .04 |

Exact per-row roughness values live beside these in JSON. Concrete/asphalt soaked roughness starts at .45; brick .49, lawn .86, roof .60. Keep grass diffuse with small broad highlights; a wet lawn is not a glass carpet. Roofs shed water; do not stamp standing-water masks on sloped roofs. Read mapped roof material when known; these values are a generic nonmetallic roof fallback.

**Repository compatibility:** weather-v1 §4 caps exposed hard-ground darkening at 12%. This pack keeps that cap. ground-v1's generic −10% light-rain and −15% soaked prescriptions become the per-surface table **if this proposal is adopted**. Replace the existing darkening once; do not stack ground × weather × this table. The rows are appearance fixtures, not a rain-rate-to-wetness shortcut. Current rain and accumulated wetness remain separate environment channels.

Damp/soaked can exist without current rain. Drying has zero precipitation and reduced standing water, but wetness decays through the existing reservoir/history model rather than an eight-second atmosphere fade. Interpolate data rows continuously; never flash five discrete presets.

## 2. Puddles: bright water, not holes
**Verified physical principle:** water is a dielectric; specular reflection returns incident radiance along the reflected direction, with angular Fresnel dependence. PBRT gives water IOR 1.333. [PBRT, Specular Reflection and Transmission](https://pbr-book.org/4ed/Reflection_Models/Specular_Reflection_and_Transmission). Normal-incidence air/water F0 is approximately 0.02037 using ((1.333−1)/(1.333+1))².

**Appearance inference:** under a bright overcast sky and a low street camera, a smooth puddle can reflect brighter sky radiance than the adjacent dark wet pavement. This is not universally true: tree/roof reflections, bright concrete and night can reverse the contrast. Do not impose a white emissive puddle floor.

Proposal: blend the shaded substrate with the current reflected-direction sky using k=.12+(.55−.12)(1−|N·V|)^5, bounded by exposure. This is a **stylized reflection proxy**, deliberately stronger than normal-incidence physical F0; do not describe the .12 coefficient as measured Fresnel. Either use this proxy or calibrate a BRDF/environment approach, never add both. Puddle roughness .18, no metallic water. Aerial scales proxy strength by .65; the more downward view gets less sky reflection.

Daylight phone fixture goal: broad water region roughly +15–45% luminance above adjacent shaded wet asphalt, with no requirement that every pixel/pale-concrete puddle meets this. At night follow actual sky/lamp values; no daytime floor.

- Long, shallow connected gutter lobes read better than isolated black circles. Proposed width .25–1.5 m, length .4–4 m, edge softness .03–.10 m. Keep pools flush; no crater geometry or black outline.
- Confine pools to supplied drainage/low areas, or label inferred demo depressions. Never conclude that a real street is flooded from a weather label.
- Cap eligible wet pavement coverage at 7%, ≤12 near pool shapes / ≤24 aerial groups. Coverage is within eligible regions, not seven percent of the entire city or screen.
- Damp halo width .04–.16 m uses the same wet substrate; no added darkening beyond its cap.
- During drying, increase a stable mask threshold so small connected lobes shrink first. Fade the sky component with water presence, leaving a damp footprint, then return substrate roughness/albedo. Keep seeded identity.
- **Optional extension:** ≤6 analytic ripple centers, ≤2 rings each, .55 s life, radius .03–.18 m, opacity .16; within 12 m and only on pools ≥12 CSS px across. Stop new rings when rain stops; existing rings expire. Skip unresolved rings rather than enlarge them. Rings modify the reflection/normal in the same wet material pass; no simulated wave field.

The 5/20/40 m comparison preserves the distinction: near water may have rings; medium water is bright broad shapes; far water is a quiet silver gutter grouping. A dark stain remains a separate material feature and should not acquire water reflection merely to make it attractive.

## 3. Falling rain, splashes and haze
Rain must be visible against shaded foliage/road without obscuring the route. These are **proposal starting values**, not real raindrop measurements:

| State | Street pool count | Aerial pool count | Opacity | Transparent screen-area cap |
|---|---:|---:|---:|---:|
| Light rain | 180 | 90 | .26 | 2% street |
| Steady rain | 360 | 180 | .34 | 4% street |
| Soaked + active heavy rain fixture | 540 | 270 | .40 | 6% street |
| Damp / drying without rain | 0 | 0 | — | 0% |

Particle **pool count is not visible on-screen count**. Aim for 12–45 concurrently readable streaks in the 390×844 phone crop; tune emitter placement/culling and projected alpha coverage, not merely increase count. A soaked dry interval may have zero rain.

Use a 30×20×30 m camera-local box, downward speed 12 m/s, wind drift .2×wind capped 2 m/s, from weather-v1. Physical streak length .07–.24 m. Starting near projected length 5–12 CSS px, mid 3–7, far 1–3; width .65–1.1 CSS px. At 3× drawable scale these correspond to 15–36 and 1.95–3.3 drawable px near. Projection/motion is authoritative; clamp screen extent and fade rather than stretch distant drops into giant scratches. Fade 20–35 m, clip closer than .6 m, depth test, suppress under supplied shelter.

Aerial counts halve, opacity ×.7, length 2–5 CSS px, alpha area ≤3%. Particles remain camera-local, not geographic rain strokes across city blocks. At high altitude an honest minimal mode may omit them and rely on atmosphere/wet surfaces; require a rain indicator in a host weather strip if the precipitation cannot be visually resolved.

**Splashes are excluded by the current weather baseline.** The user-requested proposal adds an optional measured extension: ≤12 concurrent impacts within 1–8 m, .22 s life, .025–.06 m radius, .015 m apparent height, .22 opacity. Two simple arcs at stable hard-surface anchors; no collision search per falling drop, no droplets everywhere. Pool and splash logic uses rain-active/exposure/material eligibility, not fictional evidence of runoff. Default off until performance/readability checks pass.

**Haze reuses weather-v1's one fog term:** rain tint #8F9FAA blended .22; full-intensity start ×.40/end ×.50, interpolated once by intensity. Do not also multiply a cloudy reduction. Controlled overcast-day baseline 180/900 m gives 72/450 m at full rain; this baseline is a preview assumption. Night baseline 140/600 gives 56/300. Aerial baseline 900/2500 gives 360/1250. Valid source visibility may cap these following weather-v1 floors and ordering. The immediate 5–40 m path stays identifiable; missing backdrop is not a reason to invent denser rain haze.

## 4. Dusk/night: wet-road light streaks
Keep the cool world readable with existing fill; turn on stable lamps/windows per existing policy. A wet road does not become an unlit black void.

Reuse R5: ≤6 fields globally, ≤2 per local region, ≤2 real nearby unshadowed lights. Each streak belongs to a visible/supplied lamp and is clipped to wet asphalt/pool regions. Starting length 1.2–4 m, width .10–.35 m; 3 seeded breaks, tapered/soft boundaries; opacity .18 dusk/.24 night. Color follows the lamp, e.g. #E7BA79. Fade 25–45 m; gate by wetness and non-snow exposure.

Orient the stylized field from the lamp's ground projection toward camera azimuth, not a fixed world north stripe. Source energy decays with distance and follows lamp on/off. It is a synthetic reflection cue, not an additional emissive road light or a guaranteed true mirror. Aerial length ×.4, opacity ×.65. No unsupported warm streak floating beneath an invisible light. Preserve road markings and crossings.

## 5. Snow version
Falling snow and accumulated snow are separate. Counts for flurry/steady/heavy: **60/180/270** street, **30/90/135** aerial; ≤300 flakes. Diameter .015–.045 m, projected 1–3 CSS px; .60 opacity; 1.2 m/s downward, .35×wind drift capped 3 m/s. Alpha area ≤4%. Individual flakes are simple soft discs, not textured crystalline stars.

Controlled stages: trace .05, patchy .55, blanket .90, melting .35 **eligible area fraction**, using opaque snow and the existing stable .4–1.2 m /2–5 m mask scales. A .55 state is not “55% transparent white everywhere.” Northern dormant tan shows through gaps. Unknown history remains unknown; winter/temperature alone supplies no blanket.

Fresh #E4E9EB, cool shadow #C3CDD6, compacted #ADB9C4, bank #DDE2E3, dirty lower bank #91958D. These are authored palette defaults, shaded through real lighting. They are not measured snow colors. Suppress substrate wet streaks/joints beneath opaque snow. Optional roof caps ≤24 within 20 m, .02–.05 m thickness, within existing geometry reserve.

Plowed banks require supplied clearing history or explicit demo state: ≤8 ridge sections, .15–.45 m height, .3–.8 m width, ≤2k total triangles. Dirty band only bottom 5–15% height. Place beside actual clear corridor, preserving ramps/crossings/sight lines; no fabricated plow route. Physical displacement, footprint trails and banks remain Stretch. Aerial retains broad white coverage, dark cleared roads and bank bands, removes granular lumps and impact details.

## 6. Representation and budget
**Verified repository constraints:** v2 §8.1 is 7.90 ms planned content +2.10 ms reserve =10 ms GPU maximum, 60 fps target on iPhone 13-class hardware, iOS 26 minimum. Existing surface patterns .25 ms, wet/local lights .35 ms, particles .20 ms, near geometry .35 ms. [Visual v2](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md). Rain/snow counts and six streak/two local-light limits follow [weather-v1](../weather-v1/WorldEngine-Weather-Spec-v1.md).

Proposed internal subdivisions: wet material/puddles .22 +lamp fields .10 +optional ripple .03 =.35 ms; precipitation .17 +optional impact .03 =.20 ms. These are **unmeasured acceptance targets**, not established timings. Snow masks share .25 with lawn/seams; banks/caps share .35 with existing near geometry. Optional effects stay off if their combined bucket cannot pass; freed allocations remain margin.

| Feature | Phone implementation proposal |
|---|---|
| Wetness, puddle shape, drying, lamp fields | Existing opaque material; shared low-frequency masks/analytic fields; no stacked alpha planes |
| Procedural mask alternative | One 256×256 RG8 abstract mask atlas, ~128 KiB base/~171 KiB with mips; no photo albedo |
| Rain/snow | One batched/instanced depth-tested simple-quad path per active type; evaluate alpha area as well as count |
| Ripple arcs | Fixed-size analytic center list in existing wet material; near-only; skip first when budget tight |
| Splashes | Shared impact instance/mask path, fixed anchors, no per-particle collision; optional |
| Banks | Opaque simple ridge geometry, broad LOD; no snow-grain tessellation |
| Aerial | Broad state masks, fewer particles, no tiny rings/splashes; steep camera sees no horizon |

Combined weather still has ≤600 particle slots, with ≤12 airborne leaves taking slots; never add 600 rain +300 snow +splashes as independent allowances. Impact instances count against combined effect work and rain slots if represented as particles. No per-drop lights, SSR, planar reflections, world cubemap captures, photo textures or new volumetric pass.

Measure steady rain and snowfall plus dusk/aerial transitions for ten minutes on physical device at fixed drawable resolution. Record max/p95 GPU, stalls/thermal state and feature-toggle deltas. Reduce optional impacts/ripples first, then particles/alpha coverage, then lamp fields and aerial detail. Do not quietly spend reserved 2.10 ms on new effects.

## 7. Review and acceptance
At 390 CSS px, then 320 px, compare dry/wet under **identical lighting/exposure**. At 5/20/40 m representative content distances, verify:
1. Path remains visible but clearly wet; dry-to-wet is not merely a lighting change.
2. Correct puddles read shallow water before labels are read; wrong circles read stains/holes.
3. Moving rain is visible against dark world areas without a white screen curtain.
4. Night streaks connect to lamp sources; dry streets and snow-covered regions have no streak.
5. Aerial reads broad surface/weather state without near-camera scratch clutter.
6. Snow coverage is opaque/patchy, route edges clear, supplied banks never obstruct accessible crossings.

Artwork cannot pass animated readability, parity or budget checks. No physical-device results are claimed.

**Known art limits:** Generated panels may retain fine pavement speckle, roof lines, excessive leaf/branch detail, oversized splash rings, too-long streaks, literal sky shapes and more blanket snow than a printed label implies. Exact numeric JSON wins. Sheet 01/06 received one correction each for simplification/aerial framing. The “5/20/40 m” labels are content-distance studies, not calibrated camera measurements; independently generated sheets need not have pixel-identical geometry. No real site/weather/geographic reconstruction is asserted. Copy broad hierarchy, not forbidden detail.

**Open questions:** Which renderer mapping reproduces roughness/sheens reliably? Does daylight contrast survive the real tone mapper? Can native particles hold readable subpixel width without flicker? Which optional impact cue has enough benefit to justify its cost? Is drainage data available, or should inferred puddles remain minimal? How will actual clearing history reach environment state?

Files and prompts are fully local to this proposal; the built-in image tool's own cache supplied the raster outputs, copied here. No git commands or production edits were used.
