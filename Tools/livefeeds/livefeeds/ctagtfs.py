"""CTA static GTFS (rail and bus): route shapes for snapping live vehicles, and stops.

Source: https://www.transitchicago.com/downloads/sch_data/google_transit.zip (about 69 MB, published under the CTA
Developer License Agreement, which ships inside the zip; same terms and credit as the live feeds). Read weekly by the
relay, streamed to a temporary file and capped at 160 MB; stop_times.txt (about 370 MB unzipped) is never read.

CTA's live feeds carry no GTFS trip ids, so shapes are found by key (transit.shapes.ShapeTable.resolve):
  * buses: "pid:<pattern id>" from Bus Tracker. CTA's bus shape_id is a 3-digit service prefix followed by the
    Bus Tracker pattern id zero-padded to 5 digits (68106351 = pattern 6351, 68110811 = pattern 10811; checked
    against live data 2026-10-07: 751 of 768 buses snapped by pattern, 15 had a pattern
    missing from the static feed); several prefixes repeat one pattern, so the
    shape with the most trips stands for it. Fallback: the nearest of the route's shapes ("pid:6351|route:1").
  * trains: "route:<code>" (Train Tracker codes equal GTFS route_ids: Red, Blue, Brn, G, Org, P, Pink, Y); the
    nearest of the line's shapes is used and kept while the train stays on it.
"""

import csv
import io
import json
import os
import tempfile
import time
import zipfile
from collections import Counter
from typing import Dict, List, Optional, Tuple

from .fetch import FetchError, USER_AGENT, open_stream
from .transit.shapes import Shape, ShapeTable, simplify

GTFS_URL = "https://www.transitchicago.com/downloads/sch_data/google_transit.zip"
MAX_ZIP_BYTES = 160 * 1024 * 1024
RAIL_ROUTE_TYPE = "1"


def _rows(z: zipfile.ZipFile, name: str):
    with z.open(name) as fh:
        yield from csv.DictReader(io.TextIOWrapper(fh, encoding="utf-8-sig", newline=""))


def build(z: zipfile.ZipFile, fetched_at: float, source: str = GTFS_URL) -> Tuple[ShapeTable, "StopTable"]:
    rail = {r["route_id"].strip() for r in _rows(z, "routes.txt") if (r.get("route_type") or "").strip() == RAIL_ROUTE_TYPE}
    use: Counter = Counter()
    route_of: Dict[str, str] = {}
    for t in _rows(z, "trips.txt"):
        rid, sid = (t.get("route_id") or "").strip(), (t.get("shape_id") or "").strip()
        if rid and sid:
            use[sid] += 1
            route_of[sid] = rid
    # One shape per bus pattern (the most used); every distinct rail shape.
    by_pattern: Dict[str, str] = {}
    for sid, n in sorted(use.items(), key=lambda x: (-x[1], x[0])):
        if route_of[sid] in rail:
            continue
        pid = str(int(sid[3:])) if len(sid) == 8 and sid.isdigit() else sid
        by_pattern.setdefault(pid, sid)
    keep = {sid for sid in use if route_of[sid] in rail} | set(by_pattern.values())
    raw: Dict[str, List[Tuple[int, float, float]]] = {}
    for r in _rows(z, "shapes.txt"):
        sid = (r.get("shape_id") or "").strip()
        if sid not in keep:
            continue
        try:
            raw.setdefault(sid, []).append((int(r["shape_pt_sequence"]), float(r["shape_pt_lat"]), float(r["shape_pt_lon"])))
        except (KeyError, ValueError):
            continue
    shapes: Dict[str, Shape] = {}
    for sid, pts in raw.items():
        pts.sort()
        line = [(p[1], p[2]) for p in pts]
        dedup = [line[0]] + [b for a, b in zip(line, line[1:]) if b != a]
        if len(dedup) >= 2:
            shapes[sid] = Shape(sid, simplify(dedup))
    cands: Dict[str, List[str]] = {}
    for sid in sorted(shapes):
        cands.setdefault("route:" + route_of[sid], []).append(sid)
    for pid, sid in sorted(by_pattern.items()):
        if sid in shapes:
            cands["pid:" + pid] = [sid]
    stops = StopTable.from_rows(_rows(z, "stops.txt"), fetched_at, source)
    return ShapeTable(shapes, {}, fetched_at, source, cands), stops


def fetch(url: str = GTFS_URL, user_agent: str = USER_AGENT, clock=time.time) -> Tuple[ShapeTable, "StopTable", int]:
    downloaded = 0
    resp = open_stream(url, user_agent, timeout=120)
    try:
        with tempfile.TemporaryFile() as tmp:
            while True:
                chunk = resp.read(1 << 20)
                if not chunk:
                    break
                downloaded += len(chunk)
                if downloaded > MAX_ZIP_BYTES:
                    raise FetchError("CTA static GTFS zip larger than %d MB" % (MAX_ZIP_BYTES >> 20))
                tmp.write(chunk)
            tmp.seek(0)
            try:
                with zipfile.ZipFile(tmp) as z:
                    shapes, stops = build(z, clock(), url)
            except (zipfile.BadZipFile, KeyError) as e:
                raise FetchError("CTA static GTFS zip unusable: %s" % e)
    finally:
        resp.close()
    return shapes, stops, downloaded


class StopTable:
    """Rail stations (GTFS location_type 1) and bus stops (location_type 0 outside CTA's 30000-39999 rail
    platform range). Public stop data only: id, name, position, kind."""

    def __init__(self, stops: List[dict], fetched_at: float, source: str = ""):
        self.stops = stops
        self.fetched_at = fetched_at
        self.source = source

    @classmethod
    def from_rows(cls, rows, fetched_at: float, source: str = "") -> "StopTable":
        out = []
        for r in rows:
            try:
                sid, lat, lon = r["stop_id"].strip(), float(r["stop_lat"]), float(r["stop_lon"])
            except (KeyError, ValueError, AttributeError):
                continue
            lt = (r.get("location_type") or "0").strip() or "0"
            if lt == "1":
                kind = "rail"
            elif lt == "0" and not (sid.isdigit() and 30000 <= int(sid) < 40000):
                kind = "bus"
            else:
                continue
            out.append({"id": sid, "name": (r.get("stop_name") or "").strip(), "lat": round(lat, 6),
                        "lon": round(lon, 6), "kind": kind})
        out.sort(key=lambda s: (s["kind"], s["id"]))
        return cls(out, fetched_at, source)

    def within(self, south: float, west: float, north: float, east: float, limit: int = 500) -> Tuple[List[dict], bool]:
        hit = [s for s in self.stops if south <= s["lat"] <= north and west <= s["lon"] <= east]
        return hit[:limit], len(hit) > limit

    def save(self, path: str) -> None:
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump({"schema": 1, "fetchedAt": self.fetched_at, "source": self.source, "stops": self.stops},
                      fh, separators=(",", ":"))
        os.replace(tmp, path)

    @classmethod
    def load(cls, path: str) -> Optional["StopTable"]:
        try:
            with open(path, "r", encoding="utf-8") as fh:
                d = json.load(fh)
            return cls(list(d["stops"]), float(d["fetchedAt"]), d.get("source", "")) if d.get("schema") == 1 else None
        except (OSError, ValueError, KeyError, TypeError):
            return None
