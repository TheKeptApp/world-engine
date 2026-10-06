#!/usr/bin/env python3
"""Look-loop finish: merges the per-view grades and signals into grades.json and summary.md,
publishes the compressed run to docs/lookloop/latest/ and appends one dated row to
docs/lookloop/scoreboard.md.

  Tools/lookloop/finish.py <run-dir> [--no-publish]
"""
import collections, datetime, json, os, shutil, subprocess, sys, time

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


def main():
    run = os.path.abspath(sys.argv[1])
    publish = "--no-publish" not in sys.argv
    views = {v["id"]: v for v in json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))["views"]}
    signals = json.load(open(os.path.join(run, "signals.json")))
    meta = json.load(open(os.path.join(run, "run.json"))) if os.path.exists(os.path.join(run, "run.json")) else {}
    if meta.get("t0") and not meta.get("minutes"):
        meta["minutes"] = round((time.time() - meta["t0"]) / 60, 1)
        json.dump(meta, open(os.path.join(run, "run.json"), "w"), indent=1)
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
    mean50 = round(sum(g["v2Score50"] for g in scored) / len(scored), 1) if scored else None
    meanAD = [g["adMean"] for g in scored if g.get("adMean") is not None]
    meanAD = round(sum(meanAD) / len(meanAD), 2) if meanAD else None
    passes = sum(1 for g in scored if g["gatePass"])
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
        "aggregate": {"meanV2Score50": mean50, "meanArtDirection": meanAD, "gatePasses": passes, "graded": len(scored),
                      "captured": len(captured), "failedGrades": failed, "placeholders": placeholders,
                      "criterionMeans": {k: round(sum(v) / len(v), 2) for k, v in crit.items()},
                      "fixAreasWeighted": fixes.most_common()},
    }
    json.dump(out, open(os.path.join(run, "grades.json"), "w"), indent=1)

    when = meta.get("started", datetime.datetime.now().strftime("%Y-%m-%d %H:%M"))
    md = [f"# Look loop: latest run", "",
          f"Run {when} · commit `{meta.get('commit', git('rev-parse', '--short', 'HEAD'))}` on `{meta.get('branch', git('branch', '--show-current'))}`"
          f" · {len(captured)} views captured, {len(scored)} graded"
          + (f" ({', '.join(failed)} failed)" if failed else "")
          + (f" · run time {meta['minutes']} min" if meta.get("minutes") else "")
          + f" · grader `{scored[0]['grader'] if scored else '-'}`", "",
          f"**Mean v2 score {fmt(mean50)}/50** · art direction {fmt(meanAD)}/5 · gate passes {passes}/{len(scored)}"
          + (f" · ordinary-day mean {round(sum(ordinary) / len(ordinary), 1)}/50" if ordinary else ""), "",
          "Scores are v2 §8.3 normalised to /50 over the scorable criteria (GRADING.md §E). Frame time and triangles are "
          "Simulator figures from WorldLab's console: use them for change between runs, not as device performance.", "",
          "| View | /50 | AD | Gate | " + " | ".join(SHORT[k] for k in V2[:9]) + " | AD grd | AD rain | AD reg | Luma vs target | Tris | Frame ms | Sheet |",
          "|---|---|---|---|" + "---|" * 9 + "---|---|---|---|---|---|---|"]
    for vid, g, perf, vt in rows:
        sc = lambda k, sect="scores": fmt(g[sect].get(k, {}).get("score")) if g else "?"
        tri = perf.get("triangles")
        md.append(f"| {vid} | {fmt(g['v2Score50']) if g else '?'} | {fmt(g.get('adMean')) if g else '?'} | "
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
        for f in ("grades.json", "summary.md", "overview.jpg", "run.json"):
            if os.path.exists(os.path.join(run, f)):
                shutil.copy(os.path.join(run, f), os.path.join(LATEST, f))
        board = os.path.join(DOCS, "scoreboard.md")
        if not os.path.exists(board):
            open(board, "w").write(
                "# Look-loop scoreboard\n\nOne row per full run (`Tools/lookloop/lookloop.sh run`), newest last. /50 is the mean v2 §8.3 "
                "score normalised over scorable criteria; AD is the art-direction mean (ground richness, rain readability, regional "
                "signature). Simulator frame time and triangles are for change tracking only, not device performance.\n\n"
                "| Date | Commit | Branch | Views | Mean /50 | Ordinary /50 | AD /5 | Gate passes | Worst view | Median tris | Median frame ms | Run min | Grader |\n"
                "|---|---|---|---|---|---|---|---|---|---|---|---|---|\n")
        tris = sorted(p.get("triangles") for _, _, p, _ in rows if p.get("triangles"))
        fms = sorted(p.get("frameMsMedian") for _, _, p, _ in rows if p.get("frameMsMedian"))
        open(board, "a").write(
            f"| {when} | `{meta.get('commit', '-')}` | {meta.get('branch', '-')} | {len(scored)}/{len(captured)} | {fmt(mean50)} | "
            f"{round(sum(ordinary) / len(ordinary), 1) if ordinary else '–'} | {fmt(meanAD)} | {passes} | "
            f"{f'{worst['view']} {worst['v2Score50']}' if worst else '–'} | {f'{tris[len(tris) // 2] // 1000}k' if tris else '–'} | "
            f"{fms[len(fms) // 2] if fms else '–'} | {fmt(meta.get('minutes'))} | {scored[0]['grader'] if scored else '–'} |\n")
        print(f"published {LATEST} and appended a scoreboard row")
    print(open(os.path.join(run, "summary.md")).read().split("\n## Criterion")[0])


if __name__ == "__main__":
    main()
