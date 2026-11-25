# Visual lab: pages, sections and copy

For variants judged by looking at them: a settings page, a landing page, one section of a page, a
pricing page, an email, copy that lives on a page. The lab is a local-only route that renders the
real page with real data and swaps the whole scope at once: `/settings-lab?v=c`. Each variant is a
complete version of the scope the user named, with its layout, copy, hierarchy and interactions
designed together. Current is the live view, one click away.

## Read the page

- **The scope's edges.** What's inside the scope (and gets replaced whole) and what's outside it
  (the app shell, navigation, the rest of the page) and stays live around every variant. For "the
  settings page", the scope is everything inside the shell. For "the billing section", it's that
  section, and the variants render in place on the real page.
- **The data contract.** What variables the scope receives, where its numbers come from, what its
  forms post to, and which numbers are checked against a fixture. Variants must use the same
  sources and the same endpoints. A hardcoded figure in a mockup becomes a wrong figure in
  production once it's picked, and a form that posts nowhere is a mockup, not a variant.
- **The rules.** The project's copy rules (CLAUDE.md, AGENTS.md, a copy record), the design
  language (type scale, surfaces, accent color, motion attributes) and any band rhythm (such as
  alternating dark and light sections). A variant of part of a page keeps the surface it sits on,
  so it fits the live page around it. Use the `copywriting` skill for headline and body copy.
- **What can't be duplicated.** Element ids that inline scripts bind to, singleton widgets, and
  any script that finds elements by id and swaps them (localization, live updates). These decide
  how variants are allowed to differ. See "Traps" below.

## Build the lab

A local-only route that renders the page's real layout and data, with the scope's variant chosen by
the query string. Ingredients:

- **A registry**, in ranked order: `letter => [view, short name]`, plus `current` mapped to the
  live view. Variant files are named for their idea, not their letter, so ranking only reorders
  the registry. The first letter is the recommendation and what the bare URL opens on. Unknown
  letters fall back to it. In a later round, the previous round's picked letters stay registered
  after the five, as reference.
- **Shared view data.** Extract the live page's data-building into one method both routes call, so
  the lab can't drift from what production renders. This is the only refactor the live page should
  need.
- **A picker** fixed in a corner, one row: **Current**, then the five letters in ranked order, then
  any previous pick kept as reference, set apart from the five. Each button is a link that switches
  the whole scope. Below the row, a `Pick: C` line the user can copy back to you. A panel opens a
  checkbox per letter and a note field, for when the answer is a mix or a pick with a change: the
  line then reads `Pick: B+D` with the note under it, and a Copy button copies both. Ticked letters
  override the letter on screen, so browsing doesn't change the answer. Make the picker
  collapsible.
- **A label on every variant**, on the rendered scope itself, giving its letter, its rank and a
  short name (`B · #2 — Two columns, plan beside usage`; `Current — live`), so every screenshot
  stands on its own.
- **Guard rails.** Register the route only in the local environment, mark the page `noindex`, and
  never let the lab's query strings reach the production route or its cache.
- **Login and data.** Screenshots and workers can't sign in. If the page sits behind a login, the
  lab route signs in a local user itself. If the local database is too thin for the page to look
  real, add a `?data=sample` toggle that builds the same objects the live page receives from a
  fixture, and keep live data as the default.
- **Placeholders.** Create an empty file for each of the round's five variants before any are
  written, so the lab renders from the first minute and parallel writers never touch the registry.

Then serve the app over the real host (for Laravel, the `run-laravel-valet` skill) and confirm that
the lab (every letter and `?v=current`) and the live page all return 200.

Stack-specific wiring for Laravel and Blade is in [laravel.md](laravel.md).

## Axes to split on

- structure: one long page, tabs, a sidebar of subsections, or cards that open into detail
- what leads: the most-used task, the current state (plan, usage, status), or what needs attention
- layout: centered vs split, artifact left vs right, grid vs list vs table
- abstraction: slogan or thesis vs a concrete artifact with real numbers (a remittance line, a
  broken spreadsheet, a real API response)
- density: one claim and whitespace vs an annotated, information-rich object
- interaction: edit in place, edit in a modal or drawer, or a separate edit page

## Workers and checks

