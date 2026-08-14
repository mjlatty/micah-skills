---
name: seo-improvement
description: Use when the user asks to audit or improve a website/webapp's SEO — rankings, clickthrough, bounce rate, page metadata, structured data, sitemap/robots, headings, content structure, images, or Core Web Vitals.
---

# SEO improvement

Audit and improve a website or web app for three outcomes, in order: **rank** (get onto page one), **clickthrough** (win the click over competing results), **engagement** (keep the visitor — low bounce, satisfied intent). A fix that improves one at the expense of another (e.g. a clickbait title that spikes CTR but tanks engagement) is a net loss — Google's engagement signals feed back into rankings.

Work from the code and real rendered output, not guesses — read the actual templates, framework metadata APIs, or build output before claiming something is missing. Never fabricate content to fill a title or description; pull from existing copy or ask the user.

## 0. Scope the site

Identify the framework (Next.js, Astro, Remix, Rails views, plain HTML, etc.) — this determines where metadata lives (`generateMetadata`/`<Head>` in Next.js, frontmatter in Astro/Jekyll, `<head>` partials in server-rendered apps). Find the route/page list and any existing SEO utilities (shared `<SEO>` component, metadata helper, `next-seo` config) and extend what exists rather than introducing a second pattern.

Also establish: What does each page want to rank for? Who is the searcher, and what are they trying to do? Every recommendation below is downstream of that. If the user hasn't specified target queries, infer them from the page content and confirm.

### Who the searcher is — read `icps/` first

If the project has an `icps/` folder (from the `icp-definition` skill), the searcher is already documented. Read `icps/README.md` for the ranking, then the profiles:

- **"Where to find them"** lists the queries each ICP actually types. That's your seed keyword set, and it beats a keyword tool because it came from the people who buy. Verify volume and difficulty if you have the tooling, but start here.
- **"Job to be done"** and **Pains** give you the intent behind those queries and the sub-questions to cover — a page that answers the documented pain in its first screenful satisfies intent by construction.
- The **portrait** sets reading level and vocabulary: use the terminology, tools, and entities they already know, and don't explain what a practitioner takes for granted.
- **"Product surface that serves them"** maps ICPs to pages. Pages serving the primary ICP get the ranking effort; an ICP with no page is a content gap worth naming in the audit.
- **Anti-ICPs** define traffic you don't want. A query that pulls the wrong segment is not a win — it inflates impressions, tanks engagement, and the engagement signal feeds back into rankings. Say so instead of chasing volume.

Rank the audit by ICP priority, not by page traffic: a fix on the page that serves the primary ICP beats a bigger fix on a page that serves nobody in the folder.

Search Console is unusually good evidence for these profiles — real queries, real demand, proof a watering hole exists. When an audit turns up query data that confirms or contradicts a profile, append it to that profile's evidence log (dated, marked **validated** or **hypothesis**).

No `icps/` folder: infer the searcher from page content and confirm with the user, as above. Mention the `icp-definition` skill if the site's targeting looks unsettled — SEO built on a guessed audience is expensive to redo.

## 1. Ranking — search intent and content

Intent match is the strongest on-page ranking factor. Before touching metadata, check that each page actually satisfies the intent behind its target query:

