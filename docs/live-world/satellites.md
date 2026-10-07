# Satellite layer: `worldengine.live.satellites/1`

Where satellites are now and when they pass over a place, with naked-eye visibility. Code:
`Tools/livefeeds/livefeeds/sats/`. Command:
`Tools/livefeeds/livefeeds.sh sats --lat 41.8781 --lon -87.6298 [--time ISO] [--hours 48] [--visible-only] --pretty`
(uses CelesTrak through the cache; `--elements FILE` takes local TLE or OMM JSON instead; `--offline` uses the cache only).
Vocabulary (`basis`, `state`, `attribution`): [README.md](README.md).

## 1. Methods

| Part | Method |
|---|---|
| Elements | CelesTrak GP data, OMM JSON (`gp.php?GROUP=...&FORMAT=json`) or TLE text; groups from `Tools/livefeeds/data/satellites.json` (`stations`, `visual`) |
| Propagation | SGP4, near-earth branch, WGS72, improved mode, after Vallado et al. 2006 ("Revisiting Spacetrack Report #3"). Deep-space objects (period of 225 min or more: GPS, geostationary, Molniya) are skipped; none is a naked-eye pass target |
| Frames | TEME to Earth-fixed by GMST (IAU 1982); polar motion ignored (metres); observer on WGS84 |
| Sun | Meeus ch. 25 low-precision direction (0.01 deg), enough for shadow and twilight |
| Shadow | Cylindrical Earth shadow, no penumbra (entry and exit to about 10 s) |
| Passes | 20 s scan for horizon crossings, bisection to 0.5 s, golden-section search for culmination; reported when the maximum altitude is at least 10 deg |
| Visible to the eye | Satellite sunlit, at least 10 deg up, Sun at least 6 deg below the observer's horizon (the Spot the Station / Heavens-Above rule), sampled every 5 s |
| Magnitude | Diffuse sphere: `stdMag + 5 log10(range / 1000 km) - 2.5 log10((pi - phi) cos phi + sin phi)`, phi the Sun-satellite-observer angle; `stdMag` from `data/satellites.json` (ISS -1.8, an assumption); null when unknown |

## 2. Contract

One document per (place, window). `live` is `false`: everything is a `forecast` from orbital elements.

