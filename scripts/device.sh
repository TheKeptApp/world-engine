#!/bin/bash
# Builds WorldLab (Release) for the connected iPhone, installs it, and optionally runs the
# timed walk test and pulls the metrics CSV back.
#   scripts/device.sh build            # build + install
#   scripts/device.sh walk [seconds]   # launch the walk loop with metrics logging, wait, pull CSV
# The signing team ID is read from .local/team_id (git-ignored), never from the repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEAM="$(cat "$ROOT/.local/team_id" 2>/dev/null || true)"
[ -n "$TEAM" ] || { echo "Put your Apple team ID in .local/team_id"; exit 1; }
DERIVED="$ROOT/.build/xcode-device"
APP="$DERIVED/Build/Products/Release-iphoneos/WorldLab.app"
DEVICE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -n "$DEVICE" ] || { echo "No connected iPhone found"; exit 1; }
OUT="${OUT:-$ROOT/docs/perf}"

case "${1:-build}" in
build)
  "$ROOT/scripts/generate.sh" >/dev/null
  xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab -configuration Release \
    -destination "generic/platform=iOS" -derivedDataPath "$DERIVED" -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic -quiet build
  xcrun devicectl device install app --device "$DEVICE" "$APP" | tail -2
  ;;
walk)
  SECONDS_TO_RUN="${2:-630}"
  xcrun devicectl device process launch --device "$DEVICE" --terminate-existing com.lincolnlabs.worldlab -- -metrics on | tail -1
  echo "Walking for $SECONDS_TO_RUN s…"
  sleep "$SECONDS_TO_RUN"
  mkdir -p "$OUT"
  STAMP=$(date +%Y%m%d-%H%M)
  xcrun devicectl device copy from --device "$DEVICE" --domain-type appDataContainer \
    --domain-identifier com.lincolnlabs.worldlab --source Documents/metrics.csv \
    --destination "$OUT/walk-$STAMP.csv" | tail -1
  echo "Saved $OUT/walk-$STAMP.csv"
  ;;
esac
