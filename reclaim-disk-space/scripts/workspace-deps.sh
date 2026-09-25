#!/usr/bin/env bash
# node_modules/ and vendor/ in idle Conductor workspaces: the bulk of a workspace,
# and the only part that reinstalls. Branches, uncommitted work, and .context stay.
#
#   workspace-deps.sh [DAYS]            list candidates idle >= DAYS (default 7)
#   workspace-deps.sh [DAYS] --delete   delete them, re-checking each one first
#
# A workspace is idle when no file outside node_modules/, vendor/, and .git has
# changed in DAYS days. A deps dir qualifies only if git tracks nothing inside it.
# The workspace containing $PWD is always skipped.

set -uo pipefail
shopt -s nullglob

DAYS=7
DELETE=0
for arg in "$@"; do
  case "$arg" in
    --delete) DELETE=1 ;;
    *[!0-9]*) echo "usage: $0 [DAYS] [--delete]" >&2; exit 2 ;;
    *) DAYS=$arg ;;
  esac
done

ROOT=$(cd "${WORKSPACES_ROOT:-$HOME/conductor/workspaces}" && pwd -P) || exit 1
HERE=$(pwd -P)

# Newest mtime (epoch) of any file outside deps and .git.
last_activity() {
  find "$1" \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type f -print0 2>/dev/null |
    xargs -0 stat -f %m 2>/dev/null | sort -n | tail -1
}

# Echo the deps dirs in $1 that are safe to delete right now; nothing if the workspace isn't idle.
eligible() {
  local ws=$1 d
  case "$HERE/" in "$ws"/*) return ;; esac
  [ -n "$(find "$ws" \( -name node_modules -o -name vendor -o -name .git \) -prune -o -type f -mtime -"$DAYS" -print -quit 2>/dev/null)" ] && return
  for d in "$ws/node_modules" "$ws/vendor"; do
    [ -d "$d" ] && [ ! -L "$d" ] || continue
    [ -z "$(git -C "$ws" ls-files -- "$(basename "$d")" 2>/dev/null | head -1)" ] || continue
    echo "$d"
  done
}

total=0
printf '%s\t%s\t%s\n' size idle-since path
for ws in "$ROOT"/*/*; do
  [ -d "$ws" ] && [ ! -L "$ws" ] || continue
  ws=$(cd "$ws" && pwd -P)
  deps=$(eligible "$ws")
  [ -n "$deps" ] || continue
  since=$(date -r "$(last_activity "$ws")" +%Y-%m-%d 2>/dev/null || echo unknown)
  while IFS= read -r d; do
    kb=$(du -skx "$d" 2>/dev/null | cut -f1)
    total=$(( total + ${kb:-0} ))
    printf '%.1fG\t%s\t%s\n' "$(echo "${kb:-0} / 1048576" | bc -l)" "$since" "${d#"$ROOT"/}"
    if [ "$DELETE" -eq 1 ]; then
      # Re-verify immediately before deleting: another agent may have resumed this workspace.
      # Not grep -q: exiting early would SIGPIPE eligible and fail the pipeline.
      if eligible "$ws" | grep -xF "$d" >/dev/null; then rm -rf "$d"; else echo "  skipped: became active" >&2; fi
    fi
  done <<< "$deps"
done
printf 'total %.1fG %s\n' "$(echo "$total / 1048576" | bc -l)" "$([ "$DELETE" -eq 1 ] && echo deleted || echo reclaimable)"
