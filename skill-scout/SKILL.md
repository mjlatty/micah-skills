---
name: skill-scout
description: Use when the user wants to know what skills their recent work suggests, when a skill needs fixing, or when a session cost more than it should have — "any skill ideas", "what skills should I create", "harvest skill ideas", "what's in the notebook", "review my skill notes", "I'm about to archive this workspace", "that skill got it wrong", "note that for the pr-description skill", "that took way too many turns", "why did that burn so much context", "/skill-scout". Keeps one notebook per machine at ~/.claude/skill-ideas.md, appended to quietly all session (via a SessionStart hook) from every repo and workspace, so a harvest reads across months of work instead of one session's recollection. Logs three things: friction with no skill yet, installed skills that misfire, and work the agent did that it shouldn't have had to do at all — blind searching, oversized command output, facts re-derived every session. Routes each idea to what would actually fix it — a new skill, an edit to a skill already installed, a CLAUDE.md line, a memory, or a settings change.
---

# Skill scout

Sessions produce two things: the work, and the knowledge of what made the work harder than it needed
to be. The second one evaporates. By the time a workspace is archived, the twenty minutes lost to
rediscovering a build quirk has flattened into "that was a bit annoying" — not enough to act on, and
gone entirely by next week when it happens again in a different repo.

This skill catches those moments while they're still specific, in a log that outlives the workspace,
and turns the recurring ones into prompts that create the skill.

It watches in three directions. A skill that doesn't exist yet is the obvious catch. A skill that
*does* exist and quietly underperforms is more valuable, because it's already loaded into every
session and getting it wrong at scale. And the third, which nothing else catches: work that
*succeeded* and cost far more than it should have — fifteen tool calls to locate a file, a build
command that dumped four thousand lines to find one error, the same three facts re-derived from
scratch every session. Nobody flags that, because nothing went wrong. It just ran expensive.

All three go in the same log.

The third one is worth being explicit about, because the reflex when writing skills is to save the
*user* keystrokes. That's the smaller prize. A skill that turns a sentence into a slash command saves
one line of typing; a CLAUDE.md line that says where the routes live deletes ten tool calls from
every session in that repo, forever. Optimize for what the agent doesn't have to do.

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

The three kinds of entry have different bars, because they carry different risk. A new skill is a
speculation and needs evidence. An edit to a skill that already exists is a repair, and one clear
instance is enough. A waste entry needs no judgment call at all — the cost is countable, so count it.

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

### Wasted tokens

Log a waste entry when the session spent context on something a durable artifact would have deleted.
There's no recurrence test here — recurrence is the definition. Ask: *starting this task fresh
tomorrow, would I pay this again?* If yes, it's an entry.

What it looks like:

- **Blind search.** Twelve greps and four file reads to find where a thing lives, in a repo where
  it's always in the same place. The cost is the search, not the edit.
- **Output floods.** A command whose signal is three lines out of three thousand — a full suite run
  for one test, a verbose build, an unpaginated log, an installer narrating every package. The
  remedy is usually a flag or a pipe, which is one line of CLAUDE.md.
- **Re-derivation.** Facts rebuilt from scratch every session: which port, which env var, which of
  three migrate commands is the real one. Individually trivial, paid every time.
- **The retry ladder.** A command that fails the first two ways anyone would naturally try it. Each
  failure is a full turn plus an error dump.
- **Context that belonged to a subagent.** A broad exploration whose forty file excerpts then sat in
  the main context for the rest of the session, when only the conclusion was needed.
- **A skill that is itself the cost.** Six hundred lines where forty matter, or a description broad
  enough to load on unrelated work. Log it as `#skill:<name>/body` or `/description` — same path as a
  correctness fix, just costing tokens instead of accuracy.

Name the number: "12 tool calls before the first edit", "~1800 lines of build output for one type
error", "third session re-finding the seed command". An entry without a count is a complaint.

Then the rule that keeps this from backfiring: **the remedy costs tokens too, and they're not the
same tokens.** A description is loaded into every session on the machine, fired or not. A CLAUDE.md
line is loaded into every session in that repo. A skill body costs only when it triggers. Route by
where the cost lands — small high-frequency facts to CLAUDE.md, long procedures to a skill body, and
nothing into a description except the words that make it fire. Two hundred lines of skill to save
three tool calls is a net loss. Say so, and log nothing.

