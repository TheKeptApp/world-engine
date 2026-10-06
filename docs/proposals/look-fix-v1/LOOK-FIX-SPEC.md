# WorldEngine Look Fix Pack v1

**6 October 2026 · Proposal only · P2 / 5A handoff**

The first goal is a bright, richly grounded ordinary day; the second is weather that reads without a label. Preserve true geography and celestial directions. Sky spectacle comes after those fixes.

## 0. Evidence, scope and acceptance

**Observed in repository, reviewed 2026-10-06:** [latest look-loop](../../lookloop/latest/summary.md) reports 27.5/50, 78% concept parity, 0/17 passing; ground is the largest recurring weakness. Its latest ordinary street is **107.2/255**, improved from 87.7, still below 128–156.6 targets. Light-rain street is 102.4. Do not tune from the older 88 measurement alone. A brighter aerial can still fail because its histogram is narrow and its ground is uniform.

[Calibration](../../lookloop/calibration.md) records concept mean 35.2/50, with defects including repeated crowns and wrong sun bearings. [Building gate](../../buildings/gate-5b.md) reports 16/25 and near-black roof shading. [Phase 5A report](../../m3/report.md) documents wet surfaces, fog, snow patches, sway, cloud/sky work and transparent-tree optimization already present. These are evidence of implementation, not evidence that the look passes. Diagnose missing inputs, strength, masks, LOD and tone mapping first.

**Owner decision:** use per-view concept parity as the gate. This proposal does not edit [GRADING.md](../../lookloop/GRADING.md). Retain its criterion floors, geography and hard-fail safeguards; report the older 40/50 threshold as an aspiration alongside parity. Freeze a reviewed target score for each view. The historic 35.2 average is not the score of every new concept.

**Status convention:** repository observations above are verified against local documents, not independently reproduced. All numerical visual settings, densities, labor estimates and score gains below are **proposed tuning assumptions**, unless explicitly described as calculated. Regional choices refine existing [visual-v2](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md), [experience-v1](../experience-v1/WorldEngine-Experience-Spec-v1.md) and [Chicagoland/Miami](../regions-chicagoland-miami/WorldEngine-Regions-Chicagoland-Miami-Spec-v1.md); they are not measured planting inventories. Synthetic weather is not a claim about a historical day.

P2 owns buildings, yard/ground geometry, placement, stable seeds and LOD assets. 5A owns their rendered materials, light, weather, atmosphere, sky and post. Cost labels mean **low:** fit an existing material/instance batch; **medium:** measurable geometry, shading or fill; **high:** threatens the frame budget. They are not device timings.

The supplied video screenshots inform only rich color, readable night and sky contrast. They are neither image inputs nor repo assets. No engine files, grading rules or other proposals are changed.

## 1. Ground and yards

### 1.1 Lawn palette and variation — P2 placement + 5A material · Low

All hex colors are **sRGB base-color swatches under neutral reference illumination**, not already shaded pixel colors. Decode to linear before interpolation and lighting. Choose one endpoint pair per lot, then interpolate deterministically; do not choose a new random color per frame. The ranges are permissible endpoints, not a prescription to cycle visibly through every hue.

| Region | Spring | Summer | Fall | Winter, exposed ground |
|---|---|---|---|---|
| Denver | #82954B–#A5AD65 | #788743–#9D9B5D | #98945D–#B7AA78 | #A19A78–#BBB095 |
| North Shore | #71944F–#91AD69 | #648146–#8C9C59 | #858949–#ABA16A | #8D8A68–#ABA58A |
| Lakeview | #738D50–#92A46A | #6F804D–#929663 | #91905E–#A9A276 | #918D73–#ADA78F |
| Miami | #688A4E–#83A25F | #527A45–#789253 | #64864B–#879A5D | #758B55–#969E6A |

Miami remains predominantly green; its winter row is a drier palette, not dormant northern turf. Climate and observed vegetation override calendar defaults. Snow masks existing ground; it does not replace the regional base palette. Denver unirrigated/drought patches can use #B1A172–#C3B18A on 10–35% of eligible lawn; never infer irrigation per home as fact.

Stable lot seed = world seed + profile/version + mapped feature ID + purpose salt. For an inferred partition, use its stable parent and quantized world coordinates; store provenance. Between adjacent lots, aim for **4–10% value difference**, maximum 8° hue and ±6 percentage points saturation, bounded by the palette. Avoid alternating stripes of different houses.

Within a lawn, use **3–5 broad patches**, characteristic diameter 2–6 m, value variation ±3–6%, transition width 0.5–1.5 m. Use vertex color on low tessellation or analytic object-space fields; no image-based grass texture/noise. Never multiply per-lot and per-patch variation past the palette's value bounds.

Mowing: optional 2.5–4 m bands, contrast 2–3%, at most half of suburban lawns, zero on uncertain/public natural ground; alternate no more than 4 bands. Wear: one or two 0.3–0.7 m wide low-contrast patches **only along established access or plausible eligible entry paths**, ≤5% of lawn. Do not invent a diagonal desire path through private lots. Cut edges read as 3–6 cm height / 4–8 cm darker band within 20 m; bake to color beyond 50 m. No dense individual grass blades.

