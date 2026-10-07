#!/usr/bin/env python3
"""ChatGPT drop folder -> repo (owner process, 6 Oct 2026).

  Tools/lookloop/ingest_drop.py            show what is new or changed in ~/Desktop/worldengine-gpt-drop/
  Tools/lookloop/ingest_drop.py --apply    copy it in

ChatGPT saves each pack to ~/Desktop/worldengine-gpt-drop/<pack>/, outside the repo. A pack with images is a
design pack and goes to docs/proposals/<pack>/; a pack without images is research and goes to
docs/research-gpt/<pack>/ (Tools/lookloop/drop-map.json overrides the destination per pack).
- Text files (md, json, csv, txt, html, prompts, SVG up to 1 MB) are copied into this checkout for commit.
- Images (png, jpg, jpeg, zip, SVG over 1 MB) are gitignored: they are copied into the owner's checkout
  (~/Desktop/world-engine, where the images live) and this one, then backup_design_images.sh copies them to iCloud.
Nothing in the drop folder is ever changed or deleted. A destination file that already exists with different
content is reported and left alone, never overwritten. The caller commits, updates docs/design-registry.md
and runs the backup.
"""
import filecmp, json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OWNER = os.path.expanduser("~/Desktop/world-engine")
DROP = os.environ.get("GPT_DROP") or os.path.expanduser("~/Desktop/worldengine-gpt-drop")
IMAGE = {".png", ".jpg", ".jpeg", ".zip"}
TEXT = {".md", ".json", ".csv", ".txt", ".html", ".svg"}
MB = 1024 * 1024


def kind(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in IMAGE or (ext == ".svg" and os.path.getsize(path) > MB):
        return "image"
    return "text" if ext in TEXT else "other"


def same(a, b):
    """Equal, ignoring CRLF (git stores text with LF)."""
    if filecmp.cmp(a, b, shallow=False):
        return True
    try:
        return open(a, "rb").read().replace(b"\r\n", b"\n") == open(b, "rb").read().replace(b"\r\n", b"\n")
    except OSError:
        return False


def plan():
    mp = os.path.join(HERE, "drop-map.json")
    overrides = json.load(open(mp)) if os.path.exists(mp) else {}
    out = []
    for pack in sorted(os.listdir(DROP)) if os.path.isdir(DROP) else []:
        src = os.path.join(DROP, pack)
        if not os.path.isdir(src) or pack.startswith("."):
            continue
        files = [os.path.join(d, f) for d, _, fs in os.walk(src) for f in fs if not f.startswith(".")]
        has_images = any(kind(f) == "image" for f in files)
        dest = overrides.get(pack) or (f"docs/proposals/{pack}" if has_images else f"docs/research-gpt/{pack}")
        for f in files:
            rel = os.path.relpath(f, src)
            k = kind(f)
            targets = [ROOT] if k == "text" else [OWNER, ROOT] if k == "image" else []
            for t in dict.fromkeys(targets):
                d = os.path.join(t, dest, rel)
                state = "new" if not os.path.exists(d) else "same" if same(f, d) else "CONFLICT"
                out.append((pack, k, f, d, state))
            if not targets:
                out.append((pack, k, f, None, "skipped (unknown type)"))
    return out


def main():
    apply = "--apply" in sys.argv
    rows = plan()
    for pack, k, f, d, state in rows:
        if state == "same":
            continue
        print(f"{state:9} {k:5} {pack}: {os.path.relpath(f, DROP)} -> {d}")
        if apply and state == "new":
            os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copy2(f, d)
    # Owner rule: SVGs over 1 MB are named in .gitignore (PNG, JPG and ZIP under docs/proposals already are).
    big = sorted({os.path.relpath(d, ROOT) for _, k, f, d, _ in rows if d and d.startswith(ROOT + os.sep)
                  and k == "image" and f.lower().endswith(".svg")})
    unignored = [b for b in big if subprocess.run(["git", "check-ignore", "-q", b], cwd=ROOT).returncode != 0]
    if unignored:
        print(("added to" if apply else "would add to") + " .gitignore (SVG over 1 MB): " + ", ".join(unignored))
        if apply:
            open(os.path.join(ROOT, ".gitignore"), "a").write("\n# ChatGPT drop: SVGs over 1 MB\n" + "\n".join(unignored) + "\n")
    news = sum(1 for r in rows if r[4] == "new")
    conflicts = sum(1 for r in rows if r[4] == "CONFLICT")
    print(f"{'copied' if apply else 'would copy'} {news} file(s); {conflicts} conflict(s) left for review; drop folder untouched")
    sys.exit(1 if conflicts else 0)


if __name__ == "__main__":
    main()
