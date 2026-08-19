# Watch and log

Log zero to three entries per session; zero is normal. Use the rules below when the hook or current
work reveals a candidate.

## Qualification

Log a **new-skill candidate** only when all three hold:

1. The event had a named cost: turns, retries, a reverted path, or similar.
2. It will recur in another repo, branch, or future session.
3. The remedy is a procedure with steps, ordering, gotchas, or judgment—not a fact.

A bug in the current codebase is still a bug, not a skill.

Log an **existing-skill issue** on one clear sighting. Include:

- missed or false triggers; preserve the user's exact trigger wording;
- user corrections to its output; capture the general rule, not the episode;
- wrong ordering, avoidable lookups, stale APIs, moved paths, or obsolete workarounds;
- a body or description whose token cost exceeds its value.

Do not log a changed user preference or your own failure to follow a correct skill.

Log **waste** when a durable artifact would prevent paying the same context cost tomorrow. Examples
include blind layout searches, noisy commands, facts repeatedly re-derived, predictable retry
ladders, exploration that belonged in a subagent, and bloated skills. State the cost: tool calls,
turns, output lines, or repeated sessions. Reject remedies that cost more context than they save.

## Route before logging

| Problem | Destination |
|---|---|
| Cross-repo procedure with gotchas | New skill |
| Existing skill missed, misfired, or gave wrong guidance | Edit that skill |
| Existing skill costs more than it saves | Trim that skill |
| Repo layout, command, or other stable fact | Repo `CLAUDE.md` |
| User preference or constraint | Memory |
| Repeated permission prompt | Settings allowlist |
| Behavior that should run automatically | Hook |
| One-off bug, slow tool, or agent mistake | Nothing |

Before logging a new skill, check the installed skill list. If one already covers the task, use
`#skill:<name>/description` for a trigger failure or `#skill:<name>/body` for an execution failure.

## Write the entry

Use the tags emitted by the SessionStart hook when one fits. Otherwise inspect the compact index:

```sh
python3 scripts/notebook.py summary
```

Log with one call from the skill directory:

```sh
scripts/log.sh '#waste/route-discovery — 11 greps and 5 reads to locate API registration; third session paying this. Fix: add a short layout map to CLAUDE.md.'
```

Use `#skill:<name>/description|body`, `#waste/<capability>`, or a reusable `#kebab-case` capability.
Name what was rediscovered, not the tool (`route-discovery`, not `grep`). State the event, measured
cost, and remedy without secrets or pasted output.

The helper adds date, repo, transcript ID, global and safe workspace destinations, locking,
deduplication, redaction, and the required heading. It honors `SKILL_SCOUT_LOG` or
`SKILL_SCOUT_HOME`; otherwise it uses `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skill-ideas.md`.

Log silently and resume the user's task.
