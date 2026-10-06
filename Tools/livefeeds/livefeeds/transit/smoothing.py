"""Smooth vehicle movement between observations, along route shapes.

Relay side (`Tracker`): each observation of a vehicle is snapped to its trip's shape (distance along it);
speed along the shape comes from the feed when it reports one (`observed`), else from the vehicle's last
two observations on the same shape (`inferred`). The result is a `motion` record sent with the vehicle.

Renderer side (`Smoother`, the reference the 5A port must match) applies docs/research/live-feeds.md 8.6
along the shape instead of in straight lines: draw each vehicle where it was `RENDER_DELAY_SECONDS` ago,
interpolating the distance along the shape between the two reports that bracket that time; past the newest
report, continue at the motion's speed for at most `MAX_EXTRAPOLATE_SECONDS`, then hold; blend any jump
caused by new data over `BLEND_SECONDS`; never reverse on screen by more than `BACKTRACK_TOLERANCE_M`.
Stale positions are never animated (live-feeds.md 8.7; docs/live-world/transit.md).
"""

from dataclasses import dataclass
from typing import Dict, Optional

from .shapes import MAX_OFFSET_M, ShapeTable

RENDER_DELAY_SECONDS = 45.0      # live-feeds.md 8.6 step 3
MAX_EXTRAPOLATE_SECONDS = 30.0   # live-feeds.md 8.6 step 4
POSITION_FRESH_SECONDS = 120.0   # live-feeds.md 8.6 step 8: older positions are frozen, never animated
SPEED_CAP_MPS = {"bus": 30.0, "rail": 40.0}
MIN_DT, MAX_DT = 5.0, 300.0
BLEND_SECONDS = 3.0
BACKTRACK_TOLERANCE_M = 15.0
HOLD_MAX_SECONDS = 10.0          # a hold longer than this gives way (the vehicle really is behind)
JUMP_M = 150.0                   # live-feeds.md 8.6 step 5: larger differences snap (fade out and in)


@dataclass
class _Seen:
    shape_id: str
    dist: float
    t: float
    speed: Optional[float] = None
    basis: Optional[str] = None


class Tracker:
    """Per-vehicle memory of the last observation (keyed by the salted id; dropped after 10 minutes)."""

    def __init__(self):
        self._seen: Dict[str, _Seen] = {}

    def annotate(self, vehicles, trips: Dict[str, Optional[str]], shapes: Optional[ShapeTable], now: float) -> None:
        """Adds `motion` (or None) to each vehicle record in place. `trips` maps record id -> raw trip id
        (kept only for this call; trip ids never go into records)."""
        seen: Dict[str, _Seen] = {}
        for v in vehicles:
            v["motion"] = None
            shape = shapes.for_trip(trips.get(v["id"])) if shapes else None
            if shape is None:
                continue
            prev = self._seen.get(v["id"])
            near = prev.dist if prev is not None and prev.shape_id == shape.id else None
            dist, off = shape.project(v["lat"], v["lon"], near)
            if off > MAX_OFFSET_M:
                continue
            speed, basis = None, None
            cap = SPEED_CAP_MPS.get(v["kind"], 30.0)
            same = prev is not None and prev.shape_id == shape.id
            if v.get("speedMps") is not None:
                speed, basis = min(v["speedMps"], cap), "observed"
            elif same and v["timestamp"] == prev.t:
                speed, basis = prev.speed, prev.basis  # the same report again: keep the earlier estimate
            elif same and MIN_DT <= v["timestamp"] - prev.t <= MAX_DT:
                s = (dist - prev.dist) / (v["timestamp"] - prev.t)
                if -0.5 <= s <= cap:
                    speed, basis = max(0.0, s), "inferred"
            if same and v["timestamp"] == prev.t:
                seen[v["id"]] = prev
            else:
                seen[v["id"]] = _Seen(shape.id, dist, v["timestamp"], speed, basis)
            v["motion"] = {"shapeId": shape.id, "distM": round(dist, 1), "offsetM": round(off, 1),
                           "t": v["timestamp"], "speedMps": None if speed is None else round(speed, 2),
                           "speedBasis": basis}
        for k, s in self._seen.items():
            if k not in seen and now - s.t < 600:
                seen[k] = s
        self._seen = seen


