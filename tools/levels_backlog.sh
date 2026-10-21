#!/bin/sh
# R2-LEVELS (design_docs/planned/r2/levels.md §A5, §A6; ledger D-103): read the level backlog,
# design_docs/levels/backlog.md, which Mark and the mission loop share.
#   --check  every level row has a known id, a stage from the fixed set and a valid "who"
#   --next   the items the unattended loop may take now (charter queue row L10): S1/S2 levels get
#            "level-eval <id>", S4 levels "level-assets-check <id>", landed or revisited levels
#            "levels-regress <id>" and "regress-capture <id>" (uploaded and parked for Mark).
#            A level in S0, S3 or S5 (attended) or not started is never listed.
# Usage: sh tools/levels_backlog.sh --check|--next [--file <backlog.md>]
set -eu
mode=""
file="design_docs/levels/backlog.md"
while [ $# -gt 0 ]; do
	case "$1" in
	--check | --next) mode="$1" ;;
	--file) shift; file="$1" ;;
	*) echo "levels-backlog: unknown argument $1" >&2; exit 2 ;;
	esac
	shift
done
[ -n "$mode" ] || { echo "usage: sh tools/levels_backlog.sh --check|--next [--file <backlog.md>]" >&2; exit 2; }
[ -f "$file" ] || { echo "levels-backlog: FAIL no $file" >&2; exit 1; }
awk -v mode="$mode" -F'|' '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); gsub(/`/, "", s); return s }
BEGIN {
	split("bridge commons garden homes workshops farms engineering", L, " "); for (i in L) known[L[i]] = 1
	split("not-started S0-brief S1-greybox S2-evaluate S3-playtest S4-dress S5-style S6-land landed S7-revisit", S, " "); for (i in S) stage[S[i]] = 1
	split("attended loop none", W, " "); for (i in W) who[W[i]] = 1
	bad = 0; rows = 0
}
/^\| *[0-9]+ *\|/ {
	rows++
	id = trim($4); st = trim($6); wh = trim($8)
	if (!(id in known)) { print "levels-backlog: FAIL unknown level id \"" id "\""; bad++ }
	if (!(st in stage)) { print "levels-backlog: FAIL " id ": unknown stage \"" st "\""; bad++ }
	if (!(wh in who)) { print "levels-backlog: FAIL " id ": unknown who \"" wh "\""; bad++ }
	if (id in seen) { print "levels-backlog: FAIL " id ": listed twice"; bad++ }
	seen[id] = 1
	if (mode == "--next") {
		if (st == "S1-greybox" || st == "S2-evaluate") print "level-eval " id
		else if (st == "S4-dress") print "level-assets-check " id
		else if (st == "landed" || st == "S6-land" || st == "S7-revisit") { print "levels-regress " id; print "regress-capture " id }
	}
}
END {
	if (rows == 0) { print "levels-backlog: FAIL no level rows"; bad++ }
	if (mode == "--check" && bad == 0) print "levels-backlog: ok (" rows " levels)"
	exit (bad > 0)
}' "$file"
