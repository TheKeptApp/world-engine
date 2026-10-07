#!/usr/bin/env python3
"""Look-loop finish: merges the per-view grades and signals into grades.json and summary.md,
publishes the compressed run to docs/lookloop/latest/ and appends one dated row to
docs/lookloop/scoreboard.md. The regression guard compares every freshly graded view with the
previous published run and writes regressions.md (a view down 2+ points on /50, or any criterion
down 1+).

  Tools/lookloop/finish.py <run-dir> [--no-publish]
"""
import collections, datetime, json, os, shutil, subprocess, sys, time

sys.dont_write_bytecode = True  # no __pycache__ next to the tools (nothing to commit by accident)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from grade import concept_score, paintover_score, recompute  # noqa: E402  (same totals whether reviewers ran headless or in a session)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DOCS = os.path.join(ROOT, "docs/lookloop")
LATEST = os.path.join(DOCS, "latest")
V2 = ["silhouettes", "palette", "light", "softnessAO", "groundRichness", "characterReadability",
      "depthFog", "houseVariety", "geography", "motion"]
AD = ["adGroundRich", "adRainReadable", "adRegional"]
# Owner decision (6 Oct 2026): gate on concept parity; milestones for the mean parity.
MILESTONES = [("end of 5A wrap", 85), ("end of 5B", 100)]  # mean parity; the 5B gate also needs every view's AD >= 3
SHORT = {"silhouettes": "sil", "palette": "pal", "light": "lit", "softnessAO": "AO", "groundRichness": "grd",
         "characterReadability": "chr", "depthFog": "fog", "houseVariety": "hse", "geography": "geo", "motion": "mot",
         "adGroundRich": "AD grd", "adRainReadable": "AD rain", "adRegional": "AD reg"}


def git(*args):
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    except OSError:
        return ""


def fmt(v):
    return "–" if v is None else str(v)


def regressions(prev, grades, reused, views):
    """Flags against the previous published run: a view down >= 2 on /50, or any criterion down >= 1."""
    flags, compared = [], 0
    for vid, g in grades.items():
        old = (prev.get("views", {}).get(vid) or {}).get("grade")
        if vid in reused or not old or "error" in old:
            continue
        compared += 1
        if old.get("v2Score50") is not None and g.get("v2Score50") is not None and g["v2Score50"] - old["v2Score50"] <= -2:
            flags.append((vid, "v2 /50", old["v2Score50"], g["v2Score50"], g.get("summary", "")))
        for sect, keys in (("scores", V2), ("artDirection", AD)):
            for k in keys:
                a, b = old.get(sect, {}).get(k, {}).get("score"), g.get(sect, {}).get(k, {}).get("score")
                if a is not None and b is not None and b - a <= -1:
                    flags.append((vid, k, a, b, g[sect][k].get("reason", "")))
    return flags, compared


