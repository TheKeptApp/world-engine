#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/heavy.sh" 'A10 nine-frame native foliage capture batch' python3 "$ROOT/scripts/capture_foliage_exp1.py" "$@"
