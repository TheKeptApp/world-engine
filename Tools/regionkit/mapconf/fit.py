"""Calibration tables for the map data layer's confidences (docs/research/map-confidence.md).

Reads per-record outcome files from the work directory (outside the repo), puts each record in its bin with the same
rules as Sources/WorldPackage/MapLayer/MapCalibration.swift, and writes the aggregate table (bin -> n, successes,
share, leave-one-area-out check) to results/calibration.json. The confidence of a bin is its pooled share; bins under
MIN_N records fall back to their parent bin.

  python3 Tools/regionkit/mapconf/fit.py --work /tmp/claude-mapconf-work --out Tools/regionkit/mapconf/results/calibration.json
"""
import argparse
import collections
import glob
import json
import os

MIN_N = 30
AREAS = ("sloans-lake", "evanston-south", "lakeview-sheil-park")


def band(x, edges, names):
    for e, n in zip(edges, names):
        if x < e:
            return n
    return names[-1]


def frontage_bin(r):
    if r["corner"]:
        return "corner/" + band(r["otherStreetM"], [20, 30], ["other<20", "other20-30", "other30-40"])
    return "street/" + band(r["distanceM"], [12, 20], ["d<12", "d12-20", "d>=20"])


def lot_bin(r):
    if r["droppedShare"] >= 0.05:
        return f"{r['part']}/split"
    if r["part"] == "back":
        return "back/" + band(r["areaM2"], [150, 250, 600], ["a<150", "a150-250", "a250-600", "a>=600"])
    if r["areaM2"] < 40:
        return "front/a<40"
    if r["areaM2"] >= 250:
        return "front/a>=250"
    return "front/a40-250/" + band(r["frontageM"], [12, 16, 20, 30], ["f<12", "f12-16", "f16-20", "f20-30", "f>=30"])


def door_bin(r):
    return "all"


def driveway_bin(r):
    return "all"


BINS = {"frontage": frontage_bin, "lots": lot_bin, "door": door_bin, "driveway": driveway_bin}


def load(work, kind):
    out = []
    for f in sorted(glob.glob(os.path.join(work, f"{kind}-*.json"))):
        d = json.load(open(f))
        for r in d["records"]:
            if r.get("outcome") is not None:
                out.append({**r, "area": d["area"]})
    return out


def table(recs, key):
    g = collections.defaultdict(list)
    for r in recs:
        g[key(r)].append(r)
    out = {}
    for b, rr in sorted(g.items()):
        n, k = len(rr), sum(x["outcome"] for x in rr)
        e = {"n": n, "success": k, "share": round(k / n, 3), "byArea": {}}
        for a in AREAS:
            ra = [x for x in rr if x["area"] == a]
            if ra:
                e["byArea"][a] = {"n": len(ra), "share": round(sum(x["outcome"] for x in ra) / len(ra), 3)}
        # Leave one area out: the share from the other areas, compared with the held-out area's share.
        gaps = []
        for a in AREAS:
            held = [x for x in rr if x["area"] == a]
            rest = [x for x in rr if x["area"] != a]
            if len(held) >= 10 and rest:
                gaps.append(abs(sum(x["outcome"] for x in rest) / len(rest) - sum(x["outcome"] for x in held) / len(held)))
        e["leaveOneAreaOutMaxGap"] = round(max(gaps), 3) if gaps else None
        out[b] = e
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--work", required=True)
    p.add_argument("--out", required=True)
    a = p.parse_args()
    result = {"definition": {
        "frontage": "share of buildings with OSM addr:street whose frontage segment's name is that street (names normalized)",
        "lots": "share of lots whose outline overlaps the yard cut from the parcel (parcel minus footprint, split at the same front line) at IoU >= 0.6",
        "door": "share of labelled front doors whose blind NAIP label lies on the same wall within 2.0 m along it",
        "driveway": "share of labelled driveway ends whose blind NAIP label lies within 3.0 m",
    }, "minN": MIN_N, "tables": {}}
    for kind, key in BINS.items():
        recs = load(a.work, kind)
        if recs:
            result["tables"][kind] = {"n": len(recs), "share": round(sum(r["outcome"] for r in recs) / len(recs), 3), "bins": table(recs, key)}
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    with open(a.out, "w") as f:
        json.dump(result, f, indent=2, sort_keys=True)
        f.write("\n")
    for kind, t in result["tables"].items():
        print(kind, t["n"], t["share"])
        for b, e in t["bins"].items():
            print(f"   {b:28s} n={e['n']:5d} share={e['share']:.3f} looGap={e['leaveOneAreaOutMaxGap']}")


if __name__ == "__main__":
    main()
