# WorldEngine sky and seasons — design proposal v1

**5 October 2026 · Renderer-neutral · Proposal and fixture data only**

## 0. Evidence and boundaries

**[V]** identifies a source statement or local inspection verified on **2026-10-05**. **[A]** identifies a proposed policy, equation adopted for this design, numerical calculation, illustrative calendar or unmeasured target. **[A-U]** identifies an unresolved or unavailable input. Labels at the beginning of a paragraph, subsection or table apply to everything in that scope. Calculated fixture values are **[A], not observations**; checking a calculation is not verifying the actual sky or vegetation. All source IDs resolve in §9. Dates after this document date are scenarios, not forecasts.

[V, L1–L5] Read first: `CLAUDE.md`, weather v1 §§5/7, visual v2 §§3/8.1, `SolarPosition.swift`, and `VISUAL_DIRECTION.md`. WorldEngine uses true locations, procedural visuals, stable seeds, street and aerial views, iOS **26.0** minimum, and a **60 fps / ≤10 ms GPU** target on iPhone 13-class hardware. This document changes none of those files. The host owns weather acquisition and app notifications; the environment contract contains ordinary data and mathematics.

[A] Recommended scope: reuse the existing sun model; add event finding; adopt a small analytical lunar ephemeris with topocentric correction; package 256 real bright stars with at most 128 visible; resolve vegetation into continuous, place-aware appearance channels. No texture assets, atmospheric scattering simulation, new shadow maps or per-tree daily weather simulation.

## 1. Shared environment contract

[A] Extend the weather proposal's `environment.json`, retaining its schema-major rejection, provenance, unknown-value and source-time rules. The following is a proposed contract, not a claim about the currently shipped package. One neutral resolver produces both app event data and renderer inputs. Neither renderer calls an astronomy/weather service.

| Proposed group [A] | Contents and conventions |
|---|---|
| `sky.identity` | Schema/model versions; ephemeris coefficient revision; catalog and palette hashes; horizon policy; timezone database version |
| `sky.observer` | World reference latitude/longitude degrees, east-positive longitude, elevation metres, IANA timezone; reference point separate from a coarse weather cell |
| `sky.clock` | UTC instant, `live/recap/demo`, validity interval; time of the recorded world, not playback wall clock |
| `sky.sun` | Geometric elevation, true-north clockwise azimuth, scene direction, rising/setting/stationary branch, daily maximum |
| `sky.moon` | Geometric topocentric altitude, azimuth, distance km, physical angular diameter, phase angle, illuminated fraction, phase longitude, bright-limb angle/frame, direction, disk light vector, visibility and fill scalars |
| `sky.events` | Civil-date start/end UTC; arrays of crossings and intervals with UTC timestamps, type, status, convention and accuracy class; daylight seconds |
| `sky.stars` | Catalog reference, of-date orientation matrix or resolved directions, magnitude/color scalars, ordered visible IDs, global visibility strength |
| `phenology.inputs` | Region/cohort profile; normal period, grid/station and elevation; recent-temperature series/checkpoint; coverage and missing-data flags |
| `phenology.resolved` | Per-cohort leaf/flower/color/drop/grass fractions, four palette weights, stable per-tree offset recipe and valid interval |
| `provenance` | Source URLs/IDs, checked/fetched time, `observed/modeled/climate/assumed/override`, confidence, missing intervals, source/model/profile hashes |

[A] Angles serialize in degrees; trig uses radians. Right ascension carries an explicit unit (hours or degrees). Scene directions are **east +X, up +Y, north −Z**, matching the current sun: `(cos(e) sin(A), sin(e), −cos(e) cos(A))`. Store double precision for astronomy; downcast only rendering uniforms. Interpolate unit vectors with normalized interpolation, never azimuth across its 359°/0° seam. At zenith, azimuth can be null while the vector remains valid.

[A] Unknown is null plus a reason, never zero or a fictitious midnight event. Separate an unknown scientific estimate from a labeled visual fallback. No private addresses or host-user records enter the public world package. Astronomical position uses the package reference point; optional terrain visibility uses a separate azimuth/elevation horizon profile. Moving the camera within the world does not rotate the astronomical sky incorrectly.

## 2. Sun events and app queries

### 2.1 Definitions and math

[V, S1/S2] Standard level-horizon sunrise/sunset use the solar center at approximately **−0.8333°**, combining solar radius and conventional horizon refraction. Civil and nautical twilight boundaries use geometric center elevations **−6°** and **−12°**. Local solar noon is upper meridian transit. Atmosphere and terrain change observed visibility.

| Event or interval [A, adopted conventions above from S2] | Rule using geometric center elevation e |
|---|---|
| Sunrise / sunset | Upward / downward crossing of −0.833333° |
| Solar noon | Upper transit, solar hour angle H = 0; report daily elevation maximum separately |
| Civil dawn / dusk | Upward / downward crossing of −6° |
| Nautical dawn / dusk | Upward / downward crossing of −12° |
| Morning golden interval | Increasing-elevation portion in **[−4°, +6°]** |
| Evening golden interval | Decreasing-elevation portion in **[−4°, +6°]** |
| Morning / evening blue interval | Corresponding branch in **[−6°, −4°]** |
| Daylight length | Total duration e ≥ −0.833333° within the requested local civil day |

