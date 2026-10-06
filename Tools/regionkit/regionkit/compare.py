"""Accuracy check: draft vs a hand-made reference profile, and reference vs raw measurements.

Every comparable field gets a verdict:
- agree / differ (within the stated tolerance), only when the draft value was CALIBRATED from data;
- "not measurable" when the draft field is template-only (no information), or the data gate failed;
- "excluded" for thresholds in the Denver check (they are calibrated on Denver itself).
Score = agree / (agree + differ).

Expected values are evaluated on the zone's OWN measured houses for both profiles (same footprints,
levels and frontage), with the generator's situation/eligibility rules (rules.type_probabilities).
"""
import math
from collections import Counter

from . import colours, draft, rules, stats

TOL = {
    "roofMix": 0.10,            # total variation distance
    "floors": 0.15,             # TVD of 1 / 2 / 3+ default-floor shares
    "perFloor": 0.15,           # metres
    "pitch": 4.0,               # degrees
    "threshold": 0.15,          # relative
    "share": 0.05,              # absolute (deciduousShare, youngShare)
    "treeHeight": 2.0,          # metres (range midpoint)
    "garageRoof": 0.15,         # TVD
    "colour": 10.0,             # CIEDE2000
}


def _mix_str(m):
    return "/".join("%.2f" % (m.get(k) or 0) for k in ("gabled", "hipped", "flat"))


def _floor_str(m):
    return "/".join("-" if m.get(k) is None else "%.2f" % m[k] for k in ("1", "2", "3+"))


def weighted_colour(houses, profile, slot):
    """Usage-weighted mean colour (CIELAB) of a tuple slot over the house types the zone would use."""
    u = draft.usage(houses, profile)
    types = {h["id"]: h for h in profile["houseTypes"]}
    L = a = b = W = 0.0
    for tid, w in u.items():
        cols = types[tid]["colors"]
        for t in cols:
            lab = colours.hex_to_lab(t[slot])
            ww = w / len(cols)
            L += ww * lab[0]
            a += ww * lab[1]
            b += ww * lab[2]
            W += ww
    if W <= 0:
        return None
    return colours.lab_to_hex((L / W, a / W, b / W))


def mid(r):
    return (r[0] + r[1]) / 2 if r else None


def _pitched(p):
    return {h["id"] for h in p["houseTypes"] if draft.norm_mix(h["roof"])["flat"] < 0.999}


