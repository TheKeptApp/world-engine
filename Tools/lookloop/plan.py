#!/usr/bin/env python3
"""Look-loop plan: decides which views to capture and which to carry over from the last
published run because nothing that renders or grades them has changed.

  Tools/lookloop/plan.py <run-dir> [--all] [view-id ...]

A view's fingerprint covers what is rendered (git trees of Sources, Apps/WorldLab, Package.swift and
the view's area, plus any uncommitted changes there and the converted dog asset), how it is captured
(its views.json entry, the common args, capture.sh) and how it is graded (GRADING.md, its target
images). A view is reused only when its fingerprint equals the one recorded in
docs/lookloop/latest/run.json and latest holds its frame and a valid grade.

Writes <run>/views.tsv (views to capture), <run>/reused.json, fingerprints into <run>/run.json, and
for reused views raw/<id>.png and grades/<id>.json copied from latest.
"""
import hashlib, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LATEST = os.path.join(ROOT, "docs/lookloop/latest")


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True).stdout


def tree(path):
    return git("rev-parse", f"HEAD:{path}").strip() or "missing"


def dirty(paths):
    """Uncommitted changes (tracked diff plus untracked file names and sizes) under these paths."""
    h = hashlib.sha256(git("diff", "HEAD", "--", *paths).encode())
    for f in sorted(git("ls-files", "--others", "--exclude-standard", "--", *paths).split()):
        try:
            h.update(f"{f}:{os.path.getsize(os.path.join(ROOT, f))}".encode())
        except OSError:
            pass
    return h.hexdigest()[:16]


def file_sig(path):
    p = os.path.join(ROOT, path)
    if os.path.isdir(p):
        return ",".join(f"{n}:{os.path.getsize(os.path.join(p, n))}" for n in sorted(os.listdir(p)))
    return hashlib.sha256(open(p, "rb").read()).hexdigest()[:16] if os.path.exists(p) else "missing"


def fingerprints(views, common):
    shared = {
        "Sources": tree("Sources"), "WorldLab": tree("Apps/WorldLab"), "Package.swift": tree("Package.swift"),
        "dirty": dirty(["Sources", "Apps/WorldLab", "Package.swift", "Data/areas"]),
        "dog": file_sig("Generated/dog"), "common": common, "capture": file_sig("Tools/lookloop/capture.sh"),
        "grading": file_sig("docs/lookloop/GRADING.md"),
    }
    out = {}
    for v in views:
        parts = dict(shared, area=tree(f"Data/areas/{v.get('area', 'sloans-lake')}"),
                     view=json.dumps(v, sort_keys=True), targets=[file_sig(t["path"]) for t in v.get("targets", [])])
        out[v["id"]] = hashlib.sha256(json.dumps(parts, sort_keys=True).encode()).hexdigest()[:20]
    return out


def main():
    run = os.path.abspath(sys.argv[1])
    force = "--all" in sys.argv
    only = {a for a in sys.argv[2:] if not a.startswith("--")}
    manifest = json.load(open(os.path.join(ROOT, "Tools/lookloop/views.json")))
    views = [v for v in manifest["views"] if v.get("active", True) is not False and (not only or v["id"] in only)]
    fps = fingerprints(views, manifest["commonArgs"])

    prev_meta = json.load(open(os.path.join(LATEST, "run.json"))) if os.path.exists(os.path.join(LATEST, "run.json")) else {}
    prev_fps = prev_meta.get("fingerprints", {})
    prev_grades = {}
    if os.path.exists(os.path.join(LATEST, "grades.json")):
        for vid, entry in json.load(open(os.path.join(LATEST, "grades.json")))["views"].items():
            if entry.get("grade") and "error" not in entry["grade"]:
                prev_grades[vid] = entry

    os.makedirs(os.path.join(run, "raw"), exist_ok=True)
    os.makedirs(os.path.join(run, "grades"), exist_ok=True)
    capture, reused = [], {}
    for v in views:
        vid = v["id"]
        frame = os.path.join(LATEST, "frames", f"{vid}.jpg")
        if not force and prev_fps.get(vid) == fps[vid] and vid in prev_grades and os.path.exists(frame):
            from PIL import Image
            Image.open(frame).convert("RGB").save(os.path.join(run, "raw", f"{vid}.png"))
            g = dict(prev_grades[vid]["grade"], reusedFrom=prev_meta.get("stamp"))
            json.dump(g, open(os.path.join(run, "grades", f"{vid}.json"), "w"), indent=1)
            reused[vid] = {"stamp": prev_meta.get("stamp"), "perf": prev_grades[vid]["signals"].get("perf", {})}
        else:
            capture.append(v)
    with open(os.path.join(run, "views.tsv"), "w") as f:
        for v in capture:
            f.write(v["id"] + "\t" + " ".join(v["args"]) + "\n")
    json.dump(reused, open(os.path.join(run, "reused.json"), "w"), indent=1)
    meta_path = os.path.join(run, "run.json")
    meta = json.load(open(meta_path))
    meta.update(fingerprints=fps, captured=[v["id"] for v in capture], reused=sorted(reused), forced=force)
    json.dump(meta, open(meta_path, "w"), indent=1)
    print(f"plan: capture {len(capture)} view(s), reuse {len(reused)} unchanged since {prev_meta.get('stamp', '-')}"
          + (" (--all: nothing reused)" if force else ""))


if __name__ == "__main__":
    main()
