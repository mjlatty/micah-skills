# Product lab: decisions compared by their consequences

For variants judged by what follows from them: pricing and packaging, onboarding, what v1 includes,
the free tier, a feature's scope, positioning, naming. Product variants look like choices only in
the abstract. "Freemium or trial" sounds like a decision, but the decision lives in the specifics:
the limit that triggers the upgrade, the screen where it appears, the customer it loses. So each
variant is written as concretely as the thing a customer would meet, grounded in the product as
built.

## Read first

- **Current, from the code.** What the product does today, read from the code and the data rather
  than the marketing: the real limits, the real signup steps, the real price. It goes in the
  document as an unlettered reference. If nothing exists yet, there's no Current. The default the
  user would ship without asking competes as one of the five, written as concretely as the rest.
- **The scope, whole.** Each variant is a complete answer at the scope the user named. "Variants on
  pricing" means five whole pricing models, each with its own value metric, tiers and free offer
  chosen to work together, not a metric, a tier list and a free offer to pick separately. Split into
  parts only when the user asks for that by name.
- **Who it's for.** If the project has an `icps/` folder, write for its top-ranked profile, and have
  each variant say which profile it serves and which it turns away. If not, state the assumed
  customer in one line; the `icp-definition` skill can fill the gap later.
- **The user's constraints.** Time, money, and the kind of business they'll run, from memory or
  project instructions (self-serve only, no sales calls). A variant that needs a sales team for
  someone who won't do sales isn't a variant.
- **The evidence on hand.** Analytics, database counts (how many accounts hit the current limit),
  support notes, competitor pricing pages (fetched, not recalled), and Reddit threads (the
  `reddit-research` skill). Evidence grounds the variants; it isn't there to decorate them.

## Build the lab

One document, `.context/lab/<topic>/lab.md`:

- A table at the top, in ranked order: rank, letter, short name, the idea in one line, and a
  one-line reason for its rank. Current is the first row, unranked.
- A section for Current, then one section per variant in ranked order, every one with the same
  headings, so they compare heading by heading:
  - **The idea**, in one line.
  - **What the customer meets.** The concrete artifact: the pricing table with prices and limits,
    the onboarding as its screens in order with their copy, the upgrade prompt and when it fires,
    the launch post. If it's a page, write its content here; render it in a visual lab only after
    it's picked.
  - **Who it's for, and who it loses.**
  - **What it takes to build**, read from the code: what already exists, what's new, which parts of
    the system it touches, and a rough size.
  - **What it costs to run:** support load, manual work, infrastructure, payment fees.
  - **The numbers.** Revenue or conversion math where it matters, with every input either sourced
    or marked as an assumption. Use the `monetization-strategy` skill for unit economics.
  - **What it commits to.** How reversible it is: prices you'd have to grandfather, data you can't
    un-collect, a promise made in public copy.
  - **The bet.** The assumption that has to hold, and the cheapest way to test it before building.
- A `Pick:` line at the end for the user to fill in: one letter, or a mix like `B+D` with a note.

Product variants are cheap to write and depend on each other's framing, so write all five
yourself. Parallelize only the research behind them when it's heavy (competitor pages, Reddit, data
pulls).

## Axes to split on

- who it's for: the top profile or the second, the buyer or the user
- what it charges for: seats, usage, outcomes, or a flat fee
- where the friction goes: up front (a card at signup), at the moment of value, or nowhere
- scope: the narrowest wedge that's useful, or the complete version
- manual or built: done by hand for the first customers, or automated from day one
- reversibility: a cheap experiment, or a commitment

Spread the five across these. Each is a whole answer, so a variant takes a position on several axes
at once; make sure no two take the same positions.

## Checks

A variant is checked when every number is sourced or marked as an assumption, every capability it
depends on exists in the code or appears in its build cost, its artifacts agree with each other (the
limits in the pricing table match the upgrade prompt), and it fits the user's constraints.

## Presenting

Lead with the ranked table, then show A's concrete artifacts and those of the most distinct
others. Rank by fit with the top profile and the user's constraints, and let the rank reasons say
which. Product caveats
to look for: an invented number, a competitor claim from memory, a variant that quietly needs a
capability the product lacks, one that contradicts the ICP or the user's constraints, and math that
only works at an optimistic conversion rate. Say which rate it needs.

The user may answer with "test B against C" instead of a pick. Then the next step is the cheapest
test from those variants' bets, not another round.

## Later rounds

Start a fresh document for the round with five new letters (F–J in round two), ranked, with
Current and the previous pick as unlettered references at the top, so each new variant reads
against their choice. Product
taste often shows up as a stance on risk or effort ("nothing I'd have to support by hand",
"charge from day one"). Name it in the taste sentence.

## Promote

A product pick doesn't ship by itself; it becomes the brief for what does.

- Write the decision as a plan (the `plan-docs` skill): the pick, the losers with why, and the bet
  with how it will be checked.
- Hand the surfaces on: pages and copy to a visual lab or the `copywriting` skill, open
  implementation questions to an engineering lab.
- The lab document stays in `.context/lab/` as the record. There's nothing in the app to clean up.
