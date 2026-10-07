# Sky layer: `worldengine.live.sky/1`

Accurate sky for any place and time: bright stars, Sun, Moon (position, phase, bright limb), the seven planets,
and the naked-eye limiting magnitude from light pollution, twilight and moonlight. Code:
`Tools/livefeeds/livefeeds/sky/`. Command: `Tools/livefeeds/livefeeds.sh sky --lat 41.8781 --lon -87.6298 --time 2026-10-06T04:00:00Z --pretty`.
Vocabulary (`basis`, `state`, `attribution`): [README.md](README.md).

## 1. Methods

| Part | Method | Source |
|---|---|---|
| Time | TT = UTC + leap seconds + 32.184 s (IERS table in `astro.py`); UT1 taken as UTC (at most 0.9 s, 13.5 arcsec of hour angle) | IERS Bulletin C |
| Sidereal time | GMST, Meeus eq. 12.4; GAST adds the equation of the equinoxes | Meeus, *Astronomical Algorithms* 2nd ed. |
| Precession, nutation | Meeus 21.2 angles (rigorous rotation); IAU 1980 nutation, 13 largest terms (< 0.1 arcsec truncation) | Meeus ch. 21, 22 |
| Planets, Earth-Moon barycentre | Keplerian elements with rates, table 1 (1800-2050), a fit to DE405; light time, first-order aberration | E. M. Standish, JPL SSD, "Keplerian Elements for Approximate Positions of the Major Planets" |
| Moon | ELP-2000/82 truncated (Meeus ch. 47; the same tables as `Sources/WorldEnvironment/Moon.swift`) | Meeus ch. 47 |
| Topocentric | Observer on the WGS84 ellipsoid, vector subtraction (full lunar parallax) | Meeus ch. 11, 40 |
| Horizon | Geometric `altDeg`; `apparentAltDeg` adds Saemundsson refraction (1010 hPa, 10 C) | Meeus 16.4 |
| Stars | Engine catalogue (Yale BSC5 extract, J2000 unit vectors), space motion where given, aberration, precession, nutation | `Sources/WorldEnvironment/Catalog/` |
| Planet magnitudes | Muller / Astronomical Almanac 1984 expressions; Saturn with ring tilt (pole RA 40.589, Dec 83.537) | Meeus ch. 41 |
| Moon phase | Phase angle Sun-Moon-observer; illuminated fraction (1 + cos i) / 2; bright-limb position angle (Meeus 48.5) | Meeus ch. 48 |
| Sky brightness | Linear flux sum of natural sky (22.0 V mag/arcsec^2), artificial skyglow, twilight table, Krisciunas & Schaefer (1991) moonlight | PASP 103, 1033 |
| Limiting magnitude | NELM = 7.93 - 5 log10(10^(4.316 - B/5) + 1); stars and planets corrected for extinction (k = 0.25) at their altitude | Unihedron SQM / Clear Sky Chart conversion |
| Light pollution | Kernel-weighted (d + 1 km)^-2.5, 50 km radius, mean of NASA Black Marble annual radiance; artificial/natural = 1.0 x radiance (nW/cm^2/sr) | Assumption, `confidence: "low"` until calibrated |

## 2. Contract

One document per (place, instant). `live` is always `false` (computed, not observed). Recompute every
`recomputeSeconds` (60) or interpolate; nothing here changes faster than 0.25 deg per minute.

Top level: `schema`, `layer` ("sky"), `generatedAt`, `at` (the instant described), `observer` {lat, lon, elevM},
`recomputeSeconds`, `live`, `state`, `sun`, `moon`, `planets[]`, `stars` {basis, catalog, catalogFaintestMag, count, items[]},
`lightPollution`, `skyBrightness`, `accuracy`, `attribution[]`.

