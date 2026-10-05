#!/bin/bash
# Runs all package unit tests (pure Swift modules run on the Mac).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
swift test --package-path "$ROOT" "$@"
