"""Denver RTD: fetch, decode and normalise vehicle positions (rail and bus).

Feed: RTD's public GTFS Realtime VehiclePosition file (no key). Route types (rail or bus) come
from RTD's static GTFS routes.txt (route_type), read from the start of the static zip and cached
as a small derived table. RTD pages (read 2026-10-06):
  feeds    https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds
  licence  https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement
  static   https://www.rtd-denver.com/open-records/open-spatial-information/gtfs
"""

import csv
import io
import json
import os
import tempfile
import time
import zipfile
from collections import Counter
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple

from . import gtfsrt
from .fetch import FetchError, USER_AGENT, open_stream
from .salt import DailySalt
from .zipstream import StreamUnsupported, extract_member

SOURCE = "rtd"
VEHICLE_POSITION_URL = "https://open-data.rtd-denver.com/files/gtfs-rt/rtd/VehiclePosition.pb"
ROUTES_ZIP_URL = "https://www.rtd-denver.com/files/gtfs/google_transit.zip"
FEEDS_PAGE_URL = "https://www.rtd-denver.com/open-records/open-spatial-information/real-time-feeds"
LICENSE_URL = "https://www.rtd-denver.com/open-records/open-spatial-information/gtfs-realtime-license-agreement"

# RTD's licence requires no attribution wording and no specific credit. It does say RTD may require
# a notice "stating that it is an unofficial web site and is not endorsed by, sponsored by or
# affiliated with RTD and that any views expressed on the website are not those of RTD". So the
# credit below is neutral, followed by that non-endorsement statement. No RTD logo or mark.
CREDIT = "Live vehicle positions: Regional Transportation District (RTD), Denver, GTFS Realtime feed."
NOTICE = ("Unofficial: not endorsed by, sponsored by or affiliated with RTD. "
          "Any views expressed are not those of RTD.")
ATTRIBUTION = {
    "source": SOURCE,
    "text": CREDIT + " " + NOTICE,
    "url": FEEDS_PAGE_URL,
    "licenseUrl": LICENSE_URL,
}

STOP_STATUS = {gtfsrt.INCOMING_AT: "incoming", gtfsrt.STOPPED_AT: "stopped", gtfsrt.IN_TRANSIT_TO: "inTransit"}


# -- route table --------------------------------------------------------------------------------

def route_kind(route_type: int) -> Optional[str]:
    """GTFS route_type to "rail" | "bus" | None (ferry, cable car, air and anything else).

    Basic types (https://gtfs.org/schedule/reference/#routestxt): 0 tram or light rail, 1 metro,
    2 rail, 3 bus, 5 cable tram, 7 funicular, 11 trolleybus, 12 monorail. Extended (Google/HVT)
    ranges: 100-199 railway, 200-299 coach, 400-499 urban railway, 700-899 bus and trolleybus,
    900-999 tram.
    """
    if route_type in (0, 1, 2, 5, 7, 12) or 100 <= route_type < 200 or 400 <= route_type < 500 \
            or 900 <= route_type < 1000:
        return "rail"
    if route_type in (3, 11) or 200 <= route_type < 300 or 700 <= route_type < 900:
        return "bus"
    return None


