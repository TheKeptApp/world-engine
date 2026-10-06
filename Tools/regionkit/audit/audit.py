#!/usr/bin/env python3
"""WorldEngine map-data coverage audit (Tools/regionkit/audit).

Measures, per 1 km x 1 km sample cell, what OpenStreetMap and Overture Maps provide for 3-D
buildings and trees, and estimates the triangle count the current generator would produce.

Steps (run in order; every network response is cached, so re-runs cost nothing):
  resolve    look up each cell's anchor (one batched Overpass query per metro) -> cells.json
  osm        per cell: buildings + building:parts (`out geom`) and tree counts (`out count`)
  overture   per cell: Overture buildings (DuckDB over the public GeoParquet, bbox-filtered)
  tris       triangle-count model (port of the generator's counting rules) + Sloan's Lake check
  report     results/*.csv|json and the markdown table for docs/research/data-coverage.md
  all        everything above
  bytes      total bytes downloaded (from the cache ledger)

Only aggregates are written to results/. Raw responses stay in the cache (default
Tools/regionkit/audit/.cache, git-ignored; override with --cache or $AUDIT_CACHE).
Standard library only, except `overture`, which needs the duckdb module
(`uv run --with duckdb python3 audit.py overture`).
"""
import argparse
import calendar
import csv
import gzip
import hashlib
import json
import math
import os
import re
import ssl
import statistics
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
CELLS_PATH = os.path.join(HERE, "cells.json")
RESULTS = os.path.join(HERE, "results")
USER_AGENT = "WorldEngine-regionkit/0.1 (offline research tool)"
OVERPASS = ["https://overpass.private.coffee/api/interpreter", "https://overpass-api.de/api/interpreter"]
MIN_GAP = 5.0
BACKOFF = 60.0
MAX_DATA_AGE_DAYS = 3.0
OVERTURE_RELEASE = "2026-09-23.1"
# WorldLab focus used for the recorded Sloan's Lake package (docs/package-format.md) and the M2
# matched-run header; Apps/WorldLab/Resources/demo.json at commit b76580c.
RECORDED_FOCUS_B76580C = {"south": 39.747058, "west": -105.04345, "north": 39.752462, "east": -105.037966}
STAC = "https://stac.overturemaps.org"

CACHE = None  # set in main()
_SSL = None


def ssl_context():
    """Default context; falls back to the macOS system CA bundle when Python's store is empty
    (python.org builds without "Install Certificates")."""
    global _SSL
    if _SSL is None:
        ctx = ssl.create_default_context()
        if ctx.cert_store_stats().get("x509_ca", 0) == 0:
            for cafile in ("/etc/ssl/cert.pem", "/private/etc/ssl/cert.pem"):
                if os.path.exists(cafile):
                    ctx = ssl.create_default_context(cafile=cafile)
                    break
        _SSL = ctx
    return _SSL


def log(*a):
    print(*a, file=sys.stderr, flush=True)


# ---------------------------------------------------------------------------------------------
# Cache + download ledger
# ---------------------------------------------------------------------------------------------

