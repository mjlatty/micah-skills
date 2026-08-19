# Audit transcripts

Mine recent top-level Claude Code JSONL sessions for evidence the watcher may have missed:

```sh
python3 scripts/audit.py --sessions 10
```

The read-only audit reports:

- at least eight search/read calls before the first edit;
- tool results of at least 1,000 lines;
- correction-like user messages;
- repeated Bash commands with a failed attempt;
- logged costs that exceed transcript measurements by more than 20%.

Override thresholds with `--search-chain`, `--line-threshold`, or `--retry-threshold`. Use
`--all-projects` for a machine-wide audit and `--json` for structured output.

Treat findings as candidates, not conclusions. Read the named transcript when context is needed,
route each signal through [watch.md](watch.md), and log only qualifying reusable evidence. Prefer the
audited count over an in-flight estimate. Correction matching is heuristic; capture a general rule,
not private conversation or full command output.

SessionStart records the exact transcript ID in new notebook entries, allowing later audits to check
their claimed greps, reads, tool calls, and output lines. Older unlinked entries remain unchecked.
