"""Command line: `python3 -m regionkit <command>` (wrapped by Tools/regionkit/regionkit.sh)."""
import argparse
import json
import os
import sys

from . import anchors, net, paths


def _log(msg):
    net.log_stderr(msg)


def cmd_anchors(args):
    cfg_path = paths.config_path(args.config)
    with open(cfg_path) as f:
        cfg = json.load(f)
    res = anchors.resolve_region(cfg, log=_log)
    print(json.dumps(res, indent=1))
    if args.write:
        changed = 0
        for z in cfg["zones"]:
            for c in z["cells"]:
                r = res.get(c["id"])
                if r and r.get("found"):
                    c["center"] = r["center"]
                    c["anchorResolved"] = {"osm": r["osm"], "matchedTags": r["matchedTags"],
                                           "osmTimestamp": r["osmTimestamp"], "rule": "Overpass `out center`, rounded to 4 decimals; cell = centre +- radiusMeters"}
                    changed += 1
        paths.write_json(cfg_path, cfg)
        _log("wrote %d centres to %s" % (changed, cfg_path))


def cmd_find(args):
    bbox = [float(x) for x in args.bbox.split(",")]
    key, value = args.tag.split("=", 1)
    data, meta = net.overpass(anchors.find_query(bbox, key, value), log=_log)
    rows = []
    for e in json.loads(data)["elements"]:
        c = anchors.element_center(e)
        b = e.get("bounds")
        area = None
        if b:
            from . import geo
            fr = geo.LocalFrame(c[0], c[1])
            x0, y0 = fr.xy(b["minlat"], b["minlon"])
            x1, y1 = fr.xy(b["maxlat"], b["maxlon"])
            area = abs(x1 - x0) * abs(y1 - y0) / 10000
        rows.append((e.get("tags", {}).get("name"), e["type"], e["id"], round(c[0], 4), round(c[1], 4), area))
    rows.sort(key=lambda r: (r[4]))
    for r in rows:
        print("%-40s %-8s %12d  %.4f,%.4f  bbox %.1f ha" % (r[0], r[1], r[2], r[3], r[4], r[5] or 0))
    _log("OSM base %s" % meta.get("timestamp_osm_base"))


def build_parser():
    p = argparse.ArgumentParser(prog="regionkit", description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    a = sub.add_parser("anchors", help="resolve named anchors of a region config (one batched Overpass query)")
    a.add_argument("config")
    a.add_argument("--write", action="store_true", help="write resolved centres back into the config")
    a.set_defaults(func=cmd_anchors)

    f = sub.add_parser("find", help="list named features with a tag in a box (to choose anchors)")
    f.add_argument("--bbox", required=True, help="S,W,N,E")
    f.add_argument("--tag", required=True, help="key=value, e.g. leisure=park")
    f.set_defaults(func=cmd_find)

    try:
        from . import commands
        commands.register(sub)
    except ImportError as e:  # during bootstrap only
        _log("note: draft commands unavailable (%s)" % e)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
