#!/bin/sh
# rig_check.sh: the full suite on the Studio, posted to GitHub as the rig/full commit status
# (rig/golden for --golden-only).
# Since 2026-11-03 (Mark) it runs nightly on main (tools/rig_nightly.sh) rather than per PR: a PR
# merges on the fast tier, its targeted gates, the cross-family evaluation and Mark's OK on a dev
# build. Run it by hand on a PR only when a change is risky enough to want the whole suite first
# (make test, plus make golden for visual changes, which needs a GPU window).
#
#   tools/rig_check.sh <PR number | ref> [--golden | --golden-only]
#
# --golden-only runs make golden alone and posts rig/golden instead of rig/full: the nightly runs the
# headless make test whenever the CPU is free and holds the GPU half back until the GPU is (2026-11-06).
#
# It clones fresh under RIG_DIR (default ${TMPDIR}/rig-check/<sha>; never the attended checkout),
# stages the pinned runtime if the clone lacks it, fetches the sky textures, runs the suite under
# a watchdog (macOS has no timeout), keeps the log, and posts pending, then success or failure.
# RIG_NO_STATUS=1 skips the status posts (a dry run on someone else's PR, say).
# --golden and --golden-only first run the golden setup, the makes that make test used to provide (7af), each
# bounded; every make call in the run is bounded, so a hang is a named failure, not a stuck nightly.
# The make test run (M1b) is still serial, but profiled: tools/suite_profile.sh runs it with gmake, its raw rows land in
# <sha>.profile/ beside the log, and the log ends with the summary's top 10. RIG_TRACE=1 adds --trace. Three loud
# fallbacks log 'rig-check FALLBACK <reason>' and mark the success: RIG_PROFILE=0 (plain make), profile-absent (plain
# make), gmake-missing (the profiler on the system make).
set -eu
REPO=sunholo-data/stapledons-godot
TEST_S=${RIG_TEST_S:-7200}   # make test is 66-90 min on the Studio; D-126 C (Mark, 2026-10-28)
GOLDEN_S=${RIG_GOLDEN_S:-1800}
GOLDEN_SETUP="deps starmap-assets planet-assets import"   # 7af: what make golden read from make test; import last
SETUP_S=${RIG_SETUP_S:-600}                               # per target; slowest measured 9 s
DL_S=${RIG_DL_S:-3600}   # runtime fetch + sky regen; measured regen ~900 s
# bounded SECS cmd...: cmd in its own process group, stdin from /dev/null; at SECS (or on INT/TERM/HUP) TERM the
# whole group, KILL it 2 s later, exit 124 (130 if interrupted). A plain alarm+exec signals make, not its recipes.
bounded() {
  perl -e 'my $s = shift; my $pid = fork; defined $pid or die "bounded: fork: $!\n";
    if (!$pid) { setpgrp(0, 0); open STDIN, "<", "/dev/null"; exec @ARGV or exit 127 }
    setpgrp($pid, $pid);
    for my $sig (qw(ALRM INT TERM HUP)) { $SIG{$sig} = sub { kill "TERM", -$pid; sleep 2; kill "KILL", -$pid;
      waitpid($pid, 0); exit($sig eq "ALRM" ? 124 : 130) } }
    alarm $s; waitpid($pid, 0); exit($? & 127 ? 128 + ($? & 127) : $? >> 8)' "$@"
}

usage() { echo "usage: $0 <PR number | ref> [--golden | --golden-only]"; exit 2; }
[ $# -ge 1 ] || usage
target=$1; shift
golden=0; tests=1; ctx=rig/full
for a in "$@"; do case "$a" in --golden) golden=1 ;; --golden-only) golden=1; tests=0; ctx=rig/golden ;; *) usage ;; esac; done

case "$target" in
  *[!0-9]*) sha=$(gh api "repos/$REPO/commits/$target" -q .sha) ;;
  *) sha=$(gh pr view "$target" --repo "$REPO" --json headRefOid -q .headRefOid) ;;
