#!/bin/bash
# One command, including shared heavy/load admission. Do not wrap this again.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/heavy.sh" 'native capture: prepare, build, install and collect' \
  python3 "$ROOT/scripts/capture_native.py" "$@"
