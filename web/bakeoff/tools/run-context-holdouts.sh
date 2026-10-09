#!/bin/bash
# Caller owns heavy lock. No tuning between locations/altitudes.
set -euo pipefail
cd "$(dirname "$0")/../../.."
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=40 node web/bakeoff/tools/capture-context.mjs web/bakeoff/evidence/context-ring/holdouts-40
CONTEXT_BLOCKS=sloans-ladder,lakeview-ladder,wilmette CONTEXT_ALTITUDE=150 node web/bakeoff/tools/capture-context.mjs web/bakeoff/evidence/context-ring/holdouts-150
CONTEXT_BLOCKS=west-highland node web/bakeoff/tools/capture-context.mjs web/bakeoff/evidence/context-ring/west-highland
node web/bakeoff/tools/capture-context-missing.mjs