[A] Golden/blue definitions are **product conventions**, not universal astronomical standards and not necessarily 60 minutes. They align the weather/v2 −4° dawn/dusk and +6° golden anchor. Cloud cover changes appearance, not event timing. Apps should distinguish “golden-hour elevation window” from “clear golden light.” A −4° sun does not cast direct shadows.

[A; adopted from L4/S1] Reuse the existing Julian-century declination δ and equation-of-time E. For latitude φ, longitude λ east-positive and UTC minutes u, use:

- True solar minutes `T = mod(u + E + 4λ, 1440)`; hour angle `H = T/4 − 180°`.
- `sin(e) = sin(φ) sin(δ) + cos(φ) cos(δ) cos(H)`.
- A fixed-declination crossing estimate has `cos(H₀) = [sin(e₀) − sin(φ) sin(δ)]/[cos(φ) cos(δ)]`.
- Initial UTC noon estimate is `720 − 4λ − E` minutes, retaining its UTC date displacement. Re-evaluate E and δ at the candidate time. Final events are roots of the full time-dependent model, not the fixed-declination estimate.

[A] Search the actual local-day UTC interval plus neighboring time for boundary context. Bracket crossings, refine by bisection/Brent to ≤1 second, classify direction, deduplicate boundary roots, and sort by UTC. Do not detect noon through azimuth 180°: tropical transits can be north of the observer. Solve unwrapped hour angle for upper transit. Optimize elevation independently for the light-key maximum, since declination changes during the day.

[A] A 10-minute initial grid is sufficient for these midlatitude fixtures, **not a global proof against missed grazing events**. Production must locate extrema and subdivide near thresholds, retaining tangent contacts separately. Intersect all threshold intervals with the civil day; return arrays, even where ordinary dates have one morning and one evening interval. Report `normal`, `always_above`, `always_below`, `grazing`, `no_crossing_this_day`, `unsupported_date` or `unknown`. Never clamp an impossible arccos argument into a fabricated crossing. Near grazing, uncertainty should include the possibility of no event.

### 2.2 Accuracy, time and horizon policy

[V, S1] NOAA documents theoretical sunrise/set accuracy near one minute within ±72° latitude and ten minutes beyond, while warning that observed conditions differ. It also now marks its calculator as unsupported. These statements do not certify this Swift implementation.

[A] Acceptance targets for **1950–2050**, relative to an independent ephemeris with matching conventions: sun direction ≤0.1°, ordinary sun/twilight events ≤2 minutes for |latitude| ≤65°; no fixed event-time guarantee near grazing/polar boundaries. The current file's “well under 0.5°” comment is a local claim [V, L4], not a measured result. Validate angle error as vector separation, not raw azimuth near zenith. Round app times to minutes; keep seconds internally. Report convention and model quality beside results.

[V, S3] IANA maintains timezone/DST rules. [A] Accept UTC instants or a local date plus an IANA ID, never a bare offset as the lasting location identity. Obtain the next local midnight through the calendar, not by adding 86,400 seconds. Reject nonexistent local input times; ambiguous times require an offset/fold. These fixtures exercise Denver's 23-hour March 8 and 25-hour November 1, 2026 days. Offset-bearing timestamps remain explicit. Pin timezone data for deterministic recaps, and preserve previously resolved event UTC values if rules change.

[A] Use UTC as an approximation to UT1 at this precision; a lunar adapter retains its own TT/ΔT convention. Do not feed timezone-shifted time into the ephemeris. Beyond the supported date range, label unsupported rather than silently promising the same accuracy.

[A] Standard events use a level local horizon and no altitude-derived horizon dip. Denver's elevation above sea level is **not** height above unobstructed surrounding terrain. Optional `visibleSunrise/visibleSunset` can later solve the apparent upper limb against a DEM horizon H(A), with separate provenance; those must not replace standard event fields. Buildings can occlude the disk but do not redefine civil twilight. No terrain data is included in the fixtures.

### 2.3 Small app-facing API shape

| Query [A; conceptual interface, no implementation] | Result |
|---|---|
| `eventsForLocalDate(date, observer, conventions)` | Civil-day bounds, sunrise/set arrays, transit, daily maximum, twilight crossings, golden/blue intervals, daylight seconds, per-threshold statuses, provenance |
| `nextGoldenHour(afterUTC, observer, includeActive=true, searchDays=370)` | Earliest interval whose end is after the input; start/end UTC, branch, `active/upcoming/not_found_within_horizon/unknown`, `secondsUntilStart=max(0,start−now)`, horizon end |
| `daylightForLocalDate(date, observer)` | Seconds and day duration, convention, continuous-day/night flags; polar day is the length of that civil day, not automatically 24 hours |

[A] An active interval is returned as active, not as tomorrow's “next.” With `includeActive=false`, require start > input. A polar search can stop at 370 civil days and return an explicit bounded-search result. Cache requests off the render thread. Host notification wording and refresh schedules remain outside WorldEngine.

### 2.4 Extensions to SolarPosition.swift

[V, L4] The file already computes a geometric solar center, NOAA-style E/δ, north-clockwise azimuth and the correct scene vector; it has no event API, observer height, timezone calendar, refraction or polar-event status model.

[A] Keep that position path authoritative for lighting. Expose/reuse its E/δ/hour-angle intermediate values in a neutral astronomy layer; add root/interval and transit finding, civil-day handling, validation/status types and optional visibility-horizon support. Normalize signed remainders consistently for pre-1970 times across Swift/JavaScript. Add geometric/apparent names so refraction is never applied twice. Add no renderer imports. Weather §5's direct sun remains zero for e ≤0°, ramping with smoothstep(0°,2°,e); conventional sunrise can therefore precede direct scene lighting.

