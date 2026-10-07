#!/usr/bin/env python3
"""Lit colour of the same surfaces in a look-loop frame and in the R-approved style-b-calibration-v2 frames (CIE76 dE).

Usage: python3 Tools/lookloop/calibration_colours.py NEW_STAMP [OLD_STAMP ...]   (stamps under .build/lookloop/runs/)

style-b-calibration-v2 (R, 2026-10-07, binding) owns the look: lighting, exposure, saturation, matte materials. Its
frames are painted stills with their own camera and content, so this is a surface-class comparison (sky, road,
sidewalk, lawn, crowns, sunlit brick) with boxes per frame in Tools/lookloop/calibration-regions.json, next to
region_colours.py (same camera, old hero mocks). Lower is closer; dE <= 5 is the conformance tolerance. Judge the
direction of a move between runs, not the absolute figure. Walls are reference only: the packs own wall albedo, and
the wall box in most views faces away from the sun (see Tools/lookloop/wall_variants.py). Env LOOKLOOP_RUNS overrides
the runs folder.
"""
import json
import os
import statistics as st
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import conformance as cf  # noqa: E402
import region_colours as rc  # noqa: E402
from PIL import Image  # noqa: E402

MASKS = {"brick": lambda p: p[0] >= 130 and p[0] - p[1] >= 30 and p[1] - p[2] >= 8}


def region_colour(im, spec, name):
    """Median colour of a box (fractions) with the surface's pixel filter: sky, crowns or an explicit mask."""
    box, mask = (spec["box"], MASKS[spec["mask"]]) if isinstance(spec, dict) else (spec, None)
    if mask is None:
        return rc.colour(im, box, name)
    w, h = im.size
    px = [p for p in rc.pixels(im.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h))).convert("RGB")) if mask(p)]
    return "#%02X%02X%02X" % tuple(int(st.median(c)) for c in zip(*px)) if len(px) >= 60 else None


def calibration_frame(spec):
    for base in (ROOT, rc.OWNER):  # the images are gitignored: look in the owner's checkout too
        p = os.path.join(base, spec["path"])
        if os.path.exists(p):
            return Image.open(p).convert("RGB")
    raise SystemExit(f"calibration frame not found: {spec['path']} (images are local only; see docs/proposals/style-b-calibration-v2/)")


def main():
    stamps = sys.argv[1:]
    if not stamps:
        raise SystemExit(__doc__)
    cfg = json.load(open(os.path.join(HERE, "calibration-regions.json")))
    eng = json.load(open(os.path.join(HERE, "regions.json")))["views"]
    frames = {k: calibration_frame(v) for k, v in cfg["frames"].items()}
    by_kind = {}
    for vid, pair in cfg["pairs"].items():
        fr = cfg["frames"][pair["frame"]]
        print(f"\n{vid}   (dE to the calibration frame {pair['frame']}: {' <- '.join(stamps)})")
        if vid in cfg["notes"]:
            print(f"  note: {cfg['notes'][vid]}")
        for name in pair["surfaces"]:
            ebox = eng[vid]["regions"].get(name)
            if ebox is None:
                continue
            cal = region_colour(frames[pair["frame"]], fr["regions"][name], name)
            cells = []
            for s in stamps:
                p = os.path.join(rc.RUNS, s, "raw", f"{vid}.png")
                if not os.path.exists(p):
                    cells.append(None)
                    continue
                a = region_colour(Image.open(p).convert("RGB"), ebox, name)
                cells.append((a, cal, cf.delta_e76(a, cal)) if a and cal else None)
            lab = None
            if cells and cells[0]:
                la, lc = cf.srgb_to_lab(cells[0][0]), cf.srgb_to_lab(cells[0][1])
                lab = tuple(a - c for a, c in zip(la, lc))
            first = next((c for c in cells if c), None)
            shown = " <- ".join("-" if c is None else f"{c[2]:5.1f}" for c in cells)
            hexes = " ".join("-" if c is None else c[0] for c in cells)
            print(f"  {name:13s} {shown:>26s}   frame {hexes}   calibration {first[1] if first else '-'}"
                  + (f"   newest run minus calibration: dL {lab[0]:+.0f} da {lab[1]:+.0f} db {lab[2]:+.0f}" if lab else "")
                  + ("   (reference only)" if name == "wall" else ""))
            if name != "wall":
                by_kind.setdefault("lawn" if name.endswith("lawn") else name, []).append(cells)
    dirs = {}
    for kind, rows in by_kind.items():
        for r in rows:
            if r[0]:
                la, lc = cf.srgb_to_lab(r[0][0]), cf.srgb_to_lab(r[0][1])
                dirs.setdefault(kind, []).append([a - c for a, c in zip(la, lc)])
    print(f"\nmean dE to the calibration frames by surface, over the hero views ({' <- '.join(stamps)}); walls excluded:")
    for kind, rows in by_kind.items():
        means = []
        for i in range(len(stamps)):
            vals = [r[i][2] for r in rows if r[i]]
            means.append(f"{st.mean(vals):5.1f}" if vals else "-")
        d = [st.mean(c) for c in zip(*dirs[kind])] if kind in dirs else None
        print(f"  {kind:13s} {' <- '.join(means):>26s}   ({len(rows)} regions)"
              + (f"   newest run minus calibration: dL {d[0]:+.0f} da {d[1]:+.0f} db {d[2]:+.0f}" if d else ""))


if __name__ == "__main__":
    main()
