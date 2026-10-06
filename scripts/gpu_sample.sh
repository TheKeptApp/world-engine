#!/bin/bash
# Launches WorldLab on the connected iPhone with the given app arguments, waits for it to
# settle, records 8 s of Metal System Trace and prints per-frame GPU time.
#   scripts/gpu_sample.sh LABEL [app args...]     e.g. scripts/gpu_sample.sh no-shadows -diag noShadows
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="$1"; shift
TRACES="${TRACE_DIR:-$ROOT/.build/traces}"; mkdir -p "$TRACES"
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
[ -n "$UDID" ] || { echo "Could not read the iPhone UDID"; exit 1; }
xcrun devicectl device process launch --device "$CORE" --terminate-existing com.lincolnlabs.worldlab -- "$@" >/dev/null 2>&1
sleep "${SETTLE:-12}"
rm -rf "$TRACES/$LABEL.trace"
# The GPU runs at its own clocks (template with performance state "Default"); Xcode's stock
# Metal System Trace pins it to the minimum clock. TEMPLATE overrides.
TEMPLATE="${TEMPLATE:-$("$ROOT/scripts/make_gpu_template.py")}"
xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 8s \
  --output "$TRACES/$LABEL.trace" >/dev/null 2>&1
echo "== $LABEL ($*)"
python3 "$ROOT/scripts/gpu_frames.py" "$TRACES/$LABEL.trace"
