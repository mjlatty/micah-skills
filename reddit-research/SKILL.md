---
name: reddit-research
description: Use when researching a topic, product, question, or sentiment by pulling information from Reddit — finding the right subreddits, searching threads/comments, and reading a specific thread's discussion. As of May 2026 Reddit blocks unauthenticated access to `.json` endpoints and old.reddit.com (403s for bot-like clients), so this skill routes fetching through the Arctic Shift archive API (reliable) with PullPush as an opportunistic secondary source that IP-reputation-blocks a lot of agent/datacenter traffic.
---

# Reddit research

Reddit is a strong source for real-world opinion, troubleshooting threads, and niche expertise, but it can no longer be scraped directly. Reddit deprecated unauthenticated `.json` access in May 2026; direct requests to `reddit.com/.../.json`, `old.reddit.com`, or Reddit's own search from a script/agent will return 403 (TLS fingerprinting + IP reputation blocking, not just a missing header). **Never spend time retrying direct reddit.com fetches — go straight to the archive APIs below.**

## Workflow

1. **Discover candidate threads/subreddits with web search**, not a Reddit fetch. Reddit pages are indexed by search engines even though direct fetches are blocked. Use `WebSearch` with `site:reddit.com` (optionally `site:reddit.com/r/<subreddit>`) plus the topic. This surfaces thread titles, subreddit names, and URLs — from a URL like `reddit.com/r/personalfinance/comments/1ur69uv/some_title/`, the base36 segment after `/comments/` (`1ur69uv`) is the post ID you'll need for step 3.

2. **Identify the right subreddit(s).** A topic often has both a large default subreddit (broad, more noise, faster answers) and smaller niche subreddits (slower, higher signal, more expert-level). Prefer the niche one for technical/expert questions, the default one for general sentiment. Use the Arctic Shift subreddit endpoints (see `references/apis.md`) to check subscriber count and activity before trusting a small subreddit's consensus — a "top" answer in a 200-member subreddit carries less weight than one in a 2M-member subreddit.

3. **Pull the actual content via Arctic Shift, not the live site.** Use `arctic-shift.photon-reddit.com` — free, unauthenticated, no key. Fetch a specific post by ID, walk a full comment tree, or run structured search (subreddit + date range + keyword). Treat this as the default, reliable path.

   Full endpoint and parameter reference: `references/apis.md`. This is a small volunteer-run service and it evolves — if a request 400s/404s, don't guess harder; re-fetch the live docs (`https://github.com/ArthurHeitmann/arctic_shift/blob/master/api/README.md`) since params do drift.

   **PullPush (`api.pullpush.io`) is worth trying as a secondary source, but it IP-reputation-blocks a lot of agent/datacenter traffic.** When blocked it returns `{"error":"Rate limit exceeded. This website does not provide free scraping resources for agents..."}` — this is environment-dependent (it reportedly works fine from some IPs/contexts) rather than a universal ban, so one attempt is worth it. But if you see that exact error, it's the environment being flagged, not a transient rate limit — don't retry-loop, back off, or rotate headers trying to beat it. Try once, and if blocked, fall back to Arctic Shift instead.

4. **Weigh signal, don't just quote the top comment.** Score/upvotes indicate community agreement, not correctness — corroborate load-bearing claims across threads or subreddits when the answer matters (troubleshooting steps, factual claims, purchasing decisions). Note comment age: Reddit answers rot (deprecated tools, old prices, changed APIs) — check `created_utc` and prefer recent threads for anything time-sensitive.

5. **Cite sources when reporting back.** Give the subreddit, thread title, and permalink (`reddit.com/r/<subreddit>/comments/<id>/`) for anything you rely on, plus the comment's score and date if quoting a specific comment. This lets the user sanity-check weight and recency themselves.

## Practical notes

- Arctic Shift is free with no auth — be a good citizen: don't loop tight retries, back off on `429`s (it returns `X-RateLimit-Reset` headers), and keep `limit` reasonable for what you actually need rather than pulling max pages speculatively.
- Deleted/removed content shows as `[removed]`/`[deleted]` in the body but the archive may still have the original text from before removal — useful for context, but don't present removed content as if it's still live on Reddit.
- If a user has their own authenticated Reddit API (OAuth) credentials already configured in the environment, prefer that over the archives — it's fresher and has no coverage gaps. Otherwise these archives are the only reliable unauthenticated path as of 2026.
