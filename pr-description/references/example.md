# Worked examples

## Ordinary change

Suppose three callers of the payments provider have different retry policies, which amplified an upstream outage. The PR consolidates retries in the transport. One caller still needs a separate retry loop for errors returned in successful HTTP responses.

### Useful description

```markdown
Retries move into the shared HTTP transport so every call to the payments provider backs off the same way. Inconsistent per-caller retries amplified the last provider outage (#412).

### 🏢 Business context

Checkout, invoice export, and webhooks all call the payments provider. During the outage, one caller's tight retry loop tripped the provider's rate limit and blocked checkout for every customer for 20 minutes.

### 🧭 Architecture and concepts

`OrderSubmitter | InvoiceExporter | WebhookDispatcher → HttpTransport::send() → Backoff`

- **Retry ownership.** Callers no longer retry transport errors; `HttpTransport` does, up to `retry_max_attempts` (`config/http.php:12`).
- **Errors inside a 200.** The provider reports some business failures in a successful response body, which the transport can't see (`WebhookDispatcher.php:58`).

### ⚖️ Tradeoffs

- One policy for all callers instead of per-caller tuning. Nothing needs different limits today, and the config key leaves room if something does.
- `WebhookDispatcher` keeps its outer loop for 200-with-error responses. It looks like an unfinished refactor but isn't.

### 🚨 Risks

🟡 **low · ops** `InvoiceExporter.php:31`: the export's retry cap drops from 10 to 5, so a long provider blip now fails the batch sooner. Failed batches requeue on the next nightly run.
```

The opening gives the change and the reason. Business context says why a reviewer should care. The concepts are the two things needed to judge the diff, and the tradeoffs explain the choice and the leftover loop that would otherwise draw a review comment. The one risk is concrete and says what limits the damage.

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

This tours the implementation the reviewer can read in the code. It omits the outage that motivated the work, the reason for the surviving loop, and the lowered export cap.

## Simple change

```markdown
Long project names hid the delete action on narrow screens. Keep it reachable without horizontal scrolling.
```

No sections are needed when the change is small and carries no real risk.
