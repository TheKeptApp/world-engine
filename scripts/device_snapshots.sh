#!/bin/bash
# On-device screenshots of the RealityKit renderer on the connected iPhone: visual checks without the
# Simulator. For each set of WorldLab launch arguments the script launches the app on the phone with
# `-snapshot SECONDS`. The app waits that long after the world is on screen, saves
# snapshot-realitykit-<name>.png in its Documents folder and prints "SNAPSHOT saved <file>"; the script
# waits for that line on the console, stops the app, and at the end copies the PNGs to the output folder.
# A snapshot is RealityKit's own capture of the world view (with -frame16x9, the 16:9 frame) at the view's
# render resolution. No HUD, controls or OpenStreetMap credit: SwiftUI draws those over the view. The console
# line "SNAPSHOT source=... size=..." says which capture produced the image and its size.
#
#   scripts/device_snapshots.sh [-o OUT_DIR] [-s SECONDS] [-t TIMEOUT] [--all] [ARGSET ...]
#
#   ARGSET      one set of WorldLab launch arguments, quoted as a single word, e.g. "-showcase 03 -hud off -frame16x9".
#               Default: showcase states 01-12 and the presets v2-01, v2-04, v2-06, each with "-hud off -frame16x9".
#               "-renderer realitykit" and "-snapshot SECONDS" are added when missing. Add "-snapshotname NAME" to
#               choose the file name, "-snapshotsource compositor" to capture the view as the screen composites it.
#   -o OUT_DIR  output folder (default docs/screenshots/m3/device)
#   -s SECONDS  how long the app waits after the world appears before it captures (default 25)
#   -t TIMEOUT  seconds to wait for "SNAPSHOT saved" per launch (default: the wait + 35)
#   --all       copy every snapshot-*.png on the phone, not only the ones this run reported
#
# Needs WorldLab installed (scripts/device.sh build) and the phone unlocked; the app keeps the screen on.
# It launches WorldLab on the phone, so do not run it while another session is using the phone.
# Env: DEVICE=<identifier or name> to pick a phone (default: the connected iPhone).
# Exit status: 0 every capture saved, 1 some captures failed, 2 stopped early (no phone, phone locked,
# or the app would not launch), 64 bad arguments.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE=com.lincolnlabs.worldlab
OUT="$ROOT/docs/screenshots/m3/device"
SNAP_SECONDS=25
TIMEOUT=""
ALL=0
SETS=()

usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; }
bad() { echo "device_snapshots.sh: $*" >&2; exit 64; }
is_int() { case "$1" in '' | *[!0-9]*) return 1 ;; *) return 0 ;; esac; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help) usage; exit 0 ;;
    -o | -s | -t)
      [ $# -ge 2 ] || bad "$1 needs a value"
      case "$1" in -o) OUT="$2" ;; -s) SNAP_SECONDS="$2" ;; -t) TIMEOUT="$2" ;; esac
      shift 2 ;;
    --all) ALL=1; shift ;;
    *) SETS+=("$1"); shift ;;
  esac
