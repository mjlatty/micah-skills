---
name: variant-lab
description: Use when the user wants to see several design or copy alternatives for a page's sections and choose between them — "try a few variants of each section", "give me options for the hero", "A/B some versions of the landing page", "show me alternatives and let me pick", "more like the ones I picked". Builds a local-only lab page that renders the real page with every section swappable from a picker, fills it with deliberately different variants (in parallel when there are many), screenshots them, then runs a second round in the direction the user's picks reveal and promotes the winners.
---

# Variant lab

Help someone choose a page's design by putting real alternatives in front of them, on the real
page, with real data. Variant A of every section is always the section that ships today, so
every alternative is judged against the baseline in place rather than in isolation or in a mockup.

The job has three phases. **Build the lab** once, **fill it** in rounds, then **promote** the picks.
Don't skip ahead to writing variants: a variant you can't see beside its neighbors can't be judged,
and that comparison is the whole point.

## 1. Read the page first

Before anything else, learn what you're varying:

- **The sections and their order.** List them by the role each plays (hero, problem, proof,
  pricing, close), not by file name. Each section becomes a row in the picker.
- **The data contract.** What variables each section receives, where its numbers come from, and
  which numbers are checked against a fixture. Variants must use the same sources. A hardcoded
  figure in a mockup becomes a wrong figure in production once it's picked.
- **The rules.** The project's copy rules (CLAUDE.md, AGENTS.md, a copy record), the design
  language (type scale, surfaces, accent color, motion attributes) and any band rhythm (such as
  alternating dark and light sections). Variants keep their section's surface so the rhythm survives
  any combination of picks. If the project has an `icps/` folder, copy variants are written for its
  top-ranked profile. Use the `copywriting` skill for headline and body copy.
- **What can't be duplicated.** Element ids that inline scripts bind to, singleton widgets, and
  any script that finds sections by id and swaps them (localization, live updates). These decide
  how variants are allowed to differ. See "Traps" below.

## 2. Build the lab

A local-only route that renders the page's real layout and data, with each section chosen by the
query string: `/landing-lab?hero=b&how=c`. Ingredients:

- **A registry**, ordered like the page: `section => letter => [view, short label]`. Letter `a` maps
  to the live partial and never changes. Unknown or missing letters fall back to the default pick.
- **Shared view data.** Extract the live page's data-building into one method both routes call, so
  the lab can't drift from what production renders. This is the only refactor the live page should
  need.
- **A picker** fixed in a corner: one row per section, one button per letter, each a link to the
  same URL with only that section's pick changed (the other picks are preserved), plus a
  `Picks: hero=B how=C …` line the user can copy back to you. Make it collapsible. Size it so every
  letter fits. Pruning between rounds keeps that to about five letters per section.
- **A label on every section** (`hero · B — Split: claim left, card right`) so any screenshot says
  what it shows.
- **Guard rails.** Register the route only in the local environment, mark the page `noindex`, and
  never let the lab's query strings reach the production route or its cache.
- **Login and data.** Screenshots and workers can't sign in. If the page sits behind a login, the
  lab route signs in a local user itself. If the local database is too thin for the page to look
  real, add a `?data=sample` toggle that builds the same objects the live page receives from a
  fixture, and keep live data as the default.
- **Placeholders.** Create an empty file for every registered variant before any are written, so
  the lab renders from the first minute and parallel writers never touch the registry.

Then serve the app over the real host (for Laravel, the `run-laravel-valet` skill) and confirm that
the lab and the live page both return 200.

Stack-specific wiring for Laravel and Blade is in [references/laravel.md](references/laravel.md).

## 3. Round one: diverge

Write two new variants per section (B and C), each a different *idea*, not a recolor: a different
layout, a different thing emphasized, a different headline strategy. Good axes to split on:

- layout: centered vs split, artifact left vs right, grid vs list vs table
- what leads: the problem, the proof, the product, or a question
- abstraction: slogan or thesis vs a concrete artifact with real numbers (a remittance line, a
  broken spreadsheet, a real API response)
- density: one claim and whitespace vs an annotated, information-rich object

The aim of round one is to discover the user's taste. Spread the variants across these axes rather
than writing three polished takes on one idea.

**Parallelize by section** when there are more than a handful of variants: one worker per section
(or two small sections per worker), each told to edit only its own variant files. Brief every
worker with the same rules: the data contract, the copy rules, the id restrictions, the surface to
keep, the screenshot command, and "report a 1–2 sentence description per variant plus a revised
label if yours no longer fits". You update the registry labels yourself afterwards, so workers
never edit the same file.

Every variant gets checked by its writer before it's reported: it returns 200, it's screenshotted
at desktop *and* phone width, and someone has looked at those screenshots and fixed what's off.

## 4. Present a round

- A table per round: section rows, variant columns, each cell the variant's headline or concept in
  one line. The user should be able to choose from the table and use the lab to confirm.
