#!/usr/bin/env bash
# Installers whose job is done, each checked against what's installed.
# Read-only: it mounts each .dmg read-only, lists zips without unzipping, reads
# a .pkg's manifest into a temp dir, and cleans up after itself.
#
#   installers.sh        list every installer, largest first
#
# An installer is not the thing it installs. Once that thing is on the machine,
# the installer is safe to delete:
#   .dmg / .zip   the .app inside is in /Applications or ~/Applications. A stub
#                 ("Install Spotify.app", "1Password Installer.app") counts when
#                 the app it downloads is installed.
#   Install macOS <name>.app   that macOS version or a newer one is running.
#   Xcode_<version>.xip        an Xcode of that exact version is installed.
#   .ipsw         always; Apple serves current firmware on demand.
#   .pkg          every package it holds is in the installer receipts (pkgutil).
# Everything else is the user's call. Zips with no .app inside aren't listed.

set -uo pipefail
shopt -s nullglob
. "$(dirname "$0")/lib.sh"

mnt=""
rows=$(mktemp)
work=$(mktemp -d)
# An interrupted run must not leave an image attached. The loops below write to
# a file rather than a pipe so they run in this shell, where the trap sees $mnt.
trap '[ -n "$mnt" ] && { hdiutil detach -force -quiet "$mnt"; rmdir "$mnt"; } 2>/dev/null; rm -rf "$rows" "$work"' EXIT

installed() {
  [ -d "/Applications/$1" ] || [ -d "$HOME/Applications/$1" ]
}

# "Install Linear.app" / "1Password Installer.app" -> the app the stub downloads
stub_target() {
  local n=${1%.app}
  n=${n#Install }
  n=${n% Installer}
  printf '%s.app' "$n"
}

# Newline-separated .app names -> verdict
app_verdict() {
  local app
  [ -z "$1" ] && { echo "ask: no .app inside, or it would not mount"; return; }
  while IFS= read -r app; do
    installed "$app" && { echo "safe: $app is installed"; return; }
    installed "$(stub_target "$app")" && { echo "safe: $(stub_target "$app") is installed"; return; }
  done <<< "$1"
  echo "ask: $(printf '%s' "$1" | tr '\n' ',' | sed 's/,$//') not installed"
}

row() { printf '%s\t%s  (%s)\n' "$(du -skx "$1" | cut -f1)" "$1" "$2" >> "$rows"; }

# "16.0" and "16" are the same version
norm() { printf '%s' "$1" | sed -E 's/(\.0)+$//'; }

for dmg in ~/Downloads/*.dmg ~/Desktop/*.dmg; do
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
  row "$dmg" "$(app_verdict "$apps")"
done

for zip in ~/Downloads/*.zip ~/Desktop/*.zip; do
  # An .app at the top level or one folder down. Paths, not directory entries,
  # because not every zip tool writes those.
  # LC_ALL=C: zips can hold file names that aren't valid UTF-8.
  apps=$(zipinfo -1 "$zip" 2>/dev/null | LC_ALL=C grep -v '^__MACOSX/' |
    LC_ALL=C sed -nE 's#^([^/]+/)?([^/]+\.app)/.*#\2#p' | sort -u)
  [ -n "$apps" ] && row "$zip" "$(app_verdict "$apps")"
done

running=$(sw_vers -productVersion)
running=${running%%.*}
for app in /Applications/Install\ macOS*.app ~/Applications/Install\ macOS*.app; do
  case $app in
    *Tahoe*) v=26 ;; *Sequoia*) v=15 ;; *Sonoma*) v=14 ;; *Ventura*) v=13 ;;
    *Monterey*) v=12 ;; *"Big Sur"*) v=11 ;;
    *Catalina*|*Mojave*|*"High Sierra"*|*Sierra*|*"El Capitan"*) v=10 ;;
    *) v="" ;;
  esac
  if [ -z "$v" ]; then
    row "$app" "ask: unknown macOS name"
  elif [ "$v" -le "$running" ]; then
    row "$app" "safe: macOS $running is running"
  else
    row "$app" "ask: newer than the running macOS $running"
  fi
done

xcodes=""
for a in /Applications/Xcode*.app ~/Applications/Xcode*.app; do
  xcodes+="$(norm "$(plutil -extract CFBundleShortVersionString raw "$a/Contents/Info.plist" 2>/dev/null)")"$'\n'
done
for xip in ~/Downloads/*.xip ~/Desktop/*.xip; do
  # Betas and release candidates share a version number with the final build,
  # so only a plain Xcode_<version>.xip can be matched.
  v=$(basename "$xip" | sed -nE 's/^Xcode[_ -]?([0-9]+(\.[0-9]+)*)(_Universal|_Apple_silicon)?\.xip$/\1/p')
  if [ -n "$v" ] && grep -qxF "$(norm "$v")" <<< "$xcodes"; then
    row "$xip" "safe: Xcode $v is installed"
  else
    row "$xip" "ask: no installed Xcode matches"
  fi
done

while IFS= read -r -d '' ipsw; do
  row "$ipsw" "safe: firmware, Apple re-downloads it"
done < <(find ~/Downloads ~/Desktop ~/Library/iTunes -maxdepth 2 -name '*.ipsw' -print0 2>/dev/null)

for pkg in ~/Downloads/*.pkg ~/Desktop/*.pkg; do
  d="$work/$(basename "$pkg")"
  mkdir -p "$d"
  # A product archive lists its packages in Distribution; a lone component
  # package names itself in PackageInfo.
  xar -xf "$pkg" -C "$d" Distribution PackageInfo 2>/dev/null
  ids=$( { grep -ohE '<pkg-ref id="[^"]+"' "$d/Distribution" 2>/dev/null | cut -d'"' -f2
           grep -ohE '<pkg-info [^>]*identifier="[^"]+"' "$d/PackageInfo" 2>/dev/null |
             sed -E 's/.*identifier="([^"]+)".*/\1/'; } | sort -u)
  if [ -z "$ids" ]; then
    row "$pkg" "ask: could not read its package list"
    continue
  fi
  total=$(wc -l <<< "$ids" | tr -d ' ')
  missing=0
  while IFS= read -r id; do
    pkgutil --pkg-info "$id" >/dev/null 2>&1 || missing=$((missing + 1))
  done <<< "$ids"
  if [ "$missing" -eq 0 ]; then
    row "$pkg" "safe: all $total packages are installed"
  else
    row "$pkg" "ask: $missing of $total packages not installed"
  fi
done

human < "$rows"
awk -F'\t' '/\(safe: / { n++; k += $1 } END { printf "%d installers safe to delete, %s\n", n, (k >= 1048576) ? sprintf("%.1fG", k / 1048576) : sprintf("%.0fM", k / 1024) }' "$rows"
