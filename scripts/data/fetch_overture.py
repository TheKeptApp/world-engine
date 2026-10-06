#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["duckdb==1.5.6"]
# ///
"""Fetches Overture Maps buildings for one bounding box into `overture-buildings.json`.

Normally run by `worldbake fetch <area-dir> --layers overture`, which also records the source
in the area's manifest and NOTICE.md. Standalone:

    uv run --script scripts/data/fetch_overture.py --bbox S,W,N,E --out overture-buildings.json [--release R]

- Release: the latest one in the STAC catalog (https://stac.overturemaps.org/catalog.json)
  unless --release is given.
- Files: only the buildings/building GeoParquet files whose STAC bounding box meets the box.
- Rows: DuckDB `read_parquet` over HTTPS with a bbox filter, so only the row groups whose `bbox`
  statistics meet the box are downloaded (a few MB per km²), never whole files.
- Underground buildings (`is_underground = true`) are left out.
- Output (format "overture-buildings-v1", docs/research/overture-source.md): one record per
  building, sorted by GERS ID, one per line; coordinates rounded to 7 decimals (about 1 cm),
  heights to 1 cm. Same release and box give the same bytes.

DuckDB extensions are cached in $WORLDBAKE_CACHE/duckdb-extensions when that is set (else in
DuckDB's default directory). Every HTTP request identifies the tool; the User-Agent is honest.
"""
import argparse
import json
import os
import re
import ssl
import struct
import sys
import urllib.request

STAC = "https://stac.overturemaps.org"
USER_AGENT = "WorldEngine-worldbake/0.1 (offline map data bake tool)"
FORMAT = "overture-buildings-v1"

_bytes = {"stac": 0, "parquet": 0}
_ssl = None


def log(*a):
    print(*a, file=sys.stderr, flush=True)


def ssl_context():
    """Default context; falls back to the macOS system CA bundle when Python's store is empty
    (python.org builds without "Install Certificates")."""
    global _ssl
    if _ssl is None:
        ctx = ssl.create_default_context()
        if ctx.cert_store_stats().get("x509_ca", 0) == 0:
            for cafile in ("/etc/ssl/cert.pem", "/private/etc/ssl/cert.pem"):
                if os.path.exists(cafile):
                    ctx = ssl.create_default_context(cafile=cafile)
                    break
        _ssl = ctx
    return _ssl


def get_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=120, context=ssl_context()) as r:
        if r.status != 200:
            raise RuntimeError(f"{url}: HTTP {r.status}")
        raw = r.read()
    _bytes["stac"] += len(raw)
    return json.loads(raw)


def latest_release():
    cat = get_json(f"{STAC}/catalog.json")
    if cat.get("latest"):
        return cat["latest"]
    for link in cat.get("links", []):
        if link.get("rel") == "child" and link.get("latest"):
            return link["href"].rstrip("/").split("/")[-2]
    raise RuntimeError("no latest release in the STAC catalog")


def meets(b, s, w, n, e):
    """b = [xmin, ymin, xmax, ymax] (STAC order)."""
    return not (b[2] < w or b[0] > e or b[3] < s or b[1] > n)


def parquet_files(release, s, w, n, e):
    coll = get_json(f"{STAC}/{release}/buildings/building/collection.json")
    boxes = coll["extent"]["spatial"]["bbox"][1:]  # [0] is the whole collection
    items = [l["href"] for l in coll["links"] if l.get("rel") == "item"]
    if len(boxes) != len(items):
        raise RuntimeError(f"STAC collection has {len(boxes)} boxes for {len(items)} items")
    urls = []
    for href, box in zip(items, boxes):
        if not meets(box, s, w, n, e):
            continue
        item = get_json(href)  # the item's own bbox decides; the extent list only preselects
        if meets(item["bbox"], s, w, n, e):
            urls.append(item["assets"]["aws"]["href"])
    return coll, sorted(urls)


