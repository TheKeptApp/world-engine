"""Canonical sample cells from named public anchors.

Rule (shared with the coverage audit so numbers line up): find the named OSM feature with a small
Overpass query (`out center`), take its centre rounded to 4 decimals, and box +-500 m around it.
All anchors of one region are looked up in ONE batched query (fewer requests than one per name).
"""
import json
import re

from . import geo, net


def anchor_query(names, bbox):
    alt = "|".join(_rx(n) for n in sorted(set(names)))
    s, w, n, e = bbox
    return ('[out:json][timeout:60];\n'
            'nwr["name"~"^(%s)$"](%.4f,%.4f,%.4f,%.4f);\n'
            'out center tags;' % (alt, s, w, n, e))


def _rx(name):
    """Escapes regex metacharacters (not spaces) for an Overpass name regex."""
    return re.sub(r'([.^$*+?()\[\]{}|\\])', r'\\\1', name)


def find_query(bbox, key, value):
    """Named features with key=value in a box, as bounding boxes (centre = bbox midpoint, which is
    what Overpass `out center` reports)."""
    s, w, n, e = bbox
    sel = '["%s"="%s"]["name"]' % (key, value)
    return ('[out:json][timeout:60];\n'
            '(way%s(%.4f,%.4f,%.4f,%.4f);relation%s["type"="multipolygon"](%.4f,%.4f,%.4f,%.4f);node%s(%.4f,%.4f,%.4f,%.4f););\n'
            'out bb tags;' % (sel, s, w, n, e, sel, s, w, n, e, sel, s, w, n, e))


def element_center(e):
    if "center" in e:
        return e["center"]["lat"], e["center"]["lon"]
    if "lat" in e:
        return e["lat"], e["lon"]
    if "bounds" in e:
        b = e["bounds"]
        return (b["minlat"] + b["maxlat"]) / 2, (b["minlon"] + b["maxlon"]) / 2
    return None


def matches(tags, match, match_any=None):
    if match_any and not any(matches(tags, m) for m in match_any):
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


def resolve_region(config, log=print):
    """Looks up every cell anchor of a region config; returns {cell_id: resolution dict}."""
    cells = [(z, c) for z in config["zones"] for c in z["cells"] if c.get("anchor")]
    if not cells:
        return {}
    bbox = config["anchorSearch"]["bbox"]
    q = anchor_query([n for _, c in cells for n in anchor_names(c["anchor"])], bbox)
    data, meta = net.overpass(q, log=log)
    elements = json.loads(data)["elements"]
    out = {}
    for z, c in cells:
        a = c["anchor"]
        names = anchor_names(a)
        cands = []
        for e in elements:
            tags = e.get("tags", {})
            if tags.get("name") not in names or not matches(tags, a.get("match"), a.get("matchAny")):
                continue
            ctr = element_center(e)
            if ctr is None:
                continue
            d = geo.haversine_km(ctr[0], ctr[1], a["near"][0], a["near"][1]) if a.get("near") else 0.0
            cands.append((names.index(tags["name"]), d, e["type"], e["id"], ctr, tags))
        max_km = a.get("maxKm", 3.0)
        cands = [t for t in cands if not a.get("near") or t[1] <= max_km]
        # Preferred name first, then nearest to the hint, then a stable element order.
        cands.sort(key=lambda t: (t[0], t[1], t[2], t[3]))
        if not cands:
            out[c["id"]] = {"found": False, "candidates": 0}
            continue
        _, d, typ, eid, ctr, tags = cands[0]
        out[c["id"]] = {
            "found": True, "osm": "%s/%d" % (typ, eid), "distanceFromHintKm": round(d, 3),
            "centerRaw": [ctr[0], ctr[1]], "center": [round(ctr[0], 4), round(ctr[1], 4)],
            "matchedTags": {k: tags[k] for k in sorted(tags) if k in (
                "name", "leisure", "railway", "public_transport", "historic", "tourism", "amenity", "place",
                "highway", "landuse", "man_made", "building", "memorial")},
            "osmTimestamp": meta.get("timestamp_osm_base"),
        }
    return out


def anchor_names(a):
    return a.get("names") or [a["name"]]


def cell_bbox(cell):
    """(S, W, N, E) of a cell: explicit bbox, else centre +- radiusMeters (square half-side)."""
    if cell.get("bbox"):
        return tuple(cell["bbox"])
    lat, lon = cell["center"]
    return geo.box_around(lat, lon, cell.get("radiusMeters", 500))
