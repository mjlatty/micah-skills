---
name: plan-docs
description: Use when a plan should persist in the project — "write up a plan for this", "save this plan", "document the approach", or after plan mode approves work that will span more than one sitting. Also use to organize a plans folder, move plans between statuses, or answer "what plans are still open?" and "what am I in the middle of?" Writes plans into plans/{draft,ready,in-progress,done}/ and determines status from repository evidence rather than the plan's own claims.
---

# Plan docs

A plan that lives only in the conversation dies with it. A plan in a flat `plans/` folder survives,
but soon nothing distinguishes shipped work from active work or an abandoned idea.

This skill covers a plan document's whole life: whether it deserves a file, where it goes, what
shape it takes, and how it moves with the work. For capture, move, and sort requests, change the
repository instead of returning only a status report. For status questions, report what the
evidence shows without moving files unless the user asks.

## Does this plan earn a file?

An explicit request to write or save a plan settles the question: create the file. When deciding
whether to capture an approved plan proactively, test **whether it needs to survive the session**:

Write the file when the work spans more than one sitting, when someone (including future-you) will
execute it cold, when rejected alternatives may be questioned later, or when the plan itself is
being reviewed and agreed. Multi-PR efforts always qualify.

Keep short-lived planning in chat: work you'll finish in the next hour, mechanical refactors, small
bug fixes, and changes whose diff explains everything. A `plans/` folder full of plans nobody
reopens trains people to ignore it.

When it's borderline, ask — but ask once, with a recommendation, not as a standing checkpoint.

## Capturing an approved plan

The moment after plan mode approval is the best time to write the file: decisions are fresh,
alternatives remain in context, and none of it is in the repository. If the approved work qualifies
and has no unresolved decisions, write it to `plans/ready/`. If questions still block execution,
write it to `plans/draft/`. Find the plans folder below, then say in one line where the file landed.

Write what was decided, not a transcript of deciding it. The chat exploration is raw material; the
file is the conclusion plus the reasoning that survives.

## The layout

```
plans/
  draft/         # still being figured out — open questions, not agreed
  ready/         # scoped and agreed, nobody has started
  in-progress/   # code exists for it
  done/          # shipped, or deliberately abandoned
```

Use only these four status names. Don't invent `backlog/`, `archive/`, `wontfix/`, or per-quarter
splits; a fifth status makes the convention harder to trust.

**The folder path is the status.** If a file also carries a `status:` field in its frontmatter, the
folder wins; update the field to match rather than deleting it. Having two sources of truth is how a
plan ends up in `done/` claiming to be a draft.

**Filenames don't change when status does.** `git mv plans/draft/seo-plan.md plans/ready/` and
nothing else — no `DONE-` prefix, no date stamp appended. The path already says it, and renaming
churns history and breaks every link pointing at the file.

### Find the folder, don't assume it

Plans live at `plans/` in some repositories and `docs/plans/` in others. Look before writing:

```sh
find . -maxdepth 3 -type d -name plans -not -path "*/node_modules/*" -not -path "*/vendor/*"
```

If exactly one exists, use it, even when nested somewhere unexpected. If several exist, use the one
inside the project in scope; ask once when scope remains ambiguous. If none exists and you're
writing a plan, create its destination status directory under `plans/` at the repository root. If
the user asked to *sort*, report that no plans folder exists instead of scaffolding an empty one.

## Shape of a plan

Follow `references/plan-template.md`. When the effort involved real choices, the load-bearing
section is **decisions and what you rejected**. The diff cannot reconstruct that reasoning later.
A plan that omits genuine choices is a checklist wearing a plan's clothes; never manufacture an
alternative merely to fill the section.

**Split design from implementation when the detail would bury the reasoning.** Design holds the
shape and the trade-offs and stays short; implementation holds the step-by-step and gets long and
stale fast. Name them `<slug>-design.md` and `<slug>-implementation.md` so they sort together. A plan
under a few hundred lines doesn't need the split.

**Number chapters when one effort spans many independent surfaces** — `00-overview.md`,
`01-domain-model.md`, and so on, in a folder named for the effort. The `00` file is the map; without
it a numbered set is unreadable. Reach for this only at genuine scale (a whole product build), not
for a feature.

