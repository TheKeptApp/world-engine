"""Draft profile = template + calibration (+ shrinkage toward the template), with provenance.

Shrinkage: value = (n * measured + k * template) / (n + k), k = 30 by default (K_DEFAULT).
Gates (minimum sample sizes) follow the brief; below a gate the template value is kept.
Status per field: "calibrated" (data moved the value), "template" (copied, no usable data),
"default" (rule-based, e.g. meteorological seasons from latitude).
"""
import copy
import math
from collections import Counter

from . import colours, rules, stats

K_DEFAULT = 30
GATE_ROOF = 30
GATE_LEVELS = 30
GATE_PERFLOOR = 20
GATE_PITCH = 20
GATE_TREE_HEIGHT = 30
GATE_LEAF = 30
GATE_COLOUR = 30
GATE_GARAGE_ROOF = 20
GATE_THRESHOLDS = 30
PERFLOOR_BAND = (2.6, 3.8)
YOUNG_HEIGHT_M = 7.0
ROOF_KEYS = ("gabled", "hipped", "flat")
AREA_BINS = [0, 40, 60, 90, 130, 180, 250, 400, float("inf")]
AREA_BIN_LABELS = ["<40", "40-60", "60-90", "90-130", "130-180", "180-250", "250-400", ">=400"]


def area_bin(a):
    for i in range(len(AREA_BINS) - 1):
        if AREA_BINS[i] <= a < AREA_BINS[i + 1]:
            return i
    return len(AREA_BINS) - 2


# front-range reference points for the threshold percentile transfer (Sloan's Lake houses).
FRONT_RANGE_THRESHOLDS = {"smallArea": 60.0, "largeArea": 220.0, "hugeArea": 350.0}


def r3(x):
    return None if x is None else round(x, 3)


def norm_mix(m):
    tot = sum(max(0.0, m.get(k, 0) or 0) for k in ROOF_KEYS)
    if tot <= 0:
        return {k: 0.0 for k in ROOF_KEYS}
    return {k: max(0.0, m.get(k, 0) or 0) / tot for k in ROOF_KEYS}


def tvd(a, b, keys):
    return 0.5 * sum(abs((a.get(k) or 0) - (b.get(k) or 0)) for k in keys)


class Prov:
    def __init__(self):
        self.items = {}

    def add(self, field, status, value, n=0, source="", template=None, measured=None, note=""):
        self.items[field] = {"status": status, "value": value, "n": n, "source": source,
                             "templateValue": template, "measuredValue": measured, "note": note}


# --- usage model ------------------------------------------------------------------------------
def house_situations(houses, profile, mask_levels=False):
    """(house, situation key, levels for eligibility). mask_levels=True pretends building:levels is absent."""
    t = profile["typeThresholds"]
    out = []
    for b in houses:
        lv = None if mask_levels else b["levels_raw"]
        key = rules.situation(b["type"], lv, b["area"], b["aspect"], b["rect"], b["broad_front"], t)
        li = b["levels_int"] if (lv is not None) else None
        out.append((b, key, li))
    return out


def usage(houses, profile):
    """Expected number of houses per house type (generator's weights + eligibility, per house)."""
    u = Counter()
    for b, key, li in house_situations(houses, profile):
        for tid, p in rules.type_probabilities(profile, key, li, b["aspect"], b["rect"], b["broad_front"]).items():
            u[tid] += p
    return u


def expected_roof_mix(houses, profile):
    u = usage(houses, profile)
    tot = sum(u.values())
    types = {h["id"]: h for h in profile["houseTypes"]}
    mix = {k: 0.0 for k in ROOF_KEYS}
    if tot <= 0:
        return mix
    for tid, w in u.items():
        m = norm_mix(types[tid]["roof"])
        for k in ROOF_KEYS:
            mix[k] += w * m[k] / tot
    return mix


def has_levels(b):
    return b["levels_raw"] is not None and b["levels_int"] is not None and b["levels_int"] > 0


