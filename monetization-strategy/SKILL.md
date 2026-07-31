---
name: monetization-strategy
description: Use when the user asks how to monetize, price, or turn a project into revenue — business model selection, pricing strategy, "could this make money", revenue path planning, or evaluating an idea against MRR targets. Produces ranked monetization paths with unit economics, not generic brainstorming.
---

# Monetization strategy

Strategize revenue paths for the operator below. Every recommendation must survive contact with their constraints — reject advice that assumes a team, a budget, or an audience they don't have.

## Operator profile (baked in — don't re-ask)

- Solo technical founder who ships fast with AI. Building is nearly free; **distribution and recurring support load are the scarce resources.** Judge every path by those two costs, not build cost.
- Revenue floor: **$10k/mo**. Target: **$25–50k/mo**. A path that can't plausibly reach the floor is dead on arrival; a path that caps near the floor should be flagged as a wedge, not a destination.
- No sales team, no support staff. Default to self-serve, low-touch, product-led. High-touch sales is allowed only when one deal is worth ≥$1k/mo and one person can run the whole pipeline.

## Process

1. **Understand the project first.** Read the repo, product, or description before strategizing. Pin down: what job it does, who feels that pain most acutely, and what those people currently pay for alternatives (their current spend is the pricing anchor). If the project is only described vaguely and you can't inspect it, ask — a strategy for the wrong product is worthless.
2. **Get real comps.** If web search is available, pull actual pricing pages of the 3–5 closest competitors or adjacent tools before setting numbers. Never invent comps.
3. **Do the math backwards** (next section) before naming any model.
4. **Generate 2–3 candidate paths, pressure-test distribution on each, rank, and deliver** in the output format below.

## Revenue math first

Write the customer-count table before proposing anything. $10k/mo requires:

| Price point | Customers needed | What that implies |
|---|---|---|
| $9/mo | ~1,100 | B2C volume game — needs a real distribution engine; avoid by default |
| $49/mo | ~205 | Prosumer/small-team; viable with one strong channel |
| $199/mo | ~50 | B2B self-serve sweet spot for a solo founder |
| $999/mo | 10 | Niche B2B; each logo matters, but 10 is findable by hand |
| $120k/yr contract | 1 | Enterprise; slow, fragile, usually wrong for solo |

Fewer, higher-paying customers is the solo-founder default. B2B beats B2C unless there's an existing organic channel with proof.

Then check the **ceiling**: to reach $25–50k/mo, either the customer count must 3–5x through the named channel, or revenue per customer must grow without new sales. Prefer a **value metric** that scales with customer value (seats, usage, volume processed) so existing customers expand on their own.

## Model fit for a solo founder

Roughly best-first:

- **Niche B2B SaaS subscription** — the default. Painkiller for a specific vertical or workflow; $99–499/mo; self-serve with docs good enough to replace support.
- **Usage-based API/infra** — great expansion dynamics and low support if reliability is nailed; watch for one whale being all the revenue.
- **Prosumer tool, free + paid pro tier** — works when the free tier IS the distribution (shareable output, network exposure). Gate the pro tier on business value, not annoyance.
- **Platform-marketplace apps** (Shopify, Chrome, Slack, VS Code, Raycast, etc.) — built-in distribution, which fixes the solo founder's weakest link; accept the platform-risk tradeoff and 15–30% cut.
- **One-time purchase / lifetime deal** — good cash-flow validation and launch wedge; bad at compounding to $25–50k/mo. Recommend only as a bridge with a stated pivot to recurring.
- **Paid boilerplate / template / course** — revenue spikes then decays; only works with an audience or SEO moat. Flag as side-revenue, not the path.
- **Productized service** — fastest first dollar and great for discovering what to productize, but caps at the founder's hours. Bridge only; name the exit.
- **Ads / marketplace take-rate** — needs traffic volume a solo founder almost never has. Treat proposing this as a red flag unless traffic already exists.

## Newly possible AI-era paths

Consider these alongside the classic models — each exists because AI collapsed a cost that used to require a team. Weigh them honestly; new ≠ better.

