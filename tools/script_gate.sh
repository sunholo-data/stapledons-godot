#!/bin/sh
# One pass predicate for every Godot --script gate (row 7x). Godot 4.7 exits 0 when the script fails
# to parse, and never exits when a runtime error stops _init before quit(), so rc alone proves nothing.
# usage: sh tools/script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args...]
# Passes only on all four: an exit inside TIMEOUT_S wall seconds with rc == WANT_RC (default 0); no
# 'SCRIPT ERROR' in the log; a line matching SUMMARY_ERE (which must start with ^). The command runs
# through env, so a leading VAR=value (as $(GODOT_SIM) expands) and `env -u X` both work. All output
# goes to LOG. A pass prints one line; a failure prints the log's non-ok lines (last 40) and every reason.
# The bounded supervisor retains observed descendants across PGID changes and reparenting.
# Polling cannot contain a child that escapes before its first observation.
set -u
usage() { echo "script-gate: usage: script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args...]"; exit 2; }
[ $# -ge 6 ] || usage
name=$1 log=$2 limit=$3 summary=$4
shift 4
want=0
if [ "$1" != -- ]; then want=$1; shift; fi
[ $# -ge 2 ] && [ "$1" = -- ] || usage
shift
case $limit in '' | *[!0-9]*) echo "script-gate: $name: TIMEOUT_S must be whole seconds, got '$limit'"; exit 2 ;; esac
[ "$limit" -ge 1 ] || { echo "script-gate: $name: TIMEOUT_S must be at least 1"; exit 2; }
case $want in '' | *[!0-9]*) echo "script-gate: $name: WANT_RC must be a number, got '$want'"; exit 2 ;; esac
case $summary in '^'?*) ;; *) echo "script-gate: $name: SUMMARY_ERE must start with ^ (got '$summary')"; exit 2 ;; esac
mkdir -p "$(dirname "$log")"
start=$(date +%s)
bounded=$(dirname "$0")/bounded_run.sh
cancel= runner= relay= confirmed=
relay_signal() {
  [ -n "$cancel" ] || cancel=$1
  if [ -n "$runner" ]; then
    [ -f "$relay/pending-signal" ] || printf '%s\n' "$cancel" > "$relay/pending-signal"
    if [ -z "$confirmed" ]; then kill -TERM "$runner" 2>/dev/null || :; fi
  fi
}
trap 'relay_signal HUP' HUP
trap 'relay_signal INT' INT
trap 'relay_signal TERM' TERM
relay=$(mktemp -d "${TMPDIR:-/tmp}/bounded-shell.XXXXXX") || exit 125
if [ -n "$cancel" ]; then rc=125; printf '%s\n' "bounded-shell: cancelled before spawn" > "$log"
else
  sh "$bounded" --relay "$relay" "$limit" -- "$@" > "$log" 2>&1 & runner=$!
  # The deterministic barrier holds the real spawned, captured, unconfirmed
  # direct child window. Pending traps were installed before this fork.
  if [ -n "${BR_RELAY_TEST_DIR:-}" ]; then
    sh "$bounded" --barrier "$BR_RELAY_TEST_DIR" prereg "$$" "$runner" || :
  fi
  [ -z "$cancel" ] || relay_signal "$cancel"
  tries=0
  while [ ! -f "$relay/ready" ] && [ ! -f "$relay/done" ] && [ "$tries" -lt "$(((limit + 4) * 100))" ]; do
    sleep 0.01; tries=$((tries + 1))
    [ -z "$cancel" ] || break
  done
  if [ -f "$relay/ready" ] && [ -z "$cancel" ]; then
    confirmed=1
    if [ -n "${BR_RELAY_TEST_DIR:-}" ]; then sh "$bounded" --barrier "$BR_RELAY_TEST_DIR" ready "$$" "$runner" || :; fi
  fi
  # The relay owns an absolute monotonic N+4 / first-signal+4 watchdog.
  # A trapped wait may return early; collect until completion or child exit.
  while :; do
    wait "$runner"; rc=$?
    if [ -f "$relay/done" ]; then read -r rc < "$relay/done"; break; fi
    [ "$rc" -ne 127 ] || break
    [ -n "$cancel" ] && kill -0 "$runner" 2>/dev/null || break
  done
fi
trap - HUP INT TERM
rm -f "$relay/ready.tmp" "$relay/ready" "$relay/done" "$relay/done.tmp" "$relay/inner-ready" "$relay/inner-ready.tmp" "$relay/inner-release" "$relay/pending-signal"
rmdir "$relay" 2>/dev/null || :
[ -z "$cancel" ] || rc=125
secs=$(($(date +%s) - start))
why=""
[ -z "$cancel" ] || why="$why; interrupted by $cancel"
if [ "$rc" -eq 142 ]; then why="$why; timeout after $limit s (rc 142): a runtime error before quit() leaves Godot running"
elif [ "$rc" -ne "$want" ]; then why="$why; rc $rc, want $want"; fi
se=$(grep -c 'SCRIPT ERROR' "$log")
[ "$se" -eq 0 ] || why="$why; $se SCRIPT ERROR line(s) (Godot exits 0 on a parse error)"
line=$(grep -E -- "$summary" "$log" | tail -n 1)
[ -n "$line" ] || why="$why; no summary line matching $summary (rc $rc with no summary is a load failure, not a result)"
# Zero probe (row 7x B2, judge survivor 2; per count after B2 quorum r1): a positive gate (WANT_RC 0) passes only on
# a summary with a nonzero standalone number, and only when SUMMARY_ERE refuses each variant of the line with ONE
# such number zeroed, so neither a loose ERE (^.) nor one loose count beside a bound one ([0-9]* pairs) passes.
# Numbers already 0 (0 failures) are not probed. Negative controls (WANT_RC > 0) are exempt.
if [ -n "$line" ] && [ "$want" -eq 0 ]; then
  n=$(printf '%s\n' "$line" | grep -oE '[0-9]+' | grep -c .)
  k=1 counted=0
  while [ "$k" -le "$n" ]; do
    v=$(printf '%s\n' "$line" | sed -E "s/(^|[^A-Za-z0-9_.-])[0-9]+/\\10/$k")
    if [ "$v" != "$line" ]; then
      counted=1
      if printf '%s\n' "$v" | grep -qE -- "$summary"; then why="$why; SUMMARY_ERE also matches '$v' (count $k zeroed; bind it: [1-9][0-9]*)"; break; fi
    fi
    k=$((k + 1))
  done
  [ "$counted" = 1 ] || why="$why; summary '$line' carries no nonzero count (print one, e.g. N passed, 0 failures)"
fi
if [ -n "$why" ]; then
  grep -v -E '^[[:space:]]*ok[[:space:]]' "$log" | tail -n 40
  echo "script-gate: $name FAIL$why (log $log)"
  exit 1
fi
echo "script-gate: $name ok: $line (rc $rc, no SCRIPT ERROR, $secs s of $limit s)"
