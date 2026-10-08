#!/bin/bash
# Run under scripts/heavy.sh. Reuses the repo exporter; output stays in this lane.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="${WORLDENGINE_ASSETS:-$(cd "$HERE/../.." && pwd)}"
"$REPO/.build/debug/worldbake" export "$REPO/Data/areas/lakeview-sheil-park" "$HERE/generated/lakeview-sheil-park" --date 2026-07-15T20:00:00Z --season 1 --focus 41.9445,-87.6660,41.9465,-87.6630 --margin 100 --version a2-existing-exporter
