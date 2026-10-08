#!/bin/bash
# Simulator build; invoke through scripts/heavy.sh. Never use an old app after a failed build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/generate.sh"
python3 "$ROOT/scripts/native_preflight.py" --stage build
xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$ROOT/.build/xcode" -quiet build
python3 "$ROOT/scripts/native_preflight.py" --stage capture