| Field | Unit / values | Notes |
|---|---|---|
| `altDeg`, `azDeg` | degrees; azimuth from north through east | Topocentric, geometric (airless) |
| `apparentAltDeg` | degrees | With refraction; use this for drawing and for "is it up" |
| `raDeg`, `decDeg` | degrees | Apparent, true equator and equinox of date, topocentric |
| `sun.distanceAu`, `moon.distanceKm`, `planets[].distanceAu` | | Topocentric distance |
| `angularDiameterDeg` | degrees | Sun and Moon |
| `moon.phaseAngleDeg`, `illuminatedFraction`, `phaseName` | `new`, `waxingCrescent`, `firstQuarter`, `waxingGibbous`, `full`, `waningGibbous`, `lastQuarter`, `waningCrescent` | |
| `moon.elongationLongitudeDeg`, `ageDays` | 0 new, 180 full; age = elongation / 360 x 29.53 d | |
| `moon.brightLimbPositionAngleDeg` | degrees from celestial north through east | Orientation of the lit side |
| `moon.brightLimbFromZenithDeg` | degrees from the zenith direction | What the renderer rotates the lit side by |
| `magnitude` | V | Sun fixed -26.74 |
| `planets[].id` | `mercury` ... `neptune` | Order fixed |
| `planets[].ringTiltDeg` | degrees | Saturn only: Earth's latitude above the ring plane |
| `visibleToEye` | boolean | Magnitude plus extinction at its altitude is at most `skyBrightness.limitingMagnitudeNow`, and it is up |
| `stars.items[]` | `id` (`hr` + HR number), `name` (IAU, may be null), `mag`, `colorIndexBV` | Stars with `apparentAltDeg >= -1`, brightest first |
| `lightPollution.state` | `fresh` (composite at most 2 years old), `stale` (at most 6), `unavailable` (no grid, outside it, or older) | |
| `lightPollution.weightedRadiance` | {value, unit "nW/cm^2/sr", basis "observed"} | |
| `lightPollution.artificialToNaturalRatio` | ratio | null when unavailable |
| `skyBrightness` | `zenithSkyMagDark`, `zenithSkyMagNow` (V mag/arcsec^2), `limitingMagnitudeDark`, `limitingMagnitudeNow` | `confidence`: `low`, or `assumesDarkSite` when light pollution is unavailable (with a `note`) |
| `accuracy` | arcsec per body | Error budget from section 5 |

`state` is `fresh` for any instant in 1800-2050 and `unavailable` outside (then only `reason` and `attribution`
follow). Light pollution has its own `state`; when it is `unavailable` the sky is computed as a dark site and says so.

Example (Denver, 2026-10-06 04:00 UTC; star and planet lists cut to two and one):

