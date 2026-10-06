#!/bin/bash
# Real phone frames for the look loop: one WorldLab launch on the connected iPhone steps through the
# active views of Tools/lookloop/views.json (or a given views file), saves each frame on the phone
# (Documents/views/<id>.png) and copies them back. Views in another area than the first are skipped
# (they need their own launch).
#   scripts/device_views.sh [out-dir] [views.json] [view-id ...]
# Env: SETTLE seconds per view (default 4), RENDERSCALE (default 2.5), AREA (another bundled area),
#      GPU=1: per-view GPU frame time from Metal's frame log (scripts/gpu_hud.py; the HUD overlay
#      may show in the frames, so use those frames for timing only).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/.build/device-views/$(date +%Y%m%d-%H%M%S)}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
VIEWS="${2:-$ROOT/Tools/lookloop/views.json}"; shift 2 2>/dev/null || shift $#
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/ connected / || / available /) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
[ -n "$CORE" ] || { echo "No connected iPhone"; exit 1; }
# The view list (active views, or the ids given), as base64 JSON for one launch argument.
LIST=$(python3 - "$VIEWS" "$@" <<'PY'
import base64, json, sys
doc = json.load(open(sys.argv[1]))
views = doc["views"] if isinstance(doc, dict) else doc
only = set(sys.argv[2:])
out = [{"id": v["id"], "args": v["args"]} for v in views
       if v.get("active", True) is not False and v.get("args") and (not only or v["id"] in only)]
print(base64.b64encode(json.dumps(out).encode()).decode())
PY
)
N=$(echo "$LIST" | base64 -d | python3 -c "import json,sys;print(len(json.load(sys.stdin)))")
LOG="$OUT/views.log"
echo "$N views → $OUT"
HUD_ENV=(); [ "${GPU:-0}" = 1 ] && HUD_ENV=(-e '{"MTL_HUD_ENABLED":"1","MTL_HUD_LOG_ENABLED":"1","OS_ACTIVITY_DT_MODE":"1"}')
xcrun devicectl device process launch --device "$CORE" --terminate-existing --console ${HUD_ENV[@]+"${HUD_ENV[@]}"} com.lincolnlabs.worldlab -- \
  -renderer realitykit -hud off -frame16x9 -rendertrace -renderscale "${RENDERSCALE:-2.5}" ${AREA:+-area "$AREA"} \
  -viewlist64 "$LIST" -viewsettle "${SETTLE:-4}" > "$LOG" 2>&1 &
PID=$!
for _ in $(seq 1 $((60 + N * 30))); do
  sleep 2
  grep -q "^VIEWS done\|^VIEWS failed\|Failed to build world" "$LOG" && break
  kill -0 $PID 2>/dev/null || break
done
grep -E "^CONDITIONS" "$LOG" | head -1
grep -E "^VIEWSHOT|^VIEWS" "$LOG"
kill $PID 2>/dev/null; wait $PID 2>/dev/null
TMP=$(mktemp -d)
xcrun devicectl device copy from --device "$CORE" --domain-type appDataContainer --domain-identifier com.lincolnlabs.worldlab \
  --source Documents/views --destination "$TMP" >/dev/null 2>&1
find "$TMP" -name '*.png' -exec cp {} "$OUT/" \;
rm -rf "$TMP"
echo "$(ls "$OUT"/*.png 2>/dev/null | wc -l | tr -d ' ') frames in $OUT"
[ "${GPU:-0}" = 1 ] && python3 "$ROOT/scripts/gpu_hud.py" "$LOG" | tee "$OUT/gpu.txt"
