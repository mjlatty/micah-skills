---
name: pr-description
description: Use whenever a pull request is being opened or its body written or revised — "open a PR", "create a PR for this branch", "put this up for review", "ship this", "write the PR description", "draft a PR body", "summarize this branch for review", "update the PR description". Invoke it BEFORE running `gh pr create` or `gh pr edit`: the body is part of opening the PR, not a follow-up step, so a request to open one is a request for this skill. Produces a description pitched at architecture altitude, calls out the decisions a reviewer would otherwise have to reverse-engineer, and pairs each regression risk with the test that guards it.
---

# PR description

Write the part of the pull request the diff can't tell you.

A reviewer already has the diff, and it is a better source than any prose you could write about it. What they don't have is the shape of the change, the reason it exists, the decisions that look wrong until explained, and an honest read on what might break. Write those four things. Everything else is noise standing between the reviewer and the code.

## Build ground truth first

Don't narrate this; just do it.

1. **Resolve the base.** Don't ask what you can look up: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, or `git symbolic-ref --short refs/remotes/origin/HEAD`. Then check for a stack — if another open PR's head branch is an ancestor of this one (`gh pr list --json headRefName,baseRefName`), the base is that branch, not the default. Diffing a stacked PR against the wrong base makes it read as a far bigger change than it is. Ask only when the repo genuinely disagrees with itself.
2. **Get the change.** `git diff <base>...HEAD` and `git log <base>..HEAD` — commit messages often carry reasoning that never made it into the code. For an existing PR, `gh pr view <n>` and `gh pr diff <n>`.
3. **Read the conversation.** If this thread is where the work happened, it holds the alternatives that were tried and abandoned. That's the raw material for the decisions section, and it exists nowhere else.
4. **Read the repo's rules.** `.github/pull_request_template.md` (if present, fill *that* structure — the team chose it), `CLAUDE.md`, `CONTRIBUTING.md`, and the last few merged PR bodies via `gh pr list --state merged --limit 5` to match register and length.
5. **Locate the tests.** Find what covers the changed paths — by filename convention and by grepping for the changed symbols. You'll need real paths later, and you cannot claim coverage you haven't seen.
6. **Link the tracker.** If a ticket ID appears in the branch name or commits, reference it. Don't invent one.
7. **Check for a post-deploy checklist.** If `.claude/post-deploy-checklist.md` exists (written by the `post-deploy-checklist` skill), its items belong in the body.

## Size the body to the change

The four parts are the shape of an ordinary PR, not a quota to fill.

- **A few lines with one obvious intent** — a typo, a version bump, a one-line guard. Two sentences and a single risk line, no headings. A `##` scaffold wrapped around forty words is worse than the forty words.
- **Ordinary change** — the four parts, under 400 words.
- **Sprawling** — the four parts, plus an honest line naming where the PR should have been split. A body that needs a thousand words is usually describing two PRs.

A repo template beats all of this. If `.github/pull_request_template.md` exists, fill its sections even where you'd otherwise skip them.

## The four parts

`references/example.md` shows one PR written well and then written badly, if you want something to check a draft against.

### What changed

Architecture altitude. Name the components that moved and how they now relate — new seams, layers touched, what's new versus modified, what got deleted. A three-to-six line call chain or before/after sketch earns its space here; a file-by-file inventory does not, because that's literally the diff.

The test: if a sentence would be obvious to someone who scrolled the diff for thirty seconds, cut it. "Adds a `retryWithBackoff` helper" is diff-reading. "Retries now live in the transport layer, so every caller gets them and the three hand-rolled retry loops are gone" is the shape.

Lead with the single design decision the rest hangs off. Most changes have exactly one.

### Why it matters

The trigger and the consequence. What was broken, slow, blocked, or impossible before — and what is now true that wasn't. Concrete beats adjectival: "p95 export time went from 40s to 4s on the 10k-row fixture" over "improves performance". If you're citing a number, cite where it came from; if nobody measured, say the expected direction and don't dress an expectation as a result.

Two to four sentences. If a ticket already argues the case, link it and summarize in one line rather than restating it.

### Notes

The decisions that look wrong or arbitrary to a fresh reader. This is the highest-value section and the one people skip, because the author has stopped finding their own choices surprising.

Candidates:

- A path not taken, and why — especially the obvious one the reviewer will ask about
- Something deliberately left inconsistent with the rest of the codebase, and what it's waiting on
- A constraint from outside the diff forcing the shape: an API's rate limit, a migration that must ship first, a library bug
- Scope boundaries — what's knowingly deferred, and to when
- Anything that *looks* like a bug and isn't, so review doesn't burn a round-trip on it

One line each, and only for things a competent reviewer would actually stumble on. An empty Notes section is a fine outcome; a padded one trains people to skip it. If a note runs past three lines it wants to be a code comment instead — put it there and say so here.

### Risks & tests

Pair every regression risk with the automated test that would catch it. That pairing is the whole point: a risk list with no guards is hand-waving, and a test list with no risks is inventory.

```markdown
## Risks & tests

- [x] Retry storm against a flapping upstream — `tests/transport/RetryTest.php:44` asserts the backoff cap holds at 5 attempts; run, passes
- [x] Existing callers double-retrying now that transport retries — `tests/orders/SubmitTest.php:118` covers the un-wrapped path; run, passes
- [ ] Webhook signature check on the retried request — `tests/webhooks/SignatureTest.php:31` looks right but needs a live signing key; not run: no credentials locally
- [ ] Concurrent exports on the same invoice can interleave writes — no coverage; needs a test before merge
- [ ] Rollback safety: the migration drops `legacy_status` and is not reversible — manual verification only, see below
```

