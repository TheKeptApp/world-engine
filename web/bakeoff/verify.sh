#!/bin/bash
# One heavy-lock session covers both pages, existing-viewer baselines and scoring.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"
# Resolve shared ignored exports/assets from the primary checkout, never copy them.
export WORLDENGINE_ASSETS="${WORLDENGINE_ASSETS:-$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")}"
python3 -c 'import shutil; assert shutil.disk_usage(".").free >= 8_000_000_000, "STOP: less than 8 GB free"'
mkdir -p "$HERE/evidence"
for source in "$HERE"/*.js "$HERE"/*.mjs; do node --check "$source"; done
node "$HERE/policy.test.mjs"
node "$HERE/atmosphere.test.mjs"
node "$HERE/sky-colour.test.mjs"
SCENES=sloans,lakeview node "$HERE/capture.mjs"
python3 "$HERE/score.py"
git diff --check
if [ "${TIERS:-}" = "hero,standard,floor" ]; then python3 "$HERE/phone-report.py"; fi
