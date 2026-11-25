# Engineering lab: approaches built in the real codebase

For variants judged by running and reading the code: an API's shape, a schema, where some logic
lives, a library or a few dozen lines of your own, how a sync job is structured, a caching
strategy. A sketch in a code block hides exactly what decides these questions: the call sites, the
migration, the failure paths. So every variant is working code in the real codebase, and every
variant goes through the same checks.

## Read the code

- **The scope, whole.** Name what's being decided by what changes for callers. Each variant is a
  complete design at the scope the user named: "variants of the sync job" means five whole sync
  jobs, each with its own data model, interface and failure handling designed to fit together. Don't
  split it into `schema`, `api` and `retry` picked separately unless the user asked for that by name.
- **Current.** The code on the branch, run through the same checks as the five, so every number has
  something to beat. If the feature doesn't exist yet, there's no Current. The most direct
  implementation, the one you'd write if nobody had asked for options, competes as one of the five.
- **The contract.** Behavior every variant must keep: what callers rely on, what existing tests pin,
  and the data already in production. A schema variant has to say how today's rows get there.
- **What decides it.** The criteria the user will pick by: speed, how the call site reads, size of
  change, operational load, testability, fit with the next known requirement. Each becomes a row in
  the comparison. If the user didn't say, propose them in the line where you name the kind.
- **Versions.** Read the lockfile before writing against a library. A variant built on an API from
  memory fails on the installed version, and it fails late, after the user has started to like it.

## Build the lab

Pick the layout by whether the variants fit behind one seam.

- **One tree, side by side**, when every variant implements the same interface (a strategy, a
  driver, a job, a repository). Each variant is its own class named for its idea (`OutboxSyncJob`), a
  switch maps letters to classes and picks one (`LAB_SYNC=b`, with `current` selecting the live
  class, or a container binding read from the environment), and the harness runs once per letter and once for Current. It's cheap, and every
  variant meets the same callers. The switch is the registry: you own it, and writers only touch
  their own class.
- **One worktree per variant**, when they don't fit one seam: schema changes, call sites with
  different shapes, a new dependency. Each variant gets a local branch off the same base commit:

  ```sh
  git worktree add -b lab/<topic>-<name> .context/lab/<topic>/<name> HEAD
  ```

  Each worktree needs its own installed dependencies, and a schema variant needs its own database.

Build these before any variant is written:

- **A contract test**, written against behavior rather than an implementation, that every variant
  must pass. Include the hard case the decision turns on: the concurrent write, the retry after a
  partial failure, the page with ten thousand rows. A test that skips it makes every variant look
  equal.
- **A compare script** (`.context/lab/<topic>/compare.sh`) that runs, for Current and each letter,
  the contract test, the existing tests for the area, any benchmark, and a diff summary against the
  base (`git diff --shortstat <base>...lab/<topic>-<name>`, or the variant's own files in the one-tree
  layout). It prints one table with Current first and the letters in ranked order. Every round's
  numbers come from this script so they stay comparable.
- **Call-site excerpts.** Pick one or two real callers and show how each reads today and under each
  variant.
  Most API and structure decisions are made from these, not from the implementation.

Benchmark only when speed is a criterion. Use realistic data sizes, run the variants back to back on
the same machine with a few repetitions each, and report the spread, not one number.

## Spike, don't finish

A variant is a spike sized to be judged: the whole design at its core, the contract test passing,
and one or two real callers converted to show the shape. It lists what it stubbed or left
unconverted, and that list is part of its cost. Five a round is only affordable at this size:
converting every caller wastes work on ideas that will lose.

## Axes to split on

- where the logic lives: caller or callee, database or application, in the request or on a queue
- build or buy: a library or a few dozen lines of your own
- data shape: normalized or denormalized, columns or JSON, stored state or derived from an event log
- abstraction: inline and duplicated, a shared helper, or an extension point
- failure model: fail fast, retry, or degrade
- size of change: the smallest diff that works, or the refactor that makes the next three changes easy

Spread the five across these. Each is a whole design, so a variant usually takes a position on
several axes at once; make sure no two take the same positions.

## Workers and checks

Parallelize by variant: five workers, each given its own worktree path (or its own class in the
one-tree layout) and the same base commit. Branches and classes carry the variant's working
name, never a letter, because letters are assigned by rank after the variants are checked. The
switch and the compare script map letters to names. Add
to the shared brief: the contract test and "don't edit it", the compare command, and the stub list
to report. A writer who thinks the contract is wrong reports that instead of editing it; you change
it for every variant at once.

A variant is checked when the contract test and the area's existing tests pass (or the failure is
reported as the finding it is), the compare script runs on it, its call-site excerpt and stub list
are written, and its diff has been re-read for anything that only works in the lab: a hardcoded
environment value, a skipped check, a test marked to skip.

## Presenting

- The compare script's table: Current then the five in ranked order as columns; rows for tests,
  benchmark with spread, lines changed, files touched, new dependencies, migration needed, and
  what's stubbed. Rank on these numbers and the criteria, and let the rank reasons cite them.
- Call-site excerpts side by side: Current, A, and the most distinct others.
- Engineering caveats to look for: a variant that passes because the test misses the hard case, a
  benchmark on toy data, a dependency that's unmaintained or wrongly licensed (check before
  presenting), a migration that needs a backfill or downtime at production data size, behavior that
  differs in a way the contract test doesn't pin.

## Later rounds

The pick becomes the base: the five new worktrees (F–J in round two) branch from the picked
variant's branch, the switch defaults to the round's recommendation, and the compare table keeps
Current and the previous pick as reference columns before the five. Engineering taste usually shows
up as a principle ("keep it in the database", "no new dependencies", "boring over clever"). Name it
in the taste sentence.

## Promote

- Bring the winner into the working branch: merge or cherry-pick its lab branch, or move its class
  into the real one and delete the switch.
- Finish what the spike stubbed: convert the remaining callers, write the migration for real data,
  update docs.
- Keep the contract test. It pins the decision. Drop benchmark scaffolding unless the project keeps
  benchmarks.
- Remove the lab: `git worktree remove` each worktree, `git branch -D` each `lab/<topic>-*` branch,
  and delete the losing classes and the switch. Lab branches are never pushed.
- Record the decision and each rejected approach with the measured reason it lost, wherever the
  project keeps decisions (a plan, an ADR, the PR description). Those numbers answer "why didn't we
  just…" six months later.
- Run the tests that cover the area.

## Traps

- **State shared between worktrees.** Worktrees share the git stash, and often the database, cache,
  queue and dev-server port through a copied `.env`. Give each variant its own database name and
  port, and never use `git stash` to move work between them.
- **Shared dependency directories.** Symlinking `vendor/` or `node_modules/` across worktrees breaks
  as soon as one variant adds a dependency. Install fresh in any worktree whose manifest differs.
- **The harness drifting between rounds.** If you fix the compare script or the contract test,
  rerun every surviving variant, or the table compares numbers from two different harnesses.