def compare(draft_p, ref_p, cells, prov, exclude_thresholds=False):
    B = [b for c in cells for b in c.buildings]
    H = [b for b in B if b["role"] == "house" and not b.get("probable_garage")]   # principal houses
    rows = []

    def status(field):
        return prov.items.get(field, {}).get("status"), prov.items.get(field, {}).get("n", 0)

    def row(field, dval, rval, metric, tol, n, measurable, ok, unit="", note=""):
        if not measurable:
            verdict = "not measurable"
        else:
            verdict = "agree" if ok else "differ"
        rows.append({"field": field, "draft": dval, "reference": rval, "metric": metric, "tolerance": tol, "n": n,
                     "verdict": verdict, "note": note})

    st, n = status("houseTypes[].roof")
    ed, er = draft.expected_roof_mix(H, draft_p), draft.expected_roof_mix(H, ref_p)
    d = draft.tvd(ed, er, draft.ROOF_KEYS)
    row("house roof mix G/H/F (expected on zone houses)", _mix_str(ed), _mix_str(er), "TVD %.3f" % d, TOL["roofMix"], n,
        st == "calibrated", d <= TOL["roofMix"])

    st, n = status("typeRules.unknown/small/large")
    fd, truth, cov, nt = draft.stratified_floors(H, draft_p)
    fr, _, _, _ = draft.stratified_floors(H, ref_p)
    ok_vals = fd is not None and fr is not None
    d = draft.tvd(fd, fr, ("1", "2", "3+")) if ok_vals else None
    row("default floors 1/2/3+ (houses without levels; size-stratified test on tagged houses)", _floor_str(fd) if fd else "-", _floor_str(fr) if fr else "-",
        "TVD %.3f" % d if d is not None else "-", TOL["floors"], nt, st == "calibrated" and d is not None, d is not None and d <= TOL["floors"],
        note=("truth %s (bins covering %d%% of untagged houses); TVD to truth: draft %.3f, reference %.3f" % (
            _floor_str(truth), round(100 * cov), draft.tvd(fd, truth, ("1", "2", "3+")), draft.tvd(fr, truth, ("1", "2", "3+")))) if ok_vals else "")

    st, n = status("houseTypes[].perFloor")
    vd = draft.weighted_family_value(H, draft_p, lambda h: mid(h["perFloor"]))
    vr = draft.weighted_family_value(H, ref_p, lambda h: mid(h["perFloor"]))
    row("perFloor m (usage-weighted midpoint)", round(vd, 2) if vd else None, round(vr, 2) if vr else None,
        "|d| %.2f" % abs(vd - vr) if vd and vr else "-", TOL["perFloor"], n, st == "calibrated", vd and vr and abs(vd - vr) <= TOL["perFloor"])

    st, n = status("houseTypes[].pitch")
    vd = draft.weighted_family_value(H, draft_p, lambda h: mid(h["pitch"]), _pitched(draft_p))
    vr = draft.weighted_family_value(H, ref_p, lambda h: mid(h["pitch"]), _pitched(ref_p))
    row("pitch deg (usage-weighted midpoint, pitched families)", round(vd, 1) if vd else None, round(vr, 1) if vr else None,
        "|d| %.1f" % abs(vd - vr) if vd and vr else "-", TOL["pitch"], n, st == "calibrated", vd and vr and abs(vd - vr) <= TOL["pitch"])

    st, n = status("typeThresholds.smallArea/largeArea/hugeArea")
    for key in ("smallArea", "largeArea", "hugeArea"):
        a, b = draft_p["typeThresholds"][key], ref_p["typeThresholds"][key]
        rel = abs(a - b) / b if b else None
        row("typeThresholds.%s m2" % key, a, b, "rel %.2f" % rel, TOL["threshold"], n, st == "calibrated", rel <= TOL["threshold"],
            note="")
        if exclude_thresholds:
            rows[-1]["verdict"] = "excluded"
            rows[-1]["note"] = "calibrated on Denver (percentile transfer is an identity here)"

    st, n = status("trees.deciduousShare")
    a, b = draft_p["trees"]["deciduousShare"], ref_p["trees"]["deciduousShare"]
    row("trees.deciduousShare (non-conifer share)", a, b, "|d| %.3f" % abs(a - b), TOL["share"], n, st == "calibrated", abs(a - b) <= TOL["share"])
    st, n = status("trees.heightMeters")
    a, b = draft_p["trees"]["heightMeters"], ref_p["trees"]["heightMeters"]
    row("trees.heightMeters (midpoint)", a, b, "|d| %.1f" % abs(mid(a) - mid(b)), TOL["treeHeight"], n, st == "calibrated", abs(mid(a) - mid(b)) <= TOL["treeHeight"])
    st, n = status("trees.youngShare")
    a, b = draft_p["trees"]["youngShare"], ref_p["trees"]["youngShare"]
    row("trees.youngShare", a, b, "|d| %.3f" % abs(a - b), TOL["share"], n, st == "calibrated", abs(a - b) <= TOL["share"])

    st, n = status("garage.roof")
    a, b = draft.norm_mix(draft_p["garage"].get("roof") or {}), draft.norm_mix(ref_p["garage"].get("roof") or {})
    d = draft.tvd(a, b, draft.ROOF_KEYS)
    row("garage.roof G/H/F", _mix_str(a), _mix_str(b), "TVD %.3f" % d, TOL["garageRoof"], n, st == "calibrated", d <= TOL["garageRoof"])

    for slot, name, key in ((0, "wall", "houseTypes[].colors[wall]"), (3, "roof", "houseTypes[].colors[roof]")):
        st, n = status(key)
        a, b = weighted_colour(H, draft_p, slot), weighted_colour(H, ref_p, slot)
        d = colours.delta_e2000(a, b) if a and b else None
        row("%s colour (usage-weighted mean)" % name, a, b, "dE00 %.1f" % d if d is not None else "-", TOL["colour"], n,
            st == "calibrated" and d is not None, d is not None and d <= TOL["colour"])

    for f, note in (("trees.crownWeights", "template only"), ("trees.youngHeightMeters", "template only"),
                    ("typeThresholds aspect/rectangularity", "template only"), ("porch/windows/door/overhang/parapet", "template only"),
                    ("chimneyLikelihood", "template only"), ("foundationMeters", "template only"),
                    ("garage wallHeight/pitch/colours, shed", "template only")):
        rows.append({"field": f, "draft": "-", "reference": "-", "metric": "-", "tolerance": "-", "n": 0, "verdict": "not measurable", "note": note})
    sd, sr = draft_p["seasons"], ref_p["seasons"]
    rows.append({"field": "seasons (hemisphere + months)", "draft": sd["hemisphere"], "reference": sr["hemisphere"],
                 "metric": "equal" if sd == sr else "different", "tolerance": "-", "n": 0, "verdict": "not scored",
                 "note": "rule-based from latitude, not data"})
    agree = sum(1 for r in rows if r["verdict"] == "agree")
    differ = sum(1 for r in rows if r["verdict"] == "differ")
    return {"rows": rows, "agree": agree, "differ": differ, "measurable": agree + differ,
            "score": round(agree / (agree + differ), 3) if agree + differ else None}


