"""measurements.json documents and Markdown reports (per zone, and the drafts index)."""
import time

from . import draft as draftmod
from . import paths

ATTRIBUTION = ("OSM-derived statistics: (c) OpenStreetMap contributors, Open Database License 1.0 "
               "(https://www.openstreetmap.org/copyright). Climate normals: NOAA NCEI U.S. Climate Normals 1991-2020, "
               "Palecki et al. (2021), doi:10.25921/wck8-er13.")

DEFINITIONS = {
    "cell": "A sample box (S,W,N,E). Overpass cells are centre +- radiusMeters (square), centre = anchor's `out center` rounded to 4 decimals.",
    "building": "OSM outline with building=* (not 'no'), kept if its outer-ring centroid lies in the cell, cleaned with the engine's Polygon2D.cleaned(minArea: 1). building:part-only features are counted separately and excluded.",
    "role": "BuildingGenerator.role(of:): garage/garages/carport -> garage; shed/hut/kiosk/toilets or < 12 m2 -> shed; house/detached/semidetached_house/bungalow/residential/terrace/cabin or building=yes < 250 m2 -> house; else block.",
    "situation": "BuildingGenerator.situation with the stated thresholds; broadFront from StreetContext.frontEdge (named streets within 60 m).",
    "levels": "building:levels parsed like TagParsing.number, rounded half away from zero; 0 counts as untagged.",
    "metresPerLevel": "wall = (height - roof:height)/levels, or height/levels when roof:shape=flat; total = height/(levels + roof:levels).",
    "roofMapping": "gabled/saltbox/gambrel/mansard -> gabled; hipped/pyramidal/half-hipped/side_hipped -> hipped; flat -> flat; skillion -> slab; anything else is ignored by the generator.",
    "footprint": "area = shoelace (outer minus holes); aspect = long/short side of the minimum-area rectangle; rectangularity = area / rectangle area (FootprintAnalysis).",
    "percentiles": "linear interpolation between closest ranks (type 7).",
    "setback": "footprint to nearest residential/living_street/unclassified/tertiary/secondary/primary centreline (<= 60 m) minus half the carriageway (width, else lanes x 3.3 m, else RoadRules default).",
    "coverage": "net = house footprint area inside landuse=residential / that landuse area; gross = all outline area / (cell - water). Proxies: OSM has no parcels.",
    "alleys": "highway=service + service=alley length clipped to the cell; houses within 30 m; garages within 8 m (strict) and the engine's alleyEdge rule (30 m, service/unnamed roads).",
    "barriers": "barrier=fence/wall/hedge/retaining_wall and natural=tree_row lengths clipped to the cell (closed hedge areas count their perimeter).",
    "trees": "natural=tree nodes in the cell; leaf type/cycle from tags, else genus/species/taxon via data/genus_leaf.json.",
    "useMix": "see measurements.zoneSummary.useMix.definition",
    "shrinkage": "value = (n*measured + k*template)/(n + k)",
}


def _cell_view(c):
    return {"id": c["id"], "source": c["spec"].get("source"), "bbox": c["spec"].get("bbox"), "center": c["spec"].get("center"),
            "radiusMeters": c["spec"].get("radiusMeters"), "extra": c["spec"].get("extra", False),
            "anchor": c["spec"].get("anchor"), "anchorResolved": c.get("anchorResolved"), "areaKm2": c["areaKm2"],
            "fetch": {k: v for k, v in c["fetch"].items()}, "signature": c["signature"], "summary": c["summary"]}