**An inventory of what exists is worth a section; a redundant status field is not.** Pointing to
the repository's metadata pipeline and JSON-LD helpers can prevent a second pattern. A
`status: in-progress` field inside a file sitting in `ready/` only rots.

## Assigning a status

Classify from evidence in the repo, in this order — the file's own claims about itself are the
weakest signal, since plans routinely say "next up" for months.

- **done** — the plan's result exists on the repository's default branch. Resolve that branch from
  local refs or project guidance; never assume it is `main`. Check for the routes, tables, classes,
  or config the plan names; check `git log <default-branch> --oneline -S'<distinctive symbol>'` and,
  when available, merged PRs (`gh pr list --state merged --search '<slug>'`). A plan the user says
  they've dropped is also done. Add a one-line abandonment note near the top so `done/` doesn't
  imply that it shipped.
- **in-progress** — some but not all of the work exists off the default branch, or an open PR shows
  active implementation. Use `git branch -a` and `gh pr list` as leads, then inspect the changes; a
  branch name alone is not proof.
- **ready** — nothing implemented, but the plan settles its own open questions and names concrete
  steps. Someone could pick it up tomorrow without another conversation.
- **draft** — anything else: open questions, TODOs, "decide whether", competing options left
  unchosen, or a plan that stops at motivation without a shape.

The interesting boundary is draft/ready. It depends on settled decisions, not length. A three-line
plan with the decision made is `ready`; a 400-line exploration with three unresolved forks is
`draft`.

## First-time sort

Sorting an existing flat folder is the common case. Read every file — enough to know what it claims
to build, not word by word — then:

1. Group files that form one plan. A numbered set or design/implementation pair moves as a unit.
   Splitting a set across statuses makes the overview unfindable.
2. Move everything with `git mv` so history follows the file. If `plans/` is gitignored or
   untracked, plain `mv`.
3. Fix inbound links. Search Markdown before and after with `rg -n "plans/" -g "*.md" .`, plus each
   moved file's old path and basename. READMEs, agent instructions, and other plans may link into
   this folder; a sort that breaks them is a net loss.
4. Report the moves as a short list grouped by destination. Don't paste the folder tree.

**Batch ambiguity.** If four files are genuinely unclear, ask about all four in one message with
your best guess for each. Don't ask file by file or stall the sort on one uncertain plan. Put it in
`draft/` and say so.

## Moving one plan

When the user says a plan is done, started, or agreed, move it and check its links. Confirm in one
line what moved and where.

Two moments worth catching without being asked, since they're the ones that go stale:

- A branch opens for a plan sitting in `ready/` → it's `in-progress/`.
- That PR merges → it's `done/`.

Mention it; don't move a file the user didn't ask about while you're doing something else.

## When reality diverges

Implementing from a plan and finding it wrong is normal and is the most useful thing that can happen
to a plan. Don't silently follow the plan off a cliff, and don't quietly rewrite history to match
what you built. Say what broke, then either revise the decision in place — noting what changed the
call — or add a short "what actually happened" note near the top. A `done/` plan that lies about the
shipped design is worse than no plan; the folder is the project's memory.

## Anti-patterns

- **Writing a file for every plan.** The folder's value is that everything in it matters. Chat is a
  fine place for a plan you'll execute immediately.
- **Transcribing the conversation.** The file is the conclusion and the reasoning, not the path you
  took to get there.
- **Steps without choices.** If a reader can't tell what you considered and rejected, they'll
  relitigate it — or worse, undo it.
- **Status only in frontmatter.** If the file says `status: done` but sits next to nine drafts, the
  folder never got the update and nobody trusts either signal. Move the file.
- **Deleting from `done/`.** It's the record of what the project decided and built. A plan that got
  abandoned belongs there too, labeled — the reasoning is the valuable part.
- **Sorting by date.** `2026-01-21-tagging.md` in `done/` is fine; a `2026-Q1/` folder is not. Dates
  answer "when", which git already knows. Status answers "can I pick this up", which it doesn't.
- **Re-sorting the whole folder when asked about one plan.** Answer the question, note anything
  obviously stale, and stop.
- **Trusting the plan's own tense.** "We will add a `tags` table" written eight months ago, next to
  a `tags` table that exists, means done. Check the code.