def _share_tol(p, n, base):
    if not n or p is None:
        return base
    return max(base, 1.96 * math.sqrt(max(p * (1 - p), 1e-9) / n))


def direct_tests(ref_p, cells, denver_house_areas, gates=None):
    """Tests a reference profile's values directly against raw (unshrunk) measurements."""
    B = [b for c in cells for b in c.buildings]
    H = [b for b in B if b["role"] == "house" and not b.get("probable_garage")]   # principal houses
    G = [b for b in B if b["role"] == "garage"]
    T = [x for c in cells for x in c.trees]
    rows = []

    def add(field, ref, meas, n, gate, ok, metric, tol, note=""):
        verdict = "can't test" if n < gate else ("supports" if ok else "contradicts")
        rows.append({"field": field, "reference": ref, "measured": meas, "n": n, "gate": gate, "metric": metric,
                     "tolerance": tol, "verdict": verdict, "note": note})

    tagged = Counter(rules.map_roof(b["roof_shape"]) for b in H if rules.map_roof(b["roof_shape"]) in draft.ROOF_KEYS)
    n = sum(tagged.values())
    er = draft.expected_roof_mix(H, ref_p)
    meas = {k: tagged[k] / n for k in draft.ROOF_KEYS} if n else {}
    d = draft.tvd(er, meas, draft.ROOF_KEYS) if n else None
    add("house roof mix G/H/F vs roof:shape", _mix_str(er), _mix_str(meas) if n else "-", n, draft.GATE_ROOF, d is not None and d <= TOL["roofMix"],
        "TVD %.3f" % d if d is not None else "-", TOL["roofMix"], "tagged houses may not be representative")

    fr, mm, cov, nt = draft.stratified_floors(H, ref_p)
    d = draft.tvd(fr, mm, ("1", "2", "3+")) if fr is not None else None
    add("default floors 1/2/3+ vs building:levels (size-stratified, levels hidden from the profile)", _floor_str(fr) if fr else "-",
        _floor_str(mm) if mm else "-", nt, draft.GATE_LEVELS, d is not None and d <= TOL["floors"], "TVD %.3f" % d if d is not None else "-", TOL["floors"],
        "tagged principal houses evaluated as if untagged, per footprint-area bin weighted like the untagged houses (bins cover %d%%)" % round(100 * cov))

    typed = [x for x in T if x["leaf_type"] in ("broadleaved", "needleleaved")]
    p = sum(1 for x in typed if x["leaf_type"] == "broadleaved") / len(typed) if typed else None
    ref = ref_p["trees"]["deciduousShare"]
    tol = _share_tol(p, len(typed), TOL["share"])
    add("trees.deciduousShare vs broadleaved share", ref, round(p, 3) if p is not None else "-", len(typed), draft.GATE_LEAF,
        p is not None and abs(p - ref) <= tol, "|d| %.3f" % abs(p - ref) if p is not None else "-", round(tol, 3))

    hs = [x["height"] for x in T if x["height"] is not None]
    if hs:
        q = [stats.percentile(hs, 0.25), stats.percentile(hs, 0.75)]
        add("trees.heightMeters vs tagged heights p25-p75", ref_p["trees"]["heightMeters"], [round(q[0], 1), round(q[1], 1)], len(hs), 30,
            abs(mid(q) - mid(ref_p["trees"]["heightMeters"])) <= TOL["treeHeight"], "|d mid| %.1f" % abs(mid(q) - mid(ref_p["trees"]["heightMeters"])), TOL["treeHeight"])
        ys = sum(1 for h in hs if h < draft.YOUNG_HEIGHT_M) / len(hs)
        tol = _share_tol(ys, len(hs), TOL["share"])
        add("trees.youngShare vs share of tagged heights < 7 m", ref_p["trees"]["youngShare"], round(ys, 3), len(hs), 30,
            abs(ys - ref_p["trees"]["youngShare"]) <= tol, "|d| %.3f" % abs(ys - ref_p["trees"]["youngShare"]), round(tol, 3))
    else:
        add("trees.heightMeters vs tagged heights p25-p75", ref_p["trees"]["heightMeters"], "-", 0, 30, False, "-", TOL["treeHeight"])

    areas = [b["area"] for b in H]
    for key in ("smallArea", "largeArea", "hugeArea"):
        if areas and denver_house_areas:
            pq = stats.ecdf(denver_house_areas, draft.FRONT_RANGE_THRESHOLDS[key])
            q = stats.percentile(areas, pq)
            refv = ref_p["typeThresholds"][key]
            rel = abs(q - refv) / refv
            add("typeThresholds.%s vs footprint quantile at Denver's percentile" % key, refv, round(q, 1), len(areas), draft.GATE_THRESHOLDS,
                rel <= TOL["threshold"], "rel %.2f" % rel, TOL["threshold"],
                "share of zone houses below the reference value: %.3f (front-range %s is the %.3f quantile in Denver)" % (
                    stats.ecdf(areas, refv), int(draft.FRONT_RANGE_THRESHOLDS[key]), pq))

    gt = Counter(rules.map_roof(b["roof_shape"]) for b in G if rules.map_roof(b["roof_shape"]) in draft.ROOF_KEYS)
    n = sum(gt.values())
    gr = draft.norm_mix(ref_p["garage"].get("roof") or {})
    gm = {k: gt[k] / n for k in draft.ROOF_KEYS} if n else {}
    d = draft.tvd(gr, gm, draft.ROOF_KEYS) if n else None
    add("garage.roof vs garage roof:shape", _mix_str(gr), _mix_str(gm) if n else "-", n, draft.GATE_GARAGE_ROOF,
        d is not None and d <= TOL["garageRoof"], "TVD %.3f" % d if d is not None else "-", TOL["garageRoof"])

    wall = []
    for b in H:
        if b["height"] is None or not b["levels_raw"]:
            continue
        if b["roof_height"] is not None:
            wall.append((b["height"] - b["roof_height"]) / b["levels_raw"])
        elif b["roof_shape"] == "flat":
            wall.append(b["height"] / b["levels_raw"])
    vr = draft.weighted_family_value(H, ref_p, lambda h: mid(h["perFloor"]))
    if wall:
        m = stats.percentile(wall, 0.5)
        add("perFloor vs measured wall height per level (median)", round(vr, 2), round(m, 2), len(wall), draft.GATE_PERFLOOR,
            abs(m - vr) <= TOL["perFloor"], "|d| %.2f" % abs(m - vr), TOL["perFloor"])
    else:
        add("perFloor vs measured wall height per level (median)", round(vr, 2) if vr else None, "-", 0, draft.GATE_PERFLOOR, False, "-", TOL["perFloor"])

    ang = [b["roof_angle"] for b in H if b["roof_angle"] is not None and 0 < b["roof_angle"] < 75]
    vr = draft.weighted_family_value(H, ref_p, lambda h: mid(h["pitch"]), _pitched(ref_p))
    if ang:
        m = stats.percentile(ang, 0.5)
        add("pitch vs roof:angle (median)", round(vr, 1) if vr else None, round(m, 1), len(ang), draft.GATE_PITCH,
            vr is not None and abs(m - vr) <= TOL["pitch"], "|d| %.1f" % abs(m - vr) if vr else "-", TOL["pitch"])
    else:
        add("pitch vs roof:angle (median)", round(vr, 1) if vr else None, "-", 0, draft.GATE_PITCH, False, "-", TOL["pitch"])

    from . import measure
    mt = measure.material_table()
    for slot, name, ck, mk, tbl in ((0, "wall", "building_colour", "building_material", mt["wall"]),
                                    (3, "roof", "roof_colour", "roof_material", mt["roof"])):
        ev = draft.colour_evidence(H, ck, mk, tbl)
        allh = [h for v in ev.values() for h in v]
        refc = weighted_colour(H, ref_p, slot)
        if allh:
            labs = [colours.hex_to_lab(h) for h in allh]
            mean = colours.lab_to_hex(tuple(sum(c[i] for c in labs) / len(labs) for i in range(3)))
            d = colours.delta_e2000(refc, mean)
            fam = Counter({f: len(v) for f, v in ev.items()}).most_common(3)
            add("%s colour vs measured colour/material (mean)" % name, refc, mean, len(allh), draft.GATE_COLOUR, d <= TOL["colour"],
                "dE00 %.1f" % d, TOL["colour"], "top families: " + ", ".join("%s %d" % kv for kv in fam))
        else:
            add("%s colour vs measured colour/material (mean)" % name, refc, "-", 0, draft.GATE_COLOUR, False, "-", TOL["colour"])
    sup = sum(1 for r in rows if r["verdict"] == "supports")
    con = sum(1 for r in rows if r["verdict"] == "contradicts")
    return {"rows": rows, "supports": sup, "contradicts": con, "cantTest": sum(1 for r in rows if r["verdict"] == "can't test")}
