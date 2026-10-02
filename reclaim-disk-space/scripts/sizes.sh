#!/usr/bin/env bash
# What's big in DIR: every immediate child, largest first, then the total.
#
#   sizes.sh DIR [N]     show the N largest children (default 15)
#
# No globs, so the caller's zsh options can't turn "nothing matched" into an
# aborted command that looks like an empty folder. du errors are counted, not
# hidden: a folder you can't read is reported as unreadable, not as small.

set -uo pipefail
. "$(dirname "$0")/lib.sh"

dir=${1:?usage: sizes.sh DIR [N]}
n=${2:-15}
[ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 1; }

errs=$(mktemp)
trap 'rm -f "$errs"' EXIT

children=$(find "$dir" -mindepth 1 -maxdepth 1 2>>"$errs" | grep -c .)
find "$dir" -mindepth 1 -maxdepth 1 -exec du -skx {} + 2>>"$errs" | human | head -"$n"
total=$(du -skx "$dir" 2>/dev/null | cut -f1)
echo "total $(gib "${total:-0}") in $children entries: $dir"

unreadable=$(grep -c . "$errs")
if [ "$unreadable" -gt 0 ]; then
  echo "du could not read $unreadable paths, so these sizes are a floor. First: $(head -1 "$errs")"
fi
