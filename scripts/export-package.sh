#!/bin/bash
# Exports the shared world package for the WorldLab demo area into Generated/package/<area>/
# (git-ignored), using the same recipe as WorldLab: demo.json focus, golden-hour fixture date,
# plus the noon fixture's light state. Skips the export when nothing it depends on changed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEMO="$ROOT/Apps/WorldLab/Resources/demo.json"
AREA=$(plutil -extract area raw -o - "$DEMO")
OUT="$ROOT/Generated/package/$AREA"
f() { plutil -extract "$1" raw -o - "$DEMO"; }
FOCUS="$(f focus.south),$(f focus.west),$(f focus.north),$(f focus.east)"
GOLDEN=$(f fixtures.goldenUTC)
NOON=$(f fixtures.noonUTC)

if [ -f "$OUT/world.json" ] && [ -z "$(find "$ROOT/Sources/WorldGen" "$ROOT/Sources/WorldGeo" "$ROOT/Sources/WorldMap" "$ROOT/Sources/WorldMesh" \
      "$ROOT/Sources/WorldPackage" "$ROOT/Data/areas/$AREA" "$DEMO" -newer "$OUT/world.json" -type f | head -1)" ]; then
  exit 0
fi
swift build -c release --package-path "$ROOT" --product worldbake 2>&1 | grep -E "error|warning: unre" || true
VERSION="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo dev)$(git -C "$ROOT" diff --quiet 2>/dev/null || echo '+changes')"
"$ROOT/.build/release/worldbake" export "$ROOT/Data/areas/$AREA" "$OUT" --date "$GOLDEN" --focus "$FOCUS" \
  --state "golden=$GOLDEN" --state "noon=$NOON" --version "$VERSION"
