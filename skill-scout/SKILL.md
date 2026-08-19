---
name: skill-scout
description: Use when work suggests a reusable skill, an installed skill misfires, or a session wastes tokens on repeatable discovery or noisy commands. Also use for "any skill ideas", "what's in the notebook", "note this for the X skill", "audit recent sessions", "that skill got it wrong", "why did that burn so much context", workspace wrap-up, or `/skill-scout audit|harvest`. Logs and audits evidence, then routes it to a skill, skill edit, CLAUDE.md, memory, settings, hook, or nothing.
---

# Skill scout

Keep durable evidence of recurring friction, skill failures, and avoidable token cost. Use one global
notebook so patterns survive deleted workspaces and span repositories.

## Choose one mode

- **Watch/log:** For explicit logging or a doubtful candidate, read
  [references/watch.md](references/watch.md). Hook-originated hits already contain the one-call log
  command; run it without loading the reference, then continue silently.
- **Harvest:** Read [references/harvest.md](references/harvest.md). Analyze the global notebook when
  the user asks for ideas, review, or workspace wrap-up.
- **Audit:** Read [references/audit.md](references/audit.md). Mine recent Claude JSONL transcripts for
  measured signals when asked to audit or when harvesting.
- **Set up the hook:** Read [references/setup.md](references/setup.md) only when installing or
  configuring automatic watching.

Do not harvest merely because you logged an entry. Watching is continuous; harvesting is requested
or happens at workspace wrap-up.

## Shared rules

- Run relative script paths from this skill's directory, not the user's project.
- Optimize for work the agent can avoid, not user keystrokes saved.
- Match the remedy to the problem: procedures go in skills; repo facts in `CLAUDE.md`; user
  preferences in memory; recurring permissions in settings; automatic behavior in hooks; existing
  skill failures in that skill. One-off bugs and agent mistakes produce no note.
- Count costs. A token-efficiency claim without tool-call, turn, or output-line evidence is too vague.
- Account for the remedy's context cost. Descriptions load globally, `CLAUDE.md` loads per repo, and
  skill bodies load only when triggered.
