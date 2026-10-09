#!/bin/bash
# Each headless browser/server run owns and releases a separate heavy admission.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
export HEAVY_AGENT="A2 crown scene-ready regression"
for scene in sloans lakeview; do
  for mode in off standard floor; do
    bash scripts/heavy.sh "crown scene-ready $scene/$mode" bash -c '
      set -e
      test $(df -k / | tail -1 | awk "{print \$4}") -ge 8388608
      node web/bakeoff/crown-runtime.test.mjs "$1" "$2" after
    ' _ "$scene" "$mode"
  done
done
