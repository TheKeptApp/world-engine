"""Chicago Transit Authority: Train Tracker locations ('L' trains), fetch and normalise.

API: Train Tracker `ttpositions.aspx` (https://www.transitchicago.com/developers/ttdocs/), one call for all eight
'L' routes, JSON output. Positions are derived from track circuits, not GPS (live-feeds.md 2.3), so they move in
steps; they are still `observed` (CTA's measurement, passed through).

Key: read from the environment variable CTA_TRAIN_API_KEY when the request is made. It is never logged, never
put in an error message, a response, the cache or the repository: every error text that leaves this module is
built here without the URL. Bus Tracker (CTA_BUS_API_KEY) comes later.

Terms: CTA Developer License Agreement (live-feeds.md 2.3). Credit "Data provided by Chicago Transit Authority"
(one of CTA's suggested lines). Run numbers are salted like every other vehicle id (live-feeds.md 8.9).
"""

import datetime
import json
import os
import urllib.parse
from collections import Counter
from typing import Callable, Dict, List, Optional

from .fetch import FetchError, FetchResult, USER_AGENT, http_get
from .rtd import Normalised, _valid_position
from .salt import DailySalt

SOURCE = "cta"
KEY_ENV = "CTA_TRAIN_API_KEY"
POSITIONS_URL = "https://lapi.transitchicago.com/api/1.0/ttpositions.aspx"
TIMEZONE = "America/Chicago"
ATTRIBUTION = {
    "source": SOURCE,
    "text": "Data provided by Chicago Transit Authority",
    "url": "https://www.transitchicago.com/developers/",
    "licenseUrl": "https://www.transitchicago.com/developers/terms/",
}

# Route codes as the API takes them (also CTA's GTFS route_id) -> public name. The API answers in lower case.
ROUTES = {"Red": "Red", "Blue": "Blue", "Brn": "Brown", "G": "Green", "Org": "Orange", "P": "Purple",
          "Pink": "Pink", "Y": "Yellow"}
_BY_LOWER = {k.lower(): k for k in ROUTES}

# Train Tracker error codes. Key and quota problems will not fix themselves on a retry: they are reported with an
# HTTP-like status so the relay backs off for 15 minutes (relay.HARD_ERRORS). Codes from the ttdocs error table as
# remembered (101 invalid key, 102 daily limit exceeded); the docs page could not be re-read here (transitchicago.com
# is denied by the cloud network policy). Any other non-zero code is a normal error with the usual backoff.
HARD_CODES = {"101": 403, "102": 403}

try:
    from zoneinfo import ZoneInfo
    _TZ = ZoneInfo(TIMEZONE)
except Exception:  # pragma: no cover - only without a tz database
    _TZ = None


def request_url(key: str) -> str:
    return POSITIONS_URL + "?" + urllib.parse.urlencode(
        {"key": key, "rt": ",".join(ROUTES), "outputType": "JSON"})


def fetcher(user_agent: str = USER_AGENT, timeout: float = 20.0,
            environ=os.environ, get: Callable = http_get) -> Callable[[Optional[str], Optional[str]], FetchResult]:
    """Relay fetch callable. The key is read per request, so a rotated key needs no restart."""
    def fetch(etag: Optional[str], last_modified: Optional[str]) -> FetchResult:
        key = environ.get(KEY_ENV, "").strip()
        if not key:
            raise FetchError("%s is not set" % KEY_ENV, 401)
        try:
            return get(request_url(key), user_agent, None, None, timeout)
        except FetchError as e:
            # Never let the URL (it carries the key) into a message: rebuild the text from the status only.
            raise FetchError("CTA HTTP %s" % e.status if e.status else "CTA network error", e.status, e.retry_after)
        except Exception as e:  # noqa: BLE001 - same reason: no exception text that might quote the URL
            raise FetchError("CTA request failed (%s)" % type(e).__name__)
    return fetch


def local_time(text: Optional[str]) -> Optional[int]:
    """'2026-10-06T18:57:08' (Chicago local time, as the API sends it) -> POSIX seconds, or None."""
    if not text:
        return None
    try:
        t = datetime.datetime.strptime(text.strip(), "%Y-%m-%dT%H:%M:%S")
    except ValueError:
        return None
    return int(t.replace(tzinfo=_TZ or datetime.timezone.utc).timestamp())


def _num(x) -> Optional[float]:
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def _as_list(x) -> List[dict]:
    if x is None:
        return []
    return [x] if isinstance(x, dict) else [t for t in x if isinstance(t, dict)]


def normalise(body: bytes, salt: DailySalt, now: float, max_vehicle_age: float = 300.0) -> Normalised:
    """Train Tracker JSON -> relay vehicle records (same shape as rtd.normalise, live-feeds.md 8.3).

    timestamp is the train's `prdt` (when CTA generated this train's report); heading is CTA's bearing; speed is
    not reported (null); stopStatus "incoming" when CTA flags the train as approaching its next station
    (`isApp`), otherwise null (CTA does not say whether a train is stopped). Raises ValueError on a body that is
    not a Train Tracker answer, FetchError on an API error code.
    """
    doc = json.loads(body.decode("utf-8"))
    tt = doc.get("ctatt") if isinstance(doc, dict) else None
    if not isinstance(tt, dict):
        raise ValueError("not a Train Tracker response")
    code = str(tt.get("errCd") or "0")
    if code != "0":
        raise FetchError("CTA error %s" % code, HARD_CODES.get(code))
    feed_ts = local_time(tt.get("tmst")) or int(now)
    dropped: Counter = Counter()
    out: List[dict] = []
    for r in _as_list(tt.get("route")):
        route = _BY_LOWER.get(str(r.get("@name", "")).lower())
        for t in _as_list(r.get("train")):
            if route is None:
                dropped["unknownRoute"] += 1
                continue
            lat, lon = _num(t.get("lat")), _num(t.get("lon"))
            if lat is None or lon is None:
                dropped["noPosition"] += 1
                continue
            if not _valid_position(lat, lon):
                dropped["badPosition"] += 1
                continue
            run = str(t.get("rn") or "").strip()
            if not run:
                dropped["noId"] += 1
                continue
            ts = local_time(t.get("prdt")) or feed_ts
            if feed_ts - ts > max_vehicle_age:
                dropped["tooOld"] += 1
                continue
            hdg = _num(t.get("heading"))
            heading = round(hdg % 360.0, 1) if hdg is not None and 0.0 <= hdg <= 360.0 else None
            out.append({
                "id": salt.vehicle_id(SOURCE, route + ":" + run, now),
                "kind": "rail",
                "route": route,
                "routeName": ROUTES[route],
                "lat": round(lat, 5),
                "lon": round(lon, 5),
                "heading": heading,
                "speedMps": None,
                "stopStatus": "incoming" if str(t.get("isApp")) == "1" else None,
                "timestamp": ts,
                "source": SOURCE,
            })
    out.sort(key=lambda v: v["id"])
    return Normalised(out, feed_ts, dict(dropped))
