#!/usr/bin/env python3
"""Daily before/after sheet: six key views at the ccb5f77 baseline vs the latest published run, at phone size.

  Tools/lookloop/daily.py [YYYY-MM-DD]

Baseline frames live in docs/lookloop/daily/baseline-ccb5f77/ (copied once from the ccb5f77 gate run); "after"
frames come from docs/lookloop/latest/frames. Writes docs/lookloop/daily/<date>.png and prints its path.
"""
import json, os, sys, time
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DAILY = os.path.join(ROOT, "docs/lookloop/daily")
BASE = os.path.join(DAILY, "baseline-ccb5f77")
LATEST = os.path.join(ROOT, "docs/lookloop/latest")
# Ordinary day, light rain, smoke, winter (anchor 04), Chicago (anchor 06 area), aerial with the context ring.
VIEWS = ["ordinary-street", "light-rain-street", "showcase-06", "wilmette-street-snow", "lakeview-postcard", "v2-06"]
W = 390  # phone width in points: each frame is shown as it reads on a phone held in landscape-crop
H = round(W * 9 / 16)
PAD, HEAD, LABEL = 12, 44, 22


def font(size):
    for p in ("/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def main():
    day = sys.argv[1] if len(sys.argv) > 1 else time.strftime("%Y-%m-%d")
    meta = json.load(open(os.path.join(LATEST, "run.json")))
    grades = json.load(open(os.path.join(LATEST, "grades.json")))["views"]
    sheet = Image.new("RGB", (PAD * 3 + W * 2, HEAD + len(VIEWS) * (H + LABEL + PAD) + PAD), (24, 24, 26))
    d, f, fs = ImageDraw.Draw(sheet), font(15), font(12)
    d.text((PAD, 8), f"Look loop daily {day}", fill=(240, 240, 240), font=font(17))
    d.text((PAD, 27), f"left: ccb5f77 baseline · right: latest main {meta.get('commit', '?')} ({meta.get('started', '?')}, "
                      f"{meta.get('graders', ['?'])[0] if isinstance(meta.get('graders'), list) else 'routine'})",
           fill=(170, 170, 170), font=fs)
    y = HEAD
    for vid in VIEWS:
        for col, path in enumerate((os.path.join(BASE, f"{vid}.jpg"), os.path.join(LATEST, "frames", f"{vid}.jpg"))):
            x = PAD + col * (W + PAD)
            if os.path.exists(path):
                sheet.paste(Image.open(path).convert("RGB").resize((W, H), Image.LANCZOS), (x, y + LABEL))
            else:
                d.rectangle((x, y + LABEL, x + W, y + LABEL + H), outline=(120, 60, 60))
                d.text((x + 8, y + LABEL + 8), "missing", fill=(200, 120, 120), font=fs)
        g = (grades.get(vid) or {}).get("grade") or {}
        d.text((PAD, y + 3), vid, fill=(240, 240, 240), font=f)
        d.text((PAD + W + PAD, y + 4), f"now {g.get('v2Score50', '–')}/50 · parity {g.get('parity', '–')}%", fill=(170, 170, 170), font=fs)
        y += H + LABEL + PAD
    out = os.path.join(DAILY, f"{day}.png")
    sheet.save(out, optimize=True)
    print(os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main()