### 1.2 Beds, shrubs and access — P2 · Medium near; Low after batching

Foundation beds 0.6–1.2 m deep, never obscure doors, steps, basement windows or access. Soil/mulch families #5A4B3D–#79634D, value variation ≤5%; one flat shape plus tiny contact edge, no noisy chips. Shrubs are irregular spreading cushions, upright sprays, loose branching forms or low hedges. Avoid identical spheres.

| Form | Height × width | Spacing | Shape variation |
|---|---|---|---|
| Low perennial/cushion | 0.25–0.55 × 0.4–0.9 m | 0.6–1.0 m | width ±20%, height ±15%, 3 silhouettes |
| Medium loose shrub | 0.6–1.1 × 0.8–1.5 m | 1.1–1.8 m | lean ±8°, asymmetric top |
| Upright shrub | 1.0–1.7 × 0.5–1.0 m | 0.9–1.4 m | narrow open crown |
| Hedge segment | 0.7–1.2 × 0.5–0.9 m | continuous segment ≤6 m | uneven top ±0.08 m; gaps at access |

Use two foliage families within a bed, not a rainbow: cool #405D40–#59794E and warm #708044–#879452. Flower accents ≤3% of planted-bed area in local bloom windows; zero in northern January.

Typical **eligible** lot assumptions below are ceilings/priors, not quotas. A building footprint is not a legal parcel. With no reliable parcel/access boundary, use a conservative frontage envelope clipped to known green space and building buffers; leave uncertain private edges empty. Count mapped features first, then subtract them from inferred targets. Every inferred object carries source=inferred, profile, seed, rule version and confidence; mapped features retain their position.

| Region / working lot | Lawn / exposed open area | Foundation bed area | Shrubs | Yard trees, excluding mapped street trees | Street-tree spacing | Parkway |
|---|---:|---:|---:|---:|---:|---|
| Denver, 15 × 38 m | 35–60% eligible unbuilt area | 8–18 m² | 4–8 | 0–2, mean 1.0 | 14–20 m | 1.2–2.4 m if supported |
| North Shore, 18 × 45 m | 50–70% | 12–26 m² | 7–12 | 1–3, mean 1.6 | 13–18 m | 1.5–3 m |
| Lakeview, 7.6 × 38 m | 0–20%; often no front lawn | 2–6 m² | 1–4 | 0–1, mean 0.3 | 15–22 m | 0–1.8 m / tree pit |
| Miami, 18 × 35 m | 30–55% | 10–22 m² | 6–12 | 1–2 broadleaf; palm form only where eligible | 16–24 m | 0–2 m |

Lakeview: stoop, tiny setback, real gangway and rear access dominate. No suburban lawns over paved forecourts; no front driveway invented for an alley-served three-flat. North Shore garage access follows mapped street/alley/drive context, not a universal front garage. Denver walks 1.0–1.5 m, suburban entry walks 1.2–1.8 m, Lakeview 0.9–1.2 m where clear width exists; public sidewalks normally 1.5–2.4 m, but tags/measured geometry win. Single drive 2.7–3.3 m, two-car 5–6 m only if supported. Concrete #BDB7A7–#D3C9B7, old concrete slightly cooler; asphalt #515967–#666C73. Paving is planar with restrained joint geometry, no authored surface imagery.

Placement constraints: building buffer 0.25 m minimum for low beds; trunk ≥2 m from facade, ≥0.75 m from pavement edge, ≥1.5 m from driveway edge; do not place into water, roads, mapped paths, parking, rail, sports fields or sight triangles. Known accessibility clear width overrides dressing. Clip at uncertain boundaries rather than move mapped objects.

### 1.3 Leaf litter — P2 placement / 5A season mask · Low

Northern **fall only**, weighted by canopy/phenology; not a perpetual tree-base carpet. 1–3 patches per eligible deciduous tree, radius 0.4–1.2 m, covering 2–8% of nearby exposed ground; patch colors #AA753F, #BD914F, #8C7145. Near camera, 12–30 simple leaf marks per patch within the existing 6.4k near-leaf triangle allocation. Fade leaves into broad patch color by 30–50 m. Zero litter and autumn crowns in the January fixtures; no remaining orange flecks under winter trees. Miami uses occasional neutral organic bed color, not a northern fall event.

### 1.4 Distance contract

| View | Must read | Remove |
|---|---|---|
| Street, 0–30 m | lawn edges, bed/soil boundary, shrub forms, 2–3 paving families | fine random texture |
| Postcard, 30–150 m | different lot tones, bed silhouettes, purposeful access, distinct tree profiles | individual leaves and turf blades |
| Aerial, 150–600 m | green parcels versus paving, broad warm/cool patches, crown height/width groups | mow bands, curb microgeometry, leaf litter |
| Context, >600 m | real land-use/color masses and silhouettes | private-yard inference and detail |

Pass if **groundRichness ≥3 and adGroundRich ≥3**, at least three distinct ground/planting layers are visible in an eligible foreground, grass does not span roads/yards indiscriminately, Lakeview remains dense, and no invented detail changes geography. Reference images ground-01…04 show intent, not a survey.

