---
name: technical-blog
description: Use when the user asks to write a technical blog post from a feature development or bug fix conversation thread
---

# Technical blog

Write a technical blog post based on the current conversation thread.

Read the prompt file at `docs/technical-blog/technical-blog-prompt.md` in the current project for style, structure, and content guidelines. Follow them exactly.

## Check `icps/` for who's reading

If the project has an `icps/` folder (from the `icp-definition` skill), read `icps/README.md` and any profile plausibly in the readership. Use it for:

- **Depth and vocabulary.** The profile's portrait says which tools they live in and what they already know. Write past that, not up to it — explaining fundamentals to practitioners is the fastest way to lose them.
- **The hook.** Frame the problem as the pain the profile documents, so a reader recognizes their own week in the first paragraph.
- **Distribution.** "Where to find them" names the communities and search queries where this post has a chance. A post with no plausible destination in any profile is worth writing only for reasons you should state out loud.

Be honest about the mismatch when there is one. A technical post usually reaches the **user** or **champion** role rather than the buyer, and plenty of good engineering writing serves recruiting or reputation instead of any ICP. That's a fine reason to publish — just don't retrofit a sales angle onto it, and don't let ICP language flatten a post whose value is the technical detail.

No `icps/` folder: write for the practitioner the thread implies, and say who that is at the top of the draft.

Output the post to `docs/technical-blog/` with a descriptive filename.
