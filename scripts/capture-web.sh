#!/bin/bash
# Complete web capture owns its heavy admission; do not nest another heavy wrapper.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/heavy.sh" 'web capture: prepare, serve, launch and collect' \
  node "$ROOT/scripts/capture_web.mjs" "$@"