def expected_default_floors(houses, profile, mask_levels=False):
    """Share of houses WITHOUT building:levels that get 1 / 2 / 3+ default wall floors (first entry of
    the chosen type's floors list). mask_levels=True evaluates tagged houses as if untagged (to test a
    profile's defaults against the real levels of those houses)."""
    types = {h["id"]: h for h in profile["houseTypes"]}
    cnt = Counter()
    tot = 0.0
    for b, key, li in house_situations(houses, profile, mask_levels=mask_levels):
        if li is not None and li > 0:
            continue
        for tid, p in rules.type_probabilities(profile, key, None, b["aspect"], b["rect"], b["broad_front"]).items():
            f = types[tid]["floors"][0]
            cnt["1" if f == 1 else "2" if f == 2 else "3+"] += p
            tot += p
    return {k: (cnt[k] / tot if tot else None) for k in ("1", "2", "3+")}


def floor_group(f):
    return "1" if f == 1 else "2" if f == 2 else "3+"


def stratified_floors(houses, profile):
    """Default-floor test on the population the rule applies to. Tagged houses are evaluated with their
    levels hidden; both the profile's expected default floors and the true floors are averaged per
    footprint-area bin and weighted by where the UNTAGGED houses are (bins without tagged houses are
    dropped). Returns (expected, truth, covered share of untagged houses, n tagged)."""
    tagged = [b for b in houses if has_levels(b)]
    untagged = [b for b in houses if not has_levels(b)] or tagged
    ub = Counter(area_bin(b["area"]) for b in untagged)
    exp = Counter()
    tru = Counter()
    covered = 0.0
    for bn, cnt in ub.items():
        tb = [b for b in tagged if area_bin(b["area"]) == bn]
        if not tb:
            continue
        wgt = cnt / len(untagged)
        covered += wgt
        e = expected_default_floors(tb, profile, mask_levels=True)
        for g in ("1", "2", "3+"):
            exp[g] += wgt * (e[g] or 0)
        tc = Counter(floor_group(b["levels_int"]) for b in tb)
        for g in ("1", "2", "3+"):
            tru[g] += wgt * tc[g] / len(tb)
    if covered <= 0:
        return None, None, 0.0, len(tagged)
    return ({g: exp[g] / covered for g in ("1", "2", "3+")}, {g: tru[g] / covered for g in ("1", "2", "3+")},
            covered, len(tagged))


def weighted_family_value(houses, profile, fn, families=None):
    u = usage(houses, profile)
    types = {h["id"]: h for h in profile["houseTypes"]}
    num = den = 0.0
    for tid, w in u.items():
        if families is not None and tid not in families:
            continue
        v = fn(types[tid])
        if v is None:
            continue
        num += w * v
        den += w
    return num / den if den else None


# --- floor-group fit for typeRules ------------------------------------------------------------------
def fit_floor_groups(prof, key, w, types, grp, eval_sets, target, iters=200, tol=1e-4):
    """Scales the weights of `typeRules[key]` per default-floor group so that the expected default floors
    of the evaluation houses (levels hidden, generator eligibility applied) match `target`.
    Returns (new weights summing to 100, achieved shares, target share no family can represent)."""
    groups = {tid: grp(types[tid]["floors"][0]) for tid in w if tid in types}
    present = sorted(set(groups.values()))
    missing = sum(v for g, v in target.items() if g not in present)
    tp = sum(target[g] for g in present)
    tgt = {g: (target[g] / tp if tp else 0) for g in present}
    mult = {g: 1.0 for g in present}
    ids = sorted(tid for tid in w if tid in types)
    # Eligibility does not depend on the weights: precompute each house's candidate set once
    # (BuildingGenerator.houseType: eligible types, or all when none is eligible).
    cand_sets = []
    for wb, hs in eval_sets:
        for b in hs:
            elig = [tid for tid in ids if rules.eligible(types[tid], None, b["aspect"], b["rect"], b["broad_front"])]
            cand_sets.append((wb / len(hs), elig or ids))

    def expected():
        e = Counter()
        for wt, cands in cand_sets:
            ws = [(tid, max(0.0, w[tid]) * mult[groups[tid]]) for tid in cands]
            tot = sum(x for _, x in ws)
            if tot <= 0:
                continue
            for tid, x in ws:
                e[groups[tid]] += wt * x / tot
        t = sum(e.values())
        return {g: e[g] / t for g in present} if t else {g: 0 for g in present}

    e = expected()
    for _ in range(iters):
        worst = max(abs(e[g] - tgt[g]) for g in present) if present else 0
        if worst < tol:
            break
        for g in present:
            if e[g] > 0 and tgt[g] > 0:
                mult[g] *= tgt[g] / e[g]
            elif tgt[g] == 0:
                mult[g] *= 0.5
        e = expected()
    raw = {tid: max(0.0, x) * mult.get(groups.get(tid), 1.0) for tid, x in w.items()}
    tot = sum(raw.values())
    new_w = {tid: round(v / tot * 100, 2) if tot else x for (tid, v), x in zip(raw.items(), w.values())}
    return new_w, e, missing


