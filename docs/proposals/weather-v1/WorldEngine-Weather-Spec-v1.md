# WorldEngine weather and time specification — Proposal v1

**5 October 2026 · Renderer-neutral proposal · No application code or device benchmarks**

## Evidence labels and scope

**Verified [V]** means the cited documentation, local requirement or original observation was inspected on **2026-10-05**, unless another date is given. It does not mean measured on an iPhone or observed at a particular home. **Assumption [A]** means a proposed rule, parameter, estimate, inference or calculation. **Unknown [A-U]** means evidence is unavailable; it is never silently converted to zero. These labels apply to every table and subsection below; all design formulas and expected rendering values are [A], even when driven by verified observations.

[V, local] This proposal uses [visual v2 §§3.3–3.4, 5.1 and 8.1](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md), [engine-choice §4](../engine-choice/ENGINE-CHOICE-REVIEW.md), [VISUAL_DIRECTION.md](../../VISUAL_DIRECTION.md) and [plan-m1.md](../../plan-m1.md). The current requirement is iOS 26, 60 fps and **≤10 ms GPU per frame**, including existing content. WeatherKit belongs to the host/data adapter; WorldEngine receives ordinary data. No renderer, entitlement, networking or dog-specific API belongs in this contract.

[A] The recommended first release has nine atmospheric labels, persistent wetness/snow, restrained wind, readable night fill and no lightning/audio by default. The first five labels remain compatible with the original engine plan. Haze, smoke and dust share the fog implementation with different parameters; thunderstorm shares rain/cloud rendering. They do not authorize four new simulation systems.

## 1. Neutral environment contract

[A] The host resolves provider data into a versioned `environment.json` timeline. The renderer consumes resolved values; it does not call WeatherKit or independently infer accumulation. Keep the public world package separate from private recap/location records. In a web deployment, avoid exposing original Apple data through a publicly downloadable world package; see §9.

| Field group | Required meaning and units [A] |
|---|---|
| Identity | `schemaVersion`, `modelVersion`, palette/profile hashes, solar-model version, stable seed, quality tier |
| Location | Coarse weather-cell ID and center; timezone ID; world origin is independently defined. Provider coordinates are the cell center, never a home point |
| Time | UTC `validTime`, `intervalStart`, `intervalEnd`, `fetchedAt`, `expiresAt`; `mode = live/recap/demo`; separate recorded-time and playback-time clocks |
| Provenance | Provider, dataset, source version if supplied, `dataKind = current/historical/forecast/climate/override`, source resolution, gap/trace flags, attribution metadata. Historical provider data is not automatically a station observation |
| Inputs | Cloud/humidity fractions 0–1; air temperature °C; visibility m; wind m/s and FROM bearing degrees clockwise from north; hourly liquid-equivalent precipitation mm; phase, condition code and optional snowfall liquid equivalent |
| State | One `dominantState`; intensity 0–1; independent cloud, visibility, wind, wetness and snow channels. `wetness01` and `snowCover01` are nullable; include `quality`, model reservoir and initial-state provenance |
| Light | Solar elevation/azimuth and rising/setting branch; resolved linear-light palette, direct strength, sky/ground fill, fog start/end/color; lunar phase proxy/visibility gate and stars strength |
| Presentation | Resolved scalar transition endpoints and validity; material wet/snow parameters; wind vector, particle rates/caps and optional sound/lightning flags |
| Continuity | Accumulation checkpoint timestamp, input timeline reference/hash, uncertainty flags, source change history; checkpoints only retained under an appropriate data-rights policy |

[A] Null is unknown; `0` is known absence or a deliberately identified visual fallback. Separate `estimatedState` from `displayFallback`. Never serialize NaN/infinity. Use SI-normalized values regardless of provider units. Cap rendering wind and particles while retaining the uncapped source values. Unknown schema major versions fail to a readable neutral view.

## 2. WeatherKit condition mapping

[V] Apple's current Swift `WeatherCondition` documentation enumerates **34 cases**. The table inventories all 34 using their Swift names. Source: [WeatherCondition](https://developer.apple.com/documentation/weatherkit/weathercondition); machine-readable [Apple documentation record](https://developer.apple.com/tutorials/data/documentation/weatherkit/weathercondition.json), checked 2026-10-05. The mapping, intensity defaults and overrides are [A], not Apple classifications. A REST adapter must validate its wire spelling and preserve the original string; do not infer case-sensitive wire names from Swift names.

[A] Define `clamp(x)=min(1,max(0,x))`. Quantitative intensity functions are:

- `IR(P) = 0` when known precipitation rate P is zero; otherwise `max(0.10, clamp(ln(1+P)/ln(11)))`, with P in liquid-equivalent mm/hour.
- `IS(Ps) = 0` when known snowfall liquid-equivalent rate Ps is zero; otherwise `max(0.10, clamp(sqrt(Ps/2)))`.
- `IV(V) = clamp(ln(20000/max(V,200))/ln(100))`, visibility V in metres.
- `C` is measured cloud fraction. `C?d`, `IR?d`, `IS?d`, `IV?d` mean use the quantitative value if valid, otherwise the listed default **with an assumed-intensity flag**. Clear intensity 1 means full membership, not hazardous severity. Storm intensity describes the visual storm preset, not rain rate or alert severity.

