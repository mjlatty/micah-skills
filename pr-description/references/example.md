# Worked examples

## Ordinary change

Suppose three callers have different retry policies, which amplified an upstream outage. The PR consolidates retries in the transport. One caller still needs a separate retry loop for errors returned in successful HTTP responses.

### Useful description

```markdown
Inconsistent retry policies amplified the last upstream outage. This gives callers a shared backoff policy so retries ease pressure while the upstream recovers.

`WebhookDispatcher` intentionally keeps its outer loop: it handles business errors returned as HTTP 200, which transport retries cannot detect.
```

The first paragraph gives the reason and intended outcome. The second explains the one detail likely to look like an incomplete refactor. That's enough.

### Unnecessary expansion

```markdown
## Summary

Retries now live in the transport layer. OrderSubmitter, InvoiceExporter, and WebhookDispatcher call HttpTransport::send(), which delegates to Backoff.

## Changes

- Added a shared retry helper and retry_max_attempts configuration.
- Removed the individual retry implementations from callers.
- Updated transport and caller tests.

## Testing

- Transport tests pass.
- Caller tests pass.
```

This gives the reviewer an implementation tour they can get from the code. It omits both the outage that motivated the work and the reason for the surviving loop. Routine test results don't need their own section unless the repo or user requires one.

## Simple change

```markdown
Long project names hid the delete action on narrow screens. Keep it reachable without horizontal scrolling.
```

No implementation notes are needed when the code is straightforward.
