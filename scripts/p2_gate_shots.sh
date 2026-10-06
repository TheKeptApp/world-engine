#!/bin/bash
# Phase 5B building gate captures (BuildingLab in the simulator): public streets only.
#   scripts/p2_gate_shots.sh <out-dir>
# Builds once, then reuses the build for every shot. Env: SNAPSHOT_WAIT (default 70).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:?usage: p2_gate_shots.sh <out-dir>}"
mkdir -p "$OUT"
export SNAPSHOT_WAIT="${SNAPSHOT_WAIT:-70}"
# Autumn afternoon, the time of concept 03 (2026-10-22 15:00 CDT).
DATE=2026-10-22T20:00:00Z
EV=(-area evanston-south -profile evanston -date $DATE -focus 42.0350,-87.6940,42.0410,-87.6885 -frame16x9)
LV=(-area lakeview-sheil-park -profile chicago-dense-north -date $DATE -focus 41.9415,-87.6690,41.9480,-87.6585 -frame16x9)
shot() { local name="$1"; shift; "$ROOT/scripts/building_shots.sh" "$OUT/$name.png" "$@"; export SKIP_BUILD=1; }

# Evanston: Wesley Avenue, east sidewalk, looking south (houses on the left).
shot evanston-street "${EV[@]}" -look 42.0382,-87.69135,1.65,180,-3,50
# Evanston: low oblique over the same block.
shot evanston-aerial "${EV[@]}" -overview 42.0378,-87.6915,95,32,200,45
# Lakeview: West Roscoe Street, south sidewalk, looking west.
shot lakeview-street "${LV[@]}" -look 41.943402,-87.66075,1.65,270,-3,50
# Lakeview: alley behind the block, looking north.
shot lakeview-alley "${LV[@]}" -look 41.944063,-87.666977,1.65,0,-3,50
# Lakeview: low oblique over the block.
shot lakeview-aerial "${LV[@]}" -overview 41.9440,-87.6640,110,32,330,45
# Wilmette (OSM + Overture footprints): Highland Ave, north sidewalk, looking east (regions fixture 01 camera).
WL=(-area wilmette-vattmann-park -profile wilmette -date $DATE -focus 42.0720,-87.7225,42.0790,-87.7130 -frame16x9)
shot wilmette-street "${WL[@]}" -look 42.074933,-87.719996,1.65,90,-3,50
shot wilmette-aerial "${WL[@]}" -overview 42.0755,-87.7180,110,32,200,45
# Winter date (concepts 04 and 06 show snow; BuildingLab sets no weather, so these show winter light only).
WINTER=2026-01-15T18:00:00Z
shot evanston-street-winter "${EV[@]/$DATE/$WINTER}" -look 42.0382,-87.69135,1.65,180,-3,50
shot lakeview-alley-winter "${LV[@]/$DATE/$WINTER}" -look 41.944063,-87.666977,1.65,0,-3,50
echo "Gate shots in $OUT"
