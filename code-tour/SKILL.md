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
- **Anchor to a language they know.** Translate into a stack they already have: "this decorator is Spring's `@Transactional`" beats a paragraph. Don't lean on analogies that are only 80% right — say where they break.

### Never ask about their experience level

Opening with "which stacks are you fluent in?" stalls the tour to ask for something you can usually work out. Instead:

1. **Check memory.** If a memory records their stacks, seniority, or what they already know cold, use it and don't mention the lookup.
2. **Otherwise infer** — from their other code in this repo, the vocabulary of their request, what they didn't bother explaining. Pick a working anchor, name it once in passing ("I'll translate Laravel against Rails — say the word if that's the wrong anchor"), and keep moving. Don't wait for an answer.
3. **Correct on contact.** The moment they reveal something different — they know this framework cold, or have never touched a typed language — adjust depth immediately and write it to memory as a `user` memory, so the next tour starts calibrated.

## Before the tour: build ground truth

Judging code against generic internet advice is worse than useless. Do this first, and don't narrate it:

1. **Get the diff.** `gh pr diff <n>` and `gh pr view <n>` for a PR, `git diff <base>...HEAD` for a branch, or locate the code by search if they named a feature.
2. **Read the neighbors.** For each changed file, read two or three established files doing the same job — the sibling controllers, the other services, the adjacent tests. This is what turns "fits the repo" into a claim instead of a guess.
3. **Read the rules.** CLAUDE.md, CONTRIBUTING, lint/format config, and the framework version from the lockfile. Version matters: the idiomatic answer in React 16 is wrong in React 19.
4. **Trace the execution path.** Entry point → what it calls → where it lands. This is the tour's route, and it's almost never the diff's file order.

## Descend from altitude

Understanding is built top-down. A reader who has the architecture can place every line that follows; a reader handed line 1 first is accumulating trivia and hoping it resolves later. So the tour descends in three passes, and you don't start the next until the current one has landed.

**Pass 1 — the shape.** One message, before any stop, and no line-level code. Cover:

- What the change does, in the domain's terms rather than the code's.
- The one design decision driving everything else, and what it ruled out. Most diffs have exactly one — find it before you start walking.
- The boundaries it touches: which layers change, what's new versus modified, where the seams are, what stayed untouched that you'd have expected to move.
- The route ahead — the stops, named by the role they play, in execution order.

A call chain or five-line diagram belongs here. Quoted code doesn't; it drops you an altitude too early and the map turns into a walkthrough.

**Pass 2 — the route.** Stop by stop along the execution path, each anchored in real code. This is the body of the tour. Start where the user could actually trigger the code — a route, CLI command, event handler, test — and follow the call chain to the data and back. Include untouched but load-bearing files the path runs through; a PR is rarely understandable from only the lines it changed.

**Pass 3 — the fine grain.** Idiom nits, naming drift, test-quality notes, small AI fingerprints. Bank these as you go rather than derailing an architectural stop with a naming quibble, and deliver them as one short pass before the close. Anything that changes how the system works isn't fine grain — that belongs at its stop.

## Each stop

Lead with the component's job in one line — why this file exists on the path — before any code. Then quote the real code with `file.ext:12-30`: never paraphrase it, and never show more than what's under discussion. Annotate it inline as you go (next section). Then:

**What it does** — only the parts that aren't self-evident to a strong reader. Skip the rest.

**The decision underneath** — the part they're really here for. Name the choice that got made silently and what else was on the table: where state lives, what became an abstraction versus stayed inline, what's validated at which layer, sync versus queued, new helper versus existing one. Say when the alternative was also reasonable; not every fork has a wrong branch. A reader who can see the fork can direct the next implementation. One who can't is stuck approving.

**Idiom** — is this how a fluent developer in this language writes this? Verdict: **idiomatic** / **works, but not how it's done** / **fighting the framework**. When it's off, show the idiomatic version in three lines or fewer and name the framework feature being reimplemented by hand.

**Repo fit** — does it match this codebase? Verdict: **matches**, citing the precedent as `path/file.ext:88`; **diverges**, naming what from and whether the divergence earns itself; or **no precedent**, which means this PR is setting the pattern — worth a beat.

That order is the descent again: behavior, then the choice behind it, then how it's written. Hold it. On a load-bearing stop the decision is the whole point and idiom can be one line; on a leaf stop it's the reverse, and a stop with nothing but a style note probably belongs in pass 3 instead.

Not every stop needs all four. A three-line config change gets a sentence.

## Annotate the code inline

Commentary belongs against the line it's about. Prose underneath a twenty-line block makes the reader hold the code in their head while they read about it, and "the second call in the handler" is a worse pointer than a comment sitting on that call.

So every quoted block carries inline notes prefixed `tour-guide:`, written in that language's comment syntax:

