#!/bin/bash
# Look-loop capture: renders every active view in Tools/lookloop/views.json with WorldLab in a
# dedicated, headless Simulator (no window, no device) and saves one PNG plus a console log per view.
#   Tools/lookloop/capture.sh <run-dir> [view-id ...]
# Env: SKIP_BUILD=1 reuses the last WorldLab Simulator build; SETTLE seconds after the world is built
#      (default 8); LOAD_TIMEOUT seconds to wait for the world (default 120); LOOKLOOP_SIM device name.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUN="$1"; shift || true
mkdir -p "$RUN"; RUN="$(cd "$RUN" && pwd)"   # simctl io needs absolute paths
ONLY=("$@")
VIEWS="$ROOT/Tools/lookloop/views.json"
SIM="${LOOKLOOP_SIM:-LookLoop iPhone 17 Pro}"
DERIVED="$ROOT/.build/xcode"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/WorldLab.app"
BUNDLE=com.lincolnlabs.worldlab
SETTLE="${SETTLE:-8}"
LOAD_TIMEOUT="${LOAD_TIMEOUT:-120}"
mkdir -p "$RUN/raw" "$RUN/logs"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  echo "build: WorldLab (Simulator)"
  "$ROOT/scripts/generate.sh" >/dev/null
  xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED" -quiet build 2>&1 | grep -v IDERunDestination || true
fi
[ -d "$APP" ] || { echo "capture: no WorldLab build at $APP"; exit 1; }

# A dedicated Simulator so captures never collide with other sessions' devices.
UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
if [ -z "$UDID" ]; then
  RT=$(xcrun simctl list runtimes available | grep -E '^iOS 26' | tail -1 | sed -E 's/.* - (com\.apple[^ ]+).*/\1/')
  UDID=$(xcrun simctl create "$SIM" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro "$RT")
  echo "capture: created Simulator $SIM ($UDID)"
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
# Fixed status bar and appearance: identical frames run to run.
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 >/dev/null 2>&1 || true
xcrun simctl ui "$UDID" appearance light >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP"

COMMON=$(python3 -c "import json;print(' '.join(json.load(open('$VIEWS'))['commonArgs']))")
python3 - "$VIEWS" "${ONLY[@]+"${ONLY[@]}"}" > "$RUN/views.tsv" <<'EOF'
import json, sys
views = json.load(open(sys.argv[1]))["views"]
only = set(sys.argv[2:])
for v in views:
    if v.get("active", True) is False or (only and v["id"] not in only):
        continue
    print(v["id"] + "\t" + " ".join(v["args"]))
EOF

while IFS=$'\t' read -r id args; do
  log="$RUN/logs/$id.log"
  : > "$log"
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  t0=$(python3 -c 'import time;print(time.time())')
  # NSUnbufferedIO (as Xcode sets it) makes print() reach the log at once, so STATS/RENDER lines arrive live.
  # shellcheck disable=SC2086
  SIMCTL_CHILD_NSUnbufferedIO=YES xcrun simctl launch --stdout="$log" --stderr="$log" "$UDID" "$BUNDLE" $COMMON $args >/dev/null
  ok=0
  for _ in $(seq 1 $((LOAD_TIMEOUT * 4))); do
    if grep -q '^STATS ' "$log" 2>/dev/null; then ok=1; break; fi
    if grep -q 'Failed to build world' "$log" 2>/dev/null; then break; fi
    sleep 0.25
  done
  t1=$(python3 -c 'import time;print(time.time())')
  if [ "$ok" = 1 ]; then
    sleep "$SETTLE"
    xcrun simctl io "$UDID" screenshot "$RUN/raw/$id.png" >/dev/null 2>&1
    printf '%s\tok\t%.1f\n' "$id" "$(python3 -c "print($t1-$t0)")" >> "$RUN/capture.tsv"
    echo "  $id  world in $(python3 -c "print(round($t1-$t0,1))") s"
  else
    printf '%s\tfailed\t-\n' "$id" >> "$RUN/capture.tsv"
    echo "  $id  FAILED (no STATS line within ${LOAD_TIMEOUT}s, see $log)"
  fi
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
done < "$RUN/views.tsv"
