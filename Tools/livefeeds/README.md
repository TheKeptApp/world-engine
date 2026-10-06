# Live-feed relay prototype (Denver RTD only)

A small local server that polls Denver RTD's public GTFS Realtime vehicle-position file (rail and bus),
normalises it, caches it, and serves a small JSON per area that a phone would fetch. It is a
**prototype, not production**: one feed, no authentication, no scaling, no deployment. The engine
does not use it; nothing here touches engine, renderer, app, web or generator code. Drawing vehicles in
the world comes later (phase 5A). The data contract the renderer will receive is specified in
[`docs/research/live-feeds.md`](../../docs/research/live-feeds.md) section 8, and the design behind this
tool is section 4 of the same file (relay, tiles, stale states, privacy, retention).

Python 3 standard library only (the repository's tools are stdlib Python, like `Tools/regionkit`). The
GTFS Realtime protobuf is decoded by a small wire-format decoder for exactly the fields needed
(`livefeeds/gtfsrt.py`), following the official field numbers at <https://gtfs.org/realtime/reference/>.

## How to run

The owner does not use Terminal; an agent runs these from the repository root.

| Command | What it does |
|---|---|
| `Tools/livefeeds/livefeeds.sh serve` | Polls RTD and serves on `http://127.0.0.1:8765` (add `--port 0` for a free port, `--host`, `--interval`, `--client-poll`, `--idle-seconds`, `--cache-dir`) |
| `Tools/livefeeds/livefeeds.sh once` | Fetches once, prints a summary (counts by kind, feed age, payload sizes, dropped vehicles) and exits |
| `Tools/livefeeds/livefeeds.sh test` | Offline unit tests (no network; fixtures are synthetic) |

Try it: `curl 'http://127.0.0.1:8765/v1/vehicles?bbox=39.74,-105.01,39.76,-104.98'` (a small box, at most 4 x 4 tiles),
and `curl http://127.0.0.1:8765/v1/status` for relay health.

Environment: `LIVEFEEDS_CACHE` (cache directory; default `Tools/livefeeds/.cache/`, git-ignored). On macOS
with a python.org Python that ships no CA certificates, the tool falls back to the system bundle
`/etc/ssl/cert.pem`; certificate checking is never turned off. If TLS still fails, set `SSL_CERT_FILE` to a CA bundle.

## Files

| File | Purpose |
|---|---|
| `livefeeds/gtfsrt.py` | Protobuf wire decoder for the GTFS-RT fields used (header timestamp; entity id; vehicle trip, route, id, label, position, bearing, speed, timestamp, current status) |
| `livefeeds/rtd.py` | RTD constants and attribution, route table (`routes.txt` to rail or bus), fetch, normalisation |
| `livefeeds/zipstream.py` | Reads `routes.txt` from the first ~130 KB of the 10 MB static zip instead of downloading all of it |
| `livefeeds/fetch.py` | Polite HTTP client: honest User-Agent, conditional GET, gzip, size cap, timeout |
| `livefeeds/relay.py` | Poller, last good snapshot (memory plus one short-lived disk copy), backoff, fresh / stale / unavailable |
| `livefeeds/tiles.py` | Zoom-14 tile model: bbox to canonical tile rectangle, 4 x 4 cap |
| `livefeeds/salt.py` | Daily-rotating salted vehicle ids |
| `livefeeds/server.py` | `http.server` handler: `/v1/vehicles`, `/v1/status`, ETag, gzip, cache headers |
| `areas.json` | Allowlist of served areas (data, not code) |
| `tests/` | `unittest` suite; `tests/pbenc.py` is a tiny protobuf encoder that builds synthetic feeds |

Never committed: raw feed bytes, the static zip, `routes.json` (derived route table), `snapshot.json`, `salt.json`. They
live in the cache directory (`.cache/` is git-ignored).

## Endpoint and response

`GET /v1/vehicles?tiles=14/x0/y0/x1/y1` (canonical) or `GET /v1/vehicles?bbox=S,W,N,E` (WGS84; snapped outward to the
zoom-14 tile grid, so identical views share one cache entry; the response's `Content-Location` names the canonical form).
At most 4 x 4 tiles; larger requests get HTTP 400. A rectangle outside every area in `areas.json` gets an empty list
(`area.covered: false`) and never wakes the poller.

```json
{
  "schema": 1,
  "live": true,
  "generatedAt": 1790000031,
  "feedTimestamp": 1790000029,
  "state": "fresh",
  "stale": false,
  "pollIntervalSeconds": 15,
  "area": {"z": 14, "x0": 3413, "y0": 6217, "x1": 3413, "y1": 6217,
           "bbox": [39.740986, -105.007324, 39.757880, -104.985352], "covered": true},
  "vehicles": [
    {"id": "rtd:3fa91c0b77e2", "kind": "bus", "route": "15", "routeName": "15",
     "lat": 39.75, "lon": -104.99, "heading": 90.0, "speedMps": null, "stopStatus": "inTransit",
     "timestamp": 1790000021, "ageSeconds": 10, "source": "rtd"}
  ],
  "attribution": [
    {"source": "rtd", "text": "Live vehicle positions: Regional Transportation District (RTD), Denver, GTFS Realtime feed. Unofficial: not endorsed by, sponsored by or affiliated with RTD. Any views expressed are not those of RTD.",
     "url": "https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds",
     "licenseUrl": "https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement"}
  ]
}
```

Field-by-field meaning, units and the rules for the renderer are in `docs/research/live-feeds.md` section 8. In short:
times are POSIX seconds (UTC) as integers; `lat`/`lon` are WGS84 degrees; `heading` is degrees clockwise from true north
or `null` (RTD sends exactly 0.0 as a placeholder for many vehicles; measured against direction of travel, the relay turns it into `null`); `speedMps` is `null` when RTD does not report it (most vehicles); `state` is `fresh`, `stale` or `unavailable`
(`stale` is `state != "fresh"`); when `unavailable` the vehicle list is empty. Every JSON response (including errors and
`/v1/status`) carries `schema` and the `attribution` block.

Headers: `ETag` (weak; changes with a new snapshot, the area or the state, not every second), `Cache-Control: public,
max-age=10`, `Content-Location`, `Vary: Accept-Encoding`, gzip when requested, `Access-Control-Allow-Origin: *`. Send
`If-None-Match` to get `304`.

## RTD terms and attribution

Pages read on 2026-10-06 with an honest client (User-Agent `WorldEngine-livefeeds-prototype/0.1`):

- Licence: <https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement>
- Feeds and field list: <https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds>
- Static GTFS (route types), which links the same licence: <https://www.rtd-denver.com/open-records/open-spatial-information/gtfs>

**The licence requires no attribution wording.** It grants non-exclusive, limited, revocable rights to use,
reproduce and redistribute the data, says RTD trademarks and copyrighted materials may not be used in association with
the data, and says RTD may change or stop the data at any time. Its link-appearance clause says RTD "reserves the right
to require" that a linking site carry a notice; the exact words to match are "unofficial web site and is not endorsed by,
sponsored by or affiliated with RTD" (same licence URL), followed by a statement that views expressed are not RTD's. RTD
has not required it of us, but the relay always sends it, so the credit is a neutral line plus that non-endorsement
statement (`attribution[0].text`, taken verbatim from `livefeeds/rtd.py`):

> Live vehicle positions: Regional Transportation District (RTD), Denver, GTFS Realtime feed. Unofficial: not endorsed by, sponsored by or affiliated with RTD. Any views expressed are not those of RTD.

No RTD logo, map or other RTD content is used. The RTD name appears as plain text only, inside that credit and notice.
The static GTFS page separately asks that the RTD logo, RTD maps or other website content not be used without advance permission.
Open questions for RTD (commercial use is not addressed; no polling guideline is published) are in
`docs/research/live-feeds.md` section 6.

## Polling etiquette

- One request to RTD at most every 30 s. The interval is configurable upward only (`--interval`, never below 30), with a
  small positive jitter (up to 10 percent), so the gap is never under 30 s.
- Honest User-Agent `WorldEngine-livefeeds-prototype/0.1`; never a browser identity.
- Conditional GET: RTD sends `ETag` and `Last-Modified`, so the relay sends `If-None-Match` and `If-Modified-Since` and
  treats `304` as a good pull. A file whose header timestamp is not newer than the one held is ignored.
- Back-off on errors: the delay doubles per consecutive failure up to 5 minutes, `Retry-After` is honoured (capped at 15
  minutes), and 401, 403, 404 and 410 wait 15 minutes (a revoked or moved feed is not retried hot).
- Idle pause: with no request for 2 minutes the relay stops polling (`--idle-seconds`, 0 disables); a request wakes it.
- The static zip is read once per week (or when the feed shows a route the table lacks, at most every 6 hours), by
  streaming only the start of the file (about 130 KB of about 10 MB).

## Privacy

- Vehicle ids are `rtd:` plus 12 hex digits of HMAC-SHA256 over the raw id with a random per-service-day salt (service day
  starts 03:00 local); the salt is kept only for the current day (`salt.json`, mode 0600). Raw vehicle ids, labels and trip
  ids never appear in any response or on disk (the disk snapshot holds salted ids only).
- No client address is logged or kept, there are no per-request log lines, and requested tiles are not stored. Only aggregate
  counters (`/v1/status`) exist. Poll lines on stderr hold counts and sizes, never vehicle data.
- Retention: the latest snapshot only, in memory plus one disk copy that is ignored after 5 minutes.

## Stale handling

`fresh`: last good pull at most 2 poll intervals old and the feed's own timestamp at most 120 s old (RTD: "accurate within
2 minutes"). `stale`: otherwise, up to 5 minutes (vehicles still served, flagged). `unavailable`: older than 5 minutes, or no
data (vehicles empty). After errors the last snapshot keeps being served with these flags. Vehicles whose own position is
more than 5 minutes behind the feed time are dropped at ingestion, as are non-revenue vehicles that carry no route.

## Out of scope

Other feeds (CTA, Metra, Pace, aircraft, Bustang), authentication and API keys, per-client rate limiting, TLS, gzip of
the upstream beyond what the client accepts, scaling and edge caching (the headers are CDN-ready but no CDN is used),
persistence beyond the one short-lived snapshot, process supervision, any app or renderer code.
