#!/usr/bin/env python3
"""Crops the 16:9 letterboxed Simulator captures and pairs each with its target image.

  scripts/compose_gate.py <raw-dir> <out-dir>
Writes <out-dir>/gate/<name>.png (the 16:9 frame) and <out-dir>/compare/<name>.png (target left,
RealityKit right, same height, labelled), plus <out-dir>/gate-sheet.png.
"""
import glob, json, os, sys
from PIL import Image, ImageDraw

raw, out = sys.argv[1], sys.argv[2]
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
exp = os.path.join(root, "docs/proposals/experience-v1")
manifest = {f["id"]: f for f in json.load(open(os.path.join(exp, "showcase-presets.json")))["fixtures"]}
v2 = {"v2-01": "01", "v2-04": "04", "v2-06": "06"}
os.makedirs(os.path.join(out, "gate"), exist_ok=True)
os.makedirs(os.path.join(out, "compare"), exist_ok=True)


def crop169(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    ch = int(w * 9 / 16)
    top = (h - ch) // 2
    return im.crop((0, top, w, top + ch))


def target_for(name):
    if name.startswith("showcase-"):
        sid = name.split("-")[1]
        if sid in manifest:
            return os.path.join(exp, manifest[sid]["image"]), f"experience-v1 {sid} target (generated concept)"
        return None, None
    if name in v2:
        hits = sorted(glob.glob(os.path.join(root, f"docs/proposals/visual-v2/images/{v2[name]}*.png")))
        return (hits[0], f"visual v2 {v2[name]} target") if hits else (None, None)
    return None, None


frames = []
for path in sorted(glob.glob(os.path.join(raw, "*.png"))):
    name = os.path.splitext(os.path.basename(path))[0]
    frame = crop169(path)
    frame.save(os.path.join(out, "gate", f"{name}.png"))
    frames.append((name, frame))
    tpath, tlabel = target_for(name)
    h = 540
    rk = frame.resize((int(frame.width * h / frame.height), h))
    if tpath:
        t = Image.open(tpath).convert("RGB")
        t = t.resize((int(t.width * h / t.height), h))
        pair = Image.new("RGB", (t.width + rk.width + 12, h + 34), (24, 24, 24))
        pair.paste(t, (0, 34))
        pair.paste(rk, (t.width + 12, 34))
        d = ImageDraw.Draw(pair)
        d.text((8, 10), tlabel, fill=(230, 230, 230))
        d.text((t.width + 20, 10), f"RealityKit (WorldLab Simulator, 16:9 crop): {name}", fill=(230, 230, 230))
        pair.save(os.path.join(out, "compare", f"{name}.png"))

cols = 3
tw, th = 600, 338
sheet = Image.new("RGB", (cols * tw, ((len(frames) + cols - 1) // cols) * (th + 22)), (20, 20, 20))
d = ImageDraw.Draw(sheet)
for i, (name, f) in enumerate(frames):
    x, y = (i % cols) * tw, (i // cols) * (th + 22)
    sheet.paste(f.resize((tw, th)), (x, y + 22))
    d.text((x + 6, y + 5), name, fill=(240, 240, 240))
sheet.save(os.path.join(out, "gate-sheet.png"))
print(f"{len(frames)} frames → {out}")
