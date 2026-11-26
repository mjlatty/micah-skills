#!/usr/bin/env bash
# Classify every Conductor workspace by whether its work is safe elsewhere,
# with sizes per group. Read-only: archive the safe ones in the Conductor app.
#
#   workspaces.sh        all workspaces under ~/conductor/workspaces
#
# Safe = the PR for this exact commit merged, nothing uncommitted, nothing
# unpushed. PRs here are squash-merged, so git can't tell merged branches from
# unmerged ones; GitHub can. One gh call per repo, not per workspace.

set -uo pipefail
shopt -s nullglob
. "$(dirname "$0")/lib.sh"

ROOT=$(cd "${WORKSPACES_ROOT:-$HOME/conductor/workspaces}" && pwd -P) || exit 1
HERE=$(pwd -P)
rows=$(mktemp)
sizes=$(mktemp)
trap 'rm -f "$rows" "$sizes"' EXIT

wss=()
for ws in "$ROOT"/*/*; do
  [ -d "$ws" ] && [ ! -L "$ws" ] && [ -e "$ws/.git" ] && wss+=("$ws")
done
[ ${#wss[@]} -gt 0 ] || { echo "no workspaces under $ROOT"; exit 0; }
printf '%s\0' "${wss[@]}" | xargs -0 -P 8 -n 1 du -skx 2>/dev/null > "$sizes"

for repo in "$ROOT"/*/; do
  prs=""
  for ws in "$repo"*; do
    [ -d "$ws" ] && [ ! -L "$ws" ] && [ -e "$ws/.git" ] || continue
    if [ -z "$prs" ]; then
      # "state<TAB>branch<TAB>head sha" for every PR in this repo; "-" if gh failed.
      prs=$(cd "$ws" && gh pr list --state all --limit 1000 --json state,headRefName,headRefOid \
              -q '.[] | [.state, .headRefName, .headRefOid] | @tsv' 2>/dev/null) || prs="-"
      [ -n "$prs" ] || prs="none"
    fi

    branch=$(git -C "$ws" branch --show-current 2>/dev/null)
    head=$(git -C "$ws" rev-parse HEAD 2>/dev/null)
    dirty=$(git -C "$ws" status --porcelain 2>/dev/null | grep -c .)
    unpushed=$(git -C "$ws" rev-list --count HEAD --not --remotes 2>/dev/null || echo "?")
    pr=$(printf '%s\n' "$prs" | awk -F'\t' -v b="$branch" -v h="$head" '
      $2 == b && $3 == h { exact = $1 } $2 == b { any = $1 }
      END { if (exact) print exact; else if (any) print any "-older"; else print "none" }')
    [ "$prs" = "-" ] && pr="unknown"

    if ! git -C "$ws" rev-parse --git-dir >/dev/null 2>&1; then
      group="5 broken: .git points at a missing repo (ask)"
    elif [ "$pr" = MERGED ] && [ "$dirty" = 0 ] && [ "$unpushed" = 0 ]; then
      group="1 safe: merged, clean, pushed"
    elif [ "$pr" = none ] && [ "$dirty" = 0 ] && [ "$unpushed" = 0 ] &&
         def=$(git -C "$ws" symbolic-ref -q --short refs/remotes/origin/HEAD) &&
         git -C "$ws" merge-base --is-ancestor HEAD "$def" 2>/dev/null; then
      group="2 empty: no commits, no changes, no PR (ask)"
    elif [ "${pr%-older}" = MERGED ]; then
      group="3 merged, but has work since (keep)"
    else
      group="4 unmerged or in progress (keep)"
    fi

    note="pr=$pr dirty=$dirty unpushed=$unpushed"
    case "$HERE/" in "$ws"/*) note="$note THIS WORKSPACE" ;; esac
    kb=$(awk -F'\t' -v p="$ws" '$2 == p { print $1 }' "$sizes")
    printf '%s\t%s\t%s\t%s\t%s\n' "$group" "${kb:-0}" "${ws#"$ROOT"/}" "$branch" "$note" >> "$rows"
  done
done

# Rows arrive sorted by group, then size; print each group under a header with its total.
sort -t$'\t' -k1,1 -k2,2rn "$rows" | awk -F'\t' '
  function g(k) { return sprintf("%.1fG", k / 1048576) }
  function flush() { if (cur != "") printf "== %s: %d workspaces, %s ==\n%s\n", substr(cur, 3), n, g(t), body }
  $1 != cur { flush(); cur = $1; n = 0; t = 0; body = "" }
  { body = body sprintf("  %7s  %-36s %-40s %s\n", g($2), $3, $4, $5); n++; t += $2 }
  END { flush() }'
