#!/bin/bash
# Renders postcards offscreen on the Mac (no Simulator, no phone) to check the export path and
# compare quality modes: compiles the engine's Metal shaders for macOS into the debug build's
# resource bundle (`swift build` copies the shader source uncompiled), then runs the postcard
# tests (WorldEngineTests and the WorldGen postcard suites). Images go to OUT (default
# .build/postcard-check); timing lines are printed. Mac timings show relative costs, not iPhone times.
# A heavy job: on the shared Mac run it through scripts/heavy.sh.
#
#   scripts/postcard_mac_check.sh [OUT]
#   POSTCARD_FILTER=regex  narrows the tests (default: every postcard suite)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/.build/postcard-check}"
FILTER="${POSTCARD_FILTER:-WorldEngineTests|PostcardFrameTests|PostcardReframeTests|PostcardGradeTests}"
cd "$ROOT"
nice -n 10 swift build --build-tests
BIN="$(swift build --show-bin-path)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SHADER=Sources/WorldEngine/Shaders/WorldShaders.metal
MODE=0
case "${FOLIAGE_EXP1_BUILD:-off}" in
 off) ;;
 remove|layered) MODE=1; [ "$FOLIAGE_EXP1_BUILD" != layered ] || MODE=2
 python3 scripts/foliage_variant.py "$TMP/WorldShaders.metal"; SHADER="$TMP/WorldShaders.metal" ;;
 *) echo 'Invalid FOLIAGE_EXP1_BUILD' >&2; exit 1 ;;
esac
xcrun -sdk macosx metal -DFOLIAGE_EXP1_MODE="$MODE" -c "$SHADER" -o "$TMP/WorldShaders.air"
xcrun -sdk macosx metallib "$TMP/WorldShaders.air" -o "$BIN/WorldEngine_WorldEngine.bundle/default.metallib"
mkdir -p "$OUT"
POSTCARD_TEST_OUT="$OUT" nice -n 10 swift test --skip-build --filter "$FILTER"
echo "Postcards in $OUT"
