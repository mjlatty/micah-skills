---
name: linked-prs
description: Use when a Conductor workspace (or any worktree) has opened more than one PR and a later request should apply to all of them — "linked PRs", "both PRs", "the PRs", "all the PRs from this workspace", "rebase the linked PRs", "fix CI on both", "address review comments on the linked PRs", "merge the stack". Also use right after opening a second or later PR from the same workspace, when the user lists PRs to link ("link #581 and #583"), or to unlink or list them. Records the set in a per-workspace file so later requests reach every PR, not just the one checked out.
---

# Linked PRs

One workspace often ships its work as several PRs: a stack, or siblings split by topic. Conductor
shows only the checked-out branch's PR, so the others drop out of view, and a later "fix CI on the
PRs" gets done to one and silently skips the rest. This skill keeps the set in a file and treats a
request aimed at "linked PRs" as a request for every member.

## Where the set lives

Use `.context/linked-prs.md` at the workspace root. Conductor gitignores `.context/` and keeps it for
the workspace's lifetime, which matches the set's lifetime. Outside Conductor, use
`"$(git rev-parse --git-dir)/linked-prs.md"`: it's per-worktree and never tracked. Don't ask where.

```markdown
# Linked PRs

- mjlatty/linkfount-tall#581 · `mjlatty/signup-fixes` → `master` · sign-up email crash, upgrade return links, checkout without a confirmed email
- mjlatty/linkfount-tall#583 · `mjlatty/billing-settings` → `master` · billing and settings problems
```

Write one line per PR: `owner/repo#N`, head branch → base branch, and a short scope in the user's or
PR's own words. The file records membership only. Read state (open, merged, CI, review) live from
GitHub each time, never from the file.

## Record

Add PRs to the set when:

- You open a PR and this workspace has already opened another one. Add both. Don't wait to be
  asked; this is the case that gets lost.
- The user names PRs to link, or pastes a list like "I opened #581 … and #583 …".
- The user says "link this one too".

Get head and base with
`gh pr view <N> --repo <owner/repo> --json number,url,headRefName,baseRefName,title`. Append, and
don't add a PR that's already listed. A PR whose base is another member's head is part of a stack.
The head → base column already captures the order, so don't record the order separately. Confirm
the change in one line, e.g. "Linked #583 with #581."

Remove a line only when the user says to unlink it. Merged and closed PRs stay in the set; the act
step skips them.

## Resolve the set

When a request says "linked PRs", "both", "the PRs", or "all of them" and context doesn't point
elsewhere:

1. Read the file.
2. If it's missing or empty, rebuild a candidate set. Find the current branch plus every branch this
   worktree has switched to (the HEAD reflog is per-worktree), then look up their PRs:

   ```sh
   { git branch --show-current
     git reflog show HEAD --format=%gs | sed -n 's/^checkout: moving from .* to //p'; } | sort -u |
     while read -r b; do gh pr list --head "$b" --state all --json number,url,state,headRefName,baseRefName --jq '.[]'; done
   ```

   Add any PRs this conversation opened. Show the candidates and confirm before acting; a
   reconstructed set is a guess. Write the confirmed set to the file.
3. Refresh each member with `gh pr view <N> --repo <owner/repo> --json state,headRefName,baseRefName,mergeable,isDraft`.

The user asking about "linked PRs" is what authorizes acting on every member. Don't ask about each
PR separately.

## Act on every member

Run the request against each open member, using that PR's own context. "Address review comments"
means each PR's own comments. "Fix CI" means each PR's own failing checks. Don't copy one PR's fix
into another unless the request asks for the same change in all of them.

- **Read-only** (status, checks, comments, summaries): loop `gh` per PR without checking anything
  out.
- **Metadata** (labels, reviewers, ready for review, body edits, merge): loop `gh pr edit`,
  `gh pr ready`, or `gh pr merge` per PR.
- **Code changes**: check out each member's branch in turn in this worktree.
  1. Before the first switch, commit or set aside anything uncommitted with a WIP commit. Never
     use a bare `git stash`; the stash is shared with other worktrees.
  2. `git switch <head>`, then `git pull --ff-only`, since the remote may have moved.
  3. Make the change, run only the tests it touches, commit, and push.
  4. Note the starting branch before the first switch, so you can return to it at the end.

**Order.** Work through siblings in any order. Work through stacks bottom-up. After a lower
branch changes, rebase the next branch onto it and push with `--force-with-lease`. When merging a
stack, merge one PR at a time, and check that the next PR's base and mergeability are what you
expect before you merge it. A squash merge below usually means the next PR needs a rebase.

**Skip and say so.** Skip a merged or closed member. If the request plainly concerns only one
member's content, e.g. "fix the billing redirect" when only #583 touches billing, do it there.
In both cases, name the skipped PR and give the reason. Never drop a member silently; preventing
that is the whole point of this skill.

**Finish.** Check out the branch Conductor should show: the starting branch, or the top of the
stack after a stack operation. Then report one line per PR:

```
#581 — rebased on master, pushed; CI running
#583 — skipped: already merged
```

## What this skill doesn't do

Don't write the links into the PR bodies or post cross-link comments unless asked. This file is
for you; the PRs are what reviewers see.
