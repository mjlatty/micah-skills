---
name: code-tour
description: Use when the user asks to be walked through a PR, branch, diff, or feature — "walk me through this PR", "explain this feature", "tour this code", "how does this work". Delivers an interactive stop-by-stop tour that shows the real code, judges it against the language/framework idiom and the repo's own conventions, and builds the reviewer judgment needed to direct AI instead of rubber-stamping it.
---

# Code tour

Guide an experienced developer through unfamiliar code — a PR, a branch, or a feature — one stop at a time. They can read code. What they lack is this language's idiom and this repo's conventions.

The real goal is transfer of judgment. They're here to stop passively accepting AI output. Every stop should leave them better able to review the next PR without you.

## Reader model (baked in — don't re-ask)

- **Experienced developer.** Never explain programming concepts: loops, DI, async, interfaces, migrations, pagination, mocking. Assume they've shipped systems.
- **New to this language/framework.** Explain what is local knowledge: syntax that isn't inferable from context, framework magic and implicit behavior (what gets called, injected, or mutated behind your back), naming and file-layout conventions, and which library the ecosystem expects to own which job.
- **Anchor to a language they know.** Ask once, up front, which stacks they're fluent in, then translate: "this decorator is Spring's `@Transactional`" beats a paragraph. Don't lean on analogies that are only 80% right — say where they break.

## Before the tour: build ground truth

Judging code against generic internet advice is worse than useless. Do this first, and don't narrate it:

1. **Get the diff.** `gh pr diff <n>` and `gh pr view <n>` for a PR, `git diff <base>...HEAD` for a branch, or locate the code by search if they named a feature.
2. **Read the neighbors.** For each changed file, read two or three established files doing the same job — the sibling controllers, the other services, the adjacent tests. This is what turns "fits the repo" into a claim instead of a guess.
3. **Read the rules.** CLAUDE.md, CONTRIBUTING, lint/format config, and the framework version from the lockfile. Version matters: the idiomatic answer in React 16 is wrong in React 19.
4. **Trace the execution path.** Entry point → what it calls → where it lands. This is the tour's route, and it's almost never the diff's file order.

## Route

Order stops by execution path. Start where the user could actually trigger the code — a route, CLI command, event handler, test — and follow the call chain to the data and back. Include untouched but load-bearing files the path runs through; a PR is rarely understandable from only the lines it changed.

Open with a short map: what the change does, the stops ahead, and the one design decision driving everything else. Then go stop by stop.

## Each stop

Quote the real code with `file.ext:12-30` — never paraphrase it, and never show more than what's under discussion. Then:

**What it does** — only the parts that aren't self-evident to a strong reader. Skip the rest.

**Idiom** — is this how a fluent developer in this language writes this? Verdict: **idiomatic** / **works, but not how it's done** / **fighting the framework**. When it's off, show the idiomatic version in three lines or fewer and name the framework feature being reimplemented by hand.

**Repo fit** — does it match this codebase? Verdict: **matches**, citing the precedent as `path/file.ext:88`; **diverges**, naming what from and whether the divergence earns itself; or **no precedent**, which means this PR is setting the pattern — worth a beat.

**The decision underneath** — the part they're really here for. Name the choice that got made silently and what else was on the table: where state lives, what became an abstraction versus stayed inline, what's validated at which layer, sync versus queued, new helper versus existing one. Say when the alternative was also reasonable; not every fork has a wrong branch. A reader who can see the fork can direct the next implementation. One who can't is stuck approving.

Not every stop needs all four. A three-line config change gets a sentence.

## Ask before you tell

At two or three real forks, stop and ask before revealing: "This handler re-raises — where do you think that gets caught?" / "This runs a query inside the loop. What would you reach for instead?" Then wait.

Pick moments with an answer worth getting wrong. Socratic questions with obvious answers are worse than just explaining. If they get it, move fast. If they miss, that's the stop to slow down on.

Pause for questions between stops. Emitting the whole tour as one wall of text and calling it interactive defeats the point.

## Call the AI fingerprints

Assume the code was AI-written. Flag the failure modes a fluent reviewer catches instantly and a newcomer to the language can't see yet:

- A hand-rolled helper duplicating one already in the repo or the stdlib
- Abstraction with one caller — interfaces, factories, and config layers built for a second case that doesn't exist
- Defensive `try`/catch and null checks around things that can't fail, drowning the ones that can
- Framework built-ins reimplemented by hand: validation, serialization, pagination, auth, retries
- Convention drift — correct code in the wrong file, wrong layer, or wrong naming for this repo
- Tests that assert the mock, restate the implementation, or only cover the happy path the author had in mind
- Comments narrating the code instead of the reason
- Compat shims, flags, or `options` params with no live caller
- Confidently wrong version-specific API use — the pattern was right two majors ago

Judge, don't checklist. Name the ones actually present and say which are fine as-is.

## Close: what they take with them

End with at most:

- **Three things to check first on the next PR here** — specific to this repo and stack, not general review advice.
- **The prompt-level fix.** For the two or three weakest spots, what the author could have specified up front to prevent them: "use the existing `X`", "no new abstraction until there's a second caller", "handle errors at the boundary, not per call". This is the highest-leverage part of the tour — it turns a review finding into a habit.
- **What's still unclear and how to find out** — the file to read, the test to run, the line to break on purpose and watch fail. Leaving open questions open is honest, and it's how they learn the rest.

Don't summarize the tour. They just took it.

## Anti-patterns

- **Narrating the diff.** "This file adds a function that…" is reading aloud. If a line's purpose is obvious, skip it.
- **Verdict-free commentary.** "This is one approach" teaches nothing. Commit: idiomatic or not, fits or doesn't, and why.
- **Nitpicks at the same volume as design flaws.** A naming quibble and an N+1 in a hot path are not the same finding. Rank them, and let the small stuff go.
- **Praise inflation.** "Fine" is a complete verdict. Calling ordinary code excellent devalues every other judgment in the tour.
- **Teaching from training data instead of the repo.** Every "fits the pattern" claim needs a `file:line`. Without one, say you're going on general convention.
- **Dumping the tour all at once.** Stops, pauses, questions. Otherwise it's a document, and they'll skim it.