def cache_path(*parts):
    p = os.path.join(CACHE, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def ledger(kind, url, nbytes, extra=None):
    rec = {"t": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "kind": kind, "url": url, "bytes": nbytes}
    rec.update(extra or {})
    with open(cache_path("ledger.jsonl"), "a") as f:
        f.write(json.dumps(rec) + "\n")


def http_get(url, kind):
    """GET with the cache (keyed by URL). Returns bytes."""
    key = hashlib.sha256(url.encode()).hexdigest()[:40]
    p = cache_path("http", key + ".bin")
    if os.path.exists(p):
        with open(p, "rb") as f:
            return f.read()
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept-Encoding": "gzip"})
    with urllib.request.urlopen(req, timeout=120, context=ssl_context()) as r:
        raw = r.read()
        enc = r.headers.get("Content-Encoding", "")
    ledger(kind, url, len(raw))
    data = gzip.decompress(raw) if enc == "gzip" else raw
    with open(p + ".tmp", "wb") as f:
        f.write(data)
    os.replace(p + ".tmp", p)
    return data


# ---------------------------------------------------------------------------------------------
# Overpass (owner etiquette: one at a time, UA, >=5 s gap, status check, >=60 s back-off,
# cached by query hash, never `out meta`)
# ---------------------------------------------------------------------------------------------

_last_request = [0.0]
_down_until = {}


def _overpass_wait_for_slot(endpoint):
    """Waits for a free slot. Returns False if the server doesn't answer its status page (it is
    then skipped for 10 minutes and the next endpoint is used)."""
    if _down_until.get(endpoint, 0) > time.time():
        return False
    status_url = endpoint.replace("/interpreter", "/status")
    for _ in range(40):
        gap = MIN_GAP - (time.time() - _last_request[0])
        if gap > 0:
            time.sleep(gap)
        try:
            req = urllib.request.Request(status_url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=20, context=ssl_context()) as r:
                text = r.read().decode("utf-8", "replace")
            ledger("overpass-status", status_url, len(text))
        except Exception as e:
            log(f"  status check failed on {endpoint}: {e}; skipping it for 10 min")
            _down_until[endpoint] = time.time() + 600
            return False
        if "Rate limit: 0" in text or "slots available now" in text:
            return True
        m = re.findall(r"in (\d+) seconds", text)
        wait = max(5, min(int(x) for x in m)) if m else 15
        log(f"  no free slot on {endpoint}; waiting {wait} s")
        time.sleep(wait + 1)
    return False


def overpass(query):
    """Runs an Overpass query (cached). Returns (json_dict, meta)."""
    if re.search(r"\bout\s+meta\b", query):
        raise ValueError("out meta is not allowed (contributor data)")
    norm = " ".join(query.split())
    key = "ovp-" + hashlib.sha256(norm.encode()).hexdigest()[:40]
    p = cache_path("overpass", key + ".json.gz")
    mp = cache_path("overpass", key + ".meta.json")
    if os.path.exists(p) and os.path.exists(mp):
        with gzip.open(p, "rb") as f:
            data = json.loads(f.read())
        with open(mp) as f:
            return data, json.load(f)
    last_err = None
    for attempt in range(4):
        for endpoint in OVERPASS:
            if not _overpass_wait_for_slot(endpoint):
                continue
            try:
                body = ("data=" + urllib.parse.quote(query)).encode()
                req = urllib.request.Request(endpoint, data=body, headers={
                    "User-Agent": USER_AGENT, "Accept-Encoding": "gzip",
                    "Content-Type": "application/x-www-form-urlencoded"})
                t0 = time.time()
                with urllib.request.urlopen(req, timeout=240, context=ssl_context()) as r:
                    raw = r.read()
                    enc = r.headers.get("Content-Encoding", "")
                _last_request[0] = time.time()
                ledger("overpass", endpoint, len(raw), {"key": key, "seconds": round(time.time() - t0, 1)})
                text = gzip.decompress(raw) if enc == "gzip" else raw
                data = json.loads(text)
                if "remark" in data and "runtime error" in data.get("remark", ""):
                    raise RuntimeError("overpass runtime error: " + data["remark"])
                base = data.get("osm3s", {}).get("timestamp_osm_base")
                if base:
                    age_days = (time.time() - calendar.timegm(time.strptime(base, "%Y-%m-%dT%H:%M:%SZ"))) / 86400
                    if age_days > MAX_DATA_AGE_DAYS:
                        # A mirror serving an old database: don't cache it, try the next endpoint.
                        raise RuntimeError(f"stale data ({base}, {age_days:.0f} days old)")
                meta = {"endpoint": endpoint, "fetchedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                        "timestamp_osm_base": data.get("osm3s", {}).get("timestamp_osm_base"),
                        "wireBytes": len(raw), "bodyBytes": len(text), "query": query}
                with gzip.open(p + ".tmp", "wb") as f:
                    f.write(text)
                os.replace(p + ".tmp", p)
                with open(mp, "w") as f:
                    json.dump(meta, f, indent=1)
                return data, meta
            except urllib.error.HTTPError as e:
                _last_request[0] = time.time()
                last_err = f"{endpoint}: HTTP {e.code}"
                log("  " + last_err)
                if e.code in (429, 504):
                    log(f"  backing off {BACKOFF:.0f} s")
                    time.sleep(BACKOFF)
            except Exception as e:
                _last_request[0] = time.time()
                last_err = f"{endpoint}: {e}"
                log("  " + last_err)
                _down_until[endpoint] = time.time() + 600
        log(f"  all endpoints failed; backing off {BACKOFF:.0f} s")
        time.sleep(BACKOFF)
    raise RuntimeError("Overpass failed: " + str(last_err))


# ---------------------------------------------------------------------------------------------
# Geometry (local metres; ports of the engine's WorldGeo where it matters)
# ---------------------------------------------------------------------------------------------

A = 6378137.0
FLAT = 1.0 / 298.257223563
E2 = FLAT * (2 - FLAT)


def box_around(lat, lon, half_m):
    """(S, W, N, E) +-half_m around a centre (meridional / prime-vertical radii; same rule as
    Tools/regionkit/regionkit/geo.py so the cells line up)."""
    la = math.radians(lat)
    w = math.sqrt(1 - E2 * math.sin(la) ** 2)
    m_rad = A * (1 - E2) / w ** 3
    n_rad = A / w
    dlat = math.degrees(half_m / m_rad)
    dlon = math.degrees(half_m / (n_rad * math.cos(la)))
    return (round(lat - dlat, 6), round(lon - dlon, 6), round(lat + dlat, 6), round(lon + dlon, 6))


class Frame:
    """WGS84 ECEF -> ENU at an origin (port of Sources/WorldGeo/LocalFrame.swift, flat world)."""

    def __init__(self, lat, lon):
        self.p0 = self._ecef(lat, lon)
        la, lo = math.radians(lat), math.radians(lon)
        self.sl, self.cl, self.so, self.co = math.sin(la), math.cos(la), math.sin(lo), math.cos(lo)

    @staticmethod
    def _ecef(lat, lon):
        la, lo = math.radians(lat), math.radians(lon)
        n = A / math.sqrt(1 - E2 * math.sin(la) ** 2)
        return (n * math.cos(la) * math.cos(lo), n * math.cos(la) * math.sin(lo), n * (1 - E2) * math.sin(la))

    def xy(self, lat, lon):
        x, y, z = self._ecef(lat, lon)
        dx, dy, dz = x - self.p0[0], y - self.p0[1], z - self.p0[2]
        e = -self.so * dx + self.co * dy
        n = -self.sl * self.co * dx - self.sl * self.so * dy + self.cl * dz
        return (e, n)


def signed_area(r):
    s = 0.0
    n = len(r)
    for i in range(n):
        x1, y1 = r[i]
        x2, y2 = r[(i + 1) % n]
        s += x1 * y2 - x2 * y1
    return s / 2


def centroid(r):
    """Area centroid of a ring (RingMath.centroid); vertex mean for degenerate rings."""
    a = signed_area(r)
    if abs(a) < 1e-9:
        return (sum(p[0] for p in r) / len(r), sum(p[1] for p in r) / len(r))
    cx = cy = 0.0
    n = len(r)
    for i in range(n):
        x1, y1 = r[i]
        x2, y2 = r[(i + 1) % n]
        c = x1 * y2 - x2 * y1
        cx += (x1 + x2) * c
        cy += (y1 + y2) * c
    return (cx / (6 * a), cy / (6 * a))


def ring_contains(r, p):
    x, y = p
    inside = False
    n = len(r)
    j = n - 1
    for i in range(n):
        xi, yi = r[i]
        xj, yj = r[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def clean_ring(ring, merge=0.01, collinear=0.001):
    """Port of RingMath.clean: merge close points, drop closing duplicate, remove collinear."""
    pts = []
    for p in ring:
        if pts and math.dist(pts[-1], p) < merge:
            continue
        pts.append(p)
    while len(pts) > 1 and math.dist(pts[0], pts[-1]) < merge:
        pts.pop()
    changed = True
    while changed and len(pts) >= 3:
        changed = False
        i = 0
        while i < len(pts) and len(pts) >= 3:
            a = pts[(i - 1) % len(pts)]
            b = pts[i]
            c = pts[(i + 1) % len(pts)]
            acx, acy = c[0] - a[0], c[1] - a[1]
            ln = math.hypot(acx, acy)
            d = abs(acx * (b[1] - a[1]) - acy * (b[0] - a[0])) / ln if ln > 1e-12 else math.dist(a, b)
            if d < collinear:
                pts.pop(i)
                changed = True
            else:
                i += 1
    return pts if len(pts) >= 3 else None


def clean_polygon(outer, holes, min_area=1.0):
    """Polygon2D.cleaned(minArea: 1.0) as used for buildings: outer CCW, holes CW."""
    o = clean_ring(outer)
    if o is None or abs(signed_area(o)) < min_area:
        return None
    if signed_area(o) < 0:
        o = o[::-1]
    hs = []
    for h in holes:
        c = clean_ring(h)
        if c is None or abs(signed_area(c)) < 0.5:
            continue
        hs.append(c if signed_area(c) < 0 else c[::-1])
    return o, hs


def assemble_rings(ways):
    """Joins member ways (lists of points) into closed rings, like MultipolygonAssembler.joinRings:
    returns None if any chain fails to close (the engine then skips the whole relation)."""
    rings = []
    pending = [list(w) for w in ways if len(w) >= 2]
    while pending:
        cur = pending.pop(0)
        changed = True
        while cur[0] != cur[-1] and changed:
            changed = False
            for i, w in enumerate(pending):
                if w[0] == cur[-1]:
                    cur += w[1:]
                elif w[-1] == cur[-1]:
                    cur += w[::-1][1:]
                elif w[-1] == cur[0]:
                    cur = w + cur[1:]
                elif w[0] == cur[0]:
                    cur = w[::-1] + cur[1:]
                else:
                    continue
                pending.pop(i)
                changed = True
                break
        if cur[0] != cur[-1]:
            return None
        if len(cur) >= 4:
            rings.append(cur[:-1])
    return rings


# ---------------------------------------------------------------------------------------------
# Tag parsing (ports of Sources/WorldMap/TagParsing.swift)
# ---------------------------------------------------------------------------------------------

def _first(raw):
    return raw.split(";")[0].strip()


def parse_length(raw):
    if raw is None:
        return None
    s = _first(raw).lower()
    if "." not in s and s.count(",") == 1:
        s = s.replace(",", ".")
    meters = None
    if "'" in s:
        feet_s, rest = s.split("'", 1)
        rest = rest.strip()
        if rest.endswith('"'):
            rest = rest[:-1]
        rest = rest.strip()
        try:
            meters = float(feet_s.strip()) * 0.3048 + (float(rest) if rest else 0) * 0.0254
        except ValueError:
            meters = None
    else:
        m = re.match(r"^([0-9.]*)(.*)$", s)
        num, unit = m.group(1), m.group(2).strip()
        try:
            n = float(num)
        except ValueError:
            n = None
        if n is not None and unit in ("", "m", "meter", "meters", "metre", "metres"):
            meters = n
        elif n is not None and unit in ("ft", "feet", "foot"):
            meters = n * 0.3048
    if meters is None or not (0 < meters <= 1000):
        return None
    return meters


def parse_number(raw):
    if raw is None:
        return None
    try:
        n = float(_first(raw).replace(",", "."))
    except ValueError:
        return None
    return n if 0 <= n <= 500 else None


# ---------------------------------------------------------------------------------------------
# Cells
# ---------------------------------------------------------------------------------------------

def load_cells():
    with open(CELLS_PATH) as f:
        return json.load(f)


def save_cells(doc):
    with open(CELLS_PATH + ".tmp", "w") as f:
        json.dump(doc, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(CELLS_PATH + ".tmp", CELLS_PATH)


def all_cells(doc):
    for m in doc["metros"]:
        for c in m["cells"]:
            yield m, c


def cell_bbox(doc, c):
    """Lat/lon box used to select data (Overpass, Overture)."""
    lat, lon = c["center"]
    return box_around(lat, lon, doc.get("cellHalfSizeMeters", 500))


def cell_rect(doc):
    """The counting rectangle: exactly +-half-size metres in the cell's local frame (the rounded
    lat/lon box differs from it by up to ~0.1 m)."""
    h = doc.get("cellHalfSizeMeters", 500)
    return (-h, -h, h, h)


def _rx(name):
    return re.sub(r'([.^$*+?()\[\]{}|\\])', r'\\\1', name)


def _matches(tags, match, match_any=None):
    if match_any and not any(_matches(tags, m) for m in match_any):
        return False
    for k, v in (match or {}).items():
        tv = tags.get(k)
        if v == "*":
            if tv is None:
                return False
        elif isinstance(v, list):
            if tv not in v:
                return False
        elif tv != v:
            return False
    return True


def haversine_km(lat1, lon1, lat2, lon2):
    r = 6371.0088
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lon2 - lon1)
    h = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


def step_resolve(args):
    doc = load_cells()
    for m in doc["metros"]:
        todo = [c for c in m["cells"] if args.force or not c.get("center")]
        if not todo:
            continue
        names = sorted({n for c in m["cells"] for n in (c["anchor"].get("names") or [c["anchor"]["name"]])})
        s, w, n, e = m["anchorSearch"]["bbox"]
        q = ('[out:json][timeout:60];\n'
             'nwr["name"~"^(%s)$"](%.4f,%.4f,%.4f,%.4f);\n'
             'out center tags;' % ("|".join(_rx(x) for x in names), s, w, n, e))
        log(f"[resolve] {m['id']}: {len(names)} names")
        data, meta = overpass(q)
        els = data["elements"]
        for c in todo:
            a = c["anchor"]
            names_c = a.get("names") or [a["name"]]
            cands = []
            for el in els:
                tags = el.get("tags", {})
                if tags.get("name") not in names_c or not _matches(tags, a.get("match"), a.get("matchAny")):
                    continue
                if "center" in el:
                    ctr = (el["center"]["lat"], el["center"]["lon"])
                elif "lat" in el:
                    ctr = (el["lat"], el["lon"])
                else:
                    continue
                d = haversine_km(ctr[0], ctr[1], a["near"][0], a["near"][1]) if a.get("near") else 0.0
                cands.append((names_c.index(tags["name"]), d, el["type"], el["id"], ctr, tags))
            max_km = a.get("maxKm", 3.0)
            cands = [t for t in cands if not a.get("near") or t[1] <= max_km]
            cands.sort(key=lambda t: (t[0], t[1], t[2], t[3]))
            if not cands:
                log(f"  NOT FOUND: {c['id']} ({names_c})")
                c["center"] = None
                c["resolved"] = {"found": False}
                continue
            _, d, typ, eid, ctr, tags = cands[0]
            c["center"] = [round(ctr[0], 4), round(ctr[1], 4)]
            c["osm"] = f"{typ}/{eid}"
            c["resolved"] = {
                "found": True, "candidates": len(cands), "distanceFromHintKm": round(d, 3),
                "matchedTags": {k: tags[k] for k in sorted(tags) if k in (
                    "name", "leisure", "railway", "public_transport", "historic", "tourism", "amenity", "place",
                    "highway", "landuse", "man_made", "building", "memorial")},
                "osmTimestamp": meta.get("timestamp_osm_base")}
            log(f"  {c['id']}: {c['osm']} {c['center']} ({len(cands)} cand., {d:.2f} km from hint)")
    save_cells(doc)


# ---------------------------------------------------------------------------------------------
# OSM buildings per cell
# ---------------------------------------------------------------------------------------------

KEEP_TAGS = ("building", "building:part", "building:levels", "roof:levels", "height", "min_height",
             "building:min_level", "roof:shape", "building:material", "building:colour", "roof:colour",
             "roof:material", "building:flats", "type")


def osm_query(bbox):
    b = "(%.6f,%.6f,%.6f,%.6f)" % bbox
    return ('[out:json][timeout:180];\n'
            '(way["building"]%s;relation["building"]%s;way["building:part"]%s;relation["building:part"]%s;);\n'
            'out geom;\n'
            'node["natural"="tree"]%s;\nout count;\n'
            'way["natural"="tree_row"]%s;\nout count;' % (b, b, b, b, b, b))


def parse_buildings(data, frame):
    """Building/part polygons in local metres from an `out geom` response (relations carry their
    member geometry; `out tags geom` would drop the members).

    Engine rule (MapFeatureBuilder): one building per closed way, and one per assembled outer
    polygon of a `type=multipolygon` relation (holes go to the smallest containing outer), each
    with its own centroid (of the raw outer ring). A relation whose rings don't close is skipped.
    No de-duplication: a way tagged `building` that is also the outer of a building multipolygon
    counts twice, as in the engine; such pairs are counted in `dupWayAlsoRelationOuter`.
    `type=building` relations are grouping relations (their outline way is counted) and are not
    counted; how many carry a `building` tag is reported, because the engine assembles those."""
    feats = []
    counts = [el["tags"] for el in data["elements"] if el["type"] == "count"]
    rel_outer_members = set()
    for el in data["elements"]:
        if el["type"] == "relation" and el.get("tags", {}).get("type") == "multipolygon" and \
                building_type(el.get("tags", {})) is not None:
            for mbr in el.get("members", []):
                if mbr.get("type") == "way" and mbr.get("role") != "inner":
                    rel_outer_members.add(mbr["ref"])
    stats = Counter()
    for el in data["elements"]:
        if el["type"] not in ("way", "relation"):
            continue
        tags = el.get("tags", {})
        b = tags.get("building")
        part = tags.get("building:part")
        is_building = b is not None and b != "no"
        is_part = not is_building and part is not None and part != "no"
        if not (is_building or is_part):
            continue
        ref = f"{el['type']}/{el['id']}"
        dup = False
        if el["type"] == "way":
            g = el.get("geometry") or []
            pts = [(q["lat"], q["lon"]) for q in g if q]
            # MapFeatureBuilder.classifyWay: closed, not a highway (unless area=yes), not area=no.
            if len(pts) < 4 or pts[0] != pts[-1] or tags.get("area") == "no" or \
                    ("highway" in tags and tags.get("area") != "yes"):
                continue
            dup = is_building and el["id"] in rel_outer_members
            polys = [([frame.xy(*p) for p in pts[:-1]], [])]
        else:
            if tags.get("type") == "building":
                stats["typeBuildingRelations"] += 1
                stats["typeBuildingRelationsWithBuildingTag"] += int(is_building)
                continue
            if tags.get("type") != "multipolygon":
                continue
            ow, iw = [], []
            missing = False
            for mbr in el.get("members", []):
                if mbr.get("type") != "way":
                    continue
                if not mbr.get("geometry"):
                    missing = True
                    continue
                pts = [(q["lat"], q["lon"]) for q in mbr["geometry"] if q]
                (iw if mbr.get("role") == "inner" else ow).append(pts)
            outers, inners = (None, None) if missing else (assemble_rings(ow), assemble_rings(iw))
            if not outers or inners is None:
                stats["relationsSkipped"] += 1
                continue
            stats["buildingRelations" if is_building else "partRelations"] += 1
            polys = [([frame.xy(*p) for p in o], []) for o in outers]
            for h in inners:
                lh = [frame.xy(*p) for p in h]
                cont = [i for i, (o, _) in enumerate(polys) if ring_contains(o, lh[0])]
                if cont:
                    polys[min(cont, key=lambda i: abs(signed_area(polys[i][0])))][1].append(lh)
            if len(polys) > 1:
                stats["multiOuterRelations"] += 1
        for k, (raw_outer, raw_holes) in enumerate(polys):
            cp = clean_polygon(raw_outer, raw_holes)
            if not cp:
                stats["degenerate"] += 1
                continue
            o, hs = cp
            feats.append({
                "ref": ref, "polygonIndex": k, "kind": "building" if is_building else "part", "dup": dup,
                "tags": {kk: tags[kk] for kk in KEEP_TAGS if kk in tags},
                "outer": o, "holes": hs,
                "centroid": centroid(raw_outer),
                "area": abs(signed_area(o)) - sum(abs(signed_area(h)) for h in hs),
            })
    return feats, counts, dict(stats)


def osm_cell(doc, c):
    """Fetches (cached) and parses one cell. Returns dict with features and meta."""
    bbox = cell_bbox(doc, c)
    data, meta = overpass(osm_query(bbox))
    frame = Frame(*c["center"])
    feats, counts, pstats = parse_buildings(data, frame)
    sw = frame.xy(bbox[0], bbox[1])
    ne = frame.xy(bbox[2], bbox[3])
    rect = cell_rect(doc)  # exact +-500 m in the local frame (as Tools/regionkit); the lat/lon box only selects data
    for f in feats:
        x, y = f["centroid"]
        f["in"] = rect[0] <= x <= rect[2] and rect[1] <= y <= rect[3]
    trees = int(counts[0]["nodes"]) if counts else None
    tree_rows = int(counts[1]["ways"]) if len(counts) > 1 else None
    return {"bbox": bbox, "rect": rect, "features": feats, "trees": trees, "treeRows": tree_rows,
            "parseStats": pstats, "meta": meta}


# Engine roles (BuildingGenerator.role) -------------------------------------------------------

HOUSE_TYPES = {"house", "detached", "semidetached_house", "bungalow", "residential", "terrace", "cabin"}
GARAGE_TYPES = {"garage", "garages", "carport"}
SHED_TYPES = {"shed", "hut", "kiosk", "toilets"}


def engine_role(btype, area):
    if btype in GARAGE_TYPES:
        return "garage"
    if btype in SHED_TYPES or area < 12.0:
        return "shed"
    if btype in HOUSE_TYPES or (btype == "yes" and area < 250):
        return "house"
    return "block"


def has_height(t):
    return parse_length(t.get("height")) is not None


def has_levels(t):
    v = parse_number(t.get("building:levels"))
    return v is not None and v > 0


def pct(n, d):
    return round(100.0 * n / d, 1) if d else None


def osm_metrics(cell, osm):
    rect = osm["rect"]
    area_km2 = (rect[2] - rect[0]) * (rect[3] - rect[1]) / 1e6
    bl = [f for f in osm["features"] if f["kind"] == "building" and f["in"]]
    parts = [f for f in osm["features"] if f["kind"] == "part" and f["in"]]
    n = len(bl)
    t = [f["tags"] for f in bl]
    hh = sum(1 for x in t if has_height(x))
    lv = sum(1 for x in t if has_levels(x))
    hl = sum(1 for x in t if has_height(x) or has_levels(x))
    rs = sum(1 for x in t if x.get("roof:shape"))
    mc = sum(1 for x in t if x.get("building:material") or x.get("building:colour"))
    rc = sum(1 for x in t if x.get("roof:colour") or x.get("roof:material"))
    roles = Counter()
    role_hl = Counter()
    role_rs = Counter()
    for f in bl:
        r = engine_role(f["tags"].get("building", "yes"), f["area"])
        f["role"] = r
        roles[r] += 1
        if has_height(f["tags"]) or has_levels(f["tags"]):
            role_hl[r] += 1
        if f["tags"].get("roof:shape"):
            role_rs[r] += 1
    levels = [parse_number(x.get("building:levels")) for x in t if has_levels(x)]
    heights = [parse_length(x.get("height")) for x in t if has_height(x)]
    areas = sorted(f["area"] for f in bl)
    ph = sum(1 for f in parts if has_height(f["tags"]) or has_levels(f["tags"]))
    return {
        "areaKm2": round(area_km2, 4),
        "buildings": n, "buildingsPerKm2": round(n / area_km2, 1),
        "pctHeightOrLevels": pct(hl, n), "pctHeight": pct(hh, n), "pctLevels": pct(lv, n),
        "pctRoofShape": pct(rs, n), "pctMaterialOrColour": pct(mc, n), "pctRoofColourOrMaterial": pct(rc, n),
        "buildingParts": len(parts), "partsWithHeightOrLevels": ph,
        "trees": osm["trees"], "treesPerKm2": round(osm["trees"] / area_km2, 1) if osm["trees"] is not None else None,
        "treeRows": osm["treeRows"],
        "roles": dict(roles), "roleHeightOrLevels": dict(role_hl), "roleRoofShape": dict(role_rs),
        "roofShapes": dict(Counter(x["roof:shape"] for x in t if x.get("roof:shape")).most_common(8)),
        "buildingTypes": dict(Counter(x.get("building", "yes") for x in t).most_common(10)),
        "materials": dict(Counter(x["building:material"] for x in t if x.get("building:material")).most_common(5)),
        "levelsMedian": statistics.median(levels) if levels else None,
        "levelsMax": max(levels) if levels else None,
        "heightMax": round(max(heights), 1) if heights else None,
        "tallCount10Levels": sum(1 for x in t if (parse_number(x.get("building:levels")) or 0) >= 10 or (parse_length(x.get("height")) or 0) >= 32),
        "footprintMedianM2": round(statistics.median(areas), 1) if areas else None,
        "footprintCoveragePct": round(100 * sum(areas) / (area_km2 * 1e6), 1),
        "shareUnder30m2": pct(sum(1 for a in areas if a < 30), n),
        "fromRelations": sum(1 for f in bl if f["ref"].startswith("relation/")),
        "partsFromRelations": sum(1 for f in parts if f["ref"].startswith("relation/")),
        "dupWayAlsoRelationOuter": sum(1 for f in bl if f["dup"]),
        # Small untagged outlines: building=yes, footprint < 60 m2, no building:levels. A share of ALL
        # buildings in the cell, no road test (cf. the region kit's "probable garage", which also
        # requires a service road within 8 m and is a share of generator houses).
        "smallYesNoLevels": sum(1 for f in bl if f["tags"].get("building") == "yes" and f["area"] < 60 and not has_levels(f["tags"])),
        "parseStats": osm["parseStats"],
        "osmTimestamp": osm["meta"].get("timestamp_osm_base"),
        "endpoint": osm["meta"].get("endpoint"),
    }


def step_osm(args):
    doc = load_cells()
    out = {}
    for m, c in all_cells(doc):
        if not c.get("center"):
            log(f"[osm] skip {c['id']} (no centre)")
            continue
        if args.only and c["id"] not in args.only:
            continue
        log(f"[osm] {c['id']}")
        try:
            osm = osm_cell(doc, c)
        except RuntimeError as e:  # servers busy: keep going, a re-run fills the gap from cache
            log(f"   FAILED ({e}); re-run later")
            continue
        out[c["id"]] = osm_metrics(c, osm)
        log(f"   buildings {out[c['id']]['buildings']}, parts {out[c['id']]['buildingParts']}, trees {out[c['id']]['trees']}")
    os.makedirs(RESULTS, exist_ok=True)
    prev = {}
    p = os.path.join(RESULTS, "osm_metrics.json")
    if os.path.exists(p):
        with open(p) as f:
            prev = json.load(f)
    prev.update(out)
    with open(p, "w") as f:
        json.dump(prev, f, indent=1, sort_keys=True)


# ---------------------------------------------------------------------------------------------
# Overture buildings per cell
# ---------------------------------------------------------------------------------------------

def wkb_rings(b):
    """Outer rings (lon, lat) of a WKB Polygon / MultiPolygon (little or big endian)."""
    out = []

    def rd(off, fmt):
        return struct.unpack_from(fmt, b, off)

    def geom(off):
        bo = "<" if b[off] == 1 else ">"
        (gt,) = rd(off + 1, bo + "I")
        gt %= 1000
        off += 5
        if gt == 3:
            (nr,) = rd(off, bo + "I")
            off += 4
            for r in range(nr):
                (npt,) = rd(off, bo + "I")
                off += 4
                pts = [rd(off + 16 * i, bo + "dd") for i in range(npt)]
                off += 16 * npt
                if r == 0:
                    out.append(pts)
            return off
        if gt == 6:
            (ng,) = rd(off, bo + "I")
            off += 4
            for _ in range(ng):
                off = geom(off)
            return off
        raise ValueError("unsupported WKB type %d" % gt)
    geom(0)
    return out


def _duck_bytes(con):
    tot = 0
    for (m,) in con.execute("select message from duckdb_logs where type='HTTP'").fetchall():
        req, _, resp = m.partition("'response'")
        if "'type': GET" in req:
            mm = re.search(r"Content-Length=(\d+)", resp)
            if mm:
                tot += int(mm.group(1))
    return tot


def overture_rows(doc, cells):
    """Overture rows per cell (cached per release + cell bbox). Opens DuckDB only if needed."""
    coll = json.loads(http_get(f"{STAC}/{OVERTURE_RELEASE}/buildings/building/collection.json", "overture-stac"))
    bbs = coll["extent"]["spatial"]["bbox"][1:]
    items = [l["href"] for l in coll["links"] if l["rel"] == "item"]
    con = None
    result = {}
    for c in cells:
        bbox = cell_bbox(doc, c)
        key = hashlib.sha256(f"{OVERTURE_RELEASE}|{bbox}".encode()).hexdigest()[:24]
        p = cache_path("overture", f"{c['id']}-{key}.json.gz")
        if os.path.exists(p):
            with gzip.open(p, "rb") as f:
                result[c["id"]] = json.loads(f.read())
            continue
        s, w, n, e = bbox
        sel = [i for i, b in enumerate(bbs) if not (b[2] < w or b[0] > e or b[3] < s or b[1] > n)]
        urls = []
        for i in sel:
            it = json.loads(http_get(items[i], "overture-stac"))
            b = it["bbox"]
            if b[2] < w or b[0] > e or b[3] < s or b[1] > n:
                continue
            urls.append(it["assets"]["aws"]["href"])
        if con is None:
            import duckdb
            con = duckdb.connect()
            ext = cache_path("duckdb-ext", "x")
            con.execute(f"SET extension_directory='{os.path.dirname(ext)}'")
            con.execute("INSTALL httpfs")
            con.execute("LOAD httpfs")
            for setting in ("SET parquet_metadata_cache=true", "SET enable_http_metadata_cache=true"):
                try:
                    con.execute(setting)
                except Exception as ex:  # setting names vary by DuckDB version
                    log("  duckdb:", ex)
            con.execute("CALL enable_logging('HTTP')")
            before = 0
        flist = "[" + ",".join(f"'{u}'" for u in urls) + "]"
        q = (f"SELECT id, bbox.xmin, bbox.xmax, bbox.ymin, bbox.ymax, height, num_floors, roof_shape, facade_color, "
             f"facade_material, roof_color, roof_material, sources, geometry FROM read_parquet({flist}) "
             f"WHERE bbox.xmin <= {e} AND bbox.xmax >= {w} AND bbox.ymin <= {n} AND bbox.ymax >= {s}")
        rows = con.execute(q).fetchall()
        recs = []
        for r in rows:
            rings = wkb_rings(r[13])
            recs.append({"id": r[0], "bbox": [r[1], r[2], r[3], r[4]], "height": r[5], "num_floors": r[6],
                         "roof_shape": r[7], "facade_color": r[8], "facade_material": r[9], "roof_color": r[10],
                         "roof_material": r[11],
                         "sources": [{"property": x.get("property"), "dataset": x.get("dataset"), "record_id": x.get("record_id"),
                                      "version": x.get("version")} for x in (r[12] or [])],
                         "outer": max(rings, key=lambda rg: abs(signed_area(rg))) if rings else None})
        nb = _duck_bytes(con)
        ledger("overture-parquet", f"{len(urls)} file(s) for {c['id']}", nb - before, {"rows": len(recs)})
        before = nb
        with gzip.open(p + ".tmp", "wb") as f:
            f.write(json.dumps({"files": urls, "rows": recs}).encode())
        os.replace(p + ".tmp", p)
        result[c["id"]] = {"files": urls, "rows": recs}
        log(f"[overture] {c['id']}: {len(recs)} rows from {len(urls)} file(s); {(nb) / 1e6:.1f} MB so far")
    return result


class PolyIndex:
    def __init__(self, polys, cell=30.0):
        self.cell = cell
        self.polys = polys
        self.b = defaultdict(list)
        for i, (outer, holes) in enumerate(polys):
            xs, ys = [p[0] for p in outer], [p[1] for p in outer]
            bb = (min(xs), min(ys), max(xs), max(ys))
            for x in range(int(math.floor(bb[0] / cell)), int(math.floor(bb[2] / cell)) + 1):
                for y in range(int(math.floor(bb[1] / cell)), int(math.floor(bb[3] / cell)) + 1):
                    self.b[(x, y)].append((i, bb))

    def find(self, p):
        for i, bb in self.b.get((int(math.floor(p[0] / self.cell)), int(math.floor(p[1] / self.cell))), ()):
            if bb[0] <= p[0] <= bb[2] and bb[1] <= p[1] <= bb[3]:
                outer, holes = self.polys[i]
                if ring_contains(outer, p) and not any(ring_contains(h, p) for h in holes):
                    return i
        return None


def overture_metrics(doc, c, ov):
    osm = osm_cell(doc, c)
    frame = Frame(*c["center"])
    rect = osm["rect"]
    idx = PolyIndex([(f["outer"], f["holes"]) for f in osm["features"]])  # buildings and parts, in or out
    rows = []
    for r in ov["rows"]:
        if not r["outer"]:
            continue
        loc = [frame.xy(lat, lon) for lon, lat in r["outer"]]
        if len(loc) > 1 and loc[0] == loc[-1]:
            loc = loc[:-1]
        if len(loc) < 3:
            continue
        cx, cy = centroid(loc)
        if not (rect[0] <= cx <= rect[2] and rect[1] <= cy <= rect[3]):
            continue
        r["_c"] = (cx, cy)
        r["_area"] = abs(signed_area(loc))
        rows.append(r)
    n = len(rows)
    extra, extra_strict = [], []
    ds_extra, ds_strict = Counter(), Counter()
    height_src = Counter()
    for r in rows:
        dsets = {s["dataset"] for s in r["sources"]}
        geo = next((s["dataset"] for s in r["sources"] if s["property"] in ("", None)), r["sources"][0]["dataset"] if r["sources"] else None)
        r["_geo"] = geo
        if r["height"] is not None:
            # Explicit per-property source if present, else the feature's (geometry) source.
            height_src[next((s["dataset"] for s in r["sources"] if s["property"] == "/properties/height"), geo)] += 1
        if "OpenStreetMap" in dsets:
            continue
        extra.append(r)
        ds_extra[geo] += 1
        if idx.find(r["_c"]) is None:
            extra_strict.append(r)
            ds_strict[geo] += 1
    # Heights Overture adds to OSM buildings that lack height/levels (matched by OSM record id).
    osm_in = [f for f in osm["features"] if f["kind"] == "building" and f["in"]]
    missing_feats = [f for f in osm_in if not (has_height(f["tags"]) or has_levels(f["tags"]))]
    missing = {f["ref"] for f in missing_feats}
    filled_h, filled_f, filled_src = set(), set(), Counter()
    osm_versions = Counter(s.get("version") for r in rows for s in r["sources"] if s["dataset"] == "OpenStreetMap" and s.get("version"))
    for r in rows:
        for s in r["sources"]:
            if s["dataset"] == "OpenStreetMap" and s["property"] in ("", None) and s.get("record_id"):
                m = re.match(r"^([nwr])(\d+)", s["record_id"])
                if not m:
                    continue
                ref = {"n": "node", "w": "way", "r": "relation"}[m.group(1)] + "/" + m.group(2)
                if ref in missing:
                    if r["height"] is not None:
                        filled_h.add(ref)
                        hs = next((x["dataset"] for x in r["sources"] if x["property"] == "/properties/height"), "OpenStreetMap")
                        filled_src[hs] += 1
                    if r["num_floors"] is not None:
                        filled_f.add(ref)
    # OSM buildings with no Overture building at all (centroid test, either direction).
    areas = sorted(r["_area"] for r in extra)
    return {
        "release": OVERTURE_RELEASE, "files": len(ov["files"]),
        "overtureBuildings": n,
        "fromOSM": n - len(extra),
        "extraNoOSMSource": len(extra), "extraNoOSMSourceByDataset": dict(ds_extra.most_common()),
        "extraOutsideOSMFootprints": len(extra_strict), "extraOutsideByDataset": dict(ds_strict.most_common()),
        "extraMedianAreaM2": round(statistics.median(areas), 1) if areas else None,
        "extraShareUnder30m2": pct(sum(1 for a in areas if a < 30), len(areas)) if areas else None,
        "extraShareUnder60m2": pct(sum(1 for a in areas if a < 60), len(areas)) if areas else None,
        "extraPctNumFloors": pct(sum(1 for r in extra if r["num_floors"] is not None), len(extra)) if extra else None,
        "pctHeight": pct(sum(1 for r in rows if r["height"] is not None), n),
        "pctNumFloors": pct(sum(1 for r in rows if r["num_floors"] is not None), n),
        "pctHeightOrFloors": pct(sum(1 for r in rows if r["height"] is not None or r["num_floors"] is not None), n),
        "heightSourceDatasets": dict(height_src.most_common()),
        "extraPctHeight": pct(sum(1 for r in extra if r["height"] is not None), len(extra)) if extra else None,
        "pctRoofShape": pct(sum(1 for r in rows if r["roof_shape"]), n),
        "pctFacadeOrRoofColourMaterial": pct(sum(1 for r in rows if r["facade_color"] or r["facade_material"] or r["roof_color"] or r["roof_material"]), n),
        "osmMissingHeightOrLevels": len(missing_feats),
        "osmMissingFilledHeight": sum(1 for f in missing_feats if f["ref"] in filled_h),
        "osmMissingFilledFloors": sum(1 for f in missing_feats if f["ref"] in filled_f),
        "osmMissingFilledHeightPct": pct(sum(1 for f in missing_feats if f["ref"] in filled_h), len(missing_feats)),
        "osmSourceVersions": dict(osm_versions.most_common(3)),
        "osmMissingFilledHeightSource": dict(filled_src.most_common()),
    }


def step_overture(args):
    doc = load_cells()
    cells = [c for _, c in all_cells(doc) if c.get("center") and (not args.only or c["id"] in args.only)]
    rows = overture_rows(doc, cells)
    out = {}
    for c in cells:
        out[c["id"]] = overture_metrics(doc, c, rows[c["id"]])
        o = out[c["id"]]
        log(f"[overture] {c['id']}: {o['overtureBuildings']} bldgs, extra {o['extraNoOSMSource']} / strict {o['extraOutsideOSMFootprints']}, "
            f"height {o['pctHeight']}%, fills {o['osmMissingFilledHeightPct']}% of OSM gaps")
    p = os.path.join(RESULTS, "overture_metrics.json")
    prev = {}
    if args.only and os.path.exists(p):
        with open(p) as f:
            prev = json.load(f)
    prev.update(out)
    os.makedirs(RESULTS, exist_ok=True)
    with open(p, "w") as f:
        json.dump(prev, f, indent=1, sort_keys=True)


# ---------------------------------------------------------------------------------------------
# Triangle estimate (see trimodel.py)
# ---------------------------------------------------------------------------------------------

def area_kind(t):
    """Port of MapFeatureBuilder.areaKind (priority order)."""
    if t.get("natural") == "water" or t.get("waterway") == "riverbank" or "water" in t \
            or t.get("landuse") in ("reservoir", "basin"):
        return "water"
    if t.get("leisure") == "swimming_pool":
        return "pool"
    if t.get("man_made") == "pier":
        return "pier"
    if t.get("natural") == "wetland":
        return "wetland"
    if t.get("natural") in ("sand", "beach"):
        return "sand"
    if t.get("leisure") == "pitch":
        return "pitch"
    if t.get("leisure") == "playground":
        return "playground"
    if t.get("amenity") == "parking":
        return "parking"
    if t.get("highway") == "pedestrian" or ("highway" in t and t.get("area") == "yes"):
        return "pedestrianArea"
    if t.get("natural") == "wood" or t.get("landuse") == "forest":
        return "wood"
    if t.get("natural") == "scrub":
        return "scrub"
    if t.get("leisure") == "garden":
        return "garden"
    if t.get("landuse") in ("grass", "village_green"):
        return "grass"
    if t.get("landuse") == "meadow" or t.get("natural") == "grassland":
        return "meadow"
    if t.get("landuse") == "cemetery" or t.get("amenity") == "grave_yard":
        return "cemetery"
    if t.get("leisure") == "park":
        return "park"
    if t.get("leisure") in ("sports_centre", "recreation_ground", "common") or t.get("landuse") == "recreation_ground":
        return "recreation"
    if t.get("landuse") == "residential":
        return "residential"
    if t.get("landuse") in ("commercial", "retail"):
        return "commercial"
    return None


def point_kind(t):
    if t.get("natural") == "tree":
        return "tree"
    if t.get("amenity") == "bench" or t.get("leisure") == "bench":
        return "bench"
    if t.get("highway") == "street_lamp" or t.get("man_made") == "street_lamp":
        return "lamp"
    return "other" if t else None


def building_type(t):
    b = t.get("building")
    if b is not None and b != "no":
        return b
    p = t.get("building:part")
    if p is not None and p != "no":
        return "yes" if p == "yes" else p
    return None


def scene_features(elements, frame, rect):
    """MapFeatureBuilder-like classification for Overpass JSON in either `out body` + `>` form
    (node refs) or `out geom` form. Returns dict of lists in local metres."""
    import trimodel as tm
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in elements if e["type"] == "node" and "lat" in e}
    ways = {e["id"]: e for e in elements if e["type"] == "way"}

    def way_ll(w):
        if "geometry" in w:
            return [(g["lat"], g["lon"]) for g in w["geometry"] if g]
        return [nodes[n] for n in w.get("nodes", []) if n in nodes]

    out = {"buildings": [], "roads": [], "paths": [], "sidewalks": [], "areas": [], "points": []}
    inside = lambda p: rect[0] <= p[0] <= rect[2] and rect[1] <= p[1] <= rect[3]

    def polygon(ref, tags, outer, holes):
        bt = building_type(tags)
        if bt is not None:
            if not inside(centroid(outer)):
                return
            cp = clean_polygon(outer, holes)
            if cp:
                out["buildings"].append({"ref": ref, "tags": tags, "outer": cp[0], "holes": cp[1], "isPart": tags.get("building") is None})
            return
        k = area_kind(tags)
        if k:
            o = tm.clip_ring(outer, rect)
            if len(o) >= 3 and abs(signed_area(o)) >= 0.5:
                hs = [h for h in (tm.clip_ring(h, rect) for h in holes) if len(h) >= 3]
                out["areas"].append((k, o, hs))

    for wid in sorted(ways):
        w = ways[wid]
        tags = w.get("tags") or {}
        if not tags:
            continue
        ll = way_ll(w)
        if len(ll) < 2:
            continue
        pts = [frame.xy(*p) for p in ll]
        closed = ll[0] == ll[-1] and len(ll) >= 4
        is_area = tags.get("area") == "yes"
        if closed and not ("highway" in tags and not is_area) and tags.get("area") != "no":
            if building_type(tags) is not None or area_kind(tags):
                polygon(f"way/{wid}", tags, pts[:-1], [])
                continue
            pk = point_kind(tags)
            if pk in ("tree", "bench", "lamp"):
                c = centroid(pts[:-1])
                if inside(c):
                    out["points"].append((pk, c))
                continue
        if "highway" in tags and not is_area:
            kind = tm.hw_kind(tags["highway"])
            for piece in tm.clip_polyline(pts, rect):
                f = {"ref": f"way/{wid}", "kind": kind, "tags": tags, "line": piece, "width": tm.road_width(kind, tags)}
                if kind in tm.VEHICULAR:
                    out["roads"].append(f)
                elif tags.get("footway") == "sidewalk" or tags.get("path") == "sidewalk":
                    out["sidewalks"].append(f)
                else:
                    out["paths"].append(f)
    for rel in sorted((e for e in elements if e["type"] == "relation"), key=lambda e: e["id"]):
        tags = rel.get("tags") or {}
        if tags.get("type") not in ("multipolygon", "building"):
            continue
        if building_type(tags) is None and not area_kind(tags):
            continue
        ow, iw = [], []
        missing = False
        for m in rel.get("members", []):
            if m.get("type") != "way":
                continue
            if m.get("geometry"):
                ll = [(g["lat"], g["lon"]) for g in m["geometry"] if g]
            elif m["ref"] in ways:
                ll = way_ll(ways[m["ref"]])
            else:
                missing = True  # the engine fails the whole relation on a missing member
                continue
            (iw if m.get("role") == "inner" else ow).append(ll)
        ro, ri = (None, None) if missing else (assemble_rings(ow), assemble_rings(iw))
        if ro is None or ri is None:
            out["skippedRelations"] = out.get("skippedRelations", 0) + 1
            continue
        if tags.get("type") == "building" and building_type(tags) is not None:
            # Engine behaviour: a tagged type=building relation is assembled like a multipolygon,
            # so its outline and part members become extra building polygons.
            out["typeBuildingRelationsAssembled"] = out.get("typeBuildingRelationsAssembled", 0) + 1
        outers = [[frame.xy(*p) for p in r] for r in ro]
        inners = [[frame.xy(*p) for p in r] for r in ri]
        polys = [[o, []] for o in outers]
        for h in inners:
            cont = [i for i, (o, _) in enumerate(polys) if ring_contains(o, h[0])]
            if cont:
                i = min(cont, key=lambda i: abs(signed_area(polys[i][0])))
                polys[i][1].append(h)
        for o, hs in polys:
            polygon(f"relation/{rel['id']}", tags, o, hs)
    for e in elements:
        if e["type"] == "node" and e.get("tags"):
            pk = point_kind(e["tags"])
            if pk in ("tree", "bench", "lamp"):
                p = frame.xy(e["lat"], e["lon"])
                if inside(p):
                    out["points"].append((pk, p))
    return out


def wedge_hits_rect(cam, heading, half_fov, r, far=5000.0):
    """2-D test: does the horizontal view wedge (apex cam, direction heading, +-half_fov) meet
    rectangle r = (x0, y0, x1, y1)? Mirrors chunk-level frustum culling for a level camera."""
    if r[0] <= cam[0] <= r[2] and r[1] <= cam[1] <= r[3]:
        return True
    corners = [(r[0], r[1]), (r[2], r[1]), (r[2], r[3]), (r[0], r[3])]
    for c in corners:
        dx, dy = c[0] - cam[0], c[1] - cam[1]
        dist = math.hypot(dx, dy)
        if dist <= far:
            ang = math.atan2(dy, dx)
            d = (ang - heading + math.pi) % (2 * math.pi) - math.pi
            if abs(d) <= half_fov:
                return True
    # Wedge edges crossing the rectangle.
    import trimodel as tm
    for s in (-half_fov, 0.0, half_fov):
        a = heading + s
        end = (cam[0] + math.cos(a) * far, cam[1] + math.sin(a) * far)
        if tm.clip_segment(cam, end, r):
            return True
    return False


VIEW_HALF_FOV = math.atan(math.tan(math.radians(25)) * (9 / 19.5))  # 50 deg vertical, 9:19.5 portrait


def model_world(feats, rect, focus, profile, lod=0, floors_policy="engine", with_ground=True):
    """Counts triangles for a world built over `rect` with full detail in chunks meeting `focus`."""
    import trimodel as tm
    chunk = 200.0
    nx = int(math.ceil((rect[2] - rect[0]) / chunk - 1e-9))
    ny = int(math.ceil((rect[3] - rect[1]) / chunk - 1e-9))
    crect = {}
    for i in range(nx):
        for j in range(ny):
            crect[(i, j)] = (rect[0] + i * chunk, rect[1] + j * chunk, min(rect[2], rect[0] + (i + 1) * chunk), min(rect[3], rect[1] + (j + 1) * chunk))

    def intersects(a, b):
        return not (a[2] < b[0] or a[0] > b[2] or a[3] < b[1] or a[1] > b[3])
    detail = {k: ("full" if lod == 0 and intersects(r, focus) else "simple") for k, r in crect.items()}
    chunk_tris = Counter()
    parts = Counter()
    roles = defaultdict(lambda: Counter())
    bush_pos = []
    floors_hist = Counter()
    for b in feats["buildings"]:
        if b["isPart"]:
            continue
        c = centroid(b["outer"])
        k = (int(math.floor((c[0] - rect[0]) / chunk)), int(math.floor((c[1] - rect[1]) / chunk)))
        if k not in crect:
            continue
        res = tm.building_tris(b["ref"], b["tags"], b["outer"], b["holes"], profile, detail[k], floors_policy)
        chunk_tris[k] += res["total"]
        for kk, v in res["parts"].items():
            parts["bldg." + kk] += v
        rr = roles[res["role"]]
        rr["n"] += 1
        rr["tris"] += res["total"]
        rr["windowTris"] += res["parts"].get("windows", 0)
        rr["floors"] += res["floors"]
        rr["floorsFromOSM"] += int(res["floorsFromOSM"])
        if not res["floorsFromOSM"]:
            rr["untaggedN"] += 1
            rr["untaggedOneFloor"] += int(res["floors"] == 1)
            rr["untaggedFloors"] += res["floors"]
        if res["role"] in ("house", "block"):
            floors_hist[min(res["floors"], 99)] += 1
        bush_pos += [c] * res["bushes"]
    ground = Counter()
    lamps = 0
    if with_ground:
        _, gt, lamps = tm.ground_tris(feats["roads"], feats["paths"], feats["sidewalks"], feats["areas"],
                                      [b["outer"] for b in feats["buildings"]], rect, focus, chunk, lod,
                                      lamp_spots=[p for k, p in feats["points"] if k == "lamp"])
        for (k, label), v in gt.items():
            chunk_tris[k] += v
            ground[label] += v
    pts = Counter(k for k, _ in feats["points"])
    return {"chunks": crect, "detail": detail, "chunkTris": chunk_tris, "buildingParts": parts, "ground": ground,
            "roles": {k: dict(v) for k, v in roles.items()}, "bushes": bush_pos, "generatedLamps": lamps,
            "mappedLamps": pts["lamp"], "benches": pts["bench"], "floorsHist": dict(floors_hist),
            "trees": [p for k, p in feats["points"] if k == "tree"],
            "lampPos": [p for k, p in feats["points"] if k == "lamp"]}


def prop_view(positions, cam, heading, tris_by_lod, cell=400.0, half_fov=VIEW_HALF_FOV, max_dist=None):
    """Instanced LOD props as World.swift culls them: grouped per 400 m cell, one entity (bounds =
    all instances of that LOD bucket in the cell) per LOD; an entity is drawn whole if its bounds
    meet the view wedge. Returns (triangles in view, triangles total, instances per LOD)."""
    groups = defaultdict(list)
    near, mid = 45.0, 160.0
    total = 0
    counts = [0, 0, 0]
    for p in positions:
        d = math.dist(p, cam)
        lod = 0 if d < near else (1 if d < mid else 2)
        if max_dist is not None and d > max_dist:
            continue
        counts[lod] += 1
        groups[(int(math.floor(p[0] / cell)), int(math.floor(p[1] / cell)), lod)].append(p)
        total += tris_by_lod[lod]
    view = 0
    for (_, _, lod), ps in groups.items():
        xs, ys = [p[0] for p in ps], [p[1] for p in ps]
        r = (min(xs) - 8, min(ys) - 8, max(xs) + 8, max(ys) + 8)
        if wedge_hits_rect(cam, heading, half_fov, r):
            view += len(ps) * tris_by_lod[lod]
    return round(view), round(total), counts


def view_estimate(world, profile, cams, headings, tufts=200, tree_table=None):
    """Main-view triangles for each camera/heading: chunks meeting the wedge + LOD props +
    lamps/benches + tufts (World.estimateViewTriangles)."""
    import trimodel as tm
    trees = tm.tree_mix(profile, tree_table)
    rows = []
    for ci, cam in enumerate(cams):
        for h in headings:
            st = sum(t for k, t in world["chunkTris"].items() if wedge_hits_rect(cam, h, VIEW_HALF_FOV, world["chunks"][k]))
            tv, tt, tc = prop_view(world["trees"], cam, h, trees)
            bv, bt, _ = prop_view(world["bushes"], cam, h, tm.BUSH_TRIS)
            lamps = (world["generatedLamps"] + world["mappedLamps"]) * tm.LAMP_TRIS
            benches = world["benches"] * tm.BENCH_TRIS
            total = st + tv + bv + lamps + benches + tufts * tm.TUFT_TRIS + 2
            # Shadow casters: chunks meeting the 80 m shadow region (RealityKit maximumDistance 80),
            # trees/bushes whose LOD-bucket entity bounds meet it (entity-level culling).
            sh_static = sum(t for k, t in world["chunkTris"].items() if wedge_hits_rect(cam, h, VIEW_HALF_FOV, world["chunks"][k], far=80.0))
            sh_tv, _, _ = prop_view(world["trees"], cam, h, trees, half_fov=VIEW_HALF_FOV)
            sh_inst = round(sum(trees[0 if math.dist(p, cam) < 45 else 1] for p in world["trees"] if math.dist(p, cam) <= 80))
            rows.append({"static": st, "trees": tv, "bushes": bv, "lampsBenches": lamps + benches, "tufts": tufts * tm.TUFT_TRIS,
                         "total": total, "treeLodCounts": tc, "cam": ci, "heading": round(math.degrees(h)),
                         "shadowStaticChunks": sh_static, "shadowTreesEntity": sh_tv, "shadowTreesWithin80m": sh_inst})
    return rows


def profile_for(lat, lon, prof_dir, regions_path):
    import trimodel as tm
    with open(regions_path) as f:
        reg = json.load(f)
    pid = reg.get("defaultProfile", "default")
    for r in reg["regions"]:
        b = r["bounds"]
        if b["south"] <= lat <= b["north"] and b["west"] <= lon <= b["east"]:
            pid = r["profile"]
            break
    path = os.path.join(prof_dir, pid + ".json")
    return (tm.load_profile(path), pid) if os.path.exists(path) else (None, pid)


def ground_query(bbox):
    b = "(%.6f,%.6f,%.6f,%.6f)" % bbox
    return ('[out:json][timeout:180];\n'
            '(way["highway"]%s;way["leisure"]%s;way["landuse"]%s;way["amenity"="parking"]%s;way["natural"]%s;'
            'way["man_made"="pier"]%s;way["water"]%s;'
            'relation["type"="multipolygon"]["leisure"]%s;relation["type"="multipolygon"]["landuse"]%s;'
            'relation["type"="multipolygon"]["natural"]%s;relation["type"="multipolygon"]["amenity"="parking"]%s;);\n'
            'out geom;\n'
            'node["highway"="street_lamp"]%s;out count;out body;\n'
            'node["amenity"="bench"]%s;out count;out body;\n'
            'node["natural"="tree"]%s;out count;out skel qt;' % ((b,) * 14))


def cell_world(doc, c):
    """Buildings (from the osm step's cache) + ground layers (extra query) for one cell."""
    bbox = cell_bbox(doc, c)
    frame = Frame(*c["center"])
    sw, ne = frame.xy(bbox[0], bbox[1]), frame.xy(bbox[2], bbox[3])
    rect = cell_rect(doc)
    bdata, bmeta = overpass(osm_query(bbox))
    gdata, gmeta = overpass(ground_query(bbox))
    els = [e for e in bdata["elements"] if e["type"] != "count"]
    feats = scene_features(els, frame, rect)
    # Ground response: split node sections at the count separators.
    gel = gdata["elements"]
    ways_rels = [e for e in gel if e["type"] in ("way", "relation")]
    g = scene_features(ways_rels, frame, rect)
    sections, cur = [], None
    for e in gel:
        if e["type"] == "count":
            cur = []
            sections.append(cur)
        elif e["type"] == "node" and cur is not None:
            cur.append(e)
    pts = []
    for kind, sec in zip(("lamp", "bench", "tree"), sections):
        for e in sec:
            p = frame.xy(e["lat"], e["lon"])
            if rect[0] <= p[0] <= rect[2] and rect[1] <= p[1] <= rect[3]:
                pts.append((kind, p))
    for k in ("roads", "paths", "sidewalks", "areas"):
        feats[k] = g[k]
    feats["points"] = pts
    return feats, rect, {"buildings": bmeta.get("timestamp_osm_base"), "ground": gmeta.get("timestamp_osm_base")}


def overture_extra_buildings(doc, c, frame, feats):
    """Overture buildings with no OSM source whose centroid is in no OSM footprint, as generator
    inputs: building=yes, height = Overture height. Uses the cached overture step data only."""
    bbox = cell_bbox(doc, c)
    key = hashlib.sha256(f"{OVERTURE_RELEASE}|{bbox}".encode()).hexdigest()[:24]
    p = cache_path("overture", f"{c['id']}-{key}.json.gz")
    if not os.path.exists(p):
        return []
    with gzip.open(p, "rb") as f:
        rows = json.loads(f.read())["rows"]
    idx = PolyIndex([(b["outer"], b["holes"]) for b in feats["buildings"]])
    out = []
    for r in rows:
        if not r["outer"] or any(s["dataset"] == "OpenStreetMap" for s in r["sources"]):
            continue
        loc = [frame.xy(lat, lon) for lon, lat in r["outer"]]
        if len(loc) > 1 and loc[0] == loc[-1]:
            loc = loc[:-1]
        cp = clean_polygon(loc, []) if len(loc) >= 3 else None
        if not cp or idx.find(centroid(cp[0])) is not None:
            continue
        tags = {"building": "yes"}
        if r["height"] is not None:
            tags["height"] = str(round(r["height"], 1))
        if r["num_floors"] is not None:
            tags["building:levels"] = str(r["num_floors"])
        out.append({"ref": "way/%d" % (int(hashlib.sha256(r["id"].encode()).hexdigest()[:15], 16)),
                    "tags": tags, "outer": cp[0], "holes": cp[1], "isPart": False})
    return out


def summarize_world(w, rows):
    tot_static = sum(w["chunkTris"].values())
    bparts = w["buildingParts"]
    return {
        "staticTotal": tot_static,
        "curbSharePct": round(100 * w["ground"].get("curbs", 0) / tot_static, 1) if tot_static else None,
        "buildingTris": sum(bparts.values()),
        "buildingParts": dict(bparts),
        "groundTris": dict(w["ground"]),
        "roles": w["roles"],
        "floorsHist": w["floorsHist"],
        "trees": len(w["trees"]), "bushes": len(w["bushes"]),
        "lamps": w["generatedLamps"] + w["mappedLamps"], "generatedLamps": w["generatedLamps"], "benches": w["benches"],
        "view": {
            "n": len(rows),
            "totalMean": round(statistics.mean(r["total"] for r in rows)),
            "totalP90": sorted(r["total"] for r in rows)[int(0.9 * (len(rows) - 1))],
            "totalMax": max(r["total"] for r in rows),
            "totalMin": min(r["total"] for r in rows),
            "staticMean": round(statistics.mean(r["static"] for r in rows)),
            "treesMean": round(statistics.mean(r["trees"] for r in rows)),
            "bushesMean": round(statistics.mean(r["bushes"] for r in rows)),
            "lampsBenches": rows[0]["lampsBenches"], "tufts": rows[0]["tufts"],
            "shadowStaticMean": round(statistics.mean(r["shadowStaticChunks"] for r in rows)),
            "shadowStaticMax": max(r["shadowStaticChunks"] for r in rows),
            "shadowTreesEntityMean": round(statistics.mean(r["shadowTreesEntity"] for r in rows)),
            "shadowTreesWithin80mMean": round(statistics.mean(r["shadowTreesWithin80m"] for r in rows)),
        },
        # Camera at the cell centre (chunk 2,2), all 8 headings.
        "viewCentre": {
            "totalMean": round(statistics.mean(r["total"] for r in rows if r["cam"] == 12)),
            "totalMax": max(r["total"] for r in rows if r["cam"] == 12),
            "staticMean": round(statistics.mean(r["static"] for r in rows if r["cam"] == 12)),
            "staticMax": max(r["static"] for r in rows if r["cam"] == 12),
            "treesMean": round(statistics.mean(r["trees"] for r in rows if r["cam"] == 12)),
            "bushesMean": round(statistics.mean(r["bushes"] for r in rows if r["cam"] == 12)),
            "shadowStaticMean": round(statistics.mean(r["shadowStaticChunks"] for r in rows if r["cam"] == 12)),
        },
        "chunkTrisMax": max(w["chunkTris"].values()) if w["chunkTris"] else 0,
    }


def step_tris(args):
    import trimodel as tm
    prof_dir = os.path.join(REPO, "Sources", "WorldGen", "Profiles")
    regions = os.path.join(prof_dir, "regions.json")
    out = {"method": "trimodel.py port of the generator's triangle counting; see docs/research/data-coverage.md"}

    # 1. Calibration: Sloan's Lake area B with the WorldLab demo focus vs the recorded package
    #    (docs/package-format.md: lod0 258,769, lod1 100,197) and the matched-run header
    #    (278,817 = static + 2 boundary + lamps + benches before tree LODs are bucketed).
    area = os.path.join(REPO, "Data", "areas", "sloans-lake")
    with open(os.path.join(area, "manifest.json")) as f:
        man = json.load(f)
    with open(os.path.join(REPO, "Apps", "WorldLab", "Resources", "demo.json")) as f:
        demo = json.load(f)
    with open(os.path.join(area, "osm.json")) as f:
        sl = json.load(f)
    lat0, lon0 = man["center"]["latitude"], man["center"]["longitude"]
    frame = Frame(lat0, lon0)
    rect = (-man["widthMeters"] / 2, -man["heightMeters"] / 2, man["widthMeters"] / 2, man["heightMeters"] / 2)
    def local_rect(fz):
        a, b = frame.xy(fz["south"], fz["west"]), frame.xy(fz["north"], fz["east"])
        return (min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
    # The recorded package and the 278,817 header used WorldLab's focus as of commit b76580c;
    # phase 5A (772ff24) widened demo.json's focus, and its gate runs record 401,965.
    focus = local_rect(RECORDED_FOCUS_B76580C)
    focus_now = local_rect(demo["focus"])
    feats = scene_features(sl["elements"], frame, rect)
    prof, pid = profile_for(lat0, lon0, prof_dir, regions)
    w0 = model_world(feats, rect, focus, prof, lod=0)
    w1 = model_world(feats, rect, focus, prof, lod=1)
    s0, s1 = sum(w0["chunkTris"].values()), sum(w1["chunkTris"].values())
    lamps = w0["generatedLamps"] + w0["mappedLamps"]
    out["calibration"] = {
        "area": "sloans-lake (1600 x 1200 m), WorldLab demo focus", "profile": pid,
        "modelLod0": s0, "recordedLod0": 258769, "lod0Error": round(s0 / 258769 - 1, 3),
        "modelLod1": s1, "recordedLod1": 100197, "lod1Error": round(s1 / 100197 - 1, 3),
        "modelBuildingsLod0": sum(w0["buildingParts"].values()), "modelBuildingsLod1": sum(w1["buildingParts"].values()),
        "groundLod0": dict(w0["ground"]), "groundLod1": dict(w1["ground"]),
        "modelLamps": lamps, "recordedLamps": 157, "benches": w0["benches"],
        "modelHeader": s0 + 2 + lamps * tm.LAMP_TRIS + w0["benches"] * tm.BENCH_TRIS, "recordedHeader": 278817,
        "roles": w0["roles"],
        "osmTimestamp": sl.get("osm3s", {}).get("timestamp_osm_base"),
        # Mapped natural=tree points inside the 1600 x 1200 m area (no source tag in the extract).
        "mappedTrees": len(w0["trees"]),
        "mappedTreesPerKm2": round(len(w0["trees"]) / ((rect[2] - rect[0]) * (rect[3] - rect[1]) / 1e6), 1),
        "drawCallsRecorded": "108 (docs/perf/m2-matched/realitykit-*-summary.json header, drawCalls=108)",
        "focus": RECORDED_FOCUS_B76580C,
    }
    wn = model_world(feats, rect, focus_now, prof, lod=0)
    sn = sum(wn["chunkTris"].values())
    ln = wn["generatedLamps"] + wn["mappedLamps"]
    out["calibration"]["currentFocus"] = {
        "focus": demo["focus"], "modelLod0": sn, "modelLamps": ln,
        "modelHeader": sn + 2 + ln * tm.LAMP_TRIS + wn["benches"] * tm.BENCH_TRIS, "recordedHeader": 401965,
        "recordedIn": "docs/perf/m3-phase5a-gate/realitykit-20261005-231905-summary.json (and -232127), drawCalls=109",
    }
    # View check: cameras along the WorldLab walking loop, looking along the walk (street-follow
    # camera), vs the M2 report's "a street view submits 169-276k triangles".
    route = [frame.xy(p["lat"], p["lon"]) for p in demo["route"]]
    cams, heads, acc = [], [], 0.0
    for p, q in zip(route, route[1:]):
        acc += math.dist(p, q)
        if acc >= 40 and math.dist(p, q) > 0.5:
            cams.append(p)
            heads.append(math.atan2(q[1] - p[1], q[0] - p[0]))
            acc = 0.0
    for label, table in (("routeViewPre5ATrees", tm.TREE_TRIS_PRE_5A), ("routeView", None)):
        vrows = []
        for cam, h in zip(cams, heads):
            vrows += view_estimate(w0, prof, [cam], [h], tree_table=table)
        tot = sorted(r["total"] for r in vrows)
        out["calibration"][label] = {
            "cameras": len(vrows), "min": tot[0], "p10": tot[int(0.1 * (len(tot) - 1))], "median": tot[len(tot) // 2],
            "p90": tot[int(0.9 * (len(tot) - 1))], "max": tot[-1],
            "recordedRange": [169000, 276000] if table else "none recorded with phase 5A trees",
            "staticMedian": sorted(r["static"] for r in vrows)[len(vrows) // 2],
            "treesMedian": sorted(r["trees"] for r in vrows)[len(vrows) // 2],
            "bushesMedian": sorted(r["bushes"] for r in vrows)[len(vrows) // 2],
            "treeTrisPerLod": [round(x, 1) for x in tm.tree_mix(prof, table)],
        }
    log("[tris] calibration", json.dumps({k: v for k, v in out["calibration"].items() if k not in ("roles", "groundLod0", "groundLod1")}))

    # 2. Cells: buildings-only model for every cell (full detail everywhere), and full worlds
    #    (ground + props + view) for the dense cells chosen with --dense (default: Chicago's
    #    two largest building-triangle totals plus the densest neighbourhood cell).
    doc = load_cells()
    zone_dir = args.zone_profiles
    zone_catalog = None
    if zone_dir and os.path.exists(os.path.join(zone_dir, "region-catalog.json")):
        zone_catalog = os.path.join(zone_dir, "region-catalog.json")
    per_cell = {}
    for m, c in all_cells(doc):
        if not c.get("center"):
            continue
        if args.only and c["id"] not in args.only:
            continue
        bbox = cell_bbox(doc, c)
        data, _ = overpass(osm_query(bbox))
        fr = Frame(*c["center"])
        sw, ne = fr.xy(bbox[0], bbox[1]), fr.xy(bbox[2], bbox[3])
        crect = cell_rect(doc)
        cf = scene_features([e for e in data["elements"] if e["type"] != "count"], fr, crect)
        prof, pid = profile_for(c["center"][0], c["center"][1], prof_dir, regions)
        res = {"profile": pid}
        for policy in ("engine", "height"):
            wf = model_world(cf, crect, crect, prof, lod=0, floors_policy=policy, with_ground=False)
            ws = model_world(cf, crect, crect, prof, lod=1, floors_policy=policy, with_ground=False)
            res[policy] = {"full": sum(wf["chunkTris"].values()), "simple": sum(ws["chunkTris"].values()),
                           "windowTris": wf["buildingParts"].get("bldg.windows", 0), "roles": wf["roles"]}
        zprof = None
        if zone_catalog:
            zprof, zid = profile_for(c["center"][0], c["center"][1], os.path.join(zone_dir, "profiles"), zone_catalog)
            if zprof:
                wf = model_world(cf, crect, crect, zprof, lod=0, with_ground=False)
                res["zoneProfile"] = {"id": zid, "full": sum(wf["chunkTris"].values()),
                                      "windowTris": wf["buildingParts"].get("bldg.windows", 0), "roles": wf["roles"]}
        # Same cell with Overture's extra footprints added (building=yes, Overture height as `height`).
        extra = overture_extra_buildings(doc, c, fr, cf)
        if extra:
            cfo = dict(cf)
            cfo["buildings"] = cf["buildings"] + extra
            wf = model_world(cfo, crect, crect, prof, lod=0, with_ground=False)
            ws = model_world(cfo, crect, crect, prof, lod=1, with_ground=False)
            res["withOverture"] = {"extraBuildings": len(extra), "full": sum(wf["chunkTris"].values()),
                                   "simple": sum(ws["chunkTris"].values()), "roles": wf["roles"]}
            if zprof:
                wz = model_world(cfo, crect, crect, zprof, lod=0, with_ground=False)
                res["withOverture"]["zoneFull"] = sum(wz["chunkTris"].values())
        per_cell[c["id"]] = res
        log(f"[tris] {c['id']}: full {res['engine']['full']:,} simple {res['engine']['simple']:,} ({pid})"
            + (f" zone {res['zoneProfile']['id']} {res['zoneProfile']['full']:,}" if "zoneProfile" in res else ""))
    out["cellsBuildingsOnly"] = per_cell

    # 3. Dense cells: full worlds.
    dense = args.dense or []
    worlds = {}
    for m, c in all_cells(doc):
        if c["id"] not in dense:
            continue
        feats, crect, ts = cell_world(doc, c)
        variants = [("current", profile_for(c["center"][0], c["center"][1], prof_dir, regions))]
        if zone_catalog:
            zp = profile_for(c["center"][0], c["center"][1], os.path.join(zone_dir, "profiles"), zone_catalog)
            if zp[0]:
                variants.append(("zone", zp))
        # Cameras: 5 x 5 grid of street positions (the chunk centres) x 8 headings.
        cams = [(crect[0] + 100 + 200 * i, crect[1] + 100 + 200 * j) for i in range(5) for j in range(5)]
        heads = [k * math.pi / 4 for k in range(8)]
        cx, cy = (crect[0] + crect[2]) / 2, (crect[1] + crect[3]) / 2
        # WorldLab-sized focus (470 x 600 m, as the recorded Sloan's Lake focus), centred; 1 cm short of the
        # chunk lines at +-300 m so it selects the central 3 x 3 chunks (Rect2D.intersects counts touching).
        demo_focus = (cx - 235, cy - 299.99, cx + 235, cy + 299.99)
        res = {"osmTimestamps": ts}
        for vname, (prof, pid) in variants:
            for fname, fo in (("focusWholeCell", crect), ("focusDemoSize", demo_focus)):
                wv = model_world(feats, crect, fo, prof, lod=0)
                rows = view_estimate(wv, prof, cams, heads)
                res[f"{vname}:{pid}:{fname}"] = summarize_world(wv, rows)
                log(f"[tris] {c['id']} {vname}:{pid}:{fname}: static {res[f'{vname}:{pid}:{fname}']['staticTotal']:,} "
                    f"view mean {res[f'{vname}:{pid}:{fname}']['view']['totalMean']:,} max {res[f'{vname}:{pid}:{fname}']['view']['totalMax']:,}")
            # What-if (not current behaviour): per-camera chunk LOD by distance, v2 §8.1 style:
            # full detail for chunks within 150 m of the camera, the existing lod1 beyond.
            wfull = model_world(feats, crect, crect, prof, lod=0)
            wsimp = model_world(feats, crect, crect, prof, lod=1)
            totals = []
            for cam in cams:
                mixed = dict(wfull)
                ct = Counter()
                for k, r in wfull["chunks"].items():
                    dx = max(r[0] - cam[0], 0, cam[0] - r[2])
                    dy = max(r[1] - cam[1], 0, cam[1] - r[3])
                    ct[k] = wfull["chunkTris"][k] if math.hypot(dx, dy) <= 150 else wsimp["chunkTris"][k]
                mixed["chunkTris"] = ct
                totals += [rw["total"] for rw in view_estimate(mixed, prof, [cam], heads)]
            totals.sort()
            res[f"{vname}:{pid}:whatIfDistanceLod150m"] = {
                "viewMean": round(statistics.mean(totals)), "viewP90": totals[int(0.9 * (len(totals) - 1))],
                "viewMax": totals[-1], "note": "full chunks within 150 m of the camera, lod1 beyond; props as current"}
            log(f"[tris] {c['id']} {vname}:{pid}:whatIfDistanceLod150m: view mean {round(statistics.mean(totals)):,} max {totals[-1]:,}")
        worlds[c["id"]] = res
    out["denseWorlds"] = worlds
    os.makedirs(RESULTS, exist_ok=True)
    p = os.path.join(RESULTS, "triangles.json")
    prev = {}
    if os.path.exists(p):
        with open(p) as f:
            prev = json.load(f)
    if args.only and "cellsBuildingsOnly" in prev:
        prev["cellsBuildingsOnly"].update(out["cellsBuildingsOnly"])
        out["cellsBuildingsOnly"] = prev["cellsBuildingsOnly"]
    if not dense and "denseWorlds" in prev:
        out["denseWorlds"] = prev["denseWorlds"]
    with open(p, "w") as f:
        json.dump(out, f, indent=1, sort_keys=True)


# ---------------------------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------------------------

def _fmt(v, nd=0):
    if v is None:
        return "–"
    if isinstance(v, float):
        return f"{v:,.{nd}f}"
    if isinstance(v, int):
        return f"{v:,d}"
    return str(v)


def step_report(args):
    doc = load_cells()
    with open(os.path.join(RESULTS, "osm_metrics.json")) as f:
        om = json.load(f)
    ov = {}
    p = os.path.join(RESULTS, "overture_metrics.json")
    if os.path.exists(p):
        with open(p) as f:
            ov = json.load(f)
    rows = []
    for m, c in all_cells(doc):
        if c["id"] not in om:
            continue
        o, v = om[c["id"]], ov.get(c["id"], {})
        rows.append({
            "region": c["region"], "tier": c["tier"], "cell": c["id"], "place": c["place"],
            "anchor": (c.get("resolved") or {}).get("matchedTags", {}).get("name"), "anchorOsm": c.get("osm"),
            "lat": c["center"][0], "lon": c["center"][1],
            "buildings": o["buildings"], "buildingsPerKm2": o["buildingsPerKm2"],
            "pctHeightOrLevels": o["pctHeightOrLevels"], "pctHeight": o["pctHeight"], "pctLevels": o["pctLevels"],
            "pctRoofShape": o["pctRoofShape"], "pctMaterialOrColour": o["pctMaterialOrColour"],
            "pctRoofColourOrMaterial": o["pctRoofColourOrMaterial"],
            "trees": o["trees"], "treesPerKm2": o["treesPerKm2"], "treeRows": o["treeRows"],
            "buildingParts": o["buildingParts"], "partsWithHeightOrLevels": o["partsWithHeightOrLevels"],
            "footprintMedianM2": o["footprintMedianM2"], "footprintCoveragePct": o["footprintCoveragePct"],
            "levelsMedian": o["levelsMedian"], "levelsMax": o["levelsMax"], "heightMax": o["heightMax"],
            "tall10LevelsOr32m": o["tallCount10Levels"],
            "houses": o["roles"].get("house", 0), "housesWithHeightOrLevels": o["roleHeightOrLevels"].get("house", 0),
            "blocks": o["roles"].get("block", 0), "blocksWithHeightOrLevels": o["roleHeightOrLevels"].get("block", 0),
            "garages": o["roles"].get("garage", 0), "sheds": o["roles"].get("shed", 0),
            "osmTimestamp": o["osmTimestamp"],
            "overtureBuildings": v.get("overtureBuildings"), "overtureFromOSM": v.get("fromOSM"),
            "overtureExtraNoOSMSource": v.get("extraNoOSMSource"), "overtureExtraOutsideOSM": v.get("extraOutsideOSMFootprints"),
            "overtureExtraDatasets": "; ".join(f"{k} {n}" for k, n in (v.get("extraNoOSMSourceByDataset") or {}).items()),
            "overtureExtraMedianAreaM2": v.get("extraMedianAreaM2"),
            "overturePctHeight": v.get("pctHeight"), "overturePctNumFloors": v.get("pctNumFloors"),
            "overtureHeightSources": "; ".join(f"{k} {n}" for k, n in (v.get("heightSourceDatasets") or {}).items()),
            "osmMissingHeightOrLevels": v.get("osmMissingHeightOrLevels"),
            "overtureFillsOsmHeightPct": v.get("osmMissingFilledHeightPct"),
            "overtureFillsOsmHeightSources": "; ".join(f"{k} {n}" for k, n in (v.get("osmMissingFilledHeightSource") or {}).items()),
            "overtureExtraPctHeight": v.get("extraPctHeight"),
            "overturePctRoofShape": v.get("pctRoofShape"),
        })
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, "cells.csv"), "w", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        wr.writeheader()
        wr.writerows(rows)
    # Markdown main table.
    lines = ["| Region | Cell (anchor) | Centre | Buildings | per km² | % height or levels | % roof:shape | % material or colour | Trees per km² | Overture extras: no OSM source / outside OSM footprints | building:part |",
             "|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for r in rows:
        lines.append(f"| {r['region']} | {r['place']} ({r['anchor']}) | {r['lat']:.4f}, {r['lon']:.4f} | {_fmt(r['buildings'])} | "
                     f"{_fmt(r['buildingsPerKm2'])} | {_fmt(r['pctHeightOrLevels'], 1)} | {_fmt(r['pctRoofShape'], 1)} | "
                     f"{_fmt(r['pctMaterialOrColour'], 1)} | {_fmt(r['treesPerKm2'])} | "
                     f"{_fmt(r['overtureExtraNoOSMSource'])} / {_fmt(r['overtureExtraOutsideOSM'])} | {_fmt(r['buildingParts'])} |")
    with open(os.path.join(RESULTS, "main_table.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    # Detail table: the split, roof colour/material, and what Overture adds.
    def short(ds):
        return (ds or "").replace("Microsoft ML Buildings", "MS").replace("Esri Community Maps", "Esri").replace("USGS Lidar", "USGS").replace("OpenStreetMap", "OSM")
    lines = ["| Cell | % height | % levels | % roof colour or material | Overture buildings | Overture % height | Overture % floors | OSM buildings missing height/levels | … that Overture gives a height (source) | Extras by source (median area m²) |",
             "|---|---:|---:|---:|---:|---:|---:|---:|---|---|"]
    for r in rows:
        v = ov.get(r["cell"], {})
        fills = f"{_fmt(v.get('osmMissingFilledHeightPct'), 1)}% ({short(r['overtureFillsOsmHeightSources'])})" if v else "–"
        lines.append(f"| {r['place']} | {_fmt(r['pctHeight'], 1)} | {_fmt(r['pctLevels'], 1)} | {_fmt(r['pctRoofColourOrMaterial'], 1)} | "
                     f"{_fmt(v.get('overtureBuildings'))} | {_fmt(v.get('pctHeight'), 1)} | {_fmt(v.get('pctNumFloors'), 1)} | "
                     f"{_fmt(v.get('osmMissingHeightOrLevels'))} | {fills} | {short(r['overtureExtraDatasets']) or '–'}"
                     f"{' (' + _fmt(v.get('extraMedianAreaM2')) + ')' if v.get('extraMedianAreaM2') else ''} |")
    with open(os.path.join(RESULTS, "detail_table.md"), "w") as f:
        f.write("\n".join(lines) + "\n")
    # Aggregates by tier (building-weighted), for the gap ranking.
    tiers = defaultdict(Counter)
    for r in rows:
        o, v = om[r["cell"]], ov.get(r["cell"], {})
        t = tiers[r["tier"]]
        n = o["buildings"]
        t["cells"] += 1
        t["buildings"] += n
        for k in ("pctHeightOrLevels", "pctHeight", "pctLevels", "pctRoofShape", "pctMaterialOrColour", "pctRoofColourOrMaterial"):
            t[k] += (o[k] or 0) * n / 100
        t["houses"] += o["roles"].get("house", 0)
        t["housesHL"] += o["roleHeightOrLevels"].get("house", 0)
        t["blocks"] += o["roles"].get("block", 0)
        t["blocksHL"] += o["roleHeightOrLevels"].get("block", 0)
        t["trees"] += o["trees"] or 0
        t["parts"] += o["buildingParts"]
        t["smallYes"] += o["smallYesNoLevels"]
        t["ovBuildings"] += v.get("overtureBuildings") or 0
        t["ovExtra"] += v.get("extraNoOSMSource") or 0
        t["ovExtraStrict"] += v.get("extraOutsideOSMFootprints") or 0
        t["ovHeight"] += (v.get("pctHeight") or 0) * (v.get("overtureBuildings") or 0) / 100
        t["ovFloors"] += (v.get("pctNumFloors") or 0) * (v.get("overtureBuildings") or 0) / 100
        t["osmMissingHL"] += v.get("osmMissingHeightOrLevels") or 0
        t["osmMissingFilled"] += v.get("osmMissingFilledHeight") or 0
        for ds, k in (v.get("extraNoOSMSourceByDataset") or {}).items():
            t["ovExtra:" + ds] += k
    summary = {}
    for tier, t in tiers.items():
        b = t["buildings"]
        summary[tier] = {
            "cells": t["cells"], "osmBuildings": b,
            **{k: round(100 * t[k] / b, 1) if b else None for k in ("pctHeightOrLevels", "pctHeight", "pctLevels", "pctRoofShape", "pctMaterialOrColour", "pctRoofColourOrMaterial")},
            "housesPctHeightOrLevels": round(100 * t["housesHL"] / t["houses"], 1) if t["houses"] else None,
            "blocksPctHeightOrLevels": round(100 * t["blocksHL"] / t["blocks"], 1) if t["blocks"] else None,
            "treesPerKm2": round(t["trees"] / t["cells"], 1), "buildingParts": t["parts"],
            "smallYesNoLevels": t["smallYes"], "smallYesNoLevelsPct": round(100 * t["smallYes"] / b, 1) if b else None,
            "overtureBuildings": t["ovBuildings"], "overtureExtra": t["ovExtra"], "overtureExtraStrict": t["ovExtraStrict"],
            "overtureExtraShareOfOverture": round(100 * t["ovExtra"] / t["ovBuildings"], 1) if t["ovBuildings"] else None,
            "overturePctHeight": round(100 * t["ovHeight"] / t["ovBuildings"], 1) if t["ovBuildings"] else None,
            "overturePctNumFloors": round(100 * t["ovFloors"] / t["ovBuildings"], 1) if t["ovBuildings"] else None,
            "osmMissingHeightOrLevels": t["osmMissingHL"],
            "overtureFillsPct": round(100 * t["osmMissingFilled"] / t["osmMissingHL"], 1) if t["osmMissingHL"] else None,
            "overtureExtraByDataset": {k.split(":", 1)[1]: v for k, v in t.items() if k.startswith("ovExtra:")},
        }
    ns_roofs = Counter()
    for r in rows:
        if r["tier"] == "north-shore":
            ns_roofs.update(om[r["cell"]]["roofShapes"])
    summary["_northShoreRoofShapes"] = dict(ns_roofs.most_common())
    # Overall and special-purpose aggregates quoted in docs/research/data-coverage.md.
    tierof = {r["cell"]: r["tier"] for r in rows}
    N = sum(om[c]["buildings"] for c in tierof)
    allv = [ov[c] for c in tierof if c in ov]
    fills, hsrc, vers = Counter(), Counter(), Counter()
    for v in allv:
        fills.update(v.get("osmMissingFilledHeightSource") or {})
        hsrc.update(v.get("heightSourceDatasets") or {})
        vers.update(v.get("osmSourceVersions") or {})
    miss = sum(v["osmMissingHeightOrLevels"] for v in allv)
    filled = sum(v["osmMissingFilledHeight"] for v in allv)
    summary["_all"] = {
        "cells": len(tierof), "osmBuildings": N,
        **{k: round(sum((om[c][k] or 0) * om[c]["buildings"] / 100 for c in tierof) * 100 / N, 1)
           for k in ("pctHeightOrLevels", "pctHeight", "pctLevels", "pctRoofShape", "pctMaterialOrColour", "pctRoofColourOrMaterial")},
        "houses": sum(om[c]["roles"].get("house", 0) for c in tierof),
        "housesWithHeightOrLevels": sum(om[c]["roleHeightOrLevels"].get("house", 0) for c in tierof),
        "buildingParts": sum(om[c]["buildingParts"] for c in tierof),
        "partsWithHeightOrLevels": sum(om[c]["partsWithHeightOrLevels"] for c in tierof),
        "buildingsFromRelations": sum(om[c]["fromRelations"] for c in tierof),
        "partsFromRelations": sum(om[c]["partsFromRelations"] for c in tierof),
        "dupWayAlsoRelationOuter": sum(om[c]["dupWayAlsoRelationOuter"] for c in tierof),
        "overtureBuildings": sum(v["overtureBuildings"] for v in allv),
        "overtureExtra": sum(v["extraNoOSMSource"] for v in allv),
        "overtureExtraStrict": sum(v["extraOutsideOSMFootprints"] for v in allv),
        "overtureExtraByDataset": dict(sum((Counter(v["extraNoOSMSourceByDataset"]) for v in allv), Counter())),
        "cellsWithEsriExtras": sum(1 for v in allv if "Esri Community Maps" in v["extraNoOSMSourceByDataset"]),
        "cellsWhereStrictDiffers": [c for c in tierof if c in ov and ov[c]["extraNoOSMSource"] != ov[c]["extraOutsideOSMFootprints"]],
        "overtureHeights": sum(hsrc.values()), "overtureHeightSources": dict(hsrc.most_common()),
        "overturePctHeight": round(100 * sum(hsrc.values()) / sum(v["overtureBuildings"] for v in allv), 1) if allv else None,
        "osmMissingHeightOrLevels": miss, "overtureFillsHeight": filled,
        "overtureFillsPct": round(100 * filled / miss, 1) if miss else None, "overtureFillSources": dict(fills.most_common()),
        "overtureFillsFloors": sum(v["osmMissingFilledFloors"] for v in allv),
        "extrasWithFloors": sum(round((v.get("extraPctNumFloors") or 0) * v["extraNoOSMSource"] / 100) for v in allv),
        "overtureOsmSourceVersions": dict(vers.most_common()),
    }
    # Suburban cells without a municipal height import (pctHeight < 50).
    sub = [c for c in tierof if tierof[c] in ("inner-suburb", "outer-suburb")]
    noimp = [c for c in sub if (om[c]["pctHeight"] or 0) < 50]
    per = {c: [om[c]["roles"].get("house", 0), om[c]["roleHeightOrLevels"].get("house", 0)] for c in noimp}
    h, hl = sum(x[0] for x in per.values()), sum(x[1] for x in per.values())
    top = max(per, key=lambda c: per[c][1]) if per else None
    summary["_suburbsWithoutHeightImport"] = {
        "cells": len(noimp), "houses": h, "housesWithHeightOrLevels": hl, "pct": round(100 * hl / h, 1) if h else None,
        "heightImportCells": [c for c in sub if c not in noimp],
        "largestContributor": top, "largestContributorHousesWithHeightOrLevels": per[top][1] if top else None,
        "pctWithoutLargest": round(100 * (hl - per[top][1]) / (h - per[top][0]), 1) if top else None,
        "perCell": per,
    }
    chi = [c for c in tierof if tierof[c] in ("chicago-downtown", "chicago-neighbourhood") and c in ov]
    summary["_chicagoOvertureExtraShare"] = {c: round(100 * ov[c]["extraNoOSMSource"] / ov[c]["overtureBuildings"], 1) for c in chi}
    nb = [c for c in tierof if tierof[c] == "chicago-neighbourhood"]
    summary["_chicagoSmallYesNoLevels"] = {
        "definition": "building=yes outlines under 60 m2 without building:levels, as a share of all OSM buildings in the cell; no road test",
        "count": sum(om[c]["smallYesNoLevels"] for c in nb), "buildings": sum(om[c]["buildings"] for c in nb),
        "pct": round(100 * sum(om[c]["smallYesNoLevels"] for c in nb) / sum(om[c]["buildings"] for c in nb), 1),
        "perCell": {c: om[c]["smallYesNoLevels"] for c in nb},
    }
    tp = os.path.join(RESULTS, "triangles.json")
    if os.path.exists(tp):
        with open(tp) as f:
            tri = json.load(f)
        bo = tri.get("cellsBuildingsOnly", {})
        n1 = sum(bo[c]["engine"]["roles"].get("house", {}).get("untaggedOneFloor", 0) for c in noimp if c in bo)
        nn = sum(bo[c]["engine"]["roles"].get("house", {}).get("untaggedN", 0) for c in noimp if c in bo)
        summary["_untaggedHousesOneStorey"] = {
            "scope": "houses without building:levels in the suburban cells without a height import, triangle model with the bundled profiles",
            "oneStorey": n1, "untagged": nn, "pct": round(100 * n1 / nn, 1) if nn else None,
            "natick": bo.get("natick-common", {}).get("engine", {}).get("roles", {}).get("house"),
        }
        summary["_simplePerBuildingDense"] = {c: round(bo[c]["engine"]["simple"] / om[c]["buildings"], 1)
                                             for c in tri.get("denseWorlds", {}) if c in bo}
    with open(os.path.join(RESULTS, "summary.json"), "w") as f:
        json.dump(summary, f, indent=1, sort_keys=True)
    log(f"[report] {len(rows)} cells -> results/cells.csv, results/main_table.md")


# ---------------------------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------------------------

def step_bytes(args):
    tot = Counter()
    n = Counter()
    p = cache_path("ledger.jsonl")
    if os.path.exists(p):
        with open(p) as f:
            for line in f:
                r = json.loads(line)
                tot[r["kind"]] += r["bytes"]
                n[r["kind"]] += 1
    for k in sorted(tot):
        print(f"{k:24s} {n[k]:5d} requests {tot[k]:>14,d} bytes ({tot[k] / 1e6:.1f} MB)")
    print(f"{'total':24s} {sum(n.values()):5d} requests {sum(tot.values()):>14,d} bytes ({sum(tot.values()) / 1e6:.1f} MB)")
    # Aggregate copy of the (git-ignored) ledger for the record.
    os.makedirs(RESULTS, exist_ok=True)
    with open(os.path.join(RESULTS, "downloads.json"), "w") as f:
        json.dump({"note": "bytes received per kind for the run that produced these results (from the cache ledger)",
                   "requests": dict(n), "bytes": dict(tot), "totalBytes": sum(tot.values())}, f, indent=1, sort_keys=True)
    return tot


def main():
    global CACHE
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("step", choices=["resolve", "osm", "overture", "tris", "report", "all", "bytes"])
    ap.add_argument("--cache", default=os.environ.get("AUDIT_CACHE") or os.path.join(HERE, ".cache"))
    ap.add_argument("--force", action="store_true", help="resolve: re-resolve anchors that already have a centre")
    ap.add_argument("--only", nargs="*", help="limit to these cell ids")
    ap.add_argument("--dense", nargs="*", help="tris: cells to model as full worlds (ground, props, view)")
    ap.add_argument("--zone-profiles", help="tris: optional folder with region-catalog.json + profiles/ "
                    "(proposed zone profiles) to compare against the bundled profiles")
    args = ap.parse_args()
    CACHE = os.path.abspath(args.cache)
    os.makedirs(CACHE, exist_ok=True)
    steps = ["resolve", "osm", "overture", "tris", "report"] if args.step == "all" else [args.step]
    for s in steps:
        globals()["step_" + s](args)


if __name__ == "__main__":
    main()
