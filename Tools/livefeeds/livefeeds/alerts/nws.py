"""NWS weather alerts layer (docs/live-world/alerts.md): active alerts from api.weather.gov for the live-world areas.

Official, observed data passed through verbatim: event, severity, certainty, urgency, headline, description and
instruction are never rewritten, shortened or re-ranked (the meaning of a warning is the NWS's). Each alert carries
its label, source and official link. An alert is shown only while it is in force at the snapshot instant: an expired
or ended alert, a cancellation, or a non-"Actual" message (test, exercise, draft) is never emitted as active.

Polite client (NWS API guidance): a User-Agent naming the application and a contact address, which comes only from
configuration (environment variable NWS_CONTACT, or the git-ignored .local/livefeeds.json key "nwsContact"), never
from shared code; conditional requests (If-Modified-Since); the cache's own Cache-Control/Expires decide when to ask
again, with a floor of MIN_REFRESH_SECONDS; a refused request (4xx) stops fetching for BLOCKED_BACKOFF_SECONDS and
says so (needsHuman). Alerts without a polygon are placed by their affected zones' geometry, fetched once and cached.
"""

import email.utils
import json
import os
import tempfile
import time
from typing import Callable, Dict, List, Optional, Tuple

from .. import fetch

API = "https://api.weather.gov"
ACTIVE_URL = API + "/alerts/active?area=%s"
USER_AGENT_BASE = "WorldEngine-livefeeds-prototype/0.1 (weather alerts layer)"
MIN_REFRESH_SECONDS = 60
DEFAULT_REFRESH_SECONDS = 120
FRESH_SECONDS = 15 * 60
ZONE_MAX_AGE_SECONDS = 30 * 86400
BLOCKED_BACKOFF_SECONDS = 3600
LABEL = "Official weather alert (National Weather Service)"
ATTRIBUTION = {
    "source": "nws",
    "text": "Weather alerts: National Weather Service (weather.gov). Official text, unaltered.",
    "url": "https://www.weather.gov/",
    "live": True,
    "required": True,
}
HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AREAS_FILE = os.path.join(HERE, "data", "alerts-areas.json")
REPO = os.path.dirname(os.path.dirname(HERE))
LOCAL_CONFIG = os.path.join(REPO, ".local", "livefeeds.json")


class ConfigError(Exception):
    pass


def contact(environ=os.environ, local_config: str = LOCAL_CONFIG) -> str:
    """The contact address for the User-Agent, from NWS_CONTACT or .local/livefeeds.json (never from code)."""
    value = environ.get("NWS_CONTACT")
    if not value:
        try:
            with open(local_config, "r", encoding="utf-8") as fh:
                value = json.load(fh).get("nwsContact")
        except (OSError, ValueError):
            value = None
    if not value or "@" not in value:
        raise ConfigError("NWS needs a contact address: set NWS_CONTACT or \"nwsContact\" in .local/livefeeds.json")
    return value


def user_agent(contact_address: str) -> str:
    return "%s; contact: %s" % (USER_AGENT_BASE, contact_address)


def load_areas(path: str = AREAS_FILE) -> List[dict]:
    with open(path, "r", encoding="utf-8") as fh:
        doc = json.load(fh)
    if doc.get("schema") != "worldengine.alerts-areas/1":
        raise ValueError("unsupported alerts areas schema")
    return doc["areas"]


# ------------------------------------------------------------------ time and cache headers


def parse_time(value: Optional[str]) -> Optional[float]:
    """ISO 8601 with offset (NWS) -> POSIX seconds."""
    if not value:
        return None
    from datetime import datetime
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def max_age(headers: Dict[str, str], now: float) -> Optional[float]:
    """Seconds the response may be reused, from Cache-Control max-age or Expires."""
    cc = (headers.get("Cache-Control") or "").lower()
    for part in cc.split(","):
        part = part.strip()
        if part.startswith("max-age="):
            try:
                return max(0.0, float(part[8:]))
            except ValueError:
                pass
    exp = headers.get("Expires")
    if exp:
        try:
            return max(0.0, email.utils.parsedate_to_datetime(exp).timestamp() - now)
        except (TypeError, ValueError):
            return None
    return None


# ------------------------------------------------------------------ geometry