[V, L6] The current plan labels a September 22 scene at roughly 13° elevation “golden hour.” [A] Keep it as a warm-light **art preset**, distinct from the app's −4° to +6° interval; do not silently change this event definition to match a screenshot.

## 3. Moon

### 3.1 Low-precision ephemeris and outputs

[V, S4/S5] Astronomy Engine advertises approximately one-arcminute accuracy and an MIT license. Its lunar position is an analytical series derived from the Improved Lunar Ephemeris/Brown lunar theory, documented in `GeoMoon`; it does not require downloaded ephemeris tables. Its topocentric coordinates account for observer parallax.

[A] Adopt the **pinned Astronomy Engine lunar series**, or a matching port into the neutral resolver, as v1's low-precision model. Pin revision `865d3da7d8112bbc7911238052c6af4aaf877181`; the fixture JSON records the fetched source SHA-256. This is a model recommendation, not a new dependency installed in WorldEngine. A package producer can resolve it before delivery; browser and native clients consume the same data. The existing solar model still owns sun event/light direction. Use the lunar reference's internally consistent Sun vector for lunar phase geometry; the tiny model difference must pass the angular tolerance.

[A] Proposed acceptance over 1950–2050: topocentric direction ≤0.15°, illuminated fraction absolute error ≤0.01, and ordinary moonrise/set ≤5 minutes against an independent reference under matching horizon/refraction conventions. These are port acceptance targets, not measured guarantees. The upstream one-arcminute statement does not include an arbitrary WorldEngine port, local refraction or terrain. Near zenith use vector error; near new/full moon, bright-limb angle is ill-conditioned and may be null. No eclipse, occultation or lunar-terrain accuracy is promised.

[A] Math contract: obtain geocentric Moon vector M, Sun vector S and ellipsoidal observer vector O in the **same epoch/frame and distance units**. Topocentric Moon direction is `normalize(M−O)`. Rotate of-date equatorial coordinates into the local horizontal frame. Parallax must be included: a geocentric Moon direction is not adequate near the horizon. Refraction is omitted from the returned geometric altitude.

[A] Let `l=normalize(S−M)` point from Moon toward Sun and `v=normalize(O−M)` toward observer. Phase angle is `i=acos(clamp(dot(l,v),−1,1))`; illuminated fraction is `k=(1+cos(i))/2`. Thus full moon has i≈0°, new moon i≈180°. Also return **phase longitude** `mod(lunar ecliptic longitude − solar ecliptic longitude,360°)` to distinguish waxing (0–180°) from waning (180–360°). Do not confuse this with phase angle, phase fraction of a month, or k. The fixture phase angle and k are topocentric; phase longitude is geocentric.

[A] With topocentric of-date right ascensions α and declinations δ, the position angle of the bright limb is:

`χ = atan2(cos(δs) sin(αs−αm), sin(δs) cos(δm) − cos(δs) sin(δm) cos(αs−αm))`.

[A] χ is measured from celestial north toward celestial east in the Moon tangent plane. The parallactic angle is `q=atan2(sin(Hm), tan(φ) cos(δm)−sin(δm) cos(Hm))`; χ−q gives orientation relative to local zenith, modulo ±180°. Camera roll still needs applying. Prefer basis-vector projection into camera right/up so a screen-axis handedness mistake cannot mirror the crescent in Sydney. Set angle null if the projected light direction is degenerate; full/new disk shading can still be computed.

[A; convention from S2] Moonrise/set solve `h_topocentric_geometric + 34/60° + asin(1737.4 km / distance_topocentric_km) = 0`, upward/downward. The chosen lunar radius is an adopted constant [A]. This includes physical radius and conventional refraction; do **not** add a second parallax term after topocentric conversion. Use extrema-aware searches as for the Sun. No rise or no set in a civil day is valid; return event arrays and a day-start above/below flag rather than guessing from phase. The disk's exaggerated visual radius never affects event times.

### 3.2 Procedural disk and weather integration

[A] Render an analytic disk in the sky batch, without an image texture. For normalized disk coordinates x/y, reject x²+y²>1; let the visible unit-sphere normal be `n=(x,y,sqrt(1−x²−y²))`. The local z basis points toward the observer; project l into that same basis. The sign of `dot(n,l_disk)` defines the lit side and terminator; use a bounded smooth diffuse response on the positive side. This produces crescents, quarters and gibbous shapes rather than scaling a circular sprite's alpha. The unlit portion blends into the sky; earthshine and crater detail are excluded in v1. Do not render a black disk over daytime blue sky. Analytic edge antialiasing is allowed.

[A] Keep position exact within the model tolerance. Default apparent diameter is the computed physical diameter; allow an explicit **1.5× accessibility/art option, hard cap 2×**, fixed independently of camera zoom and recorded in the preset. Never move the Moon toward a camera-facing composition. No billboard translation at world-building scale; it is an angular sky element. Both renderers must use the same camera basis and apparent-angle convention.

[A] Let C be cloud fraction, O the weather §7 haze/smoke/dust/fog intensity, and `G=smoothstep(0°,3°,hMoon)`. Disk opacity gate is `G × [1−smoothstep(0.35,0.75,C)] × (1−O)`, forced zero during active rain/snow/storm and below the geometric horizon. Clip remaining disk pixels below the local horizon/terrain silhouette. Partial-cloud scalar fading is an acknowledged stylization, not actual cloud gaps. If C or obscuration is unknown, omit the disk with an unknown flag. A faint daytime Moon is allowed when lit and clear; stars remain separately gated by night.