One worker per variant, each told to edit only its own variant files (a whole page variant may be
several partials, all in a directory named for its idea). Workers check their variant under a
provisional letter. Add to the shared brief: the scope's edges, the surface
to keep, the id restrictions, and the screenshot command. You write the registry, the names and the
ranking yourself afterwards, so workers never edit the same file.

A variant is checked when it returns 200, its forms and controls do what they claim against the
real endpoints, it's been screenshotted at desktop *and* phone width, and someone has looked at
those screenshots and fixed what's off.

## Presenting

Screenshot all five, plus Current, at both widths, after ranking, so the on-screen labels and the
file names carry the final letters. Embed A's and two or three of the most distinct
others, and list where the rest are. Visual caveats to look for: a mock that depicts a feature that
doesn't exist, a control that isn't wired to anything, an artifact whose numbers contradict each
other, a layout that breaks on a phone, an analytics event name that doesn't exist yet. Ask the user
to use Copy pick, tick more than one letter to mix, and leave a note for anything a letter can't
say.

## Later rounds

Register the round's five fresh letters in ranked order with the first as the default, keep the
previous pick registered after them as reference, and delete everything else from the previous
round. Old picker notes are keyed to the previous letters, so they clear themselves.

## Promote

- Move the winning variant into the live view (merging its helpers into the right home, and
  deleting any copy of the live data-building it carried).
- Restore whatever the live page needs: the ids that scripts and localization swap by, the jump
  anchors other pages link to, analytics event names.
- Delete the losing variants, the registry, the lab route and view, any sample-data fixture or
  local sign-in built for it, and any build-config line that existed only for the lab.
- Update the page's tests (structure, fixture drift, form submissions), the plan or copy record if
  the project keeps one, and run the tests that cover the page.

## Traps

- **Interactive widgets bound by id.** If the live view has an inline script that binds to element
  ids, move the script into its own partial first. Each variant then includes the widget and the
  script exactly once. The lab renders one variant at a time, so ids never collide on screen.
- **Scripts that swap elements by id.** If the page re-renders parts by id (localizing to the
  visitor, live updates), a variant that reuses that id gets replaced by the live markup
  mid-review. Give variants their own ids (`billing-c`). Keep an id only when other pages link to it
  as an anchor and nothing swaps it.
- **Built CSS.** With Tailwind or similar compiled at build time, classes that appear only in a new
  file don't exist until a rebuild. Run the build in watch mode once, in the background, and tell
  every worker not to run their own build, because concurrent builds collide. Stop the watch from
  emptying its output directory on each rebuild (Vite: `--no-emptyOutDir`). Otherwise every save
  by any worker 500s the lab on a missing manifest for several seconds. If the stylesheet scans an
  explicit list of files, add the lab view to it, and remove that line at promotion.
- **Phone screenshots.** Headless Chrome's `--window-size` won't go below about 500px, so a
  "390px" CLI screenshot is really a cropped desktop layout. Use Playwright with a real viewport.
  Hide the picker and any sticky header outside the scope first, because both land in the middle
  of captures. [../scripts/shoot.mjs](../scripts/shoot.mjs) does this.
- **Mock artifacts must be true and consistent.** A spreadsheet, remittance, invoice or popover
  drawn inside a variant is still a claim. Every number comes from the real data source. The
  product can actually do what the mock shows it doing. Numbers inside one artifact agree with each
  other (an offer pegged to last year shouldn't be priced on this year's amount without saying so).

## Screenshots

```sh
node <skill-dir>/scripts/shoot.mjs --base https://app.test/settings-lab --out .context/lab/shots current a b c d e
```

This loads `<base>?v=<letter>` for each letter and writes `<letter>-{desktop,mobile}.png`. It
captures the element `#lab-scope` (wrap the rendered variant, label included, in it), or the full
page if there's no such element. It hides the picker and any page-level or sticky header outside the
scope, and exits 1 if any page fails to load. Run it from the project root: it loads `playwright`
from the project's `node_modules`. If the project doesn't have it, run `npm i -D playwright`
(`npx playwright` won't make it loadable). If Playwright's own Chromium build isn't downloaded, the
script falls back to the installed Google Chrome, so don't patch a copy per worker. Pass `--param`
if the lab uses a query key other than `v`, `--scope '<css>'` for a different wrapper, and
`--hide '<css>'` if the picker or sticky header uses a different selector. When the user asked for
separate parts, run it once per part with `--param <part> --scope '#lab-<part>'`.
