#!/usr/bin/env python3
"""Batched capture: one WorldLab launch per area with `-viewlist64` (5A's view-list hook), a Simulator
screenshot at each `VIEWREADY id=…`, per-view log slices for analyze.py.

  Tools/lookloop/batch.py <run-dir> <udid> <bundle> <common-args-json>

Reads <run>/views.tsv (id \\t args). Writes raw/<id>.png, logs/<id>.log (the launch's STATS line, the
RENDER/VIEW lines while that view was up, and its VIEWSHOT line) and appends to capture.tsv. Exits 4
without capturing anything when the build has no view-list hook (no VIEWREADY), so the caller can fall
back to one launch per view. Env: SETTLE (view settle seconds), LOAD_TIMEOUT.
"""
import base64, functools, json, os, shutil, subprocess, sys, time

print = functools.partial(print, flush=True)  # progress lines reach the run log as they happen

run, udid, bundle, common = sys.argv[1], sys.argv[2], sys.argv[3], json.loads(sys.argv[4])
settle = os.environ.get("SETTLE", "3")
load_timeout = float(os.environ.get("LOAD_TIMEOUT", "120"))
os.makedirs(os.path.join(run, "raw"), exist_ok=True)
os.makedirs(os.path.join(run, "logs"), exist_ok=True)


def area_of(args):
    a = args.split()
    return a[a.index("-area") + 1] if "-area" in a else "sloans-lake"


def date_of(args):
    a = args.split()
    return a[a.index("-date") + 1] if "-date" in a else None


# One launch per (area, calendar date): the world bakes its season and palette from the launch date, so a
# view that sets another date in place would keep the wrong season. Each group launches with its date.
groups = {}
for line in open(os.path.join(run, "views.tsv")):
    vid, args = line.rstrip("\n").split("\t", 1)
    d = date_of(args)
    groups.setdefault((area_of(args), d[:10] if d else None), []).append((vid, args, d))


def record(vid, status, seconds="-"):
    with open(os.path.join(run, "capture.tsv"), "a") as f:
        f.write(f"{vid}\t{status}\t{seconds}\n")


first = True
for (area, day), views in groups.items():
    launch_date = next((d for _, _, d in views if d), None)
    views = [(vid, args) for vid, args, _ in views]
    specs = []
    for vid, args in views:
        a = args.split()
        if "-area" in a:  # the area is a launch argument, not a per-view one
            i = a.index("-area")
            a = a[:i] + a[i + 2:]
        specs.append({"id": vid, "args": a})
    log = os.path.join(run, "logs", f"_launch-{area}-{day or 'default'}.log")
    # Never pre-create the log (com.apple.provenance on files this session makes gets the launch refused).
    if os.path.exists(log):
        os.remove(log)
    launch = ["xcrun", "simctl", "launch", "--terminate-running-process", f"--stdout={log}", f"--stderr={log}", udid, bundle,
              *common, *(["-area", area] if area != "sloans-lake" else []), *(["-date", launch_date] if launch_date else []),
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
                print(f"  {area} {day or ''}: world in {time.time() - t0:.1f} s")
            elif ln.startswith("VIEWREADY id="):
                # The app captures its own frame right after this line and then moves on, so a simctl
                # screenshot lands on the NEXT view. Frames come from the in-app capture (VIEWSHOT);
                # one UI screenshot per launch shows the OSM credit is on screen.
                vid = ln.split("=", 1)[1].strip()
                seen.add(vid)
                if len(seen) == 1:
                    os.makedirs(os.path.join(run, "ui"), exist_ok=True)
                    try:
                        subprocess.run(["xcrun", "simctl", "io", udid, "screenshot", os.path.join(run, "ui", f"{area}-{day or 'default'}.png")],
                                       capture_output=True, timeout=30)
                    except subprocess.TimeoutExpired:
                        pass
            elif ln.startswith("VIEWSHOT id="):
                vid = ln.split()[1].split("=", 1)[1]
                if "file=" in ln:
                    container = subprocess.run(["xcrun", "simctl", "get_app_container", udid, bundle, "data"],
                                               capture_output=True, text=True).stdout.strip()
                    src = os.path.join(container, "Documents", ln.split("file=", 1)[1].split()[0])
                    if os.path.exists(src):
                        shutil.copy(src, os.path.join(run, "raw", f"{vid}.png"))
                body = [stats or ""] + [c for c in chunk if c.startswith(("RENDER ", "VIEW "))] + [ln]
                open(os.path.join(run, "logs", f"{vid}.log"), "w").write("\n".join(body) + "\n")
                chunk = []
                ok = os.path.exists(os.path.join(run, "raw", f"{vid}.png")) and "failed" not in ln and "skipped" not in ln
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

# Record where the frames came from (reviewers must not flag the missing UI overlay on in-app frames).
meta_path = os.path.join(run, "run.json")
if os.path.exists(meta_path):
    meta = json.load(open(meta_path))
    meta["frameSource"] = "in-app capture (WorldLab -viewlist, Documents/views); UI screenshots with the OSM credit in ui/"
    json.dump(meta, open(meta_path, "w"), indent=1)
