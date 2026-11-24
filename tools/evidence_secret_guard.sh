#!/bin/sh
# 7aw: refuse evidence containing literal candidate values from the caller's environment.
# Values go from awk ENVIRON to private grep pattern files, never through child argv.
set -u
umask 077
MIN_LEN=8
MAX_ARCHIVE_DEPTH=3
NAME_FILTER='TOKEN|KEY|SECRET|PASSWD|PASSWORD|_PAT|AUTH|CREDENTIAL'
fail2() { printf 'evidence-guard: %s\n' "$*" >&2; exit 2; }
usage() {
  echo 'usage: evidence_secret_guard.sh [--require-candidates] [--names-file FILE]... <file-or-dir>...' >&2
  exit 2
}

[ "$#" -gt 0 ] || usage
guard_tmp=
cleanup() {
  [ -n "$guard_tmp" ] || return 0
  if rm -rf "$guard_tmp" 2>/dev/null; then return 0; fi
  # Extracted directories can have read-only modes.
  find "$guard_tmp" -type d -exec chmod u+rwx {} \; >/dev/null 2>&1
  rm -rf "$guard_tmp" 2>/dev/null || fail2 'cannot remove temporary files'
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
guard_tmp=$(mktemp -d "${TMPDIR:-/tmp}/evidence-guard.XXXXXX" 2>/dev/null) || fail2 'mktemp failed'
: > "$guard_tmp/names" && : > "$guard_tmp/values" || fail2 'cannot initialize temporary files'

add_names() {
  [ -f "$1" ] && [ -r "$1" ] || fail2 "cannot read names file: $1"
  awk '
    { sub(/\r$/, ""); sub(/=.*/, "")
      sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "")
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*$/) print }
  ' > "$guard_tmp/listed" 2>/dev/null < "$1" || fail2 "cannot read names file: $1"
  [ -s "$guard_tmp/listed" ] || fail2 "names file holds no valid NAME line: $1"
  cat "$guard_tmp/listed" >> "$guard_tmp/names" 2>/dev/null || fail2 'cannot store candidate names'
}
guard_require=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --require-candidates) guard_require=1; shift ;;
    --names-file) [ "$#" -ge 2 ] || usage; add_names "$2"; shift 2 ;;
    --names-file=*) add_names "${1#--names-file=}"; shift ;;
    --) shift; break ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ "$#" -gt 0 ] || usage
guard_inputs=$#

# Build both the bulk search and per-name attribution patterns in the same pass.
awk -v filter="$NAME_FILTER" -v min="$MIN_LEN" '
  BEGIN {
    dir=ARGV[1]; ARGV[1]=""
    for (name in ENVIRON)
      if (name ~ /^[A-Za-z_][A-Za-z0-9_]*$/ && toupper(name) ~ filter) names[name]=1
  }
  {
    if (!($0 in names) && !($0 in ENVIRON))
      print "evidence-guard: names-file name absent from environment (hint, no value to guard): " $0
    names[$0]=1
  }
  END {
    for (name in names) {
      if (!(name in ENVIRON)) continue
      value=ENVIRON[name]; gsub(/\r/, "", value)
      count=split(value, lines, "\n")
      pattern=dir "/pattern." name
      for (i=1; i<=count; i++) {
        line=lines[i]; sub(/^[ \t]+/, "", line); sub(/[ \t]+$/, "", line)
        if (length(line) < min || line ~ /^-----(BEGIN|END) /) continue
        print line >> (dir "/values")
        print line > pattern
      }
      close(pattern)
    }
  }
' "$guard_tmp" > "$guard_tmp/hints" 2>/dev/null < "$guard_tmp/names" || fail2 'cannot build candidate patterns'
cat "$guard_tmp/hints" >&2 || fail2 'cannot report candidate hints'
guard_count=$(awk 'END {print NR}' "$guard_tmp/values" 2>/dev/null) || fail2 'cannot count candidate patterns'

match_file() {
  if LC_ALL=C GREP_OPTIONS= grep -F -f "$1" >/dev/null 2>&1 < "$2"; then
    return 0
  else
    [ "$?" = 1 ] || fail2 "grep failed on $3"
  fi
  return 1
}
scan_file() {
  [ -r "$1" ] || fail2 "unreadable input: $2"
  [ "$guard_count" -gt 0 ] || return 0
  if match_file "$guard_tmp/values" "$1" "$2"; then
    for guard_pattern in "$guard_tmp"/pattern.*; do
      if match_file "$guard_pattern" "$1" "$2"; then
        printf 'evidence-guard: %s value is in %s\n' "${guard_pattern##*/pattern.}" "$2" >&2
        guard_hits=$((guard_hits + 1))
      fi
    done
  fi
}
scan_archive() {
  [ "$3" -lt "$MAX_ARCHIVE_DEPTH" ] || fail2 "archive nesting exceeds $MAX_ARCHIVE_DEPTH levels: $2"
  [ -r "$1" ] || fail2 "unreadable input: $2"
  guard_unpack=$(mktemp -d "$guard_tmp/unpack.XXXXXX" 2>/dev/null) || fail2 'mktemp failed'
  TAR_OPTIONS= tar -xzf - -C "$guard_unpack" >/dev/null 2>&1 < "$1" || fail2 "tar failed: $2"
  scan_dir "$guard_unpack" "$2:" "$(($3 + 1))"
}
scan_dir() {
  [ -r "$1" ] && [ -x "$1" ] || fail2 "unreadable directory: $2"
  for guard_entry in "$1"/.[!.]* "$1"/..?* "$1"/*; do
    [ -e "$guard_entry" ] || [ -L "$guard_entry" ] || continue
    if [ "$guard_entry" -ef "$guard_tmp" ]; then continue; fi
    scan "$guard_entry" "$2${guard_entry##*/}" "$3"
  done
}
scan() {
  if [ -L "$1" ]; then fail2 "symbolic link input: $2"; fi
  if [ -d "$1" ]; then scan_dir "$1" "${2%/}/" "$3"
  elif [ -f "$1" ]; then
    case "$1" in
      *.tgz|*.tar.gz) scan_archive "$1" "$2" "$3" ;;
      *) scan_file "$1" "$2" ;;
    esac
  else fail2 "missing or unsupported input: $2"; fi
}

guard_hits=0
for guard_input do
  scan "$guard_input" "$guard_input" 0
done
if [ "$guard_hits" -gt 0 ]; then
  printf 'evidence-guard: refused: %s secret hit(s) across the given inputs\n' "$guard_hits" >&2
  exit 1
fi
if [ "$guard_count" = 0 ]; then
  if [ "$guard_require" = 1 ]; then fail2 'no candidate secret values found (--require-candidates)'; fi
  echo 'evidence-guard: 0 candidate values; nothing to check' >&2
else
  printf 'evidence-guard: clean (%s candidate value line(s), %s input(s))\n' "$guard_count" "$guard_inputs" >&2
fi
exit 0
