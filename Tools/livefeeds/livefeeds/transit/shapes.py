"""GTFS route shapes: parse, simplify, project positions onto a shape, and walk along it.

Built from the static GTFS `trips.txt` (trip_id -> shape_id) and `shapes.txt`. Distances along a shape are
metres from its first point, measured on a local equirectangular approximation per segment (error well
under 0.1 percent at city scale). Shapes are simplified with Douglas-Peucker at 2 m before use, so the
relay and the renderer walk the same polyline (`/v1/shapes` serves exactly these points and distances).
"""

import csv
import io
import json
import math
import os
import tempfile
from typing import Dict, List, Optional, Tuple

R_EARTH = 6371008.8
SIMPLIFY_M = 2.0
MAX_OFFSET_M = 60.0   # a position farther than this from its trip's shape is not snapped (wrong shape or detour)

Point = Tuple[float, float]


def _xy(lat0: float, p: Point) -> Tuple[float, float]:
    k = math.pi / 180 * R_EARTH
    return p[1] * k * math.cos(math.radians(lat0)), p[0] * k


def seg_len(a: Point, b: Point) -> float:
    lat0 = (a[0] + b[0]) / 2
    ax, ay = _xy(lat0, a)
    bx, by = _xy(lat0, b)
    return math.hypot(bx - ax, by - ay)


def simplify(points: List[Point], tol_m: float = SIMPLIFY_M) -> List[Point]:
    if len(points) < 3:
        return list(points)
    lat0 = sum(p[0] for p in points) / len(points)
    xy = [_xy(lat0, p) for p in points]
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        i, j = stack.pop()
        (x1, y1), (x2, y2) = xy[i], xy[j]
        dx, dy = x2 - x1, y2 - y1
        L2 = dx * dx + dy * dy
        best, bi = -1.0, -1
        for k in range(i + 1, j):
            px, py = xy[k]
            if L2 == 0:
                d = math.hypot(px - x1, py - y1)
            else:
                t = max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / L2))
                d = math.hypot(px - (x1 + t * dx), py - (y1 + t * dy))
            if d > best:
                best, bi = d, k
        if best > tol_m:
            keep[bi] = True
            stack += [(i, bi), (bi, j)]
    return [p for p, k in zip(points, keep) if k]


class Shape:
    __slots__ = ("id", "points", "dist")

    def __init__(self, sid: str, points: List[Point]):
        self.id = sid
        self.points = points
        d = [0.0]
        for a, b in zip(points, points[1:]):
            d.append(d[-1] + seg_len(a, b))
        self.dist = d

    @property
    def length(self) -> float:
        return self.dist[-1]

    def project(self, lat: float, lon: float, near: Optional[float] = None) -> Tuple[float, float]:
        """(distance along, offset) in metres of the closest point. With `near`, prefers the candidate
        closest in distance-along among those within 15 m of the best offset (loops, out-and-back)."""
        cands = []
        for i, (a, b) in enumerate(zip(self.points, self.points[1:])):
            lat0 = (a[0] + b[0]) / 2
            ax, ay = _xy(lat0, a)
            bx, by = _xy(lat0, b)
            px, py = _xy(lat0, (lat, lon))
            dx, dy = bx - ax, by - ay
            L2 = dx * dx + dy * dy
            t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
            off = math.hypot(px - (ax + t * dx), py - (ay + t * dy))
            cands.append((off, self.dist[i] + t * (self.dist[i + 1] - self.dist[i])))
        best = min(c[0] for c in cands)
        if near is None:
            off, d = min(cands)
            return d, off
        close = [c for c in cands if c[0] <= best + 15.0]
        off, d = min(close, key=lambda c: (abs(c[1] - near), c[0]))
        return d, off

    def point_at(self, d: float) -> Tuple[float, float, float]:
        """(lat, lon, heading degrees from true north) at distance `d` (clamped to the shape)."""
        d = max(0.0, min(self.length, d))
        lo, hi = 0, len(self.dist) - 1
        while hi - lo > 1:
            mid = (lo + hi) // 2
            if self.dist[mid] <= d:
                lo = mid
            else:
                hi = mid
        a, b = self.points[lo], self.points[hi]
        span = self.dist[hi] - self.dist[lo]
        t = 0.0 if span == 0 else (d - self.dist[lo]) / span
        lat, lon = a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])
        lat0 = (a[0] + b[0]) / 2
        ax, ay = _xy(lat0, a)
        bx, by = _xy(lat0, b)
        hdg = math.degrees(math.atan2(bx - ax, by - ay)) % 360.0
        return lat, lon, hdg

    def to_json(self) -> dict:
        return {"id": self.id, "points": [[round(p[0], 6), round(p[1], 6)] for p in self.points],
                "distM": [round(x, 1) for x in self.dist], "lengthM": round(self.length, 1)}


