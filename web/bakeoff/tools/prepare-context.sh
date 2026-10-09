#!/bin/bash
# Under heavy.sh only. No downloads; existing licensed context extracts only.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"
for AREA in sloans-lake lakeview-sheil-park wilmette-vattmann-park west-highland greenville-downtown; do
 .build/release/export-context "Data/areas/$AREA" "web/bakeoff/generated/context/$AREA.json"
done