done
is_int "$SNAP_SECONDS" || bad "-s needs whole seconds, got '$SNAP_SECONDS'"
[ -z "$TIMEOUT" ] || is_int "$TIMEOUT" || bad "-t needs whole seconds, got '$TIMEOUT'"
case "$OUT" in /*) ;; *) OUT="$ROOT/$OUT" ;; esac
if [ ${#SETS[@]} -eq 0 ]; then
  for n in 01 02 03 04 05 06 07 08 09 10 11 12; do SETS+=("-showcase $n -hud off -frame16x9"); done
  for p in v2-01 v2-04 v2-06; do SETS+=("-preset $p -hud off -frame16x9"); done
fi

# The connected iPhone, found the way scripts/device_checks.sh does, except that the state column must be
# exactly "connected" or "available" (a plain /available/ also matches "unavailable").
DEVICE="${DEVICE:-$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/ connected / || / available /) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{36}$/) print $i}' | head -1)}"
[ -n "$DEVICE" ] || { echo "No connected iPhone found. Plug it in, unlock it and trust this Mac." >&2; exit 2; }

LOGS=$(mktemp -d -t device_snapshots)
CHILD=""
KEEP_LOGS=0
LOCKED_RE='could not be, unlocked|reason: Locked|device is locked'

# Stops a console launch the way the other device scripts do: SIGTERM, which devicectl forwards to the
# app (it then flushes its own messages and exits); SIGKILL only if it does not go.
stop_console() {
  kill "$1" 2>/dev/null || return 0
  local i=0
  while kill -0 "$1" 2>/dev/null && [ $i -lt 10 ]; do sleep 1; i=$((i + 1)); done
  kill -9 "$1" 2>/dev/null
  wait "$1" 2>/dev/null
}
cleanup() {
  [ -z "$CHILD" ] || stop_console "$CHILD"
  if [ "$KEEP_LOGS" = 1 ]; then echo "Console logs: $LOGS"; else rm -rf "$LOGS"; fi
}
trap cleanup EXIT
trap 'echo; echo "Interrupted. Captures already made stay in the app: scripts/device.sh pull <folder> fetches them."; exit 130' INT TERM

lock_message() { echo "The phone is locked. Unlock it and keep the screen on, then run this again."; }

# capture <launch arguments>: launches once and waits. Sets RESULT (ok | failed | app-exited | timeout |
# launch-failed | locked), LOG, ELAPSED, NAME (the file the app reported) and INFO (its source and size line).
INDEX=0
capture() {
  local line=" $1 "
  case "$line" in *" -renderer "*) ;; *) line=" -renderer realitykit$line" ;; esac
  case "$line" in *" -snapshot "*) ;; *) line="$line-snapshot $SNAP_SECONDS " ;; esac
  local -a args=()
  read -r -a args <<< "$line"
  local secs="$SNAP_SECONDS" i
  for ((i = 0; i < ${#args[@]} - 1; i++)); do
    [ "${args[$i]}" = "-snapshot" ] && secs="${args[$((i + 1))]}"
  done
  case "$secs" in '' | *[!0-9.]*) secs="$SNAP_SECONDS" ;; esac
  local limit="${TIMEOUT:-$((${secs%%.*} + 35))}"

  INDEX=$((INDEX + 1))
  LOG="$LOGS/capture-$INDEX.log"
  xcrun devicectl device process launch --device "$DEVICE" --terminate-existing --console "$BUNDLE" -- "${args[@]}" \
    > "$LOG" 2>&1 < /dev/null &
  CHILD=$!

  local waited=0
  RESULT=timeout
  while [ $waited -lt "$limit" ]; do
    sleep 1
    waited=$((waited + 1))
    if grep -q '^SNAPSHOT saved ' "$LOG"; then RESULT=ok; break; fi
    if grep -q '^SNAPSHOT failed ' "$LOG"; then RESULT=failed; break; fi
    if ! kill -0 "$CHILD" 2>/dev/null; then RESULT=app-exited; break; fi
  done
  ELAPSED=$waited
  stop_console "$CHILD"
  CHILD=""

  # devicectl writes its own messages ("Launched application ...") only when it exits, so judge by the
  # complete log now. No sign of the app at all (no launch message, no output of its own) means it never started.
  if grep -q '^SNAPSHOT saved ' "$LOG"; then RESULT=ok
  elif grep -q '^SNAPSHOT failed ' "$LOG"; then RESULT=failed
  elif grep -Eqi "$LOCKED_RE" "$LOG"; then RESULT=locked
  elif ! grep -Eq 'Launched application|App terminated|^STATS |^SNAPSHOT ' "$LOG"; then RESULT=launch-failed
  fi
  NAME=$(sed -n 's/^SNAPSHOT saved //p' "$LOG" | head -1 | tr -d '\r')
  INFO=$(grep -m1 '^SNAPSHOT source=' "$LOG" | tr -d '\r' | cut -c1-120)
  INFO=${INFO#SNAPSHOT }
}

# Why a capture failed, from its log: the app's own report, else devicectl's first error (with the lines
# that explain it), else the end of the log.
explain() {
  local why
  why=$(grep -m1 '^SNAPSHOT failed ' "$LOG")
  [ -n "$why" ] || why=$(grep -m1 -A3 '^ERROR' "$LOG")
  # (devicectl's "Failed to load provisioning ..." warning comes with every call; it explains nothing.)
  [ -n "$why" ] || why=$(grep -v -e '^$' -e 'provisioning paramter' -e 'manage create' "$LOG" | tail -4)
  echo "$why" | tr -d '\r' | cut -c1-220 | sed 's/^/        /'
}

TOTAL=${#SETS[@]}
DONE=0
OK_COUNT=0
FAIL_COUNT=0
STOP=""
SAVED=$'\n'
SUMMARY=""
echo "iPhone $DEVICE, $TOTAL capture(s), output $OUT"
for set in "${SETS[@]}"; do
  DONE=$((DONE + 1))
  printf '[%d/%d] %s ... ' "$DONE" "$TOTAL" "$set"
  attempt=1
  while :; do
    capture "$set"
    [ "$RESULT" = launch-failed ] && [ $attempt -lt 2 ] || break
    printf 'did not launch, trying again ... '
    sleep 5
    attempt=$((attempt + 1))
  done
  case "$RESULT" in
    ok)
      OK_COUNT=$((OK_COUNT + 1))
      SAVED="$SAVED$NAME"$'\n'
      echo "saved after ${ELAPSED} s: $NAME ${INFO:+($INFO)}" ;;
    failed | app-exited | timeout)
      FAIL_COUNT=$((FAIL_COUNT + 1)); KEEP_LOGS=1
      case "$RESULT" in
        failed) echo "FAILED, the app could not take the snapshot" ;;
        app-exited) echo "FAILED, the app stopped before it saved a snapshot (crash?)" ;;
        timeout) echo "FAILED, no snapshot after ${ELAPSED} s" ;;
      esac
      explain
      SUMMARY="${SUMMARY}  $set ($RESULT, log $LOG)"$'\n' ;;
    locked)
      FAIL_COUNT=$((FAIL_COUNT + 1)); KEEP_LOGS=1; STOP=locked
      echo "FAILED, the phone is locked"
      explain
      SUMMARY="${SUMMARY}  $set (phone locked)"$'\n'
      break ;;
    launch-failed)
      FAIL_COUNT=$((FAIL_COUNT + 1)); KEEP_LOGS=1; STOP=launch
      echo "FAILED, devicectl could not launch the app (is WorldLab installed? scripts/device.sh build)"
      explain
      SUMMARY="${SUMMARY}  $set (launch, log $LOG)"$'\n'
      break ;;
  esac
done

# Copy this run's captures (or all with --all) from the app's Documents folder.
PULLED=0
if [ "$OK_COUNT" -gt 0 ] || [ "$ALL" = 1 ]; then
  TMP=$(mktemp -d -t device_snapshots_pull)
  if xcrun devicectl device copy from --device "$DEVICE" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
      --source Documents --destination "$TMP" --timeout 180 > "$LOGS/pull.log" 2>&1; then
    mkdir -p "$OUT"
    OTHERS=0
    while IFS= read -r f; do
      base=$(basename "$f")
      case "$SAVED" in
        *$'\n'"$base"$'\n'*) is_this_run=1 ;;
        *) is_this_run=0 ;;
      esac
      if [ "$is_this_run" = 1 ] || [ "$ALL" = 1 ]; then
        cp "$f" "$OUT/$base" && PULLED=$((PULLED + 1))
        size=$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {if (w) print w "x" h}')
        echo "  $base ${size:+($size)}"
      else
        OTHERS=$((OTHERS + 1))
      fi
    done < <(find "$TMP" -type f -name 'snapshot-*.png' | sort)
    [ "$OTHERS" -eq 0 ] || echo "  ($OTHERS older snapshot-*.png on the phone left alone; --all copies them)"
    # Everything the app said it saved should have come over.
    for base in $(printf '%s' "$SAVED"); do
      [ -f "$OUT/$base" ] || { echo "  MISSING $base: reported saved but not found in Documents"; FAIL_COUNT=$((FAIL_COUNT + 1)); KEEP_LOGS=1; }
    done
  else
    KEEP_LOGS=1
    echo "Could not copy the captures from the phone (is it still unlocked?):"
    grep -m1 -A3 '^ERROR' "$LOGS/pull.log" | sed 's/^/  /'
    echo "They are still in the app's Documents folder: scripts/device.sh pull \"$OUT\" fetches them."
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  rm -rf "$TMP"
fi

echo
echo "Captured $OK_COUNT of $TOTAL, copied $PULLED file(s) to $OUT"
if [ -n "$SUMMARY" ]; then echo "Failed:"; printf '%s' "$SUMMARY"; fi
if [ -n "$STOP" ]; then
  [ "$STOP" = locked ] && lock_message
  if [ "$DONE" -lt "$TOTAL" ]; then
    echo "Not run (start them again after fixing the above):"
    i=0
    for set in "${SETS[@]}"; do i=$((i + 1)); [ $i -gt $DONE ] && echo "  scripts/device_snapshots.sh \"$set\""; done
  fi
  exit 2
fi
[ "$FAIL_COUNT" -eq 0 ] || exit 1
exit 0
