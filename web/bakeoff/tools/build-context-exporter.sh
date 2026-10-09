#!/bin/bash
# Call under scripts/heavy.sh; links unmodified native geometry modules into a bakeoff-only tool.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"
swift build -c release --product worldbake
BIN="$(swift build -c release --show-bin-path)"
OBJECTS=()
for MODULE in WorldGeo WorldMap WorldMesh WorldGen; do
  for OBJECT in "$BIN/$MODULE.build/"*.o; do OBJECTS+=("$OBJECT"); done
done
swiftc -O -I "$BIN/Modules" web/bakeoff/tools/export-context.swift "${OBJECTS[@]}" -o "$BIN/export-context"
printf '%s\n' "$BIN/export-context"
