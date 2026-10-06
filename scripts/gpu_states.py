#!/usr/bin/env python3
"""GPU performance state over a Metal System Trace: share of time in each state (actual and
desired) per second, to tell a clock change from a workload change.

  scripts/gpu_states.py <file.trace>
"""
import collections
import subprocess
import sys
import xml.etree.ElementTree as ET

trace = sys.argv[1]
xml = subprocess.run(["xcrun", "xctrace", "export", "--input", trace, "--xpath",
                      '/trace-toc/run[@number="1"]/data/table[@schema="gpu-performance-device-state-intervals"]'],
                     capture_output=True, text=True, check=True).stdout
root = ET.fromstring(xml)
by_id = {}
per_second = collections.defaultdict(collections.Counter)
names = {1: "min", 2: "medium", 3: "max"}
for row in root.iter("row"):
    vals = []
    for c in row:
        if "ref" in c.attrib:
            vals.append(by_id.get(c.attrib["ref"]))
        else:
            v = (c.text or "").strip()
            if "id" in c.attrib:
                by_id[c.attrib["id"]] = v
            vals.append(v)
    try:
        start, dur, state, desired = int(vals[0]), int(vals[1]), int(vals[3]), int(vals[4])
    except (TypeError, ValueError, IndexError):
        continue
    per_second[start // 1_000_000_000][(names.get(state, state), names.get(desired, desired))] += dur / 1e6
for s in sorted(per_second):
    total = sum(per_second[s].values())
    parts = ", ".join(f"{a} (wants {b}) {ms / total * 100:.0f}%" for (a, b), ms in per_second[s].most_common())
    print(f"{s:3d} s: busy {total:6.1f} ms  {parts}")
