---
name: brief-me
description: Use when the user wants to understand or get oriented on a PR, branch, or diff before or while reviewing it — their own or someone else's, especially in an area of the codebase or a domain they don't know well. "Brief me on #123", "explain this PR", "walk me through this branch", "what should I know before reviewing this", "what's risky here", "PR overview". Produces a high-level briefing — a primer on the area as it stood, an architecture diagram of the change, a worked example traced before and after, ranked danger zones (regression, security, data, legal, ops), convention drift, and where to spend review time. It keeps per-area notes that make the next PR in the same area faster, and drills into any item on request.
---

# Brief me

Give a smart reviewer the context they're missing before they read the diff. A reviewer who starts at line 1 of file 1 collects trivia and hopes it adds up. A reviewer who first learns the area, sees the shape of the change, watches one real case go through it, and knows where the risk is can read the diff in the right order and skim the rest.

A diff only shows the change, so a reader new to the area can't see what it changed from. Teach the area first, then the change.

This is orientation, not a bug hunt. Point at where to look hard and say why. Don't try to verify every line. The deep pass is `/code-review` or `/security-review`, aimed at the zones this briefing flags.

## Reader model

- **Experienced developer.** Don't explain general programming concepts. Do explain local knowledge: framework magic, implicit behavior, this repo's conventions and vocabulary, and the domain.
- **Possibly new to this area or stack.** Translate unfamiliar framework behavior into a stack they know ("this is Rails' `before_action`"), and say where the analogy breaks. Check memory for their stacks. Otherwise infer and don't ask.
- **Own PR or someone else's.** For their own PR, they're checking what they or their agent shipped before others see it, so frame findings as things to fix or explain. For someone else's, frame them as questions to ask the author.
- **Open or merged.** For an open PR, findings are merge blockers or review comments. For a merged one, they're follow-ups, §10 becomes an audit plan, and §11's questions become candidate follow-up issues. Say which framing applies in the header.

## Build ground truth first

Don't narrate this phase.