```json
{
 "schema": "worldengine.live.sky/1",
 "layer": "sky",
 "generatedAt": 1791328758,
 "at": 1791259200,
 "observer": {
  "lat": 39.7392,
  "lon": -104.9903,
  "elevM": 1609.0
 },
 "recomputeSeconds": 60,
 "live": false,
 "state": "fresh",
 "sun": {
  "altDeg": -38.7351,
  "apparentAltDeg": -38.7351,
  "azDeg": 301.2357,
  "raDeg": 191.8854,
  "decDeg": -5.1045,
  "distanceAu": 0.9999,
  "angularDiameterDeg": 0.5332,
  "magnitude": -26.74,
  "basis": "inferred"
 },
 "moon": {
  "altDeg": -33.4599,
  "apparentAltDeg": -33.4599,
  "azDeg": 11.5828,
  "raDeg": 139.8104,
  "decDeg": 16.0205,
  "distanceKm": 377529.981,
  "angularDiameterDeg": 0.5274,
  "phaseAngleDeg": 124.2036,
  "illuminatedFraction": 0.2189,
  "elongationLongitudeDeg": 303.953,
  "phaseName": "waningCrescent",
  "ageDays": 24.9331,
  "brightLimbPositionAngleDeg": 107.9463,
  "brightLimbFromZenithDeg": 117.19,
  "magnitude": -8.588,
  "basis": "inferred"
 },
 "planets": [
  {
   "altDeg": 36.6429,
   "apparentAltDeg": 36.6655,
   "azDeg": 124.2718,
   "raDeg": 11.4102,
   "decDeg": 1.9545,
   "distanceAu": 8.4347,
   "heliocentricDistanceAu": 9.4332,
   "phaseAngleDeg": 0.3348,
   "illuminatedFraction": 1.0,
   "magnitude": 0.3086,
   "ringTiltDeg": -7.4227,
   "visibleToEye": true,
   "id": "saturn",
   "basis": "inferred"
  }
 ],
 "stars": {
  "basis": "inferred",
  "catalog": "Yale Bright Star Catalogue, 5th Revised Ed. (preliminary version, 1991)",
  "catalogFaintestMag": 3.4,
  "count": 112,
  "items": [
   {
    "id": "hr7001",
    "name": "Vega",
    "mag": 0.03,
    "colorIndexBV": 0.0,
    "altDeg": 51.5123,
    "apparentAltDeg": 51.5257,
    "azDeg": 285.312,
    "raDeg": 279.4617,
    "decDeg": 38.8128,
    "visibleToEye": true
   },
   {
    "id": "hr1708",
    "name": "Capella",
    "mag": 0.08,
    "colorIndexBV": 0.8,
    "altDeg": 16.1971,
    "apparentAltDeg": 16.2538,
    "azDeg": 42.8601,
    "raDeg": 79.6739,
    "decDeg": 46.0228,
    "visibleToEye": true
   }
  ]
 },
 "lightPollution": {
  "state": "unavailable",
  "reason": "no radiance grid loaded for this place",
  "artificialToNaturalRatio": null,
  "weightedRadiance": null,
  "basis": "inferred",
  "confidence": null
 },
 "skyBrightness": {
  "zenithSkyMagDark": 22.0,
  "zenithSkyMagNow": 22.0,
  "limitingMagnitudeDark": 6.62,
  "limitingMagnitudeNow": 6.62,
  "basis": "inferred",
  "confidence": "assumesDarkSite",
  "note": "no light-pollution data: dark-site sky assumed, real limiting magnitude is likely lower"
 },
 "accuracy": {
  "unit": "arcsec",
  "basis": "inferred",
  "sun": 20,
  "moon": 10,
  "stars": 5,
  "mercury": 20,
  "venus": 40,
  "mars": 40,
  "jupiter": 120,
  "saturn": 400,
  "uranus": 20,
  "neptune": 60
 },
 "attribution": [
  {
   "source": "bsc5",
   "text": "Stars: Yale Bright Star Catalogue, 5th rev. ed. (Hoffleit & Warren), via NASA HEASARC. Star names: IAU Working Group on Star Names.",
   "url": "https://heasarc.gsfc.nasa.gov/W3Browse/star-catalog/bsc5p.html",
   "required": true
  }
 ]
}
```

## 3. Light-pollution data

The contract reads a `worldengine.radiance/1` grid: `{schema, product, year, unit, source, grid {north, west, dlat, dlon, rows, cols}, values[]}`
(row-major from the north-west cell; null for no data). `livefeeds.sh sky-radiance in.xyz out.json --year 2025` bakes it from
GDAL XYZ text exported from a NASA Black Marble annual composite (VNP46A4, 15 arc-second grid):
`gdal_translate -of XYZ <the granule's NearNadir_Composite_Snow_Free subdataset> out.xyz`, cut to the area plus 50 km
first (`gdalinfo` on the .h5 lists the exact subdataset name; confirm it and the scale factor against the Black Marble
user guide, which this session could not read).

