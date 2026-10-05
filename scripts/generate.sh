#!/bin/bash
# Builds the pinned XcodeGen (Tools/Package.swift) if needed, then generates WorldLab.xcodeproj.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
XCODEGEN="$ROOT/Tools/.build/release/xcodegen"
if [ ! -x "$XCODEGEN" ]; then
  echo "Building pinned XcodeGen (first run only)…"
  swift build -c release --package-path "$ROOT/Tools" --product xcodegen
fi
"$XCODEGEN" generate --spec "$ROOT/Apps/WorldLab/project.yml" --project "$ROOT/Apps/WorldLab"