[A] Replace weather §7's phase proxy and event-derived horizon gate with **`B = k² × (1−C)² × G`**. The exponent preserves that proposal's artistic response; k is geometric illuminated area, not measured lunar irradiance. Unknown ephemeris/cloud gives B=0 only as a labeled display fallback. Add at most `0.03B` to existing artistic night fill, within sky fill 0.20–0.35 and ground fill 0.06–0.12. Keep weather's wet-ground adjustment. No moon directional light or moon shadow map. The Moon being below the horizon reduces its contribution to zero; the world remains readable through artistic fill.

## 4. Stars

[V, S6/S7] HYG **v4.1** supplies J2000-epoch/equinox coordinates, apparent magnitudes and color indices, and is licensed **CC BY-SA 4.0**. The license requires attribution, a license link, indication of changes, and share-alike for adaptations. This proposal does not redistribute the catalog.

[A] Build a deterministic **256-star** subset: exclude the Sun and invalid coordinates, merge unresolved components within a proposed **2 arcminutes** (connected groups, stable-ID ordering), combine their fluxes, sort by visual magnitude then stable catalog ID, and take the brightest 256. For combined components, use the normalized flux-weighted position and `m=−2.5 log10(Σ10^(−0.4mᵢ))`. Pin source version/hash, source IDs and extraction rules. Test whether major visible patterns such as Orion, the Big Dipper and Southern Cross retain their principal stars; do not claim all constellation members fit. If needed, reserve a small explicit membership list within the same 256 total rather than inventing stars or moving them.

[A] Ship the derived catalog as separable data with “HYG Database v4.1, David Nash / Astronomy Nexus,” upstream URL, CC BY-SA 4.0 URL, and a change notice covering selection, merging and transformations. Preserve upstream notices, license the adapted subset accordingly, and make its data available under those terms. Do not assert that the application's code is automatically relicensed; keep code/data licensing distinct and confirm distribution details before shipping.

[A] Advance catalog positions using supplied Cartesian velocities where available, then precess J2000 vectors to mean equator/equinox of date. For this precision, omitted nutation/annual aberration must be recorded consistently: **mean coordinates use GMST; true-of-date coordinates use GAST**. Do not rotate raw J2000 coordinates by today's sidereal angle without precession. Target star vector error ≤0.1° over 1950–2050. Missing proper motion can use fixed catalog position with a flag.

[A; sidereal basis S8] A sufficient mean sidereal approximation is `GMSTdeg = mod(280.46061837 + 360.98564736629(JDUT1−2451545) + 0.000387933T² − T³/38710000,360)`, `T=(JDUT1−2451545)/36525`. Local sidereal angle = GMST + east longitude; star hour angle H = local sidereal angle − RA. Use the same horizontal transform as the Sun: `sin(h)=sinφ sinδ+cosφ cosδ cosH`, `A=mod(atan2(sinH, cosH sinφ−tanδ cosφ)+180°,360°)`. Stable vector transforms handle poles/zenith. Stars remain fixed relative to each other while the sky rotates with sidereal time.

[A] Preserve weather §7: **≤128 visible stars**, `strength = nightFactor × (1−C)³ × (1−O) × (1−0.3B)`, `nightFactor = 1−smoothstep(−12°,−6°,sunElevation)`. Force off during active rain/snow/storm. Cull below the horizon and behind terrain/opaque world; select the brightest eligible stars up to 128 with stable-ID ties. Use source-time fades across eligibility thresholds; the cap includes fading stars. No random sky arrangement, twinkle, star particles or constellation line overlay. Brightness is a compressed, capped mapping of catalog magnitude; color is a restrained color-index tint, white if missing.

[A] Implement with ≤128 analytic point/quad primitives in the sky batch, not a 256-star loop for every full-screen pixel. Select visible membership on the CPU; rotate all directions with a shared matrix. Street and aerial views see the same celestial sphere. A downward-looking aerial view simply culls the sky; it does not project stars into the ground.

## 5. Seasons by place: phenology

### 5.1 Evidence and model hierarchy

[V, S9–S13] USA-NPN's Spring Indices model early leaf/bloom timing from temperature; they are not a universal full-canopy calendar. CSU documents Front Range crabapple bloom in April–May, differing grass seasonal behavior, and drought-related early color/leaf drop. Colorado's mountain-aspen fall calendar is not a Denver street-tree calendar. NOAA publishes 1991–2020 climate normals. These support a temperature/cohort model, not a precise date for every tree.

[A] Apply species/leaf-cycle tags first, then supplied cohort profiles, regional normals and recent temperatures, then an explicit regional calendar prior. Last resort with no regional knowledge: v2's neutral summer appearance with `phenologyQuality=unknown`; do not invent a deciduous fraction, autumn or snow from latitude alone. Profiles are world-package data, never Denver conditionals in engine code.

[A] Cohorts include temperate deciduous, evergreen broadleaf, conifer, drought-deciduous, and cool-/warm-season grass. Keep **leaf amount, leaf color, flowering and grass greenness independent**. Flowering is optional for eligible cohorts, not every tree. Evergreen does not mean no seasonal change, but it does prohibit blanket winter crown removal. Snow remains the weather reservoir's channel, not a consequence of a winter palette.

