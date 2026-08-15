#!/usr/bin/env bash
# Install the skills in this repo into every agent harness on this machine.
#
# Claude Code and Codex share an on-disk format: one directory per skill,
# containing SKILL.md with `name` and `description` frontmatter. Only the
# install root differs, so installing is just linking the same directory into
# each harness's skills folder.
#
#   ./install.sh                    install every skill into every detected harness
#   ./install.sh code-tour          install just these skills
#   ./install.sh --status           show what is installed where
#   ./install.sh --copy             copy instead of symlink
#   ./install.sh --uninstall        remove skills this repo owns
#   ./install.sh --dry-run          print the plan, change nothing
#
# Flags: --target=claude,codex   --here   --force   --help
#
# Run it from anywhere in the repo, including a `git worktree` checkout — those
# directories are disposable, and a symlink into one dies with it. Links are made
# from the main checkout by default so they survive; --here overrides that when
# you want a work-in-progress skill live in every harness.
#
# Honors $CLAUDE_CONFIG_DIR (default ~/.claude) and $CODEX_HOME (default ~/.codex).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

MODE=symlink
ACTION=install
DRY=0
FORCE=0
HERE=0
TARGETS=""
SKILLS=""

# --- output -----------------------------------------------------------------

if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; RST=$'\033[0m'
else
  B=""; DIM=""; GRN=""; YEL=""; RED=""; RST=""
fi

info() { printf '%s\n' "$*"; }
warn() { printf '%s!%s %s\n' "$YEL" "$RST" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$RED" "$RST" "$*" >&2; exit 1; }
run()  { if [ "$DRY" -eq 1 ]; then printf '%s  would: %s%s\n' "$DIM" "$*" "$RST"; else "$@"; fi; }

# Print the header comment block (everything after the shebang, up to the first
# non-comment line) as help text.
usage() { awk 'NR==1 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "$0"; exit 0; }

# --- args -------------------------------------------------------------------

for arg in "$@"; do
  case "$arg" in
    --help|-h)    usage ;;
    --copy)       MODE=copy ;;
    --symlink)    MODE=symlink ;;
    --status|--list) ACTION=status ;;
    --uninstall)  ACTION=uninstall ;;
    --dry-run|-n) DRY=1 ;;
    --force|-f)   FORCE=1 ;;
    --here)       HERE=1 ;;
    --target=*)   TARGETS="$(printf '%s' "${arg#*=}" | tr ',' ' ' | tr '[:upper:]' '[:lower:]')" ;;
    -*)           die "unknown flag: $arg (try --help)" ;;
    *)            SKILLS="$SKILLS $arg" ;;
  esac
done

# --- discovery --------------------------------------------------------------

# Every top-level directory holding a SKILL.md is a skill.
discover_skills() {
  for d in "${1:-$REPO}"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    basename "$d"
  done
}

# Physical path, with every symlink along the way resolved — both sides of a
# path comparison must be resolved or /tmp vs /private/tmp reads as a mismatch.
phys() { cd "$1" 2>/dev/null && pwd -P; }

# Membership in a newline-separated list. Written as a here-string rather than
# `list | grep -qx`, which under `pipefail` fails at random: grep exits at the
# first match and the writer upstream dies of SIGPIPE, which becomes the
# pipeline's status. It only looks correct when the match is the last line.
has() { grep -qx -- "$1" <<<"$2"; }

