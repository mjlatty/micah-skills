# Area notes format

One file per area at `<main checkout>/.context/brief-me/areas/<slug>.md`. Write for a future briefing, not for a person reading it cold. Keep it dense, cite `file:line`, and stay under about 80 lines.

```markdown
# app/Billing

verified-at: 8c41d0a (2026-11-17, PR #212 head)
path: app/Billing/

## Owns
Invoice lifecycle (draft → sent → paid → void) and money math. Totals are computed on
read by `Invoice::total()` (Invoice.php:80) and never stored.

## Callers
- InvoiceController (app/Http/Controllers/InvoiceController.php:22): create, send
- StripeWebhookController:41: marks invoices paid on `invoice.paid`
- MonthlyStatementJob:17: reads totals for every customer each month (hot path, ~40k invoices)

## Invariants
- Money is integer cents everywhere. `Money` (Money.php:12) rejects floats.
- A sent invoice is immutable. `InvoiceObserver::updating` (InvoiceObserver.php:20) throws
  on any change except `status`.
- `tax_rate` is nullable: invoices before 2024-03 predate tax support (migration
  2024_03_02_add_tax_rate.php:14).

## Glossary
- **void**: cancelled after sending. Kept for audit and excluded from statements.
- **credit note**: a negative invoice linked by `credits_invoice_id`, not a refund.

## Outside rules
- Stripe retries webhooks for up to 3 days, so handlers must be idempotent on event id.
  https://docs.stripe.com/webhooks#retries
- Ontario HST is 13% on the full amount, and rounding is per line, not per invoice.

## Gotchas from past briefings
- #198: `MonthlyStatementJob` loads invoices without eager-loading `lines`. Any new
  per-line work in `total()` multiplies its query count.
```

Rules:

- **Facts, not findings.** Record how the area works. A PR's danger zone belongs here only if the next change in this area could trip over it again.
- **Cite or cut.** Every claim gets a `file:line`. Claims you can't cite go under a `## Unverified` heading, or nowhere.
- **Rewrite in place.** Fix wrong lines instead of appending corrections. These are notes, not a log.
- **One area per file.** Listing other directories as callers is fine. If a section keeps explaining another directory's internals, and the briefing relied on them, that directory needs its own file.
