#!/usr/bin/env python3
"""GPU frame time on the iPhone from Metal's own frame log (no Instruments trace needed).

  scripts/gpu_hud.py <console.log> [--skip SECONDS]

WorldLab launched with MTL_HUD_ENABLED=1, MTL_HUD_LOG_ENABLED=1 and OS_ACTIVITY_DT_MODE=1 (devicectl `-e`,
see scripts/device_views.sh GPU=1) writes `metal-HUD: frame,memA,memB,interval,gpu,interval,gpu,…` to its
console twice a second: frame interval and GPU time in ms for the frames since the previous line.
GPU time is busy time at the clock the GPU runs at: iOS lowers the clock until a frame just fits, so
unpinned numbers rise towards ~15 ms at 60 fps whatever the work. For work comparisons, pin the clock
(Xcode, Devices and Simulators, Device Conditions, GPU Performance State: Maximum).

Splits the log by WorldLab's own markers when there are any:
- `-viewlist` runs: per view, the frames of its settle time before `VIEWREADY id=…` (minus --skip, default 1 s);
- `-attribution` runs: per `ATTR <phase> <iso time>` phase (minus --skip, default 3 s at the phase start);
- anything else: 10 s windows.
"""
import re
import statistics
import sys
from datetime import datetime

HUD = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+)([+-]\d{4}) .*?metal-HUD: ([\d.,]+)")


def hud_time(stamp, zone):
    return datetime.strptime(stamp + zone, "%Y-%m-%d %H:%M:%S.%f%z").timestamp()


def parse(path):
    """Events in file order: ("hud", t, intervals, gpus) and ("mark", kind, name, t or None)."""
    out = []
    for line in open(path, errors="replace"):
        line = line.rstrip("\n")
        m = HUD.match(line)
        if m:
            if "[Logging]" in line:  # the same line again, through the logging subsystem
                continue
            v = [float(x) for x in m.group(3).split(",") if x]
            out.append(("hud", hud_time(m.group(1), m.group(2)), v[3::2], v[4::2]))
        elif line.startswith("VIEWREADY id="):
            out.append(("mark", "ready", line.split("=", 1)[1].split()[0], None))
        elif line.startswith("VIEWSHOT id=") or line.startswith("VIEWS "):
            out.append(("mark", "shot", line.split()[1], None))
        elif line.startswith("ATTR "):
            parts = line.split()
            t = datetime.fromisoformat(parts[2].replace("Z", "+00:00")).timestamp() if len(parts) > 2 else None
            out.append(("mark", "attr", parts[1], t))
    return out


def stats(gpus, intervals):
    if not gpus:
        return "no frames"
    g = sorted(gpus)
    p90 = g[min(len(g) - 1, int(len(g) * 0.9))]
    fps = 1000 / statistics.median(intervals) if intervals else 0
    return f"GPU median {statistics.median(g):5.2f} ms  p90 {p90:5.2f}  max {g[-1]:5.2f}  ({len(g) // 2} frames, {fps:4.1f} fps)"


def main():
    path = sys.argv[1]
    skip = float(sys.argv[sys.argv.index("--skip") + 1]) if "--skip" in sys.argv else None
    ev = parse(path)
    huds = [e for e in ev if e[0] == "hud"]
    if not huds:
        sys.exit("no metal-HUD lines: launch with MTL_HUD_ENABLED=1 MTL_HUD_LOG_ENABLED=1 OS_ACTIVITY_DT_MODE=1")
    marks = [e for e in ev if e[0] == "mark"]
    if any(m[1] == "ready" for m in marks):  # viewlist: the settle frames before each VIEWREADY
        skip = 1.0 if skip is None else skip
        window = []
        for e in ev:
            if e[0] == "hud":
                window.append(e)
            elif e[1] == "ready":
                t0 = window[0][1] + skip if window else 0
                use = [h for h in window if h[1] >= t0]
                print(f"{e[2]:<24} " + stats([g for h in use for g in h[3]], [i for h in use for i in h[2]]))
                window = []
            elif e[1] == "shot":
                window = []
    elif any(m[1] == "attr" for m in marks):  # attribution phases by their timestamps
        skip = 3.0 if skip is None else skip
        phases = [(m[2], m[3]) for m in marks if m[1] == "attr" and m[3] is not None]
        medians = []
        for (name, t0), nxt in zip(phases, phases[1:] + [("", float("inf"))]):
            if name == "end":
                continue
            use = [h for h in huds if t0 + skip <= h[1] < nxt[1]]
            gpus = [g for h in use for g in h[3]]
            medians.append((name, statistics.median(gpus) if gpus else None))
            print(f"{name:<16} " + stats(gpus, [i for h in use for i in h[2]]))
        # A feature's cost: the mean of its neighbouring "all features on" phases minus its own phase.
        print("\nfeature costs (neighbouring all-phases minus the phase; meaningful only with the GPU clock pinned):")
        for k, (name, med) in enumerate(medians):
            if name.startswith("all") or med is None:
                continue
            around = [m for n, m in medians[max(0, k - 1):k + 2] if n.startswith("all") and m is not None]
            if around:
                base = sum(around) / len(around)
                print(f"  {name:<16} {base - med:+6.2f} ms  ({(base - med) / base:+.0%} of {base:.2f} ms)")
    else:  # 10 s windows
        t0 = huds[0][1]
        buckets = {}
        for h in huds:
            buckets.setdefault(int((h[1] - t0) // 10), []).append(h)
        for k in sorted(buckets):
            use = buckets[k]
            print(f"{k * 10:>4}-{k * 10 + 10:<4} s  " + stats([g for h in use for g in h[3]], [i for h in use for i in h[2]]))


if __name__ == "__main__":
    main()