Rules for the boxes, because they're claims a reviewer will trust instead of checking:

- **Check a box only after reading the test body** and confirming it fails if the change regresses. A file whose name matches is not evidence, and neither is a test that would pass with the change reverted.
- **Run the test you're citing, scoped to it** — the one file, or a `--filter`/`-k`/`-run` on the changed symbol. Never the whole suite: it's slow, it OOMs on big repos, and it isn't what makes this box true. Green means check the box.
- **If you can't run it, the box stays open.** No runner, missing fixtures, needs a live service, sandboxed — write `not run: <reason>` on the line. An unrunnable test is an honest gap; a box checked on inference is a lie the reviewer will act on.
- **Never check a box for a test you know is failing or skipped.** If it's red, say so plainly and quote the failure.
- **Unchecked means work, not decoration.** Each one states what's missing and whether it blocks merge.
- **Name what can't be automated** — manual steps, a staging check, a feature-flag rollout order — as its own unchecked line. Silence there reads as "nothing to do".

Rank by blast radius: data loss and auth first, then anything touching money or a public contract, then everything else. Include the boring risks that bite — migrations that can't roll back, cache/serialization format changes, altered default behavior for existing callers, anything whose failure mode is silent.

### Post-deploy checklist (only if the file exists)

If `.claude/post-deploy-checklist.md` exists and has items, render it as-is under a `## Post-deploy checklist` heading — same lines, same order, same check state. Skip the section entirely if the file is missing or empty; don't manufacture one.

## Revising an existing body

Revising isn't rewriting. What's already on the PR was written by someone who knew things you're reconstructing from a diff, so treat it as the source and edit it — don't regenerate from scratch and call the result a revision.

- **Fold in only what's new.** Work out which commits the current body already covers, then read `git log` forward from there. Most revisions are an amendment, not a replacement.
- **Keep their claims, ordering, and voice.** If you think a claim has gone stale, raise it with the user rather than quietly deleting it.
- **Preserve check state.** A box the author checked stays checked unless you verified it now fails. You don't have their manual-verification context.
- **Say what you changed** in a line or two, so they don't have to re-read the whole body to find your edits.

## Output

Default to Markdown printed in the chat with `##` headings, ready to paste. Match the repo's template and heading names if it has one.

Give the draft the `prose-style` editing pass before printing — PR bodies are its stated use case, and flab is this document's characteristic failure.

Length is the constraint that makes it useful: a reviewer skims this in under a minute or ignores it. Aim for under 400 words for an ordinary change. A large refactor can run longer, but if it's running much longer the PR probably wants splitting — say so.

Creating the PR is a separate act from writing the body. "Write the description" means print it and stop. "Open a PR" means write the body first, show it, confirm the target branch, and then run `gh pr create` — the body is the deliverable either way, and a PR opened with a body you never showed them is the failure this skill exists to prevent. Pushing a description to a shared remote is outward-facing and hard to un-see.

When you do, pass the body as `--body-file <path>` (or `--body-file -` on stdin), never `--body "..."`. Backticks, `$`, and newlines get eaten by the shell, and a fenced code block — the thing most worth including — is exactly the payload that breaks.

## Never in a PR body

- **Any AI or tool attribution.** No "generated with", no co-author trailers, no assistant-voice asides. The description speaks as the author.
- **First person about the assistant.** "I refactored…" is wrong; write in the change's voice — "Retries move into…". Team-voice "we" is fine if that's the repo's register.
- **Credentials or internal-only detail.** API keys, tokens, connection strings, customer names or data, internal hostnames and dashboard URLs. Scrub them from quoted logs and stack traces too. Assume the body is public even when the repo is private — it travels through email, integrations, and forks.
- **Exploitable specifics for a security fix in a public repo.** State that it hardens an input path; don't publish the reproduction. Keep the detail in the private tracker and link it.
- **Absolute guarantees.** "Fully secure", "eliminates all races", "guaranteed backwards compatible". They're unprovable and they age into liability. Say what was tested and under which conditions.
- **Commentary on people or vendors.** Not "the old code was garbage", not "$VENDOR's API is broken". Describe the behavior, not the author or the company. PR bodies get quoted in places you can't predict.
- **Speculation stated as fact.** If you didn't verify it, mark it as expectation. Also don't assert someone else's intent — "this was probably meant to…" — when you can just describe what the code does.
- **Copied text you don't have rights to.** Vendor docs, licensed source, another company's internal write-up. Link and paraphrase.

## Anti-patterns

- **Narrating the diff.** A bulleted list of every changed file is the reviewer's own scroll bar, retyped. Cut to the shape.
- **A summary of the summary.** An intro paragraph that restates the four sections in worse detail. Start with the content.
- **Checked boxes as vibes.** The single fastest way to lose a reviewer's trust is a checked box that doesn't hold. Verify or leave it open.
- **Risk sections that only list risks that don't exist.** "Low risk, no behavior change" on a diff that changes behavior. If there's genuinely nothing, one honest line is better than manufactured caution.
- **Padding Notes.** Filling it with restated obvious choices trains reviewers to skip the section where the real landmine will eventually sit.
- **Explaining what the code is instead of why it is.** The diff already answered "what". This document exists for "why".
