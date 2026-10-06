#!/usr/bin/env python3
"""Summarizes WorldLab TestRun logs: python3 analyze_runs.py <dir>"""
import csv, glob, json, os, sys, statistics
d = sys.argv[1]
rows = []
for summ in sorted(glob.glob(os.path.join(d, '*-summary.json'))):
    base = summ[:-len('-summary.json')]
    s = json.load(open(summ))
    frames = [float(r['frame_ms']) for r in csv.DictReader(open(base + '-frames.csv'))]
    # steady state: drop the first 5 s like TestRun
    acc = 0; skip = 0
    for i, f in enumerate(frames):
        acc += f
        if acc > 5000: skip = i; break
    st = frames[skip:]
    secs = list(csv.reader(open(base + '-seconds.csv')))
    header = secs[0][0]
    data = [r for r in secs[2:] if r and r[0].isdigit()]
    thermal = [(int(r[0]), r[7]) for r in data]
    changes = []
    for t, th in thermal:
        if not changes or changes[-1][1] != th: changes.append((t, th))
    mem = max(float(r[6]) for r in data) if data else 0
    over25 = 100 * sum(f > 25 for f in st) / len(st)
    over169 = 100 * sum(f > 16.9 for f in st) / len(st)
    p99 = sorted(st)[int(len(st) * 0.99)]
    worst = sorted(st, reverse=True)[:max(1, len(st) // 100)]
    low1 = 1000 / (sum(worst) / len(worst))
    avg = len(st) / (sum(st) / 1000)
    # last two minutes vs minutes 2-3 median frame time
    tsum = 0; per = []
    for f in st:
        tsum += f; per.append((tsum / 1000, f))
    m23 = [f for t, f in per if 60 <= t < 180]; last2 = [f for t, f in per if t >= per[-1][0] - 120]
    rows.append(dict(name=os.path.basename(base), renderer=s['renderer'], seconds=round(s['seconds']), avg=avg, low1=low1,
                     over169=over169, over25=over25, p99=p99, maxms=max(st), thermal=changes, memMB=mem,
                     battery=s.get('batteryUsedPercent'), bStart=s.get('batteryStart'), bEnd=s.get('batteryEnd'),
                     gpuMean=s.get('gpuMsMean'), gpuP95=s.get('gpuMsP95'), gpuMax=s.get('gpuMsMax'),
                     drift=(statistics.median(last2) / statistics.median(m23) - 1) * 100 if m23 and last2 else None,
                     note=s.get('note', ''), header=header))
for r in rows:
    print(json.dumps(r, default=str))
