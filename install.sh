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
# Flags: --target=claude,codex   --force   --help
#
# Honors $CLAUDE_CONFIG_DIR (default ~/.claude) and $CODEX_HOME (default ~/.codex).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE=symlink
ACTION=install
DRY=0
FORCE=0
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
    --target=*)   TARGETS="$(printf '%s' "${arg#*=}" | tr ',' ' ' | tr '[:upper:]' '[:lower:]')" ;;
    -*)           die "unknown flag: $arg (try --help)" ;;
    *)            SKILLS="$SKILLS $arg" ;;
  esac
done

# --- discovery --------------------------------------------------------------

# Every top-level directory holding a SKILL.md is a skill.
discover_skills() {
  for d in "$REPO"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    basename "$d"
  done
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

# Classify what currently sits at a target path:
#   absent | linked (symlink into this repo) | stale-copy (copy, identical)
#   | copy (copy, differs) | foreign (symlink elsewhere)
state_of() {
  target="$1"; src="$2"
  if [ -L "$target" ]; then
    resolved="$(cd "$(dirname "$target")" && cd "$(readlink "$target")" 2>/dev/null && pwd || true)"
    if [ "$resolved" = "$src" ]; then printf 'linked'; else printf 'foreign'; fi
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
    stale-copy) printf 'copy' ;;
    copy)       printf 'copy (edited)' ;;
    foreign)    printf 'foreign' ;;
    absent)     printf '-' ;;
  esac
}

color_of() {
  case "$1" in
    linked|stale-copy) printf '%s' "$GRN" ;;
    copy)              printf '%s' "$YEL" ;;
    foreign)           printf '%s' "$RED" ;;
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

  case "$state" in
    linked)
      if [ "$MODE" = symlink ]; then
        info "  $skill → $harness ${DIM}already linked${RST}"; return 0
      fi
      ;;
    stale-copy)
      # Byte-identical to the repo: a previous install, safe to replace.
      if [ "$MODE" = copy ]; then
        info "  $skill → $harness ${DIM}already current${RST}"; return 0
      fi
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
    info "  $skill → $harness ${GRN}linked${RST}"
  else
    run cp -R "$src" "$target"
    info "  $skill → $harness ${GRN}copied${RST}"
  fi
}

uninstall_one() {
  skill="$1"; harness="$2"
  src="$REPO/$skill"
  target="$(root_for "$harness")/$skill"
  state="$(state_of "$target" "$src")"

  case "$state" in
    absent) return 0 ;;
    linked|stale-copy)
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

all_skills="$(discover_skills)"
[ -n "$all_skills" ] || die "no skills found in $REPO (expected <name>/SKILL.md)"

# Validate requested skills.
if [ -n "${SKILLS// /}" ]; then
  selected=""
  for s in $SKILLS; do
    s="${s%/}"
    if printf '%s\n' "$all_skills" | grep -qx "$s"; then
      selected="$selected $s"
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

if [ "$ACTION" = install ] && [ "$MODE" = copy ]; then
  info "${DIM}copies do not track edits — re-run ./install.sh after changing a skill${RST}"
fi
