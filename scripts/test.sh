#!/bin/bash
# Runs all package unit tests on the Mac. Builds the tests first and compiles the Mac shader library
# into the WorldEngine test bundle, so GPU/offscreen tests (view draw budgets, postcards) really run:
# a missing prerequisite (shader library, area data, fixtures) fails its test, it never skips silently.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift build --build-tests --package-path "$ROOT"
BIN="$(swift build --package-path "$ROOT" --show-bin-path)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
xcrun -sdk macosx metal -c Sources/WorldEngine/Shaders/WorldShaders.metal -o "$TMP/WorldShaders.air"
xcrun -sdk macosx metallib "$TMP/WorldShaders.air" -o "$BIN/WorldEngine_WorldEngine.bundle/default.metallib"
swift test --package-path "$ROOT" --skip-build "$@"
