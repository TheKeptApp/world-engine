#!/usr/bin/env python3
"""Compare two look-loop runs view by view, with the frame diff as the noise control.

Usage: python3 Tools/lookloop/compare_runs.py OLD_STAMP NEW_STAMP     (stamps under .build/lookloop/runs/)

Per view: the share of pixels whose frame changed by more than 12 levels (finish.py's rule: under 0.5 % = the same
render, so any score move is grader variance, GRADING.md section N item 5), /50, parity, approved-mock closeness and
house-archetype closeness, and the house-related criteria. Then the mean move of the unchanged-frame views (the
measured grader drift of this pair) next to the mean move of the changed ones, and the core parity mean. Needs the raw
frames of both runs (kept locally for the last few runs).
"""
import json
import os
import statistics as st
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import finish  # noqa: E402  (frame_unchanged thresholds)
import grade  # noqa: E402
from PIL import Image, ImageChops, ImageStat  # noqa: E402

RUNS = os.environ.get("LOOKLOOP_RUNS") or os.path.join(ROOT, ".build/lookloop/runs")


def load(stamp):
    out = {}
    d = os.path.join(RUNS, stamp, "grades")
    for f in sorted(os.listdir(d)):
        if f.endswith(".json"):
            try:
                out[f[:-5]] = json.load(open(os.path.join(d, f)))
            except ValueError:
                pass
    return out


def changed_share(a, b, vid):
    pa, pb = (os.path.join(RUNS, s, "raw", f"{vid}.png") for s in (a, b))
    if not (os.path.exists(pa) and os.path.exists(pb)):
        return None
    A, B = Image.open(pa).convert("RGB"), Image.open(pb).convert("RGB")
    if A.size != B.size:
        return None
    d = ImageChops.difference(A, B).convert("L").point(lambda v: 255 if v > finish.FRAME_TOL else 0)
    return ImageStat.Stat(d).mean[0] / 255


def main():
    old, new = sys.argv[1], sys.argv[2]
    views = {v["id"]: v for v in json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))["views"]}
    scores = json.load(open(os.path.join(ROOT, "docs/lookloop/calibration-scores.json")))["scores"]
    ga, gb = load(old), load(new)

    def parity(g, vid):
        try:
            return grade.recompute(g, views[vid], grade.concept_score(views[vid], scores), grade.paintover_score(views[vid], scores)).get("parity")
        except Exception:  # views without a calibrated concept
            return None

    def crit(g, k):
        return (g.get("scores", {}).get(k) or g.get("artDirection", {}).get(k) or {}).get("score")

    def gap(g, key):
        return (g.get(key) or {}).get("closeness")

    print(f"{'view':30s} {'changed':>8s} {'/50':>13s} {'parity':>9s} {'mock':>6s} {'arch':>6s} {'cal':>6s}  house/silh/ground")
    rows = []
    for vid in sorted(set(ga) & set(gb)):
        a, b = ga[vid], gb[vid]
        ch = changed_share(old, new, vid)
        r = dict(vid=vid, ch=ch, s=(a.get("v2Score50"), b.get("v2Score50")), p=(parity(a, vid), parity(b, vid)),
                 m=(gap(a, "mockGap"), gap(b, "mockGap")), ar=(gap(a, "archetypeGap"), gap(b, "archetypeGap")), cal=(gap(a, "calGap"), gap(b, "calGap")))
        rows.append(r)
        f = lambda t: f"{t[0]}->{t[1]}"
        hs = "/".join(f"{crit(a, k)}->{crit(b, k)}" for k in ("houseVariety", "silhouettes", "groundRichness"))
        flag = "  (same frame)" if ch is not None and ch < finish.FRAME_FRAC else ""
        print(f"{vid:30s} {'-' if ch is None else format(ch, '.1%'):>8s} {f(r['s']):>13s} {f(r['p']):>9s} {f(r['m']):>6s} {f(r['ar']):>6s} {f(r['cal']):>6s}  {hs}{flag}")

    def stats(sel, label):
        ds = [r["s"][1] - r["s"][0] for r in sel if None not in r["s"]]
        dp = [r["p"][1] - r["p"][0] for r in sel if None not in r["p"]]
        if ds:
            print(f"{label}: {len(sel)} views; /50 mean {st.mean(ds):+.2f} (range {min(ds):+.1f}..{max(ds):+.1f}); "
                  f"parity mean {st.mean(dp) if dp else float('nan'):+.1f} over {len(dp)}")
    same = [r for r in rows if r["ch"] is not None and r["ch"] < finish.FRAME_FRAC]
    diff = [r for r in rows if r["ch"] is None or r["ch"] >= finish.FRAME_FRAC]
    print()
    stats(same, "unchanged frames (grader drift)")
    stats(diff, "changed frames")
    both = [r for r in rows if None not in r["p"]]
    if both:
        print(f"core parity mean over {len(both)} common views: {st.mean(r['p'][0] for r in both):.1f} -> {st.mean(r['p'][1] for r in both):.1f}")
    ck = [r for r in rows if None not in r["cal"]]
    if ck:
        print(f"calibration closeness mean over {len(ck)} views: {st.mean(r['cal'][0] for r in ck):.2f} -> {st.mean(r['cal'][1] for r in ck):.2f}")
    mk = [r for r in rows if None not in r["m"]]
    if mk:
        print(f"mock closeness mean over {len(mk)} views: {st.mean(r['m'][0] for r in mk):.2f} -> {st.mean(r['m'][1] for r in mk):.2f}")


if __name__ == "__main__":
    main()