def not_in_schema(summary, clim):
    t = summary["trees"]
    return {
        "comment": "Measured values the StyleProfile v2 schema cannot hold (for review / future fields). Not used by the engine.",
        "leafCycleTagOrGenus": t["leafCycleTagOrGenus"], "leafTypeTagOrGenus": t["leafTypeTagOrGenus"],
        "palmShareOfTreesWithGenus": t.get("palmShareOfTreesWithGenus"),
        "treesPerKm2": t["perKm2"], "treeRowKmPerKm2": t["treeRowKmPerKm2"], "woodShare": t["woodShare"],
        "facadeToCurbM": summary["setback"]["facadeToCurbM"], "longSideFacesStreetShare": summary["frontage"]["share"],
        "principalHousesFacadeToCurbM": summary.get("principalHouses", {}).get("facadeToCurbM"),
        "probableGarageShareOfHouses": summary.get("probableGarages", {}).get("shareOfHouses"),
        "alleyKmPerKm2": summary["alleys"]["alleyKmPerKm2"], "housesWithin30mOfAlleyShare": summary["alleys"]["housesWithin30mOfAlley"]["share"],
        "garagesAdjacentToAlleyShare": summary["alleys"]["garagesAdjacentToAlley"]["share"],
        "fenceMPer100Houses": summary["barriers"]["fence"]["mPer100Houses"], "hedgeMPer100Houses": summary["barriers"]["hedge"]["mPer100Houses"],
        "wallMPer100Houses": summary["barriers"]["wall"]["mPer100Houses"],
        "coverage": {k: summary["coverage"][k] for k in ("net", "gross")},
        "buildingsPerKm2": summary["buildings"]["perKm2"], "housesPerKm2": summary["buildings"]["housesPerKm2"],
        "sidewalkKmPerKm2": summary["streets"]["sidewalkKmPerKm2"],
        "useMixGrouped": summary["useMix"]["grouped"],
        "koppen": (clim or {}).get("koppen", {}).get("class") if clim and clim.get("available") else None,
    }


def family_signature(summary):
    ph = summary.get("principalHouses", {})
    H = {"areaM2": ph.get("footprintM2", {}), "aspect": ph.get("aspect", {}), "obbShortSideM": ph.get("obbShortSideM", {}),
         "obbLongSideM": ph.get("obbLongSideM", {})}
    lv = {"levels": ph.get("levels", {}), "withLevels": ph.get("withLevels", 0),
          "share": stats_share(ph.get("withLevels", 0), ph.get("n", 0))}
    lvls = lv.get("levels", {})
    n_lv = lv.get("withLevels", 0)
    one = lvls.get("1", {}).get("share")
    two = lvls.get("2", {}).get("share")
    three = sum(v["share"] for k, v in lvls.items() if k in ("3", "4", "5+")) if lvls else None
    a, asp, w, ln = H.get("areaM2", {}), H.get("aspect", {}), H.get("obbShortSideM", {}), H.get("obbLongSideM", {})
    fr = {"share": ph.get("longSideFacesStreetShare"), "housesWithFrontEdge": ph.get("n")}
    roofs = summary["roofShape"]["houses"]
    parts = []
    if n_lv:
        parts.append("%s%% 1-storey, %s%% 2-storey, %s%% 3+ (of %d houses with levels, %s%% of houses)" % (
            _pct(one), _pct(two), _pct(three), n_lv, _pct(lv.get("share"))))
    else:
        parts.append("no building:levels on houses")
    if a.get("n"):
        parts.append("footprints p25-p75 %s-%s m2 (median %s)" % (a["p25"], a["p75"], a["p50"]))
        parts.append("aspect p25-p75 %s-%s" % (asp["p25"], asp["p75"]))
        parts.append("rectangle short side p25-p75 %s-%s m, long side %s-%s m" % (w.get("p25"), w.get("p75"), ln.get("p25"), ln.get("p75")))
    if fr.get("housesWithFrontEdge"):
        parts.append("long side faces the street on %s%% of houses (narrow end to the street on %s%%)" % (
            _pct(fr["share"]), _pct(1 - fr["share"]) if fr["share"] is not None else "-"))
    if roofs["n"]:
        parts.append("roof:shape on %d houses: %s" % (roofs["n"], ", ".join("%s %s%%" % (k, _pct(v["share"])) for k, v in list(roofs["mapped"].items())[:4])))
    sb = ph.get("facadeToCurbM", {})
    pg = summary.get("probableGarages", {})
    if pg.get("n"):
        parts.append("%d generator 'houses' (%s%%) look like detached garages (building=yes < 60 m2 next to a service road) and are excluded here" % (
            pg["n"], _pct(pg["shareOfHouses"])))
    if sb.get("n"):
        parts.append("facade-to-curb median %s m (IQR %s-%s)" % (sb["p50"], sb["p25"], sb["p75"]))
    return {"text": "Principal houses (generator houses minus probable garages): " + "; ".join(parts) + ".",
            "numbers": {"levelShares": lvls, "footprintM2": a, "aspect": asp, "shortSideM": w, "longSideM": ln,
                        "longSideFacesStreet": fr.get("share")}}


