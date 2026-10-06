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
from grade import recompute  # noqa: E402  (same totals whether reviewers ran headless or in a session)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DOCS = os.path.join(ROOT, "docs/lookloop")
LATEST = os.path.join(DOCS, "latest")
V2 = ["silhouettes", "palette", "light", "softnessAO", "groundRichness", "characterReadability",
      "depthFog", "houseVariety", "geography", "motion"]
AD = ["adGroundRich", "adRainReadable", "adRegional"]
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
    grades, failed = {}, []
    for vid in views:
        p = os.path.join(run, "grades", f"{vid}.json")
        if os.path.exists(p):
            try:
                g = json.load(open(p))
                if "error" in g or "scores" not in g or "artDirection" not in g:
                    raise ValueError(g.get("error", "not GRADING.md section G"))
                grades[vid] = recompute(g, views[vid])
                json.dump(g, open(p, "w"), indent=1)
            except (ValueError, KeyError, TypeError) as e:
                print(f"  {vid}: grade rejected ({e})")
                failed.append(vid)
    captured = [vid for vid in views if vid in signals]
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
    # Concept parity: the view's /50 as a share of its first target concept's calibrated /50 (calibration.md).
    cp = os.path.join(DOCS, "calibration-scores.json")
    concept = json.load(open(cp))["scores"] if os.path.exists(cp) else {}
    parity = {}
    for vid, g, _, _ in rows:
        t = (views[vid].get("targets") or [{}])[0].get("path")
        if g and t in concept and concept[t]["v2Score50"]:
            parity[vid] = round(100 * g["v2Score50"] / concept[t]["v2Score50"])
    mean_parity = round(sum(parity.values()) / len(parity)) if parity else None
    mean50 = round(sum(g["v2Score50"] for g in scored) / len(scored), 1) if scored else None
    meanAD = [g["adMean"] for g in scored if g.get("adMean") is not None]
    meanAD = round(sum(meanAD) / len(meanAD), 2) if meanAD else None
    passes = sum(1 for g in scored if g["gatePass"])
    adpasses = sum(1 for g in scored if g.get("adPass"))
    worst = min(scored, key=lambda g: g["v2Score50"]) if scored else None
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
        "aggregate": {"meanV2Score50": mean50, "meanConceptParity": mean_parity, "conceptParity": parity, "meanArtDirection": meanAD, "gatePasses": passes, "graded": len(scored),
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
          + (f" · run time {meta['minutes']} min" if meta.get("minutes") else "")
          + f" · graders {', '.join(f'`{x}`' for x in sorted({g.get('grader', '?') for g in scored}))}"
          + (" · **gate run**" if meta.get("gate") else ""), "",
          f"Regression guard: {'**' + str(len(flags)) + ' flag(s)**' if flags else 'no regressions'} ([regressions.md](regressions.md)).", "",
          f"**Mean v2 score {fmt(mean50)}/50** · concept parity {fmt(mean_parity)}% · art direction {fmt(meanAD)}/5 · v2 gate passes {passes}/{len(scored)} · art-direction passes {adpasses}/{len(scored)}"
          + (f" · ordinary-day mean {round(sum(ordinary) / len(ordinary), 1)}/50" if ordinary else ""), "",
          "Scores are v2 §8.3 normalised to /50 over the scorable criteria (GRADING.md §E). Frame time and triangles are "
          "Simulator figures from WorldLab's console: use them for change between runs, not as device performance.", "",
          "| View | /50 | Parity | AD | Gate | " + " | ".join(SHORT[k] for k in V2[:9]) + " | AD grd | AD rain | AD reg | Luma vs target | Tris | Frame ms | Sheet |",
          "|---|---|---|---|---|" + "---|" * 9 + "---|---|---|---|---|---|---|"]
    for vid, g, perf, vt in rows:
        sc = lambda k, sect="scores": fmt(g[sect].get(k, {}).get("score")) if g else "?"
        tri = perf.get("triangles")
        md.append(f"| {vid}{' (reused)' if vid in reused else ''} | {fmt(g['v2Score50']) if g else '?'} | {f"{parity[vid]}%" if vid in parity else '–'} | {fmt(g.get('adMean')) if g else '?'} | "
                  f"{('pass' if g['gatePass'] else 'fail') if g else '?'} | " + " | ".join(sc(k) for k in V2[:9]) + " | "
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
                "| Date | Engine | Branch | Views | Mean /50 | Ordinary /50 | AD /5 | Gate passes | Worst view | Median tris | Median frame ms | Run min | Grader | Regressions |\n"
                "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n")
        tris = sorted(p.get("triangles") for _, _, p, _ in rows if p.get("triangles"))
        fms = sorted(p.get("frameMsMedian") for _, _, p, _ in rows if p.get("frameMsMedian"))
        open(board, "a").write(
            f"| {when} | `{meta.get('engineCommit', meta.get('commit', '-'))}`{'+dirty' if meta.get('dirtyEngineFiles') else ''} | {meta.get('branch', '-')} | {len(scored)}/{len(captured)}{f' ({len(reused & set(captured))} reused)' if reused & set(captured) else ''} | {fmt(mean50)}{f' ({mean_parity}% parity)' if mean_parity else ''} | "
            f"{round(sum(ordinary) / len(ordinary), 1) if ordinary else '–'} | {fmt(meanAD)} | {passes} (AD {adpasses}) | "
            f"{f'{worst['view']} {worst['v2Score50']}' if worst else '–'} | {f'{tris[len(tris) // 2] // 1000}k' if tris else '–'} | "
            f"{fms[len(fms) // 2] if fms else '–'} | {fmt(meta.get('minutes'))} | {', '.join(sorted({g.get('grader', '?') for vid, g in grades.items() if vid not in reused})) or 'all reused'}{' (gate)' if meta.get('gate') else ''} | {len(flags)} |\n")
        print(f"published {LATEST} and appended a scoreboard row")
    print(open(os.path.join(run, "regressions.md")).read())
    print(open(os.path.join(run, "summary.md")).read().split("\n## Criterion")[0])


if __name__ == "__main__":
    main()
