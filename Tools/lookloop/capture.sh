#!/bin/bash
# Look-loop capture: renders views with WorldLab in one dedicated, headless Simulator (no window,
# no device) and saves one PNG plus a console log per view.
#   Tools/lookloop/capture.sh <run-dir> [view-id ...]
# Uses <run-dir>/views.tsv when plan.py wrote it; otherwise every active view (or the ids given).
# Batched by default: one launch per area with WorldLab's -viewlist (batch.py); LOOKLOOP_BATCH=0 for one launch per view.
# Env: SKIP_BUILD=1 skips the (incremental) WorldLab build; SETTLE seconds after the world is built
#      (default 3; frames at 2 s and 8 s differ by <0.1/255); LOAD_TIMEOUT seconds to wait for the world (default 120); LOOKLOOP_SIM device name.
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
SETTLE="${SETTLE:-3}"
LOAD_TIMEOUT="${LOAD_TIMEOUT:-120}"
mkdir -p "$RUN/raw" "$RUN/logs"

if [ ! -f "$RUN/views.tsv" ]; then
  python3 - "$VIEWS" "${ONLY[@]+"${ONLY[@]}"}" > "$RUN/views.tsv" <<'PY'
import json, sys
views = json.load(open(sys.argv[1]))["views"]
only = set(sys.argv[2:])
for v in views:
    if v.get("active", True) is False or (only and v["id"] not in only):
        continue
    print(v["id"] + "\t" + " ".join(v["args"]))
PY
fi
[ -s "$RUN/views.tsv" ] || { echo "capture: nothing to capture"; exit 0; }

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  # Incremental: about 3 s when nothing changed.
  echo "build: WorldLab (Simulator)"
  "$ROOT/scripts/generate.sh" >/dev/null
  xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "$DERIVED" -quiet build 2>&1 | grep -v IDERunDestination || true
fi
[ -d "$APP" ] || { echo "capture: no WorldLab build at $APP"; exit 1; }

