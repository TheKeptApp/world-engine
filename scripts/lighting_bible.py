#!/usr/bin/env python3
"""The lighting bible's twelve states, rendered on the iPhone and measured against its targets.

  scripts/lighting_bible.py run [out-dir] [--tune SPEC]... [--only STATE,...]
                                                 one WorldLab launch on the phone (scripts/device_views.sh)
                                                 steps through the fixtures (once per --tune variant,
                                                 WorldLab's `-tune` look tuning), then `check`
  scripts/lighting_bible.py check <frames-dir>   whole-frame signals against the targets
  scripts/lighting_bible.py views [--tune SPEC]... [--only STATE,...]   print the view list (JSON)

Source, read-only: docs/proposals/look-fix-v1 (LOOK-FIX-SPEC.md §2.1-2.2 and lighting-fixtures.json):
the Sloan's Lake north-shore trail camera (eye 1.65 m, heading 100°, 3° down, 50° vertical FOV) at
twelve dated synthetic states. Signals are the look loop's own (Tools/lookloop/analyze.py), over the
whole frame. Tolerances per §2.2: mean ±10, percentiles ±12, saturation ±12. Frames are WorldLab's
in-app captures (no OSM credit plate, which §2.1 would include: a few hundred pixels).
Weather inputs the fixtures leave open are set here and printed with the view list: fog uses the
bible's "medium" fog (visibility 350 m); snow cover 0.8 is SWE 9.7 mm (cover = 1 - exp(-SWE/6)).
"""
import json
import os
import subprocess
import sys
from datetime import datetime

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXTURES = os.path.join(ROOT, "docs/proposals/look-fix-v1/lighting-fixtures.json")
sys.path.insert(0, os.path.join(ROOT, "Tools/lookloop"))
from analyze import signals  # noqa: E402  (the look loop's measurement, unchanged)

# Targets from the generated bible data (scripts/lookfix_data.py reads them out of the proposal):
# §2.2 Y mean, P5, P50, P95 and mean saturation (HSV S, 0-255), §2.3 lift where the framing allows.
BIBLE = json.load(open(os.path.join(ROOT, "Sources/WorldGen/Profiles/lighting-bible.json")))
TARGETS = {k: (v["luma"], v["p5"], v["p50"], v["p95"], v["saturationS"]) for k, v in BIBLE["states"].items()}
NIGHT = {"moon-night", "moonless-night"}
# The path lift boxes fit the states that share the 15:30 sun and framing.
LIFT = {k: tuple(BIBLE["states"][k]["lift"]) for k in ("ordinary-1530", "overcast", "light-rain", "storm", "fog")}


def state(fid):
    return fid.split("~")[0].split("-", 2)[2]  # lighting-03-ordinary-1530~1 -> ordinary-1530


def weather(f):
    s, cc = state(f["id"]), f["cloudCover"]
    if s == "fog":
        return f"label=fog,cloud={cc},wetness={f['wetness']},visibility=350"
    if f["snowCover"] > 0:
        return f"label=snow,cloud={cc},wetness={f['wetness']},swe=9.7,rate=0"
    if f["rainMmPerHour"] >= 4:
        return f"label=thunderstorm,cloud={cc},rate={f['rainMmPerHour']},wetness={f['wetness']}"
    if f["rainMmPerHour"] > 0:
        return f"label=rain,cloud={cc},rate={f['rainMmPerHour']},wetness={f['wetness']}"
    return f"label={'cloudy' if cc >= 0.7 else 'clear'},cloud={cc}"


def views(tunes=(None,), only=None):
    """Fixture views, once per tuning variant (ids get ~N when there are several)."""
    doc = json.load(open(FIXTURES))
    o, c = doc["observer"], doc["camera"]
    cam = f"{o['latitude']},{o['longitude']},{c['headingDeg']},{c['downPitchDeg']},{c['verticalFovDeg']}"
    out = []
    for i, tune in enumerate(tunes):
        for f in doc["fixtures"]:
            if only and state(f["id"]) not in only:
                continue
            utc = datetime.fromisoformat(f["utc"]).strftime("%Y-%m-%dT%H:%M:%SZ")
            args = ["-camera", cam, "-date", utc, "-weatherspec", weather(f)] + (["-tune", tune] if tune else [])
            out.append({"id": f["id"] + (f"~{i}" if len(tunes) > 1 else ""), "args": args, "tune": tune or ""})
    return out


