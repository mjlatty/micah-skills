---
name: skill-scout
description: Use when the user is wrapping up, closing, or archiving a workspace and wants to know what skills this session suggests, or when an existing skill needs fixing — "any skill ideas from this session", "what skills should I create", "harvest skill ideas", "I'm about to archive this workspace", "that skill got it wrong", "note that for the pr-description skill", "/skill-scout". Also runs quietly all session (via a SessionStart hook) to log both new-skill friction and existing-skill misfires, so the harvest has evidence instead of recollection. Routes each idea to what would actually fix it — a new skill, an edit to a skill already installed, a CLAUDE.md line, a memory, or a settings change.
---

# Skill scout

Sessions produce two things: the work, and the knowledge of what made the work harder than it needed
to be. The second one evaporates. By the time a workspace is archived, the twenty minutes lost to
rediscovering a build quirk has flattened into "that was a bit annoying" — not enough to act on, and
gone entirely by next week when it happens again in a different repo.

This skill catches those moments while they're still specific, in a log that outlives the workspace,
and turns the recurring ones into prompts that create the skill.

It watches in both directions. A skill that doesn't exist yet is the obvious catch; a skill that
*does* exist and quietly underperforms is the more valuable one, because it's already loaded into
every session and getting it wrong at scale. Both go in the same log.

Two modes, and they are different jobs. **Watching** runs all session and writes one line at a time.
**Harvesting** runs once, on request, and reads across every session ever logged. Don't harvest
mid-session; the value of the log is that it accumulates.

## Setup

Watching only works if something starts it. A `SessionStart` hook in
`~/.claude/settings.json` injects the instruction into every session:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c '[ -x \"$HOME/.claude/skills/skill-scout/scripts/session-start.sh\" ] && \"$HOME/.claude/skills/skill-scout/scripts/session-start.sh\" || true'"
          }
        ]
      }
    ]
  }
}
```

The existence check matters: the hook fires in every session on the machine, including ones where
this skill isn't installed, and a hook that errors on a missing path is noise forever. `compact` is
in the matcher because a compaction is exactly when the instruction would otherwise fall out of
context — the back half of a long session is where the best friction lives.

If the hook isn't installed, the skill still works when invoked by hand; it just starts the harvest
from a thinner log.

## The bar

Most friction is not skill-shaped. The failure mode of this skill is a log full of shrugs, which is
worse than an empty one — it buries the two real entries and trains you to skim.

The two kinds of entry have different bars, because they carry different risk. A new skill is a
speculation and needs evidence; an edit to a skill that already exists is a repair, and one clear
instance is enough.

### New skills

A new-skill entry qualifies when all three hold:

- **It cost something you could name.** Turns burned, a wrong path taken and reverted, a command run
  four times with different flags. "That was fiddly" is not a cost.
- **It will recur.** In another repo, another branch, or next month here. A bug in this codebase
  recurs by definition and is still not a skill — the fix is the fix.
- **The remedy is procedure, not a fact.** A sequence, an ordering constraint, a set of gotchas, a
  judgment call about when to do X instead of Y. If the remedy is a single true statement, it's a
  memory or a CLAUDE.md line, and it should be logged as that.

Expect zero to three entries in a session. If you're logging more, the bar has slipped. If a session
genuinely produced nothing, log nothing — an empty session is the common case and needs no comment.

### Existing skills

Log these on a single sighting. You already know which file to edit, so there's no threshold to
clear and nothing to accumulate evidence for — waiting for a second occurrence just means the skill
misfires twice. What counts:

- **It didn't fire when it should have.** The user asked for exactly what the skill does, in words
  the description doesn't cover. Record their phrasing verbatim; that phrasing *is* the fix.
- **It fired when it shouldn't have.** Usually a description that overreaches, or two skills whose
  triggers overlap and neither wins reliably.
- **It ran and the user corrected the output.** The most useful entry in the whole log. A correction
  is a rule the skill was missing, stated by the person who knows. Capture the rule, not the episode:
  "PR bodies should name the ticket in the title, not the body", not "Micah edited the title".
- **It made you do avoidable work.** Steps in the wrong order, a lookup it could have told you, a
  check it sends you to run that always comes back the same.
- **It's stale.** An API it references has changed, a path it names has moved, a workaround it
  prescribes is no longer needed. These decay silently and nothing else catches them.

Two things that look like this and aren't: the skill was right and the user changed their mind (a
preference — that's memory), and the skill was right and you didn't follow it (log nothing; that's
just this session).

## Route it before you log it

Half the entries worth catching are not new skills. Deciding which is the whole point; a harvest that
proposes six skills where two were skills and four were CLAUDE.md lines has made the problem worse.

| What you hit | Where it goes |
|---|---|
| A multi-step procedure with gotchas, reusable across repos | **New skill** |
| A fact about *this* repo — build command, test runner, a directory's purpose | **CLAUDE.md** in that repo |
| A fact about the *user* — a preference, a constraint, a correction they gave you | **Memory** |
| A permission prompt you hit repeatedly | **Settings allowlist** (the `fewer-permission-prompts` skill does this) |
| Something that should happen automatically every time, without being asked | **Hook** in settings.json |
| A skill that already exists but misfired, missed a step, or got corrected | **An edit to that skill**, not a new one |
| A one-off bug, a thing you should have read first, a tool being slow | **Nothing** |

That sixth row is the one that pays, and it's the one that gets misfiled. A skill that exists and
doesn't trigger is invisible, and from the inside it looks exactly like a skill that's missing — so
the reflex is to propose building the thing you already have. **Check the installed skill list before
logging any new-skill candidate.** If something covers it, the entry is an edit to that skill, and it
should name the file.

Within that row, be specific about which part is wrong, because they're different edits with
different blast radii. A **description** fix changes when the skill fires and affects every session
on the machine. A **body** fix changes what it does once triggered. "Doesn't fire" and "fires and
does the wrong thing" are never the same repair, and conflating them produces a description stuffed
with instructions nobody reads.

## The log

`~/.claude/skill-ideas.md` — outside any repo, because workspaces get deleted and this is the one
artifact that has to survive that. Honor `$CLAUDE_CONFIG_DIR` if it's set. Create the file with a
`# Skill ideas` heading if it isn't there.