- Embed three or four screenshots of the most distinct variants. List where the rest are.
- **Caveats before picking**, and only real ones: a mock that depicts a feature that doesn't
  exist, an artifact whose numbers contradict each other, a layout that breaks on a phone, an
  analytics event name that doesn't exist yet. Check the strongest-looking variants hardest. A
  convincing mockup of a feature you don't have is the most likely way for this process to put
  something false on the page.
- Ask for picks in the picker's own format (`hero=B how=C …`).

## 5. Round two: converge on their taste

When picks come back, read them as evidence, losers included:

1. **Write the inferred taste down** in a sentence or two, naming both what won and what lost
   ("concrete artifacts with real numbers, problem-first, split layouts, numbered pins; passed on
   slogans, tile grids and centered statements"). Say it to the user. That sentence is the brief
   for every worker, and it lets the user correct the reading before more is built on it.
2. **Prune what lost.** Once the taste sentence records the losers, delete each unpicked variant:
   its file and its registry entry. Keep A, because it's the live partial, and keep the pick. Keep a
   shared helper only if a surviving variant still includes it. Losers left in the picker crowd it
   and pull new variants back toward ideas the user already turned down. Their screenshots stay in
   `.context/` as the record.
3. **Make their picks the lab's default**, so the bare URL opens on their current page and each new
   letter is compared against their choice, not against A.
4. **Add D/E/F to every section**, including sections where they kept A. There, stay close to A and
   push only on the traits they showed elsewhere. Each new variant should be a distinct take
   *within* the inferred direction, specified up front (one line each) so the three don't converge.
   Don't reuse a pruned letter. A letter in a screenshot or an old `Picks:` line should always mean
   the same variant.
5. Present it the same way as round one, then prune and repeat until every section has a pick.

## 6. Promote

Once every section has a pick:

- Move each winning variant into the live partial (merging its shared helpers into the right home,
  and deleting any copy of the live data-building it carried).
- Restore whatever the live page needs: the ids that scripts and localization swap by, the jump
  anchors other sections link to, analytics event names.
- Delete the last round's losing variants, the registry, the lab route and view, any sample-data
  fixture or local sign-in built for it, and any build-config line that existed only for the lab.
- Update the page's tests (section order, fixture drift, example parsing), the plan or copy record
  if the project keeps one, and run the tests that cover the page.

## Traps

- **Interactive widgets bound by id.** If the live section has an inline script that binds to
  element ids, move the script into its own partial first. Each variant then includes the widget
  and the script exactly once, and two variants are never on the page at the same time.
- **Scripts that swap sections by id.** If the page re-renders sections by id (localizing to the
  visitor, live updates), a variant that reuses that id gets replaced by variant A's markup
  mid-review. Give variants their own ids (`how-c`). Keep an id only when other sections link to it
  as an anchor and nothing swaps it.
- **Built CSS.** With Tailwind or similar compiled at build time, classes that appear only in a new
  file don't exist until a rebuild. Run the build in watch mode once, in the background, and tell
  every worker not to run their own build, because concurrent builds collide. Stop the watch from
  emptying its output directory on each rebuild (Vite: `--no-emptyOutDir`). Otherwise every save
  by any worker 500s the lab on a missing manifest for several seconds. If the stylesheet scans an
  explicit list of files, add the lab view to it, and remove that line at promotion.
- **Phone screenshots.** Headless Chrome's `--window-size` won't go below about 500px, so a
  "390px" CLI screenshot is really a cropped desktop layout. Use Playwright with a real viewport and
  screenshot the section's element. Hide the picker and the sticky header first, because both land
  in the middle of element captures. [scripts/shoot.mjs](scripts/shoot.mjs) does this.
- **Mock artifacts must be true and consistent.** A spreadsheet, remittance, offer letter or
  popover drawn inside a variant is still a claim. Every number comes from the real data source.
  The product can actually do what the mock shows it doing. Numbers inside one artifact agree with
  each other (an offer pegged to last year shouldn't be priced on this year's amount without saying
  so).
- **Defaults hide comparisons.** Once the default is the user's picks, `?section=a` is the only way
  to see the live version. Mention that once.

## Screenshots

```sh
node <skill-dir>/scripts/shoot.mjs --base https://app.test/landing-lab --out .context/lab/shots hero b hero c how b
```

This writes `<section>-<letter>-{desktop,mobile}.png` for each pair and exits 1 if any page fails
to load. Run it from the project root: it loads `playwright` from the project's `node_modules`. If
the project doesn't have it, run `npm i -D playwright` (`npx playwright` won't make it loadable).
If Playwright's own Chromium build isn't downloaded, the script falls back to the installed Google
Chrome, so don't patch a copy per worker. If the picker or the sticky header uses a different
selector, pass `--hide '<css>'`.
