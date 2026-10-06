#!/bin/bash
# Phase 5A gate videos in the Simulator (60 s each): Luna on the street loop with the follow camera,
# and the route flythrough without a character, both at golden hour in Demo clear weather.
#   scripts/gate_videos.sh [out-dir]      (default docs/videos/m3; needs a current Simulator build)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/videos/m3}"; mkdir -p "$OUT"
SIM="${SIM:-WorldEngine P0}"   # this session's own Simulator (other sessions use theirs)
UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
APP="$ROOT/.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
record() { # $1 = name, rest = app args
  local name="$1"; shift
  xcrun simctl terminate "$UDID" com.lincolnlabs.worldlab 2>/dev/null || true
  xcrun simctl launch "$UDID" com.lincolnlabs.worldlab -renderer realitykit -hud off "$@" >/dev/null
  sleep 32   # world build + settle
  xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$OUT/$name-full.mp4" >/dev/null 2>&1 &
  local rec=$!
  sleep 60
  kill -INT $rec; wait $rec 2>/dev/null || true
  # Half size, 1.6 Mbps H.264 for the repo (~12 MB a minute).
  swift "$ROOT/scripts/encode_video.swift" "$OUT/$name-full.mp4" "$OUT/$name.mp4" 1600 >/dev/null \
    && rm "$OUT/$name-full.mp4" || mv "$OUT/$name-full.mp4" "$OUT/$name.mp4"
  echo "  $name: $(du -h "$OUT/$name.mp4" | cut -f1)"
}
ONLY="${ONLY:-street-loop route-flythrough}"
[[ " $ONLY " == *" street-loop "* ]] && record street-loop -character luna -mode follow -date 2026-10-15T23:30:00Z
[[ " $ONLY " == *" route-flythrough "* ]] && record route-flythrough -mode route -date 2026-10-15T23:30:00Z
xcrun simctl terminate "$UDID" com.lincolnlabs.worldlab 2>/dev/null || true
