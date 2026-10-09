#!/bin/bash
# Coordinator owns no heavy lock; each build/export/capture step admits itself.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/world_scoreboard.py" "$@"
