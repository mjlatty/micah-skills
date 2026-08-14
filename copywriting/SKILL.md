---
name: copywriting
description: Use when the user asks to write marketing copy, landing page copy, ad copy, taglines, product descriptions, emails, or other promotional/persuasive copy
---

# Copywriting

Write high-converting, friendly, human copy based on the conversation thread and project context.

## Before writing

1. If `docs/copywriting/copywriting-prompt.md` exists in the current project, read it — its brand voice, style, and structure rules override anything below.
2. **Read `icps/` if the project has one** (see next section). It answers the audience question with evidence instead of a guess.
3. Establish the essentials. If any are missing and not inferable from context, ask before writing:
   - **Audience** — who is this for, and how sophisticated are they about the problem?
   - **Goal** — the one action the reader should take (sign up, buy, reply, click).
   - **Channel** — landing page, ad, email, social post, product description. Channel dictates length and form.
   - **The one big idea** — the single most compelling claim. One piece of copy sells one idea; if there are two, that's two pieces of copy.

## Write to the ICP

If the project has an `icps/` folder (produced by the `icp-definition` skill), it is the audience brief — read `icps/README.md` for the ranking, then the profile for whoever this piece targets. Default to the **primary** ICP; if the user names a different one, use that. Never write to an **anti-ICP** or a documented lookalike — copy that pulls them in costs more in support than it earns.

The profile maps onto the copy directly:

