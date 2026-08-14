# Templates for the /icps folder

Two templates: the per-ICP profile file and the folder README. Sections marked
*(optional)* may be dropped when they'd be empty; every other section must be
filled or the profile isn't done — write `Unknown — hypothesis:` and a guess
rather than deleting the heading.

---

## Per-ICP profile — `icps/<slug>.md`

```markdown
---
name: <slug, kebab-case, matches filename>
one-liner: <who they are + the pain, in one sentence>
priority: primary | secondary | later | anti
roles: [buyer | user | champion | channel]
last-updated: YYYY-MM-DD
---

# <Human-readable name>

<One-paragraph portrait: the identifying facts that make them findable and
distinguish them from lookalikes — role/title, org size and shape, tools they
live in, how they bill or get paid. Only traits that gate the purchase.>

## Job to be done

<What they're hiring the product to accomplish, in their words, outcome-first.
Not a feature list — the thing they'd say they got done.>

## Pains

<What bleeds or blocks them today. Dollarize wherever possible — cost of the
problem per month/year, hours lost × their rate, revenue leaking. Each pain on
its own line so evidence can attach to it.>

## Motivations

<What they're trying to achieve beyond fixing the pain — look competent to
clients, win a negotiation, close a deal faster, grow the book. This is what
the copy speaks to; pains are what the product fixes.>

## Buying trigger

<The event that makes them buy now rather than someday: renewal, audit, new
client, deal in diligence, rate change, tool sunset. If no trigger exists,
say so — it means the sales motion must create urgency, which is expensive.>

## What they do today

<Current alternative (Excel, consultant, enterprise tool, nothing) and current
spend in dollars or hours. This is the pricing anchor and the competitor.>

## Where to find them

<Named watering holes: orgs, communities, subreddits, LinkedIn groups,
conferences, newsletters — and the search queries they actually type. Specific
enough that outreach could start tomorrow.>

## Willingness to pay

<What tier/price this ICP maps to and why, anchored to current spend and the
dollarized pain. A per-engagement framing helps: "saves 2 hrs per review at
$200/hr → pays for a year in one engagement.">

## Friction & caveats

<The honest section. What's true of this segment that makes activation or
retention hard, and what the product/onboarding must tolerate because of it.
Never leave empty.>

## Product surface that serves them

<Which existing features/pages/endpoints serve this ICP, and which planned ones
they're waiting on. Gaps stated here are roadmap input.>

## Lookalikes to exclude *(optional)*

<Who resembles this ICP but isn't one, and the telltale that separates them —
feeds the README's anti-ICP list.>

## Foreclosure watch *(only for priority: later)*

<What today's product/data-model decisions must not foreclose for this ICP,
so "later" stays possible without a rebuild.>

## Evidence log

<Append-only, newest first. Each entry dated, sourced, and tagged
**validated** or **hypothesis**. When a hypothesis resolves, append the
resolution and revise the sections above.>

- YYYY-MM-DD — **validated** — <claim> (source: <interview/quote/metric>)
- YYYY-MM-DD — **hypothesis** — <claim> (test: <how we'd find out>)
```

---

## Folder index — `icps/README.md`

```markdown
# ICPs — <project name>

<One paragraph: what the product does and the single sentence of who it's for.
Last ranked: YYYY-MM-DD.>

## Ranking

| # | ICP | Priority | Roles | One-liner |
|---|-----|----------|-------|-----------|
| 1 | [<name>](<slug>.md) | primary | buyer, user | <one-liner from frontmatter> |
| 2 | ... | secondary | ... | ... |
| — | ... | later | ... | ... |

## Why this order

<A short paragraph per placement decision that wasn't obvious: why #1 beats #2,
why a big segment sits at "later", what evidence would reorder the list.>

## Who we say no to

<The anti-ICPs, each with the one-line reason: wrong budget shape, needs
enterprise sales, support load a solo founder can't carry. Saying no here is
the point.>
```

---

## Worked example (abridged, from breezyfees)

What a filled profile's sharpness should look like — note the dollarized pain,
the named watering holes, the honest caveat:

> **Billing consultants / small RCM firms** — primary; buyer + user.
> They know their clients' multipliers cold, do fee-schedule math constantly,
> charge $150–300/hr, and currently work in Excel.
> **Pain:** unrecovered underpayments run 1.8–3.4% of paid claims ($10–60k/yr
> per practice, invisible because each variance is a few dollars).
> **Willingness to pay:** a tool that saves 2 hours per fee-schedule review
> pays for a year of subscription in one engagement.
> **Where:** AAPC / HBMA membership, billing-focused LinkedIn groups, podcasts.
> **Friction:** deliverables must be client-brandable or the consultant can't
> justify the spend to their clients.
>
> And the contrasting honest caveat on the #2 ICP (mid-market practices):
> "many don't know their multipliers — the contract-PDF-in-a-drawer problem.
> Onboarding must tolerate 'start with the Medicare rate, add multipliers as
> you extract them.'"