## 2. Lighting bible

### 2.1 Camera, math and measurement — 5A · Low

The 12 lighting concepts keep one **illustrative** postcard composition: Sloan's Lake north-shore public trail, observer 39.7528379, −105.0467978, 1609 m; eye 1.65 m, heading 100° true, down-pitch 3°, vertical FOV 50°, 16:9. Path ahead, lake right, neighborhood left. No western mountains or sunset disk ahead. This follows experience-v1's camera, but generated geometry/framing is not a surveyed render or pixel-exact camera implementation.

Sun values in [lighting-fixtures.json](lighting-fixtures.json) are calculated from the repository SolarPosition formula, geometric/no refraction. Always derive light and shadows from the same environment timestamp/observer. Let elevation be e and azimuth A: shadow bearing=(A+180) mod360; on flat ground length/height=cot(e) for e>0. Near e=0, use the real low sun and bounded shadow range; never rotate or shorten the world-space direction for a prettier picture. Below horizon, solar direct light=0.

Use a 2 m diagnostic pole in a separate engine test capture: compare base-to-tip world direction to fixture within 1°, length within 5% for e≥5°. Remove it from final artwork. Slope changes ground intersection; the flat-plane formula alone cannot validate a sloping street.

All frame luminance targets below use the look-loop's **encoded sRGB** convention: Y8=0.2126R+0.7152G+0.0722B, channels 0–255. This is not physical linear luminance. Report whole-frame values exactly as analyze.py does; optionally report a second scene/foreground ROI, labelled and held fixed. Do not compare an ROI mean with the whole-frame target. Attribution is included in whole-frame measurement. Histogram “intersection” is not a brightness ratio.

Exposure numbers are **relative EV adjustments** to a frozen clear-day reference exposure E0, not absolute camera EV or measured lux. Apply 2^EV once in linear light before tone mapping. Key:fill means direct-to-ambient contribution on an upward neutral witness patch. Adjust fill and shadow hue before exposure; do not brighten already correct sky to rescue a black roof.

### 2.2 State targets — 5A · Low, shadows Medium

Colors are artistic RGB light tints; Kelvin would imply a physical white balance these tints do not represent. Mean/P5/P50/P95 values are target centers with mean tolerance ±10 and percentile tolerance ±12, unless noted. Saturation is whole-frame mean HSV-S on 0–255, tolerance ±12; fog/snow/night legitimately lower chroma. Preserve localized material color rather than saturate every neutral pixel.

| State | Direct / sky-fill tint | Key:fill | EV offset | Y mean; P5/P50/P95 | Mean S |
|---|---|---:|---:|---|---:|
| Morning | #FFE2B6 / #99B8E5 | 2.0 | +0.10 | 135; 45/138/222 | 88 |
| Midday | #FFF3DA / #9CBDE4 | 2.4 | 0.00 | 145; 55/148/226 | 90 |
| Ordinary 15:30 | #FFE8C6 / #99AFE0 | 2.2 | +0.10 | 140; 48/143/224 | 90 |
| Golden hour | #FFC17B / #969BD0 | 2.0 | +0.15 | 130; 36/128/222 | 94 |
| Blue hour | none / #788BBE | 0 | +0.35 | 88; 25/79/167 | 86 |
| Overcast | #E7EDF1 / #B2BED0 | 0.15 | +0.20 | 137; 64/139/207 | 54 |
| Light rain | #DDE5EF / #9FACBF | 0.10 | +0.25 | 126; 48/126/198 | 64 |
| Storm | #B9C5D6 / #8494B3 | 0.05 | +0.25 | 96; 29/91/172 | 60 |
| Fog | none / #BDC9D1 | 0 | +0.10 | 147; 78/150/194 | 32 |
| Snow, overcast | #EEF1F6 / #ADBBD8 | 0.15 | −0.10 | 166; 63/181/230 | 32 |
| Moon night | moon #CEDAFF / #6574B0 | 0.35 | +0.45 | 57; 18/45/109 | 94 |
| Moonless night | none / #596497 | 0 | +0.45 | 43; 14/34/84 | 88 |

Day histograms must have a broad inhabited midrange, not one grass spike. Fog narrows contrast through distance, not a white foreground veil. Snow shifts mass toward 180–225 without losing roof/lawn/street separation. Night is dark by distribution: ≥65% of pixels below Y=80, with small warm highlights. Do not make every night pixel uniformly blue and bright. In all states, ≤0.1% true scene pixels at Y≤3; whites Y≥250 ≤0.5% except a small visible source/glitter peak. Distinguish meaningful deep recesses from whole black trunks.

### 2.3 Shadows, lifted color and distance

“Lift” here is a **rendered shadow-to-lit neutral patch ratio in linear luminance**, achieved through fill. It is not an additive sRGB pedestal or emissive material. AO may reduce local ambient another 10–20% within 0.15–0.4 m of a contact; never darken entire yards.