esac
[ -n "$sha" ] || { echo "rig-check: could not resolve $target"; exit 2; }
short=$(printf %s "$sha" | cut -c1-8)
dir=${RIG_DIR:-${TMPDIR:-/tmp}/rig-check/$sha}
log="$dir.log"; [ $tests = 1 ] || log="$dir.golden.log"   # 7ag: rig/golden must not overwrite the rig/full log of the same commit

status() {
  [ "${RIG_NO_STATUS:-0}" = 1 ] && return 0
  # GitHub refuses a description over 140 characters (row 7o): cut every post to fit.
  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context="$ctx" -f description="$(printf %s "$2" | cut -c1-140)" > /dev/null
}

suite="make test"; [ $golden = 1 ] && suite="make test + make golden"; [ $tests = 0 ] && suite="make golden"
echo "rig-check: $target -> $short in $dir ($suite); log $log"
status pending "$suite running on the Studio"

fail() {
  echo "rig-check: FAIL: $1 (log: $log)"
  d="$short: $1"   # the log pointer goes in too whenever it fits GitHub's 140 characters (row 7o)
  if [ $((${#d} + ${#log} + 8)) -le 140 ]; then d="$d (log: $log)"; fi
  status failure "$d" || echo "rig-check: could not post the failure status"
  exit 1
}

rm -rf "$dir"; mkdir -p "$(dirname "$dir")"
# Only the make test run writes <sha>.profile/: a --golden-only run (the nightly's rig/golden half, same sha) must not delete it.
if [ $tests = 1 ]; then rm -rf "$dir.profile"; fi
# The clone goes when the run ends, pass or fail; the log ($dir.log) stays. 41 kept clones once
# filled 40 GB (2026-11-03). RIG_KEEP=1 keeps it for debugging.
[ "${RIG_KEEP:-0}" = 1 ] || trap 'cd / && rm -rf "$dir"' EXIT
git clone --quiet "https://github.com/$REPO.git" "$dir" || fail "clone failed"
cd "$dir"
git fetch --quiet origin "$sha" && git checkout --quiet --detach "$sha" || fail "checkout of $short failed"

# The pin is the Makefile's AILANG_RELEASE (ci.yml's AILANG_VERSION moves with it). A runtime that is
# absent or off the pin is restaged: a stale v0.54.11 runtime once failed make test on parse errors.
pin=$(sed -n 's/^AILANG_RELEASE ?= *//p' Makefile)
[ -n "$pin" ] || fail "no AILANG_RELEASE pin in the Makefile"
have=$(runtime/bin/ailang --version 2>/dev/null | head -1 || true)
case "$have" in
  *"${pin#v}"*) echo "rig-check: runtime $pin" > "$log" ;;
  *) echo "rig-check: staging runtime $pin (had: ${have:-none})" > "$log"
     bounded "$DL_S" make runtime >> "$log" 2>&1 || fail "rig setup: make runtime failed or ran over ${DL_S}s" ;;
esac
have=$(runtime/bin/ailang --version 2>/dev/null | head -1 || true)
case "$have" in *"${pin#v}"*) ;; *) fail "runtime is '$have', pin is $pin" ;; esac
PATH=$PWD/runtime/bin:$PATH; export PATH
bounded "$DL_S" make sky-assets >> "$log" 2>&1 || fail "rig setup: make sky-assets failed or ran over ${DL_S}s"

