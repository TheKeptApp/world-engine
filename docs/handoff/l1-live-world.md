# L1 handoff: live-world lane (cloud)

Written 2026-10-06. Renderer-neutral data layers for the live world, built in a cloud session (Linux, no Swift
toolchain), so everything is Python 3 standard library under `Tools/livefeeds/` with offline unit tests
(`Tools/livefeeds/livefeeds.sh test`: 186 tests, all passing). No engine, renderer, app or web code was touched.
Contracts: `docs/live-world/` (start at its README for the shared `basis` / `state` / `attribution` vocabulary).
Sources and licences: `docs/research/licensing.md` section 14, rows LW1-LW12.

## State per layer

| Layer | Contract | Status | Validation |
|---|---|---|---|
| 1. Sky | `worldengine.live.sky/1` (`livefeeds.sh sky`) | Built | 3 dates x Chicago/Denver/Miami against JPL DE421 (Skyfield): Sun <= 13", Moon <= 4", stars <= 1.6", planets <= 34" except Jupiter 82" and Saturn 5' (inside the Standish table's stated accuracy); Meeus worked examples in tests |
| 2. Satellites | `worldengine.live.satellites/1` (`livefeeds.sh sats`) | Built | SGP4 matches Vallado's published `tcppver.out` on all 9 near-earth cases (158 states, < 1e-8 km); pass times within 0.3 s of Skyfield, sunlit flag 4,187/4,187 |
| 3. Transit | relay schema 1 + `motion`, `positionState`, `basis`, `/v1/shapes` (`livefeeds.sh serve`) | RTD shape smoothing built; CTA not started | Offline tests (shapes, speed estimation, reference `Smoother` following live-feeds.md 8.6 along shapes, privacy of trip ids) |
| 4. Planes | live-feeds.md 8 schema 1, `live: false`, `basis: "simulated"` (`livefeeds.sh planes`) | ORD and DEN simulated traffic built per `docs/research/ambient-planes.md`; live ADS-B evaluated, not built | Offline tests (StableRandom reference vectors, glide path, timing, spacing, flows, labels) |

## Blocked (and why)

- **Network policy of the cloud environment** denied: celestrak.org, ssd.jpl.nasa.gov, ladsweb.modaps.eosdis.nasa.gov and
  blackmarble.gsfc.nasa.gov, cdsarc.cds.unistra.fr, open-data.rtd-denver.com, www.rtd-denver.com, overpass-api.de,
  spotthestation.nasa.gov, heavens-above.com, api.adsb.lol, transitchicago.com. Nothing was fetched around a block.
  Consequences: no light-pollution grid baked (sky assumes a dark site and says so); no comparison with published ISS
  pass times; CelesTrak and Black Marble terms not re-read; RTD shapes never downloaded for real; no MDW runways.
- **CTA**: key `CTA_TRAIN_API_KEY` is set in the environment but only visible from a new session; `CTA_BUS_API_KEY`
  is still to come. CTA's purpose clause still needs a written answer (live-feeds.md blocker 2).
- **Live aircraft**: needs the adsb.lol operator's written permission and the owner's ODbL share-alike decision.

## Next steps

1. Allow the hosts above (environment settings, Network access), then: bake Black Marble grids for Chicago, Denver,
   Miami (`livefeeds.sh sky-radiance`, docs/live-world/sky.md section 3) and calibrate `CALIBRATION`; compare ISS passes
   with Spot the Station (satellites.md section 3); run the relay once against RTD to load real shapes; derive MDW runways.
2. CTA Train Tracker adapter in the relay, reading `CTA_TRAIN_API_KEY` from the environment (never logged, never in
   responses), credit "Data provided by Chicago Transit Authority"; Bus Tracker with `CTA_BUS_API_KEY` when it exists.
3. Fuller star catalogue (BSC5 to magnitude 6.5): extend `scripts/data/build_star_catalog.py` with a count option and
   a rule for stars without B-V.
4. Owner decisions open: ambient-planes section 9 (default on/off, density, label, departures, where it lives), the
   departure fade-in added here, and adsb.lol.
5. Phase 5A: port the reference algorithms (`sky/`, `sats/passes.py`, `transit/smoothing.Smoother`,
   `planes/ambient.py`) or consume the JSON contracts.
