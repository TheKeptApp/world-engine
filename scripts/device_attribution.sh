#!/bin/bash
# GPU cost by feature on the connected iPhone. WorldLab's `-attribution 60` mode switches one
# feature off at a time (60 s per phase), each "off" phase between two "all features on" phases so
# slow drift (heat, clocks) cancels. The camera is fixed (a moving camera changes the GPU time by
# several ms on its own): VIEW=street (default, `street-mid` with Luna standing, golden hour) or
# VIEW=aerial (the v2 aerial fixture). Fixed 2.5× scale. A 5 s Metal System Trace at
# full GPU clock is recorded inside each phase (long traces hang over Wi-Fi; a trace that would run
# into the next phase is skipped). scripts/attribution_costs.py then compares frames at the same
# GPU clock state (heat can hold the clock below the requested one).
#   scripts/device_attribution.sh [out-dir]
# HUD=1: no traces; GPU time per frame comes from Metal's frame log in the console instead
# (scripts/gpu_hud.py). Pin the GPU clock first (Xcode, Device Conditions, GPU Performance State).
set -uo pipefail
HUD="${HUD:-0}"
HUD_ENV=(); [ "$HUD" = 1 ] && HUD_ENV=(-e '{"MTL_HUD_ENABLED":"1","MTL_HUD_LOG_ENABLED":"1","OS_ACTIVITY_DT_MODE":"1"}')
# ALLOW_CHARGING=1: functional/overnight runs on the charger; results are labelled "charging" and
# must not be used for heat or battery decisions.
ALLOW_CHARGING="${ALLOW_CHARGING:-0}"
VIEW="${VIEW:-street}"
PHASE_SECONDS="${PHASE_SECONDS:-50}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-phase5a-attribution/$VIEW}"; mkdir -p "$OUT/console" "$OUT/traces"; OUT="$(cd "$OUT" && pwd)"   # xctrace needs absolute paths
case "$VIEW" in
  street) PRESET=street-mid ;;
  aerial) PRESET=v2-06 ;;
  *) echo "VIEW must be street or aerial"; exit 1 ;;
esac
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
TEMPLATE=$("$ROOT/scripts/make_gpu_template.py" "$ROOT/.build/templates/MetalSystemTrace-max.tracetemplate" 3)
LOG="$OUT/console/attribution.log"
PHASES="${PHASES:-all1 noShadows all2 shadow50 all3 shadow30 all4 noMSAA all5 noFoliage all6 cutDetail all7 noSky all8 noSurfaceDetail all9 noPost all10 noBuildings all11}"
xcrun devicectl device process launch --device "$CORE" --terminate-existing --console ${HUD_ENV[@]+"${HUD_ENV[@]}"} com.lincolnlabs.worldlab -- \
  -renderer realitykit -preset "$PRESET" -date 2026-10-15T23:44:01Z -weather clear -attribution $PHASE_SECONDS \
  -renderscale 2.5 -rendertrace -hud off > "$LOG" 2>&1 &
PID=$!
for _ in $(seq 1 60); do sleep 1; grep -q "^CONDITIONS" "$LOG" && break; done
COND=$(grep -m1 "^CONDITIONS" "$LOG"); echo "$COND"
[[ "$COND" == *"lowPowerMode=false battery=unplugged"* || ( "$ALLOW_CHARGING" == 1 && "$COND" == *"lowPowerMode=false"* ) ]] || { kill $PID; echo "STOPPED: conditions"; exit 2; }
[[ "$COND" == *"battery=unplugged"* ]] || echo "NOTE: charging run (functional only)" | tee "$OUT/CHARGING"
if [ "$HUD" = 1 ]; then
  for _ in $(seq 1 $(( $(echo $PHASES | wc -w) * PHASE_SECONDS + 120 ))); do sleep 1; grep -q "^ATTR end" "$LOG" && break; kill -0 $PID 2>/dev/null || break; done
  grep "^RENDER" "$LOG" | awk '{print $NF}' | sort | uniq -c   # heat states seen
  kill $PID 2>/dev/null; wait $PID 2>/dev/null
  python3 "$ROOT/scripts/gpu_hud.py" "$LOG" | tee "$OUT/costs.txt"
  exit 0
fi
: > "$OUT/traces.txt"
for phase in $PHASES; do
  for _ in $(seq 1 150); do sleep 1; grep -q "^ATTR $phase " "$LOG" && break; done
  MARK=$(date +%s)
  sleep 2
  rm -rf "$OUT/traces/$phase.trace"
  xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 5s \
    --output "$OUT/traces/$phase.trace" --no-prompt >/dev/null 2>&1 &
  TR=$!
  # Wait for the trace, but never past the end of the phase.
  while kill -0 $TR 2>/dev/null && [ $(( $(date +%s) - MARK )) -lt $((PHASE_SECONDS - 4)) ]; do sleep 1; done
  if kill -0 $TR 2>/dev/null; then
    kill -INT $TR; sleep 2; kill -9 $TR 2>/dev/null
    echo "$phase: trace still running at the end of the phase, dropped" | tee -a "$OUT/traces.txt"
  else
    echo "$phase: trace took $(( $(date +%s) - MARK - 2 )) s" | tee -a "$OUT/traces.txt"
  fi
done
grep "^RENDER" "$LOG" | awk '{print $NF}' | sort | uniq -c   # heat states seen
kill $PID 2>/dev/null; wait $PID 2>/dev/null
python3 "$ROOT/scripts/attribution_costs.py" "$OUT" | tee "$OUT/costs.txt"
