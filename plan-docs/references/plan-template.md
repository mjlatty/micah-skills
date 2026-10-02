# Templates for the plans folder

Use one of three shapes: the standard plan, a design/implementation split for large efforts, or a
numbered set with a `00` overview. Start with the standard plan. Let scale force the other shapes.

Drop *(optional)* sections when empty. Keep **Decisions** whenever the effort involved real choices;
never manufacture alternatives to fill it.

The frontmatter has no `status:` field. The file's folder records its status.

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

<One paragraph stating the outcome: what becomes true for a user or operator
after this ships.>

## Context *(optional)*

<What this builds on or must not duplicate: pipelines, helpers, tables, and
patterns, with file paths. Give the implementer a map of the relevant code.>

## Decisions *(optional when no alternatives existed)*

<The load-bearing section. One entry per real choice:

**<The decision.>** <Why this one.> Rejected: <the alternative> because
<reason>.

Include only choices with real alternatives. Put predetermined work in Steps.
Two or three real decisions beat a dozen manufactured ones. Preserve the
reasoning the diff will not explain later.>

## Approach

<The components involved and how they fit. Give readers a clear picture of the
end state before the steps. Put diagrams, schemas, and interface sketches here.>

## Steps

<Order coherent units of work, ideally one per PR. Define completion where it
may be unclear. Leave individual edits to the implementer.>

## Open questions *(optional)*

<Anything unsettled, plus who or what will resolve it. Entries here put the
plan in draft/. Delete the section and move the file after resolving them.>

## Out of scope *(optional)*

<What this deliberately excludes and where it is deferred. Set the boundary
before implementation and review.>

## Divergences *(optional; add during implementation)*

<Append-only. When reality contradicts the plan, log the date, the change, and
what prompted it. Keep the done/ plan accurate to what shipped.>
```

---

## Design / implementation split — large efforts

Two files, same slug, so they sort together:

- **`<slug>-design.md`** — Goal, Context, Decisions, Approach, Open questions, Out of scope. Keep it
  short and accurate; this is the document worth reading a year later.
- **`<slug>-implementation.md`** — Steps in full detail: schemas, signatures, migration order, test
  plan, edge cases. Expected to get long and to go stale the moment the work starts. Link back to
  the design file at the top.

Split when implementation detail buries the reasoning. Use whether *how* obscures *why*, not a hard
line count. Keep plans under a few hundred lines together.

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
