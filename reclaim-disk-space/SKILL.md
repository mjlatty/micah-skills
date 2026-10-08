---
name: reclaim-disk-space
description: Diagnose and fix a Mac that is low on disk or throwing "out of application memory" — "my disk is full", "startup disk almost full", "disk cleanup", "clean up my disk", "free up space", "out of application memory", "apps keep getting killed", "why is my Mac out of memory", "clean up caches", "ENOSPC / no space left on device". Measures top-down before proposing anything, separates the memory symptom from its usual disk cause, tiers deletions by reversibility, and only auto-executes the regenerable ones.
---

# Reclaim disk space on a Mac

Two rules govern everything below. **Measure before you propose** — the user's guess
about what's big is usually wrong, and correcting it with numbers is part of the job.
**Verify before you delete** — every `rm` is preceded by a check that proves the target
is what you think it is.

## Shell traps

The environment is **zsh**, which does not word-split unquoted variables. Use arrays:

```zsh
DIRS=(~/Library/Caches ~/Library/Containers ~/.npm)
du -sh "${DIRS[@]}" 2>/dev/null | sort -rh
```

`for x in $DIRS` silently iterates once over the joined string.

zsh also treats an **unmatched glob as a fatal error**: the command aborts with
`no matches found` before it runs, and `2>/dev/null` can't save it. "No matches" is the
normal case when probing for cruft. **Don't use the `(N)` qualifier**: this user's shell
sets `nobareglobqual`, which disables it, so `*.ShipIt(N)` fails the same way. Turn on
`nullglob` in a subshell, or use `find`:

```zsh
( setopt nullglob; ls -d ~/Library/Caches/*.ShipIt ~/Library/Caches/*-updater )
find ~/Library/Caches -maxdepth 1 -name '*.ShipIt'
```

The quiet version of this failure is the dangerous one. A size survey whose glob failed
printed nothing for `~/Library/Containers`, which read as "empty" while it held 23 GiB.
So **every "what's big in X" step uses `scripts/sizes.sh <dir> [N]`**, never a
hand-written `du` over a glob. It lists children with `find`, so zsh options can't
touch it, and it reports unreadable paths instead of hiding them.

**If a folder you expect to be big measures empty or tiny, re-measure it another way
before reporting it.** Use `du -skx <dir>` on the folder itself, or `ls -la`. An aborted
glob, a TCC `Operation not permitted`, and a truly empty folder all look the same in a
size list.

A quoted tilde doesn't expand either: `rm -rf "~/Library/..."` targets a directory
literally named `~`. Quote only the part after it: `~/"Library/Application Support"`.

Large `du` and `rm` runs need generous timeouts (10 min) and belong in the background. A
foreground `du` over `~/Library/Developer` has hit a 5-minute timeout before.

## 1. Survey everything in one background pass

Run `scripts/survey.sh` from this skill's directory, in the background. It is
read-only. It prints the vitals, APFS snapshots, live Xcode work, known cruft, and the
usual large items (§4). Then it measures every top-level entry in `~` and `~/Library`,
plus the system locations on the data volume (`/Applications`, `/Library`, `/opt`,
simulator runtime images). While it runs, explain the diagnosis below; don't start
probing directories by hand.

**Read the accounting line first.** It compares what was measured with `df`'s used total.
A small gap means the size list is the whole story, and the cleanup can be thorough by
proof rather than by habit. A large gap means something is hidden: unreadable system
directories, a local snapshot, or another user's files. Say so; don't report a cleanup
as complete while tens of GiB are unexplained. A negative gap means APFS clones were
counted twice (§11).

## 2. Separate the symptom from the cause

**"Out of application memory" is usually not a RAM hog.** macOS grows swap on the boot
volume; when the disk is full, swap can't grow past its cap and the kernel starts
killing applications. The user reports a memory error; the fault is disk.

**`df /` is misleading** — it reports the read-only sealed system volume, which is
always ~full and never the problem. Always ask for `/System/Volumes/Data`.