class Routes:
    """route_id -> (short name, kind or None). Small: about 130 routes for RTD."""

    def __init__(self, table: Dict[str, Tuple[str, Optional[str]]], fetched_at: float,
                 source: str = ROUTES_ZIP_URL):
        self.table = table
        self.fetched_at = fetched_at
        self.source = source

    def __len__(self) -> int:
        return len(self.table)

    def get(self, route_id: str) -> Optional[Tuple[str, Optional[str]]]:
        return self.table.get(route_id)

    @classmethod
    def from_routes_txt(cls, text: str, fetched_at: float, source: str = ROUTES_ZIP_URL) -> "Routes":
        table: Dict[str, Tuple[str, Optional[str]]] = {}
        for row in csv.DictReader(io.StringIO(text.lstrip("﻿"))):
            rid = (row.get("route_id") or "").strip()
            try:
                rtype = int((row.get("route_type") or "").strip())
            except ValueError:
                continue
            if rid:
                table[rid] = ((row.get("route_short_name") or "").strip(), route_kind(rtype))
        return cls(table, fetched_at, source)

    def save(self, path: str) -> None:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump({"fetchedAt": self.fetched_at, "source": self.source,
                       "routes": {k: list(v) for k, v in self.table.items()}}, f, separators=(",", ":"))
        os.replace(tmp, path)

    @classmethod
    def load(cls, path: str) -> Optional["Routes"]:
        try:
            with open(path, "r", encoding="utf-8") as f:
                d = json.load(f)
            table = {k: (str(v[0]), v[1] if v[1] in ("rail", "bus") else None) for k, v in d["routes"].items()}
            return cls(table, float(d["fetchedAt"]), str(d.get("source", ROUTES_ZIP_URL)))
        except (OSError, ValueError, KeyError, TypeError, IndexError):
            return None


def _download_member_full(url: str, user_agent: str, member: str, cap: int = 64 * 1024 * 1024) -> Tuple[bytes, int]:
    """Fallback: download the whole zip (capped) to a temporary file and read one member."""
    downloaded = 0
    resp = open_stream(url, user_agent)
    try:
        with tempfile.TemporaryFile() as tmp:
            while True:
                chunk = resp.read(1 << 20)
                if not chunk:
                    break
                downloaded += len(chunk)
                tmp.write(chunk)
                if downloaded > cap:
                    raise FetchError("static GTFS zip larger than %d bytes" % cap)
            tmp.seek(0)
            try:
                return zipfile.ZipFile(tmp).read(member), downloaded
            except (zipfile.BadZipFile, KeyError) as e:
                raise FetchError("static GTFS zip unusable: %s" % e)
    finally:
        resp.close()


def fetch_routes(url: str = ROUTES_ZIP_URL, user_agent: str = USER_AGENT,
                 clock=time.time) -> Tuple[Routes, int]:
    """Download routes.txt from the static GTFS zip. Returns (Routes, bytes downloaded).

    Reads only the start of the stream (about 130 KB of a 10 MB file). If the zip cannot be walked
    forward-only, falls back to one full download (capped at 64 MB) read with zipfile.
    """
    downloaded = 0
    data: Optional[bytes] = None
    resp = open_stream(url, user_agent)
    try:
        def read(n: int) -> bytes:
            nonlocal downloaded
            chunk = resp.read(n)
            downloaded += len(chunk)
            return chunk
        try:
            data = extract_member(read, "routes.txt")
            if data is None:
                raise FetchError("routes.txt not found in the static GTFS zip")
        except StreamUnsupported:
            data = None
    finally:
        resp.close()
    if data is None:
        data, extra = _download_member_full(url, user_agent, "routes.txt")
        downloaded += extra
    return Routes.from_routes_txt(data.decode("utf-8", "replace"), clock(), url), downloaded


def fetch_shapes(url: str = ROUTES_ZIP_URL, user_agent: str = USER_AGENT, clock=time.time):
    """Download the whole static GTFS zip (about 10 MB, capped at 64 MB) once and build the shape table
    from trips.txt and shapes.txt. Returns (ShapeTable, bytes downloaded)."""
    from .transit.shapes import ShapeTable
    downloaded = 0
    resp = open_stream(url, user_agent)
    try:
        with tempfile.TemporaryFile() as tmp:
            while True:
                chunk = resp.read(1 << 20)
                if not chunk:
                    break
                downloaded += len(chunk)
                tmp.write(chunk)
                if downloaded > 64 * 1024 * 1024:
                    raise FetchError("static GTFS zip larger than 64 MB")
            tmp.seek(0)
            try:
                z = zipfile.ZipFile(tmp)
                trips, shapes = z.read("trips.txt"), z.read("shapes.txt")
            except (zipfile.BadZipFile, KeyError) as e:
                raise FetchError("static GTFS zip unusable: %s" % e)
    finally:
        resp.close()
    table = ShapeTable.from_gtfs(trips.decode("utf-8", "replace"), shapes.decode("utf-8", "replace"), clock(), url)
    return table, downloaded


