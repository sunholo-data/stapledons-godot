#!/bin/sh
# One pass predicate for every Godot --script gate (row 7x). Godot 4.7 exits 0 when the script fails
# to parse, and never exits when a runtime error stops _init before quit(), so rc alone proves nothing.
# usage: sh tools/script_gate.sh NAME LOG TIMEOUT_S SUMMARY_ERE [WANT_RC] -- command [args...]
# Passes only on all four: an exit inside TIMEOUT_S wall seconds with rc == WANT_RC (default 0); no
# 'SCRIPT ERROR' in the log; a line matching SUMMARY_ERE (which must start with ^). The command runs
# through env, so a leading VAR=value (as $(GODOT_SIM) expands) and `env -u X` both work. All output
# goes to LOG. A pass prints one line; a failure prints the log's non-ok lines (last 40) and every reason.
# The timeout is an independent perl supervisor (round-2 amendment A2): it runs the command in its own
# process group and at the deadline sends TERM, waits 2 s, then KILLs the whole group, so a command that
# ignores SIGALRM or leaves a child behind is still stopped (exit 142). Limit: a child that calls setsid
# or setpgrp itself leaves the group and is not killed. No --script gate does that today.
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
perl -e 'use POSIX ":sys_wait_h"; my $secs = shift; my $pid = fork; die "fork: $!" unless defined $pid; if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127; } my $end = time + $secs; my $st; while (1) { my $r = waitpid($pid, WNOHANG); if ($r == $pid) { $st = $?; last } if (time >= $end) { kill "TERM", -$pid; my $g = time + 2; while (time < $g) { last if waitpid($pid, WNOHANG) == $pid; select(undef, undef, undef, 0.1) } kill "KILL", -$pid; waitpid($pid, 0); kill "KILL", -$pid; exit 142 } select(undef, undef, undef, 0.1) } exit($st & 127 ? 128 + ($st & 127) : $st >> 8)' "$limit" env "$@" > "$log" 2>&1
rc=$?
secs=$(($(date +%s) - start))
why=""
if [ "$rc" -eq 142 ]; then why="$why; timeout after $limit s (rc 142): a runtime error before quit() leaves Godot running"
elif [ "$rc" -ne "$want" ]; then why="$why; rc $rc, want $want"; fi
se=$(grep -c 'SCRIPT ERROR' "$log")
[ "$se" -eq 0 ] || why="$why; $se SCRIPT ERROR line(s) (Godot exits 0 on a parse error)"
line=$(grep -E -- "$summary" "$log" | tail -n 1)
[ -n "$line" ] || why="$why; no summary line matching $summary (rc $rc with no summary is a load failure, not a result)"
if [ -n "$why" ]; then
  grep -v -E '^[[:space:]]*ok[[:space:]]' "$log" | tail -n 40
  echo "script-gate: $name FAIL$why (log $log)"
  exit 1
fi
echo "script-gate: $name ok: $line (rc $rc, no SCRIPT ERROR, $secs s of $limit s)"
