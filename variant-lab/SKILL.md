---
name: variant-lab
description: Use when the user asks for variants, options, or alternatives of something so they can compare and pick — a page or part of one ("variant lab on the settings page", "give me options for the hero", "A/B some versions of the landing page"), an engineering approach ("try a few ways to build the sync job", "variants of this API", "prototype some schema options"), or a product decision ("variants on pricing", "options for onboarding", "a few takes on what v1 includes"), "more like the one I picked", or "what have my picks taught you". Picks the lab the question needs: a lab page for what's judged by eye, working implementations through shared tests for what's judged by running code, side-by-side writeups for what's judged by consequences. Each round is five whole variants of exactly the scope asked for, ranked with the recommendation first, with today's version one click away for comparison. Later rounds follow the pick and prune what lost. A taste log kept across labs shapes and ranks future variants.
---

# Variant lab

Help someone choose by putting real alternatives side by side, each one whole, each measured
against what exists today. Every round is five complete variants of the thing the user named,
ranked: A is your recommendation, and B through E follow in the order you'd rank them. Today's
version (the page that ships, the code on the branch, the product's current behavior) stays one
click away as **Current**. It sits outside the five and has no letter.

The shape is the same whatever is being varied. **Pick the kind of lab**, **build it** once, **fill
it** in rounds, then **promote** the pick. Throughout, a **taste log** records what each pick
showed, so the next lab starts from what the user has already chosen instead of from zero. Don't
skip ahead to writing variants: a variant you can't compare with its neighbors can't be judged, and
that comparison is the whole point.

## 1. Pick the kind of lab

Choose by how the user will judge the variants, not by the topic:

| They'll judge it by | Kind | The lab | Guide |
|---|---|---|---|
| Looking at it | Visual | A local-only page that renders the real page, with the scope switched whole from a one-row picker | [references/visual.md](references/visual.md) |
| Running and reading the code | Engineering | Each variant a working implementation in the real codebase, all run through one contract test and one compare script | [references/engineering.md](references/engineering.md) |
| Weighing what follows from it | Product | One document with every variant written to the same template, each as concrete as what a customer would meet | [references/product.md](references/product.md) |

"Variant lab on the settings page", "options for the hero" and "variants of the pricing page" are
visual. "A few ways to build the sync job", "variants of the webhook API" and "schema options for
teams" are engineering. "Variants on pricing", "how should onboarding work" and "what could v1
include" are product.

Some questions span kinds. Run the one the question is asking now: *what* to do is product, *how to
build it* is engineering, *how it looks* is visual. Then chain the next lab after a pick. A pricing
model picked in a product lab becomes a pricing page in a visual lab. A request for "pricing page
variants" with the tiers still undecided is a product question first; say so.

State the kind you chose, the scope (step 2) and the taste you're applying (step 2) in one line
before building, so the user can redirect cheaply. Then read that kind's guide. It covers building
the lab, the axes to vary, what a checked variant means, and promotion.

## 2. Read before writing

Learn what every variant must honor before writing one:

- **The scope.** The scope is exactly what the user named. "Variant lab on the settings page"
  means each variant is a complete settings page. "The settings page's billing section" means each
  variant is a complete billing section, and the rest of the page stays as it is. "The sync job"
  means each variant is a whole sync job: its schema, API and failure handling designed together.
  Don't split the scope into parts to be picked one at a time, and don't leave the user to assemble
  a result from pieces. Each variant has to work as a whole, with its layout, copy, hierarchy and
  interactions (or its data model, interface and failure paths) designed together.
- **Current.** What exists today at that scope. Read it closely, because every variant is compared
  with it. If nothing exists yet, there's no Current. The obvious first version, the one the user
  would get without asking for options, then competes as one of the five, ranked where it belongs.
- **The contract.** What every variant must keep true: the data the scope receives, the behavior
  callers rely on, the constraints the business runs under. A variant that breaks it can't be
  picked without hidden work.
- **The rules.** Project instructions (CLAUDE.md, AGENTS.md), its conventions, and the user's own
  constraints. If the project has an `icps/` folder, write for its top-ranked profile.
- **Their taste so far.** Read the taste log, if it exists: the General preferences for this kind,
  this project's section, the open questions, and how often your recommendation has been the pick.
  If there's no log, run `scripts/backup.sh restore` once to bring back a backup. Where the log
  lives and how to use it are in [references/taste.md](references/taste.md). The current
  request, the project's rules and the user's notes all outrank it.

**Separate parts only on request.** If the user asks by name to vary parts separately ("vary the
header and the form separately"), each named part gets its own row of five ranked variants, and
picks name the part (`header=B form=D`). Never split on your own initiative.

## 3. Round one: diverge

Write five whole variants, A through E, each a different *idea*, not a reworded or retuned Current
or a reworded neighbor. Each guide lists axes to split on. Round one exists to discover the user's
taste, so spread the five across those axes rather than polishing five takes on one idea. Where the
taste log already answers an axis, stay inside the answer and spend the variety on axes it doesn't.
Make one of the five a **challenger** that tests an open question or a thinly supported preference,
and say what it tests. Without one, the log only ever confirms itself.

**Rank them** once they're built and checked, not before. A is the one you'd ship, B the next, and
so on down to E. Rank by how well each serves the people it's for within the project's rules, not by
how novel it is, and by what the taste log says this user picks. The recommendation is a prediction
of their pick, and the log keeps its track record. Reletter the variants to match the ranking before
you present them, so the letter and the rank always agree.

**Parallelize** when building five whole variants is more than a few minutes' work: one worker per
variant, split the way the guide says. Tell each worker to touch only its own files. Brief every
worker with the same rules: the scope, the contract, the project's rules, what they must not touch,
the check to run, and "report a 1–2 sentence description and a short name for your variant". You
own the shared pieces (registry, switch, compare script, lab document) and the ranking, so workers
never edit the same file.

Every variant is checked by its writer before it's reported. Each guide defines what checked means
for its kind.

## 4. Present a round

- **A table per round, in ranked order:** rank, letter, short name, the idea in one line, and a
  one-line reason for its rank ("A: the only one that puts plan and usage on one screen without a
  tab"). Add Current as a row above A, unranked, for reference. Mark the challenger and what it
  tests. The user should be able to choose from the table and use the lab to confirm.
- The evidence the kind calls for: screenshots of all five, the compare table and call sites, or
  the concrete artifacts. Lead with A and say where the rest are.
- **Caveats before picking**, and only real ones. Check the highest-ranked variants hardest: a
  convincing variant built on something false is the most likely way for this process to ship a
  mistake. The usual falsehoods are a feature that doesn't exist, a number with no source or one
  that contradicts another, a test that passes because it skips the hard case, and a library API
  recalled from memory. Each guide lists more.
- Ask for one pick: a single letter (`Pick: C`), or a mix with a note saying what to take from each
  (`Pick: B+D` — "B's layout, D's copy"). The visual lab's picker produces this line. The other labs
  end with a `Pick:` line to fill in.

## 5. Later rounds: converge on their taste

When a pick comes back, read it as evidence, the passed-over variants included. A note outranks
your inference, and a mix is the most specific evidence of all.

1. **Write the inferred taste down** in a sentence or two, naming both what won and what lost
   ("concrete artifacts with real numbers, problem-first, split layouts; passed on slogans and
   centered statements", or "keep it in the database, no new dependencies; passed on the queue and
   the event log"). Say it to the user. That sentence is the brief for every worker, and it lets
   the user correct the reading before more is built on it.
2. **Record the round in the taste log**: append it to `picks.md`, update the profile, and commit
   back it up with `scripts/backup.sh sync`, as [references/taste.md](references/taste.md)
   describes. If the user corrected your taste sentence or stated a preference outright, record it
   as stated. Mention the update in one line.
3. **Prune what lost.** Do this at the start of every round after the first. Delete every variant
   that wasn't picked or mixed in, along with its registry entry, branch, or section. Keep Current,
   and keep the picked letters as the reference for the next round, one click away like Current
   and outside the five. Losers left in the lab crowd it and pull new variants back toward ideas the
   user already turned down. Their screenshots, numbers and write-ups stay in `.context/lab/` as the
   record.
4. **Write five new whole variants**, each a distinct take *within* the inferred direction,
   specified up front in one line each so the five don't converge. Where the user mixed, one of
   them is the blend the note describes, and the others try other ways of combining the same
   variants.
5. **Use fresh letters every round**, so a letter in an old screenshot, table or `Pick:` line
   always means the same variant: round two is F–J, round three K–O, and so on (after Y, continue
   with AA–AE). The order still follows rank, so the round's first letter is your recommendation.
6. **Rank again** and present the round the same way, with the recommendation first. The lab opens
   on it by default.
7. Prune and repeat until the user picks a single letter and says it's done. A mix isn't a final
   pick. It means another round.

## 6. Promote

Once there's a final pick, it replaces Current and the lab comes down. Each guide lists the
specifics. In every kind:

- Put the winner where the real thing lives, and finish whatever the variant left as a stub.
- Delete the lab: the losing variants, the registry or switch, the lab's branches, and anything
  that existed only to serve it.
- Keep what earned its place, such as a contract test that pins the decision.
- Record the decision and the rejected variants with the reason each lost, wherever the project
  keeps decisions (the `plan-docs` skill if it keeps plans).
- Record the final pick in the taste log, then re-read this lab's rounds there and check the profile
  still says what they show. A preference inferred in round one doesn't always survive to the end.
  Then back it up with `scripts/backup.sh push`.
- Run the tests that cover what changed.

Lab output that isn't code (screenshots, compare results, product documents, worktrees) goes under
`.context/lab/<topic>/`, or another gitignored scratch directory if the project has no `.context/`.

## Asked what the lab has learned

"What's my variant taste", "what have my picks taught you", "forget that I like tabs": read or edit
the taste log as [references/taste.md](references/taste.md) describes. No lab needs to be running.
