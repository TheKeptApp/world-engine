#!/bin/bash
# Builds the three.js renderer into web/dist (git-ignored). Installs the pinned npm packages
# on first use (web/package-lock.json).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/web"
command -v node >/dev/null || { echo "build-web: Node.js not found; skipping the web renderer"; exit 0; }
[ -d node_modules/three ] || npm ci --no-audit --no-fund
node build.mjs