class Smoother:
    """Reference client model for one vehicle. Call `observe` with every vehicle record received (and the
    layer `state`), and `distance` at each frame; draw at Shape.point_at(distance). `serverNow` is the
    caller's clock aligned to the relay's `generatedAt` (live-feeds.md 8.6 step 1)."""

    def __init__(self, length: float, render_delay: float = RENDER_DELAY_SECONDS):
        self.length = length
        self.delay = render_delay
        self.reports = []          # up to two (t, distM) on the current shape, oldest first
        self.speed = 0.0
        self.shape_id: Optional[str] = None
        self.frozen_at: Optional[float] = None
        self._frozen = False
        self.stopped = False
        self._shown: Optional[float] = None
        self._blend_from: Optional[float] = None
        self._blend_t0 = 0.0
        self._hold_since: Optional[float] = None
        self.snapped = False       # True when the last update was too far to blend (renderer fades)

    @property
    def frozen(self) -> bool:
        return self._frozen

    def _curve(self, now: float) -> Optional[float]:
        if not self.reports:
            return None
        rt = now - self.delay
        (t0, d0) = self.reports[0]
        if rt <= t0:
            return d0
        if len(self.reports) == 2:
            (t1, d1) = self.reports[1]
            if rt <= t1:
                return d0 + (d1 - d0) * (rt - t0) / (t1 - t0)
            t_last, d_last = t1, d1
        else:
            t_last, d_last = t0, d0
        if self.stopped:
            return d_last
        return max(0.0, min(self.length, d_last + self.speed * min(rt - t_last, MAX_EXTRAPOLATE_SECONDS)))

    def observe(self, vehicle: dict, now: float, layer_state: str = "fresh") -> None:
        shown = self.distance(now)
        m = vehicle.get("motion")
        if layer_state != "fresh" or vehicle.get("positionState") == "stale" \
                or now - vehicle["timestamp"] > POSITION_FRESH_SECONDS or m is None:
            if not self._frozen:
                # Freeze where it ends up (live-feeds.md 8.7). None: never animated, draw the reported lat/lon.
                self._frozen, self.frozen_at = True, shown
            return
        self._frozen, self.frozen_at = False, None
        self.snapped = False
        if m["shapeId"] != self.shape_id:
            self.shape_id, self.reports, self._shown, shown = m["shapeId"], [], None, None
        if not self.reports or m["t"] > self.reports[-1][0]:
            self.reports = (self.reports + [(m["t"], m["distM"])])[-2:]
        self.speed = m["speedMps"] or 0.0
        self.stopped = vehicle.get("stopStatus") == "stopped"
        new = self._curve(now)
        if shown is None or new is None:
            self._blend_from = None
        elif abs(new - shown) > JUMP_M:
            self._blend_from, self.snapped, self._shown = None, True, None
        else:
            self._blend_from, self._blend_t0 = shown, now

    def distance(self, now: float) -> Optional[float]:
        if self._frozen:
            return self.frozen_at
        target = self._curve(now)
        if target is None:
            return None
        if self._blend_from is not None:
            k = (now - self._blend_t0) / BLEND_SECONDS
            if k >= 1:
                self._blend_from = None
            else:
                target = self._blend_from + (target - self._blend_from) * max(0.0, k)
        if self._shown is not None and target < self._shown - BACKTRACK_TOLERANCE_M:
            if self._hold_since is None:
                self._hold_since = now
            if now - self._hold_since < HOLD_MAX_SECONDS:
                return self._shown  # hold instead of visibly reversing
        self._hold_since = None
        self._shown = target
        return target