# --- IPF ---------------------------------------------------------------------------------------
def ipf_roofs(rows, row_weights, target, iters=500, tol=1e-10):
    """Iterative proportional fitting of a family x roof-shape table.

    rows: {family: {gabled, hipped, flat}} (normalised template mixes); row_weights: {family: usage};
    target: {shape: share}. Zero cells stay zero. Returns (new rows, achieved mix, residual TVD, feasible)."""
    fams = [f for f in sorted(rows) if row_weights.get(f, 0) > 0]
    if not fams:
        return rows, None, None, False
    W = sum(row_weights[f] for f in fams)
    M = {f: {k: row_weights[f] * rows[f][k] for k in ROOF_KEYS} for f in fams}
    reachable = [k for k in ROOF_KEYS if any(M[f][k] > 0 for f in fams)]
    tsum = sum(target[k] for k in reachable)
    feasible = all(target[k] <= 1e-12 for k in ROOF_KEYS if k not in reachable)
    tgt = {k: (target[k] / tsum if tsum > 0 else 0) * W for k in reachable}
    for _ in range(iters):
        for k in reachable:
            cs = sum(M[f][k] for f in fams)
            if cs > 0:
                s = tgt[k] / cs
                for f in fams:
                    M[f][k] *= s
        delta = 0.0
        for f in fams:
            rs = sum(M[f].values())
            if rs > 0:
                s = row_weights[f] / rs
                for k in ROOF_KEYS:
                    M[f][k] *= s
                delta = max(delta, abs(s - 1))
        if delta < tol:
            break
    new = dict(rows)
    for f in fams:
        rs = sum(M[f].values())
        new[f] = {k: (M[f][k] / rs if rs else rows[f][k]) for k in ROOF_KEYS}
    achieved = {k: sum(M[f][k] for f in fams) / W for k in ROOF_KEYS}
    return new, achieved, tvd(achieved, target, ROOF_KEYS), feasible


# --- colour shift -----------------------------------------------------------------------------
def _band(hexes):
    lch = [colours.lab_to_lch(colours.hex_to_lab(h)) for h in hexes]
    return (min(c[0] for c in lch), max(c[0] for c in lch)), (min(c[1] for c in lch), max(c[1] for c in lch))


