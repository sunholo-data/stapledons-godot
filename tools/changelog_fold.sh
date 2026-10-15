#!/usr/bin/env bash
# Changelog fold: changelogs/unreleased/*.md fragments (and CHANGELOG.md's own "## Unreleased"
# entries) are filed under the first release tag whose history holds the commit that added them.
#
#   tools/changelog_fold.sh rebuild      regroup CHANGELOG.md by release tag and remove the folded
#                                        fragments (idempotent; the release workflow runs it per tag)
#   tools/changelog_fold.sh notes TAG    print TAG's section (the GitHub release notes)
#
# An entry is a "### " block. Its commit is the one that added the fragment file, or for an entry
# written straight into CHANGELOG.md under Unreleased, the commit that last touched its heading line
# (an entry already under a release heading keeps it). Its release is
# the oldest v* tag (by tag date) that contains that commit; entries in no tag stay in Unreleased.
# Shell glue only (CLAUDE.md "Python"): git, awk and sed.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
CL=CHANGELOG.md
FRAG=changelogs/unreleased

release_of() { # commit -> oldest v* tag containing it, or "Unreleased"
  local t
  t=$(git tag --contains "$1" --sort=creatordate 2>/dev/null | grep '^v' | head -1 || true)
  echo "${t:-Unreleased}"
}

tag_date() { git log -1 --format=%as "$1"; }

notes() {
  awk -v want="## $1 (" 'index($0, want) == 1 { on = 1; next } on && /^## / { exit } on' "$CL"
}

rebuild() {
  local work; work=$(mktemp -d); trap 'rm -rf "$work"' RETURN
  local n=0
  # 1. Entries already in CHANGELOG.md, in file order (newest first), with the commit of each
  #    heading line. Everything before the first "### " (the title and "## " lines) is the header.
  local first; first=$(grep -n '^### ' "$CL" | head -1 | cut -d: -f1)
  sed -n "1,$((first - 1))p" "$CL" | grep -v '^## ' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$work/header"
  local heads; heads=$(grep -n '^### ' "$CL" | cut -d: -f1)
  local total; total=$(wc -l < "$CL")
  local starts=($heads) i
  for ((i = 0; i < ${#starts[@]}; i++)); do
    local s=${starts[$i]} e
    if ((i + 1 < ${#starts[@]})); then e=$((starts[i + 1] - 1)); else e=$total; fi
    n=$((n + 1))
    sed -n "${s},${e}p" "$CL" | grep -v '^## ' > "$work/$(printf %04d $n).md"
    # Already filed under "## <tag> (...)": keep it. Under "## Unreleased": blame the heading.
    local sec; sec=$(sed -n "1,${s}p" "$CL" | grep '^## ' | tail -1 | sed -E 's/^## ([^ ]+).*/\1/')
    if [ "$sec" = Unreleased ] || [ -z "$sec" ]; then
      local c; c=$(git blame -L "$s,$s" --porcelain -- "$CL" | head -1 | cut -d' ' -f1)
      sec=$(release_of "$c")
    fi
    echo "$(printf %04d $n) $sec cl" >> "$work/map"
  done
  # 2. Fragments, newest first by file name (YYYY-MM-DD-slug.md), with the commit that added each.
  local f
  for f in $(ls "$FRAG"/*.md 2>/dev/null | grep -v '/README.md$' | sort -r); do
    n=$((n + 1))
    # Title the fragment from its file name; its own "##"/"###" headings become "####".
    local slug; slug=$(basename "$f" .md)
    { echo "### ${slug:11} (${slug:0:10})"; echo; sed -E 's/^#{2,3} /#### /' "$f"; echo; } > "$work/$(printf %04d $n).md"
    # The FIRST commit that added it (the 2026-10-12 restore of deleted files re-added many).
    local c; c=$(git log --diff-filter=A --format=%H --reverse -- "$f" | head -1)
    local r=Unreleased
    [ -n "$c" ] && r=$(release_of "$c")
    echo "$(printf %04d $n) $r frag" >> "$work/map"
    [ "$r" != Unreleased ] && git rm -q "$f"
  done
  # 3. Write: header, Unreleased, then each release newest first. Fragment entries come after the
  #    CHANGELOG.md entries of the same release (both newest first within themselves).
  {
    cat "$work/header"; echo; echo "## Unreleased"; echo
    # Unfolded fragments stay as files; only CHANGELOG.md's own unreleased entries print here.
    awk '$2 == "Unreleased" && $3 == "cl" { print $1 }' "$work/map" | while read -r id; do
      sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$work/$id.md"; echo
    done
    for t in $(git tag --sort=-creatordate | grep '^v'); do
      awk -v t="$t" '$2 == t { print $1 }' "$work/map" > "$work/ids"
      [ -s "$work/ids" ] || continue
      echo "## $t ($(tag_date "$t"))"; echo
      while read -r id; do sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$work/$id.md"; echo; done < "$work/ids"
    done
  } > "$work/out"
  mv "$work/out" "$CL"
}

case "${1:-}" in
  rebuild) rebuild ;;
  notes) [ -n "${2:-}" ] || { echo "usage: $0 notes TAG" >&2; exit 2; }; notes "$2" ;;
  *) echo "usage: $0 rebuild | notes TAG" >&2; exit 2 ;;
esac
