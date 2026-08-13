# micah-skills

Agent skills, kept in one place and installed into whichever harnesses are on the machine.

| Skill | What it's for |
|---|---|
| `code-tour` | Walks you through a PR or feature stop by stop, judging each part against the language idiom and the repo's own conventions |
| `monetization-strategy` | Ranked revenue paths with unit economics, scoped to a solo founder's constraints |
| `prose-style` | Editing pass that tightens prose without flattening its voice |
| `reddit-research` | Pulls real Reddit discussion via archive APIs, since direct scraping is blocked |

## Install

```sh
./install.sh                 # every skill into every detected harness
./install.sh code-tour       # just one
./install.sh --status        # what's installed where
./install.sh --uninstall     # remove what this repo owns
```

Useful flags: `--target=claude,codex`, `--copy`, `--dry-run`, `--force`.

Skills are **symlinked** by default, so editing a `SKILL.md` here takes effect immediately in
every harness — no reinstall step, no drift between copies.

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