def stats_share(n, total):
    return round(n / total, 3) if total else None


def _pct(x):
    return "-" if x is None else "%d" % round(100 * x)


def measurements_doc(r):
    s = r["summary"]
    return {
        "generatedBy": "Tools/regionkit 0.1", "generatedAt": time.strftime("%Y-%m-%d"),
        "attribution": ATTRIBUTION,
        "region": r["region"], "zone": {k: r["zone"].get(k) for k in ("id", "name", "poolZones", "reference")},
        "template": r["template"], "templateSource": r["templateSource"], "templateReason": r["zone"].get("templateReason"),
        "missingFamilies": r["zone"].get("missingFamilies"), "shrinkageK": r["k"],
        "osmTimestamps": {c["id"]: c["fetch"].get("timestamp_osm_base") for c in r["cells"]},
        "cells": [_cell_view(c) for c in r["cells"]],
        "zoneSummary": s,
        "familySignature": family_signature(s),
        "climate": r["climate"],
        "provenance": r["provenance"],
        "notExpressibleInSchema": not_in_schema(s, r["climate"]),
        "accuracy": r.get("accuracy"),
        "catalogCheck": r.get("catalogCheck"),
        "validation": r["validation"],
        "definitions": DEFINITIONS,
    }


def _fmt(v):
    if v is None:
        return "-"
    if isinstance(v, float):
        return ("%.3f" % v).rstrip("0").rstrip(".")
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(_fmt(x) for x in v) + "]"
    if isinstance(v, dict):
        return ", ".join("%s %s" % (k, _fmt(x)) for k, x in v.items())
    return str(v)


def _table(headers, rows):
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(_fmt(x).replace("|", "/") for x in r) + " |")
    return "\n".join(out)


def _shares(d, top=8):
    return ", ".join("%s %s%% (%d)" % (k, _pct(v["share"]), v["n"]) for k, v in list(d.items())[:top]) or "-"


