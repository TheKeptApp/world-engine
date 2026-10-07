#!/usr/bin/env python3
"""ZCTA5 2020 boundary extracts for WorldEngine area directories.

Run (shapely and numpy needed):
  UV_CACHE_DIR=/tmp/claude-zcta-uv uv run --no-project --with shapely --with numpy \
      python Tools/regionkit/zcta/zcta.py Data/areas/<id> [...]
Fetches the Census TIGERweb ZCTA layer for the area's context box and writes
<area>/zcta.json (format census-zcta-v1). See README.md.
"""
import argparse
import json
import math
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

LAYER_URL = ("https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/"
             "PUMA_TAD_TAZ_UGA_ZCTA/MapServer/7/query")
USER_AGENT = "WorldEngine regionkit (research)"
DECIMALS = 7
SIZE_TARGET = 300_000

SOURCE = {
    "id": "census-zcta5-2020",
    "title": "U.S. Census Bureau TIGER/Line ZCTA5 2020",
    "attribution": "U.S. Census Bureau, TIGER/Line ZIP Code Tabulation Areas (2020)",
    "license": "public-domain",
    "licenseURL": "https://www.census.gov/data/developers/about/terms-of-service.html",
    "url": LAYER_URL,
    "vintage": 2020,
    "retrieved": "2026-10-06",
}


def context_bounds(manifest):
    for s in manifest["sources"]:
        if s.get("layers") == ["context"]:
            return s["bounds"]
    raise ValueError("no context source in manifest")


def query_url(b):
    env = "%.7f,%.7f,%.7f,%.7f" % (b["west"], b["south"], b["east"], b["north"])
    q = {"where": "1=1", "geometry": env, "geometryType": "esriGeometryEnvelope",
         "inSR": "4326", "spatialRel": "esriSpatialRelIntersects",
         "outFields": "ZCTA5", "returnGeometry": "true", "outSR": "4326",
         "f": "geojson"}
    return LAYER_URL + "?" + urllib.parse.urlencode(q)


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    ctx = None
    try:  # python.org builds lack system CAs; use certifi when present (verification stays on)
        import certifi
        import ssl
        ctx = ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        pass
    with urllib.request.urlopen(req, timeout=120, context=ctx) as r:
        return json.load(r)


def signed_area(ring):
    return sum(ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1]
               for i in range(len(ring) - 1)) / 2


def fmt_ring(coords, ccw):
    ring = [[round(x, DECIMALS), round(y, DECIMALS)] for x, y in coords]
    out = [ring[0]]
    for p in ring[1:]:
        if p != out[-1]:
            out.append(p)
    if out[0] != out[-1]:
        out.append(out[0])
    if len(out) < 4:
        return None
    if (signed_area(out) > 0) != ccw:
        out.reverse()
    return out


def polygons_of(geom):
    if geom.is_empty:
        return []
    if geom.geom_type == "Polygon":
        return [geom]
    return [g for g in getattr(geom, "geoms", []) if g.geom_type == "Polygon" and not g.is_empty]


def clip_feature(geometry, bounds, tol_m=0.0):
    """GeoJSON geometry -> list of polygons ([outer, holes...]) clipped to bounds."""
    from shapely.geometry import shape, box
    g = shape(geometry)
    if not g.is_valid:
        g = g.buffer(0)
    g = g.intersection(box(bounds["west"], bounds["south"], bounds["east"], bounds["north"]))
    if tol_m > 0:
        lat = math.radians((bounds["south"] + bounds["north"]) / 2)
        g = g.simplify(tol_m / (111320.0 * math.cos(lat)), preserve_topology=True)
    result = []
    for p in polygons_of(g):
        rings = [fmt_ring(p.exterior.coords, True)]
        rings += [fmt_ring(i.coords, False) for i in p.interiors]
        if rings[0] is None:
            continue
        result.append([r for r in rings if r is not None])
    return result


def build(features, bounds, tol_m=0.0):
    by_id = {}
    for f in features:
        zid = str(f["properties"].get("ZCTA5") or f["properties"].get("GEOID"))
        polys = clip_feature(f["geometry"], bounds, tol_m)
        if polys:
            by_id.setdefault(zid, []).extend(polys)
    doc = {"format": "census-zcta-v1", "source": SOURCE,
           "bounds": {k: bounds[k] for k in ("south", "west", "north", "east")},
           "zctas": [{"id": i, "polygons": by_id[i]} for i in sorted(by_id)]}
    if tol_m > 0:
        doc["simplifiedToleranceM"] = tol_m
    return doc


def dump(doc):
    return json.dumps(doc, indent=2, sort_keys=True) + "\n"


def vertices(doc):
    return sum(len(r) for z in doc["zctas"] for p in z["polygons"] for r in p)


def run_area(area, pause=1.0):
    area = Path(area)
    bounds = context_bounds(json.load(open(area / "manifest.json")))
    url = query_url(bounds)
    data = fetch(url)
    feats = data.get("features", [])
    if data.get("error") or data.get("exceededTransferLimit"):
        raise RuntimeError("service error or transfer limit: %s" % str(data)[:200])
    doc = build(feats, bounds)
    text = dump(doc)
    for tol in (0.5, 1.0):
        if len(text) <= SIZE_TARGET:
            break
        doc = build(feats, bounds, tol)
        text = dump(doc)
    (area / "zcta.json").write_text(text)
    time.sleep(pause)
    return url, [z["id"] for z in doc["zctas"]], vertices(doc), len(text.encode()), doc.get("simplifiedToleranceM")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("areas", nargs="+")
    for a in ap.parse_args(argv).areas:
        url, ids, nv, size, tol = run_area(a)
        print(a, "zctas=%s vertices=%d bytes=%d tol=%s" % (ids, nv, size, tol))
        print("  ", url)


if __name__ == "__main__":
    sys.exit(main())
