#!/bin/bash
# Size of the blobs a commit range adds (new or changed files), for the 20 MB pre-push guard.
#   Tools/lookloop/commit_size.sh [range]      default: origin/main..HEAD
# Prints one line per commit over the limit and exits 1 if any commit adds more than LIMIT_MB (default 20).
set -euo pipefail
range="${1:-origin/main..HEAD}"
limit=$(( ${LIMIT_MB:-20} * 1024 * 1024 ))
over=0
for c in $(git rev-list --no-merges "$range"); do
  bytes=$(git diff-tree -r --no-commit-id --diff-filter=AM "$c" | awk '{print $4}' | git cat-file --batch-check='%(objectsize)' | awk '{s+=$1} END{print s+0}')
  if [ "$bytes" -gt "$limit" ]; then
    printf 'OVER %s %.1f MB %s\n' "$(git rev-parse --short "$c")" "$(echo "$bytes/1048576" | bc -l)" "$(git log -1 --format=%s "$c" | cut -c1-70)"
    over=1
  fi
done
exit $over
