#!/usr/bin/env bash
# Disk images (.dmg) in ~/Downloads and ~/Desktop, each checked against the
# installed apps. Read-only: it mounts each image read-only, reads the .app
# names inside, and detaches.
#
#   dmgs.sh              list every .dmg, largest first
#
# A .dmg is the installer, not the app. Once the app it holds is in
# /Applications or ~/Applications, the image is safe to delete. Images whose app
# isn't installed (including "Install X.app" stubs) are the user's call.

set -uo pipefail
shopt -s nullglob
. "$(dirname "$0")/lib.sh"

mnt=""
rows=$(mktemp)
# An interrupted run must not leave an image attached. The loop below writes to
# a file rather than a pipe so it runs in this shell, where the trap sees $mnt.
trap '[ -n "$mnt" ] && { hdiutil detach -force -quiet "$mnt"; rmdir "$mnt"; } 2>/dev/null; rm -f "$rows"' EXIT

installed() {
  [ -d "/Applications/$1" ] || [ -d "$HOME/Applications/$1" ]
}

for dmg in ~/Downloads/*.dmg ~/Desktop/*.dmg; do
  kb=$(du -k "$dmg" | cut -f1)
  mnt=$(mktemp -d)
  # yes accepts a license agreement, which would otherwise wait on stdin. Its
  # SIGPIPE exit is masked, or pipefail reports a successful mount as failed.
  if { yes 2>/dev/null || true; } | hdiutil attach -nobrowse -readonly -noautoopen -noverify \
       -mountpoint "$mnt" "$dmg" >/dev/null 2>&1; then
    apps=$(find "$mnt" -maxdepth 1 -name '*.app' -exec basename {} \;)
    hdiutil detach -quiet "$mnt" 2>/dev/null || hdiutil detach -force -quiet "$mnt" 2>/dev/null
  else
    apps=""
  fi
  rmdir "$mnt" 2>/dev/null
  mnt=""

  verdict="ask: no .app inside, or it would not mount"
  if [ -n "$apps" ]; then
    verdict="ask: $(printf '%s' "$apps" | tr '\n' ',' | sed 's/,$//') not installed"
    while IFS= read -r app; do
      installed "$app" && { verdict="safe: $app is installed"; break; }
    done <<< "$apps"
  fi
  printf '%s\t%s  (%s)\n' "$kb" "$dmg" "$verdict" >> "$rows"
done
human < "$rows"
awk -F'\t' '/\(safe: / { n++; k += $1 } END { printf "%d images safe to delete, %.1fG\n", n, k / 1048576 }' "$rows"
