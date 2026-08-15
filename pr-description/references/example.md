# Worked example

One PR, written twice. Same diff, same facts, same author.

**The change:** branch `feat/transport-retries`, 9 files. Retry logic moves into the HTTP transport; three hand-rolled retry loops in callers are deleted; a `retry_max_attempts` config key replaces three hard-coded numbers; the dead `orders.legacy_status` column is dropped.

---

## Written well

```markdown
Retries move into `HttpTransport::send()`, so every caller gets them from one place. The
hand-rolled loops in `OrderSubmitter`, `InvoiceExporter`, and `WebhookDispatcher` are gone —
each now calls the transport and lets it own backoff.

    OrderSubmitter    ─┐
    InvoiceExporter    ├─→ HttpTransport::send() ─→ Backoff (5 attempts, jittered)
    WebhookDispatcher ─┘

## Why

The three loops had drifted apart: two retried 3 times, one retried 10, and only one jittered.
During the 2026-08-02 payments incident the un-jittered path turned a flapping upstream into a
thundering herd and held it down an extra 40 minutes. One implementation means one number to
tune, and it's now `retry_max_attempts` instead of three literals in three files.

## Notes

- Backoff sits in the transport rather than in HTTP middleware because middleware runs
  per-request and can't see attempt count across retries. Middleware is the obvious choice here
  and it doesn't work.
- `WebhookDispatcher` keeps an outer loop of its own. It retries on business-level errors that
  arrive as `200` with an error body, which the transport can't see. Collapsing the two is
  INFRA-4412.
- `legacy_status` is dropped outright rather than deprecated first — nothing has read it since
  #2871 merged in June.

## Risks & tests

- [x] Retry storm against a flapping upstream — `tests/Transport/RetryTest.php:44` asserts the cap
      holds at 5 attempts and that jitter is applied; run, passes
- [x] Callers double-retrying now that the transport retries — `tests/Orders/SubmitTest.php:118`
      asserts exactly one submit against a 500-then-200 sequence; run, passes
- [ ] Concurrent exports of the same invoice can interleave writes — no coverage, and this PR
      doesn't add the lock. It predates the change, but retries widen the window, so it gets
      easier to hit. INFRA-4418; not a merge blocker.
- [ ] The `legacy_status` migration can't be rolled back — recovery means restoring from backup.
      Verified by hand on a 400k-row staging copy; no automated coverage is possible.
```

Why it works: the first paragraph is the one design decision everything else hangs off. The Notes section spends its three lines pre-empting the exact three questions a reviewer would otherwise ask in a round-trip. Every checked box names a file, a line, an assertion, and the fact it was actually run — and the two honest gaps are unchecked with a reason.

---

## Written badly

```markdown
## Summary

This PR adds retry functionality to improve reliability and code quality.

## Changes

- Added `retryWithBackoff` helper to `HttpTransport.php`
- Updated `OrderSubmitter.php` to use the new helper
- Updated `InvoiceExporter.php` to use the new helper
- Updated `WebhookDispatcher.php`
- Added `retry_max_attempts` to `config/http.php`
- Added migration `2026_08_10_drop_legacy_status.php`
- Added tests

## Testing

- [x] All tests pass
- [x] Tested locally

Low risk — no behavior change.
```

Everything in it is true, and it's worth nothing:

- **The Changes list is the diff retyped.** The reviewer has that, better, with line numbers.
- **"Improve reliability" names no trigger.** There was an incident, with a date and a 40-minute cost. That's the whole argument for the PR and it's missing.
- **No Notes, so review pays for it.** "Why not middleware?" comes back as a comment. The surviving `WebhookDispatcher` loop reads as a missed refactor rather than a deliberate one, so someone asks about that too.
- **"All tests pass" is not a risk.** It pairs no guard to no failure mode, can't be falsified, and would look identical if the change were untested.
- **"No behavior change" is false.** Two callers get a different retry count, one gains jitter, and a column is gone.
- **The irreversible migration is invisible.** The single highest-blast-radius fact about the change doesn't appear anywhere.
