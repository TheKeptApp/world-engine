# Transit layer: live vehicles, smoothed along route shapes

The live transit layer is the relay in `Tools/livefeeds/` (Denver RTD GTFS Realtime today). Its response
contract is `docs/research/live-feeds.md` section 8 (schema 1); this page documents what the live-world lane
added on top: **route-shape smoothing**, per-vehicle position state and `basis`, and the `/v1/shapes`
endpoint. Vocabulary (`basis`, `state`, `attribution`): [README.md](README.md).

## 1. Status by feed

| Feed | Status |
|---|---|
| RTD GTFS-RT (Denver, rail and bus) | Relayed (prototype since 2026-10-06), now with shape smoothing. Code and offline tests only in this pass: the cloud session's network policy denies `open-data.rtd-denver.com` and `www.rtd-denver.com`, so the shape download has not run against the real static feed yet. |
| CTA Train Tracker, Bus Tracker | **Not started, waiting for the API keys.** R adds them as environment secrets (cloud environment settings), never in chat or in the repo. Planned names: `CTA_TRAIN_API_KEY` (set in the environment; visible from the next session) and `CTA_BUS_API_KEY` (to come); the relay reads them from the environment and the feeds stay off when they are missing. Required credit in the contract: **"Data provided by Chicago Transit Authority"**. CTA's purpose clause still needs a written answer before shipping (`live-feeds.md` §1 blocker 2). |

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