### 5.2 Thermal timing and fall progression

[A] Where complete inputs exist, daily forcing in °C-days is `GDD_d=max(0,(Tmin_d+Tmax_d)/2−Tb)`. Accumulate from the cohort's configured forcing start **after** its chill requirement is met. A simple optional chill proxy accumulates valid hourly durations where 0<T<7.2°C from local autumn; its units are hours. Both Tb and chill/forcing thresholds are cohort-specific, calibrated against local phenophase data. Do not present this proxy as USA-NPN's actual Spring Index equations. Unsupported species use calendar priors rather than fabricated chill requirements.

[A] Starter tunables for a generic, explicitly uncalibrated temperate-deciduous trial: Tb=5°C, chilling 600 hours, initial green-up 100 °C-days, full leaf 250 °C-days; eligible flower peak centered on 150 °C-days with a ±40 °C-day blend. These are **assumptions for calibration**, not Denver biological facts and not the fixture calculation path. Allow flowering before leaves by independent thresholds. A freeze does not rewind accumulated GDD; supplied damage data can reduce flowers/leaf amount with a separate recovery channel.

[A] Prefer a gridded/station normal representative of latitude, elevation and climate regime; record station/grid distance, elevation and normal period. Latitude drives actual photoperiod and helps select regional profiles. If station elevation differs, an optional lapse-rate adjustment `Tlocal=Tstation−0.0065×(zlocal−zstation)` °C is a flagged assumption, capped at ±5°C; do not apply it to data already elevation-adjusted. Urban irrigation, microclimate and inversions remain unknown without evidence. Monthly normals interpolate through month midpoints cyclically; they cannot supply observed chill hours.

[A] Use normals to derive the cohort's usual forcing milestones. With complete recent data from the correct season start, solve actual thresholds. With only a recent window, retain the normal/calendar prior and apply a bounded anomaly shift: `Δdays=clamp(−0.5×mean(Trecent−Tnormal),−10,+10)` for a 30-day temperature window with ≥80% valid days. Coefficient and cap are art assumptions; missing days are excluded and reported. This is not a substitute for a complete GDD history.

[A] Autumn uses a profile's color onset/peak and drop-start/end dates, decreasing day length, and a 14-day temperature anomaly. Shift onset/peak/drop by `clamp(1.5×anomaly°C,−14,+14)` days only with ≥80% coverage; warmer autumn delays this trial model. Require day length below the cohort's configured onset guard (trial 12.5 h), and preserve ordered milestones. Drought may advance color/drop **only when supplied soil-moisture/stress evidence supports it**; do not infer it from today's clear weather. A severe freeze can accelerate drop only under a cohort policy. All coefficients require calibration; autumn uncertainty remains larger than astronomical timing.

[A] Maintain annual progression/checkpoints in source time: leaf-out and drop progress are monotonic within their respective stages. A warm November day must not regrow a spring canopy. Replaying/rewinding recomputes from the same annual checkpoint and inputs; a new source/model version creates a new state revision, not silently different historical output.

### 5.3 Stable tree variation and continuous palettes

[V, L1] Generated detail must use `OSMRef.random(salt)` / `StableRandom`, never runtime hash/random functions. [A] Use separate versioned salts for phenology timing, palette family and leaf retention. A shared per-tree `u∈[0,1)` gives a timing shift `(2u−1)×7 days`, or equivalently a bounded forcing-threshold multiplier `1+0.12(2u−1)` when using GDD. Use one approach per profile, not both. Apply the shared shift to the ordered stages and clamp independent flower variation to preserve valid intervals. Generated non-OSM trees use their established stable placement identity. Year is not a reroll seed.

[A] Let S(a,b,x) be clamped cubic smoothstep; resolve continuous green-up g, summer maturity m, autumn color c and drop d, each in [0,1]. For deciduous cohorts use:

- `leafFraction = g(1−d)`.
- `wSpring = g(1−m)(1−c)(1−d)`; `wSummer = gm(1−c)(1−d)`.
- `wAutumn = gc(1−d)`; `wWinter = 1−g+gd`; weights sum to one.
- Flower fraction is an independent rise-and-fall pulse; leaf-drop rate, not color alone, controls airborne leaves.

[A] Interpolate the **same stable palette alternative index** across v2 seasonal columns in linear light. These four weights are appearance weights; winter crown color is never permission to render a brown ball. Remove foliage continuously with stable per-lobe coverage/geometry thresholds while retaining branches; preserve silhouette continuity and seasonal AO validity. Evergreen cohorts use their own smaller color modulation and retained crowns. Grass has separate seasonal weights, so winter grass can stay green while deciduous branches are bare. Regional base → season → time light → weather → grade remains the composition order; houses stay stable.

[A] Grass uses cool-/warm-season policy, thermal state and supplied moisture/irrigation. Trial thermal green-up uses a 7-day mean crossing 5°C for cool-season or 12°C for warm-season grass, blended over 3°C; dormancy uses a separate colder threshold and ≥7-day persistence to avoid flicker. With missing moisture, do not assert drought dormancy. For known water stress, a continuous stress channel can blend summer grass toward dry/dormant color without forcing deciduous autumn. Recovery uses sustained favorable conditions, not a single shower. These thresholds are uncalibrated art parameters.