Read the vitals together: free space in the low single-digit GB, plus swap used ≈ swap
total, plus RAM that isn't unusually pressured, means this is a disk problem wearing a
memory costume. Say so explicitly before proposing anything — the user came in with a
wrong model and it should be corrected.

**Check whether the disk is still filling.** Run `df` twice a few minutes apart. On this
machine several agents build and test in parallel, and free space has dropped from 8 GiB
to 141 MiB mid-session. If it is falling, the writer matters more than any cache: look
for the newest large directories (DerivedData, `/private/tmp` build dirs, simulator
clones) and name the process. The writer can also be swap: free space here once fell
from 23.7 GiB to zero in a day, almost all of it swap driven by booted simulators
(§10). A cleanup that doesn't stop the writer only buys an hour.

## 3. Drill top-down, never sideways

Take the largest entry from the survey and descend one level at a time until you reach
something nameable, with `scripts/sizes.sh <dir>` at every level:

```zsh
scripts/sizes.sh ~/Library/Containers
```

It runs `du` with `-x`, and so should any `du` you write. Simulator runtimes are disk
images mounted under `/Library/Developer/CoreSimulator/Volumes`. Without `-x`, `du` counts their mounted
contents: 123 GiB for a `/Library/Developer` that holds 23.5 GiB on disk. The images
themselves live in `/System/Library/AssetsV2`.

Stop when you can say *what* is big and *why it exists*, not just its path. Anything you
never measured stays out of the report.

**Watch for trailing-slash globs.** Plain `du` counts a symlink as 0 B, but `du -sh dir/*/`
follows it, so a symlinked alias gets counted twice. Conductor symlinks *branch-name* →
*city-name*. Skip links (`[ -L "${d%/}" ] && continue`) or drop the trailing slash.

Findings the size list won't label for you: `/private/tmp` holds build output when
agents point `-derivedDataPath` or browser profiles there. Cursor and Linear put their
updaters in `~/Library/Application Support/Caches`, not `~/Library/Caches`. The Trash
is unreadable from an agent (`Operation not permitted`), so ask the user how full it is.

## 4. Check the usual large items

The top-down survey finds these eventually; a named checklist finds them in one pass.
`scripts/usual-suspects.sh` checks each one, and the survey runs it. On a repeat run,
run it alone; it takes about a second.

- **Docker**: `Docker.raw` under `~/Library/Containers/com.docker.docker`. It was the
  biggest single win here, at 19 GiB. The file is sparse: `ls` showed 60 GiB while it
  used 19 GiB, so quote the `du` figure. `docker system df` fails when Docker isn't
  running, so judge staleness by the file's last-modified date. Tier 2. Offer three
  options:
  1. Prune unused images (`docker image prune -a`, with Docker running). Volumes, and
     the databases in them, survive. The VM returns freed blocks to macOS gradually, so
     recheck `df` after a few minutes before calling it a zero.
  2. Wipe everything (Docker Desktop → Troubleshoot → Clean / Purge data). Loses volumes.
  3. Leave it.
- **Old JetBrains folders**: `<IDE><version>` under `Application Support/JetBrains`,
  `Caches/JetBrains`, and `Logs/JetBrains`. A folder is old when no installed IDE uses
  that version. Each IDE names its folder in `Contents/Resources/product-info.json`
  (`dataDirectoryName`), and the script compares against that. Toolbox installs IDEs in
  `~/Applications` or its own `Application Support/JetBrains/Toolbox/apps`, not
  `/Applications`. Check both before calling a version uninstalled. Caches and logs
  of an uninstalled version are tier 1. Its `Application Support` folder holds settings
  and plugins, so it's tier 2.
- **Electron app caches**: `Cache`, `Code Cache`, and `GPUCache` under
  `Application Support/<App>`. Linear's held 1.9 GiB. Tier 1, but only while the app
  isn't running, because a running app has them open. The script marks each app
  RUNNING or closed; recheck with `pgrep -fl <App>` right before the `rm`.