One line per entry, appended, never reordered:

```markdown
- [ ] `2026-08-19` `micah-skills` `#worktree-symlinks` — install.sh linked skills from the worktree, so all twelve dangled the moment the workspace closed; ~4 turns to diagnose because the symptom was "skill not found", not "bad link". Fix: link from the main checkout, warn when linking from a worktree.
- [ ] `2026-08-19` `acme-api` `#skill:pr-description/description` — didn't fire on "put this up for review"; had to be invoked by name after `gh pr create` was already drafted. Add that phrasing to the description.
- [ ] `2026-08-19` `acme-api` `#skill:pr-description/body` — checked a Risks box citing a test it never ran. Rule: run the cited test scoped to it, or leave the box open with `not run: <reason>`.
```

The fields carry weight, so fill them properly:

- **`#tag`** — a kebab slug for the *recurring capability*, not this incident. `#worktree-symlinks`,
  not `#install-sh-bug`. Reuse an existing tag from the file whenever one fits; clustering is what
  turns entries into evidence, and it only works if the same friction lands under the same tag.
  Grep the file for near-matches before minting a new one.
- **`#skill:<name>/<part>`** for entries about an installed skill, where `<part>` is `description`
  (when it fires) or `body` (what it does). The fixed prefix is what lets a harvest pull every note
  about one skill with a single grep, which is how you edit a skill once instead of five times.
- **Repo** — the directory name, so the harvest can tell "hit this in three repos" from "hit this
  three times in one afternoon". Those mean different things.
- **The line itself** — what went wrong, what it cost, and what would have prevented it. Written so
  it's legible in six months with none of this session in context. The reflex to write "the usual
  Docker thing" is the one to fight.

Log without announcing it. Append the line, continue the work, mention it in passing at most. Stopping
the session to discuss a note about efficiency is its own kind of inefficiency.

## Harvest

Triggered on request, usually as the workspace is about to close. Read the whole file, not just this
session's entries — a lone entry means nothing and three across two repos means a skill.

Do the `#skill:` entries first. They're cheap, they're already scoped to a file, and they improve
something running in every session today — whereas a new skill only starts paying once it's written
and starts firing. Report them first too; a harvest that opens with three speculative proposals and
buries "your PR skill has been checking boxes it didn't verify" has its priorities backwards.

### Existing skills

Group by skill name, not by tag, so each skill is edited once with everything known about it:

1. **Read the current file** before proposing anything. Entries are weeks old; the gap may already
   be closed, and a fix applied twice is worse than not applied.
2. **Merge the description fixes into one rewrite.** Fold every missed trigger phrase in as the user
   said it. Descriptions are matched as a whole, so five separate additions is one edit.
3. **Turn each correction into a rule in the body**, phrased as instruction rather than anecdote,
   and put it where someone following the skill would actually hit it. If it contradicts a line
   that's already there, replace that line — don't stack a caveat on top of it and let the skill
   argue with itself.
4. **Say when a fix isn't the skill's fault.** Some corrections are the user's taste on that project,
   and belong in that repo's CLAUDE.md or in memory. Encoding one project's preference into a global
   skill is how a skill starts being wrong everywhere else.
