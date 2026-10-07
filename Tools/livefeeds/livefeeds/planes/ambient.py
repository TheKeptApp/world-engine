"""Ambient (simulated) aircraft on real approach and departure corridors.

Implements docs/research/ambient-planes.md: straight-in arrivals on the extended runway centreline (3 deg
glide path), optional straight-out departures, slots of 150 s per runway and stream, occupancy from a
time-of-day curve, every draw from `StableRandom(dayNumber, slotInDay, salt)` in a fixed order. Position is
a closed-form function of time: no state, no network, identical on every device for the same area data,
time and flow. Nothing here is a real flight; every record is `basis: "simulated"` and `live: false`.
"""

import datetime
import json
import math
import os
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple
from zoneinfo import ZoneInfo

from .stablerandom import StableRandom

KT = 1852.0 / 3600.0   # m/s per knot
NM = 1852.0
R_EARTH = 6371008.8
LABEL = "Illustrative air traffic — not live"
ATTRIBUTION = {"source": "ambient", "text": "Illustrative air traffic, not live. Runway geometry © OpenStreetMap contributors.",
               "url": "https://www.openstreetmap.org/copyright", "live": False, "required": True}
HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AREA_DIR = os.path.join(HERE, "data", "ambient-planes")


def load_area(name_or_path: str) -> dict:
    path = name_or_path if os.path.sep in name_or_path or name_or_path.endswith(".json") \
        else os.path.join(AREA_DIR, name_or_path.lower() + ".json")
    with open(path, "r", encoding="utf-8") as fh:
        doc = json.load(fh)
    if doc.get("schema") != "worldengine.ambient-planes-area/1":
        raise ValueError("unsupported ambient-planes area schema")
    return doc


def destination(lat: float, lon: float, bearing_deg: float, dist_m: float) -> Tuple[float, float]:
    """Point at `dist_m` along the great circle from (lat, lon) with initial bearing (sphere)."""
    p1, l1, th, d = math.radians(lat), math.radians(lon), math.radians(bearing_deg), dist_m / R_EARTH
    p2 = math.asin(math.sin(p1) * math.cos(d) + math.cos(p1) * math.sin(d) * math.cos(th))
    l2 = l1 + math.atan2(math.sin(th) * math.sin(d) * math.cos(p1), math.cos(d) - math.sin(p1) * math.sin(p2))
    return math.degrees(p2), (math.degrees(l2) + 540.0) % 360.0 - 180.0


def multiplier(table: List[float], local_hours: float) -> float:
    """m(h): linear interpolation between hour centres (h + 0.5), wrapping at midnight."""
    x = (local_hours - 0.5) % 24.0
    i = int(math.floor(x))
    f = x - i
    return table[i] * (1 - f) + table[(i + 1) % 24] * f


def choose_flow(area: dict, wind_from_deg: Optional[float], wind_mps: Optional[float]) -> str:
    """ambient-planes.md section 3: prefer the default flow unless the other is clearly better into the wind."""
    default = area["defaultFlow"]
    m = area["model"]
    if wind_from_deg is None or wind_mps is None:
        return default
    v = wind_mps / KT
    if v < m["windMinKt"]:
        return default

    def head(flow):
        return v * math.cos(math.radians(wind_from_deg - area["flows"][flow]["landingHeadingTrueDeg"]))
    best = default
    for f in area["flows"]:
        if f != default and head(f) - head(best) >= m["windSwitchMarginKt"]:
            best = f
    return best


@dataclass
class Slot:
    runway: dict
    stream: str          # "arr" | "dep"
    day: int
    index: int
    t: float             # threshold time (arrivals) or brake release (departures), POSIX seconds
    heavy: bool
    v_app: float         # m/s (arrivals)
    hull: int
    roll_m: float        # departures