# simctl calls can hang (not fail) on a degraded Simulator: run them with a time limit (exit 124 on timeout).
limit() { python3 -c 'import subprocess, sys
try: sys.exit(subprocess.run(sys.argv[2:], timeout=float(sys.argv[1])).returncode)
except subprocess.TimeoutExpired: sys.exit(124)' "$@"; }

# One dedicated Simulator, kept booted between views and runs (never a second one).
UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/' || true)
if [ -z "$UDID" ]; then
  RT=$(xcrun simctl list runtimes available | grep -E '^iOS 26' | tail -1 | sed -E 's/.* - (com\.apple[^ ]+).*/\1/')
  UDID=$(xcrun simctl create "$SIM" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro "$RT")
  echo "capture: created Simulator $SIM ($UDID)"
fi
if ! xcrun simctl list devices | grep -F "($UDID) (Booted)" >/dev/null; then
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
fi
# Fixed status bar and appearance: identical frames run to run.
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 >/dev/null 2>&1 || true
xcrun simctl ui "$UDID" appearance light >/dev/null 2>&1 || true
# Install only when the build changed (stamp: the app executable's size and modification time).
STAMP="$ROOT/.build/lookloop/installed-$UDID"
NOW=$(stat -f '%z %m' "$APP/WorldLab")
if [ "$(cat "$STAMP" 2>/dev/null)" != "$NOW" ] || ! xcrun simctl get_app_container "$UDID" "$BUNDLE" >/dev/null 2>&1; then
  xcrun simctl install "$UDID" "$APP"
  mkdir -p "$(dirname "$STAMP")"; echo "$NOW" > "$STAMP"
  # SpringBoard can refuse launches for minutes while it registers a fresh install, and a degraded
  # Simulator can hang them: probe with a time limit; if it never launches, reboot this one Simulator once.
  probe() {
    for _ in $(seq 1 18); do
      if limit 20 xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" >/dev/null 2>&1; then
        limit 20 xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true; return 0; fi
      sleep 5
    done
    return 1
  }
  echo "install: waiting until WorldLab is launchable"
  if ! probe; then
    echo "capture: WorldLab not launchable for 3 min; rebooting $SIM once"
    limit 120 xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
    xcrun simctl boot "$UDID" 2>/dev/null || true
    limit 300 xcrun simctl bootstatus "$UDID" -b >/dev/null
    xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 >/dev/null 2>&1 || true
    xcrun simctl install "$UDID" "$APP"
    probe || { echo "capture: WorldLab still not launchable after a reboot; stopping (see the Simulator)"; exit 2; }
  fi
fi

COMMON=$(python3 -c "import json;print(' '.join(json.load(open('$VIEWS'))['commonArgs']))")

# Batched: one launch per area through WorldLab's -viewlist (batch.py). Falls back to one launch per
# view when this build has no view-list hook (exit 4) or LOOKLOOP_BATCH=0.
if [ "${LOOKLOOP_BATCH:-1}" != 0 ]; then
  set +e
  SETTLE="$SETTLE" LOAD_TIMEOUT="$LOAD_TIMEOUT" python3 "$ROOT/Tools/lookloop/batch.py" "$RUN" "$UDID" "$BUNDLE" \
    "$(python3 -c "import json;print(json.dumps(json.load(open('$VIEWS'))['commonArgs']))")"
  rc=$?
  set -e
  if [ "$rc" = 0 ]; then
    limit 20 xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
    exit 0
  fi
  [ "$rc" = 4 ] && echo "capture: this WorldLab has no view-list hook; one launch per view" || { echo "capture: batch capture failed ($rc)"; exit "$rc"; }
  rm -f "$RUN/capture.tsv"
fi
now() { python3 -c 'import time;print(time.time())'; }
while IFS=$'\t' read -r id args; do
  log="$RUN/logs/$id.log"
  # Never pre-create the log: a file this session creates carries com.apple.provenance, and the
  # Simulator's launchd then refuses the whole launch ("Operation not permitted"). simctl creates it.
  rm -f "$log"
  t0=$(now)
  # NSUnbufferedIO (as Xcode sets it) makes print() reach the log at once, so STATS/RENDER lines arrive live.
  # Right after an install SpringBoard can refuse the launch while it registers the app: retry, then
  # record the view as failed rather than aborting the run.
  launched=0
  for attempt in 1 2 3 4 5 6; do
    # shellcheck disable=SC2086
    if SIMCTL_CHILD_NSUnbufferedIO=YES limit 60 xcrun simctl launch --terminate-running-process --stdout="$log" --stderr="$log" \
      "$UDID" "$BUNDLE" $COMMON $args >/dev/null 2>"$RUN/logs/$id.launch-error"; then launched=1; break; fi
    sleep $((attempt * 5))
  done
  if [ "$launched" != 1 ]; then
    printf '%s\tfailed\t-\n' "$id" >> "$RUN/capture.tsv"
    echo "  $id  FAILED (launch refused 6 times over ~2 min, see $RUN/logs/$id.launch-error)"
    continue
  fi
  ok=0
  for _ in $(seq 1 $((LOAD_TIMEOUT * 10))); do
    if grep -q '^STATS ' "$log" 2>/dev/null; then ok=1; break; fi
    if grep -q 'Failed to build world' "$log" 2>/dev/null; then break; fi
    sleep 0.1
  done
  t1=$(now)
  if [ "$ok" = 1 ]; then
    sleep "$SETTLE"
    limit 30 xcrun simctl io "$UDID" screenshot "$RUN/raw/$id.png" >/dev/null 2>&1 || true
    printf '%s\tok\t%.1f\n' "$id" "$(python3 -c "print($t1-$t0)")" >> "$RUN/capture.tsv"
    echo "  $id  world in $(python3 -c "print(round($t1-$t0,1))") s"
  else
    printf '%s\tfailed\t-\n' "$id" >> "$RUN/capture.tsv"
    echo "  $id  FAILED (no STATS line within ${LOAD_TIMEOUT}s, see $log)"
  fi
done < "$RUN/views.tsv"
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