start=$(date +%s); mark=
if [ $tests = 1 ]; then
  # Row 7ag: -k runs every make test target, so one known red cannot hide the rest; make -k still exits 2 if any
  # target failed. The failing targets are the top-level make error lines this run appended to the log.
  # 1d (M1b): the profiled run needs the instrument on the PR head and gmake on PATH; the fallbacks log their reason.
  n0=$(wc -l < "$log"); trc=0; fb=
  if [ "${RIG_PROFILE:-1}" = 0 ]; then fb=profile-off
  elif [ ! -f tools/suite_profile.sh ] || [ ! -f tools/timed_recipe_shell.sh ]; then fb=profile-absent
  elif ! command -v gmake >/dev/null 2>&1; then fb=gmake-missing
  fi
  trace=; if [ "${RIG_TRACE:-0}" = 1 ]; then trace=--trace; fi
  case "$fb" in
    '')
      bounded "$TEST_S" sh tools/suite_profile.sh run --make gmake --out "$dir.profile" -- $trace -k test >> "$log" 2>&1 || trc=$? ;;
    profile-off)
      echo "rig-check FALLBACK profile-off" >> "$log"; mark='(SERIAL FALLBACK: profile-off)'
      bounded "$TEST_S" make -k test >> "$log" 2>&1 || trc=$? ;;
    profile-absent)
      echo "rig-check FALLBACK profile-absent" >> "$log"; mark='(SERIAL FALLBACK: profile-absent)'
      bounded "$TEST_S" make -k test >> "$log" 2>&1 || trc=$? ;;
    gmake-missing)
      echo "rig-check FALLBACK gmake-missing" >> "$log"; mark='(SERIAL FALLBACK: gmake-missing)'
      bounded "$TEST_S" sh tools/suite_profile.sh run --make make --out "$dir.profile" -- $trace -k test >> "$log" 2>&1 || trc=$? ;;
  esac
  case "$fb" in '' | gmake-missing)
    # The profiled run's summary (its top 10 rows and the totals) closes the log, pass or fail; a failed summary is one line.
    srcs=0; sumout=$(sh tools/suite_profile.sh summary "$dir.profile/profile.tsv" 2>&1) || srcs=$?
    if [ "$srcs" = 0 ]; then printf '%s\n' "$sumout" | awk 'NR <= 11 || /^totals/' >> "$log"
    else echo "rig-check: profile summary failed (rc $srcs)" >> "$log"; fi ;;
  esac
  if [ "$trc" != 0 ]; then
    red=$(tail -n +"$((n0 + 1))" "$log" | sed -nE "s/^g?make: \*\*\* \[([^]]*: )?([^]]+)\] .*/\2/p; s/^g?make: \*\*\* No rule to make target .([^']+)'.*/\1/p" | awk '!s[$0]++' | tr '\n' ' ' | sed 's/ $//')
    n=$(echo $red | wc -w | tr -d ' ')
    echo "rig-check: failed targets ($n): $red"
    why="make test failed (rc $trc; bound ${TEST_S}s)"; [ "$trc" = 124 ] && why="make test ran over ${TEST_S}s"
    [ "$n" != 0 ] || fail "$why; no failing target in the log"
    # "sha: " why "; N red: " names " +K more", K < N: the suffix is reserved at N's width (row 7o: 140 characters).
    budget=$((140 - 10 - ${#why} - 8 - ${#n} - 7 - ${#n})); list=; k=0
    for t in $red; do [ $((${#list} + ${#t} + 1)) -le $budget ] || break; list="${list:+$list }$t"; k=$((k + 1)); done
    [ "$k" != 0 ] || { list="$(printf %s "${red%% *}" | cut -c1-$((budget - 3)))..."; k=1; }   # a first name too long: cut it
    [ "$k" = "$n" ] || list="$list +$((n - k)) more"
    fail "$why; $n red: $list"
  fi
fi
if [ $golden = 1 ]; then
  for t in $GOLDEN_SETUP; do
    bounded "$SETUP_S" make "$t" >> "$log" 2>&1 || fail "golden setup: make $t failed or ran over ${SETUP_S}s"
  done
  bounded "$GOLDEN_S" make golden >> "$log" 2>&1 || fail "make golden failed or ran over ${GOLDEN_S}s"
fi
mins=$(( ($(date +%s) - start + 59) / 60 ))
echo "rig-check: ok, $short green ($suite, ${mins} min)"
status success "$suite green${mark:+ $mark} on the Studio in ${mins} min ($(ailang --version 2>&1 | head -1))" || { echo "rig-check: could not post the success status"; exit 1; }