- **Old Playwright browser builds**: `~/Library/Caches/ms-playwright/<browser>-<build>`.
  Each upgrade downloads new builds and leaves the old ones. Deleting all but the newest
  of each browser is tier 1 and avoids re-downloading the build in use. A project pinned
  to an older Playwright reinstalls its build with `npx playwright install`.
- **Firefox update downloads**: `~/Library/Caches/Mozilla/updates`. Tier 1.
- **Disk images** (`.dmg`) in `~/Downloads` and `~/Desktop`. Here, 17 installers
  totaled about 3 GiB. An image is only the installer, so once its app is in
  `/Applications` or `~/Applications`, it is tier 1. Match on the `.app` inside the
  image, not the file name: `googlechrome.dmg` holds `Google Chrome.app`.
  `scripts/dmgs.sh` mounts each image read-only, compares its `.app` against what's
  installed, and detaches. It takes about 40 seconds for 17 images, so the survey only
  counts them. An image whose app isn't installed is tier 2. So is one with only an
  `Install X.app` stub inside.
- **DerivedData**: tier 1 under the rule in §6, which says when a build is live.

## 5. Check whether the owning app is even installed

Caches under `~/Library/Caches/<Vendor>` and `~/Library/Application Support/<Vendor>`
are frequently **orphaned from apps that were uninstalled months ago**. That reclassifies
them from "risky" to "free". Verify before you classify:

```zsh
ls -d /Applications/*.app ~/Applications/*.app   # what's actually installed
```

`*.ShipIt` and `*-updater` directories are Squirrel/Electron installer staging leftovers
— downloaded update payloads. They are **always** safe, installed app or not.

## 6. Tier proposals by reversibility

Sort every candidate into a tier. **Only tier 1 executes without asking, and only when
free space is under ~10 GiB or the user asked for a cleanup.** Otherwise, propose tier 1
with sizes like everything else.

**Tier 1 — regenerable, no user data.**

- Caches of uninstalled apps, `*.ShipIt` / `*-updater` staging.
- Package-manager caches: `~/.npm/_cacache`, and CocoaPods, pnpm, go-build, composer,
  node-gyp, pip, Homebrew, and ms-playwright under `~/Library/Caches`. Delete
  `~/.cache` per entry, not wholesale; some tools keep state there.
- The tier 1 items from §4: caches and logs of uninstalled JetBrains versions, Electron
  caches of closed apps, old Playwright builds, Firefox update downloads, and `.dmg`
  installers whose app is installed.
- `~/Library/Developer/XCTestDevices`, when nothing is testing (§7). These are parallel
  testing clones ("Clone 2 of iPhone 16 Pro"). `xcodebuild` is supposed to delete them,
  but an interrupted run leaks them. Delete with `xcrun simctl --set testing delete all`.
  **Don't quote their `du` size as reclaimable.** They are APFS clones that share most
  of their blocks with the source simulator. Here, three new clones added ~20 GiB to
  `du` while `df` used rose ~1 GiB. Deleting 57 GiB of them (by `du`) once freed 3.3 GiB,
  against a promised ~75 GiB. Propose them as "mostly shared space, real size unknown
  until deleted", and report what `df` gained.
- DerivedData folders untouched for a day. Skip anything written in the last hour; that
  is a live build. A build whose DerivedData is deleted mid-run fails, so check
  `pgrep -fl xcodebuild` right before the `rm`; another agent's build counts.
- Build scratch in `/private/tmp` that `lsof +D <dir>` shows nothing holding open.

Worst case something re-downloads or rebuilds. But if the disk is still under ~10 GiB
after cleanup, that refill can hit ENOSPC halfway and leave a corrupt cache. After
`~/.cache/puppeteer` was cleared on a nearly full disk here, it came back with no Chrome
binary, and `npm ci` failed in five workspaces over the next week. Name the caches you
cleared in the report so the user can recognize the failure.

