#!/bin/bash
set -euo pipefail
export HEAVY_AGENT="${HEAVY_AGENT:-A10}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/heavy.sh" 'scene-budget camera qualification' \
 python3 "$ROOT/scripts/capture_timeout.py" --seconds "${WEB_CAPTURE_TIMEOUT_SECONDS:-900}" \
 node "$ROOT/scripts/qualify_scene_budget.mjs" "$@"
