# Shared by the reclaim-disk-space scripts. Source it; don't run it.

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

# KiB -> "12.3G"
gib() { awk -v k="$1" 'BEGIN { printf "%.1fG", k / 1048576 }'; }