def lift(im):
    """Shade-to-sun ratio (linear luminance) of the path at the ordinary 15:30 framing: sunlit path
    centre vs the near tree's shadow on it (bible §2.3 lift, 0.30-0.38 at 15:30)."""
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    def y(box):
        px = list(im.crop(box).get_flattened_data())
        r, g, b = (sum(p[i] for p in px) / len(px) for i in range(3))
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    w, h = im.size
    sx, sy = w / 982, h / 553
    sun = y((int(400 * sx), int(455 * sy), int(440 * sx), int(475 * sy)))
    shade = y((int(170 * sx), int(530 * sy), int(230 * sx), int(548 * sy)))
    return shade / max(sun, 1e-6)


def check(frames):
    vf = os.path.join(frames, "views.json")
    listed = json.load(open(vf)) if os.path.exists(vf) else views()
    rows, passed, total, last_tune = [], 0, 0, None
    print(f"{'state':<16} {'Y mean':>12} {'P5':>9} {'P50':>9} {'P95':>9} {'sat':>9}  extra")
    for v in listed:
        if v.get("tune", "") != last_tune:
            last_tune = v.get("tune", "")
            print(f"-- tune: {last_tune or 'none'}")
        path = os.path.join(frames, v["id"] + ".png")
        if not os.path.exists(path):
            print(f"{state(v['id']):<16} missing frame")
            continue
        im = Image.open(path).convert("RGB")
        sig = signals(im)
        t = TARGETS[state(v["id"])]
        got = (sig["lumaMean"], sig["lumaP5"], sig["lumaP50"], sig["lumaP95"], sig["saturationMean"])
        tol = (10, 12, 12, 12, 12)
        cells = []
        for g, want, d in zip(got, t, tol):
            ok = abs(g - want) <= d
            passed += ok
            total += 1
            cells.append(f"{g:5.0f}/{want:<3}{' ' if ok else '!'}")
        extra = f"black {sig['clipBlackPct']}% white {sig['clipWhitePct']}%"
        if state(v["id"]) in LIFT:
            lo, hi = LIFT[state(v["id"])]
            extra += f"  lift {lift(im):.2f} ({lo:.2f}-{hi:.2f})"
        if state(v["id"]) in NIGHT:
            lum = im.convert("L", (0.2126, 0.7152, 0.0722, 0)).histogram()
            dark = sum(lum[:80]) / sum(lum)
            extra += f"  below Y80 {dark:.0%} (≥65%)"
        print(f"{state(v['id']):<16} " + " ".join(f"{c:>9}" for c in cells) + "  " + extra)
        rows.append({"id": v["id"], "got": got, "target": t, **{k: sig[k] for k in ("clipBlackPct", "clipWhitePct")}})
    print(f"\n{passed}/{total} values within tolerance (got/target, ! = outside)")
    json.dump(rows, open(os.path.join(frames, "lighting-bible.json"), "w"), indent=1)


def main():
    args = sys.argv[1:]
    tunes = [args[i + 1] for i, a in enumerate(args) if a == "--tune"] or [None]
    only = next((set(args[i + 1].split(",")) for i, a in enumerate(args) if a == "--only"), None)
    pos = [a for i, a in enumerate(args) if not a.startswith("--") and (i == 0 or args[i - 1] not in ("--tune", "--only"))]
    cmd = pos[0] if pos else "run"
    if cmd == "views":
        print(json.dumps(views(tunes, only), indent=1))
    elif cmd == "check":
        check(pos[1])
    elif cmd == "run":
        out = os.path.abspath(pos[1] if len(pos) > 1 else os.path.join(
            ROOT, ".build/lighting-bible", datetime.now().strftime("%Y%m%d-%H%M%S")))
        os.makedirs(out, exist_ok=True)
        vf = os.path.join(out, "views.json")
        json.dump(views(tunes, only), open(vf, "w"), indent=1)
        subprocess.run([os.path.join(ROOT, "scripts/device_views.sh"), out, vf], check=False)
        check(out)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
