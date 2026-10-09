#!/bin/bash
# Phase 5A gate captures in the Simulator: experience-v1 showcase states 01–12 and the v2 01/04/06
# presets, 16:9 letterboxed, then side-by-side composites with the target images.
#   scripts/gate_shots.sh [out-dir]          (default docs/screenshots/m3)
# Env: SKIP_BUILD=1 reuses the last Simulator build; WAIT seconds per shot (default 30).
set -euo pipefail
export SIM="${SIM:-WorldEngine P0}"   # this session's own Simulator (other sessions use theirs)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/screenshots/m3}"
RAW="$OUT/raw"; mkdir -p "$RAW"
WAIT="${WAIT:-30}"
shot() { # $1 = name, rest = app args
  local name="$1"; shift
  SKIP_BUILD=1 SNAPSHOT_WAIT="$WAIT" "$ROOT/scripts/snapshots.sh" "$RAW/$name.png" -renderer realitykit -hud off -frame16x9 "$@" >/dev/null
  echo "  $name"
}
if [ "${SKIP_BUILD:-0}" != "1" ]; then
  "$ROOT/scripts/build-native.sh" || exit $?
fi
python3 "$ROOT/scripts/native_preflight.py" --stage capture || exit $?
for n in 01 02 03 04 05 06 07 08 09 10 11 12; do shot "showcase-$n" -showcase "$n"; done
for p in v2-01 v2-04 v2-06; do shot "$p" -preset "$p"; done
python3 "$ROOT/scripts/compose_gate.py" "$RAW" "$OUT"
