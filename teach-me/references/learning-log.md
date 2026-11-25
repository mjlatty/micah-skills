# Learning log

What the user has learned, so the next lesson starts where the last one stopped. Other skills read it too: brief-me can say "this PR uses `errors.As` the way you covered on 2026-11-10" instead of explaining it again, and spend the words on what's shaky.

## Where

`${XDG_DATA_HOME:-$HOME/.local/share}/teach-me/log.md`. Create the directory on the first write.

It lives outside every repo because what someone knows belongs to them, not to a project: Go error handling learned in one repo still holds in the next. It lives outside the skill directory because that's a symlink into the skills repo, and the log must never be committed. It isn't in a harness's config directory so that Claude Code and Codex share one log.

What a specific repo does is a fact about that repo, and it goes in the entry's `repos:` lines.

[../scripts/backup.sh](../scripts/backup.sh) copies the log onto the skills repo's `skill-data` branch so it outlives the machine. That repo is public: snapshots are scrubbed of the home path, emails and secret-shaped strings, but everything else goes in as written, which is one more reason the rules below keep code and secrets out.

## Format

One `##` section per concept, keyed `<language or library>: <concept>`. Keep concepts at lesson size, the slice one sitting covers, so `go: error wrapping and inspection` and not `go: errors`.

```markdown
# Learning log

## go: error wrapping and inspection
last: 2026-11-17 · go 1.22
solid: errors are values and wraps form a chain; %w vs %v; errors.Is for sentinels
shaky: errors.As needs a pointer to the target type (missed "what does this print?", 2026-11-17)
not yet: errors.Join and multiple %w (Go 1.20+); custom Is/As methods
review: `==` against a wrapped sentinel; %v at a package boundary; swallowed error behind a log line
repos:
- acme/api @ 3f9c2e1: 41 %w wraps, 3 %v; 12 `err ==`, 4 against wrapped sentinels (internal/store/get.go:86)

## laravel: eloquent eager loading
last: 2026-11-03 · laravel 11
solid: with() vs load(); why N+1 happens
shaky: —
not yet: preventLazyLoading in tests (offered, skipped)
review: relation access inside a loop or a Blade @foreach; ->count() on an unloaded relation
repos:
- acme/web @ 9a1b7c0: preventLazyLoading not enabled; 3 N+1s in app/Http/Controllers/ReportController.php
```

Fields:

- **last**: date of the most recent lesson, and the version it was taught against. A later lesson on a newer version may need to cover what changed.
- **solid**: points they answered correctly and could explain. Only answers count as evidence. A point they claimed to know without being tested goes here suffixed `(claimed)`.
- **shaky**: points they missed or got right for the wrong reason, with what they missed and when. This is the most valuable line in the entry, because it's where the next lesson and the next review should start.
- **not yet**: points named but not taught, or taught but not tested.
- **review**: the failure modes from the lesson's review section, in a few words each. This is the line brief-me uses when it sees the concept in a diff.
- **repos**: one line per repo surveyed: `owner/name @ short-sha`, the stance counts, and the best specimen's `path:line`. Use the remote's `owner/name`, or the directory name when there's no remote.

## Rules

- **Rewrite in place.** Move a point from shaky to solid when a later answer earns it, and replace a repo's line when you re-survey it. The log is a current picture, not a history.
- **Evidence, not coverage.** Explaining something doesn't make it solid. Write down what the answers showed.
- **Keep it short.** Each line of an entry should fit in about 200 characters, and each entry under about ten lines. Merge two concepts that keep overlapping, and split one that keeps growing.
- **Never record secrets or proprietary code.** Paths and counts are enough. Don't paste snippets into the log.

## Reading it from another skill

A skill that wants the log (brief-me, code-tour) should read the file if it exists and carry on without it if it doesn't. For each concept the diff uses:

- **solid**: skip the explanation, or give it a one-line reference back.
- **shaky**: explain it, starting from what was missed.
- **review**: check the diff for exactly those failure modes, and name the match.

Only teach-me writes the log.