def wkb_polygons(b):
    """Polygons of a WKB Polygon / MultiPolygon: [[ring, ...], ...], ring = [[lon, lat], ...]."""
    out = []

    def geom(off):
        bo = "<" if b[off] == 1 else ">"
        (gt,) = struct.unpack_from(bo + "I", b, off + 1)
        off += 5
        if gt & 0x20000000:  # EWKB SRID
            off += 4
        dims = 2 + (1 if gt & 0x80000000 or (gt & 0xFFFF) // 1000 in (1, 3) else 0) \
                 + (1 if gt & 0x40000000 or (gt & 0xFFFF) // 1000 in (2, 3) else 0)
        kind = (gt & 0xFFFF) % 1000
        if kind == 3:
            (nr,) = struct.unpack_from(bo + "I", b, off)
            off += 4
            rings = []
            for _ in range(nr):
                (npt,) = struct.unpack_from(bo + "I", b, off)
                off += 4
                pts = []
                for i in range(npt):
                    x, y = struct.unpack_from(bo + "dd", b, off + 8 * dims * i)
                    pts.append([round(x, 7), round(y, 7)])
                off += 8 * dims * npt
                rings.append(pts)
            if rings and len(rings[0]) >= 4:
                out.append(rings)
            return off
        if kind == 6:
            (ng,) = struct.unpack_from(bo + "I", b, off)
            off += 4
            for _ in range(ng):
                off = geom(off)
            return off
        raise ValueError(f"unsupported WKB geometry type {gt}")

    geom(0)
    return out


def http_bytes(con):
    total = 0
    for (m,) in con.execute("SELECT message FROM duckdb_logs WHERE type = 'HTTP'").fetchall():
        req, _, resp = m.partition("'response'")
        if "'type': GET" in req:
            mm = re.search(r"Content-Length=(\d+)", resp)
            if mm:
                total += int(mm.group(1))
    return total


def query(urls, s, w, n, e):
    import duckdb

    con = duckdb.connect(config={"custom_user_agent": USER_AGENT})
    cache = os.environ.get("WORLDBAKE_CACHE")
    if cache:
        ext = os.path.join(cache, "duckdb-extensions")
        os.makedirs(ext, exist_ok=True)
        con.execute("SET extension_directory = ?", [ext])
    con.execute("INSTALL httpfs")
    con.execute("LOAD httpfs")
    con.execute("CALL enable_logging('HTTP')")
    files = "[" + ",".join("'" + u.replace("'", "''") + "'" for u in urls) + "]"
    sql = (
        "SELECT id, class, subtype, height, min_height, num_floors, roof_shape, sources, geometry "
        f"FROM read_parquet({files}) "
        f"WHERE bbox.xmin <= {e!r} AND bbox.xmax >= {w!r} AND bbox.ymin <= {n!r} AND bbox.ymax >= {s!r} "
        "AND coalesce(is_underground, false) = false"
    )
    rows = con.execute(sql).fetchall()
    _bytes["parquet"] += http_bytes(con)
    return rows


def record(row):
    gid, cls, subtype, height, min_height, floors, roof, sources, geometry = row
    polys = wkb_polygons(bytes(geometry)) if geometry is not None else []
    if not polys:
        return None
    r = {"id": gid}
    if cls:
        r["class"] = cls
    if subtype:
        r["subtype"] = subtype
    if height is not None and height > 0:
        r["height"] = round(height, 2)
    if min_height is not None and min_height > 0:
        r["min_height"] = round(min_height, 2)
    if floors is not None and floors > 0:
        r["num_floors"] = int(floors)
    if roof:
        r["roof_shape"] = roof
    srcs = []
    for x in sources or []:
        if not x.get("dataset"):
            continue
        src = {"dataset": x["dataset"]}
        if x.get("record_id"):
            src["record_id"] = x["record_id"]
        if x.get("property"):
            src["property"] = x["property"]
        srcs.append(src)
    r["sources"] = srcs
    r["polygons"] = polys
    return r, {(x.get("dataset"), x.get("license")) for x in sources or [] if x.get("dataset")}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--bbox", required=True, help="S,W,N,E in degrees")
    ap.add_argument("--out", required=True)
    ap.add_argument("--release", help="Overture release (default: latest in the STAC catalog)")
    a = ap.parse_args()
    s, w, n, e = (float(v) for v in a.bbox.split(","))
    if not (s < n and w < e):
        sys.exit("--bbox must be S,W,N,E with S < N and W < E")

    release = a.release or latest_release()
    coll, urls = parquet_files(release, s, w, n, e)
    log(f"[overture] release {release}: {len(urls)} buildings file(s) meet the box")
    rows = query(urls, s, w, n, e) if urls else []

    recs, licenses, counts = [], {}, {}
    for row in rows:
        res = record(row)
        if res is None:
            continue
        r, dl = res
        recs.append(r)
        for d, lic in dl:
            if lic:
                licenses.setdefault(d, set()).add(lic)
        for d in {x["dataset"] for x in r["sources"]}:
            counts[d] = counts.get(d, 0) + 1
    recs.sort(key=lambda r: r["id"])
    datasets = []
    for d in sorted(counts):
        entry = {"dataset": d, "records": counts[d]}
        if d in licenses:
            entry["license"] = " / ".join(sorted(licenses[d]))
        datasets.append(entry)

    head = {
        "format": FORMAT, "release": release, "theme": "buildings", "type": "building",
        "license": coll.get("license"), "bbox": {"south": s, "west": w, "north": n, "east": e},
        "files": urls, "datasets": datasets,
    }
    dump = lambda o: json.dumps(o, ensure_ascii=False, separators=(",", ":"))
    body = dump(head)[:-1] + ',"buildings":[' + ("\n" + ",\n".join(dump(r) for r in recs) + "\n" if recs else "") + "]}\n"
    tmp = a.out + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(body)
    os.replace(tmp, a.out)
    log(f"[overture] {len(recs)} buildings; datasets: " + ", ".join(f"{d['dataset']} {d['records']}" for d in datasets))
    log(f"[overture] downloaded {_bytes['stac']:,} bytes STAC + {_bytes['parquet']:,} bytes GeoParquet")


if __name__ == "__main__":
    main()
