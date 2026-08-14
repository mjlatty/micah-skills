# micah-skills

Agent skills, kept in one place and installed into whichever harnesses are on the machine.

| Skill | What it's for |
|---|---|
| `code-tour` | Walks you through a PR or feature stop by stop, judging each part against the language idiom and the repo's own conventions |
| `copywriting` | Marketing and landing-page copy that sells one idea to one audience |
| `icp-definition` | Ranked, evidence-based customer profiles, written to the project as an `icps/` folder |
| `monetization-strategy` | Ranked revenue paths with unit economics, scoped to a solo founder's constraints |
| `pr-description` | PR bodies at architecture altitude, with each regression risk paired to the test that guards it |
| `product-changelog` | User-facing feature announcements from a branch |
| `prose-style` | Editing pass that tightens prose without flattening its voice |
| `reddit-research` | Pulls real Reddit discussion via archive APIs, since direct scraping is blocked |
| `run-laravel-valet` | Cold-starts a Laravel app over HTTPS locally and verifies it serves real pages |
| `seo-improvement` | Audits a site for rank, clickthrough, and engagement, and applies the low-risk fixes |
| `technical-blog` | Technical posts written from the conversation that produced the work |

`icp-definition` is the hub: it writes an `icps/` folder into a project, and `copywriting`,
`seo-improvement`, `monetization-strategy`, `product-changelog`, and `technical-blog` read it for
audience, queries, pricing anchors, and vocabulary instead of guessing. Each degrades gracefully when
the folder isn't there.

## Install

```sh
./install.sh                 # every skill into every detected harness
./install.sh code-tour       # just one
./install.sh --status        # what's installed where
./install.sh --uninstall     # remove what this repo owns
```

Useful flags: `--target=claude,codex`, `--copy`, `--dry-run`, `--force`, `--here`.

Skills are **symlinked** by default, so editing a `SKILL.md` here takes effect immediately in
every harness — no reinstall step, no drift between copies.

### Links that don't rot

A symlink dies with the directory it points at, and worktree checkouts are disposable — a Conductor
workspace is deleted the moment you close it, taking every skill linked from it. So the script links
from the **main checkout**, no matter which worktree you run it from, and says which one it picked.
Pass `--here` when you deliberately want a work-in-progress skill live in every harness; re-run
without it once the branch merges.

It also repairs on re-run rather than complaining. A link that dangles, or points into another
checkout of this repo, is recognized as this repo's and repointed without `--force`; leftover links
for skills that no longer exist here are pruned. Only an *edited* copy or a genuinely foreign entry
is left alone — those might be someone else's work.

## How this works

Claude Code and Codex converged on the same on-disk format: one directory per skill, containing a
`SKILL.md` whose YAML frontmatter carries `name` and `description`. The harness loads every
description up front and the model decides when a skill applies, so the description is the trigger —
write it as "use when…", covering the phrasings someone would actually type.

Only the install root differs:

| Harness | Root | Override |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `$CLAUDE_CONFIG_DIR` |
| Codex | `~/.codex/skills/` | `$CODEX_HOME` |

That's the whole portability story — a skill is just a Markdown file in a directory, so the same
directory serves both. Nothing here is Claude- or Codex-specific.

`install.sh` treats this repo as the source of truth and refuses to clobber anything it doesn't own:
a target that has been edited away from the repo version, or a symlink pointing somewhere else, is
reported and skipped unless you pass `--force`. Skills in a harness that aren't in this repo are
never touched.

### Verified behavior

Claude Code follows symlinked skill directories — verified by installing one and watching it get
picked up.

Codex support for *symlinked* directories is **unverified**: `codex exec` requires `OPENAI_API_KEY`
even when a ChatGPT credential is present, so the loader couldn't be exercised here. Worth knowing
that OpenAI's own `skill-installer` copies (`shutil.copytree`) rather than links. If Codex doesn't
list a skill after install, fall back to copies:

```sh
./install.sh --target=codex --copy --force
```

Copies don't track edits, so re-run that after changing a skill.

## Adding a skill

Create `<skill-name>/SKILL.md` with `name` and `description` frontmatter, then run `./install.sh`.
Discovery is automatic — any top-level directory containing a `SKILL.md` is treated as a skill.
Supporting files (`references/`, `scripts/`) can live alongside it and are linked with the rest.