def zone_report(r):
    s = r["summary"]
    z = r["zone"]
    clim = r["climate"]
    prov = r["provenance"]
    L = []
    L.append("# Region kit draft: %s / %s" % (r["region"], z["id"]))
    L.append("")
    L.append("**%s** - drafted %s by `Tools/regionkit` from template `%s` (%s), shrinkage k = %s. "
             "This is a starting point for human review, not a finished profile." % (z["name"], time.strftime("%Y-%m-%d"), r["template"], r["templateSource"], _fmt(r["k"])))
    L.append("")
    if z.get("templateReason"):
        L.append("Template choice: %s" % z["templateReason"])
        L.append("")
    if z.get("reference"):
        L.append("Comparison reference: `%s` (a hand-made prior, itself unmeasured)." % z["reference"])
        L.append("")
    L.append("## Sample cells")
    L.append("")
    rows = []
    for c in r["cells"]:
        a = c["spec"].get("anchor") or {}
        ar = c.get("anchorResolved") or {}
        rows.append([c["id"] + (" (extra)" if c["spec"].get("extra") else ""),
                     (a.get("names") or [a.get("name")])[0] if a else c["spec"].get("source"),
                     ar.get("osm") or "-", c["spec"].get("center"), c["areaKm2"], c["summary"]["buildings"]["outlines"],
                     c["fetch"].get("timestamp_osm_base"), c["fetch"].get("endpoint") or c["fetch"].get("source")])
    L.append(_table(["cell", "anchor", "OSM feature", "centre", "km2", "buildings", "OSM base", "source"], rows))
    L.append("")
    if s["flags"]:
        L.append("Data flags: " + "; ".join(s["flags"]))
        L.append("")

    L.append("## Confidence: sample sizes and what was calibrated")
    L.append("")
    b = s["buildings"]
    hv = s["levels"]["byRole"].get("house", {})
    L.append(_table(["measure", "n"], [
        ["buildings (outlines) / building:part", "%d / %d" % (b["outlines"], b["buildingParts"])],
        ["houses (generator role)", s["tagMissing"]["nHouses"]],
        ["houses with building:levels", hv.get("withLevels", 0)],
        ["houses with roof:shape", s["roofShape"]["houses"]["n"]],
        ["houses with roof:angle", s["roofAngleDeg"]["houses"].get("n", 0)],
        ["houses with height + levels (wall m/level)", s["metresPerLevel"]["houses"]["wall"].get("n", 0)],
        ["houses with building:colour / roof:colour", "%d / %d" % (s["materialsAndColours"]["buildingColour"]["houses"]["n"], s["materialsAndColours"]["roofColour"]["houses"]["n"])],
        ["garages with roof:shape", s["roofShape"]["garages"]["n"]],
        ["trees / with leaf type (tag or genus) / with height", "%d / %d / %d" % (s["trees"]["count"], sum(v["n"] for v in s["trees"]["leafTypeTagOrGenus"].values()), s["trees"]["heightM"].get("n", 0))],
    ]))
    L.append("")
    rows = []
    for f, p in prov.items():
        val = p["value"]
        if isinstance(val, dict) and len(str(val)) > 120:
            val = "(see measurements.json)"
        if isinstance(val, list) and len(str(val)) > 120:
            val = "(see measurements.json)"
        rows.append([f, p["status"], p["n"], val, (p.get("note") or "")[:160]])
    L.append(_table(["field", "status", "n", "value", "note"], rows))
    L.append("")
    cal = [f for f, p in prov.items() if p["status"] == "calibrated"]
    L.append("Calibrated from data: %s. Everything else is template or rule-based." % (", ".join("`%s`" % f for f in cal) or "nothing"))
    L.append("")

    L.append("## Measurements")
    L.append("")
    L.append("- Buildings: %s per km2 (%s houses per km2). Roles: %s." % (b["perKm2"], b["housesPerKm2"], _shares(b["byRole"])))
    L.append("- building=* values: %s." % _shares(b["byBuildingValue"], 10))
    L.append("- Levels (all buildings, %s%% tagged): %s. Houses: %s." % (_pct(s["levels"]["all"]["share"]), _shares(s["levels"]["all"]["levels"]), _shares(hv.get("levels", {}))))
    mpl = s["metresPerLevel"]
    L.append("- Metres per level (houses, wall): %s; all buildings total: %s." % (_fmt(mpl["houses"]["wall"]), _fmt(mpl["allBuildings"]["total"])))
    L.append("- Heights (houses): %s; blocks: %s." % (_fmt(hv.get("heightM")), _fmt(s["levels"]["byRole"].get("block", {}).get("heightM"))))
    rs = s["roofShape"]
    L.append("- roof:shape on houses (%s%%): raw %s; mapped %s. Garages: %s." % (_pct(rs["houses"]["share"]), _shares(rs["houses"]["raw"]), _shares(rs["houses"]["mapped"]), _shares(rs["garages"]["mapped"])))
    mc = s["materialsAndColours"]
    L.append("- Materials/colours: roof:material %s; building:material %s; building:colour families %s; roof:colour families %s." % (
        _shares(mc["roofMaterial"]["all"]), _shares(mc["buildingMaterial"]["all"]), _shares(mc["buildingColour"]["all"]["families"]), _shares(mc["roofColour"]["all"]["families"])))
    fp = s["footprints"]
    rows = []
    for role in ("house", "garage", "shed", "block"):
        if role in fp:
            f = fp[role]
            rows.append([role, f["areaM2"].get("n"), f["areaM2"].get("p10"), f["areaM2"].get("p25"), f["areaM2"].get("p50"), f["areaM2"].get("p75"), f["areaM2"].get("p90"),
                         "%s-%s" % (f["aspect"].get("p25"), f["aspect"].get("p75")), "%s-%s" % (f["rectangularity"].get("p25"), f["rectangularity"].get("p75"))])
    L.append("")
    L.append(_table(["role", "n", "area p10", "p25", "p50", "p75", "p90", "aspect p25-p75", "rectangularity p25-p75"], rows))
    L.append("")
    pg = s.get("probableGarages", {})
    L.append("- Probable garages among generator houses: %d (%s%% of houses; %s%% of the %d small building=yes houses sit next to a service road). The generator gives them house families, doors and windows." % (
        pg.get("n", 0), _pct(pg.get("shareOfHouses")), _pct(pg.get("shareOfSmallYesNearService")), pg.get("smallBuildingYesHouses", 0)))
    ph = s.get("principalHouses", {})
    L.append("- Principal houses (n=%s): footprint %s; levels %s; facade-to-curb %s; long side faces street %s%%." % (
        ph.get("n"), _fmt(ph.get("footprintM2")), _shares(ph.get("levels", {})), _fmt(ph.get("facadeToCurbM")), _pct(ph.get("longSideFacesStreetShare"))))
    L.append("- Footprint classes (houses): %s." % _shares(s["buildings"]["footprintClassByRole"].get("house", {})))
    L.append("- Situations with template thresholds: %s." % _shares(s["situationsTemplateThresholds"]["counts"], 10))
    L.append("- Use mix (non-outbuildings, by count): %s; by footprint area: %s." % (_shares(s["useMix"]["grouped"]), _fmt(s["useMix"]["byFootprintArea"])))
    sb = s["setback"]
    L.append("- Setback (facade to curb, %d of %d houses): median %s m, IQR %s-%s m; centreline %s m median; %d negative." % (
        sb["housesMeasured"], sb["housesTotal"], sb["facadeToCurbM"].get("p50"), sb["facadeToCurbM"].get("p25"), sb["facadeToCurbM"].get("p75"),
        sb["centrelineM"].get("p50"), sb["negative"]))
    L.append("- Long side faces the street: %s%% of %d houses with a front edge." % (_pct(s["frontage"]["share"]), s["frontage"]["housesWithFrontEdge"]))
    cv = s["coverage"]
    L.append("- Coverage proxies: net %s (residential landuse %s%% of the cell), gross %s; water %s%%." % (
        _fmt(cv["net"]), _pct(cv["residentialLanduseShare"]), _fmt(cv["gross"]), _pct(cv["waterShare"])))
    al = s["alleys"]
    L.append("- Alleys: %s km/km2; houses within 30 m of an alley %s%%; garages adjacent to an alley %s%% (engine alley edge %s%%); driveways %s km/km2." % (
        al["alleyKmPerKm2"], _pct(al["housesWithin30mOfAlley"]["share"]), _pct(al["garagesAdjacentToAlley"]["share"]),
        _pct(al["garagesEngineAlleyEdge"]["share"]), al["driveways"]["kmPerKm2"]))
    br = s["barriers"]
    L.append("- Barriers per km2 / per 100 houses: fence %s km / %s m, wall %s / %s, hedge %s / %s, retaining wall %s / %s." % (
        br["fence"]["kmPerKm2"], br["fence"]["mPer100Houses"], br["wall"]["kmPerKm2"], br["wall"]["mPer100Houses"],
        br["hedge"]["kmPerKm2"], br["hedge"]["mPer100Houses"], br["retaining_wall"]["kmPerKm2"], br["retaining_wall"]["mPer100Houses"]))
    t = s["trees"]
    L.append("- Trees: %d mapped (%s per km2); tree rows %s km/km2; wood %s%%, park %s%% of the cell. leaf_type tagged: %s; leaf_cycle tagged: %s; with genus fallback: type %s, cycle %s. Top genus: %s. Palm share (trees with genus): %s. Heights: %s." % (
        t["count"], t["perKm2"], t["treeRowKmPerKm2"], _pct(t["woodShare"]), _pct(t["parkShare"]), _shares(t["leafTypeTagged"]), _shares(t["leafCycleTagged"]),
        _shares(t["leafTypeTagOrGenus"]), _shares(t["leafCycleTagOrGenus"]), _shares(t["topGenus"], 6), _fmt(t.get("palmShareOfTreesWithGenus")), _fmt(t["heightM"])))
    L.append("- Streets (km/km2): %s; sidewalks %s." % (_fmt(s["streets"]["kmPerKm2ByHighway"]), s["streets"]["sidewalkKmPerKm2"]))
    L.append("")
    L.append("### Tag coverage (% missing)")
    L.append("")
    tm = s["tagMissing"]
    L.append(_table(["tag", "buildings (n=%d)" % tm["nBuildings"], "houses (n=%d)" % tm["nHouses"]],
                    [[k, "%s%%" % _pct(tm["buildings"][k]), "%s%%" % _pct(tm["houses"][k])] for k in tm["buildings"]]))
    L.append("")
    fs = family_signature(s)
    L.append("### Family signature hints")
    L.append("")
    L.append(fs["text"])
    L.append("")

    L.append("## Climate (NOAA NCEI 1991-2020 normals)")
    L.append("")
    if clim and clim.get("available"):
        st = clim["stationTempPrecip"]
        ss = clim.get("stationSnow")
        L.append("Temperature/precipitation: %s %s, %s km away (elev %s m). Snow: %s." % (
            st["id"], st["name"], st["distanceKm"], st["elevationM"], ("%s %s, %s km" % (ss["id"], ss["name"], ss["distanceKm"])) if ss else "no station with snowfall normals among the nearest candidates"))
        L.append("")
        months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        L.append(_table(["", *months], [["mean temp C", *clim["tempC"]], ["precip mm", *clim["precipMm"]],
                                        ["snow mm", *(clim["snowMm"] or ["-"] * 12)]]))
        L.append("")
        kd = clim["koppen"]["detail"]
        L.append("Koppen-Geiger: **%s** (0 C C/D threshold; %s with the -3 C variant). MAT %s C, MAP %s mm, warmest %s C, coldest %s C, Pthreshold %s mm." % (
            clim["koppen"]["class"], clim["koppenMinus3"]["class"], kd["MAT"], kd["MAP"], kd["Thot"], kd["Tcold"], kd["Pthreshold"]))
    else:
        L.append("No station with complete normals among the nearest candidates.")
    L.append("")

    acc = r.get("accuracy")
    if acc:
        c = acc["comparison"]
        L.append("## Accuracy check against `%s`" % acc["reference"])
        L.append("")
        L.append("Score = agree / (agree + differ) = **%s** (%d agree, %d differ; fields that are template-only are 'not measurable'). The reference is itself a hand-made prior: a difference can mean the reference is wrong - see the direct tests." % (
            _fmt(c["score"]), c["agree"], c["differ"]))
        L.append("")
        L.append(_table(["field", "draft", "reference", "metric", "tolerance", "n", "verdict"],
                        [[x["field"], x["draft"], x["reference"], x["metric"], x["tolerance"], x["n"], x["verdict"] + (" (%s)" % x["note"] if x.get("note") else "")] for x in c["rows"]]))
        L.append("")
        d = acc["directTests"]
        L.append("### Reference values tested directly against the measurements (no shrinkage)")
        L.append("")
        L.append("%d supported, %d contradicted, %d can't be tested (sample below the gate)." % (d["supports"], d["contradicts"], d["cantTest"]))
        L.append("")
        L.append(_table(["reference value", "reference", "measured", "n", "gate", "metric", "tolerance", "verdict", "note"],
                        [[x["field"], x["reference"], x["measured"], x["n"], x["gate"], x["metric"], x["tolerance"], x["verdict"], x.get("note", "")] for x in d["rows"]]))
        L.append("")
    cc = r.get("catalogCheck")
    if cc and not cc.get("missing"):
        L.append("## Catalog check (`%s`)" % cc["catalog"])
        L.append("")
        rows = []
        for cid, x in cc["cells"].items():
            rows.append([cid, x["firstMatchBox"] or "(none: defaultProfile)", x["profileAtCenter"], x["expectedProfile"],
                         "yes" if x["centerMatchesExpected"] else "NO", _fmt(x["cellAreaByResolvedProfile"]),
                         ", ".join("%s %s%%" % (b["id"], _pct(b["cellAreaShare"])) for b in x["overlappingBoxes"]) or "-"])
        L.append(_table(["cell", "first-match box at centre", "profile at centre", "expected", "match", "cell area by resolved profile", "overlapping boxes (share of cell)"], rows))
        L.append("")
        if cc.get("boxSignatures"):
            L.append(_table(["box (sampled part only)", "profile", "sampled km2", "buildings/km2", "house share", "block share", "house footprint p50", "3+ levels share (n)"],
                            [[k, v["profile"], v["sampledKm2"], v["buildingsPerKm2"], v["houseShare"], v["blockShare"], v["houseFootprintP50"],
                              "%s (%d)" % (_fmt(v["share3PlusLevels"]), v["levelsTagged"])] for k, v in cc["boxSignatures"].items()]))
            L.append("")

    L.append("## Needs a human eye")
    L.append("")
    todo = []
    tmpl = [f for f, p in prov.items() if p["status"] == "template"]
    todo.append("Template-only (no open data): " + ", ".join("`%s`" % f for f in tmpl) + ".")
    for f, p in prov.items():
        if "REVIEW" in (p.get("note") or "") or "review" in (p.get("note") or "").lower() and p["status"] == "default":
            todo.append("`%s`: %s" % (f, p["note"]))
    if z.get("missingFamilies"):
        todo.append("Still missing (needs generator work, not data): " + "; ".join(z["missingFamilies"]) + ".")
    if s["flags"]:
        todo.append("Data flags: " + "; ".join(s["flags"]) + ".")
    if s["tagMissing"]["houses"].get("roof:shape", 1) > 0.9:
        todo.append("roof:shape is missing on %s%% of houses: roof mix stays a prior; check roofs on test pictures." % _pct(s["tagMissing"]["houses"]["roof:shape"]))
    if s["tagMissing"]["houses"].get("building:levels", 1) > 0.8:
        todo.append("building:levels is missing on %s%% of houses: storey defaults come from the house-type lottery." % _pct(s["tagMissing"]["houses"]["building:levels"]))
    todo.append("Colours, porches, windows, chimneys and crown shapes: judge on test pictures (open data has almost nothing).")
    for x in todo:
        L.append("- " + x)
    L.append("")
    L.append("---")
    L.append(ATTRIBUTION)
    L.append("")
    return "\n".join(L)


