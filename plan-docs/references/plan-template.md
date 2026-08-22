# Templates for the plans folder

Three shapes: the standard plan, the design/implementation split for large efforts, and the `00`
overview that makes a numbered set navigable. Start with the standard one — the others are what it
grows into, not alternatives to choose between up front.

Sections marked *(optional)* may be dropped when they'd be empty. **Decisions** never may: a plan
without it is a checklist.

Note what's absent from the frontmatter: there is **no `status:` field**. Status is the folder the
file sits in. See the skill for why.

---

## Standard plan — `plans/<status>/<slug>.md`

```markdown
---
title: <human-readable, one line>
created: YYYY-MM-DD
updated: YYYY-MM-DD   # only once it's been meaningfully revised
---

# <Title>

## Goal

<One paragraph: what is true after this ships that isn't true now, stated as an
outcome rather than a task list. If you can't say what changes for a user or an
operator, the plan isn't ready to write.>

## Context *(optional)*

<What already exists that this builds on or must not duplicate — the pipeline,
the helper, the table, the pattern, with file paths. This is the section that
saves the implementer an hour of archaeology, and it's the reason a plan beats
a chat message. Skip only when building on nothing.>

## Decisions

<The load-bearing section. One entry per real choice:

**<The decision.>** <Why this one.> Rejected: <the alternative> because
<reason>.

Only decisions that were genuinely open belong here — if there was never a
second option, it's not a decision, it's a step. Two or three real ones beat a
dozen manufactured ones. This is what you reread when someone asks "why isn't
this a queue?" long after the diff stopped explaining itself.>

## Approach

<The shape of the work: the components involved and how they fit. Enough that a
reader can picture the end state without reading the steps. Diagrams, schemas,
and interface sketches live here.>

## Steps

<Ordered, each one a coherent unit of work — ideally a PR. Say what "done"
looks like for each, especially where it isn't obvious. Don't decompose to the
level of individual edits; the implementer knows how to type.>

## Open questions *(optional)*

<Anything genuinely unsettled, with who or what resolves it. A plan with
entries here belongs in draft/ — that's the definition. Delete the section when
the last one is answered, and move the file.>

## Out of scope *(optional)*

<What this deliberately doesn't do, and where it's deferred to. Prevents scope
creep during implementation and pre-answers the first review question.>

## Divergences *(added during implementation)*

<Append-only. When reality contradicts the plan, log it here with the date and
what changed the call. This is what keeps a done/ plan honest about what
actually shipped.>
```

---

## Design / implementation split — large efforts

Two files, same slug, so they sort together:

- **`<slug>-design.md`** — Goal, Context, Decisions, Approach, Open questions, Out of scope. Stays
  short and stays true; this is the document that's still worth reading a year later.
- **`<slug>-implementation.md`** — Steps in full detail: schemas, signatures, migration order, test
  plan, edge cases. Expected to get long and to go stale the moment the work starts. Link back to
  the design file at the top.

Split when implementation detail would bury the reasoning — not by line count, but by whether
someone looking for *why* has to wade through *how*. Below a few hundred lines, don't.

---

## Numbered set — one effort, many surfaces

Only at genuine scale (a whole product build, not a feature). A folder named for the effort, files
numbered so they read in order:

```
plans/<status>/<effort-slug>/
  00-overview.md
  01-domain-model.md
  02-pipeline-engine.md
  ...
```

`00-overview.md` is the map and is not optional — without it the set is unreadable:

```markdown
---
title: <Effort> — overview
created: YYYY-MM-DD
---

# <Effort> — overview

## Goal

<What the whole effort delivers.>

## The chapters

| # | Chapter | Covers | Depends on |
|---|---|---|---|
| 01 | [Domain model](01-domain-model.md) | <one line> | — |
| 02 | [Pipeline engine](02-pipeline-engine.md) | <one line> | 01 |

## Cross-cutting decisions

<Decisions that bind every chapter — the datastore, the tenancy model, the
error contract. Chapter-local decisions stay in their chapter.>

## Sequencing

<What has to land before what, and what can run in parallel. The dependency
column says the shape; this says the order and why.>
```

The whole numbered set shares one status and moves between folders as a unit.
