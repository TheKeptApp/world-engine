#!/bin/bash
# Look loop: plan -> capture -> signals and contact sheets -> rubric grading -> regression guard -> scoreboard.
# Sessions normally run it through the /lookloop skill (.claude/skills/lookloop/SKILL.md).
#   Tools/lookloop/lookloop.sh run [--gate] [--all] [--core] [view-id ...]
#       Routine run: captures only views whose inputs changed since docs/lookloop/latest (others are
#       reused with their grades); reviewers are Sonnet. --gate: every view, Opus reviewers (declared gate).
#       --all: every view without declaring a gate.
#   Tools/lookloop/lookloop.sh finish <run-dir>   merge grades, regression guard, publish latest/, scoreboard row
#   Tools/lookloop/lookloop.sh calibrate          grade the concept images themselves (see docs/lookloop/calibration.md)
#   Tools/lookloop/lookloop.sh calibrate-paintover  grade the paintover-v1 images blind (paint-over parity)
# Runs live in .build/lookloop/runs/<stamp>/ (git-ignored history); docs/lookloop/latest/ and scoreboard.md go into git.
# Env: SKIP_BUILD=1, SETTLE, LOAD_TIMEOUT, LOOKLOOP_SIM (see capture.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOOLS="$ROOT/Tools/lookloop"
cmd="${1:-run}"; shift || true

minutes_since() { python3 -c "import json,time;m=json.load(open('$1/run.json'));print(round((time.time()-m['t0'])/60,1))"; }

new_run() { # $1 = kind (routine|gate|calibration); prints the run dir
  local stamp run
  stamp=$(date +%Y%m%d-%H%M%S)
  run="$ROOT/.build/lookloop/runs/$stamp"
  mkdir -p "$run"
  # engineCommit: the last commit that changed what is rendered (engine, app, area data), so look-loop or
  # docs commits on top do not hide which renderer version was graded.
  python3 - "$run" "$stamp" "$1" "$(git -C "$ROOT" rev-parse --short HEAD)" "$(git -C "$ROOT" branch --show-current)" \
    "$(git -C "$ROOT" status --porcelain -- Sources Apps Data Package.swift | wc -l | tr -d ' ')" \
    "$(git -C "$ROOT" log -1 --format=%h -- Sources Apps Data Package.swift)" <<'PY'
import json, sys, time
import hashlib, os
run, stamp, kind, commit, branch, dirty, engine = sys.argv[1:8]
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(run))))
grading = hashlib.sha256(open(os.path.join(root, "docs/lookloop/GRADING.md"), "rb").read()).hexdigest()[:12]
json.dump({"stamp": stamp, "started": time.strftime("%Y-%m-%d %H:%M"), "t0": time.time(), "kind": kind, "gate": kind == "gate",
           "commit": commit, "engineCommit": engine, "branch": branch, "dirtyEngineFiles": int(dirty), "gradingSha": grading},
          open(f"{run}/run.json", "w"), indent=1)
PY
  echo "$run"
}

reviewer_prompts() { # $1 = run dir, $2 = model alias, $3 = manifest (repo-relative)
  python3 - "$1" "${1#"$ROOT"/}" "$2" "$3" <<'PY'
import json, os, sys
run, rel, model, manifest = sys.argv[1:5]
meta = json.load(open(os.path.join(run, "run.json")))
reused = set(meta.get("reused", []))
inapp = "in-app" in meta.get("frameSource", "")
views = {v["id"]: v for v in json.load(open(os.path.join(run[:-len(rel)], manifest))).get("views", [])} if os.path.exists(os.path.join(run[:-len(rel)], manifest)) else {}
ids = sorted(f[:-4] for f in os.listdir(os.path.join(run, "sheets")) if f.endswith(".jpg") and f[:-4] not in reused)
lines = [f"# Reviewer prompts: {len(ids)} view(s), model `{model}`", "",
         f"Spawn one `{model}` sub-agent per line, all in parallel (general-purpose agent; it needs Read and Write). "
         f"Then run `Tools/lookloop/lookloop.sh finish {rel}`.", ""]
for i in ids:
    lines.append(
        f"- `{i}`: Repo root is the current checkout; relative paths are relative to it. Modify no file except the grades JSON named "
        f"below. You are a strict visual reviewer for WorldEngine. Follow docs/lookloop/GRADING.md exactly to grade view `{i}` of "
        f"look-loop run `{rel}`. Read GRADING.md first, then the view entry in {manifest}, the `{i}` entry in {rel}/signals.json, "
        f"the contact sheet {rel}/sheets/{i}.jpg, the full frame {rel}/frames/{i}.jpg and the target PNG(s) if any. "
        + ("Frames in this run are WorldLab in-app captures (no UI): do not raise osm-credit-missing (the credit is checked on the UI screenshots). " if inapp else "")
        + (f"This view has an approved mock captured at its own conditions: compare the frame at phone size against {views[i]['mock']} "
           f"(if it is not in this checkout, use ~/Desktop/world-engine/{views[i]['mock']}) and include \"mockGap\" "
           f"(GRADING.md section M: mock, closeness 1-5, at most 3 gaps). " if views.get(i, {}).get("mock")
           else "Do not add mockGap for this view. ")
        + (f"Also compare against the approved house-archetypes-v1 block paint-over {views[i]['archetypeMock']} (houses only: forms, "
           f"materials, palette variety, porches, garages, yards; not lighting) and include \"archetypeGap\" with the same shape "
           f"as mockGap (mock, closeness 1-5, at most 3 gaps). " if views.get(i, {}).get("archetypeMock") else "")
        + f"Write only the "
        f"JSON object of section G to {rel}/grades/{i}.json (set \"grader\" to your model id), then reply \"done\".")
open(os.path.join(run, "reviewers.md"), "w").write("\n".join(lines) + "\n")
print(len(ids))
PY
}

