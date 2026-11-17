# Risk checklist

Sweep each category against the diff. The triggers say what in a diff should make you look harder. They're prompts, not findings: report only what you can tie to a concrete scenario at a `file:line`.

## regression

- Changed signature, return shape, default value, or exception type in code with callers outside the diff. Grep for every caller.
- Changed behavior behind an unchanged name. Callers keep compiling and silently do the wrong thing.
- Removed or narrowed branches: a deleted `else`, an early return, a tightened validation rule that rejects data that's valid today.
- Serialized formats: API responses, events, queue payloads, cache entries, cookies. Old producers or consumers still exist during a deploy.
- Ordering and timing: sync work made async, a listener reordered, a transaction boundary moved.
- Tests edited to pass instead of fixed: changed assertions, deleted tests, new skips.

## security

- New or changed routes, endpoints, commands, or webhooks. Who can reach them, and does the authz check live where siblings put it?
- Authorization by ID: can user A pass user B's record ID (IDOR)? Look for lookups not scoped to the current user or tenant.
- User input reaching SQL, shell, file paths, templates, redirects, or outbound URLs (injection, path traversal, open redirect, SSRF).
- Raw output of user content (XSS), with the escape hatch disabled: `{!! !!}`, `dangerouslySetInnerHTML`, `|safe`, `html_safe`.
- Mass assignment: new fillable or permitted fields, or `$request->all()` style passthrough.
- Secrets in code, logs, error messages, or client bundles. New env vars exposed to the frontend.
- Auth, session, CSRF, CORS, or cookie flag changes. Crypto or token generation that's hand-rolled.
- New dependencies: maintenance, popularity, install scripts, typosquat-adjacent names.

## data

- Migrations: are they reversible, do they lock large tables, do they backfill in one statement, and do they drop or rename a column that running code still reads?
- Nullability or default changes against existing rows.
- Deletes and cascades, especially new `onDelete('cascade')` or bulk updates without a narrow `where`.
- Idempotency: jobs, webhooks, and retries that can run twice.
- Race conditions: read-modify-write without a lock or atomic update, uniqueness enforced only in code.
- Timezones, currency rounding, and unit conversions.

## perf

- Queries inside loops (N+1), new relations loaded per item.
- Unbounded queries or collections: no limit, no pagination, `->get()` on a table that grows.
- Work added to a hot path: request middleware, every page render, every job.
- Missing index for a new `where` or `order by` on a large table.
- Synchronous external calls in a request without a timeout.

## ops

- New env vars, config keys, queues, cron entries, or services that must exist before or after deploy.
- Deploy ordering: migration before code, or code before migration. Is there a window where old code meets the new schema?
- Feature flags: default state, cleanup plan, and behavior when the flag service is down.
- New failure modes with no logging, metric, or alert.
- Changes to CI, build, Docker, or infra files.

## legal

- New dependencies or vendored code. Check the license against the project's: GPL or AGPL in proprietary or distributed code, no license at all, or a license header removed from copied code.
- New collection, storage, logging, or third-party sharing of personal data such as emails, IPs, location, payment, or health data. That may implicate the privacy policy, GDPR/CCPA, or data-processing agreements.
- Analytics, tracking pixels, or non-essential cookies added without consent handling.
- Third-party APIs or scraping where the provider's terms restrict the use: rate limits, redistribution, caching, or AI training.
- Fonts, images, icons, or copy with unclear licensing.
- User-facing claims, pricing, billing, refund, or terms text: anything a regulator or customer could hold you to.
- Accessibility regressions on public UI, where ADA or EAA exposure applies.

## ux

- User-visible contradictions: copy, dates, prices, or screenshots that disagree with each other or with what the product does.
- States the UI can now reach that nobody designed for: empty, loading, error, permission denied, very long content.
- Changed defaults or flows that existing users will notice without being told.

## cost

- New paid API calls, especially per request or in a loop: LLMs, SMS, email, maps, enrichment.
- Retries or fan-out that multiply those calls.
- New infrastructure such as queues, storage, or instances, and log volume.
