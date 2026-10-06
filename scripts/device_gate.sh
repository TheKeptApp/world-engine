#!/bin/bash
# Phase 5A gate checks on the connected iPhone (after scripts/device.sh build): the street loop at
# 2.5× in Demo clear weather and in light rain, 60 s each, with an 8 s Metal System Trace at the
# GPU's own clocks (performance state "Default") during each, then the logs.
#   scripts/device_gate.sh [out-dir]
set -uo pipefail
# ALLOW_CHARGING=1: functional/overnight runs on the charger; results are labelled "charging" and
# must not be used for heat or battery decisions.
ALLOW_CHARGING="${ALLOW_CHARGING:-0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-phase5a-gate}"
mkdir -p "$OUT/console" "$OUT/traces"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -n "$CORE" ] || { echo "No connected iPhone found"; exit 1; }
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
TEMPLATE=$("$ROOT/scripts/make_gpu_template.py")
STAMP=$(date +%Y%m%d-%H%M%S)

run() { # $1 = name, rest = app args
  local name="$1"; shift
  local log="$OUT/console/$name.log"
  echo "== $name: $*"
  xcrun devicectl device process launch --device "$CORE" --terminate-existing --console com.lincolnlabs.worldlab -- "$@" > "$log" 2>&1 &
  local pid=$! waited=0 cond=""
  while [ $waited -lt 25 ]; do
    sleep 1; waited=$((waited + 1))
    cond=$(grep -m1 "^CONDITIONS" "$log"); [ -n "$cond" ] && break
    grep -q "failed to launch" "$log" && break
  done
  echo "   $cond"
  if [[ "$cond" != *"lowPowerMode=false battery=unplugged"* && ! ( "$ALLOW_CHARGING" == 1 && "$cond" == *"lowPowerMode=false"* ) ]]; then
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    grep -m1 -A3 "ERROR" "$log"
    echo "STOPPED: charging, Low Power Mode, locked, or no report. Nothing after this step ran."; exit 2
  fi
  sleep $((40 - waited))
  rm -rf "$OUT/traces/$name.trace"
  xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 8s \
    --output "$OUT/traces/$name.trace" --no-prompt >/dev/null 2>&1
  python3 "$ROOT/scripts/gpu_frames.py" "$OUT/traces/$name.trace" | tee "$OUT/$name-gpu.txt"
  sleep 45
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  grep "^CONDITIONS" "$log" | grep -qv "lowPowerMode=false battery=unplugged" && echo "   WARNING: conditions changed during $name; discard it"
  grep -E "^RENDER" "$log" | tail -1
}

run loop-clear -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off -weather clear
run loop-rain -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off -weather rain

TMP=$(mktemp -d)
xcrun devicectl device copy from --device "$CORE" --domain-type appDataContainer --domain-identifier com.lincolnlabs.worldlab \
  --source Documents --destination "$TMP" >/dev/null
find "$TMP" -type f -name 'realitykit-*' | while read -r f; do
  s=$(basename "$f" | sed -E 's/^realitykit-([0-9]{8}-[0-9]{6}).*/\1/'); [[ "$s" > "$STAMP" ]] && cp "$f" "$OUT/"
done
rm -rf "$TMP"
ls -1 "$OUT"