**Baked 2026-10-07** (2025 composite, `NearNadir_Composite_Snow_Free`, VNP46A4 version 002):
`Tools/livefeeds/data/radiance/chicago-2025.json` (161 x 196 cells), `denver-2025.json` (216 x 267, tiles h07v05 +
h07v04, it crosses 40 N), `miami-2025.json` (162 x 162, tiles h09v06 + h10v06, it crosses 80 W); 530 KB together.
Each covers the area box (`areas.json`; Miami 25.55-26.00 N, 80.45-80.10 W) plus 50 km, as 2 x 2 means of the native
15" cells (30", about 0.9 km). Bake: `scripts/data/black_marble_xyz.py OUT.xyz TILE.h5 [TILE.h5] --bbox S,W,N,E`
(h5py + numpy in a scratch venv), then `livefeeds.sh sky-radiance OUT.xyz GRID.json --year 2025 --product VNP46A4
--source-file NAMES` (use absolute paths: the script changes directory). Download from LAADS
`/archive/allData/5200/VNP46A4/<year>/001/` with `Authorization: Bearer $EARTHDATA_TOKEN`.

Kernel-weighted radiance (sanity check, 2026-01-15): central Chicago 139.5, rural Illinois (41.30, -88.40) 2.7,
central Denver 80.2, the mountains (39.10, -106.0) 0.01, central Miami 84.2 nW/cm^2/sr. The ordering is right, but
with `CALIBRATION` 1.0 the downtown artificial/natural ratio of 140 is several times higher than sky-quality-meter
experience (roughly 20-50 in big-city centres), so the calibration step is still open and stays `confidence: "low"`.

Suomi NPP stops delivering on 2026-11-02. Future composites: NOAA-20 **VJ146A4** (same 15" annual product and HDF5
layout, on LAADS collection 5200, years 2022-2025 present); NOAA-21 so far has only VJ246A1/VJ246A2 (daily).

## 4. Known limits

- The engine's star file has the 256 brightest stars (to magnitude 3.4). The naked-eye catalogue (baked 2026-10-07)
  is separate and sky-only: `Tools/livefeeds/data/sky/stars-bsc5-v65.json` (build source, 8,306 merged BSC5 stars to
  V 6.5, 213 with `ci: null`, drawn white; from `build_star_catalog.py OUT --count all --missing-bv null`) packed by
  `scripts/data/pack_star_catalog.py` into `Sources/LiveSky/Resources/stars-v65.bin` (286 KB, shipped once with the
  app), loaded with `StarCatalog.nakedEye()` / `StarCatalog.load(binary:)`. The Python sky layer still defaults to
  the 256-star file; pass the v65 JSON to use the full set.
- Planet positions are good to arcseconds except Jupiter (about 1.5 arcmin) and Saturn (about 5 arcmin), which is the
  stated accuracy of the Standish table 1 fit. Both are far below what a phone screen shows; a VSOP87 series would fix it.
- Elements are valid 1800-2050 only (`state: "unavailable"` outside).
- Twilight brightness is a coarse table and the radiance-to-skyglow step is uncalibrated; both are `inferred` and
  flagged `confidence: "low"`.

## 5. Validation (3 dates x 3 places)

Reference: JPL Horizons was the intended reference, but this cloud session's network policy denies
`ssd.jpl.nasa.gov`. The reference used instead is **JPL's DE421 ephemeris** evaluated by **Skyfield 1.55**
(IAU 2000A nutation, IERS UT1), both installed from PyPI (`skyfield`, `skyfield-data` 7.0.0, which bundles DE421
and the IERS `finals2000A.all`). It is a validation-only dependency; the module itself stays standard-library.
Script: `Tools/livefeeds/validation/sky_reference.py`. Compared: apparent topocentric airless alt/az (both sides
without refraction). Stars use the same catalogue direction on both sides without space motion, so the star
column measures our time, precession, nutation, aberration and horizon pipeline. Places: Chicago (41.8781,
-87.6298, 181 m), Denver (39.7392, -104.9903, 1609 m), Miami (25.7617, -80.1918, 2 m). Stars: HR 2491 Sirius,
7001 Vega, 5340 Arcturus, 424 Polaris, 1713 Rigel.