## Route it before you log it

Half the entries worth catching are not new skills. Deciding which is the whole point; a harvest that
proposes six skills where two were skills and four were CLAUDE.md lines has made the problem worse.

| What you hit | Where it goes |
|---|---|
| A multi-step procedure with gotchas, reusable across repos | **New skill** |
| A fact about *this* repo — build command, test runner, a directory's purpose | **CLAUDE.md** in that repo |
| The same blind search every session — "where does X live in this repo" | **CLAUDE.md**, as a layout map |
| A command that floods context when a scoped invocation exists | **CLAUDE.md**, prescribing the flags |
| A fact about the *user* — a preference, a constraint, a correction they gave you | **Memory** |
| A permission prompt you hit repeatedly | **Settings allowlist** (the `fewer-permission-prompts` skill does this) |
| Something that should happen automatically every time, without being asked | **Hook** in settings.json |
| A skill that already exists but misfired, missed a step, or got corrected | **An edit to that skill**, not a new one |
| A skill whose body or description costs more than it returns | **A trim of that skill** |
| A one-off bug, a thing you should have read first, a tool being slow | **Nothing** |

The existing-skill row is the one that pays, and it's the one that gets misfiled. A skill that exists and
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

Every entry is written to **two** files, the same line in both. Create either with a `# Skill ideas`
heading if it isn't there.

- **Global** — `~/.claude/skill-ideas.md`, honoring `$CLAUDE_CONFIG_DIR`. Outside any repo, because
  workspaces get deleted and this is the one artifact that has to survive that. This is the record.
- **Workspace** — `.context/skill-ideas.md` if a `.context/` directory exists at the repo root
  (Conductor makes one and gitignores it), otherwise `.claude/skill-ideas.md`. Only create the
  fallback if `.claude/` already exists and the path is gitignored; never add an untracked file to
  someone's repo root to hold notes.

The workspace copy exists so the notes are visible where the work happened — reviewable before the
branch closes, and readable by a harvest run inside that workspace without pulling in six other
repos' entries. It's a view, never a source of truth: it can be lost with the workspace and nothing
is gone, because the global file has the same lines.

Which means the failure mode to avoid is the reverse — writing *only* to the workspace copy. If one
write has to be skipped, skip the local one. And **harvest from the global file**, always. Clusters
are cross-repo by nature; a harvest scoped to one workspace sees one entry where there are four.

One line per entry, appended, never reordered:

```markdown
- [ ] `2026-08-19` `micah-skills` `#worktree-symlinks` — install.sh linked skills from the worktree, so all twelve dangled the moment the workspace closed; ~4 turns to diagnose because the symptom was "skill not found", not "bad link". Fix: link from the main checkout, warn when linking from a worktree.
- [ ] `2026-08-19` `acme-api` `#skill:pr-description/description` — didn't fire on "put this up for review"; had to be invoked by name after `gh pr create` was already drafted. Add that phrasing to the description.
- [ ] `2026-08-19` `acme-api` `#skill:pr-description/body` — checked a Risks box citing a test it never ran. Rule: run the cited test scoped to it, or leave the box open with `not run: <reason>`.
- [ ] `2026-08-19` `acme-api` `#waste/route-discovery` — 11 greps + 5 reads to find where API routes are registered; they're all in `bootstrap/app.php`. Third session paying this. Fix: layout map in CLAUDE.md, ~6 lines.
- [ ] `2026-08-19` `acme-api` `#waste/test-output` — `php artisan test` dumped ~2400 lines to surface one failure. Fix: CLAUDE.md line prescribing `--filter` plus `--compact` for single-test runs.
```

The fields carry weight, so fill them properly:

- **`#tag`** — a kebab slug for the *recurring capability*, not this incident. `#worktree-symlinks`,
  not `#install-sh-bug`. Reuse an existing tag from the file whenever one fits; clustering is what
  turns entries into evidence, and it only works if the same friction lands under the same tag.
  Grep the file for near-matches before minting a new one.
- **`#skill:<name>/<part>`** for entries about an installed skill, where `<part>` is `description`
  (when it fires) or `body` (what it does). The fixed prefix is what lets a harvest pull every note
  about one skill with a single grep, which is how you edit a skill once instead of five times.