1. **Load the area notes.** Find which areas the diff touches and load their notes, as described in [Area notes](#area-notes). Treat the notes as a head start, not as truth.
2. **Get the change.** For a PR: `gh pr view <n> --json title,body,baseRefName,headRefName,files,additions,deletions,author,comments`, then `gh pr diff <n>`. For a branch: `git diff <base>...HEAD` plus `git log <base>..HEAD`. With no target given, use the current branch against its PR base or the repo default. Read files at the PR's own state, not whatever the local checkout has, because a stale default branch or another branch will mislead you. Use `git fetch origin pull/<n>/head` and then `git show <sha>:<path>` for an open PR, or the merge commit for a merged one. Read the base side at the base commit.
3. **Get the intent.** Read the PR body, linked issue, and commit messages. The question "does the diff do what it claims, and only that?" needs a claim to check against.
4. **Learn the area as it stood.** At the base commit, find what the touched area owns, who calls into it, and the rules that must always hold there. Look for those rules in assertions, constraints, comments, and tests. Note the terms the code uses that an outsider wouldn't know.
5. **Learn the outside rules.** If the area implements an external domain, protocol, or platform (payments, OAuth, time zones, email deliverability, App Store review, tax, GDPR), work out what an expert in that domain checks first. Back it with the official docs for the version in the lockfile, fetched rather than recalled, since APIs and rules drift between versions. Running the tool itself (the git, CLI, or library version actually in use) is even better evidence than the docs.
6. **Read the neighbors.** For each changed area, read one or two established files doing the same job: sibling controllers, other migrations, adjacent tests. Every convention claim needs a precedent to point at.
7. **Read the rules.** CLAUDE.md/AGENTS.md, CONTRIBUTING, lint config, and framework versions from the lockfile.
8. **Trace the path.** Find the entry point a user or system actually triggers (route, job, command, event, cron), follow it through the changed code to where data lands, then back. Include untouched files the path runs through. A PR is rarely understandable from its changed lines alone.
9. **Find the callers.** For each changed function signature, return shape, schema, config key, or public API, search for every caller and consumer. Most regressions live outside the diff.
10. **Look at what it produces.** If the change is deployed or generates artifacts (built HTML, images, screenshots, API responses), inspect those too. That's often the cheapest way to turn a `check` into `traced`, and it catches what the source alone hides.

For a large diff (roughly 1,500+ changed lines, or several unrelated areas), split the reading by area across parallel subagents. Give each one the same checklist, ask for findings with `file:line`, and assemble the briefing yourself.

## The briefing

Deliver it as one message in this order. Keep it skimmable: the reader should get the gist from the headings and the first line of each item. Size it to the PR. A 40-line fix might be ten lines of briefing, with most sections reduced to "none" or dropped. Aim for under about 100 lines in total unless §7 has five or more items. When you're over, cut §6, §8, and §9 down to their single most important line each before trimming §2, §5, or §7.

### Visual vocabulary

The reader should be able to find every warning by scanning the left edge, without reading anything. Use this fixed set of markers, and give each one exactly one meaning.

| Marker | Meaning | Where |
|---|---|---|
| 🔴 | high severity | danger zones, scorecard |
| 🟠 | medium severity | danger zones, scorecard |
| 🟡 | low severity | danger zones, scorecard |
| ⛔ | breaks an invariant from §2 | before the severity dot on that danger zone |
| ⚠️ | warning that isn't a danger zone | conventions that diverge without earning it, gaps, a diff that doesn't match its stated intent |
| ✅ | checked and fine | the clean-sweep line, conventions that match or diverge for a good reason, the "after" result of a fix |
| ❌ | broken or failing | the "before" result in a worked example, a claim in the PR body that doesn't hold |
| 🆕 | no precedent; this PR sets the pattern | conventions |
| 🔎 · 🧪 · ❔ | traced by reading · traced by running · plausible, unchecked | confidence on danger zones and worked-example steps |
| 📌 | read this line by line | where to spend review time |
| ❓ | needs an answer from someone | questions and unknowns |

Rules:

- **Markers go at the start of a line or list item**, followed by bold text: `🔴 **high · data**`. Keep the words next to the marker so the meaning survives a renderer without emoji, and so it can be searched.
- **No markers inside code blocks.** Emoji width varies between terminals and breaks the alignment of diagrams and code. The diagram keeps its `+ * †` legend.
- **Only markers from this table**, and none on neutral content. Every icon is a signal, so decorating an ordinary bullet dilutes the ones that matter.
- **Section headings get one fixed icon each**, as shown below, so the reader can jump between sections by eye.

### 1. Header

Start with a status line: 🟢 open or 🟣 merged, and whose PR it is. Then a **scorecard**: the danger-zone count by severity, the number of invariants broken, and the questions left open. For example:

> 🟣 merged · someone else's PR · 🔴 0 · 🟠 2 · 🟡 2 · ⛔ 1 invariant · ❓ 3 open

That gives the reader the verdict in one glance before any detail. Then one line on what the change does, in domain terms rather than code terms, and one line of scope: files, +/−, layers touched, and whether the diff matches the stated intent. Mark a mismatch or bundled unrelated changes with ⚠️.

### 2. 🧭 The area

What the reader needs to know about this part of the system before the change makes sense. Describe it as it stood at the base commit. This is a summary of the area notes, at most about ten lines. The notes file holds the full version.

- **What it owns and who calls it**, in two or three lines.
- **Invariants:** the two or three rules that must always hold here, with `file:line` for where each is enforced or relied on. A change that breaks one is usually the most important finding in the briefing.
- **Glossary:** up to six terms that are specific to this repo or domain, with one line each. Include only terms the briefing or the diff actually uses.
- **Outside rules:** when the area implements an external domain, two or three things an expert in it checks first, each with a link to the official docs. "Stripe retries webhooks for up to three days, so handlers must be idempotent" is the kind of line that belongs here. Drop this part when the area is purely internal.

Compress this to a single line when the reader clearly knows the area: memory says so, or they wrote most of it.

If something was true before the PR, it belongs here. If it only matters because of what the new code does, it belongs in §6.

### 3. 🗺️ Diagram

Draw the architecture the change lives in: the components on the execution path and how data or control flows between them. Use plain text in a `text` code block, since mermaid doesn't render in a terminal.

```text
 POST /invoices ──▶ InvoiceController ──▶ InvoiceService* ──▶ invoices table†
                                              │
                                              ├──▶ TaxCalculator+  (new)
                                              └──▶ SendInvoiceMail (queued*)
 + new   * changed   † schema change   unmarked = untouched but on the path
```

- Mark every node new, changed, or untouched, and include a legend.
- Show flow, not the file tree. Twelve nodes at most. Collapse anything that isn't on the path.
- When the change restructures something (moves responsibility, adds a layer, swaps sync for async), draw before and after side by side or one above the other.
- When the path isn't a request pipeline, nodes can be data or states instead of components: directories a resolver walks, states a record moves through, or build-time steps versus runtime steps.
- When the change spans separate runtimes (build and browser, server and mobile app, an offline pipeline), give each runtime its own labeled lane in the same block, with up to about eight nodes per lane.
- A one-file leaf change gets a one-line call chain instead of a diagram.

### 4. ⚖️ The core decision

Two to four sentences. Name the one design choice the rest of the diff follows from, what it ruled out, and whether the alternative was also reasonable. Most PRs have exactly one. If you can't find one, the PR is several changes bundled together. Say so in one sentence, then give each bundled change's decision in one line, three at most, and lead with the one that has the most consequences.

### 5. 🔬 Worked example

Follow one concrete input through the code before the change and after it. A real case teaches an unfamiliar area faster than any description of it.

- Pick the input the PR exists for: the bug's reproduction, the new feature's first use, or the case the core decision turns on. Use real values ("invoice 42, `tax_rate` null, customer in Ontario"), not placeholders.
- Show it as two short numbered traces, before and after, with `file:line` at each step and the observable result at the end of each. Mark the results: ❌ for the broken or old behavior, ✅ for the fixed or new one. When the "after" is itself wrong, mark it ❌ too and link the danger zone.
- Run it where that's cheap and has no side effects: an existing test, a pure function in a REPL, or a read-only query. Show the real output and mark those steps 🧪. Mark steps you only traced by reading with 🔎. Never run anything that writes to a shared database, calls a paid or external API, sends mail, or migrates.
- When the PR's code isn't checked out, so its tests can't run in place, don't check it out or modify the working tree to run them. Run the primitives it depends on instead (the git command, the parser on its real input, the query) and trace the rest by reading. Mark each step 🧪 if you executed it or 🔎 if you traced it by reading.
- Keep it to about twelve lines in all. If the before and after are identical for the obvious input, that's worth saying, and it's often a sign the change targets an edge case. Pick that edge case instead.

### 6. 💡 Concepts to understand

The three to six things a reviewer must know to judge this diff, and would get wrong without: implicit framework behavior (what runs, injects, or mutates without being called), patterns new to this repo, and non-obvious assumptions the new code makes. Write one or two lines each with `file:line`. Don't repeat what §2 covered. Skip anything a strong developer would infer from reading the code.

### 7. 🚨 Danger zones

The core of the briefing. Rank items by severity × likelihood. Don't group them by category.

Each item is a numbered entry in this shape:

```markdown
1. ⛔ 🔴 **high · data** `app/Billing/Invoice.php:88` (via `app/Billing/TaxCalculator.php:31`)
   Invoices created before the tax migration have `tax_rate` null. `total()` now multiplies
   by it without a fallback, so reopening any of the ~4k pre-2024 invoices throws a TypeError.
   🔎 traced (read) · **Verify:** `php artisan tinker`, then `Invoice::whereNull('tax_rate')->first()->total()`.
```

That example is shown in a code block only so the format is visible. In the briefing, write items as plain Markdown so the markers and bold text render.

- **Severity**: 🔴 `high` / 🟠 `med` / 🟡 `low`. Prefix ⛔ when the item breaks one of §2's invariants.
- **Tag**: one short word for the kind of risk, such as `regression`, `security`, `data`, `perf`, `ops`, `legal`, `cost`, or `ux`. Any honest word will do.
- **Where**: the `file:line` where the failure happens. When the diff reaches it through untouched code, add `(via path:line)` pointing at the changed line.
- **What could go wrong**: a concrete scenario, not a category name. "Existing invoices with a null `tax_rate` now throw in `total()`" rather than "possible null handling issue".
- **Confidence**: 🔎 `traced (read)` if you followed the path through the code, 🧪 `traced (ran)` if you executed it, ❔ `check` if it's plausible but you didn't follow it. Label honestly. A briefing that cries wolf trains the reader to skip it.
- **Verify**: the test to run, the query, or the caller to read.

Sweep every category in [references/risk-checklist.md](references/risk-checklist.md), plus the area's invariants and outside rules from §2. Report only what's actually present. Then close the section with one line listing the categories you checked and found clean, such as "✅ Checked, nothing found: auth, migrations, licenses, PII." That line is the evidence the sweep happened, and it tells the reader what they can skip. Keep it to one comma-separated line with no explanation per item. A clean result doesn't need defending.

### 8. 📐 Consistency and conventions

Places where the diff departs from this repo's established way of doing the same job. Cite the precedent as `path:line` and say whether the departure earns itself. Start each item with its verdict: ⚠️ diverges without a good reason, ✅ matches, or diverges for a good reason, 🆕 no precedent. "No precedent" is worth a line, because this PR is setting the pattern others will copy.

Include the AI-authorship tells that change how the code reads or behaves:

- a hand-rolled helper that duplicates one in the repo or stdlib
- framework built-ins reimplemented by hand
- an abstraction with one caller
- defensive handling around things that can't fail
- tests that assert the mock or only cover the happy path
- version-wrong API usage

Leave pure naming nits out unless they'll confuse the next reader.

### 9. 🕳️ Gaps

Things that should be in the PR and aren't, each marked ⚠️: tests for the risky paths in §7, a migration rollback, a docs or config update, a caller that should have changed alongside, or logging for a new failure mode. Skip anything that's merely nice to have. If a missing piece can itself cause a failure, it's a danger zone. List it in §7 and don't repeat it here.

### 10. 👀 Where to spend review time

An ordered reading list: the two to five files or hunks to read line by line, each marked 📌, in the order that makes them make sense, then what to skim and what can be skipped as mechanical (generated files, renames, lockfiles, formatting). This turns the briefing into a review plan.

### 11. ❓ Questions and unknowns

- **Questions.** For someone else's PR, up to five questions for the author, each one tied to a danger zone or gap. For your own PR, the questions a reviewer is likely to ask, which the PR description or code should answer before it goes up. Don't restate a danger zone as a question unless the answer is something only the author knows: intent, an external constraint, or a rollout plan.
- **Couldn't determine.** Mark every question and unknown with ❓. Up to three things the briefing couldn't settle from the repo, each with who or what would know. Production config, data shape in the live database, an external system's behavior, or a decision made in a conversation you can't see are typical. Leave this out when there's nothing.

For a merged PR, both kinds become follow-up work, so combine them into one list headed **Follow-ups**, five items at most.

## After the briefing

Update the area notes (next section). Then end with one line offering to go deeper on any numbered item. On a drill-down:

- Quote the real code with `path:start-end`, and only the part under discussion.
- Annotate it inline in the language's comment syntax, prefixed `brief:`, two to five notes per block. Never alter the quoted code, and mark anything you cut.
- Give a verdict on idiom (✅ **idiomatic** / ⚠️ **works, but not how it's done** / ❌ **fighting the framework**) and on repo fit (✅ **matches** `path:line` / ⚠️ **diverges** / 🆕 **no precedent**), with the idiomatic version in three lines or fewer when it's off.
- For a danger zone, try to settle `check` into `traced` or dismissed. Read the callers, run the targeted test, or query the schema.

If the user wants the zones bug-hunted properly, suggest `/code-review` or `/security-review` scoped to them rather than doing a full review inline.

## Area notes

The area primer is the most expensive part of the briefing to build and the part that changes least between PRs. Keep it on disk so the next PR in the same area starts from it.

**Where.** `.context/brief-me/areas/<slug>.md` in the repo's **main checkout**, which is the first entry of `git worktree list --porcelain`. Don't use the current worktree. Conductor workspaces and other worktrees are deleted when they close, and their notes go with them. `<slug>` is the area's directory path with `/` replaced by `--`, for example `internal--projects.md` or `app--Billing.md`.

**Which areas.** An area is the directory whose behavior or invariant the PR changes, usually one or two levels deep. It isn't every directory the diff touches. A cross-cutting PR usually has one such area, and the other touched directories are its callers, which the notes list under Callers. Give another directory its own file only when the briefing relied on an invariant that lives there. Cap it at three files per briefing.

**Keep it out of git.** Before the first write, run `git check-ignore -q .context` from the main checkout. If it isn't ignored, append `.context/` to `$(git rev-parse --git-common-dir)/info/exclude`. That file is local and never committed. Never add the notes to `.gitignore`, and never commit them.

**Format.** See [references/area-notes.md](references/area-notes.md). In short: what the area owns, callers, invariants, glossary, outside rules, and gotchas found in past briefings, each with `file:line`. Add a `verified-at:` line giving the commit the notes were last checked against: the PR's head commit for an open PR, or the merge commit for a merged one.

**On load.** Run `git log --oneline <verified-at>..<base> -- <area path>` to see what changed in the area since the notes were written. Re-check every claim the briefing will rely on against the current code. A wrong note repeated with confidence is worse than no note.

**On update.** Fix anything the briefing proved wrong, add the new invariants, terms, and gotchas it surfaced, and move `verified-at:` forward. Keep each file under about 80 lines by cutting what no longer helps, not by compressing it. Add PR-specific findings only when they'll matter for the next change in the area. Don't mention the notes in the briefing unless they turned out wrong in a way the reader should know.

## Anti-patterns

- **Teaching the diff before the area.** A reader who doesn't know what the code did before can't judge what it does now. §2 comes first for a reason.
- **Placeholder examples.** "Given some input X" teaches nothing. Use real values and show the real output when you can.
- **Recalling outside rules from memory.** Platform and API rules change between versions. Cite the docs for the version in use, or label the claim as general knowledge.
- **Narrating the diff.** "This PR modifies `InvoiceService` to add…" is a file list in sentences. Lead with behavior and risk.
- **Category-shaped danger zones.** "Security: consider input validation" with no file, scenario, or verification step is noise. Every item needs a concrete failure.
- **Padding the checklist.** Listing six categories as "low risk" when nothing was found. One line of "checked, nothing found" covers them.
- **Uniform volume.** A naming nit and an unauthenticated endpoint can't share a font size. Rank them, and drop what doesn't matter.
- **Conventions from training data.** Every "the repo does X" needs a `path:line`. Without one, say you're going on general convention.
- **Reviewing only the diff.** Changed signatures, schemas, and config keys break callers that the diff never shows. Search for them.
- **Trusting stale notes.** Area notes are a head start. Check anything you rely on against the code at the base commit.
- **Emoji confetti.** Icons on neutral lines, icons with no matching word, or a marker used for two meanings. Every marker should mean what the table says it means, and nothing else.
- **Wall of text.** If the reader can't get the gist from the headings and first lines, cut until they can.