def shift_slot(profile, slot, evidence, n, k, prov_key, prov):
    """Moves tuple slot `slot` (0 wall, 3 roof) of every house type toward the measured colour families,
    in proportion to their measured shares (largest-remainder quotas, nearest tuples first), by
    alpha = n / (n + k) in CIELAB, then clamps L* and C* into the template's own band for that slot."""
    fam_hex = {}
    for fam, hexes in evidence.items():
        labs = [colours.hex_to_lab(h) for h in hexes]
        fam_hex[fam] = colours.lab_to_hex(tuple(sum(c[i] for c in labs) / len(labs) for i in range(3)))
    total = sum(len(v) for v in evidence.values())
    slots = [(i, j) for i, h in enumerate(profile["houseTypes"]) for j in range(len(h["colors"]))]
    template_hexes = [profile["houseTypes"][i]["colors"][j][slot] for i, j in slots]
    (lmin, lmax), (cmin, cmax) = _band(template_hexes)
    T = len(slots)
    raw = {f: len(v) / total * T for f, v in evidence.items()}
    quota = {f: int(math.floor(x)) for f, x in raw.items()}
    for f in sorted(raw, key=lambda f: (-(raw[f] - quota[f]), f))[:T - sum(quota.values())]:
        quota[f] += 1
    pairs = sorted(((colours.delta_e2000(template_hexes[s], fam_hex[f]), s, f) for s in range(T) for f in fam_hex),
                   key=lambda t: (t[0], t[1], t[2]))
    assigned = {}
    for d, s, f in pairs:
        if s in assigned or quota.get(f, 0) <= 0:
            continue
        assigned[s] = f
        quota[f] -= 1
    alpha = n / (n + k)
    changes = []
    for s, (i, j) in enumerate(slots):
        f = assigned.get(s)
        if f is None:
            continue
        a = colours.hex_to_lab(template_hexes[s])
        b = colours.hex_to_lab(fam_hex[f])
        mixed = tuple(a[q] + alpha * (b[q] - a[q]) for q in range(3))
        L, C, hdeg = colours.lab_to_lch(mixed)
        L = min(lmax, max(lmin, L))
        C = min(cmax, max(cmin, C))
        new = colours.lab_to_hex(colours.lch_to_lab((L, C, hdeg)))
        tup = profile["houseTypes"][i]["colors"][j]
        changes.append({"type": profile["houseTypes"][i]["id"], "tuple": j, "from": tup[slot], "to": new, "family": f,
                        "deltaE00": round(colours.delta_e2000(tup[slot], new), 1)})
        tup[slot] = new
    prov.add(prov_key, "calibrated", changes, n=n, source="building/roof colour + material tags (data/materials.json, data/colours.json)",
             measured={f: {"n": len(v), "meanHex": fam_hex[f]} for f, v in sorted(evidence.items())},
             note="alpha=%.2f; L* clamped to [%.1f, %.1f], C* to [%.1f, %.1f] (template band)" % (alpha, lmin, lmax, cmin, cmax))


def colour_evidence(houses, colour_key, material_key, table):
    ev = {}
    for b in houses:
        hx = None
        if b[colour_key]:
            hx, _ = colours.normalize(b[colour_key])
        if hx is None and b[material_key]:
            m = table.get(b[material_key].strip().lower())
            if m and m.get("hex"):
                hx = m["hex"]
        if hx:
            ev.setdefault(colours.family(hx), []).append(hx)
    return ev


