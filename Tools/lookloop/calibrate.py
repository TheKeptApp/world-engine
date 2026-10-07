#!/usr/bin/env python3
"""Grader calibration: puts the concept images themselves through the rubric, blind.

  Tools/lookloop/calibrate.py <run-dir>            build the calibration run (frames = concept images)
  Tools/lookloop/calibrate.py --report <run-dir>   summarise the grades into docs/lookloop/calibration.md
  Tools/lookloop/calibrate.py --paintover <run-dir>        build a run of the paintover-v1 images only (frames po-NN)
  Tools/lookloop/calibrate.py --merge-paintover <run-dir>  add their blind /50 to docs/lookloop/calibration-scores.json

Each concept image that is a target in views.json becomes a neutral view `cal-NN` in
Tools/lookloop/calibration.json with the metadata of the view that uses it (time, weather, camera,
sun, character), but no target images, so the reviewer grades it like any capture. Concept art
should score high; where it does not, the rubric or GRADING.md needs tuning.
"""
import json, os, shutil, subprocess, sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MANIFEST = os.path.join(ROOT, "Tools/lookloop/calibration.json")
PO_MANIFEST = os.path.join(ROOT, "Tools/lookloop/calibration-paintover.json")
V2 = ["silhouettes", "palette", "light", "softnessAO", "groundRichness", "characterReadability",
      "depthFog", "houseVariety", "geography", "motion"]
AD = ["adGroundRich", "adRainReadable", "adRegional"]
V2S = "v2 street (W 23rd Ave), heading 270 (west), pitch down 16.5, vFOV 50"
R = "docs/proposals/regions-chicagoland-miami/"


def regions_entries():
    """Regions concepts with their own fixture camera, place and moment (not P2's Evanston cameras)."""
    from analyze_sun import sun  # noqa: E402
    fx = json.load(open(os.path.join(ROOT, R, "fixtures.json")))
    cams = dict(fx["cameras"]) if isinstance(fx["cameras"], list) else fx["cameras"]
    out = []
    for f in fx["fixtures"]:
        img = os.path.join(R, "images", f"{f['id']}.png")
        if not f["id"][:2] in ("01", "02", "03", "04", "05", "06") or not os.path.exists(os.path.join(ROOT, img)):
            continue
        c = cams[f["cameraId"]]
        lat, lon = c["location"]
        w = f["weather"]
        surf = f.get("surfaceCheckpoint", {})
        out.append({"source": img, "usedBy": f"regions fixture {f['id']}", "area": f.get("profileId"),
                    "utc": f["utc"], "local": f["localDateTime"],
                    "weather": f"{w['state']} {w.get('intensity01', '')}, cloud {w.get('cloud01', '')}, wetness {surf.get('wetness01', 0)}, SWE {surf.get('snowWaterEquivalentMm', 0)} mm",
                    "season": f.get("phenology", {}).get("stage", "") if isinstance(f.get("phenology"), dict) else "",
                    "character": False, "wet": bool(surf.get("wetness01", 0) or surf.get("snowWaterEquivalentMm", 0)),
                    "camera": f"regions {f['cameraId']} camera, eye {c['heightMeters']} m, heading {c['headingDeg']}, pitch down {c['pitchDownDeg']}, vFOV 50",
                    "sun": sun(f["utc"], lat, lon)})
    return out