class Airport:
    def __init__(self, area: dict):
        self.area = area
        self.m = area["model"]
        self.tz = ZoneInfo(area["timeZone"])
        self.runways = {r["ref"]: r for r in area["runways"]}
        self.corridor = self.m["corridorNm"] * NM
        self.tan_glide = math.tan(math.radians(self.m["glideDeg"]))

    # -- time ----------------------------------------------------------------------------------
    def local_midnight(self, day: int) -> float:
        d = datetime.date(1970, 1, 1) + datetime.timedelta(days=day)
        return datetime.datetime(d.year, d.month, d.day, tzinfo=self.tz).timestamp()

    def local_day(self, t: float) -> int:
        return (datetime.datetime.fromtimestamp(t, self.tz).date() - datetime.date(1970, 1, 1)).days

    def local_hours(self, t: float) -> float:
        lt = datetime.datetime.fromtimestamp(t, self.tz)
        return lt.hour + lt.minute / 60.0 + lt.second / 3600.0

    # -- slots ---------------------------------------------------------------------------------
    def slot(self, runway_ref: str, stream: str, day: int, index: int) -> Optional[Slot]:
        m = self.m
        delta, jitter = m["slotSeconds"], m["jitterSeconds"]
        start = self.local_midnight(day) + index * delta
        centre = start + delta / 2
        rng = StableRandom(day, index, salt="ambient-planes/%s/%s/%s" % (self.area["airport"], runway_ref, stream))
        u = [rng.unit() for _ in range(6)]  # fixed draw order: occupied, jitter, class, speed, hull, roll
        h = self.local_hours(centre)
        if stream == "arr":
            p = m["arrivalPeak"] * multiplier(m["hourlyMultiplier"], h)
        else:
            q0, q1 = m["departureQuietHours"]
            quiet = h >= q0 or h < q1
            p = 0.0 if quiet else m["departurePeak"] * multiplier(m["hourlyMultiplier"], h)
        if u[0] >= p:
            return None
        t = centre + (u[1] - 0.5) * 2 * jitter  # spec: (u2 - 0.5) * (delta - 100 s) = +-25 s
        heavy = u[2] >= m["mediumShare"]
        lo, hi = m["approachKt"]["heavy" if heavy else "medium"]
        rw = self.runways[runway_ref]
        dep = m["departure"]
        roll = min(dep["rollM"][0] + (dep["rollM"][1] - dep["rollM"][0]) * u[5], rw["lengthM"] - dep["rollMarginM"])
        return Slot(rw, stream, day, index, t, heavy, (lo + (hi - lo) * u[3]) * KT,
                    int(u[4] * m["hullVariants"]), roll)

    def flow_at(self, t: float, wind=None) -> str:
        """`wind` is None, a (fromDeg, mps) pair for all hours, or a function hour-start -> pair."""
        if wind is None:
            return self.area["defaultFlow"]
        hour = math.floor(t / 3600.0) * 3600.0
        w = wind(hour) if callable(wind) else wind
        return choose_flow(self.area, *(w or (None, None)))

    def slots_near(self, t: float, wind=None) -> Iterable[Slot]:
        delta = self.m["slotSeconds"]
        lo, hi = t - 420.0, t + 420.0   # covers the longest corridor (about 290 s) and the departure climb
        for day in sorted({self.local_day(lo), self.local_day(hi)}):
            mid = self.local_midnight(day)
            k0 = max(0, int(math.floor((lo - mid) / delta)) - 1)
            k1 = int(math.floor((hi - mid) / delta)) + 1
            k1 = min(k1, int(math.ceil((self.local_midnight(day + 1) - mid) / delta)) - 1)
            for k in range(k0, k1 + 1):
                centre = mid + k * delta + delta / 2
                flow = self.area["flows"][self.flow_at(centre, wind)]
                for stream, refs in (("arr", flow["arrivals"]), ("dep", flow["departures"])):
                    for ref in refs:
                        s = self.slot(ref, stream, day, k)
                        if s is not None:
                            yield s

    # -- kinematics ----------------------------------------------------------------------------
    def _arrival_distance(self, v_app: float, tau: float) -> Optional[float]:
        """Distance before the threshold with `tau` seconds to go (ambient-planes.md 4.4, closed form)."""
        d6 = self.m["speedChangeStartNm"] * NM
        v_far = self.m["corridorStartKt"] * KT
        D = self.corridor - d6
        dv = v_far - v_app
        if tau <= d6 / v_app:
            return v_app * tau
        v = v_app * math.exp((tau - d6 / v_app) * dv / D)
        d = d6 + D * (v - v_app) / dv
        return d if d <= self.corridor else None

    def _arrival_speed(self, v_app: float, d: float) -> float:
        d6 = self.m["speedChangeStartNm"] * NM
        if d <= d6:
            return v_app
        return v_app + (self.m["corridorStartKt"] * KT - v_app) * (d - d6) / (self.corridor - d6)

    def state(self, s: Slot, t: float) -> Optional[dict]:
        """Position record for the slot's aircraft at time t, or None when it is not on its corridor."""
        rw, m = s.runway, self.m
        lat0, lon0 = rw["threshold"]
        hdg = rw["headingTrueDeg"]
        fade = m["fadeNm"] * NM
        if s.stream == "arr":
            if t <= s.t:
                d = self._arrival_distance(s.v_app, s.t - t)
                if d is None:
                    return None
                lat, lon = destination(lat0, lon0, hdg + 180.0, d)
                return self._rec(s, t, lat, lon, hdg, self._arrival_speed(s.v_app, d),
                                 m["thresholdCrossingM"] + d * self.tan_glide,
                                 min(1.0, max(0.0, (self.corridor - d) / fade)), "approach")
            dt = t - s.t
            td = m["touchdownM"]
            t_td = td / s.v_app
            if dt <= t_td:
                x, v, alt = s.v_app * dt, s.v_app, m["thresholdCrossingM"] * (1 - dt / t_td)
                phase, op = "flare", 1.0
            else:
                v0, v1 = s.v_app - 5 * KT, m["rolloutEndKt"] * KT
                a = (v0 * v0 - v1 * v1) / (2 * m["rolloutM"])
                tr = (v0 - v1) / a
                tau = dt - t_td
                if tau <= tr:
                    x, v, op = td + v0 * tau - 0.5 * a * tau * tau, v0 - a * tau, 1.0
                else:
                    tau2 = tau - tr
                    if tau2 > m["dissolveSeconds"]:
                        return None
                    x, v, op = td + m["rolloutM"] + v1 * tau2, v1, 1.0 - tau2 / m["dissolveSeconds"]
                alt, phase = 0.0, "rollout"
            lat, lon = destination(lat0, lon0, hdg, x)
            return self._rec(s, t, lat, lon, hdg, v, alt, op, phase)
        # departure
        dep = m["departure"]
        if t < s.t:
            return None
        tau = t - s.t
        v_r = dep["rotateKt"] * KT
        a = v_r * v_r / (2 * s.roll_m)
        t_roll = v_r / a
        fade_in = min(1.0, tau / dep["fadeInSeconds"])
        if tau <= t_roll:
            x, v, alt, phase = 0.5 * a * tau * tau, a * tau, 0.0, "takeoffRoll"
        else:
            v = dep["climbKt"] * KT
            x = s.roll_m + v * (tau - t_roll)
            alt, phase = min((x - s.roll_m) * dep["climbTan"], dep["ceilingM"]), "climb"
        end = rw["lengthM"] + dep["beyondRunwayNm"] * NM
        if x > end:
            return None
        lat, lon = destination(lat0, lon0, hdg, x)
        return self._rec(s, t, lat, lon, hdg, v, alt, min(fade_in, max(0.0, (end - x) / fade)), phase)

    def _rec(self, s: Slot, t: float, lat, lon, hdg, v, alt, opacity, phase) -> dict:
        return {
            "id": "amb:%s:%s:%d:%04d" % (self.area["airport"], s.runway["ref"], s.day, s.index),
            "kind": "aircraft-ambient", "route": "%s %s" % (self.area["airport"], s.runway["ref"]), "routeName": None,
            "lat": round(lat, 6), "lon": round(lon, 6), "heading": hdg, "speedMps": round(v, 2),
            "stopStatus": None, "timestamp": int(t), "ageSeconds": 0, "source": "ambient",
            "altitudeM": round(alt, 1), "label": LABEL,
            "basis": "simulated", "phase": phase, "opacity": round(opacity, 3),
            "class": "heavy" if s.heavy else "medium", "hullVariant": s.hull,
        }

    def aircraft(self, t: float, wind=None) -> List[dict]:
        out = []
        for s in self.slots_near(t, wind):
            r = self.state(s, t)
            if r is not None:
                out.append(r)
        out.sort(key=lambda r: r["id"])
        return out


VISIBILITY_RULES = {"airportRadiusM": 30000, "aerialMaxRangeM": 12000, "aerialFadeStartM": 9000,
                    "streetMaxRangeM": 8000, "streetMinElevationDeg": 8, "maxAerial": 6, "maxStreet": 3,
                    "sound": False, "pickable": False}


def snapshot(areas: List[dict], t: float, wind=None) -> dict:
    """The on-device snapshot of ambient-planes.md section 7 (schema 1, live false), for one instant."""
    vehicles: List[dict] = []
    flows = {}
    for area in areas:
        if area.get("aircraftMode", "ambient") != "ambient":
            continue
        ap = Airport(area)
        vehicles += ap.aircraft(t, wind)
        flows[area["airport"]] = ap.flow_at(t, wind)
    return {
        "schema": 1, "layer": "planes", "live": False, "basis": "simulated", "generatedAt": int(t),
        "feedTimestamp": None, "state": "fresh", "stale": False, "label": LABEL,
        "flows": flows, "visibility": VISIBILITY_RULES, "vehicles": vehicles, "attribution": [ATTRIBUTION],
    }