| State | Solar height multiplier L/H | Lift ratio | Shade tint | Contact-to-distant penumbra target | Clear-air fade start → 50% / cap |
|---|---:|---:|---|---|---|
| Morning | 2.289 | 0.32–0.40 | #697DAB | 2–4 screen px; grow physically | 250→1600 m / 35% |
| Midday | 0.331 | 0.28–0.36 | #7184AC | 1–3 px | 350→2200 / 30% |
| 15:30 | 0.716 | 0.30–0.38 | #6E7FAC | 1–3 px | 300→1800 / 35% |
| Golden | 8.818 | 0.33–0.43 | #7777AA | 2–5 px plus physical widening | 200→1400 / 40% |
| Blue hour | no solar cast | 0.70–0.85 ambient-only | #626C9E | contacts only | 200→1200 / 40% |
| Overcast | underlying 0.716; nearly invisible | 0.78–0.88 | #8993AD | no legible hard sun shadow | 180→1200 / 45% |
| Rain | underlying 0.716; nearly invisible | 0.80–0.90 | #7786A5 | contacts only | weather override |
| Storm | underlying 0.716; suppressed | 0.83–0.93 | #606F94 | contacts only | weather override |
| Fog | direct suppressed | 0.88–0.96 | #9CAABD | contacts only | weather override |
| Snow | underlying 1.790; diffuse | 0.75–0.88 | #A0AFCB | contacts + broad roof shade | 150→900 / 50% |
| Moon night | moon geometry only | 0.65–0.80 | #465582 | weak, softened; no sun shadows | 150→1000 / 35% |
| Moonless | no celestial cast | ambient floor | #3E4974 | contacts only | 150→900 / 35% |

Clear-air fade color: morning #A1BDD9; noon #9ABBDC; 15:30 #9DB8D7; golden #AFACC9 (blue-violet distance, warm horizon may remain); blue #717FA6; overcast #AAB8C8; snow #B8C8DC; moon #263555; moonless #222D48. Fog/smoke use their own scattering colors, not this blue override.

For clear-air rows, a=cap·(1−exp(−ln2·max(0,d−start)/(d50−start))). Here d50 means **half the specified cap**, not 50% opaque. Blend in linear color. This intentionally bounded artistic clear-air perspective differs from full optical extinction in weather.

Sun angular core stays about 0.53°; physical penumbra grows approximately 0.0093 × receiver separation in metres. The small pixel filter is antialiasing, not a replacement for solar direction/size. Retain 60–80 m local shadow coverage initially, compare 100 m only if it fits; fade beyond coverage without a visible cutoff. Do not pay for distant tree shadows.

### 2.4 Night floor — 5A · Low; local lights Medium

Rendered, unlit-by-lamps material patches: moonlit trunk Y 25–45, roof 22–40, wall 35–65; moonless trunk 18–32, roof 16–30, wall 25–48. These are inspection bands, not per-pixel clamps. Material base roof floor remains v2 #303942; color management and ambient must preserve it without turning roofs into lights.

Ambient color varies from horizon #404F7A to upper #232A50; moonless approximately 20% lower. Moon boost = 0.35·illuminatedFraction^1.5·max(0,sin moonAltitude)·(1−cloudCover)^2 relative to reference daytime fill; normalize/tune with the night patch bands, not a second global exposure hack. Moon below terrain/horizon contributes no directional source. Keep physical moon size/phase/direction; glow may extend 2–3 disk diameters at low alpha, not a giant lunar orb.

