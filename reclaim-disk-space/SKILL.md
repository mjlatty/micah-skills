---
name: reclaim-disk-space
description: Diagnose and fix a Mac that is low on disk or throwing "out of application memory" — "my disk is full", "startup disk almost full", "free up space", "out of application memory", "apps keep getting killed", "why is my Mac out of memory", "clean up caches". Measures top-down before proposing anything, separates the memory symptom from its usual disk cause, tiers deletions by reversibility, and only auto-executes the regenerable ones.
---

# Reclaim disk space on a Mac

Two rules govern everything below. **Measure before you propose** — the user's guess
about what's big is usually wrong, and correcting it with numbers is part of the job.
**Verify before you delete** — every `rm` is preceded by a check that proves the target
is what you think it is.

The environment is **zsh**, which does not word-split unquoted variables. Use arrays:

```zsh
DIRS=(~/Library/Caches ~/Library/Containers ~/.npm)
du -sh "${DIRS[@]}" 2>/dev/null | sort -rh
```

`for x in $DIRS` silently iterates once over the joined string.

zsh also treats an **unmatched glob as a fatal error**, where bash passes the pattern
through. `ls -d ~/Library/Caches/*.ShipIt 2>/dev/null` doesn't fail quietly — it aborts
the whole command with `no matches found` before `ls` ever runs, so `2>/dev/null` can't
save it. Since "no matches" is the *normal* case when probing for cruft, append the `(N)`
null-glob qualifier to every speculative pattern:

```zsh
ls -d ~/Library/Caches/*.ShipIt(N) ~/Library/Caches/*-updater(N)   # empty, not an error
```

Large `du` and `rm` runs need generous timeouts (5–10 min) and are good candidates for
backgrounding.

## 1. Separate the symptom from the cause

**"Out of application memory" is usually not a RAM hog.** macOS grows swap on the boot
volume; when the disk is full, swap can't grow past its cap and the kernel starts
killing applications. The user reports a memory error; the fault is disk. Never blame a
process before you have all three numbers:

```zsh
df -h /System/Volumes/Data      # real free space
sysctl vm.swapusage             # is swap pinned at its ceiling?
sysctl -n hw.memsize            # physical RAM, for context
```

**`df /` is misleading** — it reports the read-only sealed system volume, which is
always ~full and never the problem. Always ask for `/System/Volumes/Data`.

Read them together: free space in the low single-digit GB, plus swap used ≈ swap total,
plus RAM that isn't unusually pressured, means this is a disk problem wearing a memory
costume. Say so explicitly before proposing anything — the user came in with a wrong
model and it should be corrected.

## 2. Measure top-down, never sideways

Survey the usual homes first, then drill into whichever is largest. Do not skip to a
directory you assume is the culprit.

```zsh
DIRS=(
  ~/Library/Caches ~/Library/Containers ~/Library/Developer
  ~/Library/"Application Support" ~/.npm ~/.cache
  ~/conductor ~/Code                      # plus any project/workspace root
)
du -sh "${DIRS[@]}" 2>/dev/null | sort -rh
```

Then descend one level at a time into the biggest entry (`du -sh <dir>/* | sort -rh |
head -20`) until you reach something nameable. Stop when you can say *what* is big and
*why it exists*, not just its path. Anything you never measured stays out of the report.

## 3. Check whether the owning app is even installed

Caches under `~/Library/Caches/<Vendor>` and `~/Library/Application Support/<Vendor>`
are frequently **orphaned from apps that were uninstalled months ago**. That reclassifies
them from "risky" to "free". Verify before you classify:

```zsh
ls -d /Applications/*.app ~/Applications/*.app 2>/dev/null   # what's actually installed
```

`*.ShipIt` and `*-updater` directories are Squirrel/Electron installer staging leftovers
— downloaded update payloads. They are **always** safe, installed app or not.

## 4. Tier proposals by reversibility

Sort every candidate into a tier. **Only tier 1 executes without asking.**

**Tier 1 — regenerable, no user data. Execute immediately when the machine is in
distress.** Caches belonging to uninstalled apps, package-manager caches (`~/.npm`,
`~/.cache`, Homebrew downloads), `*.ShipIt` / `*-updater` staging. Worst case something
re-downloads.

**Tier 2+ — anything touching user data, project state, or tooling the user actively
depends on. Report with sizes and last-used dates, then ask.** Xcode DeviceSupport and
simulators, `node_modules`/`vendor` in projects, old workspaces and branches, container
data for installed apps, VM images, Docker.

The judgment calls belong to the user: which simulators matter, which branches are dead,
which project is still live. Give them dates and sizes so the call is cheap to make —
don't make it for them, and don't hide a tier 2 item inside a tier 1 batch.

## 5. Verify before every delete

**Resolve symlinks first.** Sibling directories with identical sizes and timestamps are
one directory seen twice, not two copies. Conductor symlinks *branch-name* → *city-name*;
counting both doubles your estimate and produces a reclaim number that never materializes.

```zsh
ls -ld ~/conductor/workspaces/*/*      # a "->" arrow is the signal; count the target once
```

The arrow is the only reliable tell. `ls -ldi` shows the *symlink's* own inode, not the
target's, so the two never match and inode comparison quietly proves nothing — that's a
hard-link test, not a symlink test. Resolve with `readlink` when you need the real path.

**Before deleting `node_modules` or `vendor`, prove nothing tracked lives inside.** Must
return zero lines:

```zsh
git -C <repo> status --porcelain -- node_modules vendor
```

**Never touch Xcode `DeviceSupport`, `CoreSimulator/Devices`, or `XCTestDevices` while
Xcode or a simulator is running** — you'll corrupt live state:

```zsh
pgrep -l "Xcode|CoreSimulator|Simulator"     # must be empty
```

Keep the **current** OS version's DeviceSupport; older ones regenerate on next device
connect.

**Prefer `du` on individual entries over a command's advertised effect.** `xcrun simctl
delete unavailable` often frees nothing, because the runtimes backing those devices are
still installed. Inspect devices yourself — most are ~17 MB never-booted stubs and only a
handful hold GBs:

```zsh
SIMS=~/Library/Developer/CoreSimulator/Devices
for d in $SIMS/*/; do
  [ -f "$d/device.plist" ] || continue
  printf '%s\t%s\t%s\t%s\n' \
    "$(du -sh "$d" | cut -f1)" \
    "$(/usr/libexec/PlistBuddy -c 'Print :name' "$d/device.plist" 2>/dev/null)" \
    "$(/usr/libexec/PlistBuddy -c 'Print :runtime' "$d/device.plist" 2>/dev/null | sed 's/.*SimRuntime\.//')" \
    "$(stat -f '%Sm' -t '%Y-%m-%d' "$d")"
done | sort -rh
```

Sort by size, show the user the handful that are actually large with their runtime and
last-modified date, and let them pick.

## 6. Report honestly

Close with a before/after table built from **real `df` output**, not from the sum of what
you intended to delete:

| | Before | After | Freed |
|---|---|---|---|
| `/System/Volumes/Data` free | 4.2 Gi | 63 Gi | +58.8 Gi |

Then, in plain terms:

- **Anything that freed nothing** — name it. A step that returned 0 bytes is a finding,
  not an embarrassment to omit.
- **Any earlier estimate that was wrong** — say it was wrong and by how much. Especially
  if a symlink alias inflated it.
- **What you left untouched and why** — the tier 2 list, still awaiting the user's call.

Re-check `sysctl vm.swapusage` at the end too: if the complaint was "out of application
memory," the fix isn't proven until swap has room to grow again.
