#!/usr/bin/env python3
"""Feature costs from a scripts/device_attribution.sh run, per GPU clock state.

  scripts/attribution_costs.py <attribution-dir>

Heat can hold the GPU below the clock the trace asks for, and the state changes during a run, so
GPU busy time is compared only between frames at the same clock state ("min", "medium", "max").
For each switched-off feature: the mean busy time of its neighbouring "all" phases minus its own,
at every state with enough frames on both sides, also as a share of the frame (shares carry over
between clocks better than milliseconds do). Also prints GPU time per pass (encoder) for each phase.
"""
import bisect
import collections
import os
import re
import statistics
import subprocess
import sys
import xml.etree.ElementTree as ET
from datetime import datetime

ORDER = ["all1", "noShadows", "all2", "noSky", "all3", "noPost", "all4", "noMSAA", "all5", "noSurfaceDetail",
         "all6", "noFoliage", "all7", "noBuildings", "all8", "cutDetail", "all9",
         "shadow50", "all10", "shadow30", "all11"]
STATES = {1: "min", 2: "medium", 3: "max"}
MIN_FRAMES = 30


def table(trace, schema):
    xml = subprocess.run(["xcrun", "xctrace", "export", "--input", trace, "--xpath",
                          f'/trace-toc/run[@number="1"]/data/table[@schema="{schema}"]'],
                         capture_output=True, text=True, check=True).stdout
    by_id = {}

    def value(el):
        if "ref" in el.attrib:
            return by_id.get(el.attrib["ref"])
        result = ((el.text or "").strip(), el.attrib.get("fmt", ""))
        for child in el.iter():
            if "id" in child.attrib and child is not el:
                by_id[child.attrib["id"]] = ((child.text or "").strip(), child.attrib.get("fmt", ""))
        if "id" in el.attrib:
            by_id[el.attrib["id"]] = result
        return result

    for row in ET.fromstring(xml).iter("row"):
        yield [value(c) for c in row]


def union(intervals):
    total, cur_s, cur_e = 0, None, None
    for s, e in sorted(intervals):
        if cur_e is None or s > cur_e:
            if cur_e is not None:
                total += cur_e - cur_s
            cur_s, cur_e = s, e
        else:
            cur_e = max(cur_e, e)
    return total + (cur_e - cur_s if cur_e is not None else 0)


def label(raw):
    raw = re.sub(r"0x[0-9a-f]+", "", raw)
    raw = re.sub(r"CB \d+", "CB", raw)
    raw = re.sub(r"\(\s*WorldLab \(\d+\)\s*\)", "", raw)
    return " ".join(raw.split())


def phase_windows(console):
    """Absolute start times of each phase from WorldLab's `ATTR <phase> <ISO time>` lines."""
    marks = []
    for line in open(console, errors="replace"):
        m = re.match(r"ATTR (\S+) (\S+)", line.strip())
        if m:
            marks.append((m.group(1), datetime.fromisoformat(m.group(2).replace("Z", "+00:00")).timestamp()))
    return {name: (t + 1.5, marks[i + 1][1] if i + 1 < len(marks) else float("inf")) for i, (name, t) in enumerate(marks)}


def trace_start(trace):
    toc = subprocess.run(["xcrun", "xctrace", "export", "--input", trace, "--toc"], capture_output=True, text=True, check=True).stdout
    return datetime.fromisoformat(re.search(r"<start-date>([^<]+)</start-date>", toc).group(1)).timestamp()


