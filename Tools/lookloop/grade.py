#!/usr/bin/env python3
"""Look-loop grading: one headless reviewer sub-agent per view (claude -p, Read tool only),
in parallel, following docs/lookloop/GRADING.md. Writes <run>/grades/<id>.json.

  Tools/lookloop/grade.py <run-dir> [view-id ...]
Env: LOOKLOOP_GRADER_MODEL (default claude-opus-5-5), LOOKLOOP_JOBS (parallel reviewers, default 6),
     LOOKLOOP_GRADE_TIMEOUT seconds per view (default 600).
"""
import concurrent.futures as cf, json, os, re, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODEL = os.environ.get("LOOKLOOP_GRADER_MODEL", "claude-opus-5-5")
JOBS = int(os.environ.get("LOOKLOOP_JOBS", "6"))
TIMEOUT = int(os.environ.get("LOOKLOOP_GRADE_TIMEOUT", "600"))
V2 = ["silhouettes", "palette", "light", "softnessAO", "groundRichness", "characterReadability",
      "depthFog", "houseVariety", "geography", "motion"]
AD = ["adGroundRich", "adRainReadable", "adRegional"]

PROMPT = """You are a strict visual reviewer for WorldEngine. Follow docs/lookloop/GRADING.md exactly to grade view `{id}` of look-loop run `{run}`. Read GRADING.md first, then the view entry in Tools/lookloop/views.json, the `{id}` entry in {run}/signals.json, the contact sheet {run}/sheets/{id}.jpg, the full frame {run}/frames/{id}.jpg and the target PNG(s). Set "grader" to "{model}". Output only the JSON object of section G, with no prose and no code fence."""


def extract(text):
    """The reviewer's JSON object (tolerates a stray fence or sentence around it)."""
    m = re.search(r"\{.*\}", text, re.S)
    if not m:
        raise ValueError("no JSON object in reply")
    return json.loads(m.group(0))


def recompute(g, view):
    """Totals are recomputed from the scores so arithmetic slips never reach the scoreboard."""
    na = set(view.get("na", []))
    for i, k in enumerate(V2, start=1):
        if i in na:
            g["scores"].setdefault(k, {})["score"] = None
    if not view.get("wet"):
        g["artDirection"].setdefault("adRainReadable", {})["score"] = None
    v2 = [g["scores"][k]["score"] for k in V2 if g["scores"].get(k, {}).get("score") is not None]
    ad = [g["artDirection"][k]["score"] for k in AD if g["artDirection"].get(k, {}).get("score") is not None]
    g["v2Total"], g["v2Max"] = sum(v2), 5 * len(v2)
    g["v2Score50"] = round(50 * g["v2Total"] / g["v2Max"], 1) if v2 else None
    g["adMean"] = round(sum(ad) / len(ad), 2) if ad else None
    geo = g["scores"].get("geography", {}).get("score")
    char = g["scores"].get("characterReadability", {}).get("score")
    g["gatePass"] = bool(v2) and g["v2Score50"] >= 40 and min(v2 + ad) >= 3 and (geo or 0) >= 4 \
        and (char is None or char >= 4) and not g.get("hardGateFlags")
    return g


def grade(run, vid, view):
    out = os.path.join(run, "grades", f"{vid}.json")
    rel = os.path.relpath(run, ROOT)
    cmd = ["claude", "-p", PROMPT.format(id=vid, run=rel, model=MODEL), "--model", MODEL,
           "--tools", "Read", "--allowedTools", "Read", "--output-format", "json"]
    last = None
    for attempt in (1, 2):
        t0 = time.time()
        try:
            p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=TIMEOUT)
            reply = json.loads(p.stdout)
            if reply.get("is_error"):
                raise ValueError(reply.get("result", "reviewer error"))
            g = extract(reply.get("result", ""))
            if g.get("view") != vid or "scores" not in g or "artDirection" not in g or len(g.get("topFixes", [])) < 1:
                raise ValueError("reply does not follow GRADING.md section G")
            g = recompute(g, view)
            g["gradeSeconds"] = round(time.time() - t0, 1)
            g["costUSD"] = reply.get("total_cost_usd")
            json.dump(g, open(out, "w"), indent=1)
            return vid, g, None
        except Exception as e:  # noqa: BLE001  (reported, then retried once)
            last = f"attempt {attempt}: {e}"
    json.dump({"view": vid, "error": last}, open(out, "w"), indent=1)
    return vid, None, last


def main():
    run = os.path.abspath(sys.argv[1])
    only = set(sys.argv[2:])
    views = {v["id"]: v for v in json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))["views"]}
    os.makedirs(os.path.join(run, "grades"), exist_ok=True)
    todo = [vid for vid in views if os.path.exists(os.path.join(run, "sheets", f"{vid}.jpg")) and (not only or vid in only)]
    print(f"grading {len(todo)} views with {MODEL}, {JOBS} in parallel")
    with cf.ThreadPoolExecutor(JOBS) as pool:
        for vid, g, err in pool.map(lambda v: grade(run, v, views[v]), todo):
            if err:
                print(f"  {vid}: FAILED ({err})")
            else:
                print(f"  {vid}: {g['v2Score50']}/50  ad {g['adMean']}  gate {'pass' if g['gatePass'] else 'fail'}  ({g['gradeSeconds']} s)")


if __name__ == "__main__":
    main()
