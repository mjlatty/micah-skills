# Taste log

What the user's picks have shown about their taste, kept across labs so the next lab starts from it
instead of from zero. Round one of a new lab then spends fewer variants rediscovering what they
already told you, and the recommendation is more often the one they pick.

## Where

`${XDG_DATA_HOME:-$HOME/.local/share}/variant-lab/`, two files. Create the directory on the first
write.

- `taste.md`: the profile. What the evidence currently says, rewritten in place.
- `picks.md`: the evidence. One entry per round, appended and never edited.

Both live outside every repo, because taste belongs to the person, not to a project: someone who
passes on tabbed settings in one app will usually pass on them in the next. They live outside the
skill directory because that's a symlink into the skills repo, and the log must never be committed.
They aren't in a harness's config or memory directory, so Claude Code and Codex share one log, and so
does every worktree of every project. A Conductor workspace's `.context/` is deleted with the
workspace, so it can't hold anything meant to last.

The profile is an inference and can drift. Keeping the raw picks beside it means it can always be
rebuilt or corrected from what actually happened.

## Keeping it

[../scripts/backup.sh](../scripts/backup.sh) snapshots the log onto the `skill-data` branch of the
skills repo (see "Backing up what skills learn" in the repo's README), so it outlives this machine.
Each snapshot is a commit, so a bad inference can be found and undone.

- **At the start of a lab**, if there's no log yet, run `backup.sh restore`. It brings back the last
  backup if one exists, and does nothing otherwise.
- **After every write** to the log, run `backup.sh sync`. It always commits the snapshot locally,
  and pushes only when the last push is a week or more old.
- **At promotion**, after the final update, run `backup.sh push`.

The skills repo is public. Snapshots are scrubbed on the way in (the home directory becomes `~`,
emails and secret-shaped strings are redacted), but project names and the user's notes go in as
written. Keep secrets and customer data out of the log, as the rules below say.

## picks.md

One entry per round, appended when the pick comes back:

```markdown
## 2026-11-24 · owner/app · visual · settings page · round 2
offered: F two-column, plan beside usage (rec) · G attention-first list · H tabs by area · I single scroll, sticky index · J cards that open into drawers (challenger: tabs)
picked: G+F · note: "G's ordering, F's plan card"
recommendation picked: no
taste: problem-first ordering, current state visible without a click, real numbers on cards; passed on tabs and drawers
```

- **offered**: every variant as letter and short name, marking the recommendation `(rec)` and any
  challenger with what it tested.
- **picked**: exactly what came back, with the note quoted. A note is the user's own words. Don't
  paraphrase it.
- **recommendation picked**: `yes`, `no`, or `partly` for a mix that includes it.
- **taste**: the sentence from step 5.1 of the skill, as said to the user (after their correction, if
  they made one).

Use the remote's `owner/name` for the project, or the directory name when there's no remote.

## taste.md

```markdown
# Variant lab taste

## Calibration
visual: recommendation picked 4 of 9 rounds (last 3: no, partly, yes)
engineering: 2 of 3
product: 0 of 1

## General
- [visual] concrete artifacts with real numbers over slogans or abstract statements · 7 for, 0 against · 3 projects · last 2026-11-24
- [visual] current state visible without a click (no tabs, no drawers for primary info) · 4 for, 1 against · 2 projects · last 2026-11-24
- [engineering] no new dependencies when ~100 lines of our own will do · stated 2026-11-12
- [any] reads as dense and information-rich, not airy · 5 for, 2 against · 2 projects · last 2026-11-20

## owner/app
- [visual] problem-first ordering on settings and dashboards · 3 for, 0 against · last 2026-11-24
- [product] self-serve only; nothing that needs a sales call · stated 2026-11-02

## Open questions
- [visual] dark vs light surfaces: one pick each way, no pattern yet
```

- **Calibration**: per kind, how often the recommendation was the pick, plus the last three
  results. The ranking is a prediction, and this is its track record.
- **General**: preferences seen in two or more projects, or stated by the user as general.
- **Per project** (`## owner/name`): preferences seen in only one project so far, and facts about
  that project's design language or constraints that shouldn't leak into other projects.
- **Open questions**: axes where the evidence is split or thin. These are what challengers test.

Each preference line has a kind tag (`visual`, `engineering`, `product`, or `any`), the preference
phrased as what they choose *over* what, and its evidence: rounds for and against, how many
projects, and the date last seen. A preference the user said outright is marked `stated` with its
date instead of counts.

## Reading it

Read `taste.md` before writing round one, if it exists, and carry on without it if it doesn't. Use
the General lines for the kind, plus the current project's section.

- **Say what you're applying** in one line, together with the kind and scope: "From your taste log:
  real numbers over slogans, nothing hidden behind tabs." The user can correct it before anything is
  built.
- **Shape the five with it.** Most of round one sits inside the known taste, so it can start
  where a second round used to. Keep the five deliberately different *within* it, and leave alone
  any axis the log says nothing about.
- **Keep one challenger.** One of the five deliberately tests something: an open question, a
  preference with thin evidence (one or two rounds), or a strong preference that hasn't been tested
  in six months. Say which it is and what it tests. Without it the log only ever confirms itself,
  and a preference that has changed never gets the chance to show it. Rank the challenger where it
  honestly belongs.
- **Rank with it.** The recommendation is the variant the evidence says they'll pick. If the
  calibration line for this kind shows the recommendation losing most recent rounds, the ranking is
  off: look at what they picked instead in those rounds, and say so if you change how you rank.
- **Know what outranks it.** The current request and the user's notes in this lab outrank the log.
  So do the project's own rules and design language. A preference from another project never
  overrides a convention of this one.

## Writing it

- **After every pick:** append the round to `picks.md`, then update `taste.md`. Add one to "for" on
  each preference the pick supports and to "against" on each it contradicts, add new preferences
  under the project, and update the calibration line.
- **When the user states a preference** ("I hate tabs", "always show the price"), or corrects your
  taste sentence: record it as `stated`. A stated preference outranks any count. Remove an inferred
  line it contradicts.
- **Promote to General** when the same preference has support in a second project. Move the line
  and merge the counts.
- **Demote or drop.** When "against" catches up with "for", move the line to Open questions. Drop a
  line that has been against for three rounds running. Taste changes, and the log should follow it.
- **At promotion**, re-read the lab's entries in `picks.md` and check the profile still says what
  they show. A preference inferred from round one sometimes didn't survive to the final pick.
- Mention the update in one line at the end of the round, so the user knows it happened and can say
  "don't learn from that one". If they do, delete that round's entry and undo its counts.

## Rules

- **Evidence, not impressions.** A preference needs a pick or a statement behind it. A variant you
  liked writing is not evidence.
- **Phrase as a choice.** "Real numbers over slogans" can be applied and tested; "likes good
  design" can't. If you can't name what lost, it isn't a preference yet.
- **Keep it short.** Each line under about 200 characters, and the profile under about 60 lines.
  Merge overlapping preferences, and drop the weakest when it grows.
- **Never record secrets, customer data or proprietary code.** Short variant names and the user's
  notes are enough.

## Inspecting and editing it

If the user asks what the lab has learned ("what's my variant taste", "what do you think I like"),
summarize `taste.md`: the strongest preferences, the open questions, and the calibration. If they
ask to forget or change something, edit the profile and say what changed. Leave `picks.md` alone
unless they ask to drop a specific round.
