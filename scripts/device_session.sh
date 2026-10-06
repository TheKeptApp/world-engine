#!/bin/bash
# Daytime device session on the connected iPhone (unplugged, Low Power Mode off), in order:
#   1. walking loop, golden hour, 70 s, with an 8 s Metal System Trace at the maximum GPU clock at ~40 s
#   2. GPU attribution on the fixed street view (scripts/device_attribution.sh)
#   3. rest on the launcher screen, then the 10-minute clear run, rest, the 10-minute rain run
#      (the launcher's test runs: Luna walks the loop at golden hour, 50% brightness, logs to Documents)
#   4. copy the runs' logs from the phone
# Stops at once if a run starts on the charger or in Low Power Mode.
#   scripts/device_session.sh [out-dir]          Env: REST seconds between heavy steps (default 360)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-daytime}"; mkdir -p "$OUT/console" "$OUT/traces" "$OUT/runs"; OUT="$(cd "$OUT" && pwd)"   # xctrace needs absolute paths
REST="${REST:-360}"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
[ -n "$CORE" ] || { echo "No connected iPhone"; exit 1; }
TEMPLATE=$("$ROOT/scripts/make_gpu_template.py" "$ROOT/.build/templates/MetalSystemTrace-max.tracetemplate" 3)
stamp() { date -u +%H:%M:%S; }

# Launches WorldLab with a console log; waits for the CONDITIONS line and stops the session unless
# the phone is unplugged with Low Power Mode off.
launch() { # $1 = log, rest = app args
  local log="$1"; shift
  xcrun devicectl device process launch --device "$CORE" --terminate-existing --console com.lincolnlabs.worldlab -- "$@" > "$log" 2>&1 &
  PID=$!
  for _ in $(seq 1 60); do sleep 1; grep -q "^CONDITIONS" "$log" && break; done
  local cond; cond=$(grep -m1 "^CONDITIONS" "$log")
  echo "   $cond"
  if [[ "$cond" != *"lowPowerMode=false battery=unplugged"* ]]; then
    kill "$PID" 2>/dev/null; echo "STOPPED at $(stamp): not unplugged with Low Power Mode off (or no report)"; exit 2
  fi
}
rest() { # the launcher screen (no world) for $1 seconds
  xcrun devicectl device process launch --device "$CORE" --terminate-existing com.lincolnlabs.worldlab >/dev/null 2>&1
  echo "== rest $1 s from $(stamp)"; sleep "$1"
}
wait_render() { # until the console's RENDER t= reaches $2 seconds (or the app stops)
  local log="$1" target="$2"
  while kill -0 "$PID" 2>/dev/null; do
    local t; t=$(grep -o "^RENDER t=[0-9]*" "$log" | tail -1 | cut -d= -f2)
    [ -n "$t" ] && [ "$t" -ge "$target" ] && break
    sleep 5
  done
}

if [ "${SKIP_LOOP:-0}" != 1 ]; then
echo "== 1. walking loop with a maximum-clock trace, $(stamp)"
LOG="$OUT/console/loop-trace.log"
launch "$LOG" -renderer realitykit -rendertrace -metrics on -testseconds 60 -hud off -weather clear
sleep 35
rm -rf "$OUT/traces/loop-clear.trace"
xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 8s \
  --output "$OUT/traces/loop-clear.trace" --no-prompt >/dev/null 2>&1
wait_render "$LOG" 75
kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
python3 "$ROOT/scripts/gpu_frames.py" "$OUT/traces/loop-clear.trace" > "$OUT/loop-clear-gpu.txt" 2>&1
grep -E "GPU busy|GPU load" "$OUT/loop-clear-gpu.txt"; python3 "$ROOT/scripts/gpu_states.py" "$OUT/traces/loop-clear.trace" | head -3
fi

echo "== 2. GPU attribution, fixed street view, $(stamp)"
# Trace transfer over Wi-Fi takes 25-60 s depending on the Mac's load: 80 s phases, decision phases only by default.
ALLOW_CHARGING=0 VIEW=street PHASE_SECONDS="${PHASE_SECONDS:-80}" PHASES="${PHASES:-all1 noShadows all2 shadow50 all3 shadow30 all4 noMSAA all5}" \
  "$ROOT/scripts/device_attribution.sh" "$OUT/attribution-street" || { echo "attribution stopped"; exit 2; }

rest "$REST"
echo "== 3. 10-minute clear run, $(stamp)"
LOG="$OUT/console/run-clear.log"
launch "$LOG" -renderer realitykit -rendertrace -metrics on -testseconds 600 -hud off -weather clear
wait_render "$LOG" 630
kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
grep "^RENDER" "$LOG" | tail -1; grep -c "^HITCH" "$LOG" | sed 's/^/   hitches over 100 ms: /'

rest "$REST"
echo "== 4. 10-minute rain run, $(stamp)"
LOG="$OUT/console/run-rain.log"
launch "$LOG" -renderer realitykit -rendertrace -metrics on -testseconds 600 -hud off -weather rain
wait_render "$LOG" 630
kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
grep "^RENDER" "$LOG" | tail -1; grep -c "^HITCH" "$LOG" | sed 's/^/   hitches over 100 ms: /'

echo "== 5. copy the runs from the phone, $(stamp)"
OUT_RUNS="$OUT/runs" "$ROOT/scripts/device.sh" pull "$OUT/runs" | tail -8
xcrun devicectl device process launch --device "$CORE" --terminate-existing com.lincolnlabs.worldlab >/dev/null 2>&1
echo "== session done $(stamp)"
