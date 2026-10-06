#!/bin/bash
# Look-loop capture in ONE WorldLab launch (WorldLab's -viewlist), then P3's analysis. For a busy Mac,
# where the loop's own capture (one Simulator launch per view) stalls on every launch. Frames are
# WorldLab's in-app captures of the 16:9 view (no letterbox, no OSM credit overlay), which
# Tools/lookloop/analyze.py takes as they are. Grading and publishing stay P3's tools:
#   scripts/lookloop_viewlist.sh                 → prints the run dir; then grade and
#   Tools/lookloop/lookloop.sh finish <run-dir>
# Env: SIM (default "WorldEngine P0", this session's Simulator), SKIP_BUILD=1, SETTLE (default 5),
#      DEVICE=1 to capture on the connected iPhone instead (scripts/device_views.sh).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/Tools/lookloop"
SIM="${SIM:-WorldEngine P0}"
stamp=$(date +%Y%m%d-%H%M%S)
run="$ROOT/.build/lookloop/runs/$stamp"
mkdir -p "$run/raw" "$run/logs"
python3 - "$run" "$stamp" "$(git -C "$ROOT" rev-parse --short HEAD)" "$(git -C "$ROOT" branch --show-current)" \
  "$(git -C "$ROOT" status --porcelain -- Sources Apps Data Package.swift | wc -l | tr -d ' ')" \
  "$(git -C "$ROOT" log -1 --format=%h -- Sources Apps Data Package.swift)" "${DEVICE:-0}" <<'EOF'
import json, sys, time
run, stamp, commit, branch, dirty, engine, device = sys.argv[1:8]
json.dump({"stamp": stamp, "started": time.strftime("%Y-%m-%d %H:%M"), "t0": time.time(), "commit": commit,
           "engineCommit": engine, "branch": branch, "dirtyEngineFiles": int(dirty), "kind": "routine",
           "capture": "iPhone 14 Pro (device frames, -viewlist)" if device == "1" else "Simulator, one -viewlist launch"},
          open(f"{run}/run.json", "w"), indent=1)
EOF
echo "look loop $stamp ($(git -C "$ROOT" rev-parse --short HEAD) on $(git -C "$ROOT" branch --show-current))"
LIST=$(python3 - "$TOOLS/views.json" <<'PY'
import base64, json, sys
doc = json.load(open(sys.argv[1]))
common = doc.get("commonArgs", [])
out = [{"id": v["id"], "args": v["args"]} for v in doc["views"] if v.get("active", True) is not False and v.get("args")]
print(base64.b64encode(json.dumps(out).encode()).decode())
PY
)
COMMON=$(python3 -c "import json;print(' '.join(json.load(open('$TOOLS/views.json'))['commonArgs']))")
if [ "${DEVICE:-0}" = 1 ]; then
  "$ROOT/scripts/device_views.sh" "$run/raw" "$TOOLS/views.json" | tail -3
  cp "$run/raw/views.log" "$run/logs/all.log" 2>/dev/null
else
  APP="$ROOT/.build/xcode/Build/Products/Debug-iphonesimulator/WorldLab.app"
  if [ "${SKIP_BUILD:-0}" != 1 ]; then
    "$ROOT/scripts/generate.sh" >/dev/null
    xcodebuild -project "$ROOT/Apps/WorldLab/WorldLab.xcodeproj" -scheme WorldLab -destination "generic/platform=iOS Simulator" \
      -derivedDataPath "$ROOT/.build/xcode" -quiet build 2>&1 | grep -E "error:" | head -5
  fi
  UDID=$(xcrun simctl list devices available | grep -F "    $SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl terminate "$UDID" com.lincolnlabs.worldlab >/dev/null 2>&1 || true
  DATA=$(xcrun simctl get_app_container "$UDID" com.lincolnlabs.worldlab data)
  rm -rf "$DATA/Documents/views"
  LOG="$run/logs/all.log"
  # shellcheck disable=SC2086
  SIMCTL_CHILD_NSUnbufferedIO=YES xcrun simctl launch --stdout="$LOG" --stderr="$LOG" "$UDID" com.lincolnlabs.worldlab \
    $COMMON -viewlist64 "$LIST" -viewsettle "${SETTLE:-5}" >/dev/null
  for _ in $(seq 1 600); do sleep 2; grep -q "^VIEWS done\|^VIEWS failed\|Failed to build world" "$LOG" 2>/dev/null && break; done
  grep -E "^VIEWSHOT|^VIEWS" "$LOG" | cut -c1-150
  cp "$DATA"/Documents/views/*.png "$run/raw/" 2>/dev/null
  xcrun simctl terminate "$UDID" com.lincolnlabs.worldlab >/dev/null 2>&1 || true
  [ "${KEEP_BOOTED:-0}" = 1 ] || xcrun simctl shutdown "$UDID" 2>/dev/null || true
fi
# Per-view logs for the analysis: the shared STATS line plus that view's VIEWSHOT line.
python3 - "$run" <<'PY'
import os, re, sys
run = sys.argv[1]
src = os.path.join(run, "logs", "all.log")
text = open(src, errors="replace").read() if os.path.exists(src) else ""
stats = re.search(r"^STATS .*$", text, re.M)
for f in os.listdir(os.path.join(run, "raw")):
    if f.endswith(".png"):
        vid = f[:-4]
        shot = re.search(rf"^VIEWSHOT id={re.escape(vid)} .*$", text, re.M)
        open(os.path.join(run, "logs", f"{vid}.log"), "w").write("\n".join(x.group(0) for x in (stats, shot) if x) + "\n")
PY
prev=()
if [ -d "$ROOT/docs/lookloop/latest/frames" ]; then
  label=$(python3 -c "import json;m=json.load(open('$ROOT/docs/lookloop/latest/run.json'));print(m['started']+' '+m['commit'])" 2>/dev/null || echo "previous run")
  prev=(--prev "$ROOT/docs/lookloop/latest/frames" --prev-label "$label")
fi
python3 "$TOOLS/analyze.py" "$run" "${prev[@]+"${prev[@]}"}"
echo "run dir: $run"
