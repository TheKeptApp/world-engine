#!/bin/bash
# Builds BuildingLab, launches it in a DEDICATED iOS Simulator with launch arguments, saves a screenshot.
#   scripts/building_shots.sh <output.png> [app launch args...]
#   e.g. scripts/building_shots.sh out.png -area sloans-lake -overview 39.7494,-105.0445,300,40,0,45 -frame16x9
# App args: -area NAME -profile ID -date ISO8601 -focus S,W,N,E -look LAT,LON,H,HEADING,PITCH,FOV
#           -overview LAT,LON,DIST,PITCH,YAW,FOV -frame16x9
# Env: SIM (default "P2 BuildingLab iPad Pro 13", created if missing; DEVICE_TYPE picks its model), SNAPSHOT_WAIT (seconds, default 15),
#      SKIP_BUILD=1 to reuse the last build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$1"; shift || true
case "$OUT" in /*) ;; *) OUT="$ROOT/$OUT" ;; esac
SIM="${SIM:-P2 BuildingLab iPad Pro 13}"
DEVICE_TYPE="${DEVICE_TYPE:-iPad Pro 13-inch (M5) (}"
DERIVED="$ROOT/.build/xcode-buildinglab"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/BuildingLab.app"
BUNDLE=com.lincolnlabs.buildinglab

if [ "${SKIP_BUILD:-0}" != "1" ]; then
  XCODEGEN="$ROOT/Tools/.build/release/xcodegen"
  if [ ! -x "$XCODEGEN" ]; then
    echo "Building pinned XcodeGen (first run only)..."
    swift build -c release --package-path "$ROOT/Tools" --product xcodegen
  fi
  "$XCODEGEN" generate --spec "$ROOT/Apps/BuildingLab/project.yml" --project "$ROOT/Apps/BuildingLab" >/dev/null
  LOG="$(mktemp)"
  xcodebuild -project "$ROOT/Apps/BuildingLab/BuildingLab.xcodeproj" -scheme BuildingLab \
    -destination "generic/platform=iOS Simulator" -derivedDataPath "$DERIVED" -quiet build >"$LOG" 2>&1 || {
    grep -E "error:" "$LOG" | sort -u | head -20; echo "BuildingLab build failed (log: $LOG)"; exit 1; }
fi
[ -f "$APP/Info.plist" ] || { echo "Build failed: $APP missing"; exit 1; }

udid_of() { xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'; }
UDID=$(udid_of || true)
if [ -z "$UDID" ]; then
  TYPE=$(xcrun simctl list devicetypes | grep -F "$DEVICE_TYPE" | head -1 | sed -E 's/.*\((com\.apple[^)]*)\).*/\1/')
  RUNTIME=$(xcrun simctl list runtimes available | grep -E "^iOS " | tail -1 | sed -E 's/.* - (com\.apple\.CoreSimulator\.SimRuntime\.[^ ]*)$/\1/')
  [ -n "$TYPE" ] && [ -n "$RUNTIME" ] || { echo "Cannot find device type ($TYPE) or runtime ($RUNTIME)"; exit 1; }
  echo "Creating simulator \"$SIM\" ($TYPE, $RUNTIME)"
  UDID=$(xcrun simctl create "$SIM" "$TYPE" "$RUNTIME")
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
# bootstatus can hang on a loaded machine; give it up to BOOT_WAIT seconds, then carry on.
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 &
BS=$!
for _ in $(seq 1 "${BOOT_WAIT:-120}"); do kill -0 "$BS" 2>/dev/null || break; sleep 1; done
kill "$BS" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
sleep "${SNAPSHOT_WAIT:-15}"
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1
# With -frame16x9, keep only the centred 16:9 view.
case " $* " in *" -frame16x9 "*)
  W=$(sips -g pixelWidth "$OUT" | awk '/pixelWidth/ {print $2}')
  sips --cropToHeightWidth $((W * 9 / 16)) "$W" "$OUT" >/dev/null ;;
esac
echo "Saved $OUT"
