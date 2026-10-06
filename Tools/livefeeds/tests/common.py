"""Shared synthetic fixtures: a fake clock, a fake upstream, sample routes and a sample feed."""

import os
from typing import Optional

from livefeeds import rtd
from livefeeds.fetch import FetchError, FetchResult
from livefeeds.relay import Area, Config, Relay
from tests import pbenc

T0 = 1_790_000_000          # a synthetic "now" (POSIX seconds)
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AREAS_JSON = os.path.join(HERE, "areas.json")

# Synthetic coordinates inside the allowlisted box, in two different zoom-14 tiles.
LAT_A, LON_A = 39.7500, -104.9900      # bus 1 and bus 2 (same tile)
LAT_R, LON_R = 39.7530, -105.0150      # rail (the tile west of the buses)
LAT_FAR, LON_FAR = 39.9000, -105.1000  # a bus far away from the others


class Clock:
    def __init__(self, t: float = T0):
        self.t = float(t)

    def __call__(self) -> float:
        return self.t

    def advance(self, seconds: float) -> None:
        self.t += seconds


def sample_routes(fetched_at: float = T0) -> rtd.Routes:
    return rtd.Routes({"15": ("15", "bus"), "BOLT": ("BOLT", "bus"), "A": ("A", "rail"),
                       "FERRY": ("F", None)}, fetched_at)


def sample_feed(ts: int = T0, extra_vehicle_age: int = 0) -> bytes:
    vp = pbenc.vehicle_position
    ents = [
        pbenc.entity("BUS-1501", vp(trip_id="T-1", route_id="15", direction=0, vehicle_id="BUS-1501", label="1501",
                                    lat=LAT_A, lon=LON_A, bearing=90.0, speed=5.5, timestamp=ts - 10, status=2,
                                    extras=pbenc.f_varint(9, 1) + pbenc.f_double(4, 1234.5))),
        pbenc.entity("BUS-1502", vp(trip_id="T-2", route_id="15", direction=1, vehicle_id="BUS-1502", label="1502",
                                    lat=LAT_A + 0.0005, lon=LON_A + 0.0005, bearing=270.0, timestamp=ts - 5,
                                    status=1)),
        pbenc.entity("RAIL-9", vp(trip_id="T-3", route_id="A", direction=0, vehicle_id="RAIL-9", label="9",
                                  lat=LAT_R, lon=LON_R, bearing=45.0, timestamp=ts - 3, status=0)),
        pbenc.entity("BUS-FAR", vp(trip_id="T-4", route_id="BOLT", vehicle_id="BUS-FAR", lat=LAT_FAR, lon=LON_FAR,
                                   bearing=359.97, timestamp=ts + 20, status=2)),
        # dropped for stated reasons:
        pbenc.entity("NR-1", vp(vehicle_id="NR-1", lat=LAT_A, lon=LON_A, bearing=0.0, timestamp=ts)),       # no route
        pbenc.entity("UNK-1", vp(trip_id="T-5", route_id="ZZZ", vehicle_id="UNK-1", lat=LAT_A, lon=LON_A,
                                 timestamp=ts)),                                                              # unknown route
        pbenc.entity("FER-1", vp(trip_id="T-6", route_id="FERRY", vehicle_id="FER-1", lat=LAT_A, lon=LON_A,
                                 timestamp=ts)),                                                              # other mode
        pbenc.entity("OLD-1", vp(trip_id="T-7", route_id="15", vehicle_id="OLD-1", lat=LAT_A, lon=LON_A,
                                 timestamp=ts - 1000)),                                                       # too old
        pbenc.entity("ZERO-1", vp(trip_id="T-8", route_id="15", vehicle_id="ZERO-1", lat=0.0, lon=0.0,
                                  timestamp=ts)),                                                             # (0,0)
        pbenc.entity("NOPOS-1", vp(trip_id="T-9", route_id="15", vehicle_id="NOPOS-1", timestamp=ts)),       # no position
        pbenc.entity("DEL-1", vp(trip_id="T-10", route_id="15", vehicle_id="DEL-1", lat=LAT_A, lon=LON_A,
                                 timestamp=ts), deleted=True),                                                # deleted
        pbenc.entity("TU-1", trip_update=pbenc.f_str(1, "ignored")),                                          # not a vehicle
    ]
    return pbenc.encode_feed(ts, ents)


class FakeUpstream:
    """Stands in for the HTTP fetch: honours If-None-Match like a server with an ETag."""

    def __init__(self, body: Optional[bytes] = None):
        self.body = body
        self.version = 1
        self.error: Optional[FetchError] = None
        self.calls = []

    @property
    def etag(self) -> str:
        return '"v%d"' % self.version

    def publish(self, body: bytes) -> None:
        self.body = body
        self.version += 1

    def __call__(self, etag, last_modified):
        self.calls.append((etag, last_modified))
        if self.error is not None:
            raise self.error
        if etag is not None and etag == self.etag:
            return FetchResult(304, None, self.etag, last_modified, 0)
        return FetchResult(200, self.body, self.etag, "Mon, 01 Jan 2026 00:00:00 GMT", len(self.body or b""))


def make_relay(cache_dir: Optional[str] = None, upstream: Optional[FakeUpstream] = None,
               clock: Optional[Clock] = None, routes_fail: bool = False, **cfg) -> Relay:
    clock = clock or Clock()
    upstream = upstream or FakeUpstream(sample_feed(int(clock())))
    state = {"calls": 0}

    def routes_fetch():
        state["calls"] += 1
        if routes_fail:
            raise FetchError("routes down", 503)
        return sample_routes(clock()), 1234

    area = Area("test", "Test box", (39.40, -105.60, 40.30, -104.55), "America/Denver", 3)
    relay = Relay(Config(cache_dir=cache_dir, **cfg), [area], fetch=upstream, routes_fetch=routes_fetch, clock=clock)
    relay.routes_calls = state          # type: ignore[attr-defined]
    relay.upstream = upstream           # type: ignore[attr-defined]
    return relay
