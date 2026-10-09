#!/bin/bash
# Caller holds the heavy lock; do not nest. Choose a fresh output root for every run.
set -euo pipefail
cd "$(dirname "$0")/../../.."
OUT="${1:-web/bakeoff/evidence/context-buildings}"
node --test web/bakeoff/context-ring.test.mjs web/bakeoff/scene-budget.test.mjs
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=600 node web/bakeoff/tools/capture-context.mjs "$OUT/main-600"
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=40 node web/bakeoff/tools/capture-context.mjs "$OUT/holdouts-40-r2"
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=150 node web/bakeoff/tools/capture-context.mjs "$OUT/holdouts-150"
CONTEXT_BLOCKS=west-highland node web/bakeoff/tools/capture-context.mjs "$OUT/west-highland"
node web/bakeoff/tools/capture-context-missing.mjs "$OUT/greenville"
