#!/usr/bin/env python3
"""GPU cost by feature: splits a Metal System Trace's per-frame GPU busy time by the phases that
WorldLab's `-attribution` mode printed ("ATTR <phase> <ISO time>").

  scripts/gpu_attribution.py <file.trace> <console.log>

Drops the first 1.5 s of each phase (switch-over) and reports mean / worst-1% GPU busy per phase and
the difference to the "all" phases (all, all2, all3).
"""
import re, statistics, subprocess, sys, xml.etree.ElementTree as ET
from datetime import datetime

trace, console = sys.argv[1], sys.argv[2]
toc = subprocess.run(["xcrun", "xctrace", "export", "--input", trace, "--toc"], capture_output=True, text=True, check=True).stdout
start = datetime.fromisoformat(re.search(r"<start-date>([^<]+)</start-date>", toc).group(1)).timestamp()
phases = []
for line in open(console, errors="replace"):
    m = re.match(r"ATTR (\S+) (\S+)", line.strip())
    if m:
        phases.append((m.group(1), datetime.fromisoformat(m.group(2).replace("Z", "+00:00")).timestamp()))

xml = subprocess.run(["xcrun", "xctrace", "export", "--input", trace, "--xpath",
                      '/trace-toc/run[@number="1"]/data/table[@schema="metal-gpu-intervals"]'],
                     capture_output=True, text=True, check=True).stdout
root = ET.fromstring(xml)
by_id = {}


def value(el):
    if el is None:
        return None
    if "ref" in el.attrib:
        return by_id.get(el.attrib["ref"])
    for child in el.iter():
        if "id" in child.attrib and child is not el:
            by_id[child.attrib["id"]] = ((child.text or "").strip(), child.attrib.get("fmt", ""))
    result = ((el.text or "").strip(), el.attrib.get("fmt", ""))
    if "id" in el.attrib:
        by_id[el.attrib["id"]] = result
    return result


frames = {}
for row in root.iter("row"):
    vals = [value(c) for c in list(row)]
    if len(vals) < 11 or not vals[0] or not vals[1] or "WorldLab" not in (vals[10][1] if vals[10] else ""):
        continue
    try:
        s, d, f = int(vals[0][0]), int(vals[1][0]), int(vals[3][0])
    except (TypeError, ValueError):
        continue
    frames.setdefault(f, []).append((s, s + d))


def busy(iv):
    total, cs, ce = 0, None, None
    for s, e in sorted(iv):
        if ce is None or s > ce:
            if ce is not None:
                total += ce - cs
            cs, ce = s, e
        else:
            ce = max(ce, e)
    return total + (ce - cs if ce is not None else 0)


rows = [(start + min(s for s, _ in iv) / 1e9, busy(iv) / 1e6) for iv in frames.values()]
results = {}
for i, (name, t0) in enumerate(phases):
    if name == "end":
        continue
    t1 = phases[i + 1][1] if i + 1 < len(phases) else t0 + 7
    xs = sorted(b for t, b in rows if t0 + 1.5 <= t < t1)
    if len(xs) < 20:
        continue
    worst = xs[-max(1, len(xs) // 100):]
    results[name] = (statistics.mean(xs), statistics.mean(worst), len(xs))
base = [v[0] for k, v in results.items() if k.startswith("all")]
ref = statistics.mean(base) if base else None
for name, (mean, worst, n) in results.items():
    delta = f"  saves {ref - mean:5.2f} ms" if ref and not name.startswith("all") else ""
    print(f"{name:16s} mean {mean:6.2f} ms  worst1% {worst:6.2f} ms  frames {n}{delta}")
