#!/usr/bin/env python3
"""Per-frame GPU time from an Instruments Metal System Trace.

Usage: scripts/gpu_frames.py <file.trace> [process-name]

Exports the trace's metal-gpu-intervals table and, for the given process (default WorldLab),
reports per frame:
  busy  = union of the frame's GPU intervals (vertex, fragment, compute overlap counted once)
  span  = first GPU start to last GPU end for the frame
"""
import statistics
import subprocess
import sys
import xml.etree.ElementTree as ET

trace = sys.argv[1]
proc_name = sys.argv[2] if len(sys.argv) > 2 else "WorldLab"
xml = subprocess.run(
    ["xcrun", "xctrace", "export", "--input", trace, "--xpath",
     '/trace-toc/run[@number="1"]/data/table[@schema="metal-gpu-intervals"]'],
    capture_output=True, text=True, check=True).stdout
root = ET.fromstring(xml)

# xctrace de-duplicates repeated values: an element with id="N" defines a value, later
# elements with ref="N" reuse it.
by_id = {}


def value(el):
    if el is None:
        return None
    if "ref" in el.attrib:
        return by_id.get(el.attrib["ref"])
    v = (el.text or "").strip()
    fmt = el.attrib.get("fmt", v)
    for child in el.iter():
        if "id" in child.attrib and child is not el:
            by_id[child.attrib["id"]] = ((child.text or "").strip(), child.attrib.get("fmt", ""))
    result = (v, fmt)
    if "id" in el.attrib:
        by_id[el.attrib["id"]] = result
    return result


frames = {}
for row in root.iter("row"):
    cells = list(row)
    # Column order follows the schema: start, duration, channel, frame, latency, depth, label,
    # state, connection, color, process, ...
    vals = [value(c) for c in cells]
    if len(vals) < 11 or vals[0] is None or vals[1] is None:
        continue
    process = vals[10][1] if vals[10] else ""
    if proc_name not in process:
        continue
    try:
        start = int(vals[0][0]); dur = int(vals[1][0]); frame = int(vals[3][0])
    except (TypeError, ValueError):
        continue
    frames.setdefault(frame, []).append((start, start + dur))


def busy(intervals):
    total, cur_s, cur_e = 0, None, None
    for s, e in sorted(intervals):
        if cur_e is None or s > cur_e:
            if cur_e is not None:
                total += cur_e - cur_s
            cur_s, cur_e = s, e
        else:
            cur_e = max(cur_e, e)
    if cur_e is not None:
        total += cur_e - cur_s
    return total


if not frames:
    print("no frames found for", proc_name)
    sys.exit(1)
keys = sorted(frames)[1:-1] or sorted(frames)  # drop partial first/last frames
busy_ms = [busy(frames[k]) / 1e6 for k in keys]
span_ms = [(max(e for _, e in frames[k]) - min(s for s, _ in frames[k])) / 1e6 for k in keys]


def summary(name, xs):
    xs = sorted(xs)
    p95 = xs[min(len(xs) - 1, int(len(xs) * 0.95))]
    worst = xs[-max(1, len(xs) // 100):]   # slowest 1% (mean), like the fps 1% low
    print(f"{name}: frames={len(xs)} mean={statistics.mean(xs):.2f} ms median={statistics.median(xs):.2f} "
          f"p95={p95:.2f} worst1%={statistics.mean(worst):.2f} max={xs[-1]:.2f} over8ms={sum(x > 8 for x in xs)} "
          f"over10ms={sum(x > 10 for x in xs)}")


summary("GPU busy", busy_ms)
summary("GPU span", span_ms)
