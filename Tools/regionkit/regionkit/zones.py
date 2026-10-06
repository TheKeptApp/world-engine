"""Zone questions: catalog-box checks for the sample cells, and whether cells separate by zone on
measured OSM signatures (leave-one-out nearest-centroid test)."""
import math
from collections import Counter

from . import geo, measure, stats

SIGNATURE_FEATURES = ["buildingsPerKm2", "houseShare", "blockShare", "houseFootprintP50", "grossCoverage", "alleyKmPerKm2",
                      "share3PlusLevels"]


def first_match(catalog, lat, lon):
    for r in catalog["regions"]:
        b = r["bounds"]
        if b["south"] <= lat <= b["north"] and b["west"] <= lon <= b["east"]:
            return r
    return None


def _box_local(cell, b):
    """Catalog box (lat/lon) -> rectangle in the cell's local frame (axis-aligned approximation)."""
    fr = cell.frame
    x0, y0 = fr.xy(b["south"], b["west"])
    x1, y1 = fr.xy(b["north"], b["east"])
    return (min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1))


def _overlap(a, b):
    w = min(a[2], b[2]) - max(a[0], b[0])
    h = min(a[3], b[3]) - max(a[1], b[1])
    return max(0.0, w) * max(0.0, h)


def catalog_check(cell, catalog, expected_profile):
    lat, lon = cell.spec["center"]
    hit = first_match(catalog, lat, lon)
    boxes = []
    for i, r in enumerate(catalog["regions"]):
        rect = _box_local(cell, r["bounds"])
        ov = _overlap(cell.rect, rect)
        if ov > 0:
            boxes.append({"order": i, "id": r["id"], "profile": r["profile"], "cellAreaShare": round(ov / cell.area_m2, 3)})
    # area of the cell that first-match resolution assigns to each profile (1 m raster is overkill: 10 m grid)
    step = 10.0
    cnt = Counter()
    x0, y0, x1, y1 = cell.rect
    nx, ny = int((x1 - x0) / step), int((y1 - y0) / step)
    rects = [(r, _box_local(cell, r["bounds"])) for r in catalog["regions"]]
    for i in range(nx):
        for j in range(ny):
            px, py = x0 + (i + 0.5) * step, y0 + (j + 0.5) * step
            prof = catalog.get("defaultProfile")
            for r, rc in rects:
                if rc[0] <= px <= rc[2] and rc[1] <= py <= rc[3]:
                    prof = r["profile"]
                    break
            cnt[prof] += 1
    tot = sum(cnt.values())
    area_by_profile = {k: round(v / tot, 3) for k, v in cnt.most_common()}
    return {"center": [lat, lon], "firstMatchBox": hit["id"] if hit else None,
            "profileAtCenter": hit["profile"] if hit else catalog.get("defaultProfile"),
            "expectedProfile": expected_profile,
            "centerMatchesExpected": (hit["profile"] if hit else catalog.get("defaultProfile")) == expected_profile,
            "overlappingBoxes": boxes, "cellAreaByResolvedProfile": area_by_profile,
            "note": "the engine picks ONE profile per baked area at the manifest centre (WorldBuild.swift line 39); "
                    "cellAreaByResolvedProfile shows what per-feature selection would give instead"}


def box_signatures(cells, catalog):
    """Signature of the buildings that fall inside each catalog box, using only the sampled cells."""
    out = {}
    for r in catalog["regions"]:
        bs, area = [], 0.0
        for c in cells:
            rect = _box_local(c, r["bounds"])
            ov = _overlap(c.rect, rect)
            if ov <= 0:
                continue
            area += ov
            for b in c.buildings:
                p = b["poly"].centroid
                if rect[0] <= p[0] <= rect[2] and rect[1] <= p[1] <= rect[3]:
                    bs.append(b)
        if area < 0.1e6:
            continue
        roles = Counter(b["role"] for b in bs)
        H = [b for b in bs if b["role"] == "house"]
        lv = [b["levels_int"] for b in bs if b["levels_raw"] is not None and b["levels_int"] and b["levels_int"] > 0]
        out[r["id"]] = {"profile": r["profile"], "sampledKm2": round(area / 1e6, 3), "buildings": len(bs),
                        "buildingsPerKm2": round(len(bs) / (area / 1e6), 1),
                        "houseShare": stats.share(roles["house"], len(bs)), "blockShare": stats.share(roles["block"], len(bs)),
                        "houseFootprintP50": round(stats.percentile([b["area"] for b in H], 0.5), 1) if H else None,
                        "share3PlusLevels": stats.share(sum(1 for x in lv if x >= 3), len(lv)), "levelsTagged": len(lv)}
    return out


def _z(rows, feats):
    vals = {f: [r[f] for r in rows if r.get(f) is not None] for f in feats}
    mu = {f: (sum(v) / len(v) if v else 0.0) for f, v in vals.items()}
    sd = {f: (math.sqrt(sum((x - mu[f]) ** 2 for x in v) / len(v)) if len(v) > 1 else 1.0) or 1.0 for f, v in vals.items()}
    return mu, sd


def separation_test(cell_rows, feats=None):
    """cell_rows: [{"zone", "cell", signature fields...}]. Leave-one-out nearest-centroid on z-scored
    features (missing values -> the feature mean, i.e. 0 after z-scoring)."""
    feats = feats or SIGNATURE_FEATURES
    mu, sd = _z(cell_rows, feats)

    def vec(r):
        return [((r[f] - mu[f]) / sd[f]) if r.get(f) is not None else 0.0 for f in feats]

    results = []
    correct = 0
    for i, r in enumerate(cell_rows):
        others = [o for j, o in enumerate(cell_rows) if j != i]
        cents = {}
        for z in sorted(set(o["zone"] for o in others)):
            vs = [vec(o) for o in others if o["zone"] == z]
            cents[z] = [sum(v[k] for v in vs) / len(vs) for k in range(len(feats))]
        v = vec(r)
        dists = sorted((math.sqrt(sum((a - b) ** 2 for a, b in zip(v, c))), z) for z, c in cents.items())
        pred = dists[0][1] if dists else None
        ok = pred == r["zone"]
        correct += ok
        results.append({"cell": r["cell"], "zone": r["zone"], "predicted": pred, "correct": ok,
                        "zoneHasOtherCells": any(o["zone"] == r["zone"] for o in others),
                        "nearest": [[z, round(d, 2)] for d, z in dists[:3]]})
    testable = [x for x in results if x["zoneHasOtherCells"]]
    return {"features": feats, "standardisation": {f: {"mean": round(mu[f], 3), "sd": round(sd[f], 3)} for f in feats},
            "results": results, "accuracyAll": round(correct / len(results), 3) if results else None,
            "accuracyTestable": round(sum(1 for x in testable if x["correct"]) / len(testable), 3) if testable else None,
            "note": "leave-one-out: a cell whose zone has no other cell can never be classified correctly (counted in accuracyAll only)"}
