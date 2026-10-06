#!/bin/bash
# Runs one heavy job (Xcode/Swift build, full test suite, Simulator run, look loop) under the Mac's
# shared turn-taking lock, ~/.agent-heavy-lock (owner's shared Mac rules, 2026-10-06):
#   - first waits up to 10 minutes for a 1-minute load under 25 (without holding the lock);
#   - then waits while anyone holds the lock (checks every 60 s): a lock counts as held whenever
#     its owner file names a running PID or names none we can read;
#   - takes it with an atomic mkdir and writes an owner file (project, agent, PID, job, start);
#   - releases it the moment the job ends or is interrupted (only its own lock).
# A lock with no owner file, or a dead owner PID, while no xcodebuild/simctl/swift test runs, is
# abandoned: the job proceeds without touching it, and says so on stderr ("HEAVY abandoned lock")
# for the owner's report. Another session's lock is never written into or removed.
#   scripts/heavy.sh "job description" command [args...]
# Env: HEAVY_AGENT (default "WorldEngine P0"), HEAVY_LOAD (25), HEAVY_LOAD_WAIT seconds (600).
set -uo pipefail
LOCK="$HOME/.agent-heavy-lock"
JOB="${1:?job description}"; shift
AGENT="${HEAVY_AGENT:-WorldEngine P0}"
MAXLOAD="${HEAVY_LOAD:-25}"
LOADWAIT="${HEAVY_LOAD_WAIT:-600}"
OWNER="$LOCK/owner"
MINE=0

heavy_running() { pgrep -qf "xcodebuild|simctl|swift-test|swiftpm-testing-helper|swift-build"; }
# The owner's PID in any of "pid=1", "pid: 1", "PID 1", "\"pid\": 1" (first owner-like file).
owner_pid() {
  local f
  for f in "$LOCK"/*; do
    [ -f "$f" ] || continue
    grep -ioE 'pid[^0-9a-z]*[0-9]+' "$f" | head -1 | grep -oE '[0-9]+$' && return
  done
}
has_owner_file() { [ -n "$(ls -A "$LOCK" 2>/dev/null)" ]; }
release() { [ "$MINE" = 1 ] && [ "$(owner_pid)" = "$$" ] && rm -rf "$LOCK"; MINE=0; }
trap 'release' EXIT
trap 'release; exit 130' INT TERM

waited=0
while [ "$waited" -lt "$LOADWAIT" ]; do
  [ "$(sysctl -n vm.loadavg | awk '{print int($2)}')" -lt "$MAXLOAD" ] && break
  sleep 30; waited=$((waited + 30))
done

while :; do
  if mkdir "$LOCK" 2>/dev/null; then
    printf 'project=WorldEngine\nagent=%s\npid=%s\njob=%s\nstart=%s\n' "$AGENT" "$$" "$JOB" "$(date '+%Y-%m-%d %H:%M:%S')" > "$OWNER"
    MINE=1
    break
  fi
  pid=$(owner_pid)
  if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null && ! heavy_running; then
    echo "HEAVY abandoned lock (owner PID $pid not running, no heavy process): proceeding without it" >&2
    break
  fi
  if ! has_owner_file && ! heavy_running; then
    echo "HEAVY abandoned lock (no owner file, no heavy process): proceeding without it" >&2
    break
  fi
  echo "HEAVY waiting: lock held ($(cat "$LOCK"/* 2>/dev/null | tr '\n' ' ' | cut -c1-160))" >&2
  sleep 60
done
echo "HEAVY start: $JOB (load $(sysctl -n vm.loadavg | awk '{print $2}'), waited ${waited}s for load)" >&2
"$@"
status=$?
release
echo "HEAVY done: $JOB (exit $status)" >&2
exit $status