case "$cmd" in
  run)
    kind=routine; plan_args=()
    for a in "$@"; do
      case "$a" in
        --gate) kind=gate; plan_args+=(--all) ;;
        --all) plan_args+=(--all) ;;
        # --core: the per-merge core set (owner, 7 Oct 2026); the full set is for gate checks.
        --core) while read -r id; do plan_args+=("$id"); done < <(python3 -c "import json;[print(v['id']) for v in json.load(open('$TOOLS/views.json'))['views'] if v.get('core')]") ;;
        *) plan_args+=("$a") ;;
      esac
    done
    run=$(new_run "$kind")
    rel="${run#"$ROOT"/}"
    echo "look loop $(basename "$run") ($kind; engine $(git -C "$ROOT" log -1 --format=%h -- Sources Apps Data Package.swift), checkout $(git -C "$ROOT" rev-parse --short HEAD) on $(git -C "$ROOT" branch --show-current))"
    python3 "$TOOLS/plan.py" "$run" "${plan_args[@]+"${plan_args[@]}"}"
    "$TOOLS/capture.sh" "$run"
    prev=()
    if [ -d "$ROOT/docs/lookloop/latest/frames" ]; then
      label=$(python3 -c "import json;m=json.load(open('$ROOT/docs/lookloop/latest/run.json'));print(m['started']+' '+m.get('engineCommit',m['commit']))" 2>/dev/null || echo "previous run")
      prev=(--prev "$ROOT/docs/lookloop/latest/frames" --prev-label "$label")
    fi
    python3 "$TOOLS/analyze.py" "$run" "${prev[@]+"${prev[@]}"}"
    echo "capture + analysis: $(minutes_since "$run") min"
    model=sonnet; [ "$kind" = gate ] && model=opus
    if [ -s "$run/views.tsv" ] && ! ls "$run/raw/"*.png >/dev/null 2>&1; then
      echo "No view was captured (see $rel/capture.tsv and $rel/logs): stopping without grading or publishing."
      exit 2
    fi
    if [ ! -s "$run/views.tsv" ]; then
      echo "Nothing that renders or grades any view changed since the last published run: no new row."
      exit 0
    fi
    n=$(reviewer_prompts "$run" "$model" Tools/lookloop/views.json)
    if [ "$n" = 0 ]; then
      python3 "$TOOLS/finish.py" "$run"
      exit 0
    fi
    echo
    echo "REVIEWERS: spawn $n $model sub-agent(s) in parallel, one per line of $rel/reviewers.md;"
    echo "then run: Tools/lookloop/lookloop.sh finish $rel"
    exit 3
    ;;
  calibrate)
    run=$(new_run calibration)
    rel="${run#"$ROOT"/}"
    python3 "$TOOLS/calibrate.py" "$run"
    n=$(reviewer_prompts "$run" opus Tools/lookloop/calibration.json)
    echo "REVIEWERS: spawn $n opus sub-agent(s) in parallel, one per line of $rel/reviewers.md;"
    echo "then run: python3 Tools/lookloop/calibrate.py --report $rel"
    exit 3
    ;;
  calibrate-paintover)
    run=$(new_run calibration)
    rel="${run#"$ROOT"/}"
    python3 "$TOOLS/calibrate.py" --paintover "$run"
    n=$(reviewer_prompts "$run" opus Tools/lookloop/calibration-paintover.json)
    echo "REVIEWERS: spawn $n opus sub-agent(s) in parallel, one per line of $rel/reviewers.md;"
    echo "then run: python3 Tools/lookloop/calibrate.py --merge-paintover $rel"
    exit 3
    ;;
  finish) python3 "$TOOLS/finish.py" "$(cd "$1" && pwd)" "${@:2}" ;;
  *) sed -n 2,11p "$0"; exit 1 ;;
esac
