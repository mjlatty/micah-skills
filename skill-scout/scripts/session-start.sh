#!/usr/bin/env sh
# SessionStart hook for the skill-scout skill.
#
# Injects a short standing instruction so the model notices skill-shaped friction
# while it happens, instead of trying to recall it once the workspace is closing.
#
# Wire it up in ~/.claude/settings.json under hooks.SessionStart, guarded by an
# existence check so it stays silent on machines where the skill isn't installed:
#
#   sh -c '[ -x "$HOME/.claude/skills/skill-scout/scripts/session-start.sh" ] \
#          && "$HOME/.claude/skills/skill-scout/scripts/session-start.sh" || true'
#
# Emits SessionStart hook JSON on stdout. Keep the message to one line: it lands
# in the context of every session on this machine, and it has to earn that space.

set -u

LOG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skill-ideas.md"

# Unharvested entries. A count, not the entries themselves — the log is for the
# harvest to read, not for every session to carry.
pending=0
if [ -f "$LOG" ]; then
  pending=$(grep -c '^- \[ \]' "$LOG" 2>/dev/null) || pending=0
fi

case "$pending" in
  0) tally="Nothing pending." ;;
  1) tally="1 idea logged and unharvested." ;;
  *) tally="$pending ideas logged and unharvested." ;;
esac

# Single line, no quotes or backslashes, so it needs no JSON escaping.
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' \
  "[skill-scout] While you work, watch for friction worth turning into reusable knowledge: something that cost time you can name, that will recur in another repo or session, and whose remedy is a procedure rather than a one-off fix. Also watch for an existing skill misfiring, missing a step, or needing correction after it ran. When you see one, read the skill-scout skill and append a single line to $LOG, then carry on — do not announce it or interrupt the work. Zero to three entries a session; zero is normal. $tally Offer a harvest only if asked or if the user is clearly wrapping up or archiving the workspace."