- **Service-as-software** — sell the *outcome* at agency prices ($2–5k/mo retainers), deliver it with AI agents at software margins. The strongest new fit for this operator: 3–5 customers clears the floor, and what the agents automate becomes the product spec for a self-serve tier later. Watch the trap: every bespoke customer request is payroll you can't fire.
- **Outcome-based pricing** — charge per resolved ticket, qualified lead, or completed task instead of per seat. Only viable when the outcome is cheaply and uncontestably attributable. Pure outcome pricing is hard to operationalize; the mainstream pattern is hybrid (base subscription + outcome fees), now used by ~41% of SaaS companies.
- **Agents as customers** — expose the product as an MCP server or machine-payable API (x402 pay-per-call is now Linux Foundation–standardized, with Stripe/Visa/AWS backing). Agents discover, pay fractions of a cent per call, and settle in seconds — zero sales motion. Be honest about scale: typical paid MCP servers currently earn $500–3k/mo, so treat this as a distribution channel and revenue *layer* on a product humans also buy, not the whole path. Related: price B2B tools per *agent seat*, not per human seat — human headcount is flat while agent counts grow.
- **AEO/GEO as a channel** — buyers increasingly ask an AI assistant "what tool does X" instead of Googling. Being the tool that assistants cite and recommend (clean docs, llms.txt, registry/marketplace listings, being genuinely the best answer in a niche) is a compounding channel a solo founder can win before incumbents notice.
- **Sequential portfolio** — AI-collapsed maintenance cost makes owning several small $2–4k/mo products viable for one person, where it used to demand a team. This does NOT override the "averaging" anti-pattern: it only works *sequentially* — product one runs on autopilot before product two starts. Buying/reviving a small abandoned tool can be faster than building one.

**Pricing floor for AI-native products:** AI-native SaaS averages ~52% gross margins (vs ~80% traditional) because of inference costs. Price above per-use inference cost with headroom, and meter or gate the expensive paths — a flat low price on an inference-heavy feature is a slow leak.

## Distribution pressure test

Every path must name its channel and why *this* founder wins there. Acceptable answers: SEO/programmatic SEO (compounds while solo), launch platforms (HN, Product Hunt — spike, not a channel), a specific community where the niche already congregates, platform marketplaces, build-in-public/content with an existing footing, or cold outbound (viable for B2B ≥$200/mo — AI makes personalized outbound at volume a one-person job). "Word of mouth" or "virality" with no seed mechanism is not a channel; kill or rework the path.

Name the **first 10 customers** concretely — where they are and the exact motion to reach them. If you can't, the path isn't ready to rank.

## Validate willingness to pay before building more

The founder's speed makes overbuilding the trap: shipping is cheaper than validating, so they'll default to shipping. Force the cheap test first: a landing page with a real price and a "buy"/deposit action, 10 direct conversations with target buyers, a presale, or a concierge version. Define kill/continue thresholds up front (e.g., "20 buyer conversations, <3 would prepay → kill or reprice").

## Output format

Deliver **2–3 ranked paths**, then one clear recommendation. For each path:

- **Who pays and why** — the specific buyer and the pain that makes the purchase obvious
- **Model + launch price** — charge 2–3x what feels comfortable; discounting later is easy, raising is hard. Anchor to comps and to what the buyer already spends on the problem.
- **Math** — the exact customer count to $10k/mo, and the ceiling check against $25–50k
- **Channel + first-10-customers plan**
- **90-day milestones and kill criteria** — measurable, dated, with the decision each triggers
- **Solo load** — the support/ops burden the path commits the founder to at $10k/mo scale

Close with the single next action for this week, not a menu.

## Anti-patterns to call out

- **Pricing to be cheap.** Low price doesn't reduce distribution cost — it just demands 10x the customers and attracts the neediest ones.
- **Freemium before a funnel exists.** A generous free tier with no conversion path is unpaid support duty.
- **A second product before the first hits the floor.** The fast-builder failure mode; redirect energy to distribution of product one.
- **Averaging across paths.** Three half-pursued channels lose to one pursued hard. The ranking exists to pick one.
- **Deferring the price.** "We'll figure out pricing later" means no validation is happening. Price is part of the product from day one.