| Field | Meaning |
|---|---|
| `window` {start, end} | POSIX seconds; passes are searched in it |
| `state` | `fresh` if any satellite's elements are fresh, else `stale`, else `unavailable` (also when no elements could be loaded) |
| `elements` {source, fetchedAt, error, basis "observed"} | When the element sets were downloaded; `error` explains a failed or blocked fetch (the last good copy is still used) |
| `rules` | The thresholds above, so the renderer can explain them |
| `satellites[]` | `id` (`norad:` + catalogue number), `noradId`, `name`, `elementsEpoch`, `elementsAgeDays`, `state`, `basis` "forecast", `standardMagnitude` {value, basis "inferred"} or null, `now`, `passes[]` |
| `satellites[].state` | Element age at the window start: `fresh` at most 3 days, `stale` at most 10 days (or epoch more than 1 day in the future), `unavailable` beyond (no `now`, no passes, with `reason`) |
| `now` | At the window start: `altDeg`, `azDeg`, `rangeKm`, `subLat`, `subLon`, `heightKm`, `sunlit`, `observerSunAltDeg`, `visibleToEye`, `magnitude` |
| `passes[]` | `rise`, `culmination`, `set` points (each `t`, `altDeg`, `azDeg`, `rangeKm`, `sunlit`, `magnitude`), `startsBeforeWindow`, `endsAfterWindow`, `visible`, `basis` "forecast" |
| `passes[].visibleWindow` | Only when `visible`: `start`, `end`, `maxAltDeg`, `brightestMagnitude`, `endsInShadow` (true when it fades into Earth's shadow rather than setting), `track[]` (points every 10 s for drawing the arc without SGP4) |

Raw element lines are never part of the contract; the relay alone holds them (licence question in
`docs/research/licensing.md` row LW7).

Rendering rules: draw only `visible` passes as naked-eye events; never call a forecast "live". When
`state` is `stale`, mark times as approximate; when `unavailable`, show no satellites.

Example (ISS over Chicago, the 2008 public example element set, one visible pass, track cut to two points):

```json
{
 "schema": "worldengine.live.satellites/1",
 "layer": "satellites",
 "generatedAt": 1221933600,
 "live": false,
 "observer": {
  "lat": 41.8781,
  "lon": -87.6298,
  "elevM": 0.0
 },
 "window": {
  "start": 1221933600,
  "end": 1221976800
 },
 "state": "fresh",
 "elements": {
  "source": "celestrak",
  "fetchedAt": 1221920000,
  "error": null,
  "basis": "observed"
 },
 "rules": {
  "minPassAltDeg": 10.0,
  "visibleMinAltDeg": 10.0,
  "sunMaxAltDegForVisible": -6.0,
  "freshDays": 3.0,
  "staleDays": 10.0
 },
 "satellites": [
  {
   "id": "norad:25544",
   "noradId": 25544,
   "name": "ISS (ZARYA)",
   "elementsEpoch": 1221913540,
   "elementsAgeDays": 0.23,
   "state": "fresh",
   "basis": "forecast",
   "standardMagnitude": {
    "value": -1.8,
    "basis": "inferred"
   },
   "now": {
    "t": 1221933600,
    "altDeg": -36.34,
    "azDeg": 138.306,
    "rangeKm": 8119.1,
    "subLat": -22.9397,
    "subLon": -43.1759,
    "heightKm": 363.5,
    "sunlit": true,
    "observerSunAltDeg": 48.7,
    "visibleToEye": false,
    "magnitude": 2.6,
    "basis": "forecast"
   },
   "passes": [
    {
     "rise": {
      "t": 1221956527.7,
      "altDeg": -0.009,
      "azDeg": 212.961,
      "rangeKm": 2154.6,
      "sunlit": true,
      "magnitude": 0.83
     },
     "culmination": {
      "t": 1221956814.0,
      "altDeg": 31.14,
      "azDeg": 137.678,
      "rangeKm": 643.1,
      "sunlit": true,
      "magnitude": -3.71
     },
     "set": {
      "t": 1221957101.1,
      "altDeg": -0.004,
      "azDeg": 62.509,
      "rangeKm": 2161.7,
      "sunlit": false,
      "magnitude": null
     },
     "startsBeforeWindow": false,
     "endsAfterWindow": false,
     "visible": true,
     "basis": "forecast",
     "visibleWindow": {
      "start": {
       "t": 1221956657.3,
       "altDeg": 10.29,
       "azDeg": 202.198,
       "rangeKm": 1298.8,
       "sunlit": true,
       "magnitude": -0.79
      },
      "end": {
       "t": 1221956971.4,
       "altDeg": 10.25,
       "azDeg": 73.099,
       "rangeKm": 1304.9,
       "sunlit": true,
       "magnitude": -2.37
      },
      "maxAltDeg": 31.129,
      "brightestMagnitude": -3.79,
      "endsInShadow": false,
      "track": [
       {
        "t": 1221956657.3,
        "altDeg": 10.29,
        "azDeg": 202.198,
        "rangeKm": 1298.8,
        "sunlit": true,
        "magnitude": -0.79
       },
       {
        "t": 1221956667.3,
        "altDeg": 11.395,
        "azDeg": 200.711,
        "rangeKm": 1236.9,
        "sunlit": true,
        "magnitude": -0.96
       }
      ]
     }
    }
   ]
  }
 ],
 "attribution": [
  {
   "source": "celestrak",
   "text": "Orbital elements: CelesTrak (celestrak.org), from U.S. Space Force public GP data.",
   "url": "https://celestrak.org/NORAD/elements/",
   "required": true
  }
 ]
}
```

## 3. Validation

**SGP4 against Vallado's published verification output.** `validation/sgp4_vallado.py` runs every near-earth case of
`SGP4-VER.TLE` and compares with `tcppver.out` (Vallado's C++ reference output; both files ship in the `sgp4`
package on PyPI, MIT):

```
00005  max |dr| 6.539e-09 km  max |dv| 4.983e-10 km/s
06251  max |dr| 4.918e-09 km  max |dv| 4.903e-10 km/s
22312  max |dr| 5.120e-09 km  max |dv| 4.930e-10 km/s
28057  max |dr| 5.027e-09 km  max |dv| 4.888e-10 km/s
28350  max |dr| 4.923e-09 km  max |dv| 4.854e-10 km/s
28872  max |dr| 5.935e-09 km  max |dv| 4.913e-10 km/s
29141  max |dr| 8.401e-09 km  max |dv| 4.886e-10 km/s
29238  max |dr| 5.074e-09 km  max |dv| 4.723e-10 km/s
88888  max |dr| 4.600e-09 km  max |dv| 4.835e-10 km/s
near-earth satellites compared: 9, states: 158, deep-space skipped: 24, init errors: 0
WORST position difference 8.401e-09 km (0.0 mm), velocity 4.983e-10 km/s
```

The reference prints 8 decimals, so the differences are at its rounding level: the implementation reproduces
Vallado's SGP4 exactly on the near-earth cases.

**Passes and sunlight against Skyfield (independent implementation, same elements).** `validation/passes_skyfield.py`,
3 days of ISS passes from the 2008 example element set for Chicago, Denver and Miami:

```
Chicago: 18 passes (max alt >= 10 deg) in 3 days from 2008-09-20 12:25Z
Denver: 12 passes (max alt >= 10 deg) in 3 days from 2008-09-20 12:25Z
Miami: 8 passes (max alt >= 10 deg) in 3 days from 2008-09-20 12:25Z
passes compared: 38
worst |dt| rise 0.3 s, culmination 0.2 s, set 0.3 s; worst |d maxAlt| 0.018 deg
sunlit flag disagreements: 0 of 4187 samples (cylindrical shadow vs Skyfield's)
```

**Against published ISS pass times: not done yet.** Re-tried 2026-10-06: CelesTrak is now reachable (current elements
fetch fine), but every published pass list is still denied by the network policy: spotthestation.nasa.gov now
redirects to www.nasa.gov/spot-the-station (denied; its old XML feeds answer 404), and heavens-above.com, n2yo.com,
in-the-sky.org, calsky.com and timeanddate.com are denied too.
To close it: with network access, fetch the ISS elements from CelesTrak and, the same hour, the pass list for the
three cities from Spot the Station (or Heavens-Above); run `livefeeds.sh sats --ids 25544 --visible-only` for each
city and compare start, maximum and end times. Expected agreement: within a minute (publishers round to the
minute and may use other elements), with maximum altitude within a degree.

## 4. Known limits

- Element sets age: SGP4 errors grow by roughly 1-3 km per day, and ISS reboosts invalidate older elements. Hence
  the 3-day/10-day states.
- The cylindrical shadow ignores penumbra and atmospheric refraction of sunlight (fade timing about 10 s).
- Magnitudes are rough (a sphere model); only the ISS has a standard magnitude configured.
- Flares (old Iridium) and Starlink trains are not modelled specially.
