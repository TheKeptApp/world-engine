#!/bin/bash
# Clean device performance session (phone unplugged, cool, Low Power Mode off): 10-minute runs on the
# street (walking loop) and the aerial view (v2-06), clear and rain, with rests between. Each run logs
# per-frame CSVs (Documents, pulled after) and Metal's per-frame GPU time (console, scripts/gpu_hud.py).
#   scripts/perf_session.sh [out-dir]     Env: REST seconds between runs (default 240), SECONDS_RUN (600)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-clean}"; mkdir -p "$OUT/console" "$OUT/runs"; OUT="$(cd "$OUT" && pwd)"
REST="${REST:-240}"; RUN="${SECONDS_RUN:-600}"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -n "$CORE" ] || { echo "No connected iPhone"; exit 1; }
HUD='{"MTL_HUD_ENABLED":"1","MTL_HUD_LOG_ENABLED":"1","OS_ACTIVITY_DT_MODE":"1"}'
run() { # $1 = name, rest = app args
  local name="$1"; shift; local log="$OUT/console/$name.log"
  echo "== $name from $(date +%H:%M:%S)"
  xcrun devicectl device process launch --device "$CORE" --terminate-existing --console -e "$HUD" com.lincolnlabs.worldlab -- \
    -renderer realitykit -rendertrace -metrics on -testseconds "$RUN" -hud off "$@" > "$log" 2>&1 &
  local pid=$!
  for _ in $(seq 1 60); do sleep 1; grep -q "^CONDITIONS" "$log" && break; done
  local cond; cond=$(grep -m1 "^CONDITIONS" "$log"); echo "   $cond"
  if [[ "$cond" != *"lowPowerMode=false battery=unplugged"* ]]; then kill $pid; echo "STOPPED: not unplugged with Low Power Mode off"; exit 2; fi
  sleep $((RUN + 45)); kill $pid 2>/dev/null; wait $pid 2>/dev/null
  grep "^RENDER" "$log" | awk '{print $NF}' | sort | uniq -c | tr '\n' ' '; echo
  python3 "$ROOT/scripts/gpu_hud.py" "$log" > "$OUT/console/$name-gpu.txt" 2>&1; tail -3 "$OUT/console/$name-gpu.txt"
}
rest() { xcrun devicectl device process launch --device "$CORE" --terminate-existing com.lincolnlabs.worldlab >/dev/null 2>&1; echo "== rest $REST s"; sleep "$REST"; }
run street-clear -weather clear; rest
run street-rain -weather rain; rest
run aerial-clear -preset v2-06 -weather clear; rest
run aerial-rain -preset v2-06 -weather rain
TMP=$(mktemp -d)
xcrun devicectl device copy from --device "$CORE" --domain-type appDataContainer --domain-identifier com.lincolnlabs.worldlab \
  --source Documents --destination "$TMP" >/dev/null 2>&1
find "$TMP" -type f \( -name '*-frames.csv' -o -name '*-seconds.csv' -o -name '*-summary.json' \) -newer "$OUT/console/street-clear.log" -exec cp {} "$OUT/runs/" \;
rm -rf "$TMP"; ls "$OUT/runs"