def main():
    run = os.path.abspath(sys.argv[1])
    publish = "--no-publish" not in sys.argv
    views = {v["id"]: v for v in json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))["views"]}
    signals = json.load(open(os.path.join(run, "signals.json")))
    meta = json.load(open(os.path.join(run, "run.json"))) if os.path.exists(os.path.join(run, "run.json")) else {}
    if meta.get("t0") and not meta.get("minutes"):
        meta["minutes"] = round((time.time() - meta["t0"]) / 60, 1)
        json.dump(meta, open(os.path.join(run, "run.json"), "w"), indent=1)
    prev = json.load(open(os.path.join(LATEST, "grades.json"))) if os.path.exists(os.path.join(LATEST, "grades.json")) else {}
    reused = set(meta.get("reused", []))
    cp = os.path.join(DOCS, "calibration-scores.json")
    concept = json.load(open(cp))["scores"] if os.path.exists(cp) else {}
    grades, failed = {}, []
    for vid in views:
        p = os.path.join(run, "grades", f"{vid}.json")
        if os.path.exists(p):
            try:
                g = json.load(open(p))
                if "error" in g or "scores" not in g or "artDirection" not in g:
                    raise ValueError(g.get("error", "not GRADING.md section G"))
                grades[vid] = recompute(g, views[vid], concept_score(views[vid], concept), paintover_score(views[vid], concept))
                json.dump(g, open(p, "w"), indent=1)
            except (ValueError, KeyError, TypeError) as e:
                print(f"  {vid}: grade rejected ({e})")
                failed.append(vid)
    captured = [vid for vid in views if vid in signals]
    if not captured and publish:
        sys.exit("finish: no view was captured in this run; nothing published (see capture.tsv and the logs)")
    ct = os.path.join(run, "capture.tsv")
    capture_failed = [ln.split("\t")[0] for ln in open(ct) if "\tfailed\t" in ln] if os.path.exists(ct) else []
    placeholders = [vid for vid, v in views.items() if v.get("active", True) is False]

    # Per-view table, criterion means and the most common fixes.
    rows, crit = [], collections.defaultdict(list)
    for vid in captured:
        g, s = grades.get(vid), signals[vid]
        perf, vt = s.get("perf", {}), (s.get("vsTargets") or [{}])[0]
        if g:
            for k in V2:
                if g["scores"].get(k, {}).get("score") is not None:
                    crit[k].append(g["scores"][k]["score"])
            for k in AD:
                if g["artDirection"].get(k, {}).get("score") is not None:
                    crit[k].append(g["artDirection"][k]["score"])
        rows.append((vid, g, perf, vt))
    scored = [g for _, g, _, _ in rows if g]
    # Concept parity: the view's /50 as a share of its target concept's calibrated /50 (calibration.md).
    parity = {vid: g["parity"] for vid, g, _, _ in rows if g and g.get("parity") is not None}
    mean_parity = round(sum(parity.values()) / len(parity)) if parity else None
    po_parity = {vid: g["paintoverParity"] for vid, g, _, _ in rows if g and g.get("paintoverParity") is not None}
    mean_po = round(sum(po_parity.values()) / len(po_parity)) if po_parity else None
    ord_par = [parity[v] for v in parity if views[v]["group"] == "ordinary"]
    ordinary_parity = round(sum(ord_par) / len(ord_par)) if ord_par else None
    # P2's gate (owner): buildings and ground criteria average >= 3.5 on the region views.
    bg_keys = (("scores", "silhouettes"), ("scores", "houseVariety"), ("scores", "groundRichness"), ("artDirection", "adGroundRich"))
    bg = [g[sect][k]["score"] for vid, g, _, _ in rows if g and views[vid]["group"] == "region"
          for sect, k in bg_keys if g[sect].get(k, {}).get("score") is not None]
    region_bg = round(sum(bg) / len(bg), 2) if bg else None
    lf_fail = collections.Counter(k for g in scored for k in g.get("lookFixFailed", []))
    lf_checked = sum(g.get("lookFixChecked", 0) for g in scored)
    lf_unc = sum(1 for g in scored for v in (g.get("lookFixChecks") or {}).values()
                 if isinstance(v, dict) and v.get("pass") is None and str(v.get("reason", "")).lower().startswith("not checkable"))
    milestones = " · ".join(f"{name} ≥{t}%: {'**met**' if mean_parity is not None and mean_parity >= t else 'not yet'}" for name, t in MILESTONES)
    mean50 = round(sum(g["v2Score50"] for g in scored) / len(scored), 1) if scored else None
    meanAD = [g["adMean"] for g in scored if g.get("adMean") is not None]
    meanAD = round(sum(meanAD) / len(meanAD), 2) if meanAD else None
    passes = sum(1 for g in scored if g["gatePass"])
    adpasses = sum(1 for g in scored if g.get("adPass"))
    gate5b = sum(1 for g in scored if g.get("gate5B"))
    worst = min(scored, key=lambda g: (g.get("parity") if g.get("parity") is not None else 999, g["v2Score50"])) if scored else None
    ordinary = [g["v2Score50"] for g in scored if views[g["view"]]["group"] == "ordinary"]
    fixes = collections.Counter()
    fix_text = {}
    for g in scored:
        for i, f in enumerate(g.get("topFixes", [])[:3]):
            key = f.get("area", "?")
            fixes[key] += 3 - i
            fix_text.setdefault(key, []).append(f"{g['view']}: {f.get('fix', '')}")

    out = {
        "run": meta, "views": {vid: {"grade": g, "signals": signals[vid]} for vid, g, _, _ in rows},
        "aggregate": {"meanConceptParity": mean_parity, "paintoverParity": po_parity, "meanPaintoverParity": mean_po, "gate5BPasses": gate5b, "regionBuildingsGround": region_bg, "lookFixFailed": dict(lf_fail), "ordinaryParity": ordinary_parity, "milestones": milestones,
                      "meanV2Score50": mean50, "conceptParity": parity, "meanArtDirection": meanAD, "gatePasses": passes, "graded": len(scored),
                      "captured": len(captured), "failedGrades": failed, "placeholders": placeholders,
                      "criterionMeans": {k: round(sum(v) / len(v), 2) for k, v in crit.items()},
                      "fixAreasWeighted": fixes.most_common()},
    }
    json.dump(out, open(os.path.join(run, "grades.json"), "w"), indent=1)

    flags, compared = regressions(prev, grades, reused, views)
    prev_run = prev.get("run", {})
    graders_now = sorted({g.get("grader", "?") for vid, g in grades.items() if vid not in reused})
    graders_then = sorted({(e.get("grade") or {}).get("grader", "?") for e in prev.get("views", {}).values() if e.get("grade")})
    reg = ["# Look loop: regressions", "",
           f"This run ({meta.get('started', '-')}, engine `{meta.get('engineCommit', '-')}`) against the previous published run "
           f"({prev_run.get('started', 'none')}, engine `{prev_run.get('engineCommit', '-')}`). Rule: a view down 2 or more on /50, "
           f"or any criterion down 1 or more. {compared} freshly graded view(s) compared; {len(reused)} reused unchanged view(s) cannot regress.", ""]
    if prev_run.get("gradingSha") != meta.get("gradingSha"):
        reg += ["Caution: docs/lookloop/GRADING.md changed between the two runs (see calibration.md for why). Score moves can come "
                "from the procedure rather than the render; compare the sheets before acting.", ""]
    if graders_now and graders_then and graders_now != graders_then:
        reg += [f"Caution: graders differ ({', '.join(graders_then)} then, {', '.join(graders_now)} now). A one-point move can be grader "
                "variance; check the two sheets side by side before acting.", ""]
    if not prev:
        reg += ["No previous run: nothing to compare."]
    elif not flags:
        reg += ["**No regressions.**"]
    else:
        reg += [f"**{len(flags)} regression flag(s) in {len({f[0] for f in flags})} view(s).**", "",
                "| View | What | Before | Now | Reviewer's reason now |", "|---|---|---|---|---|"]
        reg += [f"| [{v}](sheets/{v}.jpg) | {k} | {a} | {b} | {r.replace('|', '/')[:220]} |" for v, k, a, b, r in flags]
    open(os.path.join(run, "regressions.md"), "w").write("\n".join(reg) + "\n")
    out["aggregate"]["regressionFlags"] = len(flags)
    json.dump(out, open(os.path.join(run, "grades.json"), "w"), indent=1)

    when = meta.get("started", datetime.datetime.now().strftime("%Y-%m-%d %H:%M"))
    md = [f"# Look loop: latest run", "",
          f"Run {when} · engine `{meta.get('engineCommit', '-')}`{' + uncommitted changes' if meta.get('dirtyEngineFiles') else ''} · checkout `{meta.get('commit', git('rev-parse', '--short', 'HEAD'))}` on `{meta.get('branch', git('branch', '--show-current'))}`"
          f" · {len(captured)} views ({len(captured) - len(reused & set(captured))} rendered, {len(reused & set(captured))} unchanged and reused), {len(scored)} graded"
          + (f" ({', '.join(failed)} failed)" if failed else "")
          + (f" · **capture failed: {', '.join(capture_failed)}** (logs in the run directory)" if capture_failed else "")
          + (f" · run time {meta['minutes']} min" if meta.get("minutes") else "")
          + f" · graders {', '.join(f'`{x}`' for x in sorted({g.get('grader', '?') for g in scored}))}"
          + (" · **gate run**" if meta.get("gate") else ""), "",
          f"Regression guard: {'**' + str(len(flags)) + ' flag(s)**' if flags else 'no regressions'} ([regressions.md](regressions.md)).", "",
          f"## Concept parity {fmt(mean_parity)}%  ·  gate passes {passes}/{len(scored)}  ·  end-of-5B gate {gate5b}/{len(scored)}", "",
          f"Milestones: {milestones}. Ordinary-day parity {fmt(ordinary_parity)}%."
          + (f" Region buildings & ground (sil, hse, grd, AD grd; P2 target ≥ 3.5): **{region_bg}**." if region_bg is not None else ""), "",
          ("Approved-mock closeness (GRADING.md §M, 1–5): " + ", ".join(f"{vid} {g['mockGap'].get('closeness')}" for vid, g, _, _ in rows if g and isinstance(g.get("mockGap"), dict)) + "."
           if any(g and isinstance(g.get("mockGap"), dict) for _, g, _, _ in rows) else "Approved-mock closeness: no view with an approved mock was graded."), "",
          (f"Paint-over parity {fmt(mean_po)}% (paintover-v1, beside the gate; view /50 ÷ its own paint-over's calibrated /50): "
           + ", ".join(f"{v} {p}%" for v, p in sorted(po_parity.items())) + "." if po_parity else
           "Paint-over parity: not available (paint-overs not calibrated yet)."), "",
          (f"look-fix-v1 checks (GRADING.md §H, beside the gate): {sum(lf_fail.values())} failed of {lf_checked} judged"
           + (" — " + ", ".join(f"{k} {n}" for k, n in lf_fail.most_common()) if lf_fail else "") + f"; {lf_unc} not checkable from a still." if lf_checked else
           "look-fix-v1 checks: not reported by these grades."), "",
          f"Gate per view: parity ≥ 100 % of its calibrated target concept **and** v2's per-criterion floors (no §8.3 score < 3, "
          f"geography ≥ 4, character ≥ 4 when scored, no hard-gate flags). End-of-5B gate adds every art-direction score ≥ 3 "
          f"(look-fix §8; {adpasses}/{len(scored)} meet it now). Long-term goal: v2 mean {fmt(mean50)}/50 against 40 · "
          f"art direction {fmt(meanAD)}/5, {adpasses}/{len(scored)} at the art-direction bar.", "",
          "Parity = view /50 ÷ concept /50 (docs/lookloop/calibration-scores.json). Frame time and triangles are Simulator figures "
          "from WorldLab's console: use them for change between runs, not as device performance.", "",
          "| View | Parity | Gate | /50 | AD | " + " | ".join(SHORT[k] for k in V2[:9]) + " | AD grd | AD rain | AD reg | Luma vs target | Tris | Frame ms | Sheet |",
          "|---|---|---|---|---|" + "---|" * 9 + "---|---|---|---|---|---|---|"]
    for vid, g, perf, vt in rows:
        sc = lambda k, sect="scores": fmt(g[sect].get(k, {}).get("score")) if g else "?"
        tri = perf.get("triangles")
        gate = ("pass" if g["gatePass"] else ("fail (floors)" if not g.get("v2Floors") else "fail")) if g else "?"
        gate += (" · 5B ✓" if g.get("gate5B") else " · 5B ✗") if g else ""
        md.append(f"| {vid}{' (reused)' if vid in reused else ''} | {f'**{parity[vid]}%**' if vid in parity else '–'} | {gate} | "
                  f"{fmt(g['v2Score50']) if g else '?'} | {fmt(g.get('adMean')) if g else '?'} | " + " | ".join(sc(k) for k in V2[:9]) + " | "
                  + " | ".join(sc(k, "artDirection") for k in AD)
                  + f" | {fmt(vt.get('lumaHistIntersection'))} | {f'{tri // 1000}k' if tri else '–'} | {fmt(perf.get('frameMsMedian'))} | "
                  f"[sheet](sheets/{vid}.jpg) |")
    if crit:
        md += ["", "## Criterion means", "", "| " + " | ".join(SHORT[k] for k in V2 + AD if k in crit) + " |",
               "|" + "---|" * len([k for k in V2 + AD if k in crit]),
               "| " + " | ".join(str(out["aggregate"]["criterionMeans"][k]) for k in V2 + AD if k in crit) + " |"]
    if fixes:
        md += ["", "## Most-cited fix areas (top fix 3 pts, second 2, third 1)", ""]
        for area, pts in fixes.most_common(6):
            md.append(f"- **{area}** ({pts} pts): " + "; ".join(fix_text[area][:3]))
    # Top fixes per lane (look-fix-v1 ownership: P2 = buildings, yard/ground geometry, placement, vegetation
    # assets, data; 5A = materials, light, weather, atmosphere, sky, post). Ground and vegetation are shared.
    LANE = {"buildings": "P2", "ground": "P2 (+5A material)", "vegetation": "P2 (+5A LOD/shading)", "data": "P2",
            "light": "5A", "sky": "5A", "weather": "5A", "fog": "5A", "water": "5A", "post": "5A", "camera": "5A",
            "character": "5A"}
    lanes = collections.defaultdict(collections.Counter)
    lane_text = collections.defaultdict(list)
    for g in scored:
        for i, f in enumerate(g.get("topFixes", [])[:3]):
            lane = LANE.get(f.get("area", ""), "unassigned").split(" ")[0]
            lanes[lane][f.get("area", "?")] += 3 - i
            lane_text[(lane, f.get("area", "?"))].append(f"{g['view']}: {f.get('fix', '')}")
    if lanes:
        md += ["", "## Top fixes per lane (top fix 3 pts, second 2, third 1)", ""]
        for lane in ("5A", "P2", "unassigned"):
            if lane not in lanes:
                continue
            md.append(f"**{lane}**" + (" (ground and vegetation shared with 5A for material and LOD)" if lane == "P2" else ""))
            for area, pts in lanes[lane].most_common(5):
                md.append(f"- {area} ({pts} pts): " + "; ".join(t[:160] for t in lane_text[(lane, area)][:3]))
            md.append("")
    md += ["", "## Per-view summaries", ""]
    for vid, g, _, _ in rows:
        if g:
            md.append(f"- **{vid}** ({g['v2Score50']}/50): {g.get('summary', '')}"
                      + (f" Flags: {', '.join(g['hardGateFlags'])}." if g.get("hardGateFlags") else "")
                      + f" _vs previous: {g.get('vsPrevious', '-')}_")
    if placeholders:
        md += ["", f"Placeholders (inactive until their hooks land): {', '.join(placeholders)}."]
    md += ["", "Overview of all frames: [overview.jpg](overview.jpg). Raw grades and signals: [grades.json](grades.json)."]
    open(os.path.join(run, "summary.md"), "w").write("\n".join(md) + "\n")

    if publish and meta.get("fingerprints"):
        # Fingerprints as of grading time: GRADING.md may change between plan and finish. Only when the
        # rendered code is still what was captured; otherwise a checkout moved on since capture (6 Oct 2026:
        # finishing a2c818b's run at a later HEAD stamped its frames with that HEAD and hid the next change).
        from plan import fingerprints, git as plan_git
        render = ("Sources", "Apps/WorldLab", "Package.swift", "Data/areas")
        moved = meta.get("commit") and any(plan_git("rev-parse", f"{meta['commit']}:{p}").strip() != plan_git("rev-parse", f"HEAD:{p}").strip()
                                           for p in render)
        if moved:
            print(f"finish: checkout moved past {meta['commit']} in rendered code; keeping capture-time fingerprints")
        else:
            m = json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))
            active = [v for v in m["views"] if v["id"] in meta["fingerprints"]]
            meta["fingerprints"].update(fingerprints(active, m["commonArgs"]))
            json.dump(meta, open(os.path.join(run, "run.json"), "w"), indent=1)
    if publish:
        if os.path.isdir(LATEST):
            shutil.rmtree(LATEST)
        os.makedirs(LATEST)
        for sub in ("frames", "sheets"):
            shutil.copytree(os.path.join(run, sub), os.path.join(LATEST, sub))
        for f in ("grades.json", "summary.md", "overview.jpg", "run.json", "regressions.md"):
            if os.path.exists(os.path.join(run, f)):
                shutil.copy(os.path.join(run, f), os.path.join(LATEST, f))
        board = os.path.join(DOCS, "scoreboard.md")
        if not os.path.exists(board):
            open(board, "w").write(
                "# Look-loop scoreboard\n\nOne row per full run (`Tools/lookloop/lookloop.sh run`), newest last. /50 is the mean v2 §8.3 "
                "score normalised over scorable criteria; AD is the art-direction mean (ground richness, rain readability, regional "
                "signature). Simulator frame time and triangles are for change tracking only, not device performance.\n\n"
                "| Date | Engine | Branch | Views | Parity | Gate passes | Ordinary parity | Mean /50 | AD /5 | Worst view | Median tris | Median frame ms | Run min | Grader | Regressions |\n"
                "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n")
        tris = sorted(p.get("triangles") for _, _, p, _ in rows if p.get("triangles"))
        fms = sorted(p.get("frameMsMedian") for _, _, p, _ in rows if p.get("frameMsMedian"))
        open(board, "a").write(
            f"| {when} | `{meta.get('engineCommit', meta.get('commit', '-'))}`{'+dirty' if meta.get('dirtyEngineFiles') else ''} | {meta.get('branch', '-')} | {len(scored)}/{len(captured)}{f' ({len(reused & set(captured))} reused)' if reused & set(captured) else ''} | "
            f"**{fmt(mean_parity)}%** | {passes} (5B {gate5b}) | {fmt(ordinary_parity)}% | {fmt(mean50)} | {fmt(meanAD)} | "
            f"{f'{worst['view']} {worst.get('parity')}%' if worst else '–'} | {f'{tris[len(tris) // 2] // 1000}k' if tris else '–'} | "
            f"{fms[len(fms) // 2] if fms else '–'} | {fmt(meta.get('minutes'))} | {', '.join(sorted({g.get('grader', '?') for vid, g in grades.items() if vid not in reused})) or 'all reused'}{' (gate)' if meta.get('gate') else ''} | {len(flags)} |\n")
        print(f"published {LATEST} and appended a scoreboard row")
    print(open(os.path.join(run, "regressions.md")).read())
    print(open(os.path.join(run, "summary.md")).read().split("\n## Criterion")[0])


if __name__ == "__main__":
    main()
