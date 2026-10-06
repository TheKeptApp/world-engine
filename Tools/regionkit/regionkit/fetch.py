"""Loads OSM data for sample cells: Overpass (cached) or a committed area extract (read-only)."""
import json
import os

from . import anchors, geo, net, osm, paths

HIGHWAY_BUFFER_M = 100.0  # streets are fetched in a larger box so edge houses find their street


def cell_spec(cell):
    """Normalised cell description: id, bbox (S,W,N,E), centre, source."""
    if cell.get("localExtract"):
        d = os.path.join(paths.REPO, cell["localExtract"])
        man = paths.load_json(os.path.join(d, "manifest.json"))
        src = man["sources"][0]
        b = src["bounds"]
        return {"id": cell["id"], "source": "localExtract", "path": cell["localExtract"],
                "bbox": [b["south"], b["west"], b["north"], b["east"]],
                "center": [man["center"]["latitude"], man["center"]["longitude"]],
                "osmTimestamp": src.get("dataTimestamp"), "sha256": src.get("sha256"),
                "manifestSize": [man.get("widthMeters"), man.get("heightMeters")]}
    if not cell.get("bbox") and not cell.get("center"):
        raise ValueError("cell %s has no centre yet: run `regionkit.sh anchors <config> --write`" % cell["id"])
    bbox = list(anchors.cell_bbox(cell))
    center = cell.get("center") or [(bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2]
    return {"id": cell["id"], "source": "overpass", "bbox": bbox, "center": list(center),
            "radiusMeters": cell.get("radiusMeters"), "anchor": cell.get("anchor"),
            "anchorResolved": cell.get("anchorResolved"), "extra": cell.get("extra", False)}


def highway_bbox(bbox, buffer_m=HIGHWAY_BUFFER_M):
    s, w, n, e = bbox
    lat = (s + n) / 2
    b = geo.box_around(lat, (w + e) / 2, buffer_m)
    dlat, dlon = (b[2] - b[0]) / 2, (b[3] - b[1]) / 2
    return [round(s - dlat, 6), round(w - dlon, 6), round(n + dlat, 6), round(e + dlon, 6)]


def load_cell(spec, log=print):
    """Returns (osm.Doc, fetch record) for a cell."""
    if spec["source"] == "localExtract":
        p = os.path.join(paths.REPO, spec["path"], "osm.json")
        with open(p, "rb") as f:
            data = f.read()
        doc = osm.Doc.from_overpass(data)
        return doc, {"source": "committed extract (read in place, read-only)", "path": paths.repo_rel(p),
                     "bytes": len(data), "timestamp_osm_base": doc.timestamp or spec.get("osmTimestamp"),
                     "sha256": spec.get("sha256"), "query": "see %s/osm.overpassql" % spec["path"]}
    q = osm.cell_query(spec["bbox"], highway_bbox(spec["bbox"]))
    data, meta = net.overpass(q, log=log)
    doc = osm.Doc.from_overpass(data)
    return doc, {"source": "overpass", "endpoint": meta.get("endpoint"), "bytes": meta.get("bytes"),
                 "fetchedAt": meta.get("fetchedAt"), "timestamp_osm_base": meta.get("timestamp_osm_base"),
                 "cacheKey": net.overpass_cache_key(q), "query": q}


def fetch_config(cfg, zone=None, log=print):
    for z in cfg["zones"]:
        if zone and z["id"] != zone:
            continue
        for c in z["cells"]:
            spec = cell_spec(c)
            log("cell %s/%s %s" % (z["id"], spec["id"], spec["bbox"]))
            doc, rec = load_cell(spec, log=log)
            log("  %d nodes, %d ways, %d relations, OSM base %s" % (len(doc.nodes), len(doc.ways), len(doc.relations), rec.get("timestamp_osm_base")))
