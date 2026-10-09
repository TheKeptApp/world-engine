#!/bin/bash
# Under heavy.sh only. No downloads; existing licensed context extracts only.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"
python3 web/bakeoff/tools/prepare-held-context.py west-highland greenville-downtown
for AREA in sloans-lake lakeview-sheil-park wilmette-vattmann-park west-highland greenville-downtown; do
 SOURCE="Data/areas/$AREA"
 if [ -f "Generated/context-held/$AREA/manifest.json" ]; then SOURCE="Generated/context-held/$AREA"; fi
 .build/release/export-context "$SOURCE" "web/bakeoff/generated/context/$AREA.json"
done