def build_manifest(paintover=False):
    views = {v["id"]: v for v in json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))["views"]}
    def from_view(vid, img, dog, **over):
        v = views[vid]
        e = {"source": img, "usedBy": vid, "area": v.get("area"), "utc": v["utc"], "local": v["local"], "weather": v["weather"],
             "season": v["season"], "character": dog, "wet": v.get("wet", False), "camera": v["camera"], "sun": v.get("sun")}
        e.update(over)
        return e
    V, X = "docs/proposals/visual-v2/images/", "docs/proposals/experience-v1/images/"
    if paintover:
        # paintover-v1 (owner, 6 Oct 2026): each paint-over graded blind with its own view's metadata.
        entries = [from_view(vid, v["paintover"], bool(v.get("character"))) for vid, v in views.items() if v.get("paintover")]
        cal = [dict(e, id=f"po-{i:02d}", group="calibration", title=f"Calibration frame po-{i:02d}: {e['camera'].split(',')[0]}",
                    targets=[], na=[10] if e["character"] else [6, 10]) for i, e in enumerate(entries, start=1)]
        json.dump({"about": "Paint-over calibration (calibrate.py --paintover): each paintover-v1 image graded blind with the "
                   "metadata of its view. Generated; do not edit by hand.", "views": cal}, open(PO_MANIFEST, "w"), indent=1)
        return cal
    entries = [
        from_view("v2-01", V + "01-autumn-golden-hour.png", True),
        from_view("v2-01", V + "09-data-grounded-street.png", True, usedBy="visual-v2 09 (same moment and camera as v2-01)"),
        from_view("v2-01", V + "03-rainy-dusk.png", True, usedBy="visual-v2 03 rainy dusk",
                  utc="2026-10-16T00:35:00Z", local="2026-10-15 18:35 MDT", weather="rain, dusk (direct sun off)", wet=True,
                  sun={"elevationDeg": -3.6, "azimuthDeg": 261.5, "shadowBearingDeg": 81.5, "source": "visual-v2 comparison-presets.json"}),
        from_view("v2-04", V + "04-summer-noon.png", True),
        from_view("v2-06", V + "06-aerial-golden-hour.png", False),
    ]
    for vid, v in views.items():
        if v["group"] in ("showcase", "aerial"):
            entries.append(from_view(vid, v["targets"][0]["path"], False))
    entries += regions_entries()
    cal = []
    for i, e in enumerate(entries, start=1):
        cid = f"cal-{i:02d}"
        cal.append(dict(e, id=cid, group="calibration", title=f"Calibration frame {i:02d}: {e['camera'].split(',')[0]}",
                        targets=[], na=[10] if e["character"] else [6, 10]))
    json.dump({"about": "Grader calibration (calibrate.py): each frame is a concept image graded blind with the "
               "metadata of its own preset or fixture. Generated; do not edit by hand.", "views": cal},
              open(MANIFEST, "w"), indent=1)
    return cal


def build(run, paintover=False):
    cal = build_manifest(paintover)
    os.makedirs(os.path.join(run, "raw"), exist_ok=True)
    for c in cal:
        shutil.copy(os.path.join(ROOT, c["source"]), os.path.join(run, "raw", f"{c['id']}.png"))
    meta = json.load(open(os.path.join(run, "run.json")))
    meta.update(manifest="Tools/lookloop/calibration.json", reused=[])
    json.dump(meta, open(os.path.join(run, "run.json"), "w"), indent=1)
    meta["manifest"] = os.path.relpath(PO_MANIFEST if paintover else MANIFEST, ROOT)
    json.dump(meta, open(os.path.join(run, "run.json"), "w"), indent=1)
    subprocess.run([sys.executable, os.path.join(ROOT, "Tools/lookloop/analyze.py"), run, "--manifest",
                    PO_MANIFEST if paintover else MANIFEST], check=True)
    print(f"calibration run: {len(cal)} {'paint-over' if paintover else 'concept'} images -> {run}")


def merge_paintover(run):
    """Blind /50 of each paint-over into calibration-scores.json, keyed by image path like the concepts."""
    from grade import recompute
    cp = os.path.join(ROOT, "docs/lookloop/calibration-scores.json")
    data = json.load(open(cp))
    for c in json.load(open(PO_MANIFEST))["views"]:
        g = json.load(open(os.path.join(run, "grades", f"{c['id']}.json")))
        g["hardGateFlags"] = [f for f in g.get("hardGateFlags", []) if f != "osm-credit-missing"]
        g = recompute(g, c)
        data["scores"][c["source"]] = {"v2Score50": g["v2Score50"], "adMean": g["adMean"], "calId": c["id"],
                                       "run": os.path.basename(run), "grader": g.get("grader")}
        print(f"{c['id']} {c['usedBy']}: {g['v2Score50']}/50  ad {g['adMean']}")
    json.dump(data, open(cp, "w"), indent=1)


