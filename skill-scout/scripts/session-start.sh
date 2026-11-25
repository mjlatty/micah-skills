#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Back up what every skill has learned (this notebook, teach-me's log, variant-lab's taste) to the
# skills repo's skill-data branch: a local commit when something changed, a push at most weekly.
# Detached and silent, so it never delays the session or leaks into the hook's context.
ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$ROOT" ] && [ -x "$ROOT/bin/skill-data" ]; then
  (nohup "$ROOT/bin/skill-data" sync --quiet >/dev/null 2>&1 &)
fi

exec python3 "$SCRIPT_DIR/notebook.py" hook-context
