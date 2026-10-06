"""draft / all / compare / validate / fetch commands."""
import json
import os
import sys
import time

from . import (climate, compare, draft, fetch, measure, net, paths, profiles, report, validate, zones)

_CELL_CACHE = {}
_DENVER = {}


def _log(msg):
    net.log_stderr(msg)


def denver_house_areas():
    """Sloan's Lake house footprints (the threshold percentile-transfer reference)."""
    if "areas" not in _DENVER:
        cfg = paths.load_json(os.path.join(paths.REGIONS, "denver.json"))
        spec = fetch.cell_spec(cfg["zones"][0]["cells"][0])
        tmpl, _ = profiles.load("default")
        doc, rec = fetch.load_cell(spec, log=_log)
        cell = measure.Cell(spec, doc, tmpl, rec)
        _DENVER["areas"] = [b["area"] for b in cell.buildings if b["role"] == "house"]
    return _DENVER["areas"]


def get_cell(spec, template):
    key = json.dumps(spec["bbox"]) + spec["id"]
    if key not in _CELL_CACHE:
        doc, rec = fetch.load_cell(spec, log=_log)
        _CELL_CACHE[key] = measure.Cell(spec, doc, template, rec)
    return _CELL_CACHE[key]


def zone_cells(cfg, zone):
    if zone.get("poolZones"):
        out = []
        for zid in zone["poolZones"]:
            z = next(zz for zz in cfg["zones"] if zz["id"] == zid)
            out += z["cells"]
        return out
    return zone["cells"]


def draft_zone(cfg, zone, k=draft.K_DEFAULT, out_root=None, log=_log):
    t0 = time.time()
    region = cfg["region"]
    template, template_src = profiles.load(zone["template"])
    specs = [fetch.cell_spec(c) for c in zone_cells(cfg, zone)]
    cells = [get_cell(s, template) for s in specs]
    log("zone %s/%s: %d cells, template %s" % (region, zone["id"], len(cells), zone["template"]))
    lat = sum(c.spec["center"][0] for c in cells) / len(cells)
    lon = sum(c.spec["center"][1] for c in cells) / len(cells)
    clim = climate.normals_near(lat, lon, log=log)
    summary = measure.summarize(cells, template)
    per_cell = []
    for c in cells:
        s = measure.summarize([c], template)
        per_cell.append({"id": c.spec["id"], "spec": {k2: v for k2, v in c.spec.items() if k2 not in ("anchorResolved",)},
                         "anchorResolved": c.spec.get("anchorResolved"), "fetch": c.fetch, "areaKm2": round(c.area_m2 / 1e6, 4),
                         "signature": measure.signature(s), "summary": s})
    mat = measure.material_table()
    prof, prov = draft.make_draft(zone["id"], zone["name"], region, cells, template, zone["template"], denver_house_areas(), clim, k=k,
                                  materials=mat)
    v = validate.validate(prof, prof["id"])
    if not v.ok:
        raise RuntimeError("draft failed validation: %s" % v.errors)
    result = {"region": region, "zone": zone, "template": zone["template"], "templateSource": template_src, "k": k,
              "cells": per_cell, "summary": summary, "climate": clim, "profile": prof, "provenance": prov.items,
              "validation": {"ok": v.ok, "errors": v.errors, "warnings": v.warnings}}
    if zone.get("reference"):
        ref, ref_src = profiles.load(zone["reference"])
        result["accuracy"] = {"reference": zone["reference"], "referenceSource": ref_src,
                              "comparison": compare.compare(prof, ref, cells, prov, exclude_thresholds=(region == "denver")),
                              "directTests": compare.direct_tests(ref, cells, denver_house_areas())}
    if cfg.get("catalogCheck"):
        f = paths.repo_file(cfg["catalogCheck"])
        if f:
            cat = paths.load_json(f)
            expected = zone.get("catalogProfile") or zone.get("reference")
            result["catalogCheck"] = {"catalog": cfg["catalogCheck"],
                                      "cells": {c.spec["id"]: zones.catalog_check(c, cat, expected) for c in cells},
                                      "boxSignatures": zones.box_signatures(cells, cat)}
        else:
            result["catalogCheck"] = {"catalog": cfg["catalogCheck"], "missing": True}
    out_dir = os.path.join(out_root or paths.DRAFTS, region, zone["id"])
    os.makedirs(out_dir, exist_ok=True)
    paths.write_json(os.path.join(out_dir, "profile.json"), prof)
    paths.write_json(os.path.join(out_dir, "measurements.json"), report.measurements_doc(result))
    with open(os.path.join(out_dir, "report.md"), "w") as f:
        f.write(report.zone_report(result))
    log("  wrote %s (%.1f s)" % (paths.repo_rel(out_dir), time.time() - t0))
    return result


def cmd_draft(args):
    if args.config:
        cfg = paths.load_json(paths.config_path(args.config))
        zs = [z for z in cfg["zones"] if not args.zone or z["id"] == args.zone]
        if not zs:
            sys.exit("no zone %r in %s" % (args.zone, args.config))
    else:
        if not (args.id and args.zone and args.template and (args.bbox or (args.center and args.radius))):
            sys.exit("CLI form needs --id --zone --template and --bbox S,W,N,E or --center LAT,LON --radius M")
        cell = {"id": "%s-%s-cell" % (args.id, args.zone)}
        if args.bbox:
            cell["bbox"] = [float(x) for x in args.bbox.split(",")]
        else:
            cell["center"] = [float(x) for x in args.center.split(",")]
            cell["radiusMeters"] = float(args.radius)
        zone = {"id": args.zone, "name": args.zone, "template": args.template, "cells": [cell], "missingFamilies": []}
        if args.reference:
            zone["reference"] = args.reference
        cfg = {"region": args.id, "name": args.id, "zones": [zone]}
        zs = [zone]
    for z in zs:
        draft_zone(cfg, z, k=args.k)


