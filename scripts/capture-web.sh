#!/bin/bash
# Complete web capture owns its heavy admission; do not nest another heavy wrapper.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/heavy.sh" 'web capture: prepare, serve, launch and collect' \
  python3 "$ROOT/scripts/capture_timeout.py" --seconds "${WEB_CAPTURE_TIMEOUT_SECONDS:-900}" \
  node "$ROOT/scripts/capture_web.mjs" "$@"
