#!/bin/bash
# Web renderer check (decision 4): rebuilds the shared package and the three.js bundle, serves them,
# loads the page in headless Chrome (WebGL2 through SwiftShader) and verifies that the first frame
# rendered from the latest package with the package's time, sky and season.
#   scripts/web_check.sh            exit 0 = pass
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || { echo "web_check: Google Chrome not found; skipped"; exit 0; }
"$ROOT/scripts/export-package.sh" >/dev/null
"$ROOT/scripts/build-web.sh" >/dev/null
PORT=${PORT:-8790}
PORT=$PORT node "$ROOT/web/serve.mjs" >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 1
PROFILE=$(mktemp -d)
DOM=$("$CHROME" --headless=new --user-data-dir="$PROFILE" --no-first-run --use-angle=swiftshader --enable-unsafe-swiftshader \
  --window-size=480,360 --virtual-time-budget=60000 --run-all-compositor-stages-before-draw \
  --dump-dom "http://127.0.0.1:$PORT/index.html?backend=webgl2&hud=1&post=0&check=1" 2>/dev/null || true)
rm -rf "$PROFILE"
BODY=$(printf '%s' "$DOM" | grep -o '<body[^>]*>' | head -1)
echo "web_check: $BODY"
python3 - "$ROOT" "$BODY" <<'PY'
import json, re, sys
root, body = sys.argv[1], sys.argv[2]
attrs = dict(re.findall(r'data-([a-z-]+)="([^"]*)"', body))
area = json.load(open(f"{root}/Apps/WorldLab/Resources/demo.json"))["area"]
pkg = f"{root}/Generated/package/{area}"
world = json.load(open(f"{pkg}/world.json"))
env = json.load(open(f"{pkg}/environment.json"))
state = env["states"][env["defaultState"]]
want = {
    "ready": "1",
    "state": env["defaultState"],
    "time": state["date"],
    "season": str(state["season"]),
    "sky": state["sky"],
    "generator": world["generator"]["version"],
    "sun-elevation": f'{state["light"]["sunElevation"]:.3f}',
}
bad = [f"{k}: page {attrs.get(k)!r}, package {v!r}" for k, v in want.items() if attrs.get(k) != v]
if "error" in attrs: bad.insert(0, "page error: " + attrs["error"])
if bad:
    print("web_check FAILED\n  " + "\n  ".join(bad)); sys.exit(1)
print(f"web_check passed: {attrs['backend']} rendered {attrs.get('triangles')} triangles of package {attrs['generator']} at {attrs['state']} {attrs['time']} ({attrs['zone']}), sun {attrs['sun-elevation']}°, season {attrs['season']}, sky {attrs['sky']}")
PY
