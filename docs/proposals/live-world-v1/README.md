# WorldEngine live world style pack — Style B
**6 October 2026 · Proposal only · Renderer-neutral · Rich stylized**

Live objects should belong to the same world as its houses, vegetation and ground. Use clear silhouettes, broad real lighting, opaque material families and restrained emissive lamps. Keep physical size and believable placement; make data provenance visible through shape and text as well as subtle material differences.

Anchors: [look-fix midday](../look-fix-v1/images/lighting-03-ordinary-1530.png), [vegetation pack](../vegetation-v1/README.md), [ground pack](../ground-v1/README.md), and [visual v2](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md). Agency-inspired colour families are permitted; vehicles are generic, with no logos, ads, airline branding or readable fleet/route markings.

## Pack contents
| File | Contents |
|---|---|
| [01 Rail vehicles](images/01-rail-vehicles.png) | Chicago rapid transit, Metra-inspired gallery commuter rail, RTD-inspired light rail; near, distant and aerial studies |
| [02 Elevated rail and portals](images/02-elevated-and-portals.png) | Street and aerial integration, elevated deck placement and below-ground portal occlusion |
| [03 Bus families](images/03-bus-families.png) | CTA/RTD-inspired standard and articulated buses, distant/aerial, dusk lamps |
| [04 Aircraft scale and light](images/04-aircraft-scale-and-light.png) | Generic narrow/wide twinjets, approach/departure, distance and night appearance |
| [05 City vs dark mountain sky](images/05-city-vs-dark-sky.png) | Moonless clear-night comparison; star density, faint Milky Way and magnitude hierarchy |
| [06 Sky object guide](images/06-sky-object-guide.png) | Eight Moon phases, stars/planets, satellite/ISS points, meteor and rare aurora studies |
| [07 Freshness states](images/07-freshness-states.png) | Live, stale and simulated vehicle studies, including aerial simplification |
| [08 Aerial live world](images/08-aerial-live-world.png) | Day/night composition and source-state legend |
| [09 Exact material colours](images/09-exact-material-colours.svg) | Neutral vehicle, lamp, infrastructure and provenance hex values |
| [10 Exact sky colours and magnitude](images/10-exact-sky-colours-and-magnitude.svg) | Magnitude flux/display-energy table, spectral tints and sky palette |
| [11 Scale and provenance](images/11-scale-and-provenance.svg) | Asset dimensions, calculated aircraft projection and four provenance glyphs |
| [Live style JSON](live-style.json) | 11 vehicle archetypes, materials, LOD, lighting, sky math, freshness, data contract and shared caps |
| [Prompts](image-prompts.json) | Built-in image-generation prompts, style references and two correction edits |

**Authority and limitations:** exact JSON and SVG data override incidental raster detail, colours, labels and scale. Sheets are generated concept art, not renderer captures, mapped locations, live observations, calibrated photographs or device performance results. Portal geometry is explanatory; never copy it into an unmapped location. Sheet 08's sleek train forms communicate composition; use sheet 01 and the JSON for the requested vehicle families.

The aircraft sheet's top narrowbody was corrected to two engines. The aerial legend was corrected to “Last observed.” Remaining deviations include enlarged illustrative lamps/aircraft, a too-rich Milky Way and some large aurora colour bands. Use the numerical brightness/size caps below, not their literal artwork pixels. The departure panel's “no landing lights” depicts one supplied lamp-off state, not a universal departure rule: departing aircraft may also use landing lights.

All values, palettes, freshness timeouts, mesh targets, simplified sky visibility models, regional defaults and performance subdivisions are **authored assumptions**, except facts explicitly verified below and existing v2 ceilings. This is a new reference schema proposal, not a claim that these fields already exist in the engine.

## Verified reference facts
Sources checked **6 October 2026**. Only the associated facts are verified; the proposed hex codes are not official agency brand codes.

