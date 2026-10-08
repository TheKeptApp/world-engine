#!/bin/sh
# Install this repository's tracked push-only hook; preserve other hook setups.
set -eu
cd "$(git rev-parse --show-toplevel)"
existing=$(git config --get core.hooksPath || true)
if [ -n "$existing" ] && [ "$existing" != .githooks ]; then
    echo 'Push guard installation stopped: another hooksPath is configured.' >&2
    exit 1
fi
old=$(git rev-parse --git-path hooks/pre-push)
if [ -z "$existing" ] && [ -f "$old" ]; then
    echo 'Push guard installation stopped: an existing pre-push hook needs integration.' >&2
    exit 1
fi
git config --local core.hooksPath .githooks
echo 'Push-only guard installed for this repository.'
