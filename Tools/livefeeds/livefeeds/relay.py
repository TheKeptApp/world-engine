"""Relay core: poll RTD, keep the last good snapshot, decide fresh / stale / unavailable.

Design reference: docs/research/live-feeds.md section 4 (tiles 4.3, intervals 4.4, stale states 4.7,
retention 4.10) and the contract in section 8.
"""

import json
import os
import threading
import time
from collections import Counter
from dataclasses import dataclass
from typing import Callable, Dict, List, Optional, Tuple

from . import cta, ctabus, rtd, tiles
from .fetch import FetchError, FetchResult, USER_AGENT, http_get
from .gtfsrt import DecodeError, decode_feed
from .salt import DailySalt
from .transit.shapes import ShapeTable
from .transit.smoothing import Tracker

SCHEMA = 1
MIN_POLL_INTERVAL = 30.0    # RTD is polled at most once every 30 s (owner's rule; the file refreshes about that often)
HARD_ERRORS = (401, 403, 404, 410)   # revoked or moved: do not retry hot (live-feeds.md 4.7)


@dataclass
class Config:
    feed_url: str = rtd.VEHICLE_POSITION_URL
    routes_url: str = rtd.ROUTES_ZIP_URL
    user_agent: str = USER_AGENT
    poll_interval: float = 30.0          # upstream poll, seconds; never below 30
    client_poll_interval: int = 15       # hint to phones (live-feeds.md 4.6, A4)
    max_age: int = 10                    # Cache-Control max-age on vehicle responses (4.6)
    fresh_pulls: float = 2.0             # fresh while the last good pull is at most this many poll intervals old (4.7)
    feed_fresh_age: float = 120.0        # ... and the feed's own timestamp is at most this old (RTD: "accurate within 2 minutes")
    unavailable_after: float = 300.0     # older than this (pull age or feed age): unavailable (4.7)
    max_vehicle_age: float = 300.0       # drop positions older than this behind the feed time
    idle_seconds: float = 120.0          # stop polling after this long without a request; 0 = always poll (4.3)
    wake_wait: float = 3.0               # a request that wakes an idle poller waits up to this long for data
    routes_max_age: float = 7 * 86400.0  # re-read static routes.txt after a week ...
    routes_refresh_min: float = 6 * 3600.0   # ... or after 6 h when the feed shows a route the table lacks
    routes_retry: float = 600.0          # never retry the static download more often than this
    shapes_max_age: float = 7 * 86400.0  # route shapes (full static zip, about 10 MB) are re-read weekly
    shapes_retry: float = 3600.0
    timeout: float = 20.0
    cache_dir: Optional[str] = None

    def __post_init__(self) -> None:
        if self.poll_interval < MIN_POLL_INTERVAL:
            raise ValueError("poll interval must be at least %d s" % MIN_POLL_INTERVAL)


class RtdSource:
    """Denver RTD GTFS Realtime: needs the static routes table; shapes optional."""
    name = rtd.SOURCE
    attribution = rtd.ATTRIBUTION
    needs_routes = True
    snapshot_file = "snapshot.json"

    @staticmethod
    def normalise(body: bytes, routes, salt, now: float, max_age: float) -> rtd.Normalised:
        return rtd.normalise(decode_feed(body), routes, salt, now, max_age)


class CtaSource:
    """CTA Train Tracker ('L' trains): JSON, no routes table; shapes from CTA static GTFS (ctagtfs)."""
    name = cta.SOURCE
    attribution = cta.ATTRIBUTION
    needs_routes = False
    snapshot_file = "snapshot-cta.json"

    @staticmethod
    def normalise(body: bytes, routes, salt, now: float, max_age: float) -> rtd.Normalised:
        return cta.normalise(body, salt, now, max_age)


class CtaBusSource:
    """CTA Bus Tracker: JSON, route names come with the combined body; shapes from CTA static GTFS (ctagtfs)."""
    name = ctabus.SOURCE
    attribution = ctabus.ATTRIBUTION
    needs_routes = False
    snapshot_file = "snapshot-ctabus.json"

    @staticmethod
    def normalise(body: bytes, routes, salt, now: float, max_age: float) -> rtd.Normalised:
        return ctabus.normalise(body, salt, now, max_age)


