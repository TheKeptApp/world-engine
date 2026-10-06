#!/bin/bash
# Phase 5A device checks on the connected iPhone (run after scripts/device.sh build). Each step
# launches WorldLab with launch arguments, captures its console, and checks the device conditions
# it reports: a step that starts on the charger or in Low Power Mode stops the whole sequence.
#   scripts/device_checks.sh [out-dir]
set -uo pipefail
# ALLOW_CHARGING=1: functional/overnight runs on the charger; results are labelled "charging" and
# must not be used for heat or battery decisions.
ALLOW_CHARGING="${ALLOW_CHARGING:-0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-phase5a}"
mkdir -p "$OUT/console"
DEVICE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -n "$DEVICE" ] || { echo "No connected iPhone found"; exit 1; }
STAMP=$(date +%Y%m%d-%H%M%S)

run() { # $1 = name, $2 = seconds, rest = app args
  local name="$1" secs="$2"; shift 2
  local log="$OUT/console/$name.log"
  echo "== $name ($secs s): $*"
  xcrun devicectl device process launch --device "$DEVICE" --terminate-existing --console com.lincolnlabs.worldlab -- "$@" \
    > "$log" 2>&1 &
  local pid=$!
  local waited=0 cond=""
  while [ $waited -lt 20 ]; do
    sleep 1; waited=$((waited + 1))
    cond=$(grep -m1 "^CONDITIONS" "$log")
    [ -n "$cond" ] && break
    grep -q "failed to launch" "$log" && break
  done
  echo "   $cond"
  if [[ "$cond" != *"lowPowerMode=false battery=unplugged"* && ! ( "$ALLOW_CHARGING" == 1 && "$cond" == *"lowPowerMode=false"* ) ]]; then
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    grep -m1 -A3 "ERROR" "$log"
    echo "STOPPED: the phone is charging, in Low Power Mode, locked, or did not report its state. Nothing after this step ran."
    exit 2
  fi
  sleep $((secs > waited ? secs - waited : 1))
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  if grep "^CONDITIONS" "$log" | grep -qv "lowPowerMode=false battery=unplugged"; then
    echo "   WARNING: conditions changed during $name; discard it"
  fi
  grep -E "^RENDER" "$log" | tail -2
}

run probe 30 -renderer realitykit -preset street-mid -rendertrace -diag gpustats
run view-loop-2.5x 82 -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off
run view-loop-3.0x 82 -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off -renderscale native
run view-loop-2.0x 82 -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off -renderscale 2.0
run view-pause 32 -renderer realitykit -rendertrace -pausetest 10

# Pull the TestRun logs written during this session (file names carry their start time).
TMP=$(mktemp -d)
xcrun devicectl device copy from --device "$DEVICE" --domain-type appDataContainer --domain-identifier com.lincolnlabs.worldlab \
  --source Documents --destination "$TMP" >/dev/null
find "$TMP" -type f \( -name 'realitykit-*-frames.csv' -o -name 'realitykit-*-seconds.csv' -o -name 'realitykit-*-summary.json' \) | while read -r f; do
  stamp=$(basename "$f" | sed -E 's/^realitykit-([0-9]{8}-[0-9]{6}).*/\1/')
  [[ "$stamp" > "$STAMP" || "$stamp" == "$STAMP" ]] && cp "$f" "$OUT/"
done
rm -rf "$TMP"
ls -1 "$OUT"
