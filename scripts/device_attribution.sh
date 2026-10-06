#!/bin/bash
# GPU cost by feature on the connected iPhone. WorldLab's `-attribution 60` mode switches one
# feature off at a time (60 s per phase), each "off" phase between two "all features on" phases so
# slow drift (heat, clocks) cancels. The camera is fixed (a moving camera changes the GPU time by
# several ms on its own): VIEW=street (default, `street-mid` with Luna standing, golden hour) or
# VIEW=aerial (the v2 aerial fixture). Fixed 2.5× scale. A 5 s Metal System Trace at full GPU clock
# is recorded inside each phase (long traces hang over Wi-Fi); each feature's cost is the mean GPU
# busy time of its two neighbouring "all" phases minus its own.
#   scripts/device_attribution.sh [out-dir]
set -uo pipefail
# ALLOW_CHARGING=1: functional/overnight runs on the charger; results are labelled "charging" and
# must not be used for heat or battery decisions.
ALLOW_CHARGING="${ALLOW_CHARGING:-0}"
VIEW="${VIEW:-street}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/docs/perf/m3-phase5a-attribution/$VIEW}"; mkdir -p "$OUT/console" "$OUT/traces"
case "$VIEW" in
  street) PRESET=street-mid ;;
  aerial) PRESET=v2-06 ;;
  *) echo "VIEW must be street or aerial"; exit 1 ;;
esac
CORE=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)
UDID=$(xcrun devicectl device info details --device "$CORE" 2>/dev/null | sed -nE 's/^ *\? udid: *([0-9A-F-]+).*/\1/p' | head -1)
TEMPLATE=$("$ROOT/scripts/make_gpu_template.py" "$ROOT/.build/templates/MetalSystemTrace-max.tracetemplate" 3)
LOG="$OUT/console/attribution.log"
PHASES="all1 noShadows all2 noSky all3 noPost all4 noMSAA all5 noSurfaceDetail all6 noFoliage all7 noBuildings all8"
xcrun devicectl device process launch --device "$CORE" --terminate-existing --console com.lincolnlabs.worldlab -- \
  -renderer realitykit -preset "$PRESET" -date 2026-10-15T23:44:01Z -weather clear -attribution 60 -renderscale 2.5 \
  -rendertrace -hud off > "$LOG" 2>&1 &
PID=$!
for _ in $(seq 1 60); do sleep 1; grep -q "^CONDITIONS" "$LOG" && break; done
COND=$(grep -m1 "^CONDITIONS" "$LOG"); echo "$COND"
[[ "$COND" == *"lowPowerMode=false battery=unplugged"* || ( "$ALLOW_CHARGING" == 1 && "$COND" == *"lowPowerMode=false"* ) ]] || { kill $PID; echo "STOPPED: conditions"; exit 2; }
[[ "$COND" == *"battery=unplugged"* ]] || echo "NOTE: charging run (functional only)" | tee "$OUT/CHARGING"
: > "$OUT/attribution.txt"
for phase in $PHASES; do
  for _ in $(seq 1 120); do sleep 1; grep -q "^ATTR $phase " "$LOG" && break; done
  sleep 3
  rm -rf "$OUT/traces/$phase.trace"
  xcrun xctrace record --device "$UDID" --template "$TEMPLATE" --attach WorldLab --time-limit 5s \
    --output "$OUT/traces/$phase.trace" --no-prompt >/dev/null 2>&1 &
  TR=$!; T0=$SECONDS
  for _ in $(seq 1 54); do sleep 1; kill -0 $TR 2>/dev/null || break; done
  if kill -0 $TR 2>/dev/null; then kill -INT $TR; sleep 2; kill -9 $TR 2>/dev/null; echo "$phase: trace hung after $((SECONDS - T0)) s" | tee -a "$OUT/attribution.txt"; continue; fi
  LINE=$(python3 "$ROOT/scripts/gpu_frames.py" "$OUT/traces/$phase.trace" 2>/dev/null | grep "GPU busy")
  echo "$phase $LINE (trace took $((SECONDS - T0)) s)" | tee -a "$OUT/attribution.txt"
done
grep "^CONDITIONS" "$LOG" | sort | uniq -c
grep "^RENDER" "$LOG" | awk '{print $NF}' | sort | uniq -c   # heat states seen
kill $PID 2>/dev/null; wait $PID 2>/dev/null
python3 - "$OUT/attribution.txt" <<'PY' | tee "$OUT/costs.txt"
import re, sys
order, rows = [], {}
for line in open(sys.argv[1]):
    m = re.match(r"(\S+) GPU busy: frames=(\d+) mean=([\d.]+) ms median=([\d.]+) .*worst1%=([\d.]+)", line)
    if m:
        order.append(m.group(1))
        rows[m.group(1)] = (float(m.group(3)), float(m.group(4)), float(m.group(5)), int(m.group(2)))
alls = [k for k in order if k.startswith("all")]
print("all-features phases: " + ", ".join(f"{k} {rows[k][0]:.2f}" for k in alls) + " ms (mean)")
for i, k in enumerate(order):
    if k.startswith("all"):
        continue
    nb = [order[j] for j in (i - 1, i + 1) if 0 <= j < len(order) and order[j].startswith("all")]
    if not nb:
        print(f"{k:16s} no neighbouring all phase"); continue
    ref = sum(rows[n][0] for n in nb) / len(nb)
    refmed = sum(rows[n][1] for n in nb) / len(nb)
    mean, med, worst, n = rows[k]
    spread = abs(rows[nb[0]][0] - rows[nb[-1]][0])
    print(f"{k:16s} {mean:6.2f} ms (median {med:5.2f}, worst 1% {worst:5.2f}) vs {ref:5.2f}: saves {ref - mean:5.2f} ms "
          f"(median {refmed - med:5.2f}; neighbours differ by {spread:4.2f}) [{n} frames]")
PY
