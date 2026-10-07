#!/usr/bin/env python3
"""ChatGPT drop folder -> repo (owner process, 6 Oct 2026).

  Tools/lookloop/ingest_drop.py            show what is new or changed in ~/Desktop/worldengine-gpt-drop/
  Tools/lookloop/ingest_drop.py --apply    copy it in
  Tools/lookloop/ingest_drop.py [--apply] PACK...   only these packs

ChatGPT saves each pack to ~/Desktop/worldengine-gpt-drop/<pack>/, outside the repo. A pack with images is a
design pack and goes to docs/proposals/<pack>/; a pack without images is research and goes to
docs/research-gpt/<pack>/ (Tools/lookloop/drop-map.json overrides the destination per pack).
- Text files (md, json, csv, txt, html, prompts, SVG up to 1 MB) are copied into this checkout for commit.
- Images (png, jpg, jpeg, zip, SVG over 1 MB) are gitignored: they are copied into the owner's checkout
  (~/Desktop/world-engine, where the images live) and this one, then backup_design_images.sh copies them to iCloud.
Text files are filed with absolute user paths (/Users/<name>/) replaced by ~/ (owner, 7 Oct 2026).
Filing rules added 7 Oct 2026 (disk was short): hidden folders (.work, ChatGPT scratch) are not filed; images go only to the
owner's checkout (--worktree-images also copies them here); text files over 1 MB and binary documents (xlsx, pdf, docx, pptx)
are kept local like images and named in .gitignore; the pack's own bundle zips (*-all.zip, *-all-files.zip, *-complete.zip)
and the images inside superseded* folders are skipped (their text is filed); --quiet prints one line per pack.
Nothing in the drop folder is ever changed or deleted. A destination file that already exists with different
content is reported and left alone, never overwritten. The caller commits, updates docs/design-registry.md
and runs the backup.
"""
import filecmp, json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OWNER = os.path.expanduser("~/Desktop/world-engine")
DROP = os.environ.get("GPT_DROP") or os.path.expanduser("~/Desktop/worldengine-gpt-drop")
IMAGE = {".png", ".jpg", ".jpeg", ".zip"}
DOC = {".xlsx", ".pdf", ".docx", ".pptx", ".key", ".numbers", ".mp4", ".mov"}
TEXT = {".md", ".json", ".csv", ".txt", ".html", ".svg", ".js", ".css", ".py", ".mjs", ".yml", ".yaml", ".xml"}
MB = 1024 * 1024
BUNDLE_ZIP = re.compile(r"-(all|all-files|complete)\.zip$", re.I)


def kind(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in IMAGE or ext in DOC or (ext in TEXT and os.path.getsize(path) > MB):
        return "image"
    return "text" if ext in TEXT else "other"


def skip_reason(rel, k):
    """Why a file is not filed (None = file it)."""
    parts = rel.split(os.sep)
    if any(p.startswith(".") for p in parts):
        return "hidden work folder"
    if k == "image" and BUNDLE_ZIP.search(rel):
        return "bundle zip (its files are filed one by one)"
    if k == "image" and any(p.startswith("superseded") for p in parts[:-1]):
        return "image in a superseded folder"
    return None


USER_PATH = re.compile(rb"/Users/[^/\s\"'`<>]+/")


def scrub(data):
    """Owner rule (7 Oct 2026): absolute user paths in pack text become ~/ when filed."""
    return USER_PATH.sub(b"~/", data)


def same(a, b):
    """Equal, ignoring CRLF (git stores text with LF) and the user-path scrub."""
    if filecmp.cmp(a, b, shallow=False):
        return True
    try:
        norm = lambda p: scrub(open(p, "rb").read().replace(b"\r\n", b"\n"))
        return norm(a) == norm(b)
    except OSError:
        return False


def plan(only=(), worktree_images=False):
    mp = os.path.join(HERE, "drop-map.json")
    overrides = json.load(open(mp)) if os.path.exists(mp) else {}
    out = []
    for pack in sorted(os.listdir(DROP)) if os.path.isdir(DROP) else []:
        src = os.path.join(DROP, pack)
        if not os.path.isdir(src) or pack.startswith(".") or (only and pack not in only):
            continue
        files = []
        for d, dirs, fs in os.walk(src):
            dirs[:] = [x for x in dirs if not x.startswith(".")]
            files += [os.path.join(d, f) for f in fs if not f.startswith(".")]
        has_images = any(kind(f) == "image" for f in files)
        dest = overrides.get(pack) or (f"docs/proposals/{pack}" if has_images else f"docs/research-gpt/{pack}")
        for f in files:
            rel = os.path.relpath(f, src)
            k = kind(f)
            why = skip_reason(rel, k)
            if why:
                out.append((pack, k, f, None, "skipped (" + why + ")"))
                continue
            targets = [ROOT] if k == "text" else ([OWNER, ROOT] if worktree_images else [OWNER]) if k == "image" else []
            for t in dict.fromkeys(targets):
                d = os.path.join(t, dest, rel)
                state = "new" if not os.path.exists(d) else "same" if same(f, d) else "CONFLICT"
                out.append((pack, k, f, d, state))
            if not targets:
                out.append((pack, k, f, None, "skipped (unknown type)"))
    return out


def main():
    apply = "--apply" in sys.argv
    quiet = "--quiet" in sys.argv
    rows = plan(tuple(a for a in sys.argv[1:] if not a.startswith("--")), worktree_images="--worktree-images" in sys.argv)
    per = {}
    for pack, k, f, d, state in rows:
        if state == "same":
            continue
        if state == "new" and apply:
            os.makedirs(os.path.dirname(d), exist_ok=True)
            if k == "text":
                open(d, "wb").write(scrub(open(f, "rb").read()))
            else:
                shutil.copy2(f, d)
        c = per.setdefault(pack, {})
        key = state if state.startswith(("new", "CONFLICT")) else "skipped"
        c[key] = c.get(key, 0) + 1
        if not quiet or state == "CONFLICT":
            print(f"{state:9} {k:5} {pack}: {os.path.relpath(f, DROP)} -> {d}")
    if quiet:
        for pack, c in sorted(per.items()):
            print(f"{pack:30} " + ", ".join(f"{n} {k}" for k, n in sorted(c.items())))
    # Owner rule: local-only files under this checkout (SVG, big text, binary documents) are named in .gitignore.
    local = sorted({os.path.relpath(d, OWNER if d.startswith(OWNER + os.sep) and not d.startswith(ROOT + os.sep) else ROOT)
                    for _, k, f, d, st in rows if d and k == "image" and not f.lower().endswith((".png", ".jpg", ".jpeg", ".zip"))})
    unignored = [b for b in local if subprocess.run(["git", "check-ignore", "-q", b], cwd=ROOT).returncode != 0]
    if unignored:
        print(("added to" if apply else "would add to") + f" .gitignore (local-only files): {len(unignored)}")
        if apply:
            open(os.path.join(ROOT, ".gitignore"), "a").write("\n# ChatGPT drop: local-only (SVG or text over 1 MB, binary documents)\n" + "\n".join(unignored) + "\n")
    news = sum(1 for r in rows if r[4] == "new")
    conflicts = sum(1 for r in rows if r[4] == "CONFLICT")
    skipped = sum(1 for r in rows if r[4].startswith("skipped"))
    print(f"{'copied' if apply else 'would copy'} {news} file(s); {conflicts} conflict(s) left for review; {skipped} skipped; drop folder untouched")
    sys.exit(1 if conflicts else 0)


if __name__ == "__main__":
    main()