def _rings(geometry: Optional[dict]) -> List[List[List[float]]]:
    """Outer rings ([lon, lat] lists) of a GeoJSON Polygon or MultiPolygon."""
    if not geometry:
        return []
    if geometry.get("type") == "Polygon":
        return [geometry["coordinates"][0]] if geometry.get("coordinates") else []
    if geometry.get("type") == "MultiPolygon":
        return [p[0] for p in geometry.get("coordinates", []) if p]
    return []


def _point_in_ring(lon: float, lat: float, ring: List[List[float]]) -> bool:
    inside = False
    n = len(ring)
    for i in range(n):
        x1, y1 = ring[i][0], ring[i][1]
        x2, y2 = ring[(i + 1) % n][0], ring[(i + 1) % n][1]
        if (y1 > lat) != (y2 > lat) and lon < (x2 - x1) * (lat - y1) / (y2 - y1) + x1:
            inside = not inside
    return inside


def _seg_intersect(a, b, c, d) -> bool:
    def o(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) <= 0 and o(c, d, a) * o(c, d, b) <= 0


def ring_touches_box(ring: List[List[float]], box: Tuple[float, float, float, float]) -> bool:
    """box = (south, west, north, east). True if the ring and the box overlap."""
    s, w, n, e = box
    if any(w <= p[0] <= e and s <= p[1] <= n for p in ring):
        return True
    corners = [(w, s), (e, s), (e, n), (w, n)]
    if any(_point_in_ring(x, y, ring) for x, y in corners):
        return True
    edges = list(zip(corners, corners[1:] + corners[:1]))
    for i in range(len(ring)):
        p, q = ring[i], ring[(i + 1) % len(ring)]
        if any(_seg_intersect(p, q, c, d) for c, d in edges):
            return True
    return False


# ------------------------------------------------------------------ fetching