- **Classify the intent**: informational ("how do X"), commercial-investigation ("best X", "X vs Y"), transactional ("buy X", "X pricing"), or navigational. The page *format* must match — searchers wanting a comparison table bounce off a sales page; searchers ready to sign up bounce off a 3,000-word essay. If in doubt, check what format currently ranks for the query: Google has already A/B-tested this at scale.
- **One page, one intent**: don't split one intent across multiple thin pages (they cannibalize each other), and don't stack multiple intents on one page (it ranks for none). Consolidate near-duplicate pages with a 301 and canonical to the strongest one.
- **Answer first, elaborate after**: put a direct, self-contained answer to the query in the first screenful — a definition, a number, a verdict, a TL;DR box. This satisfies the searcher (engagement), earns featured snippets (write the answer as a 40–60-word paragraph or a tight list directly under a question-phrased heading), and signals relevance.
- **Cover the topic, not the keyword**: include the sub-questions a searcher would ask next (the "People Also Ask" cluster) as sections. Naturally use related terminology and entities — synonyms, tools, brand names, units — rather than repeating one keyword. Keyword density is not a thing; comprehensiveness is.
- **Demonstrate E-E-A-T** (experience, expertise, authoritativeness, trust): visible author with credentials on articles; dates (published *and* updated — and actually update stale content, don't just bump the date); cite primary sources with outbound links; first-hand specifics (real screenshots, real numbers, tested results) rather than paraphrased generalities. For anything money/health-adjacent (YMYL), this is decisive.
- **Freshness**: for queries where recency matters, an updated page with a current year and refreshed facts outranks a stale one. Flag content with dates/stats more than ~18 months old.

### Site architecture and internal linking

- Every indexable page reachable within ~3 clicks of the homepage; no orphan pages. Hub/spoke structure: a pillar page on the broad topic links to and receives links from each specific subpage.
- Internal anchor text is descriptive and varied ("compare pricing plans", not "click here" or the same exact-match phrase 40 times). Internal links are the cheapest ranking lever a site controls — link generously from strong pages to pages that need to rank.
- Breadcrumbs on deep pages (with `BreadcrumbList` JSON-LD).
- Readable, stable, hierarchical URLs (`/guides/seo-audit`, not `/p?id=8347`); avoid dates in URLs for evergreen content (they advertise staleness and break when you refresh).

## 2. Clickthrough — winning the SERP

A ranking is an ad slot; the title and snippet are the ad. Audit each page's SERP presentation:

- **Title** (~50–60 chars before truncation): unique per page; primary keyword near the front; then a *reason to click* — a specific benefit, number, or differentiator ("Postgres Indexing: 7 Patterns That Cut Query Time" beats "Postgres Indexing Guide"). Numbers, current year for time-sensitive topics, and brackets ("[2026]", "(with examples)") measurably lift CTR. The title must be honest about what the page delivers — an over-promise raises CTR and bounces the click right back, which is worse than not winning it.
- **Meta description** (~120–158 chars): not a ranking factor, purely ad copy. Front-load the payoff, address the searcher directly, end with an implicit next step. Include the target phrase (Google bolds matched terms, drawing the eye). Google rewrites descriptions that don't match page content — write one that survives by summarizing accurately.
- **Structured data (JSON-LD)** for rich results — these expand your SERP footprint and lift CTR more than any copy tweak: `Article`/`BlogPosting`, `Product` (price, availability, review stars), `FAQPage`, `HowTo`, `BreadcrumbList`, `Organization`/`WebSite`. Only mark up content actually visible on the page (invisible-content markup violates Google's guidelines and risks a manual action). Validate with the Rich Results Test.
- **URL in the snippet**: breadcrumb-style paths display in results; keep them short and human-readable.
- **Favicon and `og:image`**: favicon shows in mobile SERPs; `og:image` (absolute URL, 1200×630) controls how shared links look on social/chat — a large share of "SEO" traffic for many sites.
- **Avoid duplicate titles/descriptions** site-wide — they suppress CTR and confuse indexing. For templated pages (e.g. product pages), build the pattern so each renders unique: `{Product} — {differentiator} | {Brand}`.

## 3. Engagement — low bounce, intent satisfied

Bounce is usually a first-screenful problem or a promise-mismatch problem:

- **Above the fold delivers on the title**: the visitor should see, within one second and without scrolling, confirmation they're in the right place — an `<h1>` echoing the search intent, the direct answer or value proposition, and no interstitial in the way. Cookie banners, newsletter modals, and app-install prompts before content are the biggest self-inflicted bounce drivers (and intrusive-interstitial penalties are real on mobile).
- **Scannability**: descriptive `<h2>`/`<h3>` every 150–300 words (a skimmer reading only headings should get the gist); short paragraphs (2–4 sentences); bullets and tables for comparisons; bolded key phrases; a table of contents with anchor links on long pages (also earns sitelinks in SERPs).
- **Readability**: match reading level to audience but default simpler than you think — plain sentences, concrete examples, no filler intros ("In today's fast-paced digital landscape…" is a bounce). Cut throat-clearing; the first paragraph earns the second.
- **Next-step paths**: every page ends somewhere — related articles, the pillar page, a relevant CTA. A dead-end page bounces by definition. Internal links within body copy ("as covered in our [caching guide]") keep sessions alive.
- **Media**: relevant images/diagrams every few hundred words break up text walls; every content image has descriptive `alt` (decorative ones get `alt=""`, never omitted); compressed and lazy-loaded below the fold, but **never** lazy-load the LCP image.
- **Trust markers**: real author bios, updated dates, testimonials/logos where relevant, working links. Broken links and 2019 screenshots read as abandonment.

### Performance (Core Web Vitals)

Speed is both a ranking signal and the first bounce filter — a large share of mobile visitors abandon loads over ~3 seconds:

- **LCP < 2.5 s**: server-render or statically generate indexable pages (client-side-only rendering also risks incomplete indexing); preload the hero image/font; `fetchpriority="high"` on the LCP image; eliminate render-blocking third-party scripts from `<head>` (defer, or load on interaction).
- **CLS < 0.1**: explicit `width`/`height` (or aspect-ratio) on all images/embeds/ads; `font-display: swap` with metric-compatible fallback fonts; never inject banners above existing content after load.
- **INP < 200 ms**: audit heavy hydration and third-party tags (chat widgets, analytics stacks are the usual culprits); code-split so interactive routes don't ship the whole app.
- Measure with Lighthouse/PageSpeed Insights or the framework's analyzer rather than guessing; field data (CrUX) trumps lab data when they disagree.

## 4. Technical / indexability baseline

None of the above matters if crawlers can't reach or trust the page:

- `robots.txt` doesn't block content that should rank; references the sitemap.
- `sitemap.xml` generated from actual routes (build-time, not hand-maintained), excluding noindex/private/redirecting pages; submitted in Search Console.
- Exactly one canonical version of every URL: consistent https + www policy enforced by 301 (not just preferred), trailing-slash policy consistent, `rel="canonical"` on every indexable page (self-referencing by default), parameter/filter variants canonicalized to the base page.
- No accidental `noindex` (check both meta tags and `X-Robots-Tag` headers — a staging header that shipped to prod is a classic).
- Correct status codes: real 404s (not 200 "soft 404s"), 301 for permanent moves, redirect chains collapsed to one hop.
- One `<h1>` per page; heading levels not skipped; semantic HTML (`<main>`, `<nav>`, `<article>`) over div soup.
- `<meta name="viewport" content="width=device-width, initial-scale=1">` and genuinely mobile-usable layout — indexing is mobile-first.
- `hreflang` pairs if the site has language/region variants (must be reciprocal or they're ignored).
- Key content present in server HTML, not injected post-load by JS that crawlers may not execute or may time out on.

## 5. Reporting and fixes

- Report findings as `file:line — issue — fix`, prioritized: (1) indexability blockers (noindex, robots, canonical, broken sitemap), (2) intent/content mismatches on key pages, (3) title/description/structured-data CTR work, (4) engagement and Core Web Vitals polish. Within a tier, pages serving the primary ICP go first.
- Apply mechanical, low-risk fixes directly (titles, descriptions, alt text, canonical tags, heading structure, JSON-LD). For structural changes — sitemap generation, redirect rules, image pipelines, rendering strategy — confirm the approach first, since they touch build/deploy config.
- Copy changes (titles, descriptions, above-fold copy) must come from what the page genuinely offers. When the page can't honestly support a compelling title, the finding is "content gap," not "write a better title."
- Verify after changing: build or run the dev server and inspect the rendered `<head>` and body of affected pages; validate JSON-LD with the Rich Results Test; re-run Lighthouse on performance changes. Don't assume a metadata API call rendered correctly.
- Where measurement exists (Search Console, analytics), tie recommendations to data: pages with high impressions but low CTR are title/description work; pages with high CTR but low engagement are intent-mismatch or above-fold work; pages with no impressions are indexability or content-gap work.