def analyse(trace, window=None):
    frames, passes = collections.defaultdict(list), collections.defaultdict(lambda: collections.Counter())
    for v in table(trace, "metal-gpu-intervals"):
        if len(v) < 11 or not v[0] or not v[1] or "WorldLab" not in (v[10][1] if v[10] else ""):
            continue
        try:
            start, dur, frame = int(v[0][0]), int(v[1][0]), int(v[3][0])
        except (TypeError, ValueError):
            continue
        frames[frame].append((start, start + dur))
        passes[frame][f"{v[2][1] if v[2] else '?'}: {label(v[6][1] if v[6] else '?')}"] += dur / 1e6
    spans = []
    for v in table(trace, "gpu-performance-device-state-intervals"):
        try:
            spans.append((int(v[0][0]), int(v[0][0]) + int(v[1][0]), int(v[3][0])))
        except (TypeError, ValueError, IndexError):
            pass
    spans.sort()
    starts = [s for s, _, _ in spans]
    keys = sorted(frames)[1:-1]
    if window:
        # Only frames inside the phase (a late trace can run into the next phase).
        t0 = trace_start(trace)
        keys = [k for k in keys if window[0] <= t0 + (min(s for s, _ in frames[k]) + max(e for _, e in frames[k])) / 2e9 < window[1]]
    by_state = collections.defaultdict(list)
    pass_by_state = collections.defaultdict(lambda: collections.defaultdict(list))
    for k in keys:
        lo, hi = min(s for s, _ in frames[k]), max(e for _, e in frames[k])
        # The state that covers most of the frame's GPU span.
        cover = collections.Counter()
        i = max(0, bisect.bisect_right(starts, lo) - 1)
        while i < len(spans) and spans[i][0] < hi:
            a, b, st = spans[i]
            cover[st] += max(0, min(b, hi) - max(a, lo))
            i += 1
        state = STATES.get(cover.most_common(1)[0][0], "?") if cover else "unknown"
        # Frames that straddle a state change are left out.
        if cover and cover.most_common(1)[0][1] < 0.8 * sum(cover.values()):
            state = "mixed"
        by_state[state].append(union(frames[k]) / 1e6)
        for name, ms in passes[k].items():
            pass_by_state[state][name].append(ms)
    return by_state, pass_by_state


def main():
    out = sys.argv[1]
    console = os.path.join(out, "console", "attribution.log")
    windows = phase_windows(console) if os.path.exists(console) else {}
    data = {}
    for phase in ORDER:
        trace = os.path.join(out, "traces", f"{phase}.trace")
        if os.path.isdir(trace):
            try:
                data[phase] = analyse(trace, windows.get(phase))
            except (subprocess.CalledProcessError, ET.ParseError, ValueError) as failure:
                print(f"  {phase}: trace unreadable ({type(failure).__name__}), skipped")
    print("GPU busy per frame by clock state (frames):")
    for phase, (by_state, _) in data.items():
        cells = [f"{st} {statistics.mean(v):5.2f} ms ({len(v)})" for st, v in sorted(by_state.items()) if v]
        print(f"  {phase:16s} " + "  ".join(cells))
    print("\nFeature costs (neighbouring all phases minus the phase, same clock state):")
    for i, phase in enumerate(ORDER):
        if phase.startswith("all") or phase not in data:
            continue
        nb = [ORDER[j] for j in (i - 1, i + 1) if 0 <= j < len(ORDER) and ORDER[j] in data]
        rows = []
        for st, v in data[phase][0].items():
            if st in ("mixed", "unknown") or len(v) < MIN_FRAMES:
                continue
            ref = [statistics.mean(data[n][0][st]) for n in nb if len(data[n][0].get(st, [])) >= MIN_FRAMES]
            if not ref:
                continue
            base = sum(ref) / len(ref)
            saving = base - statistics.mean(v)
            rows.append(f"{st}: saves {saving:5.2f} ms of {base:5.2f} ({saving / base * 100:4.1f}%; {len(ref)} neighbour(s))")
        print(f"  {phase:16s} " + ("  |  ".join(rows) if rows else "no common clock state with its neighbours"))
    print("\nGPU time per pass, ms per frame (largest clock state of each phase):")
    for phase, (by_state, pass_by_state) in data.items():
        st = max((s for s in by_state if s not in ("mixed", "unknown")), key=lambda s: len(by_state[s]), default=None)
        if not st:
            continue
        parts = sorted(((statistics.mean(v), n) for n, v in pass_by_state[st].items()), reverse=True)
        print(f"  {phase} [{st}]: " + "; ".join(f"{n} {ms:.2f}" for ms, n in parts if ms >= 0.05))


main()
