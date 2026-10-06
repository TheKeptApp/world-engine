#!/usr/bin/env python3
"""Batched capture: one WorldLab launch per area with `-viewlist64` (5A's view-list hook), a Simulator
screenshot at each `VIEWREADY id=…`, per-view log slices for analyze.py.

  Tools/lookloop/batch.py <run-dir> <udid> <bundle> <common-args-json>

Reads <run>/views.tsv (id \\t args). Writes raw/<id>.png, logs/<id>.log (the launch's STATS line, the
RENDER/VIEW lines while that view was up, and its VIEWSHOT line) and appends to capture.tsv. Exits 4
without capturing anything when the build has no view-list hook (no VIEWREADY), so the caller can fall
back to one launch per view. Env: SETTLE (view settle seconds), LOAD_TIMEOUT.
"""
import base64, functools, json, os, subprocess, sys, time

print = functools.partial(print, flush=True)  # progress lines reach the run log as they happen

run, udid, bundle, common = sys.argv[1], sys.argv[2], sys.argv[3], json.loads(sys.argv[4])
settle = os.environ.get("SETTLE", "3")
load_timeout = float(os.environ.get("LOAD_TIMEOUT", "120"))
os.makedirs(os.path.join(run, "raw"), exist_ok=True)
os.makedirs(os.path.join(run, "logs"), exist_ok=True)


def area_of(args):
    a = args.split()
    return a[a.index("-area") + 1] if "-area" in a else "sloans-lake"


groups = {}
for line in open(os.path.join(run, "views.tsv")):
    vid, args = line.rstrip("\n").split("\t", 1)
    groups.setdefault(area_of(args), []).append((vid, args))


def record(vid, status, seconds="-"):
    with open(os.path.join(run, "capture.tsv"), "a") as f:
        f.write(f"{vid}\t{status}\t{seconds}\n")


first = True
for area, views in groups.items():
    specs = []
    for vid, args in views:
        a = args.split()
        if "-area" in a:  # the area is a launch argument, not a per-view one
            i = a.index("-area")
            a = a[:i] + a[i + 2:]
        specs.append({"id": vid, "args": a})
    log = os.path.join(run, "logs", f"_launch-{area}.log")
    # Never pre-create the log (com.apple.provenance on files this session makes gets the launch refused).
    if os.path.exists(log):
        os.remove(log)
    launch = ["xcrun", "simctl", "launch", "--terminate-running-process", f"--stdout={log}", f"--stderr={log}", udid, bundle,
              *common, *(["-area", area] if area != "sloans-lake" else []),
              "-viewlist64", base64.b64encode(json.dumps(specs).encode()).decode(), "-viewsettle", settle]
    env = dict(os.environ, SIMCTL_CHILD_NSUnbufferedIO="YES")
    for attempt in range(6):  # refusals come and go with host load: back off for up to ~2 min
        try:
            if subprocess.run(launch, env=env, capture_output=True, timeout=60).returncode == 0:
                break
        except subprocess.TimeoutExpired:
            pass
        time.sleep(5 * (attempt + 1))
    else:
        for vid, _ in views:
            record(vid, "failed")
        print(f"  {area}: FAILED (launch refused 6 times over ~2 min)")
        continue
    t0, pos, stats, pending, t_stats = time.time(), 0, None, "", None
    seen, chunk, deadline = set(), [], time.time() + load_timeout
    while True:
        text = open(log, errors="replace").read() if os.path.exists(log) else ""
        new, pos = text[pos:], len(text)
        for ln in (pending + new).split("\n")[:-1]:
            chunk.append(ln)
            if ln.startswith("STATS ") and stats is None:
                stats, t_stats = ln, time.time()
                deadline = t_stats + float(settle) + 90
                print(f"  {area}: world in {time.time() - t0:.1f} s")
            elif ln.startswith("VIEWREADY id="):
                vid = ln.split("=", 1)[1].strip()
                try:
                    subprocess.run(["xcrun", "simctl", "io", udid, "screenshot", os.path.join(run, "raw", f"{vid}.png")],
                                   capture_output=True, timeout=30)
                except subprocess.TimeoutExpired:
                    pass
                seen.add(vid)
            elif ln.startswith("VIEWSHOT id="):
                vid = ln.split()[1].split("=", 1)[1]
                body = [stats or ""] + [c for c in chunk if c.startswith(("RENDER ", "VIEW "))] + [ln]
                open(os.path.join(run, "logs", f"{vid}.log"), "w").write("\n".join(body) + "\n")
                chunk = []
                ok = vid in seen and "failed" not in ln and "skipped" not in ln
                record(vid, "ok" if ok else "failed", f"{time.time() - t0:.1f}")
                print(f"  {vid}  {'ok' if ok else 'FAILED: ' + ln}")
                deadline = time.time() + 90  # next view: settle plus set-up
        pending = (pending + new).split("\n")[-1] if (pending + new) else ""
        if "VIEWS done" in text or "VIEWS failed" in text or "Failed to build world" in text:
            break
        if stats is not None and first and not seen and "VIEWREADY" not in text and time.time() - t_stats > float(settle) + 30:
            subprocess.run(["xcrun", "simctl", "terminate", udid, bundle], capture_output=True)
            sys.exit(4)  # no view-list hook in this build: the caller falls back to one launch per view
        if time.time() > deadline:
            print(f"  {area}: timed out waiting for WorldLab")
            break
        time.sleep(0.1)
    first = False
    for vid, _ in views:
        if not os.path.exists(os.path.join(run, "raw", f"{vid}.png")):
            if not any(l.startswith(vid + "\t") for l in open(os.path.join(run, "capture.tsv"))):
                record(vid, "failed")
    subprocess.run(["xcrun", "simctl", "terminate", udid, bundle], capture_output=True)
