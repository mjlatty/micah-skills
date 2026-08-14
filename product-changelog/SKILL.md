---
name: product-changelog
description: Use when the user asks to write a feature announcement, changelog entry, or social post based on a feature branch
---

# Product changelog

Write a user-facing feature announcement based on the current branch and conversation thread.

Read the prompt file at `docs/product-changelog/product-changelog-prompt.md` in the current project for style, structure, and content guidelines. Follow them exactly.

## Who it's addressed to

If the project has an `icps/` folder (from the `icp-definition` skill), read `icps/README.md` and the profile for whoever this feature serves — a shipped feature almost always maps to one. It sets three things:

- **The lead.** Open on the ICP's job to be done or the pain this removes, in their words. "You can now export to CSV" is a release note; "Stop rebuilding the payer table by hand every quarter" is an announcement.
- **The vocabulary.** Their terms for the workflow, not the codebase's. Check the profile's portrait for what they call things.
- **The proof.** A dollarized pain from the profile turns a feature claim into a number. Only use figures the evidence log marks **validated** — a hypothesis is not a customer-facing statistic.

If the feature serves an ICP ranked **later**, or mostly serves an **anti-ICP**, note that for the user before writing. It's usually a signal the announcement should be scoped down, or that the roadmap drifted.

No `icps/` folder: infer the audience from the branch and thread, and state the assumption at the top of the draft so it can be corrected.

Output the post to `docs/product-changelog/` with a descriptive filename.