**Angular error, arcseconds** (ours against Skyfield/DE421):

| UTC | Place | sun | moon | mercury | venus | mars | jupiter | saturn | uranus | neptune | star2491 | star7001 | star5340 | star424 | star1713 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-01-15 03:00Z | Chicago | 7.1 | 2.1 | 3.0 | 5.6 | 13.1 | 0.3 | 251.9 | 11.1 | 33.2 | 0.8 | 1.0 | 1.2 | 0.2 | 0.8 |
| 2026-01-15 03:00Z | Denver | 7.1 | 2.1 | 2.9 | 5.6 | 13.2 | 0.3 | 251.9 | 11.1 | 33.3 | 0.9 | 1.0 | 1.3 | 0.2 | 0.8 |
| 2026-01-15 03:00Z | Miami | 7.2 | 2.1 | 3.0 | 5.7 | 13.1 | 0.2 | 252.0 | 11.1 | 33.2 | 0.8 | 1.1 | 1.2 | 0.2 | 0.8 |
| 2026-06-21 04:30Z | Chicago | 12.7 | 3.3 | 11.5 | 1.0 | 27.0 | 36.1 | 263.1 | 8.3 | 32.0 | 0.8 | 0.3 | 0.4 | 0.3 | 0.9 |
| 2026-06-21 04:30Z | Denver | 12.7 | 3.4 | 11.5 | 1.0 | 27.0 | 36.0 | 263.2 | 8.3 | 32.0 | 0.8 | 0.3 | 0.4 | 0.3 | 0.9 |
| 2026-06-21 04:30Z | Miami | 12.8 | 3.3 | 11.6 | 1.1 | 27.0 | 36.1 | 263.1 | 8.3 | 32.0 | 0.9 | 0.2 | 0.4 | 0.3 | 0.9 |
| 2026-10-06 02:00Z | Chicago | 10.2 | 3.7 | 8.0 | 27.0 | 10.6 | 82.0 | 299.8 | 5.6 | 31.6 | 1.5 | 0.9 | 1.4 | 0.3 | 1.5 |
| 2026-10-06 02:00Z | Denver | 10.2 | 3.7 | 8.0 | 27.1 | 10.6 | 82.0 | 299.8 | 5.6 | 31.6 | 1.6 | 0.8 | 1.3 | 0.3 | 1.6 |
| 2026-10-06 02:00Z | Miami | 10.1 | 3.8 | 7.9 | 27.0 | 10.6 | 82.0 | 299.7 | 5.6 | 31.7 | 1.6 | 0.8 | 1.4 | 0.3 | 1.5 |
| **max** | | **12.8** | **3.8** | **11.6** | **27.1** | **27.0** | **82.0** | **299.8** | **11.1** | **33.3** | **1.6** | **1.1** | **1.4** | **0.3** | **1.6** |
moon illuminated 2026-01-15: ours 0.1268 skyfield(geocentric) 0.1269
moon illuminated 2026-06-21: ours 0.4223 skyfield(geocentric) 0.4257
moon illuminated 2026-10-06: ours 0.2277 skyfield(geocentric) 0.2295

(The Moon's illuminated fraction lines compare our topocentric value with Skyfield's geocentric one, so
differences of a few thousandths are parallax, not error.)

Also checked in the unit tests (`tests/test_sky.py`) against Meeus's worked examples: sidereal time 12.a/12.b
(to 0.1 ms), nutation 22.a, precession 21.b (0.15 arcsec), Moon 47.a (longitude to 0.04 arcsec, latitude 0.8 arcsec,
distance 0.02 km), Sun 25.b (0.3 arcsec) and Venus 33.a (6.5 arcsec).

To repeat against Horizons when the host is allowed: request `QUANTITIES='4'` (apparent azimuth and elevation,
airless) for the same instants and places and compare with `altDeg`/`azDeg`.
