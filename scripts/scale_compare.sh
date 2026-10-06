#!/bin/bash
# Render-scale comparison (section A): the same preset at 3.0×, 2.5×, 2.25× and 2.0× in the
# Simulator (same 1206×2622 screen), plus 2× enlarged crops of a detail-heavy region side by side.
#   scripts/scale_compare.sh [out-dir]       (default docs/screenshots/m3/scale; needs a Simulator build)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/screenshots/m3/scale}"; mkdir -p "$OUT"
for s in native 2.5 2.25 2.0; do
  SKIP_BUILD=1 SNAPSHOT_WAIT=30 "$ROOT/scripts/snapshots.sh" "$OUT/street-mid-$s.png" -renderer realitykit -hud off -preset street-mid -renderscale $s >/dev/null
  echo "  $s"
done
python3 - "$OUT" <<'PY'
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
box = (330, 1250, 930, 1650)   # sidewalk joints, tufts, lawn edge, a trunk
tiles = []
for s, label in [("native", "3.0x (native)"), ("2.5", "2.5x"), ("2.25", "2.25x"), ("2.0", "2.0x")]:
    im = Image.open(f"{out}/street-mid-{s}.png").convert("RGB").crop(box)
    im = im.resize((im.width * 2 // 2 * 1, im.height * 1), Image.NEAREST)
    tile = Image.new("RGB", (im.width, im.height + 28), (24, 24, 24))
    tile.paste(im, (0, 28)); ImageDraw.Draw(tile).text((8, 8), label, fill=(235, 235, 235))
    tiles.append(tile)
sheet = Image.new("RGB", (sum(t.width for t in tiles) + 12 * 3, tiles[0].height), (24, 24, 24))
x = 0
for t in tiles:
    sheet.paste(t, (x, 0)); x += t.width + 12
sheet.save(f"{out}/scale-crops.png")
print("wrote", f"{out}/scale-crops.png")
PY
