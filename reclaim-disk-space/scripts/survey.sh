#!/usr/bin/env bash
# Read-only first pass for reclaim-disk-space. Deletes nothing.
#
# Measures every top-level entry in ~ and ~/Library plus the system locations
# that live on the data volume, then reports how much of df's "used" that
# accounts for. A large ~/Library/Developer takes 5+ minutes, so run this in
# the background. It's bash, not zsh, so globs that match nothing expand to
# nothing regardless of the user's zsh options.
#
# du runs with -x: simulator runtimes are disk images mounted under
# /Library/Developer/CoreSimulator/Volumes, and following those mounts counts
# their contents on top of the images that actually hold the bytes.

set -uo pipefail
shopt -s nullglob

section() { printf '\n== %s ==\n' "$1"; }

# du -sk output -> "12.3G<TAB>path", largest first
human() {
  sort -rn | awk -F'\t' '{
    k = $1
    if (k >= 1048576) printf "%6.1fG\t%s\n", k / 1048576, $2
    else if (k >= 1024) printf "%6.0fM\t%s\n", k / 1024, $2
    else printf "%6dK\t%s\n", k, $2
  }'
}

section "vitals"
df -h /System/Volumes/Data | tail -1
sysctl vm.swapusage
echo "RAM: $(( $(sysctl -n hw.memsize) / 1073741824 )) GiB"

section "local snapshots (these keep deleted blocks allocated)"
tmutil listlocalsnapshots /System/Volumes/Data 2>&1 | tail -n +2

section "live Xcode work (blocks simulator and DerivedData deletes; empty = clear)"
if command -v xcrun >/dev/null; then
  xcrun simctl list devices booted 2>/dev/null | grep Booted | sed 's/^ */booted device: /'
  xcrun simctl --set testing list devices booted 2>/dev/null | grep Booted | sed 's/^ */booted test clone: /'
fi
pgrep -fl 'xcodebuild|XCTRunner' | cut -c1-160
for d in ~/Library/Developer/Xcode/DerivedData/*/; do
  [ -n "$(find "$d" -maxdepth 0 -mmin -60)" ] && echo "DerivedData written in last hour: $(basename "$d")"
done

section "known-regenerable cruft"
for d in ~/Library/Caches/*.ShipIt ~/Library/Caches/*-updater \
         ~/Library/"Application Support"/Caches/*.ShipIt ~/Library/"Application Support"/Caches/*-updater; do
  du -sk "$d" 2>/dev/null
done | human
clones=(~/Library/Developer/XCTestDevices/*/)
[ ${#clones[@]} -gt 0 ] && echo "XCTestDevices: ${#clones[@]} test clones (du overstates their reclaimable size; see SKILL.md)"
[ -n "$(find ~/.npm -user root -print -quit 2>/dev/null)" ] && echo "~/.npm contains root-owned files: rm will fail on them; needs sudo chown"

section "sizes (largest 25 of every entry measured)"
entries=()
for e in ~/.[!.]* ~/..?* ~/* ~/Library/*; do
  [ "$e" = ~/Library ] || [ -L "$e" ] || entries+=("$e")
done
for e in /Applications /Library /System/Library/AssetsV2 /opt /usr/local /Users/Shared \
         /private/tmp /private/var/vm /private/var/folders /cores; do
  [ -e "$e" ] && entries+=("$e")
done
sizes=$(printf '%s\0' "${entries[@]}" | xargs -0 -P 8 -n 1 du -skx 2>/dev/null)
printf '%s\n' "$sizes" | human | head -25

section "accounting"
measured=$(printf '%s\n' "$sizes" | awk -F'\t' '{s += $1} END {print s + 0}')
used=$(df -k /System/Volumes/Data | awk 'NR == 2 {print $3}')
awk -v m="$measured" -v u="$used" 'BEGIN {
  printf "measured %.1fG of %.1fG used; unaccounted %.1fG\n", m / 1048576, u / 1048576, (u - m) / 1048576
}'
echo "(unaccounted = unreadable dirs, local snapshots, other users; negative = APFS clones counted twice)"

if ! ls ~/.Trash >/dev/null 2>&1; then
  echo "~/.Trash: not readable from this process; ask the user how full the Trash is"
fi
