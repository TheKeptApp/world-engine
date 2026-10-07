"""HTTP side of the relay (standard library http.server).

    GET /v1/vehicles?bbox=S,W,N,E            vehicles in the zoom-14 tiles covering the box (max 4 x 4)
    GET /v1/vehicles?tiles=14/x0/y0/x1/y1    the canonical form of the same request (shares cache entries)
    GET /v1/shapes?ids=A,B                   route shapes named by vehicles' motion.shapeId (max 50)
    GET /v1/status                           relay health: states, counts, ages, counters (no client data)

Every JSON response carries `schema` and the `attribution` block. Nothing about clients is logged
or kept: no addresses, no per-request log lines, only aggregate counters.
"""

import gzip
import hashlib
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import List, Optional
from urllib.parse import parse_qs, urlsplit

from . import rtd, tiles
from .relay import SCHEMA, Relay
from .transit.smoothing import POSITION_FRESH_SECONDS


def render_vehicle(v: dict, now: float) -> dict:
    """Public vehicle record: stored fields plus ageSeconds, in the documented order."""
    age = max(0, int(now - v["timestamp"]))
    return {
        "id": v["id"], "kind": v["kind"], "route": v["route"], "routeName": v["routeName"],
        "lat": v["lat"], "lon": v["lon"], "heading": v["heading"], "speedMps": v["speedMps"],
        "stopStatus": v["stopStatus"], "timestamp": v["timestamp"], "ageSeconds": age,
        "source": v["source"],
        "positionState": "fresh" if age <= POSITION_FRESH_SECONDS else "stale",
        "basis": "observed",
        "motion": v.get("motion") if age <= POSITION_FRESH_SECONDS else None,
    }


def vehicles_payload(relay: Relay, rect: tiles.Rect, now: float, covered: bool, state: str, snap) -> dict:
    vehicles: List[dict] = []
    if snap is not None and state != "unavailable" and covered:
        for xy in rect.tiles():
            for v in snap.tile_index.get(xy, ()):
                vehicles.append(render_vehicle(v, now))
        vehicles.sort(key=lambda r: r["id"])
    s, w, n, e = rect.bbox()
    return {
        "schema": SCHEMA,
        "live": True,
        "generatedAt": int(now),
        "feedTimestamp": snap.feed_timestamp if snap is not None else None,
        "state": state,
        "stale": state != "fresh",
        "pollIntervalSeconds": relay.cfg.client_poll_interval,
        "area": {"z": rect.z, "x0": rect.x0, "y0": rect.y0, "x1": rect.x1, "y1": rect.y1,
                 "bbox": [round(s, 6), round(w, 6), round(n, 6), round(e, 6)], "covered": covered},
        "vehicles": vehicles,
        "attribution": [relay.source.attribution],
    }


def etag_for(payload: dict, rect: tiles.Rect) -> str:
    """Weak validator for the data a client would hold: it changes when the snapshot, the area or
    the state changes, not every second (ageSeconds is aged by the client between responses)."""
    key = "%d|%s|%s|%s|%d|%s" % (SCHEMA, payload["feedTimestamp"], rect.key(), payload["state"],
                                 len(payload["vehicles"]), payload["area"]["covered"])
    return 'W/"%s"' % hashlib.sha1(key.encode("ascii")).hexdigest()[:16]


def _accepts_gzip(header: Optional[str]) -> bool:
    for part in (header or "").split(","):
        token, _, params = part.strip().partition(";")
        if token.strip().lower() in ("gzip", "x-gzip"):
            q = params.replace(" ", "").lower()
            return not (q.startswith("q=0") and q in ("q=0", "q=0.0", "q=0.00", "q=0.000"))
    return False


def _etag_matches(header: Optional[str], etag: str) -> bool:
    if not header:
        return False
    if header.strip() == "*":
        return True
    weak = lambda t: t.strip()[2:] if t.strip().startswith("W/") else t.strip()  # noqa: E731
    return any(weak(t) == weak(etag) for t in header.split(","))