def all_configs():
    return [os.path.join(paths.REGIONS, f) for f in sorted(os.listdir(paths.REGIONS)) if f.endswith(".json")]


def cmd_all(args):
    results = []
    for p in all_configs():
        cfg = paths.load_json(p)
        for z in cfg["zones"]:
            results.append(draft_zone(cfg, z, k=args.k))
    write_index(results)
    net_total, n = net.ledger_total()
    _log("download ledger: %d bytes in %d requests" % (net_total, n))


def write_index(results):
    rows = []
    for r in results:
        for c in r["cells"]:
            if r["zone"].get("poolZones"):
                continue
            rows.append(dict(zone="%s/%s" % (r["region"], r["zone"]["id"]), cell=c["id"], **c["signature"]))
    chicago = [x for x in rows if x["zone"].startswith("chicagoland/")]
    sep = {"chicagoland": zones.separation_test(chicago),
           "chicagolandCityOnly": zones.separation_test([x for x in chicago if x["zone"].split("/")[1] in
                                                         ("dense-north", "greystone", "bungalow-belt", "south-side", "downtown")]),
           "chicagolandWithNorthShorePooled": zones.separation_test(
               [dict(x, zone=("chicagoland/north-shore" if x["zone"].split("/")[1] in ("evanston", "wilmette", "winnetka", "kenilworth") else x["zone"]))
                for x in chicago])}
    doc = {"generatedBy": "Tools/regionkit", "attribution": "Derived from OpenStreetMap data, (c) OpenStreetMap contributors, ODbL 1.0",
           "cellSignatures": rows, "separation": sep}
    paths.write_json(os.path.join(paths.DRAFTS, "zone-signatures.json"), doc)
    with open(os.path.join(paths.DRAFTS, "README.md"), "w") as f:
        f.write(report.index(results, doc))


def cmd_compare(args):
    out = []
    for p in all_configs():
        cfg = paths.load_json(p)
        for z in cfg["zones"]:
            if not z.get("reference"):
                continue
            mp = os.path.join(paths.DRAFTS, cfg["region"], z["id"], "measurements.json")
            if not os.path.exists(mp):
                _log("no draft yet for %s/%s (run draft first)" % (cfg["region"], z["id"]))
                continue
            m = paths.load_json(mp)
            a = m.get("accuracy", {})
            c = a.get("comparison", {})
            d = a.get("directTests", {})
            out.append({"zone": "%s/%s" % (cfg["region"], z["id"]), "reference": z["reference"], "score": c.get("score"),
                        "agree": c.get("agree"), "differ": c.get("differ"), "supports": d.get("supports"), "contradicts": d.get("contradicts"),
                        "cantTest": d.get("cantTest")})
    print("%-32s %-26s %6s %5s %6s | %8s %11s %10s" % ("zone", "reference", "score", "agree", "differ", "supports", "contradicts", "can't test"))
    for o in out:
        print("%-32s %-26s %6s %5s %6s | %8s %11s %10s" % (o["zone"], o["reference"], o["score"], o["agree"], o["differ"], o["supports"], o["contradicts"], o["cantTest"]))
    paths.write_json(os.path.join(paths.DRAFTS, "accuracy.json"), {"zones": out})


def cmd_validate(args):
    files = args.files
    bad = 0
    if not files:
        for pid, prof, src in profiles.all_known():
            r = validate.validate(prof, "%s (%s)" % (pid, src))
            print(r.summary())
            bad += not r.ok
        for root, _, fs in os.walk(paths.DRAFTS):
            for f in sorted(fs):
                if f == "profile.json":
                    p = os.path.join(root, f)
                    r = validate.validate(paths.load_json(p), paths.repo_rel(p))
                    print(r.summary())
                    for e in r.errors:
                        print("   " + e)
                    bad += not r.ok
    for f in files:
        r = validate.validate(paths.load_json(f), f)
        print(r.summary())
        for e in r.errors + r.warnings:
            print("   " + e)
        bad += not r.ok
    sys.exit(1 if bad else 0)


def cmd_fetch(args):
    cfg = paths.load_json(paths.config_path(args.config))
    fetch.fetch_config(cfg, zone=args.zone, log=_log)
    total, n = net.ledger_total()
    _log("download ledger: %d bytes in %d requests" % (total, n))


def register(sub):
    d = sub.add_parser("draft", help="draft profiles for a region config (or one CLI-defined cell)")
    d.add_argument("config", nargs="?")
    d.add_argument("--zone")
    d.add_argument("--id")
    d.add_argument("--bbox")
    d.add_argument("--center")
    d.add_argument("--radius")
    d.add_argument("--template")
    d.add_argument("--reference")
    d.add_argument("--k", type=float, default=draft.K_DEFAULT)
    d.set_defaults(func=cmd_draft)
    a = sub.add_parser("all", help="draft every region config, then write drafts/README.md and zone-signatures.json")
    a.add_argument("--k", type=float, default=draft.K_DEFAULT)
    a.set_defaults(func=cmd_all)
    c = sub.add_parser("compare", help="accuracy summary of every zone that has a reference profile")
    c.set_defaults(func=cmd_compare)
    v = sub.add_parser("validate", help="validate profile JSON files (default: all known profiles and drafts)")
    v.add_argument("files", nargs="*")
    v.set_defaults(func=cmd_validate)
    f = sub.add_parser("fetch", help="fetch (or confirm cached) data for a region config")
    f.add_argument("config")
    f.add_argument("--zone")
    f.set_defaults(func=cmd_fetch)
