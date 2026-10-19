#!/bin/sh
# R2-CAMERA-FORWARD AC-B4: every `make golden` ok line outside the families that D-92 re-poses
# must match main's exactly, numbers included (design §D8: "the same ok line with the same
# numbers"), so a moved number, a changed label, a lost case or a new one all fail.
#
#   tools/golden_baseline.sh capture <golden.log> <baseline.txt>   record from a main run
#   tools/golden_baseline.sh check   <golden.log> <baseline.txt>   compare a branch run
#   tools/golden_baseline.sh selftest                              negative controls
#
# Excluded (re-posed by D-92, design camera-forward.md §D8): exactly these label prefixes.
set -eu

EXCLUDE='^ok    (G-M4-S2|G-M4-S3|G-M4-S4|G-CAM-1|G-CAM-2|G-CAM-3)[ :]'

normalise() {
	# ok lines only, re-posed families dropped, sorted (the run order is not the contract)
	grep -E '^ok    ' "$1" | grep -vE "$EXCLUDE" | LC_ALL=C sort
}

case "${1:-}" in
capture)
	normalise "$2" > "$3"
	echo "golden-baseline: captured $(wc -l < "$3" | tr -d ' ') ok lines (re-posed families excluded) -> $3"
	;;
check)
	tmp=$(mktemp)
	normalise "$2" > "$tmp"
	if cmp -s "$tmp" "$3"; then
		echo "golden-baseline: ok ($(wc -l < "$3" | tr -d ' ') ok lines outside the re-posed families match main)"
		rm -f "$tmp"
	else
		echo "golden-baseline: FAIL: ok lines outside the re-posed families differ from main (< main, > this run):"
		diff "$3" "$tmp" | grep -E '^[<>]' | head -40
		rm -f "$tmp"
		exit 1
	fi
	;;
selftest)
	dir=$(mktemp -d)
	trap 'rm -rf "$dir"' EXIT
	printf 'ok    G-M4-1 composite position: 72 cases worst 0.1 px\nok    GR7 inside the shadow 0\nok    G-CAM-1 forward pole (bow) 0.2 px\n' > "$dir/main.log"
	normalise "$dir/main.log" > "$dir/base.txt"
	sed 's/G-CAM-1 forward pole (bow) 0.2/G-CAM-1 forward pole (bow) 0.4/' "$dir/main.log" > "$dir/reposed.log"
	normalise "$dir/reposed.log" | cmp -s - "$dir/base.txt" || { echo "golden-baseline selftest: FAIL: a re-posed family's number counted"; exit 1; }
	sed 's/72 cases worst 0.1 px/72 cases worst 0.2 px/' "$dir/main.log" > "$dir/moved.log"
	if normalise "$dir/moved.log" | cmp -s - "$dir/base.txt"; then echo "golden-baseline selftest: FAIL: a moved number outside the families passed"; exit 1; fi
	grep -v 'GR7' "$dir/main.log" > "$dir/lost.log"
	if normalise "$dir/lost.log" | cmp -s - "$dir/base.txt"; then echo "golden-baseline selftest: FAIL: a lost case passed"; exit 1; fi
	echo "golden-baseline selftest: ok (a re-posed number passes; a moved number or a lost line outside the families fails)"
	;;
*)
	echo "usage: tools/golden_baseline.sh capture|check <golden.log> <baseline.txt> | selftest" >&2
	exit 2
	;;
esac
