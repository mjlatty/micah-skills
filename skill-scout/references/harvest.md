# Harvest

Audit recent sessions, then read the compact notebook index instead of the full history:

```sh
python3 scripts/audit.py --sessions 10
python3 scripts/notebook.py summary
```

Use `notebook.py show <tag>` to load full evidence only for a candidate. Work and report in this order:

1. existing-skill repairs;
2. wasted-token fixes;
3. new-skill candidates.

Checked means “reviewed in a harvest,” not resolved. `## Shipped` and `## Declined` record outcomes.

## Existing skills

Group `#skill:` entries by skill name so each skill gets one edit.

1. Read the current skill; an old note may already be fixed.
2. Merge trigger fixes into one concise description rewrite using the user's phrasing.
3. Convert output corrections into imperative body rules at the point of use. Replace conflicting guidance.
4. Route project-specific taste to that repo's `CLAUDE.md` or memory.
5. If several unrelated corrections target one large body, propose splitting or trimming it.
6. Show the concrete diff and apply it only when the user says to proceed.

## Wasted tokens

Group `#waste/` by repo, then tag.

1. Total the recorded tool calls, turns, or output lines.
2. Compare that recurring tax with the remedy's own context cost.
3. Prefer removing work—a scoped command, quiet flag, hook, script, or alias—over documenting it.
4. Read the repo's current `CLAUDE.md` first. If discovery dominates, prefer one short layout map.
5. Show the concrete edit and apply it only when the user says to proceed.

## New skills

1. Group all entries by tag, checked or unchecked; `summary` includes the archive.
2. Exclude tags in `## Shipped` or `## Declined`, except as described under **Close the loop**.
3. Propose a cluster at three entries, two repos, or one unusually costly and clearly general entry.
   Report sub-threshold counts without proposing them.
4. Route every survivor again; evidence may now point to a skill, repo instruction, memory, settings,
   or hook.
5. Mark every reviewed entry, including inconclusive and rerouted entries:

   ```sh
   python3 scripts/notebook.py review '#tag' '#other-tag'
   ```

   This archives checked entries when the active notebook exceeds 100 of them. Never delete evidence.

Create a skill only with explicit approval. Put real trigger wording in its description and the
procedure and gotchas—not incidents—in its imperative body. Follow the destination repo's conventions.

## Present proposals

Lead with what each proposal buys. Choose one primary label using this priority:

| Label | Use when |
|---|---|
| **Correctness** | Otherwise output ships broken or a claim is false |
| **Safety** | Otherwise a destructive or irreversible mistake can occur |
| **Token efficiency** | The same result currently burns measurable avoidable context |
| **Consistency** | Correct output varies unnecessarily between runs |
| **Dev efficiency** | Only the user's time or typing improves |

Use earlier labels as primary. Quantify benefits; do not stack labels to inflate a weak proposal.

Report each proposal's tag, entry/repo count, oldest date, benefit, evidence, destination, and change.
For a new skill, include a pasteable prompt with:

- proposed name and location;
- real trigger phrases;
- problem and measured cost;
- procedure, commands, ordering, and gotchas carried from the evidence.

For rerouted clusters, print the exact edit instead of a skill prompt.

## Close the loop

After the user acts, ask once which tags they implemented. If none, leave the notebook unchanged and
do not ask again that session. Record outcomes deterministically:

```sh
python3 scripts/notebook.py ship '#tag' --artifact '<what was created>'
python3 scripts/notebook.py decline '#tag' --reason '<user reason>'
```

These update matching entries, state sections, archives, and the workspace copy under one lock.
Reconsider declined work only after materially stronger evidence.

An entry after its tag's shipped date is a regression. Repair that artifact; do not propose a duplicate.