# --- the draft ---------------------------------------------------------------------------------
def make_draft(zone_id, zone_name, region_id, cells, template, template_id, denver_house_areas, climate, k=K_DEFAULT,
               materials=None):
    prof = copy.deepcopy(template)
    prov = Prov()
    B = [b for c in cells for b in c.buildings]
    H = [b for b in B if b["role"] == "house"]
    G = [b for b in B if b["role"] == "garage"]
    T = [x for c in cells for x in c.trees]
    lat = sum(c.spec["center"][0] for c in cells) / len(cells)

    prof["id"] = "%s-%s-draft" % (region_id, zone_id)
    prof["name"] = "%s (regionkit draft from template %s)" % (zone_name, template_id)
    prof["comment"] = ("Drafted by Tools/regionkit from OpenStreetMap (ODbL, (c) OpenStreetMap contributors) and NOAA NCEI normals; "
                       "template %s, shrinkage k=%d. Per-field provenance and sample sizes: measurements.json. Review before use." % (template_id, k))
    prov.add("id", "default", prof["id"], note="region-zone-draft")

    # seasons ------------------------------------------------------------------------------
    hemi = "north" if lat >= 0 else "south"
    if hemi == "north":
        seasons = {"hemisphere": "north", "spring": [3, 4, 5], "summer": [6, 7, 8], "autumn": [9, 10, 11], "winter": [12, 1, 2]}
    else:
        seasons = {"hemisphere": "south", "spring": [9, 10, 11], "summer": [12, 1, 2], "autumn": [3, 4, 5], "winter": [6, 7, 8]}
    prof["seasons"] = seasons
    kclass = (climate or {}).get("koppen", {}).get("class") if climate and climate.get("available") else None
    note = "meteorological seasons from latitude %.3f" % lat
    if kclass and kclass.startswith("A"):
        note += "; Koppen %s (tropical): no real winter, a 4-season northern cycle is doubtful - REVIEW" % kclass
    elif kclass and kclass.startswith("B"):
        note += "; Koppen %s (arid): seasonal greenness follows rain/irrigation more than temperature - review" % kclass
    prov.add("seasons", "default", seasons, source="latitude + Koppen (NOAA normals)", note=note)

    # trees --------------------------------------------------------------------------------
    tr = prof["trees"]
    typed = [x for x in T if x["leaf_type"] in ("broadleaved", "needleleaved")]
    n_lt = len(typed)
    if n_lt >= GATE_LEAF:
        meas = sum(1 for x in typed if x["leaf_type"] == "broadleaved") / n_lt
        v = stats.shrink(meas, tr["deciduousShare"], n_lt, k)
        prov.add("trees.deciduousShare", "calibrated", r3(v), n=n_lt, source="leaf_type tag, else genus/species via data/genus_leaf.json",
                 template=tr["deciduousShare"], measured=r3(meas),
                 note="generator treats this as NON-CONIFER share (SceneGenerator: !chance(deciduousShare) -> conifer); true leaf cycle is reported separately")
        tr["deciduousShare"] = r3(v)
    else:
        prov.add("trees.deciduousShare", "template", tr["deciduousShare"], n=n_lt, note="needs >= %d trees with leaf_type or a known genus" % GATE_LEAF)
    hs = [x["height"] for x in T if x["height"] is not None]
    if len(hs) >= GATE_TREE_HEIGHT:
        q1, q3 = stats.percentile(hs, 0.25), stats.percentile(hs, 0.75)
        old = list(tr["heightMeters"])
        new = [round(stats.shrink(q1, old[0], len(hs), k), 1), round(stats.shrink(q3, old[1], len(hs), k), 1)]
        tr["heightMeters"] = [min(new), max(new)]
        prov.add("trees.heightMeters", "calibrated", tr["heightMeters"], n=len(hs), source="tree height tags p25-p75", template=old,
                 measured=[round(q1, 1), round(q3, 1)])
        ys = sum(1 for h in hs if h < YOUNG_HEIGHT_M) / len(hs)
        oldy = tr["youngShare"]
        tr["youngShare"] = r3(stats.shrink(ys, oldy, len(hs), k))
        prov.add("trees.youngShare", "calibrated", tr["youngShare"], n=len(hs), source="share of tagged tree heights < 7 m",
                 template=oldy, measured=r3(ys))
    else:
        prov.add("trees.heightMeters", "template", tr["heightMeters"], n=len(hs), note="needs >= %d tagged heights" % GATE_TREE_HEIGHT)
        prov.add("trees.youngShare", "template", tr["youngShare"], n=len(hs), note="needs >= %d tagged heights" % GATE_TREE_HEIGHT)
    prov.add("trees.crownWeights", "template", tr["crownWeights"], note="no open data on crown form; review visually")
    prov.add("trees.youngHeightMeters", "template", tr["youngHeightMeters"])

    # thresholds (percentile transfer) -----------------------------------------------------
    th = prof["typeThresholds"]
    PH = [b for b in H if not b.get("probable_garage")]
    areas = [b["area"] for b in PH]
    if len(areas) >= GATE_THRESHOLDS and denver_house_areas:
        details = {}
        for key in ("smallArea", "largeArea", "hugeArea"):
            p = stats.ecdf(denver_house_areas, FRONT_RANGE_THRESHOLDS[key])
            q = stats.percentile(areas, p)
            v = round(stats.shrink(q, th[key], len(areas), k), 1)
            details[key] = {"denverPercentile": r3(p), "zoneQuantile": round(q, 1), "template": th[key], "value": v}
            th[key] = v
        th["smallArea"] = min(th["smallArea"], th["largeArea"])
        th["hugeArea"] = max(th["hugeArea"], th["largeArea"])
        prov.add("typeThresholds.smallArea/largeArea/hugeArea", "calibrated", {k2: th[k2] for k2 in ("smallArea", "largeArea", "hugeArea")},
                 n=len(areas), source="percentile transfer: ECDF of front-range 60/220/350 m2 in Sloan's Lake house footprints, applied to this zone's principal houses (probable garages excluded)",
                 measured=details, note="reference distribution is Denver's; in the Denver check these fields are excluded from the score")
    else:
        prov.add("typeThresholds.smallArea/largeArea/hugeArea", "template", {k2: th[k2] for k2 in ("smallArea", "largeArea", "hugeArea")},
                 n=len(areas))
    prov.add("typeThresholds.aspect/rectangularity", "template",
             {k2: th[k2] for k2 in ("broadAspect", "squareAspect", "squareRectangularity", "narrowAspect")})

    # typeRules: floor shares ----------------------------------------------------------------
    with_lv = [b for b in PH if has_levels(b)]
    types = {h["id"]: h for h in prof["houseTypes"]}

    def grp(f):
        return "1" if f == 1 else "2" if f == 2 else "3+"

    if len(with_lv) >= GATE_LEVELS:
        rule_changes = {}
        for key in ("unknown", "small", "large"):
            w = prof["typeRules"].get(key)
            if not isinstance(w, dict) or not w:
                continue
            if key == "small":
                cls = [b for b in PH if b["area"] < th["smallArea"]]
            elif key == "large":
                cls = [b for b in PH if b["area"] > th["largeArea"]]
            else:
                cls = [b for b in PH if th["smallArea"] <= b["area"] <= th["largeArea"]]
            tagged = [b for b in cls if has_levels(b)]
            untagged = [b for b in cls if not has_levels(b)] or tagged
            n_c = len(tagged)
            total_w = sum(max(0, x) for x in w.values())
            G_share = Counter()
            for tid, x in w.items():
                if tid in types:
                    G_share[grp(types[tid]["floors"][0])] += max(0, x) / total_w if total_w else 0
            # Post-stratify by footprint area: the floor mix of tagged houses in each area bin, shrunk
            # toward the template's group share with that bin's n, weighted by where the UNTAGGED houses are.
            bins = Counter(area_bin(b["area"]) for b in untagged)
            per_bin = {}
            target = {g: 0.0 for g in ("1", "2", "3+")}
            eval_sets = []   # (bin weight, houses evaluated with levels hidden)
            for bn, cnt in sorted(bins.items()):
                tb = [b for b in tagged if area_bin(b["area"]) == bn]
                mc = Counter(grp(b["levels_int"]) for b in tb)
                sb = {g: stats.shrink(mc[g] / len(tb) if tb else None, G_share[g], len(tb), k) for g in target}
                per_bin[AREA_BIN_LABELS[bn]] = {"untagged": cnt, "tagged": len(tb), "target": {g: r3(v) for g, v in sb.items()}}
                for g in target:
                    target[g] += cnt / len(untagged) * sb[g]
                eval_sets.append((cnt / len(untagged), tb or [b for b in untagged if area_bin(b["area"]) == bn]))
            meas = Counter(grp(b["levels_int"]) for b in tagged)
            new_w, achieved, missing_mass = fit_floor_groups(prof, key, w, types, grp, eval_sets, target)
            prof["typeRules"][key] = new_w
            rule_changes[key] = {"housesInAreaClass": len(cls), "nWithLevels": n_c,
                                 "measuredFloorShareTagged": {g: r3(meas[g] / n_c) if n_c else None for g in ("1", "2", "3+")},
                                 "templateGroupShare": {g: r3(G_share[g]) for g in ("1", "2", "3+")},
                                 "target": {g: r3(target[g]) for g in ("1", "2", "3+")},
                                 "achievedAfterEligibility": {g: r3(achieved.get(g)) for g in ("1", "2", "3+")}, "byAreaBin": per_bin,
                                 "unrepresentableShare": r3(missing_mass), "from": w, "to": new_w}
        prov.add("typeRules.unknown/small/large", "calibrated", {k2: prof["typeRules"].get(k2) for k2 in ("unknown", "small", "large")},
                 n=len(with_lv), source="building:levels on houses, grouped by each family's default (first) floor count",
                 measured=rule_changes,
                 note="principal houses only (probable garages excluded); target = floor mix of tagged houses post-stratified by footprint-area bin (tagging depends on size), per-bin shrinkage n_b/(n_b+k); family weights scaled per default-floor group until the expected default floors AFTER eligibility filtering match; groups without a family stay unrepresented; other tagging biases remain")
    else:
        prov.add("typeRules.unknown/small/large", "template", None, n=len(with_lv), note="needs >= %d houses with building:levels" % GATE_LEVELS)
    prov.add("typeRules.(levels situations)", "template", None, note="oneFloor*/twoFloor*/threeFloor/semidetached weights kept")

    # houseTypes: perFloor --------------------------------------------------------------------
    wall = []
    for b in H:
        if b["height"] is None or not b["levels_raw"]:
            continue
        if b["roof_height"] is not None:
            wall.append((b["height"] - b["roof_height"]) / b["levels_raw"])
        elif b["roof_shape"] == "flat":
            wall.append(b["height"] / b["levels_raw"])
    if len(wall) >= GATE_PERFLOOR:
        q1 = min(PERFLOOR_BAND[1], max(PERFLOOR_BAND[0], stats.percentile(wall, 0.25)))
        q3 = min(PERFLOOR_BAND[1], max(PERFLOOR_BAND[0], stats.percentile(wall, 0.75)))
        ch = {}
        for h in prof["houseTypes"]:
            old = list(h["perFloor"])
            new = [round(stats.shrink(q1, old[0], len(wall), k), 2), round(stats.shrink(q3, old[1], len(wall), k), 2)]
            h["perFloor"] = [min(new), max(new)]
            ch[h["id"]] = {"from": old, "to": h["perFloor"]}
        prov.add("houseTypes[].perFloor", "calibrated", ch, n=len(wall), source="(height - roof:height)/levels or height/levels for flat roofs, p25-p75 clamped to 2.6-3.8 m",
                 measured=[round(stats.percentile(wall, 0.25), 2), round(stats.percentile(wall, 0.75), 2)])
    else:
        prov.add("houseTypes[].perFloor", "template", None, n=len(wall), note="needs >= %d houses with height and levels (and roof:height or a flat roof)" % GATE_PERFLOOR)

    # houseTypes: roof mix (IPF) --------------------------------------------------------------
    tagged = Counter(rules.map_roof(b["roof_shape"]) for b in H if rules.map_roof(b["roof_shape"]) in ROOF_KEYS)
    n_roof = sum(tagged.values())
    E0 = expected_roof_mix(H, prof)
    if n_roof >= GATE_ROOF:
        meas = {k2: tagged[k2] / n_roof for k2 in ROOF_KEYS}
        target = {k2: stats.shrink(meas[k2], E0[k2], n_roof, k) for k2 in ROOF_KEYS}
        u = usage(H, prof)
        rows = {h["id"]: norm_mix(h["roof"]) for h in prof["houseTypes"]}
        new_rows, achieved, resid, feasible = ipf_roofs(rows, u, target)
        ch = {}
        for h in prof["houseTypes"]:
            if h["id"] in new_rows and u.get(h["id"], 0) > 0:
                old = dict(h["roof"])
                nr = {k2: round(new_rows[h["id"]][k2], 3) for k2 in ROOF_KEYS}
                h["roof"] = nr
                ch[h["id"]] = {"from": old, "to": nr}
        prov.add("houseTypes[].roof", "calibrated", ch, n=n_roof, source="house roof:shape mapped to gabled/hipped/flat (skillion->slab and others excluded); IPF over families weighted by expected usage",
                 template={k2: r3(v) for k2, v in E0.items()}, measured={k2: r3(v) for k2, v in meas.items()},
                 note="target after shrinkage %s; achieved %s; residual TVD %.3f%s; zero weights preserved" % (
                     {k2: r3(v) for k2, v in target.items()}, {k2: r3(v) for k2, v in (achieved or {}).items()}, resid or 0,
                     "" if feasible else " (target not reachable with these families)"))
    else:
        prov.add("houseTypes[].roof", "template", None, n=n_roof, template={k2: r3(v) for k2, v in E0.items()},
                 note="needs >= %d houses with roof:shape" % GATE_ROOF)

    # houseTypes: pitch ------------------------------------------------------------------------
    ang = [b["roof_angle"] for b in H if b["roof_angle"] is not None and 0 < b["roof_angle"] < 75]
    if len(ang) >= GATE_PITCH:
        q1, q3 = stats.percentile(ang, 0.25), stats.percentile(ang, 0.75)
        ch = {}
        for h in prof["houseTypes"]:
            if norm_mix(h["roof"])["flat"] >= 0.999:
                continue
            old = list(h["pitch"])
            new = [round(stats.shrink(q1, old[0], len(ang), k), 1), round(stats.shrink(q3, old[1], len(ang), k), 1)]
            h["pitch"] = [min(new), max(new)]
            ch[h["id"]] = {"from": old, "to": h["pitch"]}
        prov.add("houseTypes[].pitch", "calibrated", ch, n=len(ang), source="roof:angle p25-p75 (pitched families only)", measured=[round(q1, 1), round(q3, 1)])
    else:
        prov.add("houseTypes[].pitch", "template", None, n=len(ang), note="needs >= %d houses with roof:angle" % GATE_PITCH)

    # houseTypes: colours ---------------------------------------------------------------------
    mt = materials or {"wall": {}, "roof": {}}
    wall_ev = colour_evidence(H, "building_colour", "building_material", mt["wall"])
    n_w = sum(len(v) for v in wall_ev.values())
    if n_w >= GATE_COLOUR:
        shift_slot(prof, 0, wall_ev, n_w, k, "houseTypes[].colors[wall]", prov)
    else:
        prov.add("houseTypes[].colors[wall]", "template", None, n=n_w, note="needs >= %d houses with building:colour or a coloured building:material" % GATE_COLOUR)
    roof_ev = colour_evidence(H, "roof_colour", "roof_material", mt["roof"])
    n_r = sum(len(v) for v in roof_ev.values())
    if n_r >= GATE_COLOUR:
        shift_slot(prof, 3, roof_ev, n_r, k, "houseTypes[].colors[roof]", prov)
    else:
        prov.add("houseTypes[].colors[roof]", "template", None, n=n_r, note="needs >= %d houses with roof:colour or a coloured roof:material" % GATE_COLOUR)
    for f in ("porch", "windows", "door", "overhang", "parapet", "floors", "minAspect/maxAspect/minRectangularity/broadFrontage", "colors[trim/door]"):
        prov.add("houseTypes[].%s" % f, "template", None, note="no open data; review visually")

    # garage ----------------------------------------------------------------------------------
    gtag = Counter(rules.map_roof(b["roof_shape"]) for b in G if rules.map_roof(b["roof_shape"]) in ROOF_KEYS)
    n_g = sum(gtag.values())
    if n_g >= GATE_GARAGE_ROOF and prof["garage"].get("roof"):
        old = norm_mix(prof["garage"]["roof"])
        meas = {k2: gtag[k2] / n_g for k2 in ROOF_KEYS}
        new = {k2: round(stats.shrink(meas[k2], old[k2], n_g, k), 3) for k2 in ROOF_KEYS}
        prof["garage"]["roof"] = new
        prov.add("garage.roof", "calibrated", new, n=n_g, source="garage roof:shape", template={k2: r3(v) for k2, v in old.items()},
                 measured={k2: r3(v) for k2, v in meas.items()})
    else:
        prov.add("garage.roof", "template", prof["garage"].get("roof"), n=n_g, note="needs >= %d garages with roof:shape" % GATE_GARAGE_ROOF)
    for f in ("garage.wallHeight/pitch/overhang/colors/doubleDoorMinWidthMeters", "shed", "chimneyLikelihood", "foundationMeters"):
        prov.add(f, "template", None, note="no open data")
    return prof, prov
