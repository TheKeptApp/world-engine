#!/bin/bash
# Look loop: capture -> signals and contact sheets -> rubric grading -> scoreboard.
#   Tools/lookloop/lookloop.sh run [view-id ...]     full loop (all active views, or just these)
#   Tools/lookloop/lookloop.sh grade  <run-dir>      headless reviewers (claude -p), if the CLI is logged in
#   Tools/lookloop/lookloop.sh finish <run-dir>      merge grades, publish docs/lookloop/latest, add a scoreboard row
# Runs live in .build/lookloop/runs/<stamp>/ (git-ignored history); only docs/lookloop/latest/ and
# scoreboard.md are meant for git. See docs/lookloop/README.md.
# Env: SKIP_BUILD=1 (reuse the WorldLab build), LOOKLOOP_GRADER=auto|cli|session, plus capture.sh/grade.py env.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$ROOT/Tools/lookloop"
cmd="${1:-run}"; shift || true

minutes_since() { python3 -c "import json,time;m=json.load(open('$1/run.json'));print(round((time.time()-m['t0'])/60,1))"; }

cli_ready() {
  # The claude CLI can grade headlessly only when it is logged in on this Mac.
  command -v claude >/dev/null || return 1
  local r; r=$(cd "$ROOT" && claude -p "Reply with the single word ready" --tools "" --output-format json 2>/dev/null || true)
  python3 -c "import json,sys;d=json.loads(sys.argv[1]);sys.exit(0 if not d.get('is_error') else 1)" "$r" 2>/dev/null
}

session_handoff() {
  local run="$1" rel; rel="${run#"$ROOT"/}"
  python3 - "$run" "$rel" <<'EOF' > "$run/reviewers.md"
import json, os, sys
run, rel = sys.argv[1], sys.argv[2]
ids = sorted(f[:-4] for f in os.listdir(os.path.join(run, "sheets")) if f.endswith(".jpg"))
print("# Reviewer prompts (one sub-agent per view, run them in parallel)\n")
print("Each reviewer writes its JSON to the given path, then the session runs `Tools/lookloop/lookloop.sh finish " + rel + "`.\n")
for i in ids:
    print(f"- `{i}`: You are a strict visual reviewer for WorldEngine. Follow docs/lookloop/GRADING.md exactly to grade view `{i}` of "
          f"look-loop run `{rel}`. Read GRADING.md first, then the view entry in Tools/lookloop/views.json, the `{i}` entry in "
          f"{rel}/signals.json, the contact sheet {rel}/sheets/{i}.jpg, the full frame {rel}/frames/{i}.jpg and the target PNG(s). "
          f"Write only the JSON object of section G to {rel}/grades/{i}.json (set \"grader\" to your model id), then reply \"done\".")
EOF
  mkdir -p "$run/grades"
  echo
  echo "GRADING NEEDS THE SESSION: the claude CLI is not logged in on this Mac, so reviewers can't start headlessly."
  echo "  1. Spawn one sub-agent per line of ${rel}/reviewers.md (in parallel)."
  echo "  2. Then run: Tools/lookloop/lookloop.sh finish ${rel}"
}

case "$cmd" in
  run)
    stamp=$(date +%Y%m%d-%H%M%S)
    run="$ROOT/.build/lookloop/runs/$stamp"
    mkdir -p "$run"
    python3 - "$run" "$stamp" "$(git -C "$ROOT" rev-parse --short HEAD)" "$(git -C "$ROOT" branch --show-current)" \
      "$(git -C "$ROOT" status --porcelain -- Sources Apps Data | wc -l | tr -d ' ')" <<'EOF'
import json, sys, time
run, stamp, commit, branch, dirty = sys.argv[1:6]
json.dump({"stamp": stamp, "started": time.strftime("%Y-%m-%d %H:%M"), "t0": time.time(), "commit": commit,
           "branch": branch, "dirtyEngineFiles": int(dirty)}, open(f"{run}/run.json", "w"), indent=1)
EOF
    echo "look loop $stamp  ($(git -C "$ROOT" rev-parse --short HEAD) on $(git -C "$ROOT" branch --show-current))"
    "$TOOLS/capture.sh" "$run" "$@"
    prev=()
    if [ -d "$ROOT/docs/lookloop/latest/frames" ]; then
      label=$(python3 -c "import json;m=json.load(open('$ROOT/docs/lookloop/latest/run.json'));print(m['started']+' '+m['commit'])" 2>/dev/null || echo "previous run")
      prev=(--prev "$ROOT/docs/lookloop/latest/frames" --prev-label "$label")
    fi
    python3 "$TOOLS/analyze.py" "$run" "${prev[@]+"${prev[@]}"}"
    echo "capture + analysis: $(minutes_since "$run") min"
    mode="${LOOKLOOP_GRADER:-auto}"
    if [ "$mode" = cli ] || { [ "$mode" = auto ] && cli_ready; }; then
      python3 "$TOOLS/grade.py" "$run"
      python3 "$TOOLS/finish.py" "$run"
    else
      session_handoff "$run"
      exit 3
    fi
    ;;
  grade)  python3 "$TOOLS/grade.py" "$(cd "$1" && pwd)" "${@:2}" ;;
  finish) python3 "$TOOLS/finish.py" "$(cd "$1" && pwd)" "${@:2}" ;;
  *) sed -n 2,9p "$0"; exit 1 ;;
esac
