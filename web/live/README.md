# A6: fixture-only live sky state

**Complete A6 module; fixture-only demo.** R approved the phase ranges for A6 only
on 8 October 2026; see `docs/decisions/owner-log.md`, “Sky phase ranges”. This
approval does not extend to other lanes or the entire reference pack.

Phase convention: `sky-seasons-v1` §2.1 supplies golden [−4°, +6°] and blue
[−6°, −4°]. For a single-valued API, golden owns the shared −4° endpoint:
day >6°, golden [−4°,6°], blue [−6°,−4°), night <−6°.
The four-state `night` label includes twilight; `twilight` is true only between
−12° and −6°. `fullNight` uses the approved `night-fog-v1` key
`states[id=night].time.maxElevationDeg` (≤−12°). Phase is driven by the Sun,
not moon phase or cloud cover. Lunar illumination and horizon state are separate.

## Public API and demo

```js
import {getSkyState} from './web/live/sky-state.mjs';
const state = getSkyState({
  lat: 39.7494, lon: -105.0445, time: '2026-06-21T12:00:00-06:00',
  region: 'front-range', weatherState: 'clear'
}); // demo: a string weather state is an authored fixture
```

Returns `sun` (azimuthDeg, elevationDeg, direction), `moon` (direction,
illuminatedFraction, waxing, aboveHorizon), `phase` (`day | goldenHour | blueHour |
night`), `twilight`, `fullNight`, `directSunAboveHorizon`, `airlight`
(linearRGB, hex, space), `extinctionPerM`, `label` (`live | stale | demo`) and
`visibility` (basis, ages, status, season, state, estimated and expiry flags).
The optional observation schema is documented below. No weather input is silently
fabricated. Missing required region/weather state throws; missing visibility uses
an explicitly estimated fallback and cannot be live.

A2/Builder: use `sun.direction` to place a directional source; cast rays in the
opposite direction. Below the geometric horizon set direct sunlight to zero.
Sun direction does not depend on weather, region, viewport or the camera.
Atmospheric extinction and airlight are separate inputs, not extra exposure or
shadow colouring. Existing renderer occlusion/terrain must determine actual shadows.
For a level plane, an unoccluded vertical object's shadow length is height/tan(elevation);
this becomes ill-conditioned near the horizon. Refraction, terrain, buildings,
survey accuracy and civil-time entry can dominate a shadow-study error; this module
is not survey-grade. Reference errors below are numerical comparisons, not a
site-specific shadow guarantee.

Open `web/live/index.html` directly in a browser: a standalone, inline-module
Sloan’s Lake slider (21 June 2026, MDT), always labelled DEMO. No server or network
is required. `node web/live/build-demo.mjs` regenerates it after source changes.
`createSkyState({clock})` provides deterministic test-clock injection; integration
should use `getSkyState` with its real clock. Never inject slider time as the live clock.

Small, dependency-free ES modules for a map viewer. No fetch, geolocation,
provider credentials, runtime packages, renderer changes or network access.
All implementation, generated data, fixtures, tests and the demo live here.
Nothing in the iOS engine, look values, bake-off or streaming viewer is changed.
A2 integration is a separate step; this module alone makes no rendered look-score claim.

## Astronomy and accuracy

`astronomy.mjs` exports `solarPosition({lat, lon, time})` and
`lunarPosition({lat, lon, time})`. Coordinates are degrees, longitude east-positive.
Time is an ISO timestamp **with Z or an explicit offset**, a Date or epoch milliseconds.
Azimuth is clockwise from true north; elevation is geometric, without refraction.
Direction is a unit vector **toward** the body: east +X, up +Y, north −Z.
The Sun below the horizon cannot provide direct light. Astronomical calculations
are computed estimates, not observed weather.

