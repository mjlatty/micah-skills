---
name: plan-docs
description: Use when a plan should become a file in the project rather than living only in the conversation — "write up a plan for this", "save this plan", "document the approach", or right after a plan mode plan is approved and the work spans more than one sitting. Also use to organize or re-sort a project's plans folder and to move a plan between statuses — "sort my plans", "organize plans/", "move this plan to done", "mark that plan in progress", "what plans are still open", "what am I in the middle of". Writes plans into plans/{draft,ready,in-progress,done}/ and classifies status by evidence from the repo, not by what the plan claims about itself.
---

# Plan docs

A plan that lives only in the conversation dies with the conversation. A plan that lives in a flat
`plans/` folder survives, but within a quarter nothing distinguishes the one you shipped from the one
you're mid-way through from the half-thought you abandoned.

This skill covers the whole life of a plan document: whether it deserves a file, where that file
goes, what shape it takes, and how it moves as the work moves. The deliverable is files in the
project repo — not a status report in chat.

## Does this plan earn a file?

Most planning shouldn't be written down. The test is **whether it needs to survive the session**:

Write the file when the work spans more than one sitting, when someone (including future-you) will
execute it cold, when you rejected real alternatives whose reasoning will be questioned later, or
when the plan is the thing being reviewed and agreed. Multi-PR efforts always qualify.

Skip the file for work you'll finish in the next hour, mechanical refactors, bug fixes, and anything
where the diff explains itself. A `plans/` folder full of plans nobody reopened is worse than no
folder — it trains you to ignore the folder.

When it's borderline, ask — but ask once, with a recommendation, not as a standing checkpoint.

## Capturing an approved plan

The moment after plan mode is approved is the highest-value time to write the file: the decisions
are fresh, the alternatives are still in context, and none of it is in the repo yet. If the approved
work spans more than one sitting, write it to `plans/ready/` without asking where the folder is —
find it (below) and say in one line where it landed.

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

Four folders, those names, always. Don't invent `backlog/`, `archive/`, `wontfix/`, or a per-quarter
split — a fifth folder is where the convention starts rotting.

**The folder path is the status.** If a file also carries a `status:` field in its frontmatter, the
folder wins; update the field to match rather than deleting it. Two sources of truth is how a plan
ends up in `done/` claiming to be a draft.

**Filenames don't change when status does.** `git mv plans/draft/seo-plan.md plans/ready/` and
nothing else — no `DONE-` prefix, no date stamp appended. The path already says it, and renaming
churns history and breaks every link pointing at the file.

### Find the folder, don't assume it

Plans live at `plans/` in some repos and `docs/plans/` in others. Look before writing:

```sh
find . -maxdepth 3 -type d -name plans -not -path "*/node_modules/*" -not -path "*/vendor/*"
```

If there's exactly one, use it — including when it's nested somewhere unexpected. If there's none,
create `plans/draft/` at the repo root. If you're being asked to *sort* and there's no folder, say
so rather than scaffolding an empty one.

## Shape of a plan

Follow `references/plan-template.md`. The load-bearing section is **decisions and what you rejected**
— that's the part that can't be reconstructed from the diff later, and the part you'll reread when
someone asks "why isn't this a queue?" eight months from now. A plan that lists steps but not
choices is a checklist wearing a plan's clothes.

**Split design from implementation when the detail would bury the reasoning.** Design holds the
shape and the trade-offs and stays short; implementation holds the step-by-step and gets long and
stale fast. Name them `<slug>-design.md` and `<slug>-implementation.md` so they sort together. A plan
under a few hundred lines doesn't need the split.

**Number chapters when one effort spans many independent surfaces** — `00-overview.md`,
`01-domain-model.md`, and so on, in a folder named for the effort. The `00` file is the map; without
it a numbered set is unreadable. Reach for this only at genuine scale (a whole product build), not
for a feature.

**An inventory of what already exists is worth a section; a status field is not.** "Here are the
metadata pipeline and JSON-LD helpers already in the repo — reuse them, don't add a second pattern"
saves the reader real time. `status: in-progress` inside a file sitting in `ready/` just rots.

## Assigning a status

Classify from evidence in the repo, in this order — the file's own claims about itself are the
weakest signal, since plans routinely say "next up" for months.

- **done** — the thing the plan describes exists in `main`. Check for the routes, tables, classes,
  or config the plan names; check `git log --oneline -S'<distinctive symbol>'` and merged PRs
  (`gh pr list --state merged --search '<slug>'`). A plan the user says they've dropped is also
  done — note the abandonment in one line at the top of the file so `done/` doesn't imply shipped.
- **in-progress** — some but not all of it exists, or there's a live branch or open PR for it.
  `git branch -a` and `gh pr list` are the tell.
- **ready** — nothing implemented, but the plan settles its own open questions and names concrete
  steps. Someone could pick it up tomorrow without another conversation.
- **draft** — anything else: open questions, TODOs, "decide whether", competing options left
  unchosen, or a plan that stops at motivation without a shape.

The interesting boundary is draft/ready, and it's about decidedness, not length. A three-line plan
with the decision made is `ready`; a 400-line exploration with three unresolved forks is `draft`.

## First-time sort

Sorting an existing flat folder is the common case. Read every file — enough to know what it claims
to build, not word by word — then:

1. Group files that are one plan. A numbered set, or a design/implementation pair, moves as a unit.
   Splitting a set across statuses makes the overview unfindable.
2. Move everything with `git mv` so history follows the file. If `plans/` is gitignored or
   untracked, plain `mv`.
3. Fix inbound links. `grep -rn "plans/" --include="*.md" .` before and after — READMEs, CLAUDE.md,
   and other plans link into this folder, and a sort that silently breaks them is a net loss.
4. Report the moves as a short list grouped by destination. Don't paste the folder tree.

**Batch the ambiguity.** If four files are genuinely unclear, ask about all four in one message with
your best guess for each, then move on. Don't ask file by file, and don't stall the whole sort on
one uncertain plan — put it in `draft/` and say you did.

## Moving one plan

When the user says a plan is done, started, or agreed, just move it — that's a one-line change plus a
link check. Confirm in one line: what moved, from where to where.

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