def report(run):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from grade import recompute
    cal = {c["id"]: c for c in json.load(open(MANIFEST))["views"]}
    rows, crit = [], {}
    for cid, c in cal.items():
        p = os.path.join(run, "grades", f"{cid}.json")
        if not os.path.exists(p):
            rows.append((cid, c, None))
            continue
        g = json.load(open(p))
        # Concept art carries no OSM credit; that flag is an artefact of grading a concept, not a render fault.
        g["hardGateFlags"] = [f for f in g.get("hardGateFlags", []) if f != "osm-credit-missing"]
        g = recompute(g, c)
        rows.append((cid, c, g))
        for sect, keys in (("scores", V2), ("artDirection", AD)):
            for k in keys:
                s = g[sect].get(k, {}).get("score")
                if s is not None:
                    crit.setdefault(k, []).append(s)
    graded = [g for _, _, g in rows if g]
    mean = round(sum(g["v2Score50"] for g in graded) / len(graded), 1) if graded else None
    low = sorted(((round(sum(v) / len(v), 2), k) for k, v in crit.items()))
    md = ["# Grader calibration", "",
          f"Run `{os.path.basename(run)}`: {len(graded)} concept images graded blind by "
          f"{', '.join(sorted({g.get('grader', '?') for g in graded}))} with docs/lookloop/GRADING.md as it stood at "
          f"`{subprocess.run(['git', 'log', '-1', '--format=%h', '--', 'docs/lookloop/GRADING.md'], cwd=ROOT, capture_output=True, text=True).stdout.strip()}`.", "",
          f"**Mean {mean}/50**, {sum(1 for g in graded if g['gatePass'])}/{len(graded)} pass the v2 gate, "
          f"{sum(1 for g in graded if g.get('adPass'))}/{len(graded)} the art-direction bar (osm-credit-missing ignored: concepts carry no credit). "
          "Concept art should score high; the known, documented concept errors (enlarged dog, oversized sun disk, invented "
          "parcels, mis-placed Moon) are legitimate deductions, not calibration failures.", "",
          "| Frame | Concept | Used by | /50 | AD | Gate | Lowest criteria |", "|---|---|---|---|---|---|---|"]
    for cid, c, g in rows:
        if not g:
            md.append(f"| {cid} | {c['source'].split('/')[-1]} | {c['usedBy']} | – | – | not graded | |")
            continue
        lows = sorted(((s["score"], k) for sect in ("scores", "artDirection") for k, s in g[sect].items()
                       if s.get("score") is not None and s["score"] <= 3))
        md.append(f"| {cid} | {c['source'].split('/')[-1]} | {c['usedBy']} | {g['v2Score50']} | {g.get('adMean')} | "
                  f"{'pass' if g['gatePass'] else 'fail'} | {', '.join(f'{k} {s}' for s, k in lows[:4]) or '–'} |")
    md += ["", "Criterion means (lowest first): " + ", ".join(f"{k} {m}" for m, k in low), ""]
    out = os.path.join(run, "calibration.md")
    open(out, "w").write("\n".join(md) + "\n")
    print("\n".join(md))


if __name__ == "__main__":
    if sys.argv[1] == "--report":
        report(os.path.abspath(sys.argv[2]))
    elif sys.argv[1] == "--paintover":
        build(os.path.abspath(sys.argv[2]), paintover=True)
    elif sys.argv[1] == "--merge-paintover":
        merge_paintover(os.path.abspath(sys.argv[2]))
    else:
        build(os.path.abspath(sys.argv[1]))
