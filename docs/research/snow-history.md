# Snow states: what weather history they need, and where it comes from (proposal, 2026-10-07)

Report only; nothing built. Owner question: what history the snow states need (snowfall over the last 1–3 days, hours
below freezing, melt) and which source provides it.

## What the engine has today

- `Sources/WorldEnvironment/Accumulation.swift` integrates an hourly appearance model of wetness and snow water
  equivalent (SWE, mm) with melt (`lastIntervalMeltMm`), from normalized hourly inputs: temperature, wind, humidity,
  cloud, liquid-equivalent precipitation and its frozen fraction. Snow cover = 1 − exp(−SWE/6).
- Without a starting value it stays `unknown_initial_state` (null, never silently zero), and a missing input hour
  invalidates it (`gap_invalidated`). So every snow state needs **a checkpoint plus complete hourly drivers since it**.
- Weather spec v1 (`docs/proposals/weather-v1`) takes snowfall from WeatherKit hourly `snowfallAmount` / liquid
  equivalent; night spec v1 says accumulation history governs snow, footprints and banks, and "plowed/trodden needs
  supplied history or explicit demo flag".

## What each snow state needs

| State (as drawn) | History needed | Window |
|---|---|---|
| Fresh snow / "morning after snow" | Liquid-equivalent snowfall per hour (or precipitation × frozen fraction); temperature (so it stayed snow) | last 24–72 h |
| Lying snow, ageing | A checkpoint SWE or depth at the window start, then hourly drivers for melt (temperature, sun from the engine, cloud, wind, humidity, rain on snow) | 3 days, longer if no checkpoint |
| Icy / refrozen | Hours below 0 °C and freeze–thaw crossings since the last melt (degree-hours below freezing) | last 24–72 h |
| Melting / slush | Hours above 0 °C with snow present, modeled melt (already computed), rain on snow | last 24–48 h |
| Plowed / trodden streets and walks | No public source records clearing; per night spec, a supplied history or an explicit demo flag | — |

All of it is hourly, per area (one cell per package area is enough at these scales).

## Sources

| Source | Gives | Licence | Latency / coverage | Fit |
|---|---|---|---|---|
| **Apple WeatherKit** (current weather provider) | Hourly history and forecast: temperature, precipitation amount (liquid), snowfall amount, humidity, cloud, wind | DPLA Attachment 8: no storing beyond temporary caching, no derived database (licensing §4.2) | Live; hourly history range per Apple docs (the engine already splits history requests into ≤ 240 h windows) | Best for the hourly drivers, computed on the device for the moment shown, never stored. No snow depth, so no checkpoint |
| **NOAA NOHRSC SNODAS** (via NSIDC, data set G02158) | Daily 1 km grids of SWE and snow depth, CONUS | NOAA / U.S. Government: public domain (verify the NSIDC use statement before use) | Daily, about a day behind (unverified) | The checkpoint: SWE at the window start; a relay subsets each area and may cache it (public domain) |
| **NOAA GHCN-Daily** (NCEI) | Station daily snowfall (SNOW), snow depth (SNWD), Tmax/Tmin | Public domain (U.S. Government) | 1–2 days behind; sparse (airports, co-op stations: ORD, MDW, DEN, a few more) | Validation of the model; fallback checkpoint where a station is close |
| **NWS observations** (`api.weather.gov/stations/…/observations`, METAR) | Hourly temperature, present weather, sometimes precipitation; snow depth only in occasional remarks | Public domain (read 2026-10-07 for the alerts layer) | Real time; airports | Public-domain fallback for hours below freezing and precipitation phase; the engine already has `MetarAdapter.swift` |
| ERA5-Land (Copernicus) | Hourly reanalysis incl. snow depth, SWE, snowfall, temperature | Copernicus licence (attribution; free use) | About 5 days behind | Recaps and back-testing, not live |

## Recommendation (to decide before building)

1. Hourly drivers from WeatherKit for the last 72 h, computed on the device for the requested moment and discarded
   (the licence forbids keeping them), with NWS observations as the public-domain fallback.
2. A daily SWE checkpoint from SNODAS through the relay (public domain, cacheable), so snow cover is "modeled" from a
   real starting value instead of unknown; GHCN-Daily stations to validate the model against measured depth.
3. Plowed and trodden surfaces stay a demo flag: no source exists.

Open points to verify before building: SNODAS latency, file size and NSIDC terms; WeatherKit's historical hourly range
and whether its snowfall amount is liquid-equivalent in the REST API (weather spec v1 marks this as to verify).