- **`#waste/<slug>`** for tokens spent on work an artifact would have deleted, where the slug names
  the *thing being rediscovered or flooded* — `#waste/route-discovery`, `#waste/test-output` — not
  the tool that did it. `#waste/grep` clusters nothing. These carry a count in the line itself; a
  waste entry that doesn't say what it cost can't be weighed against the cost of the fix.
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

Work in cost-of-fix order: `#skill:` entries, then `#waste/`, then new skills. The first two are
scoped to a file that already exists and pay out in the next session; a new skill only starts paying
once it's written and starts firing. Report them in that order too — a harvest that opens with three
speculative proposals and buries "your PR skill has been checking boxes it didn't verify" has its
priorities backwards.

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

### Wasted tokens

Group `#waste/` entries by repo first, then by tag — most fixes land in one repo's CLAUDE.md, and
writing them as a single edit beats five separate one-liners.

1. **Total the counts.** Four entries saying "~15 tool calls" is a per-session tax with a number on
   it. That number is the entire argument for the fix, so carry it into the proposal.
2. **Weigh it against the remedy's own cost.** Lines added to CLAUDE.md are paid by every session in
   that repo whether or not they're needed. A six-line layout map that deletes a dozen tool calls is
   obviously worth it; forty lines of edge cases to save two is not. When it's close, say it's close.
3. **Prefer the fix that removes the work over the one that documents it.** A flag that makes the
   command quiet beats a CLAUDE.md line reminding you to pass the flag; a hook or an alias beats
   both. Documentation is the fallback, not the default.
4. **Read the repo's CLAUDE.md before proposing a line for it.** These accrete faster than skills do,
   and half of what gets proposed is already in there being ignored — which is a different problem,
   and worth reporting as one.
5. **Apply the one-liners if they say go.** Same as skill edits: small, local, no reason to hand back
   a prompt.

If a repo's waste entries mostly say "the agent couldn't find anything", the fix isn't more CLAUDE.md
lines. It's one layout map at the top. Propose that instead of five scattered facts.

### New skills

1. **Cluster by tag**, counting checked and unchecked entries alike. An idea that was harvested and
   never acted on should resurface; that's evidence it keeps hurting.
2. **Apply a threshold.** Propose a cluster when any of these hold: three or more entries; two or
   more in different repos; or one entry whose named cost was large and whose generality is obvious.
   Below that, leave it in the log and say how many are waiting — "four tags at one entry each,
   nothing conclusive yet" is a real and useful answer.
3. **Drop anything in `## Declined` or `## Shipped`.** A declined idea comes back only if the cluster
   has grown substantially since; a shipped one comes back only as a report that the fix didn't take
   (see "Close the loop"). Re-pitching a rejected or already-built idea every session is how a tool
   gets turned off.
4. **Re-route each survivor** through the table above. Things change: a CLAUDE.md line that recurs in
   five repos has become a skill, and a proposed skill that turned out to be one fact has not.
5. **Check off what you harvested** (`- [x]`) — including entries you routed away or judged
   inconclusive. A checked box means *a harvest has read this*, not *this is resolved*; resolution is
   recorded separately, under "Close the loop" below. Never delete; the file is the record of what
   the friction actually was.

### Label the benefit

Every proposal — new skill, skill edit, or CLAUDE.md line — states what it buys before it states what
it is. Without that, a list of six proposals reads as six equal asks, and the one that prevents wrong
output gets the same weight as the one that saves a paragraph of typing.

Use one primary label, in this order of precedence. If two apply, the earlier one is primary and the
other is secondary:

| Label | It buys | Test |
|---|---|---|
| **Correctness** | Output that was wrong is now right | Without it, something ships broken or a claim is false |
| **Safety** | A destructive or irreversible mistake doesn't happen | Without it, the failure mode is data loss, a bad deploy, a force-push |
| **Token efficiency** | Same outcome, materially less context burned | Without it, the agent does work it didn't need to do — and you can count it |
| **Consistency** | The same task produces the same shape of output every time | Without it, the result is fine but varies run to run |
| **Dev efficiency** | The user spends less time or typing | Without it, the agent does the same work; the human just asks for it the long way |

Pick honestly and pick one. Stacking all five on a proposal is what a proposal with no real benefit
looks like. And **dev efficiency alone is the weakest case in the table** — if that's the only label
that fits, the skill doesn't change what the agent does, and it should be a slash command or nothing
at all. Say that rather than dressing it up.

