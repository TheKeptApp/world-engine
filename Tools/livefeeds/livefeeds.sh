#!/bin/sh
# Live-feed relay prototype (Denver RTD only). Python 3 standard library only.
#   Tools/livefeeds/livefeeds.sh serve [--port P] [--host H] [--interval S] [--cache-dir DIR]
#   Tools/livefeeds/livefeeds.sh once     fetch once and print a summary
#   Tools/livefeeds/livefeeds.sh test     offline unit tests (no network)
# Cache: $LIVEFEEDS_CACHE or Tools/livefeeds/.cache (git-ignored).
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1
if [ "$1" = "test" ]; then
  shift
  exec python3 -m unittest discover -s tests -t . "$@"
fi
exec python3 -m livefeeds "$@"
