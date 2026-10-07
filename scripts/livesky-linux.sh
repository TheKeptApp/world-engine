#!/usr/bin/env bash
# Build and test only the LiveSky target on Linux (cloud sessions) using the swift:6.2-noble Docker image.
# The rest of WorldEngine needs Apple frameworks, so LiveSky is copied into a throwaway package.
# Usage: scripts/livesky-linux.sh [build|test]   (default: test)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${LIVESKY_WORK:-${TMPDIR:-/tmp}/livesky-linux}"
if ! docker info >/dev/null 2>&1; then
  (dockerd >"${TMPDIR:-/tmp}/dockerd.log" 2>&1 &)
  for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
fi
docker image inspect swift:6.2-noble >/dev/null 2>&1 || docker pull -q swift:6.2-noble
mkdir -p "$WORK/Sources" "$WORK/Tests"
rm -rf "$WORK/Sources/LiveSky" "$WORK/Tests/LiveSkyTests"
cp -R "$ROOT/Sources/LiveSky" "$WORK/Sources/"
cp -R "$ROOT/Tests/LiveSkyTests" "$WORK/Tests/"
# The sky vector tests read the shared star catalogue by repo-relative path.
mkdir -p "$WORK/Sources/WorldEnvironment/Catalog"
cp "$ROOT"/Sources/WorldEnvironment/Catalog/stars-*.json "$WORK/Sources/WorldEnvironment/Catalog/"
cat >"$WORK/Package.swift" <<'PKG'
// swift-tools-version:6.2
import PackageDescription
let package = Package(
    name: "LiveSkyLinux",
    targets: [
        .target(name: "LiveSky"),
        .testTarget(name: "LiveSkyTests", dependencies: ["LiveSky"], resources: [.copy("Fixtures")]),
    ]
)
PKG
CMD="${1:-test}"
docker run --rm -v "$WORK":/pkg -w /pkg swift:6.2-noble swift "$CMD"