[A] For a concrete grass-palette contract, let G be resolved grass greenness, M its own spring-to-mature progress, and D the known fraction of its dormant appearance attributed to warm/dry dormancy rather than cold dormancy. Use weights `(G(1−M), GM, (1−G)D, (1−G)(1−D))` for v2 spring/summer/autumn/winter lawn and tuft colors. They sum to one. The calendar-demo fallback uses M= smoothstep(grassFull, grassFull+30 days, date) and D=0 as a labeled display prior when stress is unknown; this is not evidence of cold conditions. Soil and other season-sensitive surfaces may use regional aggregate weights; buildings retain their base palette. Flower colors must come from an eligible cohort's existing material palette, with no added petal geometry budget implied.

### 5.4 Regional behavior and Denver calendar

| Place/policy [A unless explicitly sourced] | Proposed prior and interpretation |
|---|---|
| Denver deciduous | Green-up roughly Apr 10–May 20; mature canopy by mid-June; color onset late September, peak around mid-October; drop late October–mid-November; bare winter. These exact windows are assumptions, with roughly ±2–3 weeks uncertainty and species variation. |
| Denver flowers [V, S10] | Front Range crabapples bloom April–May. [A] Only an eligible flowering cohort gets the illustrative April/May pulse; it is not a city-wide bloom observation. |
| Denver grass [V, S11] | Grass species differ; buffalograss greens later than common cool-season lawns. [A] Cool-season demo green-up late March–April, winter dormancy in November/December; irrigation/stress can change appearance. |
| Plano | Earlier spring, later fall than the Denver demo; warm-season lawn dormancy is separate from tree foliage. Texas A&M supplies bermudagrass management context [V, S14]; exact demo windows are assumptions. |
| Seattle | Mixed evergreen/deciduous cohorts, milder winter grass prior; summer lawns may be dormant when unwatered [V, S15]. Calendar alone must not force drought. |
| Sydney | Use austral season-year and local profiles: temperate deciduous green-up in September/October, leaf loss in May/June as an assumption; evergreen cohorts retain foliage. BoM climate context [V, S16] does not establish the city's tree-species mix. |
| Tropics / evergreen regions | Do not derive four seasons from hemisphere. Use evergreen or locally evidenced wet/dry phenology; drought-deciduous cycles require a moisture profile. With no suitable data, neutral retained foliage and unknown phenology. |

[A] Southern temperate forcing/chilling seasons cross January 1: use a July-to-June season-year by default, rather than resetting all sums in January. Day length comes from latitude/date naturally; do not simply add 182 days to Denver's results. Leap years use actual calendar dates and durations. The fixture calendar's day-of-year knots are fixed **2026 demonstration data**, not a perpetual algorithm.

## 6. Numerical fixtures

[A] [sky-seasons-fixtures.json](sky-seasons-fixtures.json) contains **18 cases**: 12 Denver dates plus June/December contrasts for Plano, Seattle and Sydney. Public rounded city coordinates/elevations are assumptions, not private locations. Every case includes UTC/local timestamp and timezone, all requested solar crossings and golden/blue intervals, daylight duration, Moon altitude/azimuth, topocentric phase angle/k, phase longitude, limb angles, physical diameter, rise/set events, and continuous seasonal state. Weather is a synthetic clear, unobstructed-horizon scenario.

[A] The table below is a compact index; the JSON's second-resolution times and decimal values are authoritative. Times are local. Sun times below display hours/minutes; phase “near” labels are approximate fixture labels, not timestamps of exact phase events. Moon columns are geometric topocentric altitude / true-north azimuth / illuminated percentage.

| Place/date 2026 [A] | Local sample | Sunrise–sunset | Moon alt / az / lit | Representative deciduous state |
|---|---:|---|---|---|
| Denver Jan 03 | 20:00 MST | 07:21–16:48 | 28.0° / 80.2° / 99.1% | Bare; near-full Moon |
| Denver Feb 15 | 06:30 MST | 06:52–17:36 | 3.2° / 123.6° / 4.0% | Bare; waning crescent |
| Denver Mar 08 | 07:00 MDT | 07:22–18:59 | 20.4° / 213.4° / 76.0% | Bare; waning gibbous; 23-hour day |
| Denver Apr 15 | 20:30 MDT | 06:22–19:38 | −27.3° / 303.0° / 2.9% | Early green-up/flower pulse; Moon hidden |
| Denver May 15 | 05:00 MDT | 05:45–20:07 | 3.9° / 71.5° / 2.8% | Green-up nearing full leaf |
| Denver Jun 21 | 21:30 MDT | 05:32–20:31 | 34.7° / 225.6° / 52.4% | Full canopy; waxing near quarter |
| Denver Jul 15 | 12:00 MDT | 05:44–20:26 | 51.8° / 113.2° / 2.8% | Summer; daytime waxing crescent |
| Denver Aug 15 | 22:00 MDT | 06:12–19:55 | −7.8° / 267.9° / 14.1% | Summer; Moon hidden |
| Denver Sep 22 | 18:30 MDT | 06:47–18:56 | 12.9° / 126.9° / 86.2% | Very early autumn color |
| Denver Oct 15 | 18:30 MDT | 07:10–18:20 | 17.9° / 202.3° / 25.9% | Autumn peak; waxing crescent |
| Denver Nov 01 | 06:30 MST | 06:28–16:57 | 68.7° / 207.5° / 53.4% | Leaf drop; 25-hour day |
| Denver Dec 21 | 17:30 MST | 07:17–16:38 | 33.8° / 84.1° / 93.9% | Bare; waxing gibbous |
| Plano Jun 21 | 21:30 CDT | 06:18–20:38 | 43.3° / 223.0° / 52.0% | Summer, warm-season grass green |
| Plano Dec 21 | 21:30 CST | 07:25–17:24 | 75.9° / 118.4° / 94.4% | Bare demo cohort, dormant grass |
| Seattle Jun 21 | 21:30 PDT | 05:11–21:10 | 30.0° / 219.1° / 52.9% | Summer; grass water stress unknown |
| Seattle Dec 21 | 21:30 PST | 07:54–16:20 | 66.4° / 155.6° / 94.8% | Deciduous bare; evergreens retained |
| Sydney Jun 21 | 21:30 AEST | 06:59–16:53 | 24.5° / 288.8° / 44.9% | Austral winter deciduous cohort only |
| Sydney Dec 21 | 21:30 AEDT | 05:40–20:05 | 31.1° / 10.9° / 90.0% | Austral summer; evergreens retained |