Solar implementation: [NOAA Solar Calculation Details](https://gml.noaa.gov/grad/solcalc/calcdetails.html),
Meeus, *Astronomical Algorithms*, 2nd edition, chapter 25 (Julian centuries,
apparent longitude, obliquity, declination and equation of time). UTC approximates UT1.
Publication links are citations only; no network calls were made.

`fixtures/solar-reference.json` freezes **24 independently calculated reference values**:
Denver and Chicago, March/September equinox dates and June/December solstice dates
in 2026, each at standard sunrise, upper transit and sunset. The independent
Python generator implements [USNO Approximate Solar Coordinates](https://aa.usno.navy.mil/faq/sun_approx)
using RA/declination and sidereal time, rather than the implementation's equation
of time. Sunrise/set are defined by −0.833333° solar-center elevation, not terrain
or a claim about actual visible sunrise. Generator and provenance are included;
tests read frozen values and do not regenerate their expected results.

Measured maximum disagreement across those 24 cases: **0.009164° elevation,
0.015461° azimuth, 0.010190° angular direction**. Test limits: 0.05° elevation/direction,
0.1° azimuth. These are numerical agreement errors against a separate approximate
algorithm, **not measured astronomical accuracy or a guaranteed global error bound**.
The regression coverage is 2026; extrapolation to other eras is unvalidated.
Polar day/night, dateline, pre-1970 arithmetic and offset equivalence have separate tests.

Moon: truncated Meeus chapter 47, Tables 47.A/B; spherical sea-level observer
parallax, no atmospheric refraction or terrain horizon. Returns direction,
illuminated fraction, elongation, waxing flag and above-horizon gate. No fake moon
is placed just because it is night or full. The fraction is geocentric and approximate.
Eighteen frozen Astronomy Engine fixtures from
`sky-seasons-v1/sky-seasons-fixtures.json` provide an independent comparison,
including Sydney. Maximum direction disagreement **0.078200°**, illuminated-fraction
absolute disagreement **0.005534** (including geocentric/topocentric differences).
Test limits are 1° and 0.03; do not use this small model for eclipses or precision
rise/set timing. It does not add moon lighting or alter approved look values.

## Visibility and provenance

`visibilityState(input, nowMilliseconds)` is the lower-level pure selector.
`region` is an exact `haze-visibility-v1` region ID, e.g. `front-range` or `great-lakes`.
`weatherState: 'clear'` is a demo; supported state names are `clear`, `hazy`, `humid`,
`smoke`, `rain`, `snow`. An adapter may instead supply:

```js
weatherState: {
  states: ['rain', 'hazy'],
  kind: 'observation', // explicit; demo/forecast/history are never live
  source: 'adapter/source identifier',
  observedAt: '2026-10-08T12:00:00Z',
  severity: 'heavyRain' // optional, must match a supplied state
}
```

Weather events must be verified by the caller; this module cannot verify a provider.
No smoke feed is activated. Severity keys: lightRain, heavyRain, lightSnow, snowSquall,
denseSmoke. Local dense fog requires a spatial adapter and is deliberately rejected
as a homogeneous global severity. Seasons never activate precipitation or smoke.

Optional representative observation:

```js
observedVisibility: {
  kind: 'observation', source: 'adapter/source identifier',
  observedAt: '2026-10-08T12:00:00Z', representative: true,
  value: 10000, unit: 'm', convention: 'MOR_5_PERCENT'
}
// A censored report uses report: '10SM' or report: '9999' instead of value/unit.
// Numeric US ceiling: value:10, unit:'SM', reportingSystem:'US_METAR'.
```

Pack citations (all from approved `haze-visibility-v1/values.json`):

| Key | Behavior |
|---|---|
| `definition.constant`, `sigmaFormula` | 5% MOR: sigma = 2.995732273553991 / visibility metres; m⁻¹ |
| `regions[*].seasons[season][state]` | Exact authored fallback, not climatology or a measured visibility |
| `regions[*].seasonBasis` | Meteorological seasons reversed south of equator; equator uses north convention |
| `selection.priority` | Representative uncensored total observation replaces total extinction |
| `selection.combinedStates` | Without total observation use maximum candidate sigma, never add contributors |
| `severityOverrides` | Replace matching ordinary state with severity, then combine remaining states |
| `selection.censoredObservation` | 10SM ≥16.09344 km; 9999 ≥10 km, lower-bound flag retained |
| `selection.staleData.softAgeMinutes` | Age ≥60 min is stale, never live |
| `selection.staleData.hardAgeMinutes` | Age ≥180 min discards observed visibility; retain uncertain event fallback |
| `selection.invalidVisibility` | Reject nonfinite, zero, negative, unknown units/conventions; no clamping to clear |
| `airlight.stateDayHex`, `timeHex`, `timeMix` | Decode sRGB, mix in linear light; return hex plus linear RGB |

Local season uses longitude-derived **local mean solar date**, so a UTC month
boundary does not necessarily change the local month. The API does not include an
IANA time zone. Civil-zone boundaries can differ by hours from this convention.
Unknown regions/states throw rather than silently pick Denver. Preset ranges are
not clamps: valid observations outside them are retained. 2% contrast visibility
must be converted by a source adapter before passing `MOR_5_PERCENT`.

For a censored observation, visibility is `max(regional prior, lower bound)` and is
explicitly estimated; it never becomes a precise observation or a live label.
A conflicting smoke/rain/snow event retains its conservative event prior and reports
`contradictoryBound`. Hard-expired observations are discarded, not blended back in.
Freshness is evaluated against the actual clock, independently from slider time.
A historical (≥60 min old) or future target time is `demo`, even if supplied reports
are fresh now. A fresh authored regional fallback is `demo`, not live weather.
Stale observation-based input yields `stale`; fixture/demo input stays `demo`.
Every observation age, source status, estimated basis and hard expiry are explicit.

`pack-data.mjs` selects the needed unmodified fields, with SHA-256 provenance.
`node web/live/build-data.mjs` regenerates it from the approved repo pack; a test
checks every copied field and the hash. Original pack files remain read-only.
The original JSON's historical pending label is superseded by its approved STATUS.md.

## Tests

From repository root: `HEAVY_AGENT=A6 bash scripts/heavy.sh "A6 live sky tests" node --test web/live/*.test.mjs` (Node 18+).
R requested the heavy wrapper for merge-readiness verification. No installation,
dependency lockfile or network is required.
Python is needed only to intentionally regenerate the independent solar fixture;
ordinary tests consume frozen JSON. No baseline is refreshed by the test runner.