| WeatherKit code [V inventory] | Dominant state [A] | Intensity rule/default [A] | Independent handling [A] |
|---|---|---|---|
| blowingDust | dust | IV?0.65 | Warm neutral obscuration; no rain/snow inferred |
| clear | clear | 1 | C?0 |
| cloudy | cloudy | C?1.00 | No wetness reset |
| foggy | fog | IV?0.70 | No precipitation inferred |
| haze | haze | IV?0.35 | No air-quality number inferred |
| mostlyClear | clear | 1 | C?0.20 |
| mostlyCloudy | cloudy | C?0.75 | Preserve surface history |
| partlyCloudy | cloudy | C?0.50 | Intermediate cloud light |
| smoky | smoke | IV?0.60 | Desaturated warm-gray obscuration; no ash simulation |
| breezy | clear | 1 | Wind measured independently; cloud override below |
| windy | clear | 1 | Wind capped only for rendering; cloud override below |
| drizzle | rain | IR?0.15 | Liquid phase |
| heavyRain | rain | IR?0.90 | No flooding inference |
| isolatedThunderstorms | thunderstorm | 0.45 | Area coverage does not prove rain at the character |
| rain | rain | IR?0.50 | Liquid phase |
| sunShowers | rain | IR?0.30 | Preserve visible sun; use sun multiplier floor 0.65 |
| scatteredThunderstorms | thunderstorm | 0.60 | Rain rate stays independent |
| strongStorms | thunderstorm | 0.90 | No damage/tornado simulation |
| thunderstorms | thunderstorm | 0.70 | Lightning optional and synthetic |
| frigid | clear | 1 | Temperature flag; never fabricate snow cover |
| hail | rain | IR?0.60 | Retain hail flag; liquid runoff after modeled melt, no snow blanket; hailstones excluded from Target |
| hot | clear | 1 | Temperature flag; cloud override below |
| flurries | snow | IS?0.15 | Amount can be trace/unknown |
| sleet | snow | IS?0.45 | Frozen/mixed phase retained; no ice/glaze rendering |
| snow | snow | IS?0.50 | Accumulation requires amount and thermal history |
| sunFlurries | snow | IS?0.20 | Visible sun floor 0.65; independent snow reservoir |
| wintryMix | snow | IS?0.45 | Mixed phase; split liquid/frozen amount explicitly |
| blizzard | snow | 1.00 | Wind/visibility measured; fixed particle cap |
| blowingSnow | snow | IV?0.45 | **Not new snowfall**; resuspended effect only with supported existing snow; no accumulation from label |
| freezingDrizzle | rain | IR?0.15 | Supercooled liquid; do not classify as snow |
| freezingRain | rain | IR?0.50 | Keep freezing flag; no inferred ice sheet |
| heavySnow | snow | IS?0.90 | Existing caps still apply |
| hurricane | rain | 1.00 | Preserve tropical hazard flag; no lightning inferred |
| tropicalStorm | rain | 0.85 | Preserve tropical hazard flag; no lightning inferred |

[A] **Resolution order:** select the current/hourly code for the target valid time, never today's daily summary for every hour. Explicit storm/obscuration codes win their labels. A valid precipitation-type/rate combination may override a non-precipitating cloud/temperature/wind label when rate ≥0.10 mm/hour. Explicit snow+fog resolves to snow with visibility retained; explicit rain+fog resolves to rain. A storm with zero local rain remains thunderstorm with zero rain particles and zero rain accumulation. Wind-only/hot/frigid codes use cloudy instead of clear when C≥0.65; return to clear below C≤0.55. A positive rain rate with `sunShowers` does not create an overcast sky.

[A] If code and measured type disagree, preserve both, flag conflict and let contemporaneous measured phase drive particles/accumulation. Do not infer observed rainfall from precipitation probability. Freezing rain and hail must not silently become snow. Snow amount is not derived from low visibility, blizzard severity or season. Missing/future codes use valid quantitative channels; if those are missing, mark unknown and use a labeled neutral visual fallback. This is not a hazard-warning system.

## 3. Inputs and datasets

[V] The following field availability comes from Apple's [CurrentWeather](https://developer.apple.com/documentation/weatherkit/currentweather), [HourWeather](https://developer.apple.com/documentation/weatherkit/hourweather), [DayWeather](https://developer.apple.com/documentation/weatherkit/dayweather), [Wind](https://developer.apple.com/documentation/weatherkit/wind) and [MoonEvents](https://developer.apple.com/documentation/weatherkit/moonevents) documentation, checked 2026-10-05. Each usage/default in the last column is [A].

| Input | WeatherKit dataset/field [V] | Neutral use [A] |
|---|---|---|
| Condition and cloud fraction | Current + hourly `condition`, `cloudCover`; cloud-layer data also available | Atmosphere and sunlight. Layer split optional; no volumetric cloud system |
| Precipitation type | Hourly `precipitation`; current condition supplies context | Keep source time and phase; no separate current-type field assumed |
| Current precipitation rate | Current `precipitationIntensity`, a unit-bearing speed measurement | Convert explicitly to mm/hour; never consume `.value` without its unit |
| Historical/hourly amount | Hourly `precipitationAmount` | Liquid equivalent over the hour, not probability; normalized mm over exact interval |
| Snow amount | Hourly `snowfallAmount`; newer snowfall structures expose liquid equivalent as well | Prefer a verified liquid-equivalent field. Depth is not the same quantity |
| Visibility | Current + hourly `visibility` | Obscuration and fog limit; missing is not perfect visibility |
| Wind | Current + hourly `wind.speed`, `direction`, optional `gust` | Wind direction is the direction **from** which it blows |
| Temperature | Current + hourly `temperature` | Retention, melt and drying; apparent temperature is not substituted |
| Humidity / dew point | Current + hourly `humidity`, `dewPoint` | Humidity slows drying; dew point is diagnostic only in v1 |
| Moon | Daily `moon.phase`, optional moonrise/moonset | Cheap phase/above-horizon proxy; not a lunar position vector |
| Sun | Engine solar model, not WeatherKit as authority | UTC + world location; WeatherKit daylight flag is a sanity check only |
| Climate fallback | Monthly temperature/precipitation statistics | Typical background context; averages do not establish actual hourly rain or snow |

