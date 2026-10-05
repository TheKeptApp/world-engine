#!/bin/bash
# 10-minute device walk test: launches WorldLab's walk loop with metrics logging, optionally samples
# GPU frame time with Metal System Trace at ~1, 5 and 9.5 minutes, then pulls the per-second CSV.
#   scripts/walk_test.sh [label] [extra app args...]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${1:-baseline}"; shift || true
OUT="$ROOT/docs/perf/$LABEL"
mkdir -p "$OUT"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
[ -n "$UDID" ] || { echo "Could not read the iPhone UDID"; exit 1; }
TRACES="${TRACE_DIR:-$OUT}"
xcrun devicectl device process launch --device "$CORE" --terminate-existing com.lincolnlabs.worldlab -- -metrics on "$@" >/dev/null 2>&1
START=$(date +%s)
sample() { # $1 = seconds after start, $2 = name
  local wait=$(( $1 - ($(date +%s) - START) )); [ $wait -gt 0 ] && sleep $wait
  rm -rf "$TRACES/$2.trace"
  xcrun xctrace record --device "$UDID" --template "Metal System Trace" --attach WorldLab --time-limit 8s \
    --output "$TRACES/$2.trace" >/dev/null 2>&1
  echo "== $2 ($(( $(date +%s) - START ))s)"; python3 "$ROOT/scripts/gpu_frames.py" "$TRACES/$2.trace" | tee "$OUT/$2-gpu.txt"
}
# GPU tracing forces the GPU into its minimum performance state while recording, which also
# changes heat. NO_TRACE=1 runs the walk without traces (clean heat and frame-rate data).
if [ "${NO_TRACE:-0}" != "1" ]; then
  sample 60 t01m
  sample 300 t05m
  sample 570 t09m30
fi
wait=$(( 615 - ($(date +%s) - START) )); [ $wait -gt 0 ] && sleep $wait
xcrun devicectl device copy from --device "$CORE" --domain-type appDataContainer --domain-identifier com.lincolnlabs.worldlab \
  --source Documents/metrics.csv --destination "$OUT/metrics.csv" >/dev/null 2>&1
echo "Saved $OUT/metrics.csv"