SOURCES = {"rtd": RtdSource, "cta": CtaSource, "ctabus": CtaBusSource}


@dataclass(frozen=True)
class Area:
    id: str
    name: str
    bbox: Tuple[float, float, float, float]   # south, west, north, east
    timezone: str
    day_start_hour: int
    feeds: Tuple[str, ...] = ("rtd",)


def load_areas(path: str) -> List[Area]:
    """Areas are data (areas.json), not code: the allowlist of places that may use the feed."""
    with open(path, "r", encoding="utf-8") as f:
        doc = json.load(f)
    out = []
    for a in doc["areas"]:
        s, w, n, e = (float(v) for v in a["bbox"])
        out.append(Area(a["id"], a.get("name", a["id"]), (s, w, n, e),
                        a.get("timezone", "UTC"), int(a.get("serviceDayStartHour", 3)),
                        tuple(a.get("feeds", ["rtd"]))))
    if not out:
        raise ValueError("areas.json lists no areas")
    return out


@dataclass(frozen=True)
class Snapshot:
    seq: int
    feed_timestamp: int
    received_at: float                       # when this payload was first fetched
    vehicles: tuple                          # normalised vehicle dicts (no ageSeconds), sorted by id
    tile_index: Dict[Tuple[int, int], tuple]
    counts: Dict[str, int]
    dropped: Dict[str, int]
    wire_bytes: int


def build_snapshot(seq: int, norm: rtd.Normalised, received_at: float, wire_bytes: int) -> Snapshot:
    index: Dict[Tuple[int, int], list] = {}
    counts: Counter = Counter()
    for v in norm.vehicles:
        index.setdefault(tiles.tile_xy(v["lat"], v["lon"]), []).append(v)
        counts[v["kind"]] += 1
    return Snapshot(seq, norm.feed_timestamp, received_at, tuple(norm.vehicles),
                    {k: tuple(vs) for k, vs in index.items()}, dict(counts), dict(norm.dropped), wire_bytes)