5. **Show the diff and apply it if they say go.** These are small and local; unlike new skills,
   there's no reason to hand back a prompt.

Watch for the case where the notes are really saying the skill is too big — three unrelated body
corrections against one skill usually means it's doing two jobs. Say that instead of patching it.

### New skills

1. **Cluster by tag**, counting checked and unchecked entries alike. An idea that was harvested and
   never acted on should resurface; that's evidence it keeps hurting.
2. **Apply a threshold.** Propose a cluster when any of these hold: three or more entries; two or
   more in different repos; or one entry whose named cost was large and whose generality is obvious.
   Below that, leave it in the log and say how many are waiting — "four tags at one entry each,
   nothing conclusive yet" is a real and useful answer.
3. **Drop anything in `## Declined`** unless the cluster has grown substantially since it was
   declined. Re-pitching a rejected idea every session is how a tool gets turned off.
4. **Re-route each survivor** through the table above. Things change: a CLAUDE.md line that recurs in
   five repos has become a skill, and a proposed skill that turned out to be one fact has not.
5. **Check off what you harvested** (`- [x]`) — including entries you routed away or judged
   inconclusive. Never delete; the file is the record of what the friction actually was.

Then print, per surviving cluster, a block the user can paste into a fresh session:

````markdown
### `#worktree-symlinks` — 4 entries, 3 repos, since 2026-06-02

> Create a skill called `worktree-safe-install` in ~/conductor/repos/micah-skills.
>
> Trigger it on: installing or linking dotfiles, skills, or config from a repo that might be a git
> worktree checkout — "install my skills", "link this config", "set up X on this machine".
>
> The problem: a symlink into a worktree dies when the worktree is deleted, and the symptom is a
> missing feature rather than a broken link, so it costs 20+ minutes to diagnose every time. Hit in
> micah-skills (2026-06-02, 2026-08-19), dotfiles (2026-07-14), and nvim-config (2026-08-03).
>
> It needs to know: `git worktree list --porcelain` prints the main checkout first; a `.git` *file*
> rather than a directory means you're in a worktree; and the install should link from the main
> checkout by default with an explicit flag to override.
````

The last paragraph is what makes the prompt worth more than the tag name. Carry the specifics out of
the log entries and into the prompt — the commands, the ordering, the gotcha. Without them the
prompt produces a skill that restates the problem; with them it produces one that already knows the
answer.

For clusters that routed away from "new skill", print the concrete edit instead — the CLAUDE.md line,
the memory to write, the settings entry. Those are usually one-liners and you can just apply them if
the user says go.

## Declined

When the user rejects a proposal, append its tag to a `## Declined` section with a date and their
reason in their words. That's what keeps the harvest from becoming a recurring pitch for the same
four ideas. If new entries later push a declined cluster well past its old evidence, it can come back
once — say explicitly that it was declined before and what changed.

## Writing the skill

Only if the user says go. The harvest's output is prompts, not skills; creating one is a separate
act, and a skill written on the way out of a session by someone who has stopped paying attention is
a skill that will misfire for months.

When you do write it, the description is the whole trigger — the harness loads descriptions up front
and the model matches against them, so it has to contain the phrasings the user would actually type,
lifted from the log entries. The body should say what to *do*, in order, with the gotchas that
cost the time, and should be honest about when the skill doesn't apply. Match the conventions of the
repo you're writing into.

## Anti-patterns

- **Logging the bug you just fixed.** The fix is in the diff. A skill that says "watch out for this
  bug" is a comment in the wrong file.
- **Logging your own missteps as friction.** "Should have read the config before editing" isn't a
  skill; it's a thing you already know. Log what the *environment* made hard, not what you did badly.
- **One-session skills.** A single annoying afternoon reliably feels like a pattern. That's what the
  threshold is for — trust it over the recency.
- **Proposing a skill that already exists.** Check the installed list first, every harvest. The
  duplicate always wins the trigger race for a while and then neither fires reliably.
- **Vague tags.** `#tooling`, `#setup`, `#annoying`. A tag that could hold anything clusters nothing.
- **Harvesting mid-session.** The log has one entry from today and nothing else in context. Wait.
- **Interrupting work to log.** Append the line, keep going. Nobody asked for a retrospective.
- **Logging an episode instead of a rule.** "The changelog skill got the tone wrong" is unusable in
  four weeks. What was wrong, and what's the rule that would have prevented it?
- **Fixing a skill by appending to it.** Every correction bolted on as another caveat produces a
  skill nobody finishes reading, which fails in a new way. Edit the line that was wrong.
- **Promoting one project's taste into a global skill.** If the correction only holds in that repo,
  it belongs in that repo's CLAUDE.md. Skills that are right 60% of the time get distrusted and then
  ignored.
