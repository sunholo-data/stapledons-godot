#!/bin/sh
# Row 7ar: the reasons one monitor-face control must show (make display-audit-monitor-controls), with
# its counts read from the run itself, never pinned: a pinned sample count broke when an approved
# layout change (7ae, D-148 A) took the crew playthrough from 46 samples to 45.
# The audit's summary line gives N, the samples it read. N must equal the lines of the samples file
# and be at least MONITOR_MIN_SAMPLES (10: drop_one hides a face on the tenth sampled row, so a
# shorter run cannot exercise it, and a vacuous run, samples=0, cannot pass new=N as 0=0).
# Each PATTERN is an ERE with these tokens replaced first: @N@ and @2N@ (N, 2N); @F1@ and @F10@
# (the frame numbers of sampled rows 1 and 10: the row's one integer "frame" key, wherever it sits; the
# rows also carry nested "frame" keys that are floats or strings, and a row with no integer one, or
# more than one, is refused).
# Usage: tools/monitor_control_check.sh AUDIT_LOG SAMPLES_NDJSON PATTERN...
#   exit 0 silently when every pattern matches; else exit 1 with one line saying why.
set -u
log=$1; samples=$2; shift 2
min=${MONITOR_MIN_SAMPLES:-10}
n=$(sed -nE 's/^display-audit: samples=([0-9]+) .*/\1/p' "$log" | head -n 1)
case "$n" in ''|*[!0-9]*) echo "no display-audit summary in $log"; exit 1;; esac
lines=$(wc -l < "$samples" 2>/dev/null | tr -d ' ')
[ "$n" = "$lines" ] || { echo "the audit read samples=$n but $samples has ${lines:-no} lines"; exit 1; }
[ "$n" -ge "$min" ] || { echo "samples=$n, fewer than $min (a vacuous run)"; exit 1; }
frame() { # ROW: the row's one integer "frame" value; else the reason, and exit 1
	hits=$(sed -n "$1p" "$samples" | grep -oE '"frame":[0-9]+[,}]')
	k=$(printf '%s' "$hits" | grep -c .)
	[ "$k" = 1 ] || { echo "sampled row $1 of $samples has $k integer \"frame\" keys, want 1"; exit 1; }
	printf '%s\n' "$hits" | tr -cd '0-9'
}
f1=$(frame 1) || { echo "$f1"; exit 1; }
f10=$(frame 10) || { echo "$f10"; exit 1; }
for p in "$@"; do
	q=$(printf '%s\n' "$p" | sed "s/@2N@/$((2 * n))/g; s/@N@/$n/g; s/@F10@/$f10/g; s/@F1@/$f1/g")
	grep -Eq -- "$q" "$log" || { echo "missing reason $q"; exit 1; }
done