class Relay:
    def __init__(self, cfg: Config, areas: List[Area],
                 fetch: Optional[Callable[[Optional[str], Optional[str]], FetchResult]] = None,
                 routes_fetch: Optional[Callable[[], Tuple[rtd.Routes, int]]] = None,
                 shapes_fetch: Optional[Callable[[], Tuple[ShapeTable, int]]] = None,
                 clock: Callable[[], float] = time.time,
                 log: Optional[Callable[[str], None]] = None,
                 source=RtdSource):
        self.cfg = cfg
        self.source = source
        self.log = log or (lambda message: None)
        self.areas = areas
        self.clock = clock
        if fetch is None and source is CtaSource:
            fetch = cta.fetcher(cfg.user_agent, cfg.timeout)
        if fetch is None and source is CtaBusSource:
            fetch = ctabus.fetcher(cfg.user_agent, cfg.timeout, clock=clock)
        self._fetch = fetch or (lambda etag, lm: http_get(cfg.feed_url, cfg.user_agent, etag, lm, cfg.timeout))
        self._routes_fetch = routes_fetch or (lambda: rtd.fetch_routes(cfg.routes_url, cfg.user_agent, clock))
        # Shapes (for smoothing) are optional: without a fetcher vehicles are served unsmoothed (motion null).
        self._shapes_fetch = shapes_fetch
        self._shapes: Optional[ShapeTable] = None
        self._shapes_tried_at: Optional[float] = None
        self.stops = None                    # ctagtfs.StopTable for feeds that publish stops (CTA)
        self.tracker = Tracker()
        # One feed, one salt: the service day follows the first area's time zone (prototype: one area).
        self.salt = DailySalt(cfg.cache_dir, areas[0].timezone, areas[0].day_start_hour)

        self._lock = threading.RLock()
        self._cond = threading.Condition(self._lock)
        self._snap: Optional[Snapshot] = None
        self._pulled_at: Optional[float] = None
        self._etag: Optional[str] = None
        self._last_modified: Optional[str] = None
        self._seq = 0
        self._errors = 0
        self._next_poll_at = 0.0
        self._poll_done = 0
        self._last_request: Optional[float] = None
        self._routes: Optional[rtd.Routes] = None
        self._routes_tried_at: Optional[float] = None
        self._unknown_routes_seen = False
        self._routes_error = ""
        self.last_error: Optional[str] = None
        self.last_outcome: Optional[str] = None
        self.started_at = clock()
        self.stats: Counter = Counter()        # aggregates only: no client data is kept anywhere
        self.http_codes: Counter = Counter()
        self._thread: Optional[threading.Thread] = None
        self._stop = threading.Event()
        self._wake = threading.Event()
        self._load_routes_cache()
        self._load_snapshot_cache()
        p = self._path("shapes.json")
        if p and shapes_fetch is not None:
            self._shapes = ShapeTable.load(p)
        sp = self._path("stops.json")
        if sp and shapes_fetch is not None and os.path.exists(sp):
            from .ctagtfs import StopTable
            self.stops = StopTable.load(sp)

    # -- disk cache --------------------------------------------------------------------------
    def _path(self, name: str) -> Optional[str]:
        return os.path.join(self.cfg.cache_dir, name) if self.cfg.cache_dir else None

    def _load_routes_cache(self) -> None:
        p = self._path("routes.json")
        if p:
            self._routes = rtd.Routes.load(p)

    def _load_snapshot_cache(self) -> None:
        """Restore the last good snapshot after a restart, only if it is still younger than the cutoff."""
        p = self._path(self.source.snapshot_file)
        if not p:
            return
        try:
            with open(p, "r", encoding="utf-8") as f:
                d = json.load(f)
            now = self.clock()
            pulled = float(d["pulledAt"])
            if d.get("schema") != SCHEMA or now - pulled > self.cfg.unavailable_after or pulled > now + 60:
                return
            vehicles = [dict(v) for v in d["vehicles"]]
            for v in vehicles:
                for key in ("id", "kind", "route", "lat", "lon", "timestamp", "source"):
                    v[key]
            norm = rtd.Normalised(vehicles, int(d["feedTimestamp"]), dict(d.get("dropped", {})))
            self._snap = build_snapshot(0, norm, float(d.get("receivedAt", pulled)), int(d.get("wireBytes", 0)))
            self._pulled_at = pulled
        except (OSError, ValueError, KeyError, TypeError):
            self._snap = None
            self._pulled_at = None

    def _save_snapshot(self, snap: Snapshot) -> None:
        p = self._path(self.source.snapshot_file)
        if not p:
            return
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            tmp = p + ".tmp"
            fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump({"schema": SCHEMA, "feedTimestamp": snap.feed_timestamp,
                           "receivedAt": snap.received_at, "pulledAt": self._pulled_at,
                           "wireBytes": snap.wire_bytes, "dropped": snap.dropped,
                           "vehicles": list(snap.vehicles)}, f, separators=(",", ":"))
            os.replace(tmp, p)
        except OSError:
            pass  # the in-memory snapshot is unaffected

    # -- static routes -----------------------------------------------------------------------
    def _ensure_routes(self, now: float) -> bool:
        r = self._routes
        due = (r is None or now - r.fetched_at > self.cfg.routes_max_age
               or (self._unknown_routes_seen and now - r.fetched_at > self.cfg.routes_refresh_min))
        if not due:
            return True
        if self._routes_tried_at is not None and now - self._routes_tried_at < self.cfg.routes_retry:
            return r is not None
        self._routes_tried_at = now
        try:
            new, nbytes = self._routes_fetch()
        except FetchError as e:
            self.stats["routesErrors"] += 1
            self._routes_error = str(e)
            self.last_error = "routes: %s" % e
            return r is not None
        self.stats["routesBytes"] += nbytes
        self.stats["routesFetches"] += 1
        self._routes = new
        self._unknown_routes_seen = False
        p = self._path("routes.json")
        if p:
            try:
                new.save(p)
            except OSError:
                pass
        return True

    def shape(self, shape_id: str):
        s = self._shapes
        return s.shapes.get(shape_id) if s else None

    def _ensure_shapes(self, now: float) -> None:
        if self._shapes_fetch is None:
            return
        s = self._shapes
        if s is not None and now - s.fetched_at <= self.cfg.shapes_max_age:
            return
        if self._shapes_tried_at is not None and now - self._shapes_tried_at < self.cfg.shapes_retry:
            return
        self._shapes_tried_at = now
        try:
            new, nbytes = self._shapes_fetch()
        except FetchError as e:
            self.stats["shapesErrors"] += 1
            self.log("shapes: %s (vehicles stay unsmoothed)" % e)
            return
        self.stats["shapesBytes"] += nbytes
        self.stats["shapesFetches"] += 1
        self._shapes = new
        if getattr(new, "stops", None) is not None:
            self.stops = new.stops
            sp = self._path("stops.json")
            if sp:
                new.stops.save(sp)
        p = self._path("shapes.json")
        if p:
            try:
                new.save(p)
            except OSError:
                pass

    # -- polling -----------------------------------------------------------------------------
    def _jitter(self, base: float) -> float:
        """Deterministic, positive-only spread (up to +10 percent) so the interval is never below the floor."""
        return base * 0.10 * (((self.stats["polls"] * 2654435761) % 1000) / 1000.0)

    def _finish(self, outcome: str, delay: float) -> str:
        with self._cond:
            self.last_outcome = outcome
            self._next_poll_at = self.clock() + delay + self._jitter(delay)
            self._poll_done += 1
            self._cond.notify_all()
        return outcome

    def _fail(self, message: str, status: Optional[int], retry_after: Optional[float]) -> str:
        self._errors += 1
        self.stats["errors"] += 1
        self.last_error = message
        if status in HARD_ERRORS:
            delay = 900.0
        else:
            delay = min(300.0, self.cfg.poll_interval * (2 ** self._errors))
        if retry_after is not None:
            delay = max(delay, min(retry_after, 900.0))
        self.log("poll %d: error: %s; retry in %ds" % (self.stats["polls"], message, delay))
        return self._finish("error", delay)

    def poll_once(self) -> str:
        """One upstream request. Returns "updated", "unchanged" or "error". Never raises."""
        now = self.clock()
        self.stats["polls"] += 1
        if self.source.needs_routes and not self._ensure_routes(now):
            return self._fail("routes table unavailable (%s)" % self._routes_error, None, None)
        try:
            res = self._fetch(self._etag, self._last_modified)
        except FetchError as e:
            return self._fail(str(e), e.status, e.retry_after)
        now = self.clock()
        self.stats["bytes"] += res.wire_bytes
        if res.status == 304:
            with self._lock:
                self._pulled_at = now
            self._errors = 0
            self.stats["http304"] += 1
            self.stats["unchanged"] += 1
            self.log("poll %d: HTTP 304 not modified" % self.stats["polls"])
            return self._finish("unchanged", self.cfg.poll_interval)
        try:
            norm = self.source.normalise(res.body or b"", self._routes, self.salt, now, self.cfg.max_vehicle_age)
        except FetchError as e:              # an error reported inside a 200 body (CTA errCd)
            return self._fail(str(e), e.status, None)
        except (DecodeError, ValueError, UnicodeDecodeError) as e:
            return self._fail("decode error: %s" % e, None, None)
        self._ensure_shapes(now)
        self.tracker.annotate(norm.vehicles, norm.trips, self._shapes, now)
        norm.trips = {}
        if norm.unknown_routes:
            self._unknown_routes_seen = True
        self._etag, self._last_modified = res.etag, res.last_modified
        self._errors = 0
        with self._cond:
            self._pulled_at = now
            old = self._snap
            if old is not None and norm.feed_timestamp <= old.feed_timestamp:
                outcome = "unchanged"          # same or older file (CDN lag): keep what we have
            else:
                self._seq += 1
                self._snap = build_snapshot(self._seq, norm, now, res.wire_bytes)
                outcome = "updated"
                self._save_snapshot(self._snap)
        self.stats["updates" if outcome == "updated" else "unchanged"] += 1
        snap = self._snap
        self.log("poll %d: %s HTTP %d %s, %d bytes, feed age %ds, vehicles %d (rail %d, bus %d), dropped %s" % (
            self.stats["polls"], self.source.name, res.status, outcome, res.wire_bytes, now - norm.feed_timestamp,
            len(norm.vehicles), snap.counts.get("rail", 0) if snap else 0,
            snap.counts.get("bus", 0) if snap else 0, norm.dropped))
        return self._finish(outcome, self.cfg.poll_interval)

    # -- background thread -------------------------------------------------------------------
    def _idle(self, now: float) -> bool:
        if self.cfg.idle_seconds <= 0 or self._snap is None:
            return False
        return self._last_request is None or now - self._last_request > self.cfg.idle_seconds

    def touch(self) -> bool:
        """Record that a client asked for covered data. Returns True if this resumed an idle poller."""
        now = self.clock()
        with self._lock:
            resumed = self._idle(now) and self._thread is not None
            self._last_request = now
        if resumed:
            self._wake.set()
        return resumed

    def poll_count(self) -> int:
        with self._lock:
            return self._poll_done

    def count_http(self, status: int) -> None:
        with self._lock:
            self.http_codes[status] += 1

    def wait_for_poll(self, since: int, timeout: float) -> None:
        deadline = time.monotonic() + timeout
        with self._cond:
            while self._poll_done <= since:
                left = deadline - time.monotonic()
                if left <= 0:
                    return
                self._cond.wait(left)

    def _loop(self) -> None:
        while not self._stop.is_set():
            self._wake.clear()                  # clear first, so a touch() after the checks below is not lost
            now = self.clock()
            if now >= self._next_poll_at and not self._idle(now):
                try:
                    self.poll_once()
                except Exception as e:      # a bug must not kill the poller
                    self._fail("internal error: %r" % (e,), None, None)
                continue
            if self._stop.is_set():
                break
            wait = 5.0 if self._idle(now) else max(0.05, min(5.0, self._next_poll_at - now))
            self._wake.wait(wait)

    def start(self) -> None:
        if self._thread is not None:
            return
        self._last_request = self.clock()   # starting the server counts as activity: fetch once now
        self._thread = threading.Thread(target=self._loop, name="%s-poller" % self.source.name, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        self._wake.set()
        if self._thread is not None:
            self._thread.join(timeout=5)
            self._thread = None

    # -- views -------------------------------------------------------------------------------
    def view(self, now: float) -> Tuple[Optional[Snapshot], str, str]:
        """(snapshot, state, reason). state: fresh | stale | unavailable (live-feeds.md 4.7)."""
        with self._lock:
            snap, pulled = self._snap, self._pulled_at
        if snap is None or pulled is None:
            return None, "unavailable", "no-data"
        pull_age = now - pulled
        feed_age = now - snap.feed_timestamp
        cut = self.cfg.unavailable_after
        if pull_age > cut:
            return snap, "unavailable", "relay-pull-too-old"
        if feed_age > cut:
            return snap, "unavailable", "feed-too-old"
        if pull_age > self.cfg.fresh_pulls * self.cfg.poll_interval:
            return snap, "stale", "relay-pull-late"
        if feed_age > self.cfg.feed_fresh_age:
            return snap, "stale", "feed-delayed"
        return snap, "fresh", "ok"

    def status(self, now: float) -> dict:
        snap, state, reason = self.view(now)
        with self._lock:
            pulled = self._pulled_at
            out = {
                "state": state,
                "reason": reason,
                "feedTimestamp": snap.feed_timestamp if snap else None,
                "feedAgeSeconds": round(now - snap.feed_timestamp, 1) if snap else None,
                "lastGoodPullAgeSeconds": round(now - pulled, 1) if pulled is not None else None,
                "vehicleCounts": dict(snap.counts) if snap else {},
                "droppedByReason": dict(snap.dropped) if snap else {},
                "lastPoll": self.last_outcome,
                "lastError": self.last_error,
                "consecutiveErrors": self._errors,
                "nextPollInSeconds": max(0.0, round(self._next_poll_at - now, 1)),
                "pollIntervalSeconds": self.cfg.poll_interval,
                "shapes": {"count": len(self._shapes.shapes) if self._shapes else 0,
                           "ageSeconds": round(now - self._shapes.fetched_at) if self._shapes else None},
                "routes": {"count": len(self._routes) if self._routes else 0,
                           "ageSeconds": round(now - self._routes.fetched_at) if self._routes else None},
                "counters": dict(self.stats),
                "httpResponses": {str(k): v for k, v in sorted(self.http_codes.items())},
                "uptimeSeconds": round(now - self.started_at),
            }
        return out
