#!/bin/bash
# Converts DogWell's dog export (read-only handoff folder) for WorldLab:
#   Generated/dog/luna_light.usdz  RealityKit: skeleton, walk clip, coat colors as displayColor
#   Generated/dog/luna_light.glb   three.js: unchanged copy
# Generated/ is git-ignored: DogWell assets are never committed here.
# Needs Blender.app; skips quietly when the handoff or Blender is missing (WorldLab then uses a stand-in).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${DOG_HANDOFF:-$HOME/Desktop/worldengine-handoff/dog}/luna_light.glb"
OUT="$ROOT/Generated/dog"
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
[ -f "$SRC" ] || { echo "convert-dog: no handoff at $SRC (stand-in character will be used)"; exit 0; }
mkdir -p "$OUT"
if [ ! -f "$OUT/luna_light.glb" ] || [ "$SRC" -nt "$OUT/luna_light.glb" ]; then cp "$SRC" "$OUT/luna_light.glb"; fi
if [ -f "$OUT/luna_light.usdz" ] && [ "$OUT/luna_light.usdz" -nt "$SRC" ] && [ "$OUT/luna_light.usdz" -nt "$ROOT/scripts/blender/glb_to_usdz.py" ]; then exit 0; fi
[ -x "$BLENDER" ] || { echo "convert-dog: Blender not found at $BLENDER"; exit 0; }
"$BLENDER" -b --factory-startup -P "$ROOT/scripts/blender/glb_to_usdz.py" -- "$SRC" "$OUT/luna_light.usdz" walk 2>&1 | grep -E "^(CLIP|WROTE)|Error" || true