class AlertStore:
    """Cached active alerts and zone geometry, refreshed politely."""

    def __init__(self, cache_dir: str, states: List[str], contact_address: Optional[str] = None,
                 getter: Callable = None, clock: Callable[[], float] = time.time):
        self.cache_dir = cache_dir
        self.states = sorted(set(states))
        self.clock = clock
        ua = user_agent(contact_address) if contact_address else None
        self.get = getter or (lambda url, lm=None: fetch.http_get_headers(url, user_agent=ua, last_modified=lm,
                                                                          accept="application/geo+json"))
        os.makedirs(cache_dir, exist_ok=True)

    def _path(self, name: str) -> str:
        return os.path.join(self.cache_dir, name)

    def _read(self, name: str) -> dict:
        try:
            with open(self._path(name), "r", encoding="utf-8") as fh:
                return json.load(fh)
        except (OSError, ValueError):
            return {}

    def _write(self, name: str, doc: dict) -> None:
        fd, tmp = tempfile.mkstemp(dir=self.cache_dir, suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(doc, fh)
        os.replace(tmp, self._path(name))

    def active(self, allow_fetch: bool = True) -> Tuple[List[dict], Optional[float], Optional[str]]:
        """(features, fetchedAt, error). Fetches only when the cached response may no longer be reused."""
        name = "alerts-%s.json" % "-".join(s.lower() for s in self.states)
        doc = self._read(name)
        now = self.clock()
        due = doc.get("reuseUntil", 0)
        error = doc.get("lastError")
        if allow_fetch and now >= max(due, doc.get("blockedUntil", 0)) and \
                now - doc.get("attemptedAt", 0) >= MIN_REFRESH_SECONDS:
            doc["attemptedAt"] = now
            try:
                res, headers = self.get(ACTIVE_URL % ",".join(self.states), doc.get("lastModified"))
                if res.status == 200:
                    body = json.loads(res.body.decode("utf-8"))
                    if body.get("type") != "FeatureCollection":
                        raise ValueError("not a FeatureCollection")
                    doc["features"] = body.get("features", [])
                    doc["updated"] = body.get("updated")
                    doc["lastModified"] = res.last_modified
                doc["fetchedAt"] = now
                age = max_age(headers, now)
                doc["reuseUntil"] = now + max(MIN_REFRESH_SECONDS, age if age is not None else DEFAULT_REFRESH_SECONDS)
                doc["lastError"] = error = None
            except fetch.FetchError as exc:
                error = "fetch failed: %s" % exc
                if exc.status is not None and 400 <= exc.status < 500:
                    doc["blockedUntil"] = now + BLOCKED_BACKOFF_SECONDS
                    error += " (needsHuman: api.weather.gov refused the request; stopped for an hour)"
                elif exc.retry_after:
                    doc["blockedUntil"] = now + exc.retry_after
                doc["lastError"] = error
            except ValueError as exc:
                doc["lastError"] = error = "bad response: %s" % exc
            self._write(name, doc)
        return doc.get("features") or [], doc.get("fetchedAt"), error

    def zone(self, url: str, allow_fetch: bool = True) -> Optional[dict]:
        """GeoJSON geometry of an affected zone (cached ZONE_MAX_AGE_SECONDS)."""
        safe = "".join(ch if ch.isalnum() else "_" for ch in url.split("/zones/")[-1])
        name = "zone-%s.json" % safe
        doc = self._read(name)
        now = self.clock()
        if allow_fetch and url.startswith(API + "/zones/") and now - doc.get("fetchedAt", 0) >= ZONE_MAX_AGE_SECONDS:
            try:
                res, _ = self.get(url, None)
                if res.status == 200:
                    doc = {"geometry": json.loads(res.body.decode("utf-8")).get("geometry"), "fetchedAt": now}
                    self._write(name, doc)
            except (fetch.FetchError, ValueError):
                pass
        return doc.get("geometry")


# ------------------------------------------------------------------ contract


def in_force(props: dict, t: float) -> bool:
    """Shown as active only while in force: an actual alert or update, not cancelled, not yet ended or expired."""
    if props.get("status") != "Actual" or props.get("messageType") == "Cancel":
        return False
    end = parse_time(props.get("ends")) or parse_time(props.get("expires"))
    start = parse_time(props.get("effective")) or parse_time(props.get("onset")) or parse_time(props.get("sent"))
    if end is not None and t >= end:
        return False
    if start is not None and t < start:
        return False
    return True


VERBATIM = ("event", "severity", "certainty", "urgency", "headline", "description", "instruction", "senderName",
            "areaDesc", "response", "category")


def snapshot(areas: List[dict], features: List[dict], t: float, fetched_at: Optional[float], error: Optional[str],
             zone_geometry: Callable[[str], Optional[dict]] = lambda url: None) -> dict:
    """worldengine.live.alerts/1 (docs/live-world/alerts.md) for one instant."""
    if fetched_at is None:
        state = "unavailable"
    elif t - fetched_at > FRESH_SECONDS:
        state = "stale"
    else:
        state = "fresh"
    out = []
    for f in features:
        p = f.get("properties") or {}
        if not in_force(p, t):
            continue
        rings = _rings(f.get("geometry"))
        placed = "polygon"
        if not rings:
            placed = "zones"
            for z in p.get("affectedZones") or []:
                rings += _rings(zone_geometry(z))
        hit = [a["id"] for a in areas if any(ring_touches_box(r, tuple(a["bbox"])) for r in rings)]
        if not hit:
            continue
        rec = {k: p.get(k) for k in VERBATIM}
        rec.update({
            "id": p.get("@id") or p.get("id") or f.get("id"),
            "link": p.get("@id") or f.get("id"),
            "areas": hit,
            "status": p.get("status"), "messageType": p.get("messageType"),
            "sent": parse_time(p.get("sent")), "effective": parse_time(p.get("effective")), "onset": parse_time(p.get("onset")),
            "expires": parse_time(p.get("expires")), "ends": parse_time(p.get("ends")),
            "geometry": f.get("geometry") if placed == "polygon" else None,
            "affectedZones": p.get("affectedZones") or [],
            "placedBy": placed,
            "basis": "observed", "official": True, "source": "nws", "label": LABEL,
        })
        out.append(rec)
    out.sort(key=lambda r: (r["sent"] or 0, r["id"] or ""))
    return {
        "schema": "worldengine.live.alerts/1", "layer": "alerts", "live": True, "basis": "observed", "official": True,
        "generatedAt": int(t), "feedTimestamp": int(fetched_at) if fetched_at else None, "state": state,
        "stale": state == "stale", "error": error, "label": LABEL, "areas": [a["id"] for a in areas],
        "alerts": out, "attribution": [ATTRIBUTION],
    }
