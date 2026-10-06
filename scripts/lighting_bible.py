#!/usr/bin/env python3
"""The lighting bible's twelve states, rendered on the iPhone and measured against its targets.

  scripts/lighting_bible.py run [out-dir]        one WorldLab launch on the phone (scripts/device_views.sh)
                                                 steps through the 12 fixtures, then `check`
  scripts/lighting_bible.py check <frames-dir>   whole-frame signals against the targets
  scripts/lighting_bible.py views                print the view list (JSON)

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

# §2.2 state targets: Y mean, P5, P50, P95, mean saturation (HSV S, 0-255).
TARGETS = {
    "morning": (135, 45, 138, 222, 88), "midday": (145, 55, 148, 226, 90), "ordinary-1530": (140, 48, 143, 224, 90),
    "golden-hour": (130, 36, 128, 222, 94), "blue-hour": (88, 25, 79, 167, 86), "overcast": (137, 64, 139, 207, 54),
    "light-rain": (126, 48, 126, 198, 64), "storm": (96, 29, 91, 172, 60), "fog": (147, 78, 150, 194, 32),
    "snow": (166, 63, 181, 230, 32), "moon-night": (57, 18, 45, 109, 94), "moonless-night": (43, 14, 34, 84, 88),
}
NIGHT = {"moon-night", "moonless-night"}


def state(fid):
    return fid.split("-", 2)[2]  # lighting-03-ordinary-1530 -> ordinary-1530


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


def views():
    doc = json.load(open(FIXTURES))
    o, c = doc["observer"], doc["camera"]
    cam = f"{o['latitude']},{o['longitude']},{c['headingDeg']},{c['downPitchDeg']},{c['verticalFovDeg']}"
    out = []
    for f in doc["fixtures"]:
        utc = datetime.fromisoformat(f["utc"]).strftime("%Y-%m-%dT%H:%M:%SZ")
        out.append({"id": f["id"], "args": ["-camera", cam, "-date", utc, "-weatherspec", weather(f)]})
    return out


def check(frames):
    rows, passed, total = [], 0, 0
    print(f"{'state':<16} {'Y mean':>12} {'P5':>9} {'P50':>9} {'P95':>9} {'sat':>9}  extra")
    for v in views():
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
        if state(v["id"]) in NIGHT:
            lum = im.convert("L", (0.2126, 0.7152, 0.0722, 0)).histogram()
            dark = sum(lum[:80]) / sum(lum)
            extra += f"  below Y80 {dark:.0%} (≥65%)"
        print(f"{state(v['id']):<16} " + " ".join(f"{c:>9}" for c in cells) + "  " + extra)
        rows.append({"id": v["id"], "got": got, "target": t, **{k: sig[k] for k in ("clipBlackPct", "clipWhitePct")}})
    print(f"\n{passed}/{total} values within tolerance (got/target, ! = outside)")
    json.dump(rows, open(os.path.join(frames, "lighting-bible.json"), "w"), indent=1)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "run"
    if cmd == "views":
        print(json.dumps(views(), indent=1))
    elif cmd == "check":
        check(sys.argv[2])
    elif cmd == "run":
        out = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else os.path.join(
            ROOT, ".build/lighting-bible", datetime.now().strftime("%Y%m%d-%H%M%S")))
        os.makedirs(out, exist_ok=True)
        vf = os.path.join(out, "views.json")
        json.dump(views(), open(vf, "w"), indent=1)
        subprocess.run([os.path.join(ROOT, "scripts/device_views.sh"), out, vf], check=False)
        check(out)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
