#!/usr/bin/env python3
"""Lit colour of the same surfaces in a look-loop frame and in its approved mock (same camera), as CIE76 dE.

Usage: python3 Tools/lookloop/region_colours.py NEW_STAMP [OLD_STAMP ...]   (stamps under .build/lookloop/runs/)

The 1-5 mock closeness is too coarse to show a merge that moves a surface part of the way, so this measures it:
for each hero view in Tools/lookloop/regions.json it takes the median colour of fixed boxes (wall, road, sidewalk,
lawns, crowns, sky) in the frame and in the mock, and prints dE to the mock, with the dE of the older runs after the
arrow. Lower is closer. dE <= 5 is the conformance tolerance for a colour. Frames are lit pixels, mocks are paintings:
judge the direction of a move, not the absolute figure. Env LOOKLOOP_RUNS overrides the runs folder.
"""
import json
import os
import statistics as st
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import conformance as cf  # noqa: E402
from PIL import Image  # noqa: E402

OWNER = os.path.expanduser("~/Desktop/world-engine")  # the mock images are gitignored: look in the owner's checkout too
RUNS = os.environ.get("LOOKLOOP_RUNS") or os.path.join(ROOT, ".build/lookloop/runs")
KEEP = {"sky": lambda p: p[2] > p[0] + 15 and p[2] > p[1],
        "crowns": lambda p: p[1] > p[0] + 8 and p[1] > p[2] + 20}


def pixels(im):
    return list(im.get_flattened_data()) if hasattr(im, "get_flattened_data") else list(im.getdata())


def colour(im, box, name):
    w, h = im.size
    px = pixels(im.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h))).convert("RGB"))
    keep = KEEP.get(name)
    if keep:
        px = [p for p in px if keep(p)]
        if len(px) < 60:
            return None
    return "#%02X%02X%02X" % tuple(int(st.median(c)) for c in zip(*px))


def main():
    stamps = sys.argv[1:]
    cfg = json.load(open(os.path.join(HERE, "regions.json")))["views"]
    by_kind = {}
    for vid, v in cfg.items():
        mock = Image.open(next(p for p in (os.path.join(ROOT, v["mock"]), os.path.join(OWNER, v["mock"])) if os.path.exists(p)))
        print(f"\n{vid}   (dE to the mock: {' <- '.join(stamps)})")
        for name, box in v["regions"].items():
            cells = []
            for s in stamps:
                p = os.path.join(RUNS, s, "raw", f"{vid}.png")
                if not os.path.exists(p):
                    cells.append(None)
                    continue
                im = Image.open(p).convert("RGB")
                m = mock.convert("RGB").resize(im.size)
                a, b = colour(im, box, name), colour(m, box, name)
                cells.append((a, b, cf.delta_e76(a, b)) if a and b else None)
            first = next((c for c in cells if c), None)
            shown = " <- ".join("-" if c is None else f"{c[2]:5.1f}" for c in cells)
            mockhex = first[1] if first else "-"
            hexes = " ".join("-" if c is None else c[0] for c in cells)
            print(f"  {name:13s} {shown:>26s}   frame {hexes}   mock {mockhex}")
            kind = "lawn" if name.endswith("lawn") else name
            by_kind.setdefault(kind, []).append(cells)
    print(f"\nmean dE to the mocks by surface, over the hero views ({' <- '.join(stamps)}):")
    for kind, rows in by_kind.items():
        means = []
        for i in range(len(stamps)):
            vals = [r[i][2] for r in rows if r[i]]
            means.append(f"{st.mean(vals):5.1f}" if vals else "-")
        print(f"  {kind:13s} {' <- '.join(means):>26s}   ({len(rows)} regions)")


if __name__ == "__main__":
    main()
