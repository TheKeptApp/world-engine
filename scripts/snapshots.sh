#!/bin/bash
# Builds WorldLab, launches it in the iOS Simulator and saves a screenshot.
#   scripts/snapshots.sh [name] [simulator]
# Camera presets (-camera iso|top|street|lake-edge) arrive with the rendering milestone.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-worldlab-shell}"
SIM="${2:-iPhone 17 Pro}"
OUT="$ROOT/docs/screenshots/m1/$NAME.png"
DERIVED="$ROOT/.build/xcode"

"$ROOT/scripts/generate.sh" >/dev/null
xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab \
  -destination "generic/platform=iOS Simulator" -derivedDataPath "$DERIVED" \
  -quiet build
APP="$DERIVED/Build/Products/Debug-iphonesimulator/WorldLab.app"

# Several simulators can share a name; use the first matching one's UDID.
UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "No simulator named $SIM"; exit 1; }
SIM="$UDID"

xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl install "$SIM" "$APP"
xcrun simctl terminate "$SIM" com.lincolnlabs.worldlab 2>/dev/null || true
xcrun simctl launch "$SIM" com.lincolnlabs.worldlab >/dev/null
sleep "${SNAPSHOT_WAIT:-4}"
xcrun simctl io "$SIM" screenshot "$OUT" >/dev/null
echo "Saved $OUT"