| Profile section | What it decides |
|---|---|
| Portrait | Awareness level, and the vocabulary they use for the problem — mirror their words, not the product's |
| Motivations | What the copy speaks to: the outcome they want, the way they want to be seen |
| Pains | What the product fixes — the proof, not the pitch. Dollarized pains become your specific claims |
| Buying trigger | When the CTA lands, and whether urgency is real or has to be manufactured (it shouldn't be) |
| What they do today | The thing you're switching them from. Name it honestly and beat it on one axis |
| Willingness to pay | Where price sits and which objection to handle next to the CTA |
| Friction & caveats | The objections to answer before they're raised, and what not to over-promise |

Two rules that follow from it:

- **One ICP per piece.** Copy aimed at two profiles speaks to neither — same reason one piece sells one idea. Write two.
- **Don't launder hypotheses into claims.** Profile lines are tagged **validated** or **hypothesis** in the evidence log. A validated pain can become a headline; a hypothesis can't become "teams waste 6 hours a week." Ask for the real number or write around it.

No `icps/` folder? Say so, ask the audience questions above, and mention that the `icp-definition` skill would make this reusable — but don't block on it, and don't invent a persona to fill the gap.

## Core principles

- **Clarity beats cleverness.** If a reader has to decode it, they bounce. Cut wordplay that obscures the point; keep wordplay that sharpens it.
- **Benefits over features.** Features are what it does; benefits are what the reader gets. Lead with the benefit, use the feature as proof. "Ship in minutes" (benefit) beats "CI/CD pipeline integration" (feature). Best: pair them — "Ship in minutes, not days — builds deploy automatically on merge."
- **Specificity converts.** "Trusted by 4,200 teams" beats "trusted by thousands." "Cuts review time 40%" beats "saves time." Vague claims read as filler; concrete ones read as facts.
- **Write to one person.** Use "you" more than "we." Read it aloud — if it wouldn't sound natural said across a table, rewrite it. Contractions are your friend.
- **Match the reader's awareness.** Someone who's never heard of the problem needs the problem named first. Someone comparing tools needs differentiation, not education. Don't explain what the reader already knows.
- **Earn every sentence.** Each line's job is to get the next line read. Delete anything that doesn't advance the argument or build trust.

## Voice and tone

Friendly and approachable, never sloppy or fake:

- Plain words over jargon: "use" not "utilize," "help" not "empower," "fast" not "blazingly performant."
- Active voice, present tense: "Claude drafts the reply" not "replies are drafted."
- Confident without hype. Never stack superlatives ("revolutionary game-changing platform"). One strong, supportable claim beats three inflated ones.
- Warmth comes from specificity and honesty, not exclamation points. One "!" per piece, max.
- It's fine to be funny if the brand allows it — but the joke must never come at the expense of clarity or the reader.
- Avoid the AI-slop tells: "In today's fast-paced world," "Look no further," "Unlock the power of," "seamlessly," "elevate," em-dash-riddled non-sentences, rhetorical-question openers.

## Conversion mechanics

- **Headlines do 80% of the work.** Lead with the strongest benefit or the sharpest pain. Test yourself: would the headline still be interesting with the product name removed? Formulas that work — outcome ("Get X without Y"), question the reader is already asking, specific proof ("How 4,200 teams cut review time 40%").
- **CTAs state value, not effort.** "Start writing free" beats "Submit." "Get the guide" beats "Download." One primary CTA per piece; repeat it, don't vary it.
- **Handle the objection right where it occurs.** Price worries near the CTA ("Free for 14 days, no card"). Trust worries near claims (logos, numbers, testimonials). Effort worries near onboarding ("Set up in 5 minutes").
- **Social proof must be specific to persuade.** A named person with a concrete result beats five anonymous five-star blurbs. Place proof adjacent to the claim it supports.
- **Urgency only when true.** Real deadlines and real scarcity convert; fake countdowns burn trust permanently.
- **Reduce risk at the moment of decision.** Guarantees, free tiers, "cancel anytime" — put reversal language next to the ask.

## Short-form (taglines, ads, subject lines, social, CTAs)

- One idea, one emotion, one action. If it needs a second sentence to land, the first sentence is wrong.
- Front-load the payload — the first 3–5 words carry truncated previews (subject lines, ad headlines, tweets).
- Concrete nouns and verbs; kill every adjective that isn't doing work. "Meetings that end on time" needs no adornment.
- Write 10–20 variants before choosing. The first five are always the obvious ones. Show the user the best 3–5 with a one-line rationale for each, and mark your top pick.
- Rhythm matters at this length: read candidates aloud; prefer punchy stress patterns and cut syllables that trip.

## Long-form (landing pages, sales pages, emails, launch posts)

- **Structure as a slippery slope:** hook (pain or desired outcome) → what it is, in one sentence → benefits with feature-proof → social proof → objection handling → CTA. Repeat the CTA after each major trust-building section.
- **Write for skimmers first.** Headings alone should tell the whole story — a reader who only reads headings and the CTA should still be sold. Then reward readers who go deep with the specifics.
- **Vary sentence length deliberately.** Long sentences build a case. Short ones land it. Like that.
- **Paragraphs of 1–3 sentences.** A wall of text on a sales page is a bounce.
- **The lead is the hardest part** — never open with the company or "In today's world." Open inside the reader's head: the pain they said out loud yesterday, or the outcome they daydream about.
- **Emails:** subject line gets its own variant pass (it's short-form); first line must not repeat the subject; one CTA; P.S. is prime real estate — restate the offer or add the sharpest proof point.
- **End strong.** The last line before a CTA should make acting feel like the obvious next step, not a leap.

## Editing pass (always do this before delivering)

1. Read the whole draft aloud (mentally); rewrite anything you stumbled on.
2. Cut 20% — flabby drafts hide strong copy. Target adverbs, hedges ("really," "just," "very"), throat-clearing openers, and duplicate claims.
3. Check every claim is specific or supported. Replace or cut vague ones.
4. Confirm one idea, one audience, one CTA throughout.
5. Verify the skim path: headings + bolds + CTA alone must tell the full story.
6. Scan for banned-phrase tells and jargon (see Voice and tone).

## Output

Write the copy to `docs/copywriting/` in the current project with a descriptive filename. For short-form, include the variant list with rationale. For long-form, include a one-paragraph note on the structure choices so the user can direct revisions.
