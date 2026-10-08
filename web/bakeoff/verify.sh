#!/bin/bash
# One heavy-lock session covers both pages, existing-viewer baselines and scoring.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT"
mkdir -p "$HERE/evidence"
for source in "$HERE"/*.js "$HERE"/*.mjs; do node --check "$source"; done
node "$HERE/policy.test.mjs"
node "$HERE/sky-colour.test.mjs"
SCENES=sloans,lakeview node "$HERE/capture.mjs"
python3 "$HERE/score.py"
git diff --check
