#!/usr/bin/env python3
"""Side-by-side gate sheets: a concept image (docs/proposals, read-only) next to an engine capture.

    scripts/p2_compose_gate.py <captures-dir> <out-dir>

Writes one JPEG per pair, concept on the left, engine on the right, both at the same height, with a
caption strip. Pairs are listed below (concept file, capture file, caption)."""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# PROPOSALS_ROOT: another checkout to read uncommitted proposal folders from (read-only).
CONCEPTS = os.path.join(os.environ.get("PROPOSALS_ROOT", ROOT), "docs/proposals/regions-chicagoland-miami/images")
PAIRS = [
    ("03-northshore-fall.png", "evanston-street.png", "03 North Shore fall (concept) | South Evanston, Wesley Ave, Oct 22 15:00 (engine)"),
    ("04-northshore-snow.png", "evanston-street-winter.png", "04 North Shore snow (concept) | same street, Jan 15 noon, no weather input (engine)"),
    ("06-chicago-alley-snow.png", "lakeview-alley-winter.png", "06 Chicago alley snow (concept) | Lakeview alley, Jan 15 noon, no weather input (engine)"),
    ("06-chicago-alley-snow.png", "lakeview-alley.png", "06 Chicago alley (concept) | Lakeview alley, Oct 22 15:00 (engine)"),
    ("01-northshore-golden.png", "evanston-aerial.png", "01 North Shore (concept) | South Evanston block, low oblique (engine)"),
    ("05-chicago-three-flat.png", "lakeview-street.png", "05 Chicago three-flat (concept) | Lakeview, W Roscoe St (engine)"),
    ("05-chicago-three-flat.png", "lakeview-aerial.png", "05 Chicago three-flat (concept) | Lakeview block, low oblique (engine)"),
]
H = 540


def main() -> None:
    captures, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
    except OSError:
        font = ImageFont.load_default()
    for concept, capture, caption in PAIRS:
        cpath = os.path.join(captures, capture)
        if not os.path.exists(cpath):
            print("skip (no capture):", capture)
            continue
        a = Image.open(os.path.join(CONCEPTS, concept)).convert("RGB")
        b = Image.open(cpath).convert("RGB")
        a = a.resize((round(a.width * H / a.height), H), Image.LANCZOS)
        b = b.resize((round(b.width * H / b.height), H), Image.LANCZOS)
        sheet = Image.new("RGB", (a.width + b.width + 12, H + 40), (24, 26, 30))
        sheet.paste(a, (0, 40))
        sheet.paste(b, (a.width + 12, 40))
        ImageDraw.Draw(sheet).text((10, 8), caption, fill=(235, 235, 235), font=font)
        name = os.path.splitext(capture)[0] + "--" + concept[:2] + ".jpg"
        sheet.save(os.path.join(out, name), quality=86)
        print("wrote", name)


if __name__ == "__main__":
    main()
