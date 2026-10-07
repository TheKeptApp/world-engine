"""Chicago Transit Authority: Bus Tracker vehicle locations, fetch and normalise.

API: Bus Tracker v3 (https://www.transitchicago.com/developers/bustracker/), JSON. `getvehicles` takes at most 10
routes per call, so one poll is `getroutes` (cached for a day) plus ceil(routes / 10) `getvehicles` calls (about 13
for CTA's 125 routes). At the relay's 30 s minimum that is under 38,000 transactions a day even when polled around
the clock, inside the default limit of 100,000 a day (Bus Tracker FAQ, read 2026-10-07); the relay also stops
polling when nobody asks. Positions are the buses' own GPS reports: `observed`.

Key: read from the environment variable CTA_BUS_API_KEY when the request is made. It is never logged, never put
in an error message, a response, the cache or the repository: every error text that leaves this module is built
here without the URL (same rules as the Train Tracker adapter, cta.py).

Terms: CTA Developer License Agreement (live-feeds.md 2.3), same credit as trains. Vehicle numbers are salted
like every other vehicle id (live-feeds.md 8.9); trip, block and pattern ids are not passed on.
"""

import datetime
import json
import os
import urllib.parse
from collections import Counter
from typing import Callable, Dict, List, Optional, Tuple

from .cta import ATTRIBUTION as _CTA_ATTRIBUTION, _TZ, _as_list, _num
from .fetch import FetchError, FetchResult, USER_AGENT, http_get
from .rtd import Normalised, _valid_position
from .salt import DailySalt

SOURCE = "ctabus"
KEY_ENV = "CTA_BUS_API_KEY"
API_BASE = "https://www.ctabustracker.com/bustime/api/v3/"
ATTRIBUTION = dict(_CTA_ATTRIBUTION, source=SOURCE)
ROUTES_MAX_AGE = 86400.0
ROUTES_PER_CALL = 10

# Errors without an "rt" field concern the whole request. Key and quota problems will not fix themselves on a
# retry, so they carry an HTTP-like status and the relay backs off for 15 minutes (relay.HARD_ERRORS). Matched on
# the message text, as observed live on 2026-10-07 ("Invalid API access key supplied") and in the developer guide
# (daily transaction limit). Per-route "No data found for parameter" just means no bus on that route right now.
HARD_MESSAGES = ("invalid api access key", "transaction limit")


def request_url(endpoint: str, key: str, **params) -> str:
    q = {"key": key, "format": "json"}
    q.update(params)
    return API_BASE + endpoint + "?" + urllib.parse.urlencode(q)


def _response(body: bytes) -> dict:
    doc = json.loads(body.decode("utf-8"))
    r = doc.get("bustime-response") if isinstance(doc, dict) else None
    if not isinstance(r, dict):
        raise ValueError("not a Bus Tracker response")
    return r


def _check_errors(r: dict) -> None:
    for e in _as_list(r.get("error")):
        if "rt" in e or "vid" in e:
            continue
        msg = str(e.get("msg") or "").lower()
        hard = any(h in msg for h in HARD_MESSAGES)
        raise FetchError("CTA Bus Tracker error (%s)" % ("key or daily limit" if hard else "request"),
                         403 if hard else None)


