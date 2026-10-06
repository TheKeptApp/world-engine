#!/bin/bash
# GPU cost by feature on the connected iPhone: WorldLab's `-attribution` mode switches one feature
# off at a time (7 s each) on the golden-hour street loop while a 75 s Metal System Trace records
# at full GPU clock; scripts/gpu_attribution.py splits the trace by phase.
#   scripts/device_attribution.sh [out-dir]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-phase5a-gate}"; mkdir -p "$OUT/console" "$OUT/traces"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
TEMPLATE=$("$ROOT/scripts/make_gpu_template.py" "$ROOT/.build/templates/MetalSystemTrace-max.tracetemplate" 3)
LOG="$OUT/console/attribution.log"
xcrun devicectl device process launch --device "$CORE" --terminate-existing --console com.lincolnlabs.worldlab -- \
  -renderer realitykit -character luna -mode follow -date 2026-10-15T23:44:01Z -weather clear -attribution -rendertrace -hud off > "$LOG" 2>&1 &
PID=$!
for _ in $(seq 1 60); do sleep 1; grep -q "^CONDITIONS" "$LOG" && break; done
COND=$(grep -m1 "^CONDITIONS" "$LOG"); echo "$COND"
[[ "$COND" == *"lowPowerMode=false battery=unplugged"* ]] || { kill $PID; echo "STOPPED: conditions"; exit 2; }
for _ in $(seq 1 60); do sleep 1; grep -q "^ATTR all " "$LOG" && break; done
rm -rf "$OUT/traces/attribution.trace"
xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 75s \
  --output "$OUT/traces/attribution.trace" --no-prompt >/dev/null 2>&1
kill $PID 2>/dev/null; wait $PID 2>/dev/null
python3 "$ROOT/scripts/gpu_attribution.py" "$OUT/traces/attribution.trace" "$LOG" | tee "$OUT/attribution.txt"
