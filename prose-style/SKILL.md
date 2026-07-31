---
name: prose-style
description: Use when writing or editing prose — docs, PR/commit descriptions, code comments, explanations, or general written responses — to tighten sentences and cut flab. Not for marketing/promotional copy; use the copywriting skill for that (the Marketing copy section below is a narrow exception).
---

# Prose style

Tighten prose without flattening its voice. Draft first, then run these as an editing pass — they're a guiding voice, not a checklist to write against from scratch.

## Core rules

1. **Omit needless words** (Strunk & White, Zinsser) — cut words that add nothing. "In order to" → "to". "Due to the fact that" → "because". "At this point in time" → "now".
2. **Kill zombie nouns** (Pinker) — turn nominalizations back into the verbs they came from. "The implementation of caching" → "implementing caching". "Results in a reduction in latency" → "reduces latency". "Utilization of" → "using".
3. **Prefer the positive form** (Strunk & White) — say what is true, not what isn't. "Does not fail" → "succeeds". "Doesn't require configuration" → "works out of the box".
4. **One thought per sentence** (Zinsser) — a compound-complex sentence buries its own point. Split it. This matters most where readers scan rather than study: test plan bullets, PR summaries, changelogs.

## How to apply

Read the draft aloud, mentally. Where you stumble or run out of breath, that's rule 4. Where a sentence has "of"-chains or "-tion"/"-ment" nouns doing the subject's or verb's job, that's rule 2. Where "not" shows up, check rule 3. Where a phrase could lose words and keep its meaning, that's rule 1.

## Marketing copy only

Apply this section only when the task is explicitly marketing or promotional copy — landing pages, ads, emails, taglines, social posts. Do not apply it to docs, PRs, or other technical writing. For the full framework, use the `copywriting` skill; these are the same discipline the classic advertising writers apply at the sentence level:

- **Specificity over vagueness** (Claude Hopkins) — "cuts build time 40%" beats "saves you time". A vague claim reads as filler; a concrete one reads as fact.
- **One big idea, argued once** (David Ogilvy) — a piece of copy sells one idea. A second idea doesn't add to the first, it competes with it.
- **Enter the conversation already in the reader's head** (Robert Collier) — open on the reader's problem or desire, never on the product or company.
- **Match the pitch to what the reader already believes** (Eugene Schwartz) — a skeptical reader needs proof before a claim; a reader who's already sold just needs the offer.