- CTA's 7000-series reference uses distinctive blue end caps. This supports the generic short silver/blue rapid-transit family; it does not identify every train as that series. [CTA 7000-series](https://www.transitchicago.com/7000s/), [CTA introduction](https://www.transitchicago.com/cta-introduces-new-7000-series-railcars-to-scheduled-service/).
- Metra's published equipment presentation includes gallery cars. The pack uses a representative double-deck gallery/diesel silhouette; real equipment/type data can select other Metra forms. [Metra mechanical department presentation](https://metrarail.com/sites/default/files/assets/about-metra/leadership/board_meetings/2019/201901/14_xiv_mechancial_board_presentation_1-11-19_0.pdf).
- RTD documents light-rail vehicles separately from its broader rail/bus system. A light-rail look must not silently substitute for airport commuter rail. [RTD light-rail design criteria](https://cdn.rtd-denver.com/image/upload/v1739488151/2024_LRT_Design_Criteria_v43yhf.pdf), [RTD facts and figures](https://www.rtd-denver.com/open-records/reports-and-policies/facts-figures).
- A320ceo reference dimensions are length 37.57 m, span 35.80 m with Sharklets, height 11.76 m. These provide one true-scale generic narrowbody basis, not an assertion about a tracked aircraft's type. [Airbus A320ceo](https://www.aircraft.airbus.com/en/aircraft/a320-family/a320ceo).
- Aircraft position lights use red on the aircraft's left, green on its right and white aft. [FAA Airplane Flying Handbook, night operations](https://www.faa.gov/sites/faa.gov/files/regulations_policies/handbooks_manuals/aviation/airplane_handbook/12_afh_ch11.pdf). Sheet front views therefore show red on the viewer's right.
- Five magnitude steps correspond to a factor of 100 in flux. [ESA star-tracker challenge](https://live.kelvins.esa.int/star-trackers-first-contact/challenge/). Star colour relates to temperature, not apparent magnitude. [NASA, life cycles of stars](https://imagine.gsfc.nasa.gov/educators/lifecycles/LC_main3.html).
- Urban skyglow and moonlight suppress faint stars and the Milky Way; dark sites reveal more of the sky. [NASA, good places to stargaze](https://science.nasa.gov/solar-system/how-to-find-good-places-to-stargaze/), [NASA, sky quality](https://science.nasa.gov/solar-system/skywatching/night-sky-network/check-your-sky-quality-with-orion/).
- The Moon's apparent diameter is approximately half a degree. [NASA Moon comparison](https://science.nasa.gov/asset/hubble/xdf-moon-comparison/).
- ISS visibility comes from reflected sunlight, commonly during suitable dawn/dusk passes. A visible moving point is appropriate at ordinary phone field of view. [NASA Spot the Station FAQ](https://www.nasa.gov/missions/station/spot-the-station-frequently-asked-questions/). The point presentation is the design inference; no resolved station geometry is proposed.
- NOAA's OVATION product forecasts regional aurora location/intensity; that forecast does not confirm a particular observer saw an aurora. [NOAA aurora forecast](https://www.swpc.noaa.gov/products/aurora-30-minute-forecast). This pack makes no claim about an actual Chicago/Denver event tonight.
- GTFS Realtime distinguishes vehicle positions and trip/arrival updates; some position/timestamp fields can be optional. A feed download alone is not proof of a fresh observed location. [GTFS Realtime reference](https://gtfs.org/documentation/realtime/reference/).

## Transit construction and physical size
Dimension rows below are **generic asset assumptions**, not fleet measurements. Supplied vehicle type/dimensions override them. Materials should share atlas/families across instances; use at most four material groups per detailed kit.

| Archetype | Length × width × height | Silhouette cues |
|---|---:|---|
| Chicago rapid-transit car | 15 × 2.9 × 3.7 m | Short single-level silver car, blue end mass, paired doors; no pantograph |
| Gallery commuter coach | 26 × 3.1 × 4.6 m | Taller double-deck body, two window rows, long roof |
| Commuter diesel locomotive | 18 × 3.1 × 4.7 m | Strong cab/front, broad blue/red accents, roof fan masses |
| Denver light-rail vehicle | 26 × 2.7 × 3.9 m | Articulated long body, angular ends, dark window band, pantograph |
| Standard bus, either family | 12 × 2.6 × 3.3 m | Softened box, two axles, simple roof boxes |
| Articulated bus, either family | 18 × 2.6 × 3.3 m | Two rigid sections, accordion hinge, three axles |

**Street, approximately 5–40 m:** doors, window rhythm, wheels and a few roof masses carry recognition. Use smooth surfaces with small physical bevels where silhouette/light justify them. No model of every rivet, corrugation groove or interior seat. Windows are opaque dark blue-grey panels; night light is a dim emissive window mask rather than a transparent interior.

**Aerial:** retain body length, roof/end colour and rail/road alignment. Remove mirrors, thin wipers and tiny axle details first. Do not widen a vehicle or train to make it easy to select; selection gets a separate UI marker with clear provenance.

**Rail motion:** each carriage follows arc length behind the leading reference on the mapped route. Do not animate a straight rigid consist around a sharp bend. Preserve car spacing and heading per segment. Unknown consist length should be flagged as a representative depiction; it must not imply an observed eight-car train. The two/four-car examples are illustrations.

**Metra exceptions:** locomotive location depends on push/pull direction and actual cab-car arrangement. Electric or other known equipment gets its proper data-selected kit. Avoid assuming every Metra service is locomotive-pulled or every commuter line is elevated.

**RTD exception:** this pack's requested articulated light-rail family is not a Denver airport commuter-rail kit. A commuter-rail service must select an appropriate supplied type or a plainly generic commuter fallback with uncertainty.

**Buses:** the roof, glass and two stripe families distinguish regional references subtly. An articulated bus has two rigid sections with a hinge following the road path; its rear cannot cut through a sidewalk on every bend. Keep observed position uncertainty separate from a cosmetic route snap. No cartoon bounce, exhaust clouds or per-wheel suspension simulation is needed.

**Elevated 'L':** mapped layer/elevation governs the train deck. Ground-level rail must not become elevated merely because it is in Chicago. Simplify girders into a deck, principal beam masses and spaced columns; use quiet dark steel. Maintain supplied road clearance. Typical conceptual clearance around 5 m is only a layout study assumption, not a new surveyed geometry rule.

**Subway portals:** show trains only on exposed ramp/track sections and within the visible tunnel mouth. Terrain and retaining-wall depth must occlude them. The model becomes fully hidden beyond the portal, with no translucent X-ray train, above-road GPS dot styled as a visible vehicle, or emissive light leaking through the roof. A host may offer an explicit underground location marker separate from the world object.

## Aircraft: ORD, MDW and DEN
Use the same unbranded regional/narrowbody/widebody kits at all three airports. Aircraft type and observed track choose the kit and pose, not airport proximity. A known widebody remains a widebody even near MDW; a narrowbody default for an explicitly simulated MDW scenario is an assumption, not a fleet census. Airport/runway metadata lives in location data.

Generic widebody proposal: 65 m length, 64 m span, 18 m height. Generic regional twinjet: 30 m length, 28 m span, 8 m height. Narrowbody uses the sourced A320ceo scale. These are shape families, not brand replicas.

**Scale at distance:** for cross-camera projected extent W at slant range d:

angular extent = 2 atan(W / (2d));

at frame centre, pixel extent ≈ H × W / (2d tan(verticalFOV/2)).

For a 35.8 m span, 700 drawable-pixel height and 55° vertical FOV:

| Slant range | Angular span | Frame-centre projected span |
|---|---:|---:|
| 500 m | 4.10063° | 48.140 px |
| 2,000 m | 1.02557° | 12.035 px |
| 5,000 m | 0.41024° | 4.814 px |

Orientation/foreshortening can reduce the span. These are analytic examples, not measurements of sheet 04. At 2 km the aircraft is small; no heroic enlarged jet hanging over a nearby house.

**Approach/departure:** heading, altitude, vertical speed and known/inferred flight phase control pose. Track altitude must declare datum and whether it is geometric or pressure altitude; reconcile to terrain before claiming true height above ground. Unknown altitude/phase remains unknown. Do not fabricate a 3D approach glide path or gear extension just because a plane is near an airport. Demo glide paths require explicit simulation provenance.

Landing gear is a few simple opaque struts/wheel masses, shown when supported by phase/type. Departure can retract it when phase indicates. Engine count belongs to type; generic twinjets have two engines. Windows become a few dark groups at medium distance and disappear at far distance.

**Dusk/night landing lights:** small warm-white emissive marks, no shadow-casting lights or spotlight cone. Proposed point core ≤2 drawable pixels and halo radius ≤3 pixels. Directionality:

visibility = smoothstep(cos 40°, cos 15°, dot(aircraftForward, directionToCamera)).

Lamp state also requires an eligible known/flagged inferred phase. This makes approach lights strongest when facing the viewer without painting every departing plane equally bright. A separate gate increases their prominence as solar elevation moves from 0° to −6°; daylight geometry can retain a dim physical lamp state.

Position lights keep their correct left/right/aft mapping. At unresolved size, merge energy rather than separating artificial red/green points many pixels apart. Optional anti-collision blink is phase-stable, low duty-cycle and ≤1 Hz; reduced-motion mode removes flashing. No rapid screen-wide strobe or added bloom pass.

At <4 px projected body size, night aircraft may be a point if eligible lamps are visible; daytime subpixel bodies fade. Point rendering is an angular visibility proxy, never an enlarged jet mesh. Clouds, terrain/horizon and distance haze occlude aircraft. No low-approach contrail is assumed. Aerial views preserve altitude separation and parallax; planes must not rest on roofs or cast a detached giant silhouette onto the neighborhood.

## Night sky construction
The sky is one coherent celestial frame. Use a versioned bright-star catalogue with celestial coordinates and magnitude/colour data. Transform to local east/north/up using observer position and evaluation UTC. Milky Way shares the same rotation; Moon/planets use ephemerides. Do not invent constellations by scattering random points or rotate stars to follow the camera.

All pixel sizes below mean **drawable pixels**. UI badges use platform layout points. At high-resolution drawables keep stellar cores small; never scale their physical angular size into decorative disks.

### Magnitude, brightness and colour
Verified flux ratio:

F / F0 = 10^(−0.4mV).

Proposed display compression:

E = min(2, (F/F0)^0.55) × visibility × local cloud transmittance × nightGate.

This compression is an artistic phone-display assumption, not photometric calibration. Magnitude controls emitted/displayed energy; colour comes from catalogue B−V or a spectral family, not the magnitude number.

| Magnitude | Flux relative to magnitude 0 | Compressed energy before visibility |
|---|---:|---:|
| 0 | 1 | 1 |
| 2 | 0.1584893 | 0.3630781 |
| 4 | 0.0251189 | 0.1318257 |
| 6 | 0.0039811 | 0.0478630 |

Use an energy-normalized small point kernel, core diameter 1.2 px, sprite extent up to 4 px for filtering, bright halo radius ≤2 px. Do not let a larger sprite create additional flux. Very bright objects may use the shared bloom path; only stars of magnitude ≤0 are eligible by default. No diffraction spikes on every star.

Restrained colour references: hot blue-white #CFDEEE, white #E2E6E7, warm-white #E8E2D3, warm #E6CBAF, soft orange #DEB79E. These are design colours, not measured stellar spectra. Faint stars trend toward neutral; don't show a field of saturated red/blue candy dots.

Optional twinkle: amplitude ≤4%, 0.2–0.7 Hz, stable catalogue seed, smoothly varying. It should not make stars blink on/off or independently pulse like vehicle status lamps. Reduced-motion mode removes twinkle. Planets have no default twinkle.

### City vs dark mountain visibility
Proposed profile endpoints: limiting magnitude 3.0 city, 4.5 suburb, 6.0 dark mountain. They are data-selected artistic keys, not measured Chicago/Denver sky-quality maps or a promise that altitude makes any mountain dark.

Compute effective magnitude mEff = mV + atmospheric extinction. An inexpensive initial clear-air approximation may use X = 1 / max(0.1, sin(starElevation)), and extinction = 0.2(X−1) magnitudes, only above the local horizon. This is an explicitly assumed capped approximation. Use smooth visibility:

V = 1 − smoothstep(mLimit−0.5, mLimit+0.5, mEff).

Do not hard-pop a whole group at one magnitude threshold. Clouds multiply local transmittance; weather “clear” does not erase light pollution. Terrain/buildings occlude the lower sky. Twilight gate is 1 − smoothstep(−18°,−6°, sunElevation), with bright planets and Moon evaluated separately. Angles must be converted to radians for trigonometric functions.

City sky: slate-indigo with muted warm horizon, fewer points, broad haze. Dark mountain: deep navy, more faint points, gently legible foreground fill. Both use the same time/orientation when comparing visibility.

**Milky Way:** a broad authored low-resolution celestial luminance mask, with modest uneven diffuse structure/dark gap, no astrophotography texture or bright spiral galaxy. Proposed contrast is 0% city, 2% suburb and at most 8% in clear dark sky, relative to the local linear sky background. Keep its orientation tied to galactic coordinates. Remove it below terrain/clouds and in bright twilight. No separate fullscreen post effect is necessary.

**Moon washout assumption:** illuminated fraction I and above-horizon elevation attenuate faint sky detail. Initial limiting-magnitude loss:

loss = 2 I^0.7 sqrt(max(0, sin(moonElevation))).

Subtract loss from the profile magnitude limit. Milky Way strength additionally multiplies by (1 − I sqrt(max(0, sin(moonElevation))))². These deliberately cheap relations are appearance assumptions; actual lunar brightness, transparency and angular separation need a more calibrated model if accuracy becomes a product requirement.

### Planets
Use ephemeris position, apparent magnitude and angular diameter at the evaluation time. Points are appropriate in a normal phone view; a physical disk can appear only if it genuinely resolves. No ornamental Saturn rings or giant Mars sphere at street-view FOV.

Neutral reference families: Mercury #DEDACD, Venus #E8E5D8, Mars #D6B298, Jupiter #DED6C4, Saturn #D8CEB5. Brightness is not fixed per planet. Proposed point core ≤2 px with shared glare as justified by magnitude, plus horizon/cloud occlusion. A computed planet position is **Predicted**, not a telemetry-live object. These stars/planets are a sky model, not a catalogue of tonight's visible objects.

### Moon phases, angular size and light
Phase keys: 0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter. Reference illuminated fraction I = (1−cos(2πp))/2 is an approximate phase-key relation; actual Sun–Moon elongation/ephemeris is preferred.

Render a sphere/disc with the terminator oriented to the actual Sun direction and observer. Do not hardcode “waxing = right-lit” in the world: sheet 06 is one enlarged reference orientation. Eight phase keys are in the JSON.

Fallback angular diameter 0.5°; use actual ephemeris distance when available. At 700 px height and 55° vertical FOV, a centre-frame 0.5° Moon is approximately 5.87 px across, not a giant decorative disk. Use analytic phase shading and a few broad authored maria patches. A new Moon does not display as a luminous dark full circle; optional earthshine is ≤2% of lit reference.

A cheap global lunar indirect scalar may start at ≤0.08 of the noon-key reference × I^1.3 × max(0,sin(elevation)). This is an artistic fill maximum, not physically calibrated lux or brightness proportional to phase. Combine with the environment's existing moon/night ambient policy rather than applying both and doubling illumination. Moon below the horizon contributes zero direct lunar fill. Preserve coloured night shadow readability from v2.

### Satellites and ISS
Ordinary satellite and ISS passes are tiny moving points, not resolved spacecraft. Suggested cores 1–1.5 px satellites, ≤2 px ISS; no default light trail, permanent halo or aircraft-like nav blinking. Dashed arrows in sheet 06 are explanatory annotations and never render as sky trails.

Positions from orbital elements are **Predicted**. Record element epoch, model version and validity; do not label a current propagation calculation as an observed live ISS position. Suggested stale-element warning at 24 h, hide at 72 h, overridden by source/model validity. These cutoffs are assumptions, not guarantees of orbital precision.

Gate visibility by local horizon, Earth shadow/sunlight, observer sky darkness, cloud transmittance and magnitude model. ISS is not one fixed apparent magnitude; range, geometry and illumination change it. Don't fabricate a daily pass without valid orbit/time data.

Propagate at 1–2 Hz outside the render hot path and interpolate short samples. One ISS plus up to six satellite points, sharing the same point batch. No satellite train is assumed. Stop showing a pass after its model validity/visibility window ends.

### Meteor — Stretch
One short tapering streak, 0.3–0.7 seconds, 1–3° tail length and 0.7–1.2 px width. At most one concurrent event; proposed optional ambience rate ≤0.1/minute. No persistent trail, shower or particle explosion. Reduced motion disables it.

Default off. An ambience meteor has explicit **Simulated meteor** provenance; it does not become a live event because a meteor shower is forecast. Actual recorded detections could supply time/direction separately. Save the event seed/time for a deterministic recap.

### Aurora — Stretch, rare Chicago/Denver
Default off. Show only with a valid regional visibility forecast and appropriate dark, clear local horizon, or explicit **Simulated** demo mode. Forecast-driven styling says **Predicted aurora**, never “confirmed here.” No single fixed Kp value proves visibility in a city.

Appearance: low northern arc, muted red/green haze; initial elevation band 0–15°, roughly 100° northward arc. Up to four low-frequency ribbons or one integrated sky band, ≤128 triangles, alpha ≤0.12, slow 15–30 s drift. No volumetric raymarch, rapid ribbons, neon full-sky curtain or blanket ground tint. Stronger observed events can justify another supplied style key; the default is restrained.

NOAA forecast probability/intensity controls eligibility with validity timestamps; it is not a direct per-pixel physical brightness measurement. Suggested freshness limit 15 minutes unless source validity overrides. Fade forecast loss over a few seconds while updating the provenance/status; don't leave yesterday's aurora active. Clouds and city glow may wash it out completely. Reduced motion makes a static band or turns it off.

## Freshness and truthful motion
Track two independent axes: **provenance** (observed, predicted, simulated, unknown) and **age/validity** (fresh, stale, expired). A freshly received cached point may still be stale. A recently computed prediction is still predicted.

| Presentation | Subtle material cue | Shape/text cue |
|---|---|---|
| Fresh observed | Normal body/lighting | Solid circle, “Live estimate” |
| Stale observed | 55% chroma and 90% linear body value, dimmer emissive | Clock ring, “Last observed” plus time |
| Simulated | Neutral body, pale teal segmented identification band | Outlined diamond, explicit “Simulated” |
| Predicted | Normal physical kit if useful, source distinct | Outlined square, “Predicted” |
| Unknown | Omitted by default from tracking layer | If shown explicitly, question ring and “Source unknown” |

Chroma reduction means linearRGB' = 0.9 [0.55 linearRGB + 0.45 Y(1,1,1)], not an arbitrary grey overlay. Stale exact body hex values are exported in the JSON and diagram. Keep agency accent identity muted rather than repainting the whole stale bus amber. Amber belongs to the clock glyph.

Optional stale **coverage fade** may transition 1.0→0.65 over 2 seconds, then out at expiry. Prefer object-level temporal/culling fade or a bounded stable dither when supported; avoid making every vehicle transparent and paying for sorted overlapping glass/ghost meshes. The opaque desaturation + clock is the baseline. Stale lamps multiply by 0.65.

Simulated objects retain normal physical lighting, but get the neutral palette, segmented teal identification band and diamond. This band is a reference-style provenance cue, not an agency logo. It does not replace the explicit label. At unresolved scale, preserve the diamond/legend or omit the simulated object; never style a tiny simulated moving dot as live because the band became invisible.

Show provenance in the selected-object card and the layer legend; the host UI owns those controls. Use screen-layout points for labels, shape redundancy for colour-blind users and accessible text. Markers are an overlay, not physical lamps. A small cap of twelve unselected badges avoids a sea of pins; selected objects always expose source/time. If a simulation-enabled layer needs more visible identities than the badge cap allows, omit the excess simulations or display a clearly labelled aggregate, not an indistinguishable mixed layer.

Suggested **assumed** freshness defaults: bus/rail observed fresh ≤60 s and expire by 300 s; aircraft fresh ≤20 s and expire by 60 s. Provider cadence/validity overrides these. Age is evaluated against observation UTC, not receipt UTC; a missing/invalid timestamp cannot earn a Live badge. Explicit source validity can expire earlier.

Interpolation is a display estimate between observations. Proposed extrapolation caps are 5 s surface vehicles, 2 s aircraft, only on a known sensible route/trajectory and never through uncertainty-incompatible geometry. On stale transition, stop presenting movement as observed. Surface stale objects can hold last-known location with the clock; aircraft hide within 10 s of staleness so they don't hover indefinitely. A newly invalid trajectory can disappear sooner.

Feed outage progresses stale→expired. It never silently switches to animated simulation. Scheduled timetable location is predicted. When observations return, stable identity suppresses duplicates and blends only a plausible position correction; source/provenance must be correct immediately. Large discontinuities should replace/fade rather than animate a train through buildings. Unknown tunnel/route matching must not fabricate an aboveground vehicle.

Recap evaluation uses the walk/replay time and the stored observations, validity, seeds and model versions. Show **Historical observed**, **Historical predicted** or **Simulated** status. Current live data cannot overwrite a past scene without declaring a change of mode.

## Proposed data contract
The [engine-choice review](../engine-choice/ENGINE-CHOICE-REVIEW.md) describes environment.json as renderer-neutral state. Proposed extension: it references live entity snapshots and sky state; the immutable/versioned star catalogue remains a shared resource instead of being resent every frame.

Entity fields: source-scoped id, sourceId, provenance, observationUTC, receivedUTC, validUntilUTC, position, altitude source/datum, orientation, route reference, type reference, uncertainty and simulation seed where relevant. Nullable/unavailable fields preserve uncertainty rather than inventing data.

Sky fields: evaluation UTC, observer, solar direction, cloud transmittance, light-pollution profile, lunar/planet ephemerides, orbital element epochs, forecast validity, model versions and quality caps. One renderer-independent clock drives motion, celestial orientation and freshness. Source-specific adapters decide observation/model validity, not the visual shader.

This pack does not establish agency/aviation feed availability, acquire credentials or implement a live service. The data contract is a proposal for making future source differences explicit.

## Performance and LOD
Keep existing [v2 §8.1](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md#81-budget-allocation) limits: **60 fps, ≤10 ms GPU/frame on iPhone 13-class, ≤400k main triangles, ≤150k shadow triangles, ≤100 main draws**. iOS 26 is the repository minimum.

Projected longest dimension selects LOD: ≥64 px near, ≥16 px medium, ≥4 px far; below 4 px unresolved. Apply a 15% hysteresis band and approximately 0.35 s transition where appropriate. Use distance as well as screen size; a very long train doesn't justify near detail on every tiny door. Count both versions during any crossfade.

Near kit mesh targets range approximately 500–1,000 triangles, medium 160–260, far 40–80, as specified per archetype. Physical infrastructure is ordinary static-world geometry, not a new live-object allowance.

Proposed shared per-view live caps: ≤24k vehicle/aircraft triangles, ≤4k star-point triangles, ≤30k total live-layer main triangles, ≤6k dynamic shadow triangles, ≤12 live-layer draws. These totals are **inside existing scene ceilings**. Class maxima are 24 bus objects, 32 rail cars and 12 aircraft; the aggregate cap wins, so these are not simultaneous near-detail entitlements.

Prioritize selected/near useful objects, then nearby valid sources, then distant small points. Drop far details, stale expired objects and unselected simulations before exceeding caps. Badge and light geometry also count. Aerial must not draw every city's vehicle as a detailed mesh.

| Effect | Existing bucket |
|---|---|
| Opaque transit/aircraft, sky, star points, Milky Way and aurora | Base opaque world: 4.25 ms |
| Bounded nearby dynamic sun shadows | Sun/character shadows: 1.45 ms |
| Shared lunar/night fill | AO/fill/crown shaping: 0.15 ms |
| Optional interaction with existing wet/light fields | Wet/local-light additions: 0.35 ms |
| Meteor extra geometry/effect work | Weather particles: 0.20 ms |
| Shared lamps/star glare bloom | Existing post-processing total: 0.90 ms |

Proposed internal target for all live objects and sky is ≤0.65 ms inside the 4.25 ms base bucket; aurora ≤0.06 ms is inside that subset. These are budget hypotheses, not measured costs. They require displacement/simplification of other base work if the current world already fills its bucket. The 2.10 ms safety margin stays reserved.

No per-vehicle shadow-casting headlight, no aircraft light casting onto neighborhood ground, no per-star real lights, no new full-screen bloom/aurora pass. Existing real local lights remain capped at two across the scene. Use emissive masks, restrained shared bloom and bounded opaque assets. Cast dynamic shadows only for nearby useful transit within the existing shadow region; distant aircraft don't consume large shadow maps.

Star points share one instanced batch, with ≤2,000 visible points; background stars not drawn when sky is offscreen. Brightness/colour data are compact immutable buffers. Moon can be one analytic disc; Milky Way stays in the sky evaluation. Satellites/ISS reuse point rendering. Meteor/aurora are Stretch until measured and integrated.

Update data parsing, orbit propagation and route matching off the rendering hot path. Buffer snapshots rather than re-uploading every vehicle mesh on every feed refresh. Reuse geometry and material families; keep spatial batches small enough to cull. Preserve motion continuity across chunk transitions and renderer backends.

## Acceptance checks and recommendations
1. Verify generic rapid transit, double-deck commuter rail, light rail and buses remain recognisable at 5 / 20 / 40 m and aerial size without logos.
2. Verify trains remain on the correct vertical route layer and disappear behind terrain/tunnel structures.
3. Check aircraft at identical 0.5 / 2 / 5 km slant ranges with the actual viewport; compare projection arithmetic, lamp direction and altitude datum.
4. At one fixed timestamp/orientation, city vs dark profiles must suppress/reveal faint sky objects without changing constellations. Full Moon must wash out the Milky Way; new Moon must not draw a bright disk.
5. Deliberately age and remove feed data: observed→stale→expired, simulated never Live, prediction never observation, missing timestamps never fresh.
6. Repeat in grayscale, reduced motion and aerial; provenance remains readable. Replay a saved historical scene deterministically.
7. Measure a ten-minute phone walk plus aerial transition at actual drawable resolution, warm caches and comparable thermal state; record worst GPU frames, draw/triangle totals and allocations.

Top priorities: true scale and route elevation; truthful provenance before decorative fades; opaque instanced vehicle kits; one cheap coherent sky model; rare meteor/aurora effects gated and measured.

Raster sheets used built-in image generation; aircraft sheet 04 and aerial sheet 08 each received one correction edit. Exact SVGs are deterministic authored diagrams. Prompt set and provenance are included.
