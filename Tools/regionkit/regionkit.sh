#!/bin/sh
# Region kit: drafts regional style profiles (StyleProfile v2) from open data.
#   Tools/regionkit/regionkit.sh draft regions/<region>.json [--zone Z]
#   Tools/regionkit/regionkit.sh draft --id REGION --zone ZONE (--bbox S,W,N,E | --center LAT,LON --radius M) --template ID
#   Tools/regionkit/regionkit.sh all | compare | test | validate FILE... | anchors CONFIG [--write] | find ...
# Python 3 standard library only. Cache: $REGIONKIT_CACHE or Tools/regionkit/.cache (git-ignored).
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1
if [ "$1" = "test" ]; then
  shift
  exec python3 -m unittest discover -s tests -t . "$@"
fi
exec python3 -m regionkit "$@"