```php
// app/Http/Controllers/InvoiceController.php:34-41
public function store(StoreInvoiceRequest $request)
{
    // tour-guide: typed form request — validation already ran and failed the
    // tour-guide: request before this line. No manual check needed here.
    $invoice = Invoice::create($request->validated());

    // tour-guide: THE DECISION — persisting straight from the controller. Every
    // tour-guide: sibling routes through a service object (app/Services/OrderService.php:20).
    Mail::to($invoice->customer)->send(new InvoiceCreated($invoice));  // tour-guide: sent inline, so a slow mail host slows the response. What would you do instead?

    return response()->json($invoice, 201);
}
```

Use the target language's comment marker — `#` for Python, Ruby, shell; `--` for SQL and Lua; `<!-- -->` for markup. For formats with no comment syntax at all (JSON, some configs), don't invent one: annotate in a short list under the block, keyed by line.

**The prefix is load-bearing.** It marks every word as the guide's, not the author's, so the reader is never unsure whether a comment came from the repo. Prefix every annotation line, including continuations — an unprefixed second line reads as real source. Never strip or reword the file's own comments; those are evidence, and how the author explained themselves is part of what's under review.

**Never change the code to suit the annotation.** Annotations are additions only. Preserve the original exactly — including the bug you're about to point out. Mark anything you cut with the language's ellipsis convention or a `tour-guide:` note saying what was elided, so nobody reads the excerpt as the whole function.

**Say the annotated block is disposable.** It's a teaching artifact and must never be pasted back into the repo. Worth stating once, early, if the reader might mistake it for a suggested edit.

### Division of labor

Inline notes **point**; the prose below **judges**. Don't say it twice.

- Inline: what this line is, what fires implicitly, which alternative was passed over, a verdict in a few words.
- Prose: why it matters, what it costs, the precedent, what to do about it.

An annotation that runs past two lines is prose wearing a comment's clothes — move it down. A prose paragraph that re-narrates what the annotation already said is filler — cut it.

### Density

Annotate what you'd point at if you were reading over their shoulder: **two to five notes per block**, not one per line. Silence is signal — an unannotated line reads as "nothing to say here", and that's useful. Annotating everything destroys the contrast that makes the important note stand out.

Reserve emphasis for the one that matters most. `// tour-guide: THE DECISION —` earns its caps only when it's the fork the whole stop turns on.

Inline is also the natural home for an ask-before-you-tell question — hang it on the exact line, then stop and wait for the answer instead of annotating past it.

## Ask before you tell

At two or three real forks, stop and ask before revealing. Hang the question on the line it's about — `// tour-guide: this re-raises. Where do you think it gets caught?` — then stop the message there and wait. A question with the answer three lines below it isn't a question.

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

Judge, don't checklist. Name the ones actually present and say which are fine as-is. Raise the ones that change how the system behaves at their stop; the cosmetic ones wait for pass 3.

## Close: what they take with them

End with at most:

- **Three things to check first on the next PR here** — specific to this repo and stack, not general review advice.
- **The prompt-level fix.** For the two or three weakest spots, what the author could have specified up front to prevent them: "use the existing `X`", "no new abstraction until there's a second caller", "handle errors at the boundary, not per call". This is the highest-leverage part of the tour — it turns a review finding into a habit.
- **What's still unclear and how to find out** — the file to read, the test to run, the line to break on purpose and watch fail. Leaving open questions open is honest, and it's how they learn the rest.

Don't summarize the tour. They just took it.

## Anti-patterns

- **Starting at line level.** Opening on the first stop's code before the reader has the shape means every detail lands somewhere they can't file it. Map first, always.
- **Interviewing them.** Asking their experience level, preferred stack, or how deep they want it. Infer, commit, correct later.
- **Narrating the diff.** "This file adds a function that…" is reading aloud. If a line's purpose is obvious, skip it.
- **Annotating every line.** A `tour-guide:` note on all twenty lines is the same as none — nothing stands out. Two to five per block; let silence carry the rest.
- **Unmarked commentary.** An annotation missing its `tour-guide:` prefix, or a quoted block silently edited to read better, leaves the reader unable to tell your words from the author's. That destroys the tour's only real currency.
- **Verdict-free commentary.** "This is one approach" teaches nothing. Commit: idiomatic or not, fits or doesn't, and why.
- **Nitpicks at the same volume as design flaws.** A naming quibble and an N+1 in a hot path are not the same finding. Rank them, and let the small stuff go.
- **Praise inflation.** "Fine" is a complete verdict. Calling ordinary code excellent devalues every other judgment in the tour.
- **Teaching from training data instead of the repo.** Every "fits the pattern" claim needs a `file:line`. Without one, say you're going on general convention.
- **Dumping the tour all at once.** Stops, pauses, questions. Otherwise it's a document, and they'll skim it.
