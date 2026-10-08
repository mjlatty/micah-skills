#!/usr/bin/env bash
# The usual large items on this machine, each with the facts needed to tier it.
# Read-only and fast, so survey.sh runs it and a repeat run can rerun it alone.

set -uo pipefail
shopt -s nullglob
. "$(dirname "$0")/lib.sh"

AS=~/Library/"Application Support"

section "Docker (quote the on-disk size, not ls)"
raws=$(find ~/Library/Containers/com.docker.docker -name Docker.raw 2>/dev/null)
if [ -n "$raws" ]; then
  while IFS= read -r raw; do
    disk=$(du -k "$raw" | cut -f1)
    apparent=$(( $(stat -f %z "$raw") / 1024 ))
    echo "$(gib "$disk") on disk (ls shows $(gib "$apparent")), last modified $(date -r "$raw" +%Y-%m-%d): $raw"
  done <<< "$raws"
  if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    echo "Docker is running: docker system df works"
  else
    echo "Docker is not running: docker system df will fail; judge staleness by the date above"
  fi
fi

section "JetBrains folders for versions no installed IDE uses"
installed=$(
  { for f in /Applications/*.app/Contents/Resources/product-info.json \
             ~/Applications/*.app/Contents/Resources/product-info.json; do echo "$f"; done
    find "$AS/JetBrains/Toolbox/apps" -maxdepth 6 -path '*/Contents/Resources/product-info.json' 2>/dev/null
  } | while IFS= read -r f; do plutil -extract dataDirectoryName raw -o - "$f" 2>/dev/null; done
)
for base in "$AS/JetBrains" ~/Library/Caches/JetBrains ~/Library/Logs/JetBrains; do
  for d in "$base"/*20[0-9][0-9].[0-9]*; do
    printf '%s\n' "$installed" | grep -qxF "$(basename "$d")" && continue
    du -skx "$d" 2>/dev/null
  done
done | human
[ -n "$installed" ] && echo "installed: $(printf '%s\n' "$installed" | sort -u | tr '\n' ' ')"

section "Electron app caches over 100M (tier 1 only while the app is closed)"
for app in "$AS"/*/; do
  app=${app%/}
  kb=0
  for c in "$app/Cache" "$app/Code Cache" "$app/GPUCache" "$app/Service Worker/CacheStorage"; do
    [ -d "$c" ] && kb=$(( kb + $(du -skx "$c" 2>/dev/null | cut -f1) ))
  done
  [ "$kb" -ge 102400 ] || continue
  name=$(basename "$app")
  running="closed"
  pgrep -fi "[/ ]$name[^/]*\.app/Contents/MacOS/" >/dev/null && running="RUNNING"
  printf '%s\t%s (%s)\n' "$kb" "$name" "$running"
done | human

section "Playwright browser builds older than the newest of each browser"
for d in ~/Library/Caches/ms-playwright/*-[0-9]*; do
  b=$(basename "$d")
  printf '%s\t%s\t%s\n' "${b%-*}" "${b##*-}" "$d"
done | sort -t$'\t' -k1,1 -k2,2rn | awk -F'\t' 'seen[$1]++ { print $3 }' |
  while IFS= read -r d; do du -skx "$d"; done | human

section "Firefox update downloads"
[ -d ~/Library/Caches/Mozilla/updates ] && du -skx ~/Library/Caches/Mozilla/updates | human

section "Disk images in Downloads and Desktop (dmgs.sh says which hold an installed app)"
dmgs=(~/Downloads/*.dmg ~/Desktop/*.dmg)
if [ ${#dmgs[@]} -gt 0 ]; then
  kb=$(du -kc "${dmgs[@]}" | tail -1 | cut -f1)
  echo "${#dmgs[@]} .dmg files, $(gib "$kb")"
fi

section "DerivedData (deleting a folder mid-build fails that build)"
[ -d ~/Library/Developer/Xcode/DerivedData ] && du -skx ~/Library/Developer/Xcode/DerivedData | human
for d in ~/Library/Developer/Xcode/DerivedData/*/; do
  [ -n "$(find "$d" -maxdepth 0 -mmin -60)" ] && echo "written in the last hour (live build): $(basename "$d")"
done
pgrep -fl xcodebuild | cut -c1-160
exit 0
