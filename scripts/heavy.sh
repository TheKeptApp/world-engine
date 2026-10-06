#!/bin/bash
# Runs one heavy job (Xcode/Swift build, full test suite, Simulator run, look loop) under the Mac's
# shared turn-taking lock, ~/.agent-heavy-lock (owner's shared Mac rules, 2026-10-06):
#   - waits while another live owner holds the lock (checks every 60 s);
#   - takes it with an atomic mkdir and writes an owner file (project, agent, PID, job, start);
#   - prefers a 1-minute load under 25, but starts anyway after 10 minutes of waiting for it;
#   - releases it the moment the job ends (only its own lock).
# A lock with no owner file, or a dead owner PID, while no xcodebuild/simctl/swift test runs, is
# abandoned: it is taken over and reported on stderr ("HEAVY abandoned lock taken over").
#   scripts/heavy.sh "job description" command [args...]
# Env: HEAVY_AGENT (default "WorldEngine P0"), HEAVY_LOAD (25), HEAVY_LOAD_WAIT seconds (600).
set -uo pipefail
LOCK="$HOME/.agent-heavy-lock"
JOB="${1:?job description}"; shift
AGENT="${HEAVY_AGENT:-WorldEngine P0}"
MAXLOAD="${HEAVY_LOAD:-25}"
LOADWAIT="${HEAVY_LOAD_WAIT:-600}"
OWNER="$LOCK/owner"

heavy_running() { pgrep -qf "xcodebuild|simctl|swift-test|swiftpm-testing-helper|swift-build"; }
owner_pid() { sed -nE 's/^pid=([0-9]+).*/\1/p' "$OWNER" 2>/dev/null | head -1; }

write_owner() {
  printf 'project=WorldEngine\nagent=%s\npid=%s\njob=%s\nstart=%s\n' "$AGENT" "$$" "$JOB" "$(date '+%Y-%m-%d %H:%M:%S')" > "$OWNER"
}

while :; do
  if mkdir "$LOCK" 2>/dev/null; then
    write_owner
    break
  fi
  pid=$(owner_pid)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    echo "HEAVY waiting: lock held by $(tr '\n' ' ' < "$OWNER" 2>/dev/null)" >&2
    sleep 60
    continue
  fi
  if heavy_running; then  # owner unknown or gone, but someone is building or running a Simulator
    echo "HEAVY waiting: lock has no live owner, but a heavy process is running" >&2
    sleep 60
    continue
  fi
  echo "HEAVY abandoned lock taken over (owner file: $( [ -f "$OWNER" ] && tr '\n' ' ' < "$OWNER" || echo none ))" >&2
  write_owner
  break
done
release() { [ "$(owner_pid)" = "$$" ] && rm -rf "$LOCK"; }
trap release EXIT INT TERM

waited=0
while [ "$waited" -lt "$LOADWAIT" ]; do
  load=$(sysctl -n vm.loadavg | awk '{print int($2)}')
  [ "$load" -lt "$MAXLOAD" ] && break
  sleep 30; waited=$((waited + 30))
done
echo "HEAVY start: $JOB (load $(sysctl -n vm.loadavg | awk '{print $2}'), waited ${waited}s for load)" >&2
"$@"
status=$?
echo "HEAVY done: $JOB (exit $status)" >&2
exit $status