[A] Seasons use the documented **calendar-demo** profiles, not the uncalibrated thermal thresholds in §5.2. No normal-temperature samples or actual 2026 temperature histories were ingested; corresponding JSON fields are null. The JSON lists each profile's ordered day-of-year knots. Resolve g/m/c/d with smoothstep over leaf-start/full, full/mature, color-start/peak and drop-start/end. Flower pulse uses offsets (−5,+5,+15,+30) from leaf-start; grass uses its own start/full/dormancy knots, with the explicitly assumed Seattle 0.6 floor. All per-tree offsets are zero for the representative cohort fixture; production tree variation is separate.

[V, calculated 2026-10-05] Across these 18 timestamps, the transcribed existing solar equations differed from Astronomy Engine's airless topocentric solar altitude by at most **0.010211°**. This checks sampled altitude only, not all dates, azimuths or event roots. The raw USNO January 3 Denver reference is embedded in JSON: its rise/set entries agree with these Sun/Moon calculations to the displayed minute. USNO's phase fraction is at local noon; the fixture's is at 20:00 and must not be compared as if simultaneous. Lunar fixtures otherwise come from the proposed reference model itself, so they are regression expectations, not independent proof of lunar accuracy.

[A] Acceptance work for the coding agent: compare both renderers' directions and limb orientation to the fixture vectors/angles; compare event times with stated tolerances; ensure below-horizon Moons never render; verify phase identity `k=(1+cos i)/2` and palette weight sums. Separately add polar summer/winter, grazing twilight, timezone folds/gaps, leap day, missing temperature history, tropical evergreen, and supplied summer-drought cases. These are required implementation boundary tests, not fabricated numeric fixtures in this proposal.

## 7. CPU cadence and existing GPU budget

[A] Resolve full event days/next intervals asynchronously on date/location/profile changes; cache by model, observer, timezone and convention. Ephemerides update about every **30 source-time seconds**, normalized-interpolated between endpoints for drawing; accelerated playback/seeks use source-time steps and refresh immediately. Stars use a shared sidereal matrix, with catalog/precession work cached daily. Phenology integrates once per source day/cohort, blending continuously and resolving per-tree offsets in batches. No full-catalog per-pixel loop, per-tree ephemeris, per-frame GDD accumulation or blocking network request.

[A] Provisional CPU targets: ≤0.25 ms amortized per displayed frame for sky updates and ≤10 ms background work for an ordinary event day; these are **unmeasured engineering targets**, not benchmarks. Bound long polar searches and process them incrementally off the main thread. Store compact direction/weight endpoint data rather than large daily geometry uploads. Measure memory, upload stalls and thermal behavior on device.

| Existing v2 bucket [V, L3] | Ceiling | Work inside it [A] |
|---|---:|---|
| Base opaque world/character, sky/backdrop | 4.25 ms | Gradient, procedural Moon and ≤128 star primitives; provisional sky subtarget ≤0.15 ms total, measured together with existing sky |
| Sun/character shadows | 1.45 ms | Existing solar shadows only; no lunar shadow pass |
| Vertex AO/fill/crown shaping | 0.15 ms | Moon fill scalar, seasonal crown/coverage changes and valid AO |
| Surface patterns | 0.25 ms | Grass seasonal color within existing pattern variant |
| Near geometry | 0.35 ms | Existing combined bevel/leaves/tufts allowance; ≤800 grounded leaves |
| Wet/local-light additions | 0.35 ms | Unchanged existing aggregate allowance |
| Weather particles | 0.20 ms | Shared rain/snow/airborne-leaf budget; ≤12 airborne leaves |
| Post-processing | 0.90 ms | Existing grade/bloom/aerial blur only; no lunar bloom or new sky pass |
| Reserved margin | 2.10 ms | Remains reserved |
| Total | **10.00 ms** | **7.90 ms planned content + 2.10 ms margin** |

[A] GPU figures are allocations, not additive permission on top of v2. If the procedural disk and star batch cannot fit, reduce visible stars to 64 then omit them; omit Moon detail/disk before degrading actual position or app events. Keep CPU event data at full quality. Both renderers need the same ten-minute street/aerial acceptance run at recorded resolution/thermal state, worst-frame and p95 reporting; a favorable average is insufficient. No performance claim has been measured here.

## 8. Open questions and proposed defaults [A]

