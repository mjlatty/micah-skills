---
name: post-deploy-checklist
description: Use when the user asks to add something to the post-deploy checklist, flag a manual step for after deploy, or leave a reminder for after this ships — "add to post-deploy checklist", "remind me after deploy to...", "post-deploy: flip the feature flag", "don't forget to backfill X once this merges". Captures the item into a durable file so it survives to whenever the PR actually gets written, even in a later session.
---

# Post-deploy checklist

Capture manual steps that have to happen after this change ships — feature flags, cache busts,
backfills, credential rotation, notifying a team — so they don't live only in this conversation and
get lost by the time the PR is opened.

## Capture

1. Find (or create) `.claude/post-deploy-checklist.md` in the repo root. Don't ask where — that's
   the fixed location `pr-description` also reads from.
2. If the file doesn't exist yet, create it with a `# Post-deploy checklist` heading, and add the
   path to `.gitignore` if it isn't already covered — this is a scratch file, not something that
   should show up in the diff or survive the merge.
3. Append the item as `- [ ] <item>`, tightened to one line in the requester's own words. Don't
   editorialize, expand it into a paragraph, or invent detail they didn't give you.
4. Append only — don't dedupe, reorder, or rewrite existing lines. Order usually reflects the order
   dependencies emerged in, and that's worth keeping.
5. Confirm what got added in one line. Don't re-print the whole file unless asked.

## Retire

When the user says an item is done or no longer needed, check it off (`- [x]`) rather than deleting
it — the file is the record of what actually happened post-deploy, not just a todo list. Only
delete a line if they explicitly say it was added by mistake.

## Handoff to the PR

This skill only writes the file — it doesn't touch the PR itself. `pr-description` is what turns it
into a `## Post-deploy checklist` section in the PR body. Don't render or duplicate that here, and
don't run `gh pr edit` from this skill.