def index(results, sig):
    L = ["# Region kit drafts", "",
         "Generated by `Tools/regionkit/regionkit.sh all` on %s. Each zone folder holds `profile.json` (StyleProfile v2, validated), "
         "`measurements.json` (all statistics, climate, per-field provenance, OSM timestamps, cell definitions) and `report.md` (confidence report). "
         "Drafts are review material: nothing here is wired into the engine." % time.strftime("%Y-%m-%d"), ""]
    rows = []
    for r in results:
        s = r["summary"]
        c = (r.get("accuracy") or {}).get("comparison") or {}
        clim = r["climate"]
        rows.append(["[%s/%s](%s/%s/report.md)" % (r["region"], r["zone"]["id"], r["region"], r["zone"]["id"]), r["template"],
                     len(r["cells"]), s["areaKm2"], s["buildings"]["outlines"], "%s%%" % _pct(s["levels"]["all"]["share"]),
                     "%s%%" % _pct(s["roofShape"]["all"]["share"]), s["trees"]["perKm2"],
                     clim["koppen"]["class"] if clim.get("available") else "-",
                     ("%s vs %s" % (_fmt(c.get("score")), r["zone"]["reference"])) if r["zone"].get("reference") else "-"])
    L.append(_table(["zone", "template", "cells", "km2", "buildings", "levels tagged", "roof:shape tagged", "trees/km2", "Koppen", "accuracy score"], rows))
    L.append("")
    L.append("## Do the Chicagoland cells separate by zone?")
    L.append("")
    for k, v in sig["separation"].items():
        L.append("- %s: leave-one-out nearest-centroid accuracy %s over cells whose zone has another cell (%s over all cells); features %s." % (
            k, _fmt(v["accuracyTestable"]), _fmt(v["accuracyAll"]), ", ".join(v["features"])))
    L.append("")
    L.append(_table(["zone", "cell", "buildings/km2", "house share", "block share", "house p50 m2", "gross coverage", "alley km/km2", "3+ levels share", "levels tagged"],
                    [[x["zone"], x["cell"], x["buildingsPerKm2"], x["houseShare"], x["blockShare"], x["houseFootprintP50"], x["grossCoverage"], x["alleyKmPerKm2"],
                      x["share3PlusLevels"], x["levelsTagged"]] for x in sig["cellSignatures"]]))
    L.append("")
    L.append("Details: `zone-signatures.json`. Method and discussion: `docs/research/region-kit.md`.")
    L.append("")
    L.append("---")
    L.append(ATTRIBUTION)
    L.append("")
    return "\n".join(L)
