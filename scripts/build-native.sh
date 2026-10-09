#!/bin/bash
# Simulator build; invoke through scripts/heavy.sh. Never use an old app after a failed build.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/generate.sh"
python3 "$ROOT/scripts/native_preflight.py" --stage build
xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$ROOT/.build/xcode" -quiet build
python3 "$ROOT/scripts/native_preflight.py" --stage capture

# Restore Xcode's unmodified shipping resource on every build, including variant→off.
cp "$ROOT/.build/xcode/Build/Products/Debug-iphonesimulator/WorldEngine_WorldEngine.bundle/default.metallib" "$ROOT/.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app/WorldEngine_WorldEngine.bundle/default.metallib"
# Only explicit experimental builds replace the compiled resource, never shipping source.
case "${FOLIAGE_EXP1_BUILD:-off}" in
 off) ;;
 remove|layered)
  MODE=1; [ "$FOLIAGE_EXP1_BUILD" != layered ] || MODE=2
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  python3 "$ROOT/scripts/foliage_variant.py" "$TMP/WorldShaders.metal"
  mkdir -p "$ROOT/.build/foliage-exp1"
  cp "$TMP/WorldShaders.metal" "$ROOT/.build/foliage-exp1/current.metal"
  xcrun -sdk iphonesimulator metal -target air64-apple-ios26.0-simulator -DFOLIAGE_EXP1_MODE="$MODE" -c "$TMP/WorldShaders.metal" -o "$TMP/WorldShaders.air"
  xcrun -sdk iphonesimulator metallib "$TMP/WorldShaders.air" -o "$ROOT/.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app/WorldEngine_WorldEngine.bundle/default.metallib"
  ;;
 *) echo 'Invalid FOLIAGE_EXP1_BUILD' >&2; exit 1 ;;
esac
