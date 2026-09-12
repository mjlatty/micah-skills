---
name: pr-description
description: Use whenever opening a pull request or writing or revising its body, including requests to put a branch up for review or ship it. Apply before gh pr create or gh pr edit. Produces highly concise descriptions focused on why the PR exists and surprising implementation choices a reviewer cannot readily understand from the code.
---

# PR description

Give the reviewer the context they need to read the code. Explain why the PR exists and anything odd, unexpected, or hard to understand about the implementation. Let the diff explain the implementation itself.

## Gather context

Read the diff against the intended base, relevant commits, and the conversation for the reason behind the change. Use the user-specified or existing PR base; otherwise resolve the repo default and account for stacked branches. Read the existing body when revising, and follow applicable repo instructions and PR templates.

Look for a linked issue and `.claude/post-deploy-checklist.md`. Investigate further only where needed to explain the motivation or a surprising choice. Don't invent rationale from the code alone.

## Write the body

Default to one short paragraph: one or two sentences naming the problem or need and the intended outcome. If a ticket supplies the context, link it and give only enough explanation to orient the reviewer.

Add a few brief notes only when they would prevent a likely misunderstanding:

- A choice that looks wrong or arbitrary until an external constraint is explained.
- An obvious alternative that was ruled out for a non-obvious reason.
- An intentional inconsistency, workaround, or omission the reviewer might mistake for a bug.
- A consequential caveat or required rollout step that is easy to miss in the code.

Explain the reason for each surprise. Include implementation detail only to identify or clarify it. A large diff does not automatically need a longer description.

Aim to keep an ordinary PR under 150 words; a simple change may need only one sentence. Use no headings by default; add bullets or a small section only when they improve scanning. See [the worked examples](references/example.md) for the intended level of detail.

## Cut what the code already says

Delete inventories of files or helpers, call chains, architecture tours, chronological accounts, and summaries of routine edits. Even an accurate high-level implementation summary wastes space if the reviewer can get it more clearly from the code.

Don't add boilerplate Summary, Changes, Notes, Risks, or Testing sections. Omit routine test inventories and generic risk claims. Include validation only when required by the repo or user, or when a specific result or gap affects the review decision; keep it brief and distinguish what ran from what was inferred.

Before finishing, ask of each sentence: does this explain why the PR is needed, resolve a likely misunderstanding, or convey essential information unavailable from the diff? If it does none of those, cut it. State each point once.

## Preserve required context

- Follow the repo's PR template, keeping required sections as short as possible.
- If `.claude/post-deploy-checklist.md` has items, include them under `## Post-deploy checklist`, preserving their text, order, and check state. Omit the section when there are no items.
- When revising, describe the final change. Preserve relevant rationale, issue links, and verification evidence from the existing body; remove stale descriptions and repetition when supported by the current scope. Don't silently discard context whose validity is uncertain or change check states without evidence.
- Use supported facts. Never invent measurements, test results, or reasons for a decision.

## Deliver

For a description-only request, return Markdown ready to paste. For a request to open or update a PR, prepare the body and complete the authorized action without adding a confirmation step. Pass multiline bodies through `--body-file` or a structured tool argument so shell quoting cannot corrupt them.

Keep the body in the author's voice, with no AI attribution or assistant commentary. Exclude secrets and private data.
