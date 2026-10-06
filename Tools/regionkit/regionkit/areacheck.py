"""Size check for the detailed map files (`osm.json`, layer `all`) of every area under Data/areas.

Flags an area whose osm.json is over BUDGET_MB_PER_KM2 (megabytes of 10^6 bytes per km^2 of the area box),
and any relation with >= MIN_MEMBERS members in a detailed file that still carries member ways outside
the context-ring box (a clipped stub, as `osmclip` leaves it, is fine). See docs/data/area-size-budget.md.
Python 3 standard library only.
"""
import json
import os

from . import osmclip, paths

BUDGET_MB_PER_KM2 = 5.0
MIN_MEMBERS = 300


def area_rows(areas_dir=None, budget=BUDGET_MB_PER_KM2, min_members=MIN_MEMBERS):
    areas_dir = areas_dir or os.path.join(paths.REPO, "Data", "areas")
    rows = []
    for name in sorted(os.listdir(areas_dir)):
        mpath = os.path.join(areas_dir, name, "manifest.json")
        if not os.path.isfile(mpath):
            continue
        with open(mpath, encoding="utf-8") as f:
            m = json.load(f)
        km2 = m["widthMeters"] * m["heightMeters"] / 1e6
        for s in m["sources"]:
            if s.get("format") != "osm-overpass-json" or "all" not in s.get("layers", []):
                continue
            p = os.path.join(areas_dir, name, s["path"])
            size = os.path.getsize(p)
            with open(p, encoding="utf-8") as f:
                text = f.read()
            els = json.loads(text)["elements"]
            counts = {"node": 0, "way": 0, "relation": 0}
            big = []
            for e in els:
                counts[e["type"]] = counts.get(e["type"], 0) + 1
                if e["type"] == "relation" and len(e.get("members", [])) >= min_members:
                    big.append((e["id"], len(e["members"])))
            mb = size / 1e6
            problems = []
            if mb / km2 > budget:
                problems.append("over budget: %.2f MB/km2 > %.2f" % (mb / km2, budget))
            if big:
                # A big relation is fine as a stub: the relation plus only the member ways that touch the
                # context-ring box. It is a problem when member ways outside that box are still present.
                box = osmclip.context_box(m)
                extra = None
                if box is not None:
                    extra = osmclip.clip_text(text, box, min_members)[1]["ways_dropped"]
                for rid, n in big:
                    if extra is None:
                        problems.append("relation/%d has %d members (>= %d) and the area has no context source to clip against" % (rid, n, min_members))
                    elif extra:
                        problems.append("relation/%d has %d members (>= %d); %d member ways outside the context box are still in the file: run `regionkit.sh osmclip`" % (rid, n, min_members, extra))
            rows.append({"area": name, "path": s["path"], "bytes": size, "km2": km2, "mb_per_km2": mb / km2,
                         "nodes": counts["node"], "ways": counts["way"], "relations": counts["relation"],
                         "problems": problems})
    return rows


def format_rows(rows):
    lines = ["%-26s %12s %7s %9s %9s %8s %5s" % ("area", "bytes", "km2", "MB/km2", "nodes", "ways", "rels")]
    for r in rows:
        lines.append("%-26s %12d %7.2f %9.2f %9d %8d %5d%s" % (
            r["area"], r["bytes"], r["km2"], r["mb_per_km2"], r["nodes"], r["ways"], r["relations"],
            "  FLAG" if r["problems"] else ""))
    for r in rows:
        for p in r["problems"]:
            lines.append("FLAG %s/%s: %s" % (r["area"], r["path"], p))
    return "\n".join(lines)