class ShapeTable:
    def __init__(self, shapes: Dict[str, Shape], trips: Dict[str, str], fetched_at: float, source: str = "",
                 candidates: Optional[Dict[str, List[str]]] = None):
        self.shapes = shapes
        self.trips = trips
        self.fetched_at = fetched_at
        self.source = source
        # Feeds without GTFS trip ids (CTA): a key such as "route:Red" or "pid:6351" -> possible shape ids.
        self.candidates = candidates or {}

    def for_trip(self, trip_id: Optional[str]) -> Optional[Shape]:
        sid = self.trips.get(trip_id) if trip_id else None
        return self.shapes.get(sid) if sid else None

    def resolve(self, key: Optional[str], lat: float, lon: float, prefer: Optional[str] = None) -> Optional[Shape]:
        """Shape for a vehicle: by GTFS trip id when the key is one, else the nearest of the key's candidate
        shapes, keeping `prefer` (the shape it was on) while it stays within MAX_OFFSET_M, so a train does not
        hop between branches where they share track."""
        if not key:
            return None
        if "|" in key:                      # fallbacks in order, e.g. "pid:6351|route:1"
            for k in key.split("|"):
                if k in self.candidates or k in self.trips:
                    return self.resolve(k, lat, lon, prefer)
            return None
        sh = self.for_trip(key)
        if sh is not None:
            return sh
        cands = [self.shapes[c] for c in self.candidates.get(key, ()) if c in self.shapes]
        if not cands:
            return None
        if prefer is not None:
            for c in cands:
                if c.id == prefer and c.project(lat, lon)[1] <= MAX_OFFSET_M:
                    return c
        return min(cands, key=lambda c: (c.project(lat, lon)[1], c.id))

    @classmethod
    def from_gtfs(cls, trips_txt: str, shapes_txt: str, fetched_at: float, source: str = "") -> "ShapeTable":
        trips: Dict[str, str] = {}
        for row in csv.DictReader(io.StringIO(trips_txt.lstrip("﻿"))):
            tid, sid = (row.get("trip_id") or "").strip(), (row.get("shape_id") or "").strip()
            if tid and sid:
                trips[tid] = sid
        raw: Dict[str, List[Tuple[int, float, float]]] = {}
        for row in csv.DictReader(io.StringIO(shapes_txt.lstrip("﻿"))):
            try:
                sid = row["shape_id"].strip()
                raw.setdefault(sid, []).append((int(row["shape_pt_sequence"]), float(row["shape_pt_lat"]),
                                                float(row["shape_pt_lon"])))
            except (KeyError, ValueError):
                continue
        shapes = {}
        used = set(trips.values())
        for sid, pts in raw.items():
            if sid not in used:
                continue
            pts.sort()
            line = [(p[1], p[2]) for p in pts]
            dedup = [line[0]] + [b for a, b in zip(line, line[1:]) if b != a]
            if len(dedup) >= 2:
                shapes[sid] = Shape(sid, simplify(dedup))
        trips = {t: s for t, s in trips.items() if s in shapes}
        return cls(shapes, trips, fetched_at, source)

    def save(self, path: str) -> None:
        doc = {"schema": 1, "fetchedAt": self.fetched_at, "source": self.source, "trips": self.trips,
               "candidates": self.candidates,
               "shapes": {sid: [[p[0], p[1]] for p in s.points] for sid, s in self.shapes.items()}}
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, separators=(",", ":"))
        os.replace(tmp, path)

    @classmethod
    def load(cls, path: str) -> Optional["ShapeTable"]:
        try:
            with open(path, "r", encoding="utf-8") as fh:
                d = json.load(fh)
            if d.get("schema") != 1:
                return None
            shapes = {sid: Shape(sid, [tuple(p) for p in pts]) for sid, pts in d["shapes"].items()}
            return cls(shapes, dict(d["trips"]), float(d["fetchedAt"]), d.get("source", ""),
                       {k: list(v) for k, v in d.get("candidates", {}).items()})
        except (OSError, ValueError, KeyError, TypeError):
            return None
