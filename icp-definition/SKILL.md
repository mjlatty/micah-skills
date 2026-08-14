---
name: icp-definition
description: Use when the user asks to define, document, or update ICPs (ideal customer profiles) for a project — "who is this for", target customer/audience profiling, customer segmentation, or creating/maintaining a project's /icps folder. Produces ranked, evidence-based profile files committed to the project, not throwaway personas.
---

# ICP definition

Define who a project is for, sharply enough to act on, and save it as a `/icps` folder in the target project so every later decision (pricing, features, copy, SEO, outreach) can cite it. The deliverable is files in the project repo, not a chat answer.

## The deliverable

```
icps/
  README.md              # ranked index, ranking rationale, who we say no to
  billing-consultants.md # one file per ICP, named by slug — no rank prefix
  practice-managers.md   #   (ranks change; renames churn history)
  ...
```

Each profile follows `references/icp-template.md` (also contains the README template). If the project already has an `/icps` folder, update it — never regenerate from scratch, and never delete an evidence log entry.

## Process

1. **Understand the project first.** Read the business plan, `plans/`, docs, README, and the actual product surface (routes, pages, pricing code) before naming anyone. The product's real capabilities and its plans reveal who it's already serving and who it's quietly ignoring. If the project is only described vaguely and nothing is inspectable, ask.

2. **Generate candidates by role, not demographics.** For each candidate, name the role they'd play: **buyer** (holds the budget), **user** (feels the pain daily), **champion** (sells it internally), or **channel** (a customer whose adoption distributes you to their customers — e.g. a software vendor embedding your API). One segment can hold several roles; a channel ICP is still an ICP. Cast wide here — cutting happens next.

3. **Pressure-test every candidate.** A candidate that can't answer these isn't ready to rank:
   - **Pain, dollarized.** What does the problem cost them per month/year, or what do they recover by solving it? "Annoying" is not a pain; "$10–60k/yr walking out invisibly" is.
   - **Current alternative and spend.** What do they do today (Excel, a consultant, an enterprise tool, nothing) and what does it cost them? Current spend is the pricing anchor and the proof the pain is real.
   - **Findability.** Could you list where 10 of them congregate, by name — a membership org, a subreddit, a LinkedIn group, a conference, a search query? "They're everywhere" means you can't reach them.
   - **Buying trigger.** What event makes them buy *now* — a contract renewal, an audit, a deal in diligence, a rate change? No trigger, no urgency, no close.
   - **Honest friction.** What's true of this segment that makes activation hard? (Breezyfees example: mid-market practices are a real ICP *and* most don't know their own payer multipliers — the onboarding must tolerate that.) Every ICP gets at least one caveat; a frictionless ICP is an unexamined one.
   - **Structural position.** Why is this segment underserved — is it an accident (someone will fix it) or structural (incumbents *can't* profitably serve them)? Structural gaps are durable; accidental ones are a race.

4. **Rank, and keep the losers.** Assign each ICP a priority:
   - **primary** — the wedge; product and go-to-market decisions default to this one
   - **secondary** — served deliberately but not first
   - **later** — real, but sequenced after the wedge is proven. Record *what today's decisions must not foreclose* for them (breezyfees kept payer-side teams as "later" specifically so the data model stayed multi-vintage from day one).
   - **anti** — looks like a customer, isn't one. Name who you say no to and why (too enterprise, too support-heavy, wrong budget). Anti-ICPs prevent the most expensive mistakes.

   Rank by sharpness — pain × findability × willingness to pay — not by market size. The biggest segment is usually the blurriest.

5. **Write the files.** One file per ICP from the template; README with the ranked index, a paragraph of ranking rationale, and the anti-ICP list. Map each ICP to the product surfaces and acquisition paths that serve it (which features, which pages, which queries they type) — an ICP no surface serves is a roadmap gap worth stating out loud.

6. **Mark evidence vs. hypothesis.** Every load-bearing claim in a profile is either **validated** (dated: an interview, an insider quote, a paying customer, observed search volume) or **hypothesis** (a guess awaiting a test). Convert relative dates to absolute. The evidence log at the bottom of each profile is append-only — when a hypothesis is confirmed or killed, log it and revise the profile above.

## Quality bar

- **No persona theater.** No invented names, ages, stock-photo biographies, or "values efficiency" filler. Demographics appear only when they gate the purchase (a solo biller and a 10-person RCM firm buy differently; their hobbies don't matter).
- **Wants ≠ pains ≠ triggers.** Keep them separate in the profile: what they're trying to achieve (motivation), what blocks or bleeds them today (pain), and the event that opens the wallet (trigger). Collapsing these produces mush.
- **Specific enough to argue with.** "Billing consultants who know their clients' multipliers cold, charge $150–300/hr, and currently do fee-schedule math in Excel" is falsifiable and actionable. "Healthcare professionals" is neither.
- **Solo-founder reachability check.** This operator is a solo technical founder, self-serve/low-touch only (see the monetization-strategy skill for the full profile). An ICP that requires enterprise sales cycles or a support team to serve is at best a *later*, and the profile should say so.

## Anti-patterns

- **"Everyone with X problem."** That's a market, not an ICP. Segment until the watering holes have names.
- **Ranking by market size.** Sharpness first; a small segment you can name 10 members of beats a huge one you can't reach.
- **One ICP per feature.** Features serve ICPs, not the reverse. If a profile exists only to justify a feature someone wants to build, cut it.
- **Write-once folders.** An `/icps` folder untouched since creation is dead weight. Every customer interview, insider conversation, or churned customer is an evidence-log entry.
- **Flattering profiles.** A profile with no friction section, no objections, and no anti-ICP nearby is marketing copy, not strategy.
