#!/bin/bash
# Builds WorldLab, launches it in the iOS Simulator with launch arguments, and saves a screenshot.
#   scripts/snapshots.sh <output.png> [app launch args...]
#   e.g. scripts/snapshots.sh docs/screenshots/m1/milestone1/street-mid.png -preset street-mid
# Env: SIM (simulator name, default "iPhone 17 Pro"), SNAPSHOT_WAIT (seconds, default 12),
#      SKIP_BUILD=1 to reuse the last build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$1"; shift || true
case "$OUT" in /*) ;; *) OUT="$ROOT/$OUT" ;; esac
SIM="${SIM:-iPhone 17 Pro}"
DERIVED="$ROOT/.build/xcode"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/WorldLab.app"

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  "$ROOT/scripts/generate.sh" >/dev/null
  xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab \
    -destination "generic/platform=iOS Simulator" -derivedDataPath "$DERIVED" -quiet build 2>&1 | grep -v IDERunDestination || true
fi

# Several simulators can share a name; use the first matching one's UDID.
UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "No simulator named $SIM"; exit 1; }

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" com.lincolnlabs.worldlab 2>/dev/null || true
xcrun simctl launch "$UDID" com.lincolnlabs.worldlab "$@" >/dev/null
sleep "${SNAPSHOT_WAIT:-12}"
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1
echo "Saved $OUT"
