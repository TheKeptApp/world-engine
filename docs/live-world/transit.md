# Transit layer: live vehicles, smoothed along route shapes

The live transit layer is the relay in `Tools/livefeeds/` (Denver RTD GTFS Realtime today). Its response
contract is `docs/research/live-feeds.md` section 8 (schema 1); this page documents what the live-world lane
added on top: **route-shape smoothing**, per-vehicle position state and `basis`, and the `/v1/shapes`
endpoint. Vocabulary (`basis`, `state`, `attribution`): [README.md](README.md).

## 1. Status by feed

| Feed | Status |
|---|---|
| RTD GTFS-RT (Denver, rail and bus) | Relayed (prototype since 2026-10-06), now with shape smoothing. Code and offline tests only in this pass: the cloud session's network policy denies `open-data.rtd-denver.com` and `www.rtd-denver.com`, so the shape download has not run against the real static feed yet. |
| CTA Train Tracker ('L' trains) | **Built 2026-10-06** (`livefeeds/cta.py`; `livefeeds.sh serve --feed cta`, `once --feed cta`). One `ttpositions.aspx` call per poll covers all eight lines (about 21 KB raw, 3 KB on the wire; 30 s floor and idle pause as for RTD, so at most 2,880 calls a day against CTA's default 100,000, per ttdocs re-read 2026-10-07). Key from `CTA_TRAIN_API_KEY`, read per request; it never appears in logs, error texts, responses or the cache (tested). Records follow live-feeds §8.3: `kind` rail, `route` CTA code (`Red`, `Brn`, ...), `routeName` public name (`Brown`), `heading` CTA bearing, `speedMps` null (not reported), `stopStatus` `incoming` when CTA flags the train approaching (`isApp`) else null, `timestamp` the train's `prdt` (Chicago local time converted to UTC), id = salted route + run number. API error codes inside a 200 body keep the last snapshot; invalid key (101) and daily limit (102) back off 15 minutes. Credit on every response: **"Data provided by Chicago Transit Authority"** (`source: cta`). Route shapes: see the CTA static GTFS row (trains snap to the nearest shape of their line). First live run 2026-10-06 23:58Z: 78 trains, 0 dropped, fresh. One relay process per feed for now (`--feed rtd|cta`, each serving the `areas.json` areas that list it; CTA caches under `<cache>/cta/`); merging feeds behind one endpoint is a follow-up. CTA's purpose clause still needs a written answer before shipping (`live-feeds.md` §1 blocker 2). |
| CTA Bus Tracker | **Built 2026-10-07** (`livefeeds/ctabus.py`; `livefeeds.sh serve --feed ctabus`, `once --feed ctabus`). Bus Tracker v3 JSON: `getroutes` once a day, then `getvehicles` 10 routes per call with `tmres=s` (13 calls per poll for 125 routes, under 38,000 a day even polled non-stop at the 30 s floor, against the default 100,000). Key from `CTA_BUS_API_KEY`, same handling as trains (never in logs, errors, responses or the cache; tested). Records: `kind` bus, `route` CTA route code (`X9`), `routeName` CTA's route name, `heading` `hdg`, `speedMps` and `stopStatus` null (not reported), `timestamp` the bus's `tmstmp` (Chicago local to UTC), id = salted vehicle number; trip, block and pattern ids are dropped. Per-route "No data found" is normal (no bus on that route); an error without a route (invalid key, daily transaction limit) is a hard error with the 15-minute backoff. Feed timestamp = newest bus report. Same credit (`source: ctabus`). Shapes: see the CTA static GTFS row (snapped by Bus Tracker pattern id). First live run 2026-10-07 00:20Z: 880 buses, 2 dropped as too old, fresh, 53 KB on the wire per poll. |
| CTA static GTFS (shapes, stops) | **Built 2026-10-07** (`livefeeds/ctagtfs.py`). `google_transit.zip` from transitchicago.com (69 MB; streamed to a temp file, capped at 160 MB; `stop_times.txt` never read), re-read weekly like RTD's (`shapes_max_age`), cached as `shapes.json` and `stops.json` in each CTA feed's cache directory. CTA's live feeds carry no GTFS trip ids, so shapes are chosen by key (`ShapeTable.resolve`): buses by Bus Tracker pattern id (`pid`; the bus `shape_id` is a 3-digit service prefix plus the pid padded to 5 digits, one shape kept per pattern), falling back to the nearest of the route's shapes; trains by line (Train Tracker codes equal GTFS `route_id`s), nearest shape, kept while the train stays within 60 m of it so it does not hop branches on shared track. Speed along the shape is then estimated exactly as for RTD (live-feeds.md 8.6: `motion` with `speedBasis: inferred`, caps 30 m/s bus, 40 m/s rail); stale data freezes in the reference `Smoother` and never animates (tested). Stops: `GET /v1/stops?bbox=S,W,N,E` (rail stations and bus stops, id/name/position/kind, max 500, cached a day). Result: 761 shapes, 10,826 stops. Live 2026-10-07: trains 73 of 74 snapped, buses 751 of 768 by pattern (15 patterns missing from the static feed now fall back to the route), second poll 35 s later gave inferred speeds (median train 6.8 m/s, bus 3.6 m/s). |

## 2. What changed in the vehicle record

Each vehicle in `/v1/vehicles` now also carries:

| Field | Meaning |
|---|---|
| `positionState` | `fresh` when the vehicle's own `timestamp` is at most 120 s old (`live-feeds.md` 8.6 step 8), else `stale` |
| `basis` | `observed`: `lat`, `lon`, `heading`, `speedMps`, `timestamp` are the agency's report |
| `motion` | `null`, or how to move the vehicle along its route shape (below). Always `null` when `positionState` is `stale` |

`motion`:

| Field | Meaning |
|---|---|
| `shapeId` | The trip's GTFS shape; fetch its geometry from `/v1/shapes?ids=` |
| `distM` | Metres along the shape of the reported position (the report snapped to the shape) |
| `offsetM` | How far the report was from the shape (positions more than 60 m off get `motion: null`) |
| `t` | The report's own time (equals `timestamp`) |
| `speedMps` | Speed along the shape, or `null` (then the vehicle is not extrapolated) |
| `speedBasis` | `observed` (the agency's speed), `inferred` (from the last two reports on the same shape, 5 to 300 s apart, capped at 30 m/s bus, 40 m/s rail) or `null` |

Raw trip ids are used inside the relay only to find the shape; they are never in a response or on disk
(the snapshot file holds salted vehicle ids, shape ids and distances).

## 3. `/v1/shapes?ids=A,B`

1 to 50 ids. Response: `{schema, shapes: [{id, points: [[lat, lon], ...], distM: [...], lengthM}], missing: [...],
basis: "observed", attribution}`. Points are the GTFS shape simplified with Douglas-Peucker at 2 m; `distM` is the
cumulative distance the relay used, so client and relay agree exactly. `Cache-Control: public, max-age=86400`
(shapes change with RTD's schedule changes; the relay re-reads the static zip weekly).

## 4. Renderer algorithm (reference: `Tools/livefeeds/livefeeds/transit/smoothing.py`, class `Smoother`)

`live-feeds.md` 8.6 applied along the shape instead of straight lines:

1. Align the clock to `generatedAt` (8.6 step 1). Keep the last two reports per vehicle on the same `shapeId`.
2. Draw where the vehicle was 45 s ago: interpolate `distM` linearly between the two reports bracketing that time.
3. Past the newest report, continue at `speedMps` for at most 30 s, then hold. A vehicle whose `stopStatus` is
   `stopped` is held.
4. When new data moves the curve, blend from the drawn distance to the new one over 3 s along the shape; more than
   150 m: snap while faded (8.6 step 5).
5. Never reverse on screen by more than 15 m: hold instead, for at most 10 s.
6. Position: `point_at(distance)` on the shape polyline, heading from the segment.
7. **Never stale as live:** when the layer `state` is not `fresh`, or the vehicle's `positionState` is `stale`, or
   `motion` is `null`, the vehicle is not animated: it freezes where it is drawn (or at its reported lat/lon) and
   follows 8.7 (fade to 40 percent when stale, remove when unavailable).

Without shapes (static data unavailable), vehicles still arrive with `motion: null` and the straight-line rules of
8.6 apply unchanged.

## 5. Tests

`Tools/livefeeds/tests/test_transit.py`: shape parsing and simplification, projection (including out-and-back
shapes), speed estimation and its rejection rules, the reference smoother (interpolation in the past, 30 s
extrapolation cap, blending, snap, no reversing, stale freeze), and relay wiring (motion served, trip ids
never served or written). `tests/test_server.py`: `/v1/shapes`.