# The shared .git directory behind a checkout. Every worktree of a repo reports
# the same one, which is what makes them recognizable as siblings.
git_common() {
  d="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" || return 1
  case "$d" in
    /*) printf '%s' "$d" ;;
    *)  phys "$1/$d" ;;   # the main checkout reports a bare ".git"
  esac
}

# The checkout that outlives the others: `git worktree list` always prints the
# main working tree first. Worktree directories get deleted (Conductor throws
# them away when a workspace closes); the main one is where links should point.
main_checkout() {
  git -C "$REPO" worktree list --porcelain 2>/dev/null \
    | awk 'NR==1 && $1=="worktree" { print $2; exit }'
}

REPO_GIT_COMMON="$(git_common "$REPO" || true)"

# Is this path part of some checkout of *this* repo — another worktree, an old
# clone — rather than an unrelated directory that happens to sit at the target?
same_repo() {
  [ -n "$REPO_GIT_COMMON" ] || return 1
  [ "$(git_common "$1" 2>/dev/null || true)" = "$REPO_GIT_COMMON" ]
}

# Where each harness keeps user-level skills.
root_for() {
  case "$1" in
    claude) printf '%s/skills' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ;;
    codex)  printf '%s/skills' "${CODEX_HOME:-$HOME/.codex}" ;;
    *)      return 1 ;;
  esac
}

# A harness counts as present if its config dir exists.
harness_present() {
  case "$1" in
    claude) [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] ;;
    codex)  [ -d "${CODEX_HOME:-$HOME/.codex}" ] ;;
    *)      return 1 ;;
  esac
}

# --- state ------------------------------------------------------------------

# Classify what currently sits at a target path. The first four states are ours
# to replace freely; the last two might hold work this repo didn't put there.
#
#   absent      nothing here
#   linked      symlink to this exact checkout — already done
#   broken      dangling symlink; whatever it pointed at is gone
#   moved       symlink into another checkout of this repo (a deleted-tomorrow
#               worktree, an old clone) — same skill, wrong source
#   stale-copy  a copy, byte-identical to the repo: a previous --copy install
#   copy        a copy that has been edited away from the repo
#   foreign     a symlink or file belonging to something else entirely
state_of() {
  target="$1"; src="$2"
  if [ -L "$target" ]; then
    if [ ! -e "$target" ]; then printf 'broken'; return; fi
    resolved="$(phys "$target" || true)"
    if [ "$resolved" = "$(phys "$src")" ]; then printf 'linked'
    elif [ -n "$resolved" ] && same_repo "$resolved"; then printf 'moved'
    else printf 'foreign'; fi
  elif [ -d "$target" ]; then
    if diff -rq "$target" "$src" >/dev/null 2>&1; then printf 'stale-copy'; else printf 'copy'; fi
  elif [ -e "$target" ]; then
    printf 'foreign'
  else
    printf 'absent'
  fi
}

# Plain-text label, so callers can pad by its real width.
label_of() {
  case "$1" in
    linked)     printf 'linked' ;;
    broken)     printf 'broken' ;;
    moved)      printf 'stale link' ;;
    stale-copy) printf 'copy' ;;
    copy)       printf 'copy (edited)' ;;
    foreign)    printf 'foreign' ;;
    absent)     printf '-' ;;
  esac
}

color_of() {
  case "$1" in
    linked|stale-copy) printf '%s' "$GRN" ;;
    copy|moved)        printf '%s' "$YEL" ;;
    broken|foreign)    printf '%s' "$RED" ;;
    absent)            printf '%s' "$DIM" ;;
  esac
}

# --- actions ----------------------------------------------------------------

install_one() {
  skill="$1"; harness="$2"
  src="$REPO/$skill"
  root="$(root_for "$harness")"
  target="$root/$skill"
  state="$(state_of "$target" "$src")"

  note=""
  case "$state" in
    linked)
      if [ "$MODE" = symlink ]; then
        info "  $skill → $harness ${DIM}already linked${RST}"; return 0
      fi
      ;;
    stale-copy)
      if [ "$MODE" = copy ]; then
        info "  $skill → $harness ${DIM}already current${RST}"; return 0
      fi
      ;;
    broken|moved)
      # Ours, just pointed at a checkout that moved or vanished. Repointing it
      # is the whole reason someone re-runs this script; say where it pointed.
      note=" ${DIM}(was $(basename "$(dirname "$(readlink "$target")")"))${RST}"
      ;;
    copy|foreign)
      # Diverged from the repo, or points somewhere else. Could hold real work.
      if [ "$FORCE" -ne 1 ]; then
        warn "$skill → $harness: existing $state at $target differs from this repo; left alone (--force to replace)"
        return 0
      fi
      ;;
  esac

  [ -d "$root" ] || run mkdir -p "$root"
  [ "$state" = absent ] || run rm -rf "$target"

  if [ "$MODE" = symlink ]; then
    run ln -s "$src" "$target"
    info "  $skill → $harness ${GRN}linked${RST}$note"
  else
    run cp -R "$src" "$target"
    info "  $skill → $harness ${GRN}copied${RST}$note"
  fi
}

# A symlink this repo planted for a skill that no longer exists here — renamed,
# removed, or never merged. Nothing else will ever clean these up.
prune_orphans() {
  harness="$1"; keep="$2"
  root="$(root_for "$harness")"
  [ -d "$root" ] || return 0
  for target in "$root"/*; do
    [ -L "$target" ] || continue
    name="$(basename "$target")"
    has "$name" "$keep" && continue
    if [ ! -e "$target" ]; then
      # Dangling, and we can no longer prove whose it was. Say so, touch nothing.
      warn "$name → $harness: dangling symlink to $(readlink "$target") — not a skill in this repo; remove it by hand if it was"
    elif same_repo "$(phys "$target")"; then
      run rm -f "$target"
      info "  $name → $harness ${YEL}pruned${RST} ${DIM}(no longer in this repo)${RST}"
    fi
  done
}

uninstall_one() {
  skill="$1"; harness="$2"
  src="$REPO/$skill"
  target="$(root_for "$harness")/$skill"
  state="$(state_of "$target" "$src")"

  case "$state" in
    absent) return 0 ;;
    linked|broken|moved|stale-copy)
      run rm -rf "$target"
      info "  $skill → $harness ${GRN}removed${RST}"
      ;;
    copy|foreign)
      if [ "$FORCE" -eq 1 ]; then
        run rm -rf "$target"
        info "  $skill → $harness ${YEL}removed ($state)${RST}"
      else
        warn "$skill → $harness: $state at $target is not owned by this repo; left alone (--force to remove)"
      fi
      ;;
  esac
}

# --- main -------------------------------------------------------------------

# Prefer the main checkout over a worktree, so the links outlive this directory.
INVOKED_FROM="$REPO"
unmerged=""
if [ "$HERE" -eq 0 ]; then
  m="$(main_checkout || true)"
  if [ -n "$m" ] && [ -d "$m" ] && [ "$(phys "$m")" != "$REPO" ] && [ -n "$(discover_skills "$m")" ]; then
    REPO="$(phys "$m")"
    info "${DIM}source: $REPO ${RST}${DIM}(main checkout — $INVOKED_FROM is a worktree; --here to link it instead)${RST}"
    # A skill that exists only here hasn't been merged yet; linking the main
    # checkout would silently skip it, so name it rather than swallow it.
    main_skills="$(discover_skills "$REPO")"
    for s in $(discover_skills "$INVOKED_FROM"); do
      has "$s" "$main_skills" || unmerged="$unmerged $s"
    done
  fi
elif [ -f "$REPO/.git" ]; then
  # --git-dir as a *file* means a worktree. Deliberate here, but worth saying:
  # the links die with the directory.
  warn "linking from a worktree — these links break when $REPO is deleted; re-run without --here afterwards"
fi

all_skills="$(discover_skills)"
[ -n "$all_skills" ] || die "no skills found in $REPO (expected <name>/SKILL.md)"

[ -n "${unmerged// /}" ] && warn "not in the main checkout yet, skipped:${unmerged} — merge to master, or re-run with --here"

# Validate requested skills.
if [ -n "${SKILLS// /}" ]; then
  selected=""
  for s in $SKILLS; do
    s="${s%/}"
    if has "$s" "$all_skills"; then
      selected="$selected $s"
    elif has "$s" "$(discover_skills "$INVOKED_FROM")"; then
      die "$s exists here but not in the main checkout at $REPO
merge it to master, or re-run with --here to link this worktree"
    else
      die "no such skill: $s
available: $(printf '%s' "$all_skills" | tr '\n' ' ')"
    fi
  done
else
  selected="$all_skills"
fi

# Resolve targets.
if [ -n "$TARGETS" ]; then
  for t in $TARGETS; do root_for "$t" >/dev/null || die "unknown target: $t (expected claude or codex)"; done
  chosen="$TARGETS"
else
  chosen=""
  for t in claude codex; do
    harness_present "$t" && chosen="$chosen $t"
  done
  [ -n "${chosen// /}" ] || die "no supported harness found (looked for ~/.claude and ~/.codex)
use --target=claude,codex to force"
fi
chosen="$(printf '%s' "$chosen" | xargs)"   # normalize spacing for display and iteration

if [ "$ACTION" = status ]; then
  printf '%s%s%s\n' "$B" "$REPO" "$RST"
  printf '%-24s' "skill"
  for t in $chosen; do printf '%-18s' "$t"; done
  printf '\n'
  for s in $selected; do
    printf '%-24s' "$s"
    for t in $chosen; do
      st="$(state_of "$(root_for "$t")/$s" "$REPO/$s")"
      lbl="$(label_of "$st")"
      # Pad by the label's real width; the color codes are zero-width on screen
      # but would otherwise be counted by printf's %-18s.
      printf '%s%s%s%*s' "$(color_of "$st")" "$lbl" "$RST" $(( 18 - ${#lbl} )) ""
    done
    printf '\n'
  done
  exit 0
fi

[ "$DRY" -eq 1 ] && info "${DIM}dry run — nothing will change${RST}"
info "${B}${ACTION}${RST} ${DIM}(${MODE})${RST} into: ${chosen}"

for s in $selected; do
  for t in $chosen; do
    if [ "$ACTION" = uninstall ]; then uninstall_one "$s" "$t"; else install_one "$s" "$t"; fi
  done
done

# Only a full install knows the complete skill list, so only it can tell an
# orphan from a skill this run simply wasn't asked to touch.
if [ "$ACTION" = install ] && [ -z "${SKILLS// /}" ]; then
  keep="$all_skills$(printf '\n%s' $unmerged)"   # an unmerged skill is not an orphan
  for t in $chosen; do prune_orphans "$t" "$keep"; done
fi

if [ "$ACTION" = install ] && [ "$MODE" = copy ]; then
  info "${DIM}copies do not track edits — re-run ./install.sh after changing a skill${RST}"
fi