**Tier 2+ — anything touching user data, project state, or tooling the user actively
depends on. Report with sizes and last-used dates, then ask.** Named simulators in
`CoreSimulator/Devices`, simulator runtimes, old DeviceSupport versions,
`node_modules`/`vendor` in projects, old Conductor workspaces (§8),
`~/conductor/archived-contexts` (closed workspaces' notes and PR drafts), container data
for installed apps, settings of uninstalled JetBrains versions, VM images, Docker (§4).

Two tier 2 sources are large enough to have their own scripts. Both only list unless
told otherwise:

- **Simulator runtimes** (`scripts/simulators.py`): about 8 GiB each. The script shows
  each runtime's last use and how many devices and test clones depend on it. It reads
  simctl's own metadata, so it finishes in under a second. A runtime nothing has ever
  booted is an easy yes. An older iOS runtime may be kept on purpose for testing
  backward compatibility, so ask. Delete with `xcrun simctl runtime delete <id>`.
- **Dependencies in idle workspaces** (`scripts/workspace-deps.sh [days]`): `node_modules`
  and `vendor` in workspaces with no file edited for 7 days (default). This keeps the
  branch, uncommitted work, and `.context`, and only removes what reinstalls. It skips
  anything git tracks and the current workspace. After approval, `--delete` re-checks
  each workspace right before removing it, in case another agent resumed it. The cost
  is a slower cold start in that workspace. `vendor` in linkfount-tall also needs
  `auth.json` copied in before `composer install` works, so mention it.

The judgment calls belong to the user: which simulators matter, which branches are dead,
which project is still live. Give them dates and sizes so the call is cheap to make —
don't make it for them, and don't hide a tier 2 item inside a tier 1 batch.

## 7. Verify before every delete

**Test for live simulator work directly, not for Xcode.** `pgrep -l "Xcode|Simulator"`
always matches, because launchd keeps `CoreSimulatorService` and `SimulatorTrampoline`
alive with no device running. The check still failed after the user quit Xcode, which
kept the whole simulator tree off-limits. What actually matters:

```zsh
xcrun simctl list devices booted                 # named simulators in use
xcrun simctl --set testing list devices booted   # test clones in use
pgrep -fl 'xcodebuild|XCTRunner'                 # a test run, possibly another agent's
```

All three empty means `XCTestDevices` and named simulators are safe to touch, even with
Xcode.app open. Other agents on this machine run `xcodebuild test`, so recheck right
before the `rm`, not ten minutes earlier.

**Inspect simulators yourself.** `xcrun simctl delete unavailable` often frees nothing,
because the runtimes backing those devices are still installed. `scripts/simulators.py`
lists devices by data size with their last-booted date. Most are ~17 MB never-booted
stubs; only a handful hold GBs.

Show the user the large ones with runtime and last-booted date, and let them pick.
Keep DeviceSupport for the current OS build (`sw_vers`); older builds regenerate on the
next device connect.

**Before deleting `node_modules` or `vendor`, prove nothing tracked lives inside.** Must
return zero lines:

```zsh
git -C <repo> status --porcelain -- node_modules vendor
```

## 8. Conductor workspaces

Run `scripts/workspaces.sh` in the background. It measures every workspace and asks
GitHub which PRs merged, about 30 seconds here. It sorts the workspaces into groups,
each with its total size:

- **Safe**: the PR for this exact commit merged, nothing is uncommitted, and nothing is
  unpushed. Only this group is safe to archive.
- **Empty**: no commits beyond the default branch, no changes, no PR. Usually an
  abandoned start, so ask.
- **Merged, but has work since** and **unmerged or in progress**: keep.
- **Broken**: `.git` points at a repo that no longer exists. Ask.

PRs here are squash-merged, so `git branch --merged` reports merged branches as
unmerged. The script asks GitHub instead, with one `gh pr list` per repo. It also marks
the workspace you are running in.

**Show the group sizes early.** Old workspaces are usually a small win; the safe group
was 2.9 GiB here. The user should know that before spending time on it. Most of a
workspace's size is dependencies, and `workspace-deps.sh` (§6) reclaims those without
archiving anything.

**Archive in the Conductor app; don't delete folders.** The `conductor` CLI only manages
cloud workspaces. Deleting a workspace folder, or running `git worktree remove`, leaves
Conductor listing a workspace that no longer exists. Hand the user the safe list to
archive.

**Leave `conductor.db` alone** (`~/Library/Application Support/com.conductor.app`). It is
Conductor's state, not a cache.

## 9. Hand the user what only they can do

Some fixes are out of an agent's reach. List them with sizes and stop retrying them:

- **Empty the Trash** (unreadable from here).
- **Root-owned files**, usually in `~/.npm` from an old `sudo npm`. `rm` fails on them
  every run. The fix is `sudo chown -R "$(whoami)" ~/.npm`, which needs their password.
- **Quit Xcode or stop a test run**, when a live build blocks a large delete.
- **Install a pending macOS update** (`softwareupdate --list`), if a
  `com.apple.os.update-*` snapshot is holding space.
- **Archive merged workspaces** in the Conductor app (§8).

## 10. Prevent a repeat

Cleaning up doesn't fix a machine that refills. Free space here fell from 23.7 GiB to
zero in a day, almost all of it swap, driven by booted simulators. Each one holds
gigabytes of RAM, and with several agents testing at once, swap grows on the boot disk
until the disk is full.

- **Check that the simulator-cap hook is installed.** `~/.claude/hooks/sim-cap.sh` is a
  PreToolUse hook that blocks booting a simulator or starting `xcodebuild test` once two
  simulators are booted (`CLAUDE_SIM_CAP`). The survey reports whether
  `~/.claude/settings.json` registers it. If not, tell the user and offer to wire it up.
- **Simulators named `*-claude` belong to other sessions.** Ask before shutting one
  down, even to free memory; it may be mid-test in another workspace.
- **Parallel testing multiplies the count.** Each parallel-testing clone is another
  booted simulator. Agent test runs should pass `-parallel-testing-enabled NO`.

## 11. Report honestly

Build the report from **real `df` output**, not from the sum of what you intended to
delete. **Measure `df` right before and right after each delete, and report each step's
change separately.** Free space moves on its own here: it once rose ~8 GiB between two
steps with no delete, likely macOS removing swap files or another session finishing.
A start-to-end total credits that drift to the cleanup.

| Step | Free before | Free after | Change |
|---|---|---|---|
| Package caches | 4.2 Gi | 9.0 Gi | +4.8 Gi |
| `Docker.raw` | 17.1 Gi | 36.0 Gi | +18.9 Gi |

The 8.1 Gi between the first step's "after" and the second's "before" is not yours.
Say so.

**When `df` moves much less than `du` predicted, say so, and name the likely cause.**
The usual causes:

- APFS clones. `du` counts shared blocks once per copy, so simulator test clones
  (§6) look many times larger than what deleting them frees. The survey's negative
  accounting gap is the same effect.
- A local snapshot (`tmutil listlocalsnapshots /System/Volumes/Data`) keeps deleted
  blocks allocated until it is removed.
- Another process filled the space while you deleted.

Then, in plain terms:

- **Anything that freed nothing** — name it. A step that returned 0 bytes is a finding,
  not an embarrassment to omit.
- **Any earlier estimate that was wrong** — say it was wrong and by how much.
- **What you left untouched and why** — the tier 2 list, still awaiting the user's call.
- **Why it will come back**, if it will. Name the source and a durable fix from §10,
  or a cleanup step after agent test runs. Without that, the user is back in a week.

Re-check `sysctl vm.swapusage` at the end too: if the complaint was "out of application
memory," the fix isn't proven until swap has room to grow again.

**On a repeat run in the same session**, don't redo the whole survey. Recheck `df`, the
earlier big entries, and the tier 1 locations that regrow (package caches, test clones,
`/private/tmp`), and rerun `scripts/usual-suspects.sh`. Run the full survey only if that doesn't account for the loss.