class Handler(BaseHTTPRequestHandler):
    server_version = "WorldEngine-livefeeds/0.1"
    protocol_version = "HTTP/1.1"
    timeout = 30

    def log_message(self, format, *args):  # noqa: A002 - signature fixed by the base class
        pass  # privacy: no per-request logging (no addresses, no tiles); counters live in Relay

    @property
    def relay(self) -> Relay:
        return self.server.relay  # type: ignore[attr-defined]

    # -- plumbing ----------------------------------------------------------------------------
    def _send(self, status: int, payload: Optional[dict], send_body: bool, cache_control: str = "no-store",
              extra: Optional[dict] = None) -> None:
        self.relay.count_http(status)
        body = b""
        headers = {
            "Cache-Control": cache_control,
            "X-Content-Type-Options": "nosniff",
            "Access-Control-Allow-Origin": "*",
        }
        headers.update(extra or {})
        if payload is not None:
            body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
            headers["Content-Type"] = "application/json; charset=utf-8"
            headers["Vary"] = "Accept-Encoding"
            if len(body) >= 256 and _accepts_gzip(self.headers.get("Accept-Encoding")):
                body = gzip.compress(body, compresslevel=6, mtime=0)
                headers["Content-Encoding"] = "gzip"
        self.send_response(status)
        for k, v in headers.items():
            self.send_header(k, v)
        if status != 304:
            self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if send_body and status != 304 and self.command != "HEAD":
            self.wfile.write(body)

    def _error(self, status: int, code: str, message: str, send_body: bool = True) -> None:
        self._send(status, {"schema": SCHEMA, "error": {"code": code, "message": message},
                            "attribution": [self.relay.source.attribution]}, send_body)

    # -- verbs -------------------------------------------------------------------------------
    def do_GET(self):  # noqa: N802
        self._route(True)

    def do_HEAD(self):  # noqa: N802
        self._route(False)

    def do_OPTIONS(self):  # noqa: N802
        self._send(204, None, False, extra={"Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
                                            "Access-Control-Allow-Headers": "If-None-Match, Accept-Encoding",
                                            "Access-Control-Max-Age": "600"})

    def _method_not_allowed(self):
        self._error(405, "method-not-allowed", "read-only service: GET and HEAD only",)

    do_POST = do_PUT = do_DELETE = do_PATCH = _method_not_allowed  # type: ignore[assignment]

    def _route(self, send_body: bool) -> None:
        if len(self.path) > 512:
            return self._error(414, "uri-too-long", "request target too long", send_body)
        parts = urlsplit(self.path)
        if parts.path == "/v1/vehicles":
            return self._vehicles(parse_qs(parts.query), send_body)
        if parts.path == "/v1/shapes":
            return self._shapes(parse_qs(parts.query), send_body)
        if parts.path == "/v1/status":
            now = self.relay.clock()
            return self._send(200, {"schema": SCHEMA, "status": self.relay.status(now),
                                    "attribution": [self.relay.source.attribution]}, send_body)
        self._error(404, "not-found", "unknown path; try /v1/vehicles?bbox=S,W,N,E", send_body)

    def _vehicles(self, query: dict, send_body: bool) -> None:
        bbox, tile_q = query.get("bbox"), query.get("tiles")
        if (bbox is None) == (tile_q is None) or len(query.get("bbox", [])) > 1 or len(query.get("tiles", [])) > 1:
            return self._error(400, "bad-request", "give exactly one of bbox=S,W,N,E or tiles=14/x0/y0/x1/y1",
                               send_body)
        try:
            rect = tiles.parse_bbox(bbox[0]) if bbox else tiles.parse_tiles(tile_q[0])
        except tiles.AreaError as e:
            return self._error(400, e.code, e.message, send_body)

        relay = self.relay
        covered = any(tiles.bbox_intersects(list(a.bbox), rect.bbox()) for a in relay.areas)
        if covered:
            before = relay.poll_count()
            if relay.touch():                       # the poller was idle: give it a moment to fetch
                relay.wait_for_poll(before, relay.cfg.wake_wait)
        now = relay.clock()
        snap, state, _reason = relay.view(now)
        payload = vehicles_payload(relay, rect, now, covered, state, snap)
        etag = etag_for(payload, rect)
        extra = {"ETag": etag, "Content-Location": "/v1/vehicles?tiles=" + rect.key()}
        cache = "public, max-age=%d" % relay.cfg.max_age
        if _etag_matches(self.headers.get("If-None-Match"), etag):
            return self._send(304, None, send_body, cache, extra)
        self._send(200, payload, send_body, cache, extra)


    def _shapes(self, query: dict, send_body: bool) -> None:
        ids = [i for i in ",".join(query.get("ids", [])).split(",") if i]
        if not ids or len(ids) > 50:
            return self._error(400, "bad-request", "give ids=A,B,... (1 to 50 shape ids)", send_body)
        found, missing = [], []
        for sid in dict.fromkeys(ids):
            sh = self.relay.shape(sid)
            (found.append(sh.to_json()) if sh is not None else missing.append(sid))
        # Shapes change at most weekly: long cache.
        self._send(200, {"schema": SCHEMA, "shapes": found, "missing": missing, "basis": "observed",
                         "attribution": [self.relay.source.attribution]}, send_body, "public, max-age=86400")


class RelayServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def __init__(self, address, relay: Relay):
        super().__init__(address, Handler)
        self.relay = relay


def make_server(relay: Relay, host: str = "127.0.0.1", port: int = 8765) -> RelayServer:
    return RelayServer((host, port), relay)