1. **Lunar implementation:** adopt the pinned analytical model in the neutral producer/adapter; validate any port before claiming the upstream accuracy. Keep runtime renderer dependencies optional.
2. **Catalog distribution:** accept CC BY-SA 4.0 for a separable 256-star data subset, or choose a different explicitly licensed catalog before shipping. No catalog bytes are included here.
3. **Moon size:** use physical size by default, optional 1.5×, cap 2×. Record the override; never alter its center or event timing.
4. **Phenology evidence:** choose species/cohort mappings and representative normal grids/stations; calibrate with USA-NPN/local observations. Until then, ship clearly labeled calendar priors, with independent grass and evergreen policies.
5. **Terrain-visible events:** standard level-horizon events first; add separate DEM-visible events only when a reliable horizon profile exists.
6. **Eclipses:** omit special eclipse shading/events in v1 and label unsupported dates if used as astronomy demonstrations. The ordinary phase disk is not eclipse-aware.
7. **Renderer budget gate:** determine the sky primitive/batching mechanism in RealityKit or three.js through measurement. Do not consume the reserved margin to guarantee an untested feature.

## 9. Source register

[V] Every source below was inspected **2026-10-05**. Verification applies to the stated source content, not to assumptions extrapolated from it. External software was used transiently for proposal arithmetic; no application code, dependency or catalog was installed in this repo.

| ID | Source and verified scope |
|---|---|
| L1 | [CLAUDE.md](../../../CLAUDE.md): repository rules, stable randomness, iOS minimum |
| L2 | [Weather v1](../weather-v1/WorldEngine-Weather-Spec-v1.md): §§5/7 light, Moon fill, star rules |
| L3 | [Visual v2](../visual-v2/WorldEngine-Visual-Spec-Proposal-v2.md): palettes, composition, caps, §8.1 budgets |
| L4 | [SolarPosition.swift](../../../Sources/WorldGeo/SolarPosition.swift): existing solar arithmetic and coordinate frame |
| L5 | [Visual direction](../../VISUAL_DIRECTION.md): binding style, scale and camera requirements |
| L6 | [Current plan](../../plan-m1.md): warm-light scene naming; inspected read-only while another agent may update it |
| S1 | [NOAA calculation details](https://gml.noaa.gov/grad/solcalc/calcdetails.html): conventional calculations, limits, unsupported status |
| S2 | [USNO rise/set/twilight definitions](https://aa.usno.navy.mil/faq/RST_defs): thresholds and horizon conventions |
| S3 | [IANA Time Zone Database](https://www.iana.org/time-zones): timezone rule database |
| S4 | [Astronomy Engine](https://github.com/cosinekitty/astronomy): stated accuracy and MIT licensing |
| S5 | [Pinned analytical source](https://github.com/cosinekitty/astronomy/blob/865d3da7d8112bbc7911238052c6af4aaf877181/source/python/astronomy/astronomy.py), [API documentation](https://github.com/cosinekitty/astronomy/blob/master/source/python/README.md): lunar series, coordinates and time conventions |
| S6 | [HYG v4.1 data description](https://github.com/astronexus/HYG-Database/blob/main/hyg/README.md), [license](https://github.com/astronexus/HYG-Database/blob/main/LICENSE): epoch, fields and CC BY-SA 4.0 |
| S7 | [Creative Commons BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/): attribution and adaptation terms |
| S8 | [USNO approximate sidereal time](https://aa.usno.navy.mil/faq/GAST): sidereal rotation and mean/apparent distinction |
| S9 | [USA-NPN Status of Spring](https://www.usanpn.org/data/maps/spring): modeled first-leaf/first-bloom indices |
| S10 | [CSU Front Range crabapples](https://planttalk.colostate.edu/topics/trees-shrubs-vines/1747-0-flowering-crabapple/): April–May flowering |
| S11 | [CSU turfgrass selection](https://extension.colostate.edu/resource/turfgrass-species-selection-guidelines/), [buffalograss](https://extension.colostate.edu/resource/buffalograss-lawns/): species-dependent green-up/dormancy |
| S12 | [CSU/Colorado State Forest Service aspen fall colors](https://csfs.colostate.edu/forests-trees/aspen-fall-colors/), [CSU watering mature trees](https://extension.colostate.edu/resource/watering-mature-shade-trees/): high-elevation color context and drought-related early leaf loss |
| S13 | [NOAA U.S. Climate Normals](https://www.ncei.noaa.gov/products/land-based-station/us-climate-normals): 1991–2020 normals and available temporal resolutions |
| S14 | [Texas A&M bermudagrass calendar](https://agrilifeextension.tamu.edu/library/landscaping/bermudagrass-home-lawn-management-calendar/): warm-season lawn context |
| S15 | [WSU King County lawns](https://extension.wsu.edu/king/mg-home/gardening-resources/tip-sheets/tip-sheet-11): summer watering/dormancy distinction |
| S16 | [BoM Sydney Observatory Hill statistics](https://www.bom.gov.au/climate/averages/tables/cw_066062.shtml): regional climate context, not a uniform 1991–2020 phenology series |
| S17 | [USNO API documentation](https://aa.usno.navy.mil/data/api), [January 3 Denver reference](https://aa.usno.navy.mil/api/rstt/oneday?date=2026-01-03&coords=39.7392,-104.9903&tz=-7): independent event check, local-noon phase convention |

[V, local work record] Writes were confined to this proposal directory. No git commands, app builds, engine edits or device benchmarks were performed. The companion JSON was parsed and checked for finite values, event ordering, DST day lengths, illumination consistency, seasonal weight sums and resolvable source IDs.
