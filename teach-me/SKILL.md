---
name: teach-me
description: Use when the user wants to learn or get solid on a language idiom, library feature, or concept, not review a specific PR — "teach me Go error handling", "explain errors.Is vs errors.As", "I don't really get Rust lifetimes", "how should I be doing X in this codebase", "what's the idiomatic way to Y", "quiz me on Z". Teaches from the user's own repo (good and bad examples, plus where the codebase stands overall), starts with the problem the idiom solves, verifies version-dependent facts against official docs, asks two or three questions and adapts to the answers, ends with what to catch when AI writes this code, and keeps a learning log so the next session and brief-me skip what's already known.
---

# Teach me

Teach one concept so it sticks and turns into review judgment. Explaining it is the easy part, and any chat can do that. This skill does four things a plain explanation doesn't: it teaches from the user's own code, it makes them answer, it checks version-dependent claims, and it remembers what they've learned.

The user directs AI more than they write code by hand. The lesson succeeds when they can spot this concept done wrong in the next AI-written diff, not when they can recite it.

## Reader model

- **Experienced developer.** Don't explain general programming. Explain what's local to this language or library: the idiom, the implicit behavior, the conventions, and the traps a fluent developer avoids without thinking.
- **Anchor to a stack they know.** "`errors.As` is a typed `catch` that also searches wrapped causes" beats a paragraph. Say where the analogy breaks.
- **Don't ask their level.** Check the learning log and memory first. Otherwise infer from the request and the repo, and adjust the moment an answer shows you guessed wrong.

## 1. Scope it

Pin the concept to something one sitting can cover: "Go errors" is a syllabus, while "wrapping and inspecting errors" is a lesson. When the request is broad, pick the slice that matters most in this repo, name it in one line, and list the other slices as follow-ups. Don't ask which one they want first.