Quantify where the note supports it. "Token efficiency — ~15 tool calls per session in this repo" is
an argument. "Token efficiency — significant savings" is filler.

Then print, per surviving cluster, a block the user can paste into a fresh session:

````markdown
### `#worktree-symlinks` — 4 entries, 3 repos, since 2026-06-02

**Correctness** (secondary: dev efficiency) — silent breakage that costs ~20 minutes to diagnose
each time it lands, and it has landed four times.

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
the memory to write, the settings entry — with the same label on top. Those are usually one-liners
and you can just apply them if the user says go:

````markdown
### `#waste/route-discovery` + `#waste/test-output` — 5 entries, `acme-api`, since 2026-07-02

**Token efficiency** — ~15 tool calls and ~2400 lines of output per session, against 8 lines of
CLAUDE.md. Not a skill; there's no procedure here, just facts the agent keeps rebuilding.

Add to `acme-api/CLAUDE.md`:

```markdown
## Layout
- API routes register in `bootstrap/app.php`, not `routes/api.php`
- Jobs live in `app/Jobs`, their tests in `tests/Feature/Jobs`

## Commands
- Single test: `php artisan test --compact --filter=<name>` (bare `test` prints ~2400 lines)
```
````

## Close the loop

A harvest that ends at printed prompts leaves the log wrong. The entries that produced a skill are
still sitting there as open evidence, so next month they cluster again and pitch the thing you
already built. The harvest isn't done when the output prints; it's done when the log reflects what
happened.

So once the user has had a chance to act — usually their next message, sometimes the next session —
**ask which of the proposals they actually created.** One question, all clusters listed by tag, not
one question per cluster. If the answer is "none yet", leave everything untouched and don't ask
again this session.

For each tag they name:

1. **Annotate the entries in place** in the global file: append ` ✓ <what-was-created> <date>` to
   every line under that tag. Don't delete them — the entry is the evidence of what the friction was,
   and it needs to stay legible when someone asks in six months why the skill exists.
2. **Record the tag under `## Shipped`**, naming the artifact rather than just the fact:
   ``- `#worktree-symlinks` → `worktree-safe-install` skill, 2026-08-19``. For routed-away fixes name
   what was written — "→ CLAUDE.md layout map in `acme-api`".
3. **Mirror both edits into the workspace copy** if one exists. Skip silently if it doesn't.

Two files, one pass, no confirmation prompt per tag.

Later harvests then skip shipped tags when clustering — with the exception that makes this worth
doing: **an entry logged after a tag's shipped date is a signal, not evidence.** It means the fix
went in and the friction survived it. Surface those by name — "`#worktree-symlinks` shipped
2026-08-19 and has two entries since" — instead of folding them into a fresh proposal. The answer is
almost always to repair the skill that exists, and a harvest that proposes building a second one has
misread its own history.

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
- **Calling saved typing "efficiency".** A skill that turns a sentence into a slash command doesn't
  change a single thing the agent does. That's convenience, and it should be labeled as such and
  weighed accordingly — usually below the line.
- **A remedy that costs more than the waste.** Two hundred lines of skill, or a broad description
  loaded into every session on the machine, to save a handful of tool calls. Do the arithmetic in the
  proposal; if it doesn't clear, log nothing.
- **Waste entries with no number.** "Lots of searching" can't be weighed against the cost of a fix,
  so it will sit unharvested forever. Count the calls or don't log it.
- **Harvesting mid-session.** The log has one entry from today and nothing else in context. Wait.
- **Ending the harvest at the printout.** If nobody asks what got built, the log never learns, and
  the same four proposals come back forever until the user stops reading them.
- **Logging only to the workspace copy.** It dies with the workspace. The global file is the record;
  the local one is a convenience.
- **Interrupting work to log.** Append the line, keep going. Nobody asked for a retrospective.
- **Logging an episode instead of a rule.** "The changelog skill got the tone wrong" is unusable in
  four weeks. What was wrong, and what's the rule that would have prevented it?
- **Fixing a skill by appending to it.** Every correction bolted on as another caveat produces a
  skill nobody finishes reading, which fails in a new way. Edit the line that was wrong.
- **Promoting one project's taste into a global skill.** If the correction only holds in that repo,
  it belongs in that repo's CLAUDE.md. Skills that are right 60% of the time get distrusted and then
  ignored.
