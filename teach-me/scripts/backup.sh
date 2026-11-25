#!/usr/bin/env sh
# Back up this skill's data to the skills repo's skill-data branch: backup.sh sync|push|status|restore
# Delegates to bin/skill-data at the root of the micah-skills checkout this skill is installed from.
set -eu
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || {
  echo "not installed from a micah-skills checkout (a --copy install?); backup unavailable" >&2; exit 0; }
cmd=${1:-sync}; [ $# -gt 0 ] && shift
exec "$root/bin/skill-data" "$cmd" teach-me "$@"