[V] Apple's [hourly precipitation amount](https://developer.apple.com/documentation/weatherkit/hourweather/precipitationamount) is liquid-equivalent precipitation. Its [hourly snowfall amount](https://developer.apple.com/documentation/weatherkit/hourweather/snowfallamount) is snow depth; [SnowfallAmount](https://developer.apple.com/documentation/weatherkit/snowfallamount) separately exposes liquid-equivalent quantities. These were checked 2026-10-05. [A] A type adapter must normalize the pinned SDK/REST response, with tests preventing a 1,000× or 1,000,000× unit error. If only snow depth is available, a 10:1 depth-to-water conversion may be an **explicit low-confidence fallback**, never an observation. Do not count snowfall plus total precipitation twice.

## 4. History availability and persistent accumulation

### Verified availability

[V] The current [hourly range query](https://developer.apple.com/documentation/weatherkit/weatherquery/hourly(startdate:enddate:)) explicitly documents history from **August 1, 2021**, forecasts up to ten days ahead and a maximum of approximately **240 hours per request**. The [daily range query](https://developer.apple.com/documentation/weatherkit/weatherquery/daily(startdate:enddate:)) has the same start date and ten-day return limit. Apple documentation JSON was read directly because the rendered pages were incomplete: [hourly record](https://developer.apple.com/tutorials/data/documentation/weatherkit/weatherquery/hourly(startdate:enddate:).json), [daily record](https://developer.apple.com/tutorials/data/documentation/weatherkit/weatherquery/daily(startdate:enddate:).json), checked 2026-10-05.

[V] Apple's [WWDC24 statistics presentation](https://developer.apple.com/videos/play/wwdc2024/10067/) describes historical averages based on records since January 1, 1970. These are climate statistics, **not a claim that actual hourly history is retrievable to 1970**. Its daily-summary example uses 30 days; that example is not an hourly-retention limit. [A-U] No authenticated WeatherKit request was made here; actual location/field completeness and service behavior still need one authenticated probe. Do not call modeled historical weather a verified street observation.

[A] Fetch a seven-day hourly warm-up before a recap, plus the walk interval, in windows no longer than 240 hours. Extend only on demand if needed and supported; merge on interval timestamp and do not double-count overlapping results. Seven days is a cost/latency choice, not a claim that all snow melts within seven days. Longer walks/ranges require ceil(hours/240) windows. Historical fetches are included in the cost model in §9; no separate published history surcharge was found on Apple's pricing page.

### Deterministic model — all formulas and constants [A]

This is an **appearance model**, not hydrology, snow-depth prediction or a safety assessment. Run once in the neutral state resolver, on fixed source-time intervals, independently of display fps. Store model version and initialization evidence. Surfaces receive a shared exposed-reference state multiplied by generated exposure/material masks; they do not each require a weather simulation.

Let Δ be interval length in hours; use hourly inputs, splitting at source boundaries and at a queried partial interval. Temperature T is °C; U is sustained wind capped at 20 m/s for this model; H is humidity fraction; C is cloud fraction. Missing H may use 0.5 **flagged as assumed**. Missing precipitation, temperature or phase makes accumulation uncertain; never fill a missing precipitation hour with zero.

For each hour, evaluate sun elevation e at its midpoint. Define `J = max(0,sin(e)) × (1 − 0.75C)` with e in radians. This dimensionless solar drying proxy is not irradiance. Hold hourly inputs constant within the hour, retaining interval totals when subdividing. A partial interval uses its fraction of hourly precipitation, an explicitly uniform-in-hour assumption.

**Phase partition:** total interval precipitation P is liquid-equivalent mm. Prefer separately reported rain/snow liquid equivalents. Otherwise assign frozen fraction f: snow=1, rain/freezing rain=0; mixed or unresolved cold precipitation uses `f=1−smoothstep(−1,2,T)`, where smoothstep(a,b,x) uses q=clamp((x−a)/(b−a)) and q²(3−2q). Sleet uses f=1 as a coarse frozen-water approximation, flagged uncertain; hail does not build the snow reservoir. A blowing-snow label adds zero precipitation unless an independent amount confirms new precipitation. Set `Ps=P×f`, `Pr=P−Ps`.

**Snow reservoir:** S is modeled snow water equivalent in mm, constrained to [0,100] for a bounded visual reservoir. This cap is an art-model limit, not a maximum real snowpack.

- Cold retention `r = clamp((2−T)/2)`; all snow retained at T≤0, half at 1°C, none at ≥2°C.
- Available water `Sa = S + r×Ps`.
- Melt potential `Mp = (0.12×max(T,0) + 0.25×J)×Δ` mm.
- Actual melt `M = min(Sa,Mp)`; new reservoir `Snew = min(100,max(0,Sa−M))`.
- Eligible surface coverage `snowCover = 1−exp(−Snew/6)`. This controls area, not translucent white paint everywhere. With S=6 mm the appearance covers about 63% of eligible exposed surface.

The noon solar term permits slow sun-driven loss even just below freezing; it is a stylized proxy. Refreezing, sublimation physics, drifting, soil heat and thermal mass are excluded. If they become important, replace the versioned model rather than secretly adjusting recaps.

**Wetness:** W∈[0,1] describes exposed-reference dampness. Interval liquid supply `Q = Pr + (1−r)×Ps + M`. Wetting coefficient `a = 0.8×Q/Δ` per hour. Drying coefficient `d = (0.04 + 0.008×max(T,0) + 0.015×U + 0.12×J)×(1−0.5H)` per hour. For constant inputs:

`Weq = a/(a+d)`

`Wnew = Weq + (W−Weq)×exp(−(a+d)×Δ)`

Clamp only for numerical roundoff. These coefficients make rain wet surfaces quickly and make drying take hours. For example T=10°C, U=3 m/s, J=0.5, H=0.5 gives d=0.16875/hour and a dry-weather half-life of about 4.11 hours. The proposal never uses an 8-second cloud transition to erase puddle appearance or snow.

**Deterministic evaluation:** integrate from an identified checkpoint with identical interval boundaries. Random frame dt must not enter accumulation. An arbitrary seek recomputes from the checkpoint or a cached hourly state, then the remaining fraction; playback speed does not alter the answer at a recorded timestamp. Clamp and round only on serialization; use double precision for reference calculations. Because snow availability caps melt, do not change integration steps without a model-version change. Within a partially evaluated hour, use the same hour-start state and midpoint solar value as the full-hour evaluation.

### Unknown history and initialization

[A] Known initialization needs a recorded model checkpoint with adequate provenance, or a justified surface observation/override. Temperature alone is not proof that an unknown deep snowpack disappeared. With no checkpoint, `W=null`, `S=null`, `snowCover=null`, and status is `unknown_initial_state`. The resolver may additionally run a clearly labeled assumed reference initialization W=0/S=0 for visual previews; it must not relabel it observed.

[A] A missing hour invalidates precise accumulated state. Preserve the last supported checkpoint and annotate the gap. An optional sensitivity envelope can compare W=0/S=0 with W=1/S=100, but those runs are **not confidence intervals**, and trace/phase uncertainty still remains. For missing data, a minimal view can show current rain/snow particles while omitting unsupported ground snow and persistent wet streaks. Any displayed default amount carries `displayFallback`, separate from known coverage.

[A] R6 implementation preserves exposure, upward normals and stable world-space noise at 0.4–1.2 m and 2–5 m scales. A renderer-shared normalized mask/CDF makes coverage 0.6 mean approximately 60% of eligible area. Use the same mask assets or specified generator across renderers; arbitrary different noise functions are not parity. Snow masks suppress underlying wet streaks/joints/leaves. No lake ice, snowbanks, footprints or plowed route is inferred. R5 darkens exposed road/stone by up to 12%, with roughness near 0.45–0.60; six maximum local streak fields, two maximum per local region. Rain intensity is not a command to set W=0.70 immediately.

## 5. Time, atmosphere and transitions

### Solar-driven light [A; v2 palette values verified locally]

Reuse the entire v2 linear-light palette table, including sky/horizon/ambient/fog colors; do not copy its colors into unrelated renderer code. Representative anchors are:

| Key | Solar branch/anchor | Direct strength | Sun color | Street fog start/end m |
|---|---|---:|---|---|
| Night | e≤−12° | 0 | #879DBC, dormant | 140 / 600 |
| Dawn | e=−4°, rising | 0.22 | #F3B58F | 220 / 850 |
| Morning | e=+15°, rising | 0.72 | #FFE1B2 | 420 / 1200 |
| Noon | Daily solar maximum | 1.00 | #FFF0D7 | 500 / 1400 |
| Golden hour | e=+6°, setting | 0.78 | #FFC788 | 350 / 1100 |
| Dusk | e=−4°, setting | 0.12 | #DE9C8D | 200 / 750 |

[A] Find actual daily solar maximum and crossing times using the existing solar model. Sort reachable anchors chronologically and interpolate scalar/color keys linearly in **linear light** between them. Skip unreachable crossings; merge coincident anchors with noon taking precedence over morning/golden hour. In polar conditions without crossings, interpolate by elevation between applicable night/dawn or daylight keys; never invent sunrise. Direct sun is zero below the geometric horizon, ramped by smoothstep(0°,2°,e) above it; negative-elevation dawn/dusk strengths are palette/fill guides, not light through the ground. The actual sun direction always comes from the solar model. Sunset hue may continue in the horizon without a direct sun beam.

[A] Aerial clear fog policy starts at 900/2500 m and remains constrained by available world/backdrop coverage. Weather modifies it, never spatial scale. Do not hide a missing shoreline using an invented weather event.

| Dominant preset at full intensity [A] | Tint / weight in linear light | Direct multiplier | Fog policy |
|---|---|---:|---|
| clear | none | 1.00 | Time-key baseline |
| cloudy | #BEC8D0 / .15 | .40 | start/end ×.85 |
| rain | #8F9FAA / .22 | .18 | start ×.40, end ×.50 |
| snow | #CDD6DF / .20 | .30 | start ×.35, end ×.45 |
| fog | #C1CACD / .30 | .12 | street 25/220 m; aerial 100/600 m |
| haze | #C8BCA8 / .12 | .65 | start ×.65, end ×.70 |
| smoke | #AAA59C / .18 | .40 | start ×.45, end ×.55 |
| dust | #C2AF91 / .20 | .50 | start ×.40, end ×.50 |
| thunderstorm | #8F9FAA / .22 | .12 | start ×.35, end ×.45 |

[A] Interpolate once between clear baseline and the selected preset using its intensity. For direct light use the **minimum**, not product, of cloud factor `1−0.6C` and the selected intensity-interpolated factor. This prevents stacked cloudy×rain×fog darkness. Sun-showers/flurries apply their stated sunlight floor only when source cloud evidence permits; flag conflicting overcast input. Visibility can further cap fog end at V and start at 0.1V, with readability floors 60/10 m respectively; ensure end≥start+20 m. Rendering limits are stylized, not a claim that meteorological visibility equals fog end. A reporting-limited high visibility value must not shorten a larger justified view. Apply one fog term in existing materials/sky; no second full-screen fog pass.

### Live transitions and hysteresis [A]

Accept only newer valid-time samples; fetch time does not outrank a more recent observation. Initial state can settle immediately behind the opening transition. Subsequently, non-precipitation label changes must remain the candidate for 90 seconds of live elapsed time; a replaced candidate restarts the hold. Do not require two network refreshes, which would cause a 30-minute delay. Wind/cloud hysteresis uses C=0.65 enter / 0.55 leave. Quantitative rain/snow enters at 0.10 mm/hour and leaves below 0.05; explicit fresh condition codes may establish a trace event with assumed intensity.

Blend accepted atmosphere/color/direct strength over **12 seconds**, fog over **20**, wind over **10**, precipitation appearance over **8 seconds on / 12 off** using smoothstep between frozen transition endpoints. A new target starts from the currently displayed value, avoiding jumps. Storm labels may enter immediately on fresh evidence, but their appearance still blends. No burst of old lightning is replayed when a packet arrives.

Model wetness/snow remains governed by recorded hours. For a newly obtained checkpoint, cosmetic convergence may take 60 seconds for wetness and 120 seconds for snow; label the correction and never feed the display-smoothed amount back into accumulation. A camera switch uses exactly the same environmental state and accumulated values; only fog/particle quality policy changes.

### Recap transitions [A]

Use the original walk's UTC clock and geographic solar position, not today's season/time. Resolve label holds on the source timeline once. Construct deterministic atmosphere keyframes with fixed source-time transition windows: 120 seconds across a changed hourly boundary for atmosphere/wind/particles, centered on that boundary, without moving the integrated hourly precipitation totals. Do not interpolate categorical precipitation phase into a fabricated measurement; mixed visuals during the blend are presentation only.

Replay/seek samples these precomputed curves and accumulation checkpoints directly. No arrival-time smoothing or runtime classifier memory affects the result; pause freezes it. Short transition durations in accelerated recaps may be visually capped by a presentation-only fade, but fixed-frame exports use the documented source-time curves. Historical refreshes create a new source-version result; do not silently change an already labeled reference render.

## 6. Wind and precipitation [A]

[V] WeatherKit wind bearing is FROM direction. [A] In the world frame east=+X, up=+Y, north=−Z, air transport is `v=(−U sin θ,0,+U cos θ)`. Thus a north wind travels toward +Z. Blend vectors rather than angles across 359°→1°. At variable direction use a stable cell-seeded display bearing and mark it assumed; do not serialize north as a measured default.

R10 maximum leafy branch-tip displacement is `A=0.03×min(U/12,1)` metres; a dry leafy tree at 4 m/s moves at most 1 cm. Multiply by 0.3 for bare branches and 0.7 for wet/cold foliage. Trunk displacement is zero. One sine per tree, frequency `0.10+0.08×min(U/12,1)` Hz, direction parallel to wind, and a stable per-tree phase. Fade motion from 100 to 150 m; no added tessellation, per-leaf solver or gust-frequency noise. Gusts may smoothly modulate amplitude up to the same 3 cm cap, never enlarge it.

Use an approximately 30×20×30 m camera-local precipitation box, depth tested and hidden indoors/under supplied shelter masks where available. Initial caps: rain **600** simple streaks, snow **300** simple flakes, airborne autumn leaves **12**; a blend shares a global **600-particle cap**, with leaves taking slots rather than added overhead. Rain downward speed starts at 12 m/s, snow at 1.2; horizontal drift is 0.2×wind capped at 2 m/s for rain and 0.35×wind capped at 3 m/s for snow. These are artistic motion values, not fall-speed measurements.

Particle count scales with intensity, but never changes model water input. Keep total projected transparent coverage near 8% of screen as a starting cap; particle count alone cannot control overdraw. No collisions, splashes, trails, accumulating particle geometry or per-particle lights. Aerial view may halve counts or omit local precipitation if unconvincing at scale. R4 ground leaves stay static, darken when wet and are masked by snow; at most 12 airborne leaves share the weather bucket. Blowing snow needs supported ground snow and adds no reservoir water.

## 7. Night, rare events and optional sound

### Cheap night [A]

[V] [MoonPhase](https://developer.apple.com/documentation/weatherkit/moonphase) and [MoonEvents](https://developer.apple.com/documentation/weatherkit/moonevents), checked 2026-10-05, provide phase and rise/set context, not measured scene illuminance. [A] Map new/crescent/quarter/gibbous/full to illuminated-fraction proxies **0/.15/.5/.85/1**, symmetric for waxing/waning. These category proxies are not an ephemeris. Interpolate across days with the moon's circular phase ordering if available; do not interpolate full directly to new through an incorrect daily discontinuity.

Let lunar contribution `B = phaseProxy² × (1−C)² × aboveHorizonGate`. Derive the gate from complete surrounding rise/set events, ramping over 15 minutes; missing/ambiguous events give B=0 with unknown status. Do not assume every full moon is above the horizon. Add at most **0.03** of reference noon intensity to the existing artistic night sky fill, capped within v2's 0.20–0.35 sky-fill range. Ground fill stays within 0.06–0.12 and can halve on wet ground. Preserve coat colors and dark midtones. No new shadow-casting moon light, moon shadow map or fictitious sun.

Stars are a sparse **≤128** stable sky accents, in the existing sky draw. Strength is `nightFactor×(1−C)³×(1−obscurationIntensity)×(1−0.3B)`, where nightFactor ramps from 0 at −6° to 1 at −12°. Set obscurationIntensity to the active haze/smoke/dust/fog intensity, otherwise zero; force stars off during active rain/snow/storm. No twinkle noise or star particles. A positioned moon disk waits for a real lunar-position model; phase alone cannot locate it. Windows remain a stable 20–30% household selection at night, with no per-frame random toggling.

### Lightning — Stretch, default off [A]

WeatherKit storm condition is not a strike event stream. Any flash must be labeled procedural, not an actual replay of a strike. If enabled, the neutral resolver emits a seeded event list in source time, at most one brief event per 60 seconds, with total diffuse/exposure lift ≤10% and a smooth 0.3-second envelope. No bolts, point lights, new shadows, bloom bursts or thunder delay inferred from an unknown distance. A fixed event list makes seeks deterministic. Disable during reduced-effects mode. Even this small effect needs a measured budget check; “one uniform” does not prove zero cost.

### Ambient audio — Stretch, default off [A]

Clear daylight may use sparse birds; clear warm night may use crickets only when regional/seasonal metadata supports them. Cloudy stays quieter; rain uses one loop, snow is mostly quiet, and wind scales a low-level loop. Smoke/dust has no invented crackling-fire sound. At most two simultaneous preloaded loops plus one short occasional cue, 5-second crossfades, conservative loudness, proper app mute/audio-session behavior and separately licensed assets. Stereo panning is sufficient; no physics audio or per-tree sources. Audio uses CPU, memory, download and battery rather than a GPU bucket; provisional cap 8 MB decoded working audio and ≤0.2 ms average audio-thread work requires measurement. No assets are supplied here.

## 8. Performance: existing v2 envelopes only

[V, local] v2 §8.1 allocates **7.90 ms content + 2.10 ms reserved margin = 10.00 ms**. [A] The assignments below consume parts of those existing buckets, not additional allowances. Figures remain unmeasured targets.

| Existing bucket | Ceiling | Weather/time work assigned within it [A] |
|---|---:|---|
| Base world + host character | 4.25 ms | One material fog term, sky/cloud color, stars in sky draw, normal world/water rendering, time uniforms; no volumetrics |
| Sun + character shadows | 1.45 ms | Existing sun shadow and contact solution; weather changes strength, not count; no moon/lightning shadow map |
| Vertex AO + fill + crown shaping | .15 ms | Existing AO/fill, night/moon fill modulation, one R10 sway evaluation |
| Surface pattern additions | .25 ms | R6 snow mask/exposure alongside R3 lawn and R7 seams; combined worst variant, not .25 each |
| Near geometry additions | .35 ms | Existing bevel/leaves/tufts; optional ≤24 snow caps within 20 m and .02–.05 m thick fit the existing aggregate geometry allowance |
| Wet/local-light additions | .35 ms | R5 wet variant, ≤6 streak fields, ≤2 per region, ≤2 nearby unshadowed lights |
| Weather particles | .20 ms | All rain/snow/airborne leaves together; counts/overdraw reduced to fit |
| Post-processing | .90 ms | Existing .15 grade/composite + .35 bloom + .40 aerial blur. Optional lightning uniform uses existing work; no added pass |
| Reserved margin | 2.10 ms | Remains reserved; no new weather decoration financed from it |
| Total | **10.00 ms** | Same budget in street, aerial and transition |

[A] No separate per-frame atmosphere simulation on CPU. Resolve provider/accumulation off the render thread; interpolate a small uniform block. Use hourly checkpoints; loading ten days of data must not trigger synchronous mesh rebuilds. Weather changes masks/materials, not the static city geometry. Renderer memory limits need a separate device baseline; no claim of a measured RAM budget is made here.

[A] Measure all fixtures plus rainy/snowy dusk during aerial transition at fixed drawable resolution on physical iPhone 13. Record max/p95 GPU time, presentation stalls, thermal state and memory over ten minutes. A p95≤10 ms does not pass if steady-state frames exceed the owner's maximum. On web, requestAnimationFrame is not a GPU timer. If GPU timing is unavailable, the budget is unverified. Degrade in order: disable Stretch, reduce particles/transparent area, remove optional caps, reduce local streaks, reduce aerial blur; preserve true geometry, solar direction, source state and character readability. Freed budget becomes margin.

## 9. Fetching, caching, pricing and rights

### Grid and request policy [A]

Use a provider-facing **0.05° latitude × 0.05° longitude grid**, centered at `−90+(i+0.5)×0.05` latitude and `−180+(j+0.5)×0.05` longitude, with i/j determined by floor division after longitude wrapping. In Denver this is roughly 5.6×4.3 km; physical width varies with latitude, so this is a coarse cell policy, not equal-area tiling. Send only its center. A server request carries cell/time/language/datasets, not a user ID, home coordinate or route. Avoid location-bearing logs. Coarsening is not a guarantee of anonymity and sacrifices local shower accuracy.

Refresh **every 30 minutes while active**, or **15 minutes during changing precipitation/storm conditions**. Combine needed datasets where supported. Stop polling while inactive; no all-day or all-grid prefetch. On cell change, wait until 500 m inside the new cell or 60 seconds of continued presence; blend the new state without sending the exact path to the provider. Keep solar calculation tied to the world/recorded position, independently of the weather cell.

### Cache comparison [A]

| Approach | Benefit | Cost / constraint |
|---|---|---|
| On-device first | Simple Swift integration; no custom weather server; cell rounding happens locally | Each device consumes requests; little pooling; device offline state needs expiry and attribution |
| Server cache | Shared cell/time requests, single-flight deduplication, centralized quota and web/Android support; signing key stays server-side | Hosting/operations, secure access and a cache-rights policy; dispersed users may share almost nothing |
| Recommended staged hybrid | Start local for native validation; introduce an on-demand cell proxy when measured use justifies it | Do not build a global historical database as a “cache”; retain only bounded active-request results |

[A] Suggested operational policy: current data fresh for 15–30 minutes, eligible stale response up to two hours during a fetch failure, then discard that response and use the fallback chain. This is a proposed conservative TTL, **not an Apple-promised retention entitlement**. A short-lived cache of a requested historical window can accelerate repeated playback in the same session. The source's expiry/metadata must be honored where stricter.

### Published quota and modeled monthly costs

[V] [Apple's WeatherKit pricing](https://developer.apple.com/weatherkit/), checked 2026-10-05: **500,000 calls/month included per Developer Program membership**; published total-quota tiers include 1M $49.99, 2M $99.99, 5M $249.99, 10M $499.99, 20M $999.99, 50M $2,499.99, 100M $4,999.99, 150M $7,499.99 and 200M $9,999.99. Quota does not roll over. Prices below exclude membership, tax, hosting and other services; do not add the included quota on top of a purchased tier.

[A] Model a 30-day month, N **daily active** users, one 60-minute walk/day. Thirty-minute refresh means two requests (start and minute 30); 15-minute refresh means four. Add one on-demand historical recap request per user/day. Assume one bundled request counts as one call; verify actual dashboard accounting for the selected APIs, history windows and retries. These are workload assumptions, not forecasts from registered-user counts.

| Daily active users | 30-minute live + one recap: 90N calls | Monthly WeatherKit tier cost | 15-minute live + one recap: 150N calls | Tier cost | 80% shared-cache hit rate on 90N, assumed | Tier cost |
|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 90,000 | $0 incremental | 150,000 | $0 | 18,000 | $0 |
| 10,000 | 900,000 | $49.99 | 1,500,000 | $99.99 | 180,000 | $0 |
| 100,000 | 9,000,000 | $499.99 | 15,000,000 | $999.99 | 1,800,000 | $99.99 |

[A] Formula: `calls=30×N×(liveRequestsPerDay+recapRequestsPerDay)×(1−cacheHitRate)+extraWindows+retries`. An 80% hit rate requires overlapping cells/time windows; private historical requests may have far lower reuse. At 100k users, uncached all-day 30-minute polling alone would create 144M calls/month and require the 150M tier, $7,499.99—avoid this architecture. Budget 10% request reserve and monitor quota; that can push a near-boundary estimate to a higher tier. Example: 1.8M with 10% reserve remains under 2M; 9M becomes 9.9M under 10M. Historical queries use normal call accounting in this estimate because no separate history price is published; confirm against the account's actual meter.

### Storage and recap boundary

[V] Apple's [Developer Program License Agreement, Attachment 8 §§1.5–1.6](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/), checked 2026-10-05, restricts bulk/secondary weather databases and permits caching/storage only on a temporary, limited performance basis unless documentation expressly permits more. [A] Therefore this proposal does **not** assume permission to archive raw Apple hourly timelines indefinitely, even if JSON fields are renamed. Persistent transformed state may still reveal provider data; a “value-added” label alone is not proof that storage is permitted.

[A] Default persistent recap record stores the user's own UTC walk timing, route/cell sequence, camera/playback choices and model/profile versions; **refetch historical WeatherKit on replay**, within a temporary session cache. For byte-for-byte permanent replay, offline forever, public weather JSON or B2B exports, confirm applicable rights with Apple or select a historical provider/license that expressly permits retained inputs. Keep a provider-neutral route to that alternative. Do not make a private archive of all visited cells merely to avoid future calls.

### Offline fallback [A]

Order: valid session snapshot → last known same-cell state within the proposed two-hour stale window → licensed, bundled monthly climate defaults → neutral seasonal palette. Show “last updated” or “typical conditions” in weather details. Stop presenting old storm/precipitation as live after expiry. Monthly averages may choose typical temperature and subdued cloud background, but **do not manufacture observed rain, wetness, snow or smoke**. Surface state remains unknown unless a permissible checkpoint supports it. Missing monthly cloud/wind data uses labeled calm/neutral appearance. Continue astronomical time correctly offline. A recap without a permissible saved snapshot or network uses a labeled approximate replay, never silently today's weather.

## 10. Attribution

[V] Apple requires clear Apple Weather branding and a legal link when displaying its weather data; transformed value-added products require source attribution plus notice that Apple data was modified. [Apple's attribution section](https://developer.apple.com/weatherkit/), checked 2026-10-05. The API supplies appropriate light/dark mark URLs and `legalPageURL`; `legalAttributionText` supports cases unable to display the legal page. See [WeatherAttribution](https://developer.apple.com/documentation/weatherkit/weatherattribution) and [REST attribution assets](https://developer.apple.com/documentation/weatherkitrestapi/attribution), checked 2026-10-05. Use current supplied assets/links, not a hand-drawn substitute.

[A] Proposed placement: a legible Apple Weather mark and “Weather data sources” link in the visible weather/recap information strip alongside the world, with “Weather visualization modified from Apple Weather data.” The legal link opens the provider-supplied page. Repeat on the share page; a settings-only buried credit is not the proposed implementation. Exported video/stills carry an appropriate visible credit and source/modified-data notice, with the legal link in the accompanying share page/metadata. Confirm the noninteractive-export treatment for the chosen distribution before shipping. Existing OpenStreetMap attribution remains separately visible. The fixed strip and wording are our placement proposal, not an Apple-specified pixel layout.

[A] Preserve provider identity when falling back to NOAA/climate/other sources; do not brand a non-Apple fixture as Apple weather. V1 does not show alerts. If added, Apple's separate alert-link, issuing-agency and unmodified-text requirements must be implemented; an artistic thunderstorm label is not an alert.

## 11. Recorded-walk recap contract [A]

To recreate the original light and weather, retain the user's original UTC start/end and timestamped route in the host's private record; timezone is display context, not the clock. Record the coarse weather-cell sequence, world/solar/model versions, camera track and playback speed. The world package stays generic and has no exact home coordinates or user identity.

At replay request, obtain hourly history for the original cells/time, a seven-day accumulation warm-up and the matching daily moon context, with source times and retrieval/version metadata. Preserve distinctions between historical values, forecasts that were available during the walk, and current values. A later provider revision may improve reconstruction but change the picture; expose that as a new resolved version. Hourly historical data can represent the walk's conditions without proving exactly when a five-minute shower occurred at one sidewalk.

Within an authorized temporary session, the resolved timeline contains normalized inputs, nullable accumulation states, source quality, solar outputs, light keyframes, stable seeds and any overrides. Export renderer-neutral state from that single resolver to both RealityKit and three.js. Seeking backward starts from the same checkpoint; it does not reverse a drying equation. Repeated seek/pause/speed changes must return the same state at the same original timestamp.

For permanent exact replay, the required technical record is a versioned resolved timeline/checkpoint plus sufficient provenance and assets; the required **rights** are a separate unresolved prerequisite in §9. Do not promise exact offline historical replay while relying solely on future network retrieval. An already rendered video is operationally convenient, but commercial export/retention rights still need the chosen provider policy.

## 12. Denver fixtures and reproducibility

[V] [weather-fixtures.json](weather-fixtures.json) contains **10 real timestamped Denver-area cases**, with **487 unique hourly KDEN observations** retrieved from the [Iowa Environmental Mesonet archive](https://mesonet.agron.iastate.edu/request/download.phtml?network=CO_ASOS) on 2026-10-05. Each raw observation has its exact retrieval URL and METAR. IEM aggregates airport reports with limited quality control; it is not WeatherKit. KDEN is far east of Sloan's Lake, and the March storm had a marked east-west snow gradient. Fixtures test source adapters/math, not neighborhood weather accuracy.

| Fixture | Local time, America/Denver | Evidence / expected settled atmosphere [V source; A output] |
|---|---|---|
| Clear golden hour | 2023-10-22 17:53 MDT | Few clouds; clear; computed sun elevation 2.20°, azimuth 253.39° |
| Overcast | 2023-05-15 10:53 MDT | OVC layer; cloudy |
| Light rain | 2023-05-10 18:53 MDT | −RA; 0.03 inch prior-hour precipitation; rain |
| Thunderstorm | 2023-05-10 16:53 MDT | +TSRA; thunderstorm with separately measured rain |
| First snow | 2023-10-28 06:53 MDT | SN/FZFG; snow wins label, low visibility remains |
| Morning after heavy snow | 2024-03-15 08:53 MDT | Post-storm BKN sky; cloudy with uncertain ground coverage |
| Melting snow scenario | 2024-03-16 12:53 MDT | Above freezing after the documented storm; cloudy; modeled melt, not an observed melt rate |
| Morning fog | 2023-05-10 07:53 MDT | FG, 0.5-mile visibility; fog |
| Wildfire haze | 2023-05-19 11:53 MDT | HZ, 1.25-mile visibility; haze, not a fabricated FU report |
| Windy day | 2023-05-12 12:53 MDT | Sustained 28 kt, gust 38 kt; cloudy plus independent strong wind |

[V] NWS confirms [October 28, 2023 as first measurable snow](https://www.weather.gov/bou/DenverFallWinterStatistics), [March 13–15, 2024 storm context and 5.7-inch DIA total](https://www.weather.gov/bou/March13_15_2024FrontRangeSnowstorm), and [May 18–26, 2023 wildfire smoke/haze](https://www.weather.gov/media/bou/May2023Climate.pdf). These event summaries do not supply a measured surface-coverage fraction at fixture time.

[A] METAR cloud categories become fractions by declared midpoint assumptions; reported 10-mile visibility is reporting-limited. Routine hourly precipitation is treated as the preceding hour's liquid-equivalent accumulation; special reports are excluded to avoid overlap. Trace remains `T` in raw data and uses an explicitly assumed 0.127 mm reference amount inside a conservative [0,0.254] interval. Absent present-weather code is not proof of no prior-hour precipitation. Temperature-driven phase reconstruction is flagged. All such transformations are documented in JSON.

[A-U] None of these observations establishes initial surface wetness or ground snow cover. Accordingly the primary expected `wetness01`/`snowCover01` are **null**, with unknown status. Each fixture also supplies numeric **controlledModelReference_assumption** results from W=0/S=0 and an alternate W=1/S=100 initialization over the included 48- or 72-hour history. This supplies reproducible numerical tests without calling an assumed initial snowpack historical fact. Do not replace nulls with the reference run in production without the visible assumption flag.

[A] Solar outputs are computed from the existing `Sources/WorldGeo/SolarPosition.swift` equations, without refraction, at the public station coordinate; its SHA-256 is recorded. [NOAA calculation details](https://gml.noaa.gov/grad/solcalc/calcdetails.html), checked 2026-10-05, explain the underlying solar approach. This review's arithmetic is not an independent astronomical validation of the engine. No lunar observation is present in these fixtures; moon/night-specific tests remain to be added.

[A] Replay checks: exact dominant label; scalar tolerance 0.00001; accumulation tolerance 0.0001; solar tolerance 0.05°; unknown values must remain null. Independently test freezing rain ≠ snow, blowing snow adds no snowfall, cloud transition preserves reservoirs, source gaps stay unknown, 359°→1° wind takes the short vector path, and seeking reproduces the reference hour. Measure visual/performance parity separately; passing JSON arithmetic does not establish a GPU budget.

## 13. Open questions and decisions before implementation [A-U]

1. Can Apple confirm the intended persistent transformed recap/video use and retention policy, or should permanent exact replay use a differently licensed weather archive? This affects storage architecture, not just credit text.
2. What does one authenticated seven-day historical request return at the selected coarse Denver cell: all required hourly fields, trace/missing semantics, moon data and billed-call accounting? The docs establish advertised access, not this response.
3. Does product language promise approximate historical conditions or exact as-seen-at-recording replay? Refetching can produce revised provider data.
4. How should the app present unknown accumulation: omit unsupported ground snow, show a visibly approximate reference model, or accept a user-supplied initial condition? Never infer a fully snow-covered neighborhood from winter alone.
5. Is the proposed coarse grid adequate for the first release's neighborhood showers and terrain differences? Validate against actual user experience without sending exact homes.
6. Which cross-renderer mask representation provides consistent R6 coverage and avoids duplicate procedural semantics? Which renderer exposes reliable GPU timings on the target device?
7. Are provider-cleared long-term monthly climate defaults available for all intended regions? Temperature/precipitation averages alone do not supply cloud/wind distributions.
8. Can a matched rainy/snowy dusk scene fit the existing buckets on iPhone 13 for ten minutes? Until measured, reduce optional work and keep lightning/audio off.

## Recommended decisions [A]

1. Keep one neutral resolver and one versioned UTC timeline; renderers consume state rather than interpreting WeatherKit independently.
2. Separate live atmosphere from persistent wetness/snow, and carry unknown accumulation explicitly.
3. Use documented post-August-2021 hourly history for on-demand recaps; settle permanent replay/storage rights before creating an archive.
4. Request coarse cells only while active, with 30-minute normal / 15-minute changing-weather refresh and measured cache reuse.
5. Deliver Target within v2's existing 7.90 ms content allocation; keep lightning and ambient sound Stretch until device measurements justify them.