Find the version in use from the lockfile or manifest (`go.mod`'s `go` line, `package.json`, `Cargo.toml`, `composer.lock`, `.tool-versions`). Every claim in the lesson is about that version.

## 2. Load the learning log

Read the log described in [references/learning-log.md](references/learning-log.md). Look for this concept and its neighbors.

- **Solid**: skip it, or give it one line as a bridge to what's new.
- **Shaky**: this is where to spend time. Start from what they missed last time, and ask about it again in a new form.
- **Not yet**, or no entry: teach it from scratch.

If the log says they've covered the whole concept, offer the next slice or a harder angle instead of repeating the lesson.

## 3. Survey the repo

Don't narrate this phase. Find the concept in the current repo, both done well and done badly. For Go error handling:

- wraps with `%w`, and wraps with `%v` or `%s` that drop the chain
- `errors.Is` and `errors.As`, versus `err ==` and type assertions on errors that might be wrapped
- swallowed errors: `_ =` on a call that returns one, `if err != nil { return nil }`, log-and-continue
- string matching on `err.Error()`

Build the equivalent list for whatever concept you're teaching, and search for each item. Then produce:

- **Where the codebase stands.** Counts by pattern, from `grep -c` or `rg --count`, with one line of interpretation: "41 wraps with `%w`, 3 with `%v`; 12 `err ==` comparisons, 4 of them against sentinels that are wrapped upstream." Say the counts come from text search and may include false positives.
- **Exemplars.** One or two places that get it right, as `path:line`.
- **Specimens.** Two or three places that get it wrong or fragile, as `path:line`, each with a one-line reason. Confirm each one by reading the surrounding code, since a match that only looks wrong teaches the wrong lesson. Prefer the ones with real consequences: a sentinel compared after a wrap upstream, so the check can never be true.

If the concept barely appears, that's a finding: "nothing here uses `errors.As`, so no caller ever inspects an error's type." If there's no repo, or the concept doesn't appear in it at all, say so in one line and use minimal examples marked as not from the repo.

Read files from the main branch or the current checkout, whichever the user is working in. Never edit them. Every snippet in the lesson is a quote.

## 4. Check version-dependent facts

Before you state anything that changed between versions, fetch the official docs and confirm it: release notes, the standard library reference, the framework's upgrade guide. `errors.Join` and multiple `%w` verbs in one `fmt.Errorf` arrived in Go 1.20. In a module whose `go.mod` says 1.19, `errors.Join` fails to build on a 1.19 toolchain and is flagged by `go vet` from Go 1.23 on, and a second `%w` doesn't wrap anything at runtime on 1.19. Neither is an idiom there.

- Compare each claim to the version found in step 1. When the canonical pattern needs a newer version than the repo has, say so plainly; that's one of the most useful things the lesson can tell them.
- Link the doc next to the claim.
- When you can't fetch the docs, label the claim *from general knowledge* and keep going.

Don't fetch docs for stable basics that haven't changed in years.

## 5. Teach it

Deliver the lesson in stages, one message each, and stop after each to let them answer or redirect. If they ask for all of it at once, give one message with the questions at the end and wait for the answers.

**Why it exists.** Start with the problem the idiom solves, in two to four sentences. For Go errors: errors are ordinary values, not exceptions, so the language gives you no stack or `catch` hierarchy. Wrapping builds a chain of causes, and `errors.Is` and `errors.As` are how callers ask questions of that chain without knowing who wrapped it. Without the why, the patterns read as arbitrary rules. Then give where the codebase stands from step 3, in one or two lines.

**The canonical patterns.** Three to five, in the order a reader meets them, each with a quoted exemplar from the repo when one exists. Each pattern gets the rule, why it's the rule, and the version it needs if that matters. Show an idiomatic version in three lines or fewer only when the repo has no good example.

**The traps.** The ways it goes wrong, illustrated with the specimens from step 3. Lead with the one that causes real bugs, not the one that's merely untidy. For each, give the symptom, the reason, and the fix.

**Review judgment.** What to look for when AI writes this kind of code. See [the review section](#6-review-judgment).

Annotate quoted code inline in the language's comment syntax, prefixed `teach:`, the same marker brief-me uses for its drill-downs:

```go
// internal/store/get.go:84-92
func (s *Store) Get(id string) (*Item, error) {
	item, err := s.db.Find(id)
	if err == sql.ErrNoRows { // teach: ❌ never true. Find wraps it with %w (db.go:41), and == doesn't follow wraps.
		return nil, ErrNotFound
	}
	return item, err // teach: 🔴 so a missing row escapes as a 500 instead of a 404
}
```

Two to five notes per block, on the lines worth pointing at. Never alter the quoted code, and mark anything you cut. Inline notes point; the prose under the block explains why it matters.

### Scan markers

Lead lines with these so the lesson reads at a glance. Each one carries a meaning, so use it only when that meaning applies, put at most one at the start of a line, and leave plain explanation unmarked.

| Marker | Means | Where it shows up |
|---|---|---|
| 🔴 🟠 🟡 | Severity: causes real bugs / fragile or misleading / untidy | Each trap, specimen, and review item |
| ⛔ | Breaks one of the concept's or the area's must-hold rules, so the code is wrong rather than risky | A specimen that can never work, like `==` against a sentinel that's always wrapped |
| ⚠️ | A warning that isn't a trap: a version caveat, a false-positive-prone count, a pattern that's fine here but breaks elsewhere | Version notes from step 4, survey caveats |
| ✅ ❌ | Fine versus broken | Exemplars versus specimens, idiomatic versus not, and right versus wrong answers |
| 🔎 | Where to look: evidence from the repo or the docs | The codebase stance, `path:line` pointers, doc links |
| 🧪 | Something to run or try: a test, a snippet, a breakpoint | Verification steps and "what's still open" |
| ❔ | A question for the reader, waiting on their answer | Every question in [Ask, then adapt](#ask-then-adapt) |

Severity and ⛔ can share a line: `⛔ 🔴 internal/store/get.go:86`. Markers work inside `teach:` notes too, as in the example above. If more than about a third of a message's lines carry a marker, they've stopped helping you scan; drop the ones on minor points.

## Ask, then adapt

Ask two or three questions across the lesson, one at a time, and stop the message after each. A question with its answer three lines below isn't a question.

- **"What does this print?"** Tests the mental model. Use a five- to ten-line snippet, built from a repo exemplar where possible, whose output turns on the concept: a wrapped sentinel checked with `==` and then with `errors.Is`.
- **"What's wrong here?"** Tests review judgment. Use a real specimen from step 3 if you have one. Otherwise use a lightly altered exemplar, and say it was altered.
- **"Which would you choose?"** Tests the decision: two correct options that differ in a way that matters, such as a sentinel error or a typed error.

Pick questions someone could plausibly get wrong. Obvious ones waste their time.

Then adapt:

- **Right, with the reason**: say so in a line and speed up. Compress or skip the material it covered.
- **Right, but for the wrong reason**: treat it as a miss. That's the most important case to catch.
- **Wrong**: don't just give the answer. Show the line that decides it, explain it from a different angle than before, and ask a short follow-up that tests the same point in a new form.
- **"Skip" or "just tell me"**: tell them, and log the topic as not yet tested.

## 6. Review judgment

Close the lesson with what to look for when AI writes this kind of code. That's the part they'll use daily.

- **What to catch.** Three to five failure modes specific to this concept and this repo, each as one line a reviewer could check in seconds. For Go errors: `==` against an error that might be wrapped, `%v` where the caller needs the chain, `errors.As` given a value instead of a pointer, a swallowed error behind a log line, `errors.Join` in a module that declares Go below 1.20.
- **The prompt-level fix.** One or two lines they could put in a prompt or CLAUDE.md to prevent the most common failure: "wrap with `%w` at package boundaries; compare with `errors.Is`, never `==`." If the repo's own specimens show a recurring failure, suggest adding that line to the repo's CLAUDE.md and offer to do it.
- **What's still open.** One line naming the next slice, or the question they were least sure of, and how to settle it: the test to write, or the doc page to read.

Don't summarize the lesson. They just took it.

## 7. Update the log

Write the log entry before the final message, as described in [references/learning-log.md](references/learning-log.md). Record what their answers showed, not what you covered: a topic you explained but never tested is *not yet tested*, not *solid*. Mention the update in one line at the end, so they know the next session will pick up from here.

## Anti-patterns

- **Textbook examples when the repo has real ones.** If the codebase does the thing, teach from the codebase. Invented examples are a fallback, and they get labeled.
- **Patterns before the problem.** Rules without the reason read as trivia, and trivia doesn't survive to the next review.
- **A specimen that isn't wrong.** Read the surrounding code before calling something a bug. A false specimen teaches the wrong lesson with the authority of real code.
- **Recalling version-specific facts.** Check the docs for the version in the lockfile, or say the claim is from general knowledge.
- **Questions with the answer attached.** Ask, stop, and wait.
- **Ignoring the answers.** A lesson that runs the same after a wrong answer as after a right one isn't adapting. Slow down on misses and speed up on hits.
- **Logging coverage as mastery.** Only answers count as evidence.
- **Re-teaching what the log says is solid.** Bridge in one line, and spend the time on what's shaky.
- **Lecturing in one wall of text.** Stage it, and stop between stages.