# -- normalisation ------------------------------------------------------------------------------

@dataclass
class Normalised:
    vehicles: List[dict]
    feed_timestamp: int
    dropped: Dict[str, int]
    unknown_routes: Set[str] = field(default_factory=set)
    trips: Dict[str, str] = field(default_factory=dict)   # record id -> raw trip id; memory only, never served or saved


def _valid_position(lat: Optional[float], lon: Optional[float]) -> bool:
    if lat is None or lon is None:
        return False
    if not (-90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0):
        return False
    return not (lat == 0.0 and lon == 0.0)


def normalise(feed: gtfsrt.Feed, routes: Routes, salt: DailySalt, now: float,
              max_vehicle_age: float = 300.0) -> Normalised:
    """Turn decoded vehicle entities into relay vehicle records.

    A record has: id (salted), kind, route (route_id), routeName (short name or None), lat, lon,
    heading (degrees clockwise from true north, or None; RTD's placeholder 0.0 becomes None), speedMps (or None), stopStatus, timestamp
    (the vehicle's own position time, POSIX seconds, UTC), source. ageSeconds is added at serve time.
    Vehicles are dropped, and counted by reason, when they cannot be drawn truthfully: no or invalid
    position, no route (non-revenue vehicles carry no trip), a route unknown to routes.txt, a mode
    other than rail or bus, no id, or a position older than max_vehicle_age behind the feed time.
    """
    feed_ts = int(feed.timestamp) if feed.timestamp else int(now)
    dropped: Counter = Counter()
    unknown: Set[str] = set()
    out: List[dict] = []
    trips: Dict[str, str] = {}
    for v in feed.vehicles:
        if v.lat is None or v.lon is None:
            dropped["noPosition"] += 1
            continue
        if not _valid_position(v.lat, v.lon):
            dropped["badPosition"] += 1
            continue
        if not v.route_id:
            dropped["noRoute"] += 1
            continue
        raw_id = v.vehicle_id or v.entity_id
        if not raw_id:
            dropped["noId"] += 1
            continue
        route = routes.get(v.route_id)
        if route is None:
            dropped["unknownRoute"] += 1
            unknown.add(v.route_id)
            continue
        short, kind = route
        if kind is None:
            dropped["otherMode"] += 1
            continue
        ts = int(v.timestamp) if v.timestamp else feed_ts
        if feed_ts - ts > max_vehicle_age:
            dropped["tooOld"] += 1
            continue
        # RTD sends bearing 0.0 as a placeholder: measured 2026-10-06, exact 0.0 disagreed with the
        # direction of travel (median error about 90 degrees) while every other value agreed (about 2
        # degrees). So exactly 0.0 means "unknown" and becomes None.
        heading = None
        if v.bearing is not None and v.bearing != 0.0 and 0.0 <= v.bearing <= 360.0:
            heading = round(v.bearing % 360.0, 1)
            if heading >= 360.0:        # 359.96 rounds up to 360.0; keep the range [0, 360)
                heading = 0.0
        speed = None
        if v.speed is not None and 0.0 <= v.speed <= 70.0:
            speed = round(v.speed, 2)
        rid = salt.vehicle_id(SOURCE, raw_id, now)
        if v.trip_id:
            trips[rid] = v.trip_id
        out.append({
            "id": rid,
            "kind": kind,
            "route": v.route_id,
            "routeName": short or None,
            "lat": round(v.lat, 5),
            "lon": round(v.lon, 5),
            "heading": heading,
            "speedMps": speed,
            "stopStatus": STOP_STATUS.get(v.current_status) if v.current_status is not None else None,
            "timestamp": ts,
            "source": SOURCE,
        })
    out.sort(key=lambda r: r["id"])
    return Normalised(out, feed_ts, dict(dropped), unknown, trips)
