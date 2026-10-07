"""Builds the `worldengine.live.satellites/1` JSON document (spec: docs/live-world/satellites.md)."""

import json
import os
import time
from typing import Dict, Iterable, List, Optional

from . import passes as P
from .celestrak import ATTRIBUTION
from .sgp4 import DeepSpace, Elements, PropagationError, Satellite

SCHEMA = "worldengine.live.satellites/1"
FRESH_DAYS = 3.0      # SGP4 from a fresh element set: about 1 km along-track; ISS reboosts change orbits
STALE_DAYS = 10.0     # beyond this, pass times can be off by minutes: not shown
HERE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONFIG = os.path.join(HERE, "data", "satellites.json")


def load_config(path: str = CONFIG) -> dict:
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)


def element_state(epoch: float, at: float) -> str:
    age = (at - epoch) / 86400.0
    if age < -1.0:
        return "stale"  # elements dated in the future: suspicious
    a = abs(age)
    return "fresh" if a <= FRESH_DAYS else ("stale" if a <= STALE_DAYS else "unavailable")


def _now_point(sat: Satellite, obs: P.Observer, at: float, std_mag: Optional[float]) -> dict:
    o = obs.observe(sat, at)
    m = P.magnitude(std_mag, o.range_km, o.phase_rad) if o.sunlit else None
    return {"t": int(at), "altDeg": round(o.alt, 3), "azDeg": round(o.az, 3), "rangeKm": round(o.range_km, 1),
            "subLat": round(o.lat, 4), "subLon": round(o.lon, 4), "heightKm": round(o.height_km, 1),
            "sunlit": o.sunlit, "observerSunAltDeg": round(o.sun_alt, 2),
            "visibleToEye": o.sunlit and o.alt >= P.VISIBLE_MIN_ALT and o.sun_alt <= P.SUN_MAX_ALT_FOR_VISIBLE,
            "magnitude": None if m is None else round(m, 2), "basis": "forecast"}


def build(elements: Iterable[Elements], lat: float, lon: float, elev_m: float, at: float, hours: float = 48.0,
          fetched_at: Optional[float] = None, fetch_error: Optional[str] = None, config: Optional[dict] = None,
          ids: Optional[List[int]] = None, now: Optional[float] = None, visible_only: bool = False) -> dict:
    now = time.time() if now is None else now
    config = config if config is not None else load_config()
    mags = {s["noradId"]: s.get("stdMag") for s in config.get("satellites", [])}
    obs = P.Observer(lat, lon, elev_m)
    end = at + hours * 3600.0
    sats: List[dict] = []
    seen = set()
    for el in elements:
        if el.norad_id in seen or (ids and el.norad_id not in ids):
            continue
        seen.add(el.norad_id)
        state = element_state(el.epoch, at)
        row: Dict = {"id": "norad:%d" % el.norad_id, "noradId": el.norad_id, "name": el.name,
                     "elementsEpoch": int(el.epoch), "elementsAgeDays": round((at - el.epoch) / 86400.0, 2),
                     "state": state, "basis": "forecast",
                     "standardMagnitude": ({"value": mags[el.norad_id], "basis": "inferred"}
                                           if mags.get(el.norad_id) is not None else None)}
        if state == "unavailable":
            row.update(reason="element set older than %d days" % STALE_DAYS, passes=[], now=None)
            sats.append(row)
            continue
        try:
            sat = Satellite(el)
            row["now"] = _now_point(sat, obs, at, mags.get(el.norad_id))
            ps = P.find_passes(sat, obs, at, end, mags.get(el.norad_id))
        except DeepSpace:
            continue  # not a naked-eye pass target; documented scope
        except PropagationError as exc:
            row.update(state="unavailable", reason=str(exc), passes=[], now=None)
            sats.append(row)
            continue
        row["passes"] = [p for p in ps if p["visible"]] if visible_only else ps
        sats.append(row)
    states = {s["state"] for s in sats}
    if not sats:
        overall = "unavailable"
    elif "fresh" in states:
        overall = "fresh"
    elif "stale" in states:
        overall = "stale"
    else:
        overall = "unavailable"
    return {
        "schema": SCHEMA, "layer": "satellites", "generatedAt": int(now), "live": False,
        "observer": {"lat": lat, "lon": lon, "elevM": elev_m},
        "window": {"start": int(at), "end": int(end)},
        "state": overall,
        "elements": {"source": "celestrak", "fetchedAt": None if fetched_at is None else int(fetched_at),
                     "error": fetch_error, "basis": "observed"},
        "rules": {"minPassAltDeg": P.MIN_PASS_ALT, "visibleMinAltDeg": P.VISIBLE_MIN_ALT,
                  "sunMaxAltDegForVisible": P.SUN_MAX_ALT_FOR_VISIBLE,
                  "freshDays": FRESH_DAYS, "staleDays": STALE_DAYS},
        "satellites": sats,
        "attribution": [ATTRIBUTION],
    }