def fetcher(user_agent: str = USER_AGENT, timeout: float = 20.0, environ=os.environ, get: Callable = http_get,
            clock: Callable[[], float] = None) -> Callable[[Optional[str], Optional[str]], FetchResult]:
    """Relay fetch callable: routes (daily) plus every route's vehicles, combined into one Bus Tracker-shaped body
    {"bustime-response": {"vehicle": [...], "routes": [...]}} for normalise(). The key is read per request."""
    import time
    clock = clock or time.time
    routes_cache: Dict[str, object] = {"at": None, "routes": []}

    def call(endpoint: str, key: str, **params) -> Tuple[dict, int]:
        try:
            res = get(request_url(endpoint, key, **params), user_agent, None, None, timeout)
        except FetchError as e:
            # Never let the URL (it carries the key) into a message: rebuild the text from the status only.
            raise FetchError("CTA Bus HTTP %s" % e.status if e.status else "CTA Bus network error",
                             e.status, e.retry_after)
        except Exception as e:  # noqa: BLE001 - same reason: no exception text that might quote the URL
            raise FetchError("CTA Bus request failed (%s)" % type(e).__name__)
        r = _response(res.body or b"{}")
        _check_errors(r)
        return r, res.wire_bytes

    def fetch(etag: Optional[str], last_modified: Optional[str]) -> FetchResult:
        key = environ.get(KEY_ENV, "").strip()
        if not key:
            raise FetchError("%s is not set" % KEY_ENV, 401)
        wire = 0
        now = clock()
        if routes_cache["at"] is None or now - routes_cache["at"] > ROUTES_MAX_AGE or not routes_cache["routes"]:
            r, n = call("getroutes", key)
            wire += n
            routes_cache["routes"] = [{"rt": str(x.get("rt")), "rtnm": x.get("rtnm")}
                                      for x in _as_list(r.get("routes")) if x.get("rt")]
            routes_cache["at"] = now
        routes = routes_cache["routes"]
        vehicles: List[dict] = []
        for i in range(0, len(routes), ROUTES_PER_CALL):
            batch = ",".join(x["rt"] for x in routes[i:i + ROUTES_PER_CALL])
            r, n = call("getvehicles", key, rt=batch, tmres="s")
            wire += n
            vehicles.extend(_as_list(r.get("vehicle")))
        body = json.dumps({"bustime-response": {"vehicle": vehicles, "routes": routes}},
                          separators=(",", ":")).encode()
        return FetchResult(200, body, None, None, wire)
    return fetch


def local_time(text: Optional[str]) -> Optional[int]:
    """'20261006 19:18:46' or '20261006 19:18' (Chicago local time) -> POSIX seconds, or None."""
    if not text:
        return None
    for fmt in ("%Y%m%d %H:%M:%S", "%Y%m%d %H:%M"):
        try:
            t = datetime.datetime.strptime(text.strip(), fmt)
        except ValueError:
            continue
        return int(t.replace(tzinfo=_TZ or datetime.timezone.utc).timestamp())
    return None


def normalise(body: bytes, salt: DailySalt, now: float, max_vehicle_age: float = 300.0) -> Normalised:
    """Combined Bus Tracker body (see fetcher) -> relay vehicle records (same shape as rtd.normalise).

    timestamp is the bus's `tmstmp`; heading its `hdg`; speed not reported (null); stopStatus null (not reported).
    The feed timestamp is the newest vehicle report (Bus Tracker sends none for the whole answer), else now.
    """
    r = _response(body)
    _check_errors(r)
    names = {str(x.get("rt")): x.get("rtnm") for x in _as_list(r.get("routes"))}
    raw = _as_list(r.get("vehicle"))
    stamps = [t for t in (local_time(v.get("tmstmp")) for v in raw) if t is not None and t <= now + 120]
    feed_ts = max(stamps) if stamps else int(now)
    dropped: Counter = Counter()
    seen = set()
    out: List[dict] = []
    for v in raw:
        route = str(v.get("rt") or "").strip()
        vid = str(v.get("vid") or "").strip()
        if not route or not vid:
            dropped["noId"] += 1
            continue
        if vid in seen:
            dropped["duplicate"] += 1
            continue
        lat, lon = _num(v.get("lat")), _num(v.get("lon"))
        if lat is None or lon is None:
            dropped["noPosition"] += 1
            continue
        if not _valid_position(lat, lon):
            dropped["badPosition"] += 1
            continue
        ts = local_time(v.get("tmstmp")) or feed_ts
        if feed_ts - ts > max_vehicle_age:
            dropped["tooOld"] += 1
            continue
        seen.add(vid)
        hdg = _num(v.get("hdg"))
        out.append({
            "id": salt.vehicle_id(SOURCE, vid, now),
            "kind": "bus",
            "route": route,
            "routeName": names.get(route) or route,
            "lat": round(lat, 5),
            "lon": round(lon, 5),
            "heading": round(hdg % 360.0, 1) if hdg is not None and 0.0 <= hdg <= 360.0 else None,
            "speedMps": None,
            "stopStatus": None,
            "timestamp": ts,
            "source": SOURCE,
        })
    out.sort(key=lambda x: x["id"])
    return Normalised(out, feed_ts, dict(dropped))
