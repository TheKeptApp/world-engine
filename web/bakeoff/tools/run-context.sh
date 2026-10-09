#!/bin/bash
# The caller owns scripts/heavy.sh; never nest it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"
bash web/bakeoff/tools/build-context-exporter.sh
scripts/export-package.sh
bash web/bakeoff/tools/prepare-context.sh
node --test web/bakeoff/context-ring.test.mjs web/bakeoff/scene-budget.test.mjs
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=600 node web/bakeoff/tools/capture-context.mjs web/bakeoff/evidence/context-ring/main-600
