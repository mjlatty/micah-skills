# Archive API reference

## Arctic Shift (primary — use this)

Free, unauthenticated, GET-only, returns JSON. Call it with `curl -s` (or an HTTP fetch tool) — no headers or keys required. It's a volunteer-run service and evolves; if a param below stops working, re-check the live docs linked at the bottom before improvising.

Base URL: `https://arctic-shift.photon-reddit.com`

### Fetch specific posts/comments by ID
```
GET /api/posts/ids?ids=1ur69uv,1ury1bx
GET /api/comments/ids?ids=<id1>,<id2>
```
- `ids` — comma-separated, **no `t3_`/`t1_` prefix**, max 500 per request.
- `fields` — comma-separated list to limit response fields (omit for full object).
- `md2html` — set to render markdown body to HTML.

### Full comment tree for a post
```
GET /api/comments/tree?link_id=t3_1ur69uv&limit=200
```
- `link_id` — **required**, needs the `t3_` prefix (unlike the `ids` endpoint above).
- `parent_id` — fetch a subtree instead of the whole thread.
- `limit` — 1–25000, default 50. Set high for a full thread.
- `start_breadth`, `start_depth` — pagination into large trees.

### Search posts / comments
```
GET /api/posts/search?subreddit=explainlikeimfive&title=black+holes&limit=25&sort=desc
GET /api/comments/search?subreddit=explainlikeimfive&body=black+holes&limit=100
```
- Common: `author`, `subreddit`, `after`, `before` (unix ts or ISO date), `limit` (1–100, or `auto`), `sort` (`asc`/`desc`), `fields`, `md2html`.
- Posts only: `title`, `selftext`, `query` (free text across fields), `url`, `link_flair_text`, `spoiler`, `over_18`.
- Comments only: `body`, `link_id` (restrict to one thread), `parent_id`.
- At least one scoping param (subreddit, author, or link_id) is generally required — unscoped full-text search across all of Reddit will time out.

### Subreddit info
```
GET /api/subreddits/search?subreddit_prefix=machinelearning&limit=10
GET /api/subreddits/rules?subreddits=machinelearning
GET /api/subreddits/wikis?subreddit=machinelearning&page=index
GET /api/subreddits/wikis/list?subreddit=machinelearning
```
- `subreddits` on `/rules` accepts a comma-separated list, max 1000.
- Use `/search` to check subscriber count and confirm a subreddit's exact name before querying it — fuzzy guesses (e.g. `machinelearning` vs `MachineLearning` vs `ml`) can silently return nothing.

### User info
```
GET /api/users/search?author=someuser
GET /api/users/interactions/subreddits?author=someuser
```

### Aggregations (counts over time, useful for "is this trending" questions)
```
GET /api/posts/search/aggregate?subreddit=X&aggregate=created_utc&frequency=week
```
- `aggregate` — `created_utc`, `author`, or `subreddit`.

### Notes
- Score/comment counts on very recent posts may read as 0/1 until ~36h after posting (archival lag) — don't treat a freshly-found thread's low score as real signal yet.
- Rate limit: on `429`, back off until the time in the `X-RateLimit-Reset`/`X-RateLimit-Reset-At` response headers.
- Live docs: https://github.com/ArthurHeitmann/arctic_shift/blob/master/api/README.md

## PullPush (secondary — IP-reputation-blocked in some environments)

Base URL: `https://api.pullpush.io`

Worth one attempt as a cross-check or when Arctic Shift can't serve a query. Whether it works appears to depend on the calling IP: from several sandboxed/datacenter environments (tested repeatedly, several seconds apart, 2026-08) every endpoint below returns HTTP 429 with `{"error":"Rate limit exceeded. This website does not provide free scraping resources for agents. Please contact the administrator on Discord if you're interested in a paid scraping service."}` regardless of user-agent — but it reportedly works from other (e.g. residential) IPs. If you get that exact error, it's IP/traffic-pattern detection, not a transient limit — one retry after a short wait is fine, but don't loop retries or rotate headers trying to beat it; fall back to Arctic Shift instead.

### Search submissions (posts)
```
GET /reddit/search/submission/?q=black+holes&subreddit=explainlikeimfive&size=25
```
- `q` — keyword search.
- `title`, `selftext` — restrict search to just that field.
- `subreddit`, `author` — filters.
- `after`, `before` — unix timestamp or relative (`30d`, `1y`).
- `sort` (`asc`/`desc`), `sort_type` (`created_utc`, `score`, `num_comments`).
- `size` — up to 100, default 25.
- `score`, `num_comments` — comparison filters, e.g. `>100`, `<50`.
- `over_18`, `is_video`, `locked`, `stickied`, `spoiler` — boolean filters.

### Search comments
```
GET /reddit/search/comment/?subreddit=explainlikeimfive&q=black+holes&size=100
```
- Same shared params as submissions (`q`, `subreddit`, `author`, `after`, `before`, `sort`, `sort_type`).
- `sort_type` options for comments: `created_utc`, `score`.
- `size` — up to 100, default 100.
- `link_id` — restrict to comments on one specific post.

### Notes
- Content is user-submitted, not Reddit-owned, per PullPush's stated legal basis for indexing it — still cite the original thread when reporting findings, if you ever do get access.
- Site: https://pullpush.io/ (also 403s automated fetches of the marketing page itself).
