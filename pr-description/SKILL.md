---
name: pr-description
description: Use whenever opening a pull request or writing or revising its body, including requests to put a branch up for review or ship it. Apply before gh pr create or gh pr edit. Produces a skimmable description of 400 words or fewer covering why the PR exists, the business context and concepts a reviewer needs to judge it, its core tradeoffs, and the risks worth checking, without narrating what the diff already shows.
---

# PR description

Give the reviewer the big picture before they open the diff: why the change exists, what part of the system and the business it touches, which concepts they need to judge it, what it trades away, and what could go badly wrong. Leave the line-by-line detail to the diff.

The cap is **400 words**, counting headings, diagram labels, and code. If something doesn't change how the reviewer understands or judges the PR, cut it.

## Gather ground truth

Don't narrate this phase.

1. **The base.** Use the user-specified or existing PR base. Otherwise resolve the repo default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`) and check for a stack: if another open PR's head branch is an ancestor of this one, that branch is the base.
2. **The change.** `git diff <base>...HEAD` and `git log <base>..HEAD`. When revising, also read the existing body with `gh pr view <n>`.
3. **The intent.** Read the conversation, commit messages, and linked issue for why the change exists and which alternatives were tried and dropped. That reasoning exists nowhere else. Don't invent rationale from the code alone.
4. **The business context.** Find what this code does for the product: which users or flows it serves, and whether money, data, or trust runs through it. Look in the README, CLAUDE.md/AGENTS.md, `icps/`, docs, and route or feature names. If you can't find it, keep the section short rather than invent it.
5. **The framework.** Note the implicit behavior the diff leans on: what runs, injects, retries, caches, or mutates without being called.
6. **The callers.** For each changed signature, schema, config key, or public API, search for its consumers. The biggest risks usually live outside the diff.
7. **The repo's rules.** A `.github/pull_request_template.md`, contribution rules in CLAUDE.md or CONTRIBUTING.md, and `.claude/post-deploy-checklist.md`.

Scale steps 5 and 6 to the change: on a large PR, trace the path the core decision runs through, not every file.

## The body

Use this shape, sized to the PR. A one-line fix gets the opening sentence and nothing else; drop any section that would be padding.

**Opening** (one or two sentences, no heading): what the change does in domain terms and the problem or need behind it. Link the ticket if there is one. Add ⚠️ and a line naming the split if the PR bundles unrelated changes.

### 🏢 Business context

Two to four sentences: which users or flows this serves, why it matters now, and what's at stake if it breaks (revenue, data, trust, a deadline). Skip the generic ("improves the user experience"). If a ticket already argues the case, link it and give one line.

### 🧭 Architecture and concepts

- A diagram only when the change spans three or more components or restructures how they connect. Use a `text` code block of six nodes or fewer, marking new (`+`) and changed (`*`) nodes, with a one-line legend. Otherwise give a one-line call chain, or nothing if the change stays inside one component.
- Two to four concepts the reviewer must understand to judge the diff, mixing framework mechanics (lifecycle hooks, queues, ORM behavior, caching, build vs. runtime) with domain rules (billing periods, permissions, idempotency). One line each with `path:line`. Skip anything a strong developer would infer from reading the code.

### ⚖️ Tradeoffs

One to three bullets. Start with the core design decision: what it buys, what it costs or rules out, and why the obvious alternative lost. Then add anything that looks wrong until explained: an intentional inconsistency, a workaround for an external constraint, a deliberate omission or deferral. These prevent the review round-trips descriptions exist to save.

### 🚨 Risks

The one to three things most likely to cause real harm, ranked by severity × likelihood. Each is one line:

🟠 **med · data** `path:line`: concrete failure scenario, and what guards it or what the reviewer should check.

Use 🔴 high, 🟠 med, or 🟡 low, followed by a one-word tag such as `regression`, `security`, `data`, `perf`, `ops`, `cost`, or `ux`. State a concrete scenario ("invoices with a null `tax_rate` now throw in `total()`"), not a category ("possible null handling issue"). Name a guarding test only if you've seen it, and say whether it ran. If nothing rises to a real risk, write one line: ✅ **Nothing major**, followed by what you checked.

### Post-deploy checklist

If `.claude/post-deploy-checklist.md` has items, include them under `## Post-deploy checklist`, preserving their text, order, and check state. Omit the section when there are none.

## Emoji rules

Emoji should help the reviewer find things, not decorate the page.

- One fixed icon per section heading, as above.
- In the body, use only 🔴 🟠 🟡 for severity, ⚠️ for a warning that isn't a risk, and ✅ for checked and fine. Never put them on neutral bullets.
- Keep the words next to each marker (`🔴 **high**`), so the meaning survives a renderer without emoji.
- No emoji inside code blocks.

## Preserve required context

- A repo PR template beats this shape. Fill its sections, keeping each as short as possible, and fold these sections into it where they fit.
- When revising, describe the final change. Preserve relevant rationale, issue links, and verification evidence from the existing body; remove stale descriptions. Don't silently discard context whose validity is uncertain or change check states without evidence.
- Use supported facts. Never invent measurements, test results, or reasons for a decision.

## Before delivering

Count the words: write the draft to a temp file and run `wc -w`. If you're over 400, cut whatever explains the least. Usual candidates are a fourth concept, a secondary tradeoff, the diagram (fall back to a call chain), and 🟡 risks. Never cut the opening, the core tradeoff, or the top risk.

Then ask of each sentence: does it explain why the PR is needed, give the reviewer a concept or risk they'd otherwise miss, or resolve a likely misunderstanding? If not, cut it. See [the worked examples](references/example.md) for the intended level of detail.

## Deliver

For a description-only request, return Markdown ready to paste. For a request to open or update a PR, prepare the body and complete the authorized action without adding a confirmation step. Pass multiline bodies through `--body-file` or a structured tool argument so shell quoting cannot corrupt them.

Keep the body in the author's voice, with no AI attribution or assistant commentary. Exclude secrets and private data.

## Anti-patterns

- **Narrating the diff.** "This PR modifies `InvoiceService` to…" is a file list in sentences. Lead with behavior, concepts, and risk.
- **Boilerplate sections.** No Summary, Changes, or Testing sections, file or helper inventories, or routine test lists. Mention validation only when the repo or user requires it, or when a specific result or gap affects the review decision.
- **Padding to fill sections.** An empty tradeoff or a manufactured risk costs trust. Drop the section.
- **Becoming a review.** The author is orienting the reviewer, not auditing their own code. Real problems found while writing get fixed or flagged to the user, not buried in the body.