Windows 2400–2900 K appearance (#FFD19A core, #E8A968 surround); 20–30% of eligible windows lit, clustered per building using stable seeds. Street lamps 2700–3200 K appearance, small warm pools. Reuse emissive windows and at most **two nearby unshadowed lights**; no point light per window. Bloom soft and bounded, no blown neon squares.

Pass if **light and palette ≥3**, dark roofs/trunks remain distinguishable, true source and shadow bearings agree, summer stays summer, winter has bare northern deciduous trees, and exposure does not flatten architecture. Motion/character criteria are not inferred from these character-free stills.

## 3. Weather readability — 5A · Low materials; Medium particles

### 3.1 Wet ground

Separate current rain rate R from accumulated wetness W (0–1) provided by environment data. Rain stopping must not instantly dry pavement. This pack refines appearance, not the accumulation model in weather-v1. Existing 5A maximum asphalt darkening around 34% is a diagnostic starting point; propose the smaller controlled ranges below so already dark streets do not collapse.

| Surface | Full-W diffuse reduction in linear RGB | Dry→wet roughness | Puddle eligible area at W=.65 / 1 |
|---|---:|---|---|
| Asphalt | 25–30% | .85→.42 | 3–6% / 6–10% |
| Concrete walk | 12–18% | .90→.58 | 1–3% / 3–5% |
| Stone/paving | 15–22% | .80→.48 | 2–4% / 4–7% |
| Soil | 18–25% | .95→.85 | 0 unless depression known |
| Grass/crowns | 6–10% | .90→.72 | zero reflective lawn |

Interpolate reduction by W; use p=max(0,(W−.35)/.65) for puddle activation. Puddles are 0.2–1.5 m irregular thin masks, 3–8 per visible eligible lot/road segment near camera; they are not ubiquitous decorative pools. Exclude slopes >3°, raised curbs, doors, steps and all non-ground surfaces. Without reliable drainage data they are visual inference, not surveyed depressions.

Allow **sky-only** reflection inside puddle masks, F=.02+.98(1−cosθ)^5, reflected contribution clamped to .35, roughened broad highlights; no scene/object mirror, SSR or full-surface reflection. Outside masks, broad restrained sheen, no recognizable mirrored houses. This explicitly supersedes older v2 conservative wet darkening only where accepted by the owner; do not treat a whole shiny road as the target. Existing renderer support should be tuned, not duplicated.

Wet foliage: 6–10% base darkening plus 5–12% soft highlight on upward crown lobes; never varnished plastic leaves. Light rain: cloudy sky, softened contrast, 240–600 visible bounded near drops as a proposed tuning envelope under the existing particle cap; no constant full-screen curtain. Test particle contribution separately from wet surfaces. Aerial >60 m: remove droplets, keep broad wetness and sky change. No rain-driven tree shadow resembling clear midday.

### 3.2 Fog and smoke

Use T(d)=exp(−k·max(0,d−start)), k=ln(10)/(end−start). “End” means **90% contrast extinction**, not hard clipping. Blend scattering color in linear space. At d=start+0.5(end−start), T≈.316. Values apply to near-ground horizontal sight lines; vertically thin the layer in aerials using the environment's height model.

| State / density | Color | Start / end metres | Diagnostic contrast |
|---|---|---:|---|
| Fog light | #BECBD3 | 40 / 900 | distant facades fade; foreground crisp |
| Fog medium | #B8C6D0 | 15 / 350 | opposite shore strongly obscured |
| Fog dense | #B5C1C9 | 0 / 120 | far shore absent; near path readable |
| Smoke light | #BBB3A1 | 80 / 1800 | warm-grey distant veil |
| Smoke medium | #ADA58F | 30 / 650 | blue sky muted, distant shore weak |
| Smoke dense | #9E9686 | 5 / 220 | tan-grey field; no sunny blue distance |
| Rain light | #AAB9C7 | 100 / 1400 | wet foreground, softened distance |
| Storm rain | #7D8BA5 | 30 / 550 | dark cloud lid and lost distant contrast |

These are art-test presets, not conversions from AQI. Visibility from weather should calibrate extinction, with bounded artistic adjustment; do not infer smoke from generic humidity. Reduce direct sun for smoke to 70/35/10% of clear contribution for light/medium/dense, and saturation of distant scenery by 10/25/40%. Foreground retains material identity. Do not add separate fog and smoke opacities twice; combine extinction coefficients and weight scattering colors by their contributions.

### 3.3 Snow

Use known accumulated cover S, not the word “snow” alone. Unknown history remains unknown. Synthetic snow reference uses S=.8 explicitly. Blend broad patches at .4–1.2 m, 2–5 m and 12–20 m scales; suppress small scales at altitude. Roof caps honor upward-facing geometry and slope; steep faces retain underlying roof color. No snow inside walls or floating over eaves.

Fresh lit snow #DEE7ED–#EEF0EE, blue shade #9EAFCA–#BAC7D9; keep most highlights Y≤235. Exposed road #5F6878–#7C8490, compacted snowy path #B9C4D2. Snow on eligible lawn 60–90% for S=.8, roofs 45–80% depending on slope; streets/paths not automatically plowed. Only recorded/planned maintenance may create clear tracks or banks. Open water remains water unless separate ice data authorizes freezing. Winter northern trees bare; conifers keep muted green, no autumn litter or blossoms.

Pass if **adRainReadable ≥3** in wet scenes even with particles hidden; three cues remain (wet surface contrast, small sheen/puddles, atmospheric/sky change). Fog/smoke must differ at 50/150/500 m witness ranges. Snow retains surface separation; no clipped snow, invented ice or January orange leaves. These checks support palette, light, groundRichness, depthFog and geography.

## 4. Aerial edge and scale — P2 context + 5A fade · Medium

**Recommend real ground continuation with a bounded context fade.** Keep a high-detail core, then a 150–300 m real-data transition ring, followed by 300–800 m coarse land-use/road/water context where data exists. The world is not a slab floating above a green plane. Do not invent roads, buildings or shoreline to complete an attractive island.

If the available package ends, stop private detail in the ring and blend the **known terrain surface color** toward a neutral regional backdrop (#A9B4A0 summer / #BDC8D4 winter) over 150–250 m. This is an explicit coverage visualization, not fabricated geography. Avoid a vertical cut wall unless the product intentionally adopts a map model. No cloud skirt to hide missing data. At a steep 55° down view, there is **no horizon**: top ray remains below horizontal. Tilt-shift is optional within the existing post bucket, not the edge solution.

Frame the selected true bounds plus 10–15% margin, not a tiny neighborhood in a giant blank field. Coverage fade must not mask a target building/route. The two aerial concepts show clear and snow appearance, not an OSM reconstruction.

Crown readability: at altitude retain ≥3 distinct crown aspect classes (wide/round/upright), visible height differences 20–35%, deterministic warm/cool leaf family groups, crown-to-ground contact shade. Use projected size: >24 px retains asymmetric lobes; 8–24 px 24–60 triangle silhouette; 2–8 px simplified opaque 8–16 triangle canopy; <2 px aggregate only where no mapped position changes. No alpha diamond forest. Haze cap ≤25% across the selected clear core; weather can exceed this only intentionally. Keep roads and shore discernible at test crop.

Pass if silhouettes, depthFog and geography ≥3/3/4; no horizon in steep aerial, no floating tile or flat green outside plane, no uniform diamond crowns, and no hidden route under an arbitrary fade.

## 5. Tree variety and season — P2 asset/selection, 5A LOD/shading · Medium

These are regional form priors, not botanical identification from footprints. Explicit OSM species/genus wins; generic trees can use profile probabilities and inference labels.

| Region | Crown forms / species inspiration | Typical mature height × width | Leaf families |
|---|---|---|---|
| Denver | open vase elm; broad cottonwood; upright honeylocust; occasional conical evergreen | 8–18 × 5–12 m | #638247, #809647, #889D61 |
| North Shore | wide irregular oak; upright rounded maple; vase elm; oval linden; open honeylocust | 10–22 × 6–15 m | #527248, #739153, #879B5B |
| Lakeview | restricted open elm/honeylocust; upright maple; occasional broad park oak | 7–16 × 4–9 m | #61784C, #80905C, #73874E |
| Miami | broad evergreen/live-oak form; irregular tropical broadleaf; eligible palms, not palm monoculture | 6–16 × 5–14 m; palm 8–15 × 3–5 m | #416D49, #5D8550, #779557 |

Retain Chicagoland profile species shares from its proposal; do not overwrite them with these shorter shape lists. Miami palm form around 15% of eligible inferred trees is a starting prior, never inserted into every yard. Keep regional profile selection in data.

For each species/form, **at least six silhouette variants** from 3 branching arrangements × 2 crown envelopes. Independent height ±15%, width ±20%, yaw 0–360°, lean 0–7°, asymmetry 8–18%; clamp to clearance and species range. Color per tree ±5° hue / ±6% value; coherent lobe variation ±3%, not each lobe a different sphere. Avoid the same silhouette in the nearest three adjacent inferred trees, without reseeding mapped objects. Branch apertures and merged lobes produce a crown, not a pile of balls.

Near 0–50 m: visible scaffold branches and smooth asymmetric crown; 50–150 m: two or three major lobes; 150–600 m: opaque varied silhouette meshes. Beyond 600 m: retain aggregate height/color structure; no added full-surface alpha. Existing transparent cutaway is confined to camera obstruction within 20 m, opaque elsewhere, as supported by the 5A measurements. Do not restore expensive transparency to every tree.

Season state is regional and weather/phenology aware. Northern July: fully green. September/October: species-varying fall, not all orange. November: declining foliage; December–March fixtures bare deciduous, no fall litter. Spring leaf-out transitions through buds/small crowns before full foliage. Miami evergreen remains leafy year-round; selective deciduous behavior only in the relevant species. Snow does not turn bare trees into white green spheres.

Night trunks meet §2.4 patch bands through ambient/fill and palette; do not make trunks emissive. Sway uses existing wind model, 1–3 cm tip motion, no whole-tree pendulum; fade by 100–150 m. No per-tree animated shadow pass.

Pass if silhouettes ≥3, adRegional ≥3, no three adjacent repeated inferred silhouettes, correct season in all 12 lighting frames, and both near and far tree trunks remain readable at night.

## 6. Sky polish — after §§1–5

### 6.1 Clouds — 5A · Low/Medium

Reuse unlit analytic/batched cloud forms. Flat bases with 2–4 merged lobes; varied size, never identical popcorn lines. Visible counts are art limits within camera, not a physical cloud-cover calculation.

| Cover | Suggested visible forms | Sky treatment |
|---|---:|---|
| 0–.15 | 0–3 | broad clear gradient |
| .15–.4 | 3–6 | separated chunky clouds, 40%+ clear gaps |
| .4–.7 | 5–8 | larger merged clusters, muted key |
| .7–.9 | 2–4 large banks | broad openings, no tiled puffs |
| .9–1 | one continuous stylized layer | no isolated sunny cumulus under a storm label |

Clouds occlude/dim sources consistently; moon/stars cannot shine through opaque cloud. No volumetric ray marching or new full-screen scattering pass. Cloud lower surfaces stay cool and readable.

### 6.2 Stars — 5A · Low with capped batching; Medium if enlarged

Current repository Stars.swift uses **BSC5 bright-256**, with a default maximum of 128; earlier HYG reference data is not the current catalog. Keep the existing observer/time, proper-motion, precession and sidereal pipeline. No random sky dots, mirrored constellations, camera-locked stars or moved stars to fill composition.

First fix selection: horizon/frustum visibility before final visible-count budget, with stable magnitude ordering/tie-breaks; prevent temporal popping via brightness fade near threshold. Initial cap 128 visible, trial 256 only after profiling. A denser rural field ultimately needs a reviewed larger real catalog (e.g. 1–2k entries); mark this a separate data task, preserve its license/source and epoch metadata. Do not synthesize positions when the current 256 catalog has few stars in a view.

Proposed appearance, not astronomy: rural gain1.8, suburb1.35, downtown.65; respective faint-star limits m≈5.0/4.0/2.5, constrained by catalog coverage. Night factor rises from zero at solar altitude −6° to one at −12°. Multiply by (1−cloudCover)^3, atmospheric transmission and a moon-wash factor 1−.65·k·max(0,sin moonAltitude); k=illuminated fraction. Urban brightness scales by regional light-pollution input, not a claim derived from building count alone. Missing input defaults to “suburban assumption.”

Point radius .6–1.2 px at reference resolution; brightest stars ≤1.8 px, no twinkle displacement, optional brightness ±5% over 4–8 s. One batch, no light per star. Validate against projected catalog coordinates: center within 1 px at capture resolution after full camera transform; do not grade generated star speckles as astrometric truth.

### 6.3 Sun/moon glow and water — 5A · Low/Medium

Sun center comes from solar model; physical core ~.53°, artistic glow radius 1.5–3°, alpha ≤.12, with full occlusion by terrain/cloud. Sun behind the ESE postcard camera stays out of frame even at golden hour. Bloom reuses the existing .35 ms allocation; no lens flare chain or duplicate glare pass.

Water glitter uses the same world-space source vector as lighting. For water normal n, view v and light l, evaluate a bounded microfacet/specular response around normalize(v+l), perturbed by the existing low-frequency wave normals. Only the visible illuminated water receives glitter; local shoreline/water mask clips it. Break into short moving bands with roughness .18–.35, moon .25–.45. No painted vertical stripe tied to the screen or fixed beneath the source irrespective of geometry. Glitter bright area 1–4% of visible water for sun, .2–1% for moon; diffuse blue water remains ≥85% recognizable. Clamp broad reflection gain; tiny source highlights may approach white within §2 clipping limits. No planar full-scene reflection or SSR.

The three dedicated sky references use WorldEngine materials and no characters/boats. Golden sky may use a separate west-facing water camera, explicitly unlike the 12-frame ESE set. Night source location/phase must follow its fixture; the generated star field remains aesthetic-only pending catalog projection.

Pass if sky strengthens palette/light/depthFog without moving astronomy, no sunset disk appears in the ESE view, sparse cumulus stays simple, stars remain fixed during camera movement, and glitter obeys light/water geometry.

## 7. Budget, owners and degradation

The [visual-v2 §8.1](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md) **10 ms GPU** envelope remains the constraint; none of the following is an extra budget.

| Existing bucket | Envelope ms | Look-fix work charged here | Owner / cost |
|---|---:|---|---|
| Base geometry/material | 4.25 | opaque crown variants, context ring, building LOD, base palette | P2 assets + 5A selection / Medium |
| Sun/contact shadows | 1.45 | correct source, lifted shade, bounded range | 5A / Medium |
| Vertex AO/fill/crown | .15 | fill and contact tuning; crown color | P2 vertex attributes + 5A / Low |
| Surface patterns | .25 | lawn patches, simple wet/snow masks | P2 layout + 5A / Low |
| Near geometry | .35 | beds, shrubs, curb/walk edges, leaves | P2 / Medium |
| Wet lights | .35 | bounded puddle sheen, warm lamp pools, water specular | 5A / Medium |
| Weather particles | .20 | near rain/snow; none high aerial | 5A / Medium |
| Post | .90 | .15 grade, .35 bloom, .40 aerial blur only if used | 5A / Medium |
| Reserve | 2.10 | measured variance/headroom; do not pre-spend on sky | 5A / reserve |

Cloud/star base shading belongs in base, source glow in existing bloom; palette variation has no independent pass. Fog belongs in existing material/atmosphere shading, not a new full-screen volume. Night ambient is not an extra shadow light.

Main visible view ceiling **400k triangles**, aspirational ~290k; shadows ≤150k; ≤100 visible draw calls. Existing 35k near-detail allowance is inside 400k: 20k bevels, up to 6.4k leaves, 4k tufts, remaining 4.6k other near detail. New shrubs/beds consume remaining allowance or replace tufts/leaves, never add an unlimited shrub pool. Suggested added-view caps: near shrubs/bed edges ≤4k triangles, context ≤20k, sky/cloud/star meshes ≤4k, all deducted from base/near budgets. Building share ~170k worst target demands runtime distance LOD in dense Lakeview; whole-world near assets cannot all be shown at once.

Latest 460,492 triangles/139 draws are whole-world counters: **not proof of a visible-view breach**. Instrument visible main and shadow separately. The 5A report's ~8.5 ms optimized capture and estimated 9–9.5 ms with MSAA are not sustained iPhone13-class validation. Older runs around 14–15 ms demonstrate why 60 fps alone is insufficient.

Degrade in order: remove aerial particles; reduce microgeometry; opaque far crowns; shorten costly shadow coverage carefully; reduce optional bloom/blur; lower supported render scale through existing thermal policy. Preserve geometry, true source direction, readable material contrast and season. Do not hide bugs by lowering every material's quality or recoloring the world.

High-cost rejected directions: per-tree transparency, ray-marched clouds/fog, SSR/full-scene wet reflections, per-window lights, dense grass blades, shadow-casting weather particles. All **5A High**, except grass assets **P2 High**; not part of this pack.

## 8. Grader checklist and priority

Run paired fixed-camera captures at the same package, timestamp, weather, season, exposure baseline, resolution and thermal conditions. Record input hashes, engine version, capture dimensions and visible budgets. Change one family at a time. Use the current rubric's 10 criteria; characterReadability=null without a character, motion=null for stills. Total = 50·sum/(5·scorable count), half-up to one decimal. AD scores remain separate; adRainReadable=null for dry scenes.

**Per-view acceptance:** new score ≥ frozen concept target, no scorable criterion <3, geography ≥4, character ≥4 when present, all applicable AD ≥3, no hard fail. Ratio = engineScore/thatViewTargetScore, not average of unrelated references. If an old reference has a known fault, annotate/exclude that visual behavior before rebaselining; never reward a copied wrong bearing. New concepts need independent calibration before replacing existing targets.

| Section | Pass if… | Rubric focus |
|---|---|---|
| Ground | lawn/bed/access layers read; no green blanket or fake parcels | groundRichness, adGroundRich, geography |
| Lighting | ordinary scene reaches bands without washed sky; actual bearings; readable shade | light, palette, softnessAO |
| Weather | wet cues survive particle-off; fog/smoke change contrast at known ranges; snow not clipped | adRainReadable, depthFog, groundRichness |
| Aerial | no steep-view horizon; no floating plane; varied crown footprints; real context | silhouettes, depthFog, geography |
| Trees | varied forms, no repeated diamond row; winter bare; night trunks readable | silhouettes, adRegional, palette |
| Sky | data-correct source/stars, bounded glow, coherent glitter, sparse clouds | light, palette, geography |
| Performance | sustained ≤10 ms GPU target on iPhone13-class with visible ceilings | engineering release gate, not visual-score points |

Retain all hard flags: wrong-sun-bearing, horizon-in-steep-aerial, moved-geography, authored-surface-imagery, full-surface-reflection, osm-credit-missing, clipped-snow-or-black-holes, capture-failed. Attribution must be visible in app captures. A title claiming realism does not waive geography. Generated reference images are **not already graded passes**.

### Ranked work queue

Estimated score improvements are **hypotheses**, expressed as possible points on the 50-point normalized score per affected view; not additive, not promised. Durations are focused engineer-days excluding review/device scheduling.

| Rank | Work | Owner | Days | Potential points / day | GPU cost |
|---:|---|---|---:|---|---|
| 1 | Diagnose existing uniforms/masks; fix ordinary exposure/fill, roof/trunk shade | 5A | .5–1 | 2–4 / 2–8 | Low |
| 2 | True sun-bearing fixture checks; real long golden shadows | 5A | .5–1 | 1–3 / 1–6 | Low–Medium |
| 3 | Broad lot/lawn variation, beds and access hierarchy | P2 + 5A material | 1.5–2.5 | 3–5 / 1.2–3.3 | Low–Medium |
| 4 | Wetness/puddle masks and cloudy light; particle-off rain test | 5A | 1–1.5 | 2–4 / 1.3–4 | Medium |
| 5 | Fog/smoke extinction and sky coupling | 5A | .5–1 | 1–2 / 1–4 | Low |
| 6 | Crown diversity, opaque far LOD, season/litter rules | P2 + 5A LOD | 1.5–2.5 | 2–4 / .8–2.7 | Medium, potential savings |
| 7 | Real context ring, coverage fade, aerial scale | P2 + 5A fade | 1–2 | 2–3 / 1–3 | Medium |
| 8 | Snow separation and bare-tree/night regression sweep | P2 season + 5A | .5–1 | 1–2 / 1–4 | Low–Medium |
| 9 | Regional bed/shrub refinements and access corrections | P2 | 1–2 | 1–2 / .5–2 | Medium |
| 10 | Clouds, catalog star visibility, source glow, water glitter | 5A | 2–3 | 1–3 / .3–1.5 | Low–Medium |

Ranks incorporate prevalence and dependencies as well as the uncertain points/day range. Re-score after ranks 1–5; if ground still scores 2, do not divert the next day to prettier stars.

## 9. Open implementation questions

1. Which current environment/material inputs explain rain's weak appearance despite existing wet code?
2. Which capture can run reproducibly on an iPhone13-class device, off charger at steady thermal state?
3. Does the package contain enough real context to support the aerial continuation ring?
4. Which districts have parcel/access/green-space confidence sufficient for private-yard inference?
5. Can current catalog selection deliver visibly more stars before expanding BSC data?
6. Who independently calibrates the new reference scores and records the target freeze?

See [validation notes](VALIDATION.md), [image manifest](image-manifest.json), [prompt log](PROMPT-LOG.json) and [complete inventory](README.md). Images are appearance proposals, not engine captures, historical weather evidence or surveyed geography.
